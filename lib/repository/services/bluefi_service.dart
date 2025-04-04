import 'package:flutter/material.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'dart:async';
import '../helper/constants.dart';

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
  late final String esp32Name;
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

  Future checkConn() async {
    var list = await _flutterEspBleProvPlugin.scanBleDevices('');
    if(!list.contains(esp32Name)) {
      showDialog(context: context, builder: (context) => AlertDialog(title: Text("Balança já está conectada ao WiFi"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ok"))]))
          .then((_) {Navigator.pop(context);});
    }
  }

  Future provisionWifi() async {
    final login = wifiLogin.text;
    if(login == ""){
      showDialog(context: context, builder: (context) => AlertDialog(title: Text("Login Inválido"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Por favor, verifique o login.')])));
      return;
    }

    final password = wifiPassword.text;
    if(password == ""){
      showDialog(context: context, builder: (context) => AlertDialog(title: Text("Senha Inválida"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Por favor, verifique a senha.')])));
      return;
    }

    var success = await _flutterEspBleProvPlugin.provisionWifi(esp32Name, esp32POP, login, password);
    print(success);
    if(success!) {
      showDialog(context: context, builder: (context) =>
          AlertDialog(title: Text("Conexão Wifi Concluída!"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Agora você poderá associar um bebê à balança')]),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Ok"))]
          )).then((_) { Navigator.pop(context);});
    }
    else
      showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro na Conexão Wifi"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Por favor, verifique o nome da rede e a senha, e tente novamente.')])));
  }

  @override
  Widget build(BuildContext context) {
    checkConn();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text(lbl_connect_scale_to_network_br)),
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: const Text(lbl_wifi_data_br),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text(lbl_wifi_login_br)),
                        Expanded(child: TextField(controller: wifiLogin)),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text(lbl_wifi_pass_br)),
                        Expanded(child: TextField(controller: wifiPassword, obscureText: true)),
                      ],
                    ),
                  ),
                ),
                Flexible(
                    child: Container(
                  padding: EdgeInsets.all(10),
                  child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton.icon(
                      icon: Icon(
                        Icons.login,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      label: const Text(lbl_wifi_btn_connect_br),
                      onPressed: provisionWifi,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        backgroundColor: Theme.of(context).colorScheme.onSecondary,
                        elevation: 4.0,
                      ),
                    ),
                  ]),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
