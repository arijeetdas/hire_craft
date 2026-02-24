import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/models/template_config.dart';
import 'package:hire_craft/providers/template_provider.dart';

class TemplatePage extends ConsumerWidget {
  const TemplatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(availableTemplatesProvider);
    final selected = ref.watch(selectedTemplateProvider);
    final query = GoRouterState.of(context).uri.queryParameters;
    final isPickerMode = query['pick'] == '1';
    final isCreateMode = query['mode'] == 'create';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (isCreateMode) {
              context.go('/home');
              return;
            }
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(isPickerMode ? 'Select Template' : 'Choose Template'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Pick a template to continue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = template.id == selected.id;

                return SizedBox(
                  width: 320,
                  child: FadeSlideIn(
                    duration: Duration(milliseconds: 220 + (index * 50)),
                    child: _TemplatePreviewCard(
                      config: template,
                      selected: isSelected,
                      onSelect: () {
                        ref
                            .read(selectedTemplateProvider.notifier)
                            .selectTemplate(template);

                        final target = '/builder?templateId=${template.id}';

                        if (isCreateMode) {
                          context.push(target);
                          return;
                        }

                        if (isPickerMode) {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.push(target);
                          }
                          return;
                        }

                        context.push(target);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  const _TemplatePreviewCard({
    required this.config,
    required this.selected,
    required this.onSelect,
  });

  final TemplateConfig config;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final primary = Color(config.primaryColor);
    final accent = Color(config.accentColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      config.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: primary),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.08),
                      accent.withValues(alpha: 0.16),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: 110, color: primary),
                    const SizedBox(height: 8),
                    Container(height: 6, width: 180, color: accent),
                    const SizedBox(height: 8),
                    ...List.generate(
                      7,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          height: 5,
                          width: 260 - (i * 20),
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(config.layoutType)),
                  Chip(
                    label: Text('Font: ${config.fontPair.split('/').first}'),
                  ),
                  Chip(
                    label: Text(
                      'Density: ${config.density.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onSelect,
                  icon: Icon(
                    selected ? Icons.check_circle : Icons.done_outline,
                  ),
                  label: Text(selected ? 'Selected' : 'Select Template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
