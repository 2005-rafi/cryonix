import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True after history session list played its first stagger for a classroom.
final historyStaggerPlayedProvider =
    StateProvider.family<bool, String>((ref, classroomId) => false);
