import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weight.dart';
import '../helper/conversions.dart';

enum _ChartMode { summary, detail }

class _DailyWeightSummary {
  final DateTime day;
  final List<WeightModel> measurements;
  final double medianWeight;
  final double minWeight;
  final double maxWeight;
  final double lastWeight;
  final int positiveMeasurementsCount;
  final int zeroMeasurementsCount;

  const _DailyWeightSummary({
    required this.day,
    required this.measurements,
    required this.medianWeight,
    required this.minWeight,
    required this.maxWeight,
    required this.lastWeight,
    required this.positiveMeasurementsCount,
    required this.zeroMeasurementsCount,
  });
}

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
  static final DateFormat _hourFormatter = DateFormat('HH:mm');
  static const double _fallbackChartHeight = 280;
  static const double _summaryEdgePadding = 0.6;
  static const double _dayEdgePaddingHours = 0.4;
  static const double _duplicateTimeOffsetHours = 0.03;

  late List<WeightModel> _sortedWeights;
  late List<DateTime> _availableMonths;
  int _selectedMonthIndex = 0;
  DateTime? _selectedDay;
  _ChartMode _chartMode = _ChartMode.summary;

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
    final previousSelectedDay = preserveCurrentMonth ? _selectedDay : null;

    _sortedWeights = _sanitizeWeights(widget.historicWeight ?? const <WeightModel>[]);
    _availableMonths = BabyWeightChart.availableMonths(_sortedWeights);

    if (_availableMonths.isEmpty) {
      _selectedMonthIndex = 0;
      _selectedDay = null;
      _chartMode = _ChartMode.summary;
      return;
    }

    if (previousMonth != null) {
      final preservedIndex = _availableMonths.indexWhere((month) => _isSameMonth(month, previousMonth));
      if (preservedIndex >= 0) {
        _selectedMonthIndex = preservedIndex;
        if (previousSelectedDay != null && _isSameMonth(previousSelectedDay, _availableMonths[_selectedMonthIndex])) {
          _selectedDay = previousSelectedDay;
        }
        return;
      }
    }

    _selectedMonthIndex = _availableMonths.length - 1;
    _selectedDay = null;
    _chartMode = _ChartMode.summary;
  }

  bool _isSameMonth(DateTime left, DateTime right) => left.year == right.year && left.month == right.month;
  bool _isSameDay(DateTime left, DateTime right) => left.year == right.year && left.month == right.month && left.day == right.day;

  void _changeMonth(int offset) {
    final nextIndex = _selectedMonthIndex + offset;
    if (nextIndex < 0 || nextIndex >= _availableMonths.length) {
      return;
    }

    setState(() {
      _selectedMonthIndex = nextIndex;
      _selectedDay = null;
      _chartMode = _ChartMode.summary;
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

  double _sanitizeWeight(double value) => value <= 0 ? 0 : value;

  List<WeightModel> _sanitizeWeights(List<WeightModel> weights) {
    final sanitized = weights.map((weight) => weight.copyWith(weight: _sanitizeWeight(weight.weight))).toList();
    sanitized.sort((a, b) => a.date.compareTo(b.date));
    return sanitized;
  }

  int _daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

  double _timeOfDayAsHour(DateTime value) {
    return value.hour + (value.minute / 60) + (value.second / 3600);
  }

  double _median(List<double> values) {
    final sortedValues = List<double>.from(values)..sort();
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) {
      return sortedValues[middle];
    }
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }

  List<_DailyWeightSummary> _buildDailySummaries(List<WeightModel> weights) {
    final grouped = <DateTime, List<WeightModel>>{};
    for (final weight in weights) {
      final day = DateTime(weight.date.year, weight.date.month, weight.date.day);
      grouped.putIfAbsent(day, () => <WeightModel>[]).add(weight);
    }

    final summaries = grouped.entries.map((entry) {
      final measurements = List<WeightModel>.from(entry.value)..sort((a, b) => a.date.compareTo(b.date));
      final values = measurements.map((item) => item.weight).toList();
      final positiveValues = values.where((value) => value > 0).toList();
      final valuesForMedian = positiveValues.isNotEmpty ? positiveValues : values;

      return _DailyWeightSummary(
        day: entry.key,
        measurements: measurements,
        medianWeight: _median(valuesForMedian),
        minWeight: values.reduce(math.min),
        maxWeight: values.reduce(math.max),
        lastWeight: measurements.last.weight,
        positiveMeasurementsCount: positiveValues.length,
        zeroMeasurementsCount: measurements.length - positiveValues.length,
      );
    }).toList();

    summaries.sort((a, b) => a.day.compareTo(b.day));
    return summaries;
  }

  DateTime? _resolveDetailDay(List<_DailyWeightSummary> summaries) {
    if (summaries.isEmpty) {
      return null;
    }
    if (_selectedDay == null) {
      return summaries.last.day;
    }

    for (final summary in summaries) {
      if (_isSameDay(summary.day, _selectedDay!)) {
        return summary.day;
      }
    }

    return summaries.last.day;
  }

  void _selectMode(_ChartMode mode, List<_DailyWeightSummary> summaries) {
    setState(() {
      _chartMode = mode;
      if (mode == _ChartMode.detail) {
        _selectedDay = _resolveDetailDay(summaries);
      }
    });
  }

  TextStyle _selectorLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
  }

  Widget _buildModeSelector(List<_DailyWeightSummary> summaries) {
    final selectedDetailDay = _resolveDetailDay(summaries);
    final detailLabel = selectedDetailDay == null ? 'Dia' : 'Dia ${_dayFormatter.format(selectedDetailDay)}';
    final labelStyle = _selectorLabelStyle(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ChoiceChip(
            label: Text('Resumo', style: labelStyle),
            selected: _chartMode == _ChartMode.summary,
            onSelected: (_) => _selectMode(_ChartMode.summary, summaries),
          ),
          ChoiceChip(
            label: Text(detailLabel, style: labelStyle),
            selected: _chartMode == _ChartMode.detail,
            onSelected: summaries.isEmpty ? null : (_) => _selectMode(_ChartMode.detail, summaries),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChart(
    List<_DailyWeightSummary> summaries,
    ColorScheme colorScheme,
    BoxConstraints constraints,
  ) {
    final allWeights = summaries.map((summary) => summary.medianWeight).toList();
    final spots = summaries.map((summary) => FlSpot(summary.day.day.toDouble(), summary.medianWeight)).toList();
    final minYValue = allWeights.reduce(math.min);
    final maxYValue = allWeights.reduce(math.max);
    final verticalPadding = math.max((maxYValue - minYValue).abs() * 0.15, 50.0).toDouble();
    final minY = math.max(0.0, minYValue - verticalPadding).toDouble();
    final maxY = (maxYValue + verticalPadding).toDouble();
    final selectedMonth = _availableMonths[_selectedMonthIndex];
    final daysInMonth = _daysInMonth(selectedMonth);
    final maxVisibleLabels = math.max(1, (constraints.maxWidth / 56).floor());
    final labelStep = math.max(1, (daysInMonth / maxVisibleLabels).ceil());

    Widget buildBottomTitle(double value, TitleMeta meta) {
      final roundedValue = value.round();
      final hasDayAlignment = (value - roundedValue).abs() <= 0.08;
      if (!hasDayAlignment || roundedValue < 1 || roundedValue > daysInMonth) {
        return const SizedBox.shrink();
      }

      final isLastLabel = roundedValue == daysInMonth;
      if ((roundedValue - 1) % labelStep != 0 && !isLastLabel) {
        return const SizedBox.shrink();
      }

      final labelDate = DateTime(selectedMonth.year, selectedMonth.month, roundedValue);
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: Text(
            _dayFormatter.format(labelDate),
            style: TextStyle(color: colorScheme.primary, fontSize: 10),
          ),
        ),
      );
    }

    Widget buildLeftTitle(double value, TitleMeta meta) {
      return Text(
        _formatWeight(value),
        style: TextStyle(color: colorScheme.primary, fontSize: 11),
      );
    }

    return LineChart(
      LineChartData(
        minX: 1 - _summaryEdgePadding,
        maxX: daysInMonth + _summaryEdgePadding,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots?.isNotEmpty == true) {
              final touchedIndex = response!.lineBarSpots!.first.spotIndex;
              final touchedDay = summaries[touchedIndex].day;
              setState(() {
                _selectedDay = touchedDay;
              });
            }
          },
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
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.08),
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
    );
  }

  Widget _buildDetailChart(
    List<WeightModel> dayWeights,
    DateTime selectedDay,
    ColorScheme colorScheme,
  ) {
    final plottedWeights = <WeightModel>[];
    final spots = <FlSpot>[];
    double? lastX;

    for (final weight in dayWeights) {
      var x = _timeOfDayAsHour(weight.date);
      if (lastX != null && (x - lastX).abs() < 0.0001) {
        x += _duplicateTimeOffsetHours;
      }
      plottedWeights.add(weight);
      spots.add(FlSpot(x, weight.weight));
      lastX = x;
    }

    final minYValue = dayWeights.map((weight) => weight.weight).reduce(math.min);
    final maxYValue = dayWeights.map((weight) => weight.weight).reduce(math.max);
    final verticalPadding = math.max((maxYValue - minYValue).abs() * 0.15, 30.0).toDouble();
    final minY = math.max(0.0, minYValue - verticalPadding).toDouble();
    final maxY = (maxYValue + verticalPadding).toDouble();
    final minX = math.max(0.0, spots.map((spot) => spot.x).reduce(math.min) - _dayEdgePaddingHours).toDouble();
    final maxX = math.min(24.0, spots.map((spot) => spot.x).reduce(math.max) + _dayEdgePaddingHours).toDouble();

    Widget buildBottomTitle(double value, TitleMeta meta) {
      final roundedHour = value.round();
      final hasHourAlignment = (value - roundedHour).abs() <= 0.08;
      if (!hasHourAlignment || roundedHour < 0 || roundedHour > 24 || roundedHour % 3 != 0) {
        return const SizedBox.shrink();
      }

      final labelDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, roundedHour % 24);
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: Text(
          _hourFormatter.format(labelDate),
          style: TextStyle(color: colorScheme.primary, fontSize: 10),
        ),
      );
    }

    Widget buildLeftTitle(double value, TitleMeta meta) {
      return Text(
        _formatWeight(value),
        style: TextStyle(color: colorScheme.primary, fontSize: 11),
      );
    }

    return LineChart(
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
          verticalInterval: 3,
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
              reservedSize: 30,
              interval: 3,
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
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.08),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicWeight == null || widget.historicWeight!.isEmpty || _availableMonths.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final selectedMonth = _availableMonths[_selectedMonthIndex];
    final monthWeights = BabyWeightChart.filterWeightsForMonth(_sortedWeights, selectedMonth);
    final summaries = _buildDailySummaries(monthWeights);
    final effectiveSelectedDay = _resolveDetailDay(summaries);
    final detailWeights = effectiveSelectedDay == null ? const <WeightModel>[] : monthWeights.where((weight) => _isSameDay(weight.date, effectiveSelectedDay)).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final selectorLabelStyle = _selectorLabelStyle(context);
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
              style: selectorLabelStyle.copyWith(fontSize: (selectorLabelStyle.fontSize ?? 16) + 4),
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
        if (summaries.isEmpty) {
          return const Center(child: Text('Sem dados suficientes'));
        }

        return AspectRatio(
          aspectRatio: constraints.maxWidth > 600 ? 2.0 : 1.65,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 20, top: 12, bottom: 16),
            child: _chartMode == _ChartMode.summary
                ? _buildSummaryChart(summaries, colorScheme, constraints)
                : (effectiveSelectedDay == null || detailWeights.isEmpty
                    ? const Center(child: Text('Sem dados suficientes'))
                    : _buildDetailChart(detailWeights, effectiveSelectedDay, colorScheme)),
          ),
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = <Widget>[
          monthSelector,
          _buildModeSelector(summaries),
          if (_chartMode == _ChartMode.detail && effectiveSelectedDay != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Detalhe do dia ${_dayFormatter.format(effectiveSelectedDay)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ];

        if (constraints.hasBoundedHeight) {
          return Column(
            children: [
              ...children,
              Expanded(child: chartArea),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...children,
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
