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
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 18),
          onPressed: () => Navigator.pop(context),
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
                Text(
                  'Create Account',
                  style: TextStyle(
                    color: colorScheme.primary, 
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: -0.8
                  ),
                ),
                const SizedBox(height: 16),

                // ⚪ Register Card (Radius 16)
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
                      Text(
                        'Join SkillSync',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Email', isDense: true),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Password', isDense: true),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Confirm Password', isDense: true),
                      ),
                      const SizedBox(height: 24),
                      _isLoading 
                        ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
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

                _socialButton(context, 'assets/google.png', 'Join with Google'),
                const SizedBox(height: 8),
                _socialButton(context, 'assets/facebook.png', 'Join with Facebook'),
                
                const SizedBox(height: 12),
                TextButton(
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

  Widget _socialButton(BuildContext context, String asset, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
    );
  }

  void _handleRegister() async {
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
}