enum ApprovalType {
  koreksiAbsen('Koreksi Presensi'),
  luarRadius('Presensi Luar Radius / Lapangan');

  final String label;
  const ApprovalType(this.label);
}

enum ApprovalStatus {
  pending('Menunggu', 'Menunggu persetujuan Admin (Tingkat 1)'),
  approved('Disetujui', 'Telah disetujui'),
  rejected('Ditolak', 'Permohonan ditolak'),
  escalated('Eskalasi', 'Diteruskan ke Superadmin IT');

  final String label;
  final String description;
  const ApprovalStatus(this.label, this.description);
}

class ApprovalRequest {
  final String id;
  final String userId;
  final String userName;
  final String userDepartment;
  final ApprovalType type;
  final String title;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final ApprovalStatus status;
  final DateTime submittedAt;
  final String? attachmentUrl;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? fotoUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? distanceHq;
  final String? officePlacement;
  final String? userNip;
  final bool isLate;
  final String? attendanceTime;

  const ApprovalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userDepartment,
    required this.type,
    required this.title,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.submittedAt,
    this.attachmentUrl,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.fotoUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.distanceHq,
    this.officePlacement = 'Kantor Pusat Tanjung Pinang',
    this.userNip,
    this.isLate = false,
    this.attendanceTime,
  });

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;
  bool get isEscalated => status == ApprovalStatus.escalated;

  String get distancePlacementOffice {
    final dist = distanceHq ?? '4.2 km';
    final office = officePlacement ?? 'Kantor Pusat Tanjung Pinang';
    if (dist.toLowerCase().contains('kantor') || dist.toLowerCase().contains('dari')) {
      return dist;
    }
    return '$dist dari kantor penempatan ($office)';
  }

  ApprovalRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userDepartment,
    ApprovalType? type,
    String? title,
    String? reason,
    DateTime? startDate,
    DateTime? endDate,
    ApprovalStatus? status,
    DateTime? submittedAt,
    String? attachmentUrl,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? fotoUrl,
    String? locationName,
    double? latitude,
    double? longitude,
    String? distanceHq,
    String? officePlacement,
    String? userNip,
    bool? isLate,
    String? attendanceTime,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userDepartment: userDepartment ?? this.userDepartment,
      type: type ?? this.type,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceHq: distanceHq ?? this.distanceHq,
      officePlacement: officePlacement ?? this.officePlacement,
      userNip: userNip ?? this.userNip,
      isLate: isLate ?? this.isLate,
      attendanceTime: attendanceTime ?? this.attendanceTime,
    );
  }
}
