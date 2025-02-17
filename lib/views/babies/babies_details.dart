import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patients/patient.dart';
import '../../repository/design/colors.dart';
import '../../repository/widgets/baby_weight_chart.dart';
import '../../repository/widgets/elements.dart';

class BabiesDetails extends StatelessWidget {
  const BabiesDetails({super.key, required this.baby});
  final PatientModel baby;

  @override
  Widget build(BuildContext context,) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(title: Text('Dados do Bebê')),
            body: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElementsOfViews.CardToText("Nome: ${baby.name}", white),
                  ElementsOfViews.CardToText("Último Peso: ${baby.weight} g", white),
                  ElementsOfViews.CardToText("Nascimento: ${ DateFormat('dd/MM/yyyy').format(baby.birthDate!)}", white),
                  ElementsOfViews.CardToText("Balança: ${baby.scale != null ? baby.scale!.id : '-'}", white),
                  ElementsOfViews.CardToText("Evolução Ponderal", white),
                  BabyWeightChart(historicWeight: baby.historicWeight)
                ]
            )
        )
    );
  }
}
