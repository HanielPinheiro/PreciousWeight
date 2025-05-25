import 'package:flutter/material.dart';
import 'package:precious_weight/api/baby_api.dart';
import 'package:precious_weight/api/scale_api.dart';
import 'package:precious_weight/models/scales.dart';
import 'package:precious_weight/models/baby.dart';
import 'package:precious_weight/repository/design/button_styles.dart';
import 'package:precious_weight/repository/design/fonts.dart';
import 'package:precious_weight/repository/helper/conversions.dart';
import 'package:precious_weight/repository/services/api_service.dart';
import 'package:precious_weight/repository/widgets/elements.dart';

class ScaleBabies extends StatefulWidget {
  ScaleBabies({super.key, this.scale, this.baby});

  final ScaleModel? scale;
  final BabyModel? baby;

  @override
  _ScaleBabiesState createState() => _ScaleBabiesState();
}

class _ScaleBabiesState extends State<ScaleBabies> {
  final ScaleApi _scaleApi = ScaleApi();
  final BabyApi _babyApi = BabyApi();

  dynamic _selectedItem;
  List<dynamic> _itemsList = [];
  bool _isLoading = true;
  String _title = '';
  String _associationButtonText = '';
  String _confirmationMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _title = 'Associar Bebê à Balança';
    _confirmationMessage = 'Tem certeza que deseja associar este bebê à balança?';
    _associationButtonText = widget.scale!.assignedBaby != null ? "Trocar Bebê Associado" : "Associar Bebê";

    if (widget.scale != null)
      await _fetchBabies();
    else if (widget.baby != null) await _fetchScales();

    setState(() => _isLoading = false);
  }

  Future<void> _fetchBabies() async {
    await SafeApi.call(
        context: context,
        apiCall: () async {
          final babies = await _babyApi.listBabies();
          setState(() => _itemsList = babies!);
        });
  }

  Future<void> _fetchScales() async {
    await SafeApi.call(
        context: context,
        apiCall: () async {
          final scales = await _scaleApi.listScales();
          setState(() => _itemsList = scales!);
        });
  }

  Future<void> _confirmAssociation() async {
    if (_selectedItem == null) return;

    bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
          title: Text('Confirmar Associação'),
          content: Text(_confirmationMessage),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar'), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.surface)), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirmar'), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.surface))]),
    );

    if (shouldProceed ?? false) {
      await _performAssociation();
    }
  }

  Future<void> _performAssociation() async {
    await SafeApi.call(
      context: context,
      apiCall: () async {
        if (widget.scale != null) {
          await _scaleApi.setOrUnsetScale(widget.scale!.id.toString(), baby_code: _selectedItem.id.toString());
        } else if (widget.baby != null) {
          await _scaleApi.setOrUnsetScale(_selectedItem.id.toString(), baby_code: widget.baby!.id.toString());
        }
      },
      onSuccess: () async {
        await ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Associação realizada com sucesso!')),
        );
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCurrentAssociation() {
    if (widget.scale != null && widget.scale!.assignedBaby != null) {
      return _buildBabyCard(widget.scale!.assignedBaby!);
    } else if (widget.baby != null && widget.baby!.assignedScale != null) {
      return _buildScaleCard(widget.baby!.assignedScale!);
    }
    return ElementsOfViews.CardToText(context, "Nenhuma associação atual");
  }

  Widget _buildBabyCard(BabyModel baby) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(children: [
            Container(child: baby.qrCodeImage!, constraints: BoxConstraints(maxWidth: 120)),
            SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text("Nome", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                _wrapText(context, baby.name!),
                Text("Nome da mãe", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                _wrapText(context, baby.motherName!),
                Text("Data de Nascimento", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                _wrapText(context, dateFormatter_objToDb.format(baby.birthDate!)),
              ]),
            ),
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
            Text("ID: ${scale.id}", style: TextStyle(fontSize: 16)),
            Text("MAC: ${scale.hash}", style: TextStyle(fontSize: 16)),
            Text("Status: ${ScaleModel.ScaleOperation(scale.status)}", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _wrapText(BuildContext context, String text) {
    return Expanded(
        child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: ElementsOfViews.SimpleAppBar(context, _title),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DropdownButton<dynamic>(
                            value: _selectedItem,
                            hint: Text('Selecione um item'),
                            items: _itemsList.map((item) {
                              return DropdownMenuItem<dynamic>(
                                value: item,
                                child: Text(widget.scale != null ? item.name : 'Balança ${item.id} (${item.hash})', style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedItem = value);
                            }),
                        SizedBox(height: 10),
                        ElementsOfViews.SimpleButton(context, _associationButtonText, _confirmAssociation, _selectedItem != null)
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: _buildCurrentAssociation()),
                  if (widget.scale != null)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          ElementsOfViews.CardToText(context, "Código ID: ${widget.scale!.id}"),
                          ElementsOfViews.CardToText(context, "MAC Address: ${widget.scale!.hash}"),
                          ElementsOfViews.CardToText(context, "Estado da balança: ${ScaleModel.ScaleOperation(widget.scale!.status)}"),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
