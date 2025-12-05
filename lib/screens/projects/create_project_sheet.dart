import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';
import '../../services/project_database.dart';

class CreateProjectSheet extends StatefulWidget {
  const CreateProjectSheet({super.key});

  @override
  State<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<CreateProjectSheet> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  
  // Animation Controller
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int _selectedColorValue = 0xFFA48566; 
  String _selectedIconKey = 'network';
  String _selectedIconLabel = 'Network';

  final List<Color> _colors = [
    const Color(0xFFA48566), 
    const Color(0xFF5D7A76), 
    const Color(0xFF7A8973), 
    const Color(0xFFE91E63), 
    const Color(0xFF9C27B0), 
  ];

  final List<Map<String, dynamic>> _icons = [
    {'key': 'network', 'icon': Icons.account_tree_outlined, 'label': 'Network'},
    {'key': 'hub', 'icon': Icons.hub_outlined, 'label': 'Hub'},
    {'key': 'ideas', 'icon': Icons.lightbulb_outline, 'label': 'Ideas'},
    {'key': 'favorites', 'icon': Icons.star_outline, 'label': 'Favorites'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize Animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack, // This creates the "Pop" effect
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return; 

    final newProject = Project()
      ..id = const Uuid().v4()
      ..name = name
      ..colorValue = _selectedColorValue
      ..iconKey = _selectedIconKey
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await ProjectDatabase.saveProject(newProject);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final sheetColor = isDark ? const Color(0xFF23201E) : Colors.white;
    final textColor = isDark ? const Color(0xFFD6CFC6) : Colors.black87;
    final hintColor = isDark ? const Color(0xFF8F8A85) : theme.hintColor;
    final inputFillColor = Colors.transparent; 
    final borderColor = const Color(0xFF3F3B38);

    return Dialog(
      backgroundColor: Colors.transparent, // Make dialog transparent for custom animation
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView( 
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Color(_selectedColorValue),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _icons.firstWhere((i) => i['key'] == _selectedIconKey)['icon'] as IconData,
                          color: Colors.white.withOpacity(0.9),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create project',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedIconLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Name Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(16),
                      color: inputFillColor,
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Project name',
                        hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Color
                  Text('Project color', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final color = _colors[index];
                        final isSelected = color.value == _selectedColorValue;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColorValue = color.value),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected 
                                ? const Icon(Icons.check, color: Colors.white, size: 28) 
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Icon
                  Text('Project icon', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _icons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _icons[index];
                        final isSelected = item['key'] == _selectedIconKey;
                        final cardColor = isSelected ? const Color(0xFF352F2C) : Colors.transparent;
                        final borderC = isSelected ? Color(_selectedColorValue) : borderColor;
                        
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedIconKey = item['key'];
                            _selectedIconLabel = item['label'];
                          }),
                          child: Container(
                            width: 76,
                            decoration: BoxDecoration(
                              color: cardColor,
                              border: Border.all(color: borderC, width: isSelected ? 2 : 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Color(_selectedColorValue) : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['icon'],
                                    color: isSelected ? Colors.white : hintColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['label'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Color(_selectedColorValue) : hintColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _createProject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF353230),
                            foregroundColor: textColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          child: const Text('Create'),
                        ),
                      ),
                    ],
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
