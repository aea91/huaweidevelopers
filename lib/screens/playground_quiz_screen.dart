import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/typescript.dart';

import '../data/arkts_quiz_challenges.dart';
import '../models/arkts_quiz_challenge.dart';
import '../services/arkts_playground_service.dart';

class PlaygroundQuizScreen extends StatefulWidget {
  const PlaygroundQuizScreen({super.key});

  @override
  State<PlaygroundQuizScreen> createState() => _PlaygroundQuizScreenState();
}

class _PlaygroundQuizScreenState extends State<PlaygroundQuizScreen> {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _accent = Color(0xFFE11D48);
  static const _editor = Color(0xFF111827);
  static const _success = Color(0xFF059669);

  final _challenges = arkTsQuizChallenges;
  final _playgroundService = ArkTsPlaygroundService();
  late final CodeController _codeController;

  int _index = 0;
  int _score = 0;
  final Set<String> _solvedIds = {};
  final Set<String> _attemptedWrong = {};

  ArkTsRunResult? _result;
  String? _requestError;
  bool _isRunning = false;
  bool _showHint = false;
  String? _gradeMessage;
  bool _lastAnswerCorrect = false;
  bool _showResults = false;

  ArkTsQuizChallenge get _challenge => _challenges[_index];

  int get _maxScore =>
      _challenges.fold<int>(0, (sum, challenge) => sum + challenge.points);

  bool get _allSolved => _solvedIds.length == _challenges.length;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: _challenge.starterCode,
      language: typescript,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _loadChallenge(int index) {
    setState(() {
      _index = index;
      _codeController.text = _challenges[index].starterCode;
      _result = null;
      _requestError = null;
      _showHint = false;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
    });
  }

  void _resetCode() {
    setState(() {
      _codeController.text = _challenge.starterCode;
      _result = null;
      _requestError = null;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
    });
  }

  String _normalizeOutput(String value) {
    final lines = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .toList();

    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }

    return lines.join('\n').trim();
  }

  Future<void> _runAndGrade() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _result = null;
      _requestError = null;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
    });

    try {
      final result = await _playgroundService.run(_codeController.text);
      if (!mounted) return;

      final alreadySolved = _solvedIds.contains(_challenge.id);
      final actual = _normalizeOutput(result.runtimeOutput);
      final expected = _normalizeOutput(_challenge.expectedOutput);
      final correct = result.success && actual == expected;

      setState(() {
        _result = result;
        if (correct) {
          _lastAnswerCorrect = true;
          if (!alreadySolved) {
            _solvedIds.add(_challenge.id);
            _score += _challenge.points;
            _gradeMessage =
                'Correct! +${_challenge.points} points. Total: $_score / $_maxScore';
            if (_allSolved) {
              _showResults = true;
            }
          } else {
            _gradeMessage =
                'Correct again. You already earned these ${_challenge.points} points.';
          }
        } else if (!result.success) {
          _attemptedWrong.add(_challenge.id);
          _gradeMessage =
              'Compilation or runtime failed. Fix the errors and try again.';
        } else {
          _attemptedWrong.add(_challenge.id);
          _gradeMessage =
              'Output does not match the expected result. Keep going!';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = error.toString();
        _attemptedWrong.add(_challenge.id);
        _gradeMessage = 'Could not run the challenge. Check the service and try again.';
      });
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Color _difficultyColor(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return const Color(0xFF059669);
      case QuizDifficulty.medium:
        return const Color(0xFFD97706);
      case QuizDifficulty.hard:
        return _accent;
    }
  }

  void _openResults() {
    setState(() => _showResults = true);
  }

  void _retakeQuiz() {
    setState(() {
      _showResults = false;
      _index = 0;
      _score = 0;
      _solvedIds.clear();
      _attemptedWrong.clear();
      _result = null;
      _requestError = null;
      _showHint = false;
      _gradeMessage = null;
      _lastAnswerCorrect = false;
      _codeController.text = _challenges[0].starterCode;
    });
  }

  void _continueReviewing() {
    setState(() => _showResults = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _showResults
                  ? _buildResultsScreen()
                  : Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 14 : 24,
                        16,
                        isCompact ? 14 : 24,
                        18,
                      ),
                      child: isCompact
                          ? Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _buildQuestionPanel(),
                                ),
                                const SizedBox(height: 14),
                                Expanded(flex: 7, child: _buildWorkspace()),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _buildQuestionPanel(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(flex: 7, child: _buildWorkspace()),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final solvedCount = _solvedIds.length;
    final totalCount = _challenges.length;
    final percent =
        _maxScore == 0 ? 0 : ((_score / _maxScore) * 100).round();

    String headline;
    if (_score >= _maxScore) {
      headline = 'Perfect score!';
    } else if (_score >= (_maxScore * 0.7).round()) {
      headline = 'Great work!';
    } else if (_score > 0) {
      headline = 'Nice effort!';
    } else {
      headline = 'Quiz complete';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _score >= _maxScore
                        ? Icons.emoji_events_rounded
                        : Icons.stars_rounded,
                    size: 36,
                    color: _score >= _maxScore
                        ? const Color(0xFFD97706)
                        : _success,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  solvedCount == totalCount
                      ? 'You finished all $totalCount ArkTS challenges.'
                      : 'You solved $solvedCount of $totalCount challenges.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Your points',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_score',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'out of $_maxScore',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _metaChip(
                      label: '$solvedCount / $totalCount solved',
                      color: _success,
                    ),
                    _metaChip(label: '$percent%', color: _ink),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _retakeQuiz,
                    child: Text(
                      'Try again',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _line),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _continueReviewing,
                    child: Text(
                      'Review challenges',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/playground',
                    (route) => route.isFirst,
                  ),
                  child: Text(
                    'Back to Playground',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Playground',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/playground',
              (route) => route.isFirst,
            ),
            icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 4),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Yourself',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.4,
                  ),
                ),
                if (!isNarrow)
                  Text(
                    'Solve 10 ArkTS challenges and earn points',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
          _scoreBadge(),
          if (!_showResults) ...[
            const SizedBox(width: 8),
            if (_allSolved)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: _openResults,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                  ),
                  child: const Text('Results'),
                ),
              ),
            if (isNarrow)
              IconButton.filled(
                tooltip: 'Run & Check',
                style: IconButton.styleFrom(backgroundColor: _accent),
                onPressed: _isRunning ? null : _runAndGrade,
                icon: _runIcon(),
              )
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
                onPressed: _isRunning ? null : _runAndGrade,
                icon: _runIcon(),
                label: Text(_isRunning ? 'Checking' : 'Run & Check'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _scoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Text(
            '$_score / $_maxScore',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
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

  Widget _buildQuestionPanel() {
    final challenge = _challenge;
    final solved = _solvedIds.contains(challenge.id);
    final difficultyColor = _difficultyColor(challenge.difficulty);

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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Challenge ${challenge.number} of ${_challenges.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                    const Spacer(),
                    if (solved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'Solved',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  challenge.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metaChip(
                      label: challenge.difficulty.label,
                      color: difficultyColor,
                    ),
                    _metaChip(
                      label: '${challenge.points} pts',
                      color: _ink,
                    ),
                    _metaChip(
                      label: '${_solvedIds.length}/${_challenges.length} done',
                      color: _muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.prompt,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      height: 1.5,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Expected output',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      challenge.expectedOutput,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  if (_showHint) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Hint',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.hint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        height: 1.45,
                        color: _muted,
                      ),
                    ),
                  ],
                  if (_gradeMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lastAnswerCorrect
                            ? _success.withValues(alpha: 0.1)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _lastAnswerCorrect
                              ? _success.withValues(alpha: 0.3)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        _gradeMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _lastAnswerCorrect
                              ? _success
                              : const Color(0xFFBE123C),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _challenges.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final item = _challenges[index];
                      final selected = index == _index;
                      final itemSolved = _solvedIds.contains(item.id);
                      final itemWrong = !itemSolved &&
                          _attemptedWrong.contains(item.id);
                      final idleColor = itemSolved
                          ? _success
                          : itemWrong
                              ? _accent
                              : _ink;
                      return ChoiceChip(
                        label: Text('${item.number}'),
                        selected: selected,
                        onSelected: (_) => _loadChallenge(index),
                        selectedColor: _ink,
                        labelStyle: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : idleColor,
                        ),
                        backgroundColor: itemSolved
                            ? _success.withValues(alpha: 0.12)
                            : itemWrong
                                ? _accent.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: selected
                              ? _ink
                              : itemSolved
                                  ? _success.withValues(alpha: 0.4)
                                  : itemWrong
                                      ? _accent.withValues(alpha: 0.35)
                                      : _line,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index == 0
                            ? null
                            : () => _loadChallenge(_index - 1),
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        label: const Text('Prev'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showHint = true),
                        icon: const Icon(Icons.lightbulb_outline, size: 18),
                        label: const Text('Hint'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _index >= _challenges.length - 1
                          ? FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                              ),
                              onPressed: _openResults,
                              icon: const Icon(
                                Icons.emoji_events_outlined,
                                size: 18,
                              ),
                              label: const Text('Finish'),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _loadChallenge(_index + 1),
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                              ),
                              label: const Text('Next'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    return Column(
      children: [
        Expanded(flex: 3, child: _buildEditor()),
        const SizedBox(height: 12),
        Expanded(flex: 2, child: _buildOutput()),
      ],
    );
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
          _panelHeader(
            title: 'challenge.ets',
            icon: Icons.code_rounded,
            dark: true,
            trailing: TextButton(
              onPressed: _isRunning ? null : _resetCode,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Reset code'),
            ),
          ),
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
    final output = _requestError ??
        (hasFailure
            ? (compileOutput.isNotEmpty ? compileOutput : runtimeOutput)
            : (runtimeOutput.isNotEmpty
                ? runtimeOutput
                : (_result == null
                    ? 'Run & Check to compile your solution and compare the output.'
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
            title: hasFailure
                ? 'Error'
                : (_lastAnswerCorrect ? 'Correct output' : 'Console'),
            icon: hasFailure
                ? Icons.error_outline_rounded
                : (_lastAnswerCorrect
                    ? Icons.check_circle_outline_rounded
                    : Icons.terminal_rounded),
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
                      : (_lastAnswerCorrect
                          ? _success
                          : const Color(0xFF334155)),
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
    Widget? trailing,
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
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
