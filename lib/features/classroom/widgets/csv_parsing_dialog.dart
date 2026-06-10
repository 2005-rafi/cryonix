import 'package:flutter/material.dart';

class CsvParsingDialog extends StatelessWidget {
  const CsvParsingDialog({super.key, required this.rowIndex});

  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Parsing CSV...'),
          const SizedBox(height: 8),
          Text(
            rowIndex > 0 ? 'Reading row $rowIndex...' : 'Reading file...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
