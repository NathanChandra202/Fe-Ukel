import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// screen detail merch + form beli (ambil di koperasi sekolah)
class DetailMerchScreen extends StatefulWidget {
  const DetailMerchScreen({super.key});

  @override
  State<DetailMerchScreen> createState() => _DetailMerchScreenState();
}

class _DetailMerchScreenState extends State<DetailMerchScreen> {
  Map<String, dynamic>? _merch;
  bool _loading = true;
  int _saldoPoin = 0;
  int _jumlah = 1;
  final _catatanController = TextEditingController();
  bool _sedangBeli = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final merchId = ModalRoute.of(context)!.settings.arguments as int;
    _loadDetail(merchId);
  }

  Future<void> _loadDetail(int id) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _saldoPoin = prefs.getInt('saldo_poin') ?? 0;
      final result = await ApiService.getDetailMerch(id);
      setState(() {
        _merch = result['data'];
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

  // proses beli merch - setelah sukses tampilkan kode ambil
  Future<void> _beliMerch() async {
    if (_merch == null || _sedangBeli) return;

    final harga = _merch!['harga_poin'] ?? 0;
    final total = harga * _jumlah;

    if (total > _saldoPoin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin lo ga cukup bro')),
      );
      return;
    }

    setState(() => _sedangBeli = true);
    try {
      final result = await ApiService.beliMerch(
        merchId: _merch!['id'],
        jumlah: _jumlah,
        catatan: _catatanController.text.trim(),
      );

      await ApiService.perbaruiSaldoLokal();

      if (!mounted) return;

      // tampilkan popup kode ambil
      final kode = result['kode_ambil'] ?? '-';
      await _showKodeAmbil(kode, total);

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.pesanUntukUser(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangBeli = false);
    }
  }

  // popup kode ambil - siswa tunjukin ini ke koperasi
  Future<void> _showKodeAmbil(String kode, int totalPoin) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              'Tukar Poin Berhasil!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tunjukkan kode ini ke petugas koperasi sekolah untuk ambil barang:',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // kotak kode yang gede & mencolok
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: kode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode disalin!')),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      kode,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          'tap untuk copy',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // info poin dipotong
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    '$totalPoin poin telah dipotong dari saldo kamu',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kode ini juga tersimpan di Riwayat Pesanan Merch kamu.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Oke, Siap Ambil!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Merch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _merch == null
              ? const Center(child: Text('Merch tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fotoMerch(),
                      const SizedBox(height: 16),
                      _infoMerch(),
                      const SizedBox(height: 16),
                      // banner koperasi sekolah
                      _bannerKoperasi(),
                      const SizedBox(height: 20),
                      _formBeli(),
                      const SizedBox(height: 24),
                      _tombolBeli(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  // foto merch
  Widget _fotoMerch() {
    final foto = _merch!['foto_url'] ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: foto.isNotEmpty
          ? Image.network(
              foto,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderImage(),
            )
          : _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.image_outlined, size: 60, color: AppColors.textHint),
    );
  }

  // info nama, harga, stok, deskripsi
  Widget _infoMerch() {
    final nama = _merch!['nama'] ?? 'Barang';
    final harga = _merch!['harga_poin'] ?? 0;
    final stok = _merch!['stok'] ?? 0;
    final deskripsi = _merch!['deskripsi'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nama, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.stars_rounded, size: 22, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '$harga poin',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Stok: $stok',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ),
          ],
        ),
        if (deskripsi.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(deskripsi, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        ],
      ],
    );
  }

  // banner info koperasi (ga perlu alamat, ambil di koperasi aja)
  Widget _bannerKoperasi() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_rounded, color: Color(0xFF3B82F6), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ambil di Koperasi Sekolah',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Setelah tukar poin, kamu akan dapat kode unik. Tunjukkan ke petugas koperasi untuk ambil barang.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // form beli (jumlah + catatan aja, ga ada alamat)
  Widget _formBeli() {
    final harga = _merch!['harga_poin'] ?? 0;
    final stok = _merch!['stok'] ?? 0;
    final total = harga * _jumlah;
    final cukup = _saldoPoin >= total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jumlah', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            // tombol kurang
            IconButton(
              onPressed: _jumlah > 1 ? () => setState(() => _jumlah--) : null,
              icon: Icon(Icons.remove_circle_rounded,
                color: _jumlah > 1 ? AppColors.primary : AppColors.textHint, size: 32),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$_jumlah', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            // tombol tambah
            IconButton(
              onPressed: _jumlah < stok ? () => setState(() => _jumlah++) : null,
              icon: Icon(Icons.add_circle_rounded,
                color: _jumlah < stok ? AppColors.primary : AppColors.textHint, size: 32),
            ),
            const Spacer(),
            // total + saldo
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total: $total poin',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  'Saldo: $_saldoPoin poin',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cukup ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Catatan (opsional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _catatanController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Contoh: minta yang warna biru',
          ),
        ),
      ],
    );
  }

  // tombol beli
  Widget _tombolBeli() {
    final harga = _merch!['harga_poin'] ?? 0;
    final total = harga * _jumlah;
    final cukup = _saldoPoin >= total;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (cukup && !_sedangBeli) ? _beliMerch : null,
        icon: _sedangBeli
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.stars_rounded),
        label: Text(
          _sedangBeli ? 'Memproses...' : 'Tukar $total Poin',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cukup ? AppColors.primary : AppColors.textHint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
