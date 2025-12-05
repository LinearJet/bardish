import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'widgets/existing_notes_list.dart';
import 'widgets/web_link_form.dart';
import 'widgets/new_note_link_form.dart';

class LinkNoteSheet extends StatefulWidget {
  const LinkNoteSheet({super.key});

  @override
  State<LinkNoteSheet> createState() => _LinkNoteSheetState();
}

class _LinkNoteSheetState extends State<LinkNoteSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleLinkSelected(String linkText) {
    Navigator.pop(context, linkText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // --- Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title & Search Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isSearching)
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: theme.hintColor),
                          ),
                          style: TextStyle(fontSize: 20, color: theme.colorScheme.primary),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      )
                    else
                      Text(
                        'Link Note',
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Serif',
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search, size: 28),
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Custom Tab Bar
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.hintColor,
                    indicatorColor: theme.colorScheme.secondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                    dividerColor: Colors.transparent,
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'Existing Notes'),
                      Tab(text: 'Web Link'),
                      Tab(text: 'New Note'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Tab Views ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Existing Notes
                ExistingNotesList(
                  searchQuery: _searchQuery,
                  onNoteSelected: (note) {
                    // Obsidian style link: [[Title]]
                    _handleLinkSelected('[[${note.title}]]');
                  },
                ),
                
                // 2. Web Link
                WebLinkForm(
                  onLinkCreated: (text, url) {
                    // Markdown link: [Text](URL)
                    _handleLinkSelected('[$text]($url)');
                  },
                ),
                
                // 3. New Note
                NewNoteLinkForm(
                  onNewNoteLink: (title) {
                    // Create link to new note: [[Title]]
                    // Logic to actually create the file can happen when clicked, 
                    // or we just insert the link now. Standard behavior is insert link.
                    _handleLinkSelected('[[${title.trim()}]]');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
