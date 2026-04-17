class Site {
  final String id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? managerId;
  final DateTime createdAt;

  Site({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    required this.status,
    this.startDate,
    this.endDate,
    this.managerId,
    required this.createdAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        lat: json['lat']?.toDouble(),
        lng: json['lng']?.toDouble(),
        status: json['status'],
        startDate: json['start_date'],
        endDate: json['end_date'],
        managerId: json['manager_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'start_date': startDate,
        'end_date': endDate,
      };
}
