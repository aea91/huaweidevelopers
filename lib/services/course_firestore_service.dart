import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/arkts_course.dart';
import '../models/course_firestore.dart';

/// Firestore layout:
///   courses/{courseId}
///   courses/{courseId}/lessons/{lessonId}
class CourseFirestoreService {
  CourseFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const coursesCollection = 'courses';
  static const lessonsSubcollection = 'lessons';

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(coursesCollection);

  /// Catalog metadata (no nested lesson bodies).
  Stream<List<LearningCourse>> watchCourses() {
    return _courses.orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => LearningCourseFirestore.fromFirestore(
              id: doc.id,
              data: doc.data(),
            ),
          )
          .toList();
    });
  }

  Future<List<LearningCourse>> fetchCourses() async {
    final snapshot = await _courses.orderBy('order').get();
    return snapshot.docs
        .map(
          (doc) => LearningCourseFirestore.fromFirestore(
            id: doc.id,
            data: doc.data(),
          ),
        )
        .toList();
  }

  Future<LearningCourse?> fetchCourse(String courseId) async {
    final doc = await _courses.doc(courseId).get();
    if (!doc.exists || doc.data() == null) return null;

    final lessonsSnap = await _courses
        .doc(courseId)
        .collection(lessonsSubcollection)
        .orderBy('number')
        .get();

    final lessons = lessonsSnap.docs
        .map(
          (lessonDoc) => CourseLessonFirestore.fromFirestore(
            id: lessonDoc.id,
            data: lessonDoc.data(),
          ),
        )
        .toList();

    return LearningCourseFirestore.fromFirestore(
      id: doc.id,
      data: doc.data()!,
      lessons: lessons,
    );
  }

  Stream<LearningCourse?> watchCourse(String courseId) {
    return _courses.doc(courseId).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return null;
      final lessonsSnap = await _courses
          .doc(courseId)
          .collection(lessonsSubcollection)
          .orderBy('number')
          .get();
      final lessons = lessonsSnap.docs
          .map(
            (lessonDoc) => CourseLessonFirestore.fromFirestore(
              id: lessonDoc.id,
              data: lessonDoc.data(),
            ),
          )
          .toList();
      return LearningCourseFirestore.fromFirestore(
        id: doc.id,
        data: doc.data()!,
        lessons: lessons,
      );
    });
  }

  /// Upsert a full course + lessons (used by admin seed / CMS).
  Future<void> upsertCourse(LearningCourse course, {required int order}) async {
    final courseRef = _courses.doc(course.id);
    final batch = _firestore.batch();

    batch.set(courseRef, {
      ...course.toCourseDocument(order: order),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Replace lessons: delete existing then write current set.
    final existing = await courseRef.collection(lessonsSubcollection).get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final lesson in course.lessons) {
      batch.set(
        courseRef.collection(lessonsSubcollection).doc(lesson.id),
        {
          ...lesson.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  Future<void> upsertAllCourses(List<LearningCourse> courses) async {
    for (var i = 0; i < courses.length; i++) {
      await upsertCourse(courses[i], order: i);
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final courseRef = _courses.doc(courseId);
    final lessons = await courseRef.collection(lessonsSubcollection).get();
    final batch = _firestore.batch();
    for (final doc in lessons.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(courseRef);
    await batch.commit();
  }

  /// Create or update course metadata without touching lesson documents.
  Future<void> saveCourseMetadata({
    required LearningCourse course,
    required int order,
  }) async {
    final courseRef = _courses.doc(course.id);
    final existing = await courseRef.get();
    final lessonCount = existing.exists
        ? (await courseRef.collection(lessonsSubcollection).count().get())
              .count ??
            course.lessons.length
        : course.lessons.length;

    await courseRef.set({
      ...course.toCourseDocument(order: order),
      'lessonCount': lessonCount,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveLesson({
    required String courseId,
    required CourseLesson lesson,
  }) async {
    final courseRef = _courses.doc(courseId);
    await courseRef.collection(lessonsSubcollection).doc(lesson.id).set({
      ...lesson.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final count =
        (await courseRef.collection(lessonsSubcollection).count().get()).count ??
        0;
    await courseRef.set({
      'lessonCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteLesson({
    required String courseId,
    required String lessonId,
  }) async {
    final courseRef = _courses.doc(courseId);
    await courseRef.collection(lessonsSubcollection).doc(lessonId).delete();
    final count =
        (await courseRef.collection(lessonsSubcollection).count().get()).count ??
        0;
    await courseRef.set({
      'lessonCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> nextCourseOrder() async {
    final snapshot = await _courses.orderBy('order', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return 0;
    final order = snapshot.docs.first.data()['order'];
    return ((order as num?)?.toInt() ?? -1) + 1;
  }
}
