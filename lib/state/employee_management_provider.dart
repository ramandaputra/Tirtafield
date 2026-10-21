import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../data/mock/mock_data.dart';
import '../data/models/user_model.dart';

enum EmployeeSortOption {
  nameAsc,
  nameDesc,
  nipAsc,
  nipDesc,
  department,
  role,
  office;

  String get label {
    switch (this) {
      case EmployeeSortOption.nameAsc:
        return 'Nama (A - Z)';
      case EmployeeSortOption.nameDesc:
        return 'Nama (Z - A)';
      case EmployeeSortOption.nipAsc:
        return 'NIK (Terkecil - Terbesar)';
      case EmployeeSortOption.nipDesc:
        return 'NIK (Terbesar - Terkecil)';
      case EmployeeSortOption.department:
        return 'Bidang';
      case EmployeeSortOption.role:
        return 'Peran & Hak Akses';
      case EmployeeSortOption.office:
        return 'Kantor Penempatan';
    }
  }

  String get shortLabel {
    switch (this) {
      case EmployeeSortOption.nameAsc:
        return 'Nama A-Z';
      case EmployeeSortOption.nameDesc:
        return 'Nama Z-A';
      case EmployeeSortOption.nipAsc:
        return 'NIK 0-9';
      case EmployeeSortOption.nipDesc:
        return 'NIK 9-0';
      case EmployeeSortOption.department:
        return 'Bidang';
      case EmployeeSortOption.role:
        return 'Peran';
      case EmployeeSortOption.office:
        return 'Kantor';
    }
  }

  String get description {
    switch (this) {
      case EmployeeSortOption.nameAsc:
        return 'Urutan alfabet nama dari A sampai Z';
      case EmployeeSortOption.nameDesc:
        return 'Urutan alfabet nama dari Z sampai A';
      case EmployeeSortOption.nipAsc:
        return 'Nomor induk kependudukan dari terkecil ke terbesar';
      case EmployeeSortOption.nipDesc:
        return 'Nomor induk kependudukan dari terbesar ke terkecil';
      case EmployeeSortOption.department:
        return 'Dikelompokkan berdasarkan bidang kerja';
      case EmployeeSortOption.role:
        return 'Superadmin → Admin → Pengguna';
      case EmployeeSortOption.office:
        return 'Kantor Pusat (HQ) lalu kantor cabang';
    }
  }

  IconData get icon {
    switch (this) {
      case EmployeeSortOption.nameAsc:
      case EmployeeSortOption.nameDesc:
        return Icons.sort_by_alpha_rounded;
      case EmployeeSortOption.nipAsc:
      case EmployeeSortOption.nipDesc:
        return Icons.pin_outlined;
      case EmployeeSortOption.department:
        return Icons.business_center_rounded;
      case EmployeeSortOption.role:
        return Icons.admin_panel_settings_rounded;
      case EmployeeSortOption.office:
        return Icons.location_city_rounded;
    }
  }

  bool get isAscending {
    return this == EmployeeSortOption.nameAsc || this == EmployeeSortOption.nipAsc;
  }
}

class EmployeeManagementProvider extends ChangeNotifier {
  List<UserModel> _employees = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  UserRole? _filterRole;
  String? _filterDepartment;
  String? _filterOfficeId;
  EmployeeSortOption _sortOption = EmployeeSortOption.nameAsc;

  EmployeeManagementProvider() {
    loadEmployees();
  }

  List<UserModel> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  UserRole? get filterRole => _filterRole;
  String? get filterDepartment => _filterDepartment;
  String? get filterOfficeId => _filterOfficeId;
  EmployeeSortOption get sortOption => _sortOption;

  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _filterRole != null ||
        (_filterDepartment != null && _filterDepartment!.isNotEmpty) ||
        (_filterOfficeId != null && _filterOfficeId!.isNotEmpty) ||
        _sortOption != EmployeeSortOption.nameAsc;
  }

  int get activeFiltersCount {
    int count = 0;
    if (_filterRole != null) count++;
    if (_filterDepartment != null && _filterDepartment!.isNotEmpty) count++;
    if (_filterOfficeId != null && _filterOfficeId!.isNotEmpty) count++;
    if (_sortOption != EmployeeSortOption.nameAsc) count++;
    return count;
  }

  List<UserModel> get filteredEmployees {
    final list = _employees.where((user) {
      if (!user.isActive) return false;

      final matchesQuery = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.nip.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.officeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.position.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _filterRole == null || user.role == _filterRole;

      final matchesDept = _filterDepartment == null ||
          _filterDepartment!.isEmpty ||
          user.department.toLowerCase() == _filterDepartment!.toLowerCase();

      final matchesOffice = _filterOfficeId == null ||
          _filterOfficeId!.isEmpty ||
          user.officeId == _filterOfficeId;

      return matchesQuery && matchesRole && matchesDept && matchesOffice;
    }).toList();

    // Terapkan sortir berdasarkan pilihan pengguna
    switch (_sortOption) {
      case EmployeeSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case EmployeeSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case EmployeeSortOption.nipAsc:
        list.sort((a, b) => a.nip.compareTo(b.nip));
        break;
      case EmployeeSortOption.nipDesc:
        list.sort((a, b) => b.nip.compareTo(a.nip));
        break;
      case EmployeeSortOption.department:
        list.sort((a, b) {
          final cmp = a.department.toLowerCase().compareTo(b.department.toLowerCase());
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case EmployeeSortOption.role:
        int roleWeight(UserRole r) {
          switch (r) {
            case UserRole.staffIT:
              return 0;
            case UserRole.direktur:
              return 1;
            case UserRole.karyawan:
              return 2;
          }
        }
        list.sort((a, b) {
          final cmp = roleWeight(a.role).compareTo(roleWeight(b.role));
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case EmployeeSortOption.office:
        list.sort((a, b) {
          final aIsHq = a.officeId == 'hq' ? 0 : 1;
          final bIsHq = b.officeId == 'hq' ? 0 : 1;
          if (aIsHq != bIsHq) return aIsHq.compareTo(bIsHq);
          final cmp = a.officeName.toLowerCase().compareTo(b.officeName.toLowerCase());
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }

    return list;
  }

  int get totalEmployees => _employees.length;
  int get totalKaryawan => _employees.where((u) => u.role == UserRole.karyawan).length;
  int get totalDirektur => _employees.where((u) => u.role == UserRole.direktur).length;
  int get totalStaffIT => _employees.where((u) => u.role == UserRole.staffIT).length;

  List<String> get departmentList {
    final depts = _employees.map((e) => e.department).where((d) => d.isNotEmpty).toSet().toList();
    depts.sort();
    return depts;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterRole(UserRole? role) {
    _filterRole = role;
    notifyListeners();
  }

  void setFilterDepartment(String? department) {
    _filterDepartment = department;
    notifyListeners();
  }

  void setFilterOffice(String? officeId) {
    _filterOfficeId = officeId;
    notifyListeners();
  }

  void setSortOption(EmployeeSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleSortDirection() {
    switch (_sortOption) {
      case EmployeeSortOption.nameAsc:
        _sortOption = EmployeeSortOption.nameDesc;
        break;
      case EmployeeSortOption.nameDesc:
        _sortOption = EmployeeSortOption.nameAsc;
        break;
      case EmployeeSortOption.nipAsc:
        _sortOption = EmployeeSortOption.nipDesc;
        break;
      case EmployeeSortOption.nipDesc:
        _sortOption = EmployeeSortOption.nipAsc;
        break;
      default:
        // Default to name descending if not alphabetical or numeric
        _sortOption = EmployeeSortOption.nameDesc;
        break;
    }
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _filterRole = null;
    _filterDepartment = null;
    _filterOfficeId = null;
    _sortOption = EmployeeSortOption.nameAsc;
    notifyListeners();
  }

  Future<void> loadEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.employeesUrl}?action=list');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'];
          final List<UserModel> loaded = list.map((item) {
            UserRole r = UserRole.karyawan;
            if (item['role'] == 'direktur') r = UserRole.direktur;
            if (item['role'] == 'staffIT') r = UserRole.staffIT;

            return UserModel(
              id: item['id'].toString(),
              nip: item['nip'].toString(),
              name: item['name'].toString(),
              email: item['email'].toString(),
              pin: item['pin']?.toString() ?? '123456',
              role: r,
              department: item['department']?.toString() ?? 'Bidang Hubungan Langganan',
              position: item['position']?.toString() ?? 'Seksi Pembacaan Meter',
              phone: item['phone']?.toString() ?? '081234567890',
              statusPegawai: item['status']?.toString() ?? 'Karyawan Tetap',
              avatarUrl: item['avatar_url']?.toString(),
              isActive: true,
              officeId: item['office_id']?.toString() ?? item['officeId']?.toString() ?? 'hq',
              officeName: item['office_name']?.toString() ??
                  item['officeName']?.toString() ??
                  'Kantor Pusat PERUMDA Tirta Kepri Tanjung Pinang',
            );
          }).toList();

          if (loaded.isNotEmpty) {
            _employees = loaded;
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {
      // Fallback to mock users
    }

    _employees = List.from(MockData.initialUsers);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? newPosition,
    String? newDepartment,
  }) async {
    final idx = _employees.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = _employees[idx];
      final updated = old.copyWith(
        role: newRole,
        position: newPosition ?? (newRole == UserRole.direktur ? 'Direktur Utama' : (newRole == UserRole.staffIT ? 'Staff IT & System' : 'Staff Lapangan')),
        department: newDepartment ?? (newRole == UserRole.direktur ? 'Dewan Direksi' : (newRole == UserRole.staffIT ? 'PUSIMPEL IT & System' : old.department)),
      );
      _employees[idx] = updated;
      notifyListeners();

      try {
        final uri = Uri.parse('${ApiConfig.employeesUrl}?action=update');
        await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'id': userId,
                'role': newRole.name,
                'position': updated.position,
                'department': updated.department,
              }),
            )
            .timeout(const Duration(seconds: 4));
      } catch (_) {}

      return true;
    }
    return false;
  }

  Future<bool> updateEmployeeData(UserModel updated) async {
    final idx = _employees.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _employees[idx] = updated;
      notifyListeners();

      try {
        final uri = Uri.parse('${ApiConfig.employeesUrl}?action=update');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'id': updated.id,
                'nip': updated.nip,
                'name': updated.name,
                'department': updated.department,
                'position': updated.position,
                'phone': updated.phone,
                'pin': updated.pin,
                'office_id': updated.officeId,
                'office_name': updated.officeName,
              }),
            )
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          await loadEmployees();
        }
      } catch (_) {}

      return true;
    }
    return false;
  }

  Future<bool> addEmployee({
    required String nip,
    required String name,
    required String department,
    required String position,
    required UserRole role,
    required String phone,
    String pin = '123456',
    String statusPegawai = 'Karyawan Tetap',
    String officeId = 'hq',
    String officeName = 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
  }) async {
    final newId = 'emp_${DateTime.now().millisecondsSinceEpoch}';
    final newEmp = UserModel(
      id: newId,
      nip: nip,
      name: name,
      email: '${nip.toLowerCase()}@tirtafield.co.id',
      pin: pin,
      role: role,
      department: department,
      position: position,
      phone: phone,
      statusPegawai: statusPegawai,
      officeId: officeId,
      officeName: officeName,
    );

    _employees.insert(0, newEmp);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.employeesUrl}?action=add');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nip': nip,
              'name': name,
              'department': department,
              'position': position,
              'role': role.name,
              'phone': phone,
              'pin': pin,
              'office_id': officeId,
              'office_name': officeName,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        await loadEmployees();
      }
    } catch (_) {}

    return true;
  }

  Future<bool> toggleEmployeeStatus(String userId) async {
    final idx = _employees.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final current = _employees[idx];
      _employees[idx] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> resetPin(String userId, String newPin) async {
    final idx = _employees.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _employees[idx] = _employees[idx].copyWith(pin: newPin);
      notifyListeners();

      try {
        final uri = Uri.parse('${ApiConfig.employeesUrl}?action=update');
        await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'id': userId,
                'pin': newPin,
              }),
            )
            .timeout(const Duration(seconds: 4));
      } catch (_) {}

      return true;
    }
    return false;
  }
}
