import 'package:hive_flutter/hive_flutter.dart';

/// Local (device-level) app preferences — specifically the language choice
/// from first launch, which needs somewhere to live before a Firestore
/// user doc exists yet (i.e. before signup). Once an account exists,
/// Firestore (myLanguage/theirLanguage on the user doc) is the real
/// source of truth — this is just the bridge for pre-account state.
class AppPrefsService {
  static const _boxName = 'app_prefs';
  static const _myLanguageKey = 'myLanguage';
  static const _theirLanguageKey = 'theirLanguage';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  bool get hasPickedLanguage => _box.containsKey(_myLanguageKey);

  String? get myLanguageCode => _box.get(_myLanguageKey);
  String? get theirLanguageCode => _box.get(_theirLanguageKey);

  Future<void> setLanguages({required String myLanguageCode, required String theirLanguageCode}) async {
    await _box.put(_myLanguageKey, myLanguageCode);
    await _box.put(_theirLanguageKey, theirLanguageCode);
  }
}