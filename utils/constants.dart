// lib/utils/constants.dart

class AppConstants {
  // ================================================================
  // 🔑 REPLACE THESE WITH YOUR ACTUAL API KEYS
  // ================================================================

  /// Google Gemini AI API Key
  /// Get free key at: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'api';
  //                                   ↑ PASTE YOUR KEY HERE

  /// Google AdMob IDs
  /// Get from: https://admob.google.com → Apps → Ad Units
  static const String admobBannerAdUnitId =
      'ca-app-pub-9786026190329018/6724327650';
  //  ↑ REPLACE WITH YOUR BANNER AD UNIT ID

  static const String admobInterstitialAdUnitId =
      'ca-app-pub-9786026190329018/6811957561';
  //  ↑ REPLACE WITH YOUR INTERSTITIAL AD UNIT ID

  // ================================================================
  // App Settings
  // ================================================================
  static const String appName = 'FitLens';
  static const String geminiModel =
      'gemini-3.1-flash-lite-preview'; // Free & fast

  // Gemini API endpoint
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/';
}
