import '../models/category.dart';

enum CategoryDeleteFailure { builtin, inUse }

class CategoryDeleteException implements Exception {
  const CategoryDeleteException(this.failure);

  final CategoryDeleteFailure failure;
}

abstract interface class CategoryRepository {
  Future<List<Category>> getAll();

  Future<Category?> getById(String id);

  Future<void> add(Category category);

  Future<void> update(Category category);

  /// Built-in categories and categories referenced by entries cannot be deleted.
  Future<void> delete(String id);
}
