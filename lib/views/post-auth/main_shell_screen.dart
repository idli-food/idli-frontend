import 'package:flutter/material.dart';
import '../../widgets/app_nav_bar.dart';
import 'feed_screen.dart';
import 'explore_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';
import 'create_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  // App-level tab indices: 0=Home, 1=Explore, 2=Create(+), 3=Saved, 4=Profile
  int _selectedIndex = 0;

  // Screens for indices 0,1,3,4 (index 2 = Create, handled as push)
  static const List<Widget> _screens = [
    FeedScreen(),
    ExploreScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  void _onTabChange(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateScreen()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Map app index to screen index (skip slot 2)
    final screenIndex = _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: screenIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}
