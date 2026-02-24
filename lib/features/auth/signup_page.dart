import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _passwordScore(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  String _passwordLabel(int score) {
    if (score <= 1) return 'Very weak';
    if (score == 2) return 'Weak';
    if (score == 3) return 'Fair';
    if (score == 4) return 'Strong';
    return 'Very strong';
  }

  Color _passwordColor(BuildContext context, int score) {
    final scheme = Theme.of(context).colorScheme;
    if (score <= 1) return scheme.error;
    if (score == 2) return Colors.orange;
    if (score == 3) return Colors.amber.shade700;
    return Colors.green;
  }

  Future<void> _signUp() async {
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
      final success = await authNotifier.signUpWithEmail(
        fullName: _nameController.text.trim(),
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
        AppToast.showSuccess(context, 'Sign up successful.');
        context.go('/splash');
      } else {
        final message = ref.read(authProvider).errorMessage ?? 'Sign up failed';
        AppToast.showError(context, message);
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
    final materialTitleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          height: 1.235,
          letterSpacing: 0.25,
        );
    final password = _passwordController.text;
    final passwordScore = _passwordScore(password);
    final passwordIsStrongEnough = passwordScore >= 3;

    ref.listen<AuthSessionState>(authProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (next.status == AuthSessionStatus.authenticated) {
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
                            'Sign Up',
                            style: materialTitleStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign up with full name, email and password',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                            ),
                            validator: (value) {
                              final fullName = value?.trim() ?? '';
                              if (fullName.isEmpty) {
                                return 'Full name is required';
                              }
                              if (fullName.length < 2) {
                                return 'Enter a valid full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                            onChanged: (_) => setState(() {}),
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
                              final pwd = value ?? '';
                              if (pwd.isEmpty) {
                                return 'Password is required';
                              }
                              if (_passwordScore(pwd) < 3) {
                                return 'Use a stronger password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: passwordScore / 5,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(100),
                            color: _passwordColor(context, passwordScore),
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Password strength: ${_passwordLabel(passwordScore)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _passwordColor(context, passwordScore),
                                ),
                          ),
                          const SizedBox(height: 6),
                          _RuleItem(
                            ok: password.length >= 8,
                            text: 'At least 8 characters',
                          ),
                          _RuleItem(
                            ok: RegExp(r'[A-Z]').hasMatch(password),
                            text: 'At least 1 uppercase letter',
                          ),
                          _RuleItem(
                            ok: RegExp(r'\d').hasMatch(password),
                            text: 'At least 1 number',
                          ),
                          _RuleItem(
                            ok: RegExp(r'[^A-Za-z0-9]').hasMatch(password),
                            text: 'At least 1 special character',
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: authState.isLoading || !passwordIsStrongEnough
                                || _isSubmitting
                                ? null
                                : _signUp,
                            child: authState.isLoading || _isSubmitting
                                ? const MorphingLoader(size: 20, strokeWidth: 2)
                                : const Text('Create Account'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: authState.isLoading || _isSubmitting
                                ? null
                                : () => context.go('/auth'),
                            child: const Text('Already have an account? Sign in'),
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
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
