import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _logoutToastShown = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final startedAt = DateTime.now();
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      const minLoader = Duration(milliseconds: 950);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minLoader) {
        await Future.delayed(minLoader - elapsed);
      }

      if (!mounted) {
        return;
      }

      if (success) {
        return;
      }

      final message = ref.read(authProvider).errorMessage ?? 'Sign in failed';
      final emailNotConfirmed = _isEmailNotConfirmedError(message);
      final shouldSignUp = _isSignUpRequiredError(message);
      AppToast.showError(
        context,
        emailNotConfirmed
            ? 'Email not confirmed. Please verify your email first.'
            : shouldSignUp
            ? 'No account found. Please sign up first.'
            : message,
      );

      if (shouldSignUp && !emailNotConfirmed) {
        context.go('/auth/signup');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final query = GoRouterState.of(context).uri.queryParameters;
    final justLoggedOut = query['loggedOut'] == '1';
    if (justLoggedOut && !_logoutToastShown) {
      _logoutToastShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        AppToast.showSuccess(context, 'Logged out successfully.');
      });
    }
    final materialTitleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          height: 1.235,
          letterSpacing: 0.25,
        );

    ref.listen<AuthSessionState>(authProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (previous?.status != AuthSessionStatus.authenticated &&
          next.status == AuthSessionStatus.authenticated) {
        AppToast.showSuccess(context, 'Log in successful.');
        context.go('/splash');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeSlideIn(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Login',
                            style: materialTitleStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email is required';
                              }
                              if (!email.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password is required';
                              }
                              if (password.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: authState.isLoading || _isSubmitting
                              ? null
                              : _signIn,
                            child: authState.isLoading || _isSubmitting
                                ? const MorphingLoader(size: 20, strokeWidth: 2)
                                : const Text('Sign In'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: authState.isLoading || _isSubmitting
                                ? null
                                : () => context.go('/auth/signup'),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSignUpRequiredError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('invalid login credentials') ||
        normalized.contains('user not found');
  }

  bool _isEmailNotConfirmedError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('email not confirmed');
  }
}
