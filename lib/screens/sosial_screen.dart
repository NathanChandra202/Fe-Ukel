import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class SosialScreen extends StatefulWidget {
  const SosialScreen({super.key});

  @override
  State<SosialScreen> createState() => _SosialScreenState();
}

class _SosialScreenState extends State<SosialScreen> {
  List _riwayat = [];
  bool _loading = true;
  File? _foto;
  final _deskripsiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // narik history aksi sosial user
  Future<void> _loadRiwayat() async {
    try {
      final res = await ApiService.getRiwayatSosial();
      if (res['data'] != null && mounted) {
        setState(() => _riwayat = res['data']);
      }
    } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  // milih foto dari hp
  Future<void> _pilihFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _foto = File(pickedFile.path));
    }
  }

  // upload foto ke server buat dapetin poin
  Future<void> _upload() async {
    if (_foto == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.uploadAksiSosial(deskripsi: _deskripsiCtrl.text, foto: _foto!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Berhasil')));
      _foto = null;
      _deskripsiCtrl.clear();
      _loadRiwayat();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aksi Sosial')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Kirim bukti aksi sosial lu (misal buang sampah) buat dapet poin gratis!', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _deskripsiCtrl, decoration: const InputDecoration(labelText: 'Deskripsi Kegiatan')),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pilihFoto,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Foto'),
                  ),
                  const SizedBox(width: 10),
                  if (_foto != null) const Text('Foto udah dipilih ✓', style: TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _foto == null ? null : _upload,
                child: const Text('Upload & Dapatkan Poin'),
              ),
              const Divider(height: 40),
              const Text('Riwayat Sosial Lu', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._riwayat.map((r) => ListTile(
                title: Text(r['deskripsi'] ?? ''),
                subtitle: Text('Status: ${r['status']}'),
                trailing: Text('+${r['poin_diberikan']} Poin', style: const TextStyle(color: Colors.green)),
              ))
            ],
          ),
    );
  }
}
