enum ApprovalType {
  cuti('Cuti Tahunan'),
  izin('Izin Tidak Masuk'),
  sakit('Surat Sakit'),
  lembur('Pengajuan Lembur'),
  koreksiAbsen('Koreksi Absensi');

  final String label;
  const ApprovalType(this.label);
}

enum ApprovalStatus {
  pending('Menunggu', 'Menunggu persetujuan Direktur'),
  approved('Disetujui', 'Telah disetujui oleh Direktur'),
  rejected('Ditolak', 'Permohonan ditolak');

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
  });

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;

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
    );
  }
}
