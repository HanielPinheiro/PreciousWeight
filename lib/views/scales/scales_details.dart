import 'package:flutter/material.dart';
import '../../models/scales/scales.dart';
import '../../repository/design/colors.dart';
import '../../repository/widgets/elements.dart';

class ScaleDetails extends StatelessWidget {
  const ScaleDetails({super.key, required this.scale});

  final ScaleModel scale;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(child: Scaffold(appBar: AppBar(title: Text('Dados da Balança')),
        body: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElementsOfViews.CardToText("Código ID: ${scale.id}", white),
              ElementsOfViews.CardToText("MAC Address: ${scale.hash}", white),
              ElementsOfViews.CardToText("Estado da balança: ${scale.status == 1 ? 'Operante' : 'Inoperante'}", scale.status == 1 ? green : red)])));
  }
}
