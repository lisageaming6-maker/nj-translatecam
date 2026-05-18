import 'package:google_mlkit_translation/google_mlkit_translation.dart';

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
    name: 'Hindi',
    translateLanguage: TranslateLanguage.hindi,
    ttsLocale: 'hi-IN',
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

LanguageOption langByName(String name) =>
    kSupportedLanguages.firstWhere(
      (l) => l.name == name,
      orElse: () => kSupportedLanguages.first,
    );
