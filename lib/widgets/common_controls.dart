import 'package:flutter/material.dart';

class OverlayActionButton extends StatelessWidget {
  const OverlayActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// When true, renders as an icon-only button with a tooltip (saves horizontal space).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: label,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.6)),
            backgroundColor: Colors.black.withValues(alpha: 0.14),
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.all(10),
          ),
          onPressed: onPressed,
          child: Icon(icon, color: color, size: 22),
        ),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        backgroundColor: Colors.black.withValues(alpha: 0.14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  final Color currentColor;
  final Function(Color) onColorChanged;

  @override
  Widget build(BuildContext context) {
    final List<Color> colorOptions = <Color>[
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
      Colors.grey,
      Colors.black,
      Colors.white,
      Colors.red.shade100,
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.green.shade100,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colorOptions.map((Color color) {
        final bool isSelected = color.toString() == currentColor.toString();
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }).toList(),
    );
  }
}
