# 05 · Alineamiento y topografía (MPd Predictivo)

Dos servicios que el cliente vende y el sistema todavía no sabe registrar. Los
dos entran en la familia **MPd Predictivo** de V3-19.

---

## V3-17 · Servicio de Alineamiento con el formato SKF (antes / después)

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | L | back, front | V3-01, V3-19 |

**Origen**

> Mediciones > Alineamiento: Equipos que se alinearon en el mes e imágenes pre
> y post alineamiento.
>
> Mpd Predictivo — Alineamiento (foto de SKF). Fotos: antes (4 medidas) y
> después (4 medidas). Valores (pre y post): paralelo horizontal, angular
> horizontal, paralelo vertical, angular vertical. Foto representativa del
> alineamiento: solo 3 fotos. 1 del conjunto y 2 de observaciones. Notas por
> foto.

Captura 6 del Word, el informe "Alignment Results" de SKF:

| | As Found (antes) | As Corrected (después) |
|---|---|---|
| Horizontal (vista superior) · angular | 1,00 mm/100 mm ✗ | −0,06 mm/100 mm ✓ |
| Horizontal · paralelo (offset) | 1,03 mm ✗ | −0,03 mm ✓ |
| Vertical (vista lateral) · angular | −0,01 mm/100 mm ✓ | 0,00 mm/100 mm ✓ |
| Vertical · paralelo | 0,28 mm ✗ | 0,05 mm ✓ |

Pie: "Backlash within tolerance: Yes", firma, fecha, "1A-MIG, LIMA - PERÚ".

Captura 5 del Word: "Editar orden" sobre `MPd-US-N°004-26` (una orden de
ultrasonido) con la técnica cambiada a *Alineamiento*. Jesús intentaba dar de
alta un servicio de alineamiento; el formulario le dejó elegir la técnica y el
guardado la ignoró sin avisar (bug descrito en V3-24).

**Situación actual**

- La técnica `alignment` existe (id 8, módulo `operating_data`, sin magnitud
  titular). Se pueden crear órdenes y visitas de alineamiento, pero **la visita
  no tiene nada que capturar**: no hay formato.
- Los códigos de orden siguen un prefijo por técnica (`MPd-AV` vibraciones,
  `MPd-US` ultrasonido, `MPd-AC` aceite, `MPd-AD` dieléctrico), pero se
  escriben a mano: el sistema no sugiere ninguno.
- Las recomendaciones de IPSA piden a menudo "alinear el conjunto rotórico con
  sistema láser" (Bba. Reject, Booster Nº 01). Los modos de falla
  `misalignment_parallel` y `misalignment_angular` ya existen.

**Qué hacer**

- Back, modelo propio (no `Reading`): una lectura necesita un punto, y un
  alineamiento es la relación entre dos ejes. `AlignmentRecord` por visita:
  conjunto, acople (componente conductor → conducido), RPM, y dos fases
  **antes / después**, cada una con paralelo H (mm), angular H (mm/100 mm),
  paralelo V (mm) y angular V (mm/100 mm), con signo. Además: holgura dentro
  de tolerancia (sí/no), instrumento, quién y cuándo.
- Back, tolerancias: tabla por rango de RPM (la del equipo SKF que usa 1A-MIG),
  sobrescribible por conjunto. Veredicto por valor sobre el **valor absoluto**.
  Cada registro congela la tolerancia con la que se juzgó, como las lecturas.
- Back, fotos con rol fijo y nota por foto: `alignment_before` (pantalla SKF,
  4 medidas), `alignment_after` (pantalla SKF, 4 medidas), `alignment_group`
  (1, el conjunto) y `alignment_observation` (hasta 2). Tope de 3 fotos
  representativas, validado en el servidor.
- Front, captura: formulario en dos columnas antes/después con las cuatro
  casillas cada una, ✓/✗ al escribir, y los cuatro huecos de foto con su nota.
- Front, Mediciones → Alineamiento: lista de conjuntos alineados en el mes
  (filtro por mes), con antes/después, veredicto y miniaturas pre y post.
- Órdenes: al elegir la técnica, sugerir el prefijo de código que le toca
  (`MPd-AL-…` para alineamiento; ver pregunta abajo).
- Vincular, si existe, el diagnóstico de desalineamiento de vibraciones que
  motivó el trabajo.

**Criterios de aceptación**

- **AC-01** Dada una visita de alineamiento, cuando se escriben los ocho valores
  de la captura 6 con la tolerancia que aplicó el equipo SKF en esa medición,
  entonces los ✓/✗ coinciden con los de la captura.
- **AC-02** Dado un valor antes de −0,40 mm y una tolerancia de 0,10 mm, cuando
  se guarda, entonces sale ✗ (se juzga el valor absoluto).
- **AC-03** Dadas ya tres fotos representativas, cuando se intenta subir una
  cuarta, entonces el servidor la rechaza con el motivo.
- **AC-04** Dada la pantalla Mediciones → Alineamiento en septiembre, cuando se
  abre, entonces lista los conjuntos alineados ese mes con sus imágenes pre y
  post.
- **AC-05** Dada una tolerancia cambiada después, cuando se abre un registro
  antiguo, entonces conserva el veredicto con el que se emitió.

**Preguntas abiertas**

- Q10: tolerancias — tabla SKF por RPM o una por equipo.
- Prefijo del código de las órdenes de alineamiento y topografía (y de las
  técnicas END de la épica 06). Pedir la lista oficial.
- "Alineamiento" aparece también como tarea de **mantenimiento** (V3-32). Aquí
  es la medición con el equipo láser; allá, la intervención. Un registro de
  mantenimiento de alineamiento debería enlazar a este registro, no repetirlo.

---

## V3-18 · Servicio de Topografía: nivelación y paralelismo

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | M | back, front | V3-19 |

**Origen**

> Mpd Predictivo — Topografía (foto de plano). Nivelación V y H — y
> paralelismo V y H.

**Contexto**

En una planta papelera (IPSA) la topografía se hace sobre rodillos y bases:
nivel de cada rodillo y paralelismo entre rodillos, sobre un plano de la
máquina donde cada elemento lleva número. El plano es la referencia de todo el
informe.

**Qué hacer**

- Datos: técnica `topography` en la familia MPd.
- Back: `TopographyRecord` por visita, con el **plano** (imagen, obligatoria) y
  una fila por elemento medido: identificador del elemento en el plano,
  nivelación H, nivelación V, paralelismo H, paralelismo V, observación.
- Sin veredicto automático hasta tener tolerancias (Q11): se guardan los
  valores y la conclusión del analista.
- Front: captura con el plano arriba y la tabla de elementos debajo;
  historial por elemento para ver la tendencia entre visitas.

**Criterios de aceptación**

- **AC-01** Dada una visita de topografía sin plano, cuando se intenta cerrar,
  entonces el sistema pide el plano.
- **AC-02** Dado un elemento "R3" medido en dos visitas, cuando se abre su
  historial, entonces se ven los cuatro valores de cada visita, fechados.
- **AC-03** Dada una visita de topografía, cuando se abre, entonces no muestra
  estados de condición inventados: solo valores y conclusión.

**Pregunta abierta**: Q11 (unidades, tolerancias, número de puntos por
elemento). Hasta tenerlas, mm para nivelación y mm/m para paralelismo, sin
veredicto.
