import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/services/ai_service.dart';
import 'package:hire_craft/services/ats_service.dart';
import 'package:hire_craft/services/supabase_service.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key, this.resumeId});

  final String? resumeId;

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final _keywordsController = TextEditingController(
    text: 'flutter, dart, api, performance, leadership',
  );

  final _atsService = AtsService();
  AtsAnalysisResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resumeId = widget.resumeId;
      if (resumeId == null || resumeId.isEmpty) {
        throw Exception('Missing resume id for ATS analysis.');
      }

      final resume = await SupabaseService.instance.fetchResumeById(resumeId);
      if (resume == null) {
        throw Exception('Resume not found.');
      }

      final text = _contentToText(resume.content);
      final keywords = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      final result = _atsService.scoreResume(
        resumeText: text,
        targetKeywords: keywords,
      );

      AtsAnalysisResult finalResult = result;
      try {
        final promptContext = await SupabaseService.instance
            .fetchProfilePromptContext(resume.userId);
        final aiResult = await AiService.instance.inspectAts(
          structuredResumeData: resume.content,
          resumeText: text,
          targetKeywords: keywords,
          careerLevel: promptContext?.careerLevel,
          targetRole: promptContext?.targetRole,
          industry: promptContext?.industry,
          tone: promptContext?.writingStyle,
        );

        finalResult = AtsAnalysisResult(
          totalScore: aiResult.totalScore,
          keywordScore: aiResult.keywordScore,
          bulletScore: aiResult.bulletScore,
          lengthScore: aiResult.lengthScore,
          readabilityScore: aiResult.readabilityScore,
          missingKeywords: aiResult.missingKeywords,
          suggestions: aiResult.suggestions,
          wordCount: result.wordCount,
          readabilityRaw: result.readabilityRaw,
        );
      } catch (_) {
        finalResult = result;
      }

      await SupabaseService.instance.updateResumeAtsScore(
        resumeId: resume.id,
        atsScore: finalResult.totalScore,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = finalResult;
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

  String _contentToText(Map<String, dynamic> content) {
    final buffer = StringBuffer();

    const keys = ['summary', 'experience', 'projects', 'education', 'skills'];
    for (final key in keys) {
      final value = content[key];
      if (value is String && value.trim().isNotEmpty) {
        buffer.writeln(value.trim());
      } else if (value is List) {
        for (final item in value) {
          buffer.writeln(item.toString());
        }
      }
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

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
        title: const Text('ATS Score'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _keywordsController,
                  decoration: const InputDecoration(
                    labelText: 'Target keywords (comma separated)',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _loading ? null : _analyze,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Recalculate Score'),
          ),
          const SizedBox(height: 18),
          FadeScaleSwitcher(
            child: _loading
                ? const Center(
                    key: ValueKey('loading'),
                    child: MorphingLoader(size: 32),
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
          if (!_loading && result != null) ...[
            FadeSlideIn(child: _ScoreHeader(score: result.totalScore)),
            const SizedBox(height: 12),
            _MetricRow(label: 'Keyword Match', value: result.keywordScore),
            _MetricRow(label: 'Bullet Strength', value: result.bulletScore),
            _MetricRow(label: 'Length Rules', value: result.lengthScore),
            _MetricRow(label: 'Readability', value: result.readabilityScore),
            const SizedBox(height: 16),
            Text(
              'Missing Keywords',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (result.missingKeywords.isEmpty)
              const Text('No missing keywords detected.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.missingKeywords
                    .map((keyword) => Chip(label: Text(keyword)))
                    .toList(),
              ),
            const SizedBox(height: 16),
            Text(
              'Improvement Suggestions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...result.suggestions.map(
              (item) => ListTile(
                dense: true,
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: Text(item),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Overall ATS Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '$score / 100',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: score / 100),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, title: Text(label), trailing: Text('$value'));
  }
}
