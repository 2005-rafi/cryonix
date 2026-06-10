import 'package:cryonix/core/providers.dart';
import 'package:cryonix/features/auth/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository/classroom_repository.dart';
import 'repository/student_repository.dart';
import '../../database/app_database.dart';

final classroomRepositoryProvider = Provider<ClassroomRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authRepositoryProvider);
  return ClassroomRepository(db, auth: auth);
});

final classroomListProvider = StreamProvider.family<List<Classroom>, String>((ref, userId) {
  final repository = ref.watch(classroomRepositoryProvider);
  return repository.watchClassrooms(userId);
});

/// Live classroom row from the same stream as the home list (studentCount stays current).
final classroomProvider = StreamProvider.family<Classroom?, String>((ref, id) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(classroomRepositoryProvider).watchClassrooms(user.uid).map(
        (list) {
          for (final classroom in list) {
            if (classroom.id == id) return classroom;
          }
          return null;
        },
      );
});


final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StudentRepository(db);
});

final studentsByClassroomProvider = StreamProvider.family<List<Student>, String>((ref, classroomId) {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.watchStudentsByClassroom(classroomId);
});
