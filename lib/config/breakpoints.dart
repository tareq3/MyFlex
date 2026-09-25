import 'package:flutter/widgets.dart';

/// Screen-width breakpoints used to adapt layouts.
abstract final class Breakpoints {
  /// Below this width the phone / small-tablet layout is used.
  static const double mobile = 840;

  /// At or above this width the app bar has room for the stats.
  static const double wide = 1200;
}

extension ResponsiveContext on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobileLayout => _screenWidth < Breakpoints.mobile;

  bool get isWideLayout => _screenWidth >= Breakpoints.wide;
}
