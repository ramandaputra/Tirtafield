import 'package:flutter/material.dart';
import '../data/models/approval_model.dart';
import '../data/repositories/approval_repository.dart';

class ApprovalProvider extends ChangeNotifier {
  final ApprovalRepository _repository;
  List<ApprovalRequest> _allApprovals = [];
  List<ApprovalRequest> _userApprovals = [];
  bool _isLoading = false;
  String? _errorMessage;

  ApprovalProvider({required ApprovalRepository repository})
      : _repository = repository;

  List<ApprovalRequest> get allApprovals => List.unmodifiable(_allApprovals);
  List<ApprovalRequest> get userApprovals => List.unmodifiable(_userApprovals);
  List<ApprovalRequest> get pendingApprovals =>
      _allApprovals.where((a) => a.isPending).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllApprovals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allApprovals = await _repository.getApprovals();
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar permohonan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserApprovals(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userApprovals = await _repository.getApprovalsByUser(userId);
    } catch (e) {
      _errorMessage = 'Gagal memuat permohonan pengguna: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest(ApprovalRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.submitApproval(request);
      _allApprovals.insert(0, created);
      _userApprovals.insert(0, created);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengajukan permohonan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reviewRequest({
    required String approvalId,
    required ApprovalStatus status,
    required String reviewerName,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.reviewApproval(
        approvalId: approvalId,
        status: status,
        reviewerName: reviewerName,
        notes: notes,
      );

      // Update in all approvals
      final idxAll = _allApprovals.indexWhere((a) => a.id == approvalId);
      if (idxAll != -1) _allApprovals[idxAll] = updated;

      // Update in user approvals
      final idxUser = _userApprovals.indexWhere((a) => a.id == approvalId);
      if (idxUser != -1) _userApprovals[idxUser] = updated;

      return true;
    } catch (e) {
      _errorMessage = 'Gagal memproses approval: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
