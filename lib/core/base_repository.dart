/// Shared stream/delete contract for classroom and student repositories.
abstract class BaseRepository<T> {
  Stream<List<T>> watchAll(String scopeId);
  Future<void> delete(String id);
}