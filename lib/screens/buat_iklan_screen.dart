import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BuatIklanScreen extends StatefulWidget {
  const BuatIklanScreen({super.key});

  @override
  State<BuatIklanScreen> createState() => _BuatIklanScreenState();
}

class _BuatIklanScreenState extends State<BuatIklanScreen> {
  final _judulCtrl = TextEditingController();
  final _kategoriCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  bool _loading = false;

  // submit buat bikin iklan jasa baru
  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.buatIklan(
        judul: _judulCtrl.text,
        kategori: _kategoriCtrl.text,
        deskripsi: _deskripsiCtrl.text,
        hargaPoin: int.tryParse(_hargaCtrl.text) ?? 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Berhasil')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Iklan Jasa')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _judulCtrl, decoration: const InputDecoration(labelText: 'Judul Jasa')),
          TextField(controller: _kategoriCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
          TextField(controller: _deskripsiCtrl, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 3),
          TextField(controller: _hargaCtrl, decoration: const InputDecoration(labelText: 'Harga Poin'), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _loading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(onPressed: _submit, child: const Text('Posting Jasa')),
        ],
      ),
    );
  }
}
