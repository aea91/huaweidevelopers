import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/roadmap.dart';

/// Firestore layout:
///   roadmaps/{roadmapId}
///   roadmaps/{roadmapId}/steps/{stepId}   (topics embedded as an array)
class RoadmapService {
  RoadmapService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const roadmapsCollection = 'roadmaps';
  static const stepsSubcollection = 'steps';

  /// Default roadmap document id used by the public /roadmap screen.
  static const defaultRoadmapId = 'arkts';

  CollectionReference<Map<String, dynamic>> get _roadmaps =>
      _firestore.collection(roadmapsCollection);

  CollectionReference<Map<String, dynamic>> _steps(String roadmapId) =>
      _roadmaps.doc(roadmapId).collection(stepsSubcollection);

  /// Live roadmap (metadata + ordered steps). Emits `null` when the roadmap
  /// document does not exist yet, so callers can fall back to bundled data.
  Stream<Roadmap?> watchRoadmap(String roadmapId) {
    return _roadmaps.doc(roadmapId).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return null;
      final steps = await _fetchSteps(roadmapId);
      return Roadmap.fromDocument(
        id: doc.id,
        map: doc.data()!,
        steps: steps,
      );
    });
  }

  Future<Roadmap?> fetchRoadmap(String roadmapId) async {
    final doc = await _roadmaps.doc(roadmapId).get();
    if (!doc.exists || doc.data() == null) return null;
    final steps = await _fetchSteps(roadmapId);
    return Roadmap.fromDocument(id: doc.id, map: doc.data()!, steps: steps);
  }

  Future<List<RoadmapStep>> _fetchSteps(String roadmapId) async {
    final snapshot = await _steps(roadmapId).orderBy('order').get();
    return snapshot.docs
        .map((doc) => RoadmapStep.fromMap(id: doc.id, map: doc.data()))
        .toList();
  }

  /// Live list of steps for the admin editor.
  Stream<List<RoadmapStep>> watchSteps(String roadmapId) {
    return _steps(roadmapId).orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RoadmapStep.fromMap(id: doc.id, map: doc.data()))
          .toList();
    });
  }

  Future<bool> roadmapExists(String roadmapId) async {
    final doc = await _roadmaps.doc(roadmapId).get();
    return doc.exists;
  }

  /// Create or update roadmap metadata without touching step documents.
  Future<void> saveRoadmapMeta(Roadmap roadmap, {int order = 0}) async {
    final ref = _roadmaps.doc(roadmap.id);
    final existing = await ref.get();
    await ref.set({
      ...roadmap.toDocument(order: order),
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveStep({
    required String roadmapId,
    required RoadmapStep step,
  }) async {
    await _steps(roadmapId).doc(step.id).set({
      ...step.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _syncStepCount(roadmapId);
  }

  Future<void> deleteStep({
    required String roadmapId,
    required String stepId,
  }) async {
    await _steps(roadmapId).doc(stepId).delete();
    await _syncStepCount(roadmapId);
  }

  /// Persist a new ordering. [orderedStepIds] is the desired top-to-bottom order.
  Future<void> reorderSteps({
    required String roadmapId,
    required List<String> orderedStepIds,
  }) async {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedStepIds.length; i++) {
      batch.set(
        _steps(roadmapId).doc(orderedStepIds[i]),
        {'order': i, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<int> nextStepOrder(String roadmapId) async {
    final snapshot =
        await _steps(roadmapId).orderBy('order', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return 0;
    final order = snapshot.docs.first.data()['order'];
    return ((order as num?)?.toInt() ?? -1) + 1;
  }

  /// Replace the entire roadmap (metadata + steps) from bundled seed content.
  Future<void> replaceRoadmap(Roadmap roadmap, {int order = 0}) async {
    final ref = _roadmaps.doc(roadmap.id);
    final batch = _firestore.batch();

    batch.set(ref, {
      ...roadmap.toDocument(order: order),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final existing = await _steps(roadmap.id).get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final step in roadmap.steps) {
      batch.set(_steps(roadmap.id).doc(step.id), {
        ...step.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _syncStepCount(String roadmapId) async {
    final count = (await _steps(roadmapId).count().get()).count ?? 0;
    await _roadmaps.doc(roadmapId).set({
      'stepCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
