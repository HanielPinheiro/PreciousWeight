import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:precious_weight/api/weight_api.dart';
import 'package:precious_weight/models/scales.dart';
import 'package:precious_weight/models/weight.dart';

import '../repository/helper/conversions.dart';

const String patient_id = "babyId";
const String patient_hospitalRegister = "babyHospitalId";
const String patient_name = "babyName";
const String patient_motherName = "babyMotherName";
const String patient_birthDate = "babyBirthDate";
const String patient_isActive = "babyState";
const String patient_qrCode = "babyImageAs64";
const String patient_qrCodeText = "babyImageText";
const String patient_scale= "assignedScale";
const String patient_weightHour= "babyWeightHour";

BabyModel babyFromJson(String str) => BabyModel.fromJson(json.decode(str));
List<BabyModel> babiesFromJson(String str) => List<BabyModel>.from(json.decode(str).map((x) => BabyModel.fromJson(x)));

String babyToJson(BabyModel data) => json.encode(data.toJson());
String babiesToJson(List<BabyModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BabyModel {
  final String hospitalRegister;
  final int? id;
  final String? name;
  final String? motherName;
  final DateTime? birthDate;
  final bool? isActive;
  final Image? qrCodeImage;
  final String? qrCodeText;
  final ScaleModel? assignedScale;
  final String? weightHour;

  BabyModel({required this.hospitalRegister, this.id, this.name, this.motherName, this.birthDate, this.isActive, this.qrCodeImage, this.qrCodeText, this.assignedScale, this.weightHour});

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    Image? qrImage;
    if (json[patient_qrCode].toString().isNotEmpty) {
      try {
        qrImage = Image.memory(base64.decode(json[patient_qrCode]), fit: BoxFit.fitWidth, errorBuilder: (context, error, stackTrace) {
          return Image.asset("assets/imgs/logo.png", fit: BoxFit.fitWidth);
        });
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    } else
      qrImage = Image.asset("assets/imgs/logo.png", fit: BoxFit.fitWidth);
    return BabyModel(id: json[patient_id], hospitalRegister: json[patient_hospitalRegister], name: json[patient_name], motherName: json[patient_motherName], birthDate: dateFormatter_dbToObj.parse(json[patient_birthDate]), qrCodeText: json[patient_qrCodeText], isActive: json[patient_isActive] == 1, qrCodeImage: qrImage, assignedScale: json[patient_scale] != null ? scaleFromJson(jsonEncode(json[patient_scale])) : null, weightHour: json[patient_weightHour]);
  }

  Map<String, dynamic> toJson() => {
        if (id != null) patient_id: id,
        if (qrCodeImage != null) patient_qrCode: qrCodeImage,
        patient_hospitalRegister: hospitalRegister,
        patient_name: name!,
        patient_motherName: motherName!,
        patient_birthDate: dateFormatter_dbToObj.format(birthDate!),
        patient_isActive: isActive! == true ? 1 : 0,
        patient_qrCodeText: qrCodeText!,
        patient_weightHour: weightHour!
      };

  Future<List<WeightModel>?> getWeights() async {
    final myId = id.toString();
    final api = new WeightApi();
    return await api.getBabyWeigths(myId);
  }

  BabyModel copyWith({
    String? hospitalRegister,
    int? id,
    String? name,
    String? motherName,
    DateTime? birthDate,
    bool? isActive,
    Image? qrCodeImage,
    String? qrCodeText,
    ScaleModel? assignedScale,
    String? weightHour,
  }) {
    return BabyModel(
      hospitalRegister: hospitalRegister ?? this.hospitalRegister,
      id: id ?? this.id,
      name: name ?? this.name,
      motherName: motherName ?? this.motherName,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
      qrCodeImage: qrCodeImage ?? this.qrCodeImage,
      qrCodeText: qrCodeText ?? this.qrCodeText,
      assignedScale: assignedScale ?? this.assignedScale,
      weightHour: weightHour ?? this.weightHour,
    );
  }
}
