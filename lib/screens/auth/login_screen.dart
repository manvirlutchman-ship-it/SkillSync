import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/services/database_service.dart';
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
    final textScale = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Increased toolbar height slightly to ensure back button (if present) meets target size
      appBar: AppBar(toolbarHeight: 56, backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Semantic Header for Screen Readers
                Semantics(
                  header: true,
                  child: Text(
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
                      Semantics(
                        header: true,
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Email Field with Accessibility Helpers
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email address', // Helps screen readers
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _isLoading
                          ? Semantics(
                              label: "Logging in",
                              child: const SizedBox(
                                height: 48,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            )
                          : PrimaryButton(
                              label: 'Login',
                              onPressed: _handleLogin,
                              height: 48,
                              // Ensure Semantic Label is passed if PrimaryButton supports it, 
                              // otherwise the label text is read automatically.
                            ),
                      const SizedBox(height: 4),
                      
                      TextButton(
                        // Ensure minimum tap target size (48x48)
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () {},
                        child: Text('Forgot password?', style: TextStyle(color: colorScheme.secondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Exclude "Or" from semantics if it's purely decorative, 
                // but keeping it is fine for context.
                Text('Or', style: TextStyle(color: colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // 🔵 Google Login Button
                _socialButton(
                  context,
                  'assets/google.png',
                  'Login with Google',
                  _handleGoogleLogin,
                ),
                const SizedBox(height: 8),

                TextButton(
                  // Ensure minimum tap target size
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
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

  // Updated Helper with Accessibility Improvements
  Widget _socialButton(BuildContext context, String asset, String text, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // MergeSemantics ensures the Image and Text are read as one "Button" label
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: !_isLoading,
        label: text,
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            // Ensure minimum height of 48px for accessibility
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Exclude image from semantics since the parent Semantics label covers it
                ExcludeSemantics(
                  child: Image.asset(asset, height: 18, width: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  text, 
                  style: TextStyle(
                    color: colorScheme.onSurface, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w600
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  void _handleLogin() async {
    // Hide keyboard for screen reader focus stability
    FocusManager.instance.primaryFocus?.unfocus();

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
          final profile = await DatabaseService().getUserProfile(user.uid);
          
          if (profile == null) {
            await DatabaseService().createUserProfile(user.uid, user.email!);
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/onboarding_current', (route) => false);
            }
          } else {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          }
        }
      } else if (result != "canceled") {
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