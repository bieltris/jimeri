import 'dart:html' as html;

import 'refresh_token_store.dart';

const _refreshTokenStorageKey = 'jimeri_refresh_token';

RefreshTokenStore createRefreshTokenStoreImpl() {
  return _WebRefreshTokenStore();
}

class _WebRefreshTokenStore implements RefreshTokenStore {
  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_refreshTokenStorageKey);
  }

  @override
  Future<String?> read() async {
    final value = html.window.localStorage[_refreshTokenStorageKey];
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  @override
  Future<void> write(String token) async {
    html.window.localStorage[_refreshTokenStorageKey] = token;
  }
}
