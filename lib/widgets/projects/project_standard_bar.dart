import 'package:flutter/material.dart';

class ProjectStandardBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final Function(String) onMenuSelected;

  const ProjectStandardBar({
    super.key,
    required this.onBack,
    required this.onCreate,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.cardColor; 
    final iconColor = theme.iconTheme.color;

    return Container(
      key: const ValueKey('standardBar'),
      height: 100,
      width: 500,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: iconColor),
            padding: const EdgeInsets.only(left: 8),
          ),
          
          Row(
            children: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: iconColor),
                color: barColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                offset: const Offset(0, -60),
                onSelected: onMenuSelected,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.file_upload_outlined, size: 20, color: iconColor),
                        const SizedBox(width: 12),
                        Text('Import project', style: TextStyle(color: iconColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              
              GestureDetector(
                onTap: onCreate,
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary, 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: theme.colorScheme.onSecondary, size: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}