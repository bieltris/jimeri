import 'refresh_token_store_stub.dart'
    if (dart.library.html) 'refresh_token_store_web.dart';

abstract class RefreshTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

RefreshTokenStore createRefreshTokenStore() {
  return createRefreshTokenStoreImpl();
}
