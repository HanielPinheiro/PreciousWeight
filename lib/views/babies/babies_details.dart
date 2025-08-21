import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weight.dart';
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
  final int id;

  BabiesDetails({super.key, required this.id});

  @override
  State<BabiesDetails> createState() => _BabiesDetailsState();
}

class _BabiesDetailsState extends State<BabiesDetails> {
  bool _isLoading = true;
  BabyProvider? _provider;
  BabyModel? _currentBaby;
  List<WeightModel>? _weights;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isLoading) {
      try {
        _provider = context.read<BabyProvider>();
        final baby = await _provider!.loadBabyWithQr(widget.id);
        final weights = await baby.getWeights();

        if (mounted) {
          setState(() {
            _currentBaby = baby;
            _weights = weights;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
        print('Error loading baby data: $e');
      }
    }
  }

  Widget _showFlex1() {
    return Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      ElementsOfViews.SimpleButton(context, "Editar", () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => BabiesEdit(baby: _currentBaby!)));
        final new_data = await _provider!.loadBabyWithQr(_currentBaby!.id!);
        setState(() {
          _currentBaby = new_data;
        });
      }),
      ElementsOfViews.SimpleButton(context, _currentBaby!.isActive! ? "Inativar Paciente" : "Ativar Paciente", () async {
        await _provider!.toggleBabyStatus(_currentBaby!);
        final new_data = await _provider!.getBabyById(_currentBaby!.id!);
        setState(() {
          _currentBaby = new_data!;
        });
      }, false, _currentBaby!.assignedScale != null),
      ElementsOfViews.SimpleButton(context, "${_currentBaby!.assignedScale != null ? 'Dados da Balança' : 'Associar Bebê à Balança'}", () {
        if (_currentBaby!.assignedScale != null) {
          var _scale = new ScaleModel(id: _currentBaby!.assignedScale!.id, hash: _currentBaby!.assignedScale!.hash, status: _currentBaby!.assignedScale!.status, babyId: _currentBaby!.id, assignedBaby: _currentBaby!);
          Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleDetails(id: _scale.id)));
        }
        // else
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(baby: _currentBaby!)));
      })
    ]);
  }

  Widget _showFlex2() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: InkWell(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.all(9),
              decoration: MyDecorations().GetBoxDecoration(context),
              child: _currentBaby!.qrCodeImage != null
                  ? IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: 120),
                          child: _currentBaby!.qrCodeImage ?? Container(), // Fallback if null
                        ),
                        SizedBox(width: 10),
                        Flexible(child: _buildDataColumn()),
                      ],
                    ))
                  : _buildDataColumn(),
            )));
  }

  Widget _wrapText(BuildContext context, String text) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _showFlex3() {
    return Padding(
        padding: EdgeInsets.only(top: 25.0),
        child: Column(
          children: [
            ElementsOfViews.CardToText(context, "Evolução Ponderal"),
            _weights != null && _weights!.length > 1
                ? BabyWeightChart(historicWeight: _weights!)
                : _weights != null && _weights!.length > 0
                    ? Column(children: [_wrapText(context, "Último peso: ${_weights![0].weight} g"), _wrapText(context, "Data: ${dateFormatter_log.format(_weights![0].date)}")])
                    : _wrapText(context, "Sem dados suficientes")
          ],
        ));
  }

  Widget _qrIdData(double space) {
    final qr_data = _currentBaby!.qrCodeText == null ? "" : _currentBaby!.qrCodeText!;
    return Column(children: [Text("ID do Qr Code", style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)), Text(qr_data, style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary)), SizedBox(height: space)]);
  }

  Widget _buildDataColumn() {
    final space = 10.0;

    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(), // Prevents scrolling issues
      children: [
        Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text("Nome do Bebê", style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          Text(_currentBaby!.name!, style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary)),
          SizedBox(height: space),
          Text("Nome da Mãe", style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          Text(_currentBaby!.motherName!, style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary)),
          SizedBox(height: space),
          Text("Data de Nascimento", style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          Text(dateFormatter_objToDb.format(_currentBaby!.birthDate!), style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary)),
          SizedBox(height: space),
          if (_currentBaby!.qrCodeText != null) _qrIdData(space)
        ])
      ],
    );
  }

  Future<List<Widget>> _renderData() async {
    return [
      Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Expanded(flex: 1, child: _showFlex1()),
        Expanded(flex: 2, child: _showFlex2()),
        Expanded(flex: 4, child: _showFlex3()),
      ])
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
      future: _renderData(),
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
