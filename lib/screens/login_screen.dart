import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  // fungsi buat login
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.login(email: _emailCtrl.text, password: _passCtrl.text);
      if (res['token'] != null) {
        await ApiService.simpanToken(res['token']);
        await ApiService.simpanDataSiswa(res['siswa']);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Gagal login')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            _loading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: const Text('Masuk')),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Belum punya akun? Daftar!'),
            )
          ],
        ),
      ),
    );
  }
}
