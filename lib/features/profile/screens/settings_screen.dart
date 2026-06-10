import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../widgets/reset_data_dialog.dart';

/// A premium, optimized Settings screen.
/// Includes appearance preferences and danger zone data reset.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _handleClearData(BuildContext context) async {
    final db = ref.read(appDatabaseProvider);
    final confirmed = await showResetDataDialog(context);

    if (confirmed == true && context.mounted) {
      try {
        await db.transaction(() async {
          await db.customStatement('DELETE FROM attendance_records_table');
          await db.customStatement('DELETE FROM attendance_sessions_table');
          await db.customStatement('DELETE FROM students_table');
          await db.customStatement('DELETE FROM classrooms_table');
          await db.customStatement('DELETE FROM sync_queue_table');
          await db.customStatement('DELETE FROM sync_metadata_table');
        });

        if (context.mounted) {
          ErrorSnackBar.show(
            context,
            message: 'All local attendance data has been successfully cleared.',
            type: ErrorSnackBarType.success,
          );
          // Return to home page
          context.go('/home');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorSnackBar.show(
            context,
            message: 'Failed to reset local data: $e',
            type: ErrorSnackBarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── App Header/Logo ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withAlpha(120),
                    cs.secondaryContainer.withAlpha(60),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withAlpha(30),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 40,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cryonix',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Offline Attendance Manager',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withAlpha(200),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v1.0.0 (Local-Only)',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Theme Section ────────────────────────────────────────────────
            _buildSectionHeader('Appearance', cs, tt),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: cs.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Theme Mode',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customize how Cryonix looks on your device.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: cs.primary,
                          selectedForegroundColor: cs.onPrimary,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto_outlined, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined, size: 18),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (sel) {
                          ref.read(themeNotifierProvider.notifier).setTheme(sel.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Danger Zone Section ──────────────────────────────────────────
            _buildSectionHeader('Danger Zone', cs, tt),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: cs.errorContainer.withAlpha(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.error.withAlpha(60)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: cs.error,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Destructive Actions',
                          style: tt.titleMedium?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Permanently remove all classrooms, student files, sessions, '
                      'and local records. This action is irreversible.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _handleClearData(context),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Reset Local Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error.withAlpha(120)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: tt.labelMedium?.copyWith(
          color: cs.onSurfaceVariant.withAlpha(160),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
