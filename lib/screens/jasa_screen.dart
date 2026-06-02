import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/json_utils.dart';
import '../widgets/badge_poin.dart';
import 'detail_jasa_screen.dart';

class JasaScreen extends StatefulWidget {
  const JasaScreen({super.key});

  @override
  State<JasaScreen> createState() => _JasaScreenState();
}

class _JasaScreenState extends State<JasaScreen> {
  List _jasaList = [];
  bool _loading = true;
  String _namaSiswa = '';
  int _saldoPoin = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // narik semua data jasa yang ada
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _namaSiswa = prefs.getString('siswa_nama') ?? 'Siswa';
    _saldoPoin = prefs.getInt('saldo_poin') ?? 0;
    try {
      try {
        await ApiService.perbaruiSaldoLokal();
        final prefsBaru = await SharedPreferences.getInstance();
        _saldoPoin = prefsBaru.getInt('saldo_poin') ?? _saldoPoin;
      } catch (_) {}

      final res = await ApiService.getDaftarJasa();
      if (mounted) {
        setState(() => _jasaList = List.from(res['data'] ?? []));
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal memuat daftar jasa.');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _ambilJasa() async {
    setState(() => _loading = true);
    await _loadData();
  }

  String _firstWord(String name) {
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _ambilJasa,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4C3CE0), Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Halo, ${_firstWord(_namaSiswa)}! 👋',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Temukan jasa yang kamu butuhkan',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                  BadgePoin(poin: _saldoPoin, large: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Section title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Jasa',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_jasaList.length} tersedia',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Empty state
                  if (_jasaList.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada jasa nih',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Jadilah yang pertama posting!',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Jasa list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final j = _jasaList[i];
                        return _JasaCard(
                          jasa: j,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailJasaScreen(
                                      jasaId: JsonUtils.asInt(j['id'], label: 'ID jasa'),
                                    ),
                              ),
                            );
                            _ambilJasa();
                          },
                        );
                      },
                      childCount: _jasaList.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/buat_iklan');
          _ambilJasa();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Buat Iklan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}

class _JasaCard extends StatelessWidget {
  final Map jasa;
  final VoidCallback onTap;

  const _JasaCard({required this.jasa, required this.onTap});

  Color _getCategoryColor(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'akademik':
        return const Color(0xFF3B82F6);
      case 'non-akademik':
        return const Color(0xFFEC4899);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategori = jasa['kategori'] as String? ?? 'Umum';
    final catColor = _getCategoryColor(kategori);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.assignment_rounded,
                color: catColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jasa['judul'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jasa['nama_penyedia'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          kategori,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: catColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PoinChip(poin: jasa['harga_poin'] ?? 0),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
