import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/translation_record.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  List<TranslationRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final records = await _storage.loadHistory();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _delete(String id) async {
    await _storage.deleteRecord(id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will permanently remove all saved translations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.clearHistory();
      await _load();
    }
  }

  void _share(TranslationRecord record) {
    final text = '${record.originalText}\n'
        '↓ ${record.targetLanguageName}\n'
        '${record.translatedText}';
    Share.share(text, subject: 'NJ TranslateCam Translation');
  }

  void _showDetail(TranslationRecord record) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '${record.sourceLanguageName} → ${record.targetLanguageName}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              DateFormat('MMM d, y  h:mm a').format(record.timestamp),
              style: TextStyle(
                  color: cs.onSurface.withAlpha(130), fontSize: 12),
            ),
            const Divider(height: 24),
            Text('Original (${record.sourceLanguageName})',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                    fontSize: 12)),
            const SizedBox(height: 6),
            SelectableText(record.originalText,
                style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 16),
            Text('Translation (${record.targetLanguageName})',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.tertiary,
                    fontSize: 12)),
            const SizedBox(height: 6),
            SelectableText(record.translatedText,
                style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _share(record);
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _delete(record.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation History'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 72, color: cs.onSurface.withAlpha(60)),
                      const SizedBox(height: 16),
                      Text(
                        'No translations yet',
                        style: TextStyle(
                            color: cs.onSurface.withAlpha(120),
                            fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save a translation to see it here.',
                        style: TextStyle(
                            color: cs.onSurface.withAlpha(80),
                            fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final rec = _records[i];
                      return Dismissible(
                        key: Key(rec.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.delete_outline_rounded,
                              color: cs.error),
                        ),
                        onDismissed: (_) => _delete(rec.id),
                        child: Material(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showDetail(rec),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${rec.sourceLanguageName} → ${rec.targetLanguageName}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onPrimaryContainer),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM d').format(rec.timestamp),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurface.withAlpha(100)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rec.originalText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rec.translatedText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurface.withAlpha(150)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(Icons.share_rounded,
                                            size: 18,
                                            color: cs.primary),
                                        onPressed: () => _share(rec),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: cs.error),
                                        onPressed: () => _delete(rec.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
