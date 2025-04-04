import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ScanQrCode extends StatefulWidget {
  @override
  State<ScanQrCode> createState() => _ScanQrState();
}

class _ScanQrState extends State<ScanQrCode> {
  bool state = true;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
        controller: MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, returnImage: true),
        onDetect: (capture) {
          if (state) {
            final Uint8List? image = capture.image;
            final String? qrText = capture.barcodes.first.rawValue;

            if (image != null && qrText != null) {
              state = false; // Prevent multiple triggers
              Navigator.pop(context, {'text': qrText, 'image': image}); // Return data to HomePage
            }
          }
        });
  }
}

class CreateQrCode extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CreateQrCode();
}

class _CreateQrCode extends State<CreateQrCode> {
  String qrData = "PW_D0EF7659B7C00*KwS2@y6G";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create QR Code")),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(onSubmitted: (value) {setState(() {qrData = value;});}),
          PrettyQrView.data(data: qrData),
        ],
      ),
    );
  }
}

/*
### 🔹 **Usando AES para criptografar e descriptografar os dados**
   import 'package:encrypt/encrypt.dart' as encrypt;

   final key = encrypt.Key.fromUtf8('abcdefghijklmnopabcdefghijklmnop'); // 32 bytes
   final iv = encrypt.IV.fromLength(16);
   final encrypter = encrypt.Encrypter(encrypt.AES(key));

   String encryptData(String plainText) {
     return encrypter.encrypt(plainText, iv: iv).base64;
   }

   String decryptData(String encryptedText) {
     return encrypter.decrypt64(encryptedText, iv: iv);
   }
   ```

3. **Modifique a geração e leitura do QR Code para usar criptografia**
   - **Gerar QR Code criptografado**
     ```dart
     String encryptedData = encryptData(jsonEncode(data));
     ```

   - **Ler e descriptografar QR Code**
     ```dart
     String decryptedData = decryptData(barcode.rawValue!);
     ```

*/
