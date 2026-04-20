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
}
