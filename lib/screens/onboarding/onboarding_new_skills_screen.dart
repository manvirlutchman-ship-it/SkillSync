import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/primary_button.dart'; // Using the consistent button widget

class OnboardingNewSkillsScreen extends StatefulWidget {
  const OnboardingNewSkillsScreen({super.key});

  @override
  State<OnboardingNewSkillsScreen> createState() =>
      _OnboardingNewSkillsScreenState();
}

class _OnboardingNewSkillsScreenState extends State<OnboardingNewSkillsScreen> {
  final Set<String> _selectedSkills = {};
  bool _isLoading = false;

  final List<String> categories = [
    'Programming', 'Design', 'Marketing', 'Business', 'Languages'
  ];
  final List<String> skills = [
    'Flutter', 'React', 'UI Design', 'UX Research', 'Python',
    'Java', 'Public Speaking', 'Project Management'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apple Light Gray
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // Consistent soft corner
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(colorScheme),

                const SizedBox(height: 16),

                Text(
                  'What do you want to learn?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Select the skills you want to acquire.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                _buildSearchBar(colorScheme),

                const SizedBox(height: 20),

                // Categories (Apple Style Capsules)
                _buildCategoryList(colorScheme),

                const SizedBox(height: 20),

                // Skills Grid
                Expanded(child: _buildSkillsGrid(colorScheme)),

                const SizedBox(height: 20),

                // 🟢 Using PrimaryButton for consistency
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'CONFIRM (${_selectedSkills.length})',
                        onPressed: _handleConfirm,
                        height: 50,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC ---

  void _handleConfirm() async {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one skill you want to learn")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await DatabaseService().saveUserSkills(
          userId: userId,
          skills: _selectedSkills.toList(),
          type: "learning", // Correctly tagged for this screen
        );

        if (mounted) {
          // Final Step: Go to Home and clear navigation stack
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving interests: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI HELPER WIDGETS (Matching Step 1 exactly) ---

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'STEP 2 OF 2',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colorScheme.secondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return TextField(
      style: TextStyle(color: colorScheme.primary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search skills...',
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.secondary, size: 20),
        isDense: true,
      ),
    );
  }

  Widget _buildCategoryList(ColorScheme colorScheme) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            categories[index],
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsGrid(ColorScheme colorScheme) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final isSelected = _selectedSkills.contains(skill);
        return GestureDetector(
          onTap: () => setState(
            () => isSelected ? _selectedSkills.remove(skill) : _selectedSkills.add(skill),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.white,
              border: Border.all(
                color: isSelected ? colorScheme.primary : const Color(0xFFE8E8ED),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16), // Consistent Squircle
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
              ],
            ),
            child: Text(
              skill,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}