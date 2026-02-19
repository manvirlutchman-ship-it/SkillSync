import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/primary_button.dart';

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

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _bioController = TextEditingController(text: user?.userBio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final userProvider = context.read<UserProvider>();
    final uid = userProvider.user?.id;

    if (uid != null) {
      try {
        await DatabaseService().updateUser(uid, {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'user_bio': _bioController.text.trim(),
        });
        await userProvider.fetchUser(uid);
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating profile: $e")),
          );
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  // 🟢 1. CONFIRMATION DIALOG
  void _confirmSkillReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Skills?"),
        content: const Text(
          "This will reset your current skills and allow you to select them again from scratch.\n\nDo you want to continue?",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _resetAndNavigateSkills(); // Proceed
            },
            child: const Text("Yes, Update", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🟢 2. LOGIC: WIPE ALL SKILLS -> GO TO START OF FLOW
  Future<void> _resetAndNavigateSkills() async {
    final uid = context.read<UserProvider>().user?.id;
    if (uid == null) return;

    setState(() => _isLoadingSkills = true);

    try {
      // Clear ALL skills (no type specified)
      await DatabaseService().clearUserSkills(uid);

      if (!mounted) return;

      // Navigate to the start of the skill onboarding flow
      // This is the Teaching Skills screen, which usually leads to Learning Skills next
      Navigator.pushNamed(context, '/onboarding_current'); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error resetting skills: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoadingSkills = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), 
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingSkills 
        ? const Center(child: CircularProgressIndicator(color: Colors.black)) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("PERSONAL INFORMATION"),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                _buildSectionHeader("SKILLS"),
                const SizedBox(height: 12),

                // 🟢 SINGLE BUTTON: Update Skills
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ListTile(
                    onTap: _confirmSkillReset,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05), // Light grey bg
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.layers_rounded, color: Colors.black, size: 22),
                    ),
                    title: const Text(
                      "Update Skills",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFC7C7CC)),
                  ),
                ),

                const SizedBox(height: 40),
                
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: "SAVE CHANGES",
                        onPressed: _saveProfile,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF86868B),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}