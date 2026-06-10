import 'package:cryonix/core/providers.dart';
import 'package:cryonix/features/attendance/widgets/history_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

void main() {
  testWidgets('HistoryTab shows empty state', (tester) async {
    final db = createTestDatabase();
    addTearDown(db.close);

    SharedPreferences.setMockInitialValues({'current_uid': 'teacher-1'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryTab(
              classroomId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No sessions yet'), findsOneWidget);
  });
}
