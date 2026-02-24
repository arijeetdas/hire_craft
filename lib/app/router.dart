import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/features/auth/login_page.dart';
import 'package:hire_craft/features/auth/signup_page.dart';
import 'package:hire_craft/features/ai_generate/generate_page.dart';
import 'package:hire_craft/features/builder/resume_builder_page.dart';
import 'package:hire_craft/features/dashboard/home_page.dart';
import 'package:hire_craft/features/editor/editor_page.dart';
import 'package:hire_craft/features/onboarding/onboarding_page.dart';
import 'package:hire_craft/features/optimize/optimize_page.dart';
import 'package:hire_craft/features/export/export_page.dart';
import 'package:hire_craft/features/score/score_page.dart';
import 'package:hire_craft/features/splash/splash_page.dart';
import 'package:hire_craft/features/settings/settings_page.dart';
import 'package:hire_craft/features/templates/template_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    errorPageBuilder: (context, state) => _fadeThroughPage(
      key: state.pageKey,
      child: _RouterErrorPage(error: state.error),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/splash'),
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _fadeThroughPage(key: state.pageKey, child: const SplashPage()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _fadeThroughPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/auth/signup',
        pageBuilder: (context, state) =>
            _sharedAxisPage(key: state.pageKey, child: const SignupPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _sharedAxisPage(key: state.pageKey, child: const OnboardingPage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _fadeThroughPage(key: state.pageKey, child: const HomePage()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _sharedAxisPage(key: state.pageKey, child: const SettingsPage()),
      ),
      GoRoute(
        path: '/builder',
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: ResumeBuilderPage(
            resumeId: state.uri.queryParameters['resumeId'],
            templateId: state.uri.queryParameters['templateId'],
          ),
        ),
      ),
      GoRoute(
        path: '/generate',
        pageBuilder: (context, state) => _fadeThroughPage(
          key: state.pageKey,
          child: GeneratePage(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),
      GoRoute(
        path: '/editor',
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: EditorPage(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),
      GoRoute(
        path: '/templates',
        pageBuilder: (context, state) =>
            _fadeThroughPage(key: state.pageKey, child: const TemplatePage()),
      ),
      GoRoute(
        path: '/score',
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: ScorePage(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),
      GoRoute(
        path: '/optimize',
        pageBuilder: (context, state) => _fadeThroughPage(
          key: state.pageKey,
          child: OptimizePage(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),
      GoRoute(
        path: '/export',
        pageBuilder: (context, state) => _fadeThroughPage(
          key: state.pageKey,
          child: ExportPage(resumeId: state.uri.queryParameters['resumeId']),
        ),
      ),
    ],
  );
});

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong while opening this page.',
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go to My Resumes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CustomTransitionPage<void> _fadeThroughPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Colors.transparent,
        child: pageChild,
      );
    },
  );
}

CustomTransitionPage<void> _sharedAxisPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      return SharedAxisTransition(
        transitionType: SharedAxisTransitionType.scaled,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Colors.transparent,
        child: pageChild,
      );
    },
  );
}
