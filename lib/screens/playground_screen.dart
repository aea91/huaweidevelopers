import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/typescript.dart';

import '../services/arkts_playground_service.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _accent = Color(0xFFE11D48);
  static const _editor = Color(0xFF111827);

  static const _starterCode = '''declare function print(arg: any): any

function fibonacci(count: number): number[] {
  let values: number[] = [0, 1]

  for (let index: number = 2; index < count; index++) {
    values.push(values[index - 1] + values[index - 2])
  }

  return values
}

print("ArkTS Playground")
print(fibonacci(10))
''';

  final _codeController = CodeController(
    text: _starterCode,
    language: typescript,
  );
  final _playgroundService = ArkTsPlaygroundService();

  ArkTsRunResult? _result;
  String? _requestError;
  bool _isRunning = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _result = null;
      _requestError = null;
    });

    try {
      final result = await _playgroundService.run(_codeController.text);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _requestError = error.toString());
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _reset() {
    _codeController.text = _starterCode;
    setState(() {
      _result = null;
      _requestError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 14 : 24,
                  18,
                  isCompact ? 14 : 24,
                  20,
                ),
                child: isCompact
                    ? Column(
                        children: [
                          Expanded(flex: 3, child: _buildEditor()),
                          const SizedBox(height: 14),
                          Expanded(flex: 2, child: _buildOutput()),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: _buildEditor()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildOutput()),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 650;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 20,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ),
            icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.terminal_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ],
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ArkTS Playground',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.4,
                  ),
                ),
                if (!isNarrow)
                  Text(
                    'Compile ArkTS code and view console output',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
          if (isNarrow)
            IconButton(
              tooltip: 'Test Yourself',
              onPressed: () => Navigator.pushNamed(context, '/playground/quiz'),
              icon: const Icon(Icons.quiz_rounded, size: 20, color: _ink),
            )
          else
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/playground/quiz'),
              icon: const Icon(Icons.quiz_rounded, size: 18),
              label: const Text('Test Yourself'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (isNarrow)
            IconButton(
              tooltip: 'Reset',
              onPressed: _isRunning ? null : _reset,
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
            )
          else
            TextButton.icon(
              onPressed: _isRunning ? null : _reset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset'),
            ),
          const SizedBox(width: 8),
          if (isNarrow)
            IconButton.filled(
              tooltip: 'Run',
              style: IconButton.styleFrom(backgroundColor: _accent),
              onPressed: _isRunning ? null : _run,
              icon: _runIcon(),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: _isRunning ? null : _run,
              icon: _runIcon(),
              label: Text(_isRunning ? 'Running' : 'Run'),
            ),
        ],
      ),
    );
  }

  Widget _runIcon() {
    return _isRunning
        ? const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.play_arrow_rounded);
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        color: _editor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _panelHeader(title: 'main.ets', icon: Icons.code_rounded, dark: true),
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: vs2015Theme),
              child: CodeField(
                controller: _codeController,
                expands: true,
                maxLines: null,
                minLines: null,
                wrap: false,
                background: _editor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                cursorColor: const Color(0xFFFB7185),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: const Color(0xFFFB7185),
                  selectionColor: const Color(
                    0xFF334155,
                  ).withValues(alpha: 0.8),
                  selectionHandleColor: const Color(0xFFFB7185),
                ),
                lineNumberStyle: LineNumberStyle(
                  width: 52,
                  margin: 12,
                  background: const Color(0xFF0D1422),
                  textStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    height: 1.55,
                    color: const Color(0xFF64748B),
                  ),
                ),
                textStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  height: 1.55,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    final compileOutput = _result?.compileOutput.trim() ?? '';
    final runtimeOutput = _result?.runtimeOutput.trim() ?? '';
    final hasFailure =
        _requestError != null || (_result != null && !_result!.success);
    final output =
        _requestError ??
        (hasFailure
            ? (compileOutput.isNotEmpty ? compileOutput : runtimeOutput)
            : (runtimeOutput.isNotEmpty
                  ? runtimeOutput
                  : (_result == null
                        ? 'Run the code to see its output.'
                        : 'The program completed successfully with no console output.')));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelHeader(
            title: hasFailure ? 'Error' : 'Console',
            icon: hasFailure
                ? Icons.error_outline_rounded
                : Icons.terminal_rounded,
            status: _result == null ? null : '${_result!.durationMs} ms',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: SelectableText(
                output,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13.5,
                  height: 1.55,
                  color: hasFailure
                      ? const Color(0xFFBE123C)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelHeader({
    required String title,
    required IconData icon,
    bool dark = false,
    String? status,
  }) {
    final foreground = dark ? const Color(0xFFD1D5DB) : _ink;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: dark ? const Color(0xFF374151) : _line),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const Spacer(),
          if (status != null)
            Text(
              status,
              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _muted),
            ),
        ],
      ),
    );
  }
}
