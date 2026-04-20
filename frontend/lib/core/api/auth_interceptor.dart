import 'package:http/http.dart';
import 'package:http_interceptor/http_interceptor.dart';

import 'api_auth_delegate.dart';

class AuthInterceptor implements InterceptorContract {
  const AuthInterceptor(this._auth);

  final ApiAuthDelegate _auth;

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    if (_auth.shouldSkipAuth(request.url)) {
      return request;
    }

    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      return request;
    }

    request.headers['Authorization'] = 'Bearer $token';

    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }
}
