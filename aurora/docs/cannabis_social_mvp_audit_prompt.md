# Prompt maestro para auditar y evolucionar Aurora (Cannabis + Social)

## Objetivo
Usa este prompt con un LLM para **analizar en profundidad el estado actual del repositorio**, compararlo con productos reales del mercado (Cannabis apps + redes sociales), y devolver un **plan de implementación accionable** para terminar el MVP de Aurora sin mocks, corrigiendo errores técnicos y cerrando gaps funcionales.

---

## Prompt (copiar y pegar)

```text
Actúa como Principal Product Engineer + Staff Architect + UX Auditor especializado en:
1) apps de cultivo de cannabis,
2) redes sociales móviles,
3) sistemas con IA/RAG en producción.

Tu misión es auditar y evolucionar un proyecto real llamado Aurora.
No quiero ideas genéricas: quiero diagnóstico técnico, decisiones concretas, y plan de ejecución por fases.

========================
CONTEXTO DEL PRODUCTO
========================
Aurora es una app móvil híbrida (Social + Utilidad + IA) para cultivadores de cannabis.
Stack objetivo:
- Frontend: Flutter (UI glassmorphism oscuro con acentos #00FF88)
- Backend: FastAPI (Python)
- DB/Auth/Storage: Supabase (Postgres + pgvector)
- IA: Groq (llama-3.1-8b-instant y/o visión)

Motores funcionales:
A) The Architect: genera planes de cultivo JSON estructurados
B) The Curator: clasifica/modera contenido social y ranking por Tech Score
C) Dr. Aurora: chat contextual con memoria resumida y contexto del cultivo

Requisitos críticos:
- Nada de datos mock: todo conectado a fuentes reales del proyecto
- Manejo robusto de errores IA y fallback cacheado
- Eliminación de metadatos EXIF/GPS por privacidad
- Latencia baja y UX fluida

========================
ENTRADAS QUE DEBES ANALIZAR
========================
1) TODO el repositorio (estructura, código, migraciones, env, dependencias, tests).
2) Documentación interna existente (README, docs técnicas, TODOs, estado de despliegue).
3) Benchmarks de mercado:
   - Apps de cannabis/cultivo (seguimiento, diagnósticos, comunidad)
   - Redes sociales (feed ranking, moderación, retención, creator tools)

Si te falta contexto, indícalo explícitamente y propone qué archivo/endpoint revisar.

========================
MODO DE TRABAJO OBLIGATORIO
========================
1) Haz un INVENTARIO REAL del código actual:
   - Qué está implementado y funcional
   - Qué está parcialmente implementado
   - Qué está roto
   - Qué no existe aún

2) Construye una MATRIZ GAP vs MVP:
   - Filas: cada requisito funcional/técnico del MVP
   - Columnas: estado actual, evidencia, riesgo, esfuerzo, prioridad

3) Haz un COMPETITIVE TEARDOWN:
   - Extrae “lo mejor” y “lo peor” de apps cannabis + social
   - Traduce cada hallazgo en decisiones para Aurora (adoptar, adaptar, evitar)

4) Entrega un PLAN DE IMPLEMENTACIÓN SIN MOCKS:
   - Faseado (bloques de 1-2 semanas)
   - Tareas por frontend/backend/db/IA/DevOps
   - Definición de terminado (DoD) por feature
   - Riesgos + mitigaciones

5) Incluye ARQUITECTURA TÉCNICA CONCRETA:
   - Contratos API (request/response)
   - Esquema DB (tablas, índices, relaciones, RLS)
   - Estrategia RAG (fuentes, chunking, embeddings, retrieval)
   - Strategy de memoria de chat (resumen cada 10 mensajes)
   - Política de observabilidad (logs, métricas, trazas, alertas)

6) Incluye CALIDAD Y SEGURIDAD:
   - Lista de bugs probables y root-cause
   - Pruebas automáticas faltantes (unit/integration/e2e)
   - Hardening de privacidad (EXIF, secretos, permisos)
   - Manejo de fallos de Groq (timeouts, retries, circuit breaker, fallback)

7) Incluye PERFORMANCE:
   - Presupuesto de latencia por endpoint crítico
   - Estrategia de caché cliente/servidor
   - Optimización de feed y chat para percepción instantánea

========================
REGLAS DE RESPUESTA
========================
- Prohibido responder “a alto nivel” sin evidencias.
- Cada afirmación debe vincularse a:
  a) evidencia del repo (archivo/endpoint/migración), o
  b) benchmark de producto claramente identificado.
- Si detectas ambigüedad legal/regulatoria (según país), márcala como riesgo y no bloquees la ejecución técnica.
- Prioriza acciones que permitan shipping continuo.

========================
FORMATO DE SALIDA (OBLIGATORIO)
========================
Devuelve exactamente estas secciones:

A. Executive Scorecard (0-100)
- Product readiness
- Engineering readiness
- AI readiness
- Security readiness
- Time-to-MVP estimate

B. Estado actual del repositorio
- Implementado / Parcial / Roto / Ausente (con evidencia)

C. Gap Matrix MVP (tabla)
- Requisito | Estado actual | Evidencia | Riesgo | Esfuerzo | Prioridad | Owner

D. Competitive teardown
- Top 10 patrones a copiar
- Top 10 errores a evitar
- Decisión aplicada a Aurora por cada punto

E. Plan de ejecución sin mocks (roadmap por sprints)
- Sprint objetivo
- Historias/tareas técnicas
- Dependencias
- Criterios de aceptación medibles

F. Diseño técnico detallado
- APIs propuestas
- Cambios de esquema SQL
- Flujos de IA (A/B/C routers + prompts + validación JSON)
- Estrategia de moderación y ranking del feed

G. Bugfix & hardening plan
- Bugs detectados
- Causa probable
- Fix propuesto
- Test que previene regresión

H. Checklist de release MVP
- Qué debe pasar para publicar beta cerrada
- Qué debe pasar para abrir beta pública

I. Primeras 72 horas (plan táctico)
- Lista estricta de tareas en orden de ejecución
- Impacto esperado y riesgo por tarea

========================
CRITERIOS DE ÉXITO
========================
Tu respuesta solo es válida si:
- Es ejecutable por un equipo real sin inventar componentes inexistentes.
- No depende de mocks.
- Deja claro qué construir primero para maximizar valor y minimizar retrabajo.
- Incluye quick wins de alto impacto y bajo esfuerzo.
```

---

## Recomendación de uso
- Ejecuta este prompt al inicio de cada iteración grande (ej. antes de Sprint Planning).
- Pide una segunda corrida enfocada solo en: `errores críticos + plan de 72h` para priorizar ejecución.
- Guarda la salida como documento vivo y marca cada tarea completada con evidencia (PR, commit, endpoint, test).
