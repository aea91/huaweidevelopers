import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/external_article.dart';

class LinkedInPostsService {
  static const companySlug = 'hsdturkiye';
  static const companyPostsUrl =
      'https://www.linkedin.com/company/$companySlug/posts/?feedView=all';

  static const _functionUrl =
      'https://us-central1-arkuibuilder.cloudfunctions.net/getLinkedInCompanyPosts';

  Future<List<ExternalArticle>> fetchHighlights({int limit = 5}) async {
    final uri = Uri.parse(_functionUrl).replace(
      queryParameters: {
        'company': companySlug,
        'limit': '$limit',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('LinkedIn feed unavailable (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
      throw Exception('LinkedIn feed could not be parsed');
    }

    final items = decoded['posts'];
    if (items is! List) return const [];

    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return ExternalArticle(
        id: (item['id'] ?? item['url'] ?? '').toString(),
        title: (item['title'] ?? '').toString(),
        url: (item['url'] ?? companyPostsUrl).toString(),
        excerpt: (item['excerpt'] ?? '').toString(),
        author: item['author']?.toString() ?? 'HSD Türkiye',
        imageUrl: item['imageUrl']?.toString(),
        publishedAt: DateTime.tryParse((item['publishedAt'] ?? '').toString()),
        tags: const ['linkedin'],
        source: 'linkedin',
      );
    }).where((a) => a.id.isNotEmpty && a.title.isNotEmpty).toList();
  }
}
