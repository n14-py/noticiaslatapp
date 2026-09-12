import 'package:flutter_test/flutter_test.dart';
import 'package:noticias_lat/core/data/latam_countries.dart';

void main() {
  test('el país anclado queda primero y el resto mantiene el orden original', () {
    final maps = LatamCountries.asFilterMaps(pinCode: 'py');

    expect(maps.first['code'], 'py');
    expect(maps.first['name'], 'Paraguay');
    expect(maps[1]['code'], 'todos');
    expect(maps.where((item) => item['code'] == 'py').length, 1);
    expect(maps.length, LatamCountries.all.length);
  });

  test('sin pin la lista empieza en Todos', () {
    final maps = LatamCountries.asFilterMaps();
    expect(maps.first['code'], 'todos');
    expect(maps[1]['code'], 'ar');
  });

  test('solo países LATAM soportados se pueden personalizar', () {
    expect(LatamCountries.isSupported('py'), isTrue);
    expect(LatamCountries.isSupported('cl'), isTrue);
    expect(LatamCountries.isSupported('todos'), isFalse);
    expect(LatamCountries.isSupported('us'), isFalse);
    expect(LatamCountries.byCode('CL')?.demonym, 'chileno');
    expect(LatamCountries.byCode('py')?.demonym, 'paraguayo');
  });
}
