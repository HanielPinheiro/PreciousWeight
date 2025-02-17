import 'package:flutter/material.dart';

import '../../repository/widgets/elements.dart';
import '../../views/logs/log_details.dart';
import '../enums.dart';
import 'log.dart';

class LogsRepository {
  static List<LogModel> logs = <LogModel>[
    LogModel(id: 1, date: DateTime.now(), logType: LogType.scale, scaleId: 1, prevState: 0, newState: 1),
    LogModel(id: 2, date: DateTime.now(), logType: LogType.scale, scaleId: 2, prevState: 1, newState: 0),
    LogModel(id: 3, date: DateTime.now(), logType: LogType.patient, patientId: 5, scaleId: 1, newScaleId: 5,),
    LogModel(id: 4, date: DateTime.now(), logType: LogType.scale, scaleId: 4,  prevState: 0, newState: 1),
    LogModel(id: 5, date: DateTime.now(), logType: LogType.patient, patientId: 3, scaleId: 2, newScaleId: 7),
    LogModel(id: 6, date: DateTime.now(), logType: LogType.scale, scaleId: 15,  prevState: 1, newState: 0),
    LogModel(id: 7, date: DateTime.now(), logType: LogType.scale, scaleId: 6,  prevState: 0, newState: 1),
    LogModel(id: 8, date: DateTime.now(), logType: LogType.patient, scaleId: 7, patientId: 10, newScaleId: 11),
    LogModel(id: 9, date: DateTime.now(), logType: LogType.scale, scaleId: 8,  prevState: 1, newState: 0),
    LogModel(id: 10, date: DateTime.now(), logType: LogType.patient, scaleId: 9, patientId: 12, newScaleId: 1),
    LogModel(id: 11, date: DateTime.now(), logType: LogType.scale, scaleId: 10, prevState: 0, newState: 1),
    LogModel(id: 12, date: DateTime.now(), logType: LogType.patient, scaleId: 11, patientId: 14, newScaleId: 9),
    LogModel(id: 13, date: DateTime.now(), logType: LogType.scale, scaleId: 12, prevState: 1, newState: 0),
    LogModel(id: 14, date: DateTime.now(), logType: LogType.scale, scaleId: 13, prevState: 0, newState: 1),
    LogModel(id: 15, date: DateTime.now(), logType: LogType.patient, scaleId: 14, patientId: 15, newScaleId: 7),
  ];

  static List<Widget> GetLogsLikeCards(BuildContext context) {
    return logs.map((_log) {
      return ElementsOfViews.CardToList(Icons.history,'Log #${_log.id} - ${LogModel.GetLogTypeLabel(_log.logType)}','Date: ${_log.date}',
            () {Navigator.push(context,MaterialPageRoute(builder: (context) => LogDetails(log: _log)),);},);
    }).toList();
  }
}