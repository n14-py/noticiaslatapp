// Archivo: noticias_lat/lib/screens/noticias_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/core/data/latam_countries.dart';
import 'package:noticias_lat/core/layout/app_metrics.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';
import 'package:noticias_lat/screens/detalle_noticia_screen.dart';

// --- IMPORTAMOS EL CEREBRO DE ANUNCIOS ---
import 'package:noticias_lat/core/services/ad_manager.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  // ==========================================
  // 📦 VARIABLES DE ESTADO Y DATOS
  // ==========================================
  List noticias = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  int paginaActual = 1;
  
  // Variables para el Buscador y Filtro
  String searchQuery = '';
  String selectedCountry = UserPrefs.instance.selectedCountryCode;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _fetchGeneration = 0;

  List<Map<String, String>> get countries =>
      LatamCountries.asFilterMaps(pinCode: UserPrefs.instance.pinnedCountryCode);

  @override
  void initState() {
    super.initState();
    UserPrefs.instance.addListener(_onUserPrefsChanged);
    cargarNoticias(isRefresh: true);
    
    // Listener para la Paginación Infinita (Scroll hacia abajo)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && !isFetchingMore && hasMore) {
        cargarNoticias(isRefresh: false);
      }
    });
  }

  void _onUserPrefsChanged() {
    final next = UserPrefs.instance.selectedCountryCode;
    if (next != selectedCountry) {
      selectedCountry = next;
      noticias.clear();
      cargarNoticias(isRefresh: true);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    UserPrefs.instance.removeListener(_onUserPrefsChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🌐 FUNCIÓN DE CARGA DE NOTICIAS
  // ==========================================
  Future<void> cargarNoticias({bool isRefresh = false}) async {
    if (isRefresh) {
      if (mounted) {
        setState(() {
          isLoading = noticias.isEmpty;
          paginaActual = 1;
          hasMore = true;
        });
      }
    } else {
      if (mounted) setState(() => isFetchingMore = true);
      paginaActual++;
    }

    final int requestId = ++_fetchGeneration;

    String url = 'https://api.noticias.lat/api/articles?sitio=noticias.lat&limite=12&pagina=$paginaActual';

    if (searchQuery.isNotEmpty) url += '&query=$searchQuery';
    if (selectedCountry != 'todos') url += '&pais=$selectedCountry';

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'noticias_json_cache_${selectedCountry}_${searchQuery}_p$paginaActual';

    if (isRefresh && noticias.isEmpty) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final data = json.decode(cachedData);
          final List cachedArticulos = data['articulos'] ?? [];
          if (mounted && cachedArticulos.isNotEmpty && requestId == _fetchGeneration) {
            setState(() {
              noticias = cachedArticulos;
              isLoading = false;
            });
          }
        } catch (e) {
          debugPrint("Error leyendo caché de noticias: $e");
        }
      }
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (isRefresh) {
          prefs.setString(cacheKey, response.body);
        }
        final data = json.decode(response.body);
        final List nuevosArticulos = data['articulos'] ?? [];
        
        if (mounted && requestId == _fetchGeneration) {
          setState(() {
            if (isRefresh) {
              noticias = nuevosArticulos;
            } else {
              noticias.addAll(nuevosArticulos);
            }
            hasMore = nuevosArticulos.length == 12; // Si trae el límite exacto, asumimos que hay más
            isLoading = false;
            isFetchingMore = false;
          });
        }
      } else {
        if (mounted && requestId == _fetchGeneration) setState(() { isLoading = false; isFetchingMore = false; });
      }
    } catch (e) {
      debugPrint("Error al cargar noticias: $e");
      if (mounted && requestId == _fetchGeneration) setState(() { isLoading = false; isFetchingMore = false; });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      noticias.clear();
      isLoading = true;
    });
    cargarNoticias(isRefresh: true);
  }

  void _onCountrySelected(String code) {
    setState(() {
      selectedCountry = code;
      noticias.clear();
      isLoading = true;
    });
    cargarNoticias(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ==========================================
            // 🔍 BARRA DE BÚSQUEDA GLASSMORPHISM
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Buscar noticias...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accentCyan),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // 🌍 FILTRO DE PAÍSES (SCROLL A PRUEBA DE BALAS)
            // ==========================================
            SizedBox(
              height: 45,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), // Fuerza el scroll en Android
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: countries.map((country) {
                    final isSelected = selectedCountry == country['code'];

                    return GestureDetector(
                      onTap: () => _onCountrySelected(country['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentCyan : AppTheme.cardBorder,
                          ),
                        ),
                        child: Text(
                          country['name']!.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // 📰 LISTA DE NOTICIAS (GRID REVISTA CON ANUNCIOS)
            // ==========================================
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
                  : noticias.isEmpty
                      ? const Center(child: Text('No se encontraron noticias.', style: TextStyle(color: AppTheme.textMuted)))
                      : RefreshIndicator(
                          onRefresh: () => cargarNoticias(isRefresh: true),
                          color: AppTheme.accentCyan,
                          backgroundColor: AppTheme.cardDark,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(16, 10, 16, AppMetrics.navClearance(context)),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _calculateItemCount(),
                            // OPTIMIZACIÓN: Desactiva el mantenimiento en memoria de las tarjetas que ya no se ven al scrollear
                            addAutomaticKeepAlives: false,
                            // OPTIMIZACIÓN: Evita repintar toda la lista al deslizar, solo pinta los nuevos elementos
                            addRepaintBoundaries: true,
                            itemBuilder: (context, index) {
                              return _buildMagazineLayout(index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DEL DISEÑO TIPO REVISTA (1 Grande, 2 Chicas, repite) ---
  int _calculateItemCount() {
    int count = (noticias.length / 3).ceil() * 2; 
    if (noticias.length % 3 == 1) count -= 1; 
    if (isFetchingMore) count += 1; 
    return count;
  }

  Widget _buildMagazineLayout(int index) {
    if (isFetchingMore && index == _calculateItemCount() - 1) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
      );
    }

    int listIndex = (index ~/ 2) * 3;
    Widget rowWidget;

    // Fila Par: TARJETA GRANDE
    if (index % 2 == 0) {
      if (listIndex >= noticias.length) return const SizedBox.shrink();
      rowWidget = _buildBigCard(noticias[listIndex]).animate().fade().slideY(begin: 0.1, end: 0);
    } 
    // Fila Impar: 2 TARJETAS CHICAS
    else {
      rowWidget = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            if (listIndex + 1 < noticias.length)
              Expanded(child: _buildSmallCard(noticias[listIndex + 1]).animate().fade().slideX(begin: -0.1, end: 0)),
            if (listIndex + 2 < noticias.length) ...[
              const SizedBox(width: 16),
              Expanded(child: _buildSmallCard(noticias[listIndex + 2]).animate().fade().slideX(begin: 0.1, end: 0)),
            ] else ...[
              const SizedBox(width: 16),
              Expanded(child: Container()), 
            ]
          ],
        ),
      );
    }

    // --- INYECTAR ANUNCIO ADMOB CADA 4 FILAS ---
    if (index > 0 && index % 4 == 0) {
      return Column(
        children: [
          AdManager.getBannerAdWidget(), // El anuncio de Google
          const SizedBox(height: 16),
          rowWidget,
        ],
      );
    }

    return rowWidget;
  }

  // ==========================================
  // 🖼️ TARJETA GRANDE DESTACADA
  // ==========================================
  Widget _buildBigCard(Map item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetalleNoticiaScreen(noticia: item))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.cardBorder, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item['imagen'] ?? '',
              fit: BoxFit.cover,
              // OPTIMIZACIÓN CRÍTICA: Límite de tamaño en caché para que no renderice imágenes gigantes y se caliente el procesador
              memCacheHeight: 600,
              memCacheWidth: 600,
              placeholder: (context, url) => Container(color: AppTheme.cardDark),
              errorWidget: (context, url, error) => Container(color: AppTheme.cardDark),
            ),
            Container(decoration: BoxDecoration(gradient: AppTheme.darkFadeGradient)),
            
            // ETIQUETA DE FUENTE EN ESQUINA SUPERIOR
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      item['fuente']?.toString().toUpperCase() ?? 'NOTICIAS.LAT',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.accentCyan, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      item['categoria']?.toString().toUpperCase() ?? 'GENERAL',
                      style: const TextStyle(color: AppTheme.bgDark, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['titulo'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.2),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🖼️ TARJETAS PEQUEÑAS LADO A LADO
  // ==========================================
  Widget _buildSmallCard(Map item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetalleNoticiaScreen(noticia: item))),
      child: Container(
        height: 235, 
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CachedNetworkImage(
                imageUrl: item['imagen'] ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                // OPTIMIZACIÓN CRÍTICA: Tarjetas pequeñas ocupan aún menos RAM
                memCacheHeight: 400,
                memCacheWidth: 400,
                placeholder: (context, url) => Container(color: AppTheme.cardBorder),
                errorWidget: (context, url, error) => Container(color: AppTheme.cardBorder),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CATEGORÍA Y FUENTE (JUNTOS)
                    Row(
                      children: [
                        Text(
                          item['categoria']?.toString().toUpperCase() ?? 'GENERAL',
                          style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Icon(Icons.language_rounded, color: AppTheme.textMuted.withValues(alpha: 0.8), size: 10),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item['fuente']?.toString().toUpperCase() ?? 'WEB',
                            style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['titulo'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14, height: 1.2),
                      maxLines: 4, overflow: TextOverflow.ellipsis,
                    ),
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