import '../scales/scales.dart';
import '../weight/weight.dart';

const String patient_tableName = "babies";
const String patient_id = "id_baby";
const String patient_hospitalRegister = "hospital_register";
const String patient_name = "full_name";
const String patient_birthDate = "birth_date";
const String patient_weight = "weight";
const String patient_isActive = "active";

class PatientModel{
  final int? id;
  final int hospitalRegister;
  final String? name;
  final DateTime? birthDate;
  final double? weight;
  final bool? isActive;
  final ScaleModel? scale;
  final List<WeightModel>? historicWeight;

  PatientModel({this.id, required this.hospitalRegister, this.name, this.birthDate, this.weight, this.isActive , this.scale , this.historicWeight});

  static PatientModel fromJson(Map<String, dynamic> json) => PatientModel(
    id: json[patient_id] as int?,
    hospitalRegister: int.parse(json[patient_hospitalRegister] as String),
    name: json[patient_name] as String?,
    birthDate: DateTime.parse(json[patient_birthDate] as String),
    weight:  double.parse(json[patient_weight] as String),
    isActive: json[patient_isActive] == 1,
  );

  Map<String, dynamic> toJson() => {
    patient_id: id!,
    patient_hospitalRegister: hospitalRegister,
    patient_name: name!,
    patient_birthDate: birthDate!.toIso8601String(),
    patient_weight: weight!,
    patient_isActive: isActive! ? 1 : 0,
  };

  PatientModel copyWith({int? id, int? hospitalRegister, String? name, DateTime? birthDate, double? weight, bool? isActive, ScaleModel? scale, List<WeightModel>? historicWeight}) =>
      PatientModel(id: id ?? this.id,
          hospitalRegister: hospitalRegister ?? this.hospitalRegister,
          name: name ?? this.name,
          birthDate: birthDate ?? this.birthDate,
          weight: weight ?? this.weight,
          isActive: isActive ?? this.isActive,
          scale: scale ?? this.scale,
          historicWeight: historicWeight ?? this.historicWeight,
      );
}