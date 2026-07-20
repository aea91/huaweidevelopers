import '../models/arkts_quiz_challenge.dart';

const _printDecl = 'declare function print(arg: any): any';

const List<ArkTsQuizChallenge> arkTsQuizChallenges = [
  ArkTsQuizChallenge(
    id: 'q1',
    number: 1,
    title: 'Hello ArkTS',
    prompt:
        'Print exactly the text Hello ArkTS on a single line using print().',
    difficulty: QuizDifficulty.easy,
    starterCode: '''$_printDecl

// TODO: print Hello ArkTS
''',
    expectedOutput: 'Hello ArkTS',
    hint: 'Use print("Hello ArkTS").',
  ),
  ArkTsQuizChallenge(
    id: 'q2',
    number: 2,
    title: 'Add Two Numbers',
    prompt:
        'Create a function add(a: number, b: number): number that returns the sum. '
        'Then print add(7, 5). The console must show only 12.',
    difficulty: QuizDifficulty.easy,
    starterCode: '''$_printDecl

function add(a: number, b: number): number {
  // TODO: return the sum
  return 0
}

print(add(7, 5))
''',
    expectedOutput: '12',
    hint: 'Return a + b.',
  ),
  ArkTsQuizChallenge(
    id: 'q3',
    number: 3,
    title: 'Count to Five',
    prompt:
        'Print the numbers 1 through 5, each on its own line, in ascending order.',
    difficulty: QuizDifficulty.easy,
    starterCode: '''$_printDecl

// TODO: print 1 to 5, one per line
''',
    expectedOutput: '1\n2\n3\n4\n5',
    hint: 'Use a for loop from 1 to 5 and call print(i) each time.',
  ),
  ArkTsQuizChallenge(
    id: 'q4',
    number: 4,
    title: 'Factorial',
    prompt:
        'Implement factorial(n: number): number for n >= 0. '
        'Print factorial(6). The console must show only 720.',
    difficulty: QuizDifficulty.medium,
    starterCode: '''$_printDecl

function factorial(n: number): number {
  // TODO: compute n!
  return 0
}

print(factorial(6))
''',
    expectedOutput: '720',
    hint: 'Multiply from 1 to n. factorial(0) is 1.',
  ),
  ArkTsQuizChallenge(
    id: 'q5',
    number: 5,
    title: 'Reverse a String',
    prompt:
        'Implement reverseText(text: string): string that returns the characters in reverse order. '
        'Print reverseText("ArkTS"). The console must show only STKrA.',
    difficulty: QuizDifficulty.medium,
    starterCode: '''$_printDecl

function reverseText(text: string): string {
  // TODO: reverse the characters
  return ""
}

print(reverseText("ArkTS"))
''',
    expectedOutput: 'STKrA',
    hint: 'Walk the string from the last index down to 0.',
  ),
  ArkTsQuizChallenge(
    id: 'q6',
    number: 6,
    title: 'Even Numbers Only',
    prompt:
        'Given the array [1, 2, 3, 4, 5, 6, 7, 8], print only the even numbers, '
        'each on its own line, in the same order.',
    difficulty: QuizDifficulty.medium,
    starterCode: '''$_printDecl

let numbers: number[] = [1, 2, 3, 4, 5, 6, 7, 8]

// TODO: print only even numbers, one per line
''',
    expectedOutput: '2\n4\n6\n8',
    hint: 'A number is even when value % 2 === 0.',
  ),
  ArkTsQuizChallenge(
    id: 'q7',
    number: 7,
    title: 'Maximum Value',
    prompt:
        'Implement maxValue(values: number[]): number that returns the largest number. '
        'Print maxValue([4, 17, 9, 2, 13]). The console must show only 17.',
    difficulty: QuizDifficulty.medium,
    starterCode: '''$_printDecl

function maxValue(values: number[]): number {
  // TODO: find the largest value
  return 0
}

print(maxValue([4, 17, 9, 2, 13]))
''',
    expectedOutput: '17',
    hint: 'Track a running max while iterating the array.',
  ),
  ArkTsQuizChallenge(
    id: 'q8',
    number: 8,
    title: 'FizzBuzz',
    prompt:
        'Print numbers from 1 to 15. For multiples of 3 print Fizz, for multiples of 5 print Buzz, '
        'and for multiples of both print FizzBuzz. Otherwise print the number. One result per line.',
    difficulty: QuizDifficulty.hard,
    starterCode: '''$_printDecl

// TODO: FizzBuzz from 1 to 15
''',
    expectedOutput:
        '1\n2\nFizz\n4\nBuzz\nFizz\n7\n8\nFizz\nBuzz\n11\nFizz\n13\n14\nFizzBuzz',
    hint: 'Check the multiple of 15 case before the separate 3 and 5 cases.',
  ),
  ArkTsQuizChallenge(
    id: 'q9',
    number: 9,
    title: 'Palindrome Check',
    prompt:
        'Implement isPalindrome(text: string): boolean that ignores case. '
        'Print isPalindrome("Level") then isPalindrome("ArkTS"), each on its own line. '
        'Expected console: true then false.',
    difficulty: QuizDifficulty.hard,
    starterCode: '''$_printDecl

function isPalindrome(text: string): boolean {
  // TODO: compare reversed lowercase text
  return false
}

print(isPalindrome("Level"))
print(isPalindrome("ArkTS"))
''',
    expectedOutput: 'true\nfalse',
    hint: 'Normalize with toLowerCase(), then compare the reversed string.',
  ),
  ArkTsQuizChallenge(
    id: 'q10',
    number: 10,
    title: 'Word Frequency',
    prompt:
        'Count how many times the word ark appears in the sentence '
        '"ark ui arkts ark compiler ark" (case-insensitive, space-separated words). '
        'Print only the count as a number.',
    difficulty: QuizDifficulty.hard,
    starterCode: '''$_printDecl

let sentence: string = "ark ui arkts ark compiler ark"

// TODO: count the word "ark" (case-insensitive) and print the count
''',
    expectedOutput: '3',
    hint:
        'Split by spaces, lower-case each word, and count exact matches for "ark".',
  ),
];
