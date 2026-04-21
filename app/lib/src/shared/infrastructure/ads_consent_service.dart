import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

class AdsConsentService extends ChangeNotifier {
  bool _isConsentFlowCompleted = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;

  bool get isConsentFlowCompleted => _isConsentFlowCompleted;
  bool get canRequestAds => _canRequestAds;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void> gatherConsent() async {
    if (!AppConfig.adsEnabled) {
      _isConsentFlowCompleted = true;
      _canRequestAds = false;
      _privacyOptionsRequired = false;
      notifyListeners();
      return;
    }

    final params = ConsentRequestParameters();
    final completion = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            debugPrint(
              'Consent form error ${formError.errorCode}: ${formError.message}',
            );
          }
          await _refreshConsentState();
          if (!completion.isCompleted) {
            completion.complete();
          }
        });
      },
      (error) async {
        debugPrint(
          'Consent info error ${error.errorCode}: ${error.message}',
        );
        await _refreshConsentState();
        if (!completion.isCompleted) {
          completion.complete();
        }
      },
    );

    await completion.future;
  }

  Future<void> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return;

    await ConsentForm.showPrivacyOptionsForm((formError) async {
      if (formError != null) {
        debugPrint(
          'Privacy options error ${formError.errorCode}: ${formError.message}',
        );
      }
      await _refreshConsentState();
    });
  }

  Future<void> _refreshConsentState() async {
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    _privacyOptionsRequired =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    _isConsentFlowCompleted = true;
    notifyListeners();
  }

  Future<void> debugReset() async {
    await ConsentInformation.instance.reset();
    _isConsentFlowCompleted = false;
    _canRequestAds = false;
    _privacyOptionsRequired = false;
    notifyListeners();
  }
}
