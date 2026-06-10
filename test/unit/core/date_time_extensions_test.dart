import 'package:flutter_test/flutter_test.dart';
import 'package:cryonix/core/extensions/date_time_extensions.dart';

void main() {
  group('DateTimeExtensions', () {
    group('toMidnightUtc', () {
      test('strips time component and returns midnight UTC', () {
        final dt = DateTime(2026, 5, 17, 14, 30, 45);
        final result = dt.toMidnightUtc();
        expect(result.year, 2026);
        expect(result.month, 5);
        expect(result.day, 17);
        expect(result.hour, 0);
        expect(result.minute, 0);
        expect(result.second, 0);
        expect(result.isUtc, true);
      });

      test('epoch date normalizes correctly', () {
        final epoch = DateTime(1970, 1, 1, 23, 59, 59);
        final result = epoch.toMidnightUtc();
        expect(result, DateTime.utc(1970, 1, 1));
      });
    });

    group('isSameDayAs', () {
      test('same date with different times returns true', () {
        final a = DateTime(2026, 5, 17, 8, 0);
        final b = DateTime(2026, 5, 17, 22, 59);
        expect(a.isSameDayAs(b), true);
      });

      test('different dates returns false', () {
        final a = DateTime(2026, 5, 17);
        final b = DateTime(2026, 5, 18);
        expect(a.isSameDayAs(b), false);
      });

      test('different months returns false', () {
        final a = DateTime(2026, 4, 17);
        final b = DateTime(2026, 5, 17);
        expect(a.isSameDayAs(b), false);
      });
    });

    group('toDisplayDate', () {
      test('formats date correctly', () {
        final dt = DateTime(2026, 5, 17);
        expect(dt.toDisplayDate(), '17 May 2026');
      });

      test('formats January correctly', () {
        final dt = DateTime(2026, 1, 1);
        expect(dt.toDisplayDate(), '1 Jan 2026');
      });

      test('formats December correctly', () {
        final dt = DateTime(2026, 12, 31);
        expect(dt.toDisplayDate(), '31 Dec 2026');
      });
    });
  });
}
