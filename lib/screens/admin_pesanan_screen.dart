import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// screen admin - kelola pesanan merch (sistem koperasi sekolah)
class AdminPesananScreen extends StatefulWidget {
  const AdminPesananScreen({super.key});

  @override
  State<AdminPesananScreen> createState() => _AdminPesananScreenState();
}

class _AdminPesananScreenState extends State<AdminPesananScreen> {
  List<dynamic> _pesananList = [];
  bool _loading = true;
  String _filterStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.adminGetPesanan();
      setState(() {
        _pesananList = result['data'] ?? [];
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

  List<dynamic> get _filteredList {
    if (_filterStatus == 'semua') return _pesananList;
    return _pesananList.where((p) => p['status'] == _filterStatus).toList();
  }

  // popup dialog pilih status baru
  void _updateStatus(Map<String, dynamic> pesanan) {
    // alur status: pending -> siap_ambil -> (konfirmasi kode) -> sudah_diambil
    const statusList = ['pending', 'siap_ambil', 'sudah_diambil', 'dibatalkan'];
    final statusLabel = {
      'pending':       'Pending - Belum diproses',
      'siap_ambil':    'Siap Ambil - Barang udah disiapkan',
      'sudah_diambil': 'Sudah Diambil - Selesai',
      'dibatalkan':    'Dibatalkan',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Status', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusList.map((status) {
            final isCurrent = pesanan['status'] == status;
            return ListTile(
              leading: Icon(
                isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isCurrent ? AppColors.primary : AppColors.textHint,
              ),
              title: Text(
                statusLabel[status] ?? status,
                style: GoogleFonts.inter(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              onTap: () async {
                if (isCurrent) { Navigator.pop(ctx); return; }
                Navigator.pop(ctx);
                try {
                  await ApiService.adminUpdateStatusPesanan(id: pesanan['id'], status: status);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status diupdate ke "$status"')),
                    );
                  }
                  _loadData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.pesanUntukUser(e))));
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // dialog input kode konfirmasi dari siswa
  void _showKonfirmasiKode() {
    final kodeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text('Konfirmasi Ambil Barang', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Minta siswa tunjukkan kode dari app mereka, lalu input di bawah:',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: kodeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 3),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'KOP-XXXXXX'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final kode = kodeCtrl.text.trim().toUpperCase();
              if (kode.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final result = await ApiService.adminKonfirmasiAmbil(kodeAmbil: kode);
                if (mounted) {
                  final data = result['data'] ?? {};
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text('Berhasil!', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.success)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Siswa', data['nama_siswa'] ?? '-'),
                          _infoRow('Barang', data['nama_merch'] ?? '-'),
                          _infoRow('Jumlah', '${data['jumlah'] ?? 1} pcs'),
                          _infoRow('Total Poin', '${data['total_poin'] ?? 0} poin'),
                        ],
                      ),
                      actions: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Selesai'),
                          ),
                        ),
                      ],
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.pesanUntukUser(e))));
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
          Text(': $value', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pesanan', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          // tombol konfirmasi kode ambil
          TextButton.icon(
            onPressed: _showKonfirmasiKode,
            icon: const Icon(Icons.qr_code_rounded, size: 20),
            label: Text('Konfirmasi', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredList.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _pesananCard(_filteredList[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // filter chip
  Widget _filterBar() {
    final filters = ['semua', 'pending', 'siap_ambil', 'sudah_diambil', 'dibatalkan'];
    final labels = {
      'semua': 'Semua', 'pending': 'Pending',
      'siap_ambil': 'Siap Ambil', 'sudah_diambil': 'Selesai', 'dibatalkan': 'Batal',
    };
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: filters.map((f) {
          final selected = _filterStatus == f;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                labels[f] ?? f,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // satu card pesanan
  Widget _pesananCard(Map<String, dynamic> pesanan) {
    final siswa = pesanan['siswa'] ?? {};
    final merch = pesanan['merch'] ?? {};
    final namaSiswa = siswa['nama'] ?? 'Siswa';
    final namaMerch = merch['nama'] ?? 'Barang';
    final jumlah = pesanan['jumlah'] ?? 1;
    final totalPoin = pesanan['total_poin'] ?? 0;
    final status = pesanan['status'] ?? 'pending';
    final kodeAmbil = pesanan['kode_ambil'] ?? '-';
    final catatan = pesanan['catatan'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'siap_ambil' ? AppColors.success : AppColors.border,
          width: status == 'siap_ambil' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // baris atas
          Row(
            children: [
              Expanded(
                child: Text(namaSiswa, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              _statusBadge(status),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _updateStatus(pesanan),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$namaMerch × $jumlah', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.stars_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('$totalPoin poin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              if (catatan.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text('📝 $catatan', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          // tampilkan kode ambil
          if (status != 'sudah_diambil') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Kode: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  Text(kodeAmbil, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.primary, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg; Color fg; String label;
    switch (status) {
      case 'pending':       bg = AppColors.warningLight; fg = AppColors.warning; label = 'Pending'; break;
      case 'siap_ambil':    bg = AppColors.successLight; fg = AppColors.success; label = 'Siap Ambil'; break;
      case 'sudah_diambil': bg = AppColors.border; fg = AppColors.textSecondary; label = 'Selesai'; break;
      case 'dibatalkan':    bg = AppColors.errorLight; fg = AppColors.error; label = 'Batal'; break;
      default:              bg = AppColors.border; fg = AppColors.textSecondary; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Belum ada pesanan', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
