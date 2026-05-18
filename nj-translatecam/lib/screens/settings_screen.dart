import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();

  bool _isLoading = true;
  late LanguageOption _sourceLang;
  late LanguageOption _targetLang;
  late OcrScriptOption _ocrScript;
  double _ttsSpeed = 0.5;
  double _ttsPitch = 1.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final srcName = await _storage.getSourceLang();
    final tgtName = await _storage.getTargetLang();
    final scriptName = await _storage.getOcrScript();
    final speed = await _storage.getTtsSpeed();
    final pitch = await _storage.getTtsPitch();

    setState(() {
      _sourceLang = langByName(srcName);
      _targetLang = langByName(tgtName);
      _ocrScript = scriptByName(scriptName);
      _ttsSpeed = speed;
      _ttsPitch = pitch;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    await _storage.setSourceLang(_sourceLang.name);
    await _storage.setTargetLang(_targetLang.name);
    await _storage.setOcrScript(_ocrScript.name);
    await _storage.setTtsSpeed(_ttsSpeed);
    await _storage.setTtsPitch(_ttsPitch);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── OCR Script ───────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.document_scanner_rounded,
                    label: 'OCR Script',
                    color: cs.tertiary,
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    children: [
                      Text(
                        'Default script for text recognition',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      ...kOcrScripts.map((s) {
                        final isSelected = s.name == _ocrScript.name;
                        return GestureDetector(
                          onTap: () => setState(() => _ocrScript = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withAlpha(25)
                                  : cs.surface,
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary
                                    : cs.outline.withAlpha(80),
                                width: isSelected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary.withAlpha(30)
                                        : cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.iconEmoji,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isSelected ? cs.primary : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isSelected ? cs.primary : null,
                                        ),
                                      ),
                                      Text(
                                        s.exampleLanguages,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurface.withAlpha(140),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: cs.primary, size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Assamese info note
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14,
                                color: cs.onTertiaryContainer),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Assamese (অসমীয়া) uses Eastern Nagari script. '
                                'ML Kit does not yet have a dedicated '
                                'Bengali/Assamese recognizer. Use Devanagari '
                                'for Hindi; romanized Assamese works with Latin.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onTertiaryContainer,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Default Languages ────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.language_rounded,
                    label: 'Default Languages',
                    color: cs.primary,
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    children: [
                      _LangDropdown(
                        label: 'Source Language',
                        selected: _sourceLang,
                        onChanged: (v) {
                          if (v != null) setState(() => _sourceLang = v);
                        },
                      ),
                      const Divider(height: 24),
                      _LangDropdown(
                        label: 'Target Language',
                        selected: _targetLang,
                        onChanged: (v) {
                          if (v != null) setState(() => _targetLang = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── TTS Settings ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.volume_up_rounded,
                    label: 'Text-to-Speech',
                    color: cs.secondary,
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    children: [
                      _SliderSetting(
                        label: 'Speech Speed',
                        value: _ttsSpeed,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        leftLabel: 'Slow',
                        rightLabel: 'Fast',
                        onChanged: (v) => setState(() => _ttsSpeed = v),
                      ),
                      const Divider(height: 24),
                      _SliderSetting(
                        label: 'Pitch',
                        value: _ttsPitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        leftLabel: 'Low',
                        rightLabel: 'High',
                        onChanged: (v) => setState(() => _ttsPitch = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── About ────────────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    color: cs.error,
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    children: [
                      _InfoRow(label: 'App', value: 'NJ TranslateCam'),
                      const Divider(height: 20),
                      _InfoRow(label: 'Version', value: '1.0.0'),
                      const Divider(height: 20),
                      _InfoRow(label: 'OCR Engine', value: 'Google ML Kit'),
                      const Divider(height: 20),
                      _InfoRow(
                          label: 'OCR Scripts',
                          value: '${kOcrScripts.length} scripts'),
                      const Divider(height: 20),
                      _InfoRow(
                          label: 'Translation',
                          value: 'On-Device (offline)'),
                      const Divider(height: 20),
                      _InfoRow(
                          label: 'Supported Languages',
                          value: '${kSupportedLanguages.length} languages'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Settings',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _LangDropdown extends StatelessWidget {
  final String label;
  final LanguageOption selected;
  final ValueChanged<LanguageOption?> onChanged;

  const _LangDropdown({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<LanguageOption>(
          value: selected,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.leftLabel,
    required this.rightLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text(value.toStringAsFixed(1),
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withAlpha(120))),
            Text(rightLabel,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withAlpha(120))),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: cs.onSurface.withAlpha(160), fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}
