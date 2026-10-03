import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/external_article.dart';
import '../models/github_demo.dart';
import '../models/widget_showcase.dart';
import '../services/firestore_service.dart';
import '../services/github_demos_service.dart';
import '../services/linkedin_posts_service.dart';
import '../services/medium_articles_service.dart';
import '../services/visit_tracking_service.dart';
import '../services/youtube_videos_service.dart';
import '../widgets/code_viewer.dart';
import '../widgets/widget_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFFFFFFF);
  static const _canvas = Color(0xFFF8FAFC);
  static const _accent = Color(0xFFE11D48);

  final _firestoreService = FirestoreService();
  final _mediumService = MediumArticlesService();
  final _demosService = GitHubDemosService();
  final _linkedinService = LinkedInPostsService();
  final _youtubeService = YouTubeVideosService();
  final _searchController = TextEditingController();

  // One shared stream instead of several concurrent listeners.
  late final Stream<List<WidgetShowcase>> _widgetsStream;
  late final Stream<VisitTotals> _visitTotalsStream;
  final _gridKey = GlobalKey();

  String selectedMainCategory = 'All';
  String selectedCategory = 'All';
  String sortBy = 'Newest';
  String searchQuery = '';
  List<ExternalArticle> _mediumHighlights = [];
  List<GitHubDemo> _demoHighlights = [];
  List<ExternalArticle> _linkedinHighlights = [];
  List<ExternalArticle> _youtubeHighlights = [];
  int _exploreTab = 0;

  static const List<String> _platforms = [
    'All',
    'Mobile',
    'Smart Wearable',
    'PC (2in1)',
  ];

  static const List<String> _sortOptions = ['Newest', 'Oldest', 'A–Z'];

  String _getProxyUrl(String firebaseUrl) {
    if (!firebaseUrl.startsWith('http')) return firebaseUrl;
    try {
      if (firebaseUrl.contains('firebasestorage.googleapis.com')) {
        final pathMatch = RegExp(r'/o/(.+?)\?').firstMatch(firebaseUrl);
        if (pathMatch != null) {
          final encodedPath = pathMatch.group(1);
          final decodedPath = Uri.decodeComponent(encodedPath!);
          return 'https://us-central1-arkuibuilder.cloudfunctions.net/proxyImage?path=$decodedPath';
        }
      }
    } catch (_) {}
    return firebaseUrl;
  }

  @override
  void initState() {
    super.initState();
    _widgetsStream = _firestoreService.getWidgets();
    _visitTotalsStream = VisitTrackingService().watchTotals();
    _loadMediumHighlights();
    _loadDemoHighlights();
    _loadLinkedInHighlights();
    _loadYouTubeHighlights();
  }

  Future<void> _loadMediumHighlights() async {
    try {
      final page = await _mediumService.fetchPage(offset: 0, limit: 12);
      final withImages = page.articles
          .where((a) => (a.imageUrl ?? '').trim().isNotEmpty)
          .toList();
      final seen = <String>{};
      final picks = <ExternalArticle>[];
      for (final article in [...withImages, ...page.articles]) {
        if (!seen.add(article.id)) continue;
        picks.add(article);
        if (picks.length >= 5) break;
      }
      if (!mounted || picks.isEmpty) return;
      setState(() => _mediumHighlights = picks);
    } catch (_) {}
  }

  Future<void> _loadDemoHighlights() async {
    try {
      final demos = await _demosService.fetchHighlights(limit: 5);
      if (!mounted || demos.isEmpty) return;
      setState(() => _demoHighlights = demos);
    } catch (_) {}
  }

  Future<void> _loadLinkedInHighlights() async {
    try {
      final posts = await _linkedinService.fetchHighlights(limit: 8);
      final withImages = posts
          .where((p) => (p.imageUrl ?? '').trim().isNotEmpty)
          .toList();
      final seen = <String>{};
      final picks = <ExternalArticle>[];
      for (final post in [...withImages, ...posts]) {
        if (!seen.add(post.id)) continue;
        picks.add(post);
        if (picks.length >= 5) break;
      }
      if (!mounted || picks.isEmpty) return;
      setState(() => _linkedinHighlights = picks);
    } catch (_) {}
  }

  Future<void> _loadYouTubeHighlights() async {
    try {
      final videos = await _youtubeService.fetchHighlights(limit: 5);
      if (!mounted || videos.isEmpty) return;
      setState(() => _youtubeHighlights = videos);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---- data helpers -----------------------------------------------------

  List<String> _categoriesFor(List<WidgetShowcase> all) {
    final cats = <String>{'All'};
    for (final w in all) {
      if (selectedMainCategory == 'All' || w.mainCategory == selectedMainCategory) {
        cats.add(w.category);
      }
    }
    final list = cats.toList();
    list.sort((a, b) => a == 'All' ? -1 : (b == 'All' ? 1 : a.compareTo(b)));
    return list;
  }

  int _platformCount(List<WidgetShowcase> all, String platform) {
    if (platform == 'All') return all.length;
    return all.where((w) => w.mainCategory == platform).length;
  }

  List<WidgetShowcase> _applyFilters(List<WidgetShowcase> all) {
    final q = searchQuery.toLowerCase();
    var list = all.where((w) {
      final matchPlatform =
          selectedMainCategory == 'All' || w.mainCategory == selectedMainCategory;
      final matchCategory = selectedCategory == 'All' || w.category == selectedCategory;
      final matchSearch = q.isEmpty ||
          w.title.toLowerCase().contains(q) ||
          w.description.toLowerCase().contains(q) ||
          w.mainCategory.toLowerCase().contains(q) ||
          w.category.toLowerCase().contains(q) ||
          w.tags.any((t) => t.toLowerCase().contains(q));
      return matchPlatform && matchCategory && matchSearch;
    }).toList();

    // Stream already arrives newest-first (orderBy createdAt desc).
    if (sortBy == 'Oldest') {
      list = list.reversed.toList();
    } else if (sortBy == 'A–Z') {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }

  /// 12345 -> "12,345"
  String _formatCount(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  bool _isWearable(WidgetShowcase w) => w.mainCategory.contains('Wearable');

  IconData _platformIcon(WidgetShowcase w) {
    if (w.mainCategory.contains('Wearable')) return Icons.watch_rounded;
    if (w.mainCategory.startsWith('PC')) return Icons.laptop_mac_rounded;
    return Icons.smartphone_rounded;
  }

  Color _mediaBg(WidgetShowcase w) =>
      _isWearable(w) ? const Color(0xFF0B0B10) : const Color(0xFFF1F5F9);

  TextStyle get _display => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w700,
    color: _ink,
    letterSpacing: -0.6,
  );

  TextStyle get _body => GoogleFonts.plusJakartaSans(color: _ink);

  // ---- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1024;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          _buildTopBar(context, isMobile),
          Expanded(
            child: StreamBuilder<List<WidgetShowcase>>(
              stream: _widgetsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _ink));
                }

                final all = snapshot.data ?? const <WidgetShowcase>[];
                final filtered = _applyFilters(all);
                final newIds = all.take(12).map((w) => w.id).toSet();

                return Column(
                  children: [
                    _buildFilterStrip(isMobile, all, filtered.length),
                    Expanded(
                      child: isMobile
                          ? _buildMobileBody(all, filtered, newIds)
                          : _buildDesktopBody(all, filtered, newIds, isTablet),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- top bar ----------------------------------------------------------

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    final primary = _primaryNav(context);
    final more = _moreNav(context);
    final nav = Wrap(
      alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in primary)
          _NavPill(
            label: item.label,
            icon: item.icon,
            emphasis: item.emphasis,
            onTap: item.onTap,
          ),
        _MoreMenu(items: more),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 14, isMobile ? 16 : 28, 14),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildBrandMark(), const SizedBox(height: 12), nav],
                )
              : Row(
                  children: [
                    _buildBrandMark(),
                    const SizedBox(width: 20),
                    Expanded(child: nav),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBrandMark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ArkUI Build', style: _display.copyWith(fontSize: 20, height: 1.1)),
            Text(
              'HarmonyOS components',
              style: _body.copyWith(fontSize: 11, color: _muted, height: 1.2),
            ),
          ],
        ),
      ],
    );
  }

  List<_NavItem> _primaryNav(BuildContext context) => [
    _NavItem(
      label: 'Playground',
      icon: Icons.terminal_rounded,
      emphasis: true,
      onTap: () => Navigator.pushNamed(context, '/playground'),
    ),
    _NavItem(
      label: 'App Builder',
      icon: Icons.rocket_launch_rounded,
      onTap: () => Navigator.pushNamed(context, '/app-builder'),
    ),
    _NavItem(
      label: 'Course',
      icon: Icons.school_rounded,
      onTap: () => Navigator.pushNamed(context, '/course'),
    ),
  ];

  List<_NavItem> _moreNav(BuildContext context) => [
    _NavItem(label: 'Roadmap', icon: Icons.route_rounded, onTap: () => Navigator.pushNamed(context, '/roadmap')),
    _NavItem(label: 'Theme', icon: Icons.palette_outlined, onTap: () => Navigator.pushNamed(context, '/theme-builder')),
    _NavItem(label: 'Class', icon: Icons.code_rounded, onTap: () => Navigator.pushNamed(context, '/class-builder')),
    _NavItem(label: 'Demos', icon: Icons.apps_rounded, onTap: () => Navigator.pushNamed(context, '/example-demos')),
    _NavItem(label: 'Medium', icon: Icons.article_outlined, onTap: () => Navigator.pushNamed(context, '/medium')),
    _NavItem(label: 'Forum', icon: Icons.forum_outlined, onTap: () => Navigator.pushNamed(context, '/forum')),
    _NavItem(label: 'Managers', icon: Icons.manage_accounts_outlined, onTap: () => Navigator.pushNamed(context, '/managers')),
  ];

  // ---- filter strip -----------------------------------------------------

  Widget _buildFilterStrip(bool isMobile, List<WidgetShowcase> all, int count) {
    final platformChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in _platforms)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PlatformChip(
                label: p == 'All' ? 'All' : p,
                count: _platformCount(all, p),
                selected: selectedMainCategory == p,
                onTap: () => setState(() {
                  selectedMainCategory = p;
                  selectedCategory = 'All';
                }),
              ),
            ),
        ],
      ),
    );

    final categories = _categoriesFor(all);
    final categoryDropdown = _buildDropdown(
      label: 'Category',
      value: categories.contains(selectedCategory) ? selectedCategory : 'All',
      items: categories,
      onChanged: (v) => setState(() => selectedCategory = v ?? 'All'),
    );
    final sortDropdown = _buildDropdown(
      label: 'Sort',
      value: sortBy,
      items: _sortOptions,
      onChanged: (v) => setState(() => sortBy = v ?? 'Newest'),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 12, isMobile ? 16 : 28, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: categoryDropdown),
                        const SizedBox(width: 10),
                        Expanded(child: sortDropdown),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchBar()),
                    const SizedBox(width: 12),
                    SizedBox(width: 220, child: categoryDropdown),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: sortDropdown),
                  ],
                ),
          const SizedBox(height: 12),
          platformChips,
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => searchQuery = value),
      style: _body.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search widgets, platforms, tags…',
        hintStyle: _body.copyWith(fontSize: 14, color: const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
              ),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ink, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _body.copyWith(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ink, width: 1.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
          style: _body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          dropdownColor: _surface,
          borderRadius: BorderRadius.circular(12),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis, style: _body.copyWith(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---- desktop body -----------------------------------------------------

  Widget _buildDesktopBody(
    List<WidgetShowcase> all,
    List<WidgetShowcase> filtered,
    Set<String> newIds,
    bool isTablet,
  ) {
    if (filtered.isEmpty) return _emptyState();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHero(all, filtered.length)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: _buildExploreSection(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
          sliver: SliverToBoxAdapter(child: _buildGridHeader(filtered.length)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 2 : 3,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: isTablet ? 0.92 : 0.95,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildGridCard(filtered[index], newIds.contains(filtered[index].id)),
              childCount: filtered.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }

  Widget _buildGridHeader(int count) {
    return Row(
      key: _gridKey,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Components', style: _display.copyWith(fontSize: 22)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line),
          ),
          child: Text('$count', style: _body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: _muted)),
        ),
      ],
    );
  }

  // ---- mobile body ------------------------------------------------------

  Widget _buildMobileBody(
    List<WidgetShowcase> all,
    List<WidgetShowcase> filtered,
    Set<String> newIds,
  ) {
    if (filtered.isEmpty) return _emptyState();

    final hasExplore = _exploreEntries().isNotEmpty;
    final leadCount = 1 + (hasExplore ? 1 : 0); // hero + optional explore

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: leadCount + filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) return _buildHero(all, filtered.length, compact: true);
        if (hasExplore && index == 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildExploreSection(),
          );
        }
        return _buildMobileCard(
          filtered[index - leadCount],
          newIds.contains(filtered[index - leadCount].id),
        );
      },
    );
  }

  // ---- hero -------------------------------------------------------------

  Widget _buildHero(List<WidgetShowcase> all, int count, {bool compact = false}) {
    final mobileCount = _platformCount(all, 'Mobile');
    final wearCount = _platformCount(all, 'Smart Wearable');
    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 0 : 28, compact ? 0 : 24, compact ? 0 : 28, 0),
      padding: EdgeInsets.all(compact ? 22 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hand-crafted ArkTS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: compact ? 26 : 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Browse production-ready HarmonyOS widgets for phone and watch, copy the ArkTS, and ship faster.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 14 : 15,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroStat(label: 'Components', value: '$count'),
                  _HeroStat(label: 'Mobile', value: '$mobileCount'),
                  _HeroStat(label: 'Wearable', value: '$wearCount'),
                  StreamBuilder<VisitTotals>(
                    stream: _visitTotalsStream,
                    builder: (context, snapshot) {
                      // Hide until loaded (or on error) rather than flash "0".
                      final visits = snapshot.data?.visits ?? 0;
                      if (visits <= 0) return const SizedBox.shrink();
                      return _HeroStat(label: 'Visits', value: _formatCount(visits));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroButton(
                    label: 'Browse components',
                    icon: Icons.grid_view_rounded,
                    filled: true,
                    onTap: () {
                      final ctx = _gridKey.currentContext;
                      if (ctx != null) {
                        Scrollable.ensureVisible(
                          ctx,
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeInOutCubic,
                          alignment: 0.05,
                        );
                      }
                    },
                  ),
                  _HeroButton(
                    label: 'Open Playground',
                    icon: Icons.terminal_rounded,
                    filled: false,
                    onTap: () => Navigator.pushNamed(context, '/playground'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- explore section (tabbed) ----------------------------------------

  List<_ExploreEntry> _exploreEntries() {
    return <_ExploreEntry>[
      if (_demoHighlights.isNotEmpty)
        _ExploreEntry(
          label: 'Sample Apps',
          onSeeAll: () => Navigator.pushNamed(context, '/example-demos'),
          carousel: _horizontalStrip(
            itemCount: _demoHighlights.length,
            itemBuilder: (i) => _DemoCard(demo: _demoHighlights[i], onTap: () => _openDemo(_demoHighlights[i])),
          ),
        ),
      if (_mediumHighlights.isNotEmpty)
        _ExploreEntry(
          label: 'Medium',
          onSeeAll: () => Navigator.pushNamed(context, '/medium'),
          carousel: _horizontalStrip(
            itemCount: _mediumHighlights.length,
            itemBuilder: (i) => _MediumCard(
              article: _mediumHighlights[i],
              onTap: () => _openMediumArticle(_mediumHighlights[i]),
            ),
          ),
        ),
      if (_linkedinHighlights.isNotEmpty)
        _ExploreEntry(
          label: 'LinkedIn',
          onSeeAll: () => _openUrl(LinkedInPostsService.companyPostsUrl),
          carousel: _horizontalStrip(
            itemCount: _linkedinHighlights.length,
            itemBuilder: (i) => _LinkedInCard(post: _linkedinHighlights[i], onTap: () => _openUrl(_linkedinHighlights[i].url)),
          ),
        ),
      if (_youtubeHighlights.isNotEmpty)
        _ExploreEntry(
          label: 'YouTube',
          onSeeAll: () => _openUrl(YouTubeVideosService.channelStreamsUrl),
          carousel: _horizontalStrip(
            itemCount: _youtubeHighlights.length,
            itemBuilder: (i) => _YouTubeCard(video: _youtubeHighlights[i], onTap: () => _openUrl(_youtubeHighlights[i].url)),
          ),
        ),
    ];
  }

  Widget _buildExploreSection() {
    final entries = _exploreEntries();
    if (entries.isEmpty) return const SizedBox.shrink();
    final active = _exploreTab.clamp(0, entries.length - 1);
    final current = entries[active];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Explore more', style: _display.copyWith(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: current.onSeeAll,
              child: Text('See all',
                  style: _body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: _accent)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < entries.length; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 8),
                  child: _ExploreTabChip(
                    label: entries[i].label,
                    selected: i == active,
                    onTap: () => setState(() => _exploreTab = i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        current.carousel,
      ],
    );
  }

  Widget _horizontalStrip({required int itemCount, required Widget Function(int) itemBuilder}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final narrow = constraints.maxWidth < 720;
        final visibleCount = narrow ? 1.15 : 5.0;
        final cardSize = (constraints.maxWidth - gap * (visibleCount - 1)) / visibleCount;
        return SizedBox(
          height: cardSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (context, index) =>
                SizedBox(width: cardSize, height: cardSize, child: itemBuilder(index)),
          ),
        );
      },
    );
  }

  Future<void> _openMediumArticle(ExternalArticle article) async {
    try {
      final url = await _mediumService.resolveArticleUrl(article.url);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open article: $e')));
    }
  }

  Future<void> _openDemo(GitHubDemo demo) async {
    final uri = Uri.parse(demo.htmlUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ---- cards ------------------------------------------------------------

  Widget _cardMedia(WidgetShowcase widget, {required double iconSize}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: _mediaBg(widget),
          child: widget.gifPath.startsWith('http')
              ? Image.network(
                  _getProxyUrl(widget.gifPath),
                  fit: BoxFit.contain,
                  cacheWidth: 480,
                  filterQuality: FilterQuality.low,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.image_outlined, size: iconSize, color: const Color(0xFFCBD5E1)),
                  ),
                )
              : Center(child: Icon(Icons.image_outlined, size: iconSize, color: const Color(0xFFCBD5E1))),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: _Badge(text: widget.mainCategory, icon: _platformIcon(widget), dark: _isWearable(widget)),
        ),
      ],
    );
  }

  Widget _buildGridCard(WidgetShowcase widget, bool isNew) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openWidgetDialog(widget),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _cardMedia(widget, iconSize: 42),
                      if (isNew)
                        const Positioned(right: 10, top: 10, child: _NewBadge()),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: _body.copyWith(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            widget.description,
                            style: _body.copyWith(fontSize: 12.5, color: _muted, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Tag(label: widget.category),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard(WidgetShowcase widget, bool isNew) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openWidgetSheet(widget),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: _cardMedia(widget, iconSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: _body.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew) ...[const SizedBox(width: 8), const _NewBadge()],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: _body.copyWith(fontSize: 12, color: _muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _Tag(label: widget.category),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- detail (desktop dialog + mobile sheet) ---------------------------

  void _openWidgetDialog(WidgetShowcase widget) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        final h = MediaQuery.of(ctx).size.height;
        return Dialog(
          backgroundColor: _surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1040, maxHeight: h * 0.86),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: _display.copyWith(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(widget.description, style: _body.copyWith(fontSize: 14, color: _muted, height: 1.4)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: _muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [_Badge(text: widget.mainCategory, icon: _platformIcon(widget), dark: _isWearable(widget)), const SizedBox(width: 8), _Tag(label: widget.category)]),
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: WidgetPreview(gifPath: widget.gifPath)),
                          const SizedBox(width: 24),
                          Expanded(flex: 3, child: CodeViewer(code: widget.code, title: widget.title)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openWidgetSheet(WidgetShowcase widget) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.title, style: _display.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text(widget.description, style: _body.copyWith(fontSize: 14, color: _muted, height: 1.45)),
                const SizedBox(height: 12),
                Row(children: [_Badge(text: widget.mainCategory, icon: _platformIcon(widget), dark: _isWearable(widget)), const SizedBox(width: 8), _Tag(label: widget.category)]),
                const SizedBox(height: 20),
                WidgetPreview(gifPath: widget.gifPath),
                const SizedBox(height: 16),
                CodeViewer(code: widget.code, title: widget.title),
              ],
            );
          },
        );
      },
    );
  }

  // ---- states -----------------------------------------------------------

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.widgets_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            Text('No widgets match', style: _display.copyWith(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              'Try another platform or clear the search.',
              style: _body.copyWith(fontSize: 14, color: _muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _accent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: _body.copyWith(color: _accent, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Small presentational widgets
// ===========================================================================

class _NavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasis;

  const _NavItem({required this.label, required this.icon, required this.onTap, this.emphasis = false});
}

class _NavPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasis;

  const _NavPill({required this.label, required this.icon, required this.onTap, this.emphasis = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasis ? const Color(0xFFE11D48) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: emphasis ? Colors.white : const Color(0xFF334155)),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: emphasis ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final List<_NavItem> items;
  const _MoreMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_NavItem>(
      tooltip: 'More',
      position: PopupMenuPosition.under,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (item) => item.onTap(),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<_NavItem>(
            value: item,
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: const Color(0xFF334155)),
                const SizedBox(width: 10),
                Text(item.label,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF334155)),
            const SizedBox(width: 7),
            Text('More',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
          ],
        ),
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _PlatformChip({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreEntry {
  final String label;
  final VoidCallback onSeeAll;
  final Widget carousel;

  const _ExploreEntry({required this.label, required this.onSeeAll, required this.carousel});
}

class _ExploreTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExploreTabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HeroButton({required this.label, required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: filled ? const Color(0xFF0F172A) : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool dark;
  const _Badge({required this.text, this.icon, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 5)],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'NEW',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
      ),
    );
  }
}

class _MediumCard extends StatelessWidget {
  final ExternalArticle article;
  final VoidCallback onTap;

  const _MediumCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (article.imageUrl ?? '').trim();
    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  alignment: Alignment.center,
                  child: const Icon(Icons.article_outlined, color: Colors.white54, size: 40),
                ),
              )
            else
              Container(
                color: const Color(0xFF1E293B),
                alignment: Alignment.center,
                child: const Icon(Icons.article_outlined, color: Colors.white54, size: 40),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.78)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(7)),
                        child: Text('Medium', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2, letterSpacing: -0.3),
                  ),
                  if ((article.author ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _AuthorAvatar(name: article.author!.trim(), size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.author!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YouTubeCard extends StatelessWidget {
  final ExternalArticle video;
  final VoidCallback onTap;

  const _YouTubeCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (video.imageUrl ?? '').trim();
    return Material(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackArt())
            else
              _fallbackArt(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.82)],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFFF0000).withValues(alpha: 0.92), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(7)),
                    child: Text('YouTube', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const Spacer(),
                  Text(
                    video.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2, letterSpacing: -0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      color: const Color(0xFF1F1F1F),
      alignment: Alignment.center,
      child: const Icon(Icons.ondemand_video_rounded, color: Colors.white54, size: 40),
    );
  }
}

class _LinkedInCard extends StatelessWidget {
  final ExternalArticle post;
  final VoidCallback onTap;

  const _LinkedInCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (post.imageUrl ?? '').trim();
    return Material(
      color: const Color(0xFF0A66C2),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackArt())
            else
              _fallbackArt(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.82)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(7)),
                    child: Text('LinkedIn', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const Spacer(),
                  Text(
                    post.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2, letterSpacing: -0.3),
                  ),
                  if ((post.author ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      color: const Color(0xFF0A66C2),
      alignment: Alignment.center,
      child: const Icon(Icons.work_outline_rounded, color: Colors.white70, size: 40),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final GitHubDemo demo;
  final VoidCallback onTap;

  const _DemoCard({required this.demo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = demo.screenshotUrls.isNotEmpty ? demo.screenshotUrls.first.trim() : '';
    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackArt())
            else
              _fallbackArt(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(7)),
                    child: Text('GitHub', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const Spacer(),
                  Text(
                    demo.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    demo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: const Icon(Icons.apps_rounded, color: Colors.white54, size: 40),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _AuthorAvatar({required this.name, this.size = 28});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get _avatarUrl =>
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}'
      '&background=e11d48&color=ffffff&size=128&bold=true&format=png';

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          _avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE11D48),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: GoogleFonts.plusJakartaSans(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
