import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/buat_iklan_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'theme/app_theme.dart';

// fungsi utama buat jalanin flutter
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kontrib ID',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/buat_iklan': (context) => const BuatIklanScreen(),
        '/riwayat': (context) => const RiwayatScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}
