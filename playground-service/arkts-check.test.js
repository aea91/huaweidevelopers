'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { checkArkTs } = require('./arkts-check');

function codes(code) {
  return checkArkTs(code).diagnostics.map((d) => d.code);
}

test('accepts valid ArkTS', () => {
  const result = checkArkTs(`function fibonacci(count: number): number[] {
  let values: number[] = [0, 1]
  for (let index: number = 2; index < count; index++) {
    values.push(values[index - 1] + values[index - 2])
  }
  return values
}

class Point {
  x: number = 0
  y: number = 0
}

let point: Point = { x: 1, y: 2 }
print("ArkTS Playground", fibonacci(10), point.x)
console.log(null, undefined)
`);
  assert.deepEqual(result.diagnostics, []);
  assert.equal(result.ok, true);
});

test('accepts the legacy print declaration from course starter code', () => {
  const result = checkArkTs('declare function print(arg: any): any\n\nprint("Hello ArkTS")\n');
  assert.deepEqual(result.diagnostics, []);
});

test('reports type errors that es2abc alone lets through', () => {
  assert.deepEqual(codes('let n: number = "abc"\nprint(n)'), ['TS2322']);
  assert.deepEqual(codes('class A { private x: number = 1 }\nprint(new A().x)'), ['TS2341']);
  assert.deepEqual(codes('print(missing)'), ['TS2304']);
});

test('reports ArkTS linter rules', () => {
  assert.deepEqual(codes('let a: any = 1\nprint(a)'), ['arkts-no-any-unknown']);
  assert.deepEqual(codes('var v: number = 3\nprint(v)'), ['arkts-no-var']);
  assert.deepEqual(codes('let o = { a: 1 }\nprint(o.a)'), ['arkts-no-untyped-obj-literals']);
});

test('only blanks the exact legacy declaration', () => {
  assert.ok(codes('declare function print(arg: any): any\nlet a: any = 1').includes('arkts-no-any-unknown'));
  assert.ok(codes('declare function log(arg: any): any').includes('arkts-no-any-unknown'));
});

test('formats diagnostics with positions', () => {
  const result = checkArkTs('let x: number = 1\nlet a: any = x\nprint(a)');
  assert.equal(result.ok, false);
  assert.deepEqual(result.diagnostics[0], {
    severity: 'error',
    line: 2,
    column: 8,
    code: 'arkts-no-any-unknown',
    message: 'Use explicit types instead of "any", "unknown"',
  });
  assert.equal(
    result.output,
    'ERROR: main.ets:2:8 arkts-no-any-unknown: Use explicit types instead of "any", "unknown"',
  );
});

test('reports syntax errors', () => {
  const result = checkArkTs('let x = ;');
  assert.equal(result.ok, false);
  assert.ok(result.diagnostics.some((d) => d.code === 'TS1109'));
});
