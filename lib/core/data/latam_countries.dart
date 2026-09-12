// Catálogo compartido de países LATAM (mismos nombres/códigos que ya usa la app).
class LatamCountry {
  final String name;
  final String code;
  final String demonym;

  const LatamCountry({
    required this.name,
    required this.code,
    required this.demonym,
  });
}

class LatamCountries {
  static const List<LatamCountry> all = [
    LatamCountry(name: 'Todos', code: 'todos', demonym: ''),
    LatamCountry(name: 'Argentina', code: 'ar', demonym: 'argentino'),
    LatamCountry(name: 'Bolivia', code: 'bo', demonym: 'boliviano'),
    LatamCountry(name: 'Brasil', code: 'br', demonym: 'brasileño'),
    LatamCountry(name: 'Chile', code: 'cl', demonym: 'chileno'),
    LatamCountry(name: 'Colombia', code: 'co', demonym: 'colombiano'),
    LatamCountry(name: 'Costa Rica', code: 'cr', demonym: 'costarricense'),
    LatamCountry(name: 'Cuba', code: 'cu', demonym: 'cubano'),
    LatamCountry(name: 'Ecuador', code: 'ec', demonym: 'ecuatoriano'),
    LatamCountry(name: 'El Salvador', code: 'sv', demonym: 'salvadoreño'),
    LatamCountry(name: 'Guatemala', code: 'gt', demonym: 'guatemalteco'),
    LatamCountry(name: 'Honduras', code: 'hn', demonym: 'hondureño'),
    LatamCountry(name: 'México', code: 'mx', demonym: 'mexicano'),
    LatamCountry(name: 'Nicaragua', code: 'ni', demonym: 'nicaragüense'),
    LatamCountry(name: 'Panamá', code: 'pa', demonym: 'panameño'),
    LatamCountry(name: 'Paraguay', code: 'py', demonym: 'paraguayo'),
    LatamCountry(name: 'Perú', code: 'pe', demonym: 'peruano'),
    LatamCountry(name: 'Puerto Rico', code: 'pr', demonym: 'puertorriqueño'),
    LatamCountry(name: 'R. Dominicana', code: 'do', demonym: 'dominicano'),
    LatamCountry(name: 'Uruguay', code: 'uy', demonym: 'uruguayo'),
    LatamCountry(name: 'Venezuela', code: 've', demonym: 'venezolano'),
  ];

  static LatamCountry? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code.toLowerCase();
    for (final country in all) {
      if (country.code == normalized) return country;
    }
    return null;
  }

  static bool isSupported(String? code) {
    final country = byCode(code);
    return country != null && country.code != 'todos';
  }

  /// Misma lista visual de siempre. Si hay un país anclado, ese va primero.
  static List<Map<String, String>> asFilterMaps({String? pinCode}) {
    final maps = all
        .map((country) => {'name': country.name, 'code': country.code})
        .toList();
    if (pinCode == null || pinCode.isEmpty || pinCode == 'todos') {
      return maps;
    }
    final pinned = maps.where((item) => item['code'] == pinCode).toList();
    if (pinned.isEmpty) return maps;
    final rest = maps.where((item) => item['code'] != pinCode).toList();
    return [...pinned, ...rest];
  }
}
