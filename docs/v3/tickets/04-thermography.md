# 04 · Termografía

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
  (ΔTA). Se capturan como números en la ronda, igual que vibraciones.
- Las imágenes se suben aparte, a la galería, sin relación con los números.
- **Las 20 088 lecturas de termografía de AMBEV no vienen de termogramas.**
  Todas cuelgan de visitas de vibraciones: son la temperatura de rodamiento que
  toma el colector en la ronda (las plantillas dicen `vel_rms, env_accel,
  temp`). No hay ninguna orden ni visita de termografía. La magnitud `temp`
  pertenece a la técnica termografía, y por eso el semáforo de termografía
  muestra datos.
- `modules/media/domain/flir.py` sabe leer la matriz radiométrica de un JPEG
  de FLIR, pero **las páginas de informe que exporta la E4 son PNG**, sin datos
  radiométricos: de ellas no se puede leer la temperatura.

**Qué hacer**

- Front, captura de termografía: la unidad de trabajo es la **imagen**, no la
  casilla. Por cada termograma: subir la imagen, elegir el punto o elemento
  observado, y escribir **Tmáx del elemento** y **T de referencia**; el ΔT se
  calcula. Opcional: comentario por imagen.
- Back: al guardar, cada imagen crea sus lecturas enlazadas a la imagen, y la
  imagen queda enlazada a la visita y al punto. Se reutiliza la captura por
  lotes con `Idempotency-Key`.
- Back, magnitudes: Tmáx del termograma va a una magnitud **propia**
  (`ir_tmax`, °C) y no a `temp`. Contacto e infrarrojo miden cosas distintas
  (el rodamiento por dentro de la carcasa contra la superficie que ve la
  cámara); mezclarlos en una serie produce saltos que no son del equipo. El
  ΔT sigue en `delta_temp`. Revisar a qué técnica pertenece `temp`: si es la
  del colector de vibraciones, debería contar en vibraciones.
- Si la imagen es un JPEG radiométrico, proponer Tmáx leyendo la matriz con
  `flir.py`; el técnico puede corregirla. Con un PNG, se escribe a mano.
- Registro de valores: las filas de termografía muestran Tmáx y ΔT por fecha,
  y al pasar por una celda se ve la miniatura del termograma que la produjo.
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
