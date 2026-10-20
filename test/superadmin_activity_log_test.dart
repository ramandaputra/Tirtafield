import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tirtafield/data/models/activity_log_model.dart';
import 'package:tirtafield/presentation/superadmin_it/screens/superadmin_activity_log_screen.dart';
import 'package:tirtafield/state/activity_log_provider.dart';

void main() {
  group('ActivityLogProvider Tests', () {
    test('initializes with seed logs and calculates counters accurately', () {
      final provider = ActivityLogProvider();
      expect(provider.totalCount, greaterThanOrEqualTo(10));
      expect(provider.todayCount, greaterThanOrEqualTo(1));
      expect(provider.geofenceCount, greaterThanOrEqualTo(1));
      expect(provider.securityCount, greaterThanOrEqualTo(1));
    });

    test('filtering by category filters logs correctly', () {
      final provider = ActivityLogProvider();
      provider.setSelectedCategory(ActivityCategory.geofencing);
      for (final item in provider.filteredLogs) {
        expect(item.category, equals(ActivityCategory.geofencing));
      }

      // Reset
      provider.setSelectedCategory(null);
      expect(provider.filteredLogs.length, equals(provider.totalCount));
    });

    test('filtering by level filters logs correctly', () {
      final provider = ActivityLogProvider();
      provider.setSelectedLevel(ActivityLevel.critical);
      for (final item in provider.filteredLogs) {
        expect(item.level, equals(ActivityLevel.critical));
      }
    });

    test('search query filters title, description, and actor name', () {
      final provider = ActivityLogProvider();
      provider.setSearchQuery('Kantor Cabang');
      expect(provider.filteredLogs.isNotEmpty, isTrue);

      provider.setSearchQuery('non-existent-random-query-xyz');
      expect(provider.filteredLogs.isEmpty, isTrue);
    });

    test('CSV export returns valid format with headers', () {
      final provider = ActivityLogProvider();
      final csv = provider.exportToCsv();
      expect(
        csv.contains('ID,Waktu,Aktor,Role,NIP,Kategori,Tingkat,Judul,Deskripsi,Target,IP Address,Perangkat'),
        isTrue,
      );
      expect(csv.contains('act_001'), isTrue);
    });
  });

  group('SuperadminActivityLogScreen Widget Tests', () {
    testWidgets('renders header, KPI metrics, category chips, and activity cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final logProvider = ActivityLogProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ActivityLogProvider>.value(
            value: logProvider,
            child: const SuperadminActivityLogScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and AppBar actions
      expect(find.text('Log Aktivitas Superadmin'), findsOneWidget);
      expect(find.byTooltip('Ekspor Data CSV'), findsOneWidget);
      expect(find.byTooltip('Segarkan Log'), findsOneWidget);

      // Verify KPI Metrics
      expect(find.text('Total Aktivitas'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Geofence'), findsOneWidget);
      expect(find.text('Keamanan'), findsOneWidget);

      // Verify Search TextField
      expect(find.byType(TextField), findsOneWidget);

      // Verify Filter chips exist
      expect(find.text('Semua'), findsWidgets);
      expect(find.text('Geofencing'), findsOneWidget);
      expect(find.text('Persetujuan'), findsOneWidget);

      // Verify that activity cards are rendered
      expect(
        find.text('Penetapan Kantor Pusat sebagai Kantor Utama'),
        findsOneWidget,
      );
    });
  });
}
