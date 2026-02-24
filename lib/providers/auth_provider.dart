import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hire_craft/services/local_session_service.dart';
import 'package:hire_craft/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthSessionStatus { unknown, authenticated, unauthenticated }

enum AppSignOutScope { currentDevice, allDevices }

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.session,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  final AuthSessionStatus status;
  final Session? session;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    Session? session,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const initial = AuthSessionState(status: AuthSessionStatus.unknown);
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final authProvider = NotifierProvider<AuthNotifier, AuthSessionState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthSessionState> {
  StreamSubscription<AuthState>? _subscription;
  final LocalSessionService _localSessionService = LocalSessionService();

  @override
  AuthSessionState build() {
    final supabaseService = ref.watch(supabaseServiceProvider);

    final session = supabaseService.currentSession;
    final initialState = AuthSessionState(
      status: session == null
          ? AuthSessionStatus.unauthenticated
          : AuthSessionStatus.authenticated,
      session: session,
      user: session?.user,
    );

    _subscription?.cancel();
    _subscription = supabaseService.authStateChanges.listen((authState) {
      final nextSession = authState.session;
      state = state.copyWith(
        status: nextSession == null
            ? AuthSessionStatus.unauthenticated
            : AuthSessionStatus.authenticated,
        session: nextSession,
        user: nextSession?.user,
        isLoading: false,
      );
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return initialState;
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final supabaseService = ref.read(supabaseServiceProvider);
      final response = await supabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'name': fullName},
      );

      final createdUser = response.user;
      if (createdUser != null) {
        try {
          await supabaseService.createProfile(
            userId: createdUser.id,
            email: email,
            fullName: fullName,
          );
        } catch (_) {}
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> signOut({
    AppSignOutScope scope = AppSignOutScope.currentDevice,
  }) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.auth.signOut(
      scope: scope == AppSignOutScope.allDevices
          ? SignOutScope.global
          : SignOutScope.local,
    );
    await _localSessionService.setOnboardingCompleted(false);
  }
}
