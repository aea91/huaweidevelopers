import '../../models/arkts_course.dart';
import '../../models/arkts_quiz_challenge.dart';
import 'lessons_part1.dart' show printDecl, huaweiBase;

const CourseLesson lesson11MigrationRecipes = CourseLesson(
  id: 'migration-recipes',
  number: 11,
  title: 'TS→ArkTS: Everyday Recipes',
  summary:
      'Practical cookbook rules: casting, destructuring, throw, for-in, nested functions, and more.',
  durationLabel: '32 min',
  sourceUrl: '$huaweiBase/typescript-to-arkts-migration-guide',
  sourceLabel: 'Official: TypeScript to ArkTS Cookbook — Recipes',
  content: [
    CourseHeading('High-frequency rewrites'),
    CourseBulletList([
      'Use private keyword — not #fields',
      'Cast only with as T — not angle-bracket casts',
      'No destructuring assignments/declarations/params — use temp variables',
      'No for...in — use indexed for on arrays',
      'No nested function declarations — use arrow functions',
      'throw only Error instances',
      'No delete, no in operator, limited typeof/instanceof',
      'No JSX',
      'Arrow functions instead of function expressions',
      'Declare class fields in the class body — not constructor parameter properties',
    ]),
    CourseHeading('Destructuring → temps'),
    CourseCodeSnippet(
      title: 'no-destructure',
      code: '''// Unsupported: let [a, b] = pair
// Unsupported: const { x, y } = point
const x = point.x
const y = point.y
''',
    ),
    CourseHeading('throw'),
    CourseCodeSnippet(
      title: 'throw-error',
      code: '''// Unsupported: throw "fail"
throw new Error("fail")
''',
    ),
    CourseHeading('Type casting'),
    CourseCodeSnippet(
      title: 'as-cast',
      code: '''const value: Object = "ArkTS"
const text = value as string
''',
    ),
    CourseCallout(
      title: 'Keep learning',
      text:
          'The official cookbook lists dozens of recipes (namespaces, enums, utility types, '
          'spread limits, globalThis, Function.bind, etc.). Use Adaptation Cases next for '
          'concrete before/after samples.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'mr-e1',
      title: 'Manual unpack',
      explanation: 'Replace destructuring with explicit reads.',
      code: '''$printDecl

class Point {
  x: number = 0
  y: number = 0
}
const point: Point = { x: 3, y: 4 }
const x = point.x
const y = point.y
print(x + y)
''',
    ),
    CourseExample(
      id: 'mr-e2',
      title: 'Arrow instead of nested function',
      explanation: 'Use a lambda for local helpers.',
      code: '''$printDecl

function total(a: number, b: number): number {
  const add = (x: number, y: number): number => x + y
  return add(a, b)
}
print(total(2, 8))
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-mr-q1',
      number: 1,
      title: 'Unpack Point',
      prompt:
          'Point {x:1,y:2}. Print x and y on two lines without destructuring.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

class Point {
  x: number = 0
  y: number = 0
}
const p: Point = { x: 1, y: 2 }
// TODO: print x then y
''',
      expectedOutput: '1\n2',
      hint: 'print(p.x); print(p.y)',
    ),
    ArkTsQuizChallenge(
      id: 'c-mr-q2',
      number: 2,
      title: 'Local arrow helper',
      prompt:
          'Inside compute(), use an arrow double = (n)=>n*2 and print double(11).',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function compute(): void {
  // TODO
}
compute()
''',
      expectedOutput: '22',
      hint: 'const double = (n: number): number => n * 2; print(double(11))',
    ),
    ArkTsQuizChallenge(
      id: 'c-mr-q3',
      number: 3,
      title: 'Explicit string variable',
      prompt:
          'let text: string = "OK". Print text. (Prefer explicit types over loose Object casts.)',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

let text: string = "OK"
// TODO
''',
      expectedOutput: 'OK',
      hint: 'print(text)',
    ),
  ],
);

const CourseLesson lesson12AdaptationCases = CourseLesson(
  id: 'adaptation-cases',
  number: 12,
  title: 'Adaptation Cases',
  summary:
      'Real migration patterns from the official More Cases guide: any→types, JSON, Record, literals, strict null.',
  durationLabel: '28 min',
  sourceUrl: '$huaweiBase/arkts-more-cases',
  sourceLabel: 'Official: Adaptation Cases (More Cases)',
  content: [
    CourseHeading('Learn by rewrite'),
    CourseParagraph(
      'Adaptation Cases shows concrete before/after samples for cookbook rules — ideal when '
      'a compiler error cites a rule id like arkts-no-any-unknown.',
    ),
    CourseHeading('any / unknown → specific types'),
    CourseCodeSnippet(
      title: 'typed-parse',
      code: '''class UserDto {
  id: number = 0
  name: string = ''
}
// Prefer parsing into a known shape instead of any
function asUser(id: number, name: string): UserDto {
  return { id: id, name: name }
}
''',
    ),
    CourseHeading('Record for string maps'),
    CourseParagraph(
      'When you need a string-keyed map of values, prefer Record<string, V> with known value '
      'types instead of open index signatures.',
    ),
    CourseCodeSnippet(
      title: 'record',
      code: '''const scores: Record<string, number> = {
  alice: 10,
  bob: 12
}
''',
    ),
    CourseHeading('Object literals'),
    CourseBulletList([
      'Annotate the target class/interface type',
      'Constructor should be parameterless if using class-typed literals',
      'Use identifier keys for class/interface fields; strings for Record keys',
      'Avoid export default { ... } untyped objects',
    ]),
    CourseHeading('Strict mode themes'),
    CourseBulletList([
      'strictPropertyInitialization — initialize fields',
      'Strict null checks — T | null must be handled',
      'Function return types must match all paths',
      'No use-before-assign',
    ]),
    CourseCallout(
      title: 'Rule ids are searchable',
      text:
          'When DevEco reports arkts-no-props-by-index or arkts-no-destruct-assignment, '
          'open Adaptation Cases and jump to that section for a rewrite recipe.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'ac-e1',
      title: 'DTO instead of any',
      explanation: 'Return a concrete object type.',
      code: '''$printDecl

class UserDto {
  id: number = 0
  name: string = ""
}
function asUser(id: number, name: string): UserDto {
  return { id: id, name: name }
}
print(asUser(1, "Ada").name)
''',
    ),
    CourseExample(
      id: 'ac-e2',
      title: 'Explicit map object',
      explanation: 'Prefer a declared class/interface over untyped bags.',
      code: '''$printDecl

class ScoreBoard {
  ada: number = 0
  bob: number = 0
}
const scores: ScoreBoard = { ada: 10, bob: 12 }
print(scores.bob)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-ac-q1',
      number: 1,
      title: 'UserDto',
      prompt:
          'Build UserDto {id:7, name:"Neo"} via a typed factory and print name.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

class UserDto {
  id: number = 0
  name: string = ""
}
function makeUser(id: number, name: string): UserDto {
  // TODO
  return { id: 0, name: "" }
}
print(makeUser(7, "Neo").name)
''',
      expectedOutput: 'Neo',
      hint: 'return { id: id, name: name }',
    ),
    ArkTsQuizChallenge(
      id: 'c-ac-q2',
      number: 2,
      title: 'Typed scores',
      prompt:
          'class ScoreBoard { ada: number = 0 }. Set ada to 99 and print it.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

class ScoreBoard {
  ada: number = 0
}
const scores: ScoreBoard = { ada: 99 }
// TODO
''',
      expectedOutput: '99',
      hint: 'print(scores.ada)',
    ),
    ArkTsQuizChallenge(
      id: 'c-ac-q3',
      number: 3,
      title: 'Handle null',
      prompt:
          'function len(s: string | null): number returns 0 if null else s.length. '
          'Print len(null) and len("Ark") on two lines.',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function len(s: string | null): number {
  // TODO
  return 0
}
print(len(null))
print(len("Ark"))
''',
      expectedOutput: '0\n3',
      hint: 'if (s === null) return 0; return s.length',
    ),
  ],
);

const CourseLesson lesson13HighPerformance = CourseLesson(
  id: 'high-performance',
  number: 13,
  title: 'High-Performance Programming',
  summary:
      'const, stable number kinds, loop hoisting, parameter passing, TypedArray tips, avoid sparse/union arrays & hot exceptions.',
  durationLabel: '30 min',
  sourceUrl: '$huaweiBase/arkts-high-performance-programming',
  sourceLabel: 'Official: ArkTS High-Performance Programming',
  content: [
    CourseHeading('Overview'),
    CourseParagraph(
      'These practices come from real performance-sensitive HarmonyOS code. Apply them in '
      'hot paths; combine with the Coding Style Guide for everyday quality.',
    ),
    CourseHeading('Declarations & expressions'),
    CourseBulletList([
      'Use const for values that never change',
      'Do not mix ints and floats in the same number variable after init',
      'Avoid arithmetic overflow past INT32 ranges in hot math',
      'Hoist loop-invariant property access outside loops',
    ]),
    CourseCodeSnippet(
      title: 'hoist',
      code: '''// Prefer:
const info = Time.info[num - Time.start]
for (let index = 0x8000; index > 0x8; index >>= 1) {
  // use info ...
}
''',
    ),
    CourseHeading('Functions'),
    CourseBulletList([
      'Pass external values as parameters instead of capturing heavy closures',
      'Avoid optional parameters in hot functions — use defaults instead',
    ]),
    CourseHeading('Arrays'),
    CourseBulletList([
      'Prefer TypedArray for pure numeric workloads',
      'Avoid sparse arrays (huge length holes → hash storage)',
      'Avoid union arrays like (number | string)[]; keep homogeneous arrays',
      'Do not mix int/float in the same number[] when avoidable',
    ]),
    CourseHeading('Exceptions'),
    CourseParagraph(
      'Creating exceptions builds stack frames. Do not throw inside tight loops — validate '
      'once and branch instead.',
    ),
    CourseCallout(
      title: 'Measure what matters',
      text:
          'Micro-optimizations help hottest paths. Clear types and stable layouts already '
          'buy most of ArkTS’s performance story.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'hp-e1',
      title: 'const + hoist',
      explanation: 'Cache invariant before looping.',
      code: '''$printDecl

const factor: number = 3
let total: number = 0
for (let i = 1; i <= 4; i++) {
  total += i * factor
}
print(total)
''',
    ),
    CourseExample(
      id: 'hp-e2',
      title: 'Params over closure',
      explanation: 'Pass the array in for less capture overhead.',
      code: '''$printDecl

function sum2(array: number[]): number {
  return array[0] + array[1]
}
print(sum2([4, 6]))
''',
    ),
    CourseExample(
      id: 'hp-e3',
      title: 'Homogeneous arrays',
      explanation: 'Keep number[] and string[] separate.',
      code: '''$printDecl

const arrInt: number[] = [1, 2, 3]
const arrString: string[] = ["a", "b"]
print(arrInt.length + arrString.length)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-hp-q1',
      number: 1,
      title: 'Hoisted factor',
      prompt:
          'const factor = 5. Sum i*factor for i=1..3 and print. Expected: 30',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

const factor: number = 5
// TODO
''',
      expectedOutput: '30',
      hint: '1*5 + 2*5 + 3*5 = 30',
    ),
    ArkTsQuizChallenge(
      id: 'c-hp-q2',
      number: 2,
      title: 'Pass the array',
      prompt:
          'Implement firstTwoSum(arr: number[]): number as arr[0]+arr[1]. '
          'Print firstTwoSum([10, 32]).',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

function firstTwoSum(arr: number[]): number {
  // TODO
  return 0
}
print(firstTwoSum([10, 32]))
''',
      expectedOutput: '42',
      hint: 'return arr[0] + arr[1]',
    ),
    ArkTsQuizChallenge(
      id: 'c-hp-q3',
      number: 3,
      title: 'Defaults not optionals',
      prompt:
          'add(left = 0, right = 0) returns left+right. Print add() and add(2,3) on two lines.',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function add(left: number = 0, right: number = 0): number {
  // TODO
  return 0
}
print(add())
print(add(2, 3))
''',
      expectedOutput: '0\n5',
      hint: 'return left + right',
    ),
  ],
);

const CourseLesson lesson14Capstone = CourseLesson(
  id: 'capstone',
  number: 14,
  title: 'Capstone: Think in ArkTS',
  summary:
      'Pull the pathway together — static types, style, migration habits, and performance instincts.',
  durationLabel: '20 min',
  sourceUrl: '$huaweiBase/arkts-get-started',
  sourceLabel: 'Official pathway hub: Getting Started with ArkTS',
  content: [
    CourseHeading('Your ArkTS checklist'),
    CourseBulletList([
      'Types are explicit; any/unknown are gone',
      'Object shapes are fixed at compile time',
      'Naming and format follow the style guide',
      'TS code is rewritten using the cookbook + adaptation cases',
      'Hot paths follow high-performance practices',
    ]),
    CourseHeading('Recommended official reading order'),
    CourseBulletList([
      'Getting Started with ArkTS',
      'Introduction to ArkTS',
      'ArkTS Coding Style Guide',
      'ArkTS Migration Background',
      'TypeScript to ArkTS Migration Guide',
      'Adaptation Cases',
      'ArkTS High-Performance Programming',
    ]),
    CourseParagraph(
      'Continue practicing in Playground → Test Yourself, and apply the same patterns in '
      'real .ets UI code inside DevEco Studio.',
    ),
    CourseCallout(
      title: 'Document-first course',
      text:
          'This course stays document + examples + graded quizzes. Use the Official docs '
          'button on each lesson to open Huawei’s full reference when you need depth.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'cap-e1',
      title: 'Idiomatic snippet',
      explanation: 'Typed helper + const + clear naming.',
      code: '''$printDecl

const APP_NAME = "ArkUI Build"

function formatTitle(chapter: number, title: string): string {
  return APP_NAME + " / " + chapter + ". " + title
}
print(formatTitle(14, "Capstone"))
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-cap-q1',
      number: 1,
      title: 'Format line',
      prompt:
          'Print exactly ArkTS: ready using a const language = "ArkTS".',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

const language: string = "ArkTS"
// TODO
''',
      expectedOutput: 'ArkTS: ready',
      hint: 'print(language + ": ready")',
    ),
    ArkTsQuizChallenge(
      id: 'c-cap-q2',
      number: 2,
      title: 'Mini pipeline',
      prompt:
          'Implement normalize(s: string): string that returns s in lower-ish form by '
          'returning "arkts" when s is "ArkTS", else s. Print normalize("ArkTS").',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function normalize(s: string): string {
  // TODO
  return s
}
print(normalize("ArkTS"))
''',
      expectedOutput: 'arkts',
      hint: 'if (s === "ArkTS") return "arkts"; return s',
    ),
    ArkTsQuizChallenge(
      id: 'c-cap-q3',
      number: 3,
      title: 'Score summary',
      prompt:
          'class Score { value: number = 0 }. Create { value: 100 }, print value.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

class Score {
  value: number = 0
}
// TODO
''',
      expectedOutput: '100',
      hint: 'const s: Score = { value: 100 }; print(s.value)',
    ),
  ],
);
