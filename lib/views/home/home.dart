import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../repository/design/fonts.dart';
import '../../repository/widgets/elements.dart';
import '../../repository/services/qrcode_service.dart';

class HomePage extends StatelessWidget {
  Future<void> ReadQr(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQrCode()));
    if (result != null) {
      String scannedText = result['text'];
      Uint8List scannedImage = result['image'];
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text("Scanned QR Code"),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(scannedText), SizedBox(height: 10), Image.memory(scannedImage)])));
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
          TextSpan(text: 'Precious ', style: notosans_50.copyWith(
                color:Theme.of(context).brightness == Brightness.dark? Colors.white: Theme.of(context).colorScheme.onPrimary)),
          TextSpan(text: 'Weight', style: caprasimo_50.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,)),
        ]),
      ),
      SizedBox(height: 65),
      ElementsOfViews.ScanButton(context, "Escanear Bebês", "home_btn1.jpg",
              () async {ReadQr(context);}),
      SizedBox(height: 65),
      ElementsOfViews.ScanButton(context, "Escanear Balança", "home_btn2.jpg",
              () async {ReadQr(context);}),
      SizedBox(height: 65),
      ElementsOfViews.ScanButton(context, "Trocar de Balança", "home_btn3.jpg",
              () async {ReadQr(context);}),
      SizedBox(height: 65),
    ])));
  }
}
