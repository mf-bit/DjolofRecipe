import 'package:flutter/material.dart';

import 'data/data.dart';
import 'presentation/exercises/exercise_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await openAppGymRepository();
  runApp(GymProgressionApp(repository: repository));
}

class GymProgressionApp extends StatelessWidget {
  const GymProgressionApp({
    super.key,
    required this.repository,
    this.exerciseIdGenerator,
    this.workoutIdGenerator,
    this.clock,
  });

  final GymRepository repository;
  final String Function()? exerciseIdGenerator;
  final String Function()? workoutIdGenerator;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    // Fresh organic athletic palette inspired by high-end fitness UI
    const warmCreamBg = Color(0xFFFBF8F2);
    const softSurfaceCard = Color(0xFFFFFFFF);
    const forestGreenPrimary = Color(0xFF1E3A2F);
    const lightSageSecondary = Color(0xFF5A7D6F);
    const apricotAccent = Color(0xFFE88349);

    final lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: forestGreenPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE3EFE9),
      onPrimaryContainer: forestGreenPrimary,
      secondary: lightSageSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF2ECE1),
      onSecondaryContainer: forestGreenPrimary,
      tertiary: apricotAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFECE0),
      onTertiaryContainer: const Color(0xFF682600),
      surface: softSurfaceCard,
      onSurface: const Color(0xFF1A1C1A),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF7F3EB),
      surfaceContainer: const Color(0xFFF2ECE1),
      surfaceContainerHigh: const Color(0xFFECE6DA),
      surfaceContainerHighest: const Color(0xFFE6DFC8),
      outline: const Color(0xFF8A938B),
      outlineVariant: const Color(0xFFD3DDD5),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: forestGreenPrimary,
      primary: const Color(0xFF88C9AC),
      secondary: const Color(0xFFB5CFBE),
      tertiary: const Color(0xFFFFB68C),
      surface: const Color(0xFF121915),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'YawooDial Fitness',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: warmCreamBg,
        colorScheme: lightColorScheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: warmCreamBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: softSurfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F4EC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5DFD3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: forestGreenPrimary, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: forestGreenPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1512),
        colorScheme: darkColorScheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1512),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
      home: ExerciseManagementScreen(
        repository: repository,
        exerciseIdGenerator: exerciseIdGenerator,
        workoutIdGenerator: workoutIdGenerator,
        clock: clock,
      ),
    );
  }
}
