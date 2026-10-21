import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/system_settings_model.dart';
import '../../../state/system_settings_provider.dart';

class SuperadminOperationalScreen extends StatefulWidget {
  final bool showAppBar;
  final int initialSubTabIndex;

  const SuperadminOperationalScreen({
    super.key,
    this.showAppBar = true,
    this.initialSubTabIndex = 0,
  });

  @override
  State<SuperadminOperationalScreen> createState() =>
      _SuperadminOperationalScreenState();
}

class _SuperadminOperationalScreenState
    extends State<SuperadminOperationalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  // Local state for operational hours
  int _selectedDayOfWeek = 1; // 1 = Senin .. 7 = Minggu
  bool _isWorkDay = true;
  late TimeOfDay _timeMasuk;
  late TimeOfDay _timeIstirahatKeluar;
  late TimeOfDay _timeIstirahatMasuk;
  late TimeOfDay _timePulang;
  late int _toleransiMenit;
  late bool _autoLockOutside;

  // Local state for office location view
  late String _activeOfficeId;

  bool _isInitialized = false;

  String get _currentDayName {
    switch (_selectedDayOfWeek) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  void _loadDaySchedule(int dayOfWeek, SystemSettingsProvider settingsProv) {
    final dayConfig =
        settingsProv.operationalHours.getScheduleForDay(dayOfWeek);
    setState(() {
      _selectedDayOfWeek = dayOfWeek;
      _isWorkDay = dayConfig.isWorkDay;
      _timeMasuk =
          _parseTime(dayConfig.masuk, const TimeOfDay(hour: 8, minute: 0));
      _timeIstirahatKeluar = _parseTime(
          dayConfig.istirahatKeluar, const TimeOfDay(hour: 12, minute: 0));
      _timeIstirahatMasuk = _parseTime(
          dayConfig.istirahatMasuk, const TimeOfDay(hour: 13, minute: 0));
      _timePulang =
          _parseTime(dayConfig.pulang, const TimeOfDay(hour: 17, minute: 0));
      _toleransiMenit = dayConfig.toleransiMenit;
    });
  }

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSubTabIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final settingsProv = context.read<SystemSettingsProvider>();
      final hours = settingsProv.operationalHours;
      final geo = settingsProv.geofencing;

      _autoLockOutside = hours.autoLockOutside;

      _activeOfficeId = geo.activeOfficeId;

      final currentWeekday = DateTime.now().weekday;
      _loadDaySchedule(currentWeekday, settingsProv);

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String val, TimeOfDay fallback) {
    try {
      final parts = val.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return fallback;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SystemSettingsProvider>();

    final content = Column(
      children: [
        // Top Sub Tab Selector
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _subTabController,
            indicator: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            labelStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule_rounded, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Jam Operasional',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apartment_rounded, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Titik Kantor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sub Tab Views
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildOperationalHoursView(context, settingsProv),
              _buildGeofencingView(context, settingsProv),
            ],
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Jam Operasional & Lokasi Kantor',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: content,
    );
  }

  // ==========================================
  // TAB 1: PENGATURAN JAM OPERASIONAL 4 SLOT
  // ==========================================
  Widget _buildOperationalHoursView(
      BuildContext context, SystemSettingsProvider settingsProv) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. DAY OF WEEK SELECTOR (SENIN - MINGGU)
              _buildDaySelector(settingsProv),
              const SizedBox(height: 14),

              // 2. OPERATIONAL HOURS SLOTS (ACTIVE DAY CONFIGURATION)
              if (_isWorkDay) ...[
                _buildSlotTimeCard(
                  slotNum: '1',
                  title: 'Absensi 1: Masuk',
                  subtitle:
                      'Mulai jam kerja dan batas perhitungan keterlambatan',
                  time: _timeMasuk,
                  color: AppColors.checkIn,
                  icon: Icons.login_rounded,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _timeMasuk,
                    );
                    if (picked != null) setState(() => _timeMasuk = picked);
                  },
                ),
                const SizedBox(height: 8),

                _buildSlotTimeCard(
                  slotNum: '2',
                  title: 'Absensi 2: Istirahat Keluar',
                  subtitle: _selectedDayOfWeek == 5
                      ? 'Istirahat siang Sholat Jumat (default: 11:30 WIB)'
                      : 'Awal jam istirahat siang karyawan',
                  time: _timeIstirahatKeluar,
                  color: AppColors.breakOut,
                  icon: Icons.free_breakfast_outlined,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _timeIstirahatKeluar,
                    );
                    if (picked != null) {
                      setState(() => _timeIstirahatKeluar = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),

                _buildSlotTimeCard(
                  slotNum: '3',
                  title: 'Absensi 3: Istirahat Masuk',
                  subtitle: _selectedDayOfWeek == 5
                      ? 'Selesai istirahat Sholat Jumat (default: 13:30 WIB)'
                      : 'Selesai istirahat & kembali aktif bekerja',
                  time: _timeIstirahatMasuk,
                  color: AppColors.breakIn,
                  icon: Icons.work_outline_rounded,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _timeIstirahatMasuk,
                    );
                    if (picked != null) {
                      setState(() => _timeIstirahatMasuk = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),

                _buildSlotTimeCard(
                  slotNum: '4',
                  title: 'Absensi 4: Pulang',
                  subtitle: _selectedDayOfWeek == 6
                      ? 'Jam kepulangan hari kerja setengah hari'
                      : 'Waktu akhir jam kerja harian',
                  time: _timePulang,
                  color: AppColors.checkOut,
                  icon: Icons.logout_rounded,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _timePulang,
                    );
                    if (picked != null) setState(() => _timePulang = picked);
                  },
                ),
                const SizedBox(height: 14),

                // Tolerance Slider Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Toleransi Keterlambatan Hari $_currentDayName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_toleransiMenit Menit',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pegawai yang melakukan presensi masuk hari $_currentDayName setelah ${_formatTimeOfDay(_timeMasuk)} + $_toleransiMenit menit akan ditandai sebagai Terlambat dan wajib mengisi alasan.',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      Slider(
                        value: _toleransiMenit.toDouble(),
                        min: 0,
                        max: 60,
                        divisions: 12,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _toleransiMenit = val.toInt());
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0 mnt (Ketat)',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant)),
                          Text('30 mnt',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant)),
                          Text('60 mnt',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                // Holiday Friendly Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.beach_access_rounded,
                          size: 36,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hari $_currentDayName Ditetapkan Sebagai Hari Libur',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Karyawan tidak memiliki kewajiban presensi masuk atau pulang pada hari libur operasional.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3. ACTION BUTTONS FOR THE SELECTED DAY
              ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final updatedDay = DayScheduleConfig(
                    dayOfWeek: _selectedDayOfWeek,
                    dayName: _currentDayName,
                    isWorkDay: _isWorkDay,
                    masuk: _formatTimeOfDay(_timeMasuk),
                    istirahatKeluar: _formatTimeOfDay(_timeIstirahatKeluar),
                    istirahatMasuk: _formatTimeOfDay(_timeIstirahatMasuk),
                    pulang: _formatTimeOfDay(_timePulang),
                    toleransiMenit: _toleransiMenit,
                  );
                  await settingsProv.saveDaySchedule(updatedDay);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                              'Jadwal jam kerja hari $_currentDayName berhasil disimpan.'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: Text('Simpan Jadwal Hari $_currentDayName'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Auto-lock Outside Operational Hours Setting
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoLockOutside,
                  activeThumbColor: AppColors.secondary,
                  title: const Text(
                    'Kunci Tombol di Luar Jadwal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Tombol presensi otomatis terkunci jika belum masuk jam kerja.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  onChanged: (val) {
                    setState(() => _autoLockOutside = val);
                    settingsProv.saveAutoLockOutside(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(SystemSettingsProvider settingsProv) {
    final days = [
      {'day': 1, 'name': 'Senin', 'short': 'Sen'},
      {'day': 2, 'name': 'Selasa', 'short': 'Sel'},
      {'day': 3, 'name': 'Rabu', 'short': 'Rab'},
      {'day': 4, 'name': 'Kamis', 'short': 'Kam'},
      {'day': 5, 'name': 'Jumat', 'short': 'Jum'},
      {'day': 6, 'name': 'Sabtu', 'short': 'Sab'},
      {'day': 7, 'name': 'Minggu', 'short': 'Min'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Hari Operasional (Senin - Minggu)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Pilih hari terlebih dahulu untuk mengatur jam kerja khusus',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal 7-Day Selector Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: days.map((d) {
                final dayNum = d['day'] as int;
                final shortName = d['short'] as String;
                final isSelected = _selectedDayOfWeek == dayNum;
                final sched =
                    settingsProv.operationalHours.getScheduleForDay(dayNum);
                final isWork = sched.isWorkDay;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _loadDaySchedule(dayNum, settingsProv),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isWork
                                  ? AppColors.surfaceContainerLowest
                                  : AppColors.surfaceContainerLow),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.outlineVariant
                                    .withValues(alpha: 0.4),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              shortName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isWork
                                        ? AppColors.onSurface
                                        : AppColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : (isWork
                                        ? AppColors.primary
                                            .withValues(alpha: 0.1)
                                        : AppColors.outlineVariant
                                            .withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isWork ? sched.masuk : 'Libur',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isWork
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEAEDFF)),
          const SizedBox(height: 10),

          // Active Selected Day Header & Work Day Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isWorkDay ? AppColors.checkIn : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                          children: [
                            const TextSpan(text: 'Hari Terpilih: '),
                            TextSpan(
                              text: '$_currentDayName ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            TextSpan(
                              text:
                                  _isWorkDay ? '(Hari Kerja)' : '(Hari Libur)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isWorkDay
                                    ? AppColors.checkIn
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isWorkDay ? 'Hari Aktif' : 'Libur',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isWorkDay
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _isWorkDay,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.35),
                      onChanged: (val) {
                        setState(() => _isWorkDay = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTimeCard({
    required String slotNum,
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatTimeOfDay(time),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('WIB',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600)),
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

  // ==========================================
  // TAB 2: MANAJEMEN LOKASI KANTOR PENEMPATAN
  // ==========================================
  Widget _buildGeofencingView(
      BuildContext context, SystemSettingsProvider settingsProv) {
    final geo = settingsProv.geofencing;

    // Kantor yang sedang dipilih untuk diinspeksi & dipratinjau
    final activeOffice = geo.offices.firstWhere(
      (o) => o.id == _activeOfficeId,
      orElse: () => settingsProv.activeOffice,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. PILIH TITIK KANTOR UNTUK PRATINJAU PETA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Titik Kantor Pratinjau',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: geo.offices.any((o) => o.id == activeOffice.id)
                            ? activeOffice.id
                            : (geo.offices.isNotEmpty
                                ? geo.offices.first.id
                                : null),
                        isExpanded: true,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        dropdownColor: AppColors.surfaceContainerLowest,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        items: geo.offices.map((off) {
                          return DropdownMenuItem<String>(
                            value: off.id,
                            child: Row(
                              children: [
                                Icon(
                                  off.isPrimary
                                      ? Icons.star_rounded
                                      : Icons.apartment_rounded,
                                  size: 16,
                                  color: off.isPrimary
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    off.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (off.isPrimary
                                            ? AppColors.primary
                                            : AppColors.secondary)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    off.isPrimary ? 'Utama' : 'Cabang',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: off.isPrimary
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            setState(() {
                              _activeOfficeId = newId;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. KARTU DETAIL KANTOR YANG SEDANG DIINSPEKSI
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          activeOffice.isPrimary
                              ? Icons.account_balance_rounded
                              : Icons.location_on_rounded,
                          color: activeOffice.isPrimary
                              ? AppColors.primary
                              : AppColors.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeOffice.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (activeOffice.isPrimary
                                    ? AppColors.primary
                                    : AppColors.secondary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeOffice.isPrimary
                                ? 'Kantor Utama'
                                : 'Kantor Cabang',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: activeOffice.isPrimary
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeOffice.address,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Koordinat: ${activeOffice.latitude.toStringAsFixed(5)}, ${activeOffice.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. MINI MAP VISUAL REPRESENTATION (TANPA GEOFENCE OVERLAY)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Map Tile Layer
                      Positioned.fill(
                        child: Image.network(
                          ApiConfig.cartoRasterTileUrl(
                            16,
                            _lon2tile(activeOffice.longitude, 16),
                            _lat2tile(activeOffice.latitude, 16),
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE5E7EB),
                            child: const Center(
                              child: Text('Peta Titik Kantor',
                                  style: TextStyle(color: Colors.black54)),
                            ),
                          ),
                        ),
                      ),
                      // Office Marker Pin
                      const Center(
                        child: Icon(
                          Icons.location_pin,
                          color: AppColors.error,
                          size: 36,
                        ),
                      ),
                      // Open In Maps button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              LocationService.showMapChooserSheet(
                                context,
                                activeOffice.latitude,
                                activeOffice.longitude,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Navigasi Maps',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. DAFTAR TITIK KANTOR & CABANG
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Daftar Titik Kantor (${geo.offices.length} Lokasi Penempatan)',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Semua titik kantor aktif bersamaan sebagai acuan penempatan karyawan',
                        style: TextStyle(
                            fontSize: 10.5, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showAddOfficeDialog(context, settingsProv),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_location_alt_rounded,
                              size: 15,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tambah Titik Baru',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...geo.offices.map((office) {
                final isSelected = office.id == activeOffice.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withValues(alpha: 0.04)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: office.isPrimary
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : isSelected
                                ? AppColors.secondary
                                : AppColors.outlineVariant
                                    .withValues(alpha: 0.35),
                        width:
                            office.isPrimary ? 1.8 : (isSelected ? 1.5 : 1.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.02),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: office.isPrimary
                                      ? AppColors.primary
                                          .withValues(alpha: 0.12)
                                      : AppColors.secondary
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  office.isPrimary
                                      ? Icons.account_balance_rounded
                                      : Icons.location_city_rounded,
                                  color: office.isPrimary
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            office.name,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Inter',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Badge Kantor Utama vs Cabang
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: office.isPrimary
                                                ? AppColors.primary
                                                    .withValues(alpha: 0.12)
                                                : AppColors.secondary
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: office.isPrimary
                                                  ? AppColors.primary
                                                      .withValues(alpha: 0.4)
                                                  : AppColors.secondary
                                                      .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                office.isPrimary
                                                    ? Icons.star_rounded
                                                    : Icons.apartment_rounded,
                                                size: 11,
                                                color: office.isPrimary
                                                    ? AppColors.primary
                                                    : AppColors.secondary,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                office.isPrimary
                                                    ? 'Kantor Utama'
                                                    : 'Kantor Cabang',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: office.isPrimary
                                                      ? AppColors.primary
                                                      : AppColors.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      office.address,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainer,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'GPS: ${office.latitude.toStringAsFixed(4)}, ${office.longitude.toStringAsFixed(4)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 4),

                          // Control Actions: Utamakan, Ubah, Hapus (Lebar Seimbang)
                          Row(
                            children: [
                              if (!office.isPrimary) ...[
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        await settingsProv
                                            .setAsPrimaryOffice(office.id);
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '"${office.name}" berhasil ditetapkan sebagai Kantor Utama.',
                                            ),
                                            behavior:
                                                SnackBarBehavior.floating,
                                            backgroundColor:
                                                AppColors.primary,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD97706),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFD97706)
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Utamakan',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showEditOfficeDialog(
                                        context, settingsProv, office),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.secondary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.edit_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              office.isPrimary
                                                  ? 'Ubah Data Kantor'
                                                  : 'Ubah',
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!office.isPrimary) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showDeleteOfficeDialog(
                                          context, settingsProv, office),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.error
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.delete_forever_rounded,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Hapus',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 6. SIMPAN PENGATURAN KANTOR PENEMPATAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await settingsProv.saveGeofencing(
                      strictMode: false,
                      activeOfficeId: _activeOfficeId,
                      activeRadius: 50.0,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Titik acuan kantor penempatan (${geo.offices.length} kantor) berhasil diperbarui.'),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text(
                    'Simpan Acuan Lokasi Kantor',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.secondary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RESOLVE GOOGLE MAPS LINK & COORDINATES
  // ==========================================
  Future<Map<String, dynamic>?> _resolveMapCoordinates(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // 1. Raw coordinates "-7.1234, 112.5678"
    final rawMatch = RegExp(r'^(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$')
        .firstMatch(text);
    if (rawMatch != null) {
      final lat = double.tryParse(rawMatch.group(1)!);
      final lng = double.tryParse(rawMatch.group(2)!);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'name': null};
      }
    }

    // 2. Direct regex match on standard Google Maps URLs
    final d3d4Match =
        RegExp(r'!3d(-?\d+(?:\.\d+)?)(?:!)?4d(-?\d+(?:\.\d+)?)')
            .firstMatch(text);
    if (d3d4Match != null) {
      final lat = double.tryParse(d3d4Match.group(1)!);
      final lng = double.tryParse(d3d4Match.group(2)!);
      String? placeName;
      final placeMatch = RegExp(r'/place/([^/@?#]+)').firstMatch(text);
      if (placeMatch != null) {
        placeName =
            Uri.decodeComponent(placeMatch.group(1)!.replaceAll('+', ' '));
      }
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'name': placeName};
      }
    }

    final atMatch =
        RegExp(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)').firstMatch(text);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      String? placeName;
      final placeMatch = RegExp(r'/place/([^/@?#]+)').firstMatch(text);
      if (placeMatch != null) {
        placeName =
            Uri.decodeComponent(placeMatch.group(1)!.replaceAll('+', ' '));
      }
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'name': placeName};
      }
    }

    final qMatch = RegExp(
            r'(?:[?&](?:q|query|ll)=)(?:loc:)?(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)')
        .firstMatch(text);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng, 'name': null};
      }
    }

    // 3. For short URLs (e.g. maps.app.goo.gl) or redirects, call API resolver
    try {
      final uri = Uri.parse(ApiConfig.resolveMapsUrl).replace(
        queryParameters: {'url': text},
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final d = json['data'];
          final lat = (d['latitude'] as num?)?.toDouble();
          final lng = (d['longitude'] as num?)?.toDouble();
          final name = d['name'] as String?;
          if (lat != null && lng != null) {
            return {'lat': lat, 'lng': lng, 'name': name};
          }
        }
      }
    } catch (e) {
      debugPrint('Error resolving map URL via API: $e');
    }

    return null;
  }

  void _showAddOfficeDialog(
    BuildContext context,
    SystemSettingsProvider settingsProv,
  ) {
    _showOfficeFormDialog(
      context: context,
      settingsProv: settingsProv,
      existingOffice: null,
    );
  }

  void _showEditOfficeDialog(
    BuildContext context,
    SystemSettingsProvider settingsProv,
    OfficeLocationItem office,
  ) {
    _showOfficeFormDialog(
      context: context,
      settingsProv: settingsProv,
      existingOffice: office,
    );
  }

  void _showOfficeFormDialog({
    required BuildContext context,
    required SystemSettingsProvider settingsProv,
    OfficeLocationItem? existingOffice,
  }) {
    final isEdit = existingOffice != null;
    final nameCtrl = TextEditingController(text: existingOffice?.name ?? '');
    final addrCtrl = TextEditingController(text: existingOffice?.address ?? '');
    final latCtrl = TextEditingController(
      text: existingOffice != null
          ? existingOffice.latitude.toString()
          : '0.92031',
    );
    final lngCtrl = TextEditingController(
      text: existingOffice != null
          ? existingOffice.longitude.toString()
          : '104.46069',
    );
    final mapLinkCtrl = TextEditingController();
    double currentRadius = existingOffice?.radius ?? 100.0;
    bool isPrimaryOffice = existingOffice?.isPrimary ?? false;

    double previewLat = double.tryParse(latCtrl.text) ?? 0.92031;
    double previewLng = double.tryParse(lngCtrl.text) ?? 104.46069;
    bool isResolving = false;
    String? resolveStatus;
    bool resolveSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> handleResolveLink() async {
            final link = mapLinkCtrl.text.trim();
            if (link.isEmpty) return;

            setDialogState(() {
              isResolving = true;
              resolveStatus = null;
            });

            final result = await _resolveMapCoordinates(link);

            setDialogState(() {
              isResolving = false;
              if (result != null &&
                  result['lat'] != null &&
                  result['lng'] != null) {
                final lat = result['lat'] as double;
                final lng = result['lng'] as double;
                latCtrl.text = lat.toStringAsFixed(6);
                lngCtrl.text = lng.toStringAsFixed(6);
                previewLat = lat;
                previewLng = lng;
                resolveSuccess = true;
                resolveStatus = 'Titik lokasi peta berhasil ditentukan!';

                final placeName = result['name'] as String?;
                if (placeName != null && placeName.isNotEmpty) {
                  if (nameCtrl.text.trim().isEmpty) {
                    nameCtrl.text = placeName;
                  }
                  if (addrCtrl.text.trim().isEmpty) {
                    addrCtrl.text = placeName;
                  }
                }
              } else {
                resolveSuccess = false;
                resolveStatus =
                    'Gagal mendeteksi koordinat dari tautan. Pastikan tautan Google Maps valid.';
              }
            });
          }

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 660),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. DIALOG HEADER (STICKY)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isEdit
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.secondary
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_location_alt_rounded
                                : Icons.add_location_alt_rounded,
                            color: isEdit
                                ? AppColors.primary
                                : AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isEdit
                                    ? 'Ubah Titik Lokasi Kantor'
                                    : 'Tambah Titik Lokasi Kantor Baru',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Perbarui data titik penempatan & radius'
                                    : 'Atur koordinat presensi & basis penempatan',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: AppColors.onSurfaceVariant,
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // 2. SCROLLABLE CONTENT BODY
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Klasifikasi Titik (Kantor Cabang vs Kantor Utama)
                          const Text(
                            'Klasifikasi Titik Kantor:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setDialogState(
                                        () => isPrimaryOffice = false),
                                    borderRadius: BorderRadius.circular(9),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !isPrimaryOffice
                                            ? AppColors.secondary
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        boxShadow: !isPrimaryOffice
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.secondary
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apartment_rounded,
                                            size: 14,
                                            color: !isPrimaryOffice
                                                ? Colors.white
                                                : AppColors.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Kantor Cabang',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: !isPrimaryOffice
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: !isPrimaryOffice
                                                  ? Colors.white
                                                  : AppColors
                                                      .onSurfaceVariant,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setDialogState(
                                        () => isPrimaryOffice = true),
                                    borderRadius: BorderRadius.circular(9),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isPrimaryOffice
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        boxShadow: isPrimaryOffice
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: isPrimaryOffice
                                                ? Colors.white
                                                : AppColors.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Kantor Utama',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isPrimaryOffice
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: isPrimaryOffice
                                                  ? Colors.white
                                                  : AppColors
                                                      .onSurfaceVariant,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // TAUTAN GOOGLE MAPS (INPUT TAUTAN PETA)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.share_location_rounded,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Tautan Google Maps / Share Lokasi:',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Otomatis',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: mapLinkCtrl,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'Inter'),
                            onSubmitted: (_) => handleResolveLink(),
                            decoration: InputDecoration(
                              hintText:
                                  'Tempel tautan (misal: https://maps.app.goo.gl/...)',
                              hintStyle: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                              prefixIcon: const Icon(Icons.link_rounded,
                                  size: 17, color: AppColors.secondary),
                              suffixIcon: isResolving
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 6),
                                      child: ElevatedButton(
                                        onPressed: handleResolveLink,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.secondary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          minimumSize: const Size(60, 32),
                                        ),
                                        child: const Text(
                                          'Terapkan',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (resolveStatus != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: resolveSuccess
                                    ? const Color(0xFFE6F4EA)
                                    : const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: resolveSuccess
                                      ? const Color(0xFF34A853)
                                          .withValues(alpha: 0.4)
                                      : const Color(0xFFEA4335)
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    resolveSuccess
                                        ? Icons.check_circle_rounded
                                        : Icons.error_outline_rounded,
                                    size: 14,
                                    color: resolveSuccess
                                        ? const Color(0xFF137333)
                                        : const Color(0xFFC5221F),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      resolveStatus!,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: resolveSuccess
                                            ? const Color(0xFF137333)
                                            : const Color(0xFFC5221F),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // LIVE MINI MAP PREVIEW TITIK KOORDINAT
                          Container(
                            height: 125,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      ApiConfig.cartoRasterTileUrl(
                                        16,
                                        _lon2tile(previewLng, 16),
                                        _lat2tile(previewLat, 16),
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        color: const Color(0xFFE5E7EB),
                                        child: const Center(
                                          child: Text(
                                            'Peta Titik Lokasi',
                                            style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Geofence Circle Overlay simulation (dynamic with currentRadius)
                                  Center(
                                    child: Container(
                                      width: (45.0 +
                                              ((currentRadius - 50.0) / 450.0) *
                                                  75.0)
                                          .clamp(45.0, 125.0),
                                      height: (45.0 +
                                              ((currentRadius - 50.0) / 450.0) *
                                                  75.0)
                                          .clamp(45.0, 125.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.secondary
                                            .withValues(alpha: 0.18),
                                        border: Border.all(
                                          color: AppColors.secondary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Office Center Marker Pin
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Icon(
                                        Icons.location_pin,
                                        color: AppColors.error,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  // Bottom coordinate pill
                                  Positioned(
                                    bottom: 6,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Titik: ${previewLat.toStringAsFixed(5)}, ${previewLng.toStringAsFixed(5)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                                fontFamily: 'Inter',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            'Radius ${currentRadius.toInt()}m',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // NAMA KANTOR
                          const Text(
                            'Nama Kantor / Unit Pelayanan:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            style: const TextStyle(
                                fontSize: 12.5, fontFamily: 'Inter'),
                            decoration: InputDecoration(
                              hintText:
                                  'Contoh: Kantor Pusat PERUMDA Tirta Kepri',
                              hintStyle: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                              prefixIcon: const Icon(Icons.business_rounded,
                                  size: 17,
                                  color: AppColors.onSurfaceVariant),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ALAMAT LOKASI
                          const Text(
                            'Alamat Lengkap:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: addrCtrl,
                            maxLines: 2,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'Inter'),
                            decoration: InputDecoration(
                              hintText:
                                  'Contoh: Jl. M.T Haryono Km.3, Tanjungpinang',
                              hintStyle: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 18),
                                child: Icon(Icons.place_rounded,
                                    size: 17,
                                    color: AppColors.onSurfaceVariant),
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // RADIUS PRESENSI (SLIDER INTERAKTIF 50M - 500M)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.radar_rounded,
                                    size: 15,
                                    color: AppColors.secondary,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Radius Presensi Geofence:',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${currentRadius.round()} Meter',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.secondary,
                              inactiveTrackColor: AppColors.outlineVariant
                                  .withValues(alpha: 0.35),
                              thumbColor: AppColors.secondary,
                              overlayColor: AppColors.secondary
                                  .withValues(alpha: 0.15),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14),
                            ),
                            child: Slider(
                              value: currentRadius.clamp(50.0, 500.0),
                              min: 50.0,
                              max: 500.0,
                              divisions: 45,
                              label: '${currentRadius.round()}m',
                              onChanged: (val) {
                                setDialogState(() => currentRadius = val);
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '50m (Ketat)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  '250m',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  '500m (Maksimal)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // KOORDINAT LATITUDE & LONGITUDE
                          const Text(
                            'Titik Koordinat Manual:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: latCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                      fontSize: 11.5, fontFamily: 'Inter'),
                                  onChanged: (val) {
                                    final parsed =
                                        double.tryParse(val.trim());
                                    if (parsed != null) {
                                      setDialogState(
                                          () => previewLat = parsed);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Latitude',
                                    labelStyle: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant),
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppColors.surfaceContainerLowest,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: AppColors.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.secondary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: lngCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                      fontSize: 11.5, fontFamily: 'Inter'),
                                  onChanged: (val) {
                                    final parsed =
                                        double.tryParse(val.trim());
                                    if (parsed != null) {
                                      setDialogState(
                                          () => previewLng = parsed);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Longitude',
                                    labelStyle: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant),
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppColors.surfaceContainerLowest,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: AppColors.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.secondary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. DIALOG ACTIONS BAR (STICKY BOTTOM)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);

                              final parsedLat =
                                  double.tryParse(latCtrl.text.trim()) ??
                                      previewLat;
                              final parsedLng =
                                  double.tryParse(lngCtrl.text.trim()) ??
                                      previewLng;

                              if (isEdit) {
                                final updated = existingOffice.copyWith(
                                  name: nameCtrl.text.trim(),
                                  address: addrCtrl.text.trim(),
                                  latitude: parsedLat,
                                  longitude: parsedLng,
                                  radius: currentRadius,
                                  isPrimary: isPrimaryOffice,
                                );
                                await settingsProv
                                    .updateOfficeLocation(updated);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Perubahan pada "${updated.name}" berhasil disimpan.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                final item = OfficeLocationItem(
                                  id: 'office_${DateTime.now().millisecondsSinceEpoch}',
                                  name: nameCtrl.text.trim(),
                                  address: addrCtrl.text.trim(),
                                  latitude: parsedLat,
                                  longitude: parsedLng,
                                  radius: currentRadius,
                                  isPrimary: isPrimaryOffice,
                                );
                                await settingsProv.addOfficeLocation(item);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Titik ${item.officeTypeLabel} "${nameCtrl.text.trim()}" berhasil ditambahkan.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              isEdit ? 'Simpan Perubahan' : 'Simpan Lokasi',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteOfficeDialog(
    BuildContext context,
    SystemSettingsProvider settingsProv,
    OfficeLocationItem office,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Titik Kantor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus titik kantor cabang "${office.name}"?',
          style:
              const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await settingsProv.deleteOfficeLocation(office.id);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            'Titik kantor cabang "${office.name}" berhasil dihapus.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text(
                    'Ya, Hapus',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Math helpers for Slippy Map tiles
  static int _lon2tile(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  static int _lat2tile(double lat, int zoom) {
    return ((1.0 -
                math.log(math.tan(lat * math.pi / 180.0) +
                        1.0 / math.cos(lat * math.pi / 180.0)) /
                    math.pi) /
            2.0 *
            (1 << zoom))
        .floor();
  }
}
