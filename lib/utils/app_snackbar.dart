import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// snackbar biar pesan sukses/error konsisten di semua halaman
class AppSnackbar {
  // hijau, kalo berhasil
  static void sukses(BuildContext context, String pesan) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: const Color(0xFF00897B),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // merah, kalo gagal — otomatis rapihin pesan error
  static void error(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    if (!context.mounted) return;
    final pesan = error is String
        ? error
        : ApiService.pesanUntukUser(error, fallback: fallback);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // abu/info biasa
  static void info(BuildContext context, String pesan) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
