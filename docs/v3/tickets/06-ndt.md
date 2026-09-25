# 06 · END y familias de servicio

El cliente separa su oferta en dos familias: **MPd Predictivo** (monitoreo de
condición) y **END**, ensayos no destructivos. Hoy el sistema los tiene todos al
mismo nivel y solo uno de END (espesores UT).

Recordatorio de `SUMMARY.md` §3.17: **ultrasonido aéreo (dB) ≠ UT convencional
(mm)**. El aéreo busca fricción y fugas y es MPd; el convencional es un END con
palpador de contacto. En las notas del cliente, "Ultrasonido" dentro de END es
el convencional, y "Ultrasonido a motor / a chumaceras (formato actual del
sistema)" es el aéreo.

---

## V3-19 · Separar los servicios en dos familias: MPd Predictivo y END

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P2 | M | back, front | — |

**Origen**

> Ver tendencia: Separar: 1. Ensayos no destructivos: Tintes, partículas,
> ultrasonido. 2. Mpd Predictivo: Alineamiento (…), Topografía (…).

**Situación actual**

`measurements_technique` tiene nueve técnicas en una lista plana: vibraciones,
ultrasonido (aéreo), termografía, análisis de aceite, aceite dieléctrico,
mantenimiento, lubricación, alineamiento y "END · Espesores UT". Mantenimiento
y lubricación vienen del RGP del cliente y no son servicios de medición.

**Qué hacer**

- Back: campo `family` en `Technique` con tres valores: `mpd`, `ndt` y
  `internal` (mantenimiento, lubricación: no se ofrecen como servicio).
  Migración de datos:
  - `mpd`: vibraciones, ultrasonido aéreo, termografía, análisis de aceite,
    aceite dieléctrico, alineamiento, topografía (V3-18).
  - `ndt`: END · Espesores UT, tintes penetrantes y partículas magnéticas
    (V3-20), UT en rodillos (V3-21).
- Back: `techniques/` devuelve `family` y admite `?family=`.
- Front: el selector de servicio en Mediciones, el de Órdenes y las pestañas
  del semáforo agrupan en **MPd Predictivo** y **END**. Las técnicas
  `internal` no se ofrecen para crear órdenes.

**Criterios de aceptación**

- **AC-01** Dado `/measurements`, cuando se abre el selector de servicio,
  entonces aparecen dos grupos con sus técnicas, y mantenimiento y lubricación
  no están.
- **AC-02** Dada "Nueva orden", cuando se abre la lista de técnicas, entonces
  está agrupada en MPd Predictivo y END.
- **AC-03** Dado el semáforo, cuando se abre, entonces las pestañas de END
  quedan separadas de las de MPd.

---

## V3-20 · Tintes penetrantes y partículas magnéticas: fotos y conclusiones

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | M | back, front | V3-01, V3-19 |

**Origen**

> Ensayos no destructivos: Tintes y partículas: Solo subir fotos y
> conclusiones.

**Qué hacer**

- Datos: técnicas `ndt_penetrant` (Tintes penetrantes) y `ndt_magnetic`
  (Partículas magnéticas), familia `ndt`, **sin magnitudes**.
- Back: marca `evidence_only` en `Technique`. Una visita de una técnica así no
  pide lecturas: se cierra con al menos una foto y una conclusión. Las
  conclusiones usan el diario del equipo que ya existe (líneas fechadas con
  autor).
- Front: la visita de estas técnicas muestra solo galería (con comentario por
  foto) y el diario; la captura de ronda no se ofrece.
- Semáforo: estas técnicas no tienen color. Cuentan para cobertura
  ("inspeccionado / no inspeccionado en la última orden").

**Criterios de aceptación**

- **AC-01** Dada una visita de tintes penetrantes sin fotos, cuando se intenta
  cerrar, entonces el sistema pide al menos una foto.
- **AC-02** Dada una visita con fotos y sin conclusión, cuando se intenta
  cerrar, entonces el sistema pide la conclusión.
- **AC-03** Dada una visita de partículas magnéticas, cuando se abre, entonces
  no aparece ninguna tabla de lecturas ni el botón "Capturar la ronda completa".

**Pregunta abierta**: ¿el resultado lleva un veredicto (con o sin
indicaciones; o la escala ACEPTABLE / MEDIO / CRÍTICO de UT)? Supuesto: no; la
conclusión es texto.

---

## V3-21 · Ultrasonido en rodillos: 6 puntos por rodillo, fotos comentadas y conclusiones

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | L | back, front | V3-19; es el pendiente "Polín como activo" de `SUMMARY.md` §6 |

**Origen**

> Ultrasonido: Rodillos: 6 puntos de medidas.
> Ultrasonido: observaciones, fotos (comentarios por foto) y conclusiones.
> Medidas de 6 puntos según formato.

**El formato** (`docs/v2/ORDEN_14778(1).xlsx`, hoja SECADORES)

Una fila por polín: grupo (1er grupo…), número de polín, espesores **P1–P6**
en mm (medidos con Krautkramer), observación y estado **ACEPTABLE / MEDIO /
INACCESIBLE / CRÍTICO**, con un resumen de cuántos polines hay en cada estado
(65 / 14 / 0 / 0). La hoja auxiliar añade el diámetro con calibrador en tres
puntos, contra un nominal de 219,1 mm. El informe Word de la misma carpeta
suma las incidencias (fisura, socavación, con longitud y profundidad).

**Situación actual**

- Existe la técnica "END · Espesores UT" con la magnitud `thickness_mm`
  (ESP n, `higher_is_worse=False`, titular = mínimo). Hay 948 lecturas
  **sintéticas** sembradas en AMBEV, en el rango real (8–12 mm).
- No hay polín como activo: los espesores cuelgan de puntos de equipos
  cualquiera. Tampoco hay incidencias ni el vocabulario de cuatro estados.

**Qué hacer**

- Back, activo: tipo de equipo `roller` (rodillo/polín) con diámetro nominal,
  longitud exterior y total; agrupado en su conjunto (el grupo de secadores).
  Tipo de conjunto "Rodillos" con plantilla de 6 puntos (P1–P6) de
  `thickness_mm`.
- Back, veredicto: el estado del rodillo usa un perfil de estados propio de la
  técnica (ACEPTABLE, MEDIO, INACCESIBLE, CRÍTICO) sobre el **mínimo** de sus
  seis espesores. INACCESIBLE es "no medido" con ese motivo, no un valor.
- Back, incidencias: `UTIndication` por rodillo (tipo fisura / socavación,
  longitud, profundidad, posición, foto).
- Front, captura: tabla con una fila por rodillo y las seis casillas, más
  observación; fotos con comentario por foto; conclusiones en el diario.
- Front, resumen: conteo por estado, como la tabla de la orden.
- Diámetro con calibrador y desgaste contra nominal: fuera de este ticket
  salvo que el cliente lo pida (va en la hoja auxiliar, no en la principal).

**Criterios de aceptación**

- **AC-01** Dado el polín 11 del 1er grupo con espesores 9,23 · 8,52 · 8,33 ·
  8,65 · 7,99 · 10,47, cuando se guarda, entonces el titular es 7,99 mm.
- **AC-02** Dados los umbrales que reproducen la orden 14778, cuando se
  capturan sus 79 polines, entonces el resumen da 65 ACEPTABLE y 14 MEDIO.
- **AC-03** Dado un polín que no se pudo medir, cuando se marca INACCESIBLE,
  entonces no genera valores y cuenta en su casilla del resumen.
- **AC-04** Dada una fisura registrada con longitud y profundidad, cuando se
  abre el rodillo, entonces la incidencia aparece con su foto.

**Pregunta abierta**: Q15 (que "6 puntos según formato" son los P1–P6 de la
orden 14778). Y los umbrales de MEDIO y CRÍTICO: la orden solo trae el
veredicto, no la regla. Hay que pedirla o inferirla de los datos y validarla con
el cliente.

---

## V3-22 · Ultrasonido aéreo: modos de falla *fluting* (motor) y rascado (chumacera)

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P3 | S | datos | — |

**Origen**

> Ultrasonido a motor (formato actual del sistema). Deficiencia por flutting:
> corrientes parásitas que pasan por el rodamiento y lo pican.
> Ultrasonido a chumaceras: para ver el rascado (formato actual del sistema).

**Situación actual**

El formato se queda como está. Ultrasonido tiene 12 modos de falla; el más
cercano es `bearing_friction`. No existe *fluting* (erosión eléctrica del
rodamiento).

**Qué hacer**

- Datos: modo de falla `electrical_fluting` — "Fluting (erosión eléctrica del
  rodamiento)", técnica ultrasonido, con su firma típica.
- Datos: renombrar o describir `bearing_friction` para que el analista lo
  reconozca como "rascado / roce en chumacera", o crear `bearing_scraping` si
  el cliente los distingue.
- Añadirlos a `seed_demo` y a la migración de datos del inquilino.

**Criterios de aceptación**

- **AC-01** Dada una visita de ultrasonido a un motor, cuando se abre "Problemas
  a identificar", entonces aparece "Fluting".
- **AC-02** Dado ese modo de falla, cuando se intenta asignar a una visita de
  vibraciones, entonces el servidor lo rechaza (regla actual: un modo de falla
  pertenece a su técnica).

---

## V3-23 · Informes MPd e Informes END

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | L | back, front | V3-19; es el pendiente "Reporte en PDF" de `SUMMARY.md` §6 |

**Origen**

> Servicios: Informes MPD. Informes END (ensayos no destructivos).

**Situación actual**

El módulo `reports` del back está vacío. El entregable de referencia es
`MPd-AV-N°006-13-EB P-757 - C.E.C.1.xls` (AMBEV) y, ahora, los 47 informes de
IPSA: cabecera con datos del equipo, esquema y foto, I. Antecedentes,
II. Estado actual, III. Recomendaciones, IV. Registro de valores,
V. Límites, VI. Tendencias, y hojas de espectros y termogramas.

**Qué hacer**

- Dos familias de informe con plantilla propia:
  - **Informe MPd**, por conjunto y orden: la estructura I–VI de los
    informes de IPSA, más espectros (V3-15), termogramas (V3-16) y, si aplica,
    alineamiento (V3-17).
  - **Informe END**, por orden: tabla de elementos con su estado (V3-21),
    fotos comentadas y conclusiones (V3-20).
- Un resumen mensual por planta como `EQUIPOS - CONCLUSIONES.xlsx` de IPSA:
  una fila por conjunto con estado de termografía, estado de vibraciones,
  conclusión y recomendación, más el conteo por estado (el "Pareto").
- Salida PDF y Excel. El PDF lleva el logo de 1A-MIG (V3-33).
- Pantalla "Informes" con dos pestañas: MPd y END.

**Criterios de aceptación**

- **AC-01** Dada una orden de vibraciones cerrada, cuando se genera el informe
  MPd de un conjunto, entonces contiene las secciones I a VI con los datos de
  esa orden.
- **AC-02** Dada una orden de UT en rodillos, cuando se genera el informe END,
  entonces lista los rodillos con su estado y el resumen por estado.
- **AC-03** Dado el mes de septiembre de una planta, cuando se genera el
  resumen, entonces tiene una fila por conjunto y el conteo NORMAL / ALARMA /
  PARADA / APAGADO de cada técnica.

**Nota**: es el ticket más grande de v3. Conviene partirlo cuando se empiece:
primero el informe MPd de un conjunto, después el resumen mensual, después END.
