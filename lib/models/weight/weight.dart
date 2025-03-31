import '../babies/baby.dart';
import '../scales/scales.dart';

const String weight_key = 'peso';
const String weight_id = 'id_peso';
const String weight_date = 'date_peso';

class WeightModel {
  final int id;
  final DateTime date;
  final int scaleId;
  final int patientId;
  final int weight;

  WeightModel({
    required this.id,
    required this.date,
    required this.scaleId,
    required this.patientId,
    required this.weight,
  });

  static WeightModel fromJson(Map<String, dynamic> json) => WeightModel(
    id: json[weight_id] as int,
    date: DateTime.parse(json[weight_date] as String), // Correct key for date
    scaleId: json[scales_id] as int, // Fixed constant for scaleId
    patientId: json[patient_id] as int, // Fixed constant for patientId
    weight: json[weight_key] as int, // Fixed constant for weight
  );

  Map<String, dynamic> toJson() => {
    weight_id: id,
    weight_date: date.toIso8601String(), // Correct key for date
    scales_id: scaleId, // Fixed constant for scaleId
    patient_id: patientId, // Fixed constant for patientId
    weight_key: weight, // Fixed constant for weight
  };

  WeightModel copyWith({
    int? id,
    DateTime? date,
    int? scaleId,
    int? patientId,
    int? weight,
  }) => WeightModel(
    id: id ?? this.id,
    date: date ?? this.date,
    scaleId: scaleId ?? this.scaleId,
    patientId: patientId ?? this.patientId,
    weight: weight ?? this.weight,
  );
}