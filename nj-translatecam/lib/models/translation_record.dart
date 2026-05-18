import 'dart:convert';

class TranslationRecord {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguageName;
  final String targetLanguageName;
  final DateTime timestamp;

  const TranslationRecord({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguageName,
    required this.targetLanguageName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLanguageName': sourceLanguageName,
        'targetLanguageName': targetLanguageName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TranslationRecord.fromMap(Map<String, dynamic> map) =>
      TranslationRecord(
        id: map['id'] as String,
        originalText: map['originalText'] as String,
        translatedText: map['translatedText'] as String,
        sourceLanguageName: map['sourceLanguageName'] as String,
        targetLanguageName: map['targetLanguageName'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  String toJson() => jsonEncode(toMap());

  factory TranslationRecord.fromJson(String source) =>
      TranslationRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
