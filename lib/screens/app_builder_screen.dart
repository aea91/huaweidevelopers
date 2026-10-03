import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_chrome.dart';
import '../models/manager_definition.dart';
import '../models/widget_showcase.dart';
import '../services/firestore_service.dart';
import '../services/project_generator.dart';

/// A composed page in the App Builder: a name plus an ordered list of widget ids.
class AppPage {
  String name;
  final List<String> widgetIds;
  AppPage({required this.name, List<String>? widgetIds})
      : widgetIds = widgetIds ?? [];
}

class AppBuilderScreen extends StatefulWidget {
  const AppBuilderScreen({super.key});

  @override
  State<AppBuilderScreen> createState() => _AppBuilderScreenState();
}

class _AppBuilderScreenState extends State<AppBuilderScreen> {
  final _firestoreService = FirestoreService();
  int _currentStep = 0;

  // Step 1: Theme Data
  Color primaryColor = AppChrome.ink;
  Color secondaryColor = const Color(0xFF03DAC6);
  Color tertiaryColor = const Color(0xFFFF6B6B);
  bool isDarkMode = false;

  // Step 2: Selected Widgets
  List<String> selectedWidgetIds = [];
  List<WidgetShowcase> availableWidgets = [];

  // Step 3: Design Pages (compose + live preview)
  final List<AppPage> _pages = [AppPage(name: 'Home')];
  int _activePageIndex = 0;
  String _previewDevice = 'Mobile'; // Mobile / Tablet / Wearable / PC
  int _wearIndex = 0; // which widget the round watch preview is showing
  String _catalogQuery = '';
  String _catalogPlatform = 'All';

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
  }

  Future<void> _loadWidgets() async {
    final widgets = await _firestoreService.getWidgets().first;
    setState(() {
      availableWidgets = widgets;
    });
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
                        title: 'Design Pages',
                        description: 'Compose & preview pages',
                        icon: Icons.phone_iphone,
                        isActive: _currentStep == 2,
                        isCompleted: _currentStep > 2,
                      ),
                      _buildStepItem(
                        stepNumber: 4,
                        title: 'Add Feature',
                        description: 'Select managers/features',
                        icon: Icons.manage_accounts,
                        isActive: _currentStep == 3,
                        isCompleted: _currentStep > 3,
                      ),
                      _buildStepItem(
                        stepNumber: 5,
                        title: 'Add Models',
                        description: 'Generate data models',
                        icon: Icons.code,
                        isActive: _currentStep == 4,
                        isCompleted: _currentStep > 4,
                      ),
                      _buildStepItem(
                        stepNumber: 6,
                        title: 'Generate & Download',
                        description: 'Create your project',
                        icon: Icons.download,
                        isActive: _currentStep == 5,
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
            child: Column(
              children: [
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
                            onPressed: _currentStep < 5
                                ? () {
                                    setState(() {
                                      _currentStep++;
                                    });
                                  }
                                : _generateProject,
                            icon: Icon(
                              _currentStep < 5
                                  ? Icons.arrow_forward
                                  : Icons.download,
                            ),
                            label: Text(
                              _currentStep < 5
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
        return _buildPagesStep();
      case 3:
        return _buildManagersStep();
      case 4:
        return _buildModelStep();
      case 5:
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

  // ==========================================================================
  // Step 3: Design Pages (compose + live device preview)
  // ==========================================================================

  // Nominal frame sizes with realistic aspect ratios; a FittedBox scales the
  // frame to fill the available preview area, so these only set proportions.
  double get _pvW {
    switch (_previewDevice) {
      case 'PC':
        return 720; // 16:10 landscape
      case 'Tablet':
        return 540; // ~3:4 portrait
      case 'Wearable':
        return 340; // round 1:1
      default:
        return 340; // phone 19.5:9 portrait
    }
  }

  double get _pvH {
    switch (_previewDevice) {
      case 'PC':
        return 450;
      case 'Tablet':
        return 720;
      case 'Wearable':
        return 340;
      default:
        return 736;
    }
  }

  Widget _buildPagesStep() {
    if (_activePageIndex >= _pages.length) _activePageIndex = _pages.length - 1;
    final page = _pages[_activePageIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppChrome.ink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_iphone,
                    color: AppChrome.ink, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Design Pages',
                        style: AppChrome.body(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppChrome.ink)),
                    const SizedBox(height: 4),
                    Text(
                        'Add widgets to a page and preview it live before generating',
                        style:
                            AppChrome.body(fontSize: 16, color: AppChrome.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
          child: _pageTabs(),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _catalogPane(page)),
                const SizedBox(width: 24),
                _previewPane(page),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageTabs() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final active = i == _activePageIndex;
                return InkWell(
                  onTap: () => setState(() => _activePageIndex = i),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color:
                          active ? AppChrome.ink : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: active
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_pages[i].name,
                            style: AppChrome.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF334155))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${_pages[i].widgetIds.length}',
                              style: AppChrome.body(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Rename page',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: _renameActivePage,
          ),
          if (_pages.length > 1)
            IconButton(
              tooltip: 'Delete page',
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: () => setState(() {
                _pages.removeAt(_activePageIndex);
                _activePageIndex =
                    _activePageIndex.clamp(0, _pages.length - 1);
              }),
            ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _pages.add(AppPage(name: 'Page ${_pages.length + 1}'));
              _activePageIndex = _pages.length - 1;
            }),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Page'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameActivePage() async {
    final ctrl =
        TextEditingController(text: _pages[_activePageIndex].name);
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Rename page', style: AppChrome.body(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Page name'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _pages[_activePageIndex].name = name.trim());
    }
  }

  Widget _catalogPane(AppPage page) {
    final q = _catalogQuery.toLowerCase();
    final filtered = availableWidgets.where((w) {
      final okP =
          _catalogPlatform == 'All' || w.mainCategory == _catalogPlatform;
      final okQ = q.isEmpty ||
          w.title.toLowerCase().contains(q) ||
          w.category.toLowerCase().contains(q);
      return okP && okQ;
    }).toList();
    const platforms = ['All', 'Mobile', 'Smart Wearable', 'PC (2in1)'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _catalogQuery = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Search widgets…',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: platforms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final p = platforms[i];
                final sel = _catalogPlatform == p;
                return GestureDetector(
                  onTap: () => setState(() => _catalogPlatform = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppChrome.ink : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(WidgetShowcase.platformLabel(p),
                        style: AppChrome.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : const Color(0xFF475569))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: availableWidgets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) {
                      final w = filtered[i];
                      final added = page.widgetIds.contains(w.id);
                      return _catalogTile(w, added, () {
                        setState(() {
                          if (added) {
                            page.widgetIds.remove(w.id);
                          } else {
                            page.widgetIds.add(w.id);
                          }
                        });
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _catalogTile(WidgetShowcase w, bool added, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: added ? AppChrome.ink : const Color(0xFFE5E7EB),
            width: added ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    child: w.gifPath.isNotEmpty
                        ? Image.network(_getProxyUrl(w.gifPath),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Center(
                                child: Icon(Icons.widgets,
                                    size: 32, color: Color(0xFFCBD5E1))))
                        : const Center(
                            child: Icon(Icons.widgets,
                                size: 32, color: Color(0xFFCBD5E1))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: Text(w.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppChrome.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppChrome.ink)),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: added ? AppChrome.ink : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(added ? Icons.check : Icons.add,
                    size: 16,
                    color: added ? Colors.white : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPane(AppPage page) {
    return SizedBox(
      width: 490,
      child: Column(
        children: [
          // device toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['Mobile', 'Tablet', 'Wearable', 'PC'].map((d) {
                final sel = _previewDevice == d;
                return GestureDetector(
                  onTap: () => setState(() => _previewDevice = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6)
                            ]
                          : null,
                    ),
                    child: Text(d,
                        style: AppChrome.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? AppChrome.ink
                                : const Color(0xFF94A3B8))),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: _deviceFrame(page),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
              '$_previewDevice · ${page.widgetIds.length} sections',
              style: AppChrome.body(fontSize: 12, color: AppChrome.muted)),
        ],
      ),
    );
  }

  Widget _deviceFrame(AppPage page) {
    final dark = isDarkMode;
    if (_previewDevice == 'Wearable') {
      // Round smart-watch: always a dark round screen.
      return Container(
        width: _pvW,
        height: _pvH,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 14))
          ],
        ),
        child: ClipOval(child: _watchScreen(page)),
      );
    }
    if (_previewDevice == 'PC') {
      return Container(
        width: _pvW,
        height: _pvH,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF0F1424) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 16))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 34,
              color: dark ? const Color(0xFF161B2E) : const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  _Dot(Color(0xFFFF5F57)),
                  SizedBox(width: 7),
                  _Dot(Color(0xFFFEBC2E)),
                  SizedBox(width: 7),
                  _Dot(Color(0xFF28C840)),
                ],
              ),
            ),
            Expanded(child: _pageScreen(page, dark)),
          ],
        ),
      );
    }
    final radius = _previewDevice == 'Tablet' ? 26.0 : 42.0;
    final inner = _previewDevice == 'Tablet' ? 18.0 : 32.0;
    return Container(
      width: _pvW,
      height: _pvH,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 32,
              offset: const Offset(0, 16))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(inner),
        child: Stack(
          children: [
            _pageScreen(page, dark),
            if (_previewDevice == 'Mobile')
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 120,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pageScreen(AppPage page, bool dark) {
    final bg = dark ? const Color(0xFF0B1020) : const Color(0xFFF7F8FB);
    if (page.widgetIds.isEmpty) {
      return Container(
        color: bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_to_queue,
                  size: 40,
                  color: dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              const SizedBox(height: 12),
              Text('Add widgets\nfrom the left',
                  textAlign: TextAlign.center,
                  style: AppChrome.body(
                      fontSize: 13,
                      color: dark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }
    final byId = {for (final w in availableWidgets) w.id: w};
    final ws = [
      for (final id in page.widgetIds)
        if (byId[id] != null) byId[id]!
    ];
    return Container(
      color: bg,
      child: ListView.separated(
        padding: _previewDevice == 'Wearable'
            ? const EdgeInsets.fromLTRB(34, 44, 34, 44)
            : EdgeInsets.fromLTRB(
                12, _previewDevice == 'Mobile' ? 34 : 14, 12, 16),
        itemCount: ws.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (c, i) => _sectionCard(page, ws[i], i, dark),
      ),
    );
  }

  // Round smart-watch preview: one widget fills the round face (like a real
  // watch screen), with prev/next, remove, and page dots — no top/bottom crop.
  Widget _watchScreen(AppPage page) {
    const bg = Color(0xFF0B0B0F);
    final byId = {for (final w in availableWidgets) w.id: w};
    final ws = [
      for (final id in page.widgetIds)
        if (byId[id] != null) byId[id]!
    ];
    if (ws.isEmpty) {
      return Container(
        color: bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_to_queue, color: Color(0xFF334155), size: 30),
              const SizedBox(height: 8),
              Text('Add widgets',
                  style: AppChrome.body(
                      fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }
    final idx = _wearIndex.clamp(0, ws.length - 1);
    final w = ws[idx];
    return Container(
      color: bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          w.gifPath.isNotEmpty
              ? Image.network(_getProxyUrl(w.gifPath),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(
                      child:
                          Icon(Icons.watch, color: Color(0xFF334155), size: 40)))
              : const Center(
                  child: Icon(Icons.watch, color: Color(0xFF334155), size: 40)),
          // remove current
          Positioned(
            top: 26,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  page.widgetIds.remove(w.id);
                  if (_wearIndex >= page.widgetIds.length) _wearIndex = 0;
                }),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          if (ws.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _wearChevron(Icons.chevron_left,
                    () => setState(() => _wearIndex = (idx - 1 + ws.length) % ws.length)),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _wearChevron(Icons.chevron_right,
                    () => setState(() => _wearIndex = (idx + 1) % ws.length)),
              ),
            ),
          ],
          Positioned(
            bottom: 26,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                ws.length,
                (i) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        i == idx ? Colors.white : Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wearChevron(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }

  Widget _sectionCard(AppPage page, WidgetShowcase w, int index, bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF161B2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: dark ? const Color(0xFF252542) : const Color(0xFFEEF1F5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              color: dark ? Colors.black : const Color(0xFFF1F5F9),
              child: w.gifPath.isNotEmpty
                  ? Image.network(_getProxyUrl(w.gifPath),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                          child: Icon(Icons.widgets,
                              size: 32,
                              color: dark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1))))
                  : Center(
                      child: Icon(Icons.widgets,
                          size: 32,
                          color: dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(w.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppChrome.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : AppChrome.ink)),
                ),
                _miniBtn(Icons.arrow_upward, index > 0,
                    () => _movePageItem(page, index, -1), dark),
                _miniBtn(Icons.arrow_downward,
                    index < page.widgetIds.length - 1,
                    () => _movePageItem(page, index, 1), dark),
                _miniBtn(Icons.close, true,
                    () => setState(() => page.widgetIds.removeAt(index)), dark,
                    red: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, bool enabled, VoidCallback onTap, bool dark,
      {bool red = false}) {
    final color = !enabled
        ? const Color(0xFFCBD5E1)
        : red
            ? Colors.red
            : (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
      iconSize: 17,
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, color: color),
    );
  }

  void _movePageItem(AppPage page, int index, int delta) {
    final ni = index + delta;
    if (ni < 0 || ni >= page.widgetIds.length) return;
    setState(() {
      final id = page.widgetIds.removeAt(index);
      page.widgetIds.insert(ni, id);
    });
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
      // Widgets to bundle = everything selected in step 2 PLUS anything placed
      // on a page in the Design Pages step (so every page reference has code).
      final pageWidgetIds = _pages.expand((p) => p.widgetIds).toSet();
      final allWidgetIds = {...selectedWidgetIds, ...pageWidgetIds};
      final selectedWidgets = availableWidgets
          .where((w) => allWidgetIds.contains(w.id))
          .map(
            (w) => {
              'id': w.id,
              'title': w.title,
              'category': w.category,
              'code': w.code,
            },
          )
          .toList();

      // Composed pages (skip empty pages; generator falls back to a single
      // Home page of all widgets when none have content).
      final pagesPayload = _pages
          .where((p) => p.widgetIds.isNotEmpty)
          .map((p) => {
                'name': p.name,
                'widgetIds': List<String>.from(p.widgetIds),
              })
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
        pages: pagesPayload,
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

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) =>
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
