import 'data/export/file_exporter.dart';
import 'data/local/app_database.dart';
import 'data/local/sqlite_repositories.dart';
import 'data/notifications/budget_alert_service.dart';
import 'state/app_controller.dart';

DateTime appClock() {
  const override = String.fromEnvironment('DEMO_TODAY');
  if (override.isEmpty) return DateTime.now();
  final parts = override.split('-');
  if (parts.length != 3) return DateTime.now();
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return DateTime.now();
  return DateTime(year, month, day);
}

Future<AppController> bootstrap({
  String? databasePath,
  Clock? clock,
  FileExporter? exporter,
  LocalNotifier? notifier,
  bool seedDemo = const bool.fromEnvironment('SEED_DEMO'),
  bool initNotifications = true,
}) async {
  final database = await AppDatabase.open(path: databasePath);
  final resolvedClock = clock ?? appClock;
  final LocalNotifier resolvedNotifier;
  if (notifier != null) {
    resolvedNotifier = notifier;
  } else {
    final systemNotifier = SystemLocalNotifier();
    if (initNotifications) {
      try {
        await systemNotifier.init();
      } catch (_) {
        // Desktop keeps the in-app warning when notifications are absent.
      }
    }
    resolvedNotifier = systemNotifier;
  }
  final controller = AppController(
    database: database,
    entries: SqliteEntryRepository(database),
    categories: SqliteCategoryRepository(database),
    budgets: SqliteBudgetRepository(database),
    alerts: BudgetAlertService(database, resolvedNotifier),
    exporter: exporter ?? const ShareFileExporter(),
    clock: resolvedClock,
  );
  if (seedDemo) {
    await controller.loadDemo();
  }
  await controller.load();
  return controller;
}
