import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/score_record.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    super.key,
    required this.historyRecords,
    required this.savedRecords,
    required this.fontColor,
    required this.onRecordsChanged,
    this.onContinueMatch,
  });

  final List<ScoreRecord> historyRecords;
  final List<ScoreRecord> savedRecords;
  final Color fontColor;
  final Future<void> Function(List<ScoreRecord>, List<ScoreRecord>)
  onRecordsChanged;
  final void Function(ScoreRecord)? onContinueMatch;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late List<ScoreRecord> _historyRecords;
  late List<ScoreRecord> _savedRecords;
  int _historyColumns = 1;
  int _savedColumns = 1;

  @override
  void initState() {
    super.initState();
    _historyRecords = List<ScoreRecord>.of(widget.historyRecords);
    _savedRecords = List<ScoreRecord>.of(widget.savedRecords);
  }

  Future<void> _deleteRecord({
    required bool isHistory,
    required int index,
  }) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text('Delete record?'),
            content: const Text('This action cannot be undone.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    setState(() {
      if (isHistory) {
        _historyRecords = List<ScoreRecord>.of(_historyRecords)
          ..removeAt(index);
      } else {
        _savedRecords = List<ScoreRecord>.of(_savedRecords)..removeAt(index);
      }
    });
    await widget.onRecordsChanged(_historyRecords, _savedRecords);
  }

  Future<void> _promoteToSaved(int index) async {
    final ScoreRecord src = _historyRecords[index];
    final ScoreRecord promoted = ScoreRecord(
      type: 'saved',
      timestamp: src.timestamp,
      leftScore: src.leftScore,
      rightScore: src.rightScore,
      leftBgColor: src.leftBgColor,
      rightBgColor: src.rightBgColor,
      fontColor: src.fontColor,
      leftPlayerName: src.leftPlayerName,
      rightPlayerName: src.rightPlayerName,
      showRightSide: src.showRightSide,
      duration: src.duration,
    );
    setState(() {
      _savedRecords = <ScoreRecord>[promoted, ..._savedRecords];
    });
    await widget.onRecordsChanged(_historyRecords, _savedRecords);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Saved list')));
    }
  }

  Future<void> _editRecord({
    required bool isHistory,
    required int index,
  }) async {
    final ScoreRecord current = isHistory
        ? _historyRecords[index]
        : _savedRecords[index];

    final TextEditingController leftNameController = TextEditingController(
      text: current.leftPlayerName,
    );
    final TextEditingController rightNameController = TextEditingController(
      text: current.rightPlayerName,
    );
    final TextEditingController leftScoreController = TextEditingController(
      text: current.leftScore.toString(),
    );
    final TextEditingController rightScoreController = TextEditingController(
      text: current.rightScore.toString(),
    );
    final TextEditingController durationSecondsController =
        TextEditingController(
          text: current.duration == null
              ? ''
              : current.duration!.inSeconds.toString(),
        );

    bool showRightSide = current.showRightSide;

    final bool save =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return StatefulBuilder(
              builder:
                  (
                    BuildContext context,
                    void Function(void Function()) setLocalState,
                  ) {
                    return AlertDialog(
                      title: const Text('Edit Record'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Versus Mode'),
                              value: showRightSide,
                              onChanged: (bool value) {
                                setLocalState(() {
                                  showRightSide = value;
                                });
                              },
                            ),
                            TextField(
                              controller: leftNameController,
                              decoration: const InputDecoration(
                                labelText: 'Left Player Name',
                              ),
                            ),
                            TextField(
                              controller: leftScoreController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Left Score',
                              ),
                            ),
                            if (showRightSide) ...<Widget>[
                              TextField(
                                controller: rightNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Player Name',
                                ),
                              ),
                              TextField(
                                controller: rightScoreController,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Right Score',
                                ),
                              ),
                            ],
                            TextField(
                              controller: durationSecondsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Duration (seconds)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
            );
          },
        ) ??
        false;

    if (!save || !mounted) {
      leftNameController.dispose();
      rightNameController.dispose();
      leftScoreController.dispose();
      rightScoreController.dispose();
      durationSecondsController.dispose();
      return;
    }

    final int parsedLeftScore =
        int.tryParse(leftScoreController.text.trim()) ?? 0;
    final int parsedRightScore =
        int.tryParse(rightScoreController.text.trim()) ?? 0;
    final int? durationSeconds = int.tryParse(
      durationSecondsController.text.trim(),
    );

    final ScoreRecord edited = ScoreRecord(
      type: current.type,
      timestamp: current.timestamp,
      leftScore: parsedLeftScore,
      rightScore: showRightSide ? parsedRightScore : 0,
      leftBgColor: current.leftBgColor,
      rightBgColor: current.rightBgColor,
      fontColor: current.fontColor,
      leftPlayerName: leftNameController.text.trim(),
      rightPlayerName: showRightSide ? rightNameController.text.trim() : '',
      showRightSide: showRightSide,
      duration: durationSeconds == null
          ? null
          : Duration(seconds: durationSeconds),
    );

    leftNameController.dispose();
    rightNameController.dispose();
    leftScoreController.dispose();
    rightScoreController.dispose();
    durationSecondsController.dispose();

    setState(() {
      if (isHistory) {
        final List<ScoreRecord> next = List<ScoreRecord>.of(_historyRecords);
        next[index] = edited;
        _historyRecords = next;
      } else {
        final List<ScoreRecord> next = List<ScoreRecord>.of(_savedRecords);
        next[index] = edited;
        _savedRecords = next;
      }
    });
    await widget.onRecordsChanged(_historyRecords, _savedRecords);
  }

  Future<void> _clearAll({required bool isHistory}) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text(isHistory ? 'Clear all history?' : 'Clear all saved?'),
            content: const Text('This will delete every item in the list.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete All'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    setState(() {
      if (isHistory) {
        _historyRecords = <ScoreRecord>[];
      } else {
        _savedRecords = <ScoreRecord>[];
      }
    });
    await widget.onRecordsChanged(_historyRecords, _savedRecords);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Records'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'History'),
              Tab(text: 'Saved'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            RecordList(
              records: _historyRecords,
              emptyLabel: 'No history yet',
              viewColumns: _historyColumns,
              onViewColumnsChanged: (int cols) {
                setState(() {
                  _historyColumns = cols;
                });
              },
              onClearAll: () => _clearAll(isHistory: true),
              onDelete: (int i) => _deleteRecord(isHistory: true, index: i),
              onEdit: (int i) => _editRecord(isHistory: true, index: i),
              onPromoteToSaved: _promoteToSaved,
              onContinueMatch: widget.onContinueMatch,
              onRecordsImported: (List<ScoreRecord> imported) async {
                setState(() => _historyRecords = imported);
                await widget.onRecordsChanged(_historyRecords, _savedRecords);
              },
            ),
            RecordList(
              records: _savedRecords,
              emptyLabel: 'No saved scores yet',
              viewColumns: _savedColumns,
              onViewColumnsChanged: (int cols) {
                setState(() {
                  _savedColumns = cols;
                });
              },
              onClearAll: () => _clearAll(isHistory: false),
              onDelete: (int i) => _deleteRecord(isHistory: false, index: i),
              onEdit: (int i) => _editRecord(isHistory: false, index: i),
              onContinueMatch: widget.onContinueMatch,
              onRecordsImported: (List<ScoreRecord> imported) async {
                setState(() => _savedRecords = imported);
                await widget.onRecordsChanged(_historyRecords, _savedRecords);
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _formatDuration(Duration? d) {
  if (d == null || d == Duration.zero) return '';
  final int h = d.inHours;
  final int m = d.inMinutes.remainder(60);
  final int s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m ${s}s';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}

String _durationSeconds(Duration? d) {
  if (d == null || d == Duration.zero) return '';
  return d.inSeconds.toString();
}

String _recordsToCsv(List<ScoreRecord> records) {
  const String header =
      'Date,Type,Mode,DurationSeconds,Left Player,Left Score,Right Player,Right Score';
  final Iterable<String> rows = records.map((ScoreRecord r) {
    final String leftName = r.leftPlayerName.isEmpty
        ? 'Player 1'
        : r.leftPlayerName;
    final String rightName = r.rightPlayerName.isEmpty
        ? 'Player 2'
        : r.rightPlayerName;
    return <String>[
      _csvEscape('${r.timestamp.toLocal()}'.split('.').first),
      _csvEscape(r.type == 'saved' ? 'Saved' : 'History'),
      _csvEscape(r.showRightSide ? 'Versus' : 'Solo'),
      _csvEscape(_durationSeconds(r.duration)),
      _csvEscape(leftName),
      r.leftScore.toString(),
      _csvEscape(rightName),
      r.showRightSide ? r.rightScore.toString() : '',
    ].join(',');
  });
  return '$header\n${rows.join('\n')}';
}

String _recordToCell(ScoreRecord r) {
  final String leftName = r.leftPlayerName.isEmpty
      ? 'Player 1'
      : r.leftPlayerName;
  final String rightName = r.rightPlayerName.isEmpty
      ? 'Player 2'
      : r.rightPlayerName;
  final String date = '${r.timestamp.toLocal()}'.split('.').first;
  final String type = r.type == 'saved' ? 'Saved' : 'History';
  final String mode = r.showRightSide ? 'Versus' : 'Solo';
  final String dur = _durationSeconds(r.duration);
  if (r.showRightSide) {
    return '$date\t$type\t$mode\t$dur\t$leftName\t${r.leftScore}\t$rightName\t${r.rightScore}';
  }
  return '$date\t$type\t$mode\t$dur\t$leftName\t${r.leftScore}';
}

Future<void> _saveRecordsToCsvFile(
  BuildContext context,
  List<ScoreRecord> records,
) async {
  try {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final String? pickedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to save CSV',
      initialDirectory: docDir.path,
    );
    final Directory targetDir = Directory(pickedPath ?? docDir.path);

    final String ts = DateTime.now()
        .toLocal()
        .toIso8601String()
        .replaceAll(RegExp(r'[:\.]'), '-')
        .substring(0, 19);
    final File file = File('${targetDir.path}/scoretap_$ts.csv');
    await file.writeAsString(_recordsToCsv(records), flush: true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to ${file.path}'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

/// Parses a CSV row properly (handles quoted fields with commas inside).
List<String> _parseCsvRow(String row) {
  final List<String> fields = <String>[];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < row.length; i++) {
    final String ch = row[i];
    if (inQuotes) {
      if (ch == '"' && i + 1 < row.length && row[i + 1] == '"') {
        current.write('"');
        i++;
      } else if (ch == '"') {
        inQuotes = false;
      } else {
        current.write(ch);
      }
    } else {
      if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(ch);
      }
    }
  }
  fields.add(current.toString());
  return fields;
}

Future<void> _importCsvFile(
  BuildContext context,
  Future<void> Function(List<ScoreRecord>) onImported,
) async {
  try {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select CSV to import',
      type: FileType.custom,
      allowedExtensions: <String>['csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;

    final String? filePath = result.files.single.path;
    if (filePath == null) return;

    final String content = await File(filePath).readAsString();
    final List<String> lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((String l) => l.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CSV has no data rows')));
      }
      return;
    }

    // Confirm replace
    if (context.mounted) {
      final bool confirmed =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext ctx) => AlertDialog(
              title: const Text('Replace list?'),
              content: Text(
                'Import ${lines.length - 1} record(s) from CSV?\nThis will replace the current list.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Import'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    // header: Date,Type,Mode,Duration,Left Player,Left Score,Right Player,Right Score
    final List<ScoreRecord> imported = <ScoreRecord>[];
    for (int i = 1; i < lines.length; i++) {
      final List<String> cols = _parseCsvRow(lines[i]);
      if (cols.length < 6) continue;
      final DateTime timestamp =
          DateTime.tryParse(cols[0].trim()) ?? DateTime.now();
      final String type = cols[1].trim().toLowerCase() == 'saved'
          ? 'saved'
          : 'history';
      final bool showRightSide = cols[2].trim().toLowerCase() != 'solo';
      final int? durationSeconds = cols.length > 3
          ? int.tryParse(cols[3].trim())
          : null;
      final String leftName = cols[4].trim() == 'Player 1'
          ? ''
          : cols[4].trim();
      final int leftScore = int.tryParse(cols[5].trim()) ?? 0;
      final String rightName = cols.length > 6
          ? (cols[6].trim() == 'Player 2' ? '' : cols[6].trim())
          : '';
      final int rightScore = cols.length > 7
          ? (int.tryParse(cols[7].trim()) ?? 0)
          : 0;

      imported.add(
        ScoreRecord(
          type: type,
          timestamp: timestamp,
          leftScore: leftScore,
          rightScore: rightScore,
          leftBgColor: const Color(0xFF1976D2),
          rightBgColor: const Color(0xFFF57C00),
          fontColor: Colors.white,
          leftPlayerName: leftName,
          rightPlayerName: rightName,
          showRightSide: showRightSide,
          duration: durationSeconds == null
              ? null
              : Duration(seconds: durationSeconds),
        ),
      );
    }

    await onImported(imported);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${imported.length} record(s)')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}

class RecordList extends StatelessWidget {
  const RecordList({
    super.key,
    required this.records,
    required this.emptyLabel,
    required this.viewColumns,
    required this.onViewColumnsChanged,
    required this.onClearAll,
    required this.onDelete,
    required this.onEdit,
    this.onPromoteToSaved,
    this.onContinueMatch,
    this.onRecordsImported,
  });

  final List<ScoreRecord> records;
  final String emptyLabel;
  final int viewColumns;
  final ValueChanged<int> onViewColumnsChanged;
  final Future<void> Function() onClearAll;
  final Future<void> Function(int index) onDelete;
  final Future<void> Function(int index) onEdit;
  final Future<void> Function(int index)? onPromoteToSaved;
  final void Function(ScoreRecord)? onContinueMatch;
  final Future<void> Function(List<ScoreRecord>)? onRecordsImported;

  Widget _buildRecordCard(BuildContext context, int index) {
    final ScoreRecord record = records[index];
    final String modeLabel = record.showRightSide ? 'Versus Mode' : 'Solo Mode';
    final String leftName = record.leftPlayerName.isEmpty
        ? 'Player 1'
        : record.leftPlayerName;
    final String rightName = record.rightPlayerName.isEmpty
        ? 'Player 2'
        : record.rightPlayerName;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${record.timestamp.toLocal()}'.split('.').first,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${record.type == 'saved' ? 'Saved' : 'Reset History'} | $modeLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (record.duration != null &&
                          record.duration != Duration.zero)
                        Text(
                          _formatDuration(record.duration),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                if (onContinueMatch != null)
                  IconButton(
                    tooltip: 'Continue match',
                    icon: const Icon(
                      Icons.play_circle_outline,
                      size: 20,
                      color: Colors.green,
                    ),
                    onPressed: () => onContinueMatch!(record),
                  ),
                IconButton(
                  tooltip: 'Copy as cell',
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _recordToCell(record)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Edit record',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => onEdit(index),
                ),
                if (onPromoteToSaved != null)
                  IconButton(
                    tooltip: 'Save to Saved list',
                    icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                    onPressed: () => onPromoteToSaved!(index),
                  ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: RecordSideCard(
                    name: leftName,
                    score: record.leftScore,
                    backgroundColor: record.leftBgColor,
                    fontColor: record.fontColor,
                    isLeft: true,
                  ),
                ),
                if (record.showRightSide)
                  Expanded(
                    child: RecordSideCard(
                      name: rightName,
                      score: record.rightScore,
                      backgroundColor: record.rightBgColor,
                      fontColor: record.fontColor,
                      isLeft: false,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (records.isNotEmpty || onRecordsImported != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(value: 1, label: Text('1 Col')),
                    ButtonSegment<int>(value: 2, label: Text('2 Col')),
                    ButtonSegment<int>(value: 3, label: Text('3 Col')),
                  ],
                  selected: <int>{viewColumns},
                  onSelectionChanged: (Set<int> selected) {
                    onViewColumnsChanged(selected.first);
                  },
                ),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    if (records.isNotEmpty) ...<Widget>[
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _recordsToCsv(records)),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('CSV copied to clipboard'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Copy CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _saveRecordsToCsvFile(context, records),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Export CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onClearAll,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Delete All'),
                      ),
                    ],
                    if (onRecordsImported != null)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _importCsvFile(context, onRecordsImported!),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import CSV'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Text(
                    emptyLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : viewColumns == 1
              ? ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _buildRecordCard(context, index);
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: (records.length / viewColumns).ceil(),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int rowIndex) {
                    final int start = rowIndex * viewColumns;
                    final int end = (start + viewColumns).clamp(
                      0,
                      records.length,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (int i = start; i < end; i++) ...<Widget>[
                          if (i > start) const SizedBox(width: 12),
                          Expanded(child: _buildRecordCard(context, i)),
                        ],
                        for (int i = end; i < start + viewColumns; i++)
                          const Expanded(child: SizedBox()),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class RecordSideCard extends StatelessWidget {
  const RecordSideCard({
    super.key,
    required this.name,
    required this.score,
    required this.backgroundColor,
    required this.fontColor,
    required this.isLeft,
  });

  final String name;
  final int score;
  final Color backgroundColor;
  final Color fontColor;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: isLeft ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLeft ? Radius.zero : const Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name,
            style: TextStyle(
              color: fontColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score',
            style: TextStyle(
              color: fontColor,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ],
      ),
    );
  }
}
