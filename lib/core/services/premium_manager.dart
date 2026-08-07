// Archivo: noticias_lat/lib/core/services/premium_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class PremiumManager {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    if (_prefs.getInt('ai_credits') == null) {
      await _prefs.setInt('ai_credits', 5);
    }
    if (_prefs.getInt('anuncios_vistos_hoy') == null) {
      await _prefs.setInt('anuncios_vistos_hoy', 0);
    }
  }
  
  static bool isPremium() {
    int? premiumUntil = _prefs.getInt('premium_until');
    if (premiumUntil == null) return false;
    return DateTime.now().millisecondsSinceEpoch < premiumUntil;
  }

  static Future<void> activarPremium12Horas() async {
    int until = DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch;
    await _prefs.setInt('premium_until', until);
    await _prefs.setInt('anuncios_vistos_hoy', 0);
  }

  static Future<int> registrarAnuncioVistoParaPremium() async {
    int vistos = (_prefs.getInt('anuncios_vistos_hoy') ?? 0) + 1;
    await _prefs.setInt('anuncios_vistos_hoy', vistos);
    
    if (vistos >= 2) {
      await activarPremium12Horas();
    }
    return vistos;
  }

  static int getAnunciosVistosHoy() => _prefs.getInt('anuncios_vistos_hoy') ?? 0;
  
  static int getAiCredits() {
    if (isPremium()) return 999; 
    return _prefs.getInt('ai_credits') ?? 0;
  }

  static Future<bool> usarCreditoIA() async {
    if (isPremium()) return true; 
    int current = getAiCredits();
    if (current > 0) {
      await _prefs.setInt('ai_credits', current - 1);
      return true;
    }
    return false;
  }

  static Future<void> agregarCreditosIA(int cantidad) async {
    int current = _prefs.getInt('ai_credits') ?? 0;
    await _prefs.setInt('ai_credits', current + cantidad);
  }
}