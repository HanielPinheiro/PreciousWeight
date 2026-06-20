import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weight.dart';
import '../helper/conversions.dart';

class BabyWeightChart extends StatefulWidget {
  final List<WeightModel>? historicWeight;

  const BabyWeightChart({super.key, this.historicWeight});

  static const List<String> _monthNames = <String>[
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static List<DateTime> availableMonths(List<WeightModel> weights) {
    final seenMonths = <String>{};
    final sortedWeights = List<WeightModel>.from(weights)..sort((a, b) => a.date.compareTo(b.date));

    return sortedWeights
        .where((weight) => seenMonths.add(monthKey(weight.date)))
        .map((weight) => DateTime(weight.date.year, weight.date.month))
        .toList();
  }

  static Map<DateTime, List<WeightModel>> groupWeightsByMonth(List<WeightModel> weights) {
    final groupedWeights = <DateTime, List<WeightModel>>{};

    for (final weight in List<WeightModel>.from(weights)..sort((a, b) => a.date.compareTo(b.date))) {
      final month = DateTime(weight.date.year, weight.date.month);
      groupedWeights.putIfAbsent(month, () => <WeightModel>[]).add(weight);
    }

    return groupedWeights;
  }

  static List<WeightModel> filterWeightsForMonth(List<WeightModel> weights, DateTime month) {
    final monthDate = DateTime(month.year, month.month);
    final groupedWeights = groupWeightsByMonth(weights);

    return List<WeightModel>.from(groupedWeights[monthDate] ?? const <WeightModel>[]);
  }

  static String monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static String monthLabel(DateTime month) => '${_monthNames[month.month - 1]} de ${month.year}';

  @override
  State<BabyWeightChart> createState() => _BabyWeightChartState();
}

class _BabyWeightChartState extends State<BabyWeightChart> {
  static final DateFormat _dayFormatter = DateFormat('dd/MM');
  static const double _fallbackChartHeight = 280;

  late List<WeightModel> _sortedWeights;
  late List<DateTime> _availableMonths;
  int _selectedMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    _rebuildChartState();
  }

  @override
  void didUpdateWidget(covariant BabyWeightChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.historicWeight != oldWidget.historicWeight) {
      _rebuildChartState(preserveCurrentMonth: true);
    }
  }

  void _rebuildChartState({bool preserveCurrentMonth = false}) {
    final previousMonth = preserveCurrentMonth && _availableMonths.isNotEmpty ? _availableMonths[_selectedMonthIndex.clamp(0, _availableMonths.length - 1)] : null;

    _sortedWeights = List<WeightModel>.from(widget.historicWeight ?? const <WeightModel>[])..sort((a, b) => a.date.compareTo(b.date));
    _availableMonths = BabyWeightChart.availableMonths(_sortedWeights);

    if (_availableMonths.isEmpty) {
      _selectedMonthIndex = 0;
      return;
    }

    if (previousMonth != null) {
      final preservedIndex = _availableMonths.indexWhere((month) => _isSameMonth(month, previousMonth));
      if (preservedIndex >= 0) {
        _selectedMonthIndex = preservedIndex;
        return;
      }
    }

    _selectedMonthIndex = _availableMonths.length - 1;
  }

  bool _isSameMonth(DateTime left, DateTime right) => left.year == right.year && left.month == right.month;

  void _changeMonth(int offset) {
    final nextIndex = _selectedMonthIndex + offset;
    if (nextIndex < 0 || nextIndex >= _availableMonths.length) {
      return;
    }

    setState(() {
      _selectedMonthIndex = nextIndex;
    });
  }

  double _weightAxisInterval(double minY, double maxY) {
    final delta = (maxY - minY).abs();
    if (delta <= 0) {
      return 100;
    }

    final roughStep = delta / 4;
    final magnitude = math.pow(10, math.max(0, (math.log(roughStep) / math.ln10).floor())).toDouble();
    final normalizedStep = roughStep / magnitude;

    if (normalizedStep <= 1) {
      return magnitude;
    }
    if (normalizedStep <= 2) {
      return 2 * magnitude;
    }
    if (normalizedStep <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicWeight == null || widget.historicWeight!.isEmpty || _availableMonths.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final selectedMonth = _availableMonths[_selectedMonthIndex];
    final monthWeights = BabyWeightChart.filterWeightsForMonth(_sortedWeights, selectedMonth);
    final colorScheme = Theme.of(context).colorScheme;
    final monthSelector = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _selectedMonthIndex > 0 ? () => _changeMonth(-1) : null,
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'Mes anterior',
          ),
          Expanded(
            child: Text(
              BabyWeightChart.monthLabel(selectedMonth),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            onPressed: _selectedMonthIndex < _availableMonths.length - 1 ? () => _changeMonth(1) : null,
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: 'Proximo mes',
          ),
        ],
      ),
    );

    final chartArea = LayoutBuilder(
      builder: (context, constraints) {
        final weightsByDay = <DateTime, List<WeightModel>>{};
        for (final weight in monthWeights) {
          final dayKey = DateTime(weight.date.year, weight.date.month, weight.date.day);
          weightsByDay.putIfAbsent(dayKey, () => <WeightModel>[]).add(weight);
        }

        final measurementDays = weightsByDay.keys.toList()..sort();
        final daySlotByKey = <DateTime, int>{
          for (var i = 0; i < measurementDays.length; i++) measurementDays[i]: i,
        };
        final plottedWeights = <WeightModel>[];
        final spots = <FlSpot>[];

        for (final day in measurementDays) {
          final dayWeights = weightsByDay[day]!;
          final baseX = daySlotByKey[day]!.toDouble();
          final centeredOffset = (dayWeights.length - 1) / 2;

          for (var i = 0; i < dayWeights.length; i++) {
            final offsetX = dayWeights.length == 1 ? 0.0 : (i - centeredOffset) * 0.18;
            plottedWeights.add(dayWeights[i]);
            spots.add(FlSpot(baseX + offsetX, dayWeights[i].weight.toDouble()));
          }
        }

        final minX = -0.5;
        final maxX = measurementDays.length + minX;
        final minYValue = monthWeights.map((weight) => weight.weight).reduce(math.min).toDouble();
        final maxYValue = monthWeights.map((weight) => weight.weight).reduce(math.max).toDouble();
        final verticalPadding = math.max((maxYValue - minYValue).abs() * 0.15, 50.0).toDouble();
        final minY = math.max(0.0, minYValue - verticalPadding).toDouble();
        final maxY = (maxYValue + verticalPadding).toDouble();
        final maxVisibleLabels = math.max(1, (constraints.maxWidth / 56).floor());
        final labelStep = math.max(1, (measurementDays.length / maxVisibleLabels).ceil());

        Widget buildBottomTitle(double value, TitleMeta meta) {
          final roundedValue = value.round();
          if ((value - roundedValue).abs() > 0.001 || roundedValue < 0 || roundedValue >= measurementDays.length) {
            return const SizedBox.shrink();
          }

          final isLastLabel = roundedValue == measurementDays.length - 1;
          if (roundedValue % labelStep != 0 && !isLastLabel) {
            return const SizedBox.shrink();
          }

          final labelDate = measurementDays[roundedValue];
          return SideTitleWidget(
            meta: meta,
            space: 8,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Text(
                _dayFormatter.format(labelDate),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }

        Widget buildLeftTitle(double value, TitleMeta meta) {
          return Text(
            _formatWeight(value),
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 11,
            ),
          );
        }

        return AspectRatio(
          aspectRatio: constraints.maxWidth > 600 ? 2.0 : 1.65,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 20, top: 12, bottom: 16),
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipColor: (_) => colorScheme.surface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final weight = plottedWeights[spot.spotIndex];
                        return LineTooltipItem(
                          '${dateFormatter_log.format(weight.date)}\n${_formatWeight(weight.weight)} g',
                          TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  verticalInterval: 1,
                  horizontalInterval: _weightAxisInterval(minY, maxY),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 1,
                      getTitlesWidget: buildBottomTitle,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: _weightAxisInterval(minY, maxY),
                      getTitlesWidget: buildLeftTitle,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: colorScheme.primary),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: colorScheme.primary,
                    barWidth: 2,
                    isStrokeCapRound: false,
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.10),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: colorScheme.primary,
                        strokeWidth: 1.5,
                        strokeColor: colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return Column(
            children: [
              monthSelector,
              Expanded(child: chartArea),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            monthSelector,
            SizedBox(
              height: _fallbackChartHeight,
              child: chartArea,
            ),
          ],
        );
      },
    );
  }
}
