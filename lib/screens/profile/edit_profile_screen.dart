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

  Future<void> _saveProfile(bool isFirstTime) async {
    // Dismiss keyboard to ensure screen reader focus isn't trapped
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user != null) {
      try {
        await DatabaseService().updateUser(user.id, {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'user_bio': _bioController.text.trim(),
          'is_onboarded': true,
        });

        userProvider.updateLocalUser(user.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          userBio: _bioController.text.trim(),
          isOnboarded: true,
        ));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _confirmSkillReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              Navigator.pop(ctx);
              _resetAndNavigateSkills();
            },
            child: const Text(
              "Yes, Update",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(isFirstTime ? "Final Step" : "Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isFirstTime
            ? const SizedBox.shrink()
            : Semantics(
                label: "Close",
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
      ),
      body: SafeArea(
        child: _isLoadingSkills
            ? Semantics(
                label: "Resetting skills",
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              )
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
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.black),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                hintText: 'Enter your first name',
                              ),
                              validator: (v) => v!.isEmpty ? "Enter your first name" : null,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.black),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.familyName],
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                hintText: 'Enter your last name',
                              ),
                              validator: (v) => v!.isEmpty ? "Enter your last name" : null,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _bioController,
                              style: const TextStyle(color: Colors.black),
                              maxLines: 3,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                hintText: 'Tell us a bit about yourself',
                                alignLabelWithHint: true,
                              ),
                              validator: (v) => v!.length < 10
                                  ? "Write at least a sentence about yourself"
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      if (!isFirstTime) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader("SKILLS"),
                        const SizedBox(height: 12),
                        
                        // Merge Semantics to make the entire tile a single clickable button
                        MergeSemantics(
                          child: Semantics(
                            button: true,
                            label: "Update Skills",
                            hint: "Resets current skills and starts selection over",
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: _confirmSkillReset,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  // Exclude icon from individual reading
                                  child: ExcludeSemantics(
                                    child: const Icon(
                                      Icons.layers_rounded,
                                      color: Colors.black,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                title: const Text(
                                  "Update Skills",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                                trailing: ExcludeSemantics(
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Color(0xFFC7C7CC),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      _isSaving
                          ? Semantics(
                              label: "Saving profile changes",
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.black),
                              ),
                            )
                          : PrimaryButton(
                              label: isFirstTime ? "FINISH SETUP" : "SAVE CHANGES",
                              onPressed: () => _saveProfile(isFirstTime),
                              height: 48, // Ensure minimum touch target
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    return Semantics(
      label: "Step 3 of 3",
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8ED),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          'STEP 3 OF 3',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: colorScheme.secondary,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      // Mark as Header for easier navigation
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF86868B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}