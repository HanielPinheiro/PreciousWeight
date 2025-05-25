import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scales.dart';
import '../../models/baby.dart';
import '../../views/babies/babies_edit.dart';
import '../../repository/providers/baby_provider.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/widgets/baby_weight_chart.dart';
import '../../repository/widgets/elements.dart';
import '../scales/scales_babies.dart';
import '../scales/scales_details.dart';

class BabiesDetails extends StatefulWidget {
  final BabyModel baby;
  BabiesDetails({super.key, required this.baby});

  @override
  State<BabiesDetails> createState() => _BabiesDetailsState();
}

class _BabiesDetailsState extends State<BabiesDetails> {
  late BabyModel? _baby = null;
  
  @override
  void initState() {
    super.initState();
    _baby = widget.baby;
  }
  
  _wrapText(BuildContext context, String text) {
    return Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)));
  }

  Future<List<Widget>> _getWeights(BuildContext context) async {
    final babyProvider = context.watch<BabyProvider>();
    final weights = await _baby!.getWeights();
    return [
      Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Expanded(
            flex: 1,
            child: Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElementsOfViews.SimpleButton(context, "Editar", () async {
                 await Navigator.push(context,MaterialPageRoute(builder: (context) => BabiesEdit(baby: _baby!)));                
                 await context.read<BabyProvider>().loadBabies();
                 _baby = babyProvider.babies.where((baby)=> baby.id == _baby!.id).first;
              }),

              ElementsOfViews.SimpleButton(context,_baby!.isActive! ? "Inativar Paciente" : "Ativar Paciente",
                      () => babyProvider.toggleBabyStatus(_baby!),  false,_baby!.assignedScale != null),

              ElementsOfViews.SimpleButton(context, "${_baby!.assignedScale != null ? 'Dados da Balança' : 'Associar Bebê à Balança'}", () {
                if(_baby!.assignedScale != null) {
                  var _scale = new ScaleModel(id:_baby!.assignedScale!.id, hash: _baby!.assignedScale!.hash,status: _baby!.assignedScale!.status, babyId: _baby!.id,assignedBaby: _baby!);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleDetails(scale: _scale)));
                }else
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(baby: _baby!)));

              })
            ])),
        Expanded(
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
                      Container(child: _baby!.qrCodeImage!, constraints: BoxConstraints(maxWidth: 120)),
                      SizedBox(width: 10),
                      Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Text("Nome", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                            _wrapText(context, _baby!.name!),
                            Text("Nome da mãe", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                            _wrapText(context, _baby!.motherName!),
                            Text("Data de Nascimento", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                            _wrapText(context, dateFormatter_objToDb.format(_baby!.birthDate!)),
                          ])),
                    ]),
                  ))),
        ),
        Expanded(flex: 4, child: Padding(
            padding: EdgeInsets.only(top: 25.0),
            child: Column(children: [
              ElementsOfViews.CardToText(context, "Evolução Ponderal"),
              Expanded(flex: 4, child: weights!.length > 1
                  ? BabyWeightChart(historicWeight: weights)
                  : weights.length > 0
                  ? Column(children: [_wrapText(context, "Último peso: ${weights[0].weight} g"), _wrapText(context, "Data: ${dateFormatter_log.format(weights[0].date)}")])
                  : _wrapText(context, "Sem dados suficientes"))
            ])))
      ])
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
      future: _getWeights(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return AlertDialog(content: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return AlertDialog(content: Text('No babies found'));
        } else {
          return SafeArea(child: Scaffold(appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'), body: snapshot.data![0]));
        }
      },
    );
  }
}