import 'package:flutter/material.dart';

import '../../../theme/app_custom_colors.dart';

/// 60×4px stacked P/A/OD proportion bar for history session cards.
class SessionDistributionBar extends StatelessWidget {
  const SessionDistributionBar({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.onDutyCount,
    this.width,
    this.height = 4,
  });

  final int presentCount;
  final int absentCount;
  final int onDutyCount;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<AppCustomColors>();
    final cs = Theme.of(context).colorScheme;
    final total = presentCount + absentCount + onDutyCount;

    if (total == 0) {
      return SizedBox(
        width: width ?? 60,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      );
    }

    final presentColor = custom?.presentColor ?? cs.primary;
    final absentColor = custom?.absentColor ?? cs.error;
    final onDutyColor = custom?.onDutyColor ?? cs.tertiary;

    return SizedBox(
      width: width ?? 60,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Row(
          children: [
            if (presentCount > 0)
              Flexible(
                flex: presentCount,
                child: ColoredBox(color: presentColor, child: const SizedBox.expand()),
              ),
            if (absentCount > 0)
              Flexible(
                flex: absentCount,
                child: ColoredBox(color: absentColor, child: const SizedBox.expand()),
              ),
            if (onDutyCount > 0)
              Flexible(
                flex: onDutyCount,
                child: ColoredBox(color: onDutyColor, child: const SizedBox.expand()),
              ),
          ],
        ),
      ),
    );
  }
}
