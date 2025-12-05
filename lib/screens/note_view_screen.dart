import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_database.dart';
import '../theme/colors.dart';
import 'note_editor_screen.dart';
import '../widgets/note_view/note_view_bottom_bar.dart';
import '../widgets/note_view/note_search_overlay.dart';
import '../widgets/note_view/view_mode_sheet.dart';
import '../widgets/note_view/text_size_sheet.dart';
import '../widgets/note_view/auto_mode_indicator.dart';
import '../widgets/note_view/page_indicator.dart';
import '../widgets/note_view/note_view_content.dart';
import '../widgets/note_view/more_menu_sheet.dart';
import '../widgets/note_view/export_format_sheet.dart';
import '../widgets/ai_chat_dialog.dart';

class NoteViewScreen extends StatefulWidget {
  final Note note;

  const NoteViewScreen({super.key, required this.note});

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _uiController;
  late Animation<Offset> _barSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late AnimationController _btnController;
  late Animation<double> _btnScaleAnimation;
  late Animation<double> _btnRotateAnimation;
  late AnimationController _invertController;
  late Animation<double> _invertAnimation;

  late ScrollController _scrollController;
  late PageController _pageController;

  bool _showScrollButton = false;
  bool _isInverted = false;
  bool _showSearch = false;
  ViewMode _viewMode = ViewMode.vertical;
  double _autoScrollSpeed = 1.0;
  double _autoFlipInterval = 5.0;
  double _fontSize = 16.0;
  int _currentPage = 0;
  List<String> _pages = [];
  String _searchQuery = '';
  List<int> _searchPositions = [];
  
  Timer? _autoScrollTimer;
  Timer? _autoFlipTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initControllers();
    _splitContentIntoPages();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _uiController.forward();
    });
  }

  void _initAnimations() {
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _barSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _uiController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    ));

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _btnScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.elasticOut),
    );

    _btnRotateAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(
        parent: _btnController,
        curve: const Interval(0.1, 1.0, curve: Curves.elasticOut),
      ),
    );

    _invertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _invertAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _invertController, curve: Curves.easeInOut),
    );
  }

  void _initControllers() {
    _scrollController = ScrollController()..addListener(_onScroll);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _uiController.dispose();
    _btnController.dispose();
    _invertController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _stopAutoScroll();
    _stopAutoFlip();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if (offset > 200 && !_showScrollButton) {
      setState(() => _showScrollButton = true);
      _btnController.forward();
    } else if (offset <= 200 && _showScrollButton) {
      setState(() => _showScrollButton = false);
      _btnController.reverse();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleInvert() {
    setState(() => _isInverted = !_isInverted);
    if (_isInverted) {
      _invertController.forward();
    } else {
      _invertController.reverse();
    }
  }

  String _processForDisplay(String text) {
    String processed = text.replaceAll(RegExp(r'^\[ \]', multiLine: true), '- [ ]');
    processed = processed.replaceAll(RegExp(r'^\[x\]', multiLine: true), '- [x]');
    processed = processed.replaceAll('\n', '  \n');
    return processed;
  }

  void _splitContentIntoPages() {
    final content = widget.note.content;
    final paragraphs = content.split('\n\n');
    _pages = [];
    String currentPage = '';
    const int maxCharsPerPage = 800;
    
    for (final paragraph in paragraphs) {
      if (currentPage.length + paragraph.length > maxCharsPerPage && 
          currentPage.isNotEmpty) {
        _pages.add(currentPage.trim());
        currentPage = paragraph;
      } else {
        currentPage += (currentPage.isEmpty ? '' : '\n\n') + paragraph;
      }
    }
    
    if (currentPage.isNotEmpty) {
      _pages.add(currentPage.trim());
    }
    
    if (_pages.isEmpty) {
      _pages = [content];
    }
  }

  void _changeViewMode(ViewMode mode) {
    _stopAutoScroll();
    _stopAutoFlip();
    setState(() => _viewMode = mode);
    switch (mode) {
      case ViewMode.autoScroll: _startAutoScroll(); break;
      case ViewMode.autoFlip: _startAutoFlip(); break;
      default: break;
    }
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (_scrollController.hasClients) {
          final maxExtent = _scrollController.position.maxScrollExtent;
          final currentOffset = _scrollController.offset;
          if (currentOffset >= maxExtent) {
            _stopAutoScroll();
            return;
          }
          _scrollController.jumpTo(currentOffset + (_autoScrollSpeed * 0.5));
        }
      },
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _startAutoFlip() {
    _stopAutoFlip();
    _autoFlipTimer = Timer.periodic(
      Duration(seconds: _autoFlipInterval.toInt()),
      (timer) {
        if (_currentPage < _pages.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _stopAutoFlip();
        }
      },
    );
  }

  void _stopAutoFlip() {
    _autoFlipTimer?.cancel();
    _autoFlipTimer = null;
  }

  void _onSearchChanged(int currentMatch, int totalMatches, List<int> positions, String query) {
    setState(() {
      _searchQuery = query;
      _searchPositions = positions;
    });
    
    if (positions.isEmpty || _viewMode != ViewMode.vertical) return;
    
    final position = positions[currentMatch > 0 ? currentMatch - 1 : 0];
    final content = widget.note.content;
    final textBeforeMatch = content.substring(0, position);
    final lineCount = '\n'.allMatches(textBeforeMatch).length;
    final estimatedOffset = lineCount * (_fontSize * 1.6);
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleLinkTap(String title) async {
    final notes = await NoteDatabase.searchNotes(title);
    final targetNote = notes.firstWhere(
      (n) => n.title.toLowerCase() == title.toLowerCase(),
      orElse: () => Note()..title = '',
    );

    if (targetNote.title.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteViewScreen(note: targetNote)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Note '$title' not found"),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      }
    }
  }

  void _openViewModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ViewModeSheet(
        currentMode: _viewMode,
        autoScrollSpeed: _autoScrollSpeed,
        autoFlipInterval: _autoFlipInterval,
        onModeChanged: (mode) {
          Navigator.pop(context);
          _changeViewMode(mode);
        },
        onAutoScrollSpeedChanged: (speed) {
          setState(() => _autoScrollSpeed = speed);
          if (_viewMode == ViewMode.autoScroll) _startAutoScroll();
        },
        onAutoFlipIntervalChanged: (interval) {
          setState(() => _autoFlipInterval = interval);
          if (_viewMode == ViewMode.autoFlip) _startAutoFlip();
        },
      ),
    );
  }

  void _openTextSizeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TextSizeSheet(
        currentSize: _fontSize,
        onSizeChanged: (size) => setState(() => _fontSize = size),
      ),
    );
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MoreMenuSheet(
        note: widget.note,
        onExport: _openExportSheet,
        onDuplicate: _duplicateNote,
        onArchive: () {},
        onCopy: _copyNoteToClipboard, // Pass the new callback
      ),
    );
  }

  void _copyNoteToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.note.content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note content copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExportFormatSheet(note: widget.note),
    );
  }

  Future<void> _duplicateNote() async {
    // Duplicate logic to be implemented or handled by a service
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BardishColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Note', style: TextStyle(color: BardishColors.textPrimary, fontFamily: 'Serif', fontSize: 20)),
        content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: BardishColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: BardishColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await NoteDatabase.deleteNote(widget.note.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _contentFadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildTitle(theme),
                  const SizedBox(height: 16),
                  _buildDivider(theme),
                  const SizedBox(height: 20),
                  Expanded(
                    child: NoteViewContent(
                      content: _processForDisplay(widget.note.content),
                      viewMode: _viewMode,
                      fontSize: _fontSize,
                      scrollController: _scrollController,
                      pageController: _pageController,
                      pages: _pages.map((p) => _processForDisplay(p)).toList(),
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      searchQuery: _searchQuery,
                      searchPositions: _searchPositions,
                      onLinkTap: _handleLinkTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_showSearch)
            Positioned(
              left: 0, right: 0, top: 0,
              child: SafeArea(
                child: NoteSearchOverlay(
                  content: widget.note.content,
                  onSearchChanged: _onSearchChanged,
                  onClose: () => setState(() { _showSearch = false; _searchQuery = ''; _searchPositions = []; }),
                ),
              ),
            ),

          if (_viewMode == ViewMode.autoScroll || _viewMode == ViewMode.autoFlip)
            Positioned(
              top: 8, right: 24,
              child: SafeArea(
                child: AutoModeIndicator(
                  viewMode: _viewMode,
                  autoScrollSpeed: _autoScrollSpeed,
                  autoFlipInterval: _autoFlipInterval,
                  currentPage: _currentPage,
                  totalPages: _pages.length,
                  onClose: () => _changeViewMode(ViewMode.vertical),
                ),
              ),
            ),

          if (_viewMode == ViewMode.horizontal || _viewMode == ViewMode.autoFlip)
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: PageIndicator(
                currentPage: _currentPage,
                totalPages: _pages.length,
                onPrevious: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                onNext: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              ),
            ),

          Positioned(
            left: 0, right: 0, bottom: 30,
            child: SlideTransition(
              position: _barSlideAnimation,
              child: NoteViewBottomBar(
                isInverted: _isInverted,
                onInvertToggle: _toggleInvert,
                onSearchTap: () => setState(() => _showSearch = true),
                onViewModeTap: _openViewModeSheet,
                onTextSizeTap: _openTextSizeSheet,
                onMoreTap: _openMoreMenu,
              ),
            ),
          ),

          if (_viewMode == ViewMode.vertical || _viewMode == ViewMode.autoScroll)
            Positioned(
              bottom: 100, right: 32,
              child: ScaleTransition(
                scale: _btnScaleAnimation,
                child: RotationTransition(
                  turns: _btnRotateAnimation,
                  child: FloatingActionButton.small(
                    onPressed: _scrollToTop,
                    shape: const CircleBorder(),
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 6,
                    child: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (_isInverted) {
      content = AnimatedBuilder(
        animation: _invertAnimation,
        builder: (context, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.matrix(_getInvertMatrix(_invertAnimation.value)),
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }

  List<double> _getInvertMatrix(double value) {
    final offset = 255 * value;
    return <double>[
      -1 * value + (1 - value), 0, 0, 0, offset,
      0, -1 * value + (1 - value), 0, 0, offset,
      0, 0, -1 * value + (1 - value), 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'View',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.smart_toy_outlined, color: theme.colorScheme.secondary, size: 20),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => AiChatDialog(
                note: widget.note,
                allowFullReplacement: true,
                onApplyChange: (newText) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Apply Edit?"),
                      content: const Text("This will replace the note's content."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Replace")),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    setState(() {
                      widget.note.content = newText;
                      widget.note.updatedAt = DateTime.now();
                    });
                    await NoteDatabase.saveNote(widget.note);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Note content updated")),
                      );
                    }
                  }
                },
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: _deleteNote,
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
          onPressed: () async {
            final result = await Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => NoteEditorScreen(note: widget.note),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.ease)).animate(animation),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
            if (result == true && mounted) {
              Navigator.pop(context, true);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      widget.note.title.isEmpty ? "Untitled" : widget.note.title,
      style: TextStyle(
        fontSize: 26,
        fontFamily: 'Serif',
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 1,
      width: double.infinity,
      color: theme.dividerColor.withOpacity(0.2),
    );
  }
}
