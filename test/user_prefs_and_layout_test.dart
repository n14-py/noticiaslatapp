import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noticias_lat/core/layout/app_metrics.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la barra deja espacio extra en pantallas chicas con botones de sistema', (tester) async {
    late double clearance;
    late double bottomPad;
    late bool narrow;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          padding: EdgeInsets.only(bottom: 48, top: 24),
        ),
        child: Builder(
          builder: (context) {
            clearance = AppMetrics.navClearance(context);
            bottomPad = AppMetrics.navBottomPadding(context);
            narrow = AppMetrics.isNarrow(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(narrow, isTrue);
    expect(bottomPad, 24 + 48);
    expect(clearance, 75 + 24 + 48 + 12);
  });

  test('UserPrefs guarda el país para la próxima entrada', () async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.init();

    expect(UserPrefs.instance.hasCompletedWelcome, isFalse);
    expect(UserPrefs.instance.selectedCountryCode, 'todos');

    await UserPrefs.instance.completeWelcome(countryCode: 'py', personalize: true);

    expect(UserPrefs.instance.hasCompletedWelcome, isTrue);
    expect(UserPrefs.instance.personalizeHomeCountry, isTrue);
    expect(UserPrefs.instance.selectedCountryCode, 'py');
    expect(UserPrefs.instance.pinnedCountryCode, 'py');
  });

  test('si no personaliza, sigue en Todos', () async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.init();
    await UserPrefs.instance.completeWelcome(countryCode: 'cl', personalize: false);

    expect(UserPrefs.instance.hasCompletedWelcome, isTrue);
    expect(UserPrefs.instance.selectedCountryCode, 'todos');
    expect(UserPrefs.instance.pinnedCountryCode, isNull);
  });
}
