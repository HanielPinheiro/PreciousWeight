import 'package:flutter/material.dart';
import 'package:precious_weight/models/baby.dart';
import 'package:provider/provider.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/providers/scales_provider.dart';
import '../../models/scales.dart';
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

  Widget _showFlex1() {
    return Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      ElementsOfViews.SimpleButton(context, _scaleActive ? "Inativar Balança" : "Ativar Balança", () async {
        await context.read<ScalesProvider>().enableOrDisableScale(context, _currentScale!);
        await _loadData();
      }, false, _hasBaby),
      ElementsOfViews.SimpleButton(context, _hasBaby ? "Trocar Bebê de Balança" : "Associar Bebê à Balança", () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(scale: _currentScale)));
        await _loadData();
      })
    ]);
  }

  _wrapText(BuildContext context, String text) {
    return Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)));
  }

  Widget _showFlex2() {
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
                Text("Bebê na Balança", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 24)),
                _wrapText(context, "Nome: ${_currentScale!.assignedBaby!.name!}"),
                _wrapText(context, "Nome da mãe: ${_currentScale!.assignedBaby!.motherName!}"),
                _wrapText(context, "Data de Nascimento: ${dateFormatter_objToDb.format(_currentScale!.assignedBaby!.birthDate!)}"),
              ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showFlex3() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElementsOfViews.CardToText(context, "Código Hash: \n${_currentScale!.hash}"),
        ElementsOfViews.CardToText(context, "Estado da balança: ${ScaleModel.ScaleOperation(_currentScale!.status)}"),
      ],
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
          Expanded(flex: 1, child: _showFlex1()),
          Expanded(flex: 2, child: _showFlex2()),
          Expanded(flex: 4, child: _showFlex3()),
        ],
      ),
    );
  }
}

// class _ScaleDetailsState extends State<ScaleDetails> {
//   bool _isLoading = true;
//   bool _scaleActive = false;
//   bool _hasBaby = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _loadData();
//     });
//   }
//
//   Future<void> _loadData() async {
//     if (_isLoading) {
//       final _provider = await context.read<ScalesProvider>();
//       try {
//         final sc = await _provider.getScaleById(widget.id);
//         BabyModel? bb;
//         if (sc != null && sc.babyId != null) bb = await context.read<BabyProvider>().getBabyById(sc.babyId!);
//
//         if (mounted) {
//           setState(() {
//             if (bb != null) sc!.assignedBaby = bb;
//             _isLoading = false;
//             _scaleActive = sc!.status == 1;
//             _hasBaby = sc.babyId != null;
//           });
//         }
//       } catch (e) {
//         if (mounted)
//           setState(() {
//             _isLoading = false;
//           });
//         print('Error loading scale data: $e');
//       }
//     }
//   }
//
//   _wrapText(BuildContext context, String text) {
//     return Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)));
//   }
//
//   Future<Widget> _showFlex1() async {
//     final _currentScale =  await ErrorHandler.SafeApiCall(context: context,apiCall: () async {await context.read<ScalesProvider>().getScaleById(widget.id);});
//
//
//     return Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//       ElementsOfViews.SimpleButton(context, _scaleActive ? "Inativar Balança" : "Ativar Balança", () async {
//         await ErrorHandler.SafeApiCall(
//             context: context,
//             apiCall: () async {
//               await context.read<ScalesProvider>().enableOrDisableScale(_currentScale!);
//             },
//             onSuccess: () async {
//               final new_data = await context.read<ScalesProvider>().getScaleById(widget.id);
//               setState(() {
//                 _scaleActive = new_data!.status == 1;
//                 _hasBaby = new_data.babyId != null;
//               });
//             });
//       }),
//       ElementsOfViews.SimpleButton(context, "${_hasBaby ? "Trocar Bebê de Balança" : "Associar Bebê à Balança"}", () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(scale: _currentScale)));
//       }),
//     ]);
//   }
//
//   Future<Widget> _showFlex2() async {
//     final _currentScale = await context.read<ScalesProvider>().getScaleById(widget.id);
//
//     return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 25),
//         child: InkWell(
//             // Clickable behavior
//             borderRadius: BorderRadius.circular(15),
//             child: Container(
//               padding: EdgeInsets.all(9),
//               decoration: MyDecorations().GetBoxDecoration(context),
//               child: Row(children: [
//                 Container(child: _currentScale!.assignedBaby!.qrCodeImage!, constraints: BoxConstraints(maxWidth: 120)),
//                 SizedBox(width: 10),
//                 Expanded(
//                     child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
//                   Text("Nome", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
//                   _wrapText(context, _currentScale.assignedBaby!.name!),
//                   Text("Nome da mãe", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
//                   _wrapText(context, _currentScale.assignedBaby!.motherName!),
//                   Text("Data de Nascimento", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
//                   _wrapText(context, dateFormatter_objToDb.format(_currentScale.assignedBaby!.birthDate!)),
//                 ])),
//               ]),
//             )));
//   }
//
//   Future<Widget> _showFlex3() async {
//     final _currentScale = await context.read<ScalesProvider>().getScaleById(widget.id);
//     return Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//       ElementsOfViews.CardToText(context, "Código ID: ${_currentScale!.id}"),
//       ElementsOfViews.CardToText(context, "MAC Address: ${_currentScale.hash}"),
//       ElementsOfViews.CardToText(context, "Estado da balança: ${ScaleModel.ScaleOperation(_currentScale.status)}" /*, bgColor: scale.status == 1 ? green : red*/),
//     ]);
//   }
//
//   Future<List<Widget>> _renderData() async {
//     return [
//       Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//         Expanded(flex: 1, child: await _showFlex1()),
//         _hasBaby ? Expanded(flex: 2, child: await _showFlex2()) : Expanded(flex: 1, child: ElementsOfViews.CardToText(context, "Nenhum bebê associado")),
//         Expanded(flex: 4, child: await _showFlex3()),
//       ])
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Widget>>(
//       future: _renderData(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return AlertDialog(content: Text('Error: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return AlertDialog(content: Text('No scales found'));
//         } else {
//           return SafeArea(child: Scaffold(appBar: ElementsOfViews.SimpleAppBar(context, 'Dados da Balança'), body: snapshot.data![0]));
//         }
//       },
//     );
//   }
// }
