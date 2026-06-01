import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController();
  bool _loading = false;

  // fungsi submit buat daftar
  Future<void> _daftar() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.register(
        nama: _namaCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        kelas: _kelasCtrl.text,
        jurusan: _jurusanCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Berhasil')));
        if (res['pesan'] == 'Berhasil daftar, silakan login!') {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          TextField(controller: _kelasCtrl, decoration: const InputDecoration(labelText: 'Kelas (Misal: 12)')),
          TextField(controller: _jurusanCtrl, decoration: const InputDecoration(labelText: 'Jurusan (Misal: RPL)')),
          const SizedBox(height: 20),
          _loading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(onPressed: _daftar, child: const Text('Daftar Sekarang')),
        ],
      ),
    );
  }
}
