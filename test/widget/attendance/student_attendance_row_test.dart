import 'package:cryonix/core/constants/domain_enums.dart';
import 'package:cryonix/database/app_database.dart';
import 'package:cryonix/features/attendance/widgets/student_attendance_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final student = Student(
    id: 'student_1_12345678901234567890123456',
    classroomId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    rollNumber: '01',
    name: 'Priya',
    isActive: true,
    enrolledAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    deletedAt: null,
    syncVersion: 0,
  );

  testWidgets('renders name and roll without ProviderScope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentAttendanceRow(
            student: student,
            currentStatus: AttendanceStatus.present,
            onStatusChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Priya'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
  });

  testWidgets('callback fires on absent tap', (tester) async {
    AttendanceStatus? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentAttendanceRow(
            student: student,
            currentStatus: AttendanceStatus.present,
            onStatusChanged: (s) => tapped = s,
          ),
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(tapped, AttendanceStatus.absent);
  });
}
