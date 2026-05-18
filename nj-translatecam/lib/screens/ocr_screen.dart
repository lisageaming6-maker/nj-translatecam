import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import 'translation_screen.dart';

class OcrScreen extends StatefulWidget {
  final String imagePath;

  const OcrScreen({super.key, required this.imagePath});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _storage = StorageService();
  late final TextEditingController _textController;

  bool _isProcessing = true;
  String? _errorMessage;
  String _recognizedText = '';
  late LanguageOption _sourceLang;
  late LanguageOption _targetLang;
  late OcrScriptOption _selectedScript;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _loadPrefsAndRecognize();
  }

  Future<void> _loadPrefsAndRecognize() async {
    final srcName = await _storage.getSourceLang();
    final tgtName = await _storage.getTargetLang();
    final scriptName = await _storage.getOcrScript();
    setState(() {
      _sourceLang = langByName(srcName);
      _targetLang = langByName(tgtName);
      _selectedScript = scriptByName(scriptName);
      _prefsLoaded = true;
    });
    await _recognizeText();
  }

  Future<void> _recognizeText() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final recognizer = TextRecognizer(script: _selectedScript.script);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = result.text.trim();
      setState(() {
        _recognizedText = text;
        _textController.text = text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Text recognition failed: $e';
        _isProcessing = false;
      });
    }
  }

  void _proceed() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No text to translate. Please edit the field.')),
      );
      return;
    }
    Navigator.of(context).pushNamed(
      '/translation',
      arguments: TranslationArgs(
        recognizedText: text,
        sourceLanguage: _sourceLang,
        targetLanguage: _targetLang,
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String label,
    required LanguageOption selected,
    required ValueChanged<LanguageOption?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<LanguageOption>(
          value: selected,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: kSupportedLanguages
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(l.name),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showScriptPicker() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Select OCR Script',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Choose the writing system that matches your image.',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withAlpha(140)),
              ),
            ),
            const Divider(height: 1),
            ...kOcrScripts.map((s) {
              final isSelected = s.name == _selectedScript.name;
              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withAlpha(30)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s.iconEmoji,
                    style: TextStyle(
                      fontSize: 20,
                      color: isSelected ? cs.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
                title: Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.primary : null,
                  ),
                ),
                subtitle: Text(
                  s.subtitle,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (s.name != _selectedScript.name) {
                    setState(() => _selectedScript = s);
                    _storage.setOcrScript(s.name);
                    _recognizeText();
                  }
                },
              );
            }),
            // Assamese note
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: cs.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assamese uses the Eastern Nagari script. '
                      'ML Kit does not yet offer a dedicated Bengali/Assamese '
                      'recognizer — use Devanagari for Hindi and Latin for '
                      'romanized Assamese.',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onTertiaryContainer,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognized Text'),
        actions: [
          if (_prefsLoaded)
            TextButton.icon(
              onPressed: _showScriptPicker,
              icon: Text(
                _selectedScript.iconEmoji,
                style: TextStyle(
                    fontSize: 18, color: cs.primary),
              ),
              label: Text(
                _selectedScript.name,
                style: TextStyle(color: cs.primary, fontSize: 13),
              ),
            ),
          if (!_isProcessing)
            IconButton(
              tooltip: 'Re-scan',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _recognizeText,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Script info banner
              if (_prefsLoaded)
                GestureDetector(
                  onTap: _showScriptPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedScript.iconEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Script: ${_selectedScript.name}  —  ${_selectedScript.subtitle}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                _selectedScript.exampleLanguages,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onPrimaryContainer.withAlpha(160),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_rounded,
                            size: 16, color: cs.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              if (_isProcessing) ...[
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Scanning with ${_selectedScript.name} recognizer…',
                        style: TextStyle(color: cs.onSurface.withAlpha(160)),
                      ),
                    ],
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: cs.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Language selectors
                if (_prefsLoaded) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildLanguageDropdown(
                          label: 'Source Language',
                          selected: _sourceLang,
                          onChanged: (v) {
                            if (v != null) setState(() => _sourceLang = v);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: cs.primary),
                      ),
                      Expanded(
                        child: _buildLanguageDropdown(
                          label: 'Target Language',
                          selected: _targetLang,
                          onChanged: (v) {
                            if (v != null) setState(() => _targetLang = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Recognized text editor
                Text(
                  'Recognized Text',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_recognizedText.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: cs.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No text detected. Try switching the script or type text manually.',
                            style: TextStyle(color: cs.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _textController,
                  maxLines: null,
                  minLines: 4,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    fontFamily: _selectedScript.name == 'Latin'
                        ? null
                        : null,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Recognized text appears here. Edit if needed…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Translate button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _proceed,
                  icon: const Icon(Icons.translate_rounded),
                  label: const Text('Translate',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
