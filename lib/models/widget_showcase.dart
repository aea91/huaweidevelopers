class WidgetShowcase {
  final String id;
  final String title;
  final String description;
  final String mainCategory; // Mobile, Smart Wearable, Light Wearable, PC (2in1)
  final String category; // Buttons, Bottom Navigation Bar, etc.
  final String gifPath;
  final String code;
  final List<String> tags;

  WidgetShowcase({
    required this.id,
    required this.title,
    required this.description,
    required this.mainCategory,
    required this.category,
    required this.gifPath,
    required this.code,
    required this.tags,
  });
}
