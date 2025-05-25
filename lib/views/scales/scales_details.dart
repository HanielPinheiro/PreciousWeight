import 'package:flutter/material.dart';
import 'package:precious_weight/api/scale_api.dart';
import 'package:precious_weight/repository/design/button_styles.dart';
import 'package:precious_weight/views/scales/scales_babies.dart';
import '../../models/scales.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';

class ScaleDetails extends StatelessWidget {
  ScaleDetails({super.key, required this.scale});

  final ScaleModel scale;
  final ScaleApi _scaleApi = ScaleApi();

  _wrapText(BuildContext context, String text) {
    return Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados da Balança'),
            body: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                  flex: 1,
                  child: Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    ElementsOfViews.SimpleButton(context, scale.status == 1 ? "Inativar Balança" : "Ativar Balança", () async {
                      await SafeApi.call(
                          context: context,
                          apiCall: () async {
                            await _scaleApi.enableOrDisableScale(scale.id.toString(), !(scale.status == 1));
                          },
                          onSuccess: () async {
                            await showDialog(context: context, builder: (context) => AlertDialog(content: Text("Estado da balança atualizado")));
                            Navigator.pop(context);
                          });
                    }, false, scale.assignedBaby != null),
                    ElementsOfViews.SimpleButton(context, "${scale.assignedBaby != null? "Trocar Bebê de Balança" : "Associar Bebê à Balança"}",(){Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(scale: scale)));}, false, scale.status == 0),
                  ])),
              scale.assignedBaby != null? Expanded(
                flex: 2,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: InkWell(
                      // Clickable behavior
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: EdgeInsets.all(9),
                          decoration: MyDecorations().GetBoxDecoration(context),
                          child: Row(children: [
                            Container(child: scale.assignedBaby!.qrCodeImage!, constraints: BoxConstraints(maxWidth: 120)),
                            SizedBox(width: 10),
                            Expanded(
                                child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  Text("Nome", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                  _wrapText(context, scale.assignedBaby!.name!),
                                  Text("Nome da mãe", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                  _wrapText(context, scale.assignedBaby!.motherName!),
                                  Text("Data de Nascimento", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                  _wrapText(context, dateFormatter_objToDb.format(scale.assignedBaby!.birthDate!)),
                                ])),
                          ]),
                        ))),
              ): Expanded(flex: 1, child: ElementsOfViews.CardToText(context, "Nenhum bebê associado")),
              Expanded(
                  flex:4,
                  child: Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    ElementsOfViews.CardToText(context, "Código ID: ${scale.id}"),
                    ElementsOfViews.CardToText(context, "MAC Address: ${scale.hash}"),
                    ElementsOfViews.CardToText(context, "Estado da balança: ${ScaleModel.ScaleOperation(scale.status)}"/*, bgColor: scale.status == 1 ? green : red*/),
                  ]))
            ])));
  }
}
