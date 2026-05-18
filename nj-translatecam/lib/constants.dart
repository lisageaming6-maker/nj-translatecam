import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// ── Translation language options ──────────────────────────────────────────────

class LanguageOption {
  final String name;
  final TranslateLanguage translateLanguage;
  final String ttsLocale;

  const LanguageOption({
    required this.name,
    required this.translateLanguage,
    required this.ttsLocale,
  });
}

const List<LanguageOption> kSupportedLanguages = [
  LanguageOption(
    name: 'English',
    translateLanguage: TranslateLanguage.english,
    ttsLocale: 'en-US',
  ),
  LanguageOption(
    name: 'Hindi',
    translateLanguage: TranslateLanguage.hindi,
    ttsLocale: 'hi-IN',
  ),
  LanguageOption(
    name: 'Spanish',
    translateLanguage: TranslateLanguage.spanish,
    ttsLocale: 'es-ES',
  ),
  LanguageOption(
    name: 'French',
    translateLanguage: TranslateLanguage.french,
    ttsLocale: 'fr-FR',
  ),
  LanguageOption(
    name: 'German',
    translateLanguage: TranslateLanguage.german,
    ttsLocale: 'de-DE',
  ),
  LanguageOption(
    name: 'Chinese',
    translateLanguage: TranslateLanguage.chinese,
    ttsLocale: 'zh-CN',
  ),
  LanguageOption(
    name: 'Japanese',
    translateLanguage: TranslateLanguage.japanese,
    ttsLocale: 'ja-JP',
  ),
  LanguageOption(
    name: 'Korean',
    translateLanguage: TranslateLanguage.korean,
    ttsLocale: 'ko-KR',
  ),
  LanguageOption(
    name: 'Portuguese',
    translateLanguage: TranslateLanguage.portuguese,
    ttsLocale: 'pt-BR',
  ),
  LanguageOption(
    name: 'Arabic',
    translateLanguage: TranslateLanguage.arabic,
    ttsLocale: 'ar-SA',
  ),
  LanguageOption(
    name: 'Russian',
    translateLanguage: TranslateLanguage.russian,
    ttsLocale: 'ru-RU',
  ),
  LanguageOption(
    name: 'Italian',
    translateLanguage: TranslateLanguage.italian,
    ttsLocale: 'it-IT',
  ),
];

LanguageOption langByName(String name) => kSupportedLanguages.firstWhere(
      (l) => l.name == name,
      orElse: () => kSupportedLanguages.first,
    );

// ── OCR script options ─────────────────────────────────────────────────────────

class OcrScriptOption {
  final String name;
  final String subtitle;
  final String exampleLanguages;
  final TextRecognitionScript? script;
  final String iconEmoji;

  const OcrScriptOption({
    required this.name,
    required this.subtitle,
    required this.exampleLanguages,
    required this.script,
    required this.iconEmoji,
  });

  bool get isAuto => script == null;
}

const List<OcrScriptOption> kOcrScripts = [
  OcrScriptOption(
    name: 'Auto',
    subtitle: 'Try all scripts, pick the best',
    exampleLanguages: 'All supported scripts',
    script: null,
    iconEmoji: '?',
  ),
  OcrScriptOption(
    name: 'Latin',
    subtitle: 'Roman alphabet',
    exampleLanguages: 'English, Spanish, French, German, Italian, Portuguese',
    script: TextRecognitionScript.latin,
    iconEmoji: 'A',
  ),
  OcrScriptOption(
    name: 'Devanagari',
    subtitle: 'देवनागरी — Hindi & related',
    exampleLanguages: 'Hindi, Marathi, Sanskrit, Nepali, Konkani',
    script: TextRecognitionScript.devanagari,
    iconEmoji: 'अ',
  ),
  OcrScriptOption(
    name: 'Chinese',
    subtitle: 'Simplified & Traditional',
    exampleLanguages: 'Chinese (Simplified), Chinese (Traditional)',
    script: TextRecognitionScript.chinese,
    iconEmoji: '字',
  ),
  OcrScriptOption(
    name: 'Japanese',
    subtitle: 'Hiragana · Katakana · Kanji',
    exampleLanguages: 'Japanese',
    script: TextRecognitionScript.japanese,
    iconEmoji: 'あ',
  ),
  OcrScriptOption(
    name: 'Korean',
    subtitle: 'Hangul (한글)',
    exampleLanguages: 'Korean',
    script: TextRecognitionScript.korean,
    iconEmoji: '가',
  ),
];

OcrScriptOption scriptByName(String name) => kOcrScripts.firstWhere(
      (s) => s.name == name,
      orElse: () => kOcrScripts.first, // defaults to Auto
    );

List<OcrScriptOption> get kConcreteScripts =>
    kOcrScripts.where((s) => !s.isAuto).toList();
