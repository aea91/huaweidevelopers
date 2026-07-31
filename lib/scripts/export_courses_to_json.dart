import 'dart:convert';
import 'dart:io';

import '../data/course_catalog.dart';
import '../models/course_firestore.dart';

/// Exports local seed courses to scripts/courses_seed.json for Firebase upload.
///
/// Run: `dart run lib/scripts/export_courses_to_json.dart`
void main() {
  final courses = <Map<String, dynamic>>[];
  for (var i = 0; i < seedLearningCourses.length; i++) {
    final course = seedLearningCourses[i];
    courses.add({
      'id': course.id,
      ...course.toCourseDocument(order: i),
      'lessons': [
        for (final lesson in course.lessons)
          {
            'id': lesson.id,
            ...lesson.toFirestore(),
          },
      ],
    });
  }

  final out = {
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'courses': courses,
  };

  final file = File('scripts/courses_seed.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln('Wrote ${file.path} (${courses.length} courses)');
}
