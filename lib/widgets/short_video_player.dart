// Archivo: noticias_lat/lib/widgets/short_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';

class ShortVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive; // Controla si el video es el que el usuario está viendo
  final bool isPreloading; // NUEVO: Controla si el video es el próximo o el anterior para pre-cargarlo

  const ShortVideoPlayer({
    super.key, 
    required this.videoUrl, 
    required this.isActive,
    this.isPreloading = false, // Por defecto en false para no romper la app hasta el siguiente paso
  });

  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false; 
  bool _isInitializing = false; 
  
  double _currentVisibility = 0.0; 

  late AnimationController _playPauseAnimController;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _playPauseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // OPTIMIZACIÓN EXTREMA: Solo descargamos el video si está en pantalla O si es el video que sigue
    if (widget.isActive || widget.isPreloading) {
      _initializeVideo();
    }
  }

  // Inicializa y descarga el video en segundo plano
  void _initializeVideo() {
    if (_isInitializing || _isInitialized || _controller != null) return;
    _isInitializing = true;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isInitializing = false;
            _controller!.setLooping(true);
          });
          // Si cuando terminó de cargar resulta que es el activo, que empiece a sonar
          _checkPlayOrPause(); 
        }
      }).catchError((error) {
        _isInitializing = false;
        debugPrint("Error inicializando video: $error");
      });
  }

  // NUEVO: Destruye el video de la RAM si el usuario ya se alejó mucho de él
  void _disposeVideo() {
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _isInitializing = false;
        _isPlaying = false;
      });
    }
  }

  @override
  void didUpdateWidget(ShortVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Evaluamos si el video DEBE estar cargado en RAM (activo o en precarga)
    final bool shouldBeReady = widget.isActive || widget.isPreloading;
    final bool wasReady = oldWidget.isActive || oldWidget.isPreloading;

    // Si nos acercamos al video, lo inicializamos en silencio
    if (shouldBeReady && !wasReady) {
      _initializeVideo();
    } 
    // Si nos alejamos mucho del video (quedó atrás), LO BORRAMOS DE LA RAM
    else if (!shouldBeReady && wasReady) {
      _disposeVideo();
    }

    // Lógica para pausar o reproducir al cambiar de página
    if (_isInitialized && _controller != null) {
      if (widget.isActive != oldWidget.isActive) {
        _checkPlayOrPause(); 
        
        // Si deja de verse pero sigue en caché (isPreloading), retrocedemos a 0
        if (!widget.isActive && widget.isPreloading) {
          _controller!.seekTo(Duration.zero);
        }
      }
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _playPauseAnimController.dispose();
    super.dispose();
  }

  void _checkPlayOrPause() {
    if (!mounted || !_isInitialized || _controller == null) return;
    
    // Solo reproduce si es el video activo Y la pantalla está visible
    if (_currentVisibility > 0.6 && widget.isActive) {
      if (!_controller!.value.isPlaying) {
        _controller!.play();
        setState(() => _isPlaying = true);
      }
    } else {
      // Pausa obligatoria
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized || _controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
      
      _showPlayPauseIcon = true;
      _playPauseAnimController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _showPlayPauseIcon = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        _currentVisibility = info.visibleFraction; 
        _checkPlayOrPause(); 
      },
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. FONDO NEGRO
            Container(color: Colors.black),
            
            // 2. REPRODUCTOR O CARGADOR
            _isInitialized && _controller != null
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.accentCyan),
                        const SizedBox(height: 12),
                        Text(
                          widget.isActive ? 'Cargando video...' : 'Alistando...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5), 
                            fontSize: 12
                          ),
                        )
                      ],
                    ),
                  ),

            // 3. ANIMACIÓN PLAY/PAUSA
            if (_showPlayPauseIcon)
              Center(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_playPauseAnimController),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.5).animate(_playPauseAnimController),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),

            // 4. BARRA DE PROGRESO NEÓN
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _isInitialized && _controller != null
                  ? VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: EdgeInsets.zero,
                      colors: const VideoProgressColors(
                        playedColor: AppTheme.accentCyan,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.transparent,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}