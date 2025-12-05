import 'package:flutter/material.dart';
import '../widgets/note_card.dart';
import '../widgets/dashboard_search_bar.dart';
import '../models/note.dart';
import '../models/block.dart';
import '../services/note_database.dart';
import '../services/block_database.dart';
import 'note_view_screen.dart';

class NotesTab extends StatefulWidget {
  final bool isContextMode;
  final Set<Note> selectedNotes; 
  final Function(Note) onToggleSelection; 
  final Function(Note) onEnterContextMode;
  final VoidCallback onExitContextMode;
  final VoidCallback onRefresh;
  final bool isGridView;
  final int sortOrder;

  const NotesTab({
    super.key,
    required this.isContextMode,
    required this.selectedNotes,
    required this.onToggleSelection,
    required this.onEnterContextMode,
    required this.onExitContextMode,
    required this.onRefresh,
    this.isGridView = true,
    this.sortOrder = 0,
  });

  @override
  State<NotesTab> createState() => NotesTabState();
}

class NotesTabState extends State<NotesTab> with SingleTickerProviderStateMixin {
  List<Note> allNotes = [];
  List<Block> allBlocks = [];
  Map<String, List<Note>> groupedNotes = {}; 
  Map<String, bool> collapsedBlocks = {}; 
  bool isLoading = true;
  
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );
    refreshNotes();
  }
  
  @override
  void didUpdateWidget(NotesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortOrder != widget.sortOrder) {
      _sortNotes();
    }
    if (oldWidget.isGridView != widget.isGridView) {
      _morphController.forward(from: 0.0);
    }
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _sortNotes() {
    _sortList(allNotes);
    _groupNotes();
  }

  void _sortList(List<Note> list) {
    list.sort((a, b) {
      // Pinned notes are separated by grouping logic now, so standard sort applies within groups
      switch (widget.sortOrder) {
        case 0: return b.createdAt.compareTo(a.createdAt);
        case 1: return a.createdAt.compareTo(b.createdAt);
        case 2: return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 3: return b.updatedAt.compareTo(a.updatedAt);
        default: return 0;
      }
    });
  }

  Future<void> refreshNotes() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    final notesData = await NoteDatabase.getNotes();
    final blocksData = BlockDatabase.getBlocks();
    
    if (!mounted) return;
    
    setState(() {
      allNotes = notesData;
      allBlocks = blocksData;
      isLoading = false;
    });
    
    _sortNotes();
  }

  void _groupNotes() {
    final Map<String, List<Note>> groups = {};
    
    // Initialize groups
    groups['pinned'] = [];
    for (var block in allBlocks) {
      groups[block.id] = [];
    }
    groups['others'] = [];

    for (var note in allNotes) {
      if (note.isPinned) {
        groups['pinned']!.add(note);
      } else {
        final blockId = note.blockId;
        if (blockId != null && groups.containsKey(blockId)) {
          groups[blockId]!.add(note);
        } else {
          groups['others']!.add(note);
        }
      }
    }
    
    setState(() {
      groupedNotes = groups;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> slivers = [];

    // Search Bar
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: DashboardSearchBar(
            onSearchChanged: (value) async {
              final results = await NoteDatabase.searchNotes(value);
              setState(() => allNotes = results);
              _sortNotes();
            },
          ),
        ),
      ),
    );

    // 1. Pinned Section (Special Group)
    final pinnedNotes = groupedNotes['pinned'] ?? [];
    if (pinnedNotes.isNotEmpty) {
      slivers.add(_buildBlockSection(
        theme, 
        'pinned', 
        'PINNED', 
        pinnedNotes,
        isPinnedSection: true, // Special styling flag
      ));
    }

    // 2. Custom Blocks
    for (var block in allBlocks) {
      final notes = groupedNotes[block.id] ?? [];
      // Only show blocks if they have content or if we want to show empty blocks
      // Assuming we show them if they exist
      slivers.add(_buildBlockSection(theme, block.id, block.name.toUpperCase(), notes));
    }

    // 3. Others / Uncategorized
    final othersNotes = groupedNotes['others'] ?? [];
    // Show 'Others' if there are unpinned/unblocked notes OR if no blocks exist at all
    if (othersNotes.isNotEmpty || (allBlocks.isEmpty && pinnedNotes.isEmpty)) {
      slivers.add(_buildBlockSection(theme, 'others', 'OTHERS', othersNotes));
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));

    return RefreshIndicator(
      onRefresh: refreshNotes,
      color: theme.colorScheme.secondary,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: slivers,
      ),
    );
  }

  Widget _buildBlockSection(ThemeData theme, String id, String title, List<Note> notes, {bool isPinnedSection = false}) {
    final isCollapsed = collapsedBlocks[id] ?? false;
    // Use gold/accent for Pinned title, secondary for others
    final sectionColor = isPinnedSection 
        ? theme.colorScheme.secondary 
        : theme.colorScheme.secondary.withOpacity(0.8);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () {
              setState(() {
                collapsedBlocks[id] = !isCollapsed;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '$title${notes.isNotEmpty ? " (${notes.length})" : ""}', 
                        style: TextStyle(
                          color: sectionColor, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 0.8
                        )
                      ),
                    ],
                  ),
                  Icon(
                    isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, 
                    color: sectionColor, 
                    size: 16
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isCollapsed)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: notes.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Empty block",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.hintColor.withOpacity(0.3),
                          fontSize: 12,
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ),
                  )
                : AnimatedBuilder(
                    animation: _morphAnimation,
                    builder: (context, child) {
                      // Adjust aspect ratio for ~480x350 px visual size on 1080x2400 screen
                      // Ratio 480/350 = ~1.37
                      final double targetExtent = widget.isGridView ? 280 : 600;
                      final double targetAspectRatio = widget.isGridView ? 1.37 : 3.0;
                      
                      return SliverGrid(
                        key: ValueKey(widget.isGridView),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: targetExtent,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: targetAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final note = notes[index];
                            final isSelected = widget.selectedNotes.contains(note);
                            
                            return TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                              tween: Tween(begin: 0.8, end: 1.0),
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: scale,
                                    child: NoteCard(
                                      note: note,
                                      isSelected: isSelected,
                                      // Pass highlight flag for pinned notes if desired
                                      isPinnedHighlight: isPinnedSection, 
                                      onTap: () async {
                                        if (widget.isContextMode) {
                                          widget.onToggleSelection(note);
                                        } else {
                                          await Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                                  NoteViewScreen(note: note),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return FadeTransition(opacity: animation, child: child);
                                              },
                                              transitionDuration: const Duration(milliseconds: 300),
                                            ),
                                          );
                                          refreshNotes();
                                        }
                                      },
                                      onLongPress: () {
                                        if (widget.isContextMode) {
                                          widget.onToggleSelection(note);
                                        } else {
                                          widget.onEnterContextMode(note);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: notes.length,
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}