import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/services/supabase_service.dart';
import 'package:intl/intl.dart';

final resumesProvider = StreamProvider<List<Resume>>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) {
    return Stream.value(<Resume>[]);
  }
  return SupabaseService.instance.watchUserResumes(userId);
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _autoReloadTimer;
  bool _fabMenuOpen = false;

  void _toggleFabMenu() {
    setState(() {
      _fabMenuOpen = !_fabMenuOpen;
    });
  }

  void _closeFabMenu() {
    if (_fabMenuOpen) {
      setState(() {
        _fabMenuOpen = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _autoReloadTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        ref.invalidate(resumesProvider);
      }
    });
  }

  @override
  void dispose() {
    _autoReloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resumesAsync = ref.watch(resumesProvider);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: _fabMenuOpen
                ? Column(
                    key: const ValueKey('fabMenuOpen'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'create_action_fab',
                        onPressed: () {
                          _closeFabMenu();
                          context.push('/templates?mode=create');
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create'),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.extended(
                        heroTag: 'settings_action_fab',
                        onPressed: () async {
                          _closeFabMenu();
                          await context.push('/settings');
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Settings'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('fabMenuClosed')),
          ),
          FloatingActionButton(
            heroTag: 'main_menu_fab',
            onPressed: _toggleFabMenu,
            child: AnimatedRotation(
              turns: _fabMenuOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeScaleSwitcher(
            child: resumesAsync.when(
              data: (resumes) {
                return RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: () async {
                    ref.invalidate(resumesProvider);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar.large(
                        pinned: true,
                        title: const Text('My Resumes'),
                      ),
                      if (resumes.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('No resumes yet. Tap Create to start.'),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                          sliver: SliverToBoxAdapter(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: resumes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final resume = resumes[index];
                                  return FadeSlideIn(
                                    duration: Duration(
                                      milliseconds: 220 + (index * 35),
                                    ),
                                    child: _ResumeCard(resume: resume),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              error: (error, _) => Center(
                key: const ValueKey('error'),
                child: Text('Failed to load resumes: $error'),
              ),
              loading: () => const Center(
                key: ValueKey('loading'),
                child: MorphingLoader(size: 32),
              ),
            ),
          ),
          if (_fabMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeFabMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.scrim.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResumeCard extends ConsumerWidget {
  const _ResumeCard({required this.resume});

  final Resume resume;

  Future<void> _deleteResume(BuildContext context, WidgetRef ref) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete resume?'),
            content: Text('"${resume.title}" will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    try {
      await SupabaseService.instance.deleteResumeById(resume.id);
      if (!context.mounted) {
        return;
      }
      ref.invalidate(resumesProvider);
      AppToast.showSuccess(context, 'Resume deleted successfully.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppToast.showError(context, 'Failed to delete resume: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat.yMMMd().add_jm().format(resume.lastEdited);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(resume.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last edited: $formattedDate'),
              const SizedBox(height: 4),
              Text('ATS score: ${resume.atsScore}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Delete'),
                    onPressed: () => _deleteResume(context, ref),
                  ),
                  ActionChip(
                    label: const Text('Score'),
                    onPressed: () =>
                        context.push('/score?resumeId=${resume.id}'),
                  ),
                  ActionChip(
                    label: const Text('Export'),
                    onPressed: () =>
                        context.push('/export?resumeId=${resume.id}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/builder?resumeId=${resume.id}'),
      ),
    );
  }
}
