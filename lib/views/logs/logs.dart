import 'package:flutter/material.dart';
import '../../models/logs/logs_repository.dart';

class LogsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ListView(
        children: LogsRepository.GetLogsLikeCards(context),
      ),
    );
  }
}