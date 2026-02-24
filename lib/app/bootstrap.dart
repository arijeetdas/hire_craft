import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hire_craft/services/local_session_service.dart';
import 'package:hire_craft/services/supabase_service.dart';

enum AppState {
  loading,
  unauthenticated,
  onboardingRequired,
  authenticated,
}

class AppBootstrapper {
  AppBootstrapper({
    SupabaseService? supabaseService,
    LocalSessionService? localSessionService,
  })  : _supabaseService = supabaseService ?? SupabaseService.instance,
        _localSessionService = localSessionService ?? LocalSessionService();

  final SupabaseService _supabaseService;
  final LocalSessionService _localSessionService;

  AppState _state = AppState.loading;
  AppState get state => _state;

  Future<AppState> initialize() async {
    _state = AppState.loading;

    try {
      await _localSessionService.initialize();
      await _supabaseService.initializeFromEnvironment();

      final session = _supabaseService.currentSession;
      if (session == null) {
        _state = AppState.unauthenticated;
        return _state;
      }

      try {
        final profile = await _supabaseService.loadUserProfile(session.user.id);
        if (profile == null || !profile.onboardingCompleted) {
          await _localSessionService.setOnboardingCompleted(false);
          _state = AppState.onboardingRequired;
          return _state;
        }
        await _localSessionService.setOnboardingCompleted(true);
      } catch (_) {
        final localOnboardingCompleted =
            await _localSessionService.isOnboardingCompleted();
        _state = localOnboardingCompleted
            ? AppState.authenticated
            : AppState.onboardingRequired;
        return _state;
      }

      _state = AppState.authenticated;
      return _state;
    } catch (_) {
      _state = AppState.unauthenticated;
      return _state;
    }
  }
}

final appBootstrapperProvider = Provider<AppBootstrapper>((ref) {
  return AppBootstrapper();
});

final appStateProvider = FutureProvider.autoDispose<AppState>((ref) async {
  final bootstrapper = ref.watch(appBootstrapperProvider);
  return bootstrapper.initialize();
});