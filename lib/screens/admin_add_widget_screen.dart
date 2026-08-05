import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../models/widget_showcase.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class AdminAddWidgetScreen extends StatefulWidget {
  final WidgetShowcase? widget;

  const AdminAddWidgetScreen({super.key, this.widget});

  @override
  State<AdminAddWidgetScreen> createState() => _AdminAddWidgetScreenState();
}

class _AdminAddWidgetScreenState extends State<AdminAddWidgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _codeController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;

  bool _isLoading = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _existingGifUrl;

  // Main category dropdown
  String _selectedMainCategory = 'Mobile';
  final List<String> _mainCategories = [
    'Mobile',
    'Smart Wearable',
    'PC (2in1)',
  ];

  @override
  void initState() {
    super.initState();
    final w = widget.widget;
    _titleController = TextEditingController(text: w?.title ?? '');
    _descriptionController = TextEditingController(text: w?.description ?? '');
    _codeController = TextEditingController(text: w?.code ?? '');
    _categoryController = TextEditingController(text: w?.category ?? '');
    _tagsController = TextEditingController(text: w?.tags.join(', ') ?? '');
    _existingGifUrl = w?.gifPath;
    _selectedMainCategory = w?.mainCategory ?? 'Mobile';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickGifFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif', 'png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes == null) {
          throw Exception('Could not read the file');
        }

        if (!_storageService.isFileSizeValid(file.bytes!.length)) {
          throw Exception('The file must be smaller than 5 MB');
        }

        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFileBytes == null && _existingGifUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String gifUrl = _existingGifUrl ?? '';

      // Upload the newly selected GIF
      if (_selectedFileBytes != null && _selectedFileName != null) {
        gifUrl = await _storageService.uploadGif(
          _selectedFileBytes!,
          _selectedFileName!,
        );
      }

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newWidget = WidgetShowcase(
        id: widget.widget?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        mainCategory: _selectedMainCategory,
        category: _categoryController.text.trim(),
        gifPath: gifUrl,
        code: _codeController.text.trim(),
        tags: tags,
      );

      if (widget.widget == null) {
        // Add a new widget
        await _firestoreService.addWidget(newWidget, gifUrl);
      } else {
        // Update the existing widget
        await _firestoreService.updateWidget(
          widget.widget!.id,
          newWidget,
          _selectedFileBytes != null ? gifUrl : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.widget == null
                  ? 'Widget added successfully'
                  : 'Widget updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.widget != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Widget' : 'Add New Widget',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5B21B6),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // GIF Upload Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Widget Image',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_existingGifUrl != null && _selectedFileBytes == null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingGifUrl!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (_selectedFileName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image, color: Color(0xFF5B21B6)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFileName!,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedFileBytes = null;
                                _selectedFileName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickGifFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _existingGifUrl != null ? 'Change Image' : 'Select Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B21B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max 5MB - GIF, PNG, JPG, JPEG, WebP',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Fields
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Widget Title *',
                      border: OutlineInputBorder(),
                      hintText: 'example: Bottom Nav Bar Gradient',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                      hintText: 'A short description of the widget',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Main Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedMainCategory,
                    decoration: const InputDecoration(
                      labelText: 'Platform *',
                      border: OutlineInputBorder(),
                    ),
                    items: _mainCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMainCategory = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Platform is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Widget Category *',
                      border: OutlineInputBorder(),
                      hintText: 'example: Navigation, Cards, Buttons',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Widget category is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'example: navigation, gradient, animated',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Code
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'ArkTS Code *',
                      border: OutlineInputBorder(),
                      hintText: '@Component\nstruct YourWidget {\n  ...\n}',
                    ),
                    maxLines: 15,
                    style: GoogleFonts.jetBrainsMono(fontSize: 13),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Code is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B21B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update' : 'Save',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
