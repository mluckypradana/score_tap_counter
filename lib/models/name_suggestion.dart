import 'package:flutter/material.dart';

class NameSuggestion {
  const NameSuggestion({required this.name, required this.backgroundColor});

  factory NameSuggestion.fromJson(Map<String, dynamic> json) {
    return NameSuggestion(
      name: json['name'] as String? ?? '',
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFF1976D2),
    );
  }

  final String name;
  final Color backgroundColor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'backgroundColor': backgroundColor.toARGB32(),
    };
  }
}
