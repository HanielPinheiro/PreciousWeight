import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:precious_weight/models/enums.dart';

import '../../api/logs_api.dart';
import '../../models/logs.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';
import 'log_details.dart';

class LogsList extends StatefulWidget {
  final LogType type;
  final int? babyId;
  final int? scaleId;

  const LogsList({Key? key, required this.type, this.babyId, this.scaleId}) : super(key: key);

  @override
  _LogsListState createState() => _LogsListState();
}

class _LogsListState extends State<LogsList> {
  late Future<List<LogModel>?> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
  }

  Future<List<LogModel>?> _fetchLogs() async {
    final LogsApi api = LogsApi();
    List<LogModel>? logs;

    await SafeApi.call(
        context: context,
        apiCall: () async {
          if (widget.type == LogType.baby) {
            logs = await api.listBabies('${widget.babyId!}');
          } else if (widget.type == LogType.scale) {
            logs = await api.listScales('${widget.scaleId!}');
          } else {
            logs = await api.listWeights('${widget.babyId!}');
          }
        });

    return logs;
  }

  Widget _buildListCard(LogModel log) {
    return ElementsOfViews.CardToList(context, LogModel.getLogIcon(widget.type), '${log.revision} - ${log.getActionText()}', 'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(log.revisionDate)}', () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LogDetails(log: log)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Histórico de ${LogModel.getNameFrom(widget.type)}'),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<List<LogModel>?>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final logs = snapshot.data;

                  if (logs == null || logs.isEmpty) {
                    return const Center(child: Text('No logs found'));
                  }

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) => _buildListCard(logs[index]),
                  );
                },
              ),
            )));
  }
}
