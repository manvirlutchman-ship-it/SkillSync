import 'package:flutter/material.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // 🧩 Fake list of skill categories
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

  final List<String> tags = const ['For You', 'Trending', 'All'];
  int selectedTagIndex = 0; // only one active at a time

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppAppBar(title: 'Explore', showBack: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷 Tags
            Row(
              children: List.generate(
                tags.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TagChip(
                    label: tags[index],
                    isActive: selectedTagIndex == index,
                    onTap: () {
                      setState(() {
                        selectedTagIndex = index; // only this tag is active
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🧱 Categories grid
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,       // 2 per row
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,   // wide rectangle
                ),
                itemBuilder: (context, index) {
                  return _CategoryButton(label: categories[index]);
                },
              ),
            ),
          ],
        ),
      ),

      // 🔽 Bottom nav
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2, // Explore tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/notifications');
              break;
            case 2:
              // already here
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/community');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/user_profile');
              break;
          }
        },
      ),
    );
  }
}

// 🧩 Category button
class _CategoryButton extends StatelessWidget {
  final String label;

  const _CategoryButton({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // handle category tap here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade900, // dark grey
        foregroundColor: Colors.white,          // white text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black), // black outline
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// 🏷 Tag button (stateless, reflects parent state)
class _TagChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}