import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class BuatIklanScreen extends StatefulWidget {
  const BuatIklanScreen({super.key});

  @override
  State<BuatIklanScreen> createState() => _BuatIklanScreenState();
}

class _BuatIklanScreenState extends State<BuatIklanScreen> {
  final _judulCtrl = TextEditingController();
  final _kategoriCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  int? _selectedPoin;
  bool _loading = false;

  final List<int> _poinOptions = [3, 5, 7, 10];
  final List<String> _kategoriOptions = ['Akademik', 'Non-Akademik'];
  String? _selectedKategori;

  // post iklan jasa ke api
  Future<void> _submit() async {
    if (_judulCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Judul jasa wajib diisi.');
      return;
    }
    if (_selectedKategori == null || _selectedKategori!.trim().isEmpty) {
      AppSnackbar.error(context, 'Pilih kategori (Akademik atau Non-Akademik).');
      return;
    }
    if (_deskripsiCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Deskripsi jasa wajib diisi.');
      return;
    }
    if (_selectedPoin == null) {
      AppSnackbar.error(context, 'Pilih harga poin untuk jasa ini.');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.buatIklan(
        judul: _judulCtrl.text,
        kategori: _selectedKategori!,
        deskripsi: _deskripsiCtrl.text,
        hargaPoin: _selectedPoin!,
      );
      if (!mounted) return;
      AppSnackbar.sukses(
        context,
        res['pesan']?.toString() ?? 'Jasa berhasil diposting!',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal memposting jasa.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // form posting jasa
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Iklan Jasa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Posting jasa dan bantu teman sekelasmu, lalu dapatkan poin!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _label('Judul Jasa'),
          const SizedBox(height: 8),
          TextField(
            controller: _judulCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'mis: Bantuan belajar Matematika',
              prefixIcon: Icon(Icons.title_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          _label('Kategori'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _kategoriOptions.map((k) {
              final selected = _selectedKategori == k;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedKategori = k;
                    _kategoriCtrl.text = k;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    k,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _label('Deskripsi'),
          const SizedBox(height: 8),
          TextField(
            controller: _deskripsiCtrl,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Jelaskan apa yang kamu tawarkan...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 64),
                child: Icon(Icons.description_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _label('Harga Poin'),
          const SizedBox(height: 12),
          Row(
            children: _poinOptions.map((p) {
              final selected = _selectedPoin == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPoin = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: selected
                              ? Colors.white
                              : const Color(0xFFFF9500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$p',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'poin',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: selected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          SizedBox(
            height: 54,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Text('Posting Jasa'),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // label field
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
