abstract class ApiAuthDelegate {
  String? get accessToken;

  bool shouldSkipAuth(Uri uri);

  Future<String?> refreshAccessToken();

  Future<void> logout();
}
