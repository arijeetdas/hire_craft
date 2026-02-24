import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/app/bootstrap.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppState>>(appStateProvider, (_, next) {
      next.whenData((state) {
        final targetRoute = _routeForState(state);
        final currentRoute = GoRouterState.of(context).matchedLocation;

        if (targetRoute != currentRoute) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(targetRoute);
            }
          });
        }
      });
    });

    ref.watch(appStateProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: FadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1400),
                tween: Tween(begin: 0.92, end: 1),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.16),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon_foreground.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'HireCraft',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Preparing your workspace',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const MorphingLoader(size: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _routeForState(AppState state) {
    switch (state) {
      case AppState.loading:
        return '/splash';
      case AppState.unauthenticated:
        return '/auth';
      case AppState.onboardingRequired:
        return '/onboarding';
      case AppState.authenticated:
        return '/home';
    }
  }
}
