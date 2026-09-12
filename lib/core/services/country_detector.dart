import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:noticias_lat/core/data/latam_countries.dart';

class DetectedCountry {
  final String code;
  final String source;

  const DetectedCountry({required this.code, required this.source});
}

/// Detecta el país con GPS (si el usuario acepta) y cae a IP / locale.
class CountryDetector {
  static const _timeout = Duration(seconds: 8);

  static Future<DetectedCountry?> detect({bool requestLocation = true}) async {
    if (requestLocation) {
      final fromGps = await _detectFromGps();
      if (fromGps != null) return fromGps;
    }

    final fromIp = await _detectFromIp();
    if (fromIp != null) return fromIp;

    return _detectFromLocale();
  }

  static Future<DetectedCountry?> _detectFromGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: _timeout,
        ),
      );

      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=${position.latitude}&longitude=${position.longitude}'
        '&localityLanguage=es',
      );
      final response = await http.get(uri).timeout(_timeout);
      final code = _parseCountryCode(response.body);
      if (LatamCountries.isSupported(code)) {
        return DetectedCountry(code: code!, source: 'gps');
      }
    } catch (e) {
      debugPrint('CountryDetector GPS: $e');
    }
    return null;
  }

  static Future<DetectedCountry?> _detectFromIp() async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=es',
      );
      final response = await http.get(uri).timeout(_timeout);
      final code = _parseCountryCode(response.body);
      if (LatamCountries.isSupported(code)) {
        return DetectedCountry(code: code!, source: 'ip');
      }
    } catch (e) {
      debugPrint('CountryDetector IP: $e');
    }
    return null;
  }

  static DetectedCountry? _detectFromLocale() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split(RegExp(r'[_-]'));
      if (parts.length >= 2) {
        final code = parts.last.toLowerCase();
        if (LatamCountries.isSupported(code)) {
          return DetectedCountry(code: code, source: 'locale');
        }
      }
    } catch (e) {
      debugPrint('CountryDetector locale: $e');
    }
    return null;
  }

  static String? _parseCountryCode(String body) {
    try {
      final data = json.decode(body);
      final raw = (data['countryCode'] ?? data['country_code'] ?? '').toString();
      if (raw.isEmpty) return null;
      return raw.toLowerCase();
    } catch (_) {
      return null;
    }
  }
}
