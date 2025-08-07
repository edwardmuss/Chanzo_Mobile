import 'package:flutter/services.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:flutter/material.dart';

class KiotaPayMythemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          color: Colors.black,
        )),
    brightness: Brightness.light,
    primaryColor: ChanzoColors.primary,
    //primarySwatch: ChanzoColors.primary,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
        color: ChanzoColors.primary,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)),
    cardTheme: CardThemeData(
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.black87,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Colors.black,
        // fontFamily: 'WorkSans',
      ),
      displayMedium: TextStyle(
        color: Colors.black,
        // fontFamily: 'WorkSans',
      ),
      displaySmall: TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        // fontFamily: 'WorkSans',
      ),
      headlineLarge: TextStyle(
        color: Colors.black87,
        // fontFamily: 'WorkSans',
      ),
      headlineMedium: TextStyle(
        color: Colors.black87,
        // fontFamily: 'WorkSans',
      ),
      headlineSmall: TextStyle(
        color: Colors.black87,
        fontSize: 20.0,
        // fontFamily: 'WorkSans',
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        // fontFamily: 'WorkSans',
      ),
      bodyLarge: TextStyle(
        color: Colors.black87,
        // fontFamily: 'WorkSans',
      ),
      bodyMedium: TextStyle(
        color: Colors.black87,
        fontSize: 18.0,
        // fontFamily: 'WorkSans',
      ),
      bodySmall: TextStyle(
        color: Colors.black54,
        // fontFamily: 'WorkSans',
      ),
      labelLarge: TextStyle(
        color: Colors.black,
        // fontFamily: 'WorkSans',
      ),
      labelMedium: TextStyle(
        color: Colors.black54,
        // fontFamily: 'WorkSans',
      ),
      labelSmall: TextStyle(
        color: Colors.black54,
        // fontFamily: 'WorkSans',
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: ChanzoColors.primary,
      secondaryContainer: ChanzoColors.textfield,
      onSecondaryContainer: Colors.black, // Icon color
    ),
  );

  static final darkTheme = ThemeData(
    //scaffoldBackgroundColor: ChanzoColors.grey_90,
    //primaryColor: ChanzoColors.grey_90,
    brightness: Brightness.dark,
    dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          color: Colors.white,
        )),
    bottomSheetTheme: BottomSheetThemeData(
      //backgroundColor: ChanzoColors.grey_90,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ChanzoColors.lightblack,
    ),
    bottomAppBarTheme: BottomAppBarTheme(color: ChanzoColors.lightblack),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: ChanzoColors.transparent,
        statusBarIconBrightness:
        Brightness.light, //<-- For Android (dark icons)
        statusBarBrightness: Brightness.light, //<-- For iOS (dark icons)
      ),
      color: Colors.transparent,
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    dividerColor: Colors.grey.shade800,
    cardColor: ChanzoColors.bgdark,
    //bottomAppBarTheme: BottomAppBarTheme(color: ChanzoColors.grey_90),
    cardTheme: CardThemeData(
      //color: ChanzoColors.grey_80,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        // headline1
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      displayMedium: TextStyle(
        // headline2
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      displaySmall: TextStyle(
        // headline3
        color: Colors.white,
        fontSize: 20.0,
        // fontFamily: 'WorkSans',
      ),
      headlineLarge: TextStyle(
        // headline4
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      headlineMedium: TextStyle(
        // headline5
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      headlineSmall: TextStyle(
        // headline6
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      titleMedium: TextStyle(
        // subtitle1
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      bodyLarge: TextStyle(
        // bodyText1
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      bodyMedium: TextStyle(
        // bodyText2 / subtitle2
        color: Colors.white,
        fontSize: 18.0,
        // fontFamily: 'WorkSans',
      ),
      bodySmall: TextStyle(
        // caption or smaller text
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      labelLarge: TextStyle(
        // button
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      labelMedium: TextStyle(
        // caption
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
      labelSmall: TextStyle(
        // overline
        color: Colors.white,
        // fontFamily: 'WorkSans',
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: ChanzoColors.secondary,
      secondaryContainer: Colors.white24,
      onSecondaryContainer: Colors.white, // Icon color
    ),
  );
}
