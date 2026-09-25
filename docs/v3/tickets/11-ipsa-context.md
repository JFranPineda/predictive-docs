# 11 · Contexto: los 47 informes de IPSA

`EQUIPOS PLANTA IPSA - SEPTIEMBRE/` trae el trabajo real de un mes en la planta
de **Industrias del Papel (IPSA), Chaclacayo**: 47 libros de Excel, uno por
conjunto, y un libro resumen. Es la mejor fuente que hay de cómo trabaja el
cliente hoy, más reciente y más rica que los Excel de AMBEV 2014 de los que
salió el modelo. Varios tickets de v3 se entienden mejor con esto delante.

## Qué hay

| | |
|---|---|
| Libros | `Equipo # 01` a `# 44` y `Equipo FDR #01` a `#03` (Sala de cortes) |
| Resumen | `EQUIPOS - CONCLUSIONES.xlsx`: conclusiones del 28-sep, Pareto de vibraciones y de termografía, escala térmica |
| Áreas | Filtración (la mayoría), Secadores, Sala de cortes, MP3, Mesa plana |
| Instrumentos | SKF Microlog CMXA 80 (vibraciones), FLIR E4 (termografía) |
| Periodo | Columnas del 13-nov-2024 al 28-sep-2025 (en general 12 tomas por libro; el Pulper Nº 04 tiene 14, entre el 27-ago y el 28-sep) |

Cada libro tiene tres hojas: **VIBRACIONES**, **TERMOGRAFÍA** (o
`TERMOGRAFÍA_LM` y `TERMOGRAFÍA_LT` en las chumaceras de la MP3) y **2P**. La
hoja 2P es la plantilla vieja de AMBEV 2014 (Planta Huachipa, SEMAPI) que quedó
dentro de todos los libros: **no es de IPSA y hay que ignorarla**.

## Hoja VIBRACIONES

Misma estructura que el informe de AMBEV: cabecera (cliente, locación, área,
equipo, estado, fechas, inspector de campo, inspector analista, equipo
utilizado), **I. Antecedentes**, **II. Estado actual**, **III. Recomendaciones**
(cada una con su fecha), **IV. Registro de valores**, **V. Límites**,
**VI. Tendencias**, y debajo las imágenes: esquema del tren con los puntos
(P01…P05, dientes de engranaje, HP y RPM), foto real, gráfico de tendencias y
espectros en cascada exportados del software de SKF.

Registro de valores:

```
COMPONENTE  PUNTO  UNID.    ETIQUETA  27-ago  28-ago  …  28-sep
MOTOR       1      mm/seg.  HV-1      3.02    2.31       3.70
                   Gs.      EE-1      0.91    0.86       0.42
                   mm/seg.  VV-1      2.66    1.92       2.63
                   mm/seg.  AV-1      2.98    2.08       2.65
```

- Cuatro filas por punto: velocidad H, V, A (`HV`, `VV`, `AV`, mm/s) y
  envolvente (`EE`, "Gs."). **No hay filas de temperatura** ni de aceleración.
- La numeración corre a lo largo del tren, como ya modela el sistema.
- Encima de las fechas, dos filas más: la **etiqueta de la toma** y el
  **estado por columna** (OBSERVACIÓN, PARADA).
- Debajo, filas **Alarma** y **Parada por columna**: el límite puede cambiar de
  una toma a otra.

## Trenes encontrados

| Forma | Ejemplos | Puntos |
|---|---|---|
| Motor + bomba | Bba. Reject, Booster, Pasta refinada, Motor bba vacío 01–06 | 1–4 |
| Motor + reductor | Pulper Nº 04 (1–5), Couch, Helper, Rollo cabecero (1–6) | 5–6 |
| Motor + reductor + chumacera | Faja transportadora, Ragger, Trommel | 5–6 |
| Motor + reductor + chumacera LM + chumacera LT | 1ra, 2da, 3ra prensa | 1–6 (cuatro máquinas, seis puntos) |
| Chumacera + reductor | Grupos de secadores, Size press | 1–6 |
| Motor + rollo / refinador / reject | FDR cama 01–02, Refinadores Pilao | 1–4 |
| Rollo solo | Rollo cabecero (#036) | 1–2 |
| **Líneas largas de la MP3** | Chumaceras lado mando R1 (1–16), R2 (17–32), R3 (33–36); árbol de transmisión R1 (motor + chumaceras 1–7), R2 (8–19) | hasta 36 |

Las líneas de la MP3 reparten **un solo tren** en varios libros, y la
numeración continúa de uno a otro. Es el caso que intentaba modelar Jesús en la
captura 1 del Word (V3-03).

## Límites que aparecen

- Motores: **ISO 20816-3** en casi todos (algunos todavía ISO 10816-3).
- Bombas: Technical Associates of Charlotte.
- Envolvente: "Límites permisibles de Envolvente de aceleración (**Gs
  Pico**)" — relevante para Q1.
- **Pulper Nº 04** usa límites "según **adaptación de diseño**": 10 mm/s alarma
  y 13 mm/s parada, envolvente 2 / 2,5, "definidos bajo tendencias obtenidas en
  el tiempo de operación, con una velocidad de ingreso al reductor de 1 800
  rpm". Es un umbral propio de un conjunto, no de una norma. Y el propio libro
  se contradice: las filas por columna dicen 12,1 de alarma, no 10.

## Estados que usa el cliente

NORMAL · **OBSERVACIÓN** · ALARMA · PARADA · APAGADO · **SIN ACCESO**.

- OBSERVACIÓN no existe en el sistema (operativo / alarma / parada).
- APAGADO es disponibilidad, no condición (`SUMMARY.md` §3.3).
- SIN ACCESO es "no medido" con motivo. Los motivos del resumen son concretos:
  "residuos excesivos de pulpa (SSOMA no permite el acceso por resbalamiento)",
  "equipo con guarda", "pisos mojados", "personal de planta dice que el equipo
  ya no opera" (este último apunta a *retirado*).

## Libro resumen

- Una fila por conjunto: estado de termografía (OK / APAGADO), estado de
  vibraciones, conclusión y recomendación. Es el entregable mensual; ver V3-23.
- Pareto de vibraciones: 21-sep → 17 normal, 1 alarma, 3 parada, 20 apagado;
  28-sep (ronda B) → 2 / 2 / 2 / 0.
- Escala térmica de cuatro niveles: aceptable 0–82 °C, alarma 82–121,
  **alerta** 121–148, parada 148–300 (Q9, V3-16).

## Datos sucios a tener en cuenta al importar

- Pulper Nº 04: el punto 5 está rotulado `HV-4 / EE-4 / VV-4 / AV-4` (copia del
  punto 4).
- Componentes escritos "MOTOR1".
- Estado "PARDA" (por PARADA) en el árbol de transmisión R1.
- Fechas de columna mezcladas: fechas reales y texto (`'10-Sep-25'`).
- Cabeceras de termografía que dicen "SKF Microlog" como equipo utilizado
  (copiado de la hoja de vibraciones).
- Antecedentes de termografía fechados en julio en libros de septiembre.

---

## V3-37 · Importar la planta IPSA como segundo inquilino *(derivado, no pedido)*

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | L | back, datos | V3-03, V3-12; para las imágenes, V3-14, V3-15 y V3-16 |

**Por qué está aquí**: no lo pide ninguna nota, pero la carpeta llegó con los
requerimientos y es el pendiente "Datos reales de IPSA sin importar" de
`SUMMARY.md` §6. Los formatos nuevos de v3 se validan mucho mejor contra la
planta real que contra la demo sintética de AMBEV. Confirmar con el usuario
antes de empezarlo.

**Qué hacer**

- Inquilino `ipsa` ("Industrias del Papel — Planta Chaclacayo"), con su base
  propia, como AMBEV.
- Comando `tenants run ipsa import_ipsa --docs ../predictive-docs`, aditivo e
  idempotente como `seed_more`:
  - estructura: planta → áreas → conjuntos (uno por libro, con el número del
    cliente) → equipos (por COMPONENTE) → puntos (por PUNTO y etiqueta);
  - lecturas: velocidad H/V/A y envolvente por columna fechada, en visitas
    agrupadas por fecha, con la **etiqueta de la toma** guardada como dato
    operativo de texto ("Condición de carga": VACÍO, CON AGUA, CARGA 1TN,
    CARGA 100 %);
  - antecedentes, estado actual y recomendaciones como líneas del diario, con
    su fecha;
  - umbrales: ISO 20816-3 / Technical Associates según el rótulo, y el umbral
    propio del Pulper Nº 04;
  - estados: NORMAL → operativo, ALARMA → alarma, PARADA/PARDA → parada,
    APAGADO → disponibilidad apagado, SIN ACCESO → no medido con motivo;
    OBSERVACIÓN según responda el cliente;
  - ignorar la hoja 2P;
  - informe de lo que no se pudo mapear (etiquetas repetidas, fechas en texto).
- Segunda pasada (cuando existan V3-14/15/16): esquema, foto, espectros en
  cascada y termogramas.

**Criterios de aceptación**

- **AC-01** Dado el inquilino `ipsa` vacío, cuando se importa la carpeta,
  entonces hay 47 conjuntos y ningún dato de la hoja 2P.
- **AC-02** Dado el Pulper Nº 04, cuando se abre su registro de valores,
  entonces el punto 3 H del 28-sep vale 14,14 mm/s y la columna lleva la
  condición "CARGA 100 %".
- **AC-03** Dado el punto 5 del Pulper Nº 04, rotulado HV-4 en el libro, cuando
  se importa, entonces queda como punto 5 y el informe de importación lo avisa.
- **AC-04** Dada la importación ejecutada dos veces, cuando se revisa el
  resumen, entonces la segunda crea cero registros.
- **AC-05** Dado el semáforo de vibraciones de la ronda del 28-sep, cuando se
  compara con la hoja PARETO VIBRACIONAL, entonces los conteos coinciden o las
  diferencias quedan explicadas en el informe de importación.
