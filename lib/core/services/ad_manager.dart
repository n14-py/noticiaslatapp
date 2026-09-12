// Archivo: noticias_lat/lib/core/services/ad_manager.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';

class AdManager {
  //   Tus IDs Oficiales de AdMob
  static const String bannerAdUnitId = 'ca-app-pub-5461370198299696/8176816601';
  static const String interstitialAdUnitId = 'ca-app-pub-5461370198299696/7578050809';

  /// true mientras un anuncio a pantalla completa cubre la app (pausa shorts/audio).
  static final ValueNotifier<bool> isFullscreenAdVisible = ValueNotifier<bool>(false);

  static void _setFullscreenAdVisible(bool visible) {
    if (isFullscreenAdVisible.value != visible) {
      isFullscreenAdVisible.value = visible;
    }
  }
  
  // Separamos los IDs de recompensados
  static const String rewardedAdUnitIdPremium = 'ca-app-pub-5461370198299696/3638805797';
  static const String rewardedAdUnitIdIA = 'ca-app-pub-5461370198299696/9064542151'; 

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAdPremium;
  static RewardedAd? _rewardedAdIA;

  // Contador para las noticias leídas
  static int _noticiasLeidas = 0;

  // 1  ANUNCIO BANNER (Sin "context" para no romper tus otras pantallas)
  static Widget getBannerAdWidget() {
    if (PremiumManager.isPremium()) return const SizedBox.shrink();
    return const AdaptiveBannerAdWidget();
  }

  // 2  ANUNCIO INTERSTICIAL (Pantalla Completa)
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
      onAdShowedFullScreenContent: (ad) {
        _setFullscreenAdVisible(true);
      },
      onAdDismissedFullScreenContent: (ad) {
        _setFullscreenAdVisible(false);
        ad.dispose();
        loadInterstitial(); // Recarga autom tica para la siguiente vez
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _setFullscreenAdVisible(false);
        ad.dispose();
        loadInterstitial();
      },
    );
    _setFullscreenAdVisible(true);
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // Nuevo método: Intersticial cada 3 noticias
  static void mostrarIntersticialCada3Noticias() {
    _noticiasLeidas++;
    if (_noticiasLeidas % 3 == 0) {
      showInterstitial();
    }
  }

  // Nuevo método: Intersticial de bienvenida (al abrir la app o volver a entrar)
  static void mostrarIntersticialDeBienvenida() {
    showInterstitial();
  }

  // 3  ANUNCIO RECOMPENSADO (Videos para cr ditos Premium e IA)
  static void loadRewarded() {
    _loadRewardedPremium();
    _loadRewardedIA();
  }

  static void _loadRewardedPremium() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitIdPremium,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAdPremium = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAdPremium = null;
        },
      ),
    );
  }

  static void _loadRewardedIA() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitIdIA,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAdIA = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAdIA = null;
        },
      ),
    );
  }

  static void showRewarded({
    required Function onRewardEarned,
    required Function onAdClosed,
    bool isForIA = false, // Magia: Si no le enviamos nada, asume que es el Premium para no romper tu código
  }) {
    RewardedAd? adToShow = isForIA ? _rewardedAdIA : _rewardedAdPremium;

    if (adToShow == null) {
      onAdClosed(); // Si falla la carga, contin a el flujo para no trabar al usuario
      return;
    }
    
    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _setFullscreenAdVisible(true);
      },
      onAdDismissedFullScreenContent: (ad) {
        _setFullscreenAdVisible(false);
        ad.dispose();
        if (isForIA) {
          _loadRewardedIA(); // Recarga el video de IA
        } else {
          _loadRewardedPremium(); // Recarga el video Premium
        }
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _setFullscreenAdVisible(false);
        ad.dispose();
        if (isForIA) {
          _loadRewardedIA();
        } else {
          _loadRewardedPremium();
        }
        onAdClosed();
      },
    );
    
    _setFullscreenAdVisible(true);
    adToShow.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned(); // Da los cr ditos correspondientes
      },
    );
    
    if (isForIA) {
      _rewardedAdIA = null;
    } else {
      _rewardedAdPremium = null;
    }
  }
}

// COMPONENTE INTERNO: Controla de forma inteligente el tama o y ciclo de vida del Banner
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
    // Cargamos el anuncio de forma segura bas ndonos en las dimensiones de la pantalla actual
    if (_bannerAd == null) {
      _loadAdaptiveBanner();
    }
  }

  Future<void> _loadAdaptiveBanner() async {
    // Calculamos de forma din mica el ancho m ximo de la pantalla actual del dispositivo
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
    _bannerAd?.dispose(); //   EVITA LAS SOLICITUDES DUPLICADAS AL DESTRUIR EL COMPONENTE
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
    // Muestra un espacio vac o imperceptible mientras el banner termina de cargarse en segundo plano
    return const SizedBox.shrink();
  }
}