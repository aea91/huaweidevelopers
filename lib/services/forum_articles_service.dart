import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/external_article.dart';

class ForumArticlesService {
  static const forumHomeUrl =
      'https://forums.developer.huawei.com/forumPortal/en/home?sorter=4&hash=mrkvzpfs';
  static const _apiUrl =
      'https://forums.developer.huawei.com/consumer/partnerforumserviceoversea/v1/open/getTopicListWithFilter';

  Future<List<ExternalArticle>> fetchArticles({
    int pageIndex = 1,
    int pageSize = 20,
  }) async {
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'pageIndex': pageIndex,
            'pageSize': pageSize,
            'sorter': 4, // RecentActivity
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Forum feed unavailable (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Forum feed could not be parsed');
    }
    if (decoded['code'] != 0) {
      throw Exception(decoded['message']?.toString() ?? 'Forum request failed');
    }

    final items = decoded['resultList'];
    if (items is! List) return [];

    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final tid = (item['tid'] ?? '').toString();
      final title = (item['title'] ?? '').toString().trim();
      final tags = <String>[];
      final tagList = item['topicTagInfoList'];
      if (tagList is List) {
        for (final tag in tagList) {
          if (tag is Map && tag['tagName'] != null) {
            tags.add(tag['tagName'].toString());
          }
        }
      }

      return ExternalArticle(
        id: tid,
        title: title,
        url: 'https://forums.developer.huawei.com/forumPortal/en/topic/$tid',
        excerpt: _excerptFromHtml((item['content'] ?? '').toString()),
        author: null,
        imageUrl: _firstUploadImage(item['uploadInfoList']),
        publishedAt: _parseForumDate((item['createTime'] ?? item['dateline'] ?? '').toString()),
        tags: tags,
        views: (item['views'] as num?)?.toInt(),
        likes: (item['likes'] as num?)?.toInt(),
        replies: (item['replies'] as num?)?.toInt(),
        source: 'forum',
      );
    }).where((a) => a.title.isNotEmpty && a.id.isNotEmpty).toList();
  }

  String? _firstUploadImage(dynamic uploads) {
    if (uploads is! List) return null;
    for (final item in uploads) {
      if (item is! Map) continue;
      final url = (item['url'] ?? item['fileUrl'] ?? item['downloadUrl'] ?? '').toString();
      if (url.startsWith('http')) return url;
    }
    return null;
  }

  DateTime? _parseForumDate(String raw) {
    // Format: yyyyMMddHHmmss
    if (RegExp(r'^\d{14}$').hasMatch(raw)) {
      return DateTime.tryParse(
        '${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6, 8)} '
        '${raw.substring(8, 10)}:${raw.substring(10, 12)}:${raw.substring(12, 14)}',
      );
    }
    return DateTime.tryParse(raw);
  }

  String _excerptFromHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    if (text.length <= 180) return text;
    return '${text.substring(0, 177).trim()}...';
  }
}
