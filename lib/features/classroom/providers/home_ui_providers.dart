import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../providers.dart';

/// True after the home classroom list has played its first stagger entrance.
final homeListStaggerPlayedProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Classroom IDs hidden during the delete-undo window (not yet removed from DB).
final pendingDeleteClassroomIdsProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

/// Classroom IDs that should play a solo entrance animation (newly created).
final newlyAnimatedClassroomIdsProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

/// Classroom IDs currently playing the collapse exit animation.
final collapsingClassroomIdsProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

/// Memoized provider for the classroom list after filtering out pending deletes.
final filteredClassroomsProvider = Provider.autoDispose.family<AsyncValue<List<Classroom>>, String>((ref, userId) {
  final classroomsAsync = ref.watch(classroomListProvider(userId));
  final pendingDeletes = ref.watch(pendingDeleteClassroomIdsProvider);

  return classroomsAsync.whenData((list) {
    return list.where((c) => !pendingDeletes.contains(c.id)).toList();
  });
});
