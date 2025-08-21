import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'dart:async';
import '../helper/constants.dart';
import '../widgets/elements.dart';

class BluefiService extends StatefulWidget {
  final String scannedText;

  const BluefiService(this.scannedText, {Key? key}) : super(key: key);

  @override
  State<BluefiService> createState() => _BluefiService();
}

class _BluefiService extends State<BluefiService> {
  final wifiLogin = TextEditingController();
  final wifiPassword = TextEditingController();
  final _flutterEspBleProvPlugin = FlutterEspBleProv();
  late String esp32Name;
  late final String esp32POP;

  @override
  void initState() {
    super.initState();
    var splitString = widget.scannedText.split('*');
    esp32Name = splitString[0];
    esp32POP = splitString[1];
  }

  @override
  void dispose() {
    wifiLogin.dispose();
    wifiPassword.dispose();
    super.dispose();
  }

  int _similarityScore(String input, String candidate) {
    int score = 0;
    for (int i = 0; i < input.length && i < candidate.length; i++) {
      if (input[i] == candidate[i]) {
        score++;
      } else {
        break;
      }
    }
    return score;
  }

  bool _findBestMatch(List<String> bleDevices) {
    String target = esp32Name.substring(0, esp32Name.length - 7);
    final threshold = target.length; // Set your minimum similarity requirement

    String? bestMatch;
    int highestScore = 0;

    for (final item in bleDevices) {
      final score = _similarityScore(target, item);
      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    }

    if (bestMatch != null && highestScore >= threshold) {
      esp32Name = bestMatch;
      return true;
    }
    return false;
  }

  Future checkConn() async {
    List<String> bleDevices = await _flutterEspBleProvPlugin.scanBleDevices('');
    if (!_findBestMatch(bleDevices)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Balança já está conectada ao WiFi", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ok", style: TextStyle(color: Theme.of(context).colorScheme.primary)))],
        ),
      );
    }
  }

  Future provisionWifi() async {
    final login = wifiLogin.text;
    if (login == "") {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Login Inválido", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Por favor, verifique o login.', style: TextStyle(color: Theme.of(context).colorScheme.primary))],
          ),
        ),
      );
      return;
    }

    final password = wifiPassword.text;
    if (password == "") {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Senha Inválida", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Por favor, verifique a senha.', style: TextStyle(color: Theme.of(context).colorScheme.primary))],
          ),
        ),
      );
      return;
    }

    var success = await _flutterEspBleProvPlugin.provisionWifi(esp32Name, esp32POP, login, password);
    // print(success);
    if (success!) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Conexão Wifi Concluída!", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Agora você poderá associar um bebê à balança', style: TextStyle(color: Theme.of(context).colorScheme.primary))],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ok", style: TextStyle(color: Theme.of(context).colorScheme.primary)))],
        ),
      ).then((_) {
        Navigator.pop(context);
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Erro na Conexão Wifi", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Por favor, verifique o nome da rede e a senha, e tente novamente.', style: TextStyle(color: Theme.of(context).colorScheme.primary))],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    checkConn();
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: ElementsOfViews.SimpleAppBar(context, lbl_connect_scale_to_network_br),
        body: Container(
          padding: EdgeInsets.all(10),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Theme.of(context).colorScheme.surface,
                  child: Text(lbl_wifi_data_br, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(lbl_wifi_login_br, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                      Expanded(
                        child: TextField(
                          controller: wifiLogin,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          decoration: InputDecoration(fillColor: Theme.of(context).colorScheme.surface, filled: true, border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(lbl_wifi_pass_br, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                      Expanded(
                        child: TextField(
                          controller: wifiPassword,
                          obscureText: true,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          decoration: InputDecoration(fillColor: Theme.of(context).colorScheme.surface, filled: true, border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                        label: Text(lbl_wifi_btn_connect_br, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        onPressed: provisionWifi,
                        style: ElevatedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.onSecondary, elevation: 4.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
// import 'dart:async';
// import '../helper/constants.dart';
// import '../widgets/elements.dart';
//
// class BluefiService extends StatefulWidget {
//   final String scannedText;
//
//   const BluefiService(this.scannedText, {Key? key}) : super(key: key);
//
//   @override
//   State<BluefiService> createState() => _BluefiService();
// }
//
// class _BluefiService extends State<BluefiService> {
//   final wifiLogin = TextEditingController();
//   final wifiPassword = TextEditingController();
//   final _flutterEspBleProvPlugin = FlutterEspBleProv();
//   late final String esp32Name;
//   late final String esp32POP;
//
//   @override
//   void initState() {
//     super.initState();
//     var splitString = widget.scannedText.split('*');
//     esp32Name = splitString[0];
//     esp32POP = splitString[1];
//   }
//
//   @override
//   void dispose() {
//     wifiLogin.dispose();
//     wifiPassword.dispose();
//     super.dispose();
//   }
//
//   Future checkConn() async {
//     var list = await _flutterEspBleProvPlugin.scanBleDevices('');
//     if(!list.contains(esp32Name)) {
//       showDialog(context: context, builder: (context) => AlertDialog(title: Text("Balança já está conectada ao WiFi"),
//           actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ok"))]));
//           // .then((_) {Navigator.pop(context);});
//     }
//   }
//
//   Future provisionWifi() async {
//     final login = wifiLogin.text;
//     if(login == ""){
//       showDialog(context: context, builder: (context) => AlertDialog(title: Text("Login Inválido"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Por favor, verifique o login.')])));
//       return;
//     }
//
//     final password = wifiPassword.text;
//     if(password == ""){
//       showDialog(context: context, builder: (context) => AlertDialog(title: Text("Senha Inválida"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Por favor, verifique a senha.')])));
//       return;
//     }
//
//     var success = await _flutterEspBleProvPlugin.provisionWifi(esp32Name, esp32POP, login, password);
//     print(success);
//     if(success!) {
//       showDialog(context: context, builder: (context) =>
//           AlertDialog(title: Text("Conexão Wifi Concluída!"),
//               content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Agora você poderá associar um bebê à balança')]),
//               actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ok"))]
//           )).then((_) { Navigator.pop(context);});
//     }
//     else
//       showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro na Conexão Wifi"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Por favor, verifique o nome da rede e a senha, e tente novamente.')])));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     checkConn();
//     return SafeArea(
//       child: Scaffold(
//         appBar:ElementsOfViews.SimpleAppBar(context, lbl_connect_scale_to_network_br),
//         body: Container(
//             padding: EdgeInsets.all(10),
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Flexible(child: Container(padding: EdgeInsets.all(10),child: const Text(lbl_wifi_data_br))),
//                 Flexible(child: Container(padding: EdgeInsets.all(10),
//                     child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [const Flexible(child: Text(lbl_wifi_login_br)), Expanded(child: TextField(controller: wifiLogin))],
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: Container(padding: EdgeInsets.all(10),
//                     child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [ const Flexible(child: Text(lbl_wifi_pass_br)), Expanded(child: TextField(controller: wifiPassword, obscureText: true))],
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                     child: Container(padding: EdgeInsets.all(10),child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.center,
//                         children: [ElevatedButton.icon(icon: Icon(Icons.login,color: Theme.of(context).colorScheme.surface),
//                                   label: const Text(lbl_wifi_btn_connect_br),onPressed: provisionWifi,
//                                   style: ElevatedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.surface,
//                                                                   backgroundColor: Theme.of(context).colorScheme.onSecondary,
//                                                                   elevation: 4.0),
//                         ),
//                   ]),
//                 ))
//               ],
//             ),
//           ),
//         ),
//     );
//   }
// }
