class ManagerDefinition {
  final String id;
  final String title;
  final String description;
  final String className;
  final String code;
  final String exportCode;
  final List<String> permissions;

  const ManagerDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.className,
    required this.code,
    required this.exportCode,
    required this.permissions,
  });

  String get fileName => '$className.ets';

  factory ManagerDefinition.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return ManagerDefinition(
      id: id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      className: (data['className'] ?? '').toString(),
      code: (data['code'] ?? '').toString(),
      exportCode: (data['exportCode'] ?? '').toString(),
      permissions: List<String>.from(data['permissions'] ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'className': className,
      'code': code,
      'exportCode': exportCode,
      'permissions': permissions,
    };
  }
}

