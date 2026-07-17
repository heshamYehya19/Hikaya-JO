/// A language option for Hikaya Talk. speechLocale/ttsLocale are BCP-47
/// locale tags for the device's speech recognizer / text-to-speech engine;
/// translateCode is the 2-letter code the Google Translate API expects.
class TalkLanguage {
  final String translateCode;
  final String speechLocale;
  final String ttsLocale;
  final String name;
  final String flag;

  const TalkLanguage({
    required this.translateCode,
    required this.speechLocale,
    required this.ttsLocale,
    required this.name,
    required this.flag,
  });
}

const List<TalkLanguage> kTalkLanguages = [
  TalkLanguage(translateCode: 'en', speechLocale: 'en-US', ttsLocale: 'en-US', name: 'English', flag: '🇬🇧'),
  TalkLanguage(translateCode: 'ar', speechLocale: 'ar-JO', ttsLocale: 'ar-SA', name: 'Arabic', flag: '🇯🇴'),
  TalkLanguage(translateCode: 'fr', speechLocale: 'fr-FR', ttsLocale: 'fr-FR', name: 'French', flag: '🇫🇷'),
  TalkLanguage(translateCode: 'es', speechLocale: 'es-ES', ttsLocale: 'es-ES', name: 'Spanish', flag: '🇪🇸'),
  TalkLanguage(translateCode: 'de', speechLocale: 'de-DE', ttsLocale: 'de-DE', name: 'German', flag: '🇩🇪'),
  TalkLanguage(translateCode: 'it', speechLocale: 'it-IT', ttsLocale: 'it-IT', name: 'Italian', flag: '🇮🇹'),
  TalkLanguage(translateCode: 'zh', speechLocale: 'zh-CN', ttsLocale: 'zh-CN', name: 'Chinese', flag: '🇨🇳'),
  TalkLanguage(translateCode: 'ru', speechLocale: 'ru-RU', ttsLocale: 'ru-RU', name: 'Russian', flag: '🇷🇺'),
];

/// Looks up a TalkLanguage by its translateCode, falling back to [fallback]
/// (default English) if the stored code doesn't match anything — e.g. if
/// Firestore has a code from before the language list changed.
TalkLanguage talkLanguageFromCode(String? code, {TalkLanguage fallback = const TalkLanguage(
  translateCode: 'en', speechLocale: 'en-US', ttsLocale: 'en-US', name: 'English', flag: '🇬🇧',
)}) {
  if (code == null) return fallback;
  for (final lang in kTalkLanguages) {
    if (lang.translateCode == code) return lang;
  }
  return fallback;
}