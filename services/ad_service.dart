// lib/services/ad_service.dart
import 'dart:developer' as developer;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

class AdService {
  static InterstitialAd? _interstitial;
  static bool _isInterstitialReady = false;

  /// Call this on app start to preload the interstitial
  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isInterstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              loadInterstitial(); // Reload for next time
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          developer.log('Interstitial failed to load',
              name: 'AdService', error: error);
        },
      ),
    );
  }

  /// Show interstitial if ready (e.g., after food scan)
  static void showInterstitial() {
    if (_isInterstitialReady && _interstitial != null) {
      _interstitial!.show();
    }
  }
}
