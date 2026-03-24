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
    this.nameAtLeft = true,
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
  final bool nameAtLeft;

  @override
  Widget build(BuildContext context) {
    final bool hasName = playerName.trim().isNotEmpty;
    final double reservedBottomSpace = footer != null ? 86 : 28;

    final Widget nameWidget = hasName
        ? GestureDetector(
            onTap: onEditName,
            child: Text(
              playerName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: nameAtLeft ? TextAlign.left : TextAlign.right,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                side: BorderSide(color: fontColor.withValues(alpha: 0.6)),
                backgroundColor: Colors.black.withValues(alpha: 0.18),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(10),
              ),
              onPressed: onEditName,
              child: Icon(Icons.person_add_alt_1, color: fontColor, size: 26),
            ),
          );

    final Widget editButton = Tooltip(
      message: 'Edit score',
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: fontColor,
          side: BorderSide(color: fontColor.withValues(alpha: 0.6)),
          backgroundColor: Colors.black.withValues(alpha: 0.18),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(10),
        ),
        onPressed: onEditScore,
        child: Icon(Icons.edit, color: fontColor, size: 22),
      ),
    );

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: <Widget>[
            // Score + player name — centered with extra breathing room.
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, reservedBottomSpace),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      score.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 3.6,
                        fontWeight: FontWeight.bold,
                        color: fontColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: nameWidget,
                    ),
                  ],
                ),
              ),
            ),
            // Edit button — corner (horizontally), middle (vertically)
            Align(
              alignment: nameAtLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: editButton,
              ),
            ),
            // Footer — pinned to bottom center
            if (footer != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: footer!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
