class SuggestedModel {
  final String name;
  final Map<String, dynamic> sampleJson;
  final String reason;

  const SuggestedModel({
    required this.name,
    required this.sampleJson,
    required this.reason,
  });

  factory SuggestedModel.fromJson(Map<String, dynamic> json) {
    return SuggestedModel(
      name: (json['name'] ?? '').toString(),
      sampleJson: Map<String, dynamic>.from(json['sampleJson'] ?? const {}),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sampleJson': sampleJson,
        'reason': reason,
      };
}

class WidgetSuggestion {
  final String id;
  final String reason;

  const WidgetSuggestion({required this.id, required this.reason});

  factory WidgetSuggestion.fromJson(Map<String, dynamic> json) {
    return WidgetSuggestion(
      id: (json['id'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class AppDesignSuggestion {
  final String summary;
  final String layoutDescription;
  final List<WidgetSuggestion> widgets;
  final List<String> managerIds;
  final String primaryColor;
  final String secondaryColor;
  final String tertiaryColor;
  final bool isDarkMode;
  final List<SuggestedModel> models;
  final String? projectName;
  final String? projectDescription;
  final bool usedCloudAi;

  const AppDesignSuggestion({
    required this.summary,
    required this.layoutDescription,
    required this.widgets,
    required this.managerIds,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.isDarkMode,
    required this.models,
    this.projectName,
    this.projectDescription,
    this.usedCloudAi = false,
  });

  List<String> get widgetIds => widgets.map((w) => w.id).toList();

  factory AppDesignSuggestion.fromJson(Map<String, dynamic> json) {
    final rawWidgets = json['widgets'];
    final widgets = <WidgetSuggestion>[];
    if (rawWidgets is List) {
      for (final item in rawWidgets) {
        if (item is Map) {
          widgets.add(WidgetSuggestion.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          widgets.add(WidgetSuggestion(id: item, reason: ''));
        }
      }
    }

    final rawModels = json['models'];
    final models = <SuggestedModel>[];
    if (rawModels is List) {
      for (final item in rawModels) {
        if (item is Map) {
          models.add(SuggestedModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return AppDesignSuggestion(
      summary: (json['summary'] ?? '').toString(),
      layoutDescription: (json['layoutDescription'] ?? '').toString(),
      widgets: widgets,
      managerIds: List<String>.from(json['managerIds'] ?? const []),
      primaryColor: (json['primaryColor'] ?? '#6200EE').toString(),
      secondaryColor: (json['secondaryColor'] ?? '#03DAC6').toString(),
      tertiaryColor: (json['tertiaryColor'] ?? '#FF6B6B').toString(),
      isDarkMode: json['isDarkMode'] == true,
      models: models,
      projectName: json['projectName']?.toString(),
      projectDescription: json['projectDescription']?.toString(),
      usedCloudAi: json['usedCloudAi'] == true,
    );
  }
}
