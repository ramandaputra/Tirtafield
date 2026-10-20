import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/system_settings_model.dart';
import '../../../state/system_settings_provider.dart';

class AdminGeofencingViewerScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminGeofencingViewerScreen({super.key, this.showAppBar = true});

  @override
  State<AdminGeofencingViewerScreen> createState() =>
      _AdminGeofencingViewerScreenState();
}

class _AdminGeofencingViewerScreenState
    extends State<AdminGeofencingViewerScreen> {
  int _selectedOfficeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SystemSettingsProvider>();
    final offices = settingsProv.geofencing.offices;
    final activeOffice = offices.isNotEmpty
        ? offices[_selectedOfficeIndex.clamp(0, offices.length - 1)]
        : settingsProv.primaryOffice;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [


        // Office Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(offices.length, (idx) {
              final isSel = idx == _selectedOfficeIndex;
              final o = offices[idx];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    o.name,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) setState(() => _selectedOfficeIndex = idx);
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Visual Map & Radius Radar Card
        _buildGeofenceVisualCard(activeOffice),
        const SizedBox(height: 16),

        // Geofence Details List
        _buildDetailParameters(activeOffice),
        const SizedBox(height: 16),

        // WiFi & Beacon Integration (Read-Only)
        _buildWifiBeaconCard(activeOffice),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Geofencing & Lokasi Kantor (Hanya Melihat)'),
      ),
      body: content,
    );
  }

  Widget _buildGeofenceVisualCard(OfficeLocationItem office) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radar Preview Container
          Container(
            height: 160,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                // Inner Geofence Radius
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                // Center Marker
                const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                // Top Tag
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Radius Toleransi: ${office.radius.toInt()} Meter',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Locked Indicator
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Terkunci', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Office Title & Coordinates
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  office.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  office.address,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${office.latitude.toStringAsFixed(6)} • Long: ${office.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailParameters(OfficeLocationItem office) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parameter Validasi Lokasi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          _buildParamRow('ID Titik Geofence', office.id),
          const Divider(height: 16, color: AppColors.cardBorder),
          _buildParamRow('Radius Batas Presensi', '${office.radius.toInt()} Meter'),
          const Divider(height: 16, color: AppColors.cardBorder),
          _buildParamRow('Akurasi Minimum GPS', '< 25 Meter'),
          const Divider(height: 16, color: AppColors.cardBorder),
          _buildParamRow('Anti-Fake GPS / Mock Detection', 'Wajib Aktif (Strict)'),
        ],
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildWifiBeaconCard(OfficeLocationItem office) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Integrasi Jaringan Kantor (WiFi / Beacon)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.router_rounded, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SSID WiFi Resmi Kantor',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                      Text(
                        office.id == 'ipa_sei_pulai'
                            ? 'TIRTAFIELD_IPA_SEI_PULAI_5G'
                            : (office.id == 'bintan_center' ? 'TIRTAFIELD_BINTAN_CTR_WIFI' : 'TIRTAFIELD_HQ_CORP_OFFICIAL'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
