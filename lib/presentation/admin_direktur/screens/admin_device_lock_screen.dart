import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DeviceBindingItem {
  final String employeeId;
  final String employeeName;
  final String nip;
  final String department;
  final String deviceModel;
  final String deviceId; // Hashed UUID
  final String osVersion;
  final DateTime boundAt;
  bool isLocked;
  int resetCount;

  DeviceBindingItem({
    required this.employeeId,
    required this.employeeName,
    required this.nip,
    required this.department,
    required this.deviceModel,
    required this.deviceId,
    required this.osVersion,
    required this.boundAt,
    this.isLocked = true,
    this.resetCount = 0,
  });
}

class AdminDeviceLockScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminDeviceLockScreen({super.key, this.showAppBar = true});

  @override
  State<AdminDeviceLockScreen> createState() => _AdminDeviceLockScreenState();
}

class _AdminDeviceLockScreenState extends State<AdminDeviceLockScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late List<DeviceBindingItem> _devices;

  @override
  void initState() {
    super.initState();
    _devices = [
      DeviceBindingItem(
        employeeId: '1',
        employeeName: 'SYAKYAKIRTI, S.E., M.M., M.H',
        nip: 'P001',
        department: 'Operasional Lapangan',
        deviceModel: 'Samsung Galaxy A54 5G',
        deviceId: 'SM-A546E-7F89-A1B2-C3D4',
        osVersion: 'Android 14 (OneUI 6.1)',
        boundAt: DateTime.now().subtract(const Duration(days: 45)),
        isLocked: true,
        resetCount: 1,
      ),
      DeviceBindingItem(
        employeeId: '5',
        employeeName: 'H. SUWARDI, S.AG',
        nip: 'K202602',
        department: 'Distribusi Air',
        deviceModel: 'Xiaomi Redmi Note 12',
        deviceId: '22111317G-5D6E-7F8A-9B0C',
        osVersion: 'Android 13 (HyperOS)',
        boundAt: DateTime.now().subtract(const Duration(days: 90)),
        isLocked: true,
        resetCount: 0,
      ),
      DeviceBindingItem(
        employeeId: '6',
        employeeName: 'FAZLI IDHAM MACHZAL, A.Md',
        nip: '020131',
        department: 'Unit Pelayanan Bintan Centre',
        deviceModel: 'OPPO Reno 8T 5G',
        deviceId: 'CPH2505-1122-3344-5566',
        osVersion: 'Android 14 (ColorOS 14)',
        boundAt: DateTime.now().subtract(const Duration(days: 120)),
        isLocked: true,
        resetCount: 0,
      ),
      DeviceBindingItem(
        employeeId: '7',
        employeeName: 'MUHAMAD THAPRIZAL',
        nip: '020116',
        department: 'Transmisi & Jaringan',
        deviceModel: 'Vivo V27 5G',
        deviceId: 'V2246-AABB-CCDD-EEFF',
        osVersion: 'Android 13 (Funtouch 13)',
        boundAt: DateTime.now().subtract(const Duration(days: 15)),
        isLocked: true,
        resetCount: 2,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _devices.where((d) {
      return _searchQuery.isEmpty ||
          d.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.nip.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.deviceModel.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [


        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          decoration: InputDecoration(
            hintText: 'Cari perangkat (Nama, NIK, Tipe Perangkat)...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
          ),
        ),
        const SizedBox(height: 16),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Perangkat Terikat (${filtered.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '1 Device 1 Akun Aktif',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...filtered.map((item) => _buildDeviceCard(item)),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Perangkat (Device Lock)'),
      ),
      body: content,
    );
  }

  Widget _buildDeviceCard(DeviceBindingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.smartphone_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.deviceModel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isLocked ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 11,
                      color: item.isLocked ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isLocked ? 'TERIKAT' : 'BELUM TERIKAT',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: item.isLocked ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            item.employeeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            '${item.nip} • ${item.department}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'UUID Perangkat: ${item.deviceId}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Pengaturan Ulang: ${item.resetCount} kali',
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
              OutlinedButton.icon(
                onPressed: () => _showResetDeviceDialog(item),
                icon: const Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFFD97706)),
                label: const Text('Atur Ulang ID Perangkat', style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDeviceDialog(DeviceBindingItem item) {
    final reasonCtrl = TextEditingController();
    String selectedReason = 'Karyawan Mengganti Ponsel Baru';

    final List<String> reasons = [
      'Karyawan Mengganti Ponsel Baru',
      'Ponsel Karyawan Rusak / Sedang Diperbaiki',
      'Ponsel Hilang dan Telah Lapor ke HRD',
      'Pembaruan Sistem Operasi / Hard Reset HP',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text('Konfirmasi Atur Ulang Perangkat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelepasan ikatan ID Perangkat untuk ${item.employeeName} (${item.nip}).',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Alasan Pergantian Perangkat (Wajib)'),
                      items: reasons.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11.5)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Berita Acara / Keterangan',
                        hintText: 'Opsional, misal: BA-HRD-2026/04',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                  onPressed: () {
                    setState(() {
                      item.isLocked = false;
                      item.resetCount += 1;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ID Perangkat ${item.employeeName} berhasil diatur ulang. Karyawan dapat mengikatkan ponsel baru saat masuk berikutnya.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Konfirmasi & Atur Ulang'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
