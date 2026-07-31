import '../models/arkts_course.dart';
import 'arkts_course.dart';
import 'harmonyos_kits_course.dart';

/// Local seed used only to export / upload into Firestore.
/// Runtime Course UI reads exclusively from Firebase.
const List<LearningCourse> seedLearningCourses = [
  arkTsCourse,
  harmonyOsKitsCourse,
  arkUiCoursePlaceholder,
];

/// @Deprecated('Use seedLearningCourses for export only')
const List<LearningCourse> allLearningCourses = seedLearningCourses;
