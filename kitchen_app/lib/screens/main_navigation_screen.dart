import 'package:flutter/material.dart';
import 'kitchen_screen.dart';
import 'kitchen_inventory_screen.dart';
import 'login_screen.dart'; // Tilføj import til login screen

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const KitchenScreen(),
    const KitchenInventoryScreen(),
  ];

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Log ud',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Er du sikker på at du vil logge ud?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuller',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A0D12),
              ),
              child: const Text('Log ud'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Ordrer' : 'Lager & Retter',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3A0D12),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Log ud',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF3A0D12),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Ordrer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Lager & Retter',
          ),
        ],
      ),
    );
  }
}