import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skillsync/screens/notifications/notifications_screen.dart';
import 'firebase_options.dart';
// SCREEN IMPORTS
//auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
//chat
import 'screens/chat/chat_screen.dart';
//community
import 'screens/community/community_screen.dart';
//explore
import 'screens/explore/explore_screen.dart';
//home
import 'screens/home/home_screen.dart';
//matching
import 'screens/matching/matching_screen.dart';
//onboarding
import 'screens/onboarding/onboarding_current_skills_screen.dart';
import 'screens/onboarding/onboarding_new_skills_screen.dart';
//profile
import 'screens/profile/profile_screen.dart';
import 'screens/profile/user_profile_screen.dart';
//splash
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //CONNECT APP TO SKILLSYNC PROJECT ON FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkillSyncApp());
}

class SkillSyncApp extends StatelessWidget {
  const SkillSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSync',
      theme: ThemeData(
        // Base theme colors for your app
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/login', // starting screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/onboarding_current': (context) => OnboardingCurrentSkillsScreen(),
        '/onboarding_new': (context) => OnboardingNewSkillsScreen(),
        '/splash': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/matching': (context) => MatchingScreen(),
        '/profile': (context) => ProfileScreen(),
        '/user_profile': (context) => UserProfileScreen(),
        '/chat': (context) => const ChatScreen(chatName: 'Fake User'),
        '/notifications': (context) => const NotificationsScreen(),
        '/community': (context) => CommunityScreen(),
        '/explore': (context) => ExploreScreen(),

      },
    );
  }
}
