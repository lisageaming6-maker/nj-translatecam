import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_record.dart';

class StorageService {
  static const _historyKey = 'translation_history';
  static const _sourceLangKey = 'default_source_lang';
  static const _targetLangKey = 'default_target_lang';
  static const _ttsSpeedKey = 'tts_speed';
  static const _ttsPitchKey = 'tts_pitch';
  static const _ocrScriptKey = 'default_ocr_script';

  // ── History ─────────────────────────────────────────────────────────────

  Future<List<TranslationRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((s) => TranslationRecord.fromJson(s))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveRecord(TranslationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    raw.add(record.toJson());
    if (raw.length > 100) raw.removeAt(0);
    await prefs.setStringList(_historyKey, raw);
  }

  Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    raw.removeWhere((s) {
      final r = TranslationRecord.fromJson(s);
      return r.id == id;
    });
    await prefs.setStringList(_historyKey, raw);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<String> getSourceLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sourceLangKey) ?? 'English';
  }

  Future<void> setSourceLang(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceLangKey, name);
  }

  Future<String> getTargetLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_targetLangKey) ?? 'Hindi';
  }

  Future<void> setTargetLang(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetLangKey, name);
  }

  Future<double> getTtsSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_ttsSpeedKey) ?? 0.5;
  }

  Future<void> setTtsSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ttsSpeedKey, speed);
  }

  Future<double> getTtsPitch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_ttsPitchKey) ?? 1.0;
  }

  Future<void> setTtsPitch(double pitch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ttsPitchKey, pitch);
  }

  Future<String> getOcrScript() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ocrScriptKey) ?? 'Auto';
  }

  Future<void> setOcrScript(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ocrScriptKey, name);
  }
}
