import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_design_suggestion.dart';
import '../models/manager_definition.dart';
import '../models/widget_showcase.dart';

class AppDesignAssistantService {
  static const _cloudFunctionUrl =
      'https://us-central1-arkuibuilder.cloudfunctions.net/suggestAppDesign';

  Future<AppDesignSuggestion> suggest({
    required String description,
    required List<WidgetShowcase> widgets,
    required List<ManagerDefinition> managers,
  }) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Lütfen uygulamanızı kısaca tarif edin.');
    }

    try {
      final cloudResult = await _suggestViaCloud(
        description: trimmed,
        widgets: widgets,
        managers: managers,
      );
      if (cloudResult != null) {
        return _sanitizeSuggestion(cloudResult, widgets, managers, usedCloudAi: true);
      }
    } catch (e) {
      debugPrint('Cloud AI unavailable, using local matcher: $e');
    }

    return _suggestLocally(
      description: trimmed,
      widgets: widgets,
      managers: managers,
    );
  }

  Future<AppDesignSuggestion?> _suggestViaCloud({
    required String description,
    required List<WidgetShowcase> widgets,
    required List<ManagerDefinition> managers,
  }) async {
    final response = await http
        .post(
          Uri.parse(_cloudFunctionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'description': description,
            'catalog': {
              'widgets': widgets
                  .map((w) => {
                        'id': w.id,
                        'title': w.title,
                        'description': w.description,
                        'category': w.category,
                        'mainCategory': w.mainCategory,
                        'tags': w.tags,
                      })
                  .toList(),
              'managers': managers
                  .map((m) => {
                        'id': m.id,
                        'title': m.title,
                        'description': m.description,
                        'className': m.className,
                      })
                  .toList(),
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 503) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('AI servisi yanıt vermedi (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Geçersiz AI yanıtı');
    }

    return AppDesignSuggestion.fromJson(decoded);
  }

  AppDesignSuggestion _suggestLocally({
    required String description,
    required List<WidgetShowcase> widgets,
    required List<ManagerDefinition> managers,
  }) {
    final normalized = description.toLowerCase();
    final keywords = _extractKeywords(normalized);
    final theme = _resolveTheme(normalized, keywords);

    final scoredWidgets = <MapEntry<WidgetShowcase, double>>[];
    for (final widget in widgets) {
      final score = _scoreWidget(widget, keywords, normalized);
      if (score > 0) {
        scoredWidgets.add(MapEntry(widget, score));
      }
    }

    scoredWidgets.sort((a, b) => b.value.compareTo(a.value));

    final selectedWidgets = <WidgetSuggestion>[];
    final usedCategories = <String>{};

    for (final entry in scoredWidgets.take(8)) {
      selectedWidgets.add(
        WidgetSuggestion(
          id: entry.key.id,
          reason: _widgetReason(entry.key, keywords),
        ),
      );
      usedCategories.add(entry.key.category);
    }

    if (selectedWidgets.length < 4) {
      for (final widget in widgets) {
        if (selectedWidgets.any((w) => w.id == widget.id)) continue;
        selectedWidgets.add(
          WidgetSuggestion(
            id: widget.id,
            reason: 'Katalogdan tamamlayıcı bileşen',
          ),
        );
        if (selectedWidgets.length >= 5) break;
      }
    }

    final managerIds = _matchManagers(managers, keywords, normalized);
    final models = _suggestModels(keywords, normalized);
    final layout = _buildLayoutDescription(selectedWidgets, widgets);

    return AppDesignSuggestion(
      summary:
          'Katalog eşleştirmesiyle ${selectedWidgets.length} widget, ${managerIds.length} manager ve ${models.length} model önerildi.',
      layoutDescription: layout,
      widgets: selectedWidgets,
      managerIds: managerIds,
      primaryColor: theme['primary']!,
      secondaryColor: theme['secondary']!,
      tertiaryColor: theme['tertiary']!,
      isDarkMode: theme['dark'] == 'true',
      models: models,
      projectName: _suggestProjectName(normalized),
      projectDescription: description,
      usedCloudAi: false,
    );
  }

  AppDesignSuggestion _sanitizeSuggestion(
    AppDesignSuggestion suggestion,
    List<WidgetShowcase> widgets,
    List<ManagerDefinition> managers, {
    required bool usedCloudAi,
  }) {
    final validWidgetIds = widgets.map((w) => w.id).toSet();
    final validManagerIds = managers.map((m) => m.id).toSet();

    final filteredWidgets = suggestion.widgets
        .where((w) => validWidgetIds.contains(w.id))
        .take(10)
        .toList();

    final filteredManagers =
        suggestion.managerIds.where(validManagerIds.contains).toList();

    return AppDesignSuggestion(
      summary: suggestion.summary.isNotEmpty
          ? suggestion.summary
          : 'AI önerisi katalogdan seçildi.',
      layoutDescription: suggestion.layoutDescription,
      widgets: filteredWidgets.isNotEmpty
          ? filteredWidgets
          : _suggestLocally(
              description: suggestion.projectDescription ?? 'dashboard',
              widgets: widgets,
              managers: managers,
            ).widgets,
      managerIds: filteredManagers,
      primaryColor: _normalizeHex(suggestion.primaryColor, '#6200EE'),
      secondaryColor: _normalizeHex(suggestion.secondaryColor, '#03DAC6'),
      tertiaryColor: _normalizeHex(suggestion.tertiaryColor, '#FF6B6B'),
      isDarkMode: suggestion.isDarkMode,
      models: suggestion.models,
      projectName: suggestion.projectName,
      projectDescription: suggestion.projectDescription,
      usedCloudAi: usedCloudAi,
    );
  }

  List<String> _extractKeywords(String text) {
    const vocabulary = [
      'dashboard', 'finans', 'finance', 'e-ticaret', 'ecommerce', 'eticaret',
      'mağaza', 'store', 'shop', 'satış', 'sales', 'kpi', 'grafik', 'chart',
      'liste', 'list', 'kart', 'card', 'profil', 'profile', 'navigasyon',
      'navigation', 'bottom', 'tab', 'giriş', 'login', 'auth', 'kayıt',
      'register', 'harita', 'map', 'konum', 'location', 'depolama', 'storage',
      'bildirim', 'notification', 'arama', 'search', 'form', 'buton', 'button',
      'sağlık', 'health', 'fitness', 'sosyal', 'social', 'mesaj', 'chat',
      'ödeme', 'payment', 'sipariş', 'order', 'ürün', 'product', 'istatistik',
      'stat', 'analytics', 'koyu', 'dark', 'açık', 'light', 'modern',
      'minimal', 'gradient', 'menu', 'drawer', 'sidebar', 'header', 'footer',
    ];

    final found = <String>[];
    for (final word in vocabulary) {
      if (text.contains(word)) {
        found.add(word);
      }
    }
    return found;
  }

  double _scoreWidget(WidgetShowcase widget, List<String> keywords, String text) {
    final haystack = [
      widget.title,
      widget.description,
      widget.category,
      widget.mainCategory,
      ...widget.tags,
    ].join(' ').toLowerCase();

    var score = 0.0;

    for (final keyword in keywords) {
      if (haystack.contains(keyword)) {
        score += 3;
      }
      if (widget.title.toLowerCase().contains(keyword)) {
        score += 2;
      }
      if (widget.tags.any((t) => t.toLowerCase().contains(keyword))) {
        score += 2;
      }
    }

    const directHints = {
      'dashboard': ['stat', 'chart', 'card', 'metric', 'kpi'],
      'finans': ['chart', 'stat', 'card'],
      'finance': ['chart', 'stat', 'card'],
      'navigation': ['nav', 'bottom', 'tab'],
      'liste': ['list'],
      'list': ['list'],
      'profil': ['profile'],
      'profile': ['profile'],
      'grafik': ['chart', 'graph'],
      'chart': ['chart', 'graph'],
    };

    for (final keyword in keywords) {
      final hints = directHints[keyword];
      if (hints == null) continue;
      for (final hint in hints) {
        if (haystack.contains(hint)) {
          score += 2.5;
        }
      }
    }

    if (text.contains('dashboard') &&
        (widget.category.toLowerCase().contains('card') ||
            widget.title.toLowerCase().contains('card'))) {
      score += 1.5;
    }

    return score;
  }

  String _widgetReason(WidgetShowcase widget, List<String> keywords) {
    if (keywords.isEmpty) {
      return '${widget.category} kategorisinden öneri';
    }
    return '${widget.category} — "${keywords.take(2).join(', ')}" ihtiyacına uygun';
  }

  List<String> _matchManagers(
    List<ManagerDefinition> managers,
    List<String> keywords,
    String text,
  ) {
    const managerHints = {
      'storage': ['storage', 'depolama', 'cache', 'prefs', 'kayıt'],
      'location': ['location', 'konum', 'harita', 'map', 'gps'],
      'camera': ['camera', 'kamera', 'foto'],
      'network': ['network', 'api', 'http', 'internet'],
    };

    final ids = <String>[];
    for (final manager in managers) {
      final blob =
          '${manager.title} ${manager.description} ${manager.className}'.toLowerCase();
      for (final entry in managerHints.entries) {
        final matched = entry.value.any((hint) => text.contains(hint) || blob.contains(hint));
        if (matched && blob.contains(entry.key)) {
          ids.add(manager.id);
        }
      }
      for (final keyword in keywords) {
        if (blob.contains(keyword)) {
          ids.add(manager.id);
        }
      }
    }
    return ids.toSet().toList();
  }

  List<SuggestedModel> _suggestModels(List<String> keywords, String text) {
    if (_containsAny(text, ['finans', 'finance', 'bank', 'dashboard', 'kpi'])) {
      return [
        const SuggestedModel(
          name: 'Transaction',
          sampleJson: {
            'id': 'tx_001',
            'title': 'Monthly revenue',
            'amount': 12840.5,
            'currency': 'TRY',
            'date': '2026-06-01',
          },
          reason: 'Finans dashboard için işlem verisi',
        ),
        const SuggestedModel(
          name: 'KpiMetric',
          sampleJson: {
            'label': 'Active users',
            'value': 1240,
            'delta': 8.4,
          },
          reason: 'Üst KPI kartları için metrik modeli',
        ),
      ];
    }

    if (_containsAny(text, ['e-ticaret', 'ecommerce', 'eticaret', 'shop', 'mağaza', 'store'])) {
      return [
        const SuggestedModel(
          name: 'Product',
          sampleJson: {
            'id': 'prd_01',
            'name': 'Wireless earbuds',
            'price': 1299.99,
            'imageUrl': 'https://example.com/product.png',
          },
          reason: 'Ürün listesi ve kartları için',
        ),
        const SuggestedModel(
          name: 'Order',
          sampleJson: {
            'id': 'ord_1001',
            'status': 'shipped',
            'total': 2599.98,
            'createdAt': '2026-06-08',
          },
          reason: 'Sipariş geçmişi bölümü için',
        ),
      ];
    }

    if (_containsAny(text, ['profil', 'profile', 'social', 'sosyal', 'user', 'kullanıcı'])) {
      return [
        const SuggestedModel(
          name: 'UserProfile',
          sampleJson: {
            'id': 'usr_01',
            'name': 'Arif Emre',
            'email': 'user@example.com',
            'avatarUrl': 'https://example.com/avatar.png',
          },
          reason: 'Profil ekranı için temel kullanıcı modeli',
        ),
      ];
    }

    return [
      const SuggestedModel(
        name: 'DashboardItem',
        sampleJson: {
          'id': 'item_01',
          'title': 'Overview',
          'subtitle': 'Today',
          'value': 42,
        },
        reason: 'Genel dashboard içeriği için başlangıç modeli',
      ),
    ];
  }

  Map<String, String> _resolveTheme(String text, List<String> keywords) {
    final combined = '$text ${keywords.join(' ')}';
    final isDark = _containsAny(combined, ['koyu', 'dark']) &&
        !_containsAny(combined, ['açık', 'light']);

    if (_containsAny(combined, ['finans', 'finance', 'bank'])) {
      return {
        'primary': '#1565C0',
        'secondary': '#2E7D32',
        'tertiary': '#FFA000',
        'dark': isDark.toString(),
      };
    }
    if (_containsAny(combined, ['e-ticaret', 'ecommerce', 'eticaret', 'shop'])) {
      return {
        'primary': '#7C3AED',
        'secondary': '#06B6D4',
        'tertiary': '#F97316',
        'dark': isDark.toString(),
      };
    }
    if (_containsAny(combined, ['sağlık', 'health', 'fitness'])) {
      return {
        'primary': '#059669',
        'secondary': '#0EA5E9',
        'tertiary': '#F43F5E',
        'dark': isDark.toString(),
      };
    }

    return {
      'primary': '#6200EE',
      'secondary': '#03DAC6',
      'tertiary': '#FF6B6B',
      'dark': isDark.toString(),
    };
  }

  String _buildLayoutDescription(
    List<WidgetSuggestion> selected,
    List<WidgetShowcase> catalog,
  ) {
    final titles = <String>[];
    for (final item in selected) {
      final widget = catalog.where((w) => w.id == item.id).firstOrNull;
      if (widget != null) titles.add(widget.title);
    }
    if (titles.isEmpty) return 'Üstte başlık, ortada içerik, altta navigasyon.';

    final parts = <String>[];
    if (titles.length >= 2) {
      parts.add('Üst bölüm: ${titles.take(2).join(', ')}');
    }
    if (titles.length > 2) {
      parts.add('Orta bölüm: ${titles.sublist(2, titles.length.clamp(2, 5)).join(', ')}');
    }
    if (titles.length > 5) {
      parts.add('Alt bölüm: ${titles.last}');
    }
    return parts.join(' · ');
  }

  String? _suggestProjectName(String text) {
    if (_containsAny(text, ['finans', 'finance'])) return 'FinanceDashboard';
    if (_containsAny(text, ['e-ticaret', 'ecommerce', 'eticaret'])) return 'ShopArkApp';
    if (_containsAny(text, ['sağlık', 'health'])) return 'HealthTracker';
    if (text.contains('dashboard')) return 'DashboardApp';
    return null;
  }

  String _normalizeHex(String value, String fallback) {
    final cleaned = value.trim();
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(cleaned)) {
      return cleaned;
    }
    return fallback;
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
