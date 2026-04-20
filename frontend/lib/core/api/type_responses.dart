typedef JsonMap = Map<String, dynamic>;
typedef JsonFactory<T> = T Function(JsonMap json);

class TypeResponses {
  TypeResponses._();

  static final Map<String, JsonFactory<Object?>> _factories = {};

  static void register<T>(String key, JsonFactory<T> factory) {
    _factories[key] = factory;
  }

  static void registerAll(Map<String, JsonFactory<Object?>> factories) {
    _factories.addAll(factories);
  }

  static void clear() {
    _factories.clear();
  }

  static Object? fromKey(String key, JsonMap json) {
    final factory = _factories[key];
    if (factory == null) {
      return json;
    }

    return factory(json);
  }

  static bool hasFactory(String key) {
    return _factories.containsKey(key);
  }
}
