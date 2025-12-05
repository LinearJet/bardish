import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DashboardSearchBar extends StatelessWidget {
  final Function(String) onSearchChanged;

  const DashboardSearchBar({
    super.key,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(21),
            ),
            child: TextField(
              cursorColor: theme.colorScheme.primary,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}