import 'package:flutter/material.dart';
import '../structures//view.dart';
import '../structures/definitions.dart';
import '../structures/elements.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget? topContent = Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
      SizedBox(width: 20),
      Expanded(flex: 80, child: Text('Olá, Haniel', style: Definitions.roboto_32_black)),
      Expanded(flex: 20, child: Container(color: Definitions.partial_black, height: 50)),
      SizedBox(width: 20),
    ]);

    Widget? topContent2 = Card(
        color: Definitions.blue,
        elevation: 0,
        child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(text: 'Precious ', style: Definitions.notosans_50_white),
              TextSpan(text: 'Weight', style: Definitions.caprasimo_50_orange),
            ]),
          ),
          SizedBox(height: 63),
          ElementsOfViews.ScanButton("Escanear Bebês"),
          SizedBox(height: 63),
          ElementsOfViews.ScanButton("Escanear Balança"),
          SizedBox(height: 63),
          ElementsOfViews.ScanButton("Trocar de Balança")
        ])));

    Widget? topContent3 = Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("", 'Início', true)),
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("", 'Bebês', false)),
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("", 'Balança', false)),
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("", 'Históricos', false)),
    ]);

    return BasicStructureOfViews.Home(topContent, topContent2, topContent3);
  }
}
