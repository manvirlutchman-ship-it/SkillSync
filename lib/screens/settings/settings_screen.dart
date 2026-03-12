import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/theme_provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/providers/font_size_provider.dart'; // Ensure this is imported
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/providers/biometrics_provider.dart';
import 'package:skillsync/widgets/primary_button.dart';
import 'package:skillsync/widgets/scalable_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ScalableText(
          "Settings",
          baseFontSize: 17, // Fixed: Added missing required parameter
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "PREFERENCES"),
            const SizedBox(height: 12),

            // Theme Toggle Card
            _buildSettingsCard(
              colorScheme: colorScheme,
              isDark: isDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dark Mode",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch.adaptive(
                    activeColor: colorScheme.primary,
                    value: context.watch<ThemeProvider>().isDarkMode,
                    onChanged: (value) {
                      context.read<ThemeProvider>().toggleTheme(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- FONT SIZE SELECTION CARD ---
            _buildSettingsCard(
              colorScheme: colorScheme,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Text Size",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSizeOption(context, 0.8, 'A', colorScheme),
                      _buildSizeOption(context, 1.0, 'A', colorScheme, isDefault: true),
                      _buildSizeOption(context, 1.2, 'A', colorScheme),
                      _buildSizeOption(context, 1.5, 'A', colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Biometrics Lock Card
            _buildSettingsCard(
              colorScheme: colorScheme,
              isDark: isDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Biometrics Lock",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch.adaptive(
                    activeColor: colorScheme.primary,
                    value: context.watch<BiometricsProvider>().isEnabled,
                    onChanged: (value) async {
                      final bm = context.read<BiometricsProvider>();
                      if (value) {
                        final can = await bm.canCheckBiometrics();
                        if (!can) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Biometric hardware not available.'), backgroundColor: colorScheme.error),
                          );
                          return;
                        }

                        final ok = await bm.authenticate();
                        if (ok) {
                          await bm.setEnabled(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Biometrics lock enabled'), backgroundColor: colorScheme.primary),
                          );
                        } else {
                          final err = bm.lastError;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err ?? 'Authentication failed')),
                          );
                        }
                      } else {
                        await bm.setEnabled(false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometrics lock disabled')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildSectionHeader(context, "ACCOUNT MANAGEMENT"),
            const SizedBox(height: 12),

            // Danger Zone Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Danger Zone",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Once you delete your account, there is no going back. Please be certain.",
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: "DELETE ACCOUNT",
                    isDestructive: true,
                    onPressed: _confirmDeleteAccount,
                    height: 48,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS (Properly placed outside build() method) ---

  Widget _buildSizeOption(
    BuildContext context, 
    double factor, 
    String label, 
    ColorScheme colorScheme, 
    {bool isDefault = false}
  ) {
    final currentFactor = context.watch<FontSizeProvider>().scaleFactor;
    final bool isSelected = currentFactor == factor;

    return GestureDetector(
      onTap: () => context.read<FontSizeProvider>().setScaleFactor(factor),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14 * factor,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (isDefault)
            Text("Default", style: TextStyle(fontSize: 10, color: colorScheme.secondary))
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required Widget child,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- LOGIC ---

  void _confirmDeleteAccount() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Are you sure?",
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This will permanently delete your profile, skills, and chat history.",
          style: TextStyle(color: colorScheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: TextStyle(color: colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete();
            },
            child: Text(
              "DELETE",
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please log in again.")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
    );

    final authService = context.read<AuthService>();
    final result = await authService.deleteAccount();

    if (mounted) Navigator.pop(context);

    if (result == "success") {
      context.read<UserProvider>().clearUser();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else if (result == "reauthenticate") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Security check: Please log out and back in to delete your account."),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? "Error"),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
}