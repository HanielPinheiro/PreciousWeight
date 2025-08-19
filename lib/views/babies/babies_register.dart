import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:precious_weight/api/baby_api.dart';
import 'package:provider/provider.dart';
import '../../models/baby.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/providers/baby_provider.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';

class BabiesRegister extends StatefulWidget {
  const BabiesRegister({super.key, required this.scannedImage, required this.scannedText});

  final String? scannedText;
  final Uint8List? scannedImage;

  @override
  State<BabiesRegister> createState() => _BabiesRegisterState();
}

class _BabiesRegisterState extends State<BabiesRegister> {
    late TextEditingController _hospIdController;
    late TextEditingController _nameIdController;
    late TextEditingController _nameMotherController;
    late TextEditingController _birthDateController;
    late TextEditingController _weightTimeController;

    @override
    void initState() {
      super.initState();
      _hospIdController = TextEditingController();
      _nameIdController = TextEditingController();
      _nameMotherController = TextEditingController();
      _weightTimeController = TextEditingController();
      _birthDateController = TextEditingController();
    }

    @override
    void dispose() {
      _hospIdController.dispose();
      _nameIdController.dispose();
      _nameMotherController.dispose();
      _birthDateController.dispose();
      _weightTimeController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final _babyProvider = context.watch<BabyProvider>();

      return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
            body: ListView(padding: const EdgeInsets.symmetric(horizontal: 8.0), children: <Widget>[
              Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                // const SizedBox(height: 20.0),
                // Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 25),
                //     child: InkWell( borderRadius: BorderRadius.circular(15),
                //         child: Container( padding: EdgeInsets.all(9),
                //             decoration: MyDecorations().GetBoxDecoration(context),
                //             child: Row(children: [ Container(child: scannedImage ?? Container(child: Placeholder(color: Colors.grey)), constraints: BoxConstraints(maxHeight: 120, maxWidth: 120)),
                //               SizedBox(width: 10),
                //               Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center,
                //                   children: [ElementsOfViews.SimpleButton(context, "Inserir Novo QR Code", () async {ReadQrCode(context);}),
                //                     ElementsOfViews.SimpleButton(context, "Remover QR Code", () {setState(() {scannedImage = null;});})
                //                   ])),
                //             ])))
                // ),
                const SizedBox(height: 20.0),
                ElementsOfViews.InputWithController(context, _hospIdController, 'Registro Hospitalar', 'Código/registro do bebê no hospital', Icon(Icons.numbers, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameIdController, 'Nome do paciente', 'Digite o nome do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameMotherController, 'Nome da mãe do paciente', 'Digite o nome da mãe do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.DateInput(context, _birthDateController, 'Data de Nascimento do Paciente', 'Digite os números'),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _weightTimeController, 'Horário(s) da(s) coleta(s) do peso', '', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary), false, true),
                Row(children: [SizedBox(width: 15), ElementsOfViews.SimpleButton(context, "Gerenciar Horários",
                        () async {await ElementsOfViews.ShowTimeManager(context,(newTimes) => setState(() => _weightTimeController.text = newTimes),initialTimes: _weightTimeController.text);},false)
                ]),
                const SizedBox(height: 20.0),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ElementsOfViews.SimpleButton(context, "LIMPAR CAMPOS", () {
                      _hospIdController.clear(); _nameIdController.clear();
                      _nameMotherController.clear();_birthDateController.clear();
                      _weightTimeController.clear();
                    }),
                    const SizedBox(width: 8.0),
                    ElementsOfViews.ContrastButton(
                      context, Icon(Icons.cloud_upload, color: Colors.black), "CADASTRAR",
                      () async {
                        if(_hospIdController.text.isEmpty || _nameIdController.text.isEmpty || _nameMotherController.text.isEmpty || _birthDateController.text.isEmpty || _weightTimeController.text.isEmpty){
                          await showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro de requisição"), content: Text("Há campos vazios!")));
                          return;
                        }

                        try {
                          final newBaby = BabyModel(hospitalRegister: _hospIdController.text, name: _nameIdController.text, motherName: _nameMotherController.text, birthDate: dateFormatter_objToDb.parse(_birthDateController.text), isActive: true, qrCodeText: widget.scannedText, weightHour: _weightTimeController.text);

                          final addedBaby = await SafeApi.call( // First add the baby
                            context: context, apiCall: () async => await _babyProvider.addBaby(newBaby)
                          );

                          if (widget.scannedText!.isEmpty && widget.scannedImage!.isNotEmpty) {
                            await SafeApi.call( // Then update QR code if needed
                              context: context, apiCall: () async => await _babyProvider.updateBaby(addedBaby, widget.scannedImage)
                            );
                          }

                          // Show success message
                          await showDialog(context: context, builder: (context) => AlertDialog(content: Text("Novo bebê cadastrado com sucesso")));
                          Navigator.pop(context);
                        } catch (e) {
                          await showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro de requisição"), content: Text(e.toString())));
                        }
                      },
                    )
                  ],
                ),
              ])
            ])));
  }
}
