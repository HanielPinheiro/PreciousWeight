import '../babies/baby.dart';
import '../enums.dart';
import '../scales/scales.dart';

const String logs_tableName = "logs";
const String logs_id = "id_log";
const String logs_type = "log_type";
const String logs_date = "date_log";
const String logs_newScaleId = "novo_id_balanca";
const String logs_newState = "novo_estado_balanca";

class LogModel {
  final int id;
  final DateTime date;
  final LogType logType;
  final int? patientId;
  final int scaleId;
  final int? newScaleId;
  final int? prevState;
  final int? newState;

  LogModel({
    required this.id,
    required this.date,
    required this.logType,
    this.patientId,
    required this.scaleId,
    this.newScaleId,
    this.prevState,
    this.newState,
  });

  static String GetLogTypeLabel(LogType type) {
    if (type == LogType.scale) return 'Balança';
    return 'Paciente';
  }

  static LogModel fromJson(Map<String, dynamic> json) {
    final logType = json[logs_type] == LogType.scale ? LogType.scale : LogType.patient;

    return LogModel(
      id: json[logs_id] as int,
      date: DateTime.parse(json[logs_date] as String),
      logType: logType,
      patientId: logType == LogType.patient ? json[patient_id] as int? : null,
      scaleId: json[scales_id] as int,
      newScaleId: logType == LogType.patient ? json[logs_newScaleId] as int? : null,
      prevState: logType == LogType.scale ? json[scales_state] as int? : null,
      newState: logType == LogType.scale ? json[logs_newState] as int? : null,
    );
  }

  // Method to convert a LogModel into a JSON map
  Map<String, dynamic> toJson() {
    return {
      logs_id: id,
      logs_date: date.toIso8601String(),
      logs_type: logType == LogType.scale ? LogType.scale : LogType.patient,
      if (logType == LogType.patient) patient_id: patientId,
      scales_id: scaleId,
      if (logType == LogType.patient) logs_newScaleId: newScaleId,
      if (logType == LogType.scale) scales_state: prevState,
      if (logType == LogType.scale) logs_newState: newState,
    };
  }

  // Method to create a copy of the current LogModel, allowing for modifications
  LogModel copyWith({
    int? id,
    DateTime? date,
    LogType? logType,
    int? patientId,
    int? scaleId,
    int? newScaleId,
    int? prevState,
    int? newState,
  }) {
    return LogModel(
      id: id ?? this.id,
      date: date ?? this.date,
      logType: logType ?? this.logType,
      patientId: patientId ?? this.patientId,
      scaleId: scaleId ?? this.scaleId,
      newScaleId: newScaleId ?? this.newScaleId,
      prevState: prevState ?? this.prevState,
      newState: newState ?? this.newState,
    );
  }
}
