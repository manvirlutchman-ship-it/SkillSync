import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/primary_button.dart';

import '../../widgets/scalable_text.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  bool _isLoadingSkills = false;

  final List<String> _avatars = List.generate(
    9,
    (index) => 'assets/profilephoto/${index + 1}.jpg',
  );
  String? _selectedAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _bioController = TextEditingController(text: user?.userBio ?? '');
    _selectedAvatarPath = user?.profilePictureUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(bool isFirstTime) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user != null) {
      try {
        final String fName = _firstNameController.text.trim();
        final String lName = _lastNameController.text.trim();
        final String bio = _bioController.text.trim();

        // 1️⃣ Update Firestore first
        await DatabaseService().updateUser(user.id, {
          'first_name': fName,
          'last_name': lName,
          'user_bio': bio,
          'is_onboarded': true,
          'profile_picture_url': _selectedAvatarPath ?? user.profilePictureUrl,
        });

        // 2️⃣ Create the updated user object
        final updatedUser = user.copyWith(
          firstName: fName,
          lastName: lName,
          userBio: bio,
          isOnboarded: true,
          profilePictureUrl: _selectedAvatarPath ?? user.profilePictureUrl,
        );

        if (mounted) {
          // 3️⃣ THE FIX: Navigate FIRST to break the loop
          // This clears the stack and moves to the profile screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/user_profile',
            (route) => false,
          );

          // 4️⃣ Update provider AFTER navigation starts to avoid race conditions with main.dart
          Future.microtask(() => userProvider.updateLocalUser(updatedUser));
        }
      } catch (e) {
        debugPrint("!!! SAVE ERROR: $e !!!");
        if (mounted) {
          setState(() => _isSaving = false); // Turn off spinner on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: ScalableText("Error saving: $e", baseFontSize: 14), backgroundColor: Colors.redAccent),
          );
        }
      }
      // Note: We removed the 'finally' block to ensure _isSaving doesn't 
      // trigger a rebuild on a disposed widget during navigation.
    }
  }

  // --- REST OF YOUR CODE (UI and Helpers) ---
  // Ensure the CircularProgressIndicator uses the theme primary color 
  // so it's visible in both light/dark mode

  void _confirmSkillReset() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Update Skills?", style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          "This will reset your current skills and allow you to select them again from scratch.\n\nDo you want to continue?",
          style: TextStyle(height: 1.5, color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: ScalableText("Cancel", baseFontSize: 14, style: TextStyle(color: colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetAndNavigateSkills();
            },
            child: ScalableText("Yes, Update", baseFontSize: 14, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAndNavigateSkills() async {
    final uid = context.read<UserProvider>().user?.id;
    if (uid == null) return;
    setState(() => _isLoadingSkills = true);
    try {
      await DatabaseService().clearUserSkills(uid);
      if (mounted) Navigator.pushNamed(context, '/onboarding_current');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSkills = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.watch<UserProvider>().user;
    final bool isFirstTime = user?.isOnboarded == false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isFirstTime ? "Final Step" : "Edit Profile",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isFirstTime
            ? const SizedBox.shrink()
            : IconButton(
                icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: _isLoadingSkills
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFirstTime) ...[
                        _buildStepIndicator(colorScheme),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionHeader(context, "CHOOSE AVATAR"),
                      const SizedBox(height: 16),
                      _buildAvatarPicker(colorScheme),
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, "PERSONAL INFORMATION"),
                      const SizedBox(height: 12),
                      _buildFormCard(colorScheme, theme),
                      if (!isFirstTime) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, "SKILLS"),
                        const SizedBox(height: 12),
                        _buildUpdateSkillsTile(colorScheme, theme),
                      ],
                      const SizedBox(height: 40),
                      _isSaving
                          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                          : PrimaryButton(
                              label: isFirstTime ? "FINISH SETUP" : "SAVE CHANGES",
                              onPressed: () => _saveProfile(isFirstTime),
                              height: 48,
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- SUB-WIDGETS FOR CLEANER CODE ---

  Widget _buildAvatarPicker(ColorScheme colorScheme) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatarPath = _avatars[index];
          final isSelected = _selectedAvatarPath == avatarPath;
          return GestureDetector(
            onTap: () => setState(() => _selectedAvatarPath = avatarPath),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.outline.withOpacity(0.1),
                backgroundImage: AssetImage(avatarPath),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.light ? 0.03 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: const InputDecoration(labelText: 'First Name'),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: const InputDecoration(labelText: 'Last Name'),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            style: TextStyle(color: colorScheme.onSurface),
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
            validator: (v) => v!.length < 10 ? "Write a bit more about yourself" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSkillsTile(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(theme.brightness == Brightness.light ? 0.03 : 0.2), blurRadius: 20),
        ],
      ),
      child: ListTile(
        onTap: _confirmSkillReset,
        leading: Icon(Icons.layers_rounded, color: colorScheme.onSurface),
        title: Text("Update Skills", style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.outline),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: colorScheme.outline.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
      child: ScalableText('STEP 3 OF 3', baseFontSize: 10, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colorScheme.secondary, letterSpacing: 1.1)),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: ScalableText(title, baseFontSize: 13, style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
    );
  }
}