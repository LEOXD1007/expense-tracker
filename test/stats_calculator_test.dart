import 'package:expense_tracker/domain/models/category.dart';
import 'package:expense_tracker/domain/models/entry_type.dart';
import 'package:expense_tracker/domain/models/ledger_entry.dart';
import 'package:expense_tracker/domain/services/stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final food = _category('exp_food', '餐饮', EntryType.expense);
  final salary = _category('inc_salary', '工资', EntryType.income);
  final categories = {food.id: food, salary.id: salary};

  LedgerEntry entry({
    required int cents,
    required EntryType type,
    required String categoryId,
    required DateTime day,
  }) {
    return LedgerEntry(
      id: '$categoryId-${day.day}-$cents',
      amountCents: cents,
      type: type,
      categoryId: categoryId,
      occurredOn: day,
      note: null,
      createdAt: day,
      updatedAt: day,
    );
  }

  test('sums income, expense, balance, and category share', () {
    final stats = StatsCalculator.calculate(
      year: 2026,
      month: 11,
      categories: categories,
      entries: [
        entry(cents: 10000, type: EntryType.expense, categoryId: 'exp_food', day: DateTime(2026, 11, 2)),
        entry(cents: 5000, type: EntryType.expense, categoryId: 'missing', day: DateTime(2026, 11, 3)),
        entry(cents: 20000, type: EntryType.income, categoryId: 'inc_salary', day: DateTime(2026, 11, 1)),
        entry(cents: 999, type: EntryType.expense, categoryId: 'exp_food', day: DateTime(2026, 10, 31)),
      ],
    );

    expect(stats.incomeCents, 20000);
    expect(stats.expenseCents, 15000);
    expect(stats.balanceCents, 5000);
    expect(stats.expenseByCategory, hasLength(2));
    expect(stats.expenseByCategory.first.categoryName, '餐饮');
    expect(stats.expenseByCategory.first.amountCents, 10000);
    expect(stats.expenseByCategory.first.ratio, closeTo(10000 / 15000, 0.0001));
    expect(stats.expenseByCategory.last.categoryName, '未分类');
    expect(stats.incomeByCategory.single.categoryName, '工资');
    expect(stats.daily, hasLength(30));
    expect(stats.daily[1].expenseCents, 10000);
    expect(stats.daily[0].incomeCents, 20000);
  });

  test('daily series respects month length and today', () {
    int length(int year, int month, {DateTime? today}) {
      return StatsCalculator.calculate(
        year: year,
        month: month,
        entries: const [],
        categories: const {},
        today: today,
      ).daily.length;
    }

    expect(length(2024, 2), 29);
    expect(length(2025, 2), 28);
    expect(length(2026, 11), 30);
    expect(length(2026, 11, today: DateTime(2026, 11, 18)), 18);
    expect(length(2026, 12, today: DateTime(2026, 11, 18)), 0);
    expect(length(2026, 10, today: DateTime(2026, 11, 18)), 31);
  });
}

Category _category(String id, String name, EntryType type) {
  final now = DateTime(2026, 1, 1);
  return Category(
    id: id,
    name: name,
    type: type,
    iconKey: 'other',
    colorValue: 0xFF112233,
    isBuiltin: true,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}
