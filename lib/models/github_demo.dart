class GitHubDemo {
  final String name;
  final String title;
  final String fullName;
  final String htmlUrl;
  final String? description;
  final String readmeExcerpt;
  final List<String> screenshotUrls;
  final List<String> kits;
  final List<String> topics;
  final int stars;
  final String defaultBranch;
  final DateTime? updatedAt;

  const GitHubDemo({
    required this.name,
    required this.title,
    required this.fullName,
    required this.htmlUrl,
    required this.description,
    required this.readmeExcerpt,
    required this.screenshotUrls,
    required this.kits,
    required this.topics,
    required this.stars,
    required this.defaultBranch,
    this.updatedAt,
  });

  String get displayDescription {
    if (readmeExcerpt.isNotEmpty) return readmeExcerpt;
    return description ?? '';
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        title.toLowerCase().contains(q) ||
        (description ?? '').toLowerCase().contains(q) ||
        readmeExcerpt.toLowerCase().contains(q) ||
        kits.any((k) => k.toLowerCase().contains(q)) ||
        topics.any((t) => t.toLowerCase().contains(q));
  }

  GitHubDemo copyWith({
    String? readmeExcerpt,
    List<String>? screenshotUrls,
    List<String>? kits,
  }) {
    return GitHubDemo(
      name: name,
      title: title,
      fullName: fullName,
      htmlUrl: htmlUrl,
      description: description,
      readmeExcerpt: readmeExcerpt ?? this.readmeExcerpt,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
      kits: kits ?? this.kits,
      topics: topics,
      stars: stars,
      defaultBranch: defaultBranch,
      updatedAt: updatedAt,
    );
  }
}

class GitHubIndexEntry {
  final String title;
  final String repoName;

  const GitHubIndexEntry({required this.title, required this.repoName});
}
