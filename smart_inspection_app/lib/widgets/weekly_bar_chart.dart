import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<DailyInspectionStat> data;

  const WeeklyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<int>(1, (m, e) => e.count > m ? e.count : m).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('주간 점검 현황',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: (maxY + 1),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(data[i].date,
                                style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(data.length, (i) {
                    final d = data[i];
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: d.count.toDouble(),
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: [
                          BarChartRodStackItem(0, d.passCount.toDouble(), Colors.green.shade400),
                          BarChartRodStackItem(
                              d.passCount.toDouble(), d.count.toDouble(), Colors.blue.shade200),
                        ],
                      ),
                    ]);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [
              _legend(Colors.green.shade400, '합격'),
              const SizedBox(width: 12),
              _legend(Colors.blue.shade200, '진행/불합격'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
}
