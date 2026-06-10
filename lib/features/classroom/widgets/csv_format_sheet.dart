import 'package:flutter/material.dart';

import '../../../shared/widgets/bottom_sheet_handle.dart';

void showCsvFormatSheet(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetDragHandle(),
            const SizedBox(height: 8),
            Text(
              'CSV format',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'One row per student, two columns: Roll Number and Name.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              border: TableBorder.all(color: cs.outlineVariant),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: cs.surfaceContainerHigh),
                  children: [
                    _cell('Roll', tt, cs, header: true),
                    _cell('Name', tt, cs, header: true),
                  ],
                ),
                TableRow(
                  children: [_cell('101', tt, cs), _cell('Aisha', tt, cs)],
                ),
                TableRow(
                  children: [_cell('102', tt, cs), _cell('Ravi', tt, cs)],
                ),
                TableRow(
                  children: [_cell('103', tt, cs), _cell('Mei Chan', tt, cs)],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _cell(String text, TextTheme tt, ColorScheme cs, {bool header = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(
      text,
      style: (header ? tt.labelMedium : tt.bodyMedium)?.copyWith(
        fontWeight: header ? FontWeight.w600 : null,
        color: header ? cs.onSurface : cs.onSurfaceVariant,
      ),
    ),
  );
}
