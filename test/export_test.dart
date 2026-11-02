import 'package:excel/excel.dart';
import 'package:expense_tracker/data/export/ledger_export.dart';
import 'package:expense_tracker/domain/models/category.dart';
import 'package:expense_tracker/domain/models/entry_type.dart';
import 'package:expense_tracker/domain/models/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 2);
  final categories = {
    'exp_food': Category(
      id: 'exp_food',
      name: '餐饮',
      type: EntryType.expense,
      iconKey: 'restaurant',
      colorValue: 1,
      isBuiltin: true,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    ),
  };
  final entries = [
    LedgerEntry(
      id: '1',
      amountCents: 3550,
      type: EntryType.expense,
      categoryId: 'exp_food',
      occurredOn: now,
      note: '午餐, "加面"',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  test('csv escapes commas and quotes and starts with a bom', () {
    final csv = CsvExporter.build(LedgerTable.rows(entries, categories));
    expect(csv, startsWith('\uFEFF'));
    expect(csv, contains('日期,类型,分类,金额,备注'));
    expect(csv, contains('2026-11-02,支出,餐饮,35.50,"午餐, ""加面"""'));
    expect(csv, contains('\r\n'));
  });

  test('xlsx round-trips the header and amount', () {
    final bytes = XlsxExporter.build(LedgerTable.rows(entries, categories));
    final decoded = Excel.decodeBytes(bytes);
    expect(decoded.tables.keys, contains('账单'));
    final rows = decoded['账单'].rows;
    expect(rows.first.map((cell) => cell?.value.toString()).toList(), LedgerTable.headers);
    expect(rows[1][3]?.value.toString(), '35.50');
    expect(bytes, isNotEmpty);
  });
}
