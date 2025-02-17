import 'package:flutter/material.dart';
import 'colors.dart';

class PreciousWeightTheme {}

class MyButtonStyles {
  static var color = WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) return white;
      return strongOrange;
    });

  static var bkg = WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) return strongOrange;
      return white;
    });

  static ButtonStyle whiteDefaultPurplePressed = ButtonStyle(
    foregroundColor: color,
    backgroundColor: bkg
  );
}
