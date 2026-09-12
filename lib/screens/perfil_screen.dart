// Archivo: noticias_lat/lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/core/layout/app_metrics.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';
import 'package:noticias_lat/core/services/billing_manager.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // ==========================================
  // ESTADOS DE CUENTA Y MONETIZACI N
  // ==========================================
  bool _isPremium = false;
  int _anunciosVistos = 0;
  bool _isLoadingAd = false;

  // Selecci n de paquete para publicar (Visual)
  int _selectedPackage = 1;

  @override
  void initState() {
    super.initState();
    _cargarDatosLocales();
  }

  void _cargarDatosLocales() {
    setState(() {
      _isPremium = PremiumManager.isPremium();
      _anunciosVistos = PremiumManager.getAnunciosVistosHoy();
    });
  }

  // ==========================================
  //   ABRIR ENLACES LEGALES REALES
  // ==========================================
  Future<void> _abrirEnlaceWeb(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir $url');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }

  // ==========================================
  // L GICA DE RECOMPENSAS ADMOB
  // ==========================================
  void _verAnuncioParaPremium() {
    setState(() => _isLoadingAd = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargando video publicitario...')));
    
    AdManager.showRewarded(
      onRewardEarned: () async {
        await PremiumManager.registrarAnuncioVistoParaPremium();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progreso Premium guardado.', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.accentCyan));
      },
      onAdClosed: () {
        _cargarDatosLocales();
        setState(() => _isLoadingAd = false);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.bgDark.withValues(alpha: 0.9),
            pinned: true,
            expandedHeight: 80,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1.  REA DE BIENVENIDA (Reemplaza al Login)
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  // 2. TARJETA DE SUSCRIPCI N PREMIUM ($1.99/mes)
                  const Text('Membres a', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  _buildPremiumSubscriptionCard(),
                  const SizedBox(height: 24),

                  // 3. TIENDA DE PUBLICACI N DE NOTICIAS (Pr ximamente)
                  const Text('Noticias.lat Publisher', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  _buildPublishingStore(),
                  const SizedBox(height: 30),

                  // 4. MEN  DE LEGALES Y ENLACES REALES
                  const Text('Legal e Informaci n', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  
                  _buildMenuOption(
                    icon: Icons.info_outline_rounded, 
                    title: 'Sobre Nosotros', 
                    subtitle: 'Conoce la misi n de Noticias.lat',
                    onTap: () => _abrirEnlaceWeb('https://noticias.lat/sobre-nosotros')
                  ),
                  _buildMenuOption(
                    icon: Icons.shield_rounded, 
                    title: 'Pol tica de Privacidad', 
                    subtitle: 'C mo protegemos tus datos',
                    onTap: () => _abrirEnlaceWeb('https://noticias.lat/politica-privacidad')
                  ),
                  _buildMenuOption(
                    icon: Icons.gavel_rounded, 
                    title: 'T rminos y Condiciones', 
                    subtitle: 'Reglas de uso de la plataforma',
                    onTap: () => _abrirEnlaceWeb('https://noticias.lat/terminos')
                  ),
                  _buildMenuOption(
                    icon: Icons.contact_support_rounded, 
                    title: 'Contacto y Soporte', 
                    subtitle: 'Información del desarrollador',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.bgDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.contact_support_rounded, color: AppTheme.accentCyan),
                              SizedBox(width: 10),
                              Text('Contacto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: const Text(
                            'Puedes comunicarte con el desarrollador de este agregador de noticias a través de:\n\n'
                            '📧 Correo: contactonoticiaslat@gmail.com\n'
                            '📱 Teléfono: +595 976678432\n\n'
                            'O visita nuestra página web de soporte.',
                            style: TextStyle(color: Colors.white70, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Cierra el cuadro
                                _abrirEnlaceWeb('https://noticias.lat/contacto'); // Abre la web
                              },
                              child: const Text('Ir a la Web', style: TextStyle(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  
                  SizedBox(height: AppMetrics.navClearance(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS DE LA INTERFAZ
  // ==========================================

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1585829365295-ab7cd400c167?q=80&w=600&auto=format&fit=crop'), 
          fit: BoxFit.cover, 
          opacity: 0.1
        )
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withValues(alpha: 0.2), 
              shape: BoxShape.circle
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.accentCyan, size: 36),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lector Invitado', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Bienvenido a la red de Noticias.lat', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: _isPremium 
            ? LinearGradient(colors: [AppTheme.accentCyan.withValues(alpha: 0.2), AppTheme.bgDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(colors: [AppTheme.cardDark, AppTheme.bgDark]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isPremium ? AppTheme.accentCyan : AppTheme.cardBorder, width: _isPremium ? 2 : 1),
        boxShadow: _isPremium ? AppTheme.glowShadow : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(_isPremium ? Icons.workspace_premium_rounded : Icons.star_outline_rounded, color: _isPremium ? AppTheme.accentCyan : Colors.orange, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isPremium ? 'PREMIUM ACTIVO' : 'Lector Premium', style: TextStyle(color: _isPremium ? AppTheme.accentCyan : Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_isPremium ? 'Disfruta sin l mites' : 'Cero anuncios y 100% de funciones', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (!_isPremium)
                  const Text('\$1.99', style: TextStyle(color: AppTheme.accentCyan, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          
          if (!_isPremium) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(children: [Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan, size: 18), SizedBox(width: 8), Text('0 Anuncios en toda la App', style: TextStyle(color: Colors.white, fontSize: 14))]),
                  SizedBox(height: 8),
                  Row(children: [Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan, size: 18), SizedBox(width: 8), Text('Res menes Inteligentes Ilimitados', style: TextStyle(color: Colors.white, fontSize: 14))]),
                  SizedBox(height: 8),
                  Row(children: [Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan, size: 18), SizedBox(width: 8), Text('Radio continua sin cortes', style: TextStyle(color: Colors.white, fontSize: 14))]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conectando con Google Play...'))
                        );
                        // Llamamos al motor de pagos
                        await BillingManager.comprarPremiumMensual();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan, // Lo encendemos con el color principal de la app
                        foregroundColor: AppTheme.bgDark, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: const Text('Suscribirse por \$1.99/mes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Opci n Gratuita (12 Horas por anuncios)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Opci n Gratuita (12 Horas)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _anunciosVistos / 2.0, minHeight: 4, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoadingAd ? null : _verAnuncioParaPremium,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardDark, side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: _isLoadingAd ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)) : const Icon(Icons.play_circle_filled_rounded, color: Colors.orange, size: 18),
                        label: Text('Ver Video (${2 - _anunciosVistos})', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPublishingStore() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppTheme.cardBorder)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    const Text('Publica tus Noticias', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // Etiqueta de "Pr ximamente" arriba a la derecha
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('MUY PRONTO', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text('Usa nuestra plataforma global. Tu noticia se publicar  en la Web, en la App, en Radio y se crear  un video para YouTube.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          
          // L GICA DE SELECCI N DE PAQUETES (Solo visual por ahora)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPricingPackage(amount: 1, title: '1 Noticia', price: '\$1.00', icon: Icons.article_rounded),
                _buildPricingPackage(amount: 5, title: '5 Noticias', price: '\$4.50', icon: Icons.library_books_rounded, isPopular: true),
                _buildPricingPackage(amount: 10, title: '10 Noticias', price: '\$8.00', icon: Icons.business_center_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // BOT N DESHABILITADO (PR XIMAMENTE)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Esta incre ble funci n estar  disponible en la pr xima actualizaci n!', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.orange,
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24, // Color apagado para indicar que no est  activo a n
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.lock_clock_rounded),
                label: const Text('Próximamente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPricingPackage({required int amount, required String title, required String price, required IconData icon, bool isPopular = false}) {
    bool isSelected = _selectedPackage == amount;
    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 125,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : AppTheme.bgDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.accentCyan : AppTheme.cardBorder, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.accentCyan.withValues(alpha: 0.2), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isSelected ? AppTheme.accentCyan : Colors.white24, borderRadius: BorderRadius.circular(10)), child: Text('M S VENDIDO', style: TextStyle(color: isSelected ? AppTheme.bgDark : Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
            Icon(icon, color: isSelected ? AppTheme.accentCyan : Colors.white70, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(price, style: TextStyle(color: isSelected ? AppTheme.accentCyan : Colors.white54, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.cardBorder))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
              child: Icon(icon, color: Colors.white70, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}