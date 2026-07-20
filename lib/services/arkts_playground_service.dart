import 'dart:convert';

import 'package:http/http.dart' as http;

class ArkTsRunResult {
  final bool success;
  final String compileOutput;
  final String runtimeOutput;
  final int? compileExitCode;
  final int? runtimeExitCode;
  final int durationMs;

  const ArkTsRunResult({
    required this.success,
    required this.compileOutput,
    required this.runtimeOutput,
    required this.compileExitCode,
    required this.runtimeExitCode,
    required this.durationMs,
  });

  factory ArkTsRunResult.fromJson(Map<String, dynamic> json) {
    return ArkTsRunResult(
      success: json['success'] == true,
      compileOutput: json['compileOutput']?.toString() ?? '',
      runtimeOutput: json['runtimeOutput']?.toString() ?? '',
      compileExitCode: (json['compileExitCode'] as num?)?.toInt(),
      runtimeExitCode: (json['runtimeExitCode'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class ArkTsPlaygroundException implements Exception {
  final String message;

  const ArkTsPlaygroundException(this.message);

  @override
  String toString() => message;
}

class ArkTsPlaygroundService {
  static const _configuredUrl = String.fromEnvironment(
    'ARKTS_PLAYGROUND_API_URL',
    defaultValue:
        'https://arkuibuild-playground-497257718509.europe-west1.run.app',
  );

  Uri get _runUri {
    if (_configuredUrl.trim().isEmpty) {
      throw const ArkTsPlaygroundException(
        'The playground service is not configured. Build the app '
        'with --dart-define=ARKTS_PLAYGROUND_API_URL=https://....',
      );
    }

    final base = _configuredUrl.endsWith('/')
        ? _configuredUrl.substring(0, _configuredUrl.length - 1)
        : _configuredUrl;
    return Uri.parse('$base/run');
  }

  Future<ArkTsRunResult> run(String code) async {
    if (code.trim().isEmpty) {
      throw const ArkTsPlaygroundException('The ArkTS code to run is empty.');
    }

    try {
      final response = await http
          .post(
            _runUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 12));

      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ArkTsPlaygroundException(
          body['error']?.toString() ??
              'The playground service returned ${response.statusCode}.',
        );
      }

      return ArkTsRunResult.fromJson(body);
    } on ArkTsPlaygroundException {
      rethrow;
    } on FormatException {
      throw const ArkTsPlaygroundException(
        'The playground service returned an invalid response.',
      );
    } catch (error) {
      throw ArkTsPlaygroundException(
        'Could not reach the playground service: $error',
      );
    }
  }
}
