import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/approval_model.dart';
import '../../../state/approval_provider.dart';
import '../../../state/auth_provider.dart';

class RequestApprovalScreen extends StatefulWidget {
  const RequestApprovalScreen({super.key});

  @override
  State<RequestApprovalScreen> createState() => _RequestApprovalScreenState();
}

class _RequestApprovalScreenState extends State<RequestApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  ApprovalType _selectedType = ApprovalType.koreksiAbsen;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Pengajuan Persetujuan Presensi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Permohonan Presensi',
                  hintText: 'Contoh: Koreksi Presensi Masuk',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDatePickers(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Alasan / Keterangan Presensi',
                  hintText: 'Jelaskan kendala, lokasi, atau rincian presensi yang memerlukan persetujuan...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan permohonan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Kirim Pengajuan Persetujuan Presensi',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipe Pengajuan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ApprovalType>(
          initialValue: _selectedType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: ApprovalType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedType = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tanggal Mulai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate;
                      }
                    });
                  }
                },
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  DateTimeHelper.formatReadableDate(_startDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tanggal Selesai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                  }
                },
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  DateTimeHelper.formatReadableDate(_endDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final user = context.read<AuthProvider>().currentUser;

    final request = ApprovalRequest(
      id: 'apr_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      userName: user.name,
      userDepartment: user.department,
      type: _selectedType,
      title: _titleController.text.trim(),
      reason: _reasonController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      status: ApprovalStatus.pending,
      submittedAt: DateTime.now(),
    );

    final success = await context.read<ApprovalProvider>().submitRequest(request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Pengajuan persetujuan presensi berhasil dikirim ke Direktur!'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
