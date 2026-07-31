import '../models/arkts_course.dart';
import 'course/lessons_part1.dart';
import 'course/lessons_part2.dart';
import 'course/lessons_part3.dart';

/// ArkTS course aligned with Huawei HarmonyOS official Learning ArkTS docs.
const LearningCourse arkTsCourse = LearningCourse(
  id: 'arkts-fundamentals',
  track: CourseTrack.arkts,
  title: 'ArkTS Fundamentals',
  subtitle:
      'Official HarmonyOS Learning ArkTS pathway — read, study examples, then practice.',
  description:
      'A guided course mapped to Huawei developer documentation. Progress topic by topic: '
      'Introduction to ArkTS, Coding Style Guide, Migration Background, TypeScript to ArkTS '
      'Cookbook, Adaptation Cases, and High-Performance Programming. Each lesson includes '
      'reading notes, worked examples, and graded coding challenges (same Run & Check model '
      'as Playground Quiz).',
  learningOutcomes: [
    'Explain what ArkTS is and how it tightens TypeScript for HarmonyOS',
    'Use declarations, types, operators, functions, classes, interfaces, and null safety',
    'Apply ArkTS naming, formatting, and programming-practice style rules',
    'Rewrite common TypeScript patterns using the official migration cookbook',
    'Apply high-performance habits for hot paths (const, arrays, exceptions)',
  ],
  lessons: [
    lesson01GetStarted,
    lesson02BasicsTypes,
    lesson03OperatorsStatements,
    lesson04Functions,
    lesson05Classes,
    lesson06InterfacesNull,
    lesson07CodingStyleNaming,
    lesson08CodingStylePractices,
    lesson09MigrationBackground,
    lesson10MigrationCore,
    lesson11MigrationRecipes,
    lesson12AdaptationCases,
    lesson13HighPerformance,
    lesson14Capstone,
  ],
);
