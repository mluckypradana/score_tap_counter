import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/counter_settings.dart';
import 'models/name_suggestion.dart';
import 'models/score_record.dart';
import 'pages/records_page.dart';
import 'widgets/common_controls.dart';
import 'widgets/dialogs.dart';
import 'widgets/score_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Tap Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const SportCounterPage(),
    );
  }
}

class SportCounterPage extends StatefulWidget {
  const SportCounterPage({super.key});

  @override
  State<SportCounterPage> createState() => _SportCounterPageState();
}

class _SportCounterPageState extends State<SportCounterPage> {
  static const double _swipeDistanceThreshold = 60;
  static const String _leftBgColorKey = 'left_bg_color';
  static const String _rightBgColorKey = 'right_bg_color';
  static const String _fontSizeKey = 'font_size';
  static const String _fontColorKey = 'font_color';
  static const String _showRightSideKey = 'show_right_side';
  static const String _leftPlayerNameKey = 'left_player_name';
  static const String _rightPlayerNameKey = 'right_player_name';
  static const String _isVerticalLayoutKey = 'is_vertical_layout';
  static const String _historyKey = 'score_history';
  static const String _savedScoresKey = 'saved_scores';
  static const String _playerSuggestionsKey = 'player_name_suggestions';
  static const Color _defaultLeftBgColor = Color(0xFF1976D2);
  static const Color _defaultRightBgColor = Color(0xFFF57C00);

  final FocusNode _keyboardFocusNode = FocusNode();
  Offset? _panStartPosition;
  Offset? _panCurrentPosition;

  int _leftScore = 0;
  int _rightScore = 0;
  bool _showRightSide = true;
  bool _isVerticalLayout = false;
  String _leftPlayerName = '';
  String _rightPlayerName = '';
  List<ScoreRecord> _historyRecords = <ScoreRecord>[];
  List<ScoreRecord> _savedRecords = <ScoreRecord>[];
  List<NameSuggestion> _playerSuggestions = <NameSuggestion>[];

  // Settings
  Color _leftBgColor = _defaultLeftBgColor;
  Color _rightBgColor = _defaultRightBgColor;
  double _fontSize = 24.0;
  Color _fontColor = Colors.white;

  // Match timer – starts on first score change, resets on score reset
  DateTime? _matchStartTime;
  Timer? _matchTicker;

  // UI state
  bool _showButtons = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _leftBgColor = Color(
        prefs.getInt(_leftBgColorKey) ?? _defaultLeftBgColor.toARGB32(),
      );
      _rightBgColor = Color(
        prefs.getInt(_rightBgColorKey) ?? _defaultRightBgColor.toARGB32(),
      );
      _fontSize = prefs.getDouble(_fontSizeKey) ?? 24.0;
      _fontColor = Color(
        prefs.getInt(_fontColorKey) ?? Colors.white.toARGB32(),
      );
      _showRightSide = prefs.getBool(_showRightSideKey) ?? true;
      _isVerticalLayout = prefs.getBool(_isVerticalLayoutKey) ?? false;
      _leftPlayerName = prefs.getString(_leftPlayerNameKey) ?? '';
      _rightPlayerName = prefs.getString(_rightPlayerNameKey) ?? '';
      _historyRecords = _decodeRecords(prefs.getString(_historyKey));
      _savedRecords = _decodeRecords(prefs.getString(_savedScoresKey));
      final String? suggestionsRaw = prefs.getString(_playerSuggestionsKey);
      if (suggestionsRaw != null && suggestionsRaw.isNotEmpty) {
        final Object? decoded = jsonDecode(suggestionsRaw);
        if (decoded is List<dynamic>) {
          _playerSuggestions = decoded
              .whereType<Map<String, dynamic>>()
              .map(NameSuggestion.fromJson)
              .toList();
        }
      }
    });

    await _applyOrientationLock();
  }

  Future<void> _applyOrientationLock() async {
    if (_isVerticalLayout) {
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return;
    }

    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_leftBgColorKey, _leftBgColor.toARGB32());
    await prefs.setInt(_rightBgColorKey, _rightBgColor.toARGB32());
    await prefs.setDouble(_fontSizeKey, _fontSize);
    await prefs.setInt(_fontColorKey, _fontColor.toARGB32());
    await prefs.setBool(_showRightSideKey, _showRightSide);
    await prefs.setBool(_isVerticalLayoutKey, _isVerticalLayout);
    await prefs.setString(_leftPlayerNameKey, _leftPlayerName);
    await prefs.setString(_rightPlayerNameKey, _rightPlayerName);
  }

  Future<void> _addPlayerSuggestion(String name, Color backgroundColor) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final int existingIndex = _playerSuggestions.indexWhere(
      (NameSuggestion s) => s.name.toLowerCase() == trimmed.toLowerCase(),
    );
    final NameSuggestion updated = NameSuggestion(
      name: trimmed,
      backgroundColor: backgroundColor,
    );

    setState(() {
      if (existingIndex >= 0) {
        final List<NameSuggestion> next = List<NameSuggestion>.of(
          _playerSuggestions,
        )..removeAt(existingIndex);
        _playerSuggestions = <NameSuggestion>[updated, ...next];
      } else {
        _playerSuggestions = <NameSuggestion>[updated, ..._playerSuggestions];
      }
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playerSuggestionsKey,
      jsonEncode(
        _playerSuggestions
            .map((NameSuggestion suggestion) => suggestion.toJson())
            .toList(),
      ),
    );
  }

  Future<void> _deletePlayerSuggestion(String name) async {
    setState(() {
      _playerSuggestions = _playerSuggestions
          .where((NameSuggestion s) => s.name != name)
          .toList();
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playerSuggestionsKey,
      jsonEncode(
        _playerSuggestions
            .map((NameSuggestion suggestion) => suggestion.toJson())
            .toList(),
      ),
    );
  }

  List<ScoreRecord> _decodeRecords(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) {
      return <ScoreRecord>[];
    }

    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! List<dynamic>) {
      return <ScoreRecord>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ScoreRecord.fromJson)
        .toList();
  }

  Future<void> _saveRecordLists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(
        _historyRecords.map((ScoreRecord record) => record.toJson()).toList(),
      ),
    );
    await prefs.setString(
      _savedScoresKey,
      jsonEncode(
        _savedRecords.map((ScoreRecord record) => record.toJson()).toList(),
      ),
    );
  }

  Duration _currentMatchDuration() {
    if (_matchStartTime == null) return Duration.zero;
    return DateTime.now().difference(_matchStartTime!);
  }

  String _matchDurationLabel() {
    final Duration d = _currentMatchDuration();
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startMatchTimer() {
    _matchStartTime ??= DateTime.now();
    _matchTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_matchStartTime == null) return;
      setState(() {});
    });
  }

  Future<void> _toggleLayoutOrientation() async {
    setState(() {
      _isVerticalLayout = !_isVerticalLayout;
    });
    await _applyOrientationLock();
    await _saveSettings();
  }

  Widget _buildSoloTimerWidget() {
    if (_matchStartTime == null) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: _fontColor,
          side: BorderSide(color: _fontColor.withValues(alpha: 0.7)),
          backgroundColor: Colors.black.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () {
          setState(() {
            _startMatchTimer();
          });
        },
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('Start Timer'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fontColor.withValues(alpha: 0.7)),
      ),
      child: Text(
        _matchDurationLabel(),
        style: TextStyle(color: _fontColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  ScoreRecord _buildRecord({required String type}) {
    return ScoreRecord(
      type: type,
      timestamp: DateTime.now(),
      leftScore: _leftScore,
      rightScore: _rightScore,
      leftBgColor: _leftBgColor,
      rightBgColor: _rightBgColor,
      fontColor: _fontColor,
      leftPlayerName: _leftPlayerName,
      rightPlayerName: _rightPlayerName,
      showRightSide: _showRightSide,
      duration: _currentMatchDuration(),
    );
  }

  Future<void> _saveCurrentScore() async {
    if (_leftScore == 0 && _rightScore == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to save — scores are 0–0.')),
        );
      }
      return;
    }
    setState(() {
      _savedRecords = <ScoreRecord>[
        _buildRecord(type: 'saved'),
        ..._savedRecords,
      ];
    });
    await _saveRecordLists();
    if (_leftPlayerName.trim().isNotEmpty) {
      await _addPlayerSuggestion(_leftPlayerName, _leftBgColor);
    }
    if (_rightPlayerName.trim().isNotEmpty) {
      await _addPlayerSuggestion(_rightPlayerName, _rightBgColor);
    }
  }

  Future<void> _openHistoryPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => RecordsPage(
          historyRecords: _historyRecords,
          savedRecords: _savedRecords,
          fontColor: _fontColor,
          onRecordsChanged: (List<ScoreRecord> h, List<ScoreRecord> s) async {
            setState(() {
              _historyRecords = h;
              _savedRecords = s;
            });
            await _saveRecordLists();
          },
          onContinueMatch: (ScoreRecord record) {
            setState(() {
              _leftScore = record.leftScore;
              _rightScore = record.rightScore;
              _leftBgColor = record.leftBgColor;
              _rightBgColor = record.rightBgColor;
              _fontColor = record.fontColor;
              _leftPlayerName = record.leftPlayerName;
              _rightPlayerName = record.rightPlayerName;
              _showRightSide = record.showRightSide;
              _matchStartTime = null;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _editPlayerName({required bool isLeft}) async {
    final String currentValue = isLeft ? _leftPlayerName : _rightPlayerName;
    final String sideLabel = isLeft ? 'Left Player' : 'Right Player';

    final EditTextResult? result = await showDialog<EditTextResult>(
      context: context,
      builder: (BuildContext context) {
        return EditTextDialog(
          title: sideLabel,
          hintText: 'Enter player name',
          initialValue: currentValue,
          suggestions: _playerSuggestions,
          onDeleteSuggestion: _deletePlayerSuggestion,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final String newValue = result.value.trim();
      if (isLeft) {
        _leftPlayerName = newValue;
        if (result.selectedBackgroundColor != null) {
          _leftBgColor = result.selectedBackgroundColor!;
        }
      } else {
        _rightPlayerName = newValue;
        if (result.selectedBackgroundColor != null) {
          _rightBgColor = result.selectedBackgroundColor!;
        }
      }
    });

    if (isLeft && _leftPlayerName.isNotEmpty) {
      await _addPlayerSuggestion(_leftPlayerName, _leftBgColor);
    }
    if (!isLeft && _rightPlayerName.isNotEmpty) {
      await _addPlayerSuggestion(_rightPlayerName, _rightBgColor);
    }

    await _saveSettings();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _matchTicker?.cancel();
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _incrementLeft() {
    _startMatchTimer();
    setState(() {
      _leftScore += 1;
    });
  }

  void _incrementRight() {
    _startMatchTimer();
    setState(() {
      _rightScore += 1;
    });
  }

  void _swapScores() {
    setState(() {
      final int temp = _leftScore;
      _leftScore = _rightScore;
      _rightScore = temp;

      final Color tempColor = _leftBgColor;
      _leftBgColor = _rightBgColor;
      _rightBgColor = tempColor;

      final String tempName = _leftPlayerName;
      _leftPlayerName = _rightPlayerName;
      _rightPlayerName = tempName;
    });
    _saveSettings();
  }

  Future<void> _resetScores() async {
    final bool hasScore = _leftScore != 0 || _rightScore != 0;
    setState(() {
      if (hasScore) {
        _historyRecords = <ScoreRecord>[
          _buildRecord(type: 'history'),
          ..._historyRecords,
        ];
      }
      _leftScore = 0;
      _rightScore = 0;
      _matchStartTime = null;
    });
    if (hasScore) {
      await _saveRecordLists();
      if (_leftPlayerName.trim().isNotEmpty) {
        await _addPlayerSuggestion(_leftPlayerName, _leftBgColor);
      }
      if (_rightPlayerName.trim().isNotEmpty) {
        await _addPlayerSuggestion(_rightPlayerName, _rightBgColor);
      }
    }
  }

  Future<void> _toggleRightSideVisibility() async {
    setState(() {
      _showRightSide = !_showRightSide;
    });
    await _saveSettings();
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Swipe Gestures'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Text(
                'Horizontal layout:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Swipe left → right  =  +Left score'),
              Text('• Swipe right → left  =  +Right score'),
              Text('• Swipe up  =  Reset scores'),
              Text('• Swipe down  =  Switch scores'),
              SizedBox(height: 14),
              Text(
                'Vertical layout:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Swipe bottom → top  =  +Bottom score'),
              Text('• Swipe top → bottom  =  +Top score'),
              Text('• Swipe right → left  =  Switch scores'),
              Text('• Swipe left → right  =  Reset scores'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSettings() async {
    final CounterSettings? result = await showDialog<CounterSettings>(
      context: context,
      builder: (BuildContext context) {
        return SettingsDialog(
          leftBgColor: _leftBgColor,
          rightBgColor: _rightBgColor,
          fontSize: _fontSize,
          fontColor: _fontColor,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _leftBgColor = result.leftBgColor;
      _rightBgColor = result.rightBgColor;
      _fontSize = result.fontSize;
      _fontColor = result.fontColor;
    });
    _saveSettings();
  }

  Future<void> _editScore({required bool isLeft}) async {
    final int currentValue = isLeft ? _leftScore : _rightScore;

    final int? newValue = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return EditScoreDialog(
          title: isLeft ? 'Edit Left Score' : 'Edit Right Score',
          initialValue: currentValue,
        );
      },
    );

    if (newValue == null) {
      return;
    }

    _startMatchTimer();
    setState(() {
      if (isLeft) {
        _leftScore = newValue;
      } else {
        _rightScore = newValue;
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
      _incrementLeft();
      return;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _panStartPosition = details.globalPosition;
    _panCurrentPosition = details.globalPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    final Offset? startPosition = _panStartPosition;
    final Offset? endPosition = _panCurrentPosition;
    _panStartPosition = null;
    _panCurrentPosition = null;

    if (startPosition == null || endPosition == null) {
      return;
    }

    _handleSwipeFromPoints(startPosition, endPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _panCurrentPosition = details.globalPosition;
  }

  void _onPanCancel() {
    _panStartPosition = null;
    _panCurrentPosition = null;
  }

  void _handleSwipeFromPoints(Offset startPosition, Offset endPosition) {
    final double deltaX = endPosition.dx - startPosition.dx;
    final double deltaY = endPosition.dy - startPosition.dy;

    if (_isVerticalLayout) {
      if (deltaY.abs() >= deltaX.abs()) {
        if (deltaY < -_swipeDistanceThreshold) {
          // Bottom to top = increment bottom side
          if (_showRightSide) {
            _incrementRight();
          } else {
            _incrementLeft();
          }
        } else if (deltaY > _swipeDistanceThreshold) {
          // Top to bottom = increment top side
          _incrementLeft();
        }
        return;
      }

      if (deltaX < -_swipeDistanceThreshold) {
        _swapScores();
      } else if (deltaX > _swipeDistanceThreshold) {
        _resetScores();
      }
      return;
    }

    if (deltaX.abs() >= deltaY.abs()) {
      if (deltaX > _swipeDistanceThreshold) {
        _incrementLeft();
      } else if (deltaX < -_swipeDistanceThreshold) {
        _incrementRight();
      }
      return;
    }

    if (deltaY < -_swipeDistanceThreshold) {
      _resetScores();
    } else if (deltaY > _swipeDistanceThreshold) {
      _swapScores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: Stack(
            children: <Widget>[
              _isVerticalLayout
                  ? Column(
                      children: <Widget>[
                        Expanded(
                          child: ScorePanel(
                            playerName: _leftPlayerName,
                            score: _leftScore,
                            color: _leftBgColor,
                            fontSize: _fontSize,
                            fontColor: _fontColor,
                            onTap: _incrementLeft,
                            onEditScore: () => _editScore(isLeft: true),
                            onEditName: () => _editPlayerName(isLeft: true),
                            footer: !_showRightSide
                                ? _buildSoloTimerWidget()
                                : null,
                            nameAtLeft: true,
                          ),
                        ),
                        if (_showRightSide)
                          Expanded(
                            child: ScorePanel(
                              playerName: _rightPlayerName,
                              score: _rightScore,
                              color: _rightBgColor,
                              fontSize: _fontSize,
                              fontColor: _fontColor,
                              onTap: _incrementRight,
                              onEditScore: () => _editScore(isLeft: false),
                              onEditName: () => _editPlayerName(isLeft: false),
                              nameAtLeft: false,
                            ),
                          ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: ScorePanel(
                            playerName: _leftPlayerName,
                            score: _leftScore,
                            color: _leftBgColor,
                            fontSize: _fontSize,
                            fontColor: _fontColor,
                            onTap: _incrementLeft,
                            onEditScore: () => _editScore(isLeft: true),
                            onEditName: () => _editPlayerName(isLeft: true),
                            footer: !_showRightSide
                                ? _buildSoloTimerWidget()
                                : null,
                            nameAtLeft: true,
                          ),
                        ),
                        if (_showRightSide)
                          Expanded(
                            child: ScorePanel(
                              playerName: _rightPlayerName,
                              score: _rightScore,
                              color: _rightBgColor,
                              fontSize: _fontSize,
                              fontColor: _fontColor,
                              onTap: _incrementRight,
                              onEditScore: () => _editScore(isLeft: false),
                              onEditName: () => _editPlayerName(isLeft: false),
                              nameAtLeft: false,
                            ),
                          ),
                      ],
                    ),
              SafeArea(
                child: Stack(
                  children: <Widget>[
                    // Always-visible toggle — top-right corner (above the top bar)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Tooltip(
                          message: _showButtons
                              ? 'Hide buttons'
                              : 'Show buttons',
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: _fontColor,
                              side: BorderSide(
                                color: _fontColor.withValues(alpha: 0.6),
                              ),
                            ),
                            icon: Icon(
                              _showButtons
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _showButtons = !_showButtons),
                          ),
                        ),
                      ),
                    ),
                    // Top action buttons — Settings, History, Solo Mode, Layout
                    if (_showButtons)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 56, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              OverlayActionButton(
                                icon: Icons.settings,
                                label: 'Settings',
                                color: _fontColor,
                                onPressed: _openSettings,
                              ),
                              OverlayActionButton(
                                icon: Icons.history,
                                label: 'History',
                                color: _fontColor,
                                onPressed: _openHistoryPage,
                              ),
                              OverlayActionButton(
                                icon: _showRightSide
                                    ? Icons.person_outline
                                    : Icons.people_alt_outlined,
                                label: _showRightSide
                                    ? 'Solo Mode'
                                    : 'Versus Mode',
                                color: _fontColor,
                                onPressed: _toggleRightSideVisibility,
                              ),
                              OverlayActionButton(
                                icon: _isVerticalLayout
                                    ? Icons.view_week_outlined
                                    : Icons.view_stream_outlined,
                                label: _isVerticalLayout
                                    ? 'Horizontal Layout'
                                    : 'Vertical Layout',
                                color: _fontColor,
                                onPressed: _toggleLayoutOrientation,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Bottom action buttons — Save, Switch, Reset, Help
                    if (_showButtons)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              OverlayActionButton(
                                icon: Icons.bookmark_add_outlined,
                                label: 'Save',
                                color: _fontColor,
                                onPressed: _saveCurrentScore,
                              ),
                              OverlayActionButton(
                                icon: Icons.swap_horiz,
                                label: 'Switch',
                                color: _fontColor,
                                onPressed: _swapScores,
                              ),
                              OverlayActionButton(
                                icon: Icons.restart_alt,
                                label: 'Reset',
                                color: _fontColor,
                                onPressed: _resetScores,
                              ),
                              OverlayActionButton(
                                icon: Icons.help_outline,
                                label: 'Help',
                                color: _fontColor,
                                onPressed: _showHelpDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_showRightSide)
                Center(
                  child: _matchStartTime == null
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _fontColor,
                            side: BorderSide(
                              color: _fontColor.withValues(alpha: 0.7),
                            ),
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _startMatchTimer();
                            });
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Match Timer'),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _fontColor.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Text(
                            _matchDurationLabel(),
                            style: TextStyle(
                              color: _fontColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
