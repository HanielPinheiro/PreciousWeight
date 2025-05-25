import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/weight.dart';

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
              weight.date.difference(firstDate).inSeconds.toDouble(), // X-axis
              weight.weight.toDouble(), // Y-axis (weight)
            ))
        .toList();

    double maxX = spots.reduce((a, b) => a.x > b.x ? a : b).x;
    double minX = spots.reduce((a, b) => a.x < b.x ? a : b).x;
    double deltaX = maxX > minX ? maxX - minX : minX - maxX;

    double maxY = spots.reduce((a, b) => a.y > b.y ? a : b).y;
    double minY = spots.reduce((a, b) => a.y < b.y ? a : b).y;
    double deltaY = maxY > minY ? maxY - minY : minY - maxY;

    Widget buildAxisTitle(double value, TitleMeta meta) {
      return Text(value.toInt().toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ));
    }

    return LayoutBuilder(builder: (context, constraints) {
      return AspectRatio(
              aspectRatio: constraints.maxWidth > 600 ? 2.0 : 1.78 /*16.0/9.0*/,
              child: Padding(
                  padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 12),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipColor: (LineBarSpot touchedSpot) {
                            return Theme.of(context).colorScheme.surface;
                          },
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.x.toStringAsFixed(0)}, ${spot.y} g', // Your custom text
                                TextStyle(
                                  color: Theme.of(context).colorScheme.primary, // Text color
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 20,
                                  interval: deltaX / 2, //x axis
                                  getTitlesWidget: buildAxisTitle)),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  interval: deltaY / 2, // y axis
                                  getTitlesWidget: buildAxisTitle))),
                      borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).colorScheme.primary)),
                      lineBarsData: [
                        LineChartBarData(spots: spots, isCurved: false, color: Theme.of(context).colorScheme.primary, barWidth: 3, isStrokeCapRound: false, belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.onTertiary)),
                      ],
                    ),
                  )))
          // ]
          ;
    });
  }
}
