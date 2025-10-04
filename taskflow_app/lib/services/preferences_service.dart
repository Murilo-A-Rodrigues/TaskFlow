import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  // Chaves centralizadas conforme PRD seção 7
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyPrivacyReadV1 = 'privacy_read_v1';
  static const String _keyTermsReadV1 = 'terms_read_v1';
  static const String _keyPoliciesVersionAccepted = 'policies_version_accepted';
  static const String _keyAcceptedAt = 'accepted_at';
  static const String _keyFirstTimeUser = 'first_time_user';
  static const String _keyTipsEnabled = 'tips_enabled';
  
  // Mantém compatibilidade com versões antigas
  static const String _keyPrivacyPolicyAccepted = 'privacy_policy_accepted';
  static const String _keyTermsAccepted = 'terms_accepted';
  static const String _keyPolicyVersion = 'policy_version';
  
  static const String currentPolicyVersion = 'v1';
  
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('PreferencesService não foi inicializado. Chame init() primeiro.');
    }
    return _prefs!;
  }
  
  // First Time User
  bool get isFirstTimeUser => prefs.getBool(_keyFirstTimeUser) ?? true;
  
  Future<void> setFirstTimeUser(bool value) async {
    await prefs.setBool(_keyFirstTimeUser, value);
    notifyListeners();
  }
  
  // Onboarding
  bool get isOnboardingCompleted => prefs.getBool(_keyOnboardingCompleted) ?? false;
  
  Future<void> setOnboardingCompleted(bool value) async {
    await prefs.setBool(_keyOnboardingCompleted, value);
  }
  
  // Privacy Policy
  bool get isPrivacyPolicyAccepted => prefs.getBool(_keyPrivacyPolicyAccepted) ?? false;
  
  Future<void> setPrivacyPolicyAccepted(bool value) async {
    await prefs.setBool(_keyPrivacyPolicyAccepted, value);
  }
  
  // Terms
  bool get isTermsAccepted => prefs.getBool(_keyTermsAccepted) ?? false;
  
  Future<void> setTermsAccepted(bool value) async {
    await prefs.setBool(_keyTermsAccepted, value);
  }
  
  // Policy Version
  String get policyVersion => prefs.getString(_keyPolicyVersion) ?? '';
  
  Future<void> setPolicyVersion(String version) async {
    await prefs.setString(_keyPolicyVersion, version);
  }
  
  // Accepted At
  String get acceptedAt => prefs.getString(_keyAcceptedAt) ?? '';
  
  Future<void> setAcceptedAt(String dateTime) async {
    await prefs.setString(_keyAcceptedAt, dateTime);
  }
  
  // Novas propriedades do PRD
  bool get privacyReadV1 => prefs.getBool(_keyPrivacyReadV1) ?? false;
  
  Future<void> setPrivacyReadV1(bool value) async {
    await prefs.setBool(_keyPrivacyReadV1, value);
    notifyListeners();
  }
  
  bool get termsReadV1 => prefs.getBool(_keyTermsReadV1) ?? false;
  
  Future<void> setTermsReadV1(bool value) async {
    await prefs.setBool(_keyTermsReadV1, value);
    notifyListeners();
  }
  
  String get policiesVersionAccepted => prefs.getString(_keyPoliciesVersionAccepted) ?? '';
  
  Future<void> setPoliciesVersionAccepted(String version) async {
    await prefs.setString(_keyPoliciesVersionAccepted, version);
    notifyListeners();
  }
  
  bool get tipsEnabled => prefs.getBool(_keyTipsEnabled) ?? true;
  
  Future<void> setTipsEnabled(bool value) async {
    await prefs.setBool(_keyTipsEnabled, value);
    notifyListeners();
  }

  // Métodos conforme especificação do PRD
  bool isFullyAccepted() {
    return privacyReadV1 && 
           termsReadV1 && 
           policiesVersionAccepted == currentPolicyVersion;
  }
  
  Future<void> migratePolicyVersion(String from, String to) async {
    if (policiesVersionAccepted == from) {
      await Future.wait([
        setPrivacyReadV1(false),
        setTermsReadV1(false),
        setPoliciesVersionAccepted(''),
      ]);
    }
  }

  // Consent - mantém compatibilidade + nova implementação
  bool get hasValidConsent {
    return isFullyAccepted();
  }
  
  Future<void> grantConsent() async {
    await Future.wait([
      // Mantém compatibilidade
      setPrivacyPolicyAccepted(true),
      setTermsAccepted(true),
      setPolicyVersion(currentPolicyVersion),
      // Nova implementação PRD
      setPrivacyReadV1(true),
      setTermsReadV1(true),
      setPoliciesVersionAccepted(currentPolicyVersion),
      setAcceptedAt(DateTime.now().toIso8601String()),
    ]);
    notifyListeners();
  }
  
  Future<void> revokeConsent() async {
    await Future.wait([
      // Compatibilidade
      setPrivacyPolicyAccepted(false),
      setTermsAccepted(false),
      setPolicyVersion(''),
      // Nova implementação PRD
      setPrivacyReadV1(false),
      setTermsReadV1(false),
      setPoliciesVersionAccepted(''),
      setAcceptedAt(''),
      setOnboardingCompleted(false),
    ]);
    notifyListeners();
  }
  
  // Helper method to determine initial route
  String getInitialRoute() {
    if (!hasValidConsent || policiesVersionAccepted != currentPolicyVersion) {
      return '/splash';
    }
    return '/home';
  }
}