import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/core/app_lifecycle_handler.dart';

// SETTINGS & SERVICES
import 'package:skillsync/firebase_options.dart';
import 'package:skillsync/providers/theme_provider.dart';
import 'package:skillsync/providers/biometrics_provider.dart';
import 'package:skillsync/screens/settings/settings_screen.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/theme/app_theme.dart';

// SCREEN IMPORTS
import 'package:skillsync/screens/auth/login_screen.dart';
import 'package:skillsync/screens/auth/register_screen.dart';
import 'package:skillsync/screens/home/home_screen.dart';
import 'package:skillsync/screens/notifications/notifications_screen.dart';
import 'package:skillsync/screens/matching/matching_screen.dart';
import 'package:skillsync/screens/community/community_page.dart';
import 'package:skillsync/screens/profile/user_profile_screen.dart';
import 'package:skillsync/screens/profile/profile_screen.dart';
import 'package:skillsync/screens/profile/edit_profile_screen.dart';
import 'package:skillsync/screens/onboarding/onboarding_current_skills_screen.dart';
import 'package:skillsync/screens/onboarding/onboarding_new_skills_screen.dart';
import 'package:skillsync/screens/splash/splash_screen.dart';
import 'package:skillsync/screens/auth/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BiometricsProvider()),
      ],
      child: const SkillSyncApp(),
    ),
  );
}

// Global navigator key used by lifecycle handler to push LockScreen safely
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SkillSyncApp extends StatelessWidget {
  const SkillSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 Wrap with Consumer<ThemeProvider>
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SkillSync',
          navigatorKey: navigatorKey,

          builder: (context, child) {
            return AppLifecycleHandler(child: child!);
          },
          // 🟢 Link the themeMode to our provider
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // 🛡️ Auth gate
          // lib/main.dart - build method
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                return const HomeScreen();
              }

              return const LoginScreen();
            },
          ),

          // 🚪 Routes
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/onboarding_current': (context) => const OnboardingCurrentSkillsScreen(),
            '/onboarding_new': (context) => const OnboardingNewSkillsScreen(),
            '/splash': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/matching': (context) => const MatchingScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/user_profile': (context) => const UserProfileScreen(),
            '/edit_profile': (context) => const EditProfileScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/community': (context) => const CommunityPage(),
            '/explore': (context) => const MatchingScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
