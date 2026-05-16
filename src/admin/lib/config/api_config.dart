class ApiConfig {
  ApiConfig._();

  static const bool isProd = true;

  static const String _devBaseUrl = 'http://localhost:8080';
  static const String _prodBaseUrl =
      'https://bouh-backend-1065699977643.us-central1.run.app';

  static String get baseUrl => isProd ? _prodBaseUrl : _devBaseUrl;
}
