import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// screen admin - kelola aksi sosial (approve / reject)
class AdminSosialScreen extends StatefulWidget {
  const AdminSosialScreen({super.key});

  @override
  State<AdminSosialScreen> createState() => _AdminSosialScreenState();
}

class _AdminSosialScreenState extends State<AdminSosialScreen> {
  List<dynamic> _aksiList = [];
  bool _loading = true;
  String _filterStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ambil semua aksi sosial dari api
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.adminGetAksiSosial();
      setState(() {
        _aksiList = result['data'] ?? [];
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

  // filter list berdasarkan status
  List<dynamic> get _filteredList {
    if (_filterStatus == 'semua') return _aksiList;
    return _aksiList.where((a) => a['status'] == _filterStatus).toList();
  }

  // approve aksi sosial
  Future<void> _approve(Map<String, dynamic> aksi) async {
    try {
      await ApiService.adminUpdateAksiSosial(id: aksi['id'], status: 'disetujui');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aksi sosial disetujui ✅')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.pesanUntukUser(e))),
        );
      }
    }
  }

  // reject aksi sosial
  Future<void> _reject(Map<String, dynamic> aksi) async {
    try {
      await ApiService.adminUpdateAksiSosial(id: aksi['id'], status: 'ditolak');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aksi sosial ditolak ❌')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.pesanUntukUser(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Aksi Sosial', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
                            itemBuilder: (context, index) {
                              return _aksiCard(_filteredList[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // bar filter
  Widget _filterBar() {
    const filters = ['semua', 'pending', 'disetujui', 'ditolak'];
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
                f,
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
    );
  }

  // satu card aksi sosial
  Widget _aksiCard(Map<String, dynamic> aksi) {
    final siswa = aksi['siswa'] ?? {};
    final namaSiswa = siswa['nama'] ?? 'Siswa';
    final deskripsi = aksi['deskripsi'] ?? '';
    final foto = aksi['foto_url'] ?? '';
    final status = aksi['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? AppColors.warning.withOpacity(0.4) : AppColors.border,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // nama siswa + badge status
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textHint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  namaSiswa,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          // deskripsi
          if (deskripsi.isNotEmpty)
            Text(
              deskripsi,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          // foto kalau ada
          if (foto.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                foto,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: AppColors.border,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textHint)),
                ),
              ),
            ),
          ],
          // tombol approve / reject (cuma kalau masih pending)
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(aksi),
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                    label: Text('Tolak', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(aksi),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Setujui', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // badge status
  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'pending':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
      case 'disetujui':
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case 'ditolak':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.border;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // empty state
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_outline_rounded, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Belum ada aksi sosial', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
