import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:precious_weight/repository/design/colors.dart';
import '../../models/babies/baby.dart';
import '../../repository/widgets/baby_weight_chart.dart';
import '../../repository/widgets/elements.dart';

class BabiesDetails extends StatelessWidget {
  const BabiesDetails({super.key, required this.baby});
  final PatientModel baby;

  @override
  Widget build(BuildContext context,) {
    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
            body: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElementsOfViews.CardToText(context, "Nome: ${baby.name}"),
                  ElementsOfViews.CardToText(context,"Último Peso: ${baby.weight} g"),
                  ElementsOfViews.CardToText(context,"Nascimento: ${ DateFormat('dd/MM/yyyy').format(baby.birthDate!)}"),
                  ElementsOfViews.CardToText(context,"Balança: ${baby.scale != null ? baby.scale!.id : '-'}"),
                  ElementsOfViews.CardToText(context,"Evolução Ponderal", bgColor: medium_orange, fgColor: blue),
                  BabyWeightChart(historicWeight: baby.historicWeight)
                ]
            )
        )
    );
  }
}
