import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:noticias_lat/core/data/latam_countries.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';
import 'package:noticias_lat/core/services/country_detector.dart';
import 'package:noticias_lat/core/services/json_feed_cache.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const WelcomeScreen({super.key, required this.onFinished});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _detecting = false;
  String? _countryCode;

  LatamCountry? get _country => LatamCountries.byCode(_countryCode);

  @override
  void initState() {
    super.initState();
    AdManager.suppressAds();
    JsonFeedCache.warmInBackground();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _detectCountry() async {
    setState(() => _detecting = true);
    final detected = await CountryDetector.detect(requestLocation: true);
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _countryCode = detected?.code;
    });
  }

  Future<void> _skipLocation() async {
    setState(() => _detecting = true);
    final detected = await CountryDetector.detect(requestLocation: false);
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _countryCode = detected?.code;
    });
  }

  Future<void> _finish({required bool personalize}) async {
    final canPin = personalize && LatamCountries.isSupported(_countryCode);
    await UserPrefs.instance.completeWelcome(
      countryCode: canPin ? _countryCode : null,
      personalize: canPin,
    );
    AdManager.enableAdsAfterWelcome();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final compact = size.height < 720;

    return Material(
      color: AppTheme.bgDark,
      child: Stack(
        children: [
          const _GlowBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 8 : 16, 20, 12 + bottom),
              child: Column(
                children: [
                  _Dots(count: 3, index: _page),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (value) => setState(() => _page = value),
                      children: [
                        _IntroPage(compact: compact, onNext: () => _goTo(1)),
                        _GuidePage(compact: compact, onNext: () => _goTo(2)),
                        _CountryPage(
                          compact: compact,
                          detecting: _detecting,
                          country: _country,
                          onDetect: _detectCountry,
                          onSkipLocation: _skipLocation,
                          onFinish: _finish,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBackground extends StatelessWidget {
  const _GlowBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppTheme.bgDark),
        Positioned(
          top: -80,
          right: -60,
          child: _GlowOrb(size: 240, color: AppTheme.accentCyan.withValues(alpha: 0.12)),
        ),
        Positioned(
          bottom: 80,
          left: -70,
          child: _GlowOrb(size: 220, color: const Color(0xFF007BFF).withValues(alpha: 0.14)),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 7,
          width: selected ? 22 : 7,
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentCyan : Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final bool compact;
  final VoidCallback onNext;
  const _IntroPage({required this.compact, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: compact ? 12 : 28),
                Image.asset(
                  'assets/images/logo.png',
                  height: compact ? 88 : 112,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.accentCyan,
                    size: 88,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.86, 0.86), curve: Curves.easeOutBack),
                SizedBox(height: compact ? 20 : 32),
                Text(
                  'Bienvenido a\nNoticias LAT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: compact ? 28 : 34,
                        height: 1.12,
                      ),
                ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Toda Latinoamérica, en un solo lugar. Noticias, videos y radio para arrancar el día.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                ).animate().fadeIn(delay: 280.ms),
              ],
            ),
          ),
        ),
        _PrimaryButton(label: 'Comenzar', onTap: onNext),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GuidePage extends StatelessWidget {
  final bool compact;
  final VoidCallback onNext;
  const _GuidePage({required this.compact, required this.onNext});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_rounded, 'Noticias', 'Titulares de la región. Filtrá por país o buscá un tema.'),
      (Icons.play_circle_fill_rounded, 'TV', 'Shorts y videos cortos de lo que está pasando.'),
      (Icons.podcasts_rounded, 'Radio', 'Escuchá las noticias en audio, una detrás de otra.'),
      (Icons.person_rounded, 'Perfil', 'Activá Premium y aprovechá la inteligencia artificial.'),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: compact ? 8 : 16),
                Text(
                  'Así se usa',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: compact ? 26 : 30,
                      ),
                ).animate().fadeIn().slideX(begin: -0.08, end: 0),
                const SizedBox(height: 8),
                const Text(
                  'Cuatro secciones. Todo queda a un toque.',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 18),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GuideCard(icon: item.$1, title: item.$2, text: item.$3)
                        .animate()
                        .fadeIn(delay: (90 * index).ms)
                        .slideY(begin: 0.12, end: 0),
                  );
                }),
              ],
            ),
          ),
        ),
        _PrimaryButton(label: 'Siguiente', onTap: onNext),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _GuideCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentCyan.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: AppTheme.accentCyan, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryPage extends StatelessWidget {
  final bool compact;
  final bool detecting;
  final LatamCountry? country;
  final VoidCallback onDetect;
  final VoidCallback onSkipLocation;
  final Future<void> Function({required bool personalize}) onFinish;

  const _CountryPage({
    required this.compact,
    required this.detecting,
    required this.country,
    required this.onDetect,
    required this.onSkipLocation,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final greeted = country != null && country!.demonym.isNotEmpty;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: compact ? 8 : 16),
                Text(
                  greeted ? 'Hola hermano ${country!.demonym.toUpperCase()}' : 'Tu país, tu inicio',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: compact ? 26 : 30,
                        height: 1.15,
                      ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),
                Text(
                  greeted
                      ? 'Si querés, ${country!.name} queda primero en tu lista y se selecciona solo cuando vuelvas a entrar.'
                      : 'Te saludamos según tu país y, si querés, dejamos tus noticias listas para la próxima.',
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        greeted ? Icons.public_rounded : Icons.my_location_rounded,
                        color: AppTheme.accentCyan,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        greeted
                            ? country!.name
                            : detecting
                                ? 'Detectando tu país'
                                : 'Personalizá tu experiencia',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        greeted
                            ? 'Tu lista va a abrir por acá.'
                            : 'Usamos tu ubicación solo para el saludo y el orden de los países. Nada se comparte.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                      ),
                      if (detecting) ...[
                        const SizedBox(height: 18),
                        const CircularProgressIndicator(color: AppTheme.accentCyan),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
        if (!detecting) ...[
          if (!greeted) ...[
            _PrimaryButton(label: 'Detectar mi país', onTap: onDetect),
            const SizedBox(height: 8),
            _SecondaryButton(label: 'Elegir después', onTap: onSkipLocation),
            _SecondaryButton(label: 'Entrar ahora', onTap: () => onFinish(personalize: false)),
          ] else ...[
            _PrimaryButton(
              label: 'Empezar por ${country!.name}',
              onTap: () => onFinish(personalize: true),
            ),
            const SizedBox(height: 8),
            _SecondaryButton(
              label: 'Ver todas las noticias',
              onTap: () => onFinish(personalize: false),
            ),
          ],
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentCyan,
          foregroundColor: AppTheme.bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
