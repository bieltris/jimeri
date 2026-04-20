class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.body,
  });

  final String message;
  final int? statusCode;
  final Object? body;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';

    return 'ApiException$code: $message';
  }
}
