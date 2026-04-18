class DashboardSummary {
  final int totalSites;
  final int activeSites;
  final int totalInspections;
  final double passRate;
  final int pendingInspections;
  final int totalDefects;
  final int unresolvedDefects;

  DashboardSummary({
    required this.totalSites,
    required this.activeSites,
    required this.totalInspections,
    required this.passRate,
    required this.pendingInspections,
    required this.totalDefects,
    required this.unresolvedDefects,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        totalSites: json['total_sites'],
        activeSites: json['active_sites'],
        totalInspections: json['total_inspections'],
        passRate: (json['pass_rate'] as num).toDouble(),
        pendingInspections: json['pending_inspections'],
        totalDefects: json['total_defects'],
        unresolvedDefects: json['unresolved_defects'],
      );
}

class UnresolvedDefect {
  final String id;
  final String siteName;
  final String inspectionId;
  final String severity;
  final String description;
  final String createdAt;

  UnresolvedDefect({
    required this.id,
    required this.siteName,
    required this.inspectionId,
    required this.severity,
    required this.description,
    required this.createdAt,
  });

  factory UnresolvedDefect.fromJson(Map<String, dynamic> json) => UnresolvedDefect(
        id: json['id'],
        siteName: json['site_name'],
        inspectionId: json['inspection_id'],
        severity: json['severity'],
        description: json['description'],
        createdAt: json['created_at'],
      );
}

class DailyInspectionStat {
  final String date;
  final int count;
  final int passCount;

  DailyInspectionStat({required this.date, required this.count, required this.passCount});

  factory DailyInspectionStat.fromJson(Map<String, dynamic> json) => DailyInspectionStat(
        date: json['date'],
        count: json['count'],
        passCount: json['pass_count'],
      );
}

class DefectSeverityStat {
  final int critical;
  final int major;
  final int minor;
  final int total;

  DefectSeverityStat({required this.critical, required this.major, required this.minor, required this.total});

  factory DefectSeverityStat.fromJson(Map<String, dynamic> json) => DefectSeverityStat(
        critical: json['critical'],
        major: json['major'],
        minor: json['minor'],
        total: json['total'],
      );
}

class WeeklyStats {
  final List<DailyInspectionStat> dailyInspections;
  final DefectSeverityStat defectSeverity;

  WeeklyStats({required this.dailyInspections, required this.defectSeverity});

  factory WeeklyStats.fromJson(Map<String, dynamic> json) => WeeklyStats(
        dailyInspections: (json['daily_inspections'] as List)
            .map((e) => DailyInspectionStat.fromJson(e))
            .toList(),
        defectSeverity: DefectSeverityStat.fromJson(json['defect_severity']),
      );
}
