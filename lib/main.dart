import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/providers.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_back_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('[KiwiNovas] Firebase init failed: $e');
  }

  if (!firebaseReady) {
    runApp(const _FirebaseSetupErrorApp());
    return;
  }

  // Initialise notification service
  final notifService = NotificationService();
  await notifService.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWith((_) => notifService),
      ],
      child: const PeriodTrackerApp(),
    ),
  );
}

DatePickerThemeData _datePickerTheme(Brightness brightness) {
  const deep = Color(0xFF880E4F);
  const mid = Color(0xFFE91E63);
  const bg = Color(0xFFFCE4EC);
  final isDark = brightness == Brightness.dark;
  return DatePickerThemeData(
    backgroundColor: isDark ? const Color(0xFF2C1A24) : Colors.white,
    headerBackgroundColor: deep,
    headerForegroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return isDark ? Colors.white : const Color(0xFF333333);
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return deep;
      return null;
    }),
    todayForegroundColor: WidgetStateProperty.all(mid),
    todayBorder: const BorderSide(color: mid, width: 1.5),
    yearForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return isDark ? Colors.white : deep;
    }),
    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return deep;
      return null;
    }),
    rangeSelectionBackgroundColor: bg,
  );
}

class PeriodTrackerApp extends ConsumerWidget {
  const PeriodTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-schedule notifications whenever predicted date changes
    ref.listen<DateTime?>(nextPredictedDateProvider, (_, next) {
      final enabled =
          ref.read(periodServiceProvider).profile.notificationsEnabled;
      if (enabled) {
        ref.read(notificationServiceProvider).scheduleReminder(next);
      } else {
        ref.read(notificationServiceProvider).cancelReminder();
      }
    });

    ref.listen<bool>(notificationsEnabledProvider, (_, enabled) {
      if (enabled) {
        ref.read(notificationServiceProvider)
            .scheduleReminder(ref.read(nextPredictedDateProvider));
      } else {
        ref.read(notificationServiceProvider).cancelReminder();
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = DefaultKiwiNovasTheme(brightness: Brightness.light)
        .themeData
        .copyWith(datePickerTheme: _datePickerTheme(Brightness.light));
    final darkTheme = DefaultKiwiNovasTheme(brightness: Brightness.dark)
        .themeData
        .copyWith(datePickerTheme: _datePickerTheme(Brightness.dark));

    return KiwiNovasThemeProvider(
      themeMode: themeMode,
      child: MaterialApp(
        title: 'Seluna',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Listens to Firebase auth state and routes to the correct screen.
class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (err, _) => const AuthScreen(),
      data: (User? user) {
        if (user == null) {
          // Not signed in → start onboarding (registration is the last step)
          return const OnboardingScreen();
        }

        // Signed in → check onboarding status
        final service = ref.watch(periodServiceProvider);
        final profile = service.profile;

        if (!profile.hasCompletedOnboarding) {
          // Edge case: signed in but onboarding not done (e.g. Google sign-in)
          return const OnboardingScreen();
        }

        // Returning user → brief welcome splash then home
        return const WelcomeBackScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8F0),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE91E63),
          strokeWidth: 3,
        ),
      ),
    );
  }
}

/// Shown when google-services.json is missing / Firebase not configured.
class _FirebaseSetupErrorApp extends StatelessWidget {
  const _FirebaseSetupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 64, color: Color(0xFFE91E63)),
                const SizedBox(height: 24),
                const Text(
                  'Firebase not configured',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF880E4F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please add google-services.json to android/app/ and restart the app.\n\n'
                  '1. Go to Firebase Console\n'
                  '2. Create / open your project\n'
                  '3. Add Android app with package:\n'
                  '   com.kiwinovas.periodtracker\n'
                  '4. Download google-services.json\n'
                  '5. Place it in android/app/',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
