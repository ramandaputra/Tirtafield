import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tirtafield/presentation/superadmin_it/screens/superadmin_employee_screen.dart';
import 'package:tirtafield/state/auth_provider.dart';
import 'package:tirtafield/state/employee_management_provider.dart';
import 'package:tirtafield/state/system_settings_provider.dart';

void main() {
  group('EmployeeManagementProvider Sorting Tests', () {
    test('default sort is nameAsc', () {
      final provider = EmployeeManagementProvider();
      expect(provider.sortOption, equals(EmployeeSortOption.nameAsc));
    });

    test('nameAsc sorts employees alphabetically by name A to Z', () {
      final provider = EmployeeManagementProvider();
      provider.setSortOption(EmployeeSortOption.nameAsc);
      final list = provider.filteredEmployees;
      for (int i = 0; i < list.length - 1; i++) {
        expect(
          list[i].name.toLowerCase().compareTo(list[i + 1].name.toLowerCase()),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('nameDesc sorts employees alphabetically by name Z to A', () {
      final provider = EmployeeManagementProvider();
      provider.setSortOption(EmployeeSortOption.nameDesc);
      final list = provider.filteredEmployees;
      for (int i = 0; i < list.length - 1; i++) {
        expect(
          list[i].name.toLowerCase().compareTo(list[i + 1].name.toLowerCase()),
          greaterThanOrEqualTo(0),
        );
      }
    });

    test('toggleSortDirection flips between Asc and Desc', () {
      final provider = EmployeeManagementProvider();
      expect(provider.sortOption, equals(EmployeeSortOption.nameAsc));

      provider.toggleSortDirection();
      expect(provider.sortOption, equals(EmployeeSortOption.nameDesc));

      provider.toggleSortDirection();
      expect(provider.sortOption, equals(EmployeeSortOption.nameAsc));
    });

    test('nipAsc sorts employees by NIK ascending', () {
      final provider = EmployeeManagementProvider();
      provider.setSortOption(EmployeeSortOption.nipAsc);
      final list = provider.filteredEmployees;
      for (int i = 0; i < list.length - 1; i++) {
        expect(list[i].nip.compareTo(list[i + 1].nip), lessThanOrEqualTo(0));
      }
    });

    test('resetFilters clears query, office, dept, role, and resets sort to nameAsc', () {
      final provider = EmployeeManagementProvider();
      provider.setSearchQuery('Superadmin');
      provider.setSortOption(EmployeeSortOption.nipDesc);
      expect(provider.hasActiveFilters, isTrue);

      provider.resetFilters();
      expect(provider.searchQuery, isEmpty);
      expect(provider.sortOption, equals(EmployeeSortOption.nameAsc));
      expect(provider.filterOfficeId, isNull);
      expect(provider.filterDepartment, isNull);
      expect(provider.filterRole, isNull);
      expect(provider.hasActiveFilters, isFalse);
    });
  });

  group('SuperadminEmployeeScreen Widget Tests for Sorting and Filtering', () {
    testWidgets('renders sort button, sort toggle, filter button and opens sort bottom sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProv = AuthProvider();
      final empProv = EmployeeManagementProvider();
      final settingsProv = SystemSettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProv),
            ChangeNotifierProvider<EmployeeManagementProvider>.value(value: empProv),
            ChangeNotifierProvider<SystemSettingsProvider>.value(value: settingsProv),
          ],
          child: const MaterialApp(
            home: SuperadminEmployeeScreen(initialSubTabIndex: 1), // Tab 2: Data Pegawai
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Sort Pill Button exists
      expect(find.text('Urut: Nama A-Z'), findsOneWidget);

      // Verify Filter Button exists
      expect(find.text('Filter'), findsOneWidget);

      // Tap Sort Pill Button to open sort modal
      await tester.tap(find.text('Urut: Nama A-Z'));
      await tester.pumpAndSettle();

      // Verify Sort Modal opened
      expect(find.text('Urutkan Direktori Pegawai'), findsOneWidget);
      expect(find.text('Nama (A - Z)'), findsOneWidget);
      expect(find.text('Nama (Z - A)'), findsOneWidget);
      expect(find.text('NIK (Terkecil - Terbesar)'), findsOneWidget);
      expect(find.text('Divisi & Departemen'), findsOneWidget);
      expect(find.text('Kantor Penempatan'), findsOneWidget);

      // Tap 'Nama (Z - A)'
      await tester.tap(find.text('Nama (Z - A)'));
      await tester.pumpAndSettle();

      // Verify Provider sortOption updated and pill text updated
      expect(empProv.sortOption, equals(EmployeeSortOption.nameDesc));
      expect(find.text('Urut: Nama Z-A'), findsOneWidget);
    });

    testWidgets('shows empty state when no employees match search query',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProv = AuthProvider();
      final empProv = EmployeeManagementProvider();
      final settingsProv = SystemSettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProv),
            ChangeNotifierProvider<EmployeeManagementProvider>.value(value: empProv),
            ChangeNotifierProvider<SystemSettingsProvider>.value(value: settingsProv),
          ],
          child: const MaterialApp(
            home: SuperadminEmployeeScreen(initialSubTabIndex: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type nonexistent query into search TextField
      await tester.enterText(find.byType(TextField), 'non_existent_random_person_xyz_123');
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Tidak Ada Pegawai Ditemukan'), findsOneWidget);
      expect(find.text('Reset Semua Filter & Pencarian'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset Semua Filter & Pencarian'));
      await tester.pumpAndSettle();

      // Verify empty state is gone and list is restored
      expect(find.text('Tidak Ada Pegawai Ditemukan'), findsNothing);
      expect(empProv.filteredEmployees.isNotEmpty, isTrue);
    });
  });
}
