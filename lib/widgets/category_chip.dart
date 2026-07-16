import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool onLight;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = onLight ? const Color(0xFF0F172A) : Colors.white;
    final selectedFg = onLight ? Colors.white : const Color(0xFF0F172A);
    final idleBg = onLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.14);
    final idleFg = onLight ? const Color(0xFF475569) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : idleBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? selectedBg
                : (onLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.22)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? selectedFg : idleFg,
          ),
        ),
      ),
    );
  }
}
