import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/logs/log.dart';
import '../../repository/widgets/elements.dart';

class LogDetails extends StatelessWidget {
  const LogDetails({super.key, required this.log});

  final LogModel log;

  @override
  Widget build(BuildContext context) {
    var modelScale = <Widget>[
      ElementsOfViews.CardToText(context,"Código do Log: ${log.id}", ),
      ElementsOfViews.CardToText(context,"Tipo do Log: ${LogModel.GetLogTypeLabel(log.logType)}", ),
      ElementsOfViews.CardToText(context,"Data do Log: ${log.date}", ),
      ElementsOfViews.CardToText(context,"Id da balança: ${log.scaleId}", ),
      ElementsOfViews.CardToText(context,"Estado anterior da balança: ${log.prevState}", ),
      ElementsOfViews.CardToText(context,"Novo estado da balança: ${log.newState}"),
    ];

    var modelPatient= <Widget>[
      ElementsOfViews.CardToText(context,"Código do Log: ${log.id}", ),
      ElementsOfViews.CardToText(context,"Tipo do Log: ${LogModel.GetLogTypeLabel(log.logType)}", ),
      ElementsOfViews.CardToText(context,"Data do Log: ${log.date}", ),
      ElementsOfViews.CardToText(context,"Código Id do Bebê: ${log.patientId}", ),
      ElementsOfViews.CardToText(context,"Id da balança: ${log.scaleId}", ),
      ElementsOfViews.CardToText(context,"Id da nova balança: ${log.newScaleId}", ),
    ];

    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Relatório'),
            body: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: log.logType == LogType.scale ? modelScale : modelPatient)));
  }
}
