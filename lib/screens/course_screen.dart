import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/arkts_course.dart';
import '../services/course_firestore_service.dart';
import '../services/course_progress_service.dart';
import '../theme/app_chrome.dart';

class CourseScreen extends StatefulWidget {
  final String courseId;

  const CourseScreen({super.key, required this.courseId});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final _progress = CourseProgressService.instance;
  final _courseService = CourseFirestoreService();
  LearningCourse? _course;
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _progress.ensureLoaded();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final course = await _courseService.fetchCourse(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
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

  String get _courseId => widget.courseId;

  int get _completedLessons {
    final course = _course;
    if (course == null) return 0;
    return _progress.completedLessonCount(
      _courseId,
      course.lessons.map((l) => l.id),
    );
  }

  int get _solvedChallenges {
    final course = _course;
    if (course == null) return 0;
    var n = 0;
    for (final lesson in course.lessons) {
      n += _progress.solvedCountFor(
        _courseId,
        lesson.challenges.map((c) => c.id),
      );
    }
    return n;
  }

  double get _overallProgress {
    final course = _course;
    if (course == null || course.lessons.isEmpty) return 0;
    return _completedLessons / course.lessons.length;
  }

  CourseLesson? get _continueLesson {
    final course = _course;
    if (course == null || course.lessons.isEmpty) return null;
    for (final lesson in course.lessons) {
      if (!_progress.isLessonCompleted(_courseId, lesson.id)) return lesson;
    }
    return course.lessons.last;
  }

  Future<void> _openLesson(CourseLesson lesson) async {
    await Navigator.pushNamed(
      context,
      '/course/$_courseId/lesson/${lesson.id}',
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppChrome.canvas,
        appBar: AppChrome.appBar(
          context: context,
          title: 'Course',
          icon: Icons.school_rounded,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final course = _course;
    if (course == null) {
      return Scaffold(
        backgroundColor: AppChrome.canvas,
        appBar: AppChrome.appBar(
          context: context,
          title: 'Course',
          icon: Icons.school_rounded,
        ),
        body: Center(
          child: Text(
            _loadError != null
                ? 'Could not load course.\n$_loadError'
                : 'Course not found.',
            textAlign: TextAlign.center,
            style: AppChrome.body(color: AppChrome.muted),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 900;
    final continueLesson = _continueLesson;

    return Scaffold(
      backgroundColor: AppChrome.canvas,
      appBar: AppChrome.appBar(
        context: context,
        title: course.track.label,
        icon: Icons.school_rounded,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isNarrow ? 16 : 28,
              20,
              isNarrow ? 16 : 28,
              40,
            ),
            children: [
              _buildHero(course, continueLesson, isNarrow),
              const SizedBox(height: 28),
              Text(
                'Curriculum',
                style: AppChrome.display(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                'Progress topic by topic. Unlock practice after reading each lesson.',
                style: AppChrome.body(fontSize: 14, color: AppChrome.muted),
              ),
              const SizedBox(height: 16),
              ...course.lessons.map((lesson) => _LessonCard(
                    lesson: lesson,
                    completed:
                        _progress.isLessonCompleted(_courseId, lesson.id),
                    solvedCount: _progress.solvedCountFor(
                      _courseId,
                      lesson.challenges.map((c) => c.id),
                    ),
                    locked: _isLocked(course, lesson),
                    onTap: () => _openLesson(lesson),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLocked(LearningCourse course, CourseLesson lesson) {
    if (lesson.number == 1) return false;
    final prev = course.lessons.firstWhere(
      (l) => l.number == lesson.number - 1,
    );
    return !_progress.isLessonCompleted(_courseId, prev.id);
  }

  Widget _buildHero(
    LearningCourse course,
    CourseLesson? continueLesson,
    bool isNarrow,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 20 : 28,
        isNarrow ? 22 : 28,
        isNarrow ? 20 : 28,
        isNarrow ? 22 : 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppChrome.line),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppChrome.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${course.track.label.toUpperCase()} · DOCUMENT · EXAMPLES · QUIZ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppChrome.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            course.title,
            style: AppChrome.display(fontSize: isNarrow ? 28 : 34),
          ),
          const SizedBox(height: 8),
          Text(
            course.subtitle,
            style: AppChrome.body(
              fontSize: 15,
              color: AppChrome.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            course.description,
            style: AppChrome.body(
              fontSize: 14,
              color: const Color(0xFF334155),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statChip(
                Icons.menu_book_rounded,
                '${course.lessonCount} lessons',
              ),
              _statChip(
                Icons.code_rounded,
                '${course.totalChallenges} challenges',
              ),
              _statChip(
                Icons.check_circle_outline_rounded,
                '$_completedLessons / ${course.lessonCount} done',
              ),
              _statChip(
                Icons.stars_rounded,
                '$_solvedChallenges solved',
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: AppChrome.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_overallProgress * 100).round()}% course progress',
            style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
          ),
          const SizedBox(height: 22),
          Text(
            'What you will learn',
            style: AppChrome.body(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...course.learningOutcomes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: AppChrome.body(
                        fontSize: 13.5,
                        color: const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (continueLesson != null) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppChrome.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _openLesson(continueLesson),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _completedLessons == 0
                      ? 'Start course'
                      : _completedLessons == course.lessonCount
                          ? 'Review last lesson'
                          : 'Continue: Lesson ${continueLesson.number}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppChrome.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppChrome.ink),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppChrome.body(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final CourseLesson lesson;
  final bool completed;
  final int solvedCount;
  final bool locked;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.completed,
    required this.solvedCount,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: completed
                    ? const Color(0xFF059669).withValues(alpha: 0.35)
                    : AppChrome.line,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: locked
                        ? const Color(0xFFF1F5F9)
                        : completed
                            ? const Color(0xFF059669).withValues(alpha: 0.12)
                            : AppChrome.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: locked
                        ? const Icon(
                            Icons.lock_outline_rounded,
                            color: AppChrome.muted,
                            size: 20,
                          )
                        : completed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF059669),
                                size: 22,
                              )
                            : Text(
                                '${lesson.number}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: AppChrome.body(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: locked
                                    ? AppChrome.muted
                                    : AppChrome.ink,
                              ),
                            ),
                          ),
                          Text(
                            lesson.durationLabel,
                            style: AppChrome.body(
                              fontSize: 12,
                              color: AppChrome.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.summary,
                        style: AppChrome.body(
                          fontSize: 13,
                          color: AppChrome.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniChip(
                            '${lesson.exampleCount} examples',
                            Icons.lightbulb_outline_rounded,
                          ),
                          _miniChip(
                            '$solvedCount / ${lesson.challengeCount} quizzes',
                            Icons.quiz_outlined,
                          ),
                          if (completed)
                            _miniChip(
                              'Completed',
                              Icons.verified_rounded,
                              color: const Color(0xFF059669),
                            ),
                          if (locked)
                            _miniChip(
                              'Complete previous lesson',
                              Icons.lock_outline_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppChrome.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, IconData icon, {Color? color}) {
    final c = color ?? AppChrome.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
