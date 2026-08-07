// Archivo: noticias_lat/lib/core/services/ad_manager.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';

class AdManager {
  // 🆔 Tus IDs Oficiales de AdMob
  static const String bannerAdUnitId = 'ca-app-pub-5461370198299696/8176816601';
  static const String interstitialAdUnitId = 'ca-app-pub-5461370198299696/7578050809';
  static const String rewardedAdUnitId = 'ca-app-pub-5461370198299696/3638805797';

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  // 1️⃣ ANUNCIO BANNER (Sin "context" para no romper tus otras pantallas)
  static Widget getBannerAdWidget() {
    if (PremiumManager.isPremium()) return const SizedBox.shrink();
    return const AdaptiveBannerAdWidget();
  }

  // 2️⃣ ANUNCIO INTERSTICIAL (Pantalla Completa)
  static void loadInterstitial() {
    if (PremiumManager.isPremium()) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  static void showInterstitial() {
    if (PremiumManager.isPremium() || _interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial(); // Recarga automática para la siguiente vez
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitial();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // 3️⃣ ANUNCIO RECOMPENSADO (Videos para créditos Premium)
  static void loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      // ✅ CORRECCIÓN: Aquí es estrictamente "rewardedAdLoadCallback"
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  static void showRewarded({
    required Function onRewardEarned,
    required Function onAdClosed,
  }) {
    if (_rewardedAd == null) {
      onAdClosed(); // Si falla la carga, continúa el flujo para no trabar al usuario
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded(); // Recarga el video
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewarded();
        onAdClosed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned(); // Da los créditos correspondientes
      },
    );
    _rewardedAd = null;
  }
}

// 🧱 COMPONENTE INTERNO: Controla de forma inteligente el tamaño y ciclo de vida del Banner
class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({super.key});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AnchoredAdaptiveBannerAdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargamos el anuncio de forma segura basándonos en las dimensiones de la pantalla actual
    if (_bannerAd == null) {
      _loadAdaptiveBanner();
    }
  }

  Future<void> _loadAdaptiveBanner() async {
    // Calculamos de forma dinámica el ancho máximo de la pantalla actual del dispositivo
    final int width = MediaQuery.sizeOf(context).width.truncate();
    
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (size == null || !mounted) return;

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _adSize = size;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose(); // Limpieza inmediata si falla la carga
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // ⚠️ EVITA LAS SOLICITUDES DUPLICADAS AL DESTRUIR EL COMPONENTE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null && _adSize != null) {
      return Container(
        alignment: Alignment.center,
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Muestra un espacio vacío imperceptible mientras el banner termina de cargarse en segundo plano
    return const SizedBox.shrink();
  }
}