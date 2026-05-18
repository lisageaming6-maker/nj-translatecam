import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../models/translation_record.dart';
import '../services/storage_service.dart';

class TranslationArgs {
  final String recognizedText;
  final LanguageOption sourceLanguage;
  final LanguageOption targetLanguage;

  const TranslationArgs({
    required this.recognizedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });
}

enum _TtsState { idle, playing, stopped }

class TranslationScreen extends StatefulWidget {
  final TranslationArgs args;

  const TranslationScreen({super.key, required this.args});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final _storage = StorageService();
  final _tts = FlutterTts();
  OnDeviceTranslator? _translator;

  bool _isTranslating = true;
  bool _isDownloadingModel = false;
  String? _translatedText;
  String? _errorMessage;
  _TtsState _ttsState = _TtsState.idle;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _translate();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    _tts.setStartHandler(() => setState(() => _ttsState = _TtsState.playing));
    _tts.setCompletionHandler(
        () => setState(() => _ttsState = _TtsState.stopped));
    _tts.setCancelHandler(
        () => setState(() => _ttsState = _TtsState.stopped));
    _tts.setErrorHandler((_) => setState(() => _ttsState = _TtsState.stopped));

    // Load user TTS preferences
    final speed = await _storage.getTtsSpeed();
    final pitch = await _storage.getTtsPitch();
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
  }

  Future<void> _translate() async {
    setState(() {
      _isTranslating = true;
      _isDownloadingModel = false;
      _errorMessage = null;
    });

    try {
      // Check and download model if needed
      final modelManager = OnDeviceTranslatorModelManager();
      final srcLang = widget.args.sourceLanguage.translateLanguage;
      final tgtLang = widget.args.targetLanguage.translateLanguage;

      final srcDownloaded =
          await modelManager.isModelDownloaded(srcLang.bcpCode);
      final tgtDownloaded =
          await modelManager.isModelDownloaded(tgtLang.bcpCode);

      if (!srcDownloaded || !tgtDownloaded) {
        setState(() => _isDownloadingModel = true);
        if (!srcDownloaded) {
          await modelManager.downloadModel(srcLang.bcpCode);
        }
        if (!tgtDownloaded) {
          await modelManager.downloadModel(tgtLang.bcpCode);
        }
        setState(() => _isDownloadingModel = false);
      }

      _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: srcLang,
        targetLanguage: tgtLang,
      );

      final result =
          await _translator!.translateText(widget.args.recognizedText);

      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Translation failed: $e';
        _isTranslating = false;
      });
    }
  }

  Future<void> _speak() async {
    if (_ttsState == _TtsState.playing) {
      await _tts.stop();
      setState(() => _ttsState = _TtsState.stopped);
      return;
    }
    if (_translatedText == null) return;
    await _tts.setLanguage(widget.args.targetLanguage.ttsLocale);
    await _tts.speak(_translatedText!);
  }

  Future<void> _share() async {
    if (_translatedText == null) return;
    final text = '${widget.args.recognizedText}\n'
        '↓ ${widget.args.targetLanguage.name}\n'
        '$_translatedText';
    await Share.share(text, subject: 'NJ TranslateCam');
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  Future<void> _saveToHistory() async {
    if (_translatedText == null || _saved) return;
    final record = TranslationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: widget.args.recognizedText,
      translatedText: _translatedText!,
      sourceLanguageName: widget.args.sourceLanguage.name,
      targetLanguageName: widget.args.targetLanguage.name,
      timestamp: DateTime.now(),
    );
    await _storage.saveRecord(record);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to history')),
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _translator?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final src = widget.args.sourceLanguage;
    final tgt = widget.args.targetLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text('${src.name} → ${tgt.name}'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: _translatedText != null ? _share : null,
          ),
          IconButton(
            tooltip: _saved ? 'Saved' : 'Save to History',
            icon: Icon(
              _saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
            ),
            onPressed: _translatedText != null && !_saved
                ? _saveToHistory
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original text card
              _TextCard(
                label: src.name,
                text: widget.args.recognizedText,
                color: cs.primaryContainer,
                onTextColor: cs.onPrimaryContainer,
                onCopy: () => _copyToClipboard(widget.args.recognizedText),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_downward_rounded,
                        color: cs.primary),
                  ),
                ),
              ),

              // Translation card
              if (_isTranslating)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        _isDownloadingModel
                            ? 'Downloading translation model…\nThis only happens once.'
                            : 'Translating…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSecondaryContainer),
                      ),
                    ],
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: cs.error),
                          const SizedBox(width: 8),
                          Text('Error',
                              style: TextStyle(
                                  color: cs.error,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!,
                          style: TextStyle(color: cs.onErrorContainer)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _translate,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_translatedText != null)
                _TextCard(
                  label: tgt.name,
                  text: _translatedText!,
                  color: cs.tertiaryContainer,
                  onTextColor: cs.onTertiaryContainer,
                  onCopy: () => _copyToClipboard(_translatedText!),
                ),

              const SizedBox(height: 24),

              // TTS button
              if (_translatedText != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _speak,
                    icon: Icon(
                      _ttsState == _TtsState.playing
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                    ),
                    label: Text(
                      _ttsState == _TtsState.playing
                          ? 'Stop Speaking'
                          : 'Speak Translation',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saved ? null : _saveToHistory,
                        icon: Icon(_saved
                            ? Icons.check_rounded
                            : Icons.bookmark_add_outlined),
                        label: Text(_saved ? 'Saved' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final Color onTextColor;
  final VoidCallback onCopy;

  const _TextCard({
    required this.label,
    required this.text,
    required this.color,
    required this.onTextColor,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: onTextColor.withAlpha(180),
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: onCopy,
                child: Icon(Icons.copy_rounded,
                    size: 18, color: onTextColor.withAlpha(180)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 17,
              color: onTextColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
