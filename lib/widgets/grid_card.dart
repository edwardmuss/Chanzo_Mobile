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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius!),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          border: Border.all(
            color: isSelected
                ? selectedColor ?? ChanzoColors.primary
                : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderRadius!),
        ),
        child: Padding(
          padding: padding!,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isSelected ? selectedIconColor : unselectedIconColor,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}