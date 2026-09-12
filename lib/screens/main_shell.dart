// Archivo: noticias_lat/lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:noticias_lat/core/layout/app_metrics.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/screens/noticias_screen.dart';
import 'package:noticias_lat/screens/shorts_screen.dart';
import 'package:noticias_lat/screens/radios_screen.dart';
import 'package:noticias_lat/screens/perfil_screen.dart';
import 'package:noticias_lat/screens/welcome_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _showWelcome = !UserPrefs.instance.hasCompletedWelcome;

  final List<Widget> _pages = [
    const NoticiasScreen(),
    const ShortsScreen(),
    const RadiosScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showWelcome,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark, 
        extendBody: true, 
        
        // IndexedStack mantiene el estado de las pantallas para que no se recarguen al cambiar de pestaña
        body: _showWelcome
          ? WelcomeScreen(
              onFinished: () {
                if (mounted) setState(() => _showWelcome = false);
              },
            )
          : IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
        
        bottomNavigationBar: _showWelcome ? null : _buildPremiumFloatingNavBar(),
      ),
    );
  }

  // ========================================================
  //   BARRA DE NAVEGACIÓN FLOTANTE PREMIUM (GLASSMORPHISM)
  // ========================================================
  Widget _buildPremiumFloatingNavBar() {
    final side = AppMetrics.horizontalNavPadding(context);
    final bottom = AppMetrics.navBottomPadding(context);
    final itemPadH = AppMetrics.isNarrow(context) ? 10.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(left: side, right: side, bottom: bottom),
      // NUEVO: Escudo protector. Esto bloquea que los clics atraviesen el menú 
      // y toquen los anuncios (Banners) que quedan escondidos debajo.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Absorbe los clics en los espacios vacíos
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Efecto cristal
            child: Container(
              height: AppMetrics.navBarHeight,
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withValues(alpha: 0.75), 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(0, Icons.bolt_rounded, 'Noticias', itemPadH),
                  _buildNavItem(1, Icons.play_circle_fill_rounded, 'TV', itemPadH),
                  _buildNavItem(2, Icons.podcasts_rounded, 'Radio', itemPadH),
                  _buildNavItem(3, Icons.person_rounded, 'Perfil', itemPadH),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  //   BOTONES ANIMADOS DE LA BARRA
  // ========================================================
  Widget _buildNavItem(int index, IconData icon, String label, double horizontalPadding) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.5) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
                    size: 26,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
