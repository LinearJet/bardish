import 'package:flutter/material.dart';

class NoteSearchOverlay extends StatefulWidget {
  final String content;
  final Function(int currentMatch, int totalMatches, List<int> positions, String query) onSearchChanged;
  final VoidCallback onClose;

  const NoteSearchOverlay({
    super.key,
    required this.content,
    required this.onSearchChanged,
    required this.onClose,
  });

  @override
  State<NoteSearchOverlay> createState() => NoteSearchOverlayState();
}

class NoteSearchOverlayState extends State<NoteSearchOverlay> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  List<int> _matchPositions = [];
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    
    _animController.forward();
    
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _matchPositions = [];
        _currentMatchIndex = 0;
      });
      widget.onSearchChanged(0, 0, [], '');
      return;
    }

    final content = widget.content.toLowerCase();
    final searchQuery = query.toLowerCase();
    final positions = <int>[];
    
    int index = 0;
    while ((index = content.indexOf(searchQuery, index)) != -1) {
      positions.add(index);
      index += searchQuery.length;
    }

    setState(() {
      _matchPositions = positions;
      _currentMatchIndex = positions.isNotEmpty ? 0 : -1;
    });

    widget.onSearchChanged(
      _currentMatchIndex + 1,
      positions.length,
      positions,
      query,
    );
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
    });
    widget.onSearchChanged(
      _currentMatchIndex + 1,
      _matchPositions.length,
      _matchPositions,
      _searchController.text,
    );
  }

  void _previousMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchPositions.length) % _matchPositions.length;
    });
    widget.onSearchChanged(
      _currentMatchIndex + 1,
      _matchPositions.length,
      _matchPositions,
      _searchController.text,
    );
  }

  Future<void> close() async {
    await _animController.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final barColor = isDark 
        ? const Color(0xFF2A2725) 
        : theme.colorScheme.surfaceContainerHighest;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Icon
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              
              // Search Input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search in note...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: _performSearch,
                ),
              ),
              
              // Match Counter with Animation
              if (_matchPositions.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentMatchIndex + 1}/${_matchPositions.length}',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              
              // Navigation Buttons
              if (_matchPositions.isNotEmpty) ...[
                _NavButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  onTap: _previousMatch,
                ),
                _NavButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: _nextMatch,
                ),
              ],
              
              // Close Button
              _NavButton(
                icon: Icons.close_rounded,
                onTap: close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> 
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(widget.icon, size: 20, color: theme.iconTheme.color),
          ),
        ),
      ),
    );
  }
}