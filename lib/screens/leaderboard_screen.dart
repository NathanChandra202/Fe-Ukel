import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List _peringkat = [];
  bool _loading = true;

  // load ranking pas tab dibuka
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ambil top siswa dari api
  Future<void> _loadData() async {
    try {
      final res = await ApiService.getLeaderboard();
      if (mounted) {
        setState(() => _peringkat = List.from(res['data'] ?? []));
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e, fallback: 'Gagal memuat leaderboard.');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  // warna medali juara 1 2 3
  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFB300);
      case 1:
        return const Color(0xFF9E9E9E);
      case 2:
        return const Color(0xFF8D6E63);
      default:
        return AppColors.primaryLight;
    }
  }

  // icon ranking per posisi
  IconData _rankIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events_rounded;
      case 1:
        return Icons.military_tech_rounded;
      case 2:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // tampilan ranking
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Peringkat Poin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() => _loading = true);
                await _loadData();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _peringkat.length,
                itemBuilder: (ctx, i) {
                  final p = _peringkat[i];
                  final isTop3 = i < 3;
                  final rankColor = _rankColor(i);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isTop3 ? rankColor.withOpacity(0.08) : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isTop3 ? rankColor.withOpacity(0.3) : AppColors.border,
                        width: isTop3 ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: rankColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isTop3
                              ? Icon(_rankIcon(i), color: rankColor, size: 24)
                              : Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: rankColor,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            ((p['nama'] ?? 'S') as String)[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['nama'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                p['kelas'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Points badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isTop3
                                ? rankColor.withOpacity(0.15)
                                : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${p['saldo_poin']} Poin',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isTop3 ? rankColor : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
