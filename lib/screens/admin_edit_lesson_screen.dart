import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/arkts_course.dart';
import '../models/arkts_quiz_challenge.dart';
import '../services/course_firestore_service.dart';

class AdminEditLessonScreen extends StatefulWidget {
  final String courseId;
  final CourseLesson? lesson;
  final int initialNumber;

  const AdminEditLessonScreen({
    super.key,
    required this.courseId,
    this.lesson,
    this.initialNumber = 1,
  });

  @override
  State<AdminEditLessonScreen> createState() => _AdminEditLessonScreenState();
}

class _AdminEditLessonScreenState extends State<AdminEditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseService = CourseFirestoreService();

  late final TextEditingController _idController;
  late final TextEditingController _numberController;
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _durationController;
  late final TextEditingController _sourceUrlController;
  late final TextEditingController _sourceLabelController;

  final List<_BlockDraft> _blocks = [];
  final List<_ExampleDraft> _examples = [];
  final List<_ChallengeDraft> _challenges = [];

  bool _saving = false;
  bool get _isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _idController = TextEditingController(text: lesson?.id ?? '');
    _numberController = TextEditingController(
      text: '${lesson?.number ?? widget.initialNumber}',
    );
    _titleController = TextEditingController(text: lesson?.title ?? '');
    _summaryController = TextEditingController(text: lesson?.summary ?? '');
    _durationController =
        TextEditingController(text: lesson?.durationLabel ?? '15 min');
    _sourceUrlController =
        TextEditingController(text: lesson?.sourceUrl ?? '');
    _sourceLabelController =
        TextEditingController(text: lesson?.sourceLabel ?? '');

    if (lesson != null) {
      for (final block in lesson.content) {
        _blocks.add(_BlockDraft.fromBlock(block));
      }
      for (final example in lesson.examples) {
        _examples.add(_ExampleDraft.fromExample(example));
      }
      for (final challenge in lesson.challenges) {
        _challenges.add(_ChallengeDraft.fromChallenge(challenge));
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _numberController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _durationController.dispose();
    _sourceUrlController.dispose();
    _sourceLabelController.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    for (final e in _examples) {
      e.dispose();
    }
    for (final c in _challenges) {
      c.dispose();
    }
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
          ? widget.lesson!.id
          : (_idController.text.trim().isEmpty
                ? _slugify(_titleController.text)
                : _idController.text.trim());

      final lesson = CourseLesson(
        id: id,
        number: int.tryParse(_numberController.text.trim()) ?? 1,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        durationLabel: _durationController.text.trim(),
        sourceUrl: _sourceUrlController.text.trim().isEmpty
            ? null
            : _sourceUrlController.text.trim(),
        sourceLabel: _sourceLabelController.text.trim().isEmpty
            ? null
            : _sourceLabelController.text.trim(),
        content: _blocks.map((b) => b.toBlock()).toList(),
        examples: _examples.map((e) => e.toExample()).toList(),
        challenges: [
          for (var i = 0; i < _challenges.length; i++)
            _challenges[i].toChallenge(fallbackNumber: i + 1),
        ],
      );

      await _courseService.saveLesson(
        courseId: widget.courseId,
        lesson: lesson,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Lesson updated' : 'Lesson created'),
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

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      alignLabelWithHint: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit lesson' : 'Add lesson',
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
                decoration: _dec('Lesson ID', hint: 'auto from title if empty'),
              ),
            if (!_isEditing) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Number'),
                    validator: (v) =>
                        int.tryParse(v?.trim() ?? '') == null ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: _dec('Duration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: _dec('Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              decoration: _dec('Summary'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceUrlController,
              decoration: _dec('Source URL (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceLabelController,
              decoration: _dec('Source label (optional)'),
            ),
            const SizedBox(height: 24),
            _sectionHeader(
              'Learn content',
              onAdd: () => setState(() => _blocks.add(_BlockDraft.paragraph())),
            ),
            ..._blocks.asMap().entries.map((entry) {
              final i = entry.key;
              final block = entry.value;
              return _blockCard(i, block);
            }),
            const SizedBox(height: 20),
            _sectionHeader(
              'Examples',
              onAdd: () => setState(() => _examples.add(_ExampleDraft.empty())),
            ),
            ..._examples.asMap().entries.map((entry) {
              final i = entry.key;
              final example = entry.value;
              return _exampleCard(i, example);
            }),
            const SizedBox(height: 20),
            _sectionHeader(
              'Practice challenges',
              onAdd: () =>
                  setState(() => _challenges.add(_ChallengeDraft.empty())),
            ),
            ..._challenges.asMap().entries.map((entry) {
              final i = entry.key;
              final challenge = entry.value;
              return _challengeCard(i, challenge);
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _blockCard(int index, _BlockDraft block) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: block.type,
                    decoration: _dec('Block type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'heading',
                        child: Text('Heading'),
                      ),
                      DropdownMenuItem(
                        value: 'paragraph',
                        child: Text('Paragraph'),
                      ),
                      DropdownMenuItem(
                        value: 'bullets',
                        child: Text('Bullet list'),
                      ),
                      DropdownMenuItem(value: 'code', child: Text('Code')),
                      DropdownMenuItem(
                        value: 'callout',
                        child: Text('Callout'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => block.type = v);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () {
                    setState(() {
                      block.dispose();
                      _blocks.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (block.type == 'callout' || block.type == 'code')
              TextFormField(
                controller: block.titleController,
                decoration: _dec(
                  block.type == 'code' ? 'Code title' : 'Callout title',
                ),
              ),
            if (block.type == 'callout' || block.type == 'code')
              const SizedBox(height: 10),
            TextFormField(
              controller: block.bodyController,
              minLines: block.type == 'code' ? 6 : 2,
              maxLines: block.type == 'code' ? 16 : 8,
              decoration: _dec(
                block.type == 'bullets'
                    ? 'Items (one per line)'
                    : block.type == 'code'
                        ? 'Code'
                        : 'Text',
              ),
            ),
            if (block.type == 'code') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: block.captionController,
                decoration: _dec('Caption (optional)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _exampleCard(int index, _ExampleDraft example) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Example ${index + 1}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      example.dispose();
                      _examples.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            TextFormField(
              controller: example.idController,
              decoration: _dec('Example ID'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: example.titleController,
              decoration: _dec('Title'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: example.explanationController,
              minLines: 2,
              maxLines: 4,
              decoration: _dec('Explanation'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: example.codeController,
              minLines: 6,
              maxLines: 16,
              decoration: _dec('Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(int index, _ChallengeDraft challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Challenge ${index + 1}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      challenge.dispose();
                      _challenges.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            TextFormField(
              controller: challenge.idController,
              decoration: _dec('Challenge ID'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: challenge.titleController,
              decoration: _dec('Title'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: challenge.promptController,
              minLines: 2,
              maxLines: 5,
              decoration: _dec('Prompt'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<QuizDifficulty>(
              value: challenge.difficulty,
              decoration: _dec('Difficulty'),
              items: QuizDifficulty.values
                  .map(
                    (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => challenge.difficulty = v);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: challenge.starterController,
              minLines: 5,
              maxLines: 14,
              decoration: _dec('Starter code'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: challenge.expectedController,
              minLines: 1,
              maxLines: 6,
              decoration: _dec('Expected output'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: challenge.hintController,
              decoration: _dec('Hint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockDraft {
  String type;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController captionController;

  _BlockDraft({
    required this.type,
    required String title,
    required String body,
    String caption = '',
  })  : titleController = TextEditingController(text: title),
        bodyController = TextEditingController(text: body),
        captionController = TextEditingController(text: caption);

  factory _BlockDraft.paragraph() =>
      _BlockDraft(type: 'paragraph', title: '', body: '');

  factory _BlockDraft.fromBlock(CourseDocBlock block) {
    return switch (block) {
      CourseHeading(:final text) =>
        _BlockDraft(type: 'heading', title: '', body: text),
      CourseParagraph(:final text) =>
        _BlockDraft(type: 'paragraph', title: '', body: text),
      CourseBulletList(:final items) =>
        _BlockDraft(type: 'bullets', title: '', body: items.join('\n')),
      CourseCodeSnippet(:final code, :final title, :final caption) =>
        _BlockDraft(
          type: 'code',
          title: title ?? '',
          body: code,
          caption: caption ?? '',
        ),
      CourseCallout(:final title, :final text) =>
        _BlockDraft(type: 'callout', title: title, body: text),
    };
  }

  CourseDocBlock toBlock() {
    switch (type) {
      case 'heading':
        return CourseHeading(bodyController.text.trim());
      case 'bullets':
        return CourseBulletList(
          bodyController.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      case 'code':
        return CourseCodeSnippet(
          code: bodyController.text,
          title: titleController.text.trim().isEmpty
              ? null
              : titleController.text.trim(),
          caption: captionController.text.trim().isEmpty
              ? null
              : captionController.text.trim(),
        );
      case 'callout':
        return CourseCallout(
          title: titleController.text.trim().isEmpty
              ? 'Note'
              : titleController.text.trim(),
          text: bodyController.text.trim(),
        );
      case 'paragraph':
      default:
        return CourseParagraph(bodyController.text.trim());
    }
  }

  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    captionController.dispose();
  }
}

class _ExampleDraft {
  final TextEditingController idController;
  final TextEditingController titleController;
  final TextEditingController explanationController;
  final TextEditingController codeController;

  _ExampleDraft({
    required String id,
    required String title,
    required String explanation,
    required String code,
  })  : idController = TextEditingController(text: id),
        titleController = TextEditingController(text: title),
        explanationController = TextEditingController(text: explanation),
        codeController = TextEditingController(text: code);

  factory _ExampleDraft.empty() => _ExampleDraft(
        id: '',
        title: '',
        explanation: '',
        code: 'declare function print(arg: any): any\n\n',
      );

  factory _ExampleDraft.fromExample(CourseExample example) => _ExampleDraft(
        id: example.id,
        title: example.title,
        explanation: example.explanation,
        code: example.code,
      );

  CourseExample toExample() {
    final id = idController.text.trim().isEmpty
        ? titleController.text
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        : idController.text.trim();
    return CourseExample(
      id: id.isEmpty ? 'example' : id,
      title: titleController.text.trim(),
      explanation: explanationController.text.trim(),
      code: codeController.text,
    );
  }

  void dispose() {
    idController.dispose();
    titleController.dispose();
    explanationController.dispose();
    codeController.dispose();
  }
}

class _ChallengeDraft {
  final TextEditingController idController;
  final TextEditingController titleController;
  final TextEditingController promptController;
  final TextEditingController starterController;
  final TextEditingController expectedController;
  final TextEditingController hintController;
  QuizDifficulty difficulty;

  _ChallengeDraft({
    required String id,
    required String title,
    required String prompt,
    required String starter,
    required String expected,
    required String hint,
    required this.difficulty,
  })  : idController = TextEditingController(text: id),
        titleController = TextEditingController(text: title),
        promptController = TextEditingController(text: prompt),
        starterController = TextEditingController(text: starter),
        expectedController = TextEditingController(text: expected),
        hintController = TextEditingController(text: hint);

  factory _ChallengeDraft.empty() => _ChallengeDraft(
        id: '',
        title: '',
        prompt: '',
        starter: 'declare function print(arg: any): any\n\n// TODO\n',
        expected: '',
        hint: '',
        difficulty: QuizDifficulty.easy,
      );

  factory _ChallengeDraft.fromChallenge(ArkTsQuizChallenge c) =>
      _ChallengeDraft(
        id: c.id,
        title: c.title,
        prompt: c.prompt,
        starter: c.starterCode,
        expected: c.expectedOutput,
        hint: c.hint,
        difficulty: c.difficulty,
      );

  ArkTsQuizChallenge toChallenge({required int fallbackNumber}) {
    final id = idController.text.trim().isEmpty
        ? 'q$fallbackNumber'
        : idController.text.trim();
    return ArkTsQuizChallenge(
      id: id,
      number: fallbackNumber,
      title: titleController.text.trim(),
      prompt: promptController.text.trim(),
      difficulty: difficulty,
      starterCode: starterController.text,
      expectedOutput: expectedController.text,
      hint: hintController.text.trim(),
    );
  }

  void dispose() {
    idController.dispose();
    titleController.dispose();
    promptController.dispose();
    starterController.dispose();
    expectedController.dispose();
    hintController.dispose();
  }
}
