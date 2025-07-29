import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repository/providers/scales_provider.dart';
import '../../repository/widgets/elements.dart';
import 'scales_details.dart';

class ScalesPage extends StatefulWidget {
  @override
  _ScalesPageState createState() => _ScalesPageState();
}

class _ScalesPageState extends State<ScalesPage> {
  bool isEnabled = true;

  void _changeState(bool b) {
    setState(() {
      isEnabled = b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scalesProvider = context.watch<ScalesProvider>();

    if (scalesProvider.isLoading) return const Center(child: CircularProgressIndicator());

    final filteredScales = scalesProvider.scales.where((scale) => scale.status == (isEnabled ? 1 : 0)).toList();

    return ListView(
      children: [
        Padding(padding: EdgeInsets.all(12.0)),
        Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElementsOfViews.SimpleButton(context, "Balanças Ativas", () => _changeState(true), isEnabled),
          ElementsOfViews.SimpleButton(context, "Balanças Não Ativas", () => _changeState(false), !isEnabled),
        ]),
        Padding(padding: EdgeInsets.all(12.0)),
        ...filteredScales.map((_scale) {
          return ElementsOfViews.CardToList(context, Icons.scale, 'Código da Balança #${_scale.id}', 'Estado ${_scale.status == 1 ? 'Operante' : 'Inoperante'}', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleDetails(scale: _scale)));
          });
        }).toList()
      ],
    );
  }
}