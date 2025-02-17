import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/logs/log.dart';
import '../../repository/design/colors.dart';
import '../../repository/widgets/elements.dart';

class LogDetails extends StatelessWidget {
  const LogDetails({super.key, required this.log});

  final LogModel log;

  @override
  Widget build(BuildContext context) {
    var modelScale = <Widget>[
      ElementsOfViews.CardToText("Código do Log: ${log.id}", white),
      ElementsOfViews.CardToText("Tipo do Log: ${LogModel.GetLogTypeLabel(log.logType)}", white),
      ElementsOfViews.CardToText("Data do Log: ${log.date}", white),
      ElementsOfViews.CardToText("Id da balança: ${log.scaleId}", white),
      ElementsOfViews.CardToText("Estado anterior da balança: ${log.prevState}", white),
      ElementsOfViews.CardToText("Novo estado da balança: ${log.newState}", white),
    ];

    var modelPatient= <Widget>[
      ElementsOfViews.CardToText("Código do Log: ${log.id}", white),
      ElementsOfViews.CardToText("Tipo do Log: ${LogModel.GetLogTypeLabel(log.logType)}", white),
      ElementsOfViews.CardToText("Data do Log: ${log.date}", white),
      ElementsOfViews.CardToText("Código Id do Bebê: ${log.patientId}", white),
      ElementsOfViews.CardToText("Id da balança: ${log.scaleId}", white),
      ElementsOfViews.CardToText("Id da nova balança: ${log.newScaleId}", white),
    ];

    return SafeArea(
        child: Scaffold(
            appBar: AppBar(title: Text('Dados do Relatório')),
            body: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: log.logType == LogType.scale ? modelScale : modelPatient)));
  }
}
