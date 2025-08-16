import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:get/get.dart';

class RoundedIconButtonWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final Color splashColor;
  final Color labelColor;
  final double borderRadius;
  final double spacing;

  const RoundedIconButtonWithLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundColor = const Color(0xFFE0F2FE),
    this.iconColor = const Color(0xFF0C4A6E),
    this.splashColor = const Color(0xFF0369A1),
    this.labelColor = const Color(0xFF6B7280),
    this.borderRadius = 12,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Material(
            color: backgroundColor,
            child: InkWell(
              splashColor: splashColor,
              onTap: onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          label.tr,
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}