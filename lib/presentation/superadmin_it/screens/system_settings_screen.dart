import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  TimeOfDay _timeMasuk = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _timeIstirahatKeluar = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _timeIstirahatMasuk = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _timePulang = const TimeOfDay(hour: 17, minute: 0);
  int _toleransiMenit = 15;
  double _geofenceRadius = 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi 4 Slot Presensi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal & Batas Waktu 4x Absen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimeSlotTile(
              slotNumber: 1,
              title: '1. Absen Masuk',
              time: _timeMasuk,
              color: AppColors.checkIn,
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _timeMasuk);
                if (picked != null) setState(() => _timeMasuk = picked);
              },
            ),
            const SizedBox(height: 8),
            _buildTimeSlotTile(
              slotNumber: 2,
              title: '2. Istirahat Keluar',
              time: _timeIstirahatKeluar,
              color: AppColors.breakOut,
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _timeIstirahatKeluar);
                if (picked != null) setState(() => _timeIstirahatKeluar = picked);
              },
            ),
            const SizedBox(height: 8),
            _buildTimeSlotTile(
              slotNumber: 3,
              title: '3. Istirahat Masuk',
              time: _timeIstirahatMasuk,
              color: AppColors.breakIn,
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _timeIstirahatMasuk);
                if (picked != null) setState(() => _timeIstirahatMasuk = picked);
              },
            ),
            const SizedBox(height: 8),
            _buildTimeSlotTile(
              slotNumber: 4,
              title: '4. Absen Pulang',
              time: _timePulang,
              color: AppColors.checkOut,
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _timePulang);
                if (picked != null) setState(() => _timePulang = picked);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Parameter Toleransi & Geofence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toleransi Keterlambatan:'),
                        Text(
                          '$_toleransiMenit Menit',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: _toleransiMenit.toDouble(),
                      min: 0,
                      max: 60,
                      divisions: 12,
                      label: '$_toleransiMenit menit',
                      onChanged: (val) => setState(() => _toleransiMenit = val.round()),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Radius Geofencing Kantor:'),
                        Text(
                          '${_geofenceRadius.round()} Meter',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    Slider(
                      value: _geofenceRadius,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: '${_geofenceRadius.round()} meter',
                      onChanged: (val) => setState(() => _geofenceRadius = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Konfigurasi 4 slot absensi berhasil diperbarui!'),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotTile({
    required int slotNumber,
    required String title,
    required TimeOfDay time,
    required Color color,
    required VoidCallback onTap,
  }) {
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} WIB';

    return Card(
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$slotNumber',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              formattedTime,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
