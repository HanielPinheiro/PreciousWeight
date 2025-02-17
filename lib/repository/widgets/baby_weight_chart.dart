import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/weight/weight.dart';

class BabyWeightChart extends StatelessWidget {
  final List<WeightModel>? historicWeight;

  const BabyWeightChart({super.key, this.historicWeight});

  @override
  Widget build(BuildContext context) {
    if (historicWeight == null)
      return const Center(child: Text('No data available'));
    else if (historicWeight!.isEmpty) return const Center(child: Text('No data available'));

    // Sort by date
    historicWeight!.sort((a, b) => a.date.compareTo(b.date));

    // Normalize dates: first date as zero
    DateTime firstDate = historicWeight!.first.date;
    List<FlSpot> spots = historicWeight!
        .map((weight) => FlSpot(
              weight.date.difference(firstDate).inDays.toDouble(), // X-axis
              weight.weight.toDouble(), // Y-axis (weight)
            ))
        .toList();

   return Stack(children: <Widget>[
      AspectRatio(aspectRatio: 2,
      child: Padding(
          padding: const EdgeInsets.only(right: 15,left: 10,top: 24,bottom: 12),
          child:LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,reservedSize: 30, interval: 80)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,reservedSize: 42, interval: 1200))
            ),
            borderData: FlBorderData( show: true,border: Border.all(color: const Color(0xff37434d))),
            lineBarsData: [
              LineChartBarData(spots: spots, isCurved: true, color: Colors.blue, barWidth: 3, isStrokeCapRound: true, belowBarData: BarAreaData(show: false)),
            ],
          ),
        )))]
    );
  }
}
