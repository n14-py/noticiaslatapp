// Archivo: noticias_lat/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/screens/main_shell.dart';
import 'package:noticias_lat/screens/detalle_noticia_screen.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';
import 'package:noticias_lat/core/services/ad_manager.dart';
import 'package:noticias_lat/core/services/billing_manager.dart';

// Manejador de notificaciones cuando la app est  cerrada o en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Manejando mensaje en segundo plano: ${message.messageId}");
}

// Clave global para poder navegar a otras pantallas desde notificaciones/enlaces sin context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Aseguramos que Flutter est  listo antes de arrancar los plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase (Push Notifications)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Advertencia: Firebase requiere configuraci n nativa (google-services.json). Error: $e");
  }
  
  // 1. Inicializamos la Base de Datos Local (Premium y Cr ditos)
  await PremiumManager.init();
  
  // 2. Inicializamos Google AdMob
  await MobileAds.instance.initialize();
  
  // 3. Dejamos cargando un anuncio intersticial y un reward en segundo plano
// 3. Dejamos cargando un anuncio intersticial y un reward en segundo plano
  AdManager.loadInterstitial();
  AdManager.loadRewarded();

  // 4. Inicializamos la pasarela de pagos (Google Play / App Store)
  await BillingManager.init();

  // Fijamos la orientación vertical y los colores de la barra de estado
  // Fijamos la orientaci n vertical y los colores de la barra de estado
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    // Registramos el observador para detectar cuando la app se va a segundo plano y vuelve
    WidgetsBinding.instance.addObserver(this);
    
    // Inicializamos escuchadores de Enlaces y Notificaciones
    _initDeepLinks();
    _initPushNotifications();
  }

  // ==========================================
  // L GICA DE DEEP LINKS (ENLACES PROFUNDOS)
  // ==========================================
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Manejar el enlace si la app estaba cerrada por completo y se abri  tocando el link
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _procesarEnlace(initialLink);
      }
    } catch (e) {
      debugPrint("Error obteniendo enlace inicial: $e");
    }

    // 2. Manejar enlaces mientras la app ya est  abierta o en segundo plano
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _procesarEnlace(uri);
    }, onError: (err) {
      debugPrint("Error en stream de enlaces: $err");
    });
  }

  void _procesarEnlace(Uri uri) async {
    // Acepta URLs de tipo: https://noticias.lat/articulo/123456
    // O tambi n: https://noticias.lat/?id=123456
    String? articleId;
    
    if (uri.pathSegments.contains('articulo') && uri.pathSegments.length > 1) {
      int index = uri.pathSegments.indexOf('articulo');
      articleId = uri.pathSegments[index + 1];
    } else if (uri.queryParameters.containsKey('id')) {
      articleId = uri.queryParameters['id'];
    }

    if (articleId != null && articleId.isNotEmpty) {
      _abrirNoticiaDesdeId(articleId);
    }
  }

  // ==========================================
  // L GICA DE NOTIFICACIONES PUSH
  // ==========================================
  Future<void> _initPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

// Pedir permisos (Fundamental para iOS y Android 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // --- MAGIA: SUSCRIPCIÓN AL CANAL MASIVO ---
    // Esto conecta tu App con el 'topic' de tu servidor Node.js
    await messaging.subscribeToTopic('all_users');

    // 1. Si la app está abierta en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Recibida notificaci n en primer plano: ${message.notification?.title}');
      // Opcional: Podr as mostrar un SnackBar aqu  avisando de la nueva noticia
    });

    // 2. Si el usuario toca la notificaci n y la app estaba minimizada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _procesarNotificacion(message);
    });

    // 3. Si la app estaba cerrada por completo y se abri  desde la notificaci n
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Retrasamos un poco para asegurarnos de que la interfaz ya se dibuj 
      Future.delayed(const Duration(seconds: 1), () {
        _procesarNotificacion(initialMessage);
      });
    }
  }

  void _procesarNotificacion(RemoteMessage message) {
    // Para que esto funcione, desde tu servidor debes enviar la notificaci n 
    // con un campo extra (Data) llamado 'article_id' con el ID de la noticia.
    if (message.data.containsKey('article_id')) {
      String articleId = message.data['article_id'];
      _abrirNoticiaDesdeId(articleId);
    }
  }

  // ==========================================
  // NAVEGACI N A LA NOTICIA DESDE ENLACE O PUSH
  // ==========================================
  Future<void> _abrirNoticiaDesdeId(String id) async {
    try {
      // Hacemos una petici n express a tu API para traer toda la info de la noticia
      final url = Uri.parse('https://api.noticias.lat/api/article/$id');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Empujamos la pantalla de Detalle Noticia usando el Navigator global
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DetalleNoticiaScreen(noticia: data['articulo'] ?? data),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error abriendo noticia remota por ID: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Si la app vuelve a estar activa (el usuario regres  a la app)
    if (state == AppLifecycleState.resumed) {
      AdManager.mostrarIntersticialDeBienvenida();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // IMPORTANTE: Clave para poder navegar
      title: 'Noticias Lat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Usando tu tema personalizado Premium
      home: const MainShell(),
    );
  }
}