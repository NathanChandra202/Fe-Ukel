import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;

  // fungsi submit buat daftar
  Future<void> _daftar() async {
    if (_namaCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Nama lengkap wajib diisi.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Email wajib diisi.');
      return;
    }
    if (!_emailCtrl.text.trim().contains('@')) {
      AppSnackbar.error(context, 'Format email tidak valid.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      AppSnackbar.error(context, 'Password minimal 6 karakter.');
      return;
    }
    if (_kelasCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Kelas wajib diisi.');
      return;
    }
    if (_jurusanCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Jurusan wajib diisi.');
      return;
    }

    final backendOk = await ApiService.cekKoneksiBackend();
    if (!mounted) return;
    if (!backendOk) {
      AppSnackbar.error(
        context,
        'Backend belum aktif.\n${ApiConfig.petunjukBackend}',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.register(
        nama: _namaCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        kelas: _kelasCtrl.text,
        jurusan: _jurusanCtrl.text,
      );
      if (!mounted) return;
      AppSnackbar.sukses(
        context,
        res['pesan']?.toString() ?? 'Pendaftaran berhasil. Silakan login.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Pendaftaran gagal. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4C3CE0), Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Buat Akun Baru',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bergabung dengan komunitas KONTRIB.ID',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Nama Lengkap'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Nama kamu',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label('Email'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'contoh@sekolah.id',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      hintText: 'Min. 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Kelas'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _kelasCtrl,
                              decoration: const InputDecoration(
                                hintText: 'mis: 12',
                                prefixIcon: Icon(Icons.class_outlined, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Jurusan'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _jurusanCtrl,
                              decoration: const InputDecoration(
                                hintText: 'mis: RPL',
                                prefixIcon: Icon(Icons.book_outlined, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  SizedBox(
                    height: 54,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _daftar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: const Text('Daftar Sekarang'),
                          ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Masuk',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}
