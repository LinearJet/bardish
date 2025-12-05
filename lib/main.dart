import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/colors.dart';
import 'services/note_database.dart';
import 'services/todo_database.dart';
import 'services/block_database.dart';
import 'services/project_database.dart';
import 'services/sync_service.dart';
import 'models/note.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NoteDatabase.initialize();
  await TodoDatabase.initialize();
  await BlockDatabase.initialize();
  await ProjectDatabase.initialize();

  final settingsBox = await Hive.openBox('settings');
  
  final String? syncPath = settingsBox.get('syncFolderPath');
  await SyncService.initialize(syncPath);
  
  bool isFirstRun = settingsBox.get('isFirstRun', defaultValue: true);
  bool hasSeenOnboarding = settingsBox.get('hasSeenOnboarding', defaultValue: false);

  if (isFirstRun) {
    final welcomeNote = Note()
      ..id = const Uuid().v4()
      ..title = "Welcome to Bard-ish!"
      ..content = """
# Welcome to the Void.

This is **Bard-ish**, your minimalist note-taking companion.

### Features
- **Markdown Support**: Write in *style*.
- **Local Database**: Your thoughts stay on your device.
- **Search**: Find anything instantly.

> "Simplicity is the ultimate sophistication."

Tap the pencil to start writing.
"""
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
      
    await NoteDatabase.saveNote(welcomeNote);
    await settingsBox.put('isFirstRun', false);
  }

  runApp(BardishApp(startScreen: hasSeenOnboarding ? const DashboardScreen() : const WelcomeScreen()));
}

class BardishApp extends StatelessWidget {
  final Widget startScreen;
  
  const BardishApp({super.key, required this.startScreen});

  ThemeData _buildTheme(
    Brightness brightness, 
    Color background, 
    Color surface, 
    Color primary, 
    Color secondary,
    {Color? onSecondary, Color? highlightColor}
  ) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Serif',
      scaffoldBackgroundColor: background,
      highlightColor: highlightColor ?? secondary.withOpacity(0.15),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: background,
        secondary: secondary,
        onSecondary: onSecondary ?? background,
        surface: surface,
        onSurface: primary,
        background: background,
        onBackground: primary,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      iconTheme: IconThemeData(color: secondary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
      ),
      dialogBackgroundColor: background,
      cardColor: surface,
      dividerColor: secondary.withOpacity(0.2),
      hintColor: secondary.withOpacity(0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(keys: ['themeMode']),
      builder: (context, box, _) {
        final themeModeStr = box.get('themeMode', defaultValue: 'dark');
        
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            ThemeData theme;
            
            switch (themeModeStr) {
              case 'bardish': 
                theme = _buildTheme(
                  Brightness.dark,
                  BardishColors.bardIshBackground,
                  BardishColors.bardIshSurface, 
                  BardishColors.textPrimary, 
                  BardishColors.bardIshAccent, 
                  highlightColor: BardishColors.bardIshHighlight, 
                );
                break;
              case 'light':
                theme = _buildTheme(Brightness.light, const Color(0xFFF5F5F5), Colors.white, Colors.black87, const Color(0xFF8C6D4F));
                break;
              case 'beige':
                theme = _buildTheme(Brightness.light, BardishColors.beigeBackground, BardishColors.beigeSurface, BardishColors.beigeTextPrimary, BardishColors.beigeAccent);
                break;
              case 'sapphire':
                theme = _buildTheme(Brightness.dark, BardishColors.sapphireBackground, BardishColors.sapphireSurface, BardishColors.sapphirePrimary, BardishColors.sapphireSecondary);
                break;
              case 'coffee':
                theme = _buildTheme(Brightness.dark, BardishColors.coffeeBackground, BardishColors.coffeeSurface, BardishColors.coffeePrimary, BardishColors.coffeeSecondary);
                break;
              case 'sea':
                theme = _buildTheme(Brightness.dark, BardishColors.seaBackground, BardishColors.seaSurface, BardishColors.seaPrimary, BardishColors.seaSecondary);
                break;
              case 'orange':
                theme = _buildTheme(Brightness.light, BardishColors.orangeBackground, BardishColors.orangeSurface, BardishColors.orangePrimary, BardishColors.orangeSecondary);
                break;
              case 'mint':
                theme = _buildTheme(Brightness.light, BardishColors.mintBackground, BardishColors.mintSurface, BardishColors.mintPrimary, BardishColors.mintSecondary);
                break;
              case 'chocolate':
                theme = _buildTheme(Brightness.dark, BardishColors.chocoBackground, BardishColors.chocoSurface, BardishColors.chocoPrimary, BardishColors.chocoSecondary);
                break;
              case 'material3':
                theme = ThemeData(
                  colorScheme: (WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? darkDynamic : lightDynamic) ?? 
                               ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: WidgetsBinding.instance.platformDispatcher.platformBrightness),
                  useMaterial3: true,
                  fontFamily: 'Serif',
                );
                break;
              case 'dark':
              default:
                theme = _buildTheme(Brightness.dark, BardishColors.background, BardishColors.surface, BardishColors.textPrimary, BardishColors.accent, onSecondary: const Color(0xFF1C1918));
                break;
            }

            return MaterialApp(
              title: 'Bard-ish',
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: startScreen,
            );
          }
        );
      }
    );
  }
}
