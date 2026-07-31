import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/arkts_course.dart';
import '../models/arkts_quiz_challenge.dart';
import '../services/arkts_playground_service.dart';
import '../services/course_firestore_service.dart';
import '../services/course_progress_service.dart';
import '../theme/app_chrome.dart';
import '../widgets/code_viewer.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/typescript.dart';

class CourseLessonScreen extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const CourseLessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen>
    with SingleTickerProviderStateMixin {
  static const _success = Color(0xFF059669);
  static const _editor = Color(0xFF111827);

  final _progress = CourseProgressService.instance;
  final _courseService = CourseFirestoreService();
  final _playgroundService = ArkTsPlaygroundService();
  late final TabController _tabs;
  LearningCourse? _course;
  CourseLesson? _lesson;
  late final CodeController _codeController;
  bool _loading = true;
  Object? _loadError;

  int _challengeIndex = 0;
  final Set<String> _solvedIds = {};
  ArkTsRunResult? _result;
  String? _requestError;
  bool _isRunning = false;
  bool _showHint = false;
  String? _gradeMessage;
  bool _lastAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _progress.ensureLoaded();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _codeController = CodeController(text: '', language: typescript);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final course = await _courseService.fetchCourse(widget.courseId);
      final lesson = course?.lessonById(widget.lessonId);
      final solved = <String>{};
      if (lesson != null) {
        for (final c in lesson.challenges) {
          if (_progress.isChallengeSolved(widget.courseId, c.id)) {
            solved.add(c.id);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _course = course;
        _lesson = lesson;
        _solvedIds
          ..clear()
          ..addAll(solved);
        _codeController.text = lesson != null && lesson.challenges.isNotEmpty
            ? lesson.challenges.first.starterCode
            : '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _codeController.dispose();
    super.dispose();
  }

  ArkTsQuizChallenge? get _challenge {
    final lesson = _lesson;
    if (lesson == null || lesson.challenges.isEmpty) return null;
    return lesson.challenges[_challengeIndex];
  }

  bool get _allChallengesSolved {
    final lesson = _lesson;
    if (lesson == null || lesson.challenges.isEmpty) return true;
    return lesson.challenges.every((c) => _solvedIds.contains(c.id));
  }

  void _loadChallenge(int index) {
    final lesson = _lesson;
    if (lesson == null) return;
    setState(() {
      _challengeIndex = index;
      _codeController.text = lesson.challenges[index].starterCode;
      _result = null;
      _requestError = null;
      _showHint = false;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
    });
  }

  void _resetCode() {
    final challenge = _challenge;
    if (challenge == null) return;
    setState(() {
      _codeController.text = challenge.starterCode;
      _result = null;
      _requestError = null;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
    });
  }

  String _normalizeOutput(String value) {
    final lines = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .toList();

    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }

    return lines.join('\n').trim();
  }

  Future<void> _runAndGrade() async {
    final challenge = _challenge;
    if (challenge == null || _isRunning) return;

    setState(() {
      _isRunning = true;
      _result = null;
      _requestError = null;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
    });

    try {
      final result = await _playgroundService.run(_codeController.text);
      if (!mounted) return;

      final alreadySolved = _solvedIds.contains(challenge.id);
      final actual = _normalizeOutput(result.runtimeOutput);
      final expected = _normalizeOutput(challenge.expectedOutput);
      final correct = result.success && actual == expected;

      setState(() {
        _result = result;
        if (correct) {
          _lastAnswerCorrect = true;
          if (!alreadySolved) {
            _solvedIds.add(challenge.id);
            _progress.markChallengeSolved(widget.courseId, challenge.id);
            _gradeMessage =
                'Correct! +${challenge.points} points earned for this challenge.';
            if (_allChallengesSolved) {
              final current = _lesson;
              if (current != null) {
                _progress.markLessonCompleted(widget.courseId, current.id);
              }
            }
          } else {
            _gradeMessage = 'Correct again. Already counted toward progress.';
          }
        } else if (!result.success) {
          _gradeMessage =
              'Compilation or runtime failed. Fix the errors and try again.';
        } else {
          _gradeMessage =
              'Output does not match the expected result. Keep going!';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = error.toString();
        _gradeMessage =
            'Could not run the challenge. Check the service and try again.';
      });
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _goNextLesson() {
    final lesson = _lesson;
    final course = _course;
    if (lesson == null || course == null) return;
    final idx = course.lessons.indexWhere((l) => l.id == lesson.id);
    if (idx < 0 || idx >= course.lessons.length - 1) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/course/${widget.courseId}',
        (route) =>
            route.isFirst ||
            route.settings.name == '/' ||
            route.settings.name == '/course' ||
            route.settings.name == '/course/',
      );
      return;
    }
    final next = course.lessons[idx + 1];
    Navigator.pushReplacementNamed(
      context,
      '/course/${widget.courseId}/lesson/${next.id}',
    );
  }

  Color _difficultyColor(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return _success;
      case QuizDifficulty.medium:
        return const Color(0xFFD97706);
      case QuizDifficulty.hard:
        return AppChrome.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppChrome.canvas,
        appBar: AppChrome.appBar(
          context: context,
          title: 'Lesson',
          icon: Icons.school_rounded,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: AppChrome.canvas,
        appBar: AppChrome.appBar(
          context: context,
          title: 'Lesson',
          icon: Icons.school_rounded,
        ),
        body: Center(
          child: Text(
            _loadError != null
                ? 'Could not load lesson.\n$_loadError'
                : 'Lesson not found.',
            textAlign: TextAlign.center,
            style: AppChrome.body(color: AppChrome.muted),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 960;
    final completed = _progress.isLessonCompleted(widget.courseId, lesson.id);

    return Scaffold(
      backgroundColor: AppChrome.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lesson, completed, isNarrow),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabs,
                labelColor: AppChrome.ink,
                unselectedLabelColor: AppChrome.muted,
                indicatorColor: AppChrome.accent,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: [
                  const Tab(text: 'Learn'),
                  Tab(text: 'Examples (${lesson.exampleCount})'),
                  Tab(
                    text:
                        'Practice (${_solvedIds.length}/${lesson.challengeCount})',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildLearnTab(lesson, isNarrow),
                  _buildExamplesTab(lesson, isNarrow),
                  _buildPracticeTab(lesson, isNarrow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CourseLesson lesson, bool completed, bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppChrome.line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Course',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamed(context, '/course/${widget.courseId}');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, color: AppChrome.ink),
          ),
          if (!isNarrow) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppChrome.ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson ${lesson.number} · ${lesson.title}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isNarrow ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppChrome.ink,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isNarrow)
                  Text(
                    lesson.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppChrome.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (completed)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Completed',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _success,
                ),
              ),
            ),
          if (lesson.sourceUrl != null) ...[
            IconButton(
              tooltip: lesson.sourceLabel ?? 'Official docs',
              onPressed: () async {
                final uri = Uri.parse(lesson.sourceUrl!);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.menu_book_outlined, color: AppChrome.ink),
            ),
          ],
          Text(
            lesson.durationLabel,
            style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnTab(CourseLesson lesson, bool isNarrow) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 16 : 28,
            22,
            isNarrow ? 16 : 28,
            40,
          ),
          children: [
            ...lesson.content.map(_buildDocBlock),
            if (lesson.sourceUrl != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(lesson.sourceUrl!);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(lesson.sourceLabel ?? 'Open official docs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppChrome.ink,
                  side: const BorderSide(color: AppChrome.line),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _tabs.animateTo(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppChrome.ink,
                      side: const BorderSide(color: AppChrome.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('See examples'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _tabs.animateTo(2),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppChrome.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Start practice'),
                  ),
                ),
              ],
            ),
            if (_allChallengesSolved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    _progress.markLessonCompleted(widget.courseId, lesson.id);
                    setState(() {});
                    _goNextLesson();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    lesson.number >= (_course?.lessons.length ?? 0)
                        ? 'Finish course'
                        : 'Complete & next lesson',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocBlock(CourseDocBlock block) {
    return switch (block) {
      CourseHeading(:final text) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(text, style: AppChrome.display(fontSize: 24)),
        ),
      CourseParagraph(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            text,
            style: AppChrome.body(
              fontSize: 15,
              color: const Color(0xFF334155),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      CourseBulletList(:final items) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: AppChrome.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: AppChrome.body(
                              fontSize: 14.5,
                              color: const Color(0xFF334155),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      CourseCodeSnippet(:final code, :final title, :final caption) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CodeViewer(
                code: code.trim(),
                title: title ?? 'example',
                height: _compactCodeHeight(code),
              ),
              if (caption != null) ...[
                const SizedBox(height: 8),
                Text(
                  caption,
                  style: AppChrome.body(
                    fontSize: 12.5,
                    color: AppChrome.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      CourseCallout(:final title, :final text) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppChrome.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: AppChrome.body(
                    fontSize: 13.5,
                    color: const Color(0xFF9A3412),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
    };
  }

  Widget _buildExamplesTab(CourseLesson lesson, bool isNarrow) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 16 : 28,
        20,
        isNarrow ? 16 : 28,
        40,
      ),
      itemCount: lesson.examples.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final example = lesson.examples[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppChrome.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Example ${index + 1}',
                      style: AppChrome.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppChrome.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      example.title,
                      style: AppChrome.display(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                example.explanation,
                style: AppChrome.body(
                  fontSize: 14,
                  color: const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              CodeViewer(
                code: example.code.trim(),
                title: example.id,
                height: _compactCodeHeight(example.code),
              ),
            ],
          ),
        );
      },
    );
  }

  double _compactCodeHeight(String code) {
    final lines = code.trim().split('\n').length;
    return (72 + lines * 21.0).clamp(140.0, 360.0);
  }

  Widget _buildPracticeTab(CourseLesson lesson, bool isNarrow) {
    if (lesson.challenges.isEmpty) {
      return Center(
        child: Text(
          'No practice challenges for this lesson.',
          style: AppChrome.body(color: AppChrome.muted),
        ),
      );
    }

    final challenge = _challenge!;
    final solved = _solvedIds.contains(challenge.id);

    if (isNarrow) {
      return Column(
        children: [
          Expanded(flex: 5, child: _buildQuestionPanel(lesson, challenge, solved)),
          Expanded(flex: 7, child: _buildWorkspace()),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildQuestionPanel(lesson, challenge, solved),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 7, child: _buildWorkspace()),
        ],
      ),
    );
  }

  Widget _buildQuestionPanel(
    CourseLesson lesson,
    ArkTsQuizChallenge challenge,
    bool solved,
  ) {
    final difficultyColor = _difficultyColor(challenge.difficulty);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppChrome.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Challenge ${challenge.number} of ${lesson.challenges.length}',
                      style: AppChrome.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppChrome.muted,
                      ),
                    ),
                    const Spacer(),
                    if (solved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Solved',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  challenge.title,
                  style: AppChrome.display(fontSize: 22),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metaChip(challenge.difficulty.label, difficultyColor),
                    _metaChip('${challenge.points} pts', AppChrome.ink),
                    _metaChip(
                      '${_solvedIds.length}/${lesson.challenges.length} done',
                      AppChrome.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppChrome.line),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task',
                    style: AppChrome.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.prompt,
                    style: AppChrome.body(
                      fontSize: 14.5,
                      color: const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Expected output',
                    style: AppChrome.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppChrome.ink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      challenge.expectedOutput,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  if (_showHint) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Hint',
                      style: AppChrome.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.hint,
                      style: AppChrome.body(
                        fontSize: 13.5,
                        color: AppChrome.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (_gradeMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lastAnswerCorrect
                            ? _success.withValues(alpha: 0.1)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _lastAnswerCorrect
                              ? _success.withValues(alpha: 0.3)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        _gradeMessage!,
                        style: AppChrome.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _lastAnswerCorrect
                              ? _success
                              : AppChrome.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < lesson.challenges.length; i++)
                  ChoiceChip(
                    label: Text('${i + 1}'),
                    selected: i == _challengeIndex,
                    onSelected: (_) => _loadChallenge(i),
                    selectedColor: AppChrome.ink,
                    labelStyle: TextStyle(
                      color: i == _challengeIndex
                          ? Colors.white
                          : AppChrome.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                TextButton(
                  onPressed: () => setState(() => _showHint = true),
                  child: const Text('Hint'),
                ),
                if (_allChallengesSolved)
                  FilledButton.tonal(
                    onPressed: () {
                      _progress.markLessonCompleted(widget.courseId, lesson.id);
                      setState(() {});
                      _goNextLesson();
                    },
                    child: Text(
                      lesson.number >= (_course?.lessons.length ?? 0)
                          ? 'Finish course'
                          : 'Next lesson',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppChrome.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Text(
                  'Editor',
                  style: AppChrome.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetCode,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppChrome.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onPressed: _isRunning ? null : _runAndGrade,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(_isRunning ? 'Checking' : 'Run & Check'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppChrome.line),
          Expanded(
            flex: 3,
            child: ColoredBox(
              color: _editor,
              child: CodeTheme(
                data: CodeThemeData(styles: vs2015Theme),
                child: CodeField(
                  controller: _codeController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  wrap: false,
                  background: _editor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  textStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFFE2E8F0),
                  ),
                  lineNumberStyle: LineNumberStyle(
                    width: 42,
                    textStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppChrome.line),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF0B1220),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Console',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _consoleText(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          height: 1.45,
                          color: const Color(0xFFE2E8F0),
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
    );
  }

  String _consoleText() {
    if (_requestError != null) return _requestError!;
    final result = _result;
    if (result == null) {
      return 'Run your solution to see console output here.';
    }
    final parts = <String>[];
    if (result.compileOutput.trim().isNotEmpty) {
      parts.add(result.compileOutput.trim());
    }
    if (result.runtimeOutput.trim().isNotEmpty) {
      parts.add(result.runtimeOutput.trim());
    }
    if (parts.isEmpty) {
      return result.success ? '(no output)' : 'Run failed with no output.';
    }
    return parts.join('\n\n');
  }

  Widget _metaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
