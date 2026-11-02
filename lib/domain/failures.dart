class InvalidRecordException implements Exception {
  const InvalidRecordException(this.message);

  final String message;

  @override
  String toString() => message;
}
