enum UserRole {
  karyawan,
  direktur,
  staffIT;

  String get displayName {
    switch (this) {
      case UserRole.karyawan:
        return 'Pengguna';
      case UserRole.direktur:
        return 'Admin';
      case UserRole.staffIT:
        return 'Superadmin';
    }
  }

  bool get isKaryawan => this == UserRole.karyawan;
  bool get isDirektur => this == UserRole.direktur;
  bool get isStaffIT => this == UserRole.staffIT;
}

class UserModel {
  final String id;
  final String nip; // NIK
  final String name;
  final String email;
  final String pin; // PIN 6 digit
  final UserRole role;
  final String department;
  final String position;
  final String? avatarUrl;
  final String phone;
  final String statusPegawai; // 'Karyawan Tetap', 'Kontrak', 'Lapangan'
  final bool isActive;
  final String officeId; // ID Kantor Penempatan (misal 'hq', 'bintan_center', 'ipa_sei_pulai')
  final String officeName; // Nama Kantor / Cabang Penempatan

  const UserModel({
    required this.id,
    required this.nip,
    required this.name,
    required this.email,
    this.pin = '123456',
    required this.role,
    required this.department,
    required this.position,
    this.avatarUrl,
    this.phone = '081234567890',
    this.statusPegawai = 'Karyawan Tetap',
    this.isActive = true,
    this.officeId = 'hq',
    this.officeName = 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
  });

  UserModel copyWith({
    String? id,
    String? nip,
    String? name,
    String? email,
    String? pin,
    UserRole? role,
    String? department,
    String? position,
    String? avatarUrl,
    String? phone,
    String? statusPegawai,
    bool? isActive,
    String? officeId,
    String? officeName,
  }) {
    return UserModel(
      id: id ?? this.id,
      nip: nip ?? this.nip,
      name: name ?? this.name,
      email: email ?? this.email,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      department: department ?? this.department,
      position: position ?? this.position,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      statusPegawai: statusPegawai ?? this.statusPegawai,
      isActive: isActive ?? this.isActive,
      officeId: officeId ?? this.officeId,
      officeName: officeName ?? this.officeName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nip': nip,
      'name': name,
      'email': email,
      'pin': pin,
      'role': role.name,
      'department': department,
      'position': position,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'statusPegawai': statusPegawai,
      'isActive': isActive,
      'officeId': officeId,
      'officeName': officeName,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nip: json['nip'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      pin: (json['pin'] as String?) ?? '123456',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.karyawan,
      ),
      department: json['department'] as String,
      position: json['position'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: (json['phone'] as String?) ?? '081234567890',
      statusPegawai: (json['statusPegawai'] as String?) ?? 'Karyawan Tetap',
      isActive: (json['isActive'] as bool?) ?? true,
      officeId: (json['officeId'] as String?) ?? (json['office_id'] as String?) ?? 'hq',
      officeName: (json['officeName'] as String?) ??
          (json['office_name'] as String?) ??
          'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
    );
  }
}
