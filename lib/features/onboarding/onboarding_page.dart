import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/services/local_session_service.dart';
import 'package:hire_craft/services/supabase_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 0;
  bool _isSaving = false;

  String? _careerLevel;
  String? _writingStyle;

  final _targetRoleController = TextEditingController();
  final _industryController = TextEditingController();
  final _localSessionService = LocalSessionService();

  static const _stepTitles = [
    'Career Level',
    'Target Role',
    'Industry',
    'Writing Style',
  ];

  static const _stepDescriptions = [
    'Pick your current experience level.',
    'Tell us the role you are aiming for.',
    'Share your primary industry focus.',
    'Choose your preferred resume tone.',
  ];

  @override
  void dispose() {
    _targetRoleController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      context.go('/auth');
      return;
    }

    final targetRole = _targetRoleController.text.trim();
    final industry = _industryController.text.trim();

    if (_careerLevel == null ||
        targetRole.isEmpty ||
        industry.isEmpty ||
        _writingStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all onboarding steps.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await SupabaseService.instance.saveOnboardingProfile(
        userId: userId,
        careerLevel: _careerLevel!,
        targetRole: targetRole,
        industry: industry,
        writingStyle: _writingStyle!,
      );
      await _localSessionService.setOnboardingCompleted(true);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding completed successfully.')),
      );
      context.go('/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save onboarding: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _goBack() {
    if (_isSaving) {
      return;
    }

    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _careerLevel != null;
      case 1:
        return _targetRoleController.text.trim().isNotEmpty;
      case 2:
        return _industryController.text.trim().isNotEmpty;
      case 3:
        return _writingStyle != null;
      default:
        return true;
    }
  }

  String _stepValidationMessage(int step) {
    switch (step) {
      case 0:
        return 'Please select your career level.';
      case 1:
        return 'Please enter your target role.';
      case 2:
        return 'Please enter your industry.';
      case 3:
        return 'Please select your preferred writing style.';
      default:
        return 'Please complete this step.';
    }
  }

  void _goNext() {
    if (_isSaving) {
      return;
    }

    if (!_isStepValid(_currentStep)) {
      AppToast.showError(context, _stepValidationMessage(_currentStep));
      return;
    }

    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }
    _finishOnboarding();
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return DropdownButtonFormField<String>(
          initialValue: _careerLevel,
          items: const [
            DropdownMenuItem(value: 'Student', child: Text('Student')),
            DropdownMenuItem(value: 'Junior', child: Text('Junior')),
            DropdownMenuItem(value: 'Mid-Level', child: Text('Mid-Level')),
            DropdownMenuItem(value: 'Senior', child: Text('Senior')),
            DropdownMenuItem(value: 'Lead', child: Text('Lead')),
          ],
          onChanged: (value) => setState(() => _careerLevel = value),
          decoration: const InputDecoration(
            labelText: 'Select your career level',
          ),
        );
      case 1:
        return TextField(
          controller: _targetRoleController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Target role',
            hintText: 'e.g. Flutter Developer',
          ),
        );
      case 2:
        return TextField(
          controller: _industryController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Industry',
            hintText: 'e.g. Fintech, SaaS, Healthcare',
          ),
        );
      case 3:
        return DropdownButtonFormField<String>(
          initialValue: _writingStyle,
          items: const [
            DropdownMenuItem(value: 'Concise', child: Text('Concise')),
            DropdownMenuItem(
              value: 'Professional',
              child: Text('Professional'),
            ),
            DropdownMenuItem(value: 'Creative', child: Text('Creative')),
            DropdownMenuItem(
              value: 'Achievement-Driven',
              child: Text('Achievement-Driven'),
            ),
          ],
          onChanged: (value) => setState(() => _writingStyle = value),
          decoration: const InputDecoration(
            labelText: 'Preferred writing style',
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _stepTitles.length;
    final isLastStep = _currentStep == _stepTitles.length - 1;
    final canProceed = _isStepValid(_currentStep) && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        leading: _currentStep == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _goBack,
              ),
        title: const Text('Onboarding'),
      ),
      body: FadeSlideIn(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Chip(
                          avatar: CircleAvatar(
                            child: Text('${_currentStep + 1}'),
                          ),
                          label: Text(
                            'Step ${_currentStep + 1} of ${_stepTitles.length}',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stepTitles[_currentStep],
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stepDescriptions[_currentStep],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: SizedBox(
                                key: ValueKey(_currentStep),
                                width: double.infinity,
                                child: _buildStepContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (_currentStep > 0) ...[
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _goBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: canProceed ? _goNext : null,
                            icon: _isSaving
                                ? const MorphingLoader(size: 16, strokeWidth: 2)
                                : Icon(
                                    isLastStep
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                            label: Text(
                              isLastStep ? 'Finish Setup' : 'Continue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
