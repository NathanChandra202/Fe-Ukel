import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obsecurePass = true;

  // fungsi buat login
  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty) {
      AppSnackbar.error(context, 'Masukkan email kamu.');
      return;
    }
    if (!email.contains('@')) {
      AppSnackbar.error(context, 'Format email tidak valid.');
      return;
    }
    if (password.isEmpty) {
      AppSnackbar.error(context, 'Masukkan password kamu.');
      return;
    }

    final backendOk = await ApiService.cekKoneksiBackend();
    if (!backendOk) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Backend belum aktif.\n${ApiConfig.petunjukBackend}',
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.login(email: email, password: password);
      final token = res['token'];
      if (token == null) {
        if (mounted) {
          AppSnackbar.error(
            context,
            res['pesan']?.toString() ?? 'Login gagal. Periksa email dan password.',
          );
        }
        return;
      }

      await ApiService.simpanToken(token.toString());
      final siswa = res['siswa'];
      if (siswa is Map) {
        await ApiService.simpanDataSiswa(Map<String, dynamic>.from(siswa));
      }
      await ApiService.sinkronkanProfilSetelahLogin();

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Login gagal. Coba lagi.');
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
            // Top gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat Datang!',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Login ke akun KONTRIB.ID kamu',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Form section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email field
                  _label('Email'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'contoh@sekolah.id',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  _label('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obsecurePass,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password kamu',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obsecurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obsecurePass = !_obsecurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login button
                  SizedBox(
                    height: 54,
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: const Text('Masuk'),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Daftar Sekarang',
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
