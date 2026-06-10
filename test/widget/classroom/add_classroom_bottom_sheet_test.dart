import 'package:cryonix/core/providers.dart';
import 'package:cryonix/features/classroom/widgets/add_classroom_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  testWidgets('renders form fields', (tester) async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(body: AddClassroomBottomSheet()),
        ),
      ),
    );
    expect(find.text('Classroom Name'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
  });

  testWidgets('empty name shows validation error', (tester) async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(body: AddClassroomBottomSheet()),
        ),
      ),
    );
    await tester.tap(find.text('Create Classroom'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
  });
}
