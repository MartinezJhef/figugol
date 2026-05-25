import 'package:flutter/material.dart';

enum FigugolActionButtonStyle { primary, secondary }

class FigugolActionButton extends StatelessWidget {
  const FigugolActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = FigugolActionButtonStyle.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FigugolActionButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return switch (style) {
      FigugolActionButtonStyle.primary => ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
      FigugolActionButtonStyle.secondary => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
    };
  }
}
