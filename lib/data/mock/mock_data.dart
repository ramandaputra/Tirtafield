import '../models/user_model.dart';
import '../models/approval_model.dart';

class MockData {
  // Pre-configured users from database table 'employee' (kolom pgw_nup)
  static const List<UserModel> initialUsers = [
    UserModel(
      id: '1',
      nip: 'P001',
      name: 'SYAKYAKIRTI, S.E., M.M., M.H',
      email: 'syakyakirti@tirtafield.co.id',
      role: UserRole.karyawan,
      department: 'Operasional Lapangan',
      position: 'Staff Lapangan',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBHnouN4NhcfWmjDbG_twFO6sebw3bZ18Eh5o0S5X77EHF5sjwqdJN1_ReCmIRAXuAloD9dPZQaPaz6HVgpuNpNvmO58tfZnPqD0S2Or68H_L0RpASTtBWA4c84ApGfNtIT2D9Dp8lVoCp0JDnad7J_CE3txa5AZ09a1vR9wuxu1NBIUFtj4kKAYnne-NzoAjd5q04Al1Cu_2jIhmMuPgiIkaTQw-LExIXsFQapZNGSTxquu43ZR8o',
    ),
    UserModel(
      id: '4',
      nip: 'D001',
      name: 'IR. H. ABDUL KHOLIK F, M.M.',
      email: 'abdul.kholik@tirtafield.co.id',
      pin: '123456',
      role: UserRole.direktur,
      department: 'Dewan Direksi',
      position: 'Direktur Utama',
      avatarUrl: null,
    ),
    UserModel(
      id: '162',
      nip: 'P242101',
      name: 'Superadmin Pusimpel',
      email: 'superadmin.pusimpel@tirtafield.co.id',
      pin: '123456',
      role: UserRole.staffIT,
      department: 'PUSIMPEL IT & System',
      position: 'Superadmin Pusimpel',
      avatarUrl: null,
    ),
    UserModel(
      id: '6',
      nip: '020131',
      name: 'FAZLI IDHAM MACHZAL, A.Md',
      email: 'fazli.idham@tirtafield.co.id',
      pin: '123456',
      role: UserRole.staffIT,
      department: 'IT & System Administrator',
      position: 'Staff IT',
      avatarUrl: null,
    ),
  ];

  // Seed Initial Approval Requests
  static List<ApprovalRequest> getInitialApprovals() {
    final now = DateTime.now();
    return [
      ApprovalRequest(
        id: 'apr_001',
        userId: 'usr_001',
        userName: 'Budi Santoso',
        userDepartment: 'Operasional Lapangan',
        type: ApprovalType.cuti,
        title: 'Cuti Tahunan Acara Keluarga',
        reason: 'Menghadiri acara pernikahan saudara di Yogyakarta selama 3 hari kerja.',
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 5)),
        status: ApprovalStatus.pending,
        submittedAt: now.subtract(const Duration(hours: 4)),
      ),
      ApprovalRequest(
        id: 'apr_002',
        userId: 'usr_004',
        userName: 'Siti Aminah',
        userDepartment: 'Keuangan & Akuntansi',
        type: ApprovalType.sakit,
        title: 'Izin Sakit Rawat Jalan',
        reason: 'Demam tinggi dan flu berdasarkan surat rujukan dokter puskesmas.',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now,
        status: ApprovalStatus.approved,
        submittedAt: now.subtract(const Duration(days: 1, hours: 2)),
        reviewedBy: 'Dr. Ir. Hendra Gunawan, M.M.',
        reviewedAt: now.subtract(const Duration(hours: 18)),
        reviewNotes: 'Semoga lekas sembuh, istirahat cukup.',
      ),
      ApprovalRequest(
        id: 'apr_003',
        userId: 'usr_005',
        userName: 'Ahmad Fauzi',
        userDepartment: 'Operasional Lapangan',
        type: ApprovalType.lembur,
        title: 'Lembur Maintenance Pompa Distribusi',
        reason: 'Perbaikan darurat pipa utama cluster B selesai pukul 21:00.',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.subtract(const Duration(days: 2)),
        status: ApprovalStatus.pending,
        submittedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
