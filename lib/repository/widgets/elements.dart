import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/weight/weight.dart';
import '../design/colors.dart';
import '../design/button_styles.dart';
import '../design/fonts.dart';

class ElementsOfViews {
  static Widget RoundedInput(String text) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: amaranth_20),
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

  static Widget ScanButton(BuildContext context, String label, String lbl_img, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: onTap, // Clickable behavior
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Image.asset("assets/imgs/$lbl_img", width: 80, height: 80, fit: BoxFit.cover),
              SizedBox(width: 12),
              Expanded(child: Text(label, style: amaranth_29.copyWith(
                  color:theme.colorScheme.primary))),
            ],
          ),
        ),
      ),
    );
  }

  static Widget CardToList(BuildContext context, IconData icon,
      String title, String subtitle, VoidCallback detailsScreen) {
    return Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
            onTap: detailsScreen,
            child: ListTile(
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(title, style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary)),
              subtitle: Text(subtitle, style: bodyLarge.copyWith(color: Theme.of(context).colorScheme.primary)),

            )));
  }

  static Widget CardToText(BuildContext context, String label, {Color? bgColor, Color? fgColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Card(
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        color: bgColor ?? Theme.of(context).colorScheme.surface,
        child: Container(
          padding: EdgeInsets.all(9),
          alignment: Alignment.center, // Centers the text inside the card
          child: Text(
            label,
            style: amaranth_29.copyWith(color: fgColor ?? Theme.of(context).colorScheme.primary),
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

  static PreferredSizeWidget MenuAppBar(BuildContext context, String title, String label, Icon? _icon, VoidCallback action) {
    return AppBar(
        title: Text(title, style: headlineMedium.copyWith(
              color:Theme.of(context).brightness == Brightness.dark? Colors.white: Theme.of(context).colorScheme.onPrimary)
        ),
        shape: Border(bottom:BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
        // foregroundColor: Theme.of(context).brightness == Brightness.dark? Colors.white: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 100, minHeight: 40,maxHeight: 40),
            child:
            OutlinedButton .icon(
                icon: _icon ?? const SizedBox.shrink(),
                label: Text(label, style: headlineSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark?
                                                                Colors.white: Theme.of(context).colorScheme.onPrimary),),
                style: MyButtonStyles().GetLogoutButtonStyle(context),
                onPressed: action,)
          )]
    );
  }

  static PreferredSizeWidget SimpleAppBar(BuildContext context, String title) {
    return AppBar(
        title: Text(title, style: displayMedium.copyWith(color:Theme.of(context).colorScheme.primary),),
        shape: Border(bottom:BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
