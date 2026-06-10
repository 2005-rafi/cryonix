import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// Reset confirmation with typed "RESET" and animated confirm button.
Future<bool?> showResetDataDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _ResetDataDialog(),
  );
}

class _ResetDataDialog extends StatefulWidget {
  const _ResetDataDialog();

  @override
  State<_ResetDataDialog> createState() => _ResetDataDialogState();
}

class _ResetDataDialogState extends State<_ResetDataDialog> {
  final _controller = TextEditingController();
  bool get _isMatch => _controller.text == 'RESET';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Reset Local Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will delete all local data on this device. '
            'Your data in the cloud will not be affected.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Type RESET to confirm:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'RESET',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        AnimatedContainer(
          duration: kAnimNormal,
          curve: kCurveStandard,
          child: FilledButton(
            onPressed: _isMatch ? () => Navigator.of(context).pop(true) : null,
            style: FilledButton.styleFrom(
              backgroundColor: _isMatch ? cs.error : cs.surfaceContainerHighest,
              foregroundColor: _isMatch ? cs.onError : cs.onSurfaceVariant,
              disabledBackgroundColor: cs.surfaceContainerHighest,
              disabledForegroundColor: cs.onSurfaceVariant,
            ),
            child: const Text('Confirm Reset'),
          ),
        ),
      ],
    );
  }
}
