import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de primer uso y país del usuario (SharedPreferences).
class UserPrefs extends ChangeNotifier {
  UserPrefs._();
  static final UserPrefs instance = UserPrefs._();

  static const _keyWelcomeDone = 'welcome_completed';
  static const _keyPreferredCountry = 'preferred_country_code';
  static const _keyPersonalizeCountry = 'personalize_home_country';

  late SharedPreferences _prefs;
  bool _ready = false;

  bool get isReady => _ready;
  bool get hasCompletedWelcome => _prefs.getBool(_keyWelcomeDone) ?? false;
  bool get personalizeHomeCountry =>
      _prefs.getBool(_keyPersonalizeCountry) ?? false;

  String? get preferredCountryCode {
    final code = _prefs.getString(_keyPreferredCountry);
    if (code == null || code.isEmpty || code == 'todos') return null;
    return code;
  }

  /// País que debe quedar seleccionado al abrir noticias/radio.
  String get selectedCountryCode {
    if (personalizeHomeCountry && preferredCountryCode != null) {
      return preferredCountryCode!;
    }
    return 'todos';
  }

  /// País que debe ir primero en el chip list.
  String? get pinnedCountryCode {
    if (personalizeHomeCountry) return preferredCountryCode;
    return null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  Future<void> completeWelcome({
    String? countryCode,
    required bool personalize,
  }) async {
    await _prefs.setBool(_keyWelcomeDone, true);
    await _prefs.setBool(_keyPersonalizeCountry, personalize);
    if (countryCode != null && countryCode.isNotEmpty && countryCode != 'todos') {
      await _prefs.setString(_keyPreferredCountry, countryCode.toLowerCase());
    } else if (!personalize) {
      await _prefs.remove(_keyPreferredCountry);
    }
    notifyListeners();
  }
}
