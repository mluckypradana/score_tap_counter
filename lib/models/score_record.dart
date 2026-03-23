import 'package:flutter/material.dart';

class ScoreRecord {
  const ScoreRecord({
    required this.type,
    required this.timestamp,
    required this.leftScore,
    required this.rightScore,
    required this.leftBgColor,
    required this.rightBgColor,
    required this.fontColor,
    required this.leftPlayerName,
    required this.rightPlayerName,
    required this.showRightSide,
    this.duration,
  });

  factory ScoreRecord.fromJson(Map<String, dynamic> json) {
    final int? durationSecs = json['durationSeconds'] as int?;
    return ScoreRecord(
      type: json['type'] as String? ?? 'history',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      leftScore: json['leftScore'] as int? ?? 0,
      rightScore: json['rightScore'] as int? ?? 0,
      leftBgColor: Color(json['leftBgColor'] as int? ?? 0xFF1976D2),
      rightBgColor: Color(json['rightBgColor'] as int? ?? 0xFFF57C00),
      fontColor: Color(json['fontColor'] as int? ?? 0xFFFFFFFF),
      leftPlayerName: json['leftPlayerName'] as String? ?? '',
      rightPlayerName: json['rightPlayerName'] as String? ?? '',
      showRightSide: json['showRightSide'] as bool? ?? true,
      duration: durationSecs != null ? Duration(seconds: durationSecs) : null,
    );
  }

  final String type;
  final DateTime timestamp;
  final int leftScore;
  final int rightScore;
  final Color leftBgColor;
  final Color rightBgColor;
  final Color fontColor;
  final String leftPlayerName;
  final String rightPlayerName;
  final bool showRightSide;
  final Duration? duration;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'leftScore': leftScore,
      'rightScore': rightScore,
      'leftBgColor': leftBgColor.toARGB32(),
      'rightBgColor': rightBgColor.toARGB32(),
      'fontColor': fontColor.toARGB32(),
      'leftPlayerName': leftPlayerName,
      'rightPlayerName': rightPlayerName,
      'showRightSide': showRightSide,
      if (duration != null) 'durationSeconds': duration!.inSeconds,
    };
  }
}
