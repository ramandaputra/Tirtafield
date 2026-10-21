import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';
import '../models/approval_model.dart';
import '../mock/mock_data.dart';

abstract class ApprovalRepository {
  Future<List<ApprovalRequest>> getApprovals();
  Future<List<ApprovalRequest>> getApprovalsByUser(String userId);
  Future<List<ApprovalRequest>> getPendingApprovals();
  Future<ApprovalRequest> submitApproval(ApprovalRequest request);
  Future<ApprovalRequest> reviewApproval({
    required String approvalId,
    required ApprovalStatus status,
    required String reviewerName,
    String? notes,
  });
}

class ApiApprovalRepository implements ApprovalRepository {
  final MockApprovalRepository _fallbackMock = MockApprovalRepository();

  @override
  Future<List<ApprovalRequest>> getApprovals() async {
    try {
      final uri = Uri.parse('${ApiConfig.approvalUrl}?action=list');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((item) => _parseApproval(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return _fallbackMock.getApprovals();
  }

  @override
  Future<List<ApprovalRequest>> getApprovalsByUser(String userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.approvalUrl}?action=list&user_id=$userId&role=karyawan');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((item) => _parseApproval(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return _fallbackMock.getApprovalsByUser(userId);
  }

  @override
  Future<List<ApprovalRequest>> getPendingApprovals() async {
    final all = await getApprovals();
    return all.where((a) => a.isPending).toList();
  }

  @override
  Future<ApprovalRequest> submitApproval(ApprovalRequest request) async {
    try {
      final uri = Uri.parse('${ApiConfig.approvalUrl}?action=submit');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': request.userId,
              'user_nip': request.userNip,
              'nik': request.userNip,
              'user_name': request.userName,
              'type': request.type.name,
              'reason': request.reason,
              'start_date': request.startDate.toIso8601String(),
              'location_name': request.locationName,
              'latitude': request.latitude,
              'longitude': request.longitude,
              'distance_hq': request.distanceHq,
              'foto_url': request.fotoUrl,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final newId = body['data']['id']?.toString() ?? request.id;
          return request.copyWith(id: newId);
        }
      }
    } catch (_) {}
    return _fallbackMock.submitApproval(request);
  }

  @override
  Future<ApprovalRequest> reviewApproval({
    required String approvalId,
    required ApprovalStatus status,
    required String reviewerName,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.approvalUrl}?action=review');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'approval_id': approvalId,
              'status': status.name,
              'reviewer_name': reviewerName,
              'notes': notes ?? '',
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
    return _fallbackMock.reviewApproval(
      approvalId: approvalId,
      status: status,
      reviewerName: reviewerName,
      notes: notes,
    );
  }

  ApprovalRequest _parseApproval(Map<String, dynamic> item) {
    ApprovalType type = ApprovalType.luarRadius;
    final tStr = (item['type'] ?? '').toString();
    if (tStr.contains('koreksi') || tStr.contains('koreksiAbsen')) {
      type = ApprovalType.koreksiAbsen;
    }

    ApprovalStatus status = ApprovalStatus.pending;
    final sStr = (item['status'] ?? '').toString().toLowerCase();
    if (sStr == 'approved') status = ApprovalStatus.approved;
    if (sStr == 'rejected') status = ApprovalStatus.rejected;
    if (sStr == 'escalated') status = ApprovalStatus.escalated;

    DateTime subTime = DateTime.now();
    if (item['submitted_at'] != null) {
      subTime = DateTime.tryParse(item['submitted_at'].toString()) ?? DateTime.now();
    }

    DateTime? revTime;
    if (item['reviewed_at'] != null) {
      revTime = DateTime.tryParse(item['reviewed_at'].toString());
    }

    return ApprovalRequest(
      id: item['id'].toString(),
      userId: item['user_id']?.toString() ?? '1',
      userNip: item['user_nip']?.toString() ?? 'EMP',
      userName: item['user_name']?.toString() ?? 'Karyawan Lapangan',
      userDepartment: item['user_department']?.toString() ?? 'Operasional Lapangan',
      type: type,
      title: item['title']?.toString() ?? 'Presensi Lapangan',
      reason: item['reason']?.toString() ?? '',
      startDate: DateTime.tryParse(item['start_date']?.toString() ?? '') ?? subTime,
      endDate: DateTime.tryParse(item['end_date']?.toString() ?? '') ?? subTime,
      status: status,
      submittedAt: subTime,
      locationName: item['location_name']?.toString() ?? 'Kantor Penempatan',
      latitude: (item['latitude'] as num?)?.toDouble() ?? 0.92031,
      longitude: (item['longitude'] as num?)?.toDouble() ?? 104.46069,
      distanceHq: item['distance_hq']?.toString() ?? '4.2 km',
      officePlacement: item['office_placement']?.toString() ??
          'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
      fotoUrl: item['foto_url']?.toString(),
      isLate: item['is_late'] == true,
      attendanceTime: item['attendance_time']?.toString() ?? '08:00 WIB',
      reviewedBy: item['reviewed_by']?.toString(),
      reviewedAt: revTime,
      reviewNotes: item['review_notes']?.toString(),
    );
  }
}

class MockApprovalRepository implements ApprovalRepository {
  final List<ApprovalRequest> _approvals = MockData.getInitialApprovals();

  @override
  Future<List<ApprovalRequest>> getApprovals() async {
    return List.unmodifiable(_approvals);
  }

  @override
  Future<List<ApprovalRequest>> getApprovalsByUser(String userId) async {
    return _approvals.where((item) => item.userId == userId).toList();
  }

  @override
  Future<List<ApprovalRequest>> getPendingApprovals() async {
    return _approvals.where((item) => item.isPending).toList();
  }

  @override
  Future<ApprovalRequest> submitApproval(ApprovalRequest request) async {
    _approvals.insert(0, request);
    return request;
  }

  @override
  Future<ApprovalRequest> reviewApproval({
    required String approvalId,
    required ApprovalStatus status,
    required String reviewerName,
    String? notes,
  }) async {
    final index = _approvals.indexWhere((item) => item.id == approvalId);
    if (index == -1) {
      throw Exception('Approval request with ID $approvalId not found');
    }

    final updated = _approvals[index].copyWith(
      status: status,
      reviewedBy: reviewerName,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
    );

    _approvals[index] = updated;
    return updated;
  }
}
