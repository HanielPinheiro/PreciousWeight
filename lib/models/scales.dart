import 'dart:convert';
import 'baby.dart';

const String scales_id = "scaleId";
const String scales_state = "scaleState";
const String scales_hash = "scaleHash";
const String scales_baby_id = "babyId";
const String scales_status = "connectionStatus";
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
  String? mac;
  String? pop;
  BabyModel? assignedBaby;
  bool isConnected;

  ScaleModel({required this.id, required this.hash, required this.status, required this.babyId, this.assignedBaby, this.pop, this.mac, this.isConnected = false});

  static ScaleModel fromJson(Map<String, dynamic> json) => ScaleModel(
        id: json[scales_id],
        hash: json[scales_hash],
        status: json[scales_state],
        babyId: json[scales_baby_id],
        isConnected: json[scales_status]
      );

  Map<String, dynamic> toJson() => {
        scales_id: id,
        scales_hash: hash,
        scales_state: status,
        scales_baby_id: babyId,
        scales_status: isConnected
      };

  ScaleModel copyWith({int? id, String? hash, int? status, int? babyId, BabyModel? assignedBaby, String? pop, String? mac, bool? isConnected}) => ScaleModel(
        id: id ?? this.id,
        hash: hash ?? this.hash,
        status: status ?? this.status,
        babyId: babyId ?? this.babyId,
        assignedBaby: assignedBaby ?? this.assignedBaby,
        pop: pop ?? this.pop,
        mac: mac ?? this.mac,
        isConnected: isConnected ?? this.isConnected
      );

  static ScaleOperation(int state) {
    if (state == 1) return 'Operante';

    else return 'Não Operante';
  }

  static ScaleModel copyFrom(ScaleModel other) => ScaleModel(
        id: other.id,
        hash: other.hash,
        status: other.status,
        babyId: other.babyId,
        assignedBaby: other.assignedBaby,
        pop: other.pop,
        mac: other.mac,
        isConnected: other.isConnected
      );
}
