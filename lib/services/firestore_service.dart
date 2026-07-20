import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/widget_showcase.dart';
import '../models/manager_definition.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'widgets';
  final String managersCollection = 'managers';
  final String configCollection = 'admin_config';

  // Fetch widgets
  Stream<List<WidgetShowcase>> getWidgets() {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return WidgetShowcase(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              mainCategory: data['mainCategory'] ?? 'Mobile',
              category: data['category'] ?? '',
              gifPath: data['gifUrl'] ?? '',
              code: data['code'] ?? '',
              tags: List<String>.from(data['tags'] ?? []),
            );
          }).toList();
        });
  }

  // Add a widget
  Future<String> addWidget(WidgetShowcase widget, String gifUrl) async {
    try {
      final docRef = await _firestore.collection(collection).add({
        'title': widget.title,
        'description': widget.description,
        'mainCategory': widget.mainCategory,
        'category': widget.category,
        'gifUrl': gifUrl,
        'code': widget.code,
        'tags': widget.tags,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add widget: $e');
    }
  }

  // Update a widget
  Future<void> updateWidget(
    String id,
    WidgetShowcase widget,
    String? gifUrl,
  ) async {
    try {
      final updateData = {
        'title': widget.title,
        'description': widget.description,
        'mainCategory': widget.mainCategory,
        'category': widget.category,
        'code': widget.code,
        'tags': widget.tags,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (gifUrl != null) {
        updateData['gifUrl'] = gifUrl;
      }

      await _firestore.collection(collection).doc(id).update(updateData);
    } catch (e) {
      throw Exception('Failed to update widget: $e');
    }
  }

  // Delete a widget
  Future<void> deleteWidget(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete widget: $e');
    }
  }

  // Fetch a single widget
  Future<WidgetShowcase?> getWidget(String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return WidgetShowcase(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        mainCategory: data['mainCategory'] ?? 'Mobile',
        category: data['category'] ?? '',
        gifPath: data['gifUrl'] ?? '',
        code: data['code'] ?? '',
        tags: List<String>.from(data['tags'] ?? []),
      );
    } catch (e) {
      throw Exception('Failed to fetch widget: $e');
    }
  }

  // Fetch main categories
  Future<List<String>> getMainCategories() async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final mainCategory = doc.data()['mainCategory'];
        if (mainCategory != null) {
          categories.add(mainCategory);
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch main categories: $e');
    }
  }

  // Fetch widget categories, optionally filtered by main category
  Future<List<String>> getCategories([String? mainCategory]) async {
    try {
      Query query = _firestore.collection(collection);

      if (mainCategory != null && mainCategory.isNotEmpty) {
        query = query.where('mainCategory', isEqualTo: mainCategory);
      }

      final snapshot = await query.get();
      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final category = data?['category'];
        if (category != null) {
          categories.add(category);
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Managers
  Stream<List<ManagerDefinition>> getManagers() {
    return _firestore
        .collection(managersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ManagerDefinition.fromFirestore(
              id: doc.id,
              data: doc.data(),
            );
          }).toList();
        });
  }

  Future<String> addManager(ManagerDefinition manager) async {
    try {
      final docRef = await _firestore.collection(managersCollection).add({
        ...manager.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add manager: $e');
    }
  }

  Future<void> updateManager(String id, ManagerDefinition manager) async {
    try {
      await _firestore.collection(managersCollection).doc(id).update({
        ...manager.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update manager: $e');
    }
  }

  Future<void> deleteManager(String id) async {
    try {
      await _firestore.collection(managersCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete manager: $e');
    }
  }

  Future<List<String>> getManagerPermissionTemplates() async {
    try {
      final doc = await _firestore
          .collection(configCollection)
          .doc('manager_permissions')
          .get();
      if (!doc.exists) return [];
      final data = doc.data() ?? {};
      return List<String>.from(data['permissions'] ?? const []);
    } catch (e) {
      throw Exception('Failed to fetch manager permission templates: $e');
    }
  }

  Future<void> saveManagerPermissionTemplates(List<String> permissions) async {
    try {
      await _firestore
          .collection(configCollection)
          .doc('manager_permissions')
          .set({
            'permissions': permissions,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save manager permission templates: $e');
    }
  }
}
