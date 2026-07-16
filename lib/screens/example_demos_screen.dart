import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/github_demos_config.dart';
import '../models/github_demo.dart';
import '../services/github_demos_service.dart';
import '../theme/app_chrome.dart';
import '../widgets/github_demo_card.dart';

class ExampleDemosScreen extends StatefulWidget {
  const ExampleDemosScreen({super.key});

  @override
  State<ExampleDemosScreen> createState() => _ExampleDemosScreenState();
}

class _ExampleDemosScreenState extends State<ExampleDemosScreen> {
  final _service = GitHubDemosService();
  final _searchController = TextEditingController();

  List<GitHubDemo> _allDemos = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isEnriching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDemos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDemos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.fetchDemos(
        onProgress: (demos, isComplete) {
          if (!mounted) return;
          setState(() {
            _allDemos = demos;
            _isLoading = false;
            _isEnriching = !isComplete;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<GitHubDemo> get _filteredDemos {
    return _allDemos.where((demo) => demo.matchesSearch(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width >= 1200
        ? 3
        : size.width >= 768
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: AppChrome.canvas,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(crossAxisCount)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppChrome.listHeader(
      context: context,
      title: 'Example Demos',
      subtitle: 'HarmonyOS wearable sample apps from Explore-In-HMOS-Wearable',
      icon: Icons.apps_rounded,
      actionLabel: 'HMOS Index',
      actionIcon: Icons.menu_book_rounded,
      onAction: _openGitHubProfile,
      bottom: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        style: AppChrome.body(),
        decoration: AppChrome.searchDecoration(
          hint: 'Search demos by name, description, kit or topic…',
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

  Widget _buildBody(int crossAxisCount) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppChrome.ink));
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
                'Could not load GitHub demos',
                style: AppChrome.body(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppChrome.body(color: AppChrome.muted),
              ),
              const SizedBox(height: 8),
              Text(
                'Update lib/config/github_demos_config.dart with your GitHub org/username.',
                textAlign: TextAlign.center,
                style: AppChrome.body(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDemos,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppChrome.ink,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final demos = _filteredDemos;

    if (demos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? 'No demo repositories found' : 'No demos match your search',
              style: AppChrome.body(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDemos,
      color: AppChrome.ink,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Text(
                    '${demos.length} demo${demos.length == 1 ? '' : 's'}',
                    style: AppChrome.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppChrome.muted,
                    ),
                  ),
                  if (_isEnriching) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppChrome.ink),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading previews...',
                      style: AppChrome.body(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: crossAxisCount == 1 ? 0.95 : 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => GitHubDemoCard(demo: demos[index]),
                childCount: demos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGitHubProfile() async {
    final uri = Uri.parse(
      'https://github.com/${GitHubDemosConfig.owner}/${GitHubDemosConfig.indexRepo}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
