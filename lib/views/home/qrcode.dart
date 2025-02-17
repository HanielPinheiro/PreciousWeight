import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ScanQr extends StatefulWidget {
  @override
  State<ScanQr> createState() => _ScanQrState();
}

class _ScanQrState extends State<ScanQr> {
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
  String? qrData;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(onSubmitted: (value) { setState(() {qrData = value;});}),
        if(qrData != null) PrettyQrView.data(data: qrData!),
      ],
    );
  }
}

/*Se você quer criar um **sistema de QR Code proprietário**, onde apenas seu aplicativo pode ler e interpretar corretamente os dados, você pode seguir estas etapas:

---

## **1️⃣ Definir o Formato dos Dados**
O QR Code pode conter dados em um formato que apenas seu app saiba interpretar. Exemplos de estrutura:

### 🔹 **Formato JSON codificado em Base64**
```json
{
  "id": "123456",
  "timestamp": "2025-02-16T14:30:00Z",
  "signature": "a1b2c3d4e5"
}
```
➡ **Codifique esse JSON em Base64 antes de gerar o QR Code** para que fique mais difícil de ler diretamente.

### 🔹 **Formato Proprietário (Binário ou Encriptado)**
Você pode armazenar os dados de forma encriptada para que leitores comuns não consigam interpretar. Exemplo:
```
SGFu...kZW==
```
(Apenas seu app poderá decodificar isso corretamente.)

---

## **2️⃣ Gerar o QR Code com Dados Personalizados**
Em Flutter, você pode usar a biblioteca [`qr_flutter`](https://pub.dev/packages/qr_flutter) para gerar QR Codes com seus dados personalizados:

### **Exemplo de geração de QR Code codificado em Base64**
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQR extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Criando dados estruturados
    Map<String, dynamic> data = {
      "id": "123456",
      "timestamp": DateTime.now().toIso8601String(),
      "signature": "a1b2c3d4e5"
    };

    // Convertendo para JSON e codificando em Base64
    String jsonData = jsonEncode(data);
    String encodedData = base64Encode(utf8.encode(jsonData));

    return Scaffold(
      appBar: AppBar(title: Text('Gerar QR Code')),
      body: Center(
        child: QrImageView(
          data: encodedData, // Usando o dado codificado
          size: 200,
        ),
      ),
    );
  }
}
```

---

## **3️⃣ Criar um Leitor que Decodifica Apenas Seus QR Codes**
Agora, para ler os dados e interpretá-los corretamente, você pode usar [`mobile_scanner`](https://pub.dev/packages/mobile_scanner):

### **Exemplo de leitor que decodifica JSON Base64**
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQR extends StatefulWidget {
  @override
  State<ScanQR> createState() => _ScanQRState();
}

class _ScanQRState extends State<ScanQR> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        if (!scanned) {
          scanned = true;
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            try {
              String decoded = utf8.decode(base64Decode(barcode.rawValue!));
              Map<String, dynamic> data = jsonDecode(decoded);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("QR Code Lido!"),
                  content: Text("ID: ${data['id']}\nTimestamp: ${data['timestamp']}"),
                ),
              );
            } catch (e) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Erro!"),
                  content: Text("Este QR Code não é válido para este app."),
                ),
              );
            }
          }
        }
      },
    );
  }
}
```

---

## **4️⃣ Melhorando a Segurança com Criptografia**
Se quiser garantir que só seu app possa ler os dados corretamente, use **criptografia** com uma chave secreta:

### 🔹 **Usando AES para criptografar e descriptografar os dados**
1. Adicione a biblioteca [`encrypt`](https://pub.dev/packages/encrypt):
   ```yaml
   dependencies:
     encrypt: ^5.0.0
   ```

2. **Modifique o código para criptografar o QR Code**
   ```dart
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

---

## **Conclusão**
✅ **QR Code proprietário**: Apenas seu app pode ler os dados corretamente.
✅ **Base64 ou JSON estruturado**: Para dificultar a leitura por leitores comuns.
✅ **Criptografia AES**: Garante que ninguém decodifique os dados sem sua chave secreta.

📌 **Se quiser algo ainda mais seguro, pode assinar digitalmente os dados com RSA ou HMAC.**

Se precisar de mais ajuda, só chamar! 🚀🔥*/
