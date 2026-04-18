import 'package:flutter/material.dart';
import 'package:precious_weight/api/baby_api.dart';
import 'package:precious_weight/api/scale_api.dart';
import 'package:precious_weight/models/baby.dart';
import 'package:precious_weight/models/enums.dart';
import 'package:precious_weight/models/scales.dart';
import 'package:precious_weight/views/logs/logs_list.dart';

import '../../models/logs.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';

class LogsItens extends StatefulWidget {
  final LogType type;

  const LogsItens({Key? key, required this.type}) : super(key: key);

  @override
  _LogsItensState createState() => _LogsItensState();
}

class _LogsItensState extends State<LogsItens> {
  late Future<List<BabyModel>?> _babyFuture;
  late Future<List<ScaleModel>?> _scaleFuture;

  @override
  void initState() {
    super.initState();
    _babyFuture = _fetchBabies();
    _scaleFuture = _fetchScales();
  }

  Future<List<BabyModel>?> _fetchBabies() async {
    List<BabyModel>? babies;

    await SafeApi.call(
        context: context,
        apiCall: () async {
            final BabyApi api = BabyApi();
            babies = await api.listBabies();
        });

    return babies;
  }

  Future<List<ScaleModel>?> _fetchScales() async {
    List<ScaleModel>? scales;

    await SafeApi.call(
        context: context,
        apiCall: () async {
          final ScaleApi api = ScaleApi();
          scales = await api.listScales();
        });

    return scales;
  }

  FutureBuilder<List<ScaleModel>?> futureScales(){
    return FutureBuilder(future: _scaleFuture, builder:  (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final data = snapshot.data;
      if (data == null || data.isEmpty)
        return const Center(child: Text('No data found'));

      return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) => _buildScaleCard(data[index]),
      );
    });
  }

  FutureBuilder<List<BabyModel>?> futureBabies(){
    return FutureBuilder(future: _babyFuture, builder:  (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final data = snapshot.data;
      if (data == null || data.isEmpty)
        return const Center(child: Text('No data found'));

      return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) => _buildBabiesCard(data[index]),
      );
    });
  }

  Widget _buildBabiesCard(BabyModel baby) {
    return ElementsOfViews.CardToList(context, LogModel.getLogIcon(widget.type), '${baby.name}', 'Mãe: ${baby.motherName} | Nascimento: ${dateFormatter_objToDb.format(baby.birthDate!)}', () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LogsList(type: widget.type, babyId: baby.id)));
    });
  }
  Widget _buildScaleCard(ScaleModel scale) {
    final id = scale.babyId != null ? "${scale.id} - baby: ${scale.babyId}" :"${scale.id} - Sem bebê associado";
    return ElementsOfViews.CardToList(context, LogModel.getLogIcon(widget.type), id, 'Status: ${ScaleModel.ScaleOperation(scale.status)}', () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LogsList(type: widget.type, scaleId: scale.id,)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Histórico de ${LogModel.getNameFrom(widget.type)}'),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: widget.type == LogType.scale ? futureScales() : futureBabies()
            )));
  }
}
