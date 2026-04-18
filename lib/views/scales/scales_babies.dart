import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scales.dart';
import '../../models/baby.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/widgets/elements.dart';
import '../../repository/providers/baby_provider.dart';
import '../../repository/providers/scales_provider.dart';

class ScaleBabies extends StatefulWidget {
  ScaleBabies({super.key, this.scale, this.baby});

  final ScaleModel? scale;
  final BabyModel? baby;

  @override
  _ScaleBabiesState createState() => _ScaleBabiesState();
}

class _ScaleBabiesState extends State<ScaleBabies> {
  Widget _getScaleCardList() {
    final scales = context.read<ScalesProvider>().scales.where((p) => p.status == 1 && p.babyId == null).toList();
    return ListView.builder(
        itemCount: scales.length,
        itemBuilder: (context, index) {
          final scale = scales[index];
          return GestureDetector(onTap: () => Navigator.pop(context, scale), child: _buildScaleCard(scale));
        });
  }

  Widget _getBabyCardList() {
    final babies = context.read<BabyProvider>().babies.where((p) => p.isActive == true && p.scaleId == null).toList();
    return ListView.builder(
        itemCount: babies.length,
        itemBuilder: (context, index) {
          final baby = babies[index];
          return GestureDetector(onTap: () => Navigator.pop(context, baby), child: _buildBabyCard(baby));
        });
  }

  Widget _buildBabyCard(BabyModel baby) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text("Nome: ${baby.name != null ? baby.name! : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text("Nome da mãe: ${baby.motherName != null ? baby.motherName! : ''}", style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text("Data de Nascimento: ${baby.birthDate != null ? dateFormatter_objToDb.format(baby.birthDate!) : ''}", style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildScaleCard(ScaleModel scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text("Balança #${scale.id}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text("Hash: ${scale.hash}", style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
            Text("Status: ${ScaleModel.ScaleOperation(scale.status)}", style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.baby != null) return SafeArea(child: Scaffold(appBar: ElementsOfViews.SimpleAppBar(context, 'Selecione a balança'), body: _getScaleCardList()));
    return SafeArea(child: Scaffold(appBar: ElementsOfViews.SimpleAppBar(context, 'Selecione o Bebê'), body: _getBabyCardList()));
  }
}
