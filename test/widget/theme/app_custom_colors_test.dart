import 'package:cryonix/theme/app_custom_colors.dart';
import 'package:cryonix/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppCustomColors registered on light and dark themes', () {
    final light = AppTheme.lightTheme.extension<AppCustomColors>();
    final dark = AppTheme.darkTheme.extension<AppCustomColors>();
    expect(light, isNotNull);
    expect(dark, isNotNull);
    expect(light!.presentColor, isNot(dark!.presentColor));
  });
}
