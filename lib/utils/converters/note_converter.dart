import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/note.dart';
import '../../widgets/note_view/export_format_sheet.dart';

class NoteConverter {
  
  static Future<List<int>> convert(Note note, ExportFormat format) async {
    switch (format) {
      case ExportFormat.pdf:
        return await _generatePdf(note);
      case ExportFormat.docx:
        return _generateDocx(note);
      case ExportFormat.epub:
        return _generateEpub(note);
      case ExportFormat.odt:
        return _generateOdt(note);
      case ExportFormat.txt:
        return utf8.encode(_toTxt(note));
      case ExportFormat.md:
        return utf8.encode(_toMarkdown(note));
      case ExportFormat.multiMd:
        return utf8.encode(_toMultiMarkdown(note));
      case ExportFormat.html:
        return utf8.encode(_toHtml(note));
      case ExportFormat.json:
        return utf8.encode(_toJson(note));
      case ExportFormat.xml:
        return utf8.encode(_toXml(note));
      case ExportFormat.yaml:
        return utf8.encode(_toYaml(note));
      case ExportFormat.toml:
        return utf8.encode(_toToml(note));
      case ExportFormat.asciidoc:
        return utf8.encode(_toAsciidoc(note));
      case ExportFormat.rst:
        return utf8.encode(_toRst(note));
      case ExportFormat.orgMode:
        return utf8.encode(_toOrgMode(note));
      case ExportFormat.bbCode:
        return utf8.encode(_toBBCode(note));
      case ExportFormat.rtf:
        return latin1.encode(_toRtf(note));
    }
  }

  static String getExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt: return 'txt';
      case ExportFormat.pdf: return 'pdf';
      case ExportFormat.docx: return 'docx';
      case ExportFormat.md: return 'md';
      case ExportFormat.html: return 'html';
      case ExportFormat.epub: return 'epub';
      case ExportFormat.odt: return 'odt';
      case ExportFormat.json: return 'json';
      case ExportFormat.xml: return 'xml';
      case ExportFormat.rtf: return 'rtf';
      case ExportFormat.yaml: return 'yaml';
      case ExportFormat.asciidoc: return 'adoc';
      case ExportFormat.rst: return 'rst';
      case ExportFormat.orgMode: return 'org';
      case ExportFormat.bbCode: return 'txt';
      case ExportFormat.multiMd: return 'md';
      case ExportFormat.toml: return 'toml';
    }
  }

  static String getMimeType(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf: return 'application/pdf';
      case ExportFormat.docx: return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case ExportFormat.epub: return 'application/epub+zip';
      case ExportFormat.odt: return 'application/vnd.oasis.opendocument.text';
      case ExportFormat.json: return 'application/json';
      case ExportFormat.html: return 'text/html';
      case ExportFormat.xml: return 'application/xml';
      case ExportFormat.rtf: return 'application/rtf';
      case ExportFormat.yaml: return 'text/yaml';
      case ExportFormat.md: 
      case ExportFormat.multiMd: return 'text/markdown';
      default: return 'text/plain';
    }
  }

  // ===========================================================================
  // HELPER: Add file to archive with correct byte size
  // ===========================================================================
  
  static void _addFile(Archive archive, String path, String content, {bool compress = true}) {
    final bytes = utf8.encode(content);
    final file = ArchiveFile(path, bytes.length, bytes);
    file.compress = compress;
    archive.addFile(file);
  }

  // ===========================================================================
  // PDF
  // ===========================================================================

  static Future<List<int>> _generatePdf(Note note) async {
    final pdf = pw.Document();
    
    // Sanitize text for PDF (replace unsupported characters)
    final titleText = _sanitizeForPdf(note.title.isEmpty ? 'Untitled' : note.title);
    final contentText = _sanitizeForPdf(note.content.isEmpty ? ' ' : note.content);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];
          
          widgets.add(
            pw.Text(
              titleText,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 20));
          
          final paragraphs = contentText.split('\n');
          for (final paragraph in paragraphs) {
            if (paragraph.trim().isEmpty) {
              widgets.add(pw.SizedBox(height: 12));
            } else {
              widgets.add(
                pw.Paragraph(
                  text: paragraph,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.5,
                  ),
                ),
              );
            }
          }
          
          widgets.add(pw.SizedBox(height: 20));
          widgets.add(pw.Divider());
          widgets.add(
            pw.Text(
              'Created: ${note.createdAt.toString().split('.')[0]}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
          
          return widgets;
        },
      ),
    );

    return await pdf.save();
  }

  /// Sanitize text for PDF - replace unsupported Unicode characters
  static String _sanitizeForPdf(String text) {
    return text
        // Smart quotes to straight quotes
        .replaceAll('“', '"')   // Left double quote
        .replaceAll('”', '"')   // Right double quote
        .replaceAll('‘', "'")   // Left single quote
        .replaceAll('’', "'")   // Right single quote
        .replaceAll('„', '"')   // Double low quote
        .replaceAll('‚', "'")   // Single low quote
        .replaceAll('«', '"')   // Left guillemet
        .replaceAll('»', '"')   // Right guillemet
        .replaceAll('‹', "'")   // Single left guillemet
        .replaceAll('›', "'")   // Single right guillemet
        // Dashes
        .replaceAll('—', '-')   // Em dash
        .replaceAll('–', '-')   // En dash
        .replaceAll('−', '-')   // Minus sign
        // Spaces
        .replaceAll('\u00A0', ' ')  // Non-breaking space
        .replaceAll('\u2003', ' ')  // Em space
        .replaceAll('\u2002', ' ')  // En space
        .replaceAll('\u2009', ' ')  // Thin space
        // Ellipsis
        .replaceAll('…', '...')
        // Bullets
        .replaceAll('•', '*')
        .replaceAll('◦', 'o')
        .replaceAll('▪', '*')
        .replaceAll('▸', '>')
        // Math symbols
        .replaceAll('×', 'x')
        .replaceAll('÷', '/')
        .replaceAll('≈', '~')
        .replaceAll('≠', '!=')
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=')
        // Arrows
        .replaceAll('→', '->')
        .replaceAll('←', '<-')
        .replaceAll('↔', '<->')
        .replaceAll('⇒', '=>')
        // Other common symbols
        .replaceAll('™', '(TM)')
        .replaceAll('©', '(c)')
        .replaceAll('®', '(R)')
        .replaceAll('°', ' deg')
        .replaceAll('′', "'")   // Prime
        .replaceAll('″', '"')   // Double prime
        // Remove any remaining problematic characters
        .replaceAll(RegExp(r'[\u2000-\u206F]'), ' ')  // General punctuation block
        .replaceAll(RegExp(r'[\u2E00-\u2E7F]'), '')   // Supplemental punctuation
        ;
  }

  // ===========================================================================
  // DOCX
  // ===========================================================================

  static List<int> _generateDocx(Note note) {
    final archive = Archive();
    final safeTitle = _escapeXml(note.title.isEmpty ? 'Untitled' : note.title);
    
    _addFile(archive, '[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''');

    _addFile(archive, '_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''');

    _addFile(archive, 'word/_rels/document.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''');

    _addFile(archive, 'word/styles.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="Heading 1"/>
    <w:rPr><w:b/><w:sz w:val="48"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="24"/></w:rPr>
  </w:style>
</w:styles>''');

    final paragraphs = note.content.split('\n').map((line) {
      return '<w:p><w:r><w:t xml:space="preserve">${_escapeXml(line)}</w:t></w:r></w:p>';
    }).join('\n');

    _addFile(archive, 'word/document.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>$safeTitle</w:t></w:r>
    </w:p>
    $paragraphs
  </w:body>
</w:document>''');

    return ZipEncoder().encode(archive)!;
  }

  // ===========================================================================
  // EPUB
  // ===========================================================================

  static List<int> _generateEpub(Note note) {
    final archive = Archive();
    final safeTitle = _escapeXml(note.title.isEmpty ? 'Untitled' : note.title);
    final uuid = 'urn:uuid:${note.id}';
    
    // mimetype - MUST be first and uncompressed
    final mimeBytes = utf8.encode('application/epub+zip');
    final mimeFile = ArchiveFile('mimetype', mimeBytes.length, mimeBytes);
    mimeFile.compress = false;
    archive.addFile(mimeFile);

    _addFile(archive, 'META-INF/container.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''');

    _addFile(archive, 'OEBPS/content.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>$safeTitle</dc:title>
    <dc:language>en</dc:language>
    <dc:identifier id="BookID" opf:scheme="UUID">$uuid</dc:identifier>
    <dc:creator>Note Export</dc:creator>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="content" href="chapter.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="content"/>
  </spine>
</package>''');

    _addFile(archive, 'OEBPS/toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="$uuid"/>
    <meta name="dtb:depth" content="1"/>
  </head>
  <docTitle><text>$safeTitle</text></docTitle>
  <navMap>
    <navPoint id="chapter" playOrder="1">
      <navLabel><text>$safeTitle</text></navLabel>
      <content src="chapter.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''');

    final contentHtml = note.content.split('\n').map((line) {
      if (line.trim().isEmpty) return '<p>&#160;</p>';
      return '<p>${_escapeXml(line)}</p>';
    }).join('\n');

    _addFile(archive, 'OEBPS/chapter.xhtml', '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>$safeTitle</title>
  <style type="text/css">
    body { font-family: serif; margin: 2em; line-height: 1.6; }
    h1 { font-size: 1.5em; margin-bottom: 1em; }
    p { margin: 0.5em 0; }
  </style>
</head>
<body>
  <h1>$safeTitle</h1>
  $contentHtml
</body>
</html>''');

    return ZipEncoder().encode(archive)!;
  }

  // ===========================================================================
  // ODT
  // ===========================================================================

  static List<int> _generateOdt(Note note) {
    final archive = Archive();
    final safeTitle = _escapeXml(note.title.isEmpty ? 'Untitled' : note.title);
    
    // mimetype - MUST be first and uncompressed
    final mimeBytes = utf8.encode('application/vnd.oasis.opendocument.text');
    final mimeFile = ArchiveFile('mimetype', mimeBytes.length, mimeBytes);
    mimeFile.compress = false;
    archive.addFile(mimeFile);

    _addFile(archive, 'META-INF/manifest.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
  <manifest:file-entry manifest:full-path="/" manifest:version="1.2" manifest:media-type="application/vnd.oasis.opendocument.text"/>
  <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
  <manifest:file-entry manifest:full-path="styles.xml" manifest:media-type="text/xml"/>
</manifest:manifest>''');

    _addFile(archive, 'styles.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<office:document-styles xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  office:version="1.2">
  <office:styles>
    <style:style style:name="Heading_1" style:family="paragraph">
      <style:text-properties fo:font-size="18pt" fo:font-weight="bold"/>
    </style:style>
    <style:style style:name="Standard" style:family="paragraph">
      <style:text-properties fo:font-size="12pt"/>
    </style:style>
  </office:styles>
</office:document-styles>''');

    final paragraphs = note.content.split('\n').map((line) {
      return '<text:p text:style-name="Standard">${_escapeXml(line)}</text:p>';
    }).join('\n');

    _addFile(archive, 'content.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<office:document-content 
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  office:version="1.2">
  <office:body>
    <office:text>
      <text:h text:style-name="Heading_1" text:outline-level="1">$safeTitle</text:h>
      $paragraphs
    </office:text>
  </office:body>
</office:document-content>''');

    return ZipEncoder().encode(archive)!;
  }

  // ===========================================================================
  // TEXT FORMATS
  // ===========================================================================

  static String _toTxt(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '$title\n${'=' * title.length}\n\n${note.content}';
  }

  static String _toMarkdown(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '# $title\n\n${note.content}';
  }

  static String _toMultiMarkdown(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '''Title: $title
Author: User
Date: ${note.createdAt.toString().split(' ')[0]}

# $title

${note.content}''';
  }

  static String _toHtml(Note note) {
    final title = _escapeXml(note.title.isEmpty ? 'Untitled' : note.title);
    final content = note.content.split('\n').map((line) {
      if (line.trim().isEmpty) return '<p>&nbsp;</p>';
      return '<p>${_escapeXml(line)}</p>';
    }).join('\n    ');

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
      max-width: 800px; 
      margin: 2em auto; 
      padding: 0 1em; 
      line-height: 1.6; 
    }
    h1 { border-bottom: 2px solid #333; padding-bottom: 0.3em; }
    p { margin: 0.5em 0; }
  </style>
</head>
<body>
  <h1>$title</h1>
  $content
</body>
</html>''';
  }

  static String _toJson(Note note) {
  return const JsonEncoder.withIndent('  ').convert({
    'id': note.id,
    'title': note.title,
    'content': note.content,
    'createdAt': note.createdAt.toIso8601String(),
  });
}

  static String _toXml(Note note) {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<note>
  <id>${_escapeXml(note.id)}</id>
  <title>${_escapeXml(note.title)}</title>
  <content>${_escapeXml(note.content)}</content>
  <createdAt>${note.createdAt.toIso8601String()}</createdAt>
</note>''';
}
  static String _toYaml(Note note) {
    final title = note.title.replaceAll('"', '\\"');
    return '''---
title: "$title"
date: ${note.createdAt.toIso8601String()}
---

${note.content}''';
  }

  static String _toToml(Note note) {
    final title = note.title.replaceAll('"', '\\"').replaceAll('\\', '\\\\');
    final content = note.content.replaceAll('\\', '\\\\');
    return '''[note]
title = "$title"
date = "${note.createdAt.toIso8601String()}"

[note.content]
body = """
$content
"""''';
  }

  static String _toAsciidoc(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '''= $title
:author: Note Export
:date: ${note.createdAt.toString().split(' ')[0]}

${note.content}''';
  }

  static String _toRst(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '''${'=' * title.length}
$title
${'=' * title.length}

${note.content}''';
  }

  static String _toOrgMode(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '''#+TITLE: $title
#+DATE: ${note.createdAt.toString().split(' ')[0]}

* $title

${note.content}''';
  }

  static String _toBBCode(Note note) {
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    return '''[size=6][b]$title[/b][/size]

${note.content}''';
  }

  static String _toRtf(Note note) {
    final title = _escapeRtf(note.title.isEmpty ? 'Untitled' : note.title);
    final content = _escapeRtf(note.content);
    
    return '''{\\rtf1\\ansi\\ansicpg1252\\deff0
{\\fonttbl{\\f0\\fswiss\\fcharset0 Arial;}}
{\\colortbl;\\red0\\green0\\blue0;}
\\viewkind4\\uc1\\pard\\cf1\\b\\fs36 $title\\b0\\fs24\\par
\\par
$content\\par
}''';
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _escapeRtf(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      
      if (char == '\\') {
        buffer.write('\\\\');
      } else if (char == '{') {
        buffer.write('\\{');
      } else if (char == '}') {
        buffer.write('\\}');
      } else if (char == '\n') {
        buffer.write('\\par\n');
      } else if (code > 127) {
        buffer.write("\\'${code.toRadixString(16).padLeft(2, '0')}");
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}