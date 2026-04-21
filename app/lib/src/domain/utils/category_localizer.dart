/// Mapa de traducción de categorías del juego.
///
/// La clave es el [categoryId] que viene del backend (siempre en inglés/slug).
/// El valor es el nombre legible en el idioma actual de la app.
///
/// Para localizar a otro idioma, solo hay que cambiar los valores de este mapa
/// (o reemplazarlo por un sistema basado en ARB/l10n en el futuro).
class CategoryLocalizer {
  CategoryLocalizer._();

  static const Map<String, String> _es = {
    'animals': 'Animales',
    'places': 'Lugares',
    'objects': 'Objetos',
    'food': 'Comida',
    'celebrities': 'Celebridades',
    'eras': 'Épocas',
    'movies': 'Cine',
    'sports': 'Deportes',
    'professions': 'Profesiones',
    'brands': 'Marcas',
    'books': 'Libros',
  };

  static const Map<String, String> _en = {
    'animals': 'Animals',
    'places': 'Places',
    'objects': 'Objects',
    'food': 'Food',
    'celebrities': 'Celebrities',
    'eras': 'Eras',
    'movies': 'Movies',
    'sports': 'Sports',
    'professions': 'Professions',
    'brands': 'Brands',
    'books': 'Books',
  };

  /// Devuelve el nombre localizado del [categoryId].
  /// Si no se encuentra, devuelve el propio ID como fallback.
  static String localize(String categoryId, {String languageCode = 'es'}) {
    final normalized = languageCode.toLowerCase().startsWith('en') ? _en : _es;
    return normalized[categoryId] ?? categoryId;
  }
}
