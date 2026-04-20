import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';

import 'api_auth_delegate.dart';

class ExpiredTokenRetryPolicy extends RetryPolicy {
  ExpiredTokenRetryPolicy(this._auth);

  final ApiAuthDelegate _auth;

  @override
  int get maxRetryAttempts => 1;

  @override
  Future<bool> shouldAttemptRetryOnResponse(http.BaseResponse response) async {
    final request = response.request;

    if (response.statusCode != 401 || request == null) {
      return false;
    }

    if (_auth.shouldSkipAuth(request.url)) {
      return false;
    }

    final token = await _auth.refreshAccessToken();
    if (token == null || token.isEmpty) {
      await _auth.logout();

      return false;
    }

    return true;
  }
}
