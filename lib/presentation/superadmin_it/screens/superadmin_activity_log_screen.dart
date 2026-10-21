import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/activity_log_model.dart';
import '../../../state/activity_log_provider.dart';

class SuperadminActivityLogScreen extends StatefulWidget {
  final bool showAppBar;

  const SuperadminActivityLogScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<SuperadminActivityLogScreen> createState() =>
      _SuperadminActivityLogScreenState();
}

class _SuperadminActivityLogScreenState
    extends State<SuperadminActivityLogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onExportCsv(BuildContext context, ActivityLogProvider logProv) {
    final csv = logProv.exportToCsv();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${logProv.filteredLogs.length} baris log berhasil diekspor & disalin ke clipboard (Format CSV).',
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logProv = context.watch<ActivityLogProvider>();
    final logs = logProv.filteredLogs;

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KPI BENTO METRICS
              _buildMetricsBento(logProv),
              const SizedBox(height: 14),

              // 2. SEARCH & FILTER SECTION
              _buildSearchBox(logProv),
              const SizedBox(height: 10),

              // 3. CATEGORY FILTER CHIPS
              _buildCategoryChips(logProv),
              const SizedBox(height: 12),

              // 4. SEVERITY LEVEL FILTER CHIPS
              _buildLevelFilterChips(logProv),
              const SizedBox(height: 16),

              // 5. TIMELINE AUDIT FEED LIST
              _buildLogFeed(context, logs, logProv),
            ],
          ),
        ),
      ),
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Aktivitas Superadmin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              'Audit Trail & Rekam Jejak Sistem',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ekspor Data CSV',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.secondary),
            onPressed: () => _onExportCsv(context, logProv),
          ),
          IconButton(
            tooltip: 'Segarkan Log',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurface),
            onPressed: () => logProv.refreshLogs(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
  }

  // 1. METRICS BENTO CARDS
  Widget _buildMetricsBento(ActivityLogProvider logProv) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Total Aktivitas',
            count: '${logProv.totalCount}',
            subtitle: 'Rekam Jejak',
            color: AppColors.roleStaffIT,
            icon: Icons.history_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Hari Ini',
            count: '${logProv.todayCount}',
            subtitle: 'Aksi Aktif',
            color: AppColors.secondary,
            icon: Icons.today_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Lokasi Kantor',
            count: '${logProv.geofenceCount}',
            subtitle: 'Titik Kantor',
            color: AppColors.primary,
            icon: Icons.apartment_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Keamanan',
            count: '${logProv.securityCount}',
            subtitle: 'Audit Sesi',
            color: AppColors.warning,
            icon: Icons.shield_outlined,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              color: AppColors.onSurfaceVariant,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // 2. SEARCH BOX
  Widget _buildSearchBox(ActivityLogProvider logProv) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => logProv.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Cari aksi, nama aktor, NIK, atau objek...',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.secondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    logProv.setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 3. CATEGORY CHIPS
  Widget _buildCategoryChips(ActivityLogProvider logProv) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Semua Kategori',
            icon: Icons.apps_rounded,
            isSelected: logProv.selectedCategory == null,
            onTap: () => logProv.setSelectedCategory(null),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Lokasi Kantor',
            icon: Icons.apartment_rounded,
            color: AppColors.secondary,
            isSelected: logProv.selectedCategory == ActivityCategory.geofencing,
            onTap: () => logProv.setSelectedCategory(ActivityCategory.geofencing),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Persetujuan',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFD97706),
            isSelected: logProv.selectedCategory == ActivityCategory.approval,
            onTap: () => logProv.setSelectedCategory(ActivityCategory.approval),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Jam Operasional',
            icon: Icons.schedule_rounded,
            color: AppColors.checkIn,
            isSelected: logProv.selectedCategory == ActivityCategory.operationalSchedule,
            onTap: () => logProv.setSelectedCategory(ActivityCategory.operationalSchedule),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Pegawai & Akun',
            icon: Icons.manage_accounts_rounded,
            color: AppColors.primary,
            isSelected: logProv.selectedCategory == ActivityCategory.employeeAccount,
            onTap: () => logProv.setSelectedCategory(ActivityCategory.employeeAccount),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Keamanan & Sesi',
            icon: Icons.security_rounded,
            color: AppColors.roleStaffIT,
            isSelected: logProv.selectedCategory == ActivityCategory.securityAuth,
            onTap: () => logProv.setSelectedCategory(ActivityCategory.securityAuth),
          ),
        ],
      ),
    );
  }

  // 4. LEVEL FILTER CHIPS
  Widget _buildLevelFilterChips(ActivityLogProvider logProv) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const Text(
            'Tingkat:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          _buildMiniLevelBadge(
            label: 'Semua',
            isSelected: logProv.selectedLevel == null,
            color: AppColors.onSurfaceVariant,
            onTap: () => logProv.setSelectedLevel(null),
          ),
          const SizedBox(width: 6),
          _buildMiniLevelBadge(
            label: 'Sukses',
            isSelected: logProv.selectedLevel == ActivityLevel.success,
            color: AppColors.success,
            onTap: () => logProv.setSelectedLevel(ActivityLevel.success),
          ),
          const SizedBox(width: 6),
          _buildMiniLevelBadge(
            label: 'Informasi',
            isSelected: logProv.selectedLevel == ActivityLevel.info,
            color: const Color(0xFF0284C7),
            onTap: () => logProv.setSelectedLevel(ActivityLevel.info),
          ),
          const SizedBox(width: 6),
          _buildMiniLevelBadge(
            label: 'Peringatan',
            isSelected: logProv.selectedLevel == ActivityLevel.warning,
            color: AppColors.warning,
            onTap: () => logProv.setSelectedLevel(ActivityLevel.warning),
          ),
          const SizedBox(width: 6),
          _buildMiniLevelBadge(
            label: 'Kritis',
            isSelected: logProv.selectedLevel == ActivityLevel.critical,
            color: AppColors.error,
            onTap: () => logProv.setSelectedLevel(ActivityLevel.critical),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : activeColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniLevelBadge({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppColors.onSurfaceVariant,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  // 5. TIMELINE AUDIT FEED LIST
  Widget _buildLogFeed(
    BuildContext context,
    List<ActivityLogItem> logs,
    ActivityLogProvider logProv,
  ) {
    if (logProv.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tidak ada log aktivitas yang cocok',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba ubah kata kunci pencarian atau reset filter kategori/tingkat keparahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                logProv.setSearchQuery('');
                logProv.setSelectedCategory(null);
                logProv.setSelectedLevel(null);
              },
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Reset Semua Filter', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
      );
    }

    // Group logs by Date
    final Map<String, List<ActivityLogItem>> grouped = {};
    for (final item in logs) {
      final key = item.dateGroupKey;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Rekam Audit Trail (${logs.length} Log)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ketuk kartu untuk detail audit',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...grouped.entries.map((entry) {
          final groupTitle = entry.key;
          final groupItems = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Group Header
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      groupTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.secondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),

              // Activity Cards in this date group
              ...groupItems.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildLogCard(context, log),
                  )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, ActivityLogItem log) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: log.level == ActivityLevel.critical
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAuditDetailModal(context, log),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon Node
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: log.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    log.categoryIcon,
                    size: 18,
                    color: log.categoryColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Core Log Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category tag + Level pill + Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: log.categoryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.categoryLabel,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: log.categoryColor,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: log.levelColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    log.levelLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: log.levelColor,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            log.relativeTime,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Title
                      Text(
                        log.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Description
                      Text(
                        log.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          fontFamily: 'Inter',
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Footer Row: Actor + IP / Target
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: AppColors.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${log.actorName} (${log.actorRole})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          if (log.ipAddress != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• IP ${log.ipAddress}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // AUDIT DETAIL BOTTOM SHEET
  void _showAuditDetailModal(BuildContext context, ActivityLogItem log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header with Level & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: log.categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(log.categoryIcon, size: 14, color: log.categoryColor),
                          const SizedBox(width: 5),
                          Text(
                            log.categoryLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: log.categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: log.levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.levelLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: log.levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  log.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  log.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Key Audit Details Table
                const Text(
                  'Rincian Rekam Jejak Audit (Audit Trail):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                _buildDetailRow('ID Log', log.id, isMonospace: true),
                _buildDetailRow('Waktu Eksekusi', '${log.formattedDate} • ${log.formattedTime}'),
                _buildDetailRow('Aktor / Pelaksana', '${log.actorName} (${log.actorRole})'),
                _buildDetailRow('NIK Aktor', log.actorNip),
                if (log.targetEntity != null)
                  _buildDetailRow('Target Objek', log.targetEntity!),
                if (log.ipAddress != null)
                  _buildDetailRow('Alamat IP', log.ipAddress!, isMonospace: true),
                if (log.deviceInfo != null)
                  _buildDetailRow('Perangkat / User-Agent', log.deviceInfo!),

                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Parameter Perubahan (Metadata):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: log.metadata!.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${e.key}: ${e.value}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: '[${log.formattedDate} ${log.formattedTime}] ${log.title}\nAktor: ${log.actorName} (${log.actorNip})\nDeskripsi: ${log.description}\nIP: ${log.ipAddress ?? "-"}',
                            ),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rincian log berhasil disalin ke clipboard.'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Log', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Tutup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(':', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : 'Inter',
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
