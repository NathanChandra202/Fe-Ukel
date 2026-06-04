import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// screen katalog merch (siswa)
class MerchScreen extends StatefulWidget {
  const MerchScreen({super.key});

  @override
  State<MerchScreen> createState() => _MerchScreenState();
}

class _MerchScreenState extends State<MerchScreen> {
  List<dynamic> _merchList = [];
  bool _loading = true;
  int _saldoPoin = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ambil list merch + saldo poin
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _saldoPoin = prefs.getInt('saldo_poin') ?? 0;
      
      final result = await ApiService.getDaftarMerch();
      setState(() {
        _merchList = result['data'] ?? [];
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
        title: Text(
          'Toko Merch',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          // tampil saldo poin di kanan atas
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '$_saldoPoin',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _merchList.isEmpty
                  ? _emptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _merchList.length,
                      itemBuilder: (context, index) {
                        final merch = _merchList[index];
                        return _merchCard(merch);
                      },
                    ),
            ),
    );
  }

  // empty state kalau belum ada merch
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Belum ada merch',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // satu card merch
  Widget _merchCard(Map<String, dynamic> merch) {
    final id = merch['id'];
    final nama = merch['nama'] ?? 'Barang';
    final harga = merch['harga_poin'] ?? 0;
    final stok = merch['stok'] ?? 0;
    final foto = merch['foto_url'] ?? '';

    return GestureDetector(
      onTap: () async {
        // ke halaman detail merch
        final result = await Navigator.pushNamed(
          context,
          '/detail-merch',
          arguments: id,
        );
        // kalau berhasil beli, refresh list
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // foto merch
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: foto.isNotEmpty
                  ? Image.network(
                      foto,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // nama barang
                  Text(
                    nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // harga poin
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$harga',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // stok
                  Text(
                    'Stok: $stok',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // placeholder kalau ga ada foto
  Widget _placeholderImage() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.border,
      child: const Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
    );
  }
}
