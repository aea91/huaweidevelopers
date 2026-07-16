import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/external_article.dart';

class YouTubeVideosService {
  static const channelId = 'UCoNPnz0C7LUt4Klng8fvDGA';
  static const channelStreamsUrl =
      'https://www.youtube.com/@HuaweiDeveloperGroupsT%C3%BCrkiye/streams';

  static const _functionUrl =
      'https://us-central1-arkuibuilder.cloudfunctions.net/getYouTubeChannelVideos';

  Future<List<ExternalArticle>> fetchHighlights({int limit = 5}) async {
    final uri = Uri.parse(_functionUrl).replace(
      queryParameters: {
        'channelId': channelId,
        'limit': '$limit',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('YouTube feed unavailable (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
      throw Exception('YouTube feed could not be parsed');
    }

    final items = decoded['videos'];
    if (items is! List) return const [];

    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return ExternalArticle(
        id: (item['id'] ?? '').toString(),
        title: (item['title'] ?? '').toString(),
        url: (item['url'] ?? '').toString(),
        excerpt: (item['excerpt'] ?? '').toString(),
        author: item['author']?.toString() ?? 'HDG Türkiye',
        imageUrl: item['imageUrl']?.toString(),
        publishedAt: DateTime.tryParse((item['publishedAt'] ?? '').toString()),
        tags: const ['youtube'],
        source: 'youtube',
      );
    }).where((a) => a.id.isNotEmpty && a.title.isNotEmpty && a.url.isNotEmpty).toList();
  }
}
