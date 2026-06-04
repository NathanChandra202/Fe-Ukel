import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/json_utils.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  // bikin state-nya
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List _riwayat = [];
  bool _loading = true;

  // load riwayat transaksi pas tab dibuka
  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // fetch riwayat poin masuk/keluar
  Future<void> _loadRiwayat() async {
    try {
      final res = await ApiService.getRiwayat();
      if (mounted) {
        setState(() => _riwayat = List.from(res['riwayat'] ?? []));
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal memuat riwayat transaksi.');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  // penyedia tandain jasa udah kelar
  Future<void> _selesaikan(int id) async {
    try {
      final res = await ApiService.selesaikanJasa(id);
      if (!mounted) return;
      await ApiService.perbaruiSaldoLokal();
      if (!mounted) return;
      AppSnackbar.sukses(
        context,
        res['pesan']?.toString() ?? 'Jasa ditandai selesai.',
      );
      _loadRiwayat();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal menyelesaikan jasa.');
      }
    }
  }

  // list transaksi jasa
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() => _loading = true);
                await _loadRiwayat();
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Riwayat Transaksi',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_riwayat.length} transaksi ditemukan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Empty state
                  if (_riwayat.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada riwayat',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mulai bantu teman dan dapatkan poin!',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Riwayat list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final r = _riwayat[i];
                        // cek arah transaksinya, keluar atau masuk
                        final isKeluar = r['arah_poin'] == 'keluar';
                        final status = r['status'] as String? ?? '';
                        final bool canComplete =
                            status == 'berjalan' && !isKeluar;

                        return _RiwayatCard(
                          transaksi: r,
                          isKeluar: isKeluar,
                          status: status,
                          canComplete: canComplete,
                          onComplete: () => _selesaikan(
                            JsonUtils.asInt(r['id'], label: 'ID transaksi'),
                          ),
                        );
                      },
                      childCount: _riwayat.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }
}

// kartu satu baris riwayat transaksi
class _RiwayatCard extends StatelessWidget {
  final Map transaksi;
  final bool isKeluar;
  final String status;
  final bool canComplete;
  final VoidCallback onComplete;

  const _RiwayatCard({
    required this.transaksi,
    required this.isKeluar,
    required this.status,
    required this.canComplete,
    required this.onComplete,
  });

  // warna teks status
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'selesai':
        return AppColors.success;
      case 'berjalan':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  // warna background chip status
  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'selesai':
        return AppColors.successLight;
      case 'berjalan':
        return AppColors.warningLight;
      default:
        return AppColors.surfaceVariant;
    }
  }

  // label status bahasa indo
  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'selesai':
        return 'Selesai';
      case 'berjalan':
        return 'Berjalan';
      default:
        return s;
    }
  }

  // gambar kartu transaksi
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Direction icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isKeluar ? AppColors.errorLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isKeluar
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isKeluar ? AppColors.error : AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaksi['nama_jasa'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isKeluar ? 'Kamu minta jasa' : 'Kamu beri jasa',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Points display
              Text(
                '${isKeluar ? '-' : '+'}${transaksi['jumlah_poin']}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isKeluar ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),
              const Spacer(),
              if (canComplete)
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'Selesaikan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
