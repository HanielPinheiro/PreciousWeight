import 'package:app_files/pages/home/scan_babies.dart';
import 'package:app_files/pages/home/scan_scales.dart';
import 'package:app_files/pages/home/scanned_data.dart';
import 'package:app_files/pages/login/login.dart';
import 'package:flutter/material.dart';
import '../../structures/view.dart';
import '../../structures/definitions.dart';
import '../../structures/elements.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget? topContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          SizedBox(width: 20),
          Expanded(flex: 80, child: Text('Olá, Haniel', style: Definitions.roboto_32_black)),
          Expanded(flex: 20, child: GestureDetector(
              onTap: () {Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);},
              child: Container(color: Definitions.white,height: 50,child: Image.asset('assets/imgs/logout.png'))
            ),
          ),
          SizedBox(width: 20),
        ]
    );

    Widget? topContent2 = Card(
        color: Definitions.blue,
        elevation: 0,
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(text: 'Precious ', style: Definitions.notosans_50_white),
                      TextSpan(text: 'Weight', style: Definitions.caprasimo_50_orange),]
                    ),
                  ),
                  SizedBox(height: 63),
                  ElementsOfViews.ScanButton("Escanear Bebês", "home_btn1.jpg",
                          (){Navigator.push(context, MaterialPageRoute(builder: (context) => ScanBabiesScreen()));}),
                  SizedBox(height: 63),
                  ElementsOfViews.ScanButton("Escanear Balança", "home_btn2.jpg",
                          (){ Navigator.push(context, MaterialPageRoute(builder: (context) => ScanScaleScreen()));}),
                  SizedBox(height: 63),
                  ElementsOfViews.ScanButton("Trocar de Balança", "home_btn3.jpg",
                          (){ Navigator.push(context, MaterialPageRoute(builder: (context) => ScannedDataScreen()));})
                ]
            )
        )
    );

    Widget? topContent3 = ElementsOfViews.Menu();

    return BasicStructureOfViews.Home(topContent, topContent2, topContent3);
  }
}
