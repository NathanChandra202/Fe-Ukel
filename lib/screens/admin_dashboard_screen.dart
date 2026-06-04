import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// dashboard admin - ini halaman utama admin, ga ada tampilan siswa sama sekali
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String _namaAdmin = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ambil statistik + nama admin dari local storage
  Future<void> _loadAll() async {
    setState(() => _loading = true);

    // ambil nama admin dari shared prefs
    final prefs = await SharedPreferences.getInstance();
    _namaAdmin = prefs.getString('siswa_nama') ?? 'Admin';

    try {
      final result = await ApiService.adminGetStats();
      setState(() {
        _stats = result['data'];
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

  // logout admin
  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin mau keluar dari akun admin?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.hapusToken(); // hapus token & data lokal
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            // header admin dengan gradient
            SliverToBoxAdapter(child: _header()),

            // statistik
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  'Statistik',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _loading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ))
                    : _statsSection(),
              ),
            ),

            // menu kelola
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Kelola Sistem',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _menuCard(
                      label: 'Kelola Merch',
                      subtitle: 'Tambah, edit, hapus barang',
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.primary,
                      route: '/admin-merch',
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      label: 'Kelola Pesanan',
                      subtitle: 'Proses & update status pesanan',
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.accent,
                      route: '/admin-pesanan',
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      label: 'Kelola Aksi Sosial',
                      subtitle: 'Approve / reject kiriman siswa',
                      icon: Icons.favorite_outline_rounded,
                      iconColor: AppColors.error,
                      route: '/admin-sosial',
                    ),
                  ],
                ),
              ),
            ),

            // tombol logout
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // header gradient dengan nama admin
  Widget _header() {
    final initial = _namaAdmin.isNotEmpty ? _namaAdmin[0].toUpperCase() : 'A';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3730A3), Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Row(
            children: [
              // avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // nama & role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaAdmin,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⚡ Administrator',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // section 4 stat card
  Widget _statsSection() {
    if (_stats == null) return const SizedBox.shrink();
    final totalSiswa = _stats!['total_siswa'] ?? 0;
    final totalPoin = _stats!['total_poin_beredar'] ?? 0;
    final totalJasa = _stats!['total_jasa'] ?? 0;
    final totalPesanan = _stats!['total_pesanan_merch'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Total Siswa', '$totalSiswa', Icons.people_outline, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Poin Beredar', '$totalPoin', Icons.stars_rounded, AppColors.warning)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Total Jasa', '$totalJasa', Icons.work_outline, AppColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Pesanan Merch', '$totalPesanan', Icons.shopping_cart_outlined, AppColors.error)),
          ],
        ),
      ],
    );
  }

  // satu kotak statistik
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // satu menu kelola
  Widget _menuCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
