import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_chrome.dart';
import '../widgets/code_viewer.dart';

class ClassBuilderScreen extends StatefulWidget {
  const ClassBuilderScreen({super.key});

  @override
  State<ClassBuilderScreen> createState() => _ClassBuilderScreenState();
}

class _ClassBuilderScreenState extends State<ClassBuilderScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController(text: 'MyClass');
  
  String _generatedCode = '';
  String? _errorMessage;
  bool _makeNullable = false;

  @override
  void initState() {
    super.initState();
    // Sample JSON
    _jsonController.text = '''{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "age": 30,
  "isActive": true,
  "balance": 1500.50,
  "tags": ["developer", "designer"],
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "zipCode": "10001"
  }
}''';
    _generateClass();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  void _generateClass() {
    setState(() {
      _errorMessage = null;
      try {
        final jsonString = _jsonController.text.trim();
        if (jsonString.isEmpty) {
          _generatedCode = '// Enter JSON data to generate ArkTS class';
          return;
        }

        final dynamic jsonData = jsonDecode(jsonString);
        final className = _classNameController.text.trim().isEmpty 
            ? 'MyClass' 
            : _classNameController.text.trim();

        _generatedCode = _generateArkTSClass(className, jsonData, _makeNullable);
      } catch (e) {
        _errorMessage = 'Invalid JSON: ${e.toString()}';
        _generatedCode = '// Error: Invalid JSON format\n// Please check your JSON syntax';
      }
    });
  }

  String _generateArkTSClass(String className, dynamic jsonData, bool makeNullable) {
    if (jsonData is! Map<String, dynamic>) {
      throw Exception('JSON must be an object');
    }

    final buffer = StringBuffer();
    final nestedClasses = <String>[];

    // Generate main class
    buffer.writeln('// Generated ArkTS Class');
    buffer.writeln('// Date: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln();
    
    _generateClassDefinition(
      buffer, 
      className, 
      jsonData, 
      makeNullable, 
      nestedClasses,
    );

    // Generate nested classes
    for (final nestedClass in nestedClasses) {
      buffer.writeln();
      buffer.write(nestedClass);
    }

    return buffer.toString();
  }

  void _generateClassDefinition(
    StringBuffer buffer,
    String className,
    Map<String, dynamic> jsonData,
    bool makeNullable,
    List<String> nestedClasses,
  ) {
    final fields = <String, String>{};
    
    // Analyze fields
    jsonData.forEach((key, value) {
      final fieldName = _toCamelCase(key);
      final fieldType = _getArkTSType(value, key, nestedClasses, makeNullable);
      fields[fieldName] = fieldType;
    });

    // Class definition
    buffer.writeln('export class $className {');
    
    // Properties
    for (final entry in fields.entries) {
      final nullable = makeNullable ? '?' : '';
      buffer.writeln('  ${entry.key}$nullable: ${entry.value};');
    }
    
    buffer.writeln();
    
    // Constructor
    buffer.writeln('  constructor(');
    final entries = fields.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final nullable = makeNullable ? '?' : '';
      final comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln('    ${entry.key}$nullable: ${entry.value}$comma');
    }
    buffer.writeln('  ) {');
    for (final entry in fields.entries) {
      buffer.writeln('    this.${entry.key} = ${entry.key};');
    }
    buffer.writeln('  }');
    
    buffer.writeln();
    
    // fromJson method
    buffer.writeln('  static fromJson(json: any): $className {');
    buffer.writeln('    return new $className(');
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = _findOriginalKey(jsonData, entry.key);
      final comma = i < entries.length - 1 ? ',' : '';
      
      // Check if it's a nested object or array
      final value = jsonData[key];
      if (value is Map) {
        final nestedClassName = _capitalize(entry.key);
        buffer.writeln('      json[\'$key\'] ? $nestedClassName.fromJson(json[\'$key\']) : null$comma');
      } else if (value is List && value.isNotEmpty && value[0] is Map) {
        final nestedClassName = _capitalize(_singularize(entry.key));
        buffer.writeln('      json[\'$key\']?.map((item: any) => $nestedClassName.fromJson(item)) ?? []$comma');
      } else {
        buffer.writeln('      json[\'$key\']$comma');
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    
    buffer.writeln();
    
    // toJson method
    buffer.writeln('  toJson(): Object {');
    buffer.writeln('    return {');
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = _findOriginalKey(jsonData, entry.key);
      final comma = i < entries.length - 1 ? ',' : '';
      
      // Check if it's a nested object or array
      final value = jsonData[key];
      if (value is Map) {
        buffer.writeln('      \'$key\': this.${entry.key}?.toJson()$comma');
      } else if (value is List && value.isNotEmpty && value[0] is Map) {
        buffer.writeln('      \'$key\': this.${entry.key}?.map((item) => item.toJson())$comma');
      } else {
        buffer.writeln('      \'$key\': this.${entry.key}$comma');
      }
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    
    buffer.writeln('}');
  }

  String _getArkTSType(dynamic value, String key, List<String> nestedClasses, bool makeNullable) {
    if (value == null) {
      return 'any';
    } else if (value is int) {
      return 'number';
    } else if (value is double) {
      return 'number';
    } else if (value is bool) {
      return 'boolean';
    } else if (value is String) {
      return 'string';
    } else if (value is List) {
      if (value.isEmpty) {
        return 'any[]';
      }
      final firstElement = value[0];
      if (firstElement is Map) {
        final nestedClassName = _capitalize(_singularize(key));
        final nestedBuffer = StringBuffer();
        _generateClassDefinition(
          nestedBuffer,
          nestedClassName,
          firstElement as Map<String, dynamic>,
          makeNullable,
          nestedClasses,
        );
        nestedClasses.add(nestedBuffer.toString());
        return '$nestedClassName[]';
      } else {
        final elementType = _getArkTSType(firstElement, key, nestedClasses, makeNullable);
        return '$elementType[]';
      }
    } else if (value is Map) {
      final nestedClassName = _capitalize(key);
      final nestedBuffer = StringBuffer();
      _generateClassDefinition(
        nestedBuffer,
        nestedClassName,
        value as Map<String, dynamic>,
        makeNullable,
        nestedClasses,
      );
      nestedClasses.add(nestedBuffer.toString());
      return nestedClassName;
    }
    return 'any';
  }

  String _toCamelCase(String str) {
    if (str.isEmpty) return str;
    
    // Handle snake_case
    if (str.contains('_')) {
      final parts = str.split('_');
      return parts[0] + parts.skip(1).map(_capitalize).join('');
    }
    
    // Handle kebab-case
    if (str.contains('-')) {
      final parts = str.split('-');
      return parts[0] + parts.skip(1).map(_capitalize).join('');
    }
    
    // Already camelCase or single word
    return str[0].toLowerCase() + str.substring(1);
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  String _singularize(String str) {
    // Simple singularization
    if (str.endsWith('ies')) {
      return str.substring(0, str.length - 3) + 'y';
    }
    if (str.endsWith('ses') || str.endsWith('xes') || str.endsWith('zes')) {
      return str.substring(0, str.length - 2);
    }
    if (str.endsWith('s')) {
      return str.substring(0, str.length - 1);
    }
    return str;
  }

  String _findOriginalKey(Map<String, dynamic> jsonData, String camelCaseKey) {
    // Find the original key in JSON that matches the camelCase version
    for (final key in jsonData.keys) {
      if (_toCamelCase(key) == camelCaseKey) {
        return key;
      }
    }
    return camelCaseKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppChrome.canvas,
      appBar: AppChrome.appBar(
        context: context,
        title: 'Class Builder',
        icon: Icons.code_rounded,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          
          if (isMobile) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputSection(),
          const SizedBox(height: 24),
          _buildOutputSection(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Input
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildInputSection(),
            ),
          ),
        ),
        // Right side - Output
        Expanded(
          flex: 1,
          child: _buildOutputSection(),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'JSON Input',
          style: AppChrome.body(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppChrome.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Paste your JSON data below',
          style: AppChrome.body(
            fontSize: 14,
            color: AppChrome.muted,
          ),
        ),
        const SizedBox(height: 16),
        
        // Class Name Input
        TextField(
          controller: _classNameController,
          decoration: InputDecoration(
            labelText: 'Class Name',
            hintText: 'e.g., User, Product, Order',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.class_, color: AppChrome.ink),
          ),
          onChanged: (value) => _generateClass(),
        ),
        
        const SizedBox(height: 16),
        
        // Nullable option
        CheckboxListTile(
          title: Text(
            'Make properties nullable',
            style: AppChrome.body(fontSize: 14),
          ),
          subtitle: Text(
            'Add ? to all properties for optional values',
            style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
          ),
          value: _makeNullable,
          onChanged: (value) {
            setState(() {
              _makeNullable = value ?? false;
              _generateClass();
            });
          },
          activeColor: AppChrome.ink,
          contentPadding: EdgeInsets.zero,
        ),
        
        const SizedBox(height: 16),
        
        // JSON Input
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: _errorMessage != null
                ? Border.all(color: Colors.red, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'input.json',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: const Color(0xFFCCCCCC),
                      ),
                    ),
                    const Spacer(),
                    if (_errorMessage != null)
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _jsonController,
                maxLines: 20,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: const Color(0xFFD4D4D4),
                  height: 1.5,
                ),
                onChanged: (value) => _generateClass(),
              ),
            ],
          ),
        ),
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppChrome.body(
                      fontSize: 13,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        ElevatedButton.icon(
          onPressed: _generateClass,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('Regenerate'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppChrome.ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputSection() {
    return Container(
      color: AppChrome.canvas,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generated ArkTS Class',
                    style: AppChrome.body(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppChrome.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Copy and use in your HarmonyOS project',
                    style: AppChrome.body(
                      fontSize: 14,
                      color: AppChrome.muted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Code copied to clipboard!',
                            style: AppChrome.body(),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppChrome.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CodeViewer(
              code: _generatedCode,
              title: _classNameController.text.trim().isEmpty 
                  ? 'MyClass' 
                  : _classNameController.text.trim(),
            ),
          ),
        ],
      ),
    );
  }
}
