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
