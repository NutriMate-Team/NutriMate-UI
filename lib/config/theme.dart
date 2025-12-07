import 'package:flutter/material.dart';

/// Centralized Humanize UI design tokens and helpers.
///
/// Use these helpers instead of ad‑hoc shadows/radii in widgets so we get
/// a consistent soft, organic look across the app.
class HumanizeUI {
  HumanizeUI._();

  // Pale Mint gradient used as the main app background.
  static const Color paleMintTop = Color(0xFFE0F5E8);
  static const Color paleMintBottom = Color(0xFFF5FFF9);

  static const LinearGradient paleMintBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      paleMintTop,
      paleMintBottom,
    ],
  );

  /// Asymmetric, organic radius for primary containers/cards.
  ///
  /// Order: topLeft, topRight, bottomRight, bottomLeft.
  static BorderRadius get asymmetricRadius24 => const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(18),
        bottomLeft: Radius.circular(22),
      );

  static BorderRadius get asymmetricRadius20 => const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(18),
        bottomRight: Radius.circular(16),
        bottomLeft: Radius.circular(19),
      );

  static BorderRadius get asymmetricRadius16 => const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(14),
        bottomRight: Radius.circular(16),
        bottomLeft: Radius.circular(15),
      );

  /// Two‑layer soft shadow system for natural depth.
  ///
  /// [baseColor] should usually be a light surface color (e.g. white or paleMintTop).
  static List<BoxShadow> softElevation({required Color baseColor}) {
    final shadowColor = _desaturatedShadowColor(baseColor);

    return [
      // Near shadow
      BoxShadow(
        color: shadowColor.withOpacity(0.08),
        offset: const Offset(0, 2),
        blurRadius: 4,
        spreadRadius: 0,
      ),
      // Ambient shadow
      BoxShadow(
        color: shadowColor.withOpacity(0.04),
        offset: const Offset(0, 8),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ];
  }

  /// Slightly stronger soft elevation for prominent hero cards like the
  /// central calorie ring.
  static List<BoxShadow> heroSoftElevation({required Color baseColor}) {
    final shadowColor = _desaturatedShadowColor(baseColor);

    return [
      BoxShadow(
        color: shadowColor.withOpacity(0.10),
        offset: const Offset(0, 3),
        blurRadius: 6,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: shadowColor.withOpacity(0.05),
        offset: const Offset(0, 10),
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ];
  }

  /// Desaturated shadow color derived from the given [baseColor].
  static Color _desaturatedShadowColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    final darker = hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0));
    final desaturated =
        darker.withSaturation((darker.saturation * 0.4).clamp(0.0, 1.0));
    return desaturated.toColor();
  }
}


