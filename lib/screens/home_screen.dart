import 'package:flutter/material.dart';
import 'jasa_screen.dart';
import 'sosial_screen.dart';
import 'leaderboard_screen.dart';
import 'profil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final List<Widget> _pages = [
    const JasaScreen(),
    const SosialScreen(),
    const LeaderboardScreen(),
    const ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jasa'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Sosial'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Peringkat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
