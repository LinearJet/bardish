import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../widgets/theme_card.dart';
import '../widgets/mini_theme_chip.dart';
import '../widgets/theme_list_tile.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late Box _settingsBox;
  String _currentTheme = 'dark';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _currentTheme = _settingsBox.get('themeMode', defaultValue: 'dark');
  }

  void _handleThemeChange(String value) {
    setState(() {
      _currentTheme = value;
    });
    _settingsBox.put('themeMode', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontFamily: 'Serif',
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Presets",
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Default Themes Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ThemeCard(
                    label: "Dark",
                    value: "dark",
                    isSelected: _currentTheme == 'dark',
                    color: BardishColors.background,
                    textColor: BardishColors.textPrimary,
                    onTap: () => _handleThemeChange('dark'),
                  ),
                  // --- NEW BARDISH THEME CARD ---
                  ThemeCard(
                    label: "BardIsh",
                    value: "bardish",
                    isSelected: _currentTheme == 'bardish',
                    color: BardishColors.bardIshBackground,
                    textColor: BardishColors.bardIshAccent,
                    onTap: () => _handleThemeChange('bardish'),
                  ),
                  ThemeCard(
                    label: "Light",
                    value: "light",
                    isSelected: _currentTheme == 'light',
                    color: const Color(0xFFF5F5F5),
                    textColor: Colors.black87,
                    onTap: () => _handleThemeChange('light'),
                  ),
                  ThemeCard(
                    label: "Beige",
                    value: "beige",
                    isSelected: _currentTheme == 'beige',
                    color: BardishColors.beigeBackground,
                    textColor: BardishColors.beigeTextPrimary,
                    onTap: () => _handleThemeChange('beige'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // More Button
              InkWell(
                onTap: _showMoreThemesMenu,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined, color: theme.colorScheme.secondary),
                          const SizedBox(width: 16),
                          Text(
                            "More Themes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!['dark', 'light', 'beige', 'bardish'].contains(_currentTheme))
                            Text(
                              _formatThemeName(_currentTheme),
                              style: TextStyle(color: theme.colorScheme.secondary, fontSize: 14),
                            ),
                          const SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_up, color: theme.hintColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreThemesMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Theme",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // Collection Section (Chips)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          "Collection", 
                          style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MiniThemeChip(
                              label: "Sapphire",
                              value: "sapphire",
                              color: BardishColors.sapphireBackground,
                              onTap: (v) { _handleThemeChange(v); Navigator.pop(context); },
                              isSelected: _currentTheme == 'sapphire',
                            ),
                            MiniThemeChip(
                              label: "Coffee",
                              value: "coffee",
                              color: BardishColors.coffeeBackground,
                              onTap: (v) { _handleThemeChange(v); Navigator.pop(context); },
                              isSelected: _currentTheme == 'coffee',
                            ),
                            MiniThemeChip(
                              label: "Sea",
                              value: "sea",
                              color: BardishColors.seaBackground,
                              onTap: (v) { _handleThemeChange(v); Navigator.pop(context); },
                              isSelected: _currentTheme == 'sea',
                            ),
                            MiniThemeChip(
                              label: "You",
                              value: "material3",
                              color: Theme.of(context).colorScheme.primaryContainer,
                              onTap: (v) { _handleThemeChange(v); Navigator.pop(context); },
                              isSelected: _currentTheme == 'material3',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // List Tiles
                      ThemeListTile(
                        title: "Orange",
                        subtitle: "Vibrant sunset colors",
                        value: "orange",
                        groupValue: _currentTheme,
                        onChanged: (v) { _handleThemeChange(v); Navigator.pop(context); },
                      ),
                      ThemeListTile(
                        title: "Mint",
                        subtitle: "Fresh green vibes",
                        value: "mint",
                        groupValue: _currentTheme,
                        onChanged: (v) { _handleThemeChange(v); Navigator.pop(context); },
                      ),
                      ThemeListTile(
                        title: "Chocolate",
                        subtitle: "Dark creamy aesthetic",
                        value: "chocolate",
                        groupValue: _currentTheme,
                        onChanged: (v) { _handleThemeChange(v); Navigator.pop(context); },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatThemeName(String s) {
    if (s.isEmpty) return "";
    return s[0].toUpperCase() + s.substring(1);
  }
}
