import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../data/mock/mock_data.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final List<UserModel> _availableUsers = List.from(MockData.initialUsers);
  late UserModel _currentUser;
  bool _isAuthenticated = false;
  String? _loginError;

  AuthProvider() {
    // Default to Karyawan
    _currentUser = _availableUsers.first;
  }

  UserModel get currentUser => _currentUser;
  List<UserModel> get availableUsers => List.unmodifiable(_availableUsers);
  UserRole get currentRole => _currentUser.role;
  bool get isAuthenticated => _isAuthenticated;
  String? get loginError => _loginError;

  bool get isKaryawan => _currentUser.role == UserRole.karyawan;
  bool get isDirektur => _currentUser.role == UserRole.direktur;
  bool get isStaffIT => _currentUser.role == UserRole.staffIT;

  /// Login validation with NIK and PIN against MySQL database
  Future<bool> login(String nik, String pin) async {
    _loginError = null;
    notifyListeners();

    // 1. Try authentication against MySQL database via Laragon API
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nik': nik.trim(), 'pin': pin.trim()}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final d = body['data'];
          UserRole role = UserRole.karyawan;
          if (d['role'] == 'direktur') {
            role = UserRole.direktur;
          } else if (d['role'] == 'staffIT') {
            role = UserRole.staffIT;
          }

          _currentUser = UserModel(
            id: d['id'].toString(),
            nip: d['nip'].toString(),
            name: d['name'].toString(),
            email: d['email'].toString(),
            pin: d['pin'].toString(),
            role: role,
            department: d['department'].toString(),
            position: d['position'].toString(),
            avatarUrl: d['avatar_url']?.toString(),
            officeId: d['office_id']?.toString() ?? d['officeId']?.toString() ?? 'hq',
            officeName: d['office_name']?.toString() ??
                d['officeName']?.toString() ??
                'Kantor Pusat Tirtafield Tanjung Pinang',
          );
          _isAuthenticated = true;
          _loginError = null;
          notifyListeners();
          return true;
        } else {
          _loginError = body['message'] ?? 'Login gagal.';
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        _loginError = body['message'] ?? 'NIP atau PIN salah.';
        notifyListeners();
        return false;
      }
    } catch (_) {
      // If network/API unreachable, fallback to local mock users
    }

    final normalizedNik = nik.trim().toLowerCase();
    final normalizedPin = pin.trim();

    // Look for matching user by NIP / NIK in fallback mock
    final matchedUser = _availableUsers.firstWhere(
      (u) =>
          u.nip.toLowerCase() == normalizedNik ||
          u.id.toLowerCase() == normalizedNik,
      orElse: () => const UserModel(
        id: '',
        nip: '',
        name: '',
        email: '',
        role: UserRole.karyawan,
        department: '',
        position: '',
      ),
    );

    if (matchedUser.id.isEmpty) {
      _loginError = 'NIK / NIP tidak terdaftar dalam sistem database.';
      notifyListeners();
      return false;
    }

    if (matchedUser.pin != normalizedPin) {
      _loginError = 'PIN yang Anda masukkan salah. Default PIN demo: 123456';
      notifyListeners();
      return false;
    }

    _currentUser = matchedUser;
    _isAuthenticated = true;
    _loginError = null;
    notifyListeners();
    return true;
  }

  /// Logout action
  void logout() {
    _isAuthenticated = false;
    _loginError = null;
    notifyListeners();
  }

  /// Switch user to another role
  void switchUserByRole(UserRole role) {
    final matchedUser = _availableUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => _currentUser,
    );
    _currentUser = matchedUser;
    notifyListeners();
  }

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Update user profile photo (Dapat dilakukan oleh akun user sendiri)
  Future<bool> updateProfilePhoto(String newAvatarUrl) async {
    _currentUser = _currentUser.copyWith(avatarUrl: newAvatarUrl);
    final idx = _availableUsers.indexWhere((u) => u.id == _currentUser.id);
    if (idx != -1) {
      _availableUsers[idx] = _currentUser;
    }
    notifyListeners();

    try {
      await http
          .post(
            Uri.parse(ApiConfig.updateProfileUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': _currentUser.id,
              'nik': _currentUser.nip,
              'avatar_url': newAvatarUrl,
              'actor_role': _currentUser.role.name,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateCurrentUserProfile({
    required String newName,
    required String newDepartment,
    String? newPosition,
    String? newPhone,
  }) async {
    final oldUser = _currentUser;
    final updated = oldUser.copyWith(
      name: newName,
      department: newDepartment,
      position: newPosition ?? oldUser.position,
      phone: newPhone ?? oldUser.phone,
    );
    _currentUser = updated;
    final idx = _availableUsers.indexWhere((u) => u.id == _currentUser.id);
    if (idx != -1) {
      _availableUsers[idx] = updated;
    }
    notifyListeners();

    try {
      await http
          .post(
            Uri.parse(ApiConfig.updateProfileUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': _currentUser.id,
              'name': newName,
              'department': newDepartment,
              'position': updated.position,
              'phone': updated.phone,
              'actor_role': _currentUser.role.name,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  /// Memverifikasi PIN lama dan memperbarui dengan PIN baru untuk pengguna aktif
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final currentPin = _currentUser.pin.isNotEmpty ? _currentUser.pin : '123456';
    if (oldPin.trim() != currentPin) {
      return false;
    }

    _currentUser = _currentUser.copyWith(pin: newPin.trim());
    final idx = _availableUsers.indexWhere((u) => u.id == _currentUser.id);
    if (idx != -1) {
      _availableUsers[idx] = _currentUser;
    }
    notifyListeners();

    try {
      await http
          .post(
            Uri.parse(ApiConfig.updateProfileUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': _currentUser.id,
              'pin': newPin.trim(),
              'actor_role': _currentUser.role.name,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  /// Update user data nama lengkap dan divisi penempatan (HANYA DAPAT DILAKUKAN OLEH SUPERADMIN)
  Future<bool> updateUserInfoBySuperadmin({
    required String targetUserId,
    required String newName,
    required String newDepartment,
    String? newPosition,
    UserRole? newRole,
    String? newOfficeId,
    String? newOfficeName,
  }) async {
    if (!isStaffIT) {
      return false;
    }

    final idx = _availableUsers.indexWhere((u) => u.id == targetUserId);
    if (idx != -1) {
      final oldUser = _availableUsers[idx];
      final updated = oldUser.copyWith(
        name: newName,
        department: newDepartment,
        position: newPosition ?? oldUser.position,
        role: newRole ?? oldUser.role,
        officeId: newOfficeId ?? oldUser.officeId,
        officeName: newOfficeName ?? oldUser.officeName,
      );
      _availableUsers[idx] = updated;

      if (_currentUser.id == targetUserId) {
        _currentUser = updated;
      }
      notifyListeners();

      try {
        await http
            .post(
              Uri.parse(ApiConfig.updateProfileUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'id': targetUserId,
                'name': newName,
                'department': newDepartment,
                'office_id': updated.officeId,
                'office_name': updated.officeName,
                'is_superadmin': true,
                'actor_role': 'staffIT',
              }),
            )
            .timeout(const Duration(seconds: 4));
      } catch (_) {}

      return true;
    }
    return false;
  }

  void addUser(UserModel newUser) {
    _availableUsers.add(newUser);
    notifyListeners();
  }

  void removeUser(String userId) {
    _availableUsers.removeWhere((u) => u.id == userId);
    notifyListeners();
  }
}
