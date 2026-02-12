# Aurora — Estado del MVP

## Completitud por Módulo
| Módulo | Frontend | Backend | Estado |
|--------|----------|---------|--------|
| Auth | 100% | 100% | ✅ Producción |
| Onboarding | 100% | 100% | ✅ Producción |
| Dashboard | 95% | 90% | ✅ Estable |
| Grow (Motor A) | 95% | 90% | ✅ Estable |
| Chat (Motor C) | 90% | 100% | 🧪 Testeado |
| Climate | 100% | 100% | ✅ Producción |
| Social (Pulse) | 90% | 90% | ✅ Estable |
| Profile | 100% | 100% | ✅ Producción |
| Notifications | 90% | 100% | ✅ Estable |
| Settings | 80% | 100% | 🧪 En progreso |

## Funcionalidades Pendientes (Post-MVP)
1. **Modo Offline Avanzado**: Sincronización completa de fotos cuando se recupera la conexión.
2. **Exportación de Datos**: Generación de PDF detallado del historial de cultivo.
3. **Integración con Sensores IoT**: Conexión directa vía Bluetooth/WiFi para lectura automática de VPD.
4. **Sistema de Gamificación Expandido**: Retos semanales y comunidad de expertos.

## Bugs Conocidos
1. **Scroll en Dashboard**: El scroll parallax puede tener saltos sutiles en dispositivos de gama baja.
2. **Carga de Imágenes**: En conexiones muy lentas, la miniatura de la galería puede tardar en renderizar a pesar del caché.

## Mejoras Recomendadas
1. **Seguridad**: Mover los secretos de `env_config.dart` a variables de entorno reales en el pipeline de CI/CD para evitar que queden en el binario final de Flutter (usar `--dart-define-from-file`).
2. **Testing**: Incrementar la cobertura de tests unitarios en la capa de Domain para los casos de uso de clima.
3. **UI/UX**: Refinar las micro-animaciones del widget de ciclo de vida de la planta para que sean más fluidas.
