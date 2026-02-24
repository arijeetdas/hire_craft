import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/models/template_config.dart';
import 'package:hire_craft/providers/template_provider.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/services/ai_service.dart';
import 'package:hire_craft/services/supabase_service.dart';

class GeneratePage extends ConsumerStatefulWidget {
  const GeneratePage({super.key, this.resumeId});

  final String? resumeId;

  @override
  ConsumerState<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends ConsumerState<GeneratePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _galaxy;
  bool _loading = true;
  bool _strongRewrite = false;
  String? _error;

  Resume? _resume;
  Uint8List? _generatedImage;
  String? _generatedText;

  @override
  void initState() {
    super.initState();
    _galaxy = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _generate();
  }

  @override
  void dispose() {
    _galaxy.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final startedAt = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
      _generatedImage = null;
      _generatedText = null;
    });

    try {
      final resumeId = widget.resumeId;
      if (resumeId == null || resumeId.isEmpty) {
        throw Exception('Missing resume id for generation.');
      }

      final resume = await SupabaseService.instance.fetchResumeById(resumeId);
      if (resume == null) {
        throw Exception('Resume not found.');
      }

      final template = _resolveTemplate(resume.content);
      final payload = {
        'template': template.toJson(),
        'resume': resume.content,
        'raw_resume_text': _flattenResumeContent(resume.content),
      };

      final userId = ref.read(authProvider).user?.id;
      ProfilePromptContext? profileContext;
      if (userId != null) {
        try {
          profileContext = await SupabaseService.instance
              .fetchProfilePromptContext(userId);
        } catch (_) {
          profileContext = null;
        }
      }

      final variations = await AiService.instance.generateResume(
        structuredResumeData: payload,
        careerLevel: profileContext?.careerLevel,
        targetRole: profileContext?.targetRole,
        industry: profileContext?.industry,
        tone: profileContext?.writingStyle,
        strongRewrite: _strongRewrite,
      );

      String? aiText;
      Map<String, dynamic>? generatedContent;
      if (variations.isNotEmpty) {
        aiText = variations.first;
        generatedContent = _extractGeneratedContent(
          aiText,
          fallbackContent: resume.content,
        );
      }

      if (generatedContent == null) {
        throw Exception(
          'AI returned an invalid format. Please generate again.',
        );
      }

      final aiImage = await AiService.instance.generateResumeImage(
        structuredResumeData: payload,
        careerLevel: profileContext?.careerLevel,
        targetRole: profileContext?.targetRole,
        industry: profileContext?.industry,
        tone: profileContext?.writingStyle,
      );

      Resume updatedResume = resume;
      if (userId != null) {
        final updatedContent = Map<String, dynamic>.from(resume.content);
        if (aiImage != null) {
          final imageUrl = await SupabaseService.instance
              .uploadGeneratedResumeImage(
                userId: userId,
                resumeId: resume.id,
                imageBytes: aiImage,
              );
          updatedContent['generated_image_url'] = imageUrl;
        }
        updatedContent.addAll(generatedContent);
        if (aiText != null && aiText.trim().isNotEmpty) {
          updatedContent['generated_text'] = aiText.trim();
        }

        updatedResume = resume.copyWith(
          userId: userId,
          content: updatedContent,
          lastEdited: DateTime.now(),
        );

        await SupabaseService.instance.upsertResume(resume: updatedResume);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _resume = updatedResume;
        _generatedImage = aiImage;
        _generatedText = _buildGeneratedTextPreview(
          updatedResume.content,
          aiText,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      const minLoader = Duration(milliseconds: 1400);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minLoader) {
        await Future.delayed(minLoader - elapsed);
      }
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic>? _extractGeneratedContent(
    String rawVariation, {
    required Map<String, dynamic> fallbackContent,
  }) {
    final decoded = _tryDecodeJson(rawVariation);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    Map<String, dynamic>? candidate;
    final nestedResumeData = decoded['resumeData'];
    if (nestedResumeData is Map<String, dynamic>) {
      final nestedResumeFromData = nestedResumeData['resume'];
      if (nestedResumeFromData is Map<String, dynamic>) {
        candidate = nestedResumeFromData;
      }
    }
    final nestedResume = decoded['resume'];
    if (candidate == null && nestedResume is Map<String, dynamic>) {
      candidate = nestedResume;
    } else if (candidate == null &&
        decoded['content'] is Map<String, dynamic>) {
      candidate = decoded['content'] as Map<String, dynamic>;
    } else {
      final hasSectionKeys =
          decoded.containsKey('summary') ||
          decoded.containsKey('experience') ||
          decoded.containsKey('projects') ||
          decoded.containsKey('education') ||
          decoded.containsKey('skills');
      if (candidate == null && hasSectionKeys) {
        candidate = decoded;
      }
    }

    if (candidate == null) {
      return null;
    }

    final merged = Map<String, dynamic>.from(fallbackContent);

    void setString(String key) {
      final value = candidate![key];
      if (value == null) {
        return;
      }
      merged[key] = value.toString().trim();
    }

    void setStringList(String key) {
      final value = candidate![key];
      if (value == null) {
        return;
      }
      if (value is List) {
        merged[key] = value
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return;
      }
      merged[key] = value
          .toString()
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    setString('title');
    setString('name');
    setString('email');
    setString('phone');
    setString('linkedin');
    setString('github');
    setString('website');
    setString('location');
    setString('summary');
    setStringList('experience');
    setStringList('projects');
    setStringList('education');
    setStringList('skills');

    final atsScore = candidate['ats_score'];
    if (atsScore is num) {
      merged['ats_score'] = atsScore.toInt();
    }

    return merged;
  }

  dynamic _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      try {
        return jsonDecode(cleaned);
      } catch (_) {
        return null;
      }
    }
  }

  String _flattenResumeContent(Map<String, dynamic> content) {
    final pieces = <String>[];

    void addValue(dynamic value) {
      if (value == null) {
        return;
      }
      if (value is List) {
        for (final item in value) {
          addValue(item);
        }
        return;
      }
      if (value is Map) {
        for (final item in value.values) {
          addValue(item);
        }
        return;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        pieces.add(text);
      }
    }

    addValue(content);
    return pieces.join('\n');
  }

  String? _buildGeneratedTextPreview(
    Map<String, dynamic> content,
    String? fallback,
  ) {
    final sections = <String>[];
    final summary = content['summary']?.toString().trim();
    if (summary != null && summary.isNotEmpty) {
      sections.add('Summary\n$summary');
    }

    String listText(String key, String title) {
      final raw = content[key];
      if (raw is List) {
        final rows = raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (rows.isEmpty) {
          return '';
        }
        return '$title\n${rows.map((e) => '- $e').join('\n')}';
      }
      return '';
    }

    for (final entry in const [
      ('experience', 'Experience'),
      ('projects', 'Projects'),
      ('education', 'Education'),
      ('skills', 'Skills'),
    ]) {
      final block = listText(entry.$1, entry.$2);
      if (block.isNotEmpty) {
        sections.add(block);
      }
    }

    if (sections.isEmpty) {
      final text = fallback?.trim();
      return text == null || text.isEmpty ? null : text;
    }

    return sections.join('\n\n');
  }

  TemplateConfig _resolveTemplate(Map<String, dynamic> content) {
    final id = content['template_id'] as String?;
    final defaults = ref.read(availableTemplatesProvider);
    if (id != null) {
      final match = defaults.where((item) => item.id == id).toList();
      if (match.isNotEmpty) {
        return match.first;
      }
    }
    return defaults.first;
  }

  Future<void> _exportPdf() async {
    final resume = _resume;
    if (resume == null) {
      AppToast.showError(context, 'Resume is not ready yet.');
      return;
    }
    context.push('/export?resumeId=${resume.id}');
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
            context.go('/builder?resumeId=${widget.resumeId ?? ''}');
          },
        ),
        title: const Text('Generating Resume'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? _buildGeneratingState()
            : _error != null
            ? _buildErrorState()
            : _buildPreviewState(),
      ),
    );
  }

  Widget _buildGeneratingState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('generating'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _galaxy,
            builder: (context, child) {
              final turn = _galaxy.value;
              final wave = (1 + math.sin(turn * 6.28318)) / 2;
              final pulse = 0.92 + (wave * 0.12);
              final twinkleA = 0.5 + (wave * 0.5);
              final twinkleB = 0.5 + ((1 - wave) * 0.5);
              return SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.34),
                              scheme.tertiary.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.98 + (wave * 0.08),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 35,
                        color: scheme.primary.withValues(alpha: 0.95),
                      ),
                    ),
                    Transform.rotate(
                      angle: -(turn * 6.28318 * 1.2),
                      child: Transform.translate(
                        offset: const Offset(36, -16),
                        child: Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: scheme.tertiary.withValues(alpha: twinkleA),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: turn * 6.28318 * 0.82,
                      child: Transform.translate(
                        offset: const Offset(-30, 22),
                        child: Icon(
                          Icons.star,
                          size: 10,
                          color: scheme.primary.withValues(alpha: twinkleB),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -(turn * 6.28318 * 0.55),
                      child: Transform.translate(
                        offset: const Offset(-12, -36),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 9,
                          color: scheme.onSurface.withValues(
                            alpha: 0.55 + (wave * 0.35),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Crafting your resume with AI...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Applying selected template features and your content',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Generation failed.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    return ListView(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Live Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_generatedImage != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.memory(_generatedImage!, fit: BoxFit.contain),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(_generatedText ?? 'No preview generated.'),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Export as PDF'),
        ),
        const SizedBox(height: 10),
        Card(
          child: SwitchListTile.adaptive(
            value: _strongRewrite,
            onChanged: (value) {
              setState(() {
                _strongRewrite = value;
              });
            },
            title: const Text('Stronger rewrite mode'),
            subtitle: const Text(
              'More aggressively rewrite rough input into polished sample-style wording.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            _strongRewrite ? 'Regenerate (Stronger Rewrite)' : 'Regenerate',
          ),
        ),
      ],
    );
  }
}
