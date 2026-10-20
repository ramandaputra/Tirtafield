import 'dart:math' as math;
import 'package:flutter/material.dart';
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
                        'Lokasi Kantor & Penempatan',
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
              // 1. BANNER STATUS LOKASI KANTOR & PENEMPATAN LAPANGAN
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Titik Kantor & Basis Penempatan',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                '${geo.offices.length} Titik Kantor Aktif Bersamaan',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF34A853)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 11, color: Color(0xFF137333)),
                              SizedBox(width: 4),
                              Text(
                                'Semua Aktif',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF137333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Setiap karyawan ditempatkan pada kantor tertentu (misalnya Raja di Kantor Utama A, Faiz di Cabang B, Diva di Cabang C). Saat karyawan bertugas di lapangan dan melakukan absensi online, sistem otomatis menghitung jarak dari titik GPS lapangan karyawan ke kantor penempatannya masing-masing.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. PILIH TITIK KANTOR UNTUK PRATINJAU PETA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Titik Kantor untuk Dipratinjau di Peta:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: geo.offices.map((off) {
                        final isCurr = off.id == activeOffice.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              off.isPrimary
                                  ? Icons.star_rounded
                                  : Icons.apartment_rounded,
                              size: 15,
                              color: isCurr
                                  ? Colors.white
                                  : (off.isPrimary
                                      ? AppColors.primary
                                      : AppColors.secondary),
                            ),
                            label: Text(
                              off.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight:
                                    isCurr ? FontWeight.w700 : FontWeight.w600,
                                color:
                                    isCurr ? Colors.white : AppColors.onSurface,
                              ),
                            ),
                            selected: isCurr,
                            selectedColor: AppColors.secondary,
                            backgroundColor: AppColors.surfaceContainerLowest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isCurr
                                    ? AppColors.secondary
                                    : AppColors.outlineVariant
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _activeOfficeId = off.id;
                              });
                            },
                          ),
                        );
                      }).toList(),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Titik Acuan Aktif',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF137333),
                            ),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE6F4EA),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF34A853)
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 6,
                                                color: Color(0xFF137333),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Acuan Aktif',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF137333),
                                                ),
                                              ),
                                            ],
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

                          // Control Actions: Tampilkan di Peta, Jadikan Kantor Utama, Ubah, Hapus
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              // Kalibrasi status / tombol pilih
                              if (isSelected)
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.secondary,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Sedang Ditampilkan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _activeOfficeId = office.id;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.outlineVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.visibility_rounded,
                                            size: 14,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Tampilkan di Peta',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Action Buttons: Utamakan, Ubah, Hapus
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (!office.isPrimary) ...[
                                    Material(
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
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFFDE68A),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                size: 14,
                                                color: Color(0xFFB45309),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Utamakan',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFB45309),
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showEditOfficeDialog(
                                          context, settingsProv, office),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 32,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.outlineVariant
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ubah',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!office.isPrimary) ...[
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showDeleteOfficeDialog(
                                            context, settingsProv, office),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.error
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                size: 14,
                                                color: AppColors.error,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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

  void _showAddOfficeDialog(
    BuildContext context,
    SystemSettingsProvider settingsProv,
  ) {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '0.92031');
    final lngCtrl = TextEditingController(text: '104.46069');
    bool isPrimaryOffice = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Tambah Titik Lokasi Kantor Baru',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tentukan Klasifikasi Titik:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Kantor Cabang'),
                      selected: !isPrimaryOffice,
                      onSelected: (val) {
                        setDialogState(() => isPrimaryOffice = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Kantor Utama'),
                      selected: isPrimaryOffice,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (val) {
                        setDialogState(() => isPrimaryOffice = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kantor / Unit Pelayanan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lokasi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final item = OfficeLocationItem(
                  id: 'office_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text.trim()) ?? 0.92031,
                  longitude: double.tryParse(lngCtrl.text.trim()) ?? 104.46069,
                  radius: 50.0,
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
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Simpan Lokasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOfficeDialog(
    BuildContext context,
    SystemSettingsProvider settingsProv,
    OfficeLocationItem office,
  ) {
    final nameCtrl = TextEditingController(text: office.name);
    final addrCtrl = TextEditingController(text: office.address);
    final latCtrl = TextEditingController(text: office.latitude.toString());
    final lngCtrl = TextEditingController(text: office.longitude.toString());
    bool isPrimaryOffice = office.isPrimary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Ubah Titik Lokasi Kantor',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Klasifikasi Titik:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Kantor Cabang'),
                      selected: !isPrimaryOffice,
                      onSelected: (val) {
                        setDialogState(() => isPrimaryOffice = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Kantor Utama'),
                      selected: isPrimaryOffice,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (val) {
                        setDialogState(() => isPrimaryOffice = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kantor / Unit Pelayanan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lokasi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final updated = office.copyWith(
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  latitude:
                      double.tryParse(latCtrl.text.trim()) ?? office.latitude,
                  longitude:
                      double.tryParse(lngCtrl.text.trim()) ?? office.longitude,
                  radius: office.radius,
                  isPrimary: isPrimaryOffice,
                );
                await settingsProv.updateOfficeLocation(updated);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Perubahan pada "${updated.name}" berhasil disimpan.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Simpan Perubahan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
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
            label: const Text('Ya, Hapus Titik'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
