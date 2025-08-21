// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../models/scales.dart';
// import '../../models/baby.dart';
// import '../../repository/design/button_styles.dart';
// import '../../repository/design/fonts.dart';
// import '../../repository/helper/conversions.dart';
// import '../../repository/widgets/elements.dart';
// import '../../repository/providers/baby_provider.dart';
// import '../../repository/providers/scales_provider.dart';
// import '../../repository/widgets/error_handler.dart';
//
// /**
//  * Use context.watch<T>() when the widget needs to rebuild upon provider changes.
//  * Use context.read<T>() when accessing provider data without triggering a rebuild (e.g., in event handlers).
//  * Use Consumer<T> for more granular control over widget rebuilds, affecting only a specific subtree.
//  * Prefer context.watch<T>() and context.read<T>() over Provider.of<T>(context) for modern Flutter development with the provider package.
//  */
//
// class ScaleBabies extends StatefulWidget {
//   ScaleBabies({super.key, this.scale, this.baby});
//
//   final ScaleModel? scale;
//   final BabyModel? baby;
//
//   @override
//   _ScaleBabiesState createState() => _ScaleBabiesState();
// }
//
// enum Mode { babyMode, scaleMode }
//
// class _ScaleBabiesState extends State<ScaleBabies> {
//   BabyModel? _baby;
//   ScaleModel? _scale;
//   Mode _mode = Mode.babyMode;
//   bool _associated = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _loadData();
//     });
//   }
//
//   /**
//    * _scaleProvider = await context.read<ScalesProvider>();
//    * context.read<T>() => One-time access to the provider. Does not rebuild the widget when the provider notifies listeners.
//    * _babyProvider = await context.watch<BabyProvider>();
//    * context.watch<T>() => If the provider calls notifyListeners(), this widget’s build() will re-run. Use this when you want your widget’s UI to update automatically when provider data changes.
//    */
//
//   Future<void> _loadData() async {
//     final _scaleProvider = await context.read<ScalesProvider>();
//     final _babyProvider = await context.read<BabyProvider>();
//
//     final bMode = widget.baby != null;
//     final sMode = widget.scale != null;
//
//     BabyModel? baby;
//     ScaleModel? scale;
//     bool isAssociated = false;
//     if (bMode) {
//       baby = await _babyProvider.getBabyById(widget.baby!.id!);
//       isAssociated = baby!.assignedScale != null;
//       if (isAssociated) {
//         scale = await _scaleProvider.getScaleById(baby.assignedScale!.id);
//       }
//     }
//
//     if (sMode) {
//       scale = await _scaleProvider.getScaleById(widget.scale!.id);
//       isAssociated = scale!.babyId != null;
//       if (isAssociated) {
//         baby = await _babyProvider.getBabyById(scale.babyId!);
//       }
//     }
//
//     setState(() {
//       _mode = bMode ? Mode.babyMode : Mode.scaleMode;
//       _associated = isAssociated;
//       _baby = baby;
//       _scale = scale;
//     });
//   }
//
//   Future<void> _unlinkBabyToScale() async {
//     //Find if baby or scale mode
//     //get the scale id
//     //evokes api call to this
//   }
//
//   Future<void> _linkBabyToScale({BabyModel? baby, ScaleModel? scale}) async {
//     BabyModel? chosedBaby;
//     ScaleModel? chosedScale;
//
//     if (baby != null) {
//       //se enviei o bebe, eu estou no modo balança, portanto, uso _scale
//       chosedScale = _scale!;
//       chosedBaby = baby;
//     }
//     if (scale != null) {
//       //se enviei a balança bebe, eu estou no modo bebe, portanto, uso _baby
//       chosedScale = scale;
//       chosedBaby = _baby!;
//     }
//
//     final result = await ElementsOfViews.showConfirmDialog(context, "Confirmação", "Você confirma a associação do bebê ${chosedBaby!.name!} com a balança ${chosedScale!.id}");
//     if (!result) return;
//
//     try {
//       await ErrorHandler.handle(
//         context,
//             () async => await _provider!.enableOrDisableScale(_currentScale!),
//         onSuccess: () async {
//           final new_data = await _provider!.getScaleById(_currentScale!.id);
//           setState(() => _currentScale = new_data!);
//         },
//       );
//       _scaleProvider!.setOrUnsetBaby(chosedScale.id, baby_code: chosedBaby.id!.toString());
//       ElementsOfViews.showSimpleDialog(context, "Funcionou", "Associação feita com sucesso!");
//
//       if (_scaleMode) {
//         await _scaleProvider!.loadScales();
//         final newScale = await _scaleProvider!.getScaleById(_scale!.id);
//         setState(() {
//           _scale = newScale;
//         });
//       }
//       if (_babyMode) {
//         await _babyProvider!.loadBabies();
//         final newBaby = await _babyProvider!.getBabyById(_baby!.id!);
//         setState(() {
//           _baby = newBaby;
//         });
//       }
//     } catch (e) {
//       ElementsOfViews.showSimpleDialog(context, "Erro", "Falha ao associar: ${e.toString()}");
//     }
//   }
//
//   Widget _buildBabyCard(BabyModel baby) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(15),
//         child: Container(
//           padding: EdgeInsets.all(9),
//           decoration: MyDecorations().GetBoxDecoration(context),
//           child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text("Nome: ${baby.name != null ? baby.name! : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
//             Text("Nome da mãe: ${baby.motherName != null ? baby.motherName! : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
//             Text("Data de Nascimento: ${baby.birthDate != null ? dateFormatter_objToDb.format(baby.birthDate!) : ''}", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
//           ]),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildScaleCard(ScaleModel scale) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 25),
//       child: Container(
//         padding: EdgeInsets.all(16),
//         decoration: MyDecorations().GetBoxDecoration(context),
//         child: Column(
//           children: [
//             Text("Balança Associada", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
//             SizedBox(height: 10),
//             Text("ID: ${scale.id}", style: TextStyle(fontSize: 16)),
//             Text("MAC: ${scale.mac}", style: TextStyle(fontSize: 16)),
//             Text("Status: ${ScaleModel.ScaleOperation(scale.status)}", style: TextStyle(fontSize: 16)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _getScaleCardList(Function(ScaleModel) onSelected) {
//     final scales = _scaleProvider!.scales;
//     return ListView.builder(
//         itemCount: scales.length,
//         itemBuilder: (context, index) {
//           final scale = scales[index];
//           return GestureDetector(
//               onDoubleTap: () {
//                 Navigator.pop(context, scale); // return the selected scale
//               },
//               child: _buildScaleCard(scale));
//         });
//   }
//
//   Widget _getBabyCardList(Function(BabyModel) onSelected) {
//     final babies = _babyProvider!.babies;
//     return ListView.builder(
//         itemCount: babies.length,
//         itemBuilder: (context, index) {
//           final baby = babies[index];
//           return GestureDetector(
//               onDoubleTap: () {
//                 Navigator.pop(context, baby);
//               },
//               child: _buildBabyCard(baby));
//         });
//   }
//
//   Widget _showFlex1() {
//     return Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
//       if (_babyMode && !_associated)
//         ElementsOfViews.SimpleButton(context, "Associar Bebê a uma Balança", () async {
//           final selectedScale = await Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => SafeArea(
//                           child: Scaffold(
//                         appBar: ElementsOfViews.SimpleAppBar(context, 'Selecione a balança'),
//                         body: _getScaleCardList((scale) {}),
//                       ))));
//
//           if (selectedScale != null) {
//             print("User selected scale: ${selectedScale.id}");
//             _linkBabyToScale(scale: selectedScale);
//           }
//         }),
//       if (_scaleMode && !_associated)
//         ElementsOfViews.SimpleButton(context, "Associar Balança a um Bebê", () async {
//           final selectedBaby = await Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => SafeArea(
//                           child: Scaffold(
//                         appBar: ElementsOfViews.SimpleAppBar(context, 'Selecione o Bebê'),
//                         body: _getBabyCardList((baby) {}),
//                       ))));
//
//           if (selectedBaby != null) {
//             print("User selected scale: ${selectedBaby.id}");
//             _linkBabyToScale(baby: selectedBaby);
//           }
//         }),
//       if ((_babyMode || _scaleMode) && _associated)
//         ElementsOfViews.SimpleButton(context, "Desassociar Bebê da Balança", () async {
//           await _unlinkBabyToScale();
//         }),
//       if (!_babyMode && _scaleMode) Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [Text("Nenhum bebê ou balança selecionado...", style: TextStyle(fontSize: 16))]),
//     ]);
//   }
//
//   Widget _showFlex2() {
//     if (widget.scale != null && widget.scale!.assignedBaby != null) {
//       return _buildBabyCard(widget.scale!.assignedBaby!);
//     } else if (widget.baby != null && widget.baby!.assignedScale != null) {
//       return _buildScaleCard(widget.baby!.assignedScale!);
//     }
//     return ElementsOfViews.CardToText(context, _babyMode ? "Bebê não associado à nenhuma balança" : "Balança sem bebê vinculado a ela");
//   }
//
//   Widget _renderScaleData() {
//     final double sz = 20;
//     return Column(
//       children: [
//         ElementsOfViews.CardToText(context, "Balança escolhida: ${_scale!.id}", fontSize: sz),
//         ElementsOfViews.CardToText(context, "Estado da balança: ${ScaleModel.ScaleOperation(_scale!.status)}", fontSize: sz),
//       ],
//     );
//   }
//
//   Widget _renderBabyData() {
//     final double sz = 20;
//     return Column(
//       children: [
//         ElementsOfViews.CardToText(context, "Bebê escolhido:"),
//         ElementsOfViews.CardToText(context, "${_baby!.name}", fontSize: sz),
//         ElementsOfViews.CardToText(context, "Nome da mãe:"),
//         ElementsOfViews.CardToText(context, "${_baby!.motherName}", fontSize: sz),
//         ElementsOfViews.CardToText(context, "Data de nascimento:"),
//         ElementsOfViews.CardToText(context, "${dateFormatter_objToDb.format(_baby!.birthDate!)}", fontSize: sz),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_scaleProvider == null || _babyProvider == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return SafeArea(
//       child: Scaffold(
//         appBar: ElementsOfViews.SimpleAppBar(context, 'Associar Bebê à Balança'),
//     body: Consumer<ScalesProvider>(
//     builder: (context, dataProvider, child) {
//     if (dataProvider.isLoading) {
//     return Center(child: CircularProgressIndicator());
//     } else if (dataProvider.error != null) {
//     return Center(child: Text('Error: ${dataProvider.error}'));
//     } else if (dataProvider.scales.isEmpty) {
//     return Center(child: Text('No data found.'));
//     } else {
//     ListView(
//           children: [
//             SizedBox(height: 20),
//             _showFlex1(),
//             SizedBox(height: 20),
//             _showFlex2(),
//             SizedBox(height: 20),
//             if (_scaleMode) _renderScaleData(),
//             if (_babyMode) _renderBabyData(),
//           ],
//         ),
//       ),
//     );
//   }
// }
