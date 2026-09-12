// Archivo: noticias_lat/lib/widgets/ai_summary_card.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';

class AiSummaryCard extends StatefulWidget {
  final String resumen;
  final String? audioUrl;
  final bool modoSoloAudio; // NUEVO: Para saber si mostramos texto o reproductor
  final VoidCallback? onClose; // NUEVO: Para poder cerrar la tarjeta

  const AiSummaryCard({
    super.key, 
    required this.resumen, 
    this.audioUrl,
    this.modoSoloAudio = false,
    this.onClose,
  });

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duracionTotal = Duration.zero;
  Duration posicionActual = Duration.zero;
  bool isAudioLoading = false;
  bool _pausedByAd = false;

  @override
  void initState() {
    super.initState();
    AdManager.isFullscreenAdVisible.addListener(_onFullscreenAdChanged);
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _setupAudio();
      // Autoplay si se abre en modo solo audio
      if (widget.modoSoloAudio) {
        _toggleAudio();
      }
    }
  }

  void _setupAudio() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
          isAudioLoading = false;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => duracionTotal = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => posicionActual = newPosition);
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          posicionActual = Duration.zero;
        });
      }
    });
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
    AdManager.isFullscreenAdVisible.removeListener(_onFullscreenAdChanged);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleAudio() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;
    
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => isAudioLoading = true);
        await _audioPlayer.play(UrlSource(widget.audioUrl!));
      }
    } catch (e) {
      debugPrint("Error reproduciendo audio IA: $e");
      setState(() => isAudioLoading = false);
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // CABECERA DINÁMICA (Cambia según si es Audio o Texto)
              Row(
                children: [
                  Icon(
                    widget.modoSoloAudio ? Icons.headphones_rounded : Icons.auto_awesome_rounded, 
                    color: AppTheme.accentCyan, 
                    size: 24
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.modoSoloAudio ? 'ESCUCHAR NOTICIA' : 'RESUMEN INTELIGENTE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _audioPlayer.pause(); // Pausar audio al cerrar la tarjeta
                      if (widget.onClose != null) widget.onClose!();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // VISTA DE TEXTO (Solo se muestra si modoSoloAudio es false)
              if (!widget.modoSoloAudio)
                Text(
                  widget.resumen,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                        fontSize: 15,
                      ),
                ),
              
              // VISTA DE AUDIO (Solo se muestra si modoSoloAudio es true y hay audio)
              if (widget.modoSoloAudio && widget.audioUrl != null && widget.audioUrl!.isNotEmpty)
                Row(
                  children: [
                    // Botón Play/Pause Neón
                    GestureDetector(
                      onTap: _toggleAudio,
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying ? AppTheme.accentCyan : AppTheme.accentCyan.withValues(alpha: 0.1),
                          border: Border.all(color: AppTheme.accentCyan),
                          boxShadow: isPlaying ? [AppTheme.glowShadow.first] : [],
                        ),
                        child: isAudioLoading
                            ? const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentCyan,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isPlaying ? AppTheme.bgDark : AppTheme.accentCyan,
                                size: 30,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Barra de progreso y tiempos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reproduciendo...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatDuration(posicionActual),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: AppTheme.accentCyan,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppTheme.accentCyan,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: duracionTotal.inSeconds.toDouble() > 0 ? duracionTotal.inSeconds.toDouble() : 1.0,
                                    value: posicionActual.inSeconds.toDouble().clamp(
                                        0.0,
                                        duracionTotal.inSeconds.toDouble() > 0
                                            ? duracionTotal.inSeconds.toDouble()
                                            : 1.0),
                                    onChanged: (value) async {
                                      final position = Duration(seconds: value.toInt());
                                      await _audioPlayer.seek(position);
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(duracionTotal),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
  }
}