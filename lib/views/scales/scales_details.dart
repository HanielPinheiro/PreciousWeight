import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../repository/design/button_styles.dart';
import '../../repository/providers/scales_provider.dart';
import '../../models/scales.dart';
import '../../models/baby.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/widgets/elements.dart';
import '../../repository/providers/baby_provider.dart';
import 'scales_babies.dart';

/**
 * Use context.watch<T>() when the widget needs to rebuild upon provider changes.
 * Use context.read<T>() when accessing provider data without triggering a rebuild (e.g., in event handlers).
 * Use Consumer<T> for more granular control over widget rebuilds, affecting only a specific subtree.
 * Prefer context.watch<T>() and context.read<T>() over Provider.of<T>(context) for modern Flutter development with the provider package.
 */

class ScaleDetails extends StatefulWidget {
  ScaleDetails({super.key, required this.id});

  final int id;

  @override
  State<ScaleDetails> createState() => _ScaleDetailsState();
}

class _ScaleDetailsState extends State<ScaleDetails> {
  bool _isLoading = true;
  ScaleModel? _currentScale;
  bool _scaleActive = false;
  bool _hasBaby = false;

  bool get _isScaleOnline => _currentScale?.isConnected ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<ScalesProvider>();
    final scale = await provider.getScaleById(context, widget.id);

    BabyModel? baby;
    if (scale.babyId != null) {
      baby = await context.read<BabyProvider>().getBabyById(context, scale.babyId!);
    }

    if (mounted) {
      setState(() {
        _currentScale = scale.copyWith(assignedBaby: baby);
        _scaleActive = scale.status == 1;
        _hasBaby = scale.babyId != null;
        _isLoading = false;
      });
    }
  }

  Future<void> _linkBabyToScale(BabyModel baby) async {
    final result = await ElementsOfViews.showConfirmDialog(context, "Confirmação", "Você confirma a associação do bebê ${baby.name!} com a balança ${_currentScale!.id}");
    if (!result) return;
    await context.read<ScalesProvider>().setOrUnsetBaby(context, _currentScale!.id, baby_code: baby.id!.toString());
    await _refreshBabyCacheAndScreen();
  }

  Future<void> _unlinkBabyFromScale() async {
    final _baby = _currentScale!.assignedBaby!;
    final result = await ElementsOfViews.showConfirmDialog(context, 'Bebê Associado', "Nome do bebê: ${_baby.name}\nNome da mãe: ${_baby.motherName}\nData de nascimento: ${dateFormatter_objToDb.format(_baby.birthDate!)}", btnCancelLbl: 'Fechar', btnConfirmLbl: "Desassociar");
    if (!result) return;
    await context.read<ScalesProvider>().setOrUnsetBaby(context, _baby.scaleId!);
    await _refreshBabyCacheAndScreen();
  }

  Future<void> _refreshBabyCacheAndScreen() async {
    await context.read<BabyProvider>().loadBabies(); //força atualizar o cache dos bebes
    await _loadData();
  }

  Future<void> _measureWeightNow() async {
    if (!_scaleActive) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text("Lendo peso..."),
        content: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final raw = await context.read<ScalesProvider>().getWeightNow(context, _currentScale!.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await ElementsOfViews.showSimpleDialog(context, "Peso", raw);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _runScaleCommand({ required String loadingTitle, required String successTitle, required Future<String> Function() command }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(loadingTitle),
        content: const SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final raw = await command();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await ElementsOfViews.showSimpleDialog(context, successTitle, raw.isEmpty ? 'Solicitação enviada com sucesso.' : raw);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _changeWifi() async {
    if (!_isScaleOnline) return;
    await _runScaleCommand(
      loadingTitle: 'Solicitando troca de Wi-Fi...',
      successTitle: 'Trocar Wi-Fi',
      command: () => context.read<ScalesProvider>().requestChangeWifi(context, _currentScale!.id),
    );
  }

  Future<void> _tareScale() async {
    if (!_scaleActive) return;
    await _runScaleCommand(
      loadingTitle: 'Solicitando tara...',
      successTitle: 'Realizar Tara',
      command: () => context.read<ScalesProvider>().requestTare(context, _currentScale!.id),
    );
  }

  Widget _flex1WithoutBaby(){
    return Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        ElementsOfViews.SimpleButton(context, _scaleActive ? "Inativar Balança" : "Ativar Balança", () async {
          await context.read<ScalesProvider>().enableOrDisableScale(context, _currentScale!);
          await _loadData();
        }, false, _hasBaby),

        ElementsOfViews.SimpleButton(context, "Associar Balança a um Bebê", () async {
            final baby = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(scale: _currentScale)));
            if (baby != null) await _linkBabyToScale(baby);
          }, false, !_scaleActive)
    ]);
  }

  _wrapText(BuildContext context, String text) {
    return Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)));
  }

  Widget _showBabyDetails() {
    if (_currentScale?.assignedBaby == null) {
      return ElementsOfViews.CardToText(context, "Nenhum bebê associado");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(
            children: [
              if (_currentScale!.assignedBaby!.qrCodeImage != null)
                Container(
                  child: _currentScale!.assignedBaby!.qrCodeImage,
                  constraints: BoxConstraints(maxWidth: 120),
                ),
              SizedBox(width: 10),
              Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    SizedBox(height: 20),
                    Text("Bebê na Balança", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 24)),
                    SizedBox(height: 20),
                    _wrapText(context, "Nome: ${_currentScale!.assignedBaby!.name!}"),
                    _wrapText(context, "Nome da mãe: ${_currentScale!.assignedBaby!.motherName!}"),
                    _wrapText(context, "Data de Nascimento: ${dateFormatter_objToDb.format(_currentScale!.assignedBaby!.birthDate!)}"),
                    SizedBox(height: 20),
                    ElementsOfViews.SimpleButton(context, "Trocar Bebê de Balança",  () async {await _unlinkBabyFromScale();}, false, !_scaleActive),
                    SizedBox(height: 20),
                  ])
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showScaleCommands() {
    final isActionDisabled = !_scaleActive || !_isScaleOnline;
    final wifiIcon = _isScaleOnline ? Icons.wifi : Icons.wifi_off;
    final wifiIconColor = _isScaleOnline ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.error;
    final wifiText = _isScaleOnline ? "Balança Conectada" : "Balança Desconectada";
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(children: [
                  Icon(wifiIcon, color: wifiIconColor, size: 36),
                  SizedBox(width: 10),
                  Text(wifiText, style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.normal, fontSize: 17)),
                ]),
                ElementsOfViews.SimpleButton(context, "Trocar Wi-Fi", () async { await _changeWifi(); }, false, false),
              ]
        ),
        Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElementsOfViews.SimpleButton(context, "Medir Peso Agora", () async { await _measureWeightNow(); }, false, isActionDisabled),
              ElementsOfViews.SimpleButton(context, "Realizar Tara", () async { await _tareScale(); }, false, isActionDisabled),
            ]
        )
      ]);
  }

  Widget _showScaleDetails() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: InkWell(
            borderRadius: BorderRadius.circular(15),
            child: Container(
                padding: EdgeInsets.all(9),
                decoration: MyDecorations().GetBoxDecoration(context),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _wrapText(context,"Código Hash: "),
                      _wrapText(context, _currentScale!.hash),
                      _wrapText(context, "Estado da balança: ${ScaleModel.ScaleOperation(_currentScale!.status)}")
                    ]),
            ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentScale == null) {
      return AlertDialog(content: Text('Scale not found'));
    }

    return Scaffold(
      appBar: ElementsOfViews.SimpleAppBar(context, 'Dados da Balança'),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 20),
          Expanded(flex: 1, child: _showScaleDetails()),
          SizedBox(height: 20),
          Expanded(flex: 1, child: _showScaleCommands()),
          SizedBox(height: 20),
          Expanded(flex: 2, child: _hasBaby ? _showBabyDetails() : _flex1WithoutBaby()),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
