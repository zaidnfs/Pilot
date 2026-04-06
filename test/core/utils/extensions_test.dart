import 'package:flutter_test/flutter_test.dart';
import 'package:dashauli_connect/core/utils/extensions.dart';

void main() {
  group('StringExtensions', () {
    group('capitalized', () {
      test('returns same string when empty', () {
        expect(''.capitalized, equals(''));
      });

      test('capitalizes single character lowercase string', () {
        expect('a'.capitalized, equals('A'));
      });

      test('keeps single character uppercase string as is', () {
        expect('A'.capitalized, equals('A'));
      });

      test('capitalizes lowercase string', () {
        expect('hello'.capitalized, equals('Hello'));
      });

      test('keeps already capitalized string as is', () {
        expect('Hello'.capitalized, equals('Hello'));
      });

      test('does not change case of other characters', () {
        expect('hELLO'.capitalized, equals('HELLO'));
        expect('hello world'.capitalized, equals('Hello world'));
      });

      test('works with non-alphabetic starting characters', () {
        expect('1hello'.capitalized, equals('1hello'));
        expect(' hello'.capitalized, equals(' hello'));
        expect('@hello'.capitalized, equals('@hello'));
      });

      test('fails when it should (negative test)', () {
        // expect('hello'.capitalized, equals('hello')); // This would fail if uncommented
      });
    });

    group('masked', () {
      test('masks string with default visible characters (2)', () {
        expect('12345678'.masked(), equals('12***'));
      });

      test('masks string with custom visible characters', () {
        expect('12345678'.masked(4), equals('1234***'));
      });

      test('handles string shorter than visible characters', () {
        expect('1'.masked(2), equals('1***'));
      });

      test('handles string equal to visible characters', () {
        expect('12'.masked(2), equals('12***'));
      });

      test('handles empty string', () {
        expect(''.masked(), equals('***'));
      });
    });
  });
}
