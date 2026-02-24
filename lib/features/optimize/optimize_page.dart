import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/services/ai_service.dart';
import 'package:hire_craft/services/supabase_service.dart';

class OptimizePage extends ConsumerStatefulWidget {
  const OptimizePage({super.key, this.resumeId});

  final String? resumeId;

  @override
  ConsumerState<OptimizePage> createState() => _OptimizePageState();
}

class _OptimizePageState extends ConsumerState<OptimizePage> {
  final _jobDescriptionController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<String> _suggestions = const [];

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _optimize() async {
    final jobDescription = _jobDescriptionController.text.trim();
    if (jobDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a job description.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _suggestions = const [];
    });

    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) {
        throw Exception('User is not authenticated.');
      }

      final resume = widget.resumeId == null
          ? await SupabaseService.instance.fetchLatestUserResume(userId)
          : await SupabaseService.instance.fetchResumeById(widget.resumeId!);

      if (resume == null) {
        throw Exception('No resume found to optimize.');
      }

      final profileContext = await SupabaseService.instance
          .fetchProfilePromptContext(userId);

      final suggestions = await AiService.instance.optimizeResume(
        structuredResumeData: resume.content,
        jobDescription: jobDescription,
        careerLevel: profileContext?.careerLevel,
        targetRole: profileContext?.targetRole,
        industry: profileContext?.industry,
        tone: profileContext?.writingStyle,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = suggestions;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/home');
          },
        ),
        title: const Text('Optimize Resume'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paste Job Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _jobDescriptionController,
                      minLines: 8,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        hintText: 'Paste the target job description here...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _optimize,
            icon: _loading
                ? const MorphingLoader(size: 16, strokeWidth: 2)
                : const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Generate Optimization Suggestions'),
          ),
          const SizedBox(height: 16),
          FadeScaleSwitcher(
            child: _loading
                ? const Center(
                    key: ValueKey('loading'),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: MorphingLoader(size: 32),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('loaded')),
          ),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (_suggestions.isNotEmpty) ...[
            Text('Suggestions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._suggestions.asMap().entries.map(
              (entry) => FadeSlideIn(
                duration: Duration(milliseconds: 260 + (entry.key * 40)),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.tips_and_updates_outlined),
                    title: Text(entry.value),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
