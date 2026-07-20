enum QuizDifficulty {
  easy,
  medium,
  hard,
}

extension QuizDifficultyX on QuizDifficulty {
  String get label {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
    }
  }

  int get points {
    switch (this) {
      case QuizDifficulty.easy:
        return 10;
      case QuizDifficulty.medium:
        return 20;
      case QuizDifficulty.hard:
        return 30;
    }
  }
}

class ArkTsQuizChallenge {
  final String id;
  final int number;
  final String title;
  final String prompt;
  final QuizDifficulty difficulty;
  final String starterCode;
  final String expectedOutput;
  final String hint;

  const ArkTsQuizChallenge({
    required this.id,
    required this.number,
    required this.title,
    required this.prompt,
    required this.difficulty,
    required this.starterCode,
    required this.expectedOutput,
    required this.hint,
  });

  int get points => difficulty.points;
}
