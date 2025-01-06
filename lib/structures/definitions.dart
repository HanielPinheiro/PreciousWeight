import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Definitions {
  static double opacity = 1;
  static EdgeInsets top_30 = EdgeInsets.fromLTRB(0, 30, 0, 0);
  static EdgeInsets top_40 = EdgeInsets.fromLTRB(0, 40, 0, 0);
  static EdgeInsets top_50 = EdgeInsets.fromLTRB(0, 50, 0, 0);
  static EdgeInsets all = EdgeInsets.all(20);

  static Color strong_orange = Color.fromRGBO(255, 120, 0, opacity);
  static Color medium_orange = Color.fromRGBO(255, 182, 118, opacity);
  static Color light_orange = Color.fromRGBO(250, 151, 63, opacity);
  static Color blue = Color.fromRGBO(92, 94, 163, opacity);
  static Color green = Color.fromRGBO(77, 150, 90, opacity);
  static Color red = Color.fromRGBO(150, 77, 77, opacity);
  static Color partial_black = Color.fromRGBO(51, 51, 51, opacity);
  static Color white = Color.fromRGBO(255, 255, 255, 1);

  static TextStyle amaranth_20_white = GoogleFonts.amaranth(fontSize: 20, color: white);
  static TextStyle amaranth_24_white = GoogleFonts.amaranth(fontSize: 24, color: white);
  static TextStyle amaranth_29_black = GoogleFonts.amaranth(fontSize: 29, color: partial_black);
  static TextStyle baloo2_24_white = GoogleFonts.baloo2(fontSize: 24, fontWeight: FontWeight.w800, color: white);
  static TextStyle roboto_32_black = GoogleFonts.robotoFlex(fontSize: 32, color: Definitions.partial_black);
  static TextStyle notosans_50_white = GoogleFonts.notoSansKr(fontSize: 50, color: Definitions.white);
  static TextStyle caprasimo_50_orange = GoogleFonts.caprasimo(fontSize: 50, color: Definitions.strong_orange);


}
