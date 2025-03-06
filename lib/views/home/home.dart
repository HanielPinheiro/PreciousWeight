import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../repository/design/fonts.dart';
import '../../repository/widgets/elements.dart';
import 'qrcode.dart';

class HomePage extends StatelessWidget {
  Future<void> ReadQr(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQr()));
    if (result != null) {
      String scannedText = result['text'];
      Uint8List scannedImage = result['image'];
      showDialog(context: context, builder: (context) => AlertDialog(title: Text("Scanned QR Code"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text(scannedText), SizedBox(height: 10), Image.memory(scannedImage)])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          TextSpan(text: 'Precious ', style: notosans_50),
          TextSpan(text: 'Weight', style: caprasimo_50),
        ]),
      ),
      SizedBox(height: 65),
      ElementsOfViews.ScanButton("Escanear Bebês", "home_btn1.jpg", () async {
        ReadQr(context);
      }),
      SizedBox(height: 65),
      ElementsOfViews.ScanButton("Escanear Balança", "home_btn2.jpg", () async {
        ReadQr(context);
      }),
      SizedBox(height: 65),
      ElementsOfViews.ScanButton("Trocar de Balança", "home_btn3.jpg", () async {
        ReadQr(context);
      }),
      SizedBox(height: 65),
    ])));
  }
}
