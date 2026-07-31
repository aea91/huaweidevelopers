import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/arkts_roadmap.dart';
import '../models/roadmap.dart';
import '../services/roadmap_service.dart';
import 'admin_edit_roadmap_step_screen.dart';

const _adminPurple = Color(0xFF5B21B6);

/// Admin editor for the ArkTS roadmap: reorder, add, edit and delete the
/// milestone steps that render on the public /roadmap screen.
class AdminRoadmapScreen extends StatefulWidget {
  const AdminRoadmapScreen({
    super.key,
    this.roadmapId = RoadmapService.defaultRoadmapId,
  });

  final String roadmapId;

  @override
  State<AdminRoadmapScreen> createState() => _AdminRoadmapScreenState();
}

class _AdminRoadmapScreenState extends State<AdminRoadmapScreen> {
  final _service = RoadmapService();
  bool _busy = false;

  Future<void> _ensureRoadmapDoc() async {
    if (!await _service.roadmapExists(widget.roadmapId)) {
      await _service.saveRoadmapMeta(
        Roadmap(
          id: widget.roadmapId,
          title: defaultArkTsRoadmap.title,
          subtitle: defaultArkTsRoadmap.subtitle,
        ),
      );
    }
  }

  Future<void> _addStep() async {
    await _ensureRoadmapDoc();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditRoadmapStepScreen(roadmapId: widget.roadmapId),
      ),
    );
  }

  Future<void> _editStep(RoadmapStep step) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditRoadmapStepScreen(
          roadmapId: widget.roadmapId,
          step: step,
        ),
      ),
    );
  }

  Future<void> _deleteStep(RoadmapStep step) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete step'),
        content: Text('Delete "${step.title}" and its topics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _service.deleteStep(roadmapId: widget.roadmapId, stepId: step.id);
  }

  Future<void> _seedDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load default content'),
        content: const Text(
          'This replaces the entire roadmap with the bundled default ArkTS '
          'content. Any custom steps will be overwritten. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _adminPurple, foregroundColor: Colors.white),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await _service.replaceRoadmap(
        Roadmap(
          id: widget.roadmapId,
          title: defaultArkTsRoadmap.title,
          subtitle: defaultArkTsRoadmap.subtitle,
          steps: defaultArkTsRoadmap.steps,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default roadmap loaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onReorder(List<RoadmapStep> steps, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<RoadmapStep>.from(steps);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await _service.reorderSteps(
      roadmapId: widget.roadmapId,
      orderedStepIds: reordered.map((s) => s.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: _adminPurple,
        foregroundColor: Colors.white,
        title: Text('ArkTS Roadmap',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Load default content',
            onPressed: _busy ? null : _seedDefault,
          ),
        ],
      ),
      body: StreamBuilder<List<RoadmapStep>>(
        stream: _service.watchSteps(widget.roadmapId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final steps = snapshot.data ?? [];

          if (steps.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.route_rounded,
                        size: 72, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 16),
                    Text('No roadmap steps yet',
                        style: GoogleFonts.inter(
                            fontSize: 18, color: const Color(0xFF6B7280))),
                    const SizedBox(height: 8),
                    Text(
                      'Add steps manually, or load the bundled ArkTS content to start.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _seedDefault,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Load default ArkTS roadmap'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _adminPurple),
                    ),
                  ],
                ),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: steps.length,
            onReorder: (oldIndex, newIndex) =>
                _onReorder(steps, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final step = steps[index];
              return Card(
                key: ValueKey(step.id),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _adminPurple,
                    child: Text('${index + 1}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(step.title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${step.topics.length} topic(s)'
                      '${step.summary.isNotEmpty ? ' · ${step.summary}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF6B7280)),
                    ),
                  ),
                  onTap: () => _editStep(step),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: _adminPurple),
                        onPressed: () => _editStep(step),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStep(step),
                      ),
                      const Icon(Icons.drag_handle, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStep,
        backgroundColor: _adminPurple,
        icon: const Icon(Icons.add),
        label: const Text('Add Step'),
      ),
    );
  }
}
