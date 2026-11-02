import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/services/budget_alert_planner.dart';
import '../local/app_database.dart';

abstract interface class LocalNotifier {
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

class NoopNotifier implements LocalNotifier {
  const NoopNotifier();

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}
}

class SystemLocalNotifier implements LocalNotifier {
  SystemLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notify'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          '预算提醒',
          channelDescription: '支出接近或超过预算时提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

class BudgetAlertService {
  BudgetAlertService(this._database, this._notifier);

  final AppDatabase _database;
  final LocalNotifier _notifier;

  Database get _db => _database.db;

  /// Persists newly crossed thresholds for [year]/[month] and fires a local
  /// notification once per threshold. Alerts for other months are left alone.
  /// Returns the messages that should stay visible in the app.
  Future<List<String>> sync({
    required int year,
    required int month,
    required List<BudgetAlert> alerts,
  }) async {
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    final desired = {for (final alert in alerts) alert.key: alert};
    final existingRows = await _db.query('budget_alerts');
    final existing = {
      for (final row in existingRows) row['alert_key']! as String,
    };

    for (final key in existing) {
      if (!key.startsWith(prefix) || desired.containsKey(key)) continue;
      await _db.delete('budget_alerts', where: 'alert_key = ?', whereArgs: [key]);
    }

    for (final alert in alerts) {
      if (existing.contains(alert.key)) continue;
      await _db.insert('budget_alerts', {
        'alert_key': alert.key,
        'message': alert.message,
        'fired_at': DateTime.now().millisecondsSinceEpoch,
      });
      try {
        await _notifier.show(
          id: alert.key.hashCode & 0x7fffffff,
          title: '预算提醒',
          body: alert.message,
        );
      } catch (_) {
        // The in-app banner still shows if the system notification fails.
      }
    }
    return [for (final alert in alerts) alert.message];
  }
}
