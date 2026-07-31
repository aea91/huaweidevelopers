/// Roadmap domain model (roadmap.sh-style learning path).
///
/// A [Roadmap] is an ordered list of [RoadmapStep] milestones. Each step holds
/// a set of [RoadmapTopic] nodes, and each topic can carry external
/// [RoadmapResource] links (articles, videos, official docs …).
library;

enum RoadmapTopicType { recommended, optional, alternative }

extension RoadmapTopicTypeX on RoadmapTopicType {
  String get firestoreValue {
    switch (this) {
      case RoadmapTopicType.recommended:
        return 'recommended';
      case RoadmapTopicType.optional:
        return 'optional';
      case RoadmapTopicType.alternative:
        return 'alternative';
    }
  }

  String get label {
    switch (this) {
      case RoadmapTopicType.recommended:
        return 'Recommended';
      case RoadmapTopicType.optional:
        return 'Optional';
      case RoadmapTopicType.alternative:
        return 'Alternative';
    }
  }

  static RoadmapTopicType fromValue(Object? value) {
    switch (value?.toString()) {
      case 'optional':
        return RoadmapTopicType.optional;
      case 'alternative':
        return RoadmapTopicType.alternative;
      case 'recommended':
      default:
        return RoadmapTopicType.recommended;
    }
  }
}

class RoadmapResource {
  final String label;
  final String url;

  /// Free-form kind used only for the small leading icon: article, video,
  /// official, opensource, course. Unknown values fall back to a link icon.
  final String type;

  const RoadmapResource({
    required this.label,
    required this.url,
    this.type = 'article',
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'url': url,
        'type': type,
      };

  factory RoadmapResource.fromMap(Map<String, dynamic> map) => RoadmapResource(
        label: (map['label'] ?? '').toString(),
        url: (map['url'] ?? '').toString(),
        type: (map['type'] ?? 'article').toString(),
      );

  RoadmapResource copyWith({String? label, String? url, String? type}) =>
      RoadmapResource(
        label: label ?? this.label,
        url: url ?? this.url,
        type: type ?? this.type,
      );
}

class RoadmapTopic {
  final String id;
  final String title;
  final String description;
  final RoadmapTopicType type;
  final List<RoadmapResource> resources;

  const RoadmapTopic({
    required this.id,
    required this.title,
    this.description = '',
    this.type = RoadmapTopicType.recommended,
    this.resources = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.firestoreValue,
        'resources': resources.map((r) => r.toMap()).toList(),
      };

  factory RoadmapTopic.fromMap(Map<String, dynamic> map) {
    final rawResources = map['resources'];
    return RoadmapTopic(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      type: RoadmapTopicTypeX.fromValue(map['type']),
      resources: rawResources is List
          ? rawResources
              .whereType<Map>()
              .map((e) => RoadmapResource.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  RoadmapTopic copyWith({
    String? id,
    String? title,
    String? description,
    RoadmapTopicType? type,
    List<RoadmapResource>? resources,
  }) =>
      RoadmapTopic(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        resources: resources ?? this.resources,
      );
}

class RoadmapStep {
  final String id;
  final int order;
  final String title;
  final String summary;
  final List<RoadmapTopic> topics;

  const RoadmapStep({
    required this.id,
    required this.order,
    required this.title,
    this.summary = '',
    this.topics = const [],
  });

  /// Step document fields for Firestore (topics embedded as an array).
  Map<String, dynamic> toMap() => {
        'order': order,
        'title': title,
        'summary': summary,
        'topics': topics.map((t) => t.toMap()).toList(),
      };

  factory RoadmapStep.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final rawTopics = map['topics'];
    return RoadmapStep(
      id: id,
      order: (map['order'] as num?)?.toInt() ?? 0,
      title: (map['title'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      topics: rawTopics is List
          ? rawTopics
              .whereType<Map>()
              .map((e) => RoadmapTopic.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  RoadmapStep copyWith({
    String? id,
    int? order,
    String? title,
    String? summary,
    List<RoadmapTopic>? topics,
  }) =>
      RoadmapStep(
        id: id ?? this.id,
        order: order ?? this.order,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        topics: topics ?? this.topics,
      );
}

class Roadmap {
  final String id;
  final String title;
  final String subtitle;
  final List<RoadmapStep> steps;

  const Roadmap({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.steps = const [],
  });

  Map<String, dynamic> toDocument({required int order}) => {
        'title': title,
        'subtitle': subtitle,
        'order': order,
        'stepCount': steps.length,
      };

  factory Roadmap.fromDocument({
    required String id,
    required Map<String, dynamic> map,
    List<RoadmapStep> steps = const [],
  }) =>
      Roadmap(
        id: id,
        title: (map['title'] ?? '').toString(),
        subtitle: (map['subtitle'] ?? '').toString(),
        steps: steps,
      );

  int get topicCount =>
      steps.fold(0, (total, step) => total + step.topics.length);
}
