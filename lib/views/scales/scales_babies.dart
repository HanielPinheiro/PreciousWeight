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

/**
 * Use context.watch<T>() when the widget needs to rebuild upon provider changes.
 * Use context.read<T>() when accessing provider data without triggering a rebuild (e.g., in event handlers).
 * Use Consumer<T> for more granular control over widget rebuilds, affecting only a specific subtree.
 * Prefer context.watch<T>() and context.read<T>() over Provider.of<T>(context) for modern Flutter development with the provider package.
 *
 * context.read<ScalesProvider>() = await context.read<ScalesProvider>();
 * context.read<T>() => One-time access to the provider. Does not rebuild the widget when the provider notifies listeners.
 * _babyProvider = await context.watch<BabyProvider>();
 * context.watch<T>() => If the provider calls notifyListeners(), this widget’s build() will re-run. Use this when you want your widget’s UI to update automatically when provider data changes.
 *
 */

class ScaleBabies extends StatefulWidget {
  ScaleBabies({super.key, this.scale, this.baby});

  final ScaleModel? scale;
  final BabyModel? baby;

  @override
  _ScaleBabiesState createState() => _ScaleBabiesState();
}

class _ScaleBabiesState extends State<ScaleBabies> {
  ScaleModel? _currentScale;
  BabyModel? _currentBaby;
  bool _isAssociated = false;
  bool _showBaby = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    BabyModel? baby;
    ScaleModel? scale;
    bool isAssociated = false;

    final sMode = widget.scale != null;
    final bMode = widget.baby != null;

    if (bMode) {
      baby = await context.read<BabyProvider>().getBabyById(context, widget.baby!.id!);
      isAssociated = baby.scaleId != null;
      if (isAssociated) {
        scale = await context.read<ScalesProvider>().getScaleById(context, baby.scaleId!);
      }
    }

    if (sMode) {
      scale = await context.read<ScalesProvider>().getScaleById(context, widget.scale!.id);
      isAssociated = scale.babyId != null;
      if (isAssociated) {
        baby = await context.read<BabyProvider>().getBabyById(context, scale.babyId!);
      }
    }

    setState(() {
      _isAssociated = isAssociated;
      _currentBaby = baby;
      _currentScale = scale;
      _showBaby = bMode;
    });
  }

  Future<void> _unlinkBabyToScale() async {
    int? _scaleId =null;
    //Find if baby or scale mode and get the scale id
    if(_showBaby){//baby mode
      _scaleId = _currentBaby!.scaleId!;
    } else{
      _scaleId = _currentScale!.id;
    }
    //evokes api call to this
    await context.read<ScalesProvider>().setOrUnsetBaby(context, _scaleId);
  }

  Future<void> _linkBabyToScale({BabyModel? baby, ScaleModel? scale}) async {
    BabyModel? chosedBaby;
    ScaleModel? chosedScale;

    if (baby != null) {
      //se enviei o bebe, eu estou no modo balança, portanto, uso _scale
      chosedScale = _currentScale!;
      chosedBaby = baby;
    }
    if (scale != null) {
      //se enviei a balança bebe, eu estou no modo bebe, portanto, uso _baby
      chosedScale = scale;
      chosedBaby = _currentBaby!;
    }

    final result = await ElementsOfViews.showConfirmDialog(context, "Confirmação", "Você confirma a associação do bebê ${chosedBaby!.name!} com a balança ${chosedScale!.id}");
    if (!result) return;
    await context.read<ScalesProvider>().setOrUnsetBaby(context, chosedScale.id, baby_code: chosedBaby.id!.toString());
    await context.read<BabyProvider>().loadBabies(); //força atualizar o cache dos bebes
    await _loadData();
    ElementsOfViews.showSimpleDialog(context, "Funcionou", "Associação feita com sucesso!");
  }

  Widget _getScaleCardList(Function(ScaleModel) onSelected) {
    final scales = context.read<ScalesProvider>().scales;
    return ListView.builder(
        itemCount: scales.length,
        itemBuilder: (context, index) {
          final scale = scales[index];
          return GestureDetector(
              onDoubleTap: () {
                Navigator.pop(context, scale); // return the selected scale
              },
              child: _buildScaleCard(scale));
        });
  }

  Widget _getBabyCardList(Function(BabyModel) onSelected) {
    final babies = context.read<BabyProvider>().babies;
    return ListView.builder(
        itemCount: babies.length,
        itemBuilder: (context, index) {
          final baby = babies[index];
          return GestureDetector(
              onDoubleTap: () {
                Navigator.pop(context, baby);
              },
              child: _buildBabyCard(baby));
        });
  }

  Widget _showFlex1() {
    return Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (_currentBaby != null && !_isAssociated)
        ElementsOfViews.SimpleButton(context, "Associar Bebê a uma Balança", () async {
          final selectedScale = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SafeArea(
                          child: Scaffold(
                        appBar: ElementsOfViews.SimpleAppBar(context, 'Selecione a balança'),
                        body: _getScaleCardList((scale) {}),
                      ))));

          if (selectedScale != null) {
            _linkBabyToScale(scale: selectedScale);
          }
        }),
      if (_currentScale != null && !_isAssociated)
        ElementsOfViews.SimpleButton(context, "Associar Balança a um Bebê", () async {
          final selectedBaby = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SafeArea(
                          child: Scaffold(
                        appBar: ElementsOfViews.SimpleAppBar(context, 'Selecione o Bebê'),
                        body: _getBabyCardList((baby) {}),
                      ))));

          if (selectedBaby != null) {
            _linkBabyToScale(baby: selectedBaby);
          }
        }),
      if ((_currentBaby != null || _currentScale != null) && _isAssociated)
        ElementsOfViews.SimpleButton(context, "Desassociar Bebê da Balança", () async {
          await _unlinkBabyToScale();
          await _loadData();
        }),
      if (_currentBaby == null && _currentScale == null)
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text("Nenhum bebê ou balança selecionado...", style: TextStyle(fontSize: 16))],
        ),
    ]);
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
            Text("Nome: ${baby.name != null ? baby.name! : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Nome da mãe: ${baby.motherName != null ? baby.motherName! : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Data de Nascimento: ${baby.birthDate != null ? dateFormatter_objToDb.format(baby.birthDate!) : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ),
      ),
    );
  }

  Widget _buildScaleCard(ScaleModel scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: MyDecorations().GetBoxDecoration(context),
        child: Column(
          children: [
            Text("Balança Associada", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Hash: ${scale.hash}", style: TextStyle(fontSize: 16)),
            Text("Status: ${ScaleModel.ScaleOperation(scale.status)}", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _showFlex2() {
    if (!_showBaby && _isAssociated) {
      return _buildBabyCard(_currentScale!.assignedBaby!);
    } else if (_showBaby && _isAssociated) {
      return _buildScaleCard(_currentBaby!.assignedScale!);
    }
    return ElementsOfViews.CardToText(context, _currentBaby != null ? "Bebê não associado à nenhuma balança" : "Balança sem bebê vinculado a ela");
  }

  Widget _renderScaleData() {
    final double sz = 20;
    return Column(
      children: [
        ElementsOfViews.CardToText(context, "Balança escolhida: ${_currentScale!.hash}", fontSize: sz),
        ElementsOfViews.CardToText(context, "Estado da balança: ${ScaleModel.ScaleOperation(_currentScale!.status)}", fontSize: sz),
      ],
    );
  }

  Widget _renderBabyData() {
    final double sz = 20;
    return Column(
      children: [
        ElementsOfViews.CardToText(context, "Bebê escolhido:"),
        ElementsOfViews.CardToText(context, "${_currentBaby!.name}", fontSize: sz),
        ElementsOfViews.CardToText(context, "Nome da mãe:"),
        ElementsOfViews.CardToText(context, "${_currentBaby!.motherName}", fontSize: sz),
        ElementsOfViews.CardToText(context, "Data de nascimento:"),
        ElementsOfViews.CardToText(context, "${dateFormatter_objToDb.format(_currentBaby!.birthDate!)}", fontSize: sz),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentBaby == null && _currentScale == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Associar Bebê à Balança'),
            body: Consumer<ScalesProvider>(builder: (context, dataProvider, child) {
              if (dataProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (dataProvider.scales.isEmpty) {
                return Center(child: Text('No data found.'));
              } else {
                return ListView(children: [
                  SizedBox(height: 20),
                  _showFlex1(),
                  SizedBox(height: 20),
                  _showFlex2(),
                  SizedBox(height: 20),
                  if (!_showBaby) _renderScaleData(),
                  if (_showBaby) _renderBabyData(),
                ]);
              }
            })));
  }
}
