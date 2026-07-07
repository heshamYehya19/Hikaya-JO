import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // no options needed — google-services.json handles it on Android
  runApp(const ProviderScope(child: HikayaJoApp()));
}

class HikayaJoApp extends StatelessWidget {
  const HikayaJoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hikaya JO',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E1A47), // placeholder — swap for your brand color
      ),
      home: const Scaffold(
        body: Center(child: Text('Hikaya JO 🇯🇴')),
      ),
    );
  }
}