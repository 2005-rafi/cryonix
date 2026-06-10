import '../core/constants/domain_enums.dart';

class RecordWithStudent {
  final String recordId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final AttendanceStatus status;

  const RecordWithStudent({
    required this.recordId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.status,
  });

  RecordWithStudent copyWith({
    String? recordId,
    String? studentId,
    String? studentName,
    String? rollNumber,
    AttendanceStatus? status,
  }) =>
      RecordWithStudent(
        recordId: recordId ?? this.recordId,
        studentId: studentId ?? this.studentId,
        studentName: studentName ?? this.studentName,
        rollNumber: rollNumber ?? this.rollNumber,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordWithStudent &&
          recordId == other.recordId &&
          studentId == other.studentId &&
          studentName == other.studentName &&
          rollNumber == other.rollNumber &&
          status == other.status;

  @override
  int get hashCode =>
      Object.hash(recordId, studentId, studentName, rollNumber, status);
}
