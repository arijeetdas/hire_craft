import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hire_craft/models/resume.dart';
import 'package:hire_craft/models/template_config.dart';

class DocxService {
  const DocxService();

  Future<Uint8List> generateResumeDocx({
    required Resume resume,
    required TemplateConfig template,
  }) async {
    final archive = Archive();

    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        0,
        utf8.encode(_contentTypesXml),
      ),
    );

    archive.addFile(
      ArchiveFile('_rels/.rels', 0, utf8.encode(_rootRelsXml)),
    );

    archive.addFile(
      ArchiveFile('word/document.xml', 0, utf8.encode(_documentXml(resume, template))),
    );

    final bytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  String _documentXml(Resume resume, TemplateConfig template) {
    final content = resume.content;
    final name = _safe(content['name'])
        .trim()
        .ifEmpty(_safe(content['title']).trim())
        .ifEmpty(resume.title.trim());

    final role = _safe(content['title'])
        .trim()
        .ifEmpty(_safe(content['target_role']).trim())
        .ifEmpty(_safe(content['role']).trim());

    final contact = [
      _safe(content['email']).trim(),
      _safe(content['phone']).trim(),
      _safe(content['location']).trim(),
      _safe(content['linkedin']).trim(),
      _safe(content['github']).trim(),
      _safe(content['website']).trim(),
    ].where((e) => e.isNotEmpty).join('  •  ');

    final sections = _normalizedSections(content);
    final body = StringBuffer();

    body.writeln(_paragraph(name, style: 'Name'));
    if (role.isNotEmpty) {
      body.writeln(_paragraph(role, style: 'Role'));
    }
    if (contact.isNotEmpty) {
      body.writeln(_paragraph(contact, style: 'Contact'));
    }

    for (final section in template.sectionOrder) {
      final items = sections[section];
      if (items == null || items.isEmpty) {
        continue;
      }

      body.writeln(_paragraph(_sectionTitle(section), style: 'Section'));
      if (section == 'summary') {
        body.writeln(_paragraph(items.first, style: 'Body'));
      } else {
        for (final item in items) {
          body.writeln(_paragraph(item, style: 'Bullet', bullet: true));
        }
      }
    }

    final accent = _hexRgb(template.accentColor);

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml" xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" mc:Ignorable="w14 w15 wp14">
  <w:body>
    <w:p><w:pPr><w:spacing w:after="120"/><w:pBdr><w:bottom w:val="single" w:sz="10" w:space="1" w:color="$accent"/></w:pBdr></w:pPr></w:p>
    ${body.toString()}
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1080" w:right="1080" w:bottom="1080" w:left="1080" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';
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

  String _paragraph(String text, {required String style, bool bullet = false}) {
    final escaped = _xml(text);

    final styleProps = switch (style) {
      'Name' => '<w:rPr><w:b/><w:sz w:val="44"/></w:rPr>',
      'Role' => '<w:rPr><w:sz w:val="24"/></w:rPr>',
      'Contact' => '<w:rPr><w:sz w:val="20"/></w:rPr>',
      'Section' => '<w:rPr><w:b/><w:sz w:val="24"/></w:rPr>',
      _ => '<w:rPr><w:sz w:val="22"/></w:rPr>',
    };

    final pPr = switch (style) {
      'Name' => '<w:pPr><w:spacing w:after="80"/></w:pPr>',
      'Role' => '<w:pPr><w:spacing w:after="80"/></w:pPr>',
      'Contact' => '<w:pPr><w:spacing w:after="180"/></w:pPr>',
      'Section' => '<w:pPr><w:spacing w:before="120" w:after="70"/></w:pPr>',
      _ => '<w:pPr><w:spacing w:after="40"/></w:pPr>',
    };

    if (bullet) {
      return '<w:p><w:pPr><w:ind w:left="360" w:hanging="180"/><w:spacing w:after="36"/></w:pPr><w:r><w:t>• </w:t></w:r><w:r>$styleProps<w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
    }

    return '<w:p>$pPr<w:r>$styleProps<w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  String _xml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _sectionTitle(String key) {
    return key.toUpperCase();
  }

  String _hexRgb(int argbColor) {
    final rgb = argbColor & 0x00FFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  String _safe(dynamic value) => value?.toString() ?? '';

  static const _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const _rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
