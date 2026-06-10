import 'package:cryonix/core/providers.dart';
import 'package:cryonix/features/auth/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository/attendance_repository.dart';
import '../classroom/repository/student_repository.dart';
import '../classroom/providers.dart';
import '../../../core/constants.dart';
import '../../../models/session_summary.dart';
import '../../../models/record_with_student.dart';

import '../../../models/session_date_group.dart';
import '../../../database/app_database.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final studentRepo = ref.watch(studentRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  return AttendanceRepository(db, studentRepo, auth: auth);
});

final sessionsWithSummaryProvider = StreamProvider.family<List<SessionSummary>, String>((ref, classroomId) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchSessionsWithSummary(classroomId);
});

final sessionsGroupedByDateProvider = StreamProvider.family<List<SessionDateGroup>, String>((ref, classroomId) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchSessionsGroupedByDate(classroomId);
});

enum SessionState { idle, active, saving, saved, error, duplicateSessionError }

class AttendanceSessionState {
  final SessionState state;
  final String? sessionId;
  final Map<String, AttendanceStatus> statusMap;
  final String? errorMessage;
  final String? duplicateSessionId;
  final String? label;

  AttendanceSessionState({
    required this.state,
    this.sessionId,
    required this.statusMap,
    this.errorMessage,
    this.duplicateSessionId,
    this.label,
  });

  AttendanceSessionState copyWith({
    SessionState? state,
    String? sessionId,
    Map<String, AttendanceStatus>? statusMap,
    String? errorMessage,
    String? duplicateSessionId,
    String? label,
  }) {
    return AttendanceSessionState(
      state: state ?? this.state,
      sessionId: sessionId ?? this.sessionId,
      statusMap: statusMap ?? this.statusMap,
      errorMessage: errorMessage ?? this.errorMessage,
      duplicateSessionId: duplicateSessionId ?? this.duplicateSessionId,
      label: label ?? this.label,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceSessionState> {
  final AttendanceRepository _repository;
  final StudentRepository _studentRepository;
  final String classroomId;

  AttendanceNotifier(this._repository, this._studentRepository, this.classroomId)
      : super(AttendanceSessionState(state: SessionState.idle, statusMap: {}));

  Future<void> initSession(DateTime date, {String label = 'Morning'}) async {
    state = state.copyWith(state: SessionState.saving, label: label);

    final result = await _repository.createSession(classroomId, date, label: label);
    
    if (result.isFailure) {
      final error = result.errorOrNull;
      if (error is DuplicateSessionException) {
        state = state.copyWith(
          state: SessionState.duplicateSessionError,
          duplicateSessionId: error.sessionId,
        );
      } else {
        state = state.copyWith(
          state: SessionState.error,
          errorMessage: error.toString(),
        );
      }
      return;
    }

    final sessionId = result.dataOrNull!;
    final students = await _studentRepository.getStudentsByClassroom(classroomId);
    final map = <String, AttendanceStatus>{};
    for (final s in students) {
      map[s.id] = AttendanceStatus.present;
    }

    state = state.copyWith(
      state: SessionState.active,
      sessionId: sessionId,
      statusMap: map,
      duplicateSessionId: null,
    );
  }

  void setStatus(String studentId, AttendanceStatus status) {
    if (state.state != SessionState.active) return;
    
    final newMap = Map<String, AttendanceStatus>.from(state.statusMap);
    newMap[studentId] = status;
    state = state.copyWith(statusMap: newMap);
  }

  Future<void> saveSession() async {
    if (state.state != SessionState.active || state.sessionId == null) return;
    
    state = state.copyWith(state: SessionState.saving);

    try {
      await _repository.saveSessionWithRecords(
        state.sessionId!,
        classroomId,
        state.statusMap,
      );
      
      state = state.copyWith(state: SessionState.saved);
    } catch (e) {
      state = state.copyWith(
        state: SessionState.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  void resetIdle() {
    state = AttendanceSessionState(state: SessionState.idle, statusMap: {});
  }
}

final attendanceNotifierProvider = StateNotifierProvider.autoDispose.family<AttendanceNotifier, AttendanceSessionState, String>((ref, classroomId) {
  final repo = ref.watch(attendanceRepositoryProvider);
  final studentRepo = ref.watch(studentRepositoryProvider);
  return AttendanceNotifier(repo, studentRepo, classroomId);
});

class EditSessionNotifier extends StateNotifier<AttendanceSessionState> {
  final AttendanceRepository _repository;
  final String classroomId;
  final String sessionId;

  EditSessionNotifier(this._repository, this.classroomId, this.sessionId)
      : super(AttendanceSessionState(state: SessionState.idle, statusMap: {}));

  Future<void> loadSession() async {
    state = state.copyWith(state: SessionState.saving); // Use saving as loading state here
    try {
      final records = await _repository.getRecordsForSession(sessionId);
      final map = <String, AttendanceStatus>{};
      for (final r in records) {
        map[r.studentId] = r.status;
      }
      
      final session = await _repository.getSessionById(sessionId);

      state = state.copyWith(
        state: SessionState.active,
        sessionId: sessionId,
        statusMap: map,
        label: session?.label,
      );
    } catch (e) {
      state = state.copyWith(
        state: SessionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setStatus(String studentId, AttendanceStatus status) {
    if (state.state != SessionState.active) return;
    
    final newMap = Map<String, AttendanceStatus>.from(state.statusMap);
    newMap[studentId] = status;
    state = state.copyWith(statusMap: newMap);
  }

  Future<void> saveChanges() async {
    if (state.state != SessionState.active) return;
    
    state = state.copyWith(state: SessionState.saving);

    try {
      await _repository.updateSessionRecords(
        sessionId,
        classroomId,
        state.statusMap,
      );
      
      state = state.copyWith(state: SessionState.saved);
    } catch (e) {
      state = state.copyWith(
        state: SessionState.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// Provider expects a tuple or class. Let's use a record: ({String classroomId, String sessionId})
typedef EditSessionArgs = ({String classroomId, String sessionId});

final editSessionNotifierProvider = StateNotifierProvider.autoDispose.family<EditSessionNotifier, AttendanceSessionState, EditSessionArgs>((ref, args) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return EditSessionNotifier(repo, args.classroomId, args.sessionId);
});

final sessionRecordsProvider = FutureProvider.family<List<RecordWithStudent>, String>((ref, sessionId) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getRecordsForSession(sessionId);
});

final sessionByIdProvider =
    FutureProvider.family<AttendanceSession?, String>((ref, sessionId) {
  return ref.watch(attendanceRepositoryProvider).getSessionById(sessionId);
});

final classroomLastSessionDateProvider =
    FutureProvider.family<DateTime?, String>((ref, classroomId) {
  return ref
      .watch(attendanceRepositoryProvider)
      .getLastSessionDateForClassroom(classroomId);
});

// Returns a callable that deletes a session
final deleteSessionProvider = Provider<Future<void> Function(String sessionId, String classroomId)>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return (sessionId, classroomId) => repo.deleteSession(sessionId, classroomId);
});

final deletedSessionsProvider = StreamProvider.family<List<SessionSummary>, String>((ref, classroomId) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchDeletedSessions(classroomId);
});

final restoreSessionProvider = Provider<Future<void> Function(String sessionId, String classroomId)>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return (sessionId, classroomId) => repo.restoreSession(sessionId, classroomId);
});
