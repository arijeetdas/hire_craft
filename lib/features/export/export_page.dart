import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/core/animations/app_motion.dart';
import 'package:hire_craft/core/utils/app_toast.dart';
import 'package:hire_craft/core/widgets/morphing_loader.dart';
import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/models/template_config.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:hire_craft/providers/template_provider.dart';
import 'package:hire_craft/services/docx_service.dart';
import 'package:hire_craft/services/pdf_service.dart';
import 'package:hire_craft/services/supabase_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key, this.resumeId});

  final String? resumeId;

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  final _pdfService = const PdfService();
  final _docxService = const DocxService();

  Uint8List? _pdfBytes;
  Resume? _resume;
  bool _loading = true;
  bool _downloadingDocx = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    final startedAt = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
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
        throw Exception('No resume found. Build or edit a resume first.');
      }

      final template = _resolveTemplateFromResume(resume);
      final pdf = await _pdfService.generateResumePdf(
        resume: resume,
        template: template,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _resume = resume;
        _pdfBytes = pdf;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      const minLoader = Duration(milliseconds: 900);
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

  TemplateConfig _resolveTemplateFromResume(Resume resume) {
    final templateId = resume.content['template_id'] as String?;
    if (templateId == null || templateId.isEmpty) {
      return ref.read(selectedTemplateProvider);
    }

    final match = TemplateConfig.defaults.where(
      (item) => item.id == templateId,
    );
    if (match.isNotEmpty) {
      return match.first;
    }

    return ref.read(selectedTemplateProvider);
  }

  Future<void> _downloadDocx() async {
    final resume = _resume;
    if (resume == null) {
      return;
    }

    setState(() {
      _downloadingDocx = true;
    });

    try {
      final template = _resolveTemplateFromResume(resume);
      final docxBytes = await _docxService.generateResumeDocx(
        resume: resume,
        template: template,
      );

      if (docxBytes.isEmpty) {
        throw Exception('Generated DOCX is empty.');
      }

      final fileName = _safeFileName(resume.title);
      final savedPath = await _saveDocxLocally(
        bytes: docxBytes,
        fileName: fileName,
      );

      try {
        await Share.shareXFiles([
          XFile(
            savedPath,
            mimeType:
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
        ], text: 'Resume DOCX');

        if (!mounted) {
          return;
        }

        AppToast.showSuccess(context, 'DOCX ready to save/share.');
      } on MissingPluginException {
        if (!mounted) {
          return;
        }
        AppToast.showSuccess(context, 'DOCX saved: $savedPath');
      } catch (_) {
        if (!mounted) {
          return;
        }
        AppToast.showSuccess(context, 'DOCX saved: $savedPath');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.showError(context, 'Failed to generate DOCX: $error');
    } finally {
      if (mounted) {
        setState(() {
          _downloadingDocx = false;
        });
      }
    }
  }

  String _safeFileName(String rawTitle) {
    final sanitized = rawTitle
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), '_');
    final base = sanitized.isEmpty ? 'resume' : sanitized;
    return '$base.docx';
  }

  Future<String> _saveDocxLocally({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final targetDir = await _resolveResumesDownloadDirectory();

    final filePath = '${targetDir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  Future<String> _savePdfLocally({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final targetDir = await _resolveResumesDownloadDirectory();

    final filePath = '${targetDir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  Future<Directory> _resolveResumesDownloadDirectory() async {
    Directory? downloadsDir = await getDownloadsDirectory();

    if (downloadsDir == null && Platform.isAndroid) {
      final externalStorage = await getExternalStorageDirectory();
      if (externalStorage != null) {
        final normalized = externalStorage.path.replaceAll('\\', '/');
        final androidMarkerIndex = normalized.indexOf('/Android/');
        if (androidMarkerIndex > 0) {
          final rootPath = normalized.substring(0, androidMarkerIndex);
          downloadsDir = Directory('$rootPath/Download');
        }
      }
      downloadsDir ??= Directory('/storage/emulated/0/Download');
    }

    downloadsDir ??= await getApplicationDocumentsDirectory();

    final resumesDir = Directory(
      '${downloadsDir.path}${Platform.pathSeparator}HireCraft${Platform.pathSeparator}resumes',
    );
    if (!await resumesDir.exists()) {
      await resumesDir.create(recursive: true);
    }
    return resumesDir;
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _pdfBytes;

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
        title: const Text('Export PDF'),
      ),
      body: FadeScaleSwitcher(
        child: _loading
            ? const Center(
                key: ValueKey('loading'),
                child: MorphingLoader(size: 36),
              )
            : _error != null
            ? Center(key: const ValueKey('error'), child: Text(_error!))
            : bytes == null
            ? const Center(
                key: ValueKey('empty'),
                child: Text('Unable to generate PDF.'),
              )
            : Column(
                key: const ValueKey('content'),
                children: [
                  Card(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: const Text('Review and export your resume PDF'),
                      subtitle: const Text(
                        'Download or share your professional ATS-friendly resume.',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PdfPreview(
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          allowPrinting: false,
                          allowSharing: false,
                          build: (_) async => bytes,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    try {
                                      final baseName = _safeFileName(
                                        _resume?.title ?? 'resume',
                                      );
                                      final pdfName = baseName.replaceFirst(
                                        RegExp(r'\.docx$'),
                                        '.pdf',
                                      );
                                      final path = await _savePdfLocally(
                                        bytes: bytes,
                                        fileName: pdfName,
                                      );

                                      if (!context.mounted) {
                                        return;
                                      }
                                      AppToast.showSuccess(
                                        context,
                                        'PDF saved: $path',
                                      );
                                    } catch (error) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      AppToast.showError(
                                        context,
                                        'Failed to save PDF: $error',
                                      );
                                      return;
                                    }
                                  },
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Download'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _downloadingDocx
                                      ? null
                                      : _downloadDocx,
                                  icon: _downloadingDocx
                                      ? const MorphingLoader(
                                          size: 16,
                                          strokeWidth: 2,
                                        )
                                      : const Icon(Icons.description_outlined),
                                  label: const Text('Download DOCX'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await Printing.sharePdf(
                                  bytes: bytes,
                                  filename: '${_resume?.title ?? 'resume'}.pdf',
                                );
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }
                                AppToast.showError(
                                  context,
                                  'Failed to open share sheet: $error',
                                );
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }
                              AppToast.showInfo(context, 'Share sheet opened.');
                            },
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share PDF'),
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
