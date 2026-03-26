import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todocart/provider/app_preferences_provider.dart';
import 'package:todocart/provider/tasks_provider.dart';
import 'package:todocart/provider/theme_provider.dart';
import 'package:todocart/services/notifications/notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:todocart/screens/app_navigation_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv load skipped: $e');
  }
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final prefs = AppPreferencesProvider();
            prefs.init();
            return prefs;
          },
        ),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colors.blue.withOpacity(0.2),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: Colors.blue.withOpacity(0.3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TodoCart',
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const AppNavigationPage(),
    );
  }
}
