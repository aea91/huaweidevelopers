class ExternalArticle {
  final String id;
  final String title;
  final String url;
  final String excerpt;
  final String? author;
  final String? imageUrl;
  final DateTime? publishedAt;
  final List<String> tags;
  final int? views;
  final int? likes;
  final int? replies;
  final String source; // medium | forum

  const ExternalArticle({
    required this.id,
    required this.title,
    required this.url,
    required this.excerpt,
    required this.source,
    this.author,
    this.imageUrl,
    this.publishedAt,
    this.tags = const [],
    this.views,
    this.likes,
    this.replies,
  });

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        excerpt.toLowerCase().contains(q) ||
        (author ?? '').toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }
}
