import 'arkts_quiz_challenge.dart';

/// Top-level track shown on the Course catalog (ArkTS, HarmonyOS, ArkUI, …).
enum CourseTrack {
  arkts,
  harmonyos,
  arkui,
}

extension CourseTrackX on CourseTrack {
  String get label {
    switch (this) {
      case CourseTrack.arkts:
        return 'ArkTS';
      case CourseTrack.harmonyos:
        return 'HarmonyOS';
      case CourseTrack.arkui:
        return 'ArkUI';
    }
  }

  String get blurb {
    switch (this) {
      case CourseTrack.arkts:
        return 'Language fundamentals, style, and TS migration';
      case CourseTrack.harmonyos:
        return 'System kits, permissions, and device capabilities';
      case CourseTrack.arkui:
        return 'Declarative UI, components, and state';
    }
  }
}

/// A structured reading block inside a lesson.
sealed class CourseDocBlock {
  const CourseDocBlock();
}

class CourseHeading extends CourseDocBlock {
  final String text;
  const CourseHeading(this.text);
}

class CourseParagraph extends CourseDocBlock {
  final String text;
  const CourseParagraph(this.text);
}

class CourseBulletList extends CourseDocBlock {
  final List<String> items;
  const CourseBulletList(this.items);
}

class CourseCodeSnippet extends CourseDocBlock {
  final String code;
  final String? title;
  final String? caption;

  const CourseCodeSnippet({
    required this.code,
    this.title,
    this.caption,
  });
}

class CourseCallout extends CourseDocBlock {
  final String title;
  final String text;

  const CourseCallout({
    required this.title,
    required this.text,
  });
}

class CourseExample {
  final String id;
  final String title;
  final String explanation;
  final String code;

  const CourseExample({
    required this.id,
    required this.title,
    required this.explanation,
    required this.code,
  });
}

class CourseLesson {
  final String id;
  final int number;
  final String title;
  final String summary;
  final String durationLabel;
  final String? sourceUrl;
  final String? sourceLabel;
  final List<CourseDocBlock> content;
  final List<CourseExample> examples;
  final List<ArkTsQuizChallenge> challenges;

  const CourseLesson({
    required this.id,
    required this.number,
    required this.title,
    required this.summary,
    required this.durationLabel,
    required this.content,
    required this.examples,
    required this.challenges,
    this.sourceUrl,
    this.sourceLabel,
  });

  int get challengeCount => challenges.length;
  int get exampleCount => examples.length;
}

class LearningCourse {
  final String id;
  final CourseTrack track;
  final String title;
  final String subtitle;
  final String description;
  final List<String> learningOutcomes;
  final List<CourseLesson> lessons;
  final bool comingSoon;
  /// Lesson count from Firestore catalog docs (when [lessons] is not loaded).
  final int catalogLessonCount;
  final int order;

  const LearningCourse({
    required this.id,
    required this.track,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.learningOutcomes,
    required this.lessons,
    this.comingSoon = false,
    this.catalogLessonCount = 0,
    this.order = 0,
  });

  CourseLesson? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  int get totalChallenges =>
      lessons.fold(0, (sum, lesson) => sum + lesson.challengeCount);

  int get lessonCount =>
      lessons.isNotEmpty ? lessons.length : catalogLessonCount;

  bool get isAvailable => !comingSoon && lessonCount > 0;
}

/// @Deprecated('Use LearningCourse')
typedef ArkTsCourse = LearningCourse;
