import 'package:flutter/material.dart';
import 'package:skillsync/widgets/bottom_nav.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/primary_button.dart';
import 'package:skillsync/widgets/rating_row.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apple F5F5F7
      appBar: const AppAppBar(title: 'Match Found', showBack: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Keeps content centered and compact
            children: [
              // 🟦 MODERN MATCH CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⭐ Header: Rating + Info (FIXED ROUTE)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const RatingRow(rating: 4),
                        IconButton(
                          icon: Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.secondary,
                          ),
                          // 🟢 FIXED: Takes you to the public profile screen
                          onPressed: () => Navigator.pushNamed(context, '/profile'), 
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 👤 User Identity
                    Text(
                      'Sarah Jenkins',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '98% Compatibility',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 📊 Skills Exchange Interface
                    Row(
                      children: [
                        _buildHeaderLabel('TEACHES'),
                        _buildHeaderLabel('LEARNS'),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Color(0xFFF5F5F7), thickness: 1.5),
                    ),

                    // Compact Skill rows
                    const _CompactSkillRow(left: 'Flutter UI', right: 'Python'),
                    const _CompactSkillRow(left: 'Firebase', right: 'Algorithms'),
                    const _CompactSkillRow(left: 'Dart Logic', right: 'FastAPI'),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ✅ ACTION BUTTONS
              PrimaryButton(
                label: 'ACCEPT MATCH',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
              ),

              const SizedBox(height: 8),

              // Decline is styled as a "Secondary" action (Text Button) to reduce clutter
              TextButton(
                onPressed: () {
                  // Logic to skip/find next
                },
                child: Text(
                  'NOT RIGHT NOW',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 2, // Highlight Explore/Match
        onTap: (index) {
          if (index == 2) return;
          final routes = ['/home', '/notifications', '/explore', '/community', '/user_profile'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  Widget _buildHeaderLabel(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF86868B),
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// 📄 Optimized compact row for better "Above the Fold" fit
class _CompactSkillRow extends StatelessWidget {
  final String left;
  final String right;

  const _CompactSkillRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.black12),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}