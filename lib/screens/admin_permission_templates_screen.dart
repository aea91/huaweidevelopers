import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';

class AdminPermissionTemplatesScreen extends StatefulWidget {
  const AdminPermissionTemplatesScreen({super.key});

  @override
  State<AdminPermissionTemplatesScreen> createState() =>
      _AdminPermissionTemplatesScreenState();
}

class _AdminPermissionTemplatesScreenState
    extends State<AdminPermissionTemplatesScreen> {
  final _firestoreService = FirestoreService();
  final _controller = TextEditingController();
  List<String> _permissions = [];
  bool _loading = true;
  bool _saving = false;

  String _normalizePermission(String value) {
    return value.trim().toUpperCase();
  }

  bool _existsInList(List<String> list, String candidate) {
    final normalized = _normalizePermission(candidate);
    return list.any((p) => _normalizePermission(p) == normalized);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _firestoreService.getManagerPermissionTemplates();
      if (!mounted) return;
      setState(() {
        _permissions = data..sort();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading failed: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final unique =
          _permissions.toSet().where((e) => e.trim().isNotEmpty).toList()
            ..sort();
      await _firestoreService.saveManagerPermissionTemplates(unique);
      if (!mounted) return;
      setState(() => _permissions = unique);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Templates saved', style: GoogleFonts.inter()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saving failed: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_existsInList(_permissions, value)) _permissions.add(value);
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Permission Templates',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5B21B6),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Template',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                labelText: 'Permission',
                                hintText: 'ohos.permission.LOCATION',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _add,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _permissions.isEmpty
                      ? Text(
                          'No templates yet',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _permissions.map((p) {
                            return Chip(
                              label: Text(
                                p,
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              onDeleted: () =>
                                  setState(() => _permissions.remove(p)),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B21B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
    );
  }
}
