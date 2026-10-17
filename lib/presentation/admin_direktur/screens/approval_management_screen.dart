import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/approval_model.dart';
import '../../../state/approval_provider.dart';
import '../../../state/auth_provider.dart';

class ApprovalManagementScreen extends StatefulWidget {
  const ApprovalManagementScreen({super.key});

  @override
  State<ApprovalManagementScreen> createState() =>
      _ApprovalManagementScreenState();
}

class _ApprovalManagementScreenState extends State<ApprovalManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approvalProv = context.watch<ApprovalProvider>();
    final reviewer = context.watch<AuthProvider>().currentUser.name;
    final allList = approvalProv.allApprovals;

    final pendingList = allList.where((a) => a.isPending).toList();
    final approvedList = allList.where((a) => a.isApproved).toList();
    final rejectedList = allList.where((a) => a.isRejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Approval'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Semua (${allList.length})'),
            Tab(text: 'Menunggu (${pendingList.length})'),
            Tab(text: 'Disetujui (${approvedList.length})'),
            Tab(text: 'Ditolak (${rejectedList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(allList, reviewer),
          _buildListView(pendingList, reviewer),
          _buildListView(approvedList, reviewer),
          _buildListView(rejectedList, reviewer),
        ],
      ),
    );
  }

  Widget _buildListView(List<ApprovalRequest> items, String reviewerName) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data pengajuan dalam kategori ini',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildApprovalCard(item, reviewerName);
      },
    );
  }

  Widget _buildApprovalCard(ApprovalRequest item, String reviewerName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.userDepartment} • ${item.type.label}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ApprovalStatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.reason,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.date_range, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${DateTimeHelper.formatReadableDate(item.startDate)} s/d ${DateTimeHelper.formatReadableDate(item.endDate)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (item.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showReviewDialog(
                        item,
                        ApprovalStatus.rejected,
                        reviewerName,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReviewDialog(
                        item,
                        ApprovalStatus.approved,
                        reviewerName,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(
    ApprovalRequest item,
    ApprovalStatus status,
    String reviewerName,
  ) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          status == ApprovalStatus.approved ? 'Setujui Permohonan' : 'Tolak Permohonan',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Karyawan: ${item.userName}'),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan Persetujuan',
                hintText: 'Tuliskan catatan untuk karyawan...',
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
              Navigator.pop(ctx);
              await context.read<ApprovalProvider>().reviewRequest(
                    approvalId: item.id,
                    status: status,
                    reviewerName: reviewerName,
                    notes: noteController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == ApprovalStatus.approved
                  ? AppColors.success
                  : AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
