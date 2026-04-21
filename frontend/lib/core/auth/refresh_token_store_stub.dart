import 'refresh_token_store.dart';

RefreshTokenStore createRefreshTokenStoreImpl() {
  return _NoopRefreshTokenStore();
}

class _NoopRefreshTokenStore implements RefreshTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}
}
