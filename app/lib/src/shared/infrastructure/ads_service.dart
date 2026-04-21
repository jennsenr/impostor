import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import 'ads_consent_service.dart';

class AdsService {
  AdsService(this._consentService);

  final AdsConsentService _consentService;
  bool _isInitialized = false;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  InterstitialAd? _interstitialAd;
  Completer<void>? _pendingInterstitialLoad;

  Future<void> initialize() async {
    if (_isInitialized || !AppConfig.adsEnabled || !_consentService.canRequestAds) {
      return;
    }

    await MobileAds.instance.initialize();
    _isInitialized = true;
    unawaited(preloadInterstitial());
  }

  Future<void> preloadInterstitial() async {
    if (!AppConfig.adsEnabled ||
        !_consentService.canRequestAds ||
        _isLoadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _isLoadingInterstitial = true;
    _pendingInterstitialLoad = Completer<void>();

    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          _pendingInterstitialLoad?.complete();
          _pendingInterstitialLoad = null;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          _pendingInterstitialLoad?.complete();
          _pendingInterstitialLoad = null;
        },
      ),
    );
  }

  Future<bool> showInterstitialIfReady({
    Duration waitForLoad = const Duration(seconds: 2),
  }) async {
    if (!AppConfig.adsEnabled ||
        !_consentService.canRequestAds ||
        _isShowingInterstitial) {
      return false;
    }

    await initialize();

    if (_interstitialAd == null) {
      await preloadInterstitial();
      if (_pendingInterstitialLoad != null) {
        await _pendingInterstitialLoad!.future.timeout(
          waitForLoad,
          onTimeout: () {},
        );
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      return false;
    }

    _interstitialAd = null;
    _isShowingInterstitial = true;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingInterstitial = false;
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        unawaited(preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _isShowingInterstitial = false;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        unawaited(preloadInterstitial());
      },
    );

    ad.show();
    return completer.future;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
