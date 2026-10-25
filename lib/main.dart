import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'language.dart';
import 'services/auth_service.dart';
import 'services/audio_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService().init();
  await AudioService().init();

  runApp(const IntellectArenaApp());
}

class IntellectArenaApp extends StatelessWidget {
  const IntellectArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppLanguage(),
      child: Consumer<AppLanguage>(
        builder: (context, lang, _) => _ThemeProvider(lang: lang),
      ),
    );
  }
}

class _ThemeProvider extends StatefulWidget {
  final AppLanguage lang;

  const _ThemeProvider({required this.lang});

  @override
  State<_ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<_ThemeProvider> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        _isDark = prefs.getBool('dark_mode') ?? true;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _isDark = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.lang.t('app_name'),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: const Duration(milliseconds: 350),
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => ColoredBox(
        color: _isDark
            ? const Color(0xFF0E0E1A)
            : const Color(0xFFE3E6FF),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClipRect(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      home: _Root(
        isDark: _isDark,
        onThemeToggle: _toggle,
      ),
    );
  }

  ThemeData _base(ColorScheme scheme, Color scaffold) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scaffold,
      primaryColor: const Color(0xFF6C63FF),
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return _base(
      const ColorScheme.dark(
        primary: Color(0xFF6C63FF),
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFF16213E),
      ),
      const Color(0xFF1A1A2E),
    );
  }

  ThemeData _lightTheme() {
    return _base(
      const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        secondary: Color(0xFF03DAC6),
        surface: Colors.white,
      ),
      const Color(0xFFF0F2FF),
    );
  }
}

// Аввал экрани оғозӣ, баъд экрани асосӣ бо гузариши ҳамвор.
class _Root extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeToggle;

  const _Root({
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splash = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOut,
      child: _splash
          ? SplashScreen(
        key: const ValueKey('splash'),
        onDone: () {
          if (mounted) {
            setState(() {
              _splash = false;
            });
          }
        },
      )
          : HomeScreen(
        key: const ValueKey('home'),
        onThemeToggle: widget.onThemeToggle,
        isDark: widget.isDark,
      ),
    );
  }
}