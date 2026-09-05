import 'package:flutter/material.dart';
import '../../widgets/app_nav_bar.dart';
import 'feed_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'create_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  // App-level tab indices: 0=Home, 1=Explore, 2=Create(+), 3=Profile
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    const FeedScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];

  Future<void> _onTabChange(int index) async {
    if (index == 2) {
      final posted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CreateScreen()),
      );
      if (posted == true && mounted) {
        setState(() => _selectedIndex = 0);
      }
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
