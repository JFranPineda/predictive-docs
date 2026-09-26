# 04 · Termografía

> **Estado (2026-09-26): implementado y verificado** (`9159df1` · `3ae5312`).
> `Reading.image` enlaza el termograma con sus lecturas; Tmáx va en su propia
> magnitud `ir_tmax` y el titular del semáforo pasa a `delta_temp`; un JPEG
> radiométrico de FLIR propone la Tmáx (solo matriz `raw16`, sin Pillow en el
> dominio). Al verificar salió un fallo del registro de valores: una fila
> vacía de otro eje pisaba el valor real en la misma celda.
>
> **Q8 y Q9 respondidas (2026-09-26).** Q8: el ΔT es un número en °C que el
> técnico escribe tal cual; el formulario ya no pide referencia. Q9: la
> escala de IPSA es una norma del módulo Normas («Escala térmica IPSA»,
> aceptable < 82 °C, alarma 82–121, **alerta** 121–148, parada ≥ 148, sobre
> Tmáx IR) con ALERTA como cuarto estado de condición. Cada informe (orden de
> servicio) elige su norma, así un cliente puede tener un informe con la
> norma A y otro con la B; cambiarla recalifica sus lecturas y queda en la
> auditoría. Las lecturas del termograma se califican con esa norma.

---

## V3-16 · Termografía: subir termogramas y llevar sus temperaturas y el ΔT mayor a la tendencia

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | M | back, front | V3-01, V3-10 |

**Origen**

> Termografía: Solo subir imágenes. Valores de temperaturas en el cuadro de
> tendencias, para ver con el cuadro los valores de tendencia. Valor delta
> mayor del elemento observado.

**Cómo lo hace hoy el cliente** (informes de IPSA, hoja TERMOGRAFÍA)

La hoja no tiene tabla de valores: son **solo imágenes**, una por elemento
observado. Cada imagen es la página de informe que exporta la cámara (FLIR E4):
termograma, foto visible, fecha y hora, escala (18,7–43,1 °C), parámetros de
cámara (emisividad 0,95, distancia 2 m, temperatura reflejada 20 °C) y la tabla
de medidas (`Sp1 37,2 °C`). Las conclusiones van en I–III como en vibraciones.
Los informes de chumaceras de la MP3 separan lado mando y lado transmisión en
dos hojas (`TERMOGRAFÍA_LM`, `TERMOGRAFÍA_LT`).

**Situación actual**

- Termografía existe como servicio con tres magnitudes por punto: `temp`
  (TEMP n), `delta_temp` (ΔT contra componente similar) y `delta_temp_ambient`
  (ΔTA). Se capturan como números en la ronda, igual que vibraciones. Su
  familia ya quedó fijada en `mpd` al implementar V3-19
  (`measurements/domain/families.py`), así que no hay nada pendiente ahí.
- Las imágenes se suben aparte, a la galería, sin relación con los números.
- **Las 20 088 lecturas de termografía de AMBEV no vienen de termogramas.**
  Todas cuelgan de visitas de vibraciones: son la temperatura de rodamiento que
  toma el colector en la ronda (las plantillas dicen `vel_rms, env_accel,
  temp`). No hay ninguna orden ni visita de termografía. La magnitud `temp`
  pertenece a la técnica termografía, y por eso el semáforo de termografía
  muestra datos.
- `modules/media/domain/flir.py` sabe leer la matriz radiométrica de un JPEG
  de FLIR (`extract()`, `temperature_at()`), pero **las páginas de informe que
  exporta la E4 son PNG**, sin datos radiométricos: de ellas no se puede leer
  la temperatura.
- **Ya existe el precedente exacto que este ticket necesita**: `Spectrum`
  (`measurements/infrastructure/models.py:141-186`) enlaza una imagen
  (`image`, FK a `MediaAsset`) con un punto (`point`), una visita
  (`service_visit`) y, opcionalmente, una lectura (`reading`, FK a `Reading`,
  `related_name="spectra"`). Es la misma forma que un termograma necesita:
  imagen + punto + visita + valor. No hace falta inventar cómo relacionar una
  imagen con una lectura, ni resolver cómo un `MediaAsset` sería a la vez de
  la visita y del punto (hoy solo tiene **un** propietario, `owner_type` +
  `owner_id`: `media/infrastructure/models.py:30-31`) — la captura de
  espectros de V3-15 ya lo resolvió subiendo la imagen con
  `owner_type="point"` (`media/infrastructure/uploads.py:98-102`,
  `measurements/interfaces/spectrum_views.py`, función `_store_capture`) y
  dejando que la visita se sepa por el propio `Reading.service_visit`
  (`measurements/infrastructure/models.py:100-102`), no por el `MediaAsset`.
- El otro precedente útil es `Magnitude.template_only`
  (`measurements/infrastructure/models.py:51`, dominio en
  `measurements/domain/point_magnitudes.py`): una magnitud opcional que solo
  se siembra y se ofrece en los puntos cuya plantilla la pide (usado hoy por
  `accel_rms`, V3-11). No aplica igual aquí — un termograma no se siembra por
  punto al abrir la visita, se crea al subir la imagen — pero es la referencia
  de cómo el sistema ya distingue "esta magnitud no está en todas partes" sin
  romper el resto de la ronda.

**Qué hacer**

- Front, captura de termografía: la unidad de trabajo es la **imagen**, no la
  casilla. Por cada termograma: subir la imagen, elegir el punto o elemento
  observado, y escribir **Tmáx del elemento** y **T de referencia**; el ΔT se
  calcula. Opcional: comentario por imagen.
- Back, enlace imagen ↔ lectura: **añadir `Reading.image`** (FK a
  `MediaAsset`, `null=True`, `blank=True`, `on_delete=SET_NULL`), en vez de
  crear un modelo `Thermogram` aparte. Es más simple que `Spectrum` porque no
  hay curva que guardar — solo Tmáx y ΔT, que ya son campos de `Reading`
  (`value`) y de una segunda lectura (`delta_temp`). El punto y la visita ya
  están en `Reading` (`point`, `service_visit`); no hace falta duplicarlos en
  el `MediaAsset`.
- Back, subida: la imagen se sube como hace `_store_capture` en
  `spectrum_views.py` — `owner_type="point"`, `owner_id=<point.id>`, mismo
  `store_upload()` de `media/infrastructure/uploads.py` — y el kind es
  `thermogram` (ya existe en `MediaAsset.KINDS`,
  `media/infrastructure/models.py:12`). Al guardar, se crean o actualizan las
  `Reading` de `temp` y `delta_temp` de ese punto y visita, con `image_id`
  apuntando a la imagen. Se reutiliza la captura por lotes con
  `Idempotency-Key`, igual que el resto de la ronda.
- Back, magnitudes: revisar si Tmáx del termograma necesita una magnitud
  **propia** (`ir_tmax`, °C) en vez de reutilizar `temp` — contacto e
  infrarrojo miden cosas distintas (el rodamiento por dentro de la carcasa
  contra la superficie que ve la cámara) y mezclarlos en una serie produce
  saltos que no son del equipo. El ΔT sigue en `delta_temp`. Revisar también a
  qué técnica pertenece `temp` hoy: si de verdad es la del colector de
  vibraciones (ver más arriba, "las 20 088 lecturas… no vienen de
  termogramas"), debería contar en vibraciones, y `ir_tmax` quedaría como la
  única magnitud de temperatura propia de termografía.
- Si la imagen es un JPEG radiométrico, proponer Tmáx leyendo la matriz con
  `flir.py` (`extract()` + `temperature_at()`); el técnico puede corregirla.
  Con un PNG, se escribe a mano.
- Registro de valores: las filas de termografía muestran Tmáx y ΔT por fecha,
  y al pasar por una celda se ve la miniatura del termograma que la produjo —
  el patrón ya existe para el registro (`RecordOfValuesPage.tsx`) y para el
  panel de detalle de una imagen (`MediaDetailModal.tsx`, usado por V3-02 y
  V3-15); aquí es la misma miniatura, colgada de `cell.image_url` en vez de
  abrir un modal aparte.
- "Valor delta mayor": el titular del conjunto en el semáforo de termografía
  es el **mayor ΔT** entre sus elementos observados en la última ronda.

**Criterios de aceptación**

- **AC-01** Dada una visita de termografía, cuando el técnico sube un termograma,
  elige "Punto 3 · REDUCTOR" y escribe Tmáx 72 °C y referencia 38 °C,
  entonces se guardan Tmáx 72 °C (`ir_tmax`) y ΔT 34 °C, y salen en el registro
  de valores en filas distintas de la temperatura del colector.
- **AC-02** Dada esa lectura en el registro, cuando se pasa el ratón por la
  celda, entonces se ve el termograma.
- **AC-03** Dado un JPEG radiométrico de FLIR, cuando se sube, entonces Tmáx
  viene propuesta y se puede editar.
- **AC-04** Dados tres elementos con ΔT 4, 12 y 7 °C, cuando se abre el
  semáforo de termografía, entonces el conjunto muestra 12 °C.
- **AC-05** Dada una imagen subida sin valores, cuando se guarda, entonces el
  punto queda como "no medido" con motivo, no como cero.

**Preguntas abiertas**

- Q8: ¿ΔT contra qué: componente similar, ambiente, o el mínimo de la misma
  imagen?
- Q9: la hoja de conclusiones de IPSA usa una escala térmica de **cuatro**
  niveles: aceptable 0–82 °C, alarma 82–121, **alerta** 121–148, parada
  148–300. Hoy los estados de condición son tres (operativo, alarma, parada).
  Los perfiles de estado por técnica (`thresholds_techniquestatusprofile`)
  admiten opciones propias, así que "alerta" cabe sin tocar el modelo; hay que
  confirmar que el cliente la quiere y en qué orden va ("alerta" es **peor**
  que "alarma" en esa tabla, al revés de lo habitual).
- Q10 (nueva): si un termograma **sin** valores se sube (AC-05: "no medido con
  motivo, no como cero"), ¿la fila `temp`/`delta_temp` se crea igual, vacía y
  ligada a la imagen, o solo se crea al escribir Tmáx? La ronda de vibraciones
  siembra sus filas al abrir la visita (`_seed_readings`,
  `point_plan.magnitude_plan`); termografía, al no tener una plantilla de
  puntos fija por elemento observado, probablemente no puede sembrar así, y la
  fila nacería con la imagen. Confirmar con el flujo real de campo antes de
  implementar.
