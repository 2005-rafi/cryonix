import 'package:cryonix/shared/confirm_dialog.dart';
import 'package:cryonix/shared/cryonix_scaffold.dart';
import 'package:cryonix/shared/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CryonixScaffold default header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CryonixScaffold(
          appBar: AppBar(title: const Text('Title')),
          body: const Text('Body'),
        ),
      ),
    );
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('CryonixScaffold custom header builder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CryonixScaffold(
          customHeaderBuilder: (_) => const Text('Custom Header'),
          body: const Text('Body'),
        ),
      ),
    );
    expect(find.text('Custom Header'), findsOneWidget);
  });

  testWidgets('PrimaryButton trailing icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Save',
            trailingIcon: const Icon(Icons.save, key: Key('save_icon')),
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('save_icon')), findsOneWidget);
  });

  testWidgets('ConfirmDialog additional content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showConfirmDialog(
                context,
                title: 'Delete',
                message: 'Sure?',
                additionalContent: const Text('Extra warning'),
              ),
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Extra warning'), findsOneWidget);
  });
}
