// Archivo: noticias_lat/lib/screens/detalle_noticia_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/widgets/ai_summary_card.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';

class DetalleNoticiaScreen extends StatefulWidget {
  final Map noticia;
  const DetalleNoticiaScreen({super.key, required this.noticia});

  @override
  State<DetalleNoticiaScreen> createState() => _DetalleNoticiaScreenState();
}

class _DetalleNoticiaScreenState extends State<DetalleNoticiaScreen> {
  bool _isLoadingIA = false;
  String? _aiSummary;
  
  bool _mostrarTarjeta = false;
  bool _modoSoloAudio = false;
  
  List _recomendados = [];
  bool _isLoadingRecomendados = true;

  // Lógica de Me Gusta local
  bool _isLiked = false;
  late String _articleId;

  @override
  void initState() {
    super.initState();
    _articleId = widget.noticia['_id'] ?? '';
    _checkIfLiked();
    _cargarRecomendados();
  }

  // ========================================================
  // ❤️ LÓGICA DEL BOTÓN ME GUSTA
  // ========================================================
  Future<void> _checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isLiked = prefs.getBool('liked_$_articleId') ?? false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLiked = !_isLiked);
    await prefs.setBool('liked_$_articleId', _isLiked);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLiked ? 'Noticia guardada en favoritos ❤️' : 'Eliminada de favoritos', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.bgDark,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ========================================================
  // 🤖 LÓGICA DE CRÉDITOS IA Y RECOMPENSAS
  // ========================================================
  void _intentarResumirConIA() async {
    // 1. Verificamos si tiene saldo o es Premium
    bool tieneSaldo = await PremiumManager.usarCreditoIA();
    
    if (tieneSaldo) {
      // Tiene saldo, procesamos el resumen
      setState(() {}); // Actualiza la UI de los botones
      _obtenerResumenIA();
    } else {
      // 2. NO tiene saldo: Mostramos el popup para ver el anuncio
      _mostrarDialogoSinCreditos();
    }
  }

  void _mostrarDialogoSinCreditos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.5))),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.accentCyan, size: 28),
            SizedBox(width: 8),
            Text('¡Sin Energía IA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Te has quedado sin usos de la Inteligencia Artificial.\n\n¿Quieres ver un video corto para recargar 5 usos inmediatamente?',
          style: TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              // Mostramos el anuncio recompensado
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargando anuncio...')));
              
              AdManager.showRewarded(
                onRewardEarned: () async {
                  await PremiumManager.agregarCreditosIA(5);
                  await PremiumManager.registrarAnuncioVistoParaPremium();
                  if (mounted) {
                    setState(() {});
                    _obtenerResumenIA(); // Le damos el resumen automáticamente como premio
                  }
                },
                onAdClosed: () {
                  // Si cerró a la mitad, no pasa nada, solo actualizamos UI
                  if (mounted) setState(() {});
                }
              );
            },
            child: const Text('Ver Anuncio', style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _obtenerResumenIA() async {
    if (widget.noticia['aiSummary'] != null && widget.noticia['aiSummary'].toString().trim().isNotEmpty) {
      setState(() {
        _aiSummary = widget.noticia['aiSummary'];
        _modoSoloAudio = false;
        _mostrarTarjeta = true;
      });
      return;
    }

    setState(() => _isLoadingIA = true);

    try {
      final url = Uri.parse('https://api.noticias.lat/api/article/$_articleId/ai-summary');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _aiSummary = data['summary'];
            _modoSoloAudio = false;
            _mostrarTarjeta = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error IA: $e");
    } finally {
      if (mounted) setState(() => _isLoadingIA = false);
    }
  }

  // ========================================================
  // 🌐 CARGAR NOTICIAS RECOMENDADAS
  // ========================================================
  Future<void> _cargarRecomendados() async {
    final categoria = widget.noticia['categoria'] ?? 'general';
    final url = Uri.parse('https://api.noticias.lat/api/articles?sitio=noticias.lat&limite=6&categoria=$categoria');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List articulos = data['articulos'] ?? [];
        articulos.removeWhere((item) => item['_id'] == widget.noticia['_id']);
        if (articulos.length > 5) articulos = articulos.sublist(0, 5);

        if (mounted) setState(() { _recomendados = articulos; _isLoadingRecomendados = false; });
      } else {
        if (mounted) setState(() => _isLoadingRecomendados = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecomendados = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime fechaObj = DateTime.tryParse(widget.noticia['fecha'] ?? '') ?? DateTime.now();
    String fechaFormateada = DateFormat('dd MMMM, yyyy • HH:mm').format(fechaObj);
    final tieneAudio = widget.noticia['audioUrl'] != null && widget.noticia['audioUrl'].toString().isNotEmpty;
    final tieneVideo = widget.noticia['videoUrl'] != null || widget.noticia['youtubeId'] != null;

    // Calcular la etiqueta del botón
    String aiLabel = 'Resumir con IA';
    if (!PremiumManager.isPremium()) {
      int creditos = PremiumManager.getAiCredits();
      aiLabel = 'Resumir IA (⚡ $creditos)';
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. CABECERA CON IMAGEN PARALLAX
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.bgDark,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                            color: _isLiked ? Colors.redAccent : Colors.white, 
                            size: 24
                          ),
                          onPressed: _toggleLike,
                          style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.noticia['imagen'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppTheme.cardDark),
                        errorWidget: (context, url, error) => Container(color: AppTheme.cardDark),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, AppTheme.bgDark],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      
                      // --- NUEVO: REPRODUCTOR DE VIDEO EN LA ESQUINA INFERIOR DERECHA ---
                      if (tieneVideo)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo video completo...')));
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 120,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                                    boxShadow: AppTheme.glowShadow,
                                  ),
                                  child: const Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.play_circle_fill_rounded, color: AppTheme.accentCyan, size: 40),
                                      Positioned(
                                        bottom: 4,
                                        child: Text('VER VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. CUERPO DE LA NOTICIA
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.accentCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3))),
                            child: Text(widget.noticia['categoria']?.toString().toUpperCase() ?? 'NOTICIA', style: Theme.of(context).textTheme.labelSmall),
                          ),
                          const SizedBox(width: 8),
                          // FUENTE DE LA NOTICIA AÑADIDA AQUÍ
                          Text('•  ${widget.noticia['fuente']?.toString().toUpperCase() ?? 'WEB'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          
                          const Spacer(),
                          const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(fechaFormateada, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(widget.noticia['titulo'] ?? '', style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 30),
                      Container(height: 2, width: 60, decoration: BoxDecoration(color: AppTheme.accentCyan, boxShadow: AppTheme.glowShadow)),
                      const SizedBox(height: 30),
                      Text(widget.noticia['articuloGenerado'] ?? widget.noticia['descripcion'] ?? 'No hay contenido disponible.', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),

              // --- NUEVO: BANNER DE PUBLICIDAD AL FINAL DEL ARTÍCULO ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: AdManager.getBannerAdWidget(),
                ),
              ),

              // 3. SECCIÓN DE RECOMENDADOS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.accentCyan, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text('TE PODRÍA INTERESAR', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),

              // 4. LISTA DE 5 RECOMENDADOS
              _isLoadingRecomendados
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.accentCyan))))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRecomendadoCard(_recomendados[index], context),
                        childCount: _recomendados.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),

          // ========================================================
          // 5. BOTONES FLOTANTES Y TARJETA IA (SEPARADOS)
          // ========================================================
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _mostrarTarjeta
                ? AiSummaryCard(
                    resumen: _aiSummary ?? '',
                    audioUrl: widget.noticia['audioUrl'],
                    modoSoloAudio: _modoSoloAudio, 
                    onClose: () => setState(() => _mostrarTarjeta = false),
                  )
                : Row(
                    children: [
                      if (tieneAudio) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 60, width: 60,
                              decoration: BoxDecoration(color: AppTheme.cardDark.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)), boxShadow: AppTheme.glowShadow),
                              child: IconButton(
                                icon: const Icon(Icons.headphones_rounded, color: AppTheme.accentCyan, size: 28),
                                onPressed: () => setState(() { _modoSoloAudio = true; _mostrarTarjeta = true; }),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      
                      // BOTÓN DE RESUMIR CON LÓGICA DE CRÉDITOS
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(gradient: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? AppTheme.neonGradient : null, color: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? null : Colors.grey.shade800, borderRadius: BorderRadius.circular(20), boxShadow: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? AppTheme.glowShadow : []),
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingIA ? null : _intentarResumirConIA,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), disabledBackgroundColor: Colors.transparent),
                            icon: _isLoadingIA
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.bgDark, strokeWidth: 3))
                                : Icon(PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? Icons.auto_awesome_rounded : Icons.bolt_rounded, color: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? AppTheme.bgDark : Colors.white),
                            label: Text(
                              _isLoadingIA ? 'Analizando...' : aiLabel,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? AppTheme.bgDark : Colors.white,
                                fontSize: 15, fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendadoCard(Map item, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Mostramos intersticial de forma aleatoria al cambiar de noticia (lo maneja el AdManager si no es premium)
        AdManager.showInterstitial();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DetalleNoticiaScreen(noticia: item)));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        height: 100,
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 100, height: 100,
              child: CachedNetworkImage(imageUrl: item['imagen'] ?? '', fit: BoxFit.cover, placeholder: (c, u) => Container(color: AppTheme.cardBorder), errorWidget: (c, u, e) => Container(color: AppTheme.cardBorder)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['categoria']?.toString().toUpperCase() ?? 'NOTICIA', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(item['titulo'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}