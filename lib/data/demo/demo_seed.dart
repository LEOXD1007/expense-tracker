import 'package:uuid/uuid.dart';

import '../../domain/models/budget.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/entry_repository.dart';

const _uuid = Uuid();

/// Sample month used by screenshots and `--dart-define=SEED_DEMO=true`.
/// Entries are dated in [now]'s month, and only on days up to [now].
Future<void> seedDemoData({
  required EntryRepository entries,
  required BudgetRepository budgets,
  required DateTime now,
}) async {
  final year = now.year;
  final month = now.month;

  Future<void> add({
    required String id,
    required int day,
    required int cents,
    required EntryType type,
    required String categoryId,
    String? note,
  }) async {
    if (day > now.day) return;
    final occurred = DateTime(year, month, day);
    await entries.upsert(
      LedgerEntry(
        id: id,
        amountCents: cents,
        type: type,
        categoryId: categoryId,
        occurredOn: occurred,
        note: note,
        createdAt: occurred,
        updatedAt: occurred,
      ),
    );
  }

  await add(id: 'demo-salary', day: 1, cents: 1850000, type: EntryType.income, categoryId: 'inc_salary', note: '十一月工资');
  await add(id: 'demo-invest', day: 10, cents: 32000, type: EntryType.income, categoryId: 'inc_invest', note: '基金分红');
  await add(id: 'demo-part', day: 15, cents: 80000, type: EntryType.income, categoryId: 'inc_parttime', note: '周末兼职');

  await add(id: 'demo-food-1', day: 1, cents: 3600, type: EntryType.expense, categoryId: 'exp_food', note: '早餐');
  await add(id: 'demo-transit-1', day: 2, cents: 1200, type: EntryType.expense, categoryId: 'exp_transit', note: '地铁');
  await add(id: 'demo-food-2', day: 2, cents: 4800, type: EntryType.expense, categoryId: 'exp_food', note: '午餐');
  await add(id: 'demo-shop-1', day: 3, cents: 26800, type: EntryType.expense, categoryId: 'exp_shopping', note: '日用品');
  await add(id: 'demo-fun-1', day: 4, cents: 8600, type: EntryType.expense, categoryId: 'exp_fun', note: '电影');
  await add(id: 'demo-food-3', day: 5, cents: 6200, type: EntryType.expense, categoryId: 'exp_food', note: '晚餐');
  await add(id: 'demo-home', day: 6, cents: 250000, type: EntryType.expense, categoryId: 'exp_home', note: '房租');
  await add(id: 'demo-food-4', day: 7, cents: 4100, type: EntryType.expense, categoryId: 'exp_food');
  await add(id: 'demo-med', day: 8, cents: 18000, type: EntryType.expense, categoryId: 'exp_medical', note: '感冒药');
  await add(id: 'demo-transit-2', day: 9, cents: 3500, type: EntryType.expense, categoryId: 'exp_transit', note: '打车');
  await add(id: 'demo-food-5', day: 10, cents: 12800, type: EntryType.expense, categoryId: 'exp_food', note: '聚餐');
  await add(id: 'demo-edu', day: 11, cents: 19900, type: EntryType.expense, categoryId: 'exp_edu', note: '课程');
  await add(id: 'demo-shop-2', day: 12, cents: 56000, type: EntryType.expense, categoryId: 'exp_shopping', note: '衣服');
  await add(id: 'demo-food-6', day: 13, cents: 3300, type: EntryType.expense, categoryId: 'exp_food');
  await add(id: 'demo-fun-2', day: 14, cents: 4500, type: EntryType.expense, categoryId: 'exp_fun', note: '游戏');
  await add(id: 'demo-comm', day: 15, cents: 5900, type: EntryType.expense, categoryId: 'exp_comm', note: '话费');
  await add(id: 'demo-food-7', day: 16, cents: 7600, type: EntryType.expense, categoryId: 'exp_food', note: '咖啡');
  await add(id: 'demo-transit-3', day: 17, cents: 1800, type: EntryType.expense, categoryId: 'exp_transit');
  await add(id: 'demo-food-8', day: 18, cents: 5200, type: EntryType.expense, categoryId: 'exp_food', note: '午餐');

  final updated = DateTime(year, month, 1);
  await budgets.upsert(
    Budget(
      id: _uuid.v4(),
      year: year,
      month: month,
      categoryId: null,
      amountCents: 500000,
      updatedAt: updated,
    ),
  );
  await budgets.upsert(
    Budget(
      id: _uuid.v4(),
      year: year,
      month: month,
      categoryId: 'exp_food',
      amountCents: 50000,
      updatedAt: updated,
    ),
  );
  await budgets.upsert(
    Budget(
      id: _uuid.v4(),
      year: year,
      month: month,
      categoryId: 'exp_shopping',
      amountCents: 60000,
      updatedAt: updated,
    ),
  );
  await budgets.upsert(
    Budget(
      id: _uuid.v4(),
      year: year,
      month: month,
      categoryId: 'exp_transit',
      amountCents: 30000,
      updatedAt: updated,
    ),
  );
  await budgets.upsert(
    Budget(
      id: _uuid.v4(),
      year: year,
      month: month,
      categoryId: 'exp_fun',
      amountCents: 20000,
      updatedAt: updated,
    ),
  );
  await budgets.upsert(
    Budget(
      id: _uuid.v4(),
      year: year,
      month: month,
      categoryId: 'exp_home',
      amountCents: 250000,
      updatedAt: updated,
    ),
  );
}
