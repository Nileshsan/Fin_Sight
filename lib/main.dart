import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'config/router_config.dart';
import 'config/theme.dart';
import 'constants/index.dart';
import 'providers/index.dart';
import 'services/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize StorageService
  await StorageService().init();

  // DEBUG: Clear stored tokens and user data when running in debug mode so
  // the app starts at the login screen for testing. Remove or guard this
  // behind an environment flag before committing to production behavior.
  if (kDebugMode) {
    try {
      await StorageService().clearTokens();
      await StorageService().clearUserData();
      debugPrint('Debug: cleared access token and user data at startup');
    } catch (e) {
      debugPrint('Debug: failed to clear storage at startup: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FinSight - CFO Services by Prophetic Business Solutions',
      theme: AppStyles.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
