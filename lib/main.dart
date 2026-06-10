import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_initializer.dart';
import 'core/providers.dart';
import 'theme/app_theme.dart';
import 'routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppInitializer.initialize();
    final prefs = await SharedPreferences.getInstance();
    runApp(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CryonixApp(),
    ));
  } catch (e, stack) {
    debugPrint('[Critical] Startup failed: $e\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text('Fatal Startup Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}


class CryonixApp extends ConsumerWidget {
  const CryonixApp({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final router = ref.watch(routerProvider);



    return MaterialApp.router(
      title: 'Cryonix',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
