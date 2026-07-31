import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/arkts_roadmap.dart';
import '../models/roadmap.dart';
import '../services/roadmap_service.dart';
import '../theme/app_chrome.dart';

/// Public roadmap.sh-style learning path for ArkTS.
///
/// Reads from Firestore (roadmaps/arkts) and falls back to the bundled
/// [defaultArkTsRoadmap] when nothing has been published yet.
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key, this.roadmapId = RoadmapService.defaultRoadmapId});

  final String roadmapId;

  @override
  Widget build(BuildContext context) {
    final service = RoadmapService();

    return Scaffold(
      backgroundColor: AppChrome.canvas,
      body: StreamBuilder<Roadmap?>(
        stream: service.watchRoadmap(roadmapId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Fall back to bundled content until an admin publishes a roadmap.
          final roadmap = (snapshot.data != null && snapshot.data!.steps.isNotEmpty)
              ? snapshot.data!
              : defaultArkTsRoadmap;
          return _RoadmapView(roadmap: roadmap);
        },
      ),
    );
  }
}

class _RoadmapView extends StatelessWidget {
  const _RoadmapView({required this.roadmap});

  final Roadmap roadmap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppChrome.listHeader(
          context: context,
          title: roadmap.title,
          subtitle: roadmap.subtitle,
          icon: Icons.route_rounded,
          bottom: const _Legend(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final railCenterX = wide ? constraints.maxWidth / 2 : 20.0;
                    return Column(
                      children: [
                        for (var i = 0; i < roadmap.steps.length; i++)
                          _StepRow(
                            step: roadmap.steps[i],
                            index: i,
                            isLast: i == roadmap.steps.length - 1,
                            alignRight: wide && i.isOdd,
                            wide: wide,
                            railCenterX: railCenterX,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One milestone: a numbered node on the vertical rail plus a step card that
/// zig-zags to the left or right on wide screens (stacks on narrow ones).
///
/// The card is a normal (non-positioned) child so it sizes the row, while the
/// rail is overlaid via [Positioned] with bounded height — this avoids the
/// IntrinsicHeight + Wrap combination that can overflow.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.index,
    required this.isLast,
    required this.alignRight,
    required this.wide,
    required this.railCenterX,
  });

  final RoadmapStep step;
  final int index;
  final bool isLast;
  final bool alignRight;
  final bool wide;
  final double railCenterX;

  @override
  Widget build(BuildContext context) {
    final card = _StepCard(step: step);

    final Widget content;
    if (!wide) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 24),
              child: card,
            ),
          ),
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: alignRight
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 22, bottom: 28),
                    child: card,
                  ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: alignRight
                ? Padding(
                    padding: const EdgeInsets.only(left: 22, bottom: 28),
                    child: card,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return Stack(
      children: [
        content,
        Positioned(
          left: railCenterX - 20,
          top: 0,
          bottom: 0,
          width: 40,
          child: Column(
            children: [
              _NodeCircle(number: index + 1),
              if (!isLast)
                Expanded(
                  child: Center(
                    child: Container(width: 2, color: AppChrome.line),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The numbered circle that sits on the rail.
class _NodeCircle extends StatelessWidget {
  const _NodeCircle({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppChrome.ink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppChrome.ink.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: AppChrome.display(fontSize: 16, color: Colors.white),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final RoadmapStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppChrome.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppChrome.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title, style: AppChrome.display(fontSize: 18)),
          if (step.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              step.summary,
              style: AppChrome.body(fontSize: 13, color: AppChrome.muted, height: 1.5),
            ),
          ],
          if (step.topics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in step.topics)
                  _TopicChip(topic: topic),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic});

  final RoadmapTopic topic;

  @override
  Widget build(BuildContext context) {
    final style = _typeStyle(topic.type);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showTopicDetail(context, topic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: style.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                topic.title,
                style: AppChrome.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: style.text,
                ),
              ),
            ),
            if (topic.resources.isNotEmpty) ...[
              const SizedBox(width: 6),
              Icon(Icons.link_rounded, size: 14, color: style.text.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final type in RoadmapTopicType.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _typeStyle(type).dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                type.label,
                style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
              ),
            ],
          ),
      ],
    );
  }
}

class _TopicStyle {
  final Color background;
  final Color border;
  final Color text;
  final Color dot;
  const _TopicStyle(this.background, this.border, this.text, this.dot);
}

_TopicStyle _typeStyle(RoadmapTopicType type) {
  switch (type) {
    case RoadmapTopicType.recommended:
      return const _TopicStyle(
        Color(0xFF0F172A), // ink filled
        Color(0xFF0F172A),
        Colors.white,
        Color(0xFF34D399), // green dot
      );
    case RoadmapTopicType.optional:
      return const _TopicStyle(
        Colors.white,
        Color(0xFFE2E8F0),
        Color(0xFF0F172A),
        Color(0xFF94A3B8),
      );
    case RoadmapTopicType.alternative:
      return const _TopicStyle(
        Color(0xFFFEF3C7), // amber tint
        Color(0xFFFCD34D),
        Color(0xFF92400E),
        Color(0xFFF59E0B),
      );
  }
}

void _showTopicDetail(BuildContext context, RoadmapTopic topic) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppChrome.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final style = _typeStyle(topic.type);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppChrome.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: style.border),
                    ),
                    child: Text(
                      topic.type.label,
                      style: AppChrome.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: style.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(topic.title, style: AppChrome.display(fontSize: 22)),
              if (topic.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  topic.description,
                  style: AppChrome.body(fontSize: 14, height: 1.6, color: AppChrome.ink),
                ),
              ],
              if (topic.resources.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Resources',
                  style: AppChrome.display(fontSize: 14, color: AppChrome.muted),
                ),
                const SizedBox(height: 8),
                for (final resource in topic.resources)
                  _ResourceTile(resource: resource),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.resource});

  final RoadmapResource resource;

  IconData get _icon {
    switch (resource.type) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'official':
        return Icons.verified_outlined;
      case 'opensource':
        return Icons.code_rounded;
      case 'course':
        return Icons.school_outlined;
      case 'article':
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final uri = Uri.tryParse(resource.url);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppChrome.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppChrome.line),
          ),
          child: Row(
            children: [
              Icon(_icon, size: 18, color: AppChrome.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resource.label,
                  style: AppChrome.body(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.open_in_new_rounded, size: 15, color: AppChrome.muted),
            ],
          ),
        ),
      ),
    );
  }
}
