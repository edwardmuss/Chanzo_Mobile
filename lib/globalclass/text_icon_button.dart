import 'package:flutter/material.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';

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
    this.size, this.iconSize,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final IconData? leftIcon;
  final String label;
  final Color? splashColor;
  final Color? color;
  final String? trailingText;
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
      onTap: onPressed,
      leading: ClipOval(
        child: Material(
          color: splashColor ?? ChanzoColors.primary20, // Button color
          child: InkWell(
            splashColor: ChanzoColors.primary, // Splash color
            onTap: onPressed,
            child: SizedBox(
              width: size ?? 50,
              height: size ?? 50,
              child: Icon(
                icon,
                size: iconSize ?? 20,
                color: color ?? ChanzoColors.primary,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: pregular_md.copyWith(color: ChanzoColors.textgrey),
      ),
      trailing: Wrap(
        spacing: 12, // space between two icons
        children: <Widget>[
          Text(
            trailingText ?? '',
            style: pregular_sm.copyWith(color: ChanzoColors.textgrey),
          ),
          Icon(
            leftIcon,
            size: 20,
            color: ChanzoColors.primary,
          ),
        ],
      ),
    );
  }
}
