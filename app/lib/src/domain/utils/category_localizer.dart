/// Mapa de traducción de categorías del juego.
///
/// La clave es el [categoryId] que viene del backend (siempre en inglés/slug).
/// El valor es el nombre legible en el idioma actual de la app.
///
/// Para localizar a otro idioma, solo hay que cambiar los valores de este mapa
/// (o reemplazarlo por un sistema basado en ARB/l10n en el futuro).
class CategoryLocalizer {
  CategoryLocalizer._();

  /// Traducciones en español. Extraer a ARB cuando se añada i18n completo.
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

  /// Devuelve el nombre localizado del [categoryId].
  /// Si no se encuentra, devuelve el propio ID como fallback.
  static String localize(String categoryId) {
    return _es[categoryId] ?? categoryId;
  }
}
