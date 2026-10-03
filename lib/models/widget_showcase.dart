class WidgetShowcase {
  final String id;
  final String title;
  final String description;
  final String mainCategory; // Mobile, Smart Wearable, PC (2in1)
  final String category; // Buttons, Bottom Navigation Bar, etc.
  final String gifPath;
  final String code;
  final List<String> tags;
  final DateTime? createdAt;

  WidgetShowcase({
    required this.id,
    required this.title,
    required this.description,
    required this.mainCategory,
    required this.category,
    required this.gifPath,
    required this.code,
    required this.tags,
    this.createdAt,
  });

  /// Label shown for a platform. The stored value stays "Smart Wearable"; users see "Wearable".
  static String platformLabel(String platform) =>
      platform == 'Smart Wearable' ? 'Wearable' : platform;

  String get platformDisplay => platformLabel(mainCategory);
}
