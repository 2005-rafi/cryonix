import 'package:flutter_test/flutter_test.dart';
import 'package:cryonix/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    group('truncate', () {
      test('short string is returned unchanged', () {
        const str = 'Hello';
        expect(str.truncate(10), 'Hello');
      });

      test('string exactly at max length is returned unchanged', () {
        const str = 'Hello';
        expect(str.truncate(5), 'Hello');
      });

      test('long string is truncated with suffix', () {
        const str = 'Advanced Mathematics Class';
        expect(str.truncate(20), 'Advanced Mathemat...');
      });

      test('custom suffix is used', () {
        const str = 'Hello World';
        expect(str.truncate(8, suffix: '…'), 'Hello W…');
      });

      test('empty string is returned unchanged', () {
        const str = '';
        expect(str.truncate(10), '');
      });
    });

    group('capitalized', () {
      test('capitalizes first letter', () {
        const str = 'hello world';
        expect(str.capitalized, 'Hello world');
      });

      test('already capitalized string is unchanged', () {
        const str = 'Hello';
        expect(str.capitalized, 'Hello');
      });

      test('single character is capitalized', () {
        const str = 'a';
        expect(str.capitalized, 'A');
      });

      test('empty string returns empty', () {
        const str = '';
        expect(str.capitalized, '');
      });
    });

    group('hasContent', () {
      test('non-empty string returns true', () {
        expect('hello'.hasContent, true);
      });

      test('whitespace-only string returns false', () {
        expect('   '.hasContent, false);
      });

      test('empty string returns false', () {
        expect(''.hasContent, false);
      });

      test('string with content after trimming returns true', () {
        expect('  hello  '.hasContent, true);
      });
    });
  });
}
