import 'package:flutter/material.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';

class GridCard extends StatelessWidget {
  final String title;
  final String param;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final double? iconSize;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GridCard({
    Key? key,
    required this.title,
    required this.param,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = ChanzoColors.primary,
    this.unselectedColor = Colors.white,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = ChanzoColors.primary,
    this.iconSize = 24,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(borderRadius ?? 12);
    final defaultPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: defaultBorderRadius,
      child: Container(

        decoration: BoxDecoration(
          color: isSelected
              ? (selectedColor ?? colorScheme.primary.withOpacity(0.1))
              : (unselectedColor ?? Colors.transparent),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? colorScheme.primary)
                : colorScheme.outline, // adapts to dark/light mode
            width: 1.5,
          ),
          borderRadius: defaultBorderRadius,
        ),
        padding: defaultPadding,
        child: Row(
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected
                  ? (selectedIconColor ?? colorScheme.primary)
                  : (unselectedIconColor ?? colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (selectedTextColor ?? colorScheme.primary)
                    : (unselectedTextColor ?? colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

}