import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer decoration for the shadow and the Apple "Studio White" background
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5), // Shadow moves upwards
          ),
        ],
      ),
      child: ClipRRect(
        // Clipping the bar so the background color doesn't bleed past the corners
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0, // Remove default shadow to use the Container's shadow
          
          // Apple Palette Colors
          selectedItemColor: const Color(0xFF1D1D1F),   // Deep Slate (Active)
          unselectedItemColor: const Color(0xFF86868B), // Soft Gray (Inactive)
          
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 12,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, 
            fontSize: 12,
          ),
          
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts', // Renamed to Alerts for a cleaner look
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                //child: Icon(Icons.explore_rounded),
                child: Icon(Icons.swipe_rounded), 
              ),
              label: 'Match',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.groups_rounded),
              ),
              label: 'Social', // Renamed for a shorter label
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}