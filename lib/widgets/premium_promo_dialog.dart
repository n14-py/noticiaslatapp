import 'package:flutter/material.dart';
import 'package:noticias_lat/core/services/billing_manager.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';

Future<void> showPremiumPromoDialog(BuildContext context) async {
  if (!context.mounted) return;
  if (PremiumManager.isPremium()) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: const _PremiumPromoCard(),
        ),
      );
    },
  );
}

class _PremiumPromoCard extends StatelessWidget {
  const _PremiumPromoCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.45), width: 1.5),
                boxShadow: AppTheme.glowShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentCyan.withValues(alpha: 0.12),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.accentCyan, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lector Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Resúmenes con IA sin límite y la app libre de interrupciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  const _PromoLine(text: 'Sin anuncios en toda la app'),
                  const SizedBox(height: 8),
                  const _PromoLine(text: 'Inteligencia artificial ilimitada'),
                  const SizedBox(height: 8),
                  const _PromoLine(text: 'Radio continua, sin cortes'),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await BillingManager.comprarPremiumMensual();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: AppTheme.bgDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Sumarme por \$1.99 al mes',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Seguir así',
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoLine extends StatelessWidget {
  final String text;
  const _PromoLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ],
    );
  }
}
