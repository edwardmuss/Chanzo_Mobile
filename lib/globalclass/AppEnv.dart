class AppEnv {
  static const storageKeyCountry = 'selected_country';

  /// map supported countries -> base urls
  static const Map<String, String> baseUrls = {
    'KE': 'https://app.chanzo.co.ke/api/v1/',
    'TZ': 'https://chanzo.co.tz/api/v1/',
  };

  static String defaultCountry = 'KE';
}
