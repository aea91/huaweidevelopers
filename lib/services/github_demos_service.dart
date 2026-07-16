import 'package:http/http.dart' as http;

import '../config/github_demos_config.dart';
import '../models/github_demo.dart';

/// Loads demos from GitHub using raw.githubusercontent.com instead of the
/// REST API. The raw host is served separately and is not subject to the
/// unauthenticated REST rate limit (60 req/hour), so we can load 200+ READMEs.
class GitHubDemosService {
  static const _rawBase = 'https://raw.githubusercontent.com';
  static const _branches = ['main', 'master'];
  static const _batchSize = 10;

  Future<List<GitHubDemo>> fetchDemos({
    void Function(List<GitHubDemo> demos, bool isComplete)? onProgress,
  }) async {
    final owner = GitHubDemosConfig.owner.trim();
    if (owner.isEmpty) {
      throw Exception('GitHub owner is not configured in github_demos_config.dart');
    }

    final indexEntries = await _fetchIndexEntries(owner);

    final placeholders = indexEntries
        .map((e) => _placeholderDemo(owner, e))
        .toList();
    onProgress?.call(List.unmodifiable(placeholders), false);

    final enriched = <GitHubDemo>[];
    for (var i = 0; i < placeholders.length; i += _batchSize) {
      final batch = placeholders.skip(i).take(_batchSize).toList();
      final results = await Future.wait(batch.map(_enrichWithReadme));
      enriched.addAll(results);
      onProgress?.call(List.unmodifiable(enriched), false);
    }

    onProgress?.call(List.unmodifiable(enriched), true);
    return enriched;
  }

  /// First N Sample Applications with README preview images (for home highlights).
  Future<List<GitHubDemo>> fetchHighlights({int limit = 5}) async {
    final owner = GitHubDemosConfig.owner.trim();
    if (owner.isEmpty) {
      throw Exception('GitHub owner is not configured in github_demos_config.dart');
    }

    final indexEntries = await _fetchIndexEntries(owner);
    final placeholders = indexEntries
        .take(limit)
        .map((e) => _placeholderDemo(owner, e))
        .toList();

    return Future.wait(placeholders.map(_enrichWithReadme));
  }

  Future<List<GitHubIndexEntry>> _fetchIndexEntries(String owner) async {
    final result = await _fetchRawReadme(owner, GitHubDemosConfig.indexRepo);
    if (result == null || result.content.isEmpty) {
      throw Exception('Could not read ${GitHubDemosConfig.indexRepo} README');
    }

    final readme = result.content;
    final sectionMatch = RegExp(
      r'##[^\n]*Sample Applications[^\n]*\n([\s\S]*?)(?=\n## |\Z)',
      caseSensitive: false,
    ).firstMatch(readme);

    final section = sectionMatch?.group(1) ?? readme;
    final rowPattern = RegExp(
      r'\|\s*([^|]+?)\s*\|\s*\[https://github\.com/[^/]+/([a-z0-9._-]+)\]',
      caseSensitive: false,
    );

    final entries = <GitHubIndexEntry>[];
    final seen = <String>{};

    for (final match in rowPattern.allMatches(section)) {
      final title = match.group(1)?.trim() ?? '';
      final repoName = match.group(2)?.trim() ?? '';
      if (title.isEmpty || repoName.isEmpty) continue;
      if (title.toLowerCase() == 'project name') continue;
      if (!seen.add(repoName)) continue;
      entries.add(GitHubIndexEntry(title: title, repoName: repoName));
    }

    if (entries.isEmpty) {
      throw Exception('No sample applications found in ${GitHubDemosConfig.indexRepo}');
    }

    return entries;
  }

  GitHubDemo _placeholderDemo(String owner, GitHubIndexEntry entry) {
    return GitHubDemo(
      name: entry.repoName,
      title: entry.title,
      fullName: '$owner/${entry.repoName}',
      htmlUrl: 'https://github.com/$owner/${entry.repoName}',
      description: null,
      readmeExcerpt: '',
      screenshotUrls: const [],
      kits: const [],
      topics: const [],
      stars: 0,
      defaultBranch: 'main',
    );
  }

  Future<GitHubDemo> _enrichWithReadme(GitHubDemo demo) async {
    final parts = demo.fullName.split('/');
    if (parts.length != 2) return demo;

    final result = await _fetchRawReadme(parts[0], parts[1]);
    if (result == null || result.content.isEmpty) return demo;

    final readme = result.content;
    final branch = result.branch;

    return demo.copyWith(
      readmeExcerpt: _extractDescriptionBeforePreview(readme, demo.description),
      screenshotUrls: _extractPreviewImages(readme, parts[0], parts[1], branch),
      kits: _extractKits(readme, demo.topics),
    );
  }

  Future<_RawReadme?> _fetchRawReadme(String owner, String repo) async {
    for (final branch in _branches) {
      for (final fileName in const ['README.md', 'readme.md', 'README.MD']) {
        final uri = Uri.parse('$_rawBase/$owner/$repo/$branch/$fileName');
        try {
          final response = await http.get(uri).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
            return _RawReadme(content: response.body, branch: branch);
          }
        } catch (_) {
          // Try next branch / filename.
        }
      }
    }
    return null;
  }

  String _extractDescriptionBeforePreview(String markdown, String? fallbackDescription) {
    final previewIndex = RegExp(r'^#+\s*Preview\s*$', multiLine: true, caseSensitive: false)
        .firstMatch(markdown)
        ?.start;

    var body = previewIndex == null ? markdown : markdown.substring(0, previewIndex);

    body = body.replaceAll(RegExp(r'^>.*$', multiLine: true), '');
    body = body.replaceFirst(RegExp(r'^#\s+[^\n]+\n?'), '');

    return _cleanText(body, fallbackDescription);
  }

  List<String> _extractPreviewImages(
    String markdown,
    String owner,
    String repo,
    String branch,
  ) {
    final previewSection = RegExp(
      r'#+\s*Preview\s*\n([\s\S]*?)(?=\n#+\s|\Z)',
      caseSensitive: false,
    ).firstMatch(markdown)?.group(1);

    if (previewSection == null || previewSection.trim().isEmpty) {
      return _extractScreenshotUrls(markdown, owner, repo, branch).take(6).toList();
    }

    return _extractScreenshotUrls(previewSection, owner, repo, branch).take(8).toList();
  }

  List<String> _extractScreenshotUrls(
    String markdown,
    String owner,
    String repo,
    String branch,
  ) {
    final urls = <String>[];
    final seen = <String>{};

    void addUrl(String raw) {
      final resolved = _resolveImageUrl(raw.trim(), owner, repo, branch);
      if (resolved == null) return;
      if (!_isImageUrl(resolved)) return;
      if (seen.add(resolved)) {
        urls.add(resolved);
      }
    }

    final markdownImages = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
    for (final match in markdownImages.allMatches(markdown)) {
      addUrl(match.group(1) ?? '');
    }

    final htmlImages = RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false);
    for (final match in htmlImages.allMatches(markdown)) {
      addUrl(match.group(1) ?? '');
    }

    return urls;
  }

  String? _resolveImageUrl(String raw, String owner, String repo, String branch) {
    if (raw.isEmpty) return null;

    var url = raw;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url
          .replaceFirst(
            'https://github.com/$owner/$repo/blob/$branch/',
            '$_rawBase/$owner/$repo/$branch/',
          )
          .replaceFirst(
            'https://github.com/$owner/$repo/raw/$branch/',
            '$_rawBase/$owner/$repo/$branch/',
          );
    }

    var path = url;
    if (path.startsWith('./')) path = path.substring(2);
    if (path.startsWith('/')) path = path.substring(1);

    return '$_rawBase/$owner/$repo/$branch/${Uri.encodeFull(path)}';
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  String _cleanText(String text, String? fallbackDescription) {
    var cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp(r'`[^`]+`'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*#+\s*.+$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) {
      return (fallbackDescription ?? '').trim();
    }

    if (cleaned.length <= 240) return cleaned;
    return '${cleaned.substring(0, 237).trim()}...';
  }

  List<String> _extractKits(String markdown, List<String> topics) {
    final kits = <String>{...topics};

    final kitsSection = RegExp(
      r'Libraries/Kits\s*:?\s*\n([\s\S]*?)(?=\n#|\n\*\*|\Z)',
      caseSensitive: false,
    ).firstMatch(markdown)?.group(1);

    if (kitsSection != null) {
      final bullets = RegExp(r'^\s*[-*+]\s+(.+)$', multiLine: true);
      for (final item in bullets.allMatches(kitsSection)) {
        final value = _cleanKitLabel(item.group(1) ?? '');
        if (value.isNotEmpty) kits.add(value);
      }
    }

    final stackSection = RegExp(
      r'##\s*Stack\s*\n([\s\S]*?)(?=\n##|\n# |\Z)',
      caseSensitive: false,
    ).firstMatch(markdown)?.group(1);

    if (stackSection != null) {
      final lines = RegExp(r'\*\*([^*]+)\*\*\s*:\s*([^\n]+)');
      for (final match in lines.allMatches(stackSection)) {
        final label = match.group(1)?.trim() ?? '';
        final value = match.group(2)?.trim() ?? '';
        if (label.isNotEmpty && value.isNotEmpty) {
          kits.add('$label: $value');
        }
      }
    }

    final inlineKits = RegExp(r'@(?:kit|ohos)/[\w.-]+', caseSensitive: false);
    for (final match in inlineKits.allMatches(markdown)) {
      kits.add(match.group(0) ?? '');
    }

    return kits.take(12).toList();
  }

  String _cleanKitLabel(String raw) {
    return raw
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .trim();
  }
}

class _RawReadme {
  final String content;
  final String branch;

  const _RawReadme({required this.content, required this.branch});
}
