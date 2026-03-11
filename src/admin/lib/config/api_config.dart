class ApiConfig {
  ApiConfig._();

  static const bool isProd = false;

  static const String _devBaseUrl = 'http://localhost:8080';
  static const String _prodBaseUrl = 'https://YOUR-CLOUDRUN-URL.a.run.app';

  static String get baseUrl => isProd ? _prodBaseUrl : _devBaseUrl;
}
