# 02 — Modelo de dominio

Todas las entidades llevan `company_id`, `created_at`, `updated_at`,
`created_by`. Se omite en los diagramas por ruido.

## 1. Jerarquía de activos (T9, T10, T3)

```
Company ──< Plant ──< Area ──< Sector ──< AssetGroup ──< Equipment ──< MeasurementPoint
  cliente   planta   área      sector    conjunto       equipo        punto
                     501-...   COMPRESOR  BBA.AGUA-A     MOTOR/BOMBA   1H, 2V, 3A…
```

```python
Plant        code, name, timezone, address
Area         plant, code ("501"), name ("PACKAGING CERVEZA"), criticality, parent(self, opcional)
Sector       area, code, name
AssetGroup   sector, code, name ("BBA. AGUA CRUDA - TAG:A"), kind (motor_pump | motor_compressor |
             motor_gearbox | motor_fan | standalone), criticality, is_active
Equipment    asset_group, asset_code (obligatorio, único por company), client_tag (opcional),
             equipment_type (motor|pump|compressor|gearbox|fan|blower|bearing_housing|other),
             position_in_group (driver | driven | intermediate),
             applied_standard → ThresholdStandard, machine_class → MachineClass,
             availability_status, condition_status,
             monitoring_frequency (monthly|bimonthly|quarterly|semiannual|annual|on_demand),
             installed_at, retired_at
```

Los cinco niveles del RGP se respetan tal cual: ni se colapsa Sector en Área ni
Conjunto en Equipo. Los límites y las conclusiones se emiten al **conjunto**, el
estado y el TAG viven en el **equipo**, y la medición en el **punto**.

### `asset_code` obligatorio, `client_tag` opcional

`asset_code` es obligatorio y único por compañía; `client_tag` es opcional, texto
libre y **puede repetirse** — la fuente lo demuestra: `MB1141001B` aparece en el
motor y en la bomba de EB 228.

Obligatorio porque de él cuelgan lectura, foto, reporte y auditoría: una clave
nullable significa que el día que llega un equipo sin TAG, media aplicación se
queda sin a qué agarrarse. Y **se autogenera**, así que en la práctica nadie lo
teclea:

```
1. ¿Hay client_tag y está libre?  →  asset_code = ese TAG normalizado
   (MB101001A → MB101001A: la cuadrilla reconoce el suyo, eso vale más que
    cualquier esquema que inventemos)
2. ¿Repetido o vacío?             →  <área>-<tipo>-<correlativo>
   (114-BBA-001, 501-MOT-003)
```

Implementado en `assets/domain/asset_code.py`, con tests.

`Area.parent` existe porque en las fuentes conviven `121 - AIRE COMPRIMIDO` y
`122 - AIRE COMPRIMIDO`, y áreas con sufijo (`561S`, `562S`, `563S` bajo
"PACKAGING REFRIGERANTES"). Un nivel de anidación evita duplicar sectores.

### Punto de medición

```python
MeasurementPoint
    equipment            FK
    number               1..n  (posicional dentro del AssetGroup, como en las fuentes)
    side                 free_end | coupling_end | opposite_coupling | inboard | outboard | custom
    axis                 H | V | A | none
    point_type           bearing | electrical | thermal | ultrasound | lubrication | process
    label                "1H", "3V", "Pto 3HV"   (derivado, para mostrar)
    blueprint_x          0..1  ← posición normalizada sobre el plano (T3)
    blueprint_y          0..1
    is_active
    supported_magnitudes M2M → Magnitude
```

`blueprint_x/y` normalizados (0–1) y no en píxeles: el plano se puede sustituir
por otro de distinta resolución sin recolocar puntos.

### Plano del equipo (T3)

```python
EquipmentBlueprint
    equipment      FK
    media          FK → MediaAsset   (imagen o PDF vectorizado del equipo)
    version        int               (histórico: el plano cambia tras una modificación)
    is_current     bool
    kind           schematic | photo | cad | p_and_id
BlueprintAnnotation
    blueprint, point (FK opcional), x, y, shape (dot|arrow|zone), label, color, notes
```

Un plano puede anotar puntos de rodamiento, puntos eléctricos, puntos de
lubricación y zonas de riesgo. Las anotaciones **sin** `point` sirven para
señalizar cosas que no se miden (sentido de giro, acoplamiento, brida).

En el front esto es una imagen con overlay SVG: click en el punto → histórico del
punto. Es la misma pieza que en el reporte ocupa el bloque "PUNTOS DE INSPECCIÓN".

## 2. Catálogo de medición (base de T4, T5, T7, T8)

```python
Technique     code (vibration|ultrasound|thermography|lubrication|alignment|oil_analysis|
                    electrical|visual), name, module_code
Magnitude     code, technique, name, default_unit, aggregation (rms|peak|peak_to_peak|avg|max),
              higher_is_worse (bool), decimals
Unit          code ("mm/s","gE","Gs","°C","dB","PSI","Hz","rpm","A","V","kW"), si_factor, si_base
```

Magnitudes sembradas desde las fuentes:

| code | técnica | unidad | agregación |
|---|---|---|---|
| `vel_rms` | vibration | mm/s | rms |
| `env_accel` | vibration | gE | peak *y* peak_to_peak → **la unidad viaja con el dato** |
| `accel_rms` | vibration | g | rms |
| `disp_pp` | vibration | µm | peak_to_peak |
| `temp` | thermography | °C | max |
| `delta_temp` | thermography | K | max |
| `us_db` | ultrasound | dB | avg |
| `us_rms` | ultrasound | dB | rms |

La trampa `Gs pico` vs `Gs P-P` de doc 00 §2 se resuelve porque **`Reading` guarda
`unit` y `aggregation` propios**, no los hereda del catálogo.

## 3. Lectura (T4, T7, T8)

```python
Reading                       # hypertable Timescale
    taken_at         timestamptz   ← clave de partición
    company, point, service_visit, technique, magnitude
    value            numeric
    unit             FK
    aggregation      enum
    condition_status FK → ConditionStatus   (calculado en la escritura)
    threshold_set    FK  (cuál se aplicó; congelado, no se recalcula al cambiar la norma)
    instrument       FK
    operator         FK → User
    quality          ok | suspect | not_measured
    not_measured_reason  stopped | no_access | equipment_off | retired | null
    notes
```

Dos decisiones que se pagan caro si se hacen al revés:

1. **`condition_status` se congela con el `threshold_set` usado.** Si mañana
   alguien endurece la ISO, el histórico no se reescribe solo. Recalcular es una
   acción explícita y auditada.
2. **"no medido" es una lectura**, no una ausencia de fila. Los 62 `APAGADO` del
   RGP son información: distinguen "equipo sano" de "no fuimos". Sin esto no hay
   KPI de cobertura del plan.

### Espectro (T4)

```python
Spectrum
    reading (FK opcional), point, taken_at, spectrum_type (velocity|envelope|acceleration|demodulation),
    fmin_hz, fmax_hz, lines, rpm_at_capture, window, averages,
    data_uri            → S3 parquet {freq[], amp[]}   (si hay dato numérico)
    image               → MediaAsset                   (captura de pantalla del instrumento)
    caption             "En modo Velocidad Pto 3HV, muestra desalineamiento"
    diagnosis           M2M → FaultMode
```

Acepta las dos realidades de doc 00 §8: hoy hay capturas, mañana hay arrays.
`caption` + `diagnosis` son el par (imagen, etiqueta) para el modelo futuro.

## 4. Estados, normas y umbrales — T12

Tres piezas, no una: **qué estados existen**, **qué norma juzga al equipo** y
**qué bandas aplica esa norma**.

### 4.1 Estados por técnica

El estado no es una lista única: depende del servicio que se hace.

| Técnica | Vocabulario |
|---|---|
| Vibraciones, ultrasonido | `apagado` · `operativo` · `alarma` · `parada` |
| Termografía | `operativo` · `alarma` · `parada` · `apagado` |
| Mantenimiento, lubricación | `apagado` · `retirado` · `fuera de servicio` · `operativo` |

Se muestran en una sola lista al técnico, pero por dentro siguen siendo dos
naturalezas distintas, y esa separación es la que salva los KPI:

```python
Status
    code, name, kind (condition | availability), severity, color,
    requires_action, is_terminal,
    measurable   # solo availability: ¿se puede medir estando así?

TechniqueStatusProfile   technique  (1:1)
TechniqueStatusOption    profile, status, order, display_name (override por técnica)
```

- **`condition`** (`operativo`/`alarma`/`parada`) se **calcula** a partir del
  valor medido y sus bandas.
- **`availability`** (`apagado`/`retirado`/`fuera de servicio`) la **declara** el
  técnico, y explica por qué no hay valor. Ninguno de ellos es `measurable`.

Un perfil impide, por construcción, que una ruta de vibraciones declare un equipo
`retirado` o que una termografía emita `parada` si su perfil no lo incluye
(`validate_against_profile`, `declare_availability`). Añadir un estado nuevo es
una fila más, no una migración: T12 lo pedía explícitamente.

### 4.2 Normas — Configuración global > Normas

```python
ThresholdStandard   code, name, source, description, is_builtin, is_active
MachineClass        standard, code, name, description, order
```

Sembradas: ISO 10816‑3 (Clases I–IV), ISO 20816‑3, ISO 10816‑7 (Categorías I–II),
ISO 18436‑2, Technical Associates of Charlotte, NETA MTS. Una empresa añade la
suya desde la pantalla, sin tocar código; las clases de máquina **pertenecen a la
norma**, no son un texto libre en el equipo.

Cada equipo lleva `applied_standard` + `machine_class`. **Cambiar la norma
asignada cambia sus límites y por tanto su estado**, sin tocar ni una fila de
umbrales:

```
motor clase III, 6.5 mm/s   bajo ISO 10816-3 → ALARMA   (4.5 / 7.1)
                            bajo ISO 20816-3 → PARADA   (3.5 / 6.1)
```

### 4.3 Bandas y cascada

```python
ThresholdSet
    standard (FK, vacío = criterio propio), machine_class (FK),
    scope  global | equipment_type | asset_group_kind | equipment | point
    scope_ref_id, magnitude_code, unit_code, aggregation,
    valid_from, valid_to, version, author, rationale, is_active
ThresholdBand
    threshold_set, status (solo kind=condition), min_value, max_value, order
```

**Orden de resolución** (gana el más específico, activo y vigente a la fecha de
la lectura):

```
point > equipment > asset_group_kind > equipment_type > global
```

y además tienen que coincidir magnitud, **agregación**, clase de máquina y
norma. Un juego **sin norma** es un criterio escrito a mano y compite siempre:
eso es exactamente lo que es el override de EB 228 (`4.5 / 6.5`,
`rationale = "historial del equipo"`, con autor y fecha).

La agregación forma parte del criterio, no es una etiqueta. `env_accel` en
**Gs pico** y en **Gs pico‑pico** son dos criterios distintos, los dos válidos, y
nunca se resuelven el uno al otro:

| | Normal | Alarma | Parada |
|---|---|---|---|
| Envolvente `Gs pico` | < 2.5 | — | > 4.0 |
| Envolvente `Gs p-p` | < 9.0 | 9.0 – 15.0 | > 15.0 |

Los mismos 10 gE son **parada** en la primera escala y **alarma** en la segunda.
Por eso la unidad y la agregación viajan con el dato.

Bandas con `min`/`max` nullable y sin estados cableados; se valida que no se
solapen (un solape hace que el veredicto dependa del orden, que es como dos
analistas sacan dos respuestas del mismo número).

## 5. Servicios y programación (T11)

```python
ServicePlan        plant, year, name, status
PlanLine           plan, technique, frequency_days (30|60|90|120|150|180|365),
                   scope (area|asset_group|equipment), scope_ref, planned_points, planned_mandays
ServiceOrder       plant, technique, code ("MPd-AV-N°006-13"), client_work_order ("OT 1382630"),
                   scheduled_from, scheduled_to, status (planned|in_progress|done|cancelled),
                   lead_analyst, supervisor
ServiceVisit       service_order, equipment, visited_at, availability_status (declarado,
                   del perfil de la técnica), instrument, duration_min, geo, is_closed,
                   closed_at, closed_by
VisitParticipant   visit, user, role (lead_analyst | assistant | supervisor | client_witness)
```

**Quién o quiénes.** Una visita tiene varios ejecutantes, no uno: los reportes
nombran "Inspector Analista" y "Supervisor", y la hoja de tendencias firma la
ronda con iniciales, a veces dos (`HT / AJ`). Cada participante puede editar la
visita mientras esté abierta; cada línea de notas conserva **su propio autor**,
para que la recomendación del supervisor no acabe atribuida al inspector.

`ServiceVisit` es la bisagra: **toda** lectura, foto, espectro, dato operativo y
conclusión cuelga de una visita. Es lo que permite responder "qué se hizo el
2013‑12‑17 en EB P‑757" y calcular plan vs ejecutado (§ doc 00 §6, donde los
intervalos reales van de 15 a 75 días contra un plan de 30).

`ServiceOrder.code` reproduce la nomenclatura real `MPd-AV-N°006-13`
(`MPd` = mantenimiento predictivo, `AV` = análisis vibracional, correlativo, año).

## 6. Datos operativos (T5) y nominales (T6)

Dos tablas gemelas, deliberadamente distintas:

```python
OperatingReading            # T5 — medido en la visita, cambia cada vez
    service_visit, equipment, parameter (FK OperatingParameter), value, unit, taken_at
OperatingParameter
    code, name, unit, applies_to (equipment_type[]), is_cumulative
    # rpm, current_a, voltage_v, power_kw, power_factor, freq_hz, running_hours,
    # suction_psi, discharge_psi, flushing_coupling_psi, flushing_free_psi,
    # oil_level, oil_temp, alignment_offset_mm, alignment_angle, soft_foot_mm, grease_grams

NameplateData               # T6 — de fábrica, versionado, casi inmutable
    equipment, manufacturer, model, serial_number, year,
    rated_power_kw, rated_rpm, rated_voltage_v, rated_current_a, frame_size,
    service_factor, insulation_class, ip_rating, efficiency_class,
    bearing_de (FK BearingModel), bearing_nde (FK BearingModel),
    coupling_type, lubricant (FK Lubricant), lubricant_qty, lubrication_interval_h,
    impeller_diameter_mm, stages, gear_teeth_in, gear_teeth_out, belt_count, pulley_ratio,
    source (nameplate_photo | datasheet | manual), photo → MediaAsset,
    valid_from, version
```

`BearingModel` con geometría (`balls`, `ball_diameter`, `pitch_diameter`,
`contact_angle`) es lo que convierte el sistema en una herramienta de diagnóstico
de verdad: da BPFO/BPFI/BSF/FTF, y con `rpm` de la lectura operativa se marcan
las frecuencias de falla sobre el espectro automáticamente. En las fuentes el
campo `Motor rod` está vacío pero reservado (doc 00 §3) — nadie lo llenaba porque
el Excel no hacía nada con él.

Alineamiento y lubricación (T5) son `OperatingParameter` más registros de
`MaintenanceAction`, no tablas propias: el mismo formulario sirve para "se
lubricó con 30 g de X" y "offset 0.08 mm, angular 0.03 mm/100".

## 7. Diario del equipo, hallazgos y reporte

Doc 00 §5 descubrió que antecedentes/conclusiones/recomendaciones son **líneas
fechadas**, no campos del reporte:

```python
EquipmentLogEntry
    equipment, service_visit (nullable), entry_type (background|failure_mode|finding|
    conclusion|recommendation|action_taken), entry_date, text, author,
    fault_modes M2M, severity, due_date, status (open|scheduled|done|dismissed),
    tolerance_note   ("la pata coja NO deberá exceder los 0.04 mm")

FaultMode       # catálogo, sembrado con el vocabulario de doc 00 §5
    code, name, technique, typical_signature, iso_reference
    # misalignment, mechanical_looseness, bearing_wear, soft_foot, induced_piping_stress,
    # gmf, imbalance, belt_wear, lubrication_deficiency, cavitation, electrical_fault…

Report
    service_order, equipment | asset_group, code ("AD-0007"), template,
    issued_at, inspection_date, analyst, supervisor, instrument,
    status (draft|review|issued), pdf → MediaAsset, payload jsonb (snapshot congelado)
```

El `payload` congelado importa: un reporte emitido no puede cambiar porque
alguien editó un umbral tres meses después. El PDF y su snapshot son el
documento legal frente al cliente.

Las recomendaciones con `status` y `due_date` son lo que cierra el círculo del
predictivo: en los Excel las recomendaciones se escriben y se pierden. Aquí se
siguen, y "recomendaciones abiertas por área" es un KPI.

## 8. Media (T4/T7/T8 registro fotográfico + R4)

```python
MediaAsset
    company, kind (photo|spectrum_image|thermogram|blueprint|nameplate|document|report_pdf),
    owner_type/owner_id   → visita, punto, equipo, espectro, hallazgo…
    original_key, original_format (heic|jpeg|png|dng|tiff|radiometric_jpeg),
    original_bytes, checksum_sha256 (dedupe), width, height,
    captured_at, exif jsonb, geo, camera_model,
    processing_state (pending|processing|done|failed), derivatives jsonb,
    thermal_meta jsonb    # emisividad, T reflejada, paleta, matriz radiométrica → S3
```

Detalle no obvio: una foto de termografía (T8) **no es una foto**. Un JPEG
radiométrico FLIR lleva la matriz de temperaturas embebida; si se recomprime a
AVIF se pierde y ya no se puede re‑analizar. Por eso `thermal_meta` extrae la
matriz a un fichero aparte **antes** de la conversión, y el original radiométrico
se conserva siempre (ver doc 05 §5).

## 9. Seguridad (T1)

```python
User            email, name, initials ("CT","HT"), is_active, mfa, is_external
Company
Membership      user, company, role (FK), is_default
Role            company (nullable = rol de sistema), code, name, permissions M2M
Permission      code ("vibration.add_reading"), module_code, description
ScopeRestriction  membership, scope (plant|area), refs[]
AuditLog        actor, action, object_type, object_id, before, after, ip, at
```

| rol | puede |
|---|---|
| `platform_admin` | todo, incluida instalación de módulos |
| `company_admin` | su compañía: usuarios, plantas, módulos, normas, umbrales |
| `engineer` | diagnosticar, emitir reportes, definir umbrales por equipo |
| `planner` | planes, órdenes de servicio, cronograma |
| `technician` | tomar datos, subir fotos, cerrar sus visitas |
| **`external_inspector`** | **ver el equipo; editar solo el servicio que ejecutó él** |
| `client_viewer` | solo lectura de sus plantas + reportes emitidos |

### El inspector externo

Es el rol que da forma al módulo. Las reglas viven en
`security/domain/policies.py` como predicados puros, y se prueban sin base de
datos:

| Acción | Regla |
|---|---|
| Ver equipo, plano, placa, histórico | sí, dentro de sus áreas asignadas |
| Editar el equipo (TAG, puntos, plano) | **no** — leer no implica poder reescribir la planta de otro |
| Ver visitas de otros | sí: la tendencia no sirve si se le ocultan las tomas ajenas |
| Editar una visita | solo si **es participante** y la visita sigue **abierta** |
| Lecturas, fotos, notas | misma regla de propiedad que la visita |
| Emitir reporte, cerrar recomendación, tocar umbrales | **no** — eso se queda en la oficina |
| Cualquier edición tras emitir el reporte | **no**, para nadie, ni para el ingeniero |

`ScopeRestriction` no es adorno: con 558 equipos y cuadrillas por área, dar la
planta entera a un contratista es a la vez inusable e indefendible frente al
cliente. Y un conjunto de áreas **vacío significa ninguna**, nunca "todas" — el
fallo de autorización más clásico que hay.

## 10. Informes (semáforo de planta)

```python
EquipmentStatus   equipment, area, sector, asset_group, technique, condition, availability
SummaryNode       key, label, level (area|sector|asset_group), total, evaluated,
                  coverage, worst (Status), counts[StatusCount], children[]
```

Dos reglas sostienen el módulo entero:

1. **Gana el peor.** Un área con un equipo en parada no está "casi verde": está
   roja. Promediar estados es como una planta parece sana justo hasta que algo
   se rompe.
2. **No medido no es verde.** Lo apagado, retirado o simplemente no visitado se
   cuenta aparte y tiene su propio color. En el RGP original eso era el 13 % de
   la planta; meterlo en "operativo" habría inflado todos los indicadores.

De ahí sale `coverage`: el porcentaje de equipos que realmente produjeron
veredicto. **Un área verde al 50 % de cobertura es un problema de planificación
disfrazado de buen color**, y la pantalla lo dice al lado del semáforo.

El semáforo es **uno por técnica**. La misma bomba puede estar en alarma por
vibraciones y operativa en termografía; fundirlas en un solo color borra
justamente el hallazgo por el que existe el informe.
