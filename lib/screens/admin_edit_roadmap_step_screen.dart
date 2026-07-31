import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/roadmap.dart';
import '../services/roadmap_service.dart';

const _adminPurple = Color(0xFF5B21B6);

/// Create or edit a single roadmap step (milestone) and its topics.
class AdminEditRoadmapStepScreen extends StatefulWidget {
  const AdminEditRoadmapStepScreen({
    super.key,
    required this.roadmapId,
    this.step,
  });

  final String roadmapId;

  /// Existing step to edit; `null` creates a new one.
  final RoadmapStep? step;

  @override
  State<AdminEditRoadmapStepScreen> createState() =>
      _AdminEditRoadmapStepScreenState();
}

class _AdminEditRoadmapStepScreenState
    extends State<AdminEditRoadmapStepScreen> {
  final _service = RoadmapService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late List<RoadmapTopic> _topics;
  bool _saving = false;

  bool get _isEditing => widget.step != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.step?.title ?? '');
    _summaryController = TextEditingController(text: widget.step?.summary ?? '');
    _topics = List<RoadmapTopic>.from(widget.step?.topics ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    final slug = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'item' : slug;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final baseId = widget.step?.id ?? _slugify(_titleController.text.trim());
      final order = widget.step?.order ??
          await _service.nextStepOrder(widget.roadmapId);

      final step = RoadmapStep(
        id: baseId,
        order: order,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        topics: _topics,
      );

      await _service.saveStep(roadmapId: widget.roadmapId, step: step);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editTopic({RoadmapTopic? topic, int? index}) async {
    final result = await showDialog<RoadmapTopic>(
      context: context,
      builder: (context) => _TopicEditorDialog(
        topic: topic,
        existingId: topic?.id,
        slugify: _slugify,
      ),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _topics[index] = result;
      } else {
        _topics.add(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: _adminPurple,
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? 'Edit Step' : 'New Step',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Step title',
                hintText: 'e.g. State Management',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _summaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Summary',
                hintText: 'One or two sentences describing this milestone.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Topics (${_topics.length})',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => _editTopic(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add topic'),
                  style: TextButton.styleFrom(foregroundColor: _adminPurple),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_topics.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'No topics yet. Add the concepts learners should master in this step.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                itemCount: _topics.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = _topics.removeAt(oldIndex);
                    _topics.insert(newIndex, moved);
                  });
                },
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  return Card(
                    key: ValueKey('topic-${topic.id}-$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(topic.title,
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${topic.type.label}'
                        '${topic.resources.isNotEmpty ? ' · ${topic.resources.length} resource(s)' : ''}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 20, color: _adminPurple),
                            onPressed: () =>
                                _editTopic(topic: topic, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            onPressed: () =>
                                setState(() => _topics.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _adminPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create step',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to create/edit a single topic including its resource links.
class _TopicEditorDialog extends StatefulWidget {
  const _TopicEditorDialog({
    required this.slugify,
    this.topic,
    this.existingId,
  });

  final RoadmapTopic? topic;
  final String? existingId;
  final String Function(String) slugify;

  @override
  State<_TopicEditorDialog> createState() => _TopicEditorDialogState();
}

class _TopicEditorDialogState extends State<_TopicEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late RoadmapTopicType _type;
  late List<RoadmapResource> _resources;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.topic?.description ?? '');
    _type = widget.topic?.type ?? RoadmapTopicType.recommended;
    _resources = List<RoadmapResource>.from(widget.topic?.resources ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _editResource({RoadmapResource? resource, int? index}) async {
    final result = await showDialog<RoadmapResource>(
      context: context,
      builder: (context) => _ResourceEditorDialog(resource: resource),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _resources[index] = result;
      } else {
        _resources.add(result);
      }
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final id = widget.existingId ?? widget.slugify(title);
    Navigator.pop(
      context,
      RoadmapTopic(
        id: id,
        title: title,
        description: _descriptionController.text.trim(),
        type: _type,
        resources: _resources,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.topic == null ? 'Add topic' : 'Edit topic',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Topic title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoadmapTopicType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in RoadmapTopicType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Resources (${_resources.length})',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: () => _editResource(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(foregroundColor: _adminPurple),
                  ),
                ],
              ),
              for (var i = 0; i < _resources.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_resources[i].label,
                      style: GoogleFonts.inter(fontSize: 13)),
                  subtitle: Text(_resources[i].url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF6B7280))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () =>
                            _editResource(resource: _resources[i], index: i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.red),
                        onPressed: () =>
                            setState(() => _resources.removeAt(i)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: _adminPurple, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ResourceEditorDialog extends StatefulWidget {
  const _ResourceEditorDialog({this.resource});

  final RoadmapResource? resource;

  @override
  State<_ResourceEditorDialog> createState() => _ResourceEditorDialogState();
}

class _ResourceEditorDialogState extends State<_ResourceEditorDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _urlController;
  late String _type;

  static const _types = [
    'article',
    'video',
    'official',
    'opensource',
    'course',
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.resource?.label ?? '');
    _urlController = TextEditingController(text: widget.resource?.url ?? '');
    _type = widget.resource?.type ?? 'article';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.resource == null ? 'Add resource' : 'Edit resource',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in _types)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _labelController.text.trim();
            final url = _urlController.text.trim();
            if (label.isEmpty || url.isEmpty) return;
            Navigator.pop(
              context,
              RoadmapResource(label: label, url: url, type: _type),
            );
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _adminPurple, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
