/// Mapa de sugerencias de preguntas rápidas según la fase del cultivo.
library;

class ChatSuggestions {
  static const Map<String, List<String>> _suggestionsByPhase = {
    'germination': [
      '¿Cuánto tarda en germinar?',
      '¿Qué temperatura para germinar?',
      'No veo raíz todavía',
      '¿Método de servilleta o directo?',
      '¿Cuánta agua para germinar?',
    ],
    'seedling': [
      '¿Cuándo trasplanto la plántula?',
      'Cotiledones amarillos, ¿es normal?',
      '¿Ya puedo dar nutrientes?',
      '¿A qué distancia la luz?',
      'Se está estirando mucho',
    ],
    'vegetative': [
      '¿Cuándo hago topping?',
      '¿Cuánto debo regar?',
      'Hojas amarillas en la parte baja',
      '¿Cuándo cambio a floración?',
      '¿LST o SCROG?',
      '¿Qué EC para vegetativo?',
    ],
    'pre_flowering': [
      '¿Ya puedo cambiar a 12/12?',
      '¿Cómo identifico el sexo?',
      'Necesito defoliar antes de flora?',
      '¿Subo los nutrientes de PK?',
    ],
    'flowering': [
      '¿Cuándo cosecho?',
      'Tricomas transparentes aún',
      '¿Debo subir el fósforo/potasio?',
      '¿Cuándo empiezo el lavado?',
      'Hojas se ponen moradas',
      '¿Riesgo de moho en los cogollos?',
      '¿Cómo reviso los tricomas?',
    ],
    'flushing': [
      '¿Cuántos días de lavado?',
      'Las hojas caen, ¿es normal?',
      '¿Solo agua o con enzimas?',
      '¿Cómo sé que el flush está listo?',
    ],
    'drying': [
      '¿Temperatura para secado?',
      '¿Humedad ideal para secar?',
      '¿Cuántos días de secado?',
      '¿Cómo sé si está seco?',
    ],
    'curing': [
      '¿Cuánto tiempo de curado?',
      '¿Cada cuánto abro los frascos?',
      '¿Humedad ideal en el frasco?',
      'Huele a heno, ¿es normal?',
    ],
  };

  static const List<String> _genericSuggestions = [
    '¿Cómo empiezo mi primer cultivo?',
    '¿Qué cepa me recomiendas?',
    '¿Indoor o outdoor?',
    '¿Tierra o hidro para empezar?',
    '¿Qué luces necesito?',
    '¿Cuánto cuesta montar un indoor?',
  ];

  /// Obtiene sugerencias basadas en la fase actual del cultivo.
  /// Si no hay fase (no hay cultivo activo), retorna sugerencias genéricas.
  /// Retorna máximo [maxCount] sugerencias.
  static List<String> getSuggestions({String? phase, int maxCount = 4}) {
    if (phase == null || phase.isEmpty) {
      return _genericSuggestions.take(maxCount).toList();
    }
    
    // Normalizar fase (el backend puede enviar 'Flowering', 'flowering', 'FLOWERING', etc.)
    final normalizedPhase = phase.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    
    final suggestions = _suggestionsByPhase[normalizedPhase];
    if (suggestions == null || suggestions.isEmpty) {
      return _genericSuggestions.take(maxCount).toList();
    }
    
    return suggestions.take(maxCount).toList();
  }

  /// Obtiene TODAS las sugerencias de una fase (para un menú expandible)
  static List<String> getAllSuggestions({String? phase}) {
    if (phase == null) return _genericSuggestions;
    final normalized = phase.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _suggestionsByPhase[normalized] ?? _genericSuggestions;
  }
}
