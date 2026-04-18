class InspectionPhoto {
  final String id;
  final String inspectionId;
  final String s3Key;
  final String? ocrResult;
  final String takenAt;
  final String? url;

  InspectionPhoto({
    required this.id,
    required this.inspectionId,
    required this.s3Key,
    this.ocrResult,
    required this.takenAt,
    this.url,
  });

  factory InspectionPhoto.fromJson(Map<String, dynamic> json) {
    return InspectionPhoto(
      id: json['id'] as String,
      inspectionId: json['inspection_id'] as String,
      s3Key: json['s3_key'] as String,
      ocrResult: json['ocr_result'] as String?,
      takenAt: json['taken_at'] as String,
      url: json['url'] as String?,
    );
  }
}
