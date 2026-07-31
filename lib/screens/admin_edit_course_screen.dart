import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/arkts_course.dart';
import '../services/course_firestore_service.dart';

class AdminEditCourseScreen extends StatefulWidget {
  final LearningCourse? course;

  const AdminEditCourseScreen({super.key, this.course});

  @override
  State<AdminEditCourseScreen> createState() => _AdminEditCourseScreenState();
}

class _AdminEditCourseScreenState extends State<AdminEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseService = CourseFirestoreService();

  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _outcomesController;
  late final TextEditingController _orderController;

  CourseTrack _track = CourseTrack.arkts;
  bool _comingSoon = false;
  bool _saving = false;

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _idController = TextEditingController(text: c?.id ?? '');
    _titleController = TextEditingController(text: c?.title ?? '');
    _subtitleController = TextEditingController(text: c?.subtitle ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _outcomesController = TextEditingController(
      text: c?.learningOutcomes.join('\n') ?? '',
    );
    _orderController = TextEditingController(text: '${c?.order ?? 0}');
    _track = c?.track ?? CourseTrack.arkts;
    _comingSoon = c?.comingSoon ?? false;
    if (c == null) {
      _courseService.nextCourseOrder().then((order) {
        if (mounted) _orderController.text = '$order';
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _outcomesController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final id = _isEditing
          ? widget.course!.id
          : (_idController.text.trim().isEmpty
                ? _slugify(_titleController.text)
                : _idController.text.trim());

      final outcomes = _outcomesController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final course = LearningCourse(
        id: id,
        track: _track,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        description: _descriptionController.text.trim(),
        learningOutcomes: outcomes,
        lessons: widget.course?.lessons ?? const [],
        comingSoon: _comingSoon,
        catalogLessonCount: widget.course?.catalogLessonCount ?? 0,
      );

      final order = int.tryParse(_orderController.text.trim()) ?? 0;
      await _courseService.saveCourseMetadata(course: course, order: order);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Course updated' : 'Course created'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit course' : 'Add course',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5B21B6),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing)
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Course ID (slug)',
                  hintText: 'auto from title if empty',
                  border: OutlineInputBorder(),
                ),
              ),
            if (!_isEditing) const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CourseTrack>(
              value: _track,
              decoration: const InputDecoration(
                labelText: 'Track',
                border: OutlineInputBorder(),
              ),
              items: CourseTrack.values
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _track = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Catalog order',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Coming soon'),
              value: _comingSoon,
              onChanged: (v) => setState(() => _comingSoon = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _outcomesController,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Learning outcomes (one per line)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
