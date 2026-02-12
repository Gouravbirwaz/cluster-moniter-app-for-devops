import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniMetricChart extends StatelessWidget {
  final List<FlSpot> data;
  final Color color;
  final double maxY;

  const MiniMetricChart({
    super.key,
    required this.data,
    required this.color,
    this.maxY = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 80,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: data.isNotEmpty ? data.last.x : 0,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
