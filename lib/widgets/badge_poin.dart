import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// badge poin gede di header
class BadgePoin extends StatelessWidget {
  final int poin;
  final bool large;

  const BadgePoin({super.key, required this.poin, this.large = false});

  // render badge poin
  @override
  Widget build(BuildContext context) {
    final double iconSize = large ? 22.0 : 16.0;
    final double fontSize = large ? 16.0 : 13.0;
    final double padH = large ? 16.0 : 10.0;
    final double padV = large ? 10.0 : 5.0;

    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF9500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9500).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: iconSize),
          const SizedBox(width: 4),
          Text(
            '$poin Poin',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// chip poin kecil di kartu jasa
class PoinChip extends StatelessWidget {
  final int poin;
  const PoinChip({super.key, required this.poin});

  // tampilin angka poin doang
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFF9500), size: 14),
          const SizedBox(width: 2),
          Text(
            '$poin',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF9500),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
