import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:muscleup/firebase_options.dart';
import 'package:muscleup/presentation/auth/login_screen.dart';
import 'package:muscleup/presentation/navigation/main_navigation.dart';
import 'package:muscleup/presentation/onboarding/onboarding_flow.dart';
import 'package:muscleup/presentation/contract/contract_verification_screen.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/presentation/language/bloc/language_bloc.dart';
import 'package:muscleup/presentation/language/bloc/language_state.dart';
import 'package:muscleup/core/di/service_locator.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/services/signature_migration_service.dart';
import 'package:muscleup/data/services/app_tracking_service.dart';
import 'package:muscleup/data/services/ai_service.dart';
import 'package:muscleup/data/services/language_service.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with error handling for duplicate app)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If Firebase is already initialized, continue silently
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized, continuing...');
    } else {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  // Setup dependency injection
  setupServiceLocator();

  // Load saved language preference
  final languageService = getIt<LanguageService>();
  final savedLanguage = await languageService.getLanguage() ?? 'he';
  final locale = savedLanguage == 'en' ? const Locale('en', 'US') : const Locale('he', 'IL');

  // Initialize date formatting for Hebrew locale (required for receipt generation)
  await _initializeDateFormatting();

  // Initialize AI service (for OpenAI API)
  await _initializeAIService();

  // Request App Tracking Transparency permission
  await _requestTrackingPermission();

  // Run signature migration in background
  _runSignatureMigration();

  runApp(MyApp(locale: locale));
}

/// Initialize date formatting for Hebrew locale
Future<void> _initializeDateFormatting() async {
  try {
    await initializeDateFormatting('he', null);
    print('✅ Date formatting initialized for Hebrew locale');
  } catch (e) {
    print('⚠️ Failed to initialize date formatting: $e');
    // Try to initialize with default locale as fallback
    try {
      await initializeDateFormatting('en', null);
      print('✅ Date formatting initialized with English locale as fallback');
    } catch (e2) {
      print('❌ Failed to initialize date formatting with fallback: $e2');
    }
  }
}

/// Initialize AI service
Future<void> _initializeAIService() async {
  try {
    final aiService = AIService();
    await aiService.initialize();
    print('✅ AI service initialized');
  } catch (e) {
    print('⚠️ Failed to initialize AI service: $e');
    // Don't fail app startup if AI service fails
  }
}

/// Request App Tracking Transparency permission
Future<void> _requestTrackingPermission() async {
  try {
    final isAuthorized = await AppTrackingService.requestTrackingPermission();
    print('📊 Tracking permission: ${isAuthorized ? 'Granted' : 'Denied'}');
  } catch (e) {
    print('❌ Failed to request tracking permission: $e');
  }
}

/// Run signature migration in background
void _runSignatureMigration() {
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      final migrationService = getIt<SignatureMigrationService>();
      await migrationService.migrateSignaturesToStorage();
    } catch (e) {
      print('❌ Background signature migration failed: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  final Locale locale;
  
  const MyApp({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => getIt<LanguageBloc>(),
        ),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          final currentLocale = languageState.isEnglish 
              ? const Locale('en', 'US') 
              : const Locale('he', 'IL');
          
          return Directionality(
            textDirection: languageState.isEnglish 
                ? ui.TextDirection.ltr 
                : ui.TextDirection.rtl,
            child: MaterialApp(
              title: 'MuscleUp',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('he', 'IL'),
                Locale('en', 'US'),
              ],
              locale: currentLocale,
              themeMode: ThemeMode.system,
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
        primary: const Color(0xFF4CAF50),
        surface: Colors.white,
        surfaceTint: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF4CAF50).withAlpha(50),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
        primary: const Color(0xFF66BB6A),
        surface: const Color(0xFF1E1E1E),
        surfaceTint: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66BB6A),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF66BB6A),
        foregroundColor: Colors.black,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF66BB6A).withAlpha(80),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return FutureBuilder<UserModel?>(
            future: FirestoreService().getUser(state.user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userModel = snapshot.data;

              // If no user data, go to onboarding
              if (userModel == null) {
                return OnboardingFlow(firebaseUser: state.user);
              }

              // If profile not complete, go to onboarding
              if (!userModel.isProfileComplete) {
                return OnboardingFlow(firebaseUser: state.user);
              }

              // If contract not signed, block access
              if (!userModel.hasSignedContract) {
                return ContractVerificationScreen(
                  firebaseUser: state.user,
                  userModel: userModel,
                );
              }

              // All good, go to main app
              return const MainNavigation();
            },
          );
        } else if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginScreen();
        }

        // Loading state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
