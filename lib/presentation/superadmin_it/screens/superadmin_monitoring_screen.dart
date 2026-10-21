import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/widgets/attendance_detail_bottom_sheet.dart';
import '../../../data/models/approval_model.dart';
import '../../../state/approval_provider.dart';
import '../../../state/auth_provider.dart';
import '../../../state/realtime_monitoring_provider.dart';

class SuperadminMonitoringScreen extends StatefulWidget {
  final bool showAppBar;

  const SuperadminMonitoringScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<SuperadminMonitoringScreen> createState() =>
      _SuperadminMonitoringScreenState();
}

class _SuperadminMonitoringScreenState extends State<SuperadminMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoring = context.watch<RealtimeMonitoringProvider>();
    final approvalProv = context.watch<ApprovalProvider>();
    final reviewerName = context.watch<AuthProvider>().currentUser.name;

    // Filter persetujuan & riwayat berdasarkan query pencarian
    final allApprovals = approvalProv.allApprovals;
    final filteredAll = allApprovals.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchesName = a.userName.toLowerCase().contains(q);
      final matchesNip =
          a.userNip != null && a.userNip!.toLowerCase().contains(q);
      final matchesDept = a.userDepartment.toLowerCase().contains(q);
      final matchesTitle = a.title.toLowerCase().contains(q);
      final matchesReason = a.reason.toLowerCase().contains(q);
      final matchesReviewer =
          a.reviewedBy != null && a.reviewedBy!.toLowerCase().contains(q);
      return matchesName ||
          matchesNip ||
          matchesDept ||
          matchesTitle ||
          matchesReason ||
          matchesReviewer;
    }).toList();

    // Pisahkan daftar per kategori status
    final pendingList = filteredAll.where((a) => a.isPending).toList();
    final approvedList = filteredAll.where((a) => a.isApproved).toList();
    final rejectedList = filteredAll.where((a) => a.isRejected).toList();

    // Urutkan pengajuan menunggu dari yang paling baru diajukan
    pendingList.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    // Urutkan riwayat disetujui & ditolak dari yang paling baru diproses
    approvedList.sort((a, b) {
      final timeA = a.reviewedAt ?? a.submittedAt;
      final timeB = b.reviewedAt ?? b.submittedAt;
      return timeB.compareTo(timeA);
    });
    rejectedList.sort((a, b) {
      final timeA = a.reviewedAt ?? a.submittedAt;
      final timeB = b.reviewedAt ?? b.submittedAt;
      return timeB.compareTo(timeA);
    });

    List<ApprovalRequest> activeList;
    switch (_tabController.index) {
      case 0:
        activeList = pendingList;
        break;
      case 1:
        activeList = approvedList;
        break;
      case 2:
        activeList = rejectedList;
        break;
      default:
        activeList = pendingList;
    }

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. METRIK RINGKASAN PRESENSI REALTIME SUPERADMIN
        _buildMetricsBento(monitoring),
        const SizedBox(height: 14),

        // 2. SEARCH BAR PENCARIAN REALTIME
        _buildSearchBar(),
        const SizedBox(height: 8),

        // 3. STATUS SEGMENTED TABS (MENUNGGU, DISETUJUI, DITOLAK)
        _buildStatusTabBar(
          pendingCount: pendingList.length,
          approvedCount: approvedList.length,
          rejectedCount: rejectedList.length,
        ),
        const SizedBox(height: 12),

        // 4. DAFTAR KARTU PERSETUJUAN & RIWAYAT PRESENSI
        if (approvalProv.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (activeList.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = activeList[index];
              return _buildApprovalCard(item, reviewerName, approvalProv);
            },
          ),
      ],
    );

    if (!widget.showAppBar) return mainColumn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Dashboard & Persetujuan Presensi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context
                  .read<RealtimeMonitoringProvider>()
                  .loadRealtimeAttendance();
              context.read<ApprovalProvider>().loadAllApprovals();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data berhasil diperbarui.'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: mainColumn,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. METRIK BENTO SUPERADMIN
  // ==========================================
  Widget _buildMetricsBento(RealtimeMonitoringProvider monitoring) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Hadir Hari Ini',
            count: '${monitoring.countHadirTotal}',
            subtitle: 'Pegawai Aktif',
            color: AppColors.primary,
            icon: Icons.people_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Tepat Waktu',
            count: '${monitoring.countTepatWaktu}',
            subtitle: 'Sesuai Jadwal',
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Terlambat',
            count: '${monitoring.countTerlambat}',
            subtitle: '> Toleransi',
            color: AppColors.error,
            icon: Icons.access_time_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  count,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SEARCH BAR REALTIME
  // ==========================================
  Widget _buildSearchBar() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText: 'Cari nama pegawai, NIK, atau keterangan presensi...',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          fillColor: AppColors.surfaceContainerLowest,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. STATUS SEGMENTED TABS
  // ==========================================
  Widget _buildStatusTabBar({
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          _buildStatusTab(
            label: 'Menunggu',
            count: pendingCount,
            badgeColor: const Color(0xFFD97706),
            badgeBg: const Color(0xFFFEF3C7),
            isSelected: _tabController.index == 0,
          ),
          _buildStatusTab(
            label: 'Disetujui',
            count: approvedCount,
            badgeColor: const Color(0xFF16A34A),
            badgeBg: const Color(0xFFDCFCE7),
            isSelected: _tabController.index == 1,
          ),
          _buildStatusTab(
            label: 'Ditolak',
            count: rejectedCount,
            badgeColor: const Color(0xFFDC2626),
            badgeBg: const Color(0xFFFEE2E2),
            isSelected: _tabController.index == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required String label,
    required int count,
    required Color badgeColor,
    required Color badgeBg,
    required bool isSelected,
  }) {
    return Tab(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: isSelected ? badgeColor : badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : badgeColor,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. KARTU PERSETUJUAN & RIWAYAT PRESENSI
  // ==========================================
  Widget _buildApprovalCard(
    ApprovalRequest item,
    String reviewerName,
    ApprovalProvider approvalProv,
  ) {
    final isPending = item.isPending;
    final isApproved = item.isApproved;
    final reviewer = item.reviewedBy ?? (isPending ? '' : 'Superadmin');
    final keteranganAbsen = item.title.isNotEmpty ? item.title : item.reason;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Foto Pegawai, Nama, NIK & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Thumbnail Portrait
                Container(
                  width: 38,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: item.fotoUrl != null && item.fotoUrl!.isNotEmpty
                        ? Image.network(
                            item.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                item.userName.isNotEmpty ? item.userName[0] : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              item.userName.isNotEmpty ? item.userName[0] : 'U',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIK: ${item.userNip ?? "-"} • ${item.userDepartment}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isPending)
                        _buildPunctualityBadge(item)
                      else
                        _buildStatusAbsenBadge(item),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: Keterangan Absen Untuk Apa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      keteranganAbsen,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Row 3: Action Buttons (Menunggu) ATAU Riwayat Reviewer (Disetujui/Ditolak)
            if (isPending)
              Row(
                children: [
                  // 1. LIHAT RINCIAN
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _showDetailModal(
                          context,
                          item,
                          reviewerName,
                          approvalProv,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Lihat Rincian',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 2. TOLAK
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _showReviewDialog(
                          context,
                          item,
                          ApprovalStatus.rejected,
                          reviewerName,
                          approvalProv,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Tolak',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 3. SETUJUI
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _showReviewDialog(
                          context,
                          item,
                          ApprovalStatus.approved,
                          reviewerName,
                          approvalProv,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Setujui',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              // Info Disetujui / Ditolak Oleh Siapa (IDENTIK DENGAN HALAMAN RIWAYAT)
              Row(
                children: [
                  Icon(
                    isApproved
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 13,
                    color: isApproved
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      isApproved
                          ? 'Disetujui Oleh ($reviewer)'
                          : 'Ditolak Oleh ($reviewer)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isApproved
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),

              if (!isApproved &&
                  item.reviewNotes != null &&
                  item.reviewNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Alasan: ${item.reviewNotes}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ] else if (isApproved &&
                  item.reviewNotes != null &&
                  item.reviewNotes!.isNotEmpty &&
                  item.reviewNotes != 'Disetujui oleh Superadmin') ...[
                const SizedBox(height: 4),
                Text(
                  'Catatan: ${item.reviewNotes}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Tombol Lihat Rincian Lebar Penuh
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _showDetailModal(
                    context,
                    item,
                    reviewerName,
                    approvalProv,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                  label: const Text(
                    'Lihat Rincian',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAbsenBadge(ApprovalRequest item) {
    final isApproved = item.isApproved;
    final color =
        isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bg =
        isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final icon = isApproved
        ? Icons.check_circle_outline_rounded
        : Icons.highlight_off_rounded;

    final reviewTime = item.reviewedAt ?? item.submittedAt;
    final timeStr =
        '${reviewTime.hour.toString().padLeft(2, '0')}:${reviewTime.minute.toString().padLeft(2, '0')}';
    final statusText = isApproved ? 'Disetujui' : 'Ditolak';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4.5),
          Flexible(
            child: Text(
              '${item.type.label} • $statusText ($timeStr WIB)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunctualityBadge(ApprovalRequest item) {
    final isLate = item.isLate;
    final timeStr =
        item.attendanceTime != null ? ' (${item.attendanceTime} WIB)' : '';
    final color = isLate ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final bg = isLate ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);
    final icon =
        isLate ? Icons.schedule_rounded : Icons.check_circle_outline_rounded;
    final label = isLate ? 'Terlambat' : 'Tepat Waktu';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4.5),
          Flexible(
            child: Text(
              '$label$timeStr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. MODAL DETAIL & REVIEW DIALOG
  // ==========================================
  void _showDetailModal(
    BuildContext context,
    ApprovalRequest item,
    String reviewerName,
    ApprovalProvider approvalProv,
  ) {
    final recordedTimeStr = item.attendanceTime != null
        ? '${DateTimeHelper.formatReadableDate(item.startDate)} • ${item.attendanceTime}'
        : DateTimeHelper.formatIndonesianFullDateTimeWib(item.startDate);

    AttendanceDetailBottomSheet.show(
      context,
      userName: item.userName,
      nip: item.userNip ?? '-',
      department: item.userDepartment,
      recordedTimeStr: recordedTimeStr,
      status: item.isLate ? 'Terlambat' : 'Tepat Waktu',
      isLate: item.isLate,
      absenUntukApa: '${item.title}\n${item.reason}',
      locationName: item.locationName ?? 'Lokasi Tugas Lapangan',
      latitude: item.latitude,
      longitude: item.longitude,
      distancePlacement: item.distancePlacementOffice,
      officePlacement: item.officePlacement,
      fotoUrl: item.fotoUrl,
      slotTitle: item.type.label,
      isApproval: item.isPending,
      onApprove: () {
        Navigator.pop(context);
        _showReviewDialog(
          context,
          item,
          ApprovalStatus.approved,
          reviewerName,
          approvalProv,
        );
      },
      onReject: () {
        Navigator.pop(context);
        _showReviewDialog(
          context,
          item,
          ApprovalStatus.rejected,
          reviewerName,
          approvalProv,
        );
      },
    );
  }

  void _showReviewDialog(
    BuildContext context,
    ApprovalRequest item,
    ApprovalStatus newStatus,
    String reviewerName,
    ApprovalProvider prov,
  ) {
    final noteController = TextEditingController();
    final isApprove = newStatus == ApprovalStatus.approved;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isApprove ? 'Setujui Pengajuan' : 'Tolak Pengajuan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isApprove ? AppColors.success : AppColors.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin ${isApprove ? "menyetujui" : "menolak"} permohonan dari ${item.userName}?',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isApprove
                    ? 'Catatan persetujuan (opsional)'
                    : 'Alasan penolakan (wajib diisi)',
                hintStyle: const TextStyle(fontSize: 12),
                fillColor: AppColors.background,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isApprove && noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan wajib diisi.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              await prov.reviewRequest(
                approvalId: item.id,
                status: newStatus,
                reviewerName: '$reviewerName (Superadmin)',
                notes: noteController.text.trim().isEmpty
                    ? (isApprove ? 'Disetujui oleh Superadmin' : 'Ditolak')
                    : noteController.text.trim(),
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Permohonan ${item.userName} berhasil ${isApprove ? "disetujui" : "ditolak"}.',
                    ),
                    backgroundColor:
                        isApprove ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isApprove ? 'Ya, Setujui' : 'Ya, Tolak'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. EMPTY STATE PER TAB
  // ==========================================
  Widget _buildEmptyState() {
    String title = 'Tidak Ada Data Presensi';
    String message = 'Tidak ada data presensi yang sesuai kriteria.';
    IconData icon = Icons.inbox_outlined;

    if (_searchQuery.isNotEmpty) {
      title = 'Pencarian Tidak Ditemukan';
      message = 'Tidak ada data presensi yang cocok dengan "$_searchQuery".';
      icon = Icons.search_off_rounded;
    } else {
      switch (_tabController.index) {
        case 0:
          title = 'Tidak Ada Pengajuan Menunggu';
          message = 'Semua presensi karyawan lapangan telah ditinjau.';
          icon = Icons.check_circle_outline_rounded;
          break;
        case 1:
          title = 'Belum Ada Riwayat Disetujui';
          message = 'Belum ada presensi yang disetujui.';
          icon = Icons.history_toggle_off_rounded;
          break;
        case 2:
          title = 'Belum Ada Riwayat Ditolak';
          message = 'Tidak ada presensi yang ditolak.';
          icon = Icons.history_toggle_off_rounded;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
