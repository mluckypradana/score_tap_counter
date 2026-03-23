import 'package:flutter/material.dart';

class CounterSettings {
  const CounterSettings({
    required this.leftBgColor,
    required this.rightBgColor,
    required this.fontSize,
    required this.fontColor,
  });

  final Color leftBgColor;
  final Color rightBgColor;
  final double fontSize;
  final Color fontColor;
}
