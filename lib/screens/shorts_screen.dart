// Archivo: noticias_lat/lib/screens/shorts_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/widgets/short_video_player.dart';
// --- IMPORTAMOS LOS SERVICIOS DE MONETIZACIÓN Y PREMIUM ---
import 'package:noticias_lat/core/services/premium_manager.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  // ========================================================
  //   VARIABLES DE ESTADO Y DATOS
  // ========================================================
  List todosLosShorts = [];
  List shortsFiltrados = [];
  bool isLoading = true;

  // Control de reproducción y monetización
  int currentIndex = 0;
  int shortsVistos = 0; // Se incrementa cada vez que el usuario desliza

  // Controladores de búsqueda y filtros
  bool mostrarBuscador = false;
  String categoriaSeleccionada = 'todas';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  // Lista de categorías para el filtro superior
  final List<String> categorias = [
    'todas', 
    'politica', 
    'economia', 
    'deportes', 
    'tecnologia', 
    'general',
    'salud',
    'entretenimiento'
  ];

  // Estado para la tarjeta de resumen IA flotante dentro del Short
  bool mostrarResumenIA = false;
  String resumenIAActual = '';
  bool _isLiking = false; // Para la animación de Me Gusta

  @override
  void initState() {
    super.initState();
    _cargarShorts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ========================================================
  //   CARGAR SHORTS (CON CACHÉ JSON INSTANTÁNEO)
  // ========================================================
  Future<void> _cargarShorts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('shorts_json_cache');

    // 1. Si hay caché, cargamos AL INSTANTE
    if (cachedData != null) {
      final data = json.decode(cachedData);
      _procesarListaDeArticulos(data['articulos'] ?? []);
    } else {
      setState(() => isLoading = true);
    }

    // 2. Buscamos actualizaciones silenciosamente en segundo plano
    const url = 'https://api.noticias.lat/api/articles?sitio=noticias.lat&limite=100';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Guardamos el nuevo JSON en el celular para la próxima vez
        prefs.setString('shorts_json_cache', response.body);
        
        final data = json.decode(response.body);
        _procesarListaDeArticulos(data['articulos'] ?? []);
      } else {
        if (mounted && cachedData == null) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error cargando shorts: $e");
      if (mounted && cachedData == null) setState(() => isLoading = false);
    }
  }

  void _procesarListaDeArticulos(List articulos) {
    if (!mounted) return;
    todosLosShorts = articulos.where((a) {
      final tieneVideo = a['videoUrl'] != null && a['videoUrl'].toString().isNotEmpty;
      final esShortLink = (a['enlaceOriginal'] ?? '').toString().contains('#short');
      return tieneVideo || esShortLink;
    }).toList();
    _aplicarFiltros();
  }

  // ========================================================
  //  LÓGICA DE FILTRADO Y BÚSQUEDA
  // ========================================================
  void _aplicarFiltros() {
    setState(() {
      shortsFiltrados = todosLosShorts.where((short) {
        // Filtrar por categoría
        bool pasaCategoria = categoriaSeleccionada == 'todas' || 
                             short['categoria']?.toString().toLowerCase() == categoriaSeleccionada;
        
        // Filtrar por texto ingresado en el buscador
        bool pasaBusqueda = searchQuery.isEmpty || 
                            (short['titulo'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                            (short['descripcion'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
        
        return pasaCategoria && pasaBusqueda;
      }).toList();
      
      isLoading = false;
      mostrarResumenIA = false; // Resetear panel IA al filtrar para evitar errores visuales
    });
  }

  // ========================================================
  //  LÓGICA DE MONETIZACIÓN: SIN CRÉDITOS IA
  // ========================================================
  void _mostrarDialogoSinCreditos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 2)
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 10),
            Text('¡Sin Energía IA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: const Text(
          'Te has quedado sin usos de la Inteligencia Artificial.\n\n¿Quieres ver un video corto para recargar 5 usos inmediatamente y ver este resumen?',
          style: TextStyle(color: AppTheme.textMuted, height: 1.5, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54, fontSize: 16))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () {
              Navigator.pop(context); // Cerramos el diálogo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cargando anuncio premium...', style: TextStyle(color: Colors.white)))
              );
              
              // Llamamos al AdManager para mostrar el anuncio con recompensa
              AdManager.showRewarded(
                onRewardEarned: () async {
                  // Le damos los 5 créditos y lo contamos para el Premium
                  await PremiumManager.agregarCreditosIA(5);
                  await PremiumManager.registrarAnuncioVistoParaPremium();
                  
                  if (mounted) {
                    setState(() {
                      mostrarResumenIA = true; // Mostramos el resumen como recompensa inmediata
                    });
                  }
                },
                onAdClosed: () {
                  // Actualizamos la UI al cerrar el anuncio
                  if (mounted) setState(() {}); 
                }
              );
            },
            child: const Text('Ver Anuncio', style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro puro para los Shorts
      body: Stack(
        children: [
          // ========================================================
          // 1. REPRODUCTOR DE VIDEO DE SHORTS (SCROLL VERTICAL)
          // ========================================================
          isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
              : shortsFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_camera_back_rounded, size: 70, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 20),
                          const Text('No hay Shorts disponibles', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Intenta con otra categoría o término de búsqueda.', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: shortsFiltrados.length,
                      // OPTIMIZACIÓN CRÍTICA: Mantiene la RAM baja al no renderizar widgets fantasma
                      allowImplicitScrolling: false,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                          mostrarResumenIA = false; // Ocultamos el resumen anterior
                          _isLiking = false;
                        });
                        
                        // LÓGICA DE MONETIZACIÓN: Intersticial cada 10 shorts vistos
                        shortsVistos++;
                        if (shortsVistos % 10 == 0) {
                          AdManager.showInterstitial();
                        }
                      },
                      itemBuilder: (context, index) {
                        final short = shortsFiltrados[index];
                        final bool isActive = index == currentIndex;
                        // NUEVA MAGIA: El video se precarga si está justo antes o justo después del actual
                        final bool isPreloading = (index == currentIndex - 1) || (index == currentIndex + 1);

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // EL REPRODUCTOR DE VIDEO NATIVO CON PRECARGA
                            ShortVideoPlayer(
                              videoUrl: short['videoUrl'] ?? '', 
                              isActive: isActive,
                              isPreloading: isPreloading,
                            ),
                            // GRADIENTE INFERIOR: Asegura que el texto blanco siempre se lea perfecto
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.5), // Arriba (Para el buscador)
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.9), // Abajo (Para títulos y botones)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.2, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // --- TEXTOS DEL VIDEO: TÍTULO, CATEGORÍA, FUENTE ---
                            Positioned(
                              bottom: 110, // Separado del menú inferior
                              left: 16, 
                              right: 84, // Deja espacio para los botones de la derecha
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Etiqueta de Categoría Neón
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentCyan.withValues(alpha: 0.15), 
                                      borderRadius: BorderRadius.circular(6), 
                                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4))
                                    ),
                                    child: Text(
                                      short['categoria']?.toString().toUpperCase() ?? 'SHORT', 
                                      style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Título de la Noticia Viral
                                  Text(
                                    short['titulo'] ?? '', 
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold, 
                                      height: 1.3, 
                                      shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))]
                                    ), 
                                    maxLines: 3, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Fuente del contenido
                                  Row(
                                    children: [
                                      const Icon(Icons.language_rounded, color: Colors.white70, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Fuente: ${short['fuente']?.toString().toUpperCase() ?? 'WEB'}', 
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // --- BOTONES INTERACTIVOS LATERALES (IA, LIKE, SHARE) ---
                            Positioned(
                              bottom: 115, 
                              right: 16,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 🤖 BOTÓN IA CON VERIFICACIÓN DE CRÉDITOS
                                  _buildSidebarButton(
                                    icon: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? Icons.auto_awesome_rounded : Icons.bolt_rounded,
                                    label: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? 'Resumen' : 'Energía',
                                    iconColor: PremiumManager.isPremium() || PremiumManager.getAiCredits() > 0 ? AppTheme.accentCyan : Colors.orange,
                                    badgeText: PremiumManager.isPremium() ? '∞' : (PremiumManager.getAiCredits() > 0 ? PremiumManager.getAiCredits().toString() : null),
                                    onTap: () async {
                                      // Intentamos gastar 1 crédito localmente
                                      bool tieneSaldo = await PremiumManager.usarCreditoIA();
                                      
                                      if (tieneSaldo) {
                                        setState(() {
                                          resumenIAActual = short['aiSummary'] ?? 'Resumen no disponible para este short.';
                                          mostrarResumenIA = !mostrarResumenIA;
                                        });
                                      } else {
                                        // No tiene saldo, mostramos popup para ganar créditos
                                        _mostrarDialogoSinCreditos();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // ❤️ BOTÓN ME GUSTA CON ANIMACIÓN
                                  _buildSidebarButton(
                                    icon: _isLiking ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                    label: 'Me Gusta', 
                                    iconColor: _isLiking ? Colors.redAccent : Colors.white, 
                                    onTap: () {
                                      setState(() => _isLiking = !_isLiking);
                                      if (_isLiking) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en favoritos ❤️')));
                                      }
                                    }
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // 🔗 BOTÓN COMPARTIR
                                  _buildSidebarButton(
                                    icon: Icons.share_rounded, 
                                    label: 'Compartir', 
                                    iconColor: Colors.white, 
                                    onTap: () {}
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

          // ========================================================
          // 2. HEADER FLOTANTE CON BUSCADOR Y FILTROS
          // ========================================================
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título Superior y Botón de Lupa
                      Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, color: AppTheme.accentCyan, size: 24),
                          const SizedBox(width: 8),
                          const Text('SHORTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(mostrarBuscador ? Icons.close_rounded : Icons.search_rounded, color: Colors.white, size: 28), 
                            onPressed: () {
                              setState(() {
                                mostrarBuscador = !mostrarBuscador;
                                if (!mostrarBuscador) {
                                  _searchController.clear();
                                  searchQuery = '';
                                  _aplicarFiltros();
                                }
                              });
                            }
                          ),
                        ],
                      ),
                      
                      // Buscador Desplegable (Solo se ve si tocaron la lupa)
                      if (mostrarBuscador) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15), 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2))
                          ),
                          child: TextField(
                            controller: _searchController, 
                            style: const TextStyle(color: Colors.white, fontSize: 15), 
                            decoration: const InputDecoration(
                              hintText: 'Buscar palabras clave...', 
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14), 
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 22), 
                              border: InputBorder.none, 
                              contentPadding: EdgeInsets.symmetric(vertical: 14)
                            ), 
                            onChanged: (value) {
                              searchQuery = value;
                              _aplicarFiltros();
                            }
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Cápsulas Horizontales de Categorías
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal, 
                          physics: const BouncingScrollPhysics(), 
                          itemCount: categorias.length,
                          itemBuilder: (context, index) {
                            final cat = categorias[index];
                            final bool isSelected = categoriaSeleccionada == cat;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  categoriaSeleccionada = cat;
                                  _aplicarFiltros();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300), 
                                margin: const EdgeInsets.only(right: 10), 
                                padding: const EdgeInsets.symmetric(horizontal: 18), 
                                alignment: Alignment.center, 
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.accentCyan : Colors.black.withValues(alpha: 0.5), 
                                  borderRadius: BorderRadius.circular(20), 
                                  border: Border.all(color: isSelected ? AppTheme.accentCyan : Colors.white24)
                                ), 
                                child: Text(
                                  cat.toUpperCase(), 
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.bgDark : Colors.white70, 
                                    fontSize: 12, 
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                    letterSpacing: 0.5
                                  )
                                )
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========================================================
          // 3. TARJETA FLOTANTE DE RESUMEN IA
          // ========================================================
          if (mostrarResumenIA)
            Positioned(
              bottom: 120, // Aparece justo por encima de los textos del video
              left: 16, 
              right: 84, // No tapa los botones laterales
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withValues(alpha: 0.85), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accentCyan.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentCyan, size: 20), 
                            const SizedBox(width: 8),
                            const Text('RESUMEN IA', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)), 
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => mostrarResumenIA = false),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          resumenIAActual, 
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5), 
                          maxLines: 8, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========================================================
  //   WIDGET REUTILIZABLE: BOTONES LATERALES DE SHORTS
  // ========================================================
  Widget _buildSidebarButton({
    required IconData icon, 
    required String label, 
    required Color iconColor, 
    String? badgeText,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 52, 
                width: 52, 
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5), 
                  shape: BoxShape.circle, 
                  border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5)
                ), 
                child: Icon(icon, color: iconColor, size: 26)
              ),
              
              // Pequeño indicador de créditos encima del botón (si existe)
              if (badgeText != null)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5)
                    ),
                    child: Text(
                      badgeText, 
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))]
            )
          ),
        ],
      ),
    );
  }
}