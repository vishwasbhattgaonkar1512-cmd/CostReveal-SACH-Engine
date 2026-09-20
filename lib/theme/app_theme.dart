import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors (Mumbai Sunlight Spec) ──────────────────────────────────────────
  static const Color bg            = Color(0xFFF9F9F9);
  static const Color navy          = Color(0xFF1E3A8A);
  static const Color green         = Color(0xFF10B981);
  static const Color red           = Color(0xFFDC2626);
  static const Color white         = Colors.white;
  static const Color border        = Color(0xFFE5E7EB);
  static const Color textPrimary   = Colors.black87;
  static const Color textSecondary = Colors.black54;

  // ── Typography ────────────────────────────────────────────────────────────
  static const double labelSize   = 14.0;
  static const double bodyMin     = 16.0;
  static const double subheadline = 24.0;
  static const double numberSub   = 24.0;
  static const double numberHero  = 40.0;
  
  static const FontWeight numberWeight = FontWeight.w900;

  // ── Layout & Targets ──────────────────────────────────────────────────────
  static const double cardPadding     = 16.0;
  static const double minTapTarget    = 60.0;
  static const double cardRadius      = 12.0;
  static const double cardBorderWidth = 2.0;

  // ── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: borderColor ?? border,
        width: cardBorderWidth,
      ),
    );
  }

  static BoxDecoration heroStatDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ],
    );
  }
}
