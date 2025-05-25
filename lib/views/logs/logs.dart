import 'package:flutter/material.dart';
import 'package:precious_weight/models/enums.dart';
import 'package:precious_weight/views/logs/logs_itens.dart';
import '../../repository/design/fonts.dart';
import '../../repository/widgets/elements.dart';

class LogsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          TextSpan(text: 'Precious ', style: notosans_50.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary)),
          TextSpan(text: 'Weight', style: caprasimo_50.copyWith(color: Theme.of(context).colorScheme.onSecondary)),
        ]),
      ),
      SizedBox(height: 65),
      ElementsOfViews.ScanButtonNoImage(context, "Histórico - Bebês", () async {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LogsItens(type: LogType.baby)));
      }),
      SizedBox(height: 65),
      ElementsOfViews.ScanButtonNoImage(context, "Histórico - Balanças", () async {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LogsItens(type: LogType.scale)));
      }),
      SizedBox(height: 65),
      ElementsOfViews.ScanButtonNoImage(context, "Histórico - Peso", () async {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LogsItens(type: LogType.weight)));
      }),
      SizedBox(height: 65),
    ])));
  }
}
