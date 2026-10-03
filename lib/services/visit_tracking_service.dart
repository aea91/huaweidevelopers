import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

/// Visit counts for one calendar day (Türkiye time).
class DailyVisits {
  const DailyVisits({
    required this.date,
    required this.uniqueVisitors,
    required this.visits,
  });

  /// YYYY-MM-DD
  final String date;
  final int uniqueVisitors;
  final int visits;
}

/// All-time visit counts.
class VisitTotals {
  const VisitTotals({this.uniqueVisitors = 0, this.visits = 0});

  final int uniqueVisitors;
  final int visits;
}

/// Records site visits through the `trackVisit` Cloud Function and reads the
/// per-day counts back for the admin dashboard.
class VisitTrackingService {
  static const _functionUrl =
      'https://us-central1-arkuibuilder.cloudfunctions.net/trackVisit';
  static const _storageKey = 'visitor_id_v1';

  static bool _tracked = false;

  final DocumentReference<Map<String, dynamic>> _visitsDoc =
      FirebaseFirestore.instance.collection('analytics').doc('visits');

  /// Counts this page load. Fire-and-forget: never throws, never blocks startup.
  static Future<void> trackVisit() async {
    if (!kIsWeb || kDebugMode || _tracked) return;
    _tracked = true;
    try {
      await http
          .post(
            Uri.parse(_functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'visitorId': _visitorId()}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Analytics must never break the app.
    }
  }

  /// Anonymous random id kept in localStorage so a returning browser counts once.
  static String _visitorId() {
    try {
      final stored = html.window.localStorage[_storageKey];
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {
      // Storage blocked (private mode) — fall through to a one-off id.
    }
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    try {
      html.window.localStorage[_storageKey] = id;
    } catch (_) {
      // Ignore quota / private mode failures.
    }
    return id;
  }

  /// Most recent days first. Admin only (see firestore.rules).
  Stream<List<DailyVisits>> watchDailyVisits({int days = 90}) {
    return _visitsDoc
        .collection('daily')
        .orderBy('date', descending: true)
        .limit(days)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return DailyVisits(
              date: (data['date'] ?? doc.id).toString(),
              uniqueVisitors: (data['uniqueVisitors'] as num?)?.toInt() ?? 0,
              visits: (data['visits'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        });
  }

  /// All-time totals. Publicly readable (shown on the home page).
  Stream<VisitTotals> watchTotals() {
    return _visitsDoc.snapshots().map((doc) {
      final data = doc.data() ?? const {};
      return VisitTotals(
        uniqueVisitors: (data['totalUniqueVisitors'] as num?)?.toInt() ?? 0,
        visits: (data['totalVisits'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// Today's key in Türkiye time (UTC+3), matching the Cloud Function.
  static String todayKey() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }
}
