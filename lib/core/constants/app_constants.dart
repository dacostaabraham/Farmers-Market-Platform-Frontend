class AppConstants {
  // ── API ─────────────────────────────────────────────────────────────
  /// Change this to your deployed backend URL in production.
  // Android Emulator  → http://10.0.2.2:8000/api
  // iOS Simulateur    → http://127.0.0.1:8000/api  ✅
  // iPhone physique   → http://<IP_LOCAL_MAC>:8000/api
  static const String baseUrl = 'https://farmers-market-platform-api.onrender.com/api';

  // ── Storage keys ─────────────────────────────────────────────────────
  static const String tokenKey         = 'auth_token';
  static const String userKey          = 'auth_user';
  static const String productsCache    = 'cached_products';
  static const String categoriesCache  = 'cached_categories';

  // ── UI ────────────────────────────────────────────────────────────────
  static const String appName = 'AgroMarket POS';
  static const String currencySymbol = 'FCFA';
}
