class DayScheduleConfig {
  final int dayOfWeek; // 1 = Senin, 2 = Selasa, 3 = Rabu, 4 = Kamis, 5 = Jumat, 6 = Sabtu, 7 = Minggu
  final String dayName;
  final bool isWorkDay;
  final String masuk;
  final String istirahatKeluar;
  final String istirahatMasuk;
  final String pulang;
  final int toleransiMenit;

  const DayScheduleConfig({
    required this.dayOfWeek,
    required this.dayName,
    this.isWorkDay = true,
    this.masuk = '08:00',
    this.istirahatKeluar = '12:00',
    this.istirahatMasuk = '13:00',
    this.pulang = '17:00',
    this.toleransiMenit = 15,
  });

  DayScheduleConfig copyWith({
    int? dayOfWeek,
    String? dayName,
    bool? isWorkDay,
    String? masuk,
    String? istirahatKeluar,
    String? istirahatMasuk,
    String? pulang,
    int? toleransiMenit,
  }) {
    return DayScheduleConfig(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayName: dayName ?? this.dayName,
      isWorkDay: isWorkDay ?? this.isWorkDay,
      masuk: masuk ?? this.masuk,
      istirahatKeluar: istirahatKeluar ?? this.istirahatKeluar,
      istirahatMasuk: istirahatMasuk ?? this.istirahatMasuk,
      pulang: pulang ?? this.pulang,
      toleransiMenit: toleransiMenit ?? this.toleransiMenit,
    );
  }

  bool isLateForCheckIn(DateTime time) {
    if (!isWorkDay) return false;
    final parts = masuk.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;
    final limitMinutes = (h * 60) + m + toleransiMenit;
    final currentMinutes = (time.hour * 60) + time.minute;
    return currentMinutes > limitMinutes;
  }

  int getLateDurationMinutes(DateTime time) {
    if (!isWorkDay) return 0;
    final parts = masuk.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;
    final limitMinutes = (h * 60) + m + toleransiMenit;
    final currentMinutes = (time.hour * 60) + time.minute;
    final diff = currentMinutes - limitMinutes;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'day_name': dayName,
      'is_work_day': isWorkDay,
      'masuk': masuk,
      'istirahat_keluar': istirahatKeluar,
      'istirahat_masuk': istirahatMasuk,
      'pulang': pulang,
      'toleransi_menit': toleransiMenit,
    };
  }

  factory DayScheduleConfig.fromJson(Map<String, dynamic> json) {
    return DayScheduleConfig(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      dayName: json['day_name'] as String? ?? 'Senin',
      isWorkDay: json['is_work_day'] as bool? ?? true,
      masuk: json['masuk'] as String? ?? '08:00',
      istirahatKeluar: json['istirahat_keluar'] as String? ?? '12:00',
      istirahatMasuk: json['istirahat_masuk'] as String? ?? '13:00',
      pulang: json['pulang'] as String? ?? '17:00',
      toleransiMenit: (json['toleransi_menit'] as num?)?.toInt() ?? 15,
    );
  }
}

class OperationalHoursConfig {
  final List<DayScheduleConfig> dailySchedules;
  final bool autoLockOutside;
  final String hariKerja;

  const OperationalHoursConfig({
    this.dailySchedules = defaultDailySchedules,
    this.autoLockOutside = true,
    this.hariKerja = 'Senin - Jumat (5 Hari Kerja)',
  });

  static const List<DayScheduleConfig> defaultDailySchedules = [
    DayScheduleConfig(
      dayOfWeek: 1,
      dayName: 'Senin',
      isWorkDay: true,
      masuk: '08:00',
      istirahatKeluar: '12:00',
      istirahatMasuk: '13:00',
      pulang: '17:00',
      toleransiMenit: 15,
    ),
    DayScheduleConfig(
      dayOfWeek: 2,
      dayName: 'Selasa',
      isWorkDay: true,
      masuk: '08:00',
      istirahatKeluar: '12:00',
      istirahatMasuk: '13:00',
      pulang: '17:00',
      toleransiMenit: 15,
    ),
    DayScheduleConfig(
      dayOfWeek: 3,
      dayName: 'Rabu',
      isWorkDay: true,
      masuk: '08:00',
      istirahatKeluar: '12:00',
      istirahatMasuk: '13:00',
      pulang: '17:00',
      toleransiMenit: 15,
    ),
    DayScheduleConfig(
      dayOfWeek: 4,
      dayName: 'Kamis',
      isWorkDay: true,
      masuk: '08:00',
      istirahatKeluar: '12:00',
      istirahatMasuk: '13:00',
      pulang: '17:00',
      toleransiMenit: 15,
    ),
    DayScheduleConfig(
      dayOfWeek: 5,
      dayName: 'Jumat',
      isWorkDay: true,
      masuk: '08:00',
      istirahatKeluar: '11:30',
      istirahatMasuk: '13:30',
      pulang: '17:00',
      toleransiMenit: 15,
    ),
    DayScheduleConfig(
      dayOfWeek: 6,
      dayName: 'Sabtu',
      isWorkDay: false,
      masuk: '08:00',
      istirahatKeluar: '12:00',
      istirahatMasuk: '12:30',
      pulang: '13:00',
      toleransiMenit: 15,
    ),
    DayScheduleConfig(
      dayOfWeek: 7,
      dayName: 'Minggu',
      isWorkDay: false,
      masuk: '08:00',
      istirahatKeluar: '12:00',
      istirahatMasuk: '13:00',
      pulang: '17:00',
      toleransiMenit: 15,
    ),
  ];

  DayScheduleConfig getScheduleForDay(int weekday) {
    return dailySchedules.firstWhere(
      (d) => d.dayOfWeek == weekday,
      orElse: () => defaultDailySchedules.firstWhere(
        (d) => d.dayOfWeek == weekday,
        orElse: () => defaultDailySchedules.first,
      ),
    );
  }

  DayScheduleConfig get todaySchedule =>
      getScheduleForDay(DateTime.now().weekday);

  String get masuk => todaySchedule.masuk;
  String get istirahatKeluar => todaySchedule.istirahatKeluar;
  String get istirahatMasuk => todaySchedule.istirahatMasuk;
  String get pulang => todaySchedule.pulang;
  int get toleransiMenit => todaySchedule.toleransiMenit;

  bool isLateForCheckIn(DateTime time) {
    return getScheduleForDay(time.weekday).isLateForCheckIn(time);
  }

  int getLateDurationMinutes(DateTime time) {
    return getScheduleForDay(time.weekday).getLateDurationMinutes(time);
  }

  OperationalHoursConfig copyWith({
    List<DayScheduleConfig>? dailySchedules,
    bool? autoLockOutside,
    String? hariKerja,
  }) {
    return OperationalHoursConfig(
      dailySchedules: dailySchedules ?? this.dailySchedules,
      autoLockOutside: autoLockOutside ?? this.autoLockOutside,
      hariKerja: hariKerja ?? this.hariKerja,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masuk': masuk,
      'istirahat_keluar': istirahatKeluar,
      'istirahat_masuk': istirahatMasuk,
      'pulang': pulang,
      'toleransi_menit': toleransiMenit,
      'auto_lock_outside': autoLockOutside,
      'hari_kerja': hariKerja,
      'daily_schedules': dailySchedules.map((e) => e.toJson()).toList(),
    };
  }

  factory OperationalHoursConfig.fromJson(Map<String, dynamic> json) {
    List<DayScheduleConfig> schedules = [];
    if (json['daily_schedules'] is List) {
      schedules = (json['daily_schedules'] as List)
          .map((item) =>
              DayScheduleConfig.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (schedules.isEmpty) {
      final legacyMasuk = json['masuk'] as String? ?? '08:00';
      final legacyIstirahatKeluar =
          json['istirahat_keluar'] as String? ?? '12:00';
      final legacyIstirahatMasuk =
          json['istirahat_masuk'] as String? ?? '13:00';
      final legacyPulang = json['pulang'] as String? ?? '17:00';
      final legacyToleransi =
          (json['toleransi_menit'] as num?)?.toInt() ?? 15;

      schedules = [
        DayScheduleConfig(
          dayOfWeek: 1,
          dayName: 'Senin',
          isWorkDay: true,
          masuk: legacyMasuk,
          istirahatKeluar: legacyIstirahatKeluar,
          istirahatMasuk: legacyIstirahatMasuk,
          pulang: legacyPulang,
          toleransiMenit: legacyToleransi,
        ),
        DayScheduleConfig(
          dayOfWeek: 2,
          dayName: 'Selasa',
          isWorkDay: true,
          masuk: legacyMasuk,
          istirahatKeluar: legacyIstirahatKeluar,
          istirahatMasuk: legacyIstirahatMasuk,
          pulang: legacyPulang,
          toleransiMenit: legacyToleransi,
        ),
        DayScheduleConfig(
          dayOfWeek: 3,
          dayName: 'Rabu',
          isWorkDay: true,
          masuk: legacyMasuk,
          istirahatKeluar: legacyIstirahatKeluar,
          istirahatMasuk: legacyIstirahatMasuk,
          pulang: legacyPulang,
          toleransiMenit: legacyToleransi,
        ),
        DayScheduleConfig(
          dayOfWeek: 4,
          dayName: 'Kamis',
          isWorkDay: true,
          masuk: legacyMasuk,
          istirahatKeluar: legacyIstirahatKeluar,
          istirahatMasuk: legacyIstirahatMasuk,
          pulang: legacyPulang,
          toleransiMenit: legacyToleransi,
        ),
        DayScheduleConfig(
          dayOfWeek: 5,
          dayName: 'Jumat',
          isWorkDay: true,
          masuk: legacyMasuk,
          istirahatKeluar: '11:30',
          istirahatMasuk: '13:30',
          pulang: legacyPulang,
          toleransiMenit: legacyToleransi,
        ),
        DayScheduleConfig(
          dayOfWeek: 6,
          dayName: 'Sabtu',
          isWorkDay: false,
          masuk: legacyMasuk,
          istirahatKeluar: '12:00',
          istirahatMasuk: '12:30',
          pulang: '13:00',
          toleransiMenit: legacyToleransi,
        ),
        DayScheduleConfig(
          dayOfWeek: 7,
          dayName: 'Minggu',
          isWorkDay: false,
          masuk: legacyMasuk,
          istirahatKeluar: legacyIstirahatKeluar,
          istirahatMasuk: legacyIstirahatMasuk,
          pulang: legacyPulang,
          toleransiMenit: legacyToleransi,
        ),
      ];
    }

    return OperationalHoursConfig(
      dailySchedules: schedules,
      autoLockOutside: json['auto_lock_outside'] as bool? ?? true,
      hariKerja:
          json['hari_kerja'] as String? ?? 'Senin - Jumat (5 Hari Kerja)',
    );
  }
}

class OfficeLocationItem {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isPrimary;

  const OfficeLocationItem({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius = 50.0,
    this.isPrimary = false,
  });

  String get officeTypeLabel => isPrimary ? 'Kantor Utama' : 'Kantor Cabang';
  String get officeTypeBadge => isPrimary ? 'Kantor Utama (Pusat)' : 'Kantor Cabang';

  OfficeLocationItem copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isPrimary,
  }) {
    return OfficeLocationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_primary': isPrimary,
    };
  }

  factory OfficeLocationItem.fromJson(Map<String, dynamic> json) {
    return OfficeLocationItem(
      id: json['id'] as String? ?? 'office_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Kantor',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.92031,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 104.46069,
      radius: (json['radius'] as num?)?.toDouble() ?? 50.0,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class GeofencingConfig {
  final bool strictMode;
  final String activeOfficeId;
  final List<OfficeLocationItem> offices;

  OfficeLocationItem get primaryOffice => offices.firstWhere(
        (o) => o.isPrimary,
        orElse: () => offices.isNotEmpty
            ? offices.first
            : const OfficeLocationItem(
                id: 'hq',
                name: 'Kantor Pusat Tirtafield Tanjung Pinang',
                address:
                    'Jl. Wisata Bahari No. 12, Tanjung Pinang Timur, Kepulauan Riau',
                latitude: 0.92031,
                longitude: 104.46069,
                radius: 50.0,
                isPrimary: true,
              ),
      );

  List<OfficeLocationItem> get branchOffices =>
      offices.where((o) => !o.isPrimary).toList();

  const GeofencingConfig({
    this.strictMode = true,
    this.activeOfficeId = 'hq',
    this.offices = const [
      OfficeLocationItem(
        id: 'hq',
        name: 'Kantor Pusat Tirtafield Tanjung Pinang',
        address: 'Jl. Wisata Bahari No. 12, Tanjung Pinang Timur, Kepulauan Riau',
        latitude: 0.92031,
        longitude: 104.46069,
        radius: 50.0,
        isPrimary: true,
      ),
      OfficeLocationItem(
        id: 'bintan_center',
        name: 'Unit Pelayanan Bintan Centre',
        address: 'Komp. Bintan Centre Blok A No. 5-6, Tanjung Pinang',
        latitude: 0.92550,
        longitude: 104.47120,
        radius: 60.0,
        isPrimary: false,
      ),
      OfficeLocationItem(
        id: 'ipa_sei_pulai',
        name: 'Instalasi Pengolahan Air (IPA) Sei Pulai',
        address: 'Kawasan Waduk Sei Pulai, Bintan',
        latitude: 0.90810,
        longitude: 104.43250,
        radius: 100.0,
        isPrimary: false,
      ),
    ],
  });

  GeofencingConfig copyWith({
    bool? strictMode,
    String? activeOfficeId,
    List<OfficeLocationItem>? offices,
  }) {
    return GeofencingConfig(
      strictMode: strictMode ?? this.strictMode,
      activeOfficeId: activeOfficeId ?? this.activeOfficeId,
      offices: offices ?? this.offices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strict_mode': strictMode,
      'active_office_id': activeOfficeId,
      'offices': offices.map((o) => o.toJson()).toList(),
    };
  }

  factory GeofencingConfig.fromJson(Map<String, dynamic> json) {
    var rawOffices = json['offices'] as List<dynamic>? ?? [];
    List<OfficeLocationItem> list = rawOffices
        .map((e) => OfficeLocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isEmpty) {
      list = const GeofencingConfig().offices;
    }
    return GeofencingConfig(
      strictMode: json['strict_mode'] as bool? ?? true,
      activeOfficeId: json['active_office_id'] as String? ?? 'hq',
      offices: list,
    );
  }
}

class SystemSettingsModel {
  final OperationalHoursConfig operationalHours;
  final GeofencingConfig geofencing;

  const SystemSettingsModel({
    this.operationalHours = const OperationalHoursConfig(),
    this.geofencing = const GeofencingConfig(),
  });

  SystemSettingsModel copyWith({
    OperationalHoursConfig? operationalHours,
    GeofencingConfig? geofencing,
  }) {
    return SystemSettingsModel(
      operationalHours: operationalHours ?? this.operationalHours,
      geofencing: geofencing ?? this.geofencing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operational_hours': operationalHours.toJson(),
      'geofencing': geofencing.toJson(),
    };
  }

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      operationalHours: json['operational_hours'] != null
          ? OperationalHoursConfig.fromJson(
              json['operational_hours'] as Map<String, dynamic>)
          : const OperationalHoursConfig(),
      geofencing: json['geofencing'] != null
          ? GeofencingConfig.fromJson(
              json['geofencing'] as Map<String, dynamic>)
          : const GeofencingConfig(),
    );
  }
}
