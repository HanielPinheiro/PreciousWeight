import 'dart:convert';
import 'baby.dart';

const String scales_id = "scaleId";
const String scales_state = "scaleState";
const String scales_hash = "scaleHash";
const String scales_baby_id = "babyId";
const String scales_baby = "assignedBaby";

ScaleModel scaleFromJson(String str) => ScaleModel.fromJson(json.decode(str));

List<ScaleModel> scalesFromJson(String str) => List<ScaleModel>.from(json.decode(str).map((x) => ScaleModel.fromJson(x)));

String scaleToJson(ScaleModel data) => json.encode(data.toJson());

String scalesToJson(List<ScaleModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ScaleModel {
  final int id;
  final String hash;
  final int status;
  final int? babyId;
  final BabyModel? assignedBaby;

  ScaleModel({required this.id, required this.hash, required this.status, required this.babyId, required this.assignedBaby});

  static ScaleModel fromJson(Map<String, dynamic> json) => ScaleModel(id: json[scales_id], hash: json[scales_hash], status: json[scales_state], babyId: json[scales_baby_id], assignedBaby: json[scales_baby] != null ? babyFromJson(jsonEncode(json[scales_baby])) : null);

  Map<String, dynamic> toJson() => {scales_id: id, scales_hash: hash, scales_state: status, scales_baby_id: babyId, scales_baby: babyId != null ? babyToJson(assignedBaby!) : null};

  ScaleModel copyWith({int? id, String? hash, int? status, int? babyId, BabyModel? assignedBaby}) => ScaleModel(
        id: id ?? this.id,
        hash: hash ?? this.hash,
        status: status ?? this.status,
        babyId: babyId ?? this.babyId,
        assignedBaby: assignedBaby ?? this.assignedBaby,
      );

  static ScaleOperation(int state) {
    if (state == 1)
      return 'Operante';
    else
      return 'Não Operante';
  }
}
