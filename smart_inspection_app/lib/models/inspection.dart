class Inspection {
  final String id;
  final String siteId;
  final String inspectorId;
  final String category;
  final String status;
  final String? memo;
  final double? locationLat;
  final double? locationLng;
  final DateTime inspectedAt;
  final bool isSynced;
  final DateTime createdAt;

  Inspection({
    required this.id,
    required this.siteId,
    required this.inspectorId,
    required this.category,
    required this.status,
    this.memo,
    this.locationLat,
    this.locationLng,
    required this.inspectedAt,
    required this.isSynced,
    required this.createdAt,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id'],
        siteId: json['site_id'],
        inspectorId: json['inspector_id'],
        category: json['category'],
        status: json['status'],
        memo: json['memo'],
        locationLat: json['location_lat']?.toDouble(),
        locationLng: json['location_lng']?.toDouble(),
        inspectedAt: DateTime.parse(json['inspected_at']),
        isSynced: json['is_synced'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'site_id': siteId,
        'inspector_id': inspectorId,
        'category': category,
        'status': status,
        'memo': memo,
        'location_lat': locationLat,
        'location_lng': locationLng,
      };
}

class Defect {
  final String id;
  final String inspectionId;
  final String severity;
  final String description;
  final String? resolvedAt;
  final String? resolvedById;
  final DateTime createdAt;

  Defect({
    required this.id,
    required this.inspectionId,
    required this.severity,
    required this.description,
    this.resolvedAt,
    this.resolvedById,
    required this.createdAt,
  });

  factory Defect.fromJson(Map<String, dynamic> json) => Defect(
        id: json['id'],
        inspectionId: json['inspection_id'],
        severity: json['severity'],
        description: json['description'],
        resolvedAt: json['resolved_at'],
        resolvedById: json['resolved_by_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  bool get isResolved => resolvedAt != null;
}
