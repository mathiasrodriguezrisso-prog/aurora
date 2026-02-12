/// Funciones PURAS de cálculo climático.
/// NO necesitan backend, NO necesitan IA.
/// Se usan para cálculos reactivos en la UI (mientras el usuario mueve sliders).
///
/// IMPORTANTE: Usar la FÓRMULA DE TETEN exacta.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class VPDCalculator {
  /// Calcula el Déficit de Presión de Vapor (VPD) en kPa.
  ///
  /// Fórmula de Teten:
  ///   SVP = 0.6108 * exp((17.27 * tempCelsius) / (tempCelsius + 237.3))
  ///   AVP = SVP * (humidityPercent / 100)
  ///   VPD = SVP - AVP
  ///
  /// [tempCelsius] Temperatura del aire en grados Celsius (rango típico: 15-35)
  /// [humidityPercent] Humedad relativa en porcentaje (rango: 0-100)
  /// Returns VPD en kPa (típicamente entre 0.0 y 3.0)
  static double calculateVPD(double tempCelsius, double humidityPercent) {
    if (tempCelsius < 0) return 0.0;
    if (humidityPercent < 0) humidityPercent = 0;
    if (humidityPercent > 100) humidityPercent = 100;

    final svp = 0.6108 *
        math.exp((17.27 * tempCelsius) / (tempCelsius + 237.3));
    final avp = svp * (humidityPercent / 100.0);
    final vpd = svp - avp;

    // Retornamos 2 decimales convertidos de nuevo a double
    return double.parse(vpd.toStringAsFixed(2));
  }

  /// Calcula el Índice de Luz Diaria (DLI) en mol/m²/d.
  ///
  /// Fórmula: DLI = PPFD × 3600 × hoursLight / 1000000
  ///
  /// [ppfd] Densidad de Flujo de Fotones Fotosintéticos en μmol/m²/s
  /// [hoursLight] Horas de luz por día (ej: 18 para veg, 12 para flora)
  /// Returns DLI en mol/m²/d
  static double calculateDLI(double ppfd, double hoursLight) {
    final dli = (ppfd * 3600 * hoursLight) / 1000000;
    return double.parse(dli.toStringAsFixed(2));
  }

  /// Calcula la temperatura de la hoja estimada.
  /// La hoja suele estar 1-2°C más fría que el aire debido a la transpiración.
  ///
  /// [airTemp] Temperatura del aire en °C
  /// [offset] Diferencia estimada (default: -2.0°C)
  static double estimateLeafTemp(double airTemp, {double offset = -2.0}) {
    return airTemp + offset;
  }

  /// Determina la zona VPD según la fase del cultivo.
  ///
  /// Rangos óptimos por fase:
  ///   Propagación/Plántula (seedling): 0.4 - 0.8 kPa
  ///   Vegetativo (vegetative): 0.8 - 1.0 kPa (extendido a 1.1 tolerado)
  ///   Floración temprana (flowering_early): 1.0 - 1.2 kPa
  ///   Floración tardía (flowering_late): 1.2 - 1.6 kPa
  ///
  /// Returns: VPDZone enum
  static VPDZone getVPDZone(double vpd, String phase) {
    double minOptimal, maxOptimal;

    switch (phase.toLowerCase()) {
      case 'seedling':
      case 'propagation':
        minOptimal = 0.4;
        maxOptimal = 0.8;
        break;
      case 'vegetative':
      case 'veg':
        minOptimal = 0.8;
        maxOptimal = 1.1; // Ligeramente más tolerante
        break;
      case 'flowering_early':
      case 'early_flower':
        minOptimal = 1.0;
        maxOptimal = 1.2;
        break;
      case 'flowering':
      case 'flowering_late':
      case 'late_flower':
      case 'flower':
        minOptimal = 1.2;
        maxOptimal = 1.6;
        break;
      default:
        // Default a vegetativo si no se reconoce
        minOptimal = 0.8;
        maxOptimal = 1.1;
    }

    // Critical: < 0.4 (Riesgo inminente de moho/hongos)
    if (vpd < 0.4) return VPDZone.critical;

    // Low: Entre 0.4 y el mínimo óptimo
    if (vpd >= 0.4 && vpd < minOptimal) return VPDZone.low;

    // Optimal: Dentro del rango
    if (vpd >= minOptimal && vpd <= maxOptimal) return VPDZone.optimal;

    // High: Entre el máximo óptimo y 1.6 (o un poco más)
    if (vpd > maxOptimal && vpd <= 1.8) return VPDZone.high;

    // Danger: > 1.8 (Riesgo de estrés hídrico severo / cierre de estomas)
    return VPDZone.danger;
  }

  /// Calcula un score de ambiente de 0-100.
  ///
  /// Ponderación:
  ///   - Temperatura dentro de rango: 30 puntos
  ///   - Humedad dentro de rango: 25 puntos
  ///   - VPD dentro de rango: 30 puntos
  ///   - pH dentro de rango: 10 puntos (si disponible, sino redistribuir)
  ///   - EC dentro de rango: 5 puntos (si disponible, sino redistribuir)
  ///
  /// Cada parámetro recibe puntaje completo si está en rango (ideal ± 0),
  /// y decae linealmente.
  static int calculateEnvironmentScore({
    required double temp,
    required double targetTempMin,
    required double targetTempMax,
    required double humidity,
    required double targetHumMin,
    required double targetHumMax,
    required double vpd,
    required String phase,
    double? ph,
    double? targetPhMin,
    double? targetPhMax,
    double? ec,
    double? targetEcMin,
    double? targetEcMax,
  }) {
    double score = 0.0;
    double maxScore = 0.0;

    // Helper para calcular puntaje parcial
    double getPartialScore(double current, double min, double max, double points) {
      if (current >= min && current <= max) return points;
      
      final center = (min + max) / 2;
      final range = max - min;
      final dist = (current - center).abs();
      // Tolerancia: hasta 2 veces el rango
      final maxDist = range * 1.5; 
      
      if (dist >= maxDist) return 0.0;
      
      // Decaimiento lineal
      // Si dist == range/2 (en el borde), score es points.
      // Si estamos fuera, calculamos la desviación extra.
      // Realmente: si está EN rango, 100%. Si sale, decae.
      
      // Simplificación: distancia al borde más cercano
      double distToEdge = 0.0;
      if (current < min) distToEdge = min - current;
      if (current > max) distToEdge = current - max;
      
      // Si se aleja más de "range" unidades, 0 puntos
      final tolerance = range; // Tolerancia igual al ancho del rango
      if (distToEdge >= tolerance) return 0.0;
      
      return points * (1.0 - (distToEdge / tolerance));
    }

    // 1. Temperature (30 pts)
    score += getPartialScore(temp, targetTempMin, targetTempMax, 30);
    maxScore += 30;

    // 2. Humidity (25 pts)
    score += getPartialScore(humidity, targetHumMin, targetHumMax, 25);
    maxScore += 25;

    // 3. VPD (30 pts)
    // VPD targets dependen de la fase internamente
    // Usamos getVPDZone para simplificar: Optimal=30, Low/High=15, Critical/Danger=0
    final zone = getVPDZone(vpd, phase);
    if (zone == VPDZone.optimal) score += 30;
    else if (zone == VPDZone.low || zone == VPDZone.high) score += 15;
    else score += 0;
    maxScore += 30;

    // 4. pH (10 pts)
    if (ph != null && targetPhMin != null && targetPhMax != null) {
      score += getPartialScore(ph, targetPhMin, targetPhMax, 10);
      maxScore += 10;
    }

    // 5. EC (5 pts)
    if (ec != null && targetEcMin != null && targetEcMax != null) {
      score += getPartialScore(ec, targetEcMin, targetEcMax, 5);
      maxScore += 5;
    }

    // Normalizar a 0-100 si faltan datos opcionals (pH/EC)
    if (maxScore == 0) return 0;
    
    // Si faltan pH o EC, los puntos maxScore son menos de 100 (ej: 85),
    // así que escalamos el resultado a 100.
    final finalScore = (score / maxScore) * 100;
    
    return finalScore.round().clamp(0, 100);
  }

  /// Retorna el color correspondiente a un valor VPD para el heatmap.
  /// Realiza interpolación entre colores de zonas.
  static Color getVPDColor(double vpd) {
    if (vpd <= 0.4) {
      // Critical (Azul) -> Low (Celeste)
      // 0.0 -> Azul, 0.4 -> Celeste
      // Interpolación simple
      return Color.lerp(
        const Color(0xFF2196F3), 
        const Color(0xFF4FC3F7), 
        (vpd / 0.4).clamp(0.0, 1.0)
      )!;
    } else if (vpd <= 0.8) {
      // Low (Celeste) -> Optimal (Verde Neón)
      return Color.lerp(
        const Color(0xFF4FC3F7), 
        const Color(0xFF00FF88), 
        ((vpd - 0.4) / 0.4).clamp(0.0, 1.0)
      )!;
    } else if (vpd <= 1.2) {
      // Optimal (Verde Neón) -> High (Naranja)
      // Nota: Rango óptimo amplio, mantenemos verde en el centro
      if (vpd <= 1.0) return const Color(0xFF00FF88);
      return Color.lerp(
        const Color(0xFF00FF88), 
        const Color(0xFFFFA726), 
        ((vpd - 1.0) / 0.2).clamp(0.0, 1.0)
      )!;
    } else if (vpd <= 1.6) {
      // High (Naranja) -> Danger (Rojo)
      return Color.lerp(
        const Color(0xFFFFA726), 
        const Color(0xFFEF5350), 
        ((vpd - 1.2) / 0.4).clamp(0.0, 1.0)
      )!;
    } else {
      // Danger (Rojo)
      return const Color(0xFFEF5350);
    }
  }

  /// Genera la matriz de datos para el VPD Heatmap.
  ///
  /// [tempMin] Temperatura mínima (Eje X start)
  /// [tempMax] Temperatura máxima (Eje X end)
  /// [tempStep] Pasos de temperatura (columna)
  /// [humMin] Humedad mínima (Eje Y start)
  /// [humMax] Humedad máxima (Eje Y end)
  /// [humStep] Pasos de humedad (fila)
  /// 
  /// Returns: List<List<double>> donde cada celda es el VPD calculado.
  /// El orden es: outer list = columnas (temp), inner list = filas (humedad)
  static List<List<double>> generateVPDMatrix({
    double tempMin = 15,
    double tempMax = 35,
    double tempStep = 1,
    double humMin = 30,
    double humMax = 90,
    double humStep = 5,
  }) {
    List<List<double>> matrix = [];

    // Iteramos por temperatura (columnas)
    for (double t = tempMin; t <= tempMax; t += tempStep) {
      List<double> column = [];
      // Iteramos por humedad (filas)
      // Nota: Visualmente humedad suele ir de abajo (min) a arriba (max),
      // o viceversa. El painter decidirá cómo dibujar.
      // Aquí generamos los datos puros.
      for (double h = humMin; h <= humMax; h += humStep) {
        column.add(calculateVPD(t, h));
      }
      matrix.add(column);
    }
    return matrix;
  }
}

/// Enum para zonas VPD
enum VPDZone {
  critical,    // Muy bajo, riesgo moho (<0.4)
  low,         // Bajo (0.4 - 0.8)
  optimal,     // Dentro del rango ideal
  high,        // Alto (1.2 - 1.6)
  danger,      // Muy alto, estrés severo (>1.6)
}

/// Extension para obtener label y color de cada zona
extension VPDZoneExtension on VPDZone {
  String get label {
    switch (this) {
      case VPDZone.critical: return 'Crítico — Riesgo de Moho';
      case VPDZone.low: return 'Bajo';
      case VPDZone.optimal: return 'Óptimo';
      case VPDZone.high: return 'Alto';
      case VPDZone.danger: return 'Peligro — Estrés';
    }
  }
  
  Color get color {
    switch (this) {
      case VPDZone.critical: return const Color(0xFF2196F3); // Azul
      case VPDZone.low: return const Color(0xFF4FC3F7);      // Celeste
      case VPDZone.optimal: return const Color(0xFF00FF88);   // Neón verde
      case VPDZone.high: return const Color(0xFFFFA726);      // Naranja
      case VPDZone.danger: return const Color(0xFFEF5350);    // Rojo
    }
  }
  
  IconData get icon {
    switch (this) {
      case VPDZone.critical: return Icons.water_drop;
      case VPDZone.low: return Icons.arrow_downward;
      case VPDZone.optimal: return Icons.check_circle;
      case VPDZone.high: return Icons.arrow_upward;
      case VPDZone.danger: return Icons.warning; // o local_fire_department
    }
  }
}
