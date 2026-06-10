import 'package:cryonix/services/csv_result.dart';
import 'package:cryonix/services/csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = CsvService();

  test('valid CSV returns CsvSuccess', () {
    const csv = 'roll,name\n01,Alice\n02,Bob\n03,Carol\n';
    final result = service.parseString(csv);
    expect(result, isA<CsvSuccess>());
    final success = result as CsvSuccess;
    expect(success.students.length, 3);
    expect(success.students.first.rollNumber, '01');
  });

  test('empty CSV returns CsvFailure', () {
    final result = service.parseString('');
    expect(result, isA<CsvFailure>());
  });

  test('missing fields returns CsvFailure with row', () {
    const csv = 'roll,name\n01\n';
    final result = service.parseString(csv);
    expect(result, isA<CsvFailure>());
    expect((result as CsvFailure).row, 2);
  });

  test('header row is skipped', () {
    const csv = 'roll,name\n01,One\n02,Two\n03,Three\n';
    final result = service.parseString(csv) as CsvSuccess;
    expect(result.students.length, 3);
  });

  test('duplicate roll numbers returns CsvFailure', () {
    const csv = 'roll,name\n01,Alice\n01,Bob\n';
    final result = service.parseString(csv);
    expect(result, isA<CsvFailure>());
  });
}
