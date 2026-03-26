import 'package:flutter/material.dart';
import 'package:todocart/screens/home_page.dart';
import 'package:todocart/screens/reminders_page.dart';

class AppNavigationPage extends StatefulWidget {
  const AppNavigationPage({super.key});

  @override
  State<AppNavigationPage> createState() => _AppNavigationPageState();
}

class _AppNavigationPageState extends State<AppNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomePage(), RemindersPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}
