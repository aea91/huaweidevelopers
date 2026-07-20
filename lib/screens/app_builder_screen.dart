import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_chrome.dart';
import '../models/app_design_suggestion.dart';
import '../models/manager_definition.dart';
import '../models/widget_showcase.dart';
import '../services/app_design_assistant_service.dart';
import '../services/firestore_service.dart';
import '../services/project_generator.dart';
import '../widgets/app_builder_ai_panel.dart';

class AppBuilderScreen extends StatefulWidget {
  const AppBuilderScreen({super.key});

  @override
  State<AppBuilderScreen> createState() => _AppBuilderScreenState();
}

class _AppBuilderScreenState extends State<AppBuilderScreen> {
  final _firestoreService = FirestoreService();
  final _assistantService = AppDesignAssistantService();
  final _aiDescriptionController = TextEditingController();
  int _currentStep = 0;
  bool _aiPanelExpanded = true;
  bool _isAiLoading = false;
  AppDesignSuggestion? _aiSuggestion;
  List<ManagerDefinition> _availableManagers = [];

  // Step 1: Theme Data
  Color primaryColor = AppChrome.ink;
  Color secondaryColor = const Color(0xFF03DAC6);
  Color tertiaryColor = const Color(0xFFFF6B6B);
  bool isDarkMode = false;

  // Step 2: Selected Widgets
  List<String> selectedWidgetIds = [];
  List<WidgetShowcase> availableWidgets = [];

  // Step 3: Managers
  List<String> selectedManagerIds = [];

  // Step 4: Models
  List<Map<String, dynamic>> models = [];
  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  bool _makeModelsNullable = false;

  // Step 5: Project Info
  final TextEditingController _projectNameController = TextEditingController(
    text: 'MyArkUIApp',
  );
  final TextEditingController _bundleIdController = TextEditingController(
    text: 'com.example.myapp',
  );
  final TextEditingController _descriptionController = TextEditingController(
    text: 'A beautiful ArkUI application',
  );
  final TextEditingController _sdkVersionController = TextEditingController(
    text: '5.1.0(18)',
  );

  @override
  void dispose() {
    _aiDescriptionController.dispose();
    _modelNameController.dispose();
    _jsonController.dispose();
    _projectNameController.dispose();
    _bundleIdController.dispose();
    _descriptionController.dispose();
    _sdkVersionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadWidgets();
    _loadManagers();
  }

  Future<void> _loadWidgets() async {
    final widgets = await _firestoreService.getWidgets().first;
    setState(() {
      availableWidgets = widgets;
    });
  }

  Future<void> _loadManagers() async {
    final managers = await _firestoreService.getManagers().first;
    setState(() {
      _availableManagers = managers;
    });
  }

  Future<void> _requestAiSuggestion() async {
    final description = _aiDescriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe your app', style: AppChrome.body()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
    });

    try {
      final suggestion = await _assistantService.suggest(
        description: description,
        widgets: availableWidgets,
        managers: _availableManagers,
      );
      if (!mounted) return;
      setState(() {
        _aiSuggestion = suggestion;
        _isAiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAiLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not get an AI suggestion: $e',
            style: AppChrome.body(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyAiSuggestion() {
    final suggestion = _aiSuggestion;
    if (suggestion == null) return;

    setState(() {
      selectedWidgetIds = suggestion.widgetIds;
      selectedManagerIds = suggestion.managerIds;
      primaryColor = _colorFromHex(suggestion.primaryColor, primaryColor);
      secondaryColor = _colorFromHex(suggestion.secondaryColor, secondaryColor);
      tertiaryColor = _colorFromHex(suggestion.tertiaryColor, tertiaryColor);
      isDarkMode = suggestion.isDarkMode;

      if (suggestion.projectName != null &&
          suggestion.projectName!.isNotEmpty) {
        _projectNameController.text = suggestion.projectName!;
      }
      if (suggestion.projectDescription != null &&
          suggestion.projectDescription!.isNotEmpty) {
        _descriptionController.text = suggestion.projectDescription!;
      }

      for (final model in suggestion.models) {
        final exists = models.any((m) => m['name'] == model.name);
        if (exists) continue;

        final fields = <Map<String, String>>[];
        model.sampleJson.forEach((key, value) {
          fields.add({'name': key, 'type': _getJsonType(value)});
        });

        models.add({
          'name': model.name,
          'json': jsonEncode(model.sampleJson),
          'nullable': false,
          'fields': fields,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'AI suggestions applied. You can review and edit the steps.',
          style: AppChrome.body(),
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Color _colorFromHex(String hex, Color fallback) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(0xFF000000 | value);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppChrome.canvas,
      appBar: AppChrome.appBar(
        context: context,
        title: 'App Builder',
        icon: Icons.rocket_launch_rounded,
      ),
      body: Row(
        children: [
          // Left Sidebar - Steps
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Your App',
                        style: AppChrome.body(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppChrome.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow the steps to create your ArkUI project',
                        style: AppChrome.body(
                          fontSize: 13,
                          color: AppChrome.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStepItem(
                        stepNumber: 1,
                        title: 'Choose Theme',
                        description: 'Select colors and style',
                        icon: Icons.palette,
                        isActive: _currentStep == 0,
                        isCompleted: _currentStep > 0,
                      ),
                      _buildStepItem(
                        stepNumber: 2,
                        title: 'Select Widgets',
                        description: 'Pick UI components',
                        icon: Icons.widgets,
                        isActive: _currentStep == 1,
                        isCompleted: _currentStep > 1,
                      ),
                      _buildStepItem(
                        stepNumber: 3,
                        title: 'Add Feature',
                        description: 'Select managers/features',
                        icon: Icons.manage_accounts,
                        isActive: _currentStep == 2,
                        isCompleted: _currentStep > 2,
                      ),
                      _buildStepItem(
                        stepNumber: 4,
                        title: 'Add Models',
                        description: 'Generate data models',
                        icon: Icons.code,
                        isActive: _currentStep == 3,
                        isCompleted: _currentStep > 3,
                      ),
                      _buildStepItem(
                        stepNumber: 5,
                        title: 'Generate & Download',
                        description: 'Create your project',
                        icon: Icons.download,
                        isActive: _currentStep == 4,
                        isCompleted: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxAiPanelHeight = _aiPanelExpanded
                    ? (_aiSuggestion != null
                          ? (constraints.maxHeight * 0.45).clamp(280.0, 420.0)
                          : 250.0)
                    : 88.0;

                return Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxAiPanelHeight),
                      child: SingleChildScrollView(
                        child: AppBuilderAiPanel(
                          descriptionController: _aiDescriptionController,
                          isLoading: _isAiLoading,
                          isExpanded: _aiPanelExpanded,
                          suggestion: _aiSuggestion,
                          availableWidgets: availableWidgets,
                          availableManagers: _availableManagers,
                          onToggleExpanded: () {
                            setState(() {
                              _aiPanelExpanded = !_aiPanelExpanded;
                            });
                          },
                          onSuggest: _requestAiSuggestion,
                          onApply: _applyAiSuggestion,
                          onClearSuggestion: () {
                            setState(() {
                              _aiSuggestion = null;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(child: _buildCurrentStep()),
                    // Navigation Buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentStep--;
                                });
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            )
                          else
                            const SizedBox(),
                          ElevatedButton.icon(
                            onPressed: _currentStep < 4
                                ? () {
                                    setState(() {
                                      _currentStep++;
                                    });
                                  }
                                : _generateProject,
                            icon: Icon(
                              _currentStep < 4
                                  ? Icons.arrow_forward
                                  : Icons.download,
                            ),
                            label: Text(
                              _currentStep < 4
                                  ? 'Next Step'
                                  : 'Generate Project',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppChrome.ink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? AppChrome.ink.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppChrome.ink
              : isCompleted
              ? Colors.green
              : Colors.transparent,
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                ? AppChrome.ink
                : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Icon(
                    icon,
                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    size: 20,
                  ),
          ),
        ),
        title: Text(
          title,
          style: AppChrome.body(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppChrome.ink : AppChrome.ink,
          ),
        ),
        subtitle: Text(
          description,
          style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
        ),
        trailing: Text(
          '$stepNumber',
          style: AppChrome.body(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildThemeStep();
      case 1:
        return _buildWidgetStep();
      case 2:
        return _buildManagersStep();
      case 3:
        return _buildModelStep();
      case 4:
        return _buildGenerateStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildManagersStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppChrome.ink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.manage_accounts,
                  color: AppChrome.ink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Feature',
                    style: AppChrome.body(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppChrome.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick singleton managers (optional)',
                    style: AppChrome.body(fontSize: 16, color: AppChrome.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<ManagerDefinition>>(
            stream: _firestoreService.getManagers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: AppChrome.body(),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final managers = snapshot.data ?? [];
              if (managers.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No managers yet. Add managers from the admin panel.',
                    style: AppChrome.body(),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (final m in managers)
                      CheckboxListTile(
                        value: selectedManagerIds.contains(m.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedManagerIds = {
                                ...selectedManagerIds,
                                m.id,
                              }.toList();
                            } else {
                              selectedManagerIds = selectedManagerIds
                                  .where((id) => id != m.id)
                                  .toList();
                            }
                          });
                        },
                        title: Text(
                          m.title,
                          style: AppChrome.body(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          m.description,
                          style: AppChrome.body(fontSize: 12),
                        ),
                        secondary: Text(
                          m.fileName,
                          style: AppChrome.body(
                            fontSize: 11,
                            color: AppChrome.muted,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Selected: ${selectedManagerIds.length}',
            style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppChrome.ink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette,
                  color: AppChrome.ink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Theme',
                    style: AppChrome.body(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppChrome.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select colors for your app theme',
                    style: AppChrome.body(fontSize: 16, color: AppChrome.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Theme Mode Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton(
                  'Light Mode',
                  Icons.light_mode,
                  !isDarkMode,
                  () {
                    setState(() => isDarkMode = false);
                  },
                ),
                _buildModeButton('Dark Mode', Icons.dark_mode, isDarkMode, () {
                  setState(() => isDarkMode = true);
                }),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Color Pickers
          Row(
            children: [
              Expanded(
                child: _buildColorCard(
                  'Primary',
                  'Main brand color',
                  primaryColor,
                  (color) => setState(() => primaryColor = color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildColorCard(
                  'Secondary',
                  'Accent color',
                  secondaryColor,
                  (color) => setState(() => secondaryColor = color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildColorCard(
                  'Tertiary',
                  'Additional accent',
                  tertiaryColor,
                  (color) => setState(() => tertiaryColor = color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppChrome.ink : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppChrome.body(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppChrome.ink : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard(
    String label,
    String description,
    Color color,
    ValueChanged<Color> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showColorPickerDialog(color, onChanged),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.colorize, color: Colors.white, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppChrome.body(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppChrome.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppChrome.body(fontSize: 13, color: AppChrome.muted),
          ),
          const SizedBox(height: 8),
          Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showColorPickerDialog(color, onChanged),
              icon: const Icon(Icons.colorize, size: 16),
              label: const Text('Change Color'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppChrome.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick a Color',
                style: AppChrome.body(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _predefinedColors.length,
                  itemBuilder: (context, index) {
                    final color = _predefinedColors[index];
                    final isSelected = currentColor.value == color.value;
                    final hexCode =
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              onColorChanged(color);
                              Navigator.pop(dialogContext);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.black12,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hexCode,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: AppChrome.muted,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Predefined color palette
  static final List<Color> _predefinedColors = [
    // Reds
    const Color(0xFFFF6B6B),
    const Color(0xFFEE5A6F),
    const Color(0xFFC44569),
    // Oranges
    const Color(0xFFFF9F43),
    const Color(0xFFFC5C65),
    const Color(0xFFFD7272),
    // Yellows
    const Color(0xFFFECA57),
    const Color(0xFFFFD93D),
    const Color(0xFFF8B500),
    // Greens
    const Color(0xFF6BCF7F),
    const Color(0xFF26DE81),
    const Color(0xFF20BF6B),
    // Blues
    const Color(0xFF45AAF2),
    const Color(0xFF4B7BEC),
    const Color(0xFF3867D6),
    // Purples
    AppChrome.ink,
    const Color(0xFF5F27CD),
    const Color(0xFFA55EEA),
    // Pinks
    const Color(0xFFFC427B),
    const Color(0xFFF78FB3),
    const Color(0xFFD980FA),
    // Teals
    const Color(0xFF00D2D3),
    const Color(0xFF1DD1A1),
    const Color(0xFF10AC84),
    // Grays
    const Color(0xFF778CA3),
    const Color(0xFF4B6584),
    const Color(0xFF2C3E50),
    // Others
    const Color(0xFF00B894),
    const Color(0xFF00CEC9),
    const Color(0xFF0984E3),
  ];

  Widget _buildWidgetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppChrome.ink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.widgets,
                  color: AppChrome.ink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Widgets',
                      style: AppChrome.body(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppChrome.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose UI components for your app (${selectedWidgetIds.length} selected)',
                      style: AppChrome.body(
                        fontSize: 16,
                        color: AppChrome.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedWidgetIds.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedWidgetIds.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          if (availableWidgets.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading widgets...',
                    style: AppChrome.body(fontSize: 16, color: AppChrome.muted),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemCount: availableWidgets.length,
              itemBuilder: (context, index) {
                final widget = availableWidgets[index];
                final isSelected = selectedWidgetIds.contains(widget.id);

                return _buildWidgetCard(widget, isSelected, () {
                  setState(() {
                    if (isSelected) {
                      selectedWidgetIds.remove(widget.id);
                    } else {
                      selectedWidgetIds.add(widget.id);
                    }
                  });
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWidgetCard(
    WidgetShowcase widget,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppChrome.ink : const Color(0xFFE5E7EB),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppChrome.ink.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Widget Preview Image
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      color: AppChrome.canvas,
                      child: widget.gifPath.isNotEmpty
                          ? Image.network(
                              _getProxyUrl(widget.gifPath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.widgets,
                                    size: 48,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.widgets,
                                size: 48,
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                    ),
                  ),
                ),
                // Widget Info
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: AppChrome.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppChrome.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category,
                          style: AppChrome.body(
                            fontSize: 12,
                            color: AppChrome.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Selection Indicator
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppChrome.ink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
    } catch (e) {
      print('Proxy URL parse error: $e');
    }

    return firebaseUrl;
  }

  Widget _buildModelStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppChrome.ink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code, color: AppChrome.ink, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Data Models',
                      style: AppChrome.body(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppChrome.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate ArkTS classes from JSON (${models.length} models)',
                      style: AppChrome.body(
                        fontSize: 16,
                        color: AppChrome.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Model List
              Expanded(
                flex: 1,
                child: Container(
                  height: 500,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Models',
                            style: AppChrome.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppChrome.ink,
                            ),
                          ),
                          Text(
                            '${models.length}',
                            style: AppChrome.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppChrome.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: models.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No models yet',
                                      style: AppChrome.body(
                                        fontSize: 14,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add your first model →',
                                      style: AppChrome.body(
                                        fontSize: 12,
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: models.length,
                                itemBuilder: (context, index) {
                                  final model = models[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppChrome.canvas,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppChrome.ink.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.data_object,
                                            size: 20,
                                            color: AppChrome.ink,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${model['name']}.ets',
                                                style:
                                                    GoogleFonts.jetBrainsMono(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppChrome.ink,
                                                    ),
                                              ),
                                              Text(
                                                '${model['fields']?.length ?? 0} fields',
                                                style: AppChrome.body(
                                                  fontSize: 11,
                                                  color: AppChrome.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          color: Colors.red,
                                          onPressed: () {
                                            setState(() {
                                              models.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right: Add Model Form
              Expanded(
                flex: 2,
                child: Container(
                  height: 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Model',
                        style: AppChrome.body(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppChrome.ink,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Model Name Input
                      TextField(
                        controller: _modelNameController,
                        decoration: InputDecoration(
                          labelText: 'Model Name',
                          hintText: 'e.g., User, Product, Order',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.abc),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nullable checkbox
                      CheckboxListTile(
                        title: Text(
                          'Make properties nullable',
                          style: AppChrome.body(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Add ? to all properties',
                          style: AppChrome.body(
                            fontSize: 11,
                            color: AppChrome.muted,
                          ),
                        ),
                        value: _makeModelsNullable,
                        onChanged: (value) {
                          setState(() {
                            _makeModelsNullable = value ?? false;
                          });
                        },
                        activeColor: AppChrome.ink,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),

                      const SizedBox(height: 12),

                      // JSON Input
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2D2D2D),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'JSON Data',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        color: const Color(0xFFCCCCCC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _jsonController,
                                  maxLines: null,
                                  expands: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                    hintText:
                                        '{\n  "id": 1,\n  "name": "John",\n  "email": "john@example.com"\n}',
                                    hintStyle: TextStyle(
                                      color: AppChrome.muted,
                                    ),
                                  ),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    color: const Color(0xFFD4D4D4),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Add Model Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addModel,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Model'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppChrome.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addModel() {
    final name = _modelNameController.text.trim();
    final jsonText = _jsonController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a model name', style: AppChrome.body()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (jsonText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter JSON data', style: AppChrome.body()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final jsonData = json.decode(jsonText);

      if (jsonData is! Map<String, dynamic>) {
        throw Exception('JSON must be an object');
      }

      // Extract field names and types
      final fields = <Map<String, String>>[];
      jsonData.forEach((key, value) {
        fields.add({'name': key, 'type': _getJsonType(value)});
      });

      setState(() {
        models.add({
          'name': name,
          'json': jsonText,
          'nullable': _makeModelsNullable,
          'fields': fields,
        });

        // Clear form
        _modelNameController.clear();
        _jsonController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Model "$name" added successfully!',
                style: AppChrome.body(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid JSON: ${e.toString()}',
            style: AppChrome.body(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getJsonType(dynamic value) {
    if (value == null) return 'any';
    if (value is int || value is double) return 'number';
    if (value is bool) return 'boolean';
    if (value is String) return 'string';
    if (value is List) return 'array';
    if (value is Map) return 'object';
    return 'any';
  }

  Widget _buildGenerateStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppChrome.ink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: AppChrome.ink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate Your App',
                      style: AppChrome.body(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppChrome.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure project details and download',
                      style: AppChrome.body(
                        fontSize: 16,
                        color: AppChrome.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Project Info Form
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Information',
                        style: AppChrome.body(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppChrome.ink,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Project Name
                      TextField(
                        controller: _projectNameController,
                        decoration: InputDecoration(
                          labelText: 'Project Name',
                          hintText: 'MyArkUIApp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.folder),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bundle ID
                      TextField(
                        controller: _bundleIdController,
                        decoration: InputDecoration(
                          labelText: 'Bundle ID',
                          hintText: 'com.example.myapp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'A beautiful ArkUI application',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // SDK Version
                      TextField(
                        controller: _sdkVersionController,
                        decoration: InputDecoration(
                          labelText: 'SDK Version',
                          hintText: '5.1.0(18)',
                          helperText: 'DevEco > Project Structure > Basic Info',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.system_update),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right: Summary
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Summary',
                        style: AppChrome.body(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppChrome.ink,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSummaryItem(
                        Icons.palette,
                        'Theme',
                        isDarkMode ? 'Dark Mode' : 'Light Mode',
                        '3 colors selected',
                      ),
                      const SizedBox(height: 16),

                      _buildSummaryItem(
                        Icons.widgets,
                        'Widgets',
                        '${selectedWidgetIds.length} components',
                        selectedWidgetIds.isEmpty
                            ? 'No widgets selected'
                            : 'Ready to use',
                      ),
                      const SizedBox(height: 16),

                      _buildSummaryItem(
                        Icons.code,
                        'Models',
                        '${models.length} data models',
                        models.isEmpty
                            ? 'No models added'
                            : 'With fromJson/toJson',
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppChrome.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppChrome.ink,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'What will be generated?',
                                  style: AppChrome.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppChrome.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildBulletPoint(
                              'Complete ArkUI project structure',
                            ),
                            _buildBulletPoint('Theme configuration files'),
                            _buildBulletPoint('Selected widget components'),
                            _buildBulletPoint('Data model classes'),
                            _buildBulletPoint('Ready to build & run'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _generateProject,
                          icon: const Icon(Icons.download, size: 24),
                          label: Text(
                            'Generate & Download',
                            style: AppChrome.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppChrome.ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppChrome.ink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppChrome.ink, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
              ),
              Text(
                value,
                style: AppChrome.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppChrome.ink,
                ),
              ),
              Text(
                subtitle,
                style: AppChrome.body(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateProject() async {
    final projectName = _projectNameController.text.trim();
    final bundleId = _bundleIdController.text.trim();
    final description = _descriptionController.text.trim();
    final sdkVersion = _sdkVersionController.text.trim();

    if (projectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a project name', style: AppChrome.body()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (bundleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a bundle ID', style: AppChrome.body()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (sdkVersion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter SDK version', style: AppChrome.body()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Generating your ArkUI project...', style: AppChrome.body()),
          ],
        ),
      ),
    );

    try {
      // Get selected widgets
      final selectedWidgets = availableWidgets
          .where((w) => selectedWidgetIds.contains(w.id))
          .map(
            (w) => {
              'id': w.id,
              'title': w.title,
              'category': w.category,
              'code': w.code,
            },
          )
          .toList();

      final managerDocs = await _firestoreService.getManagers().first;
      final selectedManagers = managerDocs
          .where((m) => selectedManagerIds.contains(m.id))
          .map(
            (m) => {
              'id': m.id,
              'title': m.title,
              'className': m.className,
              'exportCode': m.exportCode,
              'permissions': m.permissions,
              'code': m.code,
            },
          )
          .toList();

      // Generate and download the project
      await ProjectGenerator.generateAndDownload(
        projectName: projectName,
        bundleId: bundleId,
        description: description,
        primaryColor: '#${primaryColor.value.toRadixString(16).substring(2)}',
        secondaryColor:
            '#${secondaryColor.value.toRadixString(16).substring(2)}',
        tertiaryColor: '#${tertiaryColor.value.toRadixString(16).substring(2)}',
        isDarkMode: isDarkMode,
        selectedWidgets: selectedWidgets,
        selectedManagers: selectedManagers,
        models: models,
        sdkVersion: sdkVersion,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Success!',
                  style: AppChrome.body(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ArkUI project has been generated and downloaded!',
                  style: AppChrome.body(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppChrome.canvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Project:', projectName),
                      _buildInfoRow('Bundle ID:', bundleId),
                      _buildInfoRow('SDK:', sdkVersion),
                      _buildInfoRow('Theme:', isDarkMode ? 'Dark' : 'Light'),
                      _buildInfoRow('Widgets:', '${selectedWidgetIds.length}'),
                      _buildInfoRow(
                        'Managers:',
                        '${selectedManagerIds.length}',
                      ),
                      _buildInfoRow('Models:', '${models.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Check your Downloads folder for $projectName.zip',
                          style: AppChrome.body(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating project: $e',
              style: AppChrome.body(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppChrome.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppChrome.muted,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppChrome.body(fontSize: 12, color: AppChrome.ink),
          ),
        ],
      ),
    );
  }
}
