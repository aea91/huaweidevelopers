import '../../models/arkts_course.dart';
import '../../models/arkts_quiz_challenge.dart';
import 'lessons_part1.dart' show printDecl, huaweiBase;

const CourseLesson lesson06InterfacesNull = CourseLesson(
  id: 'interfaces-null',
  number: 6,
  title: 'Interfaces, Generics & Null Safety',
  summary:
      'Interfaces, generics, non-null by default, ??, optional chaining, and modules overview.',
  durationLabel: '28 min',
  sourceUrl: '$huaweiBase/introduction-to-arkts',
  sourceLabel: 'Official: Introduction to ArkTS — Interface / Null Safety',
  content: [
    CourseHeading('Interfaces'),
    CourseParagraph(
      'An interface describes a contract of properties and methods. Classes implement '
      'interfaces. Interfaces can extend other interfaces.',
    ),
    CourseCodeSnippet(
      title: 'interface',
      code: '''interface Named {
  name: string
}

class User implements Named {
  name: string = ''
  constructor(name: string) {
    this.name = name
  }
}
''',
    ),
    CourseHeading('Generics'),
    CourseParagraph(
      'Generic classes, interfaces, and functions parameterize types. Constraints use '
      'extends. Prefer explicit type arguments when inference is limited (ArkTS rule).',
    ),
    CourseCodeSnippet(
      title: 'generic',
      code: '''function identity<T>(value: T): T {
  return value
}
const n = identity<number>(10)
''',
    ),
    CourseHeading('Null safety'),
    CourseParagraph(
      'Types are non-nullable by default. null must be opt-in via T | null. '
      'Use ?? for defaults and ?. for optional chaining.',
    ),
    CourseCodeSnippet(
      title: 'null-safety',
      code: '''let x: number | null = null
x = 1
const nick: string | null = null
const display: string = nick ?? ''
''',
    ),
    CourseCallout(
      title: 'Modules (overview)',
      text:
          'Use export / import to share types and functions across .ets files. '
          'Top-level statements and this-binding rules are stricter than loose JS modules.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'in-e1',
      title: 'Null coalescing',
      explanation: 'Fall back when a value is null.',
      code: '''$printDecl

function label(nick: string | null): string {
  return nick ?? "guest"
}
print(label(null))
print(label("Ada"))
''',
    ),
    CourseExample(
      id: 'in-e2',
      title: 'Generic identity',
      explanation: 'Pass an explicit type argument.',
      code: '''$printDecl

function identity<T>(value: T): T {
  return value
}
print(identity<string>("ArkTS"))
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-in-q1',
      number: 1,
      title: 'Default nick',
      prompt:
          'Implement display(nick: string | null): string using ?? to return "anon" '
          'when null. Print display(null).',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

function display(nick: string | null): string {
  // TODO
  return ""
}
print(display(null))
''',
      expectedOutput: 'anon',
      hint: 'return nick ?? "anon"',
    ),
    ArkTsQuizChallenge(
      id: 'c-in-q2',
      number: 2,
      title: 'Generic echo',
      prompt:
          'Implement echo<T>(v: T): T and print echo<number>(99).',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function echo<T>(v: T): T {
  // TODO
  return v
}
print(echo<number>(99))
''',
      expectedOutput: '99',
      hint: 'return v',
    ),
  ],
);

const CourseLesson lesson07CodingStyleNaming = CourseLesson(
  id: 'style-naming',
  number: 7,
  title: 'Coding Style: Naming & Format',
  summary:
      'UpperCamelCase, lowerCamelCase, CONSTANT_CASE, boolean names, braces, and line length.',
  durationLabel: '20 min',
  sourceUrl: '$huaweiBase/arkts-coding-style-guide',
  sourceLabel: 'Official: ArkTS Coding Style Guide',
  content: [
    CourseHeading('Purpose'),
    CourseParagraph(
      'The ArkTS Coding Style Guide improves standardization, security, and performance. '
      'Rules must be followed; recommendations should be considered.',
    ),
    CourseHeading('Naming'),
    CourseBulletList([
      'Classes, enums, namespaces → UpperCamelCase (Person, UserType)',
      'Variables, methods, parameters → lowerCamelCase (userName, sendMsg)',
      'Constants & enum values → UPPER_SNAKE_CASE (MAX_USER_SIZE)',
      'Booleans → positive names with is/has/can/should (avoid isNotError)',
      'Clear English intent — no Pinyin, no cryptic single letters (except loop indices)',
    ]),
    CourseCodeSnippet(
      title: 'naming',
      code: '''class User {
  username: string
  constructor(username: string) {
    this.username = username
  }
}

enum UserType {
  TEACHER = 0,
  STUDENT = 1
}

const MAX_USER_SIZE = 10000
let isFound = true
''',
    ),
    CourseHeading('Format highlights'),
    CourseBulletList([
      'Spaces for indentation',
      '≤ 120 characters per line',
      'Always use braces for if/else and loops',
      'Prefer single quotes for strings in style guide samples',
      'Object literals with >4 properties: one property per line',
      'Put else/catch on the same line as the closing brace',
    ]),
  ],
  examples: [
    CourseExample(
      id: 'sn-e1',
      title: 'Constants',
      explanation: 'Style-compliant constant naming.',
      code: '''$printDecl

const MAX_RETRY_COUNT = 3
print(MAX_RETRY_COUNT)
''',
    ),
    CourseExample(
      id: 'sn-e2',
      title: 'Boolean prefix',
      explanation: 'Positive boolean naming.',
      code: '''$printDecl

function isReady(flag: boolean): string {
  return flag ? "yes" : "no"
}
print(isReady(true))
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-sn-q1',
      number: 1,
      title: 'CONSTANT_CASE',
      prompt:
          'Declare const MAX_BUFFER_SIZE = 1024 and print it.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

// TODO
''',
      expectedOutput: '1024',
      hint: 'Use UPPER_SNAKE_CASE for the name.',
    ),
    ArkTsQuizChallenge(
      id: 'c-sn-q2',
      number: 2,
      title: 'isEmpty helper',
      prompt:
          'Implement isEmpty(text: string): boolean — true if length is 0. '
          'Print isEmpty("") then isEmpty("a") on two lines as true/false.',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function isEmpty(text: string): boolean {
  // TODO
  return false
}
print(isEmpty(""))
print(isEmpty("a"))
''',
      expectedOutput: 'true\nfalse',
      hint: 'return text.length === 0',
    ),
  ],
);

const CourseLesson lesson08CodingStylePractices = CourseLesson(
  id: 'style-practices',
  number: 8,
  title: 'Coding Style: Programming Practices',
  summary:
      'Access modifiers, NaN checks, array methods, finally rules, avoid ESObject, prefer T[].',
  durationLabel: '18 min',
  sourceUrl: '$huaweiBase/arkts-coding-style-guide',
  sourceLabel: 'Official: ArkTS Coding Style Guide — Practices',
  content: [
    CourseHeading('Class properties need modifiers'),
    CourseParagraph(
      'Add public / private / protected so intent is explicit for readers and tooling.',
    ),
    CourseHeading('Numeric hygiene'),
    CourseBulletList([
      'Write 0.5 not .5; write 1.0 not 1.',
      'Use Number.isNaN() to test NaN — never x === NaN',
    ]),
    CourseHeading('Arrays'),
    CourseBulletList([
      'Prefer array methods for traversal when appropriate',
      'Declare arrays as T[] (e.g. number[]) rather than Array alone',
    ]),
    CourseHeading('Control & exceptions'),
    CourseBulletList([
      'Do not assign inside control conditions (if (x = y))',
      'Do not return/break/continue/throw from finally',
    ]),
    CourseCallout(
      title: 'Avoid ESObject',
      text:
          'ESObject is for ArkTS ↔ JS/TS cross-language boundaries. Using it elsewhere '
          'forces expensive cross-language calls. Prefer native ArkTS types.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'sp-e1',
      title: 'Typed array T[]',
      explanation: 'Prefer number[] style declarations.',
      code: '''$printDecl

const values: number[] = [1, 2, 3]
let total = 0
for (let i = 0; i < values.length; i++) {
  total += values[i]
}
print(total)
''',
    ),
    CourseExample(
      id: 'sp-e2',
      title: 'Explicit field modifiers',
      explanation: 'public fields with clear intent.',
      code: '''$printDecl

class Account {
  public id: number = 0
  public balance: number = 0
}
const a: Account = { id: 1, balance: 50 }
print(a.balance)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-sp-q1',
      number: 1,
      title: 'Sum T[]',
      prompt:
          'Sum const values: number[] = [4, 5, 6] and print the total. Expected: 15',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

const values: number[] = [4, 5, 6]
// TODO
''',
      expectedOutput: '15',
      hint: 'Loop and accumulate.',
    ),
    ArkTsQuizChallenge(
      id: 'c-sp-q2',
      number: 2,
      title: 'Float literal style',
      prompt:
          'Create const rate: number = 0.5 and print rate * 10. Expected: 5',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

// TODO: use 0.5 not .5
''',
      expectedOutput: '5',
      hint: 'print(0.5 * 10)',
    ),
  ],
);

const CourseLesson lesson09MigrationBackground = CourseLesson(
  id: 'migration-background',
  number: 9,
  title: 'Migration Background',
  summary:
      'Why ArkTS tightens TypeScript: stability, performance, .ets compatibility, and TS/JS interop.',
  durationLabel: '20 min',
  sourceUrl: '$huaweiBase/arkts-migration-background',
  sourceLabel: 'Official: ArkTS Migration Background',
  content: [
    CourseHeading('Why migrate from standard TS?'),
    CourseParagraph(
      'Building on TypeScript syntax, ArkTS strengthens static checks so more errors are '
      'caught during development — improving stability and runtime performance.',
    ),
    CourseHeading('Program stability'),
    CourseParagraph(
      'Dynamic languages can hide undefined bugs until runtime. TS helps with annotations, '
      'but optional typing still leaves gaps. ArkTS forces a static type system and stricter '
      'checks, including explicit field initialization.',
    ),
    CourseCodeSnippet(
      title: 'explicit-init',
      code: '''class Person {
  name: string = '' // must be initialized

  getName(): string {
    return this.name
  }
}
''',
      caption: 'Uninitialized fields that can be undefined are a common TS footgun.',
    ),
    CourseHeading('Program performance'),
    CourseParagraph(
      'JS engines must keep runtime type checks. ArkTS compiles to Ark bytecode with known '
      'layouts, enabling ahead-of-time optimization and fewer runtime checks.',
    ),
    CourseHeading('Compatibility topics'),
    CourseBulletList([
      '.ets code compatibility — ArkTS files use the .ets extension',
      'Interaction with TS/JS — interop is supported with clear boundaries',
      'ArkCompiler runtime compatibility with TS/JS modules',
    ]),
    CourseCallout(
      title: 'Null safety example',
      text:
          'Passing null into a stringy API may "work" in JS via ToString, but still costs '
          'runtime checks. Accurate types remove those hidden branches.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'mb-e1',
      title: 'Initialized field',
      explanation: 'Safe default prevents undefined length crashes.',
      code: '''$printDecl

class Person {
  name: string = ""
  getName(): string {
    return this.name
  }
}
const buddy = new Person()
print(buddy.getName().length)
''',
    ),
    CourseExample(
      id: 'mb-e2',
      title: 'Explicit nullable API',
      explanation: 'When null is possible, reflect it in the type.',
      code: '''$printDecl

class Person1 {
  name: string | null = null
  getName(): string | null {
    return this.name
  }
}
const p = new Person1()
print(p.getName() === null ? "none" : "set")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-mb-q1',
      number: 1,
      title: 'Safe default length',
      prompt:
          'class Tag { value: string = "ArkTS" }. Print new Tag().value.length.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

class Tag {
  value: string = "ArkTS"
}
// TODO
''',
      expectedOutput: '5',
      hint: 'print(new Tag().value.length)',
    ),
    ArkTsQuizChallenge(
      id: 'c-mb-q2',
      number: 2,
      title: 'Nullable branch',
      prompt:
          'let msg: string | null = null. Print "empty" if null else msg.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

let msg: string | null = null
// TODO
''',
      expectedOutput: 'empty',
      hint: 'print(msg === null ? "empty" : msg)',
    ),
  ],
);

const CourseLesson lesson10MigrationCore = CourseLesson(
  id: 'migration-core',
  number: 10,
  title: 'TS→ArkTS: Core Restrictions',
  summary:
      'Static typing, no any/unknown, let not var, fixed object layout, restricted operators, no structural typing.',
  durationLabel: '30 min',
  sourceUrl: '$huaweiBase/typescript-to-arkts-migration-guide',
  sourceLabel: 'Official: TypeScript to ArkTS Migration Guide',
  content: [
    CourseHeading('Recipes summarized'),
    CourseParagraph(
      'ArkTS constrains TS features that hurt correctness or force runtime overhead. '
      'Code rewritten to these rules remains valid TypeScript.',
    ),
    CourseHeading('1. Static typing is enforced'),
    CourseParagraph(
      'Ban any and unknown. Model API results with explicit classes/interfaces instead of '
      'untyped bags of data.',
    ),
    CourseCodeSnippet(
      title: 'no-any',
      code: '''// Unsupported: let res: any = api()
class CallResult {
  ok: boolean = false
  message: string = ''
}
let res: CallResult = { ok: true, message: 'done' }
''',
    ),
    CourseHeading('2. Object layout cannot change at runtime'),
    CourseBulletList([
      'No adding/removing properties dynamically',
      'No delete operator',
      'No indexed field access for arbitrary keys (obj[field])',
      'No Symbol()-generated keys',
    ]),
    CourseHeading('3. Operator semantics are restricted'),
    CourseParagraph(
      'Unary +, -, ~ apply to numbers only — no implicit string-to-number coercion.',
    ),
    CourseHeading('4. Structural typing is not supported'),
    CourseParagraph(
      'Two types are not interchangeable just because they share the same fields. Use '
      'explicit inheritance, interfaces, or aliases.',
    ),
    CourseCallout(
      title: 'Constraint levels',
      text:
          'Error = compile fails. Warning = compiles now but may become an error later. '
          'Treat warnings as errors in new code.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'mc-e1',
      title: 'let instead of var',
      explanation: 'Block-scoped bindings only.',
      code: '''$printDecl

function addTen(x: number): number {
  let ten = 10
  return x + ten
}
print(addTen(5))
''',
    ),
    CourseExample(
      id: 'mc-e2',
      title: 'Explicit result type',
      explanation: 'Replace any with a concrete shape.',
      code: '''$printDecl

class CallResult {
  ok: boolean = false
  message: string = ""
}
function run(): CallResult {
  return { ok: true, message: "ok" }
}
print(run().message)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-mc-q1',
      number: 1,
      title: 'let not var',
      prompt:
          'Rewrite with let: compute x + 10 for x=7 and print. Expected: 17',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

function addTen(x: number): number {
  // TODO: use let, not var
  return 0
}
print(addTen(7))
''',
      expectedOutput: '17',
      hint: 'let ten = 10; return x + ten',
    ),
    ArkTsQuizChallenge(
      id: 'c-mc-q2',
      number: 2,
      title: 'Typed API result',
      prompt:
          'class Status { code: number = 0 }. Return { code: 200 } from ok() and print code.',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

class Status {
  code: number = 0
}
function ok(): Status {
  // TODO
  return { code: 0 }
}
print(ok().code)
''',
      expectedOutput: '200',
      hint: 'return { code: 200 }',
    ),
  ],
);
