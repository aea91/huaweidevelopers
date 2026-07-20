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
  PageController? _pageController;

  WidgetShowcase? selectedWidget;
  String selectedMainCategory = 'All';
  String selectedCategory = 'All';
  String searchQuery = '';
  List<WidgetShowcase> allWidgets = [];
  List<ExternalArticle> _mediumHighlights = [];
  List<GitHubDemo> _demoHighlights = [];
  List<ExternalArticle> _linkedinHighlights = [];
  List<ExternalArticle> _youtubeHighlights = [];

  final List<String> mainCategories = const [
    'All',
    'Mobile',
    'Smart Wearable',
    'Light Wearable',
    'PC (2in1)',
  ];

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
    _firestoreService.getWidgets().first.then((widgets) {
      if (widgets.isNotEmpty && mounted) {
        setState(() {
          allWidgets = widgets;
          selectedWidget = widgets[0];
        });
      }
    });
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
    } catch (_) {
      // Ignore — home still works without Medium strip.
    }
  }

  Future<void> _loadDemoHighlights() async {
    try {
      final demos = await _demosService.fetchHighlights(limit: 5);
      if (!mounted || demos.isEmpty) return;
      setState(() => _demoHighlights = demos);
    } catch (_) {
      // Ignore — home still works without demos strip.
    }
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
    } catch (_) {
      // Ignore — home still works without LinkedIn strip.
    }
  }

  Future<void> _loadYouTubeHighlights() async {
    try {
      final videos = await _youtubeService.fetchHighlights(limit: 5);
      if (!mounted || videos.isEmpty) return;
      setState(() => _youtubeHighlights = videos);
    } catch (_) {
      // Ignore — home still works without YouTube strip.
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get categories {
    final cats = <String>{'All'};
    for (final widget in allWidgets) {
      if (selectedMainCategory == 'All' || widget.mainCategory == selectedMainCategory) {
        cats.add(widget.category);
      }
    }
    return cats.toList();
  }

  List<WidgetShowcase> get filteredWidgets {
    return allWidgets.where((widget) {
      final matchesMainCategory =
          selectedMainCategory == 'All' || widget.mainCategory == selectedMainCategory;
      final matchesCategory =
          selectedCategory == 'All' || widget.category == selectedCategory;
      final q = searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          widget.title.toLowerCase().contains(q) ||
          widget.description.toLowerCase().contains(q) ||
          widget.mainCategory.toLowerCase().contains(q) ||
          widget.category.toLowerCase().contains(q) ||
          widget.tags.any((tag) => tag.toLowerCase().contains(q));
      return matchesMainCategory && matchesCategory && matchesSearch;
    }).toList();
  }

  TextStyle get _display => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w700,
    color: _ink,
    letterSpacing: -0.6,
  );

  TextStyle get _body => GoogleFonts.plusJakartaSans(color: _ink);

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
          _buildFilterStrip(isMobile),
          Expanded(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
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
                  children: [
                    _buildBrandMark(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _navItems(context)
                          .map(
                            (item) => _NavPill(
                              label: item.label,
                              icon: item.icon,
                              emphasis: item.emphasis,
                              onTap: item.onTap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildBrandMark(),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: _navItems(context)
                            .map(
                              (item) => _NavPill(
                                label: item.label,
                                icon: item.icon,
                                emphasis: item.emphasis,
                                onTap: item.onTap,
                              ),
                            )
                            .toList(),
                      ),
                    ),
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
          child: const Icon(
            Icons.auto_awesome_mosaic_rounded,
            color: Colors.white,
            size: 20,
          ),
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

  List<_NavItem> _navItems(BuildContext context) {
    return [
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
        label: 'Theme',
        icon: Icons.palette_outlined,
        onTap: () => Navigator.pushNamed(context, '/theme-builder'),
      ),
      _NavItem(
        label: 'Class',
        icon: Icons.code_rounded,
        onTap: () => Navigator.pushNamed(context, '/class-builder'),
      ),
      _NavItem(
        label: 'Demos',
        icon: Icons.apps_rounded,
        onTap: () => Navigator.pushNamed(context, '/example-demos'),
      ),
      _NavItem(
        label: 'Medium',
        icon: Icons.article_outlined,
        onTap: () => Navigator.pushNamed(context, '/medium'),
      ),
      _NavItem(
        label: 'Forum',
        icon: Icons.forum_outlined,
        onTap: () => Navigator.pushNamed(context, '/forum'),
      ),
      _NavItem(
        label: 'Managers',
        icon: Icons.manage_accounts_outlined,
        onTap: () => Navigator.pushNamed(context, '/managers'),
      ),
    ];
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

  Widget _buildFilterStrip(bool isMobile) {
    final platformDropdown = _buildFilterDropdown(
      label: 'Platform',
      value: selectedMainCategory,
      items: mainCategories,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          selectedMainCategory = value;
          selectedCategory = 'All';
          selectedWidget = null;
          if (filteredWidgets.isNotEmpty) {
            selectedWidget = filteredWidgets.first;
          }
        });
      },
    );

    final categoryDropdown = _buildFilterDropdown(
      label: 'Category',
      value: categories.contains(selectedCategory) ? selectedCategory : 'All',
      items: categories,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          selectedCategory = value;
          if (value != 'All') {
            final filtered = filteredWidgets;
            selectedWidget = filtered.isNotEmpty ? filtered.first : null;
          }
        });
      },
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 12, isMobile ? 16 : 28, 14),
      child: isMobile
          ? Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: platformDropdown),
                    const SizedBox(width: 10),
                    Expanded(child: categoryDropdown),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: 12),
                SizedBox(width: 200, child: platformDropdown),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: categoryDropdown),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _body.copyWith(
          fontSize: 12,
          color: _muted,
          fontWeight: FontWeight.w600,
        ),
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
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: _body.copyWith(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isTablet) {
    if (selectedCategory == 'All') {
      return _buildGridView(isTablet);
    }

    return Row(
      children: [
        Container(
          width: isTablet ? 300 : 340,
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(right: BorderSide(color: _line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  '${filteredWidgets.length} components',
                  style: _display.copyWith(fontSize: 18),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<WidgetShowcase>>(
                  stream: _firestoreService.getWidgets(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _errorState(snapshot.error.toString());
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _ink));
                    }

                    allWidgets = snapshot.data ?? [];
                    final filtered = filteredWidgets;

                    if (filtered.isEmpty) {
                      return _emptyState();
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final widget = filtered[index];
                        final isSelected = selectedWidget?.id == widget.id;
                        return _buildWidgetListItem(widget, isSelected);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredWidgets.isEmpty
              ? _emptyState()
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: filteredWidgets.length,
                  controller: _pageController ??= PageController(
                    initialPage: selectedWidget != null
                        ? filteredWidgets
                              .indexWhere((w) => w.id == selectedWidget!.id)
                              .clamp(0, filteredWidgets.length - 1)
                        : 0,
                  ),
                  onPageChanged: (index) {
                    setState(() => selectedWidget = filteredWidgets[index]);
                  },
                  itemBuilder: (context, index) {
                    final widget = filteredWidgets[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: _buildWidgetDetail(widget, isTablet),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return StreamBuilder<List<WidgetShowcase>>(
      stream: _firestoreService.getWidgets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && allWidgets.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _ink));
        }
        if (snapshot.hasData) {
          allWidgets = snapshot.data ?? [];
        }

        final filtered = filteredWidgets;
        if (filtered.isEmpty) return _emptyState();

        final highlightBlocks = <Widget>[
          if (_mediumHighlights.isNotEmpty) _buildMediumCards(),
          if (_demoHighlights.isNotEmpty) _buildDemoCards(),
          if (_linkedinHighlights.isNotEmpty) _buildLinkedInCards(),
          if (_youtubeHighlights.isNotEmpty) _buildYouTubeCards(),
        ];

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: filtered.length + highlightBlocks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index < highlightBlocks.length) {
              return highlightBlocks[index];
            }
            return _buildMobileCard(filtered[index - highlightBlocks.length]);
          },
        );
      },
    );
  }

  Widget _buildMobileCard(WidgetShowcase widget) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            selectedWidget = widget;
            selectedCategory = widget.category;
          });
          showModalBottomSheet(
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
                          decoration: BoxDecoration(
                            color: _line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.title, style: _display.copyWith(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: _body.copyWith(fontSize: 14, color: _muted, height: 1.45),
                      ),
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
        },
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
                child: Container(
                  width: 76,
                  height: 76,
                  color: const Color(0xFFF1F5F9),
                  child: widget.gifPath.startsWith('http')
                      ? Image.network(
                          _getProxyUrl(widget.gifPath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1)),
                        )
                      : const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: _body.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildGridView(bool isTablet) {
    return StreamBuilder<List<WidgetShowcase>>(
      stream: _firestoreService.getWidgets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.waiting && allWidgets.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _ink));
        }

        allWidgets = snapshot.data ?? allWidgets;
        final filtered = filteredWidgets;

        if (filtered.isEmpty) {
          return _emptyState();
        }

        return CustomScrollView(
          slivers: [
            // Atmosphere strip
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      bottom: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hand-crafted ArkTS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 34,
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
                            'Browse production-ready HarmonyOS widgets, copy the ArkTS, and ship faster.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.78),
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _HeroStat(label: 'Components', value: '${filtered.length}'),
                            _HeroStat(
                              label: 'Platform',
                              value: selectedMainCategory == 'All'
                                  ? 'All'
                                  : selectedMainCategory,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_mediumHighlights.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _buildMediumCards(),
                ),
              ),
            if (_demoHighlights.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _buildDemoCards(),
                ),
              ),
            if (_linkedinHighlights.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _buildLinkedInCards(),
                ),
              ),
            if (_youtubeHighlights.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _buildYouTubeCards(),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
              sliver: SliverToBoxAdapter(
                child: Text('All widgets', style: _display.copyWith(fontSize: 22)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 3,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: isTablet ? 0.92 : 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildGridCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediumCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('From Medium', style: _display.copyWith(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/medium'),
              child: Text(
                'See all',
                style: _body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final narrow = constraints.maxWidth < 720;
            final visibleCount = narrow ? 1.15 : 5.0;
            final cardSize =
                (constraints.maxWidth - gap * (visibleCount - 1)) / visibleCount;
            return SizedBox(
              height: cardSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mediumHighlights.length,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  final article = _mediumHighlights[index];
                  return SizedBox(
                    width: cardSize,
                    height: cardSize,
                    child: _MediumCard(
                      article: article,
                      onTap: () => _openMediumArticle(article),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open article: $e')));
    }
  }

  Widget _buildDemoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Sample Applications', style: _display.copyWith(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/example-demos'),
              child: Text(
                'See all',
                style: _body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final narrow = constraints.maxWidth < 720;
            final visibleCount = narrow ? 1.15 : 5.0;
            final cardSize =
                (constraints.maxWidth - gap * (visibleCount - 1)) / visibleCount;
            return SizedBox(
              height: cardSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _demoHighlights.length,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  final demo = _demoHighlights[index];
                  return SizedBox(
                    width: cardSize,
                    height: cardSize,
                    child: _DemoCard(demo: demo, onTap: () => _openDemo(demo)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openDemo(GitHubDemo demo) async {
    final uri = Uri.parse(demo.htmlUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLinkedInCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('LinkedIn', style: _display.copyWith(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: () => _openUrl(LinkedInPostsService.companyPostsUrl),
              child: Text(
                'See all',
                style: _body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final narrow = constraints.maxWidth < 720;
            final visibleCount = narrow ? 1.15 : 5.0;
            final cardSize =
                (constraints.maxWidth - gap * (visibleCount - 1)) / visibleCount;
            return SizedBox(
              height: cardSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _linkedinHighlights.length,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  final post = _linkedinHighlights[index];
                  return SizedBox(
                    width: cardSize,
                    height: cardSize,
                    child: _LinkedInCard(post: post, onTap: () => _openUrl(post.url)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildYouTubeCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('YouTube', style: _display.copyWith(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: () => _openUrl(YouTubeVideosService.channelStreamsUrl),
              child: Text(
                'See all',
                style: _body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final narrow = constraints.maxWidth < 720;
            final visibleCount = narrow ? 1.15 : 5.0;
            final cardSize =
                (constraints.maxWidth - gap * (visibleCount - 1)) / visibleCount;
            return SizedBox(
              height: cardSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _youtubeHighlights.length,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  final video = _youtubeHighlights[index];
                  return SizedBox(
                    width: cardSize,
                    height: cardSize,
                    child: _YouTubeCard(video: video, onTap: () => _openUrl(video.url)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridCard(WidgetShowcase widget) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Material(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                selectedWidget = widget;
                selectedCategory = widget.category;
              });
            },
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
                    child: Container(
                      color: const Color(0xFFF1F5F9),
                      child: widget.gifPath.startsWith('http')
                          ? Image.network(
                              _getProxyUrl(widget.gifPath),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 42,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
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
                            style: _body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              widget.description,
                              style: _body.copyWith(
                                fontSize: 12.5,
                                color: _muted,
                                height: 1.35,
                              ),
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
      ),
    );
  }

  Widget _buildWidgetListItem(WidgetShowcase widget, bool isSelected) {
    return InkWell(
      onTap: () {
        final index = filteredWidgets.indexWhere((w) => w.id == widget.id);
        if (index != -1 && _pageController != null) {
          _pageController!.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        setState(() => selectedWidget = widget);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _ink.withValues(alpha: 0.18) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: _body.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? _ink : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: _body.copyWith(fontSize: 12.5, color: _muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.tags.take(2).map((tag) => _Tag(label: tag)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetDetail(WidgetShowcase widget, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: _display.copyWith(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: _body.copyWith(fontSize: 15, color: _muted, height: 1.45),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isTablet ? 1 : 2,
                child: WidgetPreview(gifPath: widget.gifPath),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: CodeViewer(code: widget.code, title: widget.title),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: _body.copyWith(color: _accent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasis;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.emphasis = false,
  });
}

class _NavPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasis;

  const _NavPill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.emphasis = false,
  });

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
              Icon(
                icon,
                size: 16,
                color: emphasis ? Colors.white : const Color(0xFF334155),
              ),
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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
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
                  child: const Icon(
                    Icons.article_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFF1E293B),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.article_outlined,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.78),
                  ],
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
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Medium',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
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
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackArt(),
              )
            else
              _fallbackArt(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'YouTube',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    video.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
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
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackArt(),
              )
            else
              _fallbackArt(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.82),
                  ],
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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'LinkedIn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if ((post.author ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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
    final imageUrl = demo.screenshotUrls.isNotEmpty
        ? demo.screenshotUrls.first.trim()
        : '';

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
                errorBuilder: (_, __, ___) => _fallbackArt(),
              )
            else
              _fallbackArt(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.8),
                  ],
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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'GitHub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    demo.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    demo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
