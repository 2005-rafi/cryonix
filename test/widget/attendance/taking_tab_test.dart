import 'package:cryonix/core/providers.dart';
import 'package:cryonix/features/attendance/providers.dart';
import 'package:cryonix/features/attendance/widgets/taking_tab.dart';

import 'package:cryonix/models/session_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/builders/test_data_builder.dart';
import '../../helpers/test_database.dart';

void main() {
  testWidgets('TakingTab renders session setup in idle state', (tester) async {
    final db = createTestDatabase();
    addTearDown(db.close);

    SharedPreferences.setMockInitialValues({'current_uid': 'teacher-1'});
    final prefs = await SharedPreferences.getInstance();

    const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    await db.insertClassroom(buildTestClassroom(id: classroomId, userId: 'teacher-1'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          sessionsWithSummaryProvider.overrideWith(
            (ref, _) => Stream.value(<SessionSummary>[]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TakingTab(
              classroomId: classroomId,
              onSaveSuccess: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Session Setup'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
