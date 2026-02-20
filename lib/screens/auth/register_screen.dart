import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Increased height to 56 (standard) to ensure back button has 48px touch target
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.transparent,
        leading: Semantics(
          label: "Back",
          button: true,
          child: IconButton(
            tooltip: "Back",
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      color: colorScheme.primary, 
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: -0.8
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ⚪ Register Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Join SkillSync',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email', 
                          hintText: 'Enter your email address',
                          isDense: true
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Password', 
                          hintText: 'Create a password',
                          isDense: true
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password', 
                          hintText: 'Re-enter your password',
                          isDense: true
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _isLoading 
                        ? Semantics(
                            label: "Registering account",
                            child: const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                          )
                        : PrimaryButton(
                            label: 'Register', 
                            onPressed: _handleRegister, 
                            height: 48
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
                  'Join with Google', 
                  _handleGoogleLogin
                ),
                const SizedBox(height: 8),
                
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48), // Ensure minimum touch target
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Have an account? Login', 
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(BuildContext context, String asset, String text, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Group elements so TalkBack reads "Join with Google, Button" instead of separate image and text
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: text,
        enabled: !_isLoading,
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48), // Accessible height
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hide image from semantics as the parent label covers it
                ExcludeSemantics(
                  child: Image.asset(asset, height: 18, width: 18),
                ),
                const SizedBox(width: 10),
                Text(text, style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    // Dismiss keyboard for accessibility focus
    FocusManager.instance.primaryFocus?.unfocus();

    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields")));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signUp(_emailController.text.trim(), _passwordController.text.trim());

      if (result == "success") {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await DatabaseService().createUserProfile(user.uid, user.email!);
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushNamedAndRemoveUntil(context, '/onboarding_current', (route) => false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? "Registration failed")));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
            if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/onboarding_current', (route) => false);
          } else {
            if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      } else if (result != "canceled") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result ?? "Google Sign-In failed"), backgroundColor: Colors.redAccent)
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}