# 03 — Catálogo de módulos y trazabilidad T1–T12

## 1. Mapa de requisitos a módulos

| Req | Qué pedía | Módulo(s) |
|---|---|---|
| T1 | Usuarios y permisos | `security` |
| T2 | Instalación de módulos tipo ERP | `core` (registro) + `modules_admin` (UI/API) |
| T3 | Planos de equipos con puntos | `blueprints` |
| T4 | Vibraciones: espectros, plano, tablas, fotos | `vibration` (+ `measurements`, `media`) |
| T5 | Datos operativos reales | `operating_data` |
| T6 | Datos nominales de fábrica | `nameplate` |
| T7 | Ultrasonido | `ultrasound` |
| T8 | Termografía | `thermography` |
| T9 | Áreas de planta | `assets` |
| T10 | Equipos por área | `assets` |
| T11 | Servicios por fecha | `services` |
| T12 | Umbrales y estados configurables | `thresholds` |

Módulos que no estaban pedidos pero que el análisis de las fuentes hace
obligatorios (o casi):

| Módulo | Por qué |
|---|---|
| `measurements` | T4/T7/T8 comparten punto, lectura, unidad, evaluación y tendencia. Sin base común son tres implementaciones del mismo código. |
| `media` | R4 es transversal a T4/T7/T8 y no pertenece a ninguno. |
| `diagnostics` | El diario fechado + catálogo de fallas + recomendaciones con seguimiento (doc 00 §5). Es donde vive el valor del predictivo. |
| `reports` | El entregable al cliente. Las fuentes SON reportes. |
| `summaries` | **Informes**: semáforo de planta por área y sector, resúmenes por tipo de servicio. Es lo que la dirección mira; el reporte por equipo no lo sustituye. |
| `oil_analysis` | **En alcance.** 26 % del volumen anual del cronograma real (doc 00 §6). |
| `integrations` | OT/JD Edwards aparecen en los reportes. Fase 3. |
| `ai` | Fase 3. Consume `media` + `diagnostics`. |

## 2. Grafo de dependencias

```
core ──┬── security
       ├── assets ──┬── blueprints
       │            ├── nameplate
       │            └── measurements ──┬── vibration
       │                               ├── ultrasound
       │                               ├── thermography
       │                               └── operating_data
       ├── thresholds ───────────────────┘
       ├── media ────────────────────────┘
       ├── services ─────────────────────┤
       ├── summaries ────────────────────┘
       └── diagnostics ── reports
```

`core`, `security`, `assets` son **no desinstalables** (`is_core = True`). El
resto sí: una empresa que solo hace termografía instala `thermography` y no ve
nada de vibraciones.

## 3. Ficha por módulo

### `core`
Registro de módulos, bus de eventos, `Company`, multi‑tenant, auditoría,
configuración por compañía, bootstrap de sesión, tareas base de Celery.
**Expone:** `ModuleRegistry`, `EventBus`, `TenantScopedManager`, `SettingsRegistry`.

### `security` (T1)
`User` (interno o externo), `Membership`, `Role`, `Permission`,
`ScopeRestriction`, JWT con refresh rotatorio, MFA opcional, `AuditLog`.
Los permisos se **declaran en el manifiesto de cada módulo** y se sincronizan al
instalar — igual que Odoo. Nadie escribe permisos a mano en una migración.

Incluye el rol **`external_inspector`**: invitación por correo, alcance por
áreas, lectura del activo y escritura **solo sobre el servicio que ejecutó él**
mientras siga abierto. Las reglas son predicados puros en `domain/policies.py`
(ver doc 02 §9), no `if` repartidos por las vistas.

### `modules_admin` (T2)
API + pantalla de "Aplicaciones": listar disponibles/instalados, instalar,
actualizar, desinstalar, ver dependencias, ver y editar `settings` del módulo,
sembrar datos de demo. Muestra el grafo y bloquea desinstalaciones que romperían
dependientes.

### `assets` (T9, T10)
`Plant`, `Area`, `Sector`, `AssetGroup`, `Equipment`, criticidad, frecuencia de
monitoreo, alta/baja, importador del RGP en Excel (las fuentes de este repo son
el primer caso de prueba), buscador por TAG, árbol navegable, códigos QR por
equipo para identificarlo en campo con el móvil.

### `blueprints` (T3)
`EquipmentBlueprint` versionado + `BlueprintAnnotation`. Editor de anotaciones en
el navegador (arrastrar puntos sobre la imagen), plantillas por tipo de conjunto
(motor‑bomba de 4 puntos ya viene creada), herencia: crear un equipo desde una
plantilla genera sus puntos y su plano base. Vista de solo lectura embebible en
reportes y en la pantalla de toma de datos.

### `measurements` (base de T4/T7/T8)
`MeasurementPoint`, `Technique`, `Magnitude`, `Unit`, `Reading`, `Instrument`,
motor de evaluación contra `thresholds`, cálculo de tendencia, detección de
salto brusco (delta % contra la toma anterior), matriz punto × fecha (la de
`TABLA DE TENDENCIAS`), exportación.
**Puertos:** `ReadingRepository`, `ThresholdResolver`, `TrendCalculator`.

### `vibration` (T4)
Extiende `measurements` con `Spectrum`, formas de onda, bandas de frecuencia
(1×, 2×, 3×, BPFO/BPFI/BSF/FTF, GMF, BPF), cálculo de frecuencias de falla a
partir de `nameplate` + rpm operativa, y overlay de cursores sobre el espectro.

**Instrumentos: SEMAPI y SKF, sin límite de equipos.** Hoy el cliente digita la
ronda en oficina; mañana sube el CSV que exporta el instrumento. Las dos rutas
terminan en el mismo `ImportResult`, así que el caso de uso que guarda una ronda
no sabe de dónde vienen los números. Los parsers se **registran**
(`ImporterRegistry`), no se cablean: añadir un tercer instrumento es una clase y
una llamada a `register()`.

### `ultrasound` (T7)
Lecturas en dB, captura de pantalla del equipo, audio heterodino (`MediaAsset`
de tipo audio con espectrograma generado), rutas de inspección de fugas y de
trampas de vapor, comparación contra línea base.

### `thermography` (T8)
Termogramas con `thermal_meta` (matriz radiométrica preservada), ΔT contra
referencia/ambiente/equipo gemelo, clasificación por norma NETA/ISO, cajas y
puntos de análisis sobre la imagen, imagen visual pareada.

### `operating_data` (T5)
`OperatingParameter` configurable por tipo de equipo, `OperatingReading`,
lubricación (lubricante, cantidad, intervalo, próxima), alineamiento (offset y
angular, pata coja con tolerancia), correlación operativo↔vibracional en el
mismo gráfico — que es la lectura que hoy no se puede hacer en el Excel.

### `nameplate` (T6)
`NameplateData` versionado, `BearingModel` con geometría, `Lubricant`,
catálogo de fabricantes, OCR de la foto de placa (fase 2, ya deja el hueco), y
cálculo de frecuencias características que consume `vibration`.

### `thresholds` (T12)
`ConditionStatus`, `AvailabilityStatus`, `ThresholdStandard`, `ThresholdSet`,
`ThresholdBand`, resolución en cascada, simulador ("con esta norma, cuántos
equipos cambiarían de estado" — antes de aplicarla), recálculo masivo auditado,
fixtures ISO 10816‑3 / Technical Associates / API 610.

### `services` (T11)
`ServicePlan`, `PlanLine`, `ServiceOrder`, `ServiceVisit`, `VisitParticipant`,
**vista de ejecución** (quién o quiénes hicieron cada servicio, con sus notas,
observaciones, conclusiones y recomendaciones, cada línea con su autor),
calendario y
cronograma anual (la vista del `2CRONOGRAMA…xlsx`), cumplimiento plan vs real,
asignación de cuadrilla, ruta de inspección optimizada por área, modo campo
offline‑tolerante.

### `media` (R4)
Ingesta masiva con subida directa a S3, cola de subida con reintentos,
deduplicación por hash, EXIF, derivadas nocturnas, galería por equipo/visita,
comparador lado a lado entre fechas. Detalle completo en doc 05.

### `diagnostics`
`EquipmentLogEntry`, `FaultMode`, recomendaciones con seguimiento y vencimiento,
plantillas de texto (los reportes repiten literalmente los mismos párrafos),
severidad, y el "Relato General de Planta" — que es exactamente el
`VIBRACION 2014 AMBEV - JUNIO.xls` generado solo.

### `summaries` (Informes)
Semáforo de planta: Área → Sector → Conjunto, coloreado por el **peor** estado
que contiene, con barra de reparto por estado, conteo y **cobertura** (qué
porcentaje se midió de verdad). Un semáforo por técnica. Colores tomados del
catálogo de estados, así que repintar `alarma` no necesita release. Exportable.

No confundir con `reports`: aquí se resume la planta para decidir; allí se emite
el documento por equipo que se firma al cliente.

### `oil_analysis`
Dos técnicas con el mismo flujo — tomar muestra, mandar al laboratorio, cargar
resultados días después — y límites distintos:

- **Lubricante**: viscosidad 40/100 °C, TAN, agua (ppm), código ISO 4406,
  índice ferroso PQ, Fe/Cu/Si, oxidación. 804 análisis/año en el plan real.
- **Dieléctrico**: rigidez dieléctrica (kV), agua, acidez, tensión interfacial,
  DGA. 11 análisis/año.

Ojo con la dirección del límite: en viscosidad, rigidez y tensión interfacial
**más bajo es peor**, al revés que en vibración. `higher_is_worse` es por
parámetro, no global.

### `reports` (Reportes de inspección)
Plantillas versionadas, snapshot congelado, render a PDF (WeasyPrint desde el
mismo HTML que ve el usuario, para que lo impreso sea lo visto), numeración
`MPd-AV-N°nnn-aa`, envío al cliente, firma, portal de descarga para
`client_viewer`.

## 4. Anatomía de un manifiesto

```python
# modules/thresholds/manifest.py
from core.modules import Manifest, MenuItem

MANIFEST = Manifest(
    code="thresholds",
    name="Umbrales y estados",
    summary="Normas, bandas y estados de condición, globales o por equipo",
    version="1.0.0",
    category="Configuración",
    depends=["core", "assets"],
    is_core=False,
    auto_install=True,
    permissions=[
        ("thresholds.view_set",     "Ver umbrales"),
        ("thresholds.manage_set",   "Crear y editar umbrales"),
        ("thresholds.manage_status","Gestionar estados de condición"),
        ("thresholds.recalculate",  "Recalcular estados históricos"),
    ],
    menu=[
        MenuItem(label="Umbrales", route="/settings/thresholds",
                 icon="gauge", order=20, parent="settings",
                 permission="thresholds.view_set"),
    ],
    settings_schema="thresholds.settings:ThresholdSettings",
    fixtures=["condition_statuses.yaml", "iso_10816_3.yaml", "technical_associates.yaml"],
    on_install="thresholds.hooks:seed_defaults",
    on_uninstall="thresholds.hooks:keep_data_warn",
    events_subscribed=["ReadingRecorded"],
    events_published=["ThresholdSetChanged", "EquipmentStatusChanged"],
)
```

El mismo manifiesto, servido por `/api/v1/modules/`, es lo que el front usa para
construir su menú y sus rutas. **Una sola fuente de verdad para los dos repos.**

## 5. Ciclo de vida

```
discover → validate deps → migrate → seed fixtures → sync permissions
         → on_install() → mark installed → publish ModuleInstalled
                                                    ↓
                                    front invalida bootstrap y remonta menú
```

`uninstall` invierte lo anterior **salvo el borrado de datos**: revoca permisos,
oculta menú y rutas, desuscribe eventos, marca `uninstalled`. Borrar datos es una
acción aparte, con doble confirmación y export previo obligatorio.

`upgrade` compara `version` del manifiesto con la de `InstalledModule`, corre
migraciones y `on_upgrade()`. Igual que Odoo con `-u`.
