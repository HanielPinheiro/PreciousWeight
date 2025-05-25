import 'package:flutter/material.dart';
import 'package:precious_weight/models/scales.dart';

import '../../api/scale_api.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';
import 'scales_details.dart';

class ScalesPage extends StatefulWidget {
  @override
  _ScalesPageState createState() => _ScalesPageState();
}

class _ScalesPageState extends State<ScalesPage> {
  late List<ScaleModel>? scales;
  final ScaleApi api = ScaleApi();
  bool isEnabled = true;

  void _changeState(bool b) {
    setState(() {
      isEnabled = b;
    });
  }

  Future<List<Widget>> _getScalesLikeCards(BuildContext context) async {
    List<Widget>? widgets = null;
    await SafeApi.call(
        context: context,
        apiCall: () async {
          scales = await api.listScales();
        },
        onSuccess: () async {
          widgets = [];
          widgets!.add(Padding(padding: EdgeInsets.all(12.0)));
          widgets!.add(Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElementsOfViews.SimpleButton(context, "Balanças Ativas", () => _changeState(true), isEnabled),
            ElementsOfViews.SimpleButton(context, "Balanças Não Ativas", () => _changeState(false), !isEnabled),
          ]));
          widgets!.add(Padding(padding: EdgeInsets.all(12.0)));

          // Filter babies based on discharge status
          final filteredScales = scales!.where((_scale) => _scale.status == (isEnabled ? 1 : 0)).toList();
          widgets!.addAll(await filteredScales.map((_scale) {
            return ElementsOfViews.CardToList(context, Icons.scale, 'Código da Balança #${_scale.id}', 'Estado ${_scale.status == 1 ? 'Operante' : 'Inoperante'}', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleDetails(scale: _scale)));
            });
          }).toList());
        });

    return widgets!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: FutureBuilder<List<Widget>>(
        future: _getScalesLikeCards(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return AlertDialog(content: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return AlertDialog(content: Text('No babies found'));
          } else {
            return ListView(children: snapshot.data!);
          }
        },
      ),
    );
  }
}
