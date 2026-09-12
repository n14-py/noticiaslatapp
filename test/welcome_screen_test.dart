import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';
import 'package:noticias_lat/screens/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('la bienvenida muestra el saludo, cómo funciona y los botones', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WelcomeScreen(onFinished: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('Bienvenido a Noticias LAT'), findsOneWidget);
    expect(find.text('Detectar mi país'), findsOneWidget);
    expect(find.text('Entrar sin ubicación'), findsOneWidget);
    expect(find.text('CÓMO FUNCIONA'), findsOneWidget);
    expect(find.text('Noticias'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('Radio'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
