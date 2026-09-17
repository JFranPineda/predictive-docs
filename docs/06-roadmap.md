# 06 — Roadmap y decisiones abiertas

## Fases

### Fase 0 — Cimientos (lo que se levanta primero)
`core` (registro de módulos + eventos + multi‑tenant), `security` (incluido el
rol de inspector externo y el alcance por área), `assets`, `thresholds` (estados,
perfiles por técnica y normas), `summaries`, `media` básico. Front: shell,
registro de módulos, bootstrap, login, árbol de activos, semáforo, design system.
**Criterio de terminado:** se importa el RGP real de este repo (558 equipos) y se
navega la planta con permisos por área.

### Fase 1 — Vertical de vibraciones
`measurements` + `vibration` + `blueprints` + `services` + `operating_data` +
`nameplate` + `diagnostics` + `reports`.
**Criterio de terminado:** se reproduce `MPd-AV-N°006-13-EB P-757` completo —
cabecera, plano con puntos, matriz de valores × fecha, límites aplicados,
tendencia, espectros con pie, conclusiones y recomendaciones fechadas — desde
datos del sistema y no de un Excel.

### Fase 2 — Las otras técnicas y la digitación en serio
`ultrasound`, `thermography`, `oil_analysis`, **rejilla de digitación masiva**
(teclado, tabulación por punto, pegado desde Excel), ingesta masiva de imágenes
a escala real, cronograma anual y cumplimiento.
**Criterio de terminado:** una ronda mensual completa de 280 equipos se digita
íntegra en el sistema, sin Excel de apoyo, en menos tiempo del que hoy cuesta
llenar la hoja.

Sin modo offline: no hay cobertura en planta y los datos se cargan en oficina.
Lo que sí se mantiene es la tolerancia a reintentos (`Idempotency-Key` por lote),
porque una digitación de 20 lecturas que se corta a la mitad no puede duplicar.

### Fase 2b — Importadores de instrumento
Parsers de SEMAPI DSP Logger y SKF Microlog detrás del puerto `ReadingImporter`
ya probado: el CSV que descarga el equipo se sube y se carga como servicio
realizado. Sin límite de equipos ni de instrumentos.

### Fase 3 — Inteligencia
`ai` + servicio `predictive-ml` en FastAPI:
1. **Lo primero no es un LLM**: reglas y umbrales adaptativos por historial
   (banda estadística del propio equipo, que es lo que ya hacían a mano en
   `EB P-757` con "de acuerdo a historial del equipo").
2. Detección de anomalía en tendencia (cambio de pendiente, salto).
3. Clasificación de espectros → modo de falla. El dataset es el par
   (imagen/array de espectro, `caption` + `FaultMode`) que doc 02 §3 ya guarda.
4. Visión sobre el registro fotográfico: fugas, corrosión, estado de acople,
   lectura de placa (OCR) para `nameplate`.
5. LLM sobre todo lo anterior para redactar el borrador de conclusiones y
   recomendaciones — con el analista firmando, nunca emitiendo solo.

El orden importa: los pasos 1–2 dan valor con los datos que ya existen; el 3–5
necesitan volumen etiquetado, y ese volumen solo llega si las fases 1–2 están en
producción. Por eso la etiqueta se captura desde el día 1 aunque no se use.

## Decisiones ya tomadas (y por qué)

| Decisión | Alternativa descartada | Razón |
|---|---|---|
| Django + DRF | FastAPI | T2 necesita migraciones por módulo, RBAC y registro; Django los trae. FastAPI se reserva para inferencia. |
| Jerarquía de 7 niveles | Área → Equipo, como pedía T9/T10 | Las fuentes tienen Sector y Conjunto Rotativo, y los límites se aplican al conjunto. |
| Estado de condición separado de disponibilidad | un solo campo `estado` | 13 % del RGP es "APAGADO" y contamina todo KPI. |
| Umbrales en cascada versionados | umbral por equipo | ISO se define una vez; el override lleva autor, fecha y motivo. |
| "No medido" es una lectura | ausencia de fila | Sin ello no hay cobertura de plan. |
| Timescale para lecturas | tablas normales | La consulta dominante es serie temporal a 3–5 años. |
| Espectros en Parquet/S3 | filas en Postgres | 10⁷ muestras/año/planta. |
| Originales de imagen conservados | borrar tras convertir | Son el dataset del modelo futuro. |
| Miniatura al subir + derivadas de noche | solo cron nocturno | Cumple R4 sin que el usuario espere a mañana para ver su foto. |
| Termogramas nunca recomprimidos | tratarlos como fotos | Se perdería la matriz radiométrica. |
| RTK Query como estado de servidor | Redux clásico para todo | Es un ERP: casi todo el estado es del servidor. |
| Módulos siempre migrados, activación por datos | recargar INSTALLED_APPS | Django no lo permite en caliente; y desinstalar no debe borrar histórico. |
| `asset_code` obligatorio y autogenerado, `client_tag` opcional | clave = TAG del cliente | El TAG se repite entre motor y bomba y a veces no existe; de `asset_code` cuelga todo lo demás. |
| Vocabulario de estados **por técnica** | una lista única de estados | Mantenimiento no tiene alarma; una ruta de vibraciones no retira equipos. |
| Norma asignada al equipo decide sus bandas | umbrales sueltos por equipo | Cambiar de ISO 10816‑3 a 20816‑3 recalifica la planta sin tocar umbrales. |
| Agregación forma parte del criterio (`Gs pico` ≠ `Gs p-p`) | una sola escala de envolvente | Los reportes reales usan una cada uno; 10 gE es parada en una y alarma en otra. |
| Inspector externo: lee el activo, escribe solo su visita abierta | rol de técnico normal | Un contratista no puede reescribir la planta ni firmar al cliente. |
| Varios ejecutantes por visita, autoría por línea | un campo "inspector" | La hoja real firma `HT / AJ`, y el supervisor escribe sus propias recomendaciones. |
| Semáforo: gana el peor, "no medido" aparte, cobertura visible | promedio o porcentaje de verdes | Un área verde al 50 % de cobertura es un problema de plan disfrazado. |

## Decidido (segunda ronda)

| Pregunta | Respuesta | Qué implica |
|---|---|---|
| Hosting | **VPS 8 de Contabo, Postgres propio**, migrar a plan mayor si hace falta | Un host con Docker Compose; Timescale como extensión, no como servicio. El disco es el límite: ver [doc 07](07-deployment.md). |
| Offline en campo | **No hay cobertura → no hay captura en planta.** Se digita en oficina, con internet | Fuera la PWA offline. A cambio, **la pantalla de digitación pasa a ser crítica**: rejilla con teclado, tabulación por punto, pegado desde Excel y validación al vuelo. |
| Instrumentos | **SEMAPI y SKF**, sin límite de equipos. Manual primero, importadores CSV después | El puerto `ReadingImporter` + registro ya existen y están probados; añadir un parser es una clase y un `register()`. |
| Multi‑cliente | **Sí, multitenant desde el día 1** | Confirmado lo ya diseñado: `Company` raíz, `company_id` en todo, RLS en Postgres. |
| Análisis de aceite | **Entra en alcance** | Módulo `oil_analysis` con dos técnicas: lubricante (viscosidad, TAN, agua, ISO 4406, PQ, metales) y dieléctrico (rigidez, DGA). 804 + 11 análisis/año en el cronograma real. |
| Integración ERP | **Solo anotar el número de OT**, integración más adelante | `client_work_order` + `external_refs` (JSONB) reservado. Ni un adaptador todavía. |
| Idioma | **Español e inglés**, conmutables en Configuración > Idioma | Ver §i18n abajo: es la pieza que más toca al front. |

### i18n: por qué no es solo un fichero de textos

En un ERP de mantenimiento **la mitad de lo que el usuario lee es dato, no
código**: nombres de estados, técnicas, magnitudes, normas, modos de falla,
parámetros operativos. Y el cliente añade los suyos desde la pantalla. Un `.po`
no llega ahí.

Por eso hay dos mecanismos, y es deliberado:

| Qué se traduce | Dónde vive | Cómo |
|---|---|---|
| Interfaz (botones, cabeceras, mensajes) | JSON por módulo, en su chunk | i18next; un módulo desinstalado no descarga sus textos |
| Catálogo (estados, normas, técnicas…) | columna `translations` JSONB en la propia fila | resuelto en el servidor y servido ya traducido |

Cadena de resolución, idéntica en los dos lados:
`elección guardada → preferencia del usuario → cabecera del navegador → empresa → es`.

Y una trampa encontrada al implementarlo: **`es-PE` escribe `1,234.50`, igual
que `en-US`; es `es-ES` quien escribe `1234,50`**. Dar por hecho "español =
coma decimal" habría corrompido todos los números que lee un usuario peruano.
El formateo va por `Intl`, nunca a mano.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| El alcance es un ERP entero y se intenta todo a la vez | Fases con criterio de terminado verificable contra los ficheros reales de este repo. |
| Los técnicos siguen usando Excel | Fase 1 debe reproducir el reporte exacto que ya entregan; si el sistema no emite *su* reporte, no lo adoptan. |
| Volumen de imágenes dispara el coste | Derivadas + ciclo de vida de almacenamiento + deduplicación, medidos desde el primer mes. |
| Umbrales mal migrados invalidan el histórico | `condition_status` congelado con su `threshold_set`; recálculo explícito y auditado. |
| El modelo de IA se intenta antes de tener datos | Fase 3 detrás de fases 1–2; captura de etiquetas desde el día 1. |
