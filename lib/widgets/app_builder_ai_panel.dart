import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_chrome.dart';

import '../models/app_design_suggestion.dart';
import '../models/manager_definition.dart';
import '../models/widget_showcase.dart';

class AppBuilderAiPanel extends StatelessWidget {
  final TextEditingController descriptionController;
  final bool isLoading;
  final bool isExpanded;
  final AppDesignSuggestion? suggestion;
  final List<WidgetShowcase> availableWidgets;
  final List<ManagerDefinition> availableManagers;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSuggest;
  final VoidCallback onApply;
  final VoidCallback onClearSuggestion;

  const AppBuilderAiPanel({
    super.key,
    required this.descriptionController,
    required this.isLoading,
    required this.isExpanded,
    required this.suggestion,
    required this.availableWidgets,
    required this.availableManagers,
    required this.onToggleExpanded,
    required this.onSuggest,
    required this.onApply,
    required this.onClearSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppChrome.ink.withOpacity(0.08),
            const Color(0xFF03DAC6).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppChrome.ink.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppChrome.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Tasarım Asistanı',
                          style: AppChrome.body(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uygulamanızı tarif edin — katalogdan widget, tema ve model önersin',
                          style: AppChrome.body(
                            fontSize: 13,
                            color: AppChrome.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppChrome.ink,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Örn: Finans dashboard — üstte KPI kartları, ortada aylık gelir grafiği, altta işlem listesi. Koyu tema.',
                      hintStyle: AppChrome.body(fontSize: 13, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppChrome.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppChrome.line),
                      ),
                    ),
                    style: AppChrome.body(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : onSuggest,
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: Text(isLoading ? 'Analiz ediliyor...' : 'Katalogdan Öner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppChrome.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (suggestion != null)
                        OutlinedButton(
                          onPressed: onClearSuggestion,
                          child: const Text('Temizle'),
                        ),
                    ],
                  ),
                  if (suggestion != null) ...[
                    const SizedBox(height: 20),
                    _buildSuggestionPreview(context),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionPreview(BuildContext context) {
    final current = suggestion!;
    final widgetById = {for (final w in availableWidgets) w.id: w};
    final managerById = {for (final m in availableManagers) m.id: m};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppChrome.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  current.summary,
                  style: AppChrome.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: current.usedCloudAi
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  current.usedCloudAi ? 'Cloud AI' : 'Akıllı eşleştirme',
                  style: AppChrome.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: current.usedCloudAi
                        ? const Color(0xFF166534)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          if (current.layoutDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              current.layoutDescription,
              style: AppChrome.body(fontSize: 13, color: AppChrome.muted),
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Widget önerileri (${current.widgets.length})'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: current.widgets.map((item) {
              final widget = widgetById[item.id];
              final label = widget?.title ?? item.id;
              return Tooltip(
                message: item.reason.isNotEmpty ? item.reason : label,
                child: Chip(
                  avatar: const Icon(Icons.widgets, size: 16),
                  label: Text(label, style: AppChrome.body(fontSize: 12)),
                  backgroundColor: const Color(0xFFF3E8FF),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Tema'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _colorDot(current.primaryColor, 'Primary'),
              _colorDot(current.secondaryColor, 'Secondary'),
              _colorDot(current.tertiaryColor, 'Tertiary'),
              Chip(
                label: Text(
                  current.isDarkMode ? 'Koyu tema' : 'Açık tema',
                  style: AppChrome.body(fontSize: 12),
                ),
              ),
            ],
          ),
          if (current.managerIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Manager önerileri'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: current.managerIds.map((id) {
                final manager = managerById[id];
                return Chip(
                  avatar: const Icon(Icons.manage_accounts, size: 16),
                  label: Text(
                    manager?.title ?? id,
                    style: AppChrome.body(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
          if (current.models.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Model önerileri'),
            const SizedBox(height: 8),
            Column(
              children: current.models.map((model) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.data_object, color: AppChrome.ink),
                  title: Text(model.name, style: GoogleFonts.jetBrainsMono(fontSize: 13)),
                  subtitle: Text(model.reason, style: AppChrome.body(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Önerileri Uygula'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppChrome.body(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _colorDot(String hex, String label) {
    Color color;
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      color = Color(0xFF000000 | value);
    } catch (_) {
      color = AppChrome.ink;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppChrome.line),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppChrome.body(fontSize: 12, color: AppChrome.muted)),
      ],
    );
  }
}
