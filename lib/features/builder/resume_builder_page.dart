import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/models/template_config.dart';
import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/providers/template_provider.dart';
import 'package:hire_craft/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class ResumeBuilderPage extends ConsumerStatefulWidget {
  const ResumeBuilderPage({super.key, this.resumeId, this.templateId});

  final String? resumeId;
  final String? templateId;

  @override
  ConsumerState<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends ConsumerState<ResumeBuilderPage> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();

  final List<TextEditingController> _experienceControllers = [];
  final List<TextEditingController> _projectControllers = [];
  final List<TextEditingController> _educationControllers = [];
  final List<TextEditingController> _skillControllers = [];

  bool _isSaving = false;
  String? _resumeId;
  late TemplateConfig _selectedTemplate;
  bool _templatePickerShown = false;
  int _currentAtsScore = 0;
  bool _createdToastShown = false;
  String? _lastSavedFingerprint;

  @override
  void initState() {
    super.initState();
    _resumeId = widget.resumeId ?? _uuid.v4();
    _selectedTemplate = ref.read(selectedTemplateProvider);
    if (widget.templateId != null) {
      final matched = TemplateConfig.defaults
          .where((template) => template.id == widget.templateId)
          .toList();
      if (matched.isNotEmpty) {
        _selectedTemplate = matched.first;
      }
    }
    _loadInitialData();

    _ensureAtLeastOneField(_experienceControllers);
    _ensureAtLeastOneField(_projectControllers);
    _ensureAtLeastOneField(_educationControllers);
    _ensureAtLeastOneField(_skillControllers);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_isNewResume ||
          _templatePickerShown ||
          widget.templateId != null) {
        return;
      }
      _templatePickerShown = true;
      _showTemplatePicker();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _disposeControllerList(_experienceControllers);
    _disposeControllerList(_projectControllers);
    _disposeControllerList(_educationControllers);
    _disposeControllerList(_skillControllers);
    super.dispose();
  }

  void _disposeControllerList(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _loadInitialData() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || _resumeId == null) {
      return;
    }

    if (widget.resumeId != null) {
      final resume = await SupabaseService.instance.fetchResumeById(
        widget.resumeId!,
      );
      final content = resume?.content;
      if (resume != null && content != null) {
        _nameController.text = content['name'] as String? ?? '';
        _phoneController.text = content['phone'] as String? ?? '';
        _emailController.text = content['email'] as String? ?? '';
        _linkedinController.text = content['linkedin'] as String? ?? '';
        _githubController.text = content['github'] as String? ?? '';
        _titleController.text = resume.title;
        _currentAtsScore = resume.atsScore;
        _summaryController.text = content['summary'] as String? ?? '';
        _setControllerValues(_experienceControllers, content['experience']);
        _setControllerValues(_projectControllers, content['projects']);
        _setControllerValues(_educationControllers, content['education']);
        _setControllerValues(_skillControllers, content['skills']);
        _applyTemplateFromData(content);
        _markSavedSnapshot();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _applyTemplateFromData(Map<String, dynamic> data) {
    final templateId = data['template_id'] as String?;
    if (templateId == null) {
      return;
    }

    final match = TemplateConfig.defaults.where((t) => t.id == templateId);
    if (match.isNotEmpty) {
      _selectedTemplate = match.first;
    }
  }

  Future<void> _showTemplatePicker() async {
    await context.push('/templates?pick=1');
    if (!mounted) {
      return;
    }
    final selected = ref.read(selectedTemplateProvider);
    if (_selectedTemplate.id == selected.id) {
      return;
    }
    setState(() {
      _selectedTemplate = selected;
    });
  }

  void _setControllerValues(
    List<TextEditingController> target,
    dynamic source,
  ) {
    _disposeControllerList(target);
    target.clear();

    final values = (source as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    if (values.isEmpty) {
      _ensureAtLeastOneField(target);
      return;
    }

    for (final value in values) {
      final controller = TextEditingController(text: value);
      target.add(controller);
    }
  }

  void _ensureAtLeastOneField(List<TextEditingController> controllers) {
    if (controllers.isNotEmpty) {
      return;
    }
    final controller = TextEditingController();
    controllers.add(controller);
  }

  Future<bool> _saveResume() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || _resumeId == null) {
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = _buildContentJson();
    final resume = Resume(
      id: _resumeId!,
      userId: userId,
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Resume'
          : _titleController.text.trim(),
      lastEdited: DateTime.now(),
      atsScore: _currentAtsScore,
      content: payload,
    );

    try {
      await SupabaseService.instance.upsertResume(resume: resume);
      _markSavedSnapshot();
      if (mounted && _isNewResume && !_createdToastShown) {
        _createdToastShown = true;
        AppToast.showSuccess(context, 'Resume created successfully.');
      }
      return true;
    } catch (error) {
      if (mounted) {
        AppToast.showError(context, 'Failed to save resume: $error');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildContentJson() {
    return {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'linkedin': _linkedinController.text.trim(),
      'github': _githubController.text.trim(),
      'title': _titleController.text.trim(),
      'summary': _summaryController.text.trim(),
      'experience': _nonEmptyValues(_experienceControllers),
      'projects': _nonEmptyValues(_projectControllers),
      'education': _nonEmptyValues(_educationControllers),
      'skills': _nonEmptyValues(_skillControllers),
      'template_id': _selectedTemplate.id,
      'ats_score': _currentAtsScore,
    };
  }

  List<String> _nonEmptyValues(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool get _isNewResume => widget.resumeId == null;

  bool get _hasAnyInput {
    bool hasControllerText(TextEditingController c) => c.text.trim().isNotEmpty;
    return hasControllerText(_nameController) ||
        hasControllerText(_phoneController) ||
        hasControllerText(_emailController) ||
        hasControllerText(_linkedinController) ||
        hasControllerText(_githubController) ||
        hasControllerText(_titleController) ||
        hasControllerText(_summaryController) ||
        _experienceControllers.any(hasControllerText) ||
        _projectControllers.any(hasControllerText) ||
        _educationControllers.any(hasControllerText) ||
        _skillControllers.any(hasControllerText);
  }

  String _currentFingerprint() {
    return jsonEncode({
      'resumeId': _resumeId,
      'title': _titleController.text.trim(),
      'content': _buildContentJson(),
    });
  }

  void _markSavedSnapshot() {
    _lastSavedFingerprint = _currentFingerprint();
  }

  bool get _hasUnsavedChanges {
    if (!_hasAnyInput) {
      return false;
    }
    if (_lastSavedFingerprint == null) {
      return true;
    }
    return _currentFingerprint() != _lastSavedFingerprint;
  }

  bool get _hasValidEmail {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  bool get _hasValidPhoneWithCountryCode {
    final raw = _phoneController.text.trim();
    if (!raw.startsWith('+')) {
      return false;
    }
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 7;
  }

  bool _hasAtLeastOneValue(List<TextEditingController> controllers) {
    return controllers.any((controller) => controller.text.trim().isNotEmpty);
  }

  bool get _canGenerate {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty;
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasSummary = _summaryController.text.trim().isNotEmpty;
    return hasName &&
        hasPhone &&
        hasEmail &&
        _hasValidPhoneWithCountryCode &&
        _hasValidEmail &&
        hasTitle &&
        hasSummary &&
        _hasAtLeastOneValue(_experienceControllers) &&
        _hasAtLeastOneValue(_projectControllers) &&
        _hasAtLeastOneValue(_educationControllers) &&
        _hasAtLeastOneValue(_skillControllers);
  }

  Future<void> _discardAndGoBack() async {
    if (!_hasUnsavedChanges) {
      if (!mounted) {
        return;
      }
      context.go('/home');
      return;
    }

    final shouldDiscard =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Do you want to discard them and go back?',
            ),
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
      if (_isNewResume && _resumeId != null && _lastSavedFingerprint == null) {
        await SupabaseService.instance.deleteResumeById(_resumeId!);
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  Future<bool> _onWillPop() async {
    if (_isSaving) {
      return false;
    }
    await _discardAndGoBack();
    return false;
  }

  void _addField(List<TextEditingController> controllers) {
    final controller = TextEditingController();
    setState(() {
      controllers.add(controller);
    });
  }

  void _removeField(
    List<TextEditingController> controllers,
    TextEditingController controller,
  ) {
    if (controllers.length == 1) {
      controller.clear();
      return;
    }
    setState(() {
      controllers.remove(controller);
      controller.dispose();
    });
  }

  List<TextEditingController> _controllersForSection(String section) {
    switch (section) {
      case 'summary':
        return <TextEditingController>[_summaryController];
      case 'experience':
        return _experienceControllers;
      case 'projects':
        return _projectControllers;
      case 'education':
        return _educationControllers;
      case 'skills':
        return _skillControllers;
      default:
        return <TextEditingController>[];
    }
  }

  String _sectionLabel(String section) {
    return section[0].toUpperCase() + section.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _isSaving ? null : _discardAndGoBack,
              ),
              title: const Text('Resume Builder'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Color(
                                _selectedTemplate.primaryColor,
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTemplate.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Layout: ${_selectedTemplate.layoutType.replaceAll('_', ' ')}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _isSaving ? null : _showTemplatePicker,
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeScaleSwitcher(
                      child: _isSaving
                          ? const LinearProgressIndicator(
                              key: ValueKey('saving'),
                            )
                          : const SizedBox.shrink(key: ValueKey('idle')),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Phone number (with country code)',
                        hintText: 'e.g. +91 9876543210',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _linkedinController,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _githubController,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'GitHub (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Resume title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _summaryController,
                      onChanged: (_) => setState(() {}),
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Professional summary',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._selectedTemplate.sectionOrder.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final section = entry.value;
                      if (section == 'summary') {
                        return const SizedBox.shrink();
                      }

                      final controllers = _controllersForSection(section);
                      final title = _sectionLabel(section);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FadeSlideIn(
                          duration: Duration(milliseconds: 380 + (index * 60)),
                          child: _SectionEditor(
                            title: title,
                            controllers: controllers,
                            onAdd: () => _addField(controllers),
                            onRemove: (controller) =>
                                _removeField(controllers, controller),
                            onChanged: () => setState(() {}),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving || !_canGenerate
                          ? null
                          : () async {
                              final saved = await _saveResume();
                              if (!saved) {
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }
                              context.push(
                                '/generate?resumeId=${_resumeId ?? ''}',
                              );
                            },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate'),
                    ),
                    if (!_canGenerate)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Fill name, phone (+country code), email, title, summary, and at least one item in each section to generate.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEditor extends StatelessWidget {
  const _SectionEditor({
    required this.title,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final String title;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<TextEditingController> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...controllers.map(
              (controller) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: (_) => onChanged(),
                        decoration: InputDecoration(
                          labelText: '$title item',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(controller),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
