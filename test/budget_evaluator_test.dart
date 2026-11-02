import 'package:expense_tracker/domain/models/budget.dart';
import 'package:expense_tracker/domain/models/budget_level.dart';
import 'package:expense_tracker/domain/models/category.dart';
import 'package:expense_tracker/domain/models/entry_type.dart';
import 'package:expense_tracker/domain/models/ledger_entry.dart';
import 'package:expense_tracker/domain/services/budget_alert_planner.dart';
import 'package:expense_tracker/domain/services/budget_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 1);
  final food = Category(
    id: 'exp_food',
    name: '餐饮',
    type: EntryType.expense,
    iconKey: 'restaurant',
    colorValue: 0xFFE25B45,
    isBuiltin: true,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );

  LedgerEntry expense(int cents, {String categoryId = 'exp_food', EntryType type = EntryType.expense}) {
    return LedgerEntry(
      id: '$categoryId-$cents-$type',
      amountCents: cents,
      type: type,
      categoryId: categoryId,
      occurredOn: DateTime(2026, 11, 2),
      note: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  Budget budget({String? categoryId, required int cents}) {
    return Budget(
      id: categoryId ?? 'total',
      year: 2026,
      month: 11,
      categoryId: categoryId,
      amountCents: cents,
      updatedAt: now,
    );
  }

  List<BudgetProgress> evaluate(List<Budget> budgets, List<LedgerEntry> entries) {
    return BudgetEvaluator.evaluate(
      budgets: budgets,
      entries: entries,
      categories: {food.id: food},
    );
  }

  test('levels follow the 80 percent and 100 percent thresholds', () {
    BudgetLevel level(int spent, int amount) {
      return evaluate(
        [budget(cents: amount)],
        [expense(spent)],
      ).single.level;
    }

    expect(level(799, 1000), BudgetLevel.ok);
    expect(level(800, 1000), BudgetLevel.warning);
    expect(level(999, 1000), BudgetLevel.warning);
    expect(level(1000, 1000), BudgetLevel.exceeded);
    expect(level(1500, 1000), BudgetLevel.exceeded);
  });

  test('percent display stays aligned with the threshold', () {
    int percent(int spent, int amount) {
      return evaluate([budget(cents: amount)], [expense(spent)]).single.percent;
    }

    expect(percent(799, 1000), 79);
    expect(percent(800, 1000), 80);
    expect(percent(1000, 1000), 100);
    expect(percent(1500, 1000), 150);
  });

  test('total budget ignores income and category budget is scoped', () {
    final progress = evaluate(
      [
        budget(cents: 10000),
        budget(categoryId: 'exp_food', cents: 4000),
      ],
      [
        expense(3200),
        expense(2500, categoryId: 'exp_transit'),
        expense(9000, type: EntryType.income, categoryId: 'inc_salary'),
      ],
    );

    expect(progress.first.isTotal, isTrue);
    expect(progress.first.spentCents, 5700);
    expect(progress.last.spentCents, 3200);
    expect(progress.last.categoryName, '餐饮');
    expect(progress.last.level, BudgetLevel.warning);
  });

  test('planner writes one alert per crossed budget and prefers exceeded', () {
    final progress = evaluate(
      [
        budget(cents: 1000),
        budget(categoryId: 'exp_food', cents: 1000),
      ],
      [expense(1000)],
    );
    final alerts = BudgetAlertPlanner.plan(progress: progress, year: 2026, month: 11);
    expect(alerts, hasLength(2));
    expect(alerts.every((alert) => alert.level == BudgetLevel.exceeded), isTrue);
    expect(alerts.map((alert) => alert.key), [
      '2026-11-exp_food-exceeded',
      '2026-11-total-exceeded',
    ]);
    expect(alerts.last.message, contains('本月支出已超出总预算'));
    expect(alerts.first.message, contains('「餐饮」已超出预算'));
  });

  test('planner stays quiet under the warning line', () {
    final progress = evaluate([budget(cents: 1000)], [expense(799)]);
    expect(BudgetAlertPlanner.plan(progress: progress, year: 2026, month: 11), isEmpty);
  });
}
