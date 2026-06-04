import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// screen admin - kelola merch (lihat, tambah, edit, hapus)
class AdminMerchScreen extends StatefulWidget {
  const AdminMerchScreen({super.key});

  @override
  State<AdminMerchScreen> createState() => _AdminMerchScreenState();
}

class _AdminMerchScreenState extends State<AdminMerchScreen> {
  List<dynamic> _merchList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ambil list merch dari api (semua merch, bukan cuma yang tersedia)
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getDaftarMerch();
      setState(() {
        _merchList = result['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.pesanUntukUser(e))),
      );
    }
  }

  // dialog form tambah / edit merch
  void _showForm({Map<String, dynamic>? merch}) {
    final isEdit = merch != null;
    final namaCtrl = TextEditingController(text: merch?['nama'] ?? '');
    final deskCtrl = TextEditingController(text: merch?['deskripsi'] ?? '');
    final fotoCtrl = TextEditingController(text: merch?['foto_url'] ?? '');
    final hargaCtrl = TextEditingController(text: '${merch?['harga_poin'] ?? ''}');
    final stokCtrl = TextEditingController(text: '${merch?['stok'] ?? ''}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Merch' : 'Tambah Merch',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(namaCtrl, 'Nama Barang'),
              const SizedBox(height: 12),
              _field(deskCtrl, 'Deskripsi', maxLines: 3),
              const SizedBox(height: 12),
              _field(fotoCtrl, 'URL Foto (opsional)'),
              const SizedBox(height: 12),
              _field(hargaCtrl, 'Harga Poin', isNumber: true),
              const SizedBox(height: 12),
              _field(stokCtrl, 'Stok', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // validasi input
              if (namaCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama barang wajib diisi')),
                );
                return;
              }
              final harga = int.tryParse(hargaCtrl.text) ?? 0;
              final stok = int.tryParse(stokCtrl.text) ?? 0;
              if (harga <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harga poin harus lebih dari 0')),
                );
                return;
              }

              Navigator.pop(ctx);

              try {
                if (isEdit) {
                  // update merch yang udah ada
                  await ApiService.adminUpdateMerch(
                    id: merch!['id'],
                    nama: namaCtrl.text.trim(),
                    deskripsi: deskCtrl.text.trim(),
                    fotoUrl: fotoCtrl.text.trim(),
                    hargaPoin: harga,
                    stok: stok,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Merch berhasil diupdate')),
                    );
                  }
                } else {
                  // bikin merch baru
                  await ApiService.adminBuatMerch(
                    nama: namaCtrl.text.trim(),
                    deskripsi: deskCtrl.text.trim(),
                    fotoUrl: fotoCtrl.text.trim(),
                    hargaPoin: harga,
                    stok: stok,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Merch berhasil ditambahkan')),
                    );
                  }
                }
                _loadData(); // refresh list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ApiService.pesanUntukUser(e))),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  // dialog konfirmasi hapus merch
  void _hapusMerch(Map<String, dynamic> merch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Merch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin mau hapus "${merch['nama']}"?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.adminHapusMerch(merch['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Merch berhasil dihapus')),
                  );
                }
                _loadData(); // refresh list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ApiService.pesanUntukUser(e))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Merch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _merchList.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _merchList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final merch = _merchList[index];
                        return _merchCard(merch);
                      },
                    ),
            ),
    );
  }

  // satu baris merch
  Widget _merchCard(Map<String, dynamic> merch) {
    final nama = merch['nama'] ?? 'Barang';
    final harga = merch['harga_poin'] ?? 0;
    final stok = merch['stok'] ?? 0;
    final status = merch['status'] ?? 'tersedia';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // icon barang
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // info barang
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$harga poin',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Stok: $stok',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    // badge status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'tersedia' ? AppColors.successLight : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status == 'tersedia' ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // tombol edit & hapus
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: () => _showForm(merch: merch),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => _hapusMerch(merch),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // empty state
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Belum ada merch',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk tambah merch',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // helper bikin input field
  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }
}
