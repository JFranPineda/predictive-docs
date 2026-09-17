# 00 — Análisis de las fuentes (qué dicen realmente los Excel)

Revisión de los 6 ficheros de `predictive-docs/`. Todo lo que sigue está extraído
del contenido real, no supuesto. Las fechas de los Excel están en serial 1900 y
aquí van ya convertidas.

| Fichero | Hojas | Qué es |
|---|---|---|
| `111.ETEI - Soplador # 01..xls` | `PARA BOMBAS` (56×11) | Plantilla de **reporte de inspección predictiva** (análisis vibracional) de un equipo. Lleva imágenes embebidas (1 PNG, 2 JPEG). |
| `MPd-AV-N°006-13-EB P-757 - C.E.C.1.xls` | `EB P-757` (105×10) | El **mismo reporte, versión completa**: vibración + ultrasonido + temperatura, con secciones de tendencias y espectros (3 PNG, 2 JPEG embebidos). |
| `TABLA DE TENDENCIAS.xls` | `EB 228` (62×20), `CONDICIÓN` (13×15) | **Histórico por equipo**: 13 tomas entre 2013‑02‑08 y 2013‑12‑16, una columna por fecha. Es la matriz de tendencia. |
| `VIBRACION 2014 AMBEV.xls` | `Table 1` (1086×6) | **Maestro de equipos (RGP)** — 558 equipos, 2014‑03‑25. Sin resultados. |
| `VIBRACION 2014 AMBEV - JUNIO.xls` | `Table 1` (1086×8) | Mismo maestro, 462 equipos, 2014‑05‑13, **con estado + conclusiones + recomendaciones** por equipo. Es el "Relato General de Planta". |
| `2CRONOGRAMA SERVICIOS AMBEV HUACHIPA MPd 2014.xlsx` | `Hoja1` (56×16) | **Cronograma anual de servicios** por tipo de análisis, cantidad de puntos y días‑hombre por mes. |

---

## 1. La jerarquía real de activos

El RGP (`VIBRACION 2014 AMBEV - JUNIO.xls`) la define en 4 niveles + TAG:

```
Área                 Sector                    Conjunto Rotativo         Equipo (componente)
101 - ETA            KIT BOMBAS AGUA CRUDA     BBA. AGUA CRUDA - TAG:A   MOTOR  - TAG:MB101001A
                                                                         BOMBA  - TAG:B101001A
131A - VAPOR         CALDERA 1 ATA             SOPLADOR PRIMARIO         MOTOR  - TAG:MSP131001
561S - SOPLADORA...  ELEVADOR DE PREFORMAS     ACION. PRINCIPAL          MOTOR  - TAG:MR561S002
                                                                         REDUCTOR - TAG:R561S002
```

Hechos que salen de los datos:

- **El área tiene código y nombre** en el mismo string (`"501 - PACKAGING CERVEZA"`). 24 áreas distintas en la planta Huachipa.
- **El "Conjunto Rotativo" es el tren de máquina**, no el equipo. Es la unidad que
  se alinea y se reporta junta (motor+bomba, motor+compresor, motor+reductor).
  El reporte de `EB P-757` confirma que los límites y las conclusiones se dan
  **al conjunto**, no al componente suelto.
- **El Equipo/componente es lo que lleva TAG** y lo que tiene estado propio.
  Tipos observados: `MOTOR`, `BOMBA`, `COMPRESOR`, `REDUCTOR`, `VENTILADOR`,
  `SOPLADOR`, `CHUMACERA`. El prefijo del TAG codifica el tipo
  (`M…`=motor, `B…`=bomba, `C…`=compresor, `R…`=reductor, `MSP…`=motor soplador).
- Un mismo equipo aparece con **dos TAG distintos** en el histórico de `EB 228`
  (`TAG MOTOR` y `TAG BOMBA` con el mismo valor `MB1141001B`) → el TAG del
  cliente no es fiable como clave única. **La clave es (planta, tag, tipo)**, y
  el sistema debe tolerar TAG duplicados con un `asset_code` interno.

> Consecuencia de diseño: la jerarquía es de **5 niveles**
> `Cliente → Planta → Área → Sector → Conjunto → Equipo → Punto`, y no de 2
> ("áreas" y "equipos") como pide literalmente T9/T10. Modelarla con 2 niveles
> obliga a rehacerla en la primera planta real.

## 2. Los puntos de medición

Dos nomenclaturas conviven en las fuentes y hay que soportar las dos:

| Notación | Dónde | Significa |
|---|---|---|
| `1H`, `1V`, `1A` | `TABLA DE TENDENCIAS` | punto 1, eje Horizontal / Vertical / Axial |
| `1H gE` | `TABLA DE TENDENCIAS` | punto 1 H, magnitud Envolvente de aceleración |
| `HV`, `VV`, `AV` | reportes `EB P-757`, Soplador | Velocidad Horizontal / Vertical / Axial |
| `EE` | reportes | Envolvente de aceleración (Gs) |
| `T°` | reportes | Temperatura del punto (°C) |

La numeración es **posicional dentro del conjunto**, no del equipo:

```
Punto 1 → MOTOR lado libre        Punto 3 → BOMBA lado acople
Punto 2 → MOTOR lado acople       Punto 4 → BOMBA lado opuesto a acople
```

`TABLA DE TENDENCIAS` lo dice explícito (`LADO LIBRE`, `LADO ACOPLE`,
`LADO OPUESTO A ACOPLE`). Es decir: **un punto = (conjunto, nº, componente,
posición/lado, eje)** y sobre ese punto se cuelgan N magnitudes.

Magnitudes medidas por punto, con su unidad (todas aparecen en los ficheros):

| Magnitud | Unidad | Técnica |
|---|---|---|
| Velocidad vibracional RMS | `mm/seg. – RMS` | vibración |
| Envolvente de aceleración | `Gs` / `gE` (pico y pico‑pico, ojo) | vibración |
| Temperatura | `°C` | termografía / contacto |
| Ultrasonido | `dB` | ultrasonido |

⚠️ Trampa detectada: el Soplador declara la envolvente en **`Gs Pico`** y
`EB P-757` en **`Gs P-P`**. Mismo símbolo, escala distinta (factor 2). La unidad
tiene que guardarse **con el valor**, no en la cabecera del reporte.

## 3. Datos operativos vs. datos nominales

Los ficheros los mezclan; el sistema debe separarlos (T5 vs T6).

**Operativos, tomados en cada servicio** (`TABLA DE TENDENCIAS`, filas 16‑23 y 57‑61,
y reportes filas 45‑47 / 60‑62):

`VELOCIDAD (rpm)`, `AMPERAJE (A)`, `VOLTAJE (V)`, `POTENCIA (kW)`,
`FACT. POT (cosφ)`, `FRECUENCIA (Hz)`, `HORAS ACUMULADAS`,
`PRESIÓN DE SUCCIÓN (PSI)`, `PRESIÓN DE DESCARGA (PSI)`,
`PRESIÓN FLUSHING lado acople / lado libre (PSI)`, `LECTURAS TOMADAS POR` (iniciales del técnico).

**Nominales de fábrica** (`TABLA DE TENDENCIAS`, bloque M5:S10):

`Motor marca` (SIEMENS), `Motor S/N`, `Motor rod` (modelo de rodamiento),
`Bomba`, `Bomba S/N`, `Bomba rod`.

> El campo **`rod` (rodamiento) está vacío en la fuente pero reservado**. Es el
> dato más valioso del bloque: con el modelo de rodamiento y las rpm se calculan
> BPFO/BPFI/BSF/FTF y el diagnóstico de espectro deja de ser artesanal. El
> módulo de datos nominales debe llevar catálogo de rodamientos con geometría.

Nótese que `HORAS ACUMULADAS` crece monótono (28 102 → 33 774 en 13 tomas) →
sirve para mantenimiento por horas y para normalizar tendencias.

## 4. Estados y umbrales — el corazón de T12

Estados realmente usados en el RGP (frecuencia de aparición):

| Estado | Nº | Qué significa |
|---|---|---|
| `NORMAL` | 147 | dentro de límites |
| `APAGADO` | 62 | no se pudo medir, equipo sin marcha |
| `PARADA` | 45 | supera el límite de parada |
| `ALARMA` | 19 | zona intermedia |
| `Equipo Retirado` / `RETIRADO` | 5 | ya no existe en planta |
| `Equipo Fuera de Servicio` | 2 | existe, no operativo |

Dos familias distintas metidas en un solo campo:
**estados de condición** (NORMAL/ALARMA/PARADA, derivados del valor medido) y
**estados de disponibilidad** (APAGADO/RETIRADO/FUERA DE SERVICIO, que explican
por qué *no hay* medición). El sistema debe separarlas: la primera se **calcula**,
la segunda se **declara**. Mezclarlas es lo que hace que el 13 % de los equipos
del RGP aparezcan "APAGADO" y contaminen cualquier KPI de salud de planta.

Umbrales encontrados, todos con la forma `normal < alarma ≤ parada`:

| Norma / origen | Magnitud | Normal | Alarma | Parada |
|---|---|---|---|---|
| ISO 10816‑3, motores eléctricos | velocidad mm/s RMS | < 4.5 | 4.5 – 7.1 | > 7.1 |
| Technical Associates of Charlotte, bombas | velocidad mm/s RMS | < 5.4 | 5.4 – 8.1 | > 8.1 |
| Genérico envolvente | envolvente Gs pico | < 2.5 | — | > 4.0 |
| **Historial del equipo** EB P‑757 | velocidad mm/s RMS | < 4.5 | 4.5 – 7.1 | > 7.1 |
| **Historial del equipo** EB P‑757 | envolvente Gs P‑P | < 9.0 | 9.0 – 15.0 | > 15.0 |
| **EB 228 (MOTOR CLASE III)** | velocidad mm/s RMS | < 4.5 | 4.5 – 6.5 | > 6.5 |

Esto valida exactamente T12: hay un **catálogo global de normas** (ISO 10816‑3,
Technical Associates) y **overrides por equipo** ("de acuerdo a historial del
equipo"). En `EB 228` el override es más estricto que la ISO (6.5 vs 7.1) →
el override no es un relajamiento, es ingeniería, y debe versionarse con fecha
y autor.

## 5. Anatomía del reporte (lo que el sistema tiene que poder emitir)

`MPd-AV-N°006-13-EB P-757` es la versión canónica. Secciones, en orden:

```
Cabecera   Cliente · Locación/Base · Área · Equipo · TAG · Componente · H.O. aprox ·
           Estado · OT · Fecha inspección · Fecha reporte · Inspector analista ·
           Supervisor · Equipo utilizado (instrumento) · Reporte Nº
           + bloque lateral "PUNTOS DE INSPECCIÓN"   ← aquí va el PLANO (T3)
I.    ANTECEDENTES            (líneas fechadas)
II.   MODO DE FALLA / ESTADO ACTUAL   (líneas fechadas)
III.  CONCLUSIONES            (líneas fechadas)
IV.   RECOMENDACIONES         (líneas fechadas)
V.    REGISTRO DE VALORES     (matriz punto × fecha, con fila de estado por fecha)
VI.   LÍMITES DE VIBRACIÓN    (las normas aplicadas, con su origen)
VII.  TENDENCIAS              (gráfico)
VIII. ESPECTROS               (imágenes + pie explicativo:
                               "En modo Velocidad Pto 3HV, mostrando desalineamiento
                                y Soltura mecánica")
```

Tres cosas importantes:

1. **El bloque "PUNTOS DE INSPECCIÓN" de la cabecera es T3.** No es texto: es el
   plano del equipo con los puntos numerados encima. El reporte ya lo trata como
   parte fija de la ficha.
2. **Antecedentes/Conclusiones/Recomendaciones son líneas con fecha**, no un
   campo de texto libre. En `EB P-757` hay antecedentes de 2013‑11‑16 junto a
   conclusiones de 2013‑12‑17 en el mismo reporte → son un **diario del equipo**
   filtrado por fecha, no un campo del reporte. Modelarlo como texto largo
   destruye el histórico.
3. **El pie del espectro contiene el diagnóstico** ("GMF en Bomba", "falla
   incipiente de rodamiento"). Es el dato de entrenamiento más directo que hay
   para el futuro modelo de visión: imagen de espectro ↔ etiqueta de falla.

### Vocabulario de fallas presente en las fuentes

Del RGP y de los reportes, ya normalizable a catálogo:
desalineamiento (motor‑bomba, polea motriz‑conducida), soltura mecánica,
desgaste de rodamientos (incipiente / avanzado), pata coja, tensiones inducidas
(en bomba, por SKID), GMF (frecuencia de engrane), falta de lubricación,
juego radial en acople, liqueo por o‑ring, fajas de transmisión en mal estado.

Y el de recomendaciones: alinear con láser, lainar/nivelar skid, cambiar
rodamientos, lubricar, mejorar anclaje, reemplazar fajas/poleas, reprogramar
monitoreo. Con tolerancia numérica explícita en un caso: *"la pata coja NO deberá
exceder los 0.04 mm"*.

## 6. Planificación de servicios (T11)

`TABLA DE TENDENCIAS` da la periodicidad real de un equipo crítico: 13 tomas en
11 meses, intervalos de 15 a 75 días. Es decir: **la frecuencia programada se
incumple**, y el sistema debe medir desvío (programado vs ejecutado), no asumirlo.

El RGP asigna frecuencia por equipo: `Mensual` 280, `Trimestral` 182,
`Bimestral` 96 (558 equipos). El cronograma 2014 lo agrega por tipo de servicio:

| Servicio | Tomas/año | Días‑hombre/año | Ritmo |
|---|---|---|---|
| Análisis Vibracional | 3 130 | 114 | mensual 90 + bimestral 171 + trimestral 256 |
| Análisis de Aceite | 804 | 14 | bimestral 100 + trimestral 51 |
| Análisis Termográfico | 542 | 4 | semestral 271 |
| Análisis Aceite Aislante | 11 | 1 | anual |

Las columnas del cronograma son ciclos de **30/60/90/120/150/180 días**, no meses
naturales. La planificación es por *ciclo de equipo*, y el mes es solo la
proyección. Aparece un cuarto servicio no pedido en T1‑T12: **análisis de aceite**
(lubricante y dieléctrico), que es el 26 % del volumen anual. Conviene que el
modelo de "técnica de análisis" sea extensible desde el día 1.

## 7. Volumetría (dimensiona el sistema)

- 558 equipos · ~4 puntos/equipo · ~5 magnitudes = **~11 000 valores por ronda completa**.
- 3 130 tomas vibracionales/año en **una sola planta** → ~60 000 valores/año.
- Con espectro guardado por punto crítico: 1 espectro ≈ 1 600–6 400 líneas → del orden de
  **10⁷ muestras/año/planta**. Esto no cabe cómodo en tablas normales a 5 años: hay que
  decidir almacenamiento de series desde el principio.
- Fotos: registro fotográfico por punto y servicio. A 4 fotos/equipo/ronda en una
  planta de 558 equipos son ~2 200 fotos por ronda; en HEIC de móvil (3–5 MB) son
  **~9 GB por ronda**, ~100 GB/año/planta. Esto es lo que justifica R4 entero.

## 8. Lo que las fuentes NO dicen (decisiones que hay que tomar)

1. **Multi‑cliente**: hay dos clientes distintos (AMBEV Huachipa; Trompeteros /
   Lote 8 con OT de JD Edwards). No hay ningún dato de aislamiento entre ellos.
   → se decide multi‑tenant por `Company` desde el inicio.
2. **Identidad de usuario**: solo iniciales (`CT`, `WG`, `HT`, `JA`) y nombres
   sueltos (Carlos Balta, Henry Tejada). No hay roles. → T1 se diseña desde cero.
3. **Integración ERP**: el reporte lleva `OT` y menciona JD Edwards y matrícula
   de activos. → se reserva un módulo de integración, no se implementa aún.
4. **Espectros crudos**: no hay ni un fichero de espectro, solo capturas de
   pantalla del instrumento. → el sistema debe aceptar **ambas**: imagen de
   espectro (lo que hay hoy) y espectro numérico (lo que hará falta para IA).
5. **Instrumentos**: `DSP LOGGER MX300 – SEMAPI` y `Microlog GX 75` (SKF).
   Cada uno con su formato de exportación. → adaptadores de importación por
   instrumento, detrás de un puerto común.
