enum UserRole {
  karyawan,
  direktur,
  staffIT;

  String get displayName {
    switch (this) {
      case UserRole.karyawan:
        return 'Karyawan';
      case UserRole.direktur:
        return 'Direktur (Admin)';
      case UserRole.staffIT:
        return 'Staff IT (Superadmin)';
    }
  }

  bool get isKaryawan => this == UserRole.karyawan;
  bool get isDirektur => this == UserRole.direktur;
  bool get isStaffIT => this == UserRole.staffIT;
}

class UserModel {
  final String id;
  final String nip; // NIK / NIP Karyawan
  final String name;
  final String email;
  final String pin; // PIN 6 digit
  final UserRole role;
  final String department;
  final String position;
  final String? avatarUrl;

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
    );
  }
}
