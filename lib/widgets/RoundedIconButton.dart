import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final Color splashColor;
  final double borderRadius;
  final VoidCallback onPressed;

  const RoundedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.backgroundColor = const Color(0xFFE0F2FE),
    this.iconColor = const Color(0xFF0C4A6E),
    this.splashColor = const Color(0xFF0369A1),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          splashColor: splashColor,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size * 1.5,
            height: size * 1.5,
            child: Icon(
              icon,
              size: size,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}