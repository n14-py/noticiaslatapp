// Archivo: noticias_lat/lib/screens/publicar_noticia_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noticias_lat/core/theme/app_theme.dart';

class PublicarNoticiaScreen extends StatefulWidget {
  final int paquete; // Recibe cuántas noticias compró (1, 5 o 10)
  
  const PublicarNoticiaScreen({super.key, required this.paquete});

  @override
  State<PublicarNoticiaScreen> createState() => _PublicarNoticiaScreenState();
}

class _PublicarNoticiaScreenState extends State<PublicarNoticiaScreen> {
  int _pasoActual = 0; // 0: Tutorial, 1: Formulario, 2: Pago y Envío, 3: Éxito
  bool _isLoading = false;

  // Controladores del formulario
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  String _categoriaSeleccionada = 'general';
  
  // Manejo de la Imagen
  File? _imagenPortada;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categorias = ['general', 'politica', 'economia', 'deportes', 'tecnologia', 'salud', 'entretenimiento'];

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  // ==========================================
  // 📸 LÓGICA PARA SELECCIONAR IMAGEN
  // ==========================================
  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _imagenPortada = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir la galería.')));
    }
  }

  // ==========================================
  // 💳 LÓGICA DE PAGO Y ENVÍO A LA API
  // ==========================================
  Future<void> _procesarPagoYPublicar() async {
    setState(() => _isLoading = true);

    try {
      // 1. Simulación de Pago con Google Play Billing
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo Google Play... Procesando pago...')));
      await Future.delayed(const Duration(seconds: 3)); // Simulamos que el usuario acepta el cobro
      
      // 2. Obtener el Token del usuario para la API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';

      if (token.isEmpty) {
        throw Exception('No hay sesión activa. Por favor, inicia sesión de nuevo.');
      }

      // 3. Preparar el envío (MultipartRequest para incluir la imagen)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo artículo al servidor...')));
      
      // NOTA: Ajusta esta URL si tu ruta en lfaftechapi para recibir noticias de miembros es distinta.
      var uri = Uri.parse('https://api.noticias.lat/api/articles/member-publish'); 
      var request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['titulo'] = _tituloController.text;
      request.fields['contenido'] = _contenidoController.text;
      request.fields['categoria'] = _categoriaSeleccionada;
      request.fields['sitio'] = 'noticias.lat';
      
      if (_imagenPortada != null) {
        request.files.add(await http.MultipartFile.fromPath('imagen', _imagenPortada!.path));
      }

      // IMPORTANTE: Como es un código de desarrollo, no haremos estallar la app si el endpoint de la API 
      // aún no está listo para recibir MultipartRequest. Simularemos el éxito.
      /* var response = await request.send();
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error en el servidor al publicar.');
      }
      */
      
      // Simulamos tiempo de subida
      await Future.delayed(const Duration(seconds: 2));

      // 4. Éxito
      setState(() {
        _isLoading = false;
        _pasoActual = 3; // Pasamos a la pantalla final de éxito
      });

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // CÁLCULO DE PRECIOS
  // ==========================================
  String _obtenerPrecio() {
    if (widget.paquete == 1) return '\$1.00 USD';
    if (widget.paquete == 5) return '\$4.50 USD';
    if (widget.paquete == 10) return '\$8.00 USD';
    return '\$1.00 USD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (_pasoActual > 0 && _pasoActual < 3) {
              setState(() => _pasoActual--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _pasoActual == 0 ? '¿Cómo funciona?' : _pasoActual == 1 ? 'Redacción' : _pasoActual == 2 ? 'Pago y Envío' : '¡Éxito!',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // BARRA DE PROGRESO
            if (_pasoActual < 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Guía'),
                    _buildStepLine(0),
                    _buildStepIndicator(1, 'Escribir'),
                    _buildStepLine(1),
                    _buildStepIndicator(2, 'Publicar'),
                  ],
                ),
              ),
            
            // CONTENIDO DEL PASO
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation), child: child));
                },
                child: _construirPasoActual(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VISTAS DE CADA PASO
  // ==========================================
  
  Widget _construirPasoActual() {
    switch (_pasoActual) {
      case 0: return _buildPasoTutorial();
      case 1: return _buildPasoFormulario();
      case 2: return _buildPasoPago();
      case 3: return _buildPasoExito();
      default: return const SizedBox.shrink();
    }
  }

  // --- PASO 0: TUTORIAL ---
  Widget _buildPasoTutorial() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Potencia tu voz en toda Latinoamérica', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 10),
          const Text('Al publicar en Noticias.lat, tu contenido no solo se queda en texto. Nuestro sistema automatizado hace el trabajo duro por ti.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 30),
          
          _buildInfoRow(Icons.edit_document, '1. Redacción y Envío', 'Tú escribes el título, el contenido y subes una foto. Al enviarlo, pasa a estado de Revisión.'),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.admin_panel_settings_rounded, '2. Revisión Express', 'Nuestro equipo y sistema IA verificarán rápidamente que el texto cumpla con las normas comunitarias.'),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.public_rounded, '3. Publicación Global', 'Se publicará con SEO optimizado en Noticias.lat y se distribuirá al instante en nuestra App.'),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.multitrack_audio_rounded, '4. Radio y YouTube (Automático)', 'Generaremos un audio con IA para nuestra Radio 24/7 y un video formato Short que se subirá a nuestro canal de YouTube.'),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: () => setState(() => _pasoActual = 1),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Entendido, ¡Comencemos!', style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  // --- PASO 1: FORMULARIO ---
  Widget _buildPasoFormulario() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            const Text('Foto de Portada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder, width: 2), image: _imagenPortada != null ? DecorationImage(image: FileImage(_imagenPortada!), fit: BoxFit.cover) : null),
                child: _imagenPortada == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 48),
                          const SizedBox(height: 8),
                          const Text('Toca para seleccionar imagen', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      )
                    : Container(
                        alignment: Alignment.topRight, padding: const EdgeInsets.all(8),
                        child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 20)),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // TÍTULO
            const Text('Título de la Noticia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _tituloController,
              style: const TextStyle(color: Colors.white),
              maxLength: 100,
              decoration: _inputDecoration('Ej: Nueva tecnología revoluciona el mercado...'),
              validator: (v) => v!.isEmpty ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 20),

            // CATEGORÍA
            const Text('Categoría', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  dropdownColor: AppTheme.cardDark,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.accentCyan),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: _categorias.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() { _categoriaSeleccionada = newValue!; });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CONTENIDO
            const Text('Contenido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contenidoController,
              style: const TextStyle(color: Colors.white),
              maxLines: 10,
              maxLength: 5000,
              decoration: _inputDecoration('Redacta aquí tu artículo completo...'),
              validator: (v) => v!.length < 50 ? 'El contenido debe tener al menos 50 caracteres' : null,
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_imagenPortada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona una foto de portada.')));
                      return;
                    }
                    setState(() => _pasoActual = 2);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Continuar al Pago', style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- PASO 2: PAGO ---
  Widget _buildPasoPago() {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de tu Publicación', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paquete seleccionado:', style: TextStyle(color: AppTheme.textMuted)),
                    Text('${widget.paquete} Noticia(s)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AppTheme.cardBorder)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a pagar:', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text(_obtenerPrecio(), style: const TextStyle(color: AppTheme.accentCyan, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Método de pago seguro', style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
            child: Row(
              children: [
                Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Google_Play_Arrow_logo.svg/1024px-Google_Play_Arrow_logo.svg.png', width: 30),
                const SizedBox(width: 16),
                const Text('Google Play Billing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                const Icon(Icons.check_circle_rounded, color: Colors.green),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _procesarPagoYPublicar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.payment_rounded),
              label: Text(_isLoading ? 'Procesando...' : 'Pagar ${_obtenerPrecio()} y Enviar', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PASO 3: ÉXITO ---
  Widget _buildPasoExito() {
    return Center(
      key: const ValueKey(3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80)),
            const SizedBox(height: 24),
            const Text('¡Noticia Enviada!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text('El pago se realizó con éxito y tu artículo está ahora en revisión. Te notificaremos cuando se publique y comience la magia de la IA.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardDark, side: const BorderSide(color: AppTheme.accentCyan), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Volver a mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================
  
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.accentCyan, width: 2)),
      counterStyle: const TextStyle(color: AppTheme.textMuted),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isCompleted = _pasoActual > stepIndex;
    bool isActive = _pasoActual == stepIndex;
    
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: isCompleted || isActive ? AppTheme.accentCyan : AppTheme.cardDark, shape: BoxShape.circle, border: Border.all(color: isActive ? Colors.white : AppTheme.cardBorder, width: 2)),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: AppTheme.bgDark, size: 18)
                : Text('${stepIndex + 1}', style: TextStyle(color: isActive ? AppTheme.bgDark : AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(color: isActive ? AppTheme.accentCyan : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStepLine(int stepIndex) {
    bool isCompleted = _pasoActual > stepIndex;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18, left: 8, right: 8),
        height: 3,
        decoration: BoxDecoration(color: isCompleted ? AppTheme.accentCyan : AppTheme.cardDark, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)), child: Icon(icon, color: AppTheme.accentCyan, size: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}