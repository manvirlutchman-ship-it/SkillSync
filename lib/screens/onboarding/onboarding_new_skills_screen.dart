import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/models/skill_model.dart'; // 🟢 Added
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/primary_button.dart';

import '../../widgets/scalable_text.dart';

class OnboardingNewSkillsScreen extends StatefulWidget {
  const OnboardingNewSkillsScreen({super.key});

  @override
  State<OnboardingNewSkillsScreen> createState() => _OnboardingNewSkillsScreenState();
}

class _OnboardingNewSkillsScreenState extends State<OnboardingNewSkillsScreen> {
  final DatabaseService _dbService = DatabaseService();

  // 🟢 State Variables for Dynamic Data
  List<SkillModel> _allSkills = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  final Set<String> _selectedSkillIds = {}; 

  bool _isPageLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSkillsFromFirestore();
  }

  // 🟢 Fetch real data from your 'Skill' collection
  Future<void> _loadSkillsFromFirestore() async {
    final skills = await _dbService.getGlobalSkills();
    
    // Extract unique categories dynamically
    final dynamicCategories = skills.map((s) => s.skillCategory).toSet().toList();
    dynamicCategories.sort();

    if (mounted) {
      setState(() {
        _allSkills = skills;
        _categories = ['All', ...dynamicCategories];
        _isPageLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter logic for categories
    final filteredSkills = _selectedCategory == 'All'
        ? _allSkills
        : _allSkills.where((s) => s.skillCategory == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isPageLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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

                ScalableText(
                  'What do you want to learn?',
                  baseFontSize: 26,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 8),

                ScalableText(
                  'Select the skills you want to acquire.',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // 🏷 Category Scroll (Dynamic)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: _buildCategoryChip(cat, isSelected, colorScheme),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 🧱 Real Skills Grid
                Expanded(
                  child: filteredSkills.isEmpty 
                    ? const Center(child: ScalableText("No skills found in this category.", baseFontSize: 14))
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: filteredSkills.length,
                        itemBuilder: (context, index) {
                          final skill = filteredSkills[index];
                          final isSelected = _selectedSkillIds.contains(skill.id);
                          return _buildSkillCard(skill, isSelected, colorScheme);
                        },
                      ),
                ),

                const SizedBox(height: 20),

                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'CONFIRM (${_selectedSkillIds.length})',
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
    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: ScalableText("Please select at least one skill you want to learn", baseFontSize: 14)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        // Save selected skill IDs as 'learning'
        await DatabaseService().saveUserSkills(
          userId: userId,
          skills: _selectedSkillIds.toList(),
          type: "learning",
        );

        if (mounted) {
          // Navigate to Step 3: Edit Profile Setup
          Navigator.pushNamed(context, '/edit_profile');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: ScalableText("Error saving interests: $e", baseFontSize: 14)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- UI HELPERS ---

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ScalableText(
        'STEP 2 OF 3', // 🟢 Updated to 3
        baseFontSize: 10,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colorScheme.secondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ScalableText(
        label.toUpperCase(),
        baseFontSize: 11,
        style: TextStyle(
          color: isSelected ? Colors.white : colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSkillCard(SkillModel skill, bool isSelected, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(
        () => isSelected ? _selectedSkillIds.remove(skill.id) : _selectedSkillIds.add(skill.id),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.white,
          border: Border.all(
            color: isSelected ? colorScheme.primary : const Color(0xFFE8E8ED),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ScalableText(
          skill.skillName,
          baseFontSize: 13,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : colorScheme.primary,
          ),
        ),
      ),
    );
  }
}