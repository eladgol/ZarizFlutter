import 'dart:ui';

import 'package:flutter/cupertino.dart';

class Colors {

  const Colors();

  static const Color zarizGradientStart = const Color(0xFFf6aa1c); // bright yellow (rayola)
  static const Color zarizGradientEnd = const Color(0xFFA63C06); // Rust
  static const Color zarizGradientEnd2 = const Color(0xFF2F1000); // dark brown (zinnwaldite)
  static const Color zarizGradientStart2 = const Color(0xFFD7BE82); // burrly wood (light gree)
  static const Color zarizGradientStart1 = const Color(0xFF515A47); // gray asparags (dark green)


  static const primaryGradient = const LinearGradient(
    colors: const [zarizGradientStart, zarizGradientEnd],
    stops: const [0.0, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}