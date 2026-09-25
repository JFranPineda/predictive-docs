# 02 · El conjunto como fila

El cliente trabaja por **conjunto rotativo** (motor + bomba, motor + reductor),
no por máquina suelta. Es lo mismo que ya decía `docs/00-source-analysis.md`:
los límites y las conclusiones se emiten al conjunto. Las tablas principales
todavía listan equipos, y eso obliga a buscar dos o tres filas para ver una
sola unidad de trabajo.

Regla común a los cuatro tickets: **la fila es el conjunto; el equipo aparece
dentro de él**, nunca al revés.

---

## V3-05 · Activos: una fila por conjunto

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | M | back, front | — |

**Origen**

> Activos: Filas deben de ser conjuntos no equipos.

**Situación actual**

`/assets` (`assets/ui/EquipmentListPage.tsx:80-130`) pinta una fila por equipo:
TAG, equipo, conjunto, área, frecuencia, estado, vencido. En AMBEV son 558
filas para 360 conjuntos; el conjunto sale como una columna más.

**Qué hacer**

- Back: el listado de `asset-groups/` devuelve, por conjunto: código, nombre,
  tipo, área y sector, **estado del conjunto** (el peor de sus equipos, con la
  misma regla que el semáforo), número de equipos y sus equipos resumidos
  (TAG, nombre, componente, estado). Paginado por cursor, como el resto.
- Front: la tabla lista conjuntos. Cada fila se despliega para ver sus
  equipos, y cada equipo conserva sus acciones actuales (editar, placa,
  multimedia, mediciones).
- Los filtros actuales (área, tipo, estado) filtran conjuntos: un conjunto
  entra si alguno de sus equipos cumple el filtro.
- La búsqueda por TAG sigue funcionando: devuelve el conjunto con el equipo
  buscado desplegado.

**Criterios de aceptación**

- **AC-01** Dado un conjunto Motor-Bomba, cuando se abre `/assets`, entonces
  aparece una sola fila con el nombre del conjunto y "2 equipos".
- **AC-02** Dado un conjunto con el motor en alarma y la bomba operativa,
  cuando se lista, entonces la fila del conjunto sale en alarma.
- **AC-03** Dado un TAG de bomba, cuando se busca, entonces aparece su conjunto
  con la bomba visible.
- **AC-04** Dada una fila desplegada, cuando se pulsa "editar" en un equipo,
  entonces se abre el mismo formulario de equipo que hoy.

---

## V3-06 · Mediciones: la tabla "Elige un equipo" pasa a ser por conjunto

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | M | back, front | V3-08 |

**Origen**

> Mediciones: En vez de "medidas" que diga "tipos de medición".
> Tabla: elige un equipo: Que se dirija por Conjunto no por equipo cada fila.

**Situación actual**

- `/measurements` (`measurements/ui/MeasurementsIndexPage.tsx`) lista equipos:
  TAG, equipo, conjunto, área, estado (`measurements/locales/es.json:17-24`).
  "Ver tendencia" abre `/measurements/:equipmentId`.
- La palabra "Medidas" aparece en tres sitios: el indicador del índice
  (`measurements/locales/es.json:32`), la ayuda "Créalas en Configuración →
  Medidas" (`:29`) y el título de `/settings/magnitudes`
  (`thresholds/locales/es.json:126`).

**Qué hacer**

- Front: la tabla lista conjuntos (código, conjunto, tipo, área, estado del
  conjunto, puntos medidos por el servicio elegido). "Ver tendencia" abre el
  registro del conjunto entero.
- Rutas: nueva `/measurements/groups/:groupId`. La actual
  `/measurements/:equipmentId` redirige al conjunto del equipo con ese equipo
  preseleccionado en la lista de alcance (V3-08), para que no se rompan los
  enlaces que ya existen (semáforo, visitas).
- Textos: "Medidas" → "Tipos de medición" en los tres sitios, en `es` y `en`
  ("Measurement types").

**Criterios de aceptación**

- **AC-01** Dado el servicio de vibraciones, cuando se abre `/measurements`,
  entonces cada fila es un conjunto.
- **AC-02** Dada una fila, cuando se pulsa "Ver tendencia", entonces se abre el
  registro con **Todo el conjunto** seleccionado.
- **AC-03** Dado un enlace antiguo `/measurements/47`, cuando se abre, entonces
  se ve el conjunto del equipo 47 con ese equipo seleccionado.
- **AC-04** Dada la interfaz en español, cuando se busca la palabra "Medidas",
  entonces no aparece en ninguna pantalla; en su lugar dice "Tipos de medición".

---

## V3-07 · Columna "Última fecha de intervención"

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P1 | S | back, front | V3-06; se completa con V3-32 |

**Origen**

> Mediciones: Columna nueva: última fecha de intervención.

**Qué hacer**

- Back: en el listado por conjunto (V3-06), `last_intervention_at` = la fecha
  más reciente entre las visitas de **cualquier servicio** a cualquier equipo
  del conjunto y, cuando exista V3-32, los registros de mantenimiento.
  Calculado con una agregación, no una consulta por fila.
- Front: columna ordenable, con la fecha en formato `Intl` del idioma elegido.
  Al pasar el ratón: qué fue (servicio u orden de mantenimiento) y quién.

**Criterios de aceptación**

- **AC-01** Dado un conjunto con una visita de vibraciones el 12-sep y una de
  termografía el 18-sep, cuando se lista, entonces la columna dice 18-sep y el
  tooltip dice "Termografía".
- **AC-02** Dado un conjunto sin visitas, cuando se lista, entonces la columna
  muestra "—" y se ordena al final.

**Pregunta abierta**: Q3 del índice (qué cuenta como intervención). Si la
respuesta es "solo mantenimiento", este ticket espera a V3-32.

---

## V3-08 · Registro de valores: lista de alcance en lugar de dos botones

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | front | — |

**Origen**

> Todo el conjunto vs Solo este equipo: Ya que medidas van a ser mandado por
> tipo de conjunto, entonces poner lista seleccionable en vez de botones Todo el
> conjunto y solo este equipo. Que esa lista muestre las opciones de: todo el
> conjunto, motor, bomba, cada equipo dentro del conjunto.

**Situación actual**

`measurements/ui/RecordOfValuesPage.tsx:39` guarda `scope` como
`'group' | 'equipment'` y pinta dos botones (`:108-116`). "Solo este equipo"
depende de por qué equipo se entró: para ver la bomba hay que volver y entrar
por la bomba.

**Qué hacer**

- Un `Select` con: **Todo el conjunto** y, debajo, un elemento por equipo del
  conjunto con su componente y su TAG, en el orden del tren
  (`order_in_group`): "MOTOR · MB1141001A", "BOMBA · MB1141001B". Con dos
  chumaceras, cada una sale por separado (lado mando / lado transmisión).
- Elegir un equipo pide la matriz con `scope=equipment` para **ese** equipo.
- La elección viaja en la URL (`?equipment=<id>`), así el enlace se puede
  compartir y el botón atrás funciona.

**Criterios de aceptación**

- **AC-01** Dado un conjunto Motor-Bomba, cuando se abre su registro, entonces
  la lista ofrece: Todo el conjunto, MOTOR, BOMBA.
- **AC-02** Dada la opción BOMBA, cuando se elige, entonces la tabla y la
  exportación a Excel muestran solo los puntos de la bomba.
- **AC-03** Dado un conjunto con dos chumaceras, cuando se abre la lista,
  entonces aparecen las dos, distinguibles por su TAG.
- **AC-04** Dada una URL con `?equipment=<id>`, cuando se abre, entonces la
  lista ya tiene ese equipo elegido.
