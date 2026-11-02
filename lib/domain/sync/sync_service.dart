enum SyncStatus { disabled, success, failed }

/// v2 seam. A remote backend can push and pull entries, categories, and
/// budgets. Each record already carries `updatedAt` so a future sync
/// implementation can detect changes without rewriting the UI.
abstract interface class SyncService {
  Future<SyncStatus> sync();
}

final class DisabledSyncService implements SyncService {
  const DisabledSyncService();

  @override
  Future<SyncStatus> sync() async => SyncStatus.disabled;
}
