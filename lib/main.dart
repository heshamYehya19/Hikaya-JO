import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/go_router.dart';
import 'core/localization/app_locale.dart';
import 'firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/offline_service.dart';
import 'core/services/app_prefs_service.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Web has no native config file to read from (unlike Android's
  // google-services.json), so it needs FirebaseOptions passed explicitly.
  // Other platforms keep initializing from their native config as before —
  // DefaultFirebaseOptions.currentPlatform only has a `web` case configured.
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );
  await Hive.initFlutter();
  await OfflineService.init();
  await AppPrefsService.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: HikayaJoApp()));
}

class HikayaJoApp extends StatelessWidget {
  const HikayaJoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hikaya JO',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AppLocaleScope(child: child!),
    );
  }
}