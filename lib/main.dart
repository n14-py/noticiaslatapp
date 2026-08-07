// Archivo: noticias_lat/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/screens/main_shell.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';

void main() async {
  // Aseguramos que Flutter esté listo antes de arrancar los plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializamos la Base de Datos Local (Premium y Créditos)
  await PremiumManager.init();
  
  // 2. Inicializamos Google AdMob
  await MobileAds.instance.initialize();
  
  // 3. Dejamos cargando un anuncio intersticial y un reward en segundo plano
  AdManager.loadInterstitial();
  AdManager.loadRewarded();

  // Fijamos la orientación vertical y los colores de la barra de estado
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noticias Lat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Usando tu tema personalizado Premium
      home: const MainShell(),
    );
  }
}