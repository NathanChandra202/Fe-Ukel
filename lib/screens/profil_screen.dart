import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/badge_poin.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  // bikin state buat halaman profil
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _dataSiswa;
  bool _sedangLoading = true;
  bool _isAdmin = false; // flag admin

  // load profil pas buka tab
  @override
  void initState() {
    super.initState();
    _ambilData();
    _cekAdmin();
  }

  // cek apakah user admin
  Future<void> _cekAdmin() async {
    final isAdmin = await ApiService.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  // get profil dari api
  Future<void> _ambilData() async {
    try {
      final res = await ApiService.getProfil();
      if (res['siswa'] != null) {
        setState(() => _dataSiswa = res['siswa']);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal memuat profil.');
      }
    }
    if (mounted) setState(() => _sedangLoading = false);
  }

  // popup edit nama/kelas/jurusan
  Future<void> _editProfil() async {
    final ctrlNama = TextEditingController(text: _dataSiswa!['nama']);
    final ctrlKelas = TextEditingController(text: _dataSiswa!['kelas']);
    final ctrlJurusan = TextEditingController(text: _dataSiswa!['jurusan']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrlNama,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrlKelas,
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrlJurusan,
                decoration: const InputDecoration(
                  labelText: 'Jurusan',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _sedangLoading = true);
      try {
        final res = await ApiService.updateProfil(
          nama: ctrlNama.text,
          kelas: ctrlKelas.text,
          jurusan: ctrlJurusan.text,
        );
        if (mounted) {
          AppSnackbar.sukses(
            context,
            res['pesan']?.toString() ?? 'Profil berhasil diperbarui.',
          );
        }
        _ambilData();
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, e, fallback: 'Gagal memperbarui profil.');
          setState(() => _sedangLoading = false);
        }
      }
    }
  }

  // buka link export excel di browser
  Future<void> _downloadExcel() async {
    if (!mounted) return;
    AppSnackbar.info(context, 'Membuka unduhan riwayat poin...');
    try {
      final url = await ApiService.getExportExcelUrl();
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackbar.error(
            context,
            'Browser tidak bisa membuka link unduhan.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal mengunduh riwayat.');
      }
    }
  }

  // keluar akun, hapus token lokal
  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign Out',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin keluar dari akun kamu?',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.hapusToken();
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // hapus akun permanen (hati hati)
  void _hapusAkun() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Akun',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Tindakan ini tidak bisa dibatalkan. Semua data kamu akan terhapus. Yakin?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _sedangLoading = true);
              Navigator.pop(ctx);
              try {
                final res = await ApiService.hapusAkun();
                await ApiService.hapusToken();
                if (mounted) {
                  AppSnackbar.sukses(
                    context,
                    res['pesan']?.toString() ?? 'Akun berhasil dihapus.',
                  );
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  AppSnackbar.error(context, e, fallback: 'Gagal menghapus akun.');
                }
                setState(() => _sedangLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  // ui profil + menu menu
  @override
  Widget build(BuildContext context) {
    if (_sedangLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dataSiswa == null) {
      return const Center(child: Text('Gagal muat profil'));
    }

    final nama = _dataSiswa!['nama'] as String? ?? 'Siswa';
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() => _sedangLoading = true);
          await _ambilData();
        },
        child: ListView(
          children: [
            // Profile header gradient card
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3730A3),
                    Color(0xFF6C63FF),
                    Color(0xFF8B5CF6)
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nama,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dataSiswa!['email'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BadgePoin(poin: _dataSiswa!['saldo_poin'] ?? 0, large: true),
                    ],
                  ),
                ),
              ),
            ),

            // Info cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      Icons.class_rounded,
                      'Kelas',
                      _dataSiswa!['kelas'] ?? '-',
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      Icons.book_rounded,
                      'Jurusan',
                      _dataSiswa!['jurusan'] ?? '-',
                      AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Menu Admin (cuma muncul kalau admin)
                  if (_isAdmin) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      ),
                      child: _menuItem(
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.primarySurface,
                        title: '⚡ Admin Dashboard',
                        onTap: () => Navigator.pushNamed(context, '/admin-dashboard'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _menuItem(
                          icon: Icons.edit_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primarySurface,
                          title: 'Edit Profil',
                          onTap: _editProfil,
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.download_rounded,
                          iconColor: AppColors.success,
                          iconBg: AppColors.successLight,
                          title: 'Download Riwayat (Excel)',
                          onTap: _downloadExcel,
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.warning,
                          iconBg: AppColors.warningLight,
                          title: 'Riwayat Transaksi',
                          onTap: () =>
                              Navigator.pushNamed(context, '/riwayat'),
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.shopping_bag_rounded,
                          iconColor: AppColors.accent,
                          iconBg: AppColors.accent.withOpacity(0.1),
                          title: 'Riwayat Pesanan Merch',
                          onTap: () =>
                              Navigator.pushNamed(context, '/riwayat-merch'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _menuItem(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.warning,
                          iconBg: AppColors.warningLight,
                          title: 'Keluar',
                          titleColor: AppColors.warning,
                          onTap: _logout,
                        ),
                        _divider(),
                        _menuItem(
                          icon: Icons.delete_forever_rounded,
                          iconColor: AppColors.error,
                          iconBg: AppColors.errorLight,
                          title: 'Hapus Akun',
                          titleColor: AppColors.error,
                          onTap: _hapusAkun,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // widget kotak info buat nampilin data profil
  Widget _infoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // satu baris menu di profil
  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // garis pemisah tipis
  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
    );
  }
}
