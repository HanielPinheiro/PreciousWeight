import 'package:flutter/material.dart';

const EdgeInsets top_30 = EdgeInsets.fromLTRB(0, 30, 0, 0);
const EdgeInsets top_40 = EdgeInsets.fromLTRB(0, 40, 0, 0);
const EdgeInsets top_50 = EdgeInsets.fromLTRB(0, 50, 0, 0);
const EdgeInsets all = EdgeInsets.all(20);

class MyButtonStyles {
  ButtonStyle GetLogoutButtonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: colorScheme.surface,
      padding: EdgeInsets.zero,
      minimumSize: Size.fromWidth(100),
      maximumSize: Size.fromWidth(100),
      side: BorderSide(
        color: colorScheme.primary, width: 1.5,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}