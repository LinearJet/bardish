import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../models/note.dart';
import '../../utils/export_helper/export_helper.dart';
import '../../utils/converters/note_converter.dart';

enum ExportFormat {
  txt, pdf, docx,
  md, html, epub, odt, json, xml, rtf,
  yaml, asciidoc, rst, orgMode, bbCode, multiMd, toml,
}

class ExportFormatSheet extends StatefulWidget {
  final Note note;

  const ExportFormatSheet({
    super.key,
    required this.note,
  });

  static Future<void> show(BuildContext context, Note note) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportFormatSheet(note: note),
    );
  }

  @override
  State<ExportFormatSheet> createState() => _ExportFormatSheetState();
}

class _ExportFormatSheetState extends State<ExportFormatSheet> {
  bool _showAdvanced = false;
  bool _showSpecial = false;
  bool _isExporting = false;
  ExportFormat? _currentFormat;

  Future<bool> _checkPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 30) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    } else {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }

  Future<void> _export(ExportFormat format) async {
    if (_isExporting) return;

    final hasPerm = await _checkPermissions();
    if (!hasPerm) {
      if (mounted) _showError('Storage permission is required to save to Downloads.');
      return;
    }

    setState(() {
      _isExporting = true;
      _currentFormat = format;
    });

    try {
      final List<int> bytes = await NoteConverter.convert(widget.note, format);
      
      final extension = NoteConverter.getExtension(format);
      final sanitizedTitle = widget.note.title.isEmpty 
          ? 'Untitled' 
          : widget.note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '$sanitizedTitle.$extension';
      final mimeType = NoteConverter.getMimeType(format);
      
      if (kIsWeb) {
        ExportHelper.downloadForWeb(bytes, fileName, mimeType);
        if (mounted) {
          _showSuccess('Download started: $fileName');
        }
      } else {
        if (Platform.isAndroid) {
          final path = await ExportHelper.saveFile(bytes, fileName);
          if (mounted) {
            _showSuccess('Saved to: $path');
          }
        } else if (Platform.isIOS) {
          await ExportHelper.shareFile(bytes, fileName, mimeType);
        } else {
          final path = await ExportHelper.saveFile(bytes, fileName);
          if (mounted) {
            _showSuccess('Saved to: $path');
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _currentFormat = null;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt: return 'Plain Text';
      case ExportFormat.pdf: return 'PDF';
      case ExportFormat.docx: return 'Word Document';
      case ExportFormat.md: return 'Markdown';
      case ExportFormat.html: return 'HTML';
      case ExportFormat.epub: return 'EPUB';
      case ExportFormat.odt: return 'OpenDocument';
      case ExportFormat.json: return 'JSON';
      case ExportFormat.xml: return 'XML';
      case ExportFormat.rtf: return 'Rich Text';
      case ExportFormat.yaml: return 'YAML';
      case ExportFormat.asciidoc: return 'AsciiDoc';
      case ExportFormat.rst: return 'reStructuredText';
      case ExportFormat.orgMode: return 'Org-Mode';
      case ExportFormat.bbCode: return 'BBCode';
      case ExportFormat.multiMd: return 'MultiMarkdown';
      case ExportFormat.toml: return 'TOML';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt: return 'Simple text file';
      case ExportFormat.pdf: return 'Portable document format';
      case ExportFormat.docx: return 'Microsoft Word format';
      case ExportFormat.md: return 'Standard markdown';
      case ExportFormat.html: return 'Web page format';
      case ExportFormat.epub: return 'E-book format';
      case ExportFormat.odt: return 'OpenDocument text';
      case ExportFormat.json: return 'Structured data';
      case ExportFormat.xml: return 'Extensible markup language';
      case ExportFormat.rtf: return 'Rich text format';
      case ExportFormat.yaml: return 'Front matter + content';
      case ExportFormat.asciidoc: return 'Technical documentation';
      case ExportFormat.rst: return 'Python documentation standard';
      case ExportFormat.orgMode: return 'Emacs Org-Mode format';
      case ExportFormat.bbCode: return 'Forum formatting';
      case ExportFormat.multiMd: return 'Extended markdown with metadata';
      case ExportFormat.toml: return 'TOML configuration format';
    }
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt: return Icons.text_snippet_outlined;
      case ExportFormat.pdf: return Icons.picture_as_pdf_outlined;
      case ExportFormat.docx: return Icons.description_outlined;
      case ExportFormat.md:
      case ExportFormat.multiMd: return Icons.code;
      case ExportFormat.html: return Icons.language_rounded;
      case ExportFormat.epub: return Icons.menu_book_outlined;
      case ExportFormat.odt: return Icons.article_outlined;
      case ExportFormat.json: return Icons.data_object_rounded;
      case ExportFormat.xml: return Icons.integration_instructions_rounded;
      case ExportFormat.rtf: return Icons.format_align_left_rounded;
      case ExportFormat.yaml: return Icons.settings_suggest_rounded;
      case ExportFormat.asciidoc: return Icons.terminal_rounded;
      case ExportFormat.rst: return Icons.text_fields_rounded;
      case ExportFormat.orgMode: return Icons.account_tree_rounded;
      case ExportFormat.bbCode: return Icons.forum_outlined;
      case ExportFormat.toml: return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final sheetColor = isDark 
        ? const Color(0xFF1E1E1E) 
        : theme.colorScheme.surface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(theme),
          _buildHeader(theme),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(theme, 'BASIC FORMATS'),
                  const SizedBox(height: 8),
                  _buildFormatButton(ExportFormat.txt),
                  _buildFormatButton(ExportFormat.pdf),
                  _buildFormatButton(ExportFormat.docx),

                  const SizedBox(height: 16),

                  _buildCollapsibleSection(
                    theme: theme,
                    title: 'ADVANCED FORMATS',
                    isExpanded: _showAdvanced,
                    onToggle: () => setState(() => _showAdvanced = !_showAdvanced),
                    formats: [
                      ExportFormat.md,
                      ExportFormat.html,
                      ExportFormat.epub,
                      ExportFormat.odt,
                      ExportFormat.json,
                      ExportFormat.xml,
                      ExportFormat.rtf,
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildCollapsibleSection(
                    theme: theme,
                    title: 'SPECIAL FORMATS',
                    isExpanded: _showSpecial,
                    onToggle: () => setState(() => _showSpecial = !_showSpecial),
                    formats: [
                      ExportFormat.multiMd,
                      ExportFormat.yaml,
                      ExportFormat.asciidoc,
                      ExportFormat.rst,
                      ExportFormat.orgMode,
                      ExportFormat.bbCode,
                      ExportFormat.toml,
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildCancelButton(theme),
        ],
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.file_download_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Note',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.note.title.isEmpty ? 'Untitled' : widget.note.title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required ThemeData theme,
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<ExportFormat> formats,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formats.length} formats',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              const SizedBox(height: 8),
              ...formats.map((format) => _buildFormatButton(format)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatButton(ExportFormat format) {
    final theme = Theme.of(context);
    final isCurrentlyExporting = _isExporting && _currentFormat == format;
    final isDisabled = _isExporting && _currentFormat != format;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => _export(format),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isDisabled ? 0.4 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentlyExporting
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : theme.colorScheme.onSurface.withOpacity(0.1),
                  width: isCurrentlyExporting ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isCurrentlyExporting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            _getFormatIcon(format),
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFormatName(format),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getFormatDescription(format),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '.${NoteConverter.getExtension(format)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.download_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isExporting ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                ),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(_isExporting ? 0.3 : 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
