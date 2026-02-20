import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// SETTINGS & SERVICES
import 'package:skillsync/firebase_options.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const SkillSyncApp(),
    ),
  );
}

class SkillSyncApp extends StatelessWidget {
  const SkillSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // 🛡️ THE SMART AUTH GATE
      // lib/main.dart - build method inside SkillSyncApp
      // lib/main.dart - Inside SkillSyncApp build method
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 🟢 SIMPLIFIED: If logged in, ALWAYS go to Home. 
          // Home will handle the onboarding check itself.
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          
          return const LoginScreen();
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding_current': (context) =>
            const OnboardingCurrentSkillsScreen(),
        '/onboarding_new': (context) => const OnboardingNewSkillsScreen(),
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/matching': (context) => const MatchingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/user_profile': (context) => const UserProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/community': (context) => const CommunityPage(),
        '/explore': (context) =>
            const MatchingScreen(), // Redirected as requested
      },
    );
  }
}
