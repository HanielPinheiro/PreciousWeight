import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:precious_weight/api/baby_api.dart';
import '../../models/baby.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';

class BabiesRegister extends StatelessWidget {
  const BabiesRegister({super.key, required this.scannedImage, required this.scannedText});

  final String scannedText;
  final Uint8List scannedImage;

  @override
  Widget build(
    BuildContext context,
  ) {
    final _hospIdController = TextEditingController();
    final _nameIdController = TextEditingController();
    final _nameMotherController = TextEditingController();
    final _birthDateController = TextEditingController();
    final _babyApi = new BabyApi();
    BabyModel? new_baby;

    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
            body: ListView(padding: const EdgeInsets.symmetric(horizontal: 8.0), children: <Widget>[
              Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 20.0),
                ElementsOfViews.InputWithController(context, _hospIdController, 'Registro Hospitalar', 'Código/registro do bebê no hospital', Icon(Icons.numbers, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameIdController, 'Nome do paciente', 'Digite o nome do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameMotherController, 'Nome da mãe do paciente', 'Digite o nome da mãe do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.DateInput(context, _birthDateController, 'Data de Nascimento do Paciente', 'Digite os números'),
                const SizedBox(height: 12.0),
                // ElementsOfViews.GetTimePicker(context),
                const SizedBox(height: 20.0),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ElementsOfViews.SimpleButton(context, "LIMPAR CAMPOS", () {
                      _hospIdController.clear();
                      _nameIdController.clear();
                      _nameMotherController.clear();
                      _birthDateController.clear();
                    }),
                    const SizedBox(width: 8.0),
                    ElementsOfViews.ContrastButton(
                      context,
                      Icon(Icons.cloud_upload, color: Colors.black),
                      "CADASTRAR",
                      () async {
                        await SafeApi.call(
                            context: context,
                            apiCall: () async {
                              final baby = BabyModel(hospitalRegister: _hospIdController.text, name: _nameIdController.text, motherName: _nameMotherController.text, birthDate: dateFormatter_objToDb.parse(_birthDateController.text), isActive: true, qrCodeText: scannedText);
                              new_baby = await _babyApi.insertBaby(baby.toJson());
                            },
                            onSuccess: () async {
                              await SafeApi.call(
                                  context: context,
                                  apiCall: () async {
                                    await _babyApi.updateBabyQr(new_baby!.id.toString(), scannedImage);
                                  },
                                  onSuccess: () async {
                                    await showDialog(context: context, builder: (context) => AlertDialog(content: Text("Novo bebê cadastrado com sucesso")));
                                    Navigator.pop(context);
                                  });
                            });
                      },
                    )
                  ],
                ),
              ])
            ])));
  }
}
