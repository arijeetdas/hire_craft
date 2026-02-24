import 'package:shared_preferences/shared_preferences.dart';

class LocalSessionService {
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> hasSession() async {
    await initialize();
    return _prefs?.getBool(_sessionKey) ?? false;
  }

  Future<bool> isOnboardingCompleted() async {
    await initialize();
    return _prefs?.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setSession(bool value) async {
    await initialize();
    await _prefs?.setBool(_sessionKey, value);
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await initialize();
    await _prefs?.setBool(_onboardingCompletedKey, value);
  }

  static const _sessionKey = 'local_session_active';
  static const _onboardingCompletedKey = 'local_onboarding_completed';
}
