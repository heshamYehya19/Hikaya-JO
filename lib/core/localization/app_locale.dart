import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_prefs_service.dart';
import 'app_strings.dart';

/// Resolves 'ar' only when the user's saved language is Arabic; every other
/// choice (including the 6 Hikaya-Talk-only languages we don't have UI
/// strings for) falls back to English. That's a deliberate design choice,
/// not a bug — picking German for Hikaya Talk conversations doesn't mean
/// there's a German UI to switch to.
///
/// Usage in any widget: AppLocale.of(context).t('home_headline')
class AppLocale extends InheritedWidget {
  final String locale; // 'en' or 'ar'
  final String Function(String key) t;

  const AppLocale({
    super.key,
    required this.locale,
    required this.t,
    required super.child,
  });

  static AppLocale of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppLocale>();
    assert(result != null, 'No AppLocale found in context — make sure AppLocaleScope wraps the app root.');
    return result!;
  }

  @override
  bool updateShouldNotify(AppLocale oldWidget) => oldWidget.locale != locale;
}

/// Wrap the whole app in this once, at the root (see main.dart). Listens to
/// the signed-in user's appLanguage field in real time — changing it in
/// Profile updates every screen immediately, no restart needed. Before
/// login, falls back to whatever was picked on the first-launch language
/// screen (stored locally via AppPrefsService). This is intentionally
/// separate from Hikaya Talk's myLanguage/theirLanguage — see AppPrefsService.
class AppLocaleScope extends StatefulWidget {
  final Widget child;
  const AppLocaleScope({super.key, required this.child});

  @override
  State<AppLocaleScope> createState() => _AppLocaleScopeState();
}

class _AppLocaleScopeState extends State<AppLocaleScope> {
  String _locale = 'en';
  StreamSubscription? _userDocSub;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadLocalFallback();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _loadLocalFallback() {
    final code = AppPrefsService().appLanguageCode;
    if (code != null && mounted) {
      setState(() => _locale = code == 'ar' ? 'ar' : 'en');
    }
  }

  void _onAuthChanged(User? user) {
    _userDocSub?.cancel();
    if (user == null) {
      _loadLocalFallback();
      return;
    }
    _userDocSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
      final lang = doc.data()?['appLanguage'] as String?;
      if (lang != null && mounted) {
        setState(() => _locale = lang == 'ar' ? 'ar' : 'en');
      }
    });
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  String _translate(String key) {
    final map = _locale == 'ar' ? AppStrings.ar : AppStrings.en;
    return map[key] ?? AppStrings.en[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      t: _translate,
      child: Directionality(
        textDirection: _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: widget.child,
      ),
    );
  }
}