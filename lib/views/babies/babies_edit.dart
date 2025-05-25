import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/baby_api.dart';
import '../../repository/design/button_styles.dart';
import '../../models/baby.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/providers/baby_provider.dart';
import '../../repository/services/api_service.dart';
import '../../repository/services/qrcode_service.dart';
import '../../repository/widgets/elements.dart';

class BabiesEdit extends StatefulWidget {
  const BabiesEdit({super.key, required this.baby});

  final BabyModel baby;

  @override
  State<BabiesEdit> createState() => _BabiesEditState();
}

class _BabiesEditState extends State<BabiesEdit> {
  late TextEditingController _hospIdController;
  late TextEditingController _nameIdController;
  late TextEditingController _nameMotherController;
  late TextEditingController _birthDateController;
  late TextEditingController _weightTimeController;

  late String? qrRefText = widget.baby.qrCodeText!;
  late Image? qrRefImage = widget.baby.qrCodeImage!;
  final BabyApi _babyApi = BabyApi();

  BabyModel? new_baby;

  @override
  void initState() {
    super.initState();
    _hospIdController = TextEditingController(text: widget.baby.hospitalRegister ?? '');
    _nameIdController = TextEditingController(text: widget.baby.name ?? '');
    _nameMotherController = TextEditingController(text: widget.baby.motherName ?? '');
    _weightTimeController = TextEditingController(text: widget.baby.weightHour != null ? widget.baby.weightHour!.replaceAll(r'$',' - ') : 'Sem hora de coleta');
    _birthDateController = TextEditingController(text: widget.baby.birthDate != null ? dateFormatter_dbToObj.format(widget.baby.birthDate!) : '');
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

  Future<void> ReadQrCode(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQrCode()));
    if (result != null) {
      qrRefText = result['text'];
      qrRefImage = Image.memory(result['image']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.read<BabyProvider>();
    return SafeArea(
      child: Scaffold(
        appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20.0),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: InkWell( borderRadius: BorderRadius.circular(15),
                        child: Container( padding: EdgeInsets.all(9),
                            decoration: MyDecorations().GetBoxDecoration(context),
                            child: Row(children: [ Container(child: qrRefImage ?? Container(child: Placeholder(color: Colors.grey)), constraints: BoxConstraints(maxHeight: 120, maxWidth: 120)),
                              SizedBox(width: 10),
                              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [ElementsOfViews.SimpleButton(context, "Inserir Novo QR Code",
                                          () async {ReadQrCode(context);}),
                                ElementsOfViews.SimpleButton(context, "Remover QR Code",
                                        () {setState(() {qrRefImage = null;});})
                              ])),
                            ])))
                ),
                const SizedBox(height: 20.0),
                ElementsOfViews.InputWithController(context, _hospIdController, 'Registro Hospitalar', 'Código/registro do bebê no hospital', Icon(Icons.numbers, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameIdController, 'Nome do paciente', 'Digite o nome do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameMotherController, 'Nome da mãe do paciente', 'Digite o nome da mãe do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _weightTimeController, 'Horário(s) da(s) coleta(s) do peso', '', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary), false, true),
                Row(children: [SizedBox(width: 15), ElementsOfViews.SimpleButton(context, "Gerenciar Horários",
                                ()=>ElementsOfViews.ShowTimeManager(context,(newTimes) => setState(() => _weightTimeController.text = newTimes),initialTimes: _weightTimeController.text),false)
                ]),
                const SizedBox(height: 20.0),
                OverflowBar(alignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ElementsOfViews.SimpleButton(context, "LIMPAR CAMPOS", () {
                      _hospIdController.clear();
                      _nameIdController.clear();
                      _nameMotherController.clear();
                      _birthDateController.clear();
                      _weightTimeController.clear();
                    }),
                    const SizedBox(width: 8.0),
                    ElementsOfViews.ContrastButton(context,Icon(Icons.cloud_upload, color: Colors.black),"ATUALIZAR",
                      () async { await SafeApi.call(context: context,
                            apiCall: () async {
                              final updatedBaby = BabyModel(id: widget.baby.id, hospitalRegister: _hospIdController.text, name: _nameIdController.text, motherName: _nameMotherController.text, birthDate: dateFormatter_dbToObj.parse(_birthDateController.text), isActive: widget.baby.isActive, qrCodeText: qrRefText,weightHour: _weightTimeController.text.replaceAll(' - ', r'$'));
                              await babyProvider.updateBaby(updatedBaby, qrRefImage != null ? await imageToUint8List(qrRefImage!) : null, );
                            },
                            onSuccess: () async {
                              await showDialog(context: context, builder: (context) => AlertDialog(content: Text("Dados do bebê atualizados com sucesso")));
                              Navigator.pop(context);
                            });
                      })
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
