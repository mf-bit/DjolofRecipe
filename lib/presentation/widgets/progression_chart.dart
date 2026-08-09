import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/domain.dart';

/// The metric to visualize on the progression chart.
enum ProgressionMetric {
  maxWeight('Max Weight', 'kg', Icons.fitness_center),
  maxReps('Max Reps', 'reps', Icons.repeat),
  totalVolume('Total Volume', 'kg', Icons.show_chart);

  const ProgressionMetric(this.label, this.unit, this.icon);

  final String label;
  final String unit;
  final IconData icon;
}

/// A session data point for chart plotting.
class ChartDataPoint {
  const ChartDataPoint({
    required this.date,
    required this.value,
    required this.workoutExercise,
  });

  final DateTime date;
  final double value;
  final WorkoutExercise workoutExercise;
}

/// Interactive chart displaying weight, repetition, or volume progression.
class ProgressionChart extends StatefulWidget {
  const ProgressionChart({
    super.key,
    required this.sessions,
    this.initialMetric = ProgressionMetric.maxWeight,
  });

  final List<({DateTime performedAt, WorkoutExercise workoutExercise})>
  sessions;
  final ProgressionMetric initialMetric;

  @override
  State<ProgressionChart> createState() => _ProgressionChartState();
}

class _ProgressionChartState extends State<ProgressionChart> {
  late ProgressionMetric _selectedMetric;
  int? _selectedPointIndex;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
  }

  List<ChartDataPoint> _extractPoints() {
    // Sort chronologically (earliest to latest) for the chart
    final sorted = List.of(widget.sessions)
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

    final points = <ChartDataPoint>[];
    for (final session in sorted) {
      if (session.workoutExercise.sets.isEmpty) continue;
      double value = 0;
      switch (_selectedMetric) {
        case ProgressionMetric.maxWeight:
          value = session.workoutExercise.sets
              .map((s) => s.weight)
              .reduce(math.max);
          break;
        case ProgressionMetric.maxReps:
          value = session.workoutExercise.sets
              .map((s) => s.repetitions.toDouble())
              .reduce(math.max);
          break;
        case ProgressionMetric.totalVolume:
          value = session.workoutExercise.sets.fold<double>(
            0,
            (sum, s) => sum + (s.weight * s.repetitions),
          );
          break;
      }
      points.add(
        ChartDataPoint(
          date: session.performedAt,
          value: value,
          workoutExercise: session.workoutExercise,
        ),
      );
    }
    return points;
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()} ${_selectedMetric.unit}';
    }
    return '${value.toStringAsFixed(1)} ${_selectedMetric.unit}';
  }

  static String _formatShortDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day}';
  }

  static String _formatFullDate(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final points = _extractPoints();
    final colorScheme = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedPoint =
        _selectedPointIndex != null && _selectedPointIndex! < points.length
        ? points[_selectedPointIndex!]
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression Chart',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${points.length} ${points.length == 1 ? 'session' : 'sessions'}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ProgressionMetric>(
              segments: ProgressionMetric.values
                  .map((metric) {
                    return ButtonSegment<ProgressionMetric>(
                      value: metric,
                      label: Text(
                        metric.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: Icon(metric.icon, size: 16),
                    );
                  })
                  .toList(growable: false),
              selected: {_selectedMetric},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedMetric = newSelection.first;
                  _selectedPointIndex = null;
                });
              },
            ),
            const SizedBox(height: 16),
            // Tooltip banner if point is selected
            if (selectedPoint != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatFullDate(selectedPoint.date),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatValue(selectedPoint.value),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(
                        details.globalPosition,
                      );
                      _handleTouch(localPos, constraints.biggest, points);
                    },
                    onPanUpdate: (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(
                        details.globalPosition,
                      );
                      _handleTouch(localPos, constraints.biggest, points);
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 200),
                      painter: _ChartPainter(
                        points: points,
                        selectedPointIndex: _selectedPointIndex,
                        primaryColor: colorScheme.primary,
                        gridColor: colorScheme.outlineVariant.withAlpha(90),
                        labelColor: colorScheme.onSurfaceVariant,
                        surfaceColor: colorScheme.surface,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatShortDate(points.first.date),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colorScheme.outline),
                ),
                Text(
                  'Tap data points to view details',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  _formatShortDate(points.last.date),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleTouch(Offset localPos, Size size, List<ChartDataPoint> points) {
    if (points.isEmpty) return;
    const padding = EdgeInsets.fromLTRB(40, 16, 16, 24);
    final chartWidth = size.width - padding.left - padding.right;

    if (points.length == 1) {
      setState(() => _selectedPointIndex = 0);
      return;
    }

    final stepX = chartWidth / (points.length - 1);
    final touchX = localPos.dx - padding.left;
    final closestIndex = (touchX / stepX).round().clamp(0, points.length - 1);

    setState(() {
      _selectedPointIndex = closestIndex;
    });
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.selectedPointIndex,
    required this.primaryColor,
    required this.gridColor,
    required this.labelColor,
    required this.surfaceColor,
  });

  final List<ChartDataPoint> points;
  final int? selectedPointIndex;
  final Color primaryColor;
  final Color gridColor;
  final Color labelColor;
  final Color surfaceColor;

  static const _padding = EdgeInsets.fromLTRB(40, 16, 16, 24);

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = _padding.left;
    final chartTop = _padding.top;
    final chartRight = size.width - _padding.right;
    final chartBottom = size.height - _padding.bottom;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    if (points.isEmpty) return;

    double minValue = points.map((p) => p.value).reduce(math.min);
    double maxValue = points.map((p) => p.value).reduce(math.max);

    // Provide padding for flat charts or single points
    if (minValue == maxValue) {
      minValue = math.max(0, minValue - 5);
      maxValue = maxValue + 5;
    } else {
      final valuePadding = (maxValue - minValue) * 0.15;
      minValue = math.max(0, minValue - valuePadding);
      maxValue = maxValue + valuePadding;
    }

    final valueRange = maxValue - minValue;

    // Draw horizontal grid lines and Y-axis labels
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    const horizontalGridCount = 4;
    for (var i = 0; i <= horizontalGridCount; i++) {
      final y = chartTop + chartHeight * (1 - (i / horizontalGridCount));
      final val = minValue + (valueRange * (i / horizontalGridCount));

      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final valText = val == val.roundToDouble()
          ? '${val.toInt()}'
          : val.toStringAsFixed(1);
      final textSpan = TextSpan(text: valText, style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: chartLeft - 6);

      tp.paint(canvas, Offset(chartLeft - tp.width - 6, y - tp.height / 2));
    }

    // Compute pixel coordinates for points
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + (i / (points.length - 1)) * chartWidth;
      final y =
          chartBottom -
          ((points[i].value - minValue) / valueRange) * chartHeight;
      offsets.add(Offset(x, y));
    }

    // Draw gradient area under the curve
    if (offsets.length > 1) {
      final path = Path();
      path.moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }
      path.lineTo(offsets.last.dx, chartBottom);
      path.lineTo(offsets.first.dx, chartBottom);
      path.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryColor.withAlpha(80), primaryColor.withAlpha(5)],
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    }

    // Draw the chart line
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (offsets.length > 1) {
      final linePath = Path();
      linePath.moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        linePath.lineTo(offsets[i].dx, offsets[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final pointInnerPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final isSelected = selectedPointIndex == i;

      if (isSelected) {
        // Vertical indicator line for selected point
        final selectedLinePaint = Paint()
          ..color = primaryColor.withAlpha(120)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(offset.dx, chartTop),
          Offset(offset.dx, chartBottom),
          selectedLinePaint,
        );

        // Highlight ring
        canvas.drawCircle(
          offset,
          8,
          Paint()..color = primaryColor.withAlpha(60),
        );
        canvas.drawCircle(offset, 6, pointPaint);
        canvas.drawCircle(offset, 3, pointInnerPaint);
      } else {
        canvas.drawCircle(offset, 4.5, pointPaint);
        canvas.drawCircle(offset, 2.5, pointInnerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedPointIndex != selectedPointIndex ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.gridColor != gridColor;
  }
}
