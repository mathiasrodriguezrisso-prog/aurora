# VPD (Déficit de Presión de Vapor) — Guía Técnica

## ¿Qué es el VPD?

El VPD (Vapor Pressure Deficit) es la diferencia entre la cantidad de humedad que el aire PUEDE contener (a una temperatura dada) y la cantidad de humedad que REALMENTE contiene. Se mide en kilopascales (kPa).

En términos prácticos: el VPD indica cuánta "fuerza de evaporación" ejerce el aire sobre las hojas de la planta. Un VPD alto significa que el aire está "sediento" y extrae mucha humedad de la planta. Un VPD bajo significa que el aire está saturado y la planta no puede transpirar eficientemente.

### ¿Por qué importa más que la humedad sola?

La humedad relativa (HR%) por sí sola no cuenta la historia completa. Una HR de 60% a 20°C tiene un VPD completamente diferente que una HR de 60% a 30°C. El VPD integra AMBAS variables (temperatura y humedad) en un solo número que predice el comportamiento de la planta.

## Fórmula de Cálculo

### Paso 1: Presión de Vapor Saturada (SVP)

Usando la ecuación de Tetens:

```
SVP = 0.6108 × exp((17.27 × T) / (T + 237.3))
```

Donde:
- SVP = Presión de vapor saturada en kPa
- T = Temperatura en °C
- exp = función exponencial (e^x)

### Paso 2: VPD

```
VPD = SVP × (1 - RH / 100)
```

Donde:
- RH = Humedad relativa en %

### Ejemplo de cálculo

A 25°C y 60% HR:
1. SVP = 0.6108 × exp((17.27 × 25) / (25 + 237.3)) = 0.6108 × exp(1.6465) = 0.6108 × 5.188 = 3.168 kPa
2. VPD = 3.168 × (1 - 60/100) = 3.168 × 0.40 = 1.267 kPa

### Nota sobre temperatura foliar
Para mayor precisión, se usa la temperatura de la HOJA (T_leaf) que típicamente es 1-3°C menor que la temperatura ambiente (T_air) debido a la transpiración. Algunos sensores infrarrojos pueden medir T_leaf directamente.

```
VPD_leaf = SVP(T_leaf) × (1 - RH / 100)
```

## VPD Óptimo por Fase de Crecimiento

| Fase | VPD Óptimo (kPa) | VPD Mínimo | VPD Máximo | Razonamiento |
|------|------------------|------------|------------|-------------|
| Clones/esquejes | 0.2-0.6 | 0.1 | 0.8 | Sin raíces desarrolladas, la transpiración debe ser MÍNIMA. Humedad alta (dome). |
| Plántulas | 0.4-0.8 | 0.3 | 1.0 | Raíces pequeñas, capacidad de absorción limitada. Transpiración suave. |
| Vegetativo temprano | 0.4-0.8 | 0.4 | 1.0 | Desarrollo radicular activo. Incrementar VPD gradualmente conforme crece. |
| Vegetativo tardío | 0.8-1.2 | 0.6 | 1.4 | Raíces establecidas, la planta puede manejar mayor transpiración. Esto maximiza absorción de nutrientes. |
| Floración temprana | 1.0-1.4 | 0.8 | 1.6 | Transpiración activa. Reducir humedad para prevenir botrytis en cogollos formándose. |
| Floración media | 1.0-1.5 | 0.8 | 1.6 | Cogollos densos son propensos a hongos. Mantener VPD en rango alto. |
| Floración tardía | 1.2-1.6 | 1.0 | 1.8 | Máxima prevención de humedad en cogollos maduros. Algunos cultivadores llegan a 1.6+ la última semana. |

## Tabla Cruzada: Temperatura × Humedad → VPD (kPa)

| T°C \ HR% | 30% | 35% | 40% | 45% | 50% | 55% | 60% | 65% | 70% | 75% | 80% | 85% | 90% |
|-----------|------|------|------|------|------|------|------|------|------|------|------|------|------|
| 18 | 1.44 | 1.34 | 1.24 | 1.13 | 1.03 | 0.93 | 0.82 | 0.72 | 0.62 | 0.52 | 0.41 | 0.31 | 0.21 |
| 19 | 1.54 | 1.43 | 1.32 | 1.21 | 1.10 | 0.99 | 0.88 | 0.77 | 0.66 | 0.55 | 0.44 | 0.33 | 0.22 |
| 20 | 1.64 | 1.52 | 1.40 | 1.29 | 1.17 | 1.05 | 0.94 | 0.82 | 0.70 | 0.58 | 0.47 | 0.35 | 0.23 |
| 21 | 1.74 | 1.62 | 1.49 | 1.37 | 1.24 | 1.12 | 0.99 | 0.87 | 0.75 | 0.62 | 0.50 | 0.37 | 0.25 |
| 22 | 1.85 | 1.72 | 1.59 | 1.45 | 1.32 | 1.19 | 1.06 | 0.92 | 0.79 | 0.66 | 0.53 | 0.40 | 0.26 |
| 23 | 1.97 | 1.83 | 1.69 | 1.55 | 1.40 | 1.26 | 1.12 | 0.98 | 0.84 | 0.70 | 0.56 | 0.42 | 0.28 |
| 24 | 2.10 | 1.95 | 1.79 | 1.64 | 1.49 | 1.34 | 1.19 | 1.04 | 0.89 | 0.74 | 0.60 | 0.45 | 0.30 |
| 25 | 2.22 | 2.06 | 1.90 | 1.74 | 1.58 | 1.43 | 1.27 | 1.11 | 0.95 | 0.79 | 0.63 | 0.47 | 0.32 |
| 26 | 2.36 | 2.19 | 2.02 | 1.85 | 1.68 | 1.51 | 1.34 | 1.18 | 1.01 | 0.84 | 0.67 | 0.50 | 0.34 |
| 27 | 2.50 | 2.32 | 2.14 | 1.96 | 1.78 | 1.61 | 1.43 | 1.25 | 1.07 | 0.89 | 0.71 | 0.54 | 0.36 |
| 28 | 2.65 | 2.46 | 2.27 | 2.08 | 1.89 | 1.70 | 1.51 | 1.32 | 1.13 | 0.94 | 0.76 | 0.57 | 0.38 |
| 29 | 2.81 | 2.61 | 2.41 | 2.21 | 2.01 | 1.81 | 1.60 | 1.40 | 1.20 | 1.00 | 0.80 | 0.60 | 0.40 |
| 30 | 2.97 | 2.76 | 2.55 | 2.34 | 2.12 | 1.91 | 1.70 | 1.49 | 1.27 | 1.06 | 0.85 | 0.64 | 0.42 |
| 31 | 3.15 | 2.92 | 2.70 | 2.47 | 2.25 | 2.02 | 1.80 | 1.57 | 1.35 | 1.12 | 0.90 | 0.67 | 0.45 |
| 32 | 3.33 | 3.09 | 2.86 | 2.62 | 2.38 | 2.14 | 1.90 | 1.67 | 1.43 | 1.19 | 0.95 | 0.71 | 0.48 |

### Cómo usar esta tabla
1. Mide tu temperatura y humedad actual.
2. Busca la celda correspondiente en la tabla.
3. Compara con el VPD ideal para tu fase de crecimiento.
4. Ajusta temperatura o humedad para acercarte al rango óptimo.

## Cómo Ajustar el VPD

### Para SUBIR el VPD (necesitas más transpiración)
- **Bajar la humedad:** Usar deshumidificador, aumentar extracción de aire, reducir frecuencia de riego.
- **Subir la temperatura:** Acercar las luces (con cuidado), reducir la extracción de aire, usar calefactor.
- Recuerda: subir temperatura sin bajar humedad tiene efecto limitado porque SVP sube pero HR sigue igual.

### Para BAJAR el VPD (la planta se está secando demasiado)
- **Subir la humedad:** Usar humidificador, poner bandejas de agua, reducir extracción, regar más frecuentemente.
- **Bajar la temperatura:** Alejar las luces, aumentar extracción, usar aire acondicionado.

## Relación del VPD con la Planta

### Transpiración y absorción de nutrientes
La transpiración es el motor que impulsa la absorción de agua y nutrientes a través de las raíces. Un VPD óptimo crea un flujo de transpiración constante que:
- Mueve nutrientes desde las raíces hasta las hojas y cogollos.
- Enfría las hojas mediante evaporación.
- Estimula la apertura estomática para que entre CO2 para la fotosíntesis.

### VPD demasiado bajo (< 0.4 kPa)
- Los estomas se cierran parcialmente porque no hay necesidad de transpirar.
- La absorción de nutrientes disminuye.
- El agua se condensa en las hojas y cogollos.
- ALTO riesgo de botrytis (bud rot), oidio (powdery mildew) y otros hongos.
- Edema: las hojas absorben más agua de la que transpiran y aparecen protuberancias.

### VPD demasiado alto (> 1.8 kPa)
- La planta se deshidrata más rápido de lo que las raíces pueden absorber.
- Los estomas se CIERRAN defensivamente para conservar agua.
- La fotosíntesis SE DETIENE porque no entra CO2.
- Las hojas se curvan hacia arriba (taco/canoa), los bordes se secan.
- Las puntas de las raíces pueden dañarse por deshidratación.

### VPD en el rango óptimo
- Los estomas están completamente abiertos.
- Máxima fotosíntesis y absorción de CO2.
- Flujo constante y estable de nutrientes desde las raíces.
- La planta crece a su máximo potencial genético.
- Equilibrio perfecto entre transpiración y absorción.
