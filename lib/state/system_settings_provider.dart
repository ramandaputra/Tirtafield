import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../data/models/system_settings_model.dart';

class SystemSettingsProvider extends ChangeNotifier {
  SystemSettingsModel _settings = const SystemSettingsModel();
  bool _isLoading = false;
  String? _errorMessage;

  SystemSettingsProvider() {
    loadSettings();
  }

  SystemSettingsModel get settings => _settings;
  OperationalHoursConfig get operationalHours => _settings.operationalHours;
  GeofencingConfig get geofencing => _settings.geofencing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  OfficeLocationItem get activeOffice {
    final list = _settings.geofencing.offices;
    final found = list.firstWhere(
      (o) => o.id == _settings.geofencing.activeOfficeId,
      orElse: () => list.isNotEmpty ? list.first : primaryOffice,
    );
    return found;
  }

  OfficeLocationItem get primaryOffice => _settings.geofencing.primaryOffice;
  List<OfficeLocationItem> get branchOffices => _settings.geofencing.branchOffices;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=get');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _settings = SystemSettingsModel.fromJson(body['data']);
        }
      }
    } catch (e) {
      // In case of network/offline, fallback to default in-memory config
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDaySchedule(DayScheduleConfig updatedDay) async {
    final list = List<DayScheduleConfig>.from(
      _settings.operationalHours.dailySchedules,
    );
    final idx = list.indexWhere((d) => d.dayOfWeek == updatedDay.dayOfWeek);
    if (idx != -1) {
      list[idx] = updatedDay;
    } else {
      list.add(updatedDay);
    }
    final updatedHours = _settings.operationalHours.copyWith(
      dailySchedules: list,
    );
    _settings = _settings.copyWith(operationalHours: updatedHours);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_operational');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedHours.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> copyScheduleToAllWorkDays(DayScheduleConfig template) async {
    final list = List<DayScheduleConfig>.from(
      _settings.operationalHours.dailySchedules,
    );
    for (int i = 0; i < list.length; i++) {
      if (list[i].dayOfWeek >= 1 && list[i].dayOfWeek <= 5) {
        list[i] = list[i].copyWith(
          isWorkDay: true,
          masuk: template.masuk,
          istirahatKeluar:
              list[i].dayOfWeek == 5 ? '11:30' : template.istirahatKeluar,
          istirahatMasuk:
              list[i].dayOfWeek == 5 ? '13:30' : template.istirahatMasuk,
          pulang: template.pulang,
          toleransiMenit: template.toleransiMenit,
        );
      }
    }
    final updatedHours = _settings.operationalHours.copyWith(
      dailySchedules: list,
    );
    _settings = _settings.copyWith(operationalHours: updatedHours);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_operational');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedHours.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> saveAutoLockOutside(bool autoLockOutside) async {
    final updatedHours = _settings.operationalHours.copyWith(
      autoLockOutside: autoLockOutside,
    );
    _settings = _settings.copyWith(operationalHours: updatedHours);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_operational');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedHours.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> saveOperationalHours({
    required String masuk,
    required String istirahatKeluar,
    required String istirahatMasuk,
    required String pulang,
    required int toleransiMenit,
    required bool autoLockOutside,
    String? hariKerja,
  }) async {
    final list = List<DayScheduleConfig>.from(
      _settings.operationalHours.dailySchedules,
    );
    for (int i = 0; i < list.length; i++) {
      if (list[i].isWorkDay) {
        list[i] = list[i].copyWith(
          masuk: masuk,
          istirahatKeluar: istirahatKeluar,
          istirahatMasuk: istirahatMasuk,
          pulang: pulang,
          toleransiMenit: toleransiMenit,
        );
      }
    }

    final updatedHours = _settings.operationalHours.copyWith(
      dailySchedules: list,
      autoLockOutside: autoLockOutside,
      hariKerja: hariKerja ?? _settings.operationalHours.hariKerja,
    );

    _settings = _settings.copyWith(operationalHours: updatedHours);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_operational');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedHours.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> saveGeofencing({
    required bool strictMode,
    required String activeOfficeId,
    required double activeRadius,
    Map<String, double>? officeRadii,
  }) async {
    final updatedOffices = _settings.geofencing.offices.map((o) {
      if (officeRadii != null && officeRadii.containsKey(o.id)) {
        return o.copyWith(radius: officeRadii[o.id]!);
      }
      if (o.id == activeOfficeId) {
        return o.copyWith(radius: activeRadius);
      }
      return o;
    }).toList();

    final updatedGeo = _settings.geofencing.copyWith(
      strictMode: strictMode,
      activeOfficeId: activeOfficeId,
      offices: updatedOffices,
    );

    _settings = _settings.copyWith(geofencing: updatedGeo);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_geofencing');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedGeo.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> setAsPrimaryOffice(String officeId) async {
    final updatedList = _settings.geofencing.offices.map((o) {
      return o.copyWith(isPrimary: o.id == officeId);
    }).toList();

    final updatedGeo = _settings.geofencing.copyWith(offices: updatedList);
    _settings = _settings.copyWith(geofencing: updatedGeo);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_geofencing');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedGeo.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> addOfficeLocation(OfficeLocationItem item) async {
    List<OfficeLocationItem> current = List.from(_settings.geofencing.offices);
    if (item.isPrimary) {
      current = current.map((o) => o.copyWith(isPrimary: false)).toList();
    }
    final updatedList = List<OfficeLocationItem>.from(current)..add(item);
    final updatedGeo = _settings.geofencing.copyWith(offices: updatedList);
    _settings = _settings.copyWith(geofencing: updatedGeo);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_geofencing');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedGeo.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateOfficeLocation(OfficeLocationItem item) async {
    final updatedList = _settings.geofencing.offices.map((o) {
      if (o.id == item.id) return item;
      if (item.isPrimary) return o.copyWith(isPrimary: false);
      return o;
    }).toList();

    final updatedGeo = _settings.geofencing.copyWith(offices: updatedList);
    _settings = _settings.copyWith(geofencing: updatedGeo);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_geofencing');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedGeo.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> deleteOfficeLocation(String officeId) async {
    final target = _settings.geofencing.offices.firstWhere(
      (o) => o.id == officeId,
      orElse: () => _settings.geofencing.offices.first,
    );
    if (target.isPrimary) return false; // Do not delete primary office

    final updatedList = _settings.geofencing.offices
        .where((o) => o.id != officeId)
        .toList();

    String activeId = _settings.geofencing.activeOfficeId;
    if (activeId == officeId) {
      activeId = _settings.geofencing.primaryOffice.id;
    }

    final updatedGeo = _settings.geofencing.copyWith(
      activeOfficeId: activeId,
      offices: updatedList,
    );
    _settings = _settings.copyWith(geofencing: updatedGeo);
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.settingsUrl}?action=save_geofencing');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updatedGeo.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return true;
    }
  }
}
