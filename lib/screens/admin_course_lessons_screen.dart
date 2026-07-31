import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/arkts_course.dart';
import '../services/course_firestore_service.dart';
import 'admin_edit_lesson_screen.dart';

class AdminCourseLessonsScreen extends StatefulWidget {
  final String courseId;

  const AdminCourseLessonsScreen({super.key, required this.courseId});

  @override
  State<AdminCourseLessonsScreen> createState() =>
      _AdminCourseLessonsScreenState();
}

class _AdminCourseLessonsScreenState extends State<AdminCourseLessonsScreen> {
  final _courseService = CourseFirestoreService();
  LearningCourse? _course;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
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
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _deleteLesson(CourseLesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete lesson'),
        content: Text('Delete "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _courseService.deleteLesson(
        courseId: widget.courseId,
        lessonId: lesson.id,
      );
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          course?.title ?? 'Lessons',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5B21B6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: course == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF5B21B6),
              onPressed: () async {
                final nextNumber = course.lessons.isEmpty
                    ? 1
                    : course.lessons
                            .map((l) => l.number)
                            .reduce((a, b) => a > b ? a : b) +
                        1;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEditLessonScreen(
                      courseId: widget.courseId,
                      initialNumber: nextNumber,
                    ),
                  ),
                );
                await _reload();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add lesson'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : course == null
                  ? const Center(child: Text('Course not found'))
                  : course.lessons.isEmpty
                      ? Center(
                          child: Text(
                            'No lessons yet — add the first one',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: course.lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = course.lessons[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF5B21B6),
                                  child: Text(
                                    '${lesson.number}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  lesson.title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${lesson.durationLabel} · '
                                  '${lesson.exampleCount} examples · '
                                  '${lesson.challengeCount} quizzes\n'
                                  '${lesson.summary}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF6B7280),
                                    height: 1.35,
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminEditLessonScreen(
                                            courseId: widget.courseId,
                                            lesson: lesson,
                                          ),
                                        ),
                                      );
                                      await _reload();
                                    } else if (value == 'delete') {
                                      await _deleteLesson(lesson);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminEditLessonScreen(
                                        courseId: widget.courseId,
                                        lesson: lesson,
                                      ),
                                    ),
                                  );
                                  await _reload();
                                },
                              ),
                            );
                          },
                        ),
    );
  }
}
