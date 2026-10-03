import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/visit_tracking_service.dart';

const _adminPurple = Color(0xFF5B21B6);

/// Admin view of how many people visited the site, day by day.
class AdminVisitorsScreen extends StatelessWidget {
  const AdminVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = VisitTrackingService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Visitors',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _adminPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DailyVisits>>(
        stream: service.watchDailyVisits(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final days = snapshot.data ?? [];
          final today = VisitTrackingService.todayKey();
          final todayVisitors = days.isNotEmpty && days.first.date == today
              ? days.first.uniqueVisitors
              : 0;
          final maxVisitors = days.fold<int>(
            1,
            (m, d) => max(m, d.uniqueVisitors),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamBuilder<VisitTotals>(
                stream: service.watchTotals(),
                builder: (context, totalsSnapshot) {
                  final totals = totalsSnapshot.data ?? const VisitTotals();
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(label: 'Visitors today', value: todayVisitors),
                      _StatCard(
                        label: 'Unique visitors (all time)',
                        value: totals.uniqueVisitors,
                      ),
                      _StatCard(
                        label: 'Visits (all time)',
                        value: totals.visits,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Daily visitors',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last ${days.length} days with visits · Türkiye time',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No visits recorded yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        for (final day in days)
                          _DayRow(day: day, maxVisitors: maxVisitors),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _adminPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.maxVisitors});

  final DailyVisits day;
  final int maxVisitors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              day.date,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: day.uniqueVisitors / maxVisitors,
                minHeight: 10,
                backgroundColor: const Color(0xFFF3F4F6),
                color: _adminPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: Text(
              '${day.uniqueVisitors} visitors · ${day.visits} visits',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
