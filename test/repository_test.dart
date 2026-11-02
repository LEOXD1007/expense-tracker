import 'dart:convert';
import 'dart:io';

import 'package:expense_tracker/bootstrap.dart';
import 'package:expense_tracker/data/export/file_exporter.dart';
import 'package:expense_tracker/data/local/app_database.dart';
import 'package:expense_tracker/data/local/sqlite_repositories.dart';
import 'package:expense_tracker/data/notifications/budget_alert_service.dart';
import 'package:expense_tracker/domain/failures.dart';
import 'package:expense_tracker/domain/models/budget.dart';
import 'package:expense_tracker/domain/models/budget_level.dart';
import 'package:expense_tracker/domain/models/category.dart';
import 'package:expense_tracker/domain/models/entry_type.dart';
import 'package:expense_tracker/domain/models/ledger_entry.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/domain/services/budget_alert_planner.dart';
import 'package:expense_tracker/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('jizhang_test_');
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  Future<AppDatabase> openDb() {
    return AppDatabase.open(path: '${temp.path}/jizhang.db');
  }

  test('seeds built-in categories and stores entries by month', () async {
    final database = await openDb();
    final categories = SqliteCategoryRepository(database);
    final entries = SqliteEntryRepository(database);
    final all = await categories.getAll();
    expect(all.where((category) => category.type == EntryType.expense), hasLength(10));
    expect(all.where((category) => category.type == EntryType.income), hasLength(5));
    expect(all.every((category) => category.isBuiltin), isTrue);

    final now = DateTime(2026, 11, 18, 9, 30);
    await entries.upsert(
      LedgerEntry(
        id: 'lunch',
        amountCents: 3550,
        type: EntryType.expense,
        categoryId: 'exp_food',
        occurredOn: now,
        note: '  午餐  ',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await entries.upsert(
      LedgerEntry(
        id: 'october',
        amountCents: 100,
        type: EntryType.expense,
        categoryId: 'exp_food',
        occurredOn: DateTime(2026, 10, 31),
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await entries.upsert(
      LedgerEntry(
        id: 'leap',
        amountCents: 200,
        type: EntryType.expense,
        categoryId: 'exp_food',
        occurredOn: DateTime(2024, 2, 29),
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final november = await entries.getByMonth(2026, 11);
    expect(november.map((entry) => entry.id), ['lunch']);
    expect(november.single.note, '午餐');
    expect(november.single.occurredOn, DateTime(2026, 11, 18));
    expect(await entries.getByMonth(2024, 2), hasLength(1));
    expect(await entries.getByMonth(2024, 3), isEmpty);

    await entries.upsert(
      november.single.copyWith(amountCents: 4000, note: '晚餐', updatedAt: now),
    );
    expect((await entries.getById('lunch'))!.amountCents, 4000);
    await entries.delete('lunch');
    expect(await entries.getByMonth(2026, 11), isEmpty);

    expect(
      () => entries.upsert(
        LedgerEntry(
          id: 'bad',
          amountCents: 100,
          type: EntryType.income,
          categoryId: 'exp_food',
          occurredOn: now,
          note: null,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<InvalidRecordException>()),
    );
    await database.close();
  });

  test('custom categories can be edited and deleted, built-ins cannot', () async {
    final database = await openDb();
    final categories = SqliteCategoryRepository(database);
    final entries = SqliteEntryRepository(database);
    final now = DateTime(2026, 11, 1);
    final custom = Category(
      id: 'custom_pet',
      name: '宠物',
      type: EntryType.expense,
      iconKey: 'pet',
      colorValue: 0xFF7A5AF5,
      isBuiltin: true,
      sortOrder: -1,
      createdAt: now,
      updatedAt: now,
    );
    await categories.add(custom);
    final stored = await categories.getById('custom_pet');
    expect(stored!.isBuiltin, isFalse);
    expect(stored.sortOrder, greaterThan(0));

    await categories.update(stored.copyWith(name: '猫猫', updatedAt: now));
    expect((await categories.getById('custom_pet'))!.name, '猫猫');

    await expectLater(
      categories.delete('exp_food'),
      throwsA(
        isA<CategoryDeleteException>().having(
          (error) => error.failure,
          'failure',
          CategoryDeleteFailure.builtin,
        ),
      ),
    );

    await entries.upsert(
      LedgerEntry(
        id: 'pet-food',
        amountCents: 1000,
        type: EntryType.expense,
        categoryId: 'custom_pet',
        occurredOn: now,
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await entries.countByCategory('custom_pet'), 1);
    await expectLater(
      categories.delete('custom_pet'),
      throwsA(
        isA<CategoryDeleteException>().having(
          (error) => error.failure,
          'failure',
          CategoryDeleteFailure.inUse,
        ),
      ),
    );
    await entries.delete('pet-food');
    await categories.delete('custom_pet');
    expect(await categories.getById('custom_pet'), isNull);
    await database.close();
  });

  test('budgets upsert by month and category', () async {
    final database = await openDb();
    final budgets = SqliteBudgetRepository(database);
    final now = DateTime(2026, 11, 1);
    await budgets.upsert(
      Budget(id: 'a', year: 2026, month: 11, categoryId: null, amountCents: 1000, updatedAt: now),
    );
    await budgets.upsert(
      Budget(id: 'b', year: 2026, month: 11, categoryId: null, amountCents: 2500, updatedAt: now),
    );
    await budgets.upsert(
      Budget(id: 'c', year: 2026, month: 11, categoryId: 'exp_food', amountCents: 800, updatedAt: now),
    );
    await budgets.upsert(
      Budget(id: 'd', year: 2026, month: 10, categoryId: null, amountCents: 900, updatedAt: now),
    );

    final november = await budgets.getForMonth(2026, 11);
    expect(november, hasLength(2));
    expect(november.singleWhere((budget) => budget.isTotal).amountCents, 2500);
    expect(november.singleWhere((budget) => budget.categoryId == 'exp_food').amountCents, 800);

    await budgets.deleteFor(year: 2026, month: 11, categoryId: null);
    expect((await budgets.getForMonth(2026, 11)).single.categoryId, 'exp_food');
    expect(await budgets.getForMonth(2026, 10), hasLength(1));
    await database.close();
  });

  test('budget alerts notify once per threshold and again after recovery', () async {
    final database = await openDb();
    final notifier = _RecordingNotifier();
    final service = BudgetAlertService(database, notifier);
    const warning = BudgetAlert(
      key: '2026-11-total-warning',
      message: '接近预算',
      level: BudgetLevel.warning,
    );
    final first = await service.sync(year: 2026, month: 11, alerts: [warning]);
    expect(first, ['接近预算']);
    expect(notifier.bodies, ['接近预算']);

    await service.sync(year: 2026, month: 11, alerts: [warning]);
    expect(notifier.bodies, ['接近预算']);

    const exceeded = BudgetAlert(
      key: '2026-11-total-exceeded',
      message: '超出预算',
      level: BudgetLevel.exceeded,
    );
    await service.sync(year: 2026, month: 11, alerts: [exceeded]);
    expect(notifier.bodies, ['接近预算', '超出预算']);

    await service.sync(year: 2026, month: 11, alerts: const []);
    await service.sync(year: 2026, month: 11, alerts: [exceeded]);
    expect(notifier.bodies, ['接近预算', '超出预算', '超出预算']);

    final otherMonth = await service.sync(
      year: 2026,
      month: 10,
      alerts: [
        const BudgetAlert(
          key: '2026-10-total-warning',
          message: '十月',
          level: BudgetLevel.warning,
        ),
      ],
    );
    expect(otherMonth, ['十月']);
    await service.sync(year: 2026, month: 11, alerts: [exceeded]);
    expect(notifier.bodies.where((body) => body == '十月'), hasLength(1));
    await database.close();
  });

  test('controller export writes csv bytes for the focused month', () async {
    final exporter = MemoryFileExporter();
    final controller = await bootstrap(
      databasePath: '${temp.path}/app.db',
      clock: () => DateTime(2026, 11, 18),
      exporter: exporter,
      notifier: const NoopNotifier(),
      initNotifications: false,
    );
    await controller.saveEntry(
      LedgerEntry(
        id: 'export-me',
        amountCents: 1200,
        type: EntryType.expense,
        categoryId: 'exp_transit',
        occurredOn: DateTime(2026, 11, 2),
        note: '地铁',
        createdAt: DateTime(2026, 11, 2),
        updatedAt: DateTime(2026, 11, 2),
      ),
    );
    final count = await controller.export(
      format: ExportFormat.csv,
      scope: ExportScope.month,
    );
    expect(count, 1);
    final file = exporter.files.values.single;
    final text = utf8.decode(file);
    expect(text, contains('交通'));
    expect(text, contains('12.00'));
    expect(text, contains('地铁'));
    await controller.database.close();
  });
}

class _RecordingNotifier implements LocalNotifier {
  final bodies = <String>[];

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    bodies.add(body);
  }
}
