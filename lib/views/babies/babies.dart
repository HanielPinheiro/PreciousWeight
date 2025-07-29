import 'package:flutter/material.dart';
import 'package:precious_weight/models/weight.dart';
import 'package:provider/provider.dart';

import '../../repository/providers/baby_provider.dart';
import '../../repository/widgets/elements.dart';
import 'babies_details.dart';

class BabiesPage extends StatefulWidget {
  @override
  _BabiesPageState createState() => _BabiesPageState();
}

class _BabiesPageState extends State<BabiesPage> {
  bool isDischarged = false;

  void _changeState(bool b) {
    setState(() => isDischarged = b);
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.watch<BabyProvider>();

    if (babyProvider.isLoading) return const Center(child: CircularProgressIndicator());

    final filteredBabies = babyProvider.babies.where((baby) => baby.isActive == !isDischarged).toList();

    return ListView(
      children: [
        Padding(padding: EdgeInsets.all(12.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElementsOfViews.SimpleButton(context, "Bebês Ativos", () => _changeState(false), !isDischarged),
            ElementsOfViews.SimpleButton(context, "Bebês Não Ativos", () => _changeState(true), isDischarged),
          ],
        ),
        Padding(padding: EdgeInsets.all(12.0)),
        ...filteredBabies.map((baby) => FutureBuilder<List<WeightModel>?>(
              future: baby.getWeights(),
              builder: (context, snapshot) {
                final text = snapshot.hasData && snapshot.data!.isNotEmpty ? "Último peso: ${snapshot.data!.last.weight.toString()} g" : "Último peso: N/A";
                return ElementsOfViews.CardToList(context, Icons.baby_changing_station, baby.name!, text, () => Navigator.push(context, MaterialPageRoute(builder: (context) => BabiesDetails(baby: baby))));
              },
            )),
      ],
    );
  }
}
