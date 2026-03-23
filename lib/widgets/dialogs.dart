import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/counter_settings.dart';
import '../models/name_suggestion.dart';
import 'common_controls.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.leftBgColor,
    required this.rightBgColor,
    required this.fontSize,
    required this.fontColor,
  });

  final Color leftBgColor;
  final Color rightBgColor;
  final double fontSize;
  final Color fontColor;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late Color _tempLeftBgColor;
  late Color _tempRightBgColor;
  late double _tempFontSize;
  late Color _tempFontColor;

  @override
  void initState() {
    super.initState();
    _tempLeftBgColor = widget.leftBgColor;
    _tempRightBgColor = widget.rightBgColor;
    _tempFontSize = widget.fontSize;
    _tempFontColor = widget.fontColor;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Left Background Color',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ColorPickerButton(
                        currentColor: _tempLeftBgColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            _tempLeftBgColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Right Background Color',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ColorPickerButton(
                        currentColor: _tempRightBgColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            _tempRightBgColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Font Color',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ColorPickerButton(
                        currentColor: _tempFontColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            _tempFontColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Font Size',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Slider(
                              value: _tempFontSize,
                              min: 12,
                              max: 96,
                              divisions: 21,
                              label: _tempFontSize.toStringAsFixed(0),
                              onChanged: (double value) {
                                setState(() {
                                  _tempFontSize = value;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(_tempFontSize.toStringAsFixed(0)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _tempLeftBgColor = const Color(0xFF1976D2);
                        _tempRightBgColor = const Color(0xFFF57C00);
                        _tempFontSize = 24.0;
                        _tempFontColor = Colors.white;
                      });
                    },
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Reset'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        CounterSettings(
                          leftBgColor: _tempLeftBgColor,
                          rightBgColor: _tempRightBgColor,
                          fontSize: _tempFontSize,
                          fontColor: _tempFontColor,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditScoreDialog extends StatefulWidget {
  const EditScoreDialog({
    super.key,
    required this.title,
    required this.initialValue,
  });

  final String title;
  final int initialValue;

  @override
  State<EditScoreDialog> createState() => _EditScoreDialogState();
}

class _EditScoreDialogState extends State<EditScoreDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(hintText: 'Enter score'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final int parsedValue = int.tryParse(_controller.text) ?? 0;
            Navigator.of(context).pop(parsedValue);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EditTextDialog extends StatefulWidget {
  const EditTextDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.initialValue,
    this.suggestions = const <NameSuggestion>[],
    this.onDeleteSuggestion,
  });

  final String title;
  final String hintText;
  final String initialValue;
  final List<NameSuggestion> suggestions;
  final Future<void> Function(String)? onDeleteSuggestion;

  @override
  State<EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<EditTextDialog> {
  late final TextEditingController _controller;
  late List<NameSuggestion> _suggestions;
  String? _selectedSuggestionName;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _suggestions = List<NameSuggestion>.of(widget.suggestions);
    _controller.addListener(() {
      final String value = _controller.text.trim().toLowerCase();
      final bool matchesSelected =
          _selectedSuggestionName != null &&
          _selectedSuggestionName!.toLowerCase() == value;
      if (!matchesSelected) {
        _selectedSuggestionName = null;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: widget.hintText),
            ),
            if (_suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Previous names:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _suggestions.map((NameSuggestion suggestion) {
                      return InputChip(
                        avatar: CircleAvatar(
                          radius: 8,
                          backgroundColor: suggestion.backgroundColor,
                        ),
                        label: Text(suggestion.name),
                        onPressed: () {
                          _selectedSuggestionName = suggestion.name;
                          _controller.text = suggestion.name;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: suggestion.name.length),
                          );
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () async {
                          if (widget.onDeleteSuggestion != null) {
                            await widget.onDeleteSuggestion!(suggestion.name);
                          }
                          setState(() {
                            _suggestions = _suggestions
                                .where(
                                  (NameSuggestion s) =>
                                      s.name != suggestion.name,
                                )
                                .toList();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const EditTextResult(value: '')),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () {
            Color? selectedBackgroundColor;
            final String trimmed = _controller.text.trim();
            for (final NameSuggestion suggestion in _suggestions) {
              if (suggestion.name.toLowerCase() == trimmed.toLowerCase()) {
                selectedBackgroundColor = suggestion.backgroundColor;
                break;
              }
            }

            Navigator.of(context).pop(
              EditTextResult(
                value: _controller.text,
                selectedBackgroundColor: selectedBackgroundColor,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EditTextResult {
  const EditTextResult({required this.value, this.selectedBackgroundColor});

  final String value;
  final Color? selectedBackgroundColor;
}
