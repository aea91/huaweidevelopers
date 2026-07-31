import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/arkts_course.dart';
import '../services/course_firestore_service.dart';
import '../services/course_progress_service.dart';
import '../theme/app_chrome.dart';

/// Catalog of learning tracks loaded from Firestore `courses`.
class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final _progress = CourseProgressService.instance;
  final _courseService = CourseFirestoreService();

  @override
  void initState() {
    super.initState();
    _progress.ensureLoaded();
  }

  IconData _trackIcon(CourseTrack track) {
    switch (track) {
      case CourseTrack.arkts:
        return Icons.code_rounded;
      case CourseTrack.harmonyos:
        return Icons.phone_android_rounded;
      case CourseTrack.arkui:
        return Icons.widgets_outlined;
    }
  }

  Future<void> _openCourse(LearningCourse course) async {
    if (!course.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${course.title} is coming soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.pushNamed(context, '/course/${course.id}');
    if (mounted) setState(() {});
  }

  List<CourseTrack> _tracksFrom(List<LearningCourse> courses) {
    final seen = <CourseTrack>{};
    final tracks = <CourseTrack>[];
    for (final course in courses) {
      if (seen.add(course.track)) tracks.add(course.track);
    }
    return tracks;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 800;

    return Scaffold(
      backgroundColor: AppChrome.canvas,
      appBar: AppChrome.appBar(
        context: context,
        title: 'Course',
        icon: Icons.school_rounded,
      ),
      body: StreamBuilder<List<LearningCourse>>(
        stream: _courseService.watchCourses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load courses.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppChrome.body(color: AppChrome.muted),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!;
          if (courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No courses in Firebase yet.\nSeed them from Admin → Upload courses.',
                  textAlign: TextAlign.center,
                  style: AppChrome.body(color: AppChrome.muted, height: 1.45),
                ),
              ),
            );
          }

          final tracks = _tracksFrom(courses);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 28,
                  20,
                  isNarrow ? 16 : 28,
                  40,
                ),
                children: [
                  Text(
                    'Choose a path',
                    style: AppChrome.display(fontSize: isNarrow ? 28 : 34),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Courses are loaded from Firebase. Pick ArkTS, HarmonyOS kits, or upcoming tracks.',
                    style: AppChrome.body(
                      fontSize: 15,
                      color: AppChrome.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...tracks.map((track) {
                    final trackCourses =
                        courses.where((c) => c.track == track).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppChrome.ink,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  _trackIcon(track),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.label,
                                      style: AppChrome.display(fontSize: 22),
                                    ),
                                    Text(
                                      track.blurb,
                                      style: AppChrome.body(
                                        fontSize: 13,
                                        color: AppChrome.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...trackCourses.map(
                            (course) => _CatalogCourseCard(
                              course: course,
                              progressLabel: _progressLabel(course),
                              onTap: () => _openCourse(course),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _progressLabel(LearningCourse course) {
    if (course.comingSoon) return 'Coming soon';
    if (course.lessonCount == 0) return 'No lessons yet';
    final done = _progress.completedLessonCount(
      course.id,
      // Catalog docs do not include lesson ids; progress shows after opening course.
      const [],
    );
    // Without lesson ids on catalog, show total only.
    if (done == 0) return '${course.lessonCount} lessons';
    return '$done / ${course.lessonCount} lessons';
  }
}

class _CatalogCourseCard extends StatelessWidget {
  final LearningCourse course;
  final String progressLabel;
  final VoidCallback onTap;

  const _CatalogCourseCard({
    required this.course,
    required this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = course.isAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppChrome.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              style: AppChrome.body(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color:
                                    available ? AppChrome.ink : AppChrome.muted,
                              ),
                            ),
                          ),
                          if (course.comingSoon)
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
                                'Soon',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppChrome.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.subtitle,
                        style: AppChrome.body(
                          fontSize: 13,
                          color: AppChrome.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        progressLabel,
                        style: AppChrome.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: available ? AppChrome.accent : AppChrome.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  available
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: AppChrome.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
