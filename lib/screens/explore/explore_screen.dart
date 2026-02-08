import 'package:flutter/material.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> categories = const [
    'Flutter',
    'Firebase',
    'UI/UX',
    'Python',
    'React',
    'Java',
    'Dart',
    'Machine Learning',
    'Blockchain',
    'Game Dev',
  ];

  final List<String> tags = const ['For You', 'Trending', 'All Categories'];
  int selectedTagIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apple Light Gray
      appBar: const AppAppBar(title: 'Explore', showBack: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            
            // 🏷 Filter Tags (Apple Capsule Style)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  tags.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _TagChip(
                      label: tags[index],
                      isActive: selectedTagIndex == index,
                      onTap: () => setState(() => selectedTagIndex = index),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🧱 Categories Grid (Apple Card Style)
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.2, // Tighter ratio for better spacing
                ),
                itemBuilder: (context, index) {
                  return _CategoryButton(label: categories[index]);
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          final routes = ['/home', '/notifications', '/explore', '/community', '/user_profile'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}

// 🧩 Modern Category Card
class _CategoryButton extends StatelessWidget {
  final String label;

  const _CategoryButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface, // Pure White
        borderRadius: BorderRadius.circular(16), // Consistent Squircle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.primary, // Deep Slate
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🏷 Capsule Tag Toggle
class _TagChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(30), // Capsule shape
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
          border: isActive 
            ? null 
            : Border.all(color: colorScheme.outline.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}