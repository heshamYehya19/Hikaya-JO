import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Local (device-level) app preferences. Currently just the app's UI
/// language (en/ar), settable from Profile → Settings, plus the
/// per-account "has this account seen the feature tour" flag.
class AppPrefsService {
  static const _boxName = 'app_prefs';
  static const _appLanguageKey = 'appLanguage';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  String? get appLanguageCode => _box.get(_appLanguageKey);

  /// Scoped per-account (uid), not per-device — same class of bug as the
  /// downloaded-journeys leak: the tour only ever makes sense as "has this
  /// specific account seen it", not "has this phone ever seen it".
  String get _tourKeyForCurrentUser {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'hasSeenFeatureTour::$uid';
  }

  bool get hasSeenFeatureTour => _box.containsKey(_tourKeyForCurrentUser);

  Future<void> setAppLanguage(String code) async {
    await _box.put(_appLanguageKey, code);
  }

  Future<void> markFeatureTourSeen() async {
    await _box.put(_tourKeyForCurrentUser, 'true');
  }
}