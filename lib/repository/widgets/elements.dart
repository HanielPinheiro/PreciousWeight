import '../../models/weight/weight.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design/colors.dart';
import '../design/fonts.dart';
import '../design/theme.dart';

class ElementsOfViews {
  static Widget RoundedInput(String text) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: amaranth_20_white),
      SizedBox(height: 5),
      TextFormField(
        decoration: InputDecoration(
          filled: true,
          fillColor: white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }

  static Widget AlignedTextButton(String text, TextStyle style, Alignment align, VoidCallback? action) {
    return Align(
        alignment: align, //Alignment.centerRight,
        child: TextButton(
            onPressed: action, //() { },
            child: Text(text, style: style) //Definitions.amaranth_20_white),
        ));
  }

  static Widget RoundedElevatedButton(String text, Color color, TextStyle style, VoidCallback? action) {
    return ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: style));
  }

  static Widget ScanButton(String label, String lbl_img, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: onTap, // Clickable behavior
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: white, // Background color
            border: Border.all(color: partial_black),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Image.asset("assets/imgs/$lbl_img", width: 80, height: 80, fit: BoxFit.cover),
              SizedBox(width: 12),
              Expanded(child: Text(label, style: amaranth_29_black)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget CardToList(IconData icon, String title, String subtitle, VoidCallback detailsScreen) {
    return Card(
        child: GestureDetector(
            onDoubleTap: detailsScreen,
            child: ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
            )));
  }

  static Widget CardToText(String label, Color? bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Card(
        color: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: EdgeInsets.all(9),
          alignment: Alignment.center, // Centers the text inside the card
          child: Text(
            label,
            style: amaranth_29_black,
            textAlign: TextAlign.center, // Ensures text alignment
          ),
        ),
      ),
    );
  }

  static Widget BabyWeightChart(List<WeightModel> baby) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1),
              const FlSpot(1, 3),
              const FlSpot(2, 7),
              const FlSpot(3, 4),
              const FlSpot(4, 6),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  static PreferredSizeWidget SimpleAppBar(String title, String label, Icon? _icon, VoidCallback action) {
    return AppBar(title: Text(title), actions: <Widget>[
      TextButton.icon(
        icon: _icon != null ? _icon : null,
        label: Text(label),
        style: MyButtonStyles.whiteDefaultPurplePressed,
        onPressed: action,
      )
    ]);
  }
}
