import 'package:flutter/material.dart';

/// Métricas de layout. En pantallas grandes se ve igual; en chicas evita que se escondan botones.
class AppMetrics {
  static const double navBarHeight = 75;
  static const double navBottomGap = 24;
  static const double navSidePadding = 20;
  static const double navSidePaddingNarrow = 12;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 380;

  static double horizontalNavPadding(BuildContext context) =>
      isNarrow(context) ? navSidePaddingNarrow : navSidePadding;

  static double navBottomPadding(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return navBottomGap + inset;
  }

  /// Espacio que deben dejar shorts/radio/listas para no tapar la barra flotante.
  static double navClearance(BuildContext context) {
    return navBarHeight + navBottomPadding(context) + 12;
  }

  static double statusBarPadding(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return top > 0 ? top + 8 : 50;
  }
}
