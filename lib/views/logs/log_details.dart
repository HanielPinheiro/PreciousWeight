import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:precious_weight/models/baby.dart';
import 'package:precious_weight/models/scales.dart';
import 'package:precious_weight/models/weight.dart';
import 'package:precious_weight/repository/helper/conversions.dart';
import '../../models/logs.dart';
import '../../repository/widgets/elements.dart';

class LogDetails extends StatelessWidget {
  const LogDetails({super.key, required this.log});

  final LogModel log;

  List<Widget> _renderLog(BuildContext context) {
    return [
      ElementsOfViews.CardToText(context, 'Operação no BD: ${log.revision}'),
      ElementsOfViews.CardToText(context, 'Tipo de Operação: ${log.getActionText()}'),
      ElementsOfViews.CardToText(context, 'Data: ${dateFormatter_log.format(log.revisionDate)}'),
      if (log.username != null) ElementsOfViews.CardToText(context, 'Usuário: ${log.username}'),
      const SizedBox(height: 40),
      ElementsOfViews.CardToText(context, 'Dados do Relatório:'),
      const SizedBox(height: 40),
    ];
  }

  List<Widget>? _renderBaby(BuildContext context, BabyModel? parsedBaby) {
    if (parsedBaby == null) return null;
    return [
      ElementsOfViews.CardToText(context, 'ID: ${parsedBaby.id.toString()}'),
      ElementsOfViews.CardToText(context, 'Registro Hospitalar: ${parsedBaby.hospitalRegister.toString()}'),
      ElementsOfViews.CardToText(context, 'Estado: ${parsedBaby.isActive! ? 'Internado / Em tratamento' : 'De alta'}'),
      ElementsOfViews.CardToText(context, 'Nome: ${parsedBaby.name.toString()}'),
      ElementsOfViews.CardToText(context, 'Nome da mãe: ${parsedBaby.motherName.toString()}'),
      ElementsOfViews.CardToText(context, 'Data de Nascimento: ${dateFormatter_objToDb.format(parsedBaby.birthDate!)}'),
      SizedBox(height: 40),
      parsedBaby.hasQrCode ? ElementsOfViews.CardToText(context, 'Tem imagem para identificação') : ElementsOfViews.CardToText(context, 'Texto do Qr Code:\n ${parsedBaby.qrCodeText.toString()}'),
      SizedBox(height: 10),
    ];
  }

  List<Widget>? _renderScale(BuildContext context, ScaleModel? parsedScale) {
    if (parsedScale == null) return null;

    return [
      const SizedBox(height: 20),
      ElementsOfViews.CardToText(context, 'ID: ${parsedScale.id}'),
      ElementsOfViews.CardToText(context, 'Bebe vinculado: ${parsedScale.babyId ?? 'Não há'}'),
      ElementsOfViews.CardToText(context, 'Estado: ${ScaleModel.ScaleOperation(parsedScale.status)}'),
      ElementsOfViews.CardToText(context, 'Código: ${parsedScale.hash}'),
      const SizedBox(height: 20),
    ];
  }

  List<Widget>? _renderWeight(BuildContext context, WeightModel? parsedWeight) {
    if (parsedWeight == null) return null;

    return [
      ElementsOfViews.CardToText(context, 'ID: ${parsedWeight.id}'),
      ElementsOfViews.CardToText(context, 'Data: ${dateFormatter_objToDb.format(parsedWeight.date)}'),
      ElementsOfViews.CardToText(context, 'Bebê ID: ${parsedWeight.babyId}'),
      ElementsOfViews.CardToText(context, 'Balança ID: ${parsedWeight.scaleId}'),
      ElementsOfViews.CardToText(context, 'Peso: ${parsedWeight.weight}g'),
      const SizedBox(height: 20),
    ];
  }

  @override
  Widget build(BuildContext context) {
    BabyModel? parsedBaby;
    ScaleModel? parsedScale;
    WeightModel? parsedWeight;

    final entityJson = jsonEncode(log.entity);
    try {
      parsedBaby = babyFromJson(entityJson);
    } catch (e) {
      /*Ignore*/
    }
    try {
      parsedScale = scaleFromJson(entityJson);
    } catch (e) {
      /*Ignore*/
    }
    try {
      parsedWeight = weightFromJson(entityJson);
    } catch (e) {
      /*Ignore*/
    }

    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Relatório'),
            body: ListView(children: [
              ..._renderLog(context),
              if (parsedBaby != null) ...?_renderBaby(context, parsedBaby),
              if (parsedScale != null) ...?_renderScale(context, parsedScale),
              if (parsedWeight != null) ...?_renderWeight(context, parsedWeight),
              if (parsedBaby == null && parsedScale == null && parsedWeight == null) ElementsOfViews.CardToText(context, 'Tipo de registro não reconhecido'),
            ])));
  }
}
