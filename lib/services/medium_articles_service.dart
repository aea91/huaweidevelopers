import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/external_article.dart';

class MediumArticlePage {
  final List<ExternalArticle> articles;
  final int total;
  final int offset;
  final bool hasMore;

  const MediumArticlePage({
    required this.articles,
    required this.total,
    required this.offset,
    required this.hasMore,
  });
}

class MediumArticlesService {
  static const publicationUrl =
      'https://medium.com/huawei-developers/all?topic=wearables';

  static const _archiveFunctionUrl =
      'https://us-central1-arkuibuilder.cloudfunctions.net/getMediumWearableArticles';
  static const _resolveFunctionUrl =
      'https://us-central1-arkuibuilder.cloudfunctions.net/resolveGoogleNewsUrl';

  static const pageSize = 20;

  /// Medium RSS returns max ~10 items per feed. Local fallback merges several
  /// wearable-related publication tag feeds.
  static const _strictTagFeeds = <String>[
    'https://medium.com/feed/huawei-developers/tagged/wearables',
    'https://medium.com/feed/huawei-developers/tagged/harmonyos-next-wearables',
    'https://medium.com/feed/huawei-developers/tagged/smartwatch',
    'https://medium.com/feed/huawei-developers/tagged/litewearable',
    'https://medium.com/feed/huawei-developers/tagged/lite-wearable',
    'https://medium.com/feed/huawei-developers/tagged/wear-engine',
    'https://medium.com/feed/huawei-developers/tagged/wearengine',
    'https://medium.com/feed/huawei-developers/tagged/huawei-watch',
    'https://medium.com/feed/huawei-developers/tagged/watch5',
    'https://medium.com/feed/huawei-developers/tagged/watch',
  ];

  static const _filteredFeeds = <String>[
    'https://medium.com/feed/huawei-developers/tagged/harmonyos-next',
    'https://medium.com/feed/huawei-developers',
  ];

  static const _wearableKeywords = <String>[
    'wearable',
    'wearables',
    'smartwatch',
    'smart watch',
    'litewearable',
    'lite-wearable',
    'wear engine',
    'wearengine',
    'watch5',
    'huawei watch',
    'watch face',
    'crown gesture',
  ];

  Future<MediumArticlePage> fetchPage({
    int offset = 0,
    int limit = pageSize,
    bool forceRefresh = false,
  }) async {
    try {
      final page = await _fetchCloudPage(
        offset: offset,
        limit: limit,
        forceRefresh: forceRefresh,
      );
      if (page.articles.isNotEmpty || page.total > 0) {
        return page;
      }
    } catch (_) {
      // Fall back to client-side multi-feed merge.
    }

    final all = await _fetchLocalFallback();
    final slice = all.skip(offset).take(limit).toList();
    return MediumArticlePage(
      articles: slice,
      total: all.length,
      offset: offset,
      hasMore: offset + slice.length < all.length,
    );
  }

  /// Legacy full fetch (local tooling / fallbacks).
  Future<List<ExternalArticle>> fetchArticles({bool forceRefresh = false}) async {
    final first = await fetchPage(offset: 0, limit: 50, forceRefresh: forceRefresh);
    if (!first.hasMore) return first.articles;

    final all = [...first.articles];
    var offset = first.articles.length;
    while (offset < first.total) {
      final page = await fetchPage(offset: offset, limit: 50);
      if (page.articles.isEmpty) break;
      all.addAll(page.articles);
      offset += page.articles.length;
      if (!page.hasMore) break;
    }
    return all;
  }

  /// If the listed URL is still a Google News redirect, resolve to Medium.
  Future<String> resolveArticleUrl(String url) async {
    if (!url.contains('news.google.com')) return url;

    final uri = Uri.parse(_resolveFunctionUrl).replace(
      queryParameters: {'url': url},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Could not open Medium article (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['status'] != 'ok') {
      throw Exception('Could not resolve Medium article URL');
    }
    final resolved = decoded['url']?.toString() ?? '';
    if (resolved.isEmpty) {
      throw Exception('Empty Medium article URL');
    }
    return resolved;
  }

  Future<MediumArticlePage> _fetchCloudPage({
    required int offset,
    required int limit,
    required bool forceRefresh,
  }) async {
    final params = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
    };
    if (forceRefresh) params['refresh'] = '1';

    final uri = Uri.parse(_archiveFunctionUrl).replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 280));
    if (response.statusCode != 200) {
      throw Exception('Medium archive unavailable (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
      throw Exception('Medium archive could not be parsed');
    }

    final items = decoded['articles'];
    if (items is! List) {
      return const MediumArticlePage(
        articles: [],
        total: 0,
        offset: 0,
        hasMore: false,
      );
    }

    final articles = items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return ExternalArticle(
        id: (item['id'] ?? item['url'] ?? '').toString(),
        title: (item['title'] ?? '').toString(),
        url: (item['url'] ?? '').toString(),
        excerpt: (item['excerpt'] ?? '').toString(),
        author: item['author']?.toString(),
        imageUrl: item['imageUrl']?.toString(),
        publishedAt: DateTime.tryParse((item['publishedAt'] ?? '').toString()),
        tags: List<String>.from(item['tags'] ?? const []),
        source: 'medium',
      );
    }).where((a) => a.title.isNotEmpty && a.url.isNotEmpty).toList();

    final total = (decoded['total'] as num?)?.toInt() ?? articles.length;
    final hasMore = decoded['hasMore'] == true || offset + articles.length < total;

    return MediumArticlePage(
      articles: articles,
      total: total,
      offset: offset,
      hasMore: hasMore,
    );
  }

  Future<List<ExternalArticle>> _fetchLocalFallback() async {
    final results = await Future.wait([
      ..._strictTagFeeds.map((url) => _fetchFeed(url, requireWearableMatch: false)),
      ..._filteredFeeds.map((url) => _fetchFeed(url, requireWearableMatch: true)),
    ]);

    final byId = <String, ExternalArticle>{};
    for (final articles in results) {
      for (final article in articles) {
        byId.putIfAbsent(article.id, () => article);
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    if (merged.isEmpty) {
      throw Exception('No Medium wearable articles found');
    }

    return merged;
  }

  Future<List<ExternalArticle>> _fetchFeed(
    String feedUrl, {
    required bool requireWearableMatch,
  }) async {
    try {
      final uri = Uri.parse('https://api.rss2json.com/v1/api.json').replace(
        queryParameters: {'rss_url': feedUrl},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
        return const [];
      }

      final items = decoded['items'];
      if (items is! List) return const [];

      final articles = <ExternalArticle>[];
      for (final raw in items.whereType<Map>()) {
        final item = Map<String, dynamic>.from(raw);
        final html = (item['description'] ?? item['content'] ?? '').toString();
        final thumbnail = (item['thumbnail'] ?? '').toString().trim();
        final imageUrl = thumbnail.isNotEmpty ? thumbnail : _firstImage(html);
        final link = _cleanUrl((item['link'] ?? '').toString());
        final title = _decodeHtml((item['title'] ?? '').toString());
        final tags = List<String>.from(item['categories'] ?? const []);
        final author = (item['author'] ?? '').toString().trim();

        if (title.isEmpty || link.isEmpty) continue;
        if (requireWearableMatch && !_isWearableRelated(title, tags, html)) {
          continue;
        }

        articles.add(
          ExternalArticle(
            id: _normalizeId((item['guid'] ?? link).toString()),
            title: title,
            url: link,
            excerpt: _excerptFromHtml(html),
            author: author.isEmpty ? null : author,
            imageUrl: imageUrl,
            publishedAt: DateTime.tryParse((item['pubDate'] ?? '').toString()),
            tags: tags,
            source: 'medium',
          ),
        );
      }
      return articles;
    } catch (_) {
      return const [];
    }
  }

  bool _isWearableRelated(String title, List<String> tags, String html) {
    final blob = '$title ${tags.join(' ')} $html'.toLowerCase();
    return _wearableKeywords.any(blob.contains);
  }

  String _normalizeId(String value) {
    final match = RegExp(r'(?:/p/|-)([a-f0-9]{8,})$').firstMatch(value);
    if (match != null) return match.group(1)!;
    return value;
  }

  String _cleanUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(queryParameters: {}).toString().replaceAll(RegExp(r'\?$'), '');
  }

  String? _firstImage(String html) {
    final match = RegExp(
      r'''<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1);
  }

  String _excerptFromHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    text = _decodeHtml(text);
    if (text.length <= 180) return text;
    return '${text.substring(0, 177).trim()}...';
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }
}
