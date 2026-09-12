import 'package:flutter/material.dart';
import 'package:noticias_lat/core/data/latam_countries.dart';
import 'package:noticias_lat/core/services/country_detector.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const WelcomeScreen({super.key, required this.onFinished});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _detecting = false;
  String? _countryCode;
  String? _errorText;

  LatamCountry? get _country => LatamCountries.byCode(_countryCode);

  Future<void> _detectCountry() async {
    setState(() {
      _detecting = true;
      _errorText = null;
    });

    final detected = await CountryDetector.detect(requestLocation: true);

    if (!mounted) return;
    setState(() {
      _detecting = false;
      _countryCode = detected?.code;
      if (detected == null) {
        _errorText =
            'No pudimos confirmar tu país. Podés entrar igual y elegir el filtro cuando quieras.';
      }
    });
  }

  Future<void> _skipLocation() async {
    setState(() {
      _detecting = true;
      _errorText = null;
    });
    final detected = await CountryDetector.detect(requestLocation: false);
    if (!mounted) return;
    if (detected == null) {
      await _finish(personalize: false);
      return;
    }
    setState(() {
      _detecting = false;
      _countryCode = detected.code;
    });
  }

  Future<void> _finish({required bool personalize}) async {
    final canPin = personalize && LatamCountries.isSupported(_countryCode);
    await UserPrefs.instance.completeWelcome(
      countryCode: canPin ? _countryCode : null,
      personalize: canPin,
    );
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: AppTheme.bgDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottom),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 88,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bolt_rounded,
                            color: AppTheme.accentCyan,
                            size: 72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _greetingTitle(),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _greetingBody(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildHowItWorksCard(),
                      if (_errorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (_detecting) ...[
                        const SizedBox(height: 28),
                        const Center(
                          child: CircularProgressIndicator(color: AppTheme.accentCyan),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Detectando tu país...',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingTitle() {
    final country = _country;
    if (country != null && country.demonym.isNotEmpty) {
      return 'Hola hermano ${country.demonym.toUpperCase()}';
    }
    return 'Bienvenido a Noticias LAT';
  }

  String _greetingBody() {
    if (_country != null) {
      return 'Te damos la bienvenida. Mientras cargan las noticias, acá va un resumen corto de la app.\n\nSi querés, ${_country!.name} queda primero en tu lista y se selecciona solo la próxima vez que entres.';
    }
    return 'La primera vez la red puede tardar un poquito en cargar. Mientras tanto, si querés, detectamos tu país para saludarte y dejarte las noticias de tu casa listas.';
  }

  Widget _buildHowItWorksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CÓMO FUNCIONA',
            style: TextStyle(
              color: AppTheme.accentCyan,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 14),
          _HowRow(
            icon: Icons.bolt_rounded,
            title: 'Noticias',
            text: 'Titulares de Latinoamérica. Filtrá por país o buscá un tema.',
          ),
          SizedBox(height: 12),
          _HowRow(
            icon: Icons.play_circle_fill_rounded,
            title: 'TV',
            text: 'Shorts y videos cortos de las noticias del momento.',
          ),
          SizedBox(height: 12),
          _HowRow(
            icon: Icons.podcasts_rounded,
            title: 'Radio',
            text: 'Escuchá las noticias en audio, una detrás de otra.',
          ),
          SizedBox(height: 12),
          _HowRow(
            icon: Icons.person_rounded,
            title: 'Perfil',
            text: 'Premium, créditos IA y opciones de la cuenta.',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_detecting) return const [SizedBox.shrink()];

    if (_country == null) {
      return [
        _PrimaryButton(
          label: 'Detectar mi país',
          onTap: _detectCountry,
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: 'Entrar sin ubicación',
          onTap: _skipLocation,
        ),
      ];
    }

    return [
      _PrimaryButton(
        label: 'Sí, mostrar ${_country!.name} primero',
        onTap: () => _finish(personalize: true),
      ),
      const SizedBox(height: 10),
      _SecondaryButton(
        label: 'Entrar sin personalizar',
        onTap: () => _finish(personalize: false),
      ),
    ];
  }
}

class _HowRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HowRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accentCyan, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
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
      height: 48,
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
