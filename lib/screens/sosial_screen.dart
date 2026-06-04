import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class SosialScreen extends StatefulWidget {
  const SosialScreen({super.key});

  @override
  State<SosialScreen> createState() => _SosialScreenState();
}

class _SosialScreenState extends State<SosialScreen> {
  List _riwayat = [];
  bool _loadingRiwayat = true;
  String? _errorRiwayat;
  bool _uploading = false;
  Uint8List? _fotoBytes;
  String _namaFile = 'foto.jpg';
  final _deskripsiCtrl = TextEditingController();

  // wajib dipanggil biar ga loading forever
  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // bersihin controller
  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  // ambil list aksi sosial dari backend
  Future<void> _loadRiwayat({bool tampilkanError = true}) async {
    if (mounted) {
      setState(() {
        _loadingRiwayat = true;
        _errorRiwayat = null;
      });
    }
    try {
      final res = await ApiService.getRiwayatSosial();
      if (mounted) {
        setState(() {
          _riwayat = List.from(res['data'] ?? []);
          _loadingRiwayat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRiwayat = false;
          _errorRiwayat = ApiService.pesanUntukUser(
            e,
            fallback: 'Gagal memuat riwayat aksi sosial.',
          );
        });
        if (tampilkanError) {
          AppSnackbar.error(
            context,
            e,
            fallback: 'Gagal memuat riwayat aksi sosial.',
          );
        }
      }
    }
  }

  // pilih gambar dari galeri (web juga)
  Future<void> _pilihFoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _fotoBytes = bytes;
        _namaFile = picked.name.isNotEmpty ? picked.name : 'foto.jpg';
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e,
          fallback: 'Gagal memilih foto. Izinkan akses file di browser jika diminta.',
        );
      }
    }
  }

  // kirim foto + deskripsi ke server
  Future<void> _upload() async {
    if (_fotoBytes == null) {
      AppSnackbar.error(context, 'Pilih foto bukti aksi sosial terlebih dahulu.');
      return;
    }
    if (_deskripsiCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Tulis deskripsi kegiatan sosial kamu.');
      return;
    }

    setState(() => _uploading = true);
    try {
      final res = await ApiService.uploadAksiSosial(
        deskripsi: _deskripsiCtrl.text,
        fotoBytes: _fotoBytes!,
        namaFile: _namaFile,
      );
      if (!mounted) return;
      AppSnackbar.sukses(context, res['pesan']?.toString() ?? 'Upload berhasil dikirim.');
      setState(() => _fotoBytes = null);
      _deskripsiCtrl.clear();
      await ApiService.perbaruiSaldoLokal();
      await _loadRiwayat(tampilkanError: false);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Upload foto gagal. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // halaman upload + riwayat sosial
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _loadRiwayat(tampilkanError: false),
              child: CustomScrollView(
                slivers: [
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
                          child: Text(
                            'Aksi Sosial',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00C2A8),
                                        Color(0xFF00897B),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upload Bukti Sosial',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Dapatkan poin gratis!',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _deskripsiCtrl,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText:
                                    'Ceritain aksi sosial kamu (buang sampah, dll)',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 28),
                                  child: Icon(Icons.edit_note_rounded, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _pilihFoto,
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _fotoBytes != null
                                        ? AppColors.accent
                                        : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: _fotoBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.memory(
                                              _fotoBytes!,
                                              fit: BoxFit.cover,
                                            ),
                                            Container(
                                              color: Colors.black.withOpacity(0.3),
                                            ),
                                            Center(
                                              child: Text(
                                                'Tap untuk ganti foto',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 36,
                                            color: AppColors.textHint,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap untuk pilih foto (JPG/PNG)',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _uploading ||
                                        _fotoBytes == null ||
                                        _deskripsiCtrl.text.trim().isEmpty
                                    ? null
                                    : _upload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  disabledBackgroundColor:
                                      AppColors.surfaceVariant,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: _fotoBytes != null ? 4 : 0,
                                  shadowColor:
                                      AppColors.accent.withOpacity(0.4),
                                ),
                                child: _uploading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.upload_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Upload & Dapatkan Poin',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: Text(
                        'Riwayat Sosial',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (_loadingRiwayat)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_errorRiwayat != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _errorRiwayat!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _loadRiwayat,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_riwayat.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                size: 40,
                                color: AppColors.accent,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada aksi sosial',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!_loadingRiwayat && _errorRiwayat == null)
                    SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final r = _riwayat[i];
                        final status = r['status'] as String? ?? '';
                        final poin = r['poin_diberikan'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['deskripsi'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: $status',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  '+$poin Poin',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
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

