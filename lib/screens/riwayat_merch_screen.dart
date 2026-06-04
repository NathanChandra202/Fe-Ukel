import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// screen riwayat pesanan merch siswa - tampil kode ambil di koperasi
class RiwayatMerchScreen extends StatefulWidget {
  const RiwayatMerchScreen({super.key});

  @override
  State<RiwayatMerchScreen> createState() => _RiwayatMerchScreenState();
}

class _RiwayatMerchScreenState extends State<RiwayatMerchScreen> {
  List<dynamic> _pesananList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getRiwayatMerch();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pesanan Merch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _pesananList.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pesananList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _pesananCard(_pesananList[index]),
                    ),
            ),
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
          const SizedBox(height: 8),
          Text('Tukar poin kamu di Toko Merch!', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _pesananCard(Map<String, dynamic> pesanan) {
    final merch = pesanan['merch'] ?? {};
    final namaMerch = merch['nama'] ?? 'Barang';
    final jumlah = pesanan['jumlah'] ?? 1;
    final totalPoin = pesanan['total_poin'] ?? 0;
    final status = pesanan['status'] ?? 'pending';
    final kodeAmbil = pesanan['kode_ambil'] ?? '-';
    final catatan = pesanan['catatan'] ?? '';
    final sudahDiambil = status == 'sudah_diambil';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor(status),
          width: status == 'siap_ambil' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // header card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    namaMerch,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                _statusBadge(status),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // jumlah & poin
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text('$jumlah barang', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.stars_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('$totalPoin poin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),

                // catatan (kalau ada)
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Catatan: $catatan', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic)),
                ],

                const SizedBox(height: 12),

                // kode ambil - ditampilkan selama belum sudah_diambil
                if (!sudahDiambil) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: status == 'siap_ambil' ? AppColors.successLight : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: status == 'siap_ambil' ? AppColors.success : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_rounded,
                              size: 16,
                              color: status == 'siap_ambil' ? AppColors.success : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status == 'siap_ambil' ? 'Barang siap! Tunjukkan kode ini:' : 'Kode Ambil Koperasi:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: status == 'siap_ambil' ? AppColors.success : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: kodeAmbil));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kode disalin ke clipboard!')),
                            );
                          },
                          child: Text(
                            kodeAmbil,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: status == 'siap_ambil' ? AppColors.success : AppColors.primary,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tap untuk copy',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // kalau sudah diambil, tampil info selesai
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.textHint),
                        const SizedBox(width: 8),
                        Text(
                          'Barang sudah diambil',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // warna border berdasarkan status
  Color _borderColor(String status) {
    switch (status) {
      case 'siap_ambil':    return AppColors.success;
      case 'sudah_diambil': return AppColors.border;
      case 'dibatalkan':    return AppColors.error;
      default:              return AppColors.border;
    }
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'pending':
        bg = AppColors.warningLight; fg = AppColors.warning; label = 'Pending';
        break;
      case 'siap_ambil':
        bg = AppColors.successLight; fg = AppColors.success; label = '✅ Siap Diambil';
        break;
      case 'sudah_diambil':
        bg = AppColors.border; fg = AppColors.textSecondary; label = 'Selesai';
        break;
      case 'dibatalkan':
        bg = AppColors.errorLight; fg = AppColors.error; label = 'Dibatalkan';
        break;
      default:
        bg = AppColors.border; fg = AppColors.textSecondary; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
