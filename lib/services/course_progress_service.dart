import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// Persists per-course progress in the browser (web). Falls back to memory elsewhere.
class CourseProgressService {
  CourseProgressService._();
  static final CourseProgressService instance = CourseProgressService._();

  static const _storageKey = 'learning_course_progress_v3';
  static const _legacyKey = 'arkts_course_progress_v2';

  final Map<String, Set<String>> _completedLessonsByCourse = {};
  final Map<String, Set<String>> _solvedChallengesByCourse = {};
  bool _loaded = false;

  void ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    if (!kIsWeb) return;

    try {
      final raw = html.window.localStorage[_storageKey];
      if (raw != null && raw.isNotEmpty) {
        _loadV3(raw);
        return;
      }
      _migrateLegacy();
    } catch (_) {
      // Ignore corrupt storage.
    }
  }

  void _loadV3(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final courses = map['courses'];
    if (courses is! Map) return;
    courses.forEach((key, value) {
      if (value is! Map) return;
      final courseId = key.toString();
      final lessons = value['completedLessons'];
      final challenges = value['solvedChallenges'];
      if (lessons is List) {
        _completedLessonsByCourse[courseId] =
            lessons.map((e) => e.toString()).toSet();
      }
      if (challenges is List) {
        _solvedChallengesByCourse[courseId] =
            challenges.map((e) => e.toString()).toSet();
      }
    });
  }

  void _migrateLegacy() {
    final raw = html.window.localStorage[_legacyKey];
    if (raw == null || raw.isEmpty) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final lessons = map['completedLessons'];
    final challenges = map['solvedChallenges'];
    const arktsId = 'arkts-fundamentals';
    if (lessons is List) {
      _completedLessonsByCourse[arktsId] =
          lessons.map((e) => e.toString()).toSet();
    }
    if (challenges is List) {
      _solvedChallengesByCourse[arktsId] =
          challenges.map((e) => e.toString()).toSet();
    }
    _persist();
  }

  void _persist() {
    if (!kIsWeb) return;
    try {
      final courses = <String, dynamic>{};
      final ids = <String>{
        ..._completedLessonsByCourse.keys,
        ..._solvedChallengesByCourse.keys,
      };
      for (final id in ids) {
        courses[id] = {
          'completedLessons':
              (_completedLessonsByCourse[id] ?? {}).toList(),
          'solvedChallenges':
              (_solvedChallengesByCourse[id] ?? {}).toList(),
        };
      }
      html.window.localStorage[_storageKey] = jsonEncode({'courses': courses});
    } catch (_) {
      // Ignore quota / private mode failures.
    }
  }

  Set<String> _lessons(String courseId) =>
      _completedLessonsByCourse.putIfAbsent(courseId, () => <String>{});

  Set<String> _challenges(String courseId) =>
      _solvedChallengesByCourse.putIfAbsent(courseId, () => <String>{});

  bool isLessonCompleted(String courseId, String lessonId) {
    ensureLoaded();
    return _completedLessonsByCourse[courseId]?.contains(lessonId) ?? false;
  }

  bool isChallengeSolved(String courseId, String challengeId) {
    ensureLoaded();
    return _solvedChallengesByCourse[courseId]?.contains(challengeId) ?? false;
  }

  void markChallengeSolved(String courseId, String challengeId) {
    ensureLoaded();
    if (_challenges(courseId).add(challengeId)) {
      _persist();
    }
  }

  void markLessonCompleted(String courseId, String lessonId) {
    ensureLoaded();
    if (_lessons(courseId).add(lessonId)) {
      _persist();
    }
  }

  int solvedCountFor(String courseId, Iterable<String> challengeIds) {
    ensureLoaded();
    final solved = _solvedChallengesByCourse[courseId] ?? const {};
    var count = 0;
    for (final id in challengeIds) {
      if (solved.contains(id)) count++;
    }
    return count;
  }

  int completedLessonCount(String courseId, Iterable<String> lessonIds) {
    ensureLoaded();
    final done = _completedLessonsByCourse[courseId] ?? const {};
    var count = 0;
    for (final id in lessonIds) {
      if (done.contains(id)) count++;
    }
    return count;
  }
}
