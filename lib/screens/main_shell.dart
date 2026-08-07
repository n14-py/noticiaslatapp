// Archivo: noticias_lat/lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/screens/noticias_screen.dart';
import 'package:noticias_lat/screens/shorts_screen.dart';
import 'package:noticias_lat/screens/radios_screen.dart';
import 'package:noticias_lat/screens/perfil_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const NoticiasScreen(),
    const ShortsScreen(),
    const RadiosScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark, 
      extendBody: true, 
      
      // IndexedStack mantiene el estado de las pantallas para que no se recarguen al cambiar de pestaña
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: _buildPremiumFloatingNavBar(),
    );
  }

  // ========================================================
  //   BARRA DE NAVEGACIÓN FLOTANTE PREMIUM (GLASSMORPHISM)
  // ========================================================
  Widget _buildPremiumFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
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
              height: 75,
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.bolt_rounded, 'Noticias'),
                  _buildNavItem(1, Icons.play_circle_fill_rounded, 'TV'),
                  _buildNavItem(2, Icons.podcasts_rounded, 'Radio'),
                  _buildNavItem(3, Icons.person_rounded, 'Perfil'),
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
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
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
    );
  }
}