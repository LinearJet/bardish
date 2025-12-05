import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/note.dart';

class MoreMenuSheet extends StatelessWidget {
  final Note note;
  final VoidCallback onExport;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onCopy; // Added callback

  const MoreMenuSheet({
    super.key,
    required this.note,
    required this.onExport,
    required this.onDuplicate,
    required this.onArchive,
    required this.onCopy, // Added parameter
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final sheetColor = isDark 
        ? const Color(0xFF23201E) 
        : theme.colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'More Options',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Copy
          _MenuItem(
            icon: Icons.copy_rounded,
            title: 'Copy Note',
            subtitle: 'Copy content to clipboard',
            onTap: () {
              Navigator.pop(context);
              onCopy();
            },
          ),

          // Share
          _MenuItem(
            icon: Icons.share_rounded,
            title: 'Share Note',
            subtitle: 'Share as text or file',
            onTap: () {
              Navigator.pop(context);
              Share.share(
                '${note.title}\n\n${note.content}',
                subject: note.title,
              );
            },
          ),
          
          // Export
          _MenuItem(
            icon: Icons.file_download_outlined,
            title: 'Export',
            subtitle: 'Multiple Format Options',
            onTap: () {
              Navigator.pop(context);
              onExport();
            },
          ),
          
          // Duplicate
          _MenuItem(
            icon: Icons.content_copy_rounded,
            title: 'Duplicate',
            subtitle: 'Create a copy of this note',
            onTap: () {
              Navigator.pop(context);
              onDuplicate();
            },
          ),
          
          // Note Info
          _MenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Note Info',
            subtitle: 'View details and statistics',
            onTap: () {
              Navigator.pop(context);
              _showNoteInfo(context);
            },
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showNoteInfo(BuildContext context) {
    final theme = Theme.of(context);
    final wordCount = note.content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = note.content.length;
    final lineCount = note.content.split('\n').length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Note Information',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontFamily: 'Serif',
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Words', '$wordCount', theme),
            _InfoRow('Characters', '$charCount', theme),
            _InfoRow('Lines', '$lineCount', theme),
            const SizedBox(height: 12),
            _InfoRow('Created', _formatDate(note.createdAt), theme),
            _InfoRow('Modified', _formatDate(note.updatedAt), theme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _InfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: theme.colorScheme.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
