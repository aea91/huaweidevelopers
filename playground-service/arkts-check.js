'use strict';

// Static ArkTS check that runs before es2abc. es2abc only parses the source,
// so without this step `any`, `var`, untyped object literals and plain type
// errors would compile and run. ohos-typescript is OpenHarmony's TypeScript
// fork used by DevEco's ets-loader; it ships the official ArkTS linter.
const ts = require('ohos-typescript');

const SOURCE_FILE = '/playground/main.ets';
const PRELUDE_FILE = '/playground/prelude.d.ts';
const ARKTS_VERSION = '1.1';

// Globals that ark_js_vm provides at runtime (console is polyfilled in
// server.js). Kept in a .d.ts so the linter does not apply ArkTS rules to it.
const PRELUDE = `type PrintArg = Object | null | undefined;
declare function print(...args: PrintArg[]): void;
interface Console {
  log(...args: PrintArg[]): void;
  info(...args: PrintArg[]): void;
  warn(...args: PrintArg[]): void;
  error(...args: PrintArg[]): void;
  debug(...args: PrintArg[]): void;
}
declare const console: Console;
`;

// Course starter code ships with this line. print now comes from the prelude,
// so the line is blanked (same length, so positions stay put) instead of
// failing every lesson with arkts-no-any-unknown.
const LEGACY_PRINT_DECLARATION = /^declare function print\(arg: any\): any[ \t]*;?[ \t]*$/m;

const COMPILER_OPTIONS = {
  target: ts.ScriptTarget.ES2021,
  lib: ['lib.es2021.d.ts'],
  strict: true,
  noEmit: true,
  types: [],
  skipLibCheck: true,
};

// Library .d.ts files never change, so parse them once per process.
const libraryCache = new Map();

function createSourceFile(fileName, text, languageVersion) {
  const scriptKind = fileName.endsWith('.ets') ? ts.ScriptKind.ETS : ts.ScriptKind.TS;
  const sourceFile = ts.createSourceFile(fileName, text, languageVersion, true, scriptKind);
  // The builder program used by the linter requires versioned source files.
  sourceFile.version = '1';
  return sourceFile;
}

function createHost(files) {
  const host = ts.createCompilerHost(COMPILER_OPTIONS);
  const readLibrary = host.getSourceFile.bind(host);

  host.getSourceFile = (fileName, languageVersion, ...rest) => {
    if (files.has(fileName)) {
      return createSourceFile(fileName, files.get(fileName), languageVersion);
    }
    if (!libraryCache.has(fileName)) {
      const sourceFile = readLibrary(fileName, languageVersion, ...rest);
      if (sourceFile) sourceFile.version = '1';
      libraryCache.set(fileName, sourceFile);
    }
    return libraryCache.get(fileName);
  };
  host.fileExists = (fileName) => files.has(fileName) || ts.sys.fileExists(fileName);
  host.readFile = (fileName) => (files.has(fileName) ? files.get(fileName) : ts.sys.readFile(fileName));
  host.writeFile = () => {};
  return host;
}

function toDiagnostic(diagnostic) {
  const { line, character } = diagnostic.file.getLineAndCharacterOfPosition(diagnostic.start);
  // Linter diagnostics carry the rule name in the message ("... (arkts-no-var)");
  // tsc diagnostics carry a numeric code.
  const message = ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n');
  const rule = /\((arkts-[a-z0-9-]+)\)$/.exec(message)?.[1] ?? null;
  return {
    severity: diagnostic.category === ts.DiagnosticCategory.Error ? 'error' : 'warning',
    line: line + 1,
    column: character + 1,
    code: rule ?? `TS${diagnostic.code}`,
    message: rule ? message.slice(0, -(rule.length + 2)).trim() : message,
  };
}

function formatDiagnostics(diagnostics) {
  return diagnostics
    .map((d) => `${d.severity.toUpperCase()}: main.ets:${d.line}:${d.column} ${d.code}: ${d.message}`)
    .join('\n');
}

function checkArkTs(code) {
  const source = code.replace(LEGACY_PRINT_DECLARATION, (line) => ' '.repeat(line.length));
  const files = new Map([
    [SOURCE_FILE, source],
    [PRELUDE_FILE, PRELUDE],
  ]);

  const builderProgram = ts.createIncrementalProgram({
    rootNames: [...files.keys()],
    options: COMPILER_OPTIONS,
    host: createHost(files),
  });
  const program = builderProgram.getProgram();
  const sourceFile = program.getSourceFile(SOURCE_FILE);

  const raw = [
    ...program.getSyntacticDiagnostics(sourceFile),
    ...program.getSemanticDiagnostics(sourceFile),
    ...ts.ArkTSLinter_1_1.runArkTSLinter(builderProgram, sourceFile, undefined, ARKTS_VERSION),
  ];

  // The linter re-reports some strict-mode tsc errors; keep one of each.
  const seen = new Set();
  const diagnostics = raw
    .filter((d) => d.file && d.file.fileName === SOURCE_FILE && d.start !== undefined)
    .map(toDiagnostic)
    .filter((d) => {
      const key = `${d.line}:${d.column}:${d.code}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .sort((a, b) => a.line - b.line || a.column - b.column);

  return {
    ok: !diagnostics.some((d) => d.severity === 'error'),
    diagnostics,
    output: formatDiagnostics(diagnostics),
  };
}

module.exports = { checkArkTs };
