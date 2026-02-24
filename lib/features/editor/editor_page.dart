import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, this.resumeId});

  final String? resumeId;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  static const _sections = <String>[
    'summary',
    'experience',
    'projects',
    'education',
    'skills',
  ];

  final _titleController = TextEditingController();
  final _uuid = const Uuid();

  final Map<String, List<dynamic>> _sectionDeltas = {
    for (final section in _sections) section: _emptyDelta,
  };

  String _activeSection = _sections.first;
  late QuillController _controller;
  String? _resumeId;
  bool _loading = true;
  bool _saving = false;
  int _currentAtsScore = 0;

  bool get _isNewResume => widget.resumeId == null;

  static const List<dynamic> _emptyDelta = [
    {'insert': '\n'},
  ];

  @override
  void initState() {
    super.initState();
    _resumeId = widget.resumeId ?? _uuid.v4();
    _controller = _buildController(_sectionDeltas[_activeSection]!);
    _loadResume();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  QuillController _buildController(List<dynamic> deltaJson) {
    final document = Document.fromJson(deltaJson);
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _loadResume() async {
    if (widget.resumeId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final resume = await SupabaseService.instance.fetchResumeById(
        widget.resumeId!,
      );
      if (!mounted || resume == null) {
        setState(() => _loading = false);
        return;
      }

      _titleController.text = resume.title;
      _currentAtsScore = resume.atsScore;

      final content = resume.content;
      final quillSections = content['quill_sections'];
      if (quillSections is Map<String, dynamic>) {
        for (final section in _sections) {
          final value = quillSections[section];
          if (value is List) {
            _sectionDeltas[section] = value.cast<dynamic>();
          }
        }
      } else {
        _migrateLegacyContent(content);
      }

      _controller.dispose();
      _controller = _buildController(_sectionDeltas[_activeSection]!);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _migrateLegacyContent(Map<String, dynamic> content) {
    for (final section in _sections) {
      final value = content[section];
      if (value is String && value.trim().isNotEmpty) {
        _sectionDeltas[section] = [
          {'insert': '${value.trim()}\n'},
        ];
      } else if (value is List && value.isNotEmpty) {
        final text = value.map((e) => '- ${e.toString()}').join('\n');
        _sectionDeltas[section] = [
          {'insert': '$text\n'},
        ];
      }
    }
  }

  void _switchSection(String section) {
    _persistCurrentSection();
    setState(() {
      _activeSection = section;
      _controller.dispose();
      _controller = _buildController(_sectionDeltas[section] ?? _emptyDelta);
    });
  }

  void _persistCurrentSection() {
    _sectionDeltas[_activeSection] = _controller.document.toDelta().toJson();
  }

  Future<void> _saveAsVersion() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || _resumeId == null) {
      return;
    }

    _persistCurrentSection();
    setState(() => _saving = true);

    try {
      final plainSections = {
        for (final section in _sections)
          section: _extractPlainText(_sectionDeltas[section] ?? _emptyDelta),
      };

      final content = <String, dynamic>{
        'quill_sections': _sectionDeltas,
        ...plainSections,
      };

      final resume = Resume(
        id: _resumeId!,
        userId: userId,
        title: _titleController.text.trim().isEmpty
            ? 'Untitled Resume'
            : _titleController.text.trim(),
        lastEdited: DateTime.now(),
        atsScore: _currentAtsScore,
        content: content,
      );

      await SupabaseService.instance.upsertResume(
        resume: resume,
        createVersionSnapshot: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resume version saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save version: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _extractPlainText(List<dynamic> deltaJson) {
    final document = Document.fromJson(deltaJson);
    return document.toPlainText().trim();
  }

  Future<void> _showVersionManager() async {
    final resumeId = _resumeId;
    if (resumeId == null) {
      return;
    }

    final versions = await SupabaseService.instance.fetchResumeVersions(
      resumeId,
    );
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final items = List<ResumeVersionEntry>.from(versions);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Saved Versions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No versions yet.'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final version = items[index];
                            final formattedDate = DateFormat.yMMMd()
                                .add_jm()
                                .format(version.lastEdited.toLocal());
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: Text('Version ${version.version}'),
                              subtitle: Text('Saved on $formattedDate'),
                              trailing: IconButton(
                                tooltip: 'Delete version',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirm =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Delete this version?',
                                          ),
                                          content: Text(
                                            'Version ${version.version} will be permanently removed.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;

                                  if (!confirm) {
                                    return;
                                  }

                                  await SupabaseService.instance
                                      .deleteResumeVersion(version.id);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  setModalState(() {
                                    items.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Version deleted.'),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _discardAndGoBack() async {
    final shouldDiscard =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard resume draft?'),
            content: const Text('Unsaved changes will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDiscard) {
      return;
    }

    try {
      if (_isNewResume && _resumeId != null) {
        await SupabaseService.instance.deleteResumeById(_resumeId!);
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: MorphingLoader(size: 32)));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _saving
              ? null
              : () {
                  if (_isNewResume) {
                    _discardAndGoBack();
                  } else {
                    context.go('/home');
                  }
                },
        ),
        title: const Text('Resume Editor'),
        actions: [
          if (_isNewResume)
            TextButton(
              onPressed: _saving ? null : _discardAndGoBack,
              child: const Text('Discard'),
            ),
          IconButton(
            tooltip: 'Manage versions',
            onPressed: _saving ? null : _showVersionManager,
            icon: const Icon(Icons.history_rounded),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _saveAsVersion,
            icon: _saving
                ? const MorphingLoader(size: 14, strokeWidth: 2)
                : const Icon(Icons.save_outlined),
            label: const Text('Save Version'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Resume title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: _sections
                  .map(
                    (section) => ButtonSegment<String>(
                      value: section,
                      label: Text(_label(section)),
                    ),
                  )
                  .toList(),
              selected: {_activeSection},
              onSelectionChanged: (selection) {
                final selectedSection = selection.firstOrNull;
                if (selectedSection != null) {
                  _switchSection(selectedSection);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FadeScaleSwitcher(
              child: Column(
                key: ValueKey(_activeSection),
                children: [
                  QuillSimpleToolbar(
                    controller: _controller,
                    config: const QuillSimpleToolbarConfig(),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: QuillEditor.basic(
                        controller: _controller,
                        config: const QuillEditorConfig(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _persistCurrentSection();
                      context.push('/score?resumeId=${_resumeId ?? ''}');
                    },
                    child: const Text('View ATS Score'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(String section) {
    return section[0].toUpperCase() + section.substring(1);
  }
}

extension on Set<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
