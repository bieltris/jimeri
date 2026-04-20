class ApiRoutes {
  ApiRoutes._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static Uri login() => Uri.parse('$baseUrl/auth/login');

  static Uri refresh() => Uri.parse('$baseUrl/auth/refresh');

  static Uri logout() => Uri.parse('$baseUrl/auth/logout');

  static Uri me() => Uri.parse('$baseUrl/auth/me');

  static Uri clients({String? search}) {
    return Uri.parse('$baseUrl/clients/').replace(
      queryParameters: search == null || search.isEmpty
          ? null
          : {
              'search': search,
            },
    );
  }

  static Uri client(String id) => Uri.parse('$baseUrl/clients/$id');

  static Uri clientWhatsappCharge(String id) =>
      Uri.parse('$baseUrl/clients/$id/whatsapp-charge');

  static Uri clientPayments(String clientId) =>
      Uri.parse('$baseUrl/payments/client/$clientId');

  static Uri payments() => Uri.parse('$baseUrl/payments/');

  static Uri cancelPayment(String id) => Uri.parse('$baseUrl/payments/$id/cancel');

  static Uri products({String? search}) {
    return Uri.parse('$baseUrl/products/').replace(
      queryParameters: search == null || search.isEmpty
          ? null
          : {
              'search': search,
            },
    );
  }

  static Uri product(String id) => Uri.parse('$baseUrl/products/$id');

  static Uri productCategories({String? search}) {
    return Uri.parse('$baseUrl/products/categories').replace(
      queryParameters: search == null || search.isEmpty
          ? null
          : {
              'search': search,
            },
    );
  }

  static Uri productCategory(String id) =>
      Uri.parse('$baseUrl/products/categories/$id');
}
