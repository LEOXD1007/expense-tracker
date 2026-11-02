import '../models/ledger_entry.dart';

abstract interface class EntryRepository {
  Future<List<LedgerEntry>> getByMonth(int year, int month);

  Future<List<LedgerEntry>> getAll();

  Future<LedgerEntry?> getById(String id);

  Future<int> countByCategory(String categoryId);

  Future<void> upsert(LedgerEntry entry);

  Future<void> delete(String id);
}
