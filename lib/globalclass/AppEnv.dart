class AppEnv {
  static const storageKeyCountry = 'selected_country';

  static const bool isLive = false;
  /// map supported countries -> base urls
  static const Map<String, String> baseUrls = {
    'KE': isLive ? 'https://app.chanzo.co.ke/api/v1/' : 'https://antelope-refined-nicely.ngrok-free.app/api/v1/',
    'TZ': 'https://chanzo.co.tz/api/v1/',
  };

  static String defaultCountry = 'KE';
}
