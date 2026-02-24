import 'dart:typed_data';

import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/models/template_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  const PdfService();

  Future<Uint8List> generatePdfFromImage(Uint8List imageBytes) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          return pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    return doc.save();
  }

  Future<Uint8List> generateResumePdf({
    required Resume resume,
    required TemplateConfig template,
  }) async {
    final doc = pw.Document();
    final sections = _normalizedSections(resume.content);

    final headingFont = _fontForPair(template.fontPair, heading: true);
    final bodyFont = _fontForPair(template.fontPair, heading: false);
    final primary = _pdfColorFromThemeInt(template.primaryColor);
    final accent = _pdfColorFromThemeInt(template.accentColor);

    final name = (resume.content['name'] as String?)?.trim() ?? '';
    final headline = name.isNotEmpty
      ? name
      : (resume.content['title'] as String?)?.trim().isNotEmpty == true
        ? (resume.content['title'] as String).trim()
        : resume.title.trim();

    final role = name.isNotEmpty
      ? ((resume.content['title'] as String?)?.trim() ??
        (resume.content['target_role'] as String?)?.trim() ??
        (resume.content['role'] as String?)?.trim() ??
        '')
      : ((resume.content['target_role'] as String?)?.trim() ??
        (resume.content['role'] as String?)?.trim() ??
        '');

    final contactLine = _buildContactLine(resume.content);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: pw.EdgeInsets.all(26 * template.density),
          theme: pw.ThemeData.withFont(base: bodyFont, bold: headingFont),
        ),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              headline,
              style: pw.TextStyle(
                font: headingFont,
                fontSize: 24,
                color: primary,
              ),
            ),
            if (role.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                role,
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 11,
                  color: accent,
                ),
              ),
            ],
            if (contactLine.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                contactLine,
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 9.6,
                  color: PdfColors.grey800,
                ),
              ),
            ],
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              height: 1.6,
              color: accent,
            ),
            pw.SizedBox(height: 14),
          ];

          for (final section in template.sectionOrder) {
            final content = sections[section];
            if (content == null || content.isEmpty) {
              continue;
            }

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle)),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      _sectionTitle(section),
                      style: pw.TextStyle(
                        font: headingFont,
                        fontSize: 11.2,
                        color: primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (section == 'summary') {
              widgets.add(
                pw.Text(
                  content.first,
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 10.4,
                  ),
                ),
              );
            } else {
              for (final item in content) {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4.2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 5),
                          child: pw.Container(
                            width: 4,
                            height: 4,
                            decoration: pw.BoxDecoration(
                              color: accent,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            item,
                            style: pw.TextStyle(
                              font: bodyFont,
                              fontSize: 10.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            widgets.add(pw.SizedBox(height: 10));
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  Map<String, List<String>> _normalizedSections(Map<String, dynamic> content) {
    final normalized = <String, List<String>>{};
    const keys = ['summary', 'experience', 'projects', 'education', 'skills'];

    for (final key in keys) {
      final value = content[key];
      if (value is String) {
        final cleaned = value.trim();
        if (cleaned.isNotEmpty) {
          normalized[key] = [cleaned];
        }
      } else if (value is List) {
        final items = value
            .map((e) => e.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          normalized[key] = items;
        }
      }
    }

    return normalized;
  }

  String _buildContactLine(Map<String, dynamic> content) {
    final parts = <String>[];
    for (final key in const ['email', 'phone', 'location', 'linkedin', 'github', 'website']) {
      final value = content[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        parts.add(value);
      }
    }
    return parts.join('  •  ');
  }

  pw.Font _fontForPair(String pair, {required bool heading}) {
    final lower = pair.toLowerCase();
    if (lower.contains('times')) {
      return heading ? pw.Font.timesBold() : pw.Font.times();
    }
    if (lower.contains('courier')) {
      return heading ? pw.Font.courierBold() : pw.Font.courier();
    }
    return heading ? pw.Font.helveticaBold() : pw.Font.helvetica();
  }

  String _sectionTitle(String key) {
    return key.toUpperCase();
  }

  PdfColor _pdfColorFromThemeInt(int argbColor) {
    final rgb = argbColor & 0x00FFFFFF;
    return PdfColor.fromInt(rgb);
  }
}
