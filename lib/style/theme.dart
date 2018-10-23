import 'dart:ui';

import 'package:flutter/cupertino.dart';

class Colors {

  const Colors();

  static const Color zarizGradientStart = const Color(0xFFf6aa1c);
  static const Color zarizGradientEnd = const Color(0xFFA63C06);

  static const primaryGradient = const LinearGradient(
    colors: const [zarizGradientStart, zarizGradientEnd],
    stops: const [0.0, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}