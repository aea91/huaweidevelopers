import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/manager_definition.dart';
import '../services/firestore_service.dart';

class AdminAddManagerScreen extends StatefulWidget {
  final ManagerDefinition? manager;

  const AdminAddManagerScreen({super.key, this.manager});

  @override
  State<AdminAddManagerScreen> createState() => _AdminAddManagerScreenState();
}

class _AdminAddManagerScreenState extends State<AdminAddManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _classNameController;
  late TextEditingController _exportCodeController;
  late TextEditingController _customPermissionController;
  late TextEditingController _codeController;
  final List<String> _defaultPermissionTemplates = const [
    'ohos.permission.INTERNET',
    'ohos.permission.LOCATION',
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.CAMERA',
    'ohos.permission.MICROPHONE',
    'ohos.permission.READ_IMAGEVIDEO',
    'ohos.permission.WRITE_IMAGEVIDEO',
    'ohos.permission.FILE_ACCESS_PERSIST',
    'ohos.permission.READ_CONTACTS',
  ];
  List<String> _permissionTemplates = [];
  Set<String> _selectedPermissions = {};

  bool _isLoading = false;

  String _normalizePermission(String value) {
    return value.trim().toUpperCase();
  }

  bool _containsPermission(Set<String> permissions, String candidate) {
    final normalized = _normalizePermission(candidate);
    return permissions.any((p) => _normalizePermission(p) == normalized);
  }

  @override
  void initState() {
    super.initState();
    final m = widget.manager;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _classNameController = TextEditingController(text: m?.className ?? '');
    _exportCodeController = TextEditingController(text: m?.exportCode ?? '');
    _customPermissionController = TextEditingController();
    _selectedPermissions = {
      ...?m?.permissions.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };
    _codeController = TextEditingController(text: m?.code ?? '');
    _loadPermissionTemplates();
  }

  Future<void> _loadPermissionTemplates() async {
    try {
      final remote = await _firestoreService.getManagerPermissionTemplates();
      if (!mounted) return;
      setState(() {
        _permissionTemplates = remote.isNotEmpty
            ? remote
            : List<String>.from(_defaultPermissionTemplates);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _permissionTemplates = List<String>.from(_defaultPermissionTemplates);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _classNameController.dispose();
    _exportCodeController.dispose();
    _customPermissionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? _validateClassName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Class name is required';
    final ok = RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(v);
    if (!ok) return 'Example: StorageManager (PascalCase)';
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newManager = ManagerDefinition(
        id: widget.manager?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        className: _classNameController.text.trim(),
        exportCode: _exportCodeController.text.trim(),
        permissions: _selectedPermissions.toList()..sort(),
        code: _codeController.text.trim(),
      );

      if (widget.manager == null) {
        await _firestoreService.addManager(newManager);
      } else {
        await _firestoreService.updateManager(widget.manager!.id, newManager);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.manager == null ? 'Manager added' : 'Manager updated',
              style: GoogleFonts.inter(),
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
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.manager != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Manager' : 'Add New Manager',
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
            _card(
              title: 'Basic Information',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _classNameController,
                    decoration: const InputDecoration(
                      labelText: 'Class Name (example: StorageManager)',
                    ),
                    validator: _validateClassName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _exportCodeController,
                    decoration: const InputDecoration(
                      labelText: "Export Code (opsiyonel)",
                      hintText:
                          "export { StorageManager } from './src/main/ets/managers/StorageManager';",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Permissions',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _permissionTemplates.map((p) {
                      return FilterChip(
                        label: Text(p, style: GoogleFonts.inter(fontSize: 12)),
                        selected: _selectedPermissions.contains(p),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPermissions.add(p);
                            } else {
                              _selectedPermissions.remove(p);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _customPermissionController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Permission',
                            hintText: 'ohos.permission.YOUR_CUSTOM_PERMISSION',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final value = _customPermissionController.text.trim();
                          if (value.isEmpty) return;
                          setState(() {
                            if (!_containsPermission(
                              _selectedPermissions,
                              value,
                            )) {
                              _selectedPermissions.add(value);
                            }
                          });
                          _customPermissionController.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_selectedPermissions.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedPermissions.map((p) {
                        return Chip(
                          label: Text(
                            p,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedPermissions.remove(p);
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              title: 'ArkTS Code',
              child: TextFormField(
                controller: _codeController,
                minLines: 10,
                maxLines: 30,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Code is required' : null,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSave,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'Update' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B21B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
