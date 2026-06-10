import 'package:cryonix/core/constants/domain_enums.dart';
import 'package:cryonix/models/parsed_student.dart';
import 'package:cryonix/models/record_with_student.dart';
import 'package:cryonix/models/session_date_group.dart';
import 'package:cryonix/models/session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ParsedStudent equality and copyWith', () {
    const a = ParsedStudent(rollNumber: '01', name: 'Ali');
    const b = ParsedStudent(rollNumber: '01', name: 'Ali');
    expect(a, b);
    expect(a.copyWith(name: 'Bob').name, 'Bob');
  });

  test('SessionSummary equality', () {
    final date = DateTime(2026, 5, 1);
    final a = SessionSummary(
      sessionId: 's1',
      date: date,
      label: 'Morning',
      presentCount: 1,
      absentCount: 0,
      onDutyCount: 0,
      syncStatus: 'synced',
    );
    final b = a.copyWith(presentCount: 2);
    expect(b.presentCount, 2);
    expect(a, isNot(b));
  });

  test('RecordWithStudent holds status enum', () {
    const r = RecordWithStudent(
      recordId: 'r1',
      studentId: 'st1',
      studentName: 'Ali',
      rollNumber: '01',
      status: AttendanceStatus.present,
    );
    expect(r.status, AttendanceStatus.present);
  });

  test('SessionDateGroup basic holds sessions', () {
    final date = DateTime(2026, 5, 1);
    final summary = SessionSummary(
      sessionId: 's1',
      date: date,
      label: 'Full Day',
      presentCount: 5,
      absentCount: 0,
      onDutyCount: 0,
      syncStatus: 'pending',
    );
    final group = SessionDateGroup(date: date, sessions: [summary]);
    expect(group.sessions.length, 1);
  });
}
