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
