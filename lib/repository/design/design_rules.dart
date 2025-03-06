import 'package:flutter/material.dart';

import 'colors.dart';

const EdgeInsets top_30 = EdgeInsets.fromLTRB(0, 30, 0, 0);
const EdgeInsets top_40 = EdgeInsets.fromLTRB(0, 40, 0, 0);
const EdgeInsets top_50 = EdgeInsets.fromLTRB(0, 50, 0, 0);
const EdgeInsets all = EdgeInsets.all(20);

class MyButtonStyles {
  static WidgetStateProperty<Color> color = WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed)) return white;
        return strongOrange;
      });

  static WidgetStateProperty<Color> bkg = WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed)) return strongOrange;
        return white;
      });

  static ButtonStyle whiteDefaultPurplePressed = ButtonStyle(
      foregroundColor: color,
      backgroundColor: bkg
  );
}