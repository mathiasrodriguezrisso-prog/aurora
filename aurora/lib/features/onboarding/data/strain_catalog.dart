/// Catálogo local de cepas populares para el autocompletado.
/// Usado hasta que se conecte al backend para búsqueda.
library;

const List<Map<String, String>> kStrainCatalog = [
  {'name': 'Blue Dream', 'type': 'Sativa Hybrid', 'difficulty': 'Fácil'},
  {'name': 'OG Kush', 'type': 'Indica Hybrid', 'difficulty': 'Media'},
  {'name': 'White Widow', 'type': 'Balanced Hybrid', 'difficulty': 'Fácil'},
  {'name': 'Northern Lights', 'type': 'Indica', 'difficulty': 'Fácil'},
  {'name': 'Girl Scout Cookies', 'type': 'Indica Hybrid', 'difficulty': 'Media'},
  {'name': 'Gorilla Glue #4', 'type': 'Indica Hybrid', 'difficulty': 'Media'},
  {'name': 'Amnesia Haze', 'type': 'Sativa', 'difficulty': 'Difícil'},
  {'name': 'Critical Mass', 'type': 'Indica', 'difficulty': 'Fácil'},
  {'name': 'AK-47', 'type': 'Sativa Hybrid', 'difficulty': 'Fácil'},
  {'name': 'Sour Diesel', 'type': 'Sativa', 'difficulty': 'Media'},
  {'name': 'Jack Herer', 'type': 'Sativa', 'difficulty': 'Media'},
  {'name': 'Purple Haze', 'type': 'Sativa', 'difficulty': 'Media'},
  {'name': 'Skunk #1', 'type': 'Indica Hybrid', 'difficulty': 'Fácil'},
  {'name': 'Super Silver Haze', 'type': 'Sativa', 'difficulty': 'Difícil'},
  {'name': 'Cheese', 'type': 'Indica Hybrid', 'difficulty': 'Fácil'},
  {'name': 'Blueberry', 'type': 'Indica', 'difficulty': 'Media'},
  {'name': 'Gelato', 'type': 'Indica Hybrid', 'difficulty': 'Media'},
  {'name': 'Wedding Cake', 'type': 'Indica Hybrid', 'difficulty': 'Media'},
  {'name': 'Zkittlez', 'type': 'Indica', 'difficulty': 'Media'},
  {'name': 'Runtz', 'type': 'Balanced Hybrid', 'difficulty': 'Media'},
];

/// Lista de nombres para el autocompletado.
final List<String> kStrainNames =
    kStrainCatalog.map((s) => s['name']!).toList();
