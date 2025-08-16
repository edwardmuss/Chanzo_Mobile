import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import '../globalclass/chanzo_color.dart';

class ReusableBottomSheet {
  static void show({
    required BuildContext context,
    required String title,
    required List<BottomSheetButton> buttons,
    String cancelText = 'Cancel',
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heading
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Buttons Column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: buttons
                    .map(
                      (button) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildButton(
                      context: context,
                      icon: button.icon,
                      title: button.title,
                      onTap: button.onTap,
                      isCancel: false,
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Cancel Button (centered text)
              _buildCancelButton(
                context: context,
                title: cancelText,
                onTap: () => Navigator.pop(context),
              ),

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isCancel,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isCancel
            ? ChanzoColors.secondary
            : (isDarkMode ? Colors.grey[850] : Colors.transparent),
        foregroundColor: isCancel
            ? Colors.white
            : (isDarkMode ? Colors.white70 : ChanzoColors.textgrey),
        side: BorderSide(
          color: isCancel
              ? Colors.transparent
              : (isDarkMode ? Colors.white24 : ChanzoColors.secondary),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  static Widget _buildCancelButton({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: ChanzoColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide(
          color: ChanzoColors.secondary,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BottomSheetButton {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  BottomSheetButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
