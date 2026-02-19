import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/services/database_service.dart'; // Added for profile check
import 'package:skillsync/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(toolbarHeight: 40, backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome To\nSkillSync',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 20),

                // ⚪ Login Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Email', isDense: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Password', isDense: true),
                      ),
                      const SizedBox(height: 24),
                      _isLoading 
                        ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                        : PrimaryButton(
                            label: 'Login',
                            onPressed: _handleLogin,
                            height: 48,
                          ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {}, 
                        child: Text('Forgot password?', style: TextStyle(color: colorScheme.secondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text('Or', style: TextStyle(color: colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // 🔵 Google Login Button
                _socialButton(
                  context, 
                  'assets/google.png', 
                  'Login with Google', 
                  _handleGoogleLogin
                ),
                const SizedBox(height: 8),
                
                // Facebook Login Button (Logic empty for now)
                _socialButton(
                  context, 
                  'assets/facebook.png', 
                  'Login with Facebook', 
                  () {}
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    "Don't have an account? Create one",
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated Helper with InkWell for touch feedback
  Widget _socialButton(BuildContext context, String asset, String text, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, height: 18, width: 18),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields")));
      return;
    }
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final result = await authService.login(_emailController.text.trim(), _passwordController.text.trim());
    if (mounted) setState(() => _isLoading = false);

    if (result == "success") {
       Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? "Error"), backgroundColor: Colors.redAccent));
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    
    try {
      final result = await authService.signInWithGoogle();

      if (result == "success") {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Senior Practice: Check if this user already has a Firestore document
          final profile = await DatabaseService().getUserProfile(user.uid);
          
          if (profile == null) {
            // New user via Google: Create their document first, then Onboard
            await DatabaseService().createUserProfile(user.uid, user.email!);
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/onboarding_current', (route) => false);
            }
          } else {
            // Existing user: Straight to Home
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          }
        }
      } else if (result != "canceled") {
        // Show actual error if it wasn't just the user closing the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result ?? "Google Sign-In failed"), backgroundColor: Colors.redAccent)
          );
        }
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}