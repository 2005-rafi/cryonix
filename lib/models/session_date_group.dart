import 'session_summary.dart';

class SessionDateGroup {
  final DateTime date;
  final List<SessionSummary> sessions;

  const SessionDateGroup({required this.date, required this.sessions});

  SessionDateGroup copyWith({DateTime? date, List<SessionSummary>? sessions}) =>
      SessionDateGroup(
        date: date ?? this.date,
        sessions: sessions ?? this.sessions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionDateGroup && date == other.date && sessions == other.sessions;

  @override
  int get hashCode => Object.hash(date, sessions);
}
