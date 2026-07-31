import '../../models/arkts_course.dart';
import '../../models/arkts_quiz_challenge.dart';

const printDecl = 'declare function print(arg: any): any';

const huaweiBase = 'https://developer.huawei.com/consumer/en/doc/harmonyos-guides';

const CourseLesson lesson01GetStarted = CourseLesson(
  id: 'get-started',
  number: 1,
  title: 'Getting Started with ArkTS',
  summary:
      'What ArkTS is, why HarmonyOS prefers it, and the four pillars that separate it from TypeScript.',
  durationLabel: '15 min',
  sourceUrl: '$huaweiBase/arkts-get-started',
  sourceLabel: 'Official: Getting Started with ArkTS',
  content: [
    CourseHeading('Preferred language for HarmonyOS'),
    CourseParagraph(
      'ArkTS is the preferred programming language for HarmonyOS application development. '
      'Built on the TypeScript ecosystem, it keeps the familiar TS style while extending '
      'the language with stronger static checks for stability and performance.',
    ),
    CourseParagraph(
      'Since API version 10, ArkTS further strengthens static check and analysis. '
      'Understanding these pillars early will make every later lesson clearer.',
    ),
    CourseHeading('Four pillars of ArkTS'),
    CourseBulletList([
      'Forced static types — every value has a definite compile-time type; no any.',
      'Forbidden runtime object-layout changes — properties cannot be added/removed dynamically.',
      'Restricted operator semantics — e.g. unary + only on numbers.',
      'No structural typing — types match by declared identity (classes/interfaces), not by shape alone.',
    ]),
    CourseCallout(
      title: 'How this course maps to official docs',
      text:
          'Lessons follow Huawei’s Learning ArkTS pathway: Introduction → Coding Style → '
          'Migration Background → TypeScript to ArkTS Cookbook → Adaptation Cases → '
          'High-Performance Programming. Each lesson links to the matching official page.',
    ),
    CourseHeading('Interop with TS/JS'),
    CourseParagraph(
      'ArkTS remains compatible with the TypeScript and JavaScript ecosystem. You can write '
      'new ArkTS code or reuse existing TS/JS where the runtime allows — covered later in '
      'Migration Background.',
    ),
    CourseCodeSnippet(
      title: 'hello',
      code: '''$printDecl

print("Hello ArkTS")
''',
      caption: 'In this course playground, print() is your console.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'gs-e1',
      title: 'First console line',
      explanation: 'Print a greeting — the foundation of every practice challenge.',
      code: '''$printDecl

print("HarmonyOS")
''',
    ),
    CourseExample(
      id: 'gs-e2',
      title: 'Typed constant',
      explanation: 'Prefer const when a binding never changes after initialization.',
      code: '''$printDecl

const language: string = "ArkTS"
print(language)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-gs-q1',
      number: 1,
      title: 'Say Hello ArkTS',
      prompt: 'Print exactly Hello ArkTS on one line.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

// TODO
''',
      expectedOutput: 'Hello ArkTS',
      hint: 'print("Hello ArkTS")',
    ),
    ArkTsQuizChallenge(
      id: 'c-gs-q2',
      number: 2,
      title: 'Static typing mindset',
      prompt:
          'Declare const pillar: string = "static types" and print it. '
          'Expected: static types',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

// TODO
''',
      expectedOutput: 'static types',
      hint: 'Use an explicit string type annotation.',
    ),
  ],
);

const CourseLesson lesson02BasicsTypes = CourseLesson(
  id: 'basics-types',
  number: 2,
  title: 'Basics: Declarations & Types',
  summary:
      'let/const, number, string, boolean, arrays, enums, unions, and type aliases from Introduction to ArkTS.',
  durationLabel: '25 min',
  sourceUrl: '$huaweiBase/introduction-to-arkts',
  sourceLabel: 'Official: Introduction to ArkTS — The Basics',
  content: [
    CourseHeading('Declarations'),
    CourseParagraph(
      'let introduces a variable that may be reassigned. const introduces a read-only '
      'constant that can be assigned only once. Prefer const by default.',
    ),
    CourseCodeSnippet(
      title: 'let-const',
      code: '''let hi: string = 'hello'
hi = 'hello, world'

const greeting: string = 'hello'
''',
    ),
    CourseParagraph(
      'If an initializer is present, ArkTS can often infer the type. Both of these are string:',
    ),
    CourseCodeSnippet(
      title: 'inference',
      code: '''let hi1: string = 'hello'
let hi2 = 'hello, world'
''',
    ),
    CourseHeading('Core types'),
    CourseBulletList([
      'number — integers and floats (decimal, hex 0x, octal 0o, binary 0b)',
      'bigint — for integers beyond safe number precision',
      'boolean — true / false',
      'string — quotes or template literals with backticks and \${expression}',
      'void — function returns nothing',
      'Object / object — base reference types',
      'T[] — arrays of element type T',
      'enum — named value sets',
      'union — T | U combinations',
      'type aliases — name complex types',
    ]),
    CourseCallout(
      title: 'Basic vs reference',
      text:
          'number and string behave as basic values. Objects, arrays, and functions are '
          'reference types — assigning them copies the reference, not a deep clone.',
    ),
    CourseHeading('Enums & unions'),
    CourseCodeSnippet(
      title: 'enum-union',
      code: '''enum ColorSet { Red, Green, Blue }
let c: ColorSet = ColorSet.Red

type Id = number | string
let id: Id = 42
id = 'user-1'
''',
    ),
  ],
  examples: [
    CourseExample(
      id: 'bt-e1',
      title: 'Numbers and strings',
      explanation: 'Mix typed locals and print results.',
      code: '''$printDecl

const answer: number = 42
const label: string = "n=" + answer
print(label)
''',
    ),
    CourseExample(
      id: 'bt-e2',
      title: 'Array access',
      explanation: 'Declare a typed array and print an element.',
      code: '''$printDecl

const names: string[] = ["Alice", "Bob", "Carol"]
print(names[1])
''',
    ),
    CourseExample(
      id: 'bt-e3',
      title: 'Enum values',
      explanation: 'Print an enum member as a number (default auto-increment).',
      code: '''$printDecl

enum Level { Low, Mid, High }
print(Level.Mid)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-bt-q1',
      number: 1,
      title: 'Const string',
      prompt: 'Create const app: string = "HarmonyOS" and print it.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

// TODO
''',
      expectedOutput: 'HarmonyOS',
      hint: 'const app: string = "HarmonyOS"; print(app)',
    ),
    ArkTsQuizChallenge(
      id: 'c-bt-q2',
      number: 2,
      title: 'Array length',
      prompt: 'Given const nums: number[] = [10, 20, 30], print nums.length.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

const nums: number[] = [10, 20, 30]
// TODO
''',
      expectedOutput: '3',
      hint: 'print(nums.length)',
    ),
    ArkTsQuizChallenge(
      id: 'c-bt-q3',
      number: 3,
      title: 'Template-style join',
      prompt:
          'const a = "Ark"; const b = "TS"; print a + b. Expected: ArkTS',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

const a: string = "Ark"
const b: string = "TS"
// TODO
''',
      expectedOutput: 'ArkTS',
      hint: 'print(a + b)',
    ),
  ],
);

const CourseLesson lesson03OperatorsStatements = CourseLesson(
  id: 'operators-statements',
  number: 3,
  title: 'Basics: Operators & Statements',
  summary:
      'Assignment, comparison, arithmetic, control flow, loops, and try/catch from Introduction to ArkTS.',
  durationLabel: '22 min',
  sourceUrl: '$huaweiBase/introduction-to-arkts',
  sourceLabel: 'Official: Introduction to ArkTS — Operators & Statements',
  content: [
    CourseHeading('Comparison: === vs =='),
    CourseParagraph(
      '=== compares values and types. == compares values with coercion. Prefer === in ArkTS code.',
    ),
    CourseHeading('Control flow'),
    CourseBulletList([
      'if / else if / else',
      'switch with case / default',
      'for, while, do-while',
      'break / continue',
      'try / catch / finally',
    ]),
    CourseCodeSnippet(
      title: 'for-loop',
      code: '''for (let i: number = 1; i <= 3; i++) {
  print(i)
}
''',
    ),
    CourseCallout(
      title: 'throw rules (preview)',
      text:
          'ArkTS only allows throwing Error (or subclasses). Throwing a string/number is forbidden — '
          'covered in the migration lessons.',
    ),
    CourseHeading('for-of for arrays'),
    CourseParagraph(
      'Iterate array elements with for...of. Do not use for...in over object keys in ArkTS '
      '(forbidden — object layout is fixed).',
    ),
  ],
  examples: [
    CourseExample(
      id: 'os-e1',
      title: 'if / else',
      explanation: 'Branch on a score threshold.',
      code: '''$printDecl

const score: number = 85
if (score >= 60) {
  print("Pass")
} else {
  print("Fail")
}
''',
    ),
    CourseExample(
      id: 'os-e2',
      title: 'Accumulate in a loop',
      explanation: 'Sum 1..4 then print once.',
      code: '''$printDecl

let sum: number = 0
for (let i: number = 1; i <= 4; i++) {
  sum += i
}
print(sum)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-os-q1',
      number: 1,
      title: 'Count 1 to 5',
      prompt: 'Print 1 through 5, each on its own line.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

// TODO
''',
      expectedOutput: '1\n2\n3\n4\n5',
      hint: 'for (let i = 1; i <= 5; i++) print(i)',
    ),
    ArkTsQuizChallenge(
      id: 'c-os-q2',
      number: 2,
      title: 'Even check',
      prompt:
          'If n = 8 is even print even, else odd. Expected: even',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

const n: number = 8
// TODO
''',
      expectedOutput: 'even',
      hint: 'Use n % 2 === 0',
    ),
    ArkTsQuizChallenge(
      id: 'c-os-q3',
      number: 3,
      title: 'Sum to 10',
      prompt: 'Print the sum of 1..10. Expected: 55',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

// TODO
''',
      expectedOutput: '55',
      hint: 'Accumulate in a for loop, print once.',
    ),
  ],
);

const CourseLesson lesson04Functions = CourseLesson(
  id: 'functions',
  number: 4,
  title: 'Functions',
  summary:
      'Parameters, optional/default/rest args, return types, arrow functions, and closures.',
  durationLabel: '24 min',
  sourceUrl: '$huaweiBase/introduction-to-arkts',
  sourceLabel: 'Official: Introduction to ArkTS — Function',
  content: [
    CourseHeading('Function declaration'),
    CourseParagraph(
      'Every parameter needs a type annotation. Specify the return type when it is not obvious.',
    ),
    CourseCodeSnippet(
      title: 'add-strings',
      code: '''function add(x: string, y: string): string {
  return x + ' ' + y
}
''',
    ),
    CourseHeading('Optional, default, rest'),
    CourseBulletList([
      'Optional: name?: Type',
      'Default: coeff: number = 2',
      'Rest: ...numbers: number[] as the last parameter',
    ]),
    CourseCodeSnippet(
      title: 'defaults-rest',
      code: '''function multiply(n: number, coeff: number = 2): number {
  return n * coeff
}

function sum(...numbers: number[]): number {
  let res = 0
  for (let i = 0; i < numbers.length; i++) {
    res += numbers[i]
  }
  return res
}
''',
    ),
    CourseHeading('Arrow functions'),
    CourseParagraph(
      'ArkTS prefers arrow functions over classic function expressions. Nested named function '
      'declarations inside functions are also restricted — use lambdas instead.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'fn-e1',
      title: 'Typed return',
      explanation: 'Implement and call a numeric helper.',
      code: '''$printDecl

function square(n: number): number {
  return n * n
}
print(square(6))
''',
    ),
    CourseExample(
      id: 'fn-e2',
      title: 'Default parameter',
      explanation: 'Call with one argument; default applies.',
      code: '''$printDecl

function multiply(n: number, coeff: number = 2): number {
  return n * coeff
}
print(multiply(5))
''',
    ),
    CourseExample(
      id: 'fn-e3',
      title: 'Arrow function',
      explanation: 'Assign an arrow function to a typed variable.',
      code: '''$printDecl

const double = (n: number): number => n * 2
print(double(9))
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-fn-q1',
      number: 1,
      title: 'add()',
      prompt: 'Implement add(a,b) and print add(7,5). Expected: 12',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

function add(a: number, b: number): number {
  // TODO
  return 0
}
print(add(7, 5))
''',
      expectedOutput: '12',
      hint: 'return a + b',
    ),
    ArkTsQuizChallenge(
      id: 'c-fn-q2',
      number: 2,
      title: 'Default multiplier',
      prompt:
          'Implement scale(n, factor = 3) returning n * factor. Print scale(4). Expected: 12',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

function scale(n: number, factor: number = 3): number {
  // TODO
  return 0
}
print(scale(4))
''',
      expectedOutput: '12',
      hint: 'return n * factor',
    ),
    ArkTsQuizChallenge(
      id: 'c-fn-q3',
      number: 3,
      title: 'fullName',
      prompt:
          'fullName(first, last) returns first + " " + last. '
          'Print fullName("Ada", "Lovelace").',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

function fullName(first: string, last: string): string {
  // TODO
  return ""
}
print(fullName("Ada", "Lovelace"))
''',
      expectedOutput: 'Ada Lovelace',
      hint: 'return first + " " + last',
    ),
  ],
);

const CourseLesson lesson05Classes = CourseLesson(
  id: 'classes',
  number: 5,
  title: 'Classes & Object Literals',
  summary:
      'Fields, methods, constructors, visibility, static members, and typed object literals.',
  durationLabel: '26 min',
  sourceUrl: '$huaweiBase/introduction-to-arkts',
  sourceLabel: 'Official: Introduction to ArkTS — Class',
  content: [
    CourseHeading('Class anatomy'),
    CourseParagraph(
      'A class introduces a type with fields, methods, and constructors. Fields should be '
      'initialized at declaration or in the constructor (strict initialization).',
    ),
    CourseCodeSnippet(
      title: 'person',
      code: '''class Person {
  public name: string = ''
  public surname: string = ''
  constructor(n: string, sn: string) {
    this.name = n
    this.surname = sn
  }
  fullName(): string {
    return this.name + ' ' + this.surname
  }
}
''',
    ),
    CourseHeading('Object literals need an explicit type'),
    CourseParagraph(
      'You can create instances with new or with an object literal that matches a declared '
      'class/interface. Untyped object literals are a major migration pitfall.',
    ),
    CourseCodeSnippet(
      title: 'point-literal',
      code: '''class Point {
  public x: number = 0
  public y: number = 0
}
let p: Point = { x: 42, y: 42 }
''',
    ),
    CourseHeading('Visibility'),
    CourseBulletList([
      'public — accessible everywhere (often explicit in style guides)',
      'private — only inside the class',
      'protected — class + subclasses',
      'Do not use #private fields — use the private keyword',
    ]),
  ],
  examples: [
    CourseExample(
      id: 'cl-e1',
      title: 'Method call',
      explanation: 'Create a person and print fullName().',
      code: '''$printDecl

class Person {
  name: string = ""
  surname: string = ""
  constructor(n: string, sn: string) {
    this.name = n
    this.surname = sn
  }
  fullName(): string {
    return this.name + " " + this.surname
  }
}
const p = new Person("John", "Smith")
print(p.fullName())
''',
    ),
    CourseExample(
      id: 'cl-e2',
      title: 'Counter',
      explanation: 'Mutate instance state through a method.',
      code: '''$printDecl

class Counter {
  value: number = 0
  add(n: number): void {
    this.value = this.value + n
  }
}
const c = new Counter()
c.add(5)
c.add(7)
print(c.value)
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'c-cl-q1',
      number: 1,
      title: 'Object field',
      prompt:
          'Create city with name "Istanbul" typed via a class or interface-like object, '
          'print city.name.',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$printDecl

class City {
  name: string = ""
}
// TODO: create instance and print name
''',
      expectedOutput: 'Istanbul',
      hint: 'const city: City = { name: "Istanbul" }; print(city.name)',
    ),
    ArkTsQuizChallenge(
      id: 'c-cl-q2',
      number: 2,
      title: 'Counter class',
      prompt:
          'Complete add(n). Call add(5) then add(7), print value. Expected: 12',
      difficulty: QuizDifficulty.medium,
      starterCode: '''$printDecl

class Counter {
  value: number = 0
  add(n: number): void {
    // TODO
  }
}
const c = new Counter()
c.add(5)
c.add(7)
print(c.value)
''',
      expectedOutput: '12',
      hint: 'this.value = this.value + n',
    ),
  ],
);
