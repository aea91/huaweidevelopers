import 'arkts_quiz_challenge.dart';
import 'arkts_course.dart';

extension QuizDifficultyFirestore on QuizDifficulty {
  String get firestoreValue {
    switch (this) {
      case QuizDifficulty.easy:
        return 'easy';
      case QuizDifficulty.medium:
        return 'medium';
      case QuizDifficulty.hard:
        return 'hard';
    }
  }

  static QuizDifficulty fromFirestore(Object? value) {
    switch (value?.toString()) {
      case 'medium':
        return QuizDifficulty.medium;
      case 'hard':
        return QuizDifficulty.hard;
      case 'easy':
      default:
        return QuizDifficulty.easy;
    }
  }
}

extension ArkTsQuizChallengeFirestore on ArkTsQuizChallenge {
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'number': number,
        'title': title,
        'prompt': prompt,
        'difficulty': difficulty.firestoreValue,
        'starterCode': starterCode,
        'expectedOutput': expectedOutput,
        'hint': hint,
      };

  static ArkTsQuizChallenge fromFirestore(Map<String, dynamic> data) {
    return ArkTsQuizChallenge(
      id: (data['id'] ?? '').toString(),
      number: (data['number'] as num?)?.toInt() ?? 0,
      title: (data['title'] ?? '').toString(),
      prompt: (data['prompt'] ?? '').toString(),
      difficulty: QuizDifficultyFirestore.fromFirestore(data['difficulty']),
      starterCode: (data['starterCode'] ?? '').toString(),
      expectedOutput: (data['expectedOutput'] ?? '').toString(),
      hint: (data['hint'] ?? '').toString(),
    );
  }
}

extension CourseDocBlockFirestore on CourseDocBlock {
  Map<String, dynamic> toFirestore() {
    return switch (this) {
      CourseHeading(:final text) => {'type': 'heading', 'text': text},
      CourseParagraph(:final text) => {'type': 'paragraph', 'text': text},
      CourseBulletList(:final items) => {'type': 'bullets', 'items': items},
      CourseCodeSnippet(:final code, :final title, :final caption) => {
          'type': 'code',
          'code': code,
          if (title != null) 'title': title,
          if (caption != null) 'caption': caption,
        },
      CourseCallout(:final title, :final text) => {
          'type': 'callout',
          'title': title,
          'text': text,
        },
    };
  }

  static CourseDocBlock fromFirestore(Map<String, dynamic> data) {
    switch (data['type']?.toString()) {
      case 'heading':
        return CourseHeading((data['text'] ?? '').toString());
      case 'bullets':
        return CourseBulletList(
          List<String>.from(data['items'] ?? const <String>[]),
        );
      case 'code':
        return CourseCodeSnippet(
          code: (data['code'] ?? '').toString(),
          title: data['title']?.toString(),
          caption: data['caption']?.toString(),
        );
      case 'callout':
        return CourseCallout(
          title: (data['title'] ?? '').toString(),
          text: (data['text'] ?? '').toString(),
        );
      case 'paragraph':
      default:
        return CourseParagraph((data['text'] ?? '').toString());
    }
  }
}

extension CourseExampleFirestore on CourseExample {
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'explanation': explanation,
        'code': code,
      };

  static CourseExample fromFirestore(Map<String, dynamic> data) {
    return CourseExample(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      explanation: (data['explanation'] ?? '').toString(),
      code: (data['code'] ?? '').toString(),
    );
  }
}

extension CourseLessonFirestore on CourseLesson {
  Map<String, dynamic> toFirestore() => {
        'number': number,
        'title': title,
        'summary': summary,
        'durationLabel': durationLabel,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        if (sourceLabel != null) 'sourceLabel': sourceLabel,
        'content': content.map((b) => b.toFirestore()).toList(),
        'examples': examples.map((e) => e.toFirestore()).toList(),
        'challenges': challenges.map((c) => c.toFirestore()).toList(),
      };

  static CourseLesson fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final contentRaw = data['content'];
    final examplesRaw = data['examples'];
    final challengesRaw = data['challenges'];

    return CourseLesson(
      id: id,
      number: (data['number'] as num?)?.toInt() ?? 0,
      title: (data['title'] ?? '').toString(),
      summary: (data['summary'] ?? '').toString(),
      durationLabel: (data['durationLabel'] ?? '').toString(),
      sourceUrl: data['sourceUrl']?.toString(),
      sourceLabel: data['sourceLabel']?.toString(),
      content: contentRaw is List
          ? contentRaw
              .whereType<Map>()
              .map((e) => CourseDocBlockFirestore.fromFirestore(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      examples: examplesRaw is List
          ? examplesRaw
              .whereType<Map>()
              .map((e) => CourseExampleFirestore.fromFirestore(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      challenges: challengesRaw is List
          ? challengesRaw
              .whereType<Map>()
              .map((e) => ArkTsQuizChallengeFirestore.fromFirestore(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}

extension CourseTrackFirestore on CourseTrack {
  String get firestoreValue {
    switch (this) {
      case CourseTrack.arkts:
        return 'arkts';
      case CourseTrack.harmonyos:
        return 'harmonyos';
      case CourseTrack.arkui:
        return 'arkui';
    }
  }

  static CourseTrack fromFirestore(Object? value) {
    switch (value?.toString()) {
      case 'harmonyos':
        return CourseTrack.harmonyos;
      case 'arkui':
        return CourseTrack.arkui;
      case 'arkts':
      default:
        return CourseTrack.arkts;
    }
  }
}

extension LearningCourseFirestore on LearningCourse {
  /// Course document fields (lessons live in a subcollection).
  Map<String, dynamic> toCourseDocument({required int order}) => {
        'track': track.firestoreValue,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'learningOutcomes': learningOutcomes,
        'comingSoon': comingSoon,
        'order': order,
        'lessonCount': lessons.length,
      };

  static LearningCourse fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    List<CourseLesson> lessons = const [],
  }) {
    return LearningCourse(
      id: id,
      track: CourseTrackFirestore.fromFirestore(data['track']),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      learningOutcomes: List<String>.from(
        data['learningOutcomes'] ?? const <String>[],
      ),
      lessons: lessons,
      comingSoon: data['comingSoon'] == true,
      catalogLessonCount: (data['lessonCount'] as num?)?.toInt() ?? 0,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}
