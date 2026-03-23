import 'package:flutter/material.dart';

class ScorePanel extends StatelessWidget {
  const ScorePanel({
    super.key,
    required this.playerName,
    required this.score,
    required this.color,
    required this.fontSize,
    required this.fontColor,
    required this.onTap,
    required this.onEditScore,
    required this.onEditName,
    this.footer,
  });

  final String playerName;
  final int score;
  final Color color;
  final double fontSize;
  final Color fontColor;
  final VoidCallback onTap;
  final VoidCallback onEditScore;
  final VoidCallback onEditName;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final bool hasName = playerName.trim().isNotEmpty;

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: hasName
                    ? GestureDetector(
                        onTap: onEditName,
                        child: Text(
                          playerName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: fontColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      )
                    : Tooltip(
                        message: 'Add player name',
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: fontColor,
                            side: BorderSide(
                              color: fontColor.withValues(alpha: 0.6),
                            ),
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.14,
                            ),
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.all(10),
                          ),
                          onPressed: onEditName,
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: fontColor,
                            size: 26,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize * 3.6,
                fontWeight: FontWeight.bold,
                color: fontColor,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Tooltip(
                message: 'Edit score',
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fontColor,
                    side: BorderSide(color: fontColor.withValues(alpha: 0.6)),
                    backgroundColor: Colors.black.withValues(alpha: 0.14),
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: onEditScore,
                  child: Icon(Icons.edit, color: fontColor, size: 22),
                ),
              ),
            ),
            if (footer != null) ...<Widget>[
              const SizedBox(height: 10),
              Center(child: footer),
            ],
          ],
        ),
      ),
    );
  }
}
