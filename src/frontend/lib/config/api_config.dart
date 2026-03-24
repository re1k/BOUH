class ApiConfig {
  static const bool isProd = false;

  static const String localBaseUrl = "http://10.0.2.2:8080";
  static const String prodBaseUrl = "https://YOUR-CLOUDRUN-URL.a.run.app";

  static String get baseUrl => isProd ? prodBaseUrl : localBaseUrl;

  static const String stripePublishableKey =
      "pk_test_51T1RUF3J4YBiQKXP81FdmRZQlfm7THtaL0mFwVuubXzecRn8jYUt2pRITKJ5TsHGN6Fbm1o6q3zb6oaDLYe2z96Q00ecPVk7ZK";
}
