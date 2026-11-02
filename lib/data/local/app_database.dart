import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';
import 'default_categories.dart';

class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static const fileName = 'jizhang.db';
  static const version = 1;

  static Future<String> defaultPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, fileName);
  }

  static Future<AppDatabase> open({String? path}) async {
    ensureDatabaseFactory();
    final database = await openDatabase(
      path ?? await defaultPath(),
      version: version,
      singleInstance: path == null,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            icon_key TEXT NOT NULL,
            color_value INTEGER NOT NULL,
            is_builtin INTEGER NOT NULL,
            sort_order INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE entries (
            id TEXT PRIMARY KEY,
            amount_cents INTEGER NOT NULL,
            type TEXT NOT NULL,
            category_id TEXT NOT NULL,
            occurred_on INTEGER NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_entries_occurred ON entries(occurred_on)',
        );
        await db.execute(
          'CREATE INDEX idx_entries_category ON entries(category_id)',
        );
        await db.execute('''
          CREATE TABLE budgets (
            id TEXT PRIMARY KEY,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            category_key TEXT NOT NULL,
            amount_cents INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_budget_natural
          ON budgets(year, month, category_key)
        ''');
        await db.execute('''
          CREATE TABLE budget_alerts (
            alert_key TEXT PRIMARY KEY,
            message TEXT NOT NULL,
            fired_at INTEGER NOT NULL
          )
        ''');
        final now = DateTime.now().millisecondsSinceEpoch;
        final batch = db.batch();
        for (final row in defaultCategoryRows(now)) {
          batch.insert('categories', row);
        }
        await batch.commit(noResult: true);
      },
    );
    return AppDatabase(database);
  }

  Future<void> close() => db.close();
}
