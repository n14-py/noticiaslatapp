import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cache JSON de feeds, igual que el de shorts en actualizacion 17.
class JsonFeedCache {
  static const shortsKey = 'shorts_json_cache';
  static const radiosKey = 'radios_json_cache';

  static const _shortsUrl =
      'https://api.noticias.lat/api/articles?sitio=noticias.lat&limite=100';
  static const _radiosUrl =
      'https://api.noticias.lat/api/articles?sitio=noticias.lat&limite=200';

  static Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> write(String key, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, body);
  }

  /// Precarga shorts y radio en silencio, sin montar reproductores.
  static void warmInBackground() {
    _fetchAndStore(shortsKey, _shortsUrl);
    _fetchAndStore(radiosKey, _radiosUrl);
  }

  static Future<void> _fetchAndStore(String key, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        await write(key, response.body);
      }
    } catch (e) {
      debugPrint('JsonFeedCache $key: $e');
    }
  }
}
