import 'package:sqflite/sqflite.dart';

import '../../core/dates.dart';
import '../../domain/failures.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/entry_repository.dart';
import 'app_database.dart';

String budgetCategoryKey(String? categoryId) => categoryId ?? '';

class SqliteCategoryRepository implements CategoryRepository {
  SqliteCategoryRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<List<Category>> getAll() async {
    final rows = await _db.query(
      'categories',
      orderBy: "CASE type WHEN 'expense' THEN 0 ELSE 1 END, sort_order, name",
    );
    return rows.map(_categoryFromRow).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final rows = await _db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _categoryFromRow(rows.first);
  }

  @override
  Future<void> add(Category category) async {
    final name = category.name.trim();
    if (name.isEmpty || name.length > 12) {
      throw const InvalidRecordException('分类名称需要 1 到 12 个字');
    }
    final order = category.sortOrder >= 0
        ? category.sortOrder
        : await _nextSortOrder(category.type);
    await _db.insert('categories', {
      'id': category.id,
      'name': name,
      'type': category.type.name,
      'icon_key': category.iconKey,
      'color_value': category.colorValue,
      'is_builtin': 0,
      'sort_order': order,
      'created_at': category.createdAt.millisecondsSinceEpoch,
      'updated_at': category.updatedAt.millisecondsSinceEpoch,
    });
  }

  Future<int> _nextSortOrder(EntryType type) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS m FROM categories WHERE type = ?',
      [type.name],
    );
    final max = Sqflite.firstIntValue(rows) ?? -1;
    return max + 1;
  }

  @override
  Future<void> update(Category category) async {
    final existing = await getById(category.id);
    if (existing == null) {
      throw const InvalidRecordException('分类不存在');
    }
    if (existing.type != category.type) {
      throw const InvalidRecordException('不能修改分类的收支类型');
    }
    final name = category.name.trim();
    if (name.isEmpty || name.length > 12) {
      throw const InvalidRecordException('分类名称需要 1 到 12 个字');
    }
    await _db.update(
      'categories',
      {
        'name': name,
        'icon_key': category.iconKey,
        'color_value': category.colorValue,
        'sort_order': category.sortOrder,
        'updated_at': category.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) return;
    if (existing.isBuiltin) {
      throw const CategoryDeleteException(CategoryDeleteFailure.builtin);
    }
    final used = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM entries WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;
    if (used > 0) {
      throw const CategoryDeleteException(CategoryDeleteFailure.inUse);
    }
    await _db.delete('budgets', where: 'category_key = ?', whereArgs: [id]);
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteEntryRepository implements EntryRepository {
  SqliteEntryRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<List<LedgerEntry>> getByMonth(int year, int month) async {
    final rows = await _db.query(
      'entries',
      where: 'occurred_on >= ? AND occurred_on < ?',
      whereArgs: [monthStartKey(year, month), nextMonthStartKey(year, month)],
      orderBy: 'occurred_on DESC, created_at DESC',
    );
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<List<LedgerEntry>> getAll() async {
    final rows = await _db.query(
      'entries',
      orderBy: 'occurred_on ASC, created_at ASC',
    );
    return rows.map(_entryFromRow).toList();
  }

  @override
  Future<LedgerEntry?> getById(String id) async {
    final rows = await _db.query('entries', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _entryFromRow(rows.first);
  }

  @override
  Future<int> countByCategory(String categoryId) async {
    return Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM entries WHERE category_id = ?',
            [categoryId],
          ),
        ) ??
        0;
  }

  @override
  Future<void> upsert(LedgerEntry entry) async {
    if (entry.amountCents <= 0) {
      throw const InvalidRecordException('金额必须大于 0');
    }
    final categories = await _db.query(
      'categories',
      columns: ['type'],
      where: 'id = ?',
      whereArgs: [entry.categoryId],
    );
    if (categories.isEmpty) {
      throw const InvalidRecordException('分类不存在');
    }
    if (categories.first['type'] != entry.type.name) {
      throw const InvalidRecordException('分类类型与收支类型不一致');
    }
    final note = entry.note?.trim();
    await _db.insert('entries', {
      'id': entry.id,
      'amount_cents': entry.amountCents,
      'type': entry.type.name,
      'category_id': entry.categoryId,
      'occurred_on': dateKey(entry.occurredOn),
      'note': (note == null || note.isEmpty) ? null : note,
      'created_at': entry.createdAt.millisecondsSinceEpoch,
      'updated_at': entry.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteBudgetRepository implements BudgetRepository {
  SqliteBudgetRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<List<Budget>> getForMonth(int year, int month) async {
    final rows = await _db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return rows.map(_budgetFromRow).toList();
  }

  @override
  Future<void> upsert(Budget budget) async {
    if (budget.amountCents <= 0) {
      throw const InvalidRecordException('预算金额必须大于 0');
    }
    if (budget.month < 1 || budget.month > 12) {
      throw const InvalidRecordException('月份无效');
    }
    await _db.rawInsert(
      '''
      INSERT INTO budgets (id, year, month, category_key, amount_cents, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(year, month, category_key) DO UPDATE SET
        amount_cents = excluded.amount_cents,
        updated_at = excluded.updated_at
      ''',
      [
        budget.id,
        budget.year,
        budget.month,
        budgetCategoryKey(budget.categoryId),
        budget.amountCents,
        budget.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<void> deleteFor({
    required int year,
    required int month,
    required String? categoryId,
  }) async {
    await _db.delete(
      'budgets',
      where: 'year = ? AND month = ? AND category_key = ?',
      whereArgs: [year, month, budgetCategoryKey(categoryId)],
    );
  }
}

Category _categoryFromRow(Map<String, Object?> row) {
  return Category(
    id: row['id']! as String,
    name: row['name']! as String,
    type: EntryType.fromDb(row['type']! as String),
    iconKey: row['icon_key']! as String,
    colorValue: row['color_value']! as int,
    isBuiltin: (row['is_builtin']! as int) == 1,
    sortOrder: row['sort_order']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
  );
}

LedgerEntry _entryFromRow(Map<String, Object?> row) {
  return LedgerEntry(
    id: row['id']! as String,
    amountCents: row['amount_cents']! as int,
    type: EntryType.fromDb(row['type']! as String),
    categoryId: row['category_id']! as String,
    occurredOn: dateFromKey(row['occurred_on']! as int),
    note: row['note'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
  );
}

Budget _budgetFromRow(Map<String, Object?> row) {
  final key = row['category_key']! as String;
  return Budget(
    id: row['id']! as String,
    year: row['year']! as int,
    month: row['month']! as int,
    categoryId: key.isEmpty ? null : key,
    amountCents: row['amount_cents']! as int,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
  );
}
