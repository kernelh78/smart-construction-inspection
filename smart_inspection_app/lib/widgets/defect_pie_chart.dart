import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard.dart';

class DefectPieChart extends StatelessWidget {
  final DefectSeverityStat stat;

  const DefectPieChart({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    if (stat.total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('미결 결함 없음', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final sections = [
      if (stat.critical > 0)
        PieChartSectionData(
          value: stat.critical.toDouble(),
          color: Colors.red.shade600,
          title: '심각\n${stat.critical}',
          radius: 56,
          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      if (stat.major > 0)
        PieChartSectionData(
          value: stat.major.toDouble(),
          color: Colors.orange.shade600,
          title: '주요\n${stat.major}',
          radius: 56,
          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      if (stat.minor > 0)
        PieChartSectionData(
          value: stat.minor.toDouble(),
          color: Colors.yellow.shade700,
          title: '경미\n${stat.minor}',
          radius: 56,
          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('미결 결함 분포 (총 ${stat.total}건)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: PieChart(PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 32,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
