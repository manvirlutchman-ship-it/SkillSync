import 'package:flutter/material.dart';

class OnboardingCurrentSkillsScreen extends StatelessWidget {
  const OnboardingCurrentSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      'Programming',
      'Design',
      'Marketing',
      'Business',
      'Languages',
    ];

    final List<String> skills = [
      'Flutter',
      'React',
      'UI Design',
      'UX Research',
      'Python',
      'Java',
      'Public Speaking',
      'Project Management',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Step indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Step 1 of 2',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                ),

                const SizedBox(height: 16),

                /// Heading (same style intent as Login)
                const Text(
                  'Select the skills you have',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),

                const SizedBox(height: 16),

                /// Search bar + search button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.black,
                        ), // typed text
                        decoration: InputDecoration(
                          hintText: 'Search a skill',
                          hintStyle: const TextStyle(
                            color: Colors.black,
                          ), // placeholder
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Categories (horizontal scroll)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Chip(
                        label: Text(
                          categories[index],
                          style: const TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.grey.shade200,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                /// Skills grid (vertical scroll)
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 3,
                        ),
                    itemCount: skills.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skills[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// Confirm button (NOT scrollable, separate from list)
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/onboarding_new');
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
