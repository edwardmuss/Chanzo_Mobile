import 'package:flutter/material.dart';
import 'package:chanzo/globalclass/chanzo_color.dart';
import 'package:chanzo/globalclass/kiotapay_fontstyle.dart';

class TextIconButton extends StatelessWidget {
  const TextIconButton({
    super.key,
    this.onPressed,
    required this.label,
    required this.icon,
    this.leftIcon,
    this.splashColor,
    this.color,
    this.trailingText,
    this.size,
    this.iconSize,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final IconData? leftIcon; // Note: This is used as the trailing (right) icon in your Wrap
  final String label;
  final Color? splashColor;
  final Color? color;
  final String? trailingText;
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    // Detect if the app is currently in Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Set dynamic default colors based on the theme
    final Color defaultIconBg = isDark ? Colors.white12 : ChanzoColors.primary20;
    // Orange for dark mode, Primary for light mode
    final Color defaultIconColor = isDark ? ChanzoColors.secondary : ChanzoColors.primary;
    final Color defaultChevronColor = isDark ? Colors.white54 : ChanzoColors.primary;
    final Color defaultTextColor = isDark ? Colors.white : ChanzoColors.textgrey;
    final Color defaultSplashColor = isDark ? ChanzoColors.secondary.withOpacity(0.3) : ChanzoColors.primary;

    return ListTile(
      onTap: onPressed,
      leading: ClipOval(
        child: Material(
          color: splashColor ?? defaultIconBg,
          child: InkWell(
            splashColor: defaultSplashColor,
            onTap: onPressed,
            child: SizedBox(
              width: size ?? 40,
              height: size ?? 40,
              child: Icon(
                icon,
                size: iconSize ?? 20,
                color: color ?? defaultIconColor,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: pregular_md.copyWith(color: defaultTextColor),
      ),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: <Widget>[
          if (trailingText != null)
            Text(
              trailingText!,
              style: pregular_sm.copyWith(color: isDark ? Colors.white70 : ChanzoColors.textgrey),
            ),
          Icon(
            leftIcon ?? Icons.chevron_right,
            size: 20,
            color: defaultChevronColor, // Muted in dark mode so it doesn't distract
          ),
        ],
      ),
    );
  }
}