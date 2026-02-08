import 'package:flutter/material.dart';

class SkillGrid extends StatelessWidget {
  final List<String> skills;

  const SkillGrid({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: skills.map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          skill,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      )).toList(),
    );
  }
}