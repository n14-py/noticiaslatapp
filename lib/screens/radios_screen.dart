// Archivo: noticias_lat/lib/screens/radios_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/core/data/latam_countries.dart';
import 'package:noticias_lat/core/layout/app_metrics.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';

// --- IMPORTAMOS EL CEREBRO DE ANUNCIOS ---
import 'package:noticias_lat/core/services/ad_manager.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  // ==========================================
  // 📦 VARIABLES DE ESTADO Y DATOS
  // ==========================================
  List todosLosAudios = [];
  List audiosFiltrados = [];
  bool isLoading = true;

  // Filtros activos
  String paisSeleccionado = UserPrefs.instance.selectedCountryCode;
  String categoriaSeleccionada = 'todas';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> get paises =>
      LatamCountries.asFilterMaps(pinCode: UserPrefs.instance.pinnedCountryCode);

  final List<String> categorias = ['todas', 'politica', 'economia', 'deportes', 'tecnologia', 'salud', 'general'];

  // Reproductor de Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map? audioActual;
  bool isPlaying = false;
  Duration duracionTotal = Duration.zero;
  Duration posicionActual = Duration.zero;

  // Contador para monetización
  int cambiosDeRadio = 0;
  bool _pausedByAd = false;

  @override
  void initState() {
    super.initState();
    _cargarAudios();
    UserPrefs.instance.addListener(_onUserPrefsChanged);
    AdManager.isFullscreenAdVisible.addListener(_onFullscreenAdChanged);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => duracionTotal = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => posicionActual = newPosition);
    });
    
    // REPRODUCCIÓN CONTINUA AUTOMÁTICA
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        _playNext();
      }
    });
  }

  void _onUserPrefsChanged() {
    final next = UserPrefs.instance.selectedCountryCode;
    if (next != paisSeleccionado) {
      paisSeleccionado = next;
      if (todosLosAudios.isNotEmpty) {
        _aplicarFiltros();
      }
    } else if (mounted) {
      setState(() {});
    }
  }

  void _onFullscreenAdChanged() async {
    if (AdManager.isFullscreenAdVisible.value) {
      if (isPlaying) {
        _pausedByAd = true;
        await _audioPlayer.pause();
      }
    } else if (_pausedByAd) {
      _pausedByAd = false;
      await _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    UserPrefs.instance.removeListener(_onUserPrefsChanged);
    AdManager.isFullscreenAdVisible.removeListener(_onFullscreenAdChanged);
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==========================================
  // 🌐 CARGAR AUDIOS DE LA API
  // ==========================================
  Future<void> _cargarAudios() async {
    setState(() => isLoading = true);
    const url = 'https://api.noticias.lat/api/articles?sitio=noticias.lat&limite=200';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articulos = data['articulos'] ?? [];

        // Filtramos solo los que tienen audio url
        todosLosAudios = articulos.where((a) => a['audioUrl'] != null && a['audioUrl'].toString().isNotEmpty).toList();
        
        _aplicarFiltros();
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error cargando audios: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _aplicarFiltros() {
    setState(() {
      audiosFiltrados = todosLosAudios.where((audio) {
        bool pasaPais = paisSeleccionado == 'todos' || audio['pais'] == paisSeleccionado;
        bool pasaCategoria = categoriaSeleccionada == 'todas' || audio['categoria'] == categoriaSeleccionada;
        bool pasaBusqueda = searchQuery.isEmpty || 
                            (audio['titulo'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());

        return pasaPais && pasaCategoria && pasaBusqueda;
      }).toList();

      isLoading = false;
    });
  }

  // ==========================================
  // 🎵 CONTROLES DEL REPRODUCTOR Y MONETIZACIÓN
  // ==========================================
  void _playAudio(Map audio) async {
    // Si tocan la misma canción que está sonando, solo pausamos/reanudamos
    if (audioActual != null && audioActual!['_id'] == audio['_id']) {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      // 💰 MONETIZACIÓN: Mostrar Intersticial cada 5 cambios de radio manuales
      cambiosDeRadio++;
      if (cambiosDeRadio % 5 == 0) {
        AdManager.showInterstitial();
      }

      setState(() {
        audioActual = audio;
        posicionActual = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(audio['audioUrl']));
      if (AdManager.isFullscreenAdVisible.value) {
        _pausedByAd = true;
        await _audioPlayer.pause();
      }
    }
  }

  void _playNext() {
    if (audioActual == null || audiosFiltrados.isEmpty) return;
    int currentIndex = audiosFiltrados.indexWhere((a) => a['_id'] == audioActual!['_id']);
    
    if (currentIndex != -1 && currentIndex + 1 < audiosFiltrados.length) {
      _playAudio(audiosFiltrados[currentIndex + 1]);
    } else {
      setState(() {
        isPlaying = false;
        posicionActual = Duration.zero;
      });
    }
  }

  void _playPrevious() {
    if (audioActual == null || audiosFiltrados.isEmpty) return;
    int currentIndex = audiosFiltrados.indexWhere((a) => a['_id'] == audioActual!['_id']);
    
    // Si han pasado más de 3 segundos, retrocede al inicio del audio
    if (posicionActual.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
    } else if (currentIndex > 0) {
      // Si no, pasa al audio anterior
      _playAudio(audiosFiltrados[currentIndex - 1]);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. CABECERA Y BUSCADOR PREMIUM
              SliverAppBar(
                backgroundColor: AppTheme.bgDark.withValues(alpha: 0.95),
                pinned: true,
                floating: true,
                elevation: 10,
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.podcasts_rounded, color: AppTheme.accentCyan, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'RADIO LATAM', 
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 1.5,
                                  fontSize: 24,
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Escucha las noticias del día, una tras otra.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          // BUSCADOR
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Buscar noticia o tema...',
                                hintStyle: const TextStyle(color: AppTheme.textMuted),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            searchQuery = '';
                                            _aplicarFiltros();
                                          });
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                  _aplicarFiltros();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. FILTROS HORIZONTALES ELEGANTES Y ANUNCIO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPillsSelector(
                        categorias.map((c) => {'name': c.toUpperCase(), 'code': c}).toList(), 
                        categoriaSeleccionada, 
                        (val) { categoriaSeleccionada = val; _aplicarFiltros(); }
                      ),
                      const SizedBox(height: 12),
                      _buildPillsSelector(
                        paises, 
                        paisSeleccionado, 
                        (val) { paisSeleccionado = val; _aplicarFiltros(); }
                      ),
                      
                      // BOTÓN DE REPRODUCIR TODO
                      if (audiosFiltrados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: InkWell(
                            onTap: () {
                              if (audiosFiltrados.isNotEmpty) {
                                _playAudio(audiosFiltrados.first);
                              }
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppTheme.neonGradient,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: AppTheme.glowShadow,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: AppTheme.bgDark, size: 28),
                                  SizedBox(width: 8),
                                  Text(
                                    'REPRODUCIR TODO',
                                    style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                      // --- BANNER DE PUBLICIDAD EN LA RADIO ---
                      const SizedBox(height: 10),
                      AdManager.getBannerAdWidget(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // 3. LISTA DE PODCASTS / AUDIOS
              isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)))
                  : audiosFiltrados.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic_off_rounded, size: 60, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                const Text('No hay audios para estos filtros.', style: TextStyle(color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = audiosFiltrados[index];
                              final bool isThisPlaying = audioActual != null && audioActual!['_id'] == item['_id'];
                              return _buildAudioEpisodeCard(item, isThisPlaying, index);
                            },
                            childCount: audiosFiltrados.length,
                            // OPTIMIZACIÓN CRÍTICA: Libera la RAM al desechar tarjetas que salen de la pantalla
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                          ),
                        ),

              // Espacio extra al final para que el mini-reproductor no tape la última noticia
              SliverToBoxAdapter(child: SizedBox(height: AppMetrics.navClearance(context) + 80)),
            ],
          ),

          // ==========================================
          // 4. MINI REPRODUCTOR FLOTANTE (ALTURA SEGURA)
          // ==========================================
          if (audioActual != null)
            Positioned(
              bottom: AppMetrics.navClearance(context), 
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accentCyan.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 3,
                          child: LinearProgressIndicator(
                            value: duracionTotal.inSeconds > 0 ? posicionActual.inSeconds / duracionTotal.inSeconds : 0.0,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: audioActual!['imagen'] ?? '',
                                  width: 45, height: 45, fit: BoxFit.cover,
                                  // OPTIMIZACIÓN: Ahorra RAM en la miniatura
                                  memCacheHeight: 100,
                                  memCacheWidth: 100,
                                  placeholder: (context, url) => Container(color: Colors.white10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      audioActual!['titulo'] ?? '', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatDuration(posicionActual)} / ${_formatDuration(duracionTotal)}', 
                                      style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 28),
                                    onPressed: _playPrevious,
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _playAudio(audioActual!),
                                    child: Container(
                                      height: 40, width: 40,
                                      decoration: const BoxDecoration(color: AppTheme.accentCyan, shape: BoxShape.circle),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                                        color: AppTheme.bgDark, size: 28
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                                    onPressed: _playNext,
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  // ==========================================
  // 🎛️ WIDGETS AUXILIARES DE DISEÑO
  // ==========================================

  // AQUÍ ESTÁ LA SOLUCIÓN DEL SCROLL: SingleChildScrollView + Row
  Widget _buildPillsSelector(List<Map<String, String>> items, String selectedValue, Function(String) onSelect) {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), // Fuerza el scroll en Android
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: items.map((item) {
            final isSelected = selectedValue == item['code'];
            return GestureDetector(
              onTap: () => onSelect(item['code']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentCyan : AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppTheme.accentCyan : AppTheme.cardBorder),
                  boxShadow: isSelected ? AppTheme.glowShadow : [],
                ),
                child: Text(
                  item['name']!, 
                  style: TextStyle(
                    color: isSelected ? AppTheme.bgDark : Colors.white70, 
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                    letterSpacing: isSelected ? 0.5 : 0,
                  )
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAudioEpisodeCard(Map item, bool isThisPlaying, int index) {
    return InkWell(
      onTap: () => _playAudio(item),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isThisPlaying ? AppTheme.accentCyan.withValues(alpha: 0.05) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isThisPlaying ? AppTheme.accentCyan : AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: isThisPlaying
                  ? const Icon(Icons.multitrack_audio_rounded, color: AppTheme.accentCyan, size: 20)
                  : Text('${index + 1}', style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item['imagen'] ?? '', 
                width: 65, height: 65, fit: BoxFit.cover,
                // OPTIMIZACIÓN: Ahorra RAM al no decodificar imágenes gigantes en miniaturas
                memCacheHeight: 150,
                memCacheWidth: 150,
                placeholder: (context, url) => Container(color: Colors.white10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['pais']?.toUpperCase()} • ${item['categoria']?.toUpperCase()}', 
                    style: TextStyle(color: isThisPlaying ? AppTheme.accentCyan : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['titulo'] ?? '', 
                    style: TextStyle(color: isThisPlaying ? AppTheme.accentCyan : Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2), 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                isThisPlaying && isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded, 
                color: isThisPlaying ? AppTheme.accentCyan : Colors.white54, 
                size: 32
              ),
            ),
          ],
        ),
      ),
    );
  }
}