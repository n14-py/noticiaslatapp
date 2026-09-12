import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noticias_lat/core/services/user_prefs.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await UserPrefs.instance.init();
  });

  testWidgets('la bienvenida guía sin hablar de lentitud ni de la API', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WelcomeScreen(onFinished: () {}),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Bienvenido'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.textContaining('tardar'), findsNothing);
    expect(find.textContaining('lenta'), findsNothing);
    expect(find.textContaining('API'), findsNothing);
    expect(find.textContaining('cargar'), findsNothing);

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Así se usa'), findsOneWidget);
    expect(find.text('Noticias'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('Radio'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });
}
