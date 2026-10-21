import '../models/user_model.dart';
import '../models/approval_model.dart';

class MockData {
  // Users dari tabel database 'users' (Pusimpel & IR. H. ABDUL KHOLIK F, M.M.)
  static const List<UserModel> initialUsers = [
    UserModel(
      id: '1',
      nip: 'P242101',
      name: 'Pusimpel',
      email: 'pusimpel@tirtakepri.co.id',
      pin: '123456',
      role: UserRole.staffIT,
      department: 'PUSIMPEL IT & System',
      position: 'Superadmin Pusimpel',
      officeId: 'hq',
      officeName: 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
      avatarUrl: null,
    ),
    UserModel(
      id: '2',
      nip: 'D001',
      name: 'IR. H. ABDUL KHOLIK F, M.M.',
      email: 'abdul.kholik@tirtakepri.co.id',
      pin: '123456',
      role: UserRole.direktur,
      department: 'Dewan Direksi',
      position: 'Direktur',
      officeId: 'hq',
      officeName: 'Kantor Pusat Perumda Air Minum Tirta Kepri Tanjung Pinang',
      avatarUrl: null,
    ),
  ];

  // Seed Initial Approval Requests (Kosong karena belum ada yang mengajukan absensi)
  static List<ApprovalRequest> getInitialApprovals() {
    return [];
  }
}
