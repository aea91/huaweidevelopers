import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/external_article.dart';
import '../services/forum_articles_service.dart';
import '../services/medium_articles_service.dart';
import '../theme/app_chrome.dart';

enum ArticlesSource { medium, forum }

class ArticlesScreen extends StatefulWidget {
  final ArticlesSource source;

  const ArticlesScreen({super.key, required this.source});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _mediumService = MediumArticlesService();
  final _forumService = ForumArticlesService();

  List<ExternalArticle> _articles = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _total = 0;
  int _forumPage = 1;
  String? _error;

  static const _pageSize = 20;

  bool get _isMedium => widget.source == ArticlesSource.medium;

  String get _title => _isMedium ? 'Medium' : 'Forum';

  String get _subtitle => _isMedium
      ? 'Huawei Developers · Wearables archive'
      : 'Huawei Developer Forum · Recent activity';

  String get _externalHome =>
      _isMedium ? MediumArticlesService.publicationUrl : ForumArticlesService.forumHomeUrl;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_searchQuery.isNotEmpty) return;
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 420) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _articles = [];
      _hasMore = true;
      _total = 0;
      _forumPage = 1;
    });

    try {
      if (_isMedium) {
        final page = await _mediumService.fetchPage(
          offset: 0,
          limit: _pageSize,
          forceRefresh: false,
        );
        if (!mounted) return;
        setState(() {
          _articles = page.articles;
          _total = page.total;
          _hasMore = page.hasMore;
          _isLoading = false;
        });
      } else {
        final articles = await _forumService.fetchArticles(
          pageIndex: 1,
          pageSize: _pageSize,
        );
        if (!mounted) return;
        setState(() {
          _articles = articles;
          _forumPage = 1;
          _total = articles.length;
          _hasMore = articles.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      if (_isMedium) {
        final page = await _mediumService.fetchPage(
          offset: _articles.length,
          limit: _pageSize,
        );
        if (!mounted) return;
        setState(() {
          _articles = [..._articles, ...page.articles];
          _total = page.total;
          _hasMore = page.hasMore;
          _isLoadingMore = false;
        });
      } else {
        final nextPage = _forumPage + 1;
        final more = await _forumService.fetchArticles(
          pageIndex: nextPage,
          pageSize: _pageSize,
        );
        if (!mounted) return;
        final existingIds = _articles.map((a) => a.id).toSet();
        final fresh = more.where((a) => !existingIds.contains(a.id)).toList();
        setState(() {
          _articles = [..._articles, ...fresh];
          _forumPage = nextPage;
          _total = _articles.length;
          _hasMore = more.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  List<ExternalArticle> get _filtered {
    return _articles.where((a) => a.matchesSearch(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppChrome.canvas,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppChrome.listHeader(
      context: context,
      title: _title,
      subtitle: _subtitle,
      icon: _isMedium ? Icons.article_outlined : Icons.forum_outlined,
      actionLabel: _isMedium ? 'Open Medium' : 'Open Forum',
      actionIcon: Icons.open_in_new_rounded,
      onAction: () => _openUrl(_externalHome),
      bottom: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        style: AppChrome.body(),
        decoration: AppChrome.searchDecoration(
          hint: _isMedium ? 'Search Medium articles…' : 'Search forum topics…',
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppChrome.muted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _isMedium ? AppChrome.ink : AppChrome.accent,
            ),
            if (_isMedium) ...[
              const SizedBox(height: 16),
              Text(
                'Loading Wearables archive…\nFirst load may take up to a minute.',
                textAlign: TextAlign.center,
                style: AppChrome.body(color: AppChrome.muted, height: 1.4),
              ),
            ],
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: const Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              Text(
                'Could not load $_title articles',
                style: AppChrome.body(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppChrome.body(color: AppChrome.muted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMedium ? AppChrome.ink : AppChrome.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final articles = _filtered;
    if (articles.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No articles found' : 'No articles match your search',
          style: AppChrome.body(fontSize: 16, color: AppChrome.muted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _isMedium ? AppChrome.ink : AppChrome.accent,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: articles.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            final searching = _searchQuery.isNotEmpty;
            final label = searching
                ? '${articles.length} match${articles.length == 1 ? '' : 'es'}'
                : _isMedium && _total > articles.length
                    ? 'Showing ${articles.length} of $_total'
                    : '${articles.length} article${articles.length == 1 ? '' : 's'}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                label,
                style: AppChrome.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppChrome.muted,
                ),
              ),
            );
          }

          if (index == articles.length + 1) {
            if (_searchQuery.isNotEmpty) {
              return const SizedBox(height: 8);
            }
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (!_hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'All articles loaded',
                  textAlign: TextAlign.center,
                  style: AppChrome.body(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              );
            }
            return const SizedBox(height: 24);
          }

          return _ArticleCard(
            article: articles[index - 1],
            accent: _isMedium ? AppChrome.ink : AppChrome.accent,
            onTap: () => _openArticle(articles[index - 1]),
          );
        },
      ),
    );
  }

  Future<void> _openArticle(ExternalArticle article) async {
    try {
      final url = _isMedium
          ? await _mediumService.resolveArticleUrl(article.url)
          : article.url;
      await _openUrl(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open article: $e')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ArticleCard extends StatelessWidget {
  final ExternalArticle article;
  final Color accent;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      article.imageUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderThumb(),
                    ),
                  )
                else
                  _placeholderThumb(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: AppChrome.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppChrome.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (article.excerpt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          article.excerpt,
                          style: AppChrome.body(
                            fontSize: 13,
                            height: 1.45,
                            color: AppChrome.muted,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (article.author != null)
                            _metaChip(Icons.person_outline, article.author!),
                          if (article.publishedAt != null)
                            _metaChip(
                              Icons.calendar_today_outlined,
                              _formatDate(article.publishedAt!),
                            ),
                          if (article.views != null)
                            _metaChip(Icons.visibility_outlined, '${article.views}'),
                          if (article.likes != null)
                            _metaChip(Icons.thumb_up_alt_outlined, '${article.likes}'),
                          if (article.replies != null)
                            _metaChip(Icons.chat_bubble_outline, '${article.replies}'),
                          ...article.tags.take(3).map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: AppChrome.body(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Open article',
                            style: AppChrome.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16, color: accent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        article.source == 'medium' ? Icons.article_outlined : Icons.forum_outlined,
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
