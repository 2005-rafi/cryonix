/// Domain-level enums for attendance status and sync state.
/// These are used across multiple features (attendance, profile, shared).
library;

enum AttendanceStatus {
  present,
  absent,
  onDuty;

  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'onDuty':
        return AttendanceStatus.onDuty;
      default:
        return AttendanceStatus.present;
    }
  }

  String toDisplayLabel() {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onDuty:
        return 'On-Duty';
    }
  }

  String get shortName {
    switch (this) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.onDuty:
        return 'OD';
    }
  }
}

enum SyncStatus {
  unsynced,
  syncing,
  synced,
  failed;

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'unsynced':
        return SyncStatus.unsynced;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.unsynced;
    }
  }
}
