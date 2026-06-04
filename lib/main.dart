import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/buat_iklan_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/merch_screen.dart';
import 'screens/detail_merch_screen.dart';
import 'screens/riwayat_merch_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_merch_screen.dart';
import 'screens/admin_pesanan_screen.dart';
import 'screens/admin_sosial_screen.dart';
import 'theme/app_theme.dart';

// entry point app, jalanin flutter dari sini
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

  // atur route & tema global app
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
        '/merch': (context) => const MerchScreen(),
        '/detail-merch': (context) => const DetailMerchScreen(),
        '/riwayat-merch': (context) => const RiwayatMerchScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-merch': (context) => const AdminMerchScreen(),
        '/admin-pesanan': (context) => const AdminPesananScreen(),
        '/admin-sosial': (context) => const AdminSosialScreen(),
      },
    );
  }
}
