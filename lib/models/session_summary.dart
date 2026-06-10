class SessionSummary {
  final String sessionId;
  final DateTime date;
  final String label;
  final int presentCount;
  final int absentCount;
  final int onDutyCount;
  final String syncStatus;

  const SessionSummary({
    required this.sessionId,
    required this.date,
    required this.label,
    required this.presentCount,
    required this.absentCount,
    required this.onDutyCount,
    required this.syncStatus,
  });

  SessionSummary copyWith({
    String? sessionId,
    DateTime? date,
    String? label,
    int? presentCount,
    int? absentCount,
    int? onDutyCount,
    String? syncStatus,
  }) =>
      SessionSummary(
        sessionId: sessionId ?? this.sessionId,
        date: date ?? this.date,
        label: label ?? this.label,
        presentCount: presentCount ?? this.presentCount,
        absentCount: absentCount ?? this.absentCount,
        onDutyCount: onDutyCount ?? this.onDutyCount,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionSummary &&
          sessionId == other.sessionId &&
          date == other.date &&
          label == other.label &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          onDutyCount == other.onDutyCount &&
          syncStatus == other.syncStatus;

  @override
  int get hashCode => Object.hash(
        sessionId,
        date,
        label,
        presentCount,
        absentCount,
        onDutyCount,
        syncStatus,
      );
}
