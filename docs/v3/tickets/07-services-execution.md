# 07 · Servicios y ejecución

Pantallas `/services` (órdenes), `/services/authorship` (Ejecución) y el
detalle de visita `/services/visits/:id`.

---

## V3-24 · Órdenes: columna "Empresa" en lugar de "Analista", editable

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio + bug | P1 | M | back, front | — |

**Origen**

> Servicios: Botón Editar: no me deja editar al analista.
> Columna analista: renombrar por Empresa.

Captura 5 del Word: "Editar orden" sobre `MPd-US-N°004-26` con la técnica
cambiada a Alineamiento y el botón principal diciendo **"Crear orden"**.

**Situación actual — el formulario de edición tiene cuatro fallos**

`services/ui/OrderFormModal.tsx`:

1. **No tiene campo de analista.** El back sí lo acepta en el PATCH
   (`modules/services/interfaces/admin_views.py:79-80`, `lead_analyst`).
2. **Planta y técnica se pueden cambiar, pero el guardado las ignora sin
   avisar** (`:45-54`). El comentario explica por qué no se deben mover (las
   visitas cuelgan de ellas), pero los selectores siguen activos. Es lo que
   pasó en la captura 5.
3. **La planta arranca vacía al editar** (`plant: 0`, `:34`) y el botón exige
   `draft.plant` (`:74`): para guardar un cambio de código hay que volver a
   elegir la planta, que después se descarta.
4. **El botón dice "Crear orden" también al editar** (`:77`, siempre
   `orderForm.create`).

Además, no existe el concepto de empresa: la orden guarda `lead_analyst` y
`supervisor` (usuarios); del usuario solo se sabe si es externo
(`User.is_external`).

**Qué hacer**

- Back: catálogo `ServiceProvider` (empresa ejecutora) por compañía: nombre,
  RUC opcional, activo. Semilla: "1A-MIG". `ServiceOrder.provider` (FK,
  opcional al principio). El listado devuelve `provider_name`.
- Front, formulario: campo **Empresa** (select del catálogo) y campo
  **Analista** (usuarios con rol de ingeniero); los dos editables.
- Front, formulario de edición: planta y técnica **deshabilitadas** con una
  línea que diga por qué; la planta precargada; botón "Guardar cambios".
- Front, tabla: columna "Empresa" en lugar de "Analista". El analista pasa al
  detalle de la orden.
- Configuración: pantalla mínima del catálogo de empresas.

**Criterios de aceptación**

- **AC-01** Dada una orden, cuando se pulsa "Editar", se cambia la empresa y el
  analista y se guarda, entonces la tabla muestra la empresa nueva y el detalle
  el analista nuevo.
- **AC-02** Dada una orden con visitas, cuando se abre "Editar", entonces planta
  y técnica aparecen bloqueadas con su motivo.
- **AC-03** Dada una orden, cuando se abre "Editar" y solo se cambia el código,
  entonces se puede guardar sin tocar la planta.
- **AC-04** Dado el modal en modo edición, cuando se mira el botón principal,
  entonces dice "Guardar cambios".

**Pregunta abierta**: Q4 (qué es "Empresa").

---

## V3-25 · Órdenes: "Fecha de servicio", fuera "Abiertas", aclarar "Visitas"

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | front | — |

**Origen**

> Columna ventana: renombrar por Fecha de servicio.
> Visitas: ¿qué significa? ¿Renombrar por número de personas? ¿Son personas que
> ingresarán a planta?
> Abiertas: ¿qué significa abiertas? […] Abiertas: quitar esa columna.

**Situación actual**

Columnas de `services/ui/ServiceOrdersPage.tsx` con sus textos en
`services/locales/es.json:36-44`: Código, Técnica, **Ventana**, Analista, OT
cliente, **Visitas**, **Abiertas**, Estado. "Visitas" es el número de equipos
visitados en la orden; "Abiertas", las visitas que su autor aún puede editar.
Ninguno de los dos términos se entiende sin explicación.

**Qué hacer**

- "Ventana" → **"Fecha de servicio"**. Con un solo día, una fecha; con varios,
  el rango ("18–20 sep 2026").
- "Visitas" → **"Equipos inspeccionados"**, con ayuda al pasar el ratón:
  "Equipos visitados en esta orden". No es número de personas.
- Quitar la columna "Abiertas" y su indicador de la fila de totales.
- Ajustar el subtítulo de la página, que hoy explica "las abiertas".
- Textos en `es` y `en`.

**Criterios de aceptación**

- **AC-01** Dado `/services`, cuando se abre, entonces las columnas son: Código,
  Técnica, Fecha de servicio, Empresa, OT cliente, Equipos inspeccionados,
  Estado.
- **AC-02** Dada una orden del 18 al 20 de septiembre, cuando se lista, entonces
  la fecha de servicio dice "18–20 sep 2026".
- **AC-03** Dado el encabezado "Equipos inspeccionados", cuando se pasa el ratón,
  entonces aparece la explicación.

**Pregunta abierta**: Q5 (confirmar el nombre de "Visitas").

---

## V3-26 · Órdenes: buscador y totales que siguen al filtro

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P1 | M | back, front | V3-04, V3-25 |

**Origen**

> Valores superiores (tienen que ser dinámicos respecto de barra de búsqueda de
> órdenes de servicio) de: Órdenes, visitas, abiertas. Agregar barra de
> búsqueda por órdenes de servicio.

**Situación actual**

El listado solo filtra por `status` (`modules/services/interfaces/views.py:31-32`).
No hay búsqueda. Los totales tienen el fallo de V3-04.

**Qué hacer**

- Back: parámetro `q` que busca en código de orden, OT del cliente, técnica,
  empresa y analista. Filtros adicionales: técnica, estado y rango de fechas.
- Back: `totals` (V3-04) se calcula **sobre el mismo filtro** que la lista.
- Front: barra de búsqueda con espera de 300 ms; los filtros viajan en la URL.
  Los indicadores de arriba (Órdenes, Equipos inspeccionados) cambian con la
  búsqueda.

**Criterios de aceptación**

- **AC-01** Dado el texto "MPd-AV", cuando se escribe en el buscador, entonces
  la tabla muestra solo órdenes de vibraciones y "Órdenes" dice 6.
- **AC-02** Dado ese filtro, cuando se mira "Equipos inspeccionados", entonces
  es la suma de las 6 órdenes filtradas.
- **AC-03** Dada una búsqueda sin resultados, cuando se muestra, entonces los
  totales dicen 0 y la tabla ofrece limpiar el filtro.
- **AC-04** Dada una URL con `?q=OT-1390003`, cuando se abre, entonces el
  buscador ya tiene el texto y la tabla está filtrada.

---

## V3-27 · Solo el administrador cambia el estado de una orden

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, front | — |

**Origen**

> Columna estado: solo el admin puede cambiar el estado de los servicios (en
> ejecución, abierta, …).

**Situación actual**

- Estados: Programada, En ejecución, Ejecutada, Anulada. En pantalla solo se
  ven; no hay forma de cambiarlos salvo "Anular".
- El PATCH acepta `status` con el permiso `services.manage_order`
  (`admin_views.py:70-75`), que tienen **company_admin, engineer y
  jefe_mantenimiento**.
- Hallazgo de paso: el Jefe de Mantenimiento figura en la matriz de acceso
  como "Solo lectura + auditoría", pero tiene `services.manage_order`: hoy
  puede crear, editar y anular órdenes. Hay que confirmar si es intencional
  (su comportamiento base es `planner`).

**Qué hacer**

- Back: permiso nuevo `services.change_order_status`, concedido solo a
  `company_admin`. El PATCH rechaza `status` sin él; "Anular" también lo exige.
  Cada cambio de estado se registra en la auditoría.
- Back: validar transiciones (no se reabre una anulada).
- Front: para quien tiene el permiso, la columna Estado es un selector en la
  fila; para el resto, la etiqueta de siempre.
- Revisar con el cliente el permiso del Jefe de Mantenimiento.

**Criterios de aceptación**

- **AC-01** Dado un ingeniero, cuando abre `/services`, entonces el estado es
  una etiqueta y no puede cambiarlo ni anular.
- **AC-02** Dado un ingeniero que fuerza el PATCH con `status`, cuando el
  servidor responde, entonces es 403 con el motivo.
- **AC-03** Dado el administrador, cuando cambia una orden de Programada a En
  ejecución, entonces la fila cambia y queda una línea en `/settings/audit`.
- **AC-04** Dada una orden anulada, cuando el administrador intenta pasarla a
  En ejecución, entonces el servidor lo rechaza.

---

## V3-28 · Ejecución: el detalle muestra equipo y conjunto

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, front | — |

**Origen**

> Ejecución de servicios: Detalle: agregar columna que diga equipo y conjunto.

Captura 3 del Word (`/services/visits/4328`): el encabezado de la visita dice
"C122001 · COMPRESOR" y debajo "122 - AIRE COMPRIMIDO · COMPRESSOR SULLAIR 05".

**Situación actual**

Cada tarjeta de `/services/authorship`
(`services/ui/AuthorshipPage.tsx:115-127`) muestra el nombre del equipo, su TAG
y el área, **pero no el conjunto**. Con nombres como "MOTOR" o "BOMBA", que se
repiten en cientos de conjuntos, la tarjeta no dice de qué máquina se trata. En
el detalle de visita el conjunto sí aparece, pero sin rótulo.

**Qué hacer**

- Back: el payload de Ejecución añade `group_name` y `group_code`.
- Front, tarjeta: dos datos rotulados, **Conjunto** y **Equipo** (componente +
  TAG), antes del área.
- Front, detalle de visita: rotular "Conjunto" y "Equipo" en la cabecera.

**Criterios de aceptación**

- **AC-01** Dada una visita a la bomba del conjunto "EB 228", cuando se abre
  Ejecución, entonces la tarjeta dice "Conjunto: EB 228 · Equipo: BOMBA
  MB1141001B".
- **AC-02** Dado el detalle de esa visita, cuando se abre, entonces la cabecera
  rotula Conjunto y Equipo.

---

## V3-29 · Tipo de lubricación por equipo (aceite / grasa)

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | S | back, front | — |

**Origen**

> Tipo de lubricación: Compresor, bomba, reductor, turbinas: Aceite. Motor:
> grasa. Soplador: aceite o grasa.

**Situación actual**

La placa (`modules/nameplate/infrastructure/models.py:52-53`) guarda
`lubricant` (texto libre: la marca o grado) y `lubricant_interval_h`. No hay
tipo de lubricación.

**Qué hacer**

- Back: `Equipment.lubrication_type` con valores `oil`, `grease`, `none`.
  Al crear un equipo, se propone según su tipo: compresor, bomba, reductor y
  turbina → aceite; motor → grasa; soplador → sin valor por defecto (hay que
  elegir). Migración de datos con la misma regla para los existentes.
- Front: campo en el formulario de equipo; se muestra en la ficha y en la
  cabecera de las visitas de lubricación y de análisis de aceite.
- Análisis de aceite: advertir si se programa sobre un equipo con grasa.

**Criterios de aceptación**

- **AC-01** Dado un equipo nuevo de tipo bomba, cuando se abre el formulario,
  entonces "Aceite" viene elegido.
- **AC-02** Dado un soplador nuevo, cuando se abre el formulario, entonces el
  campo está vacío y es obligatorio.
- **AC-03** Dada la migración, cuando se aplica en AMBEV, entonces todos los
  motores quedan con grasa y todos los reductores con aceite.

**Pregunta abierta**: Q7 (dónde se quiere ver).

---

## V3-30 · Datos operativos en números enteros

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, front, datos | — |

**Origen**

> Datos operativos: Números sin decimales, solo guardar y mostrar enteros.

**Situación actual**

`OperatingParameter.decimals` vale **1** en los doce parámetros de AMBEV
(velocidad, frecuencia, amperaje, voltaje, potencia, factor de potencia, horas,
presiones, temperatura ambiente). El valor se guarda como
`DecimalField(max_digits=14, decimal_places=4)`
(`modules/operating_data/infrastructure/models.py:27` y `:49`).

**Qué hacer**

- Datos: `decimals = 0` en todos los parámetros, **salvo factor de potencia**
  (ver pregunta).
- Back: al guardar, redondear a `decimals` del parámetro (la regla ya está en
  el catálogo; se aplica en la escritura, no solo al mostrar).
- Front: la casilla usa `step` según `decimals` y el valor se muestra con
  `Intl` sin decimales.
- Las lecturas ya guardadas con decimales se muestran redondeadas; no se
  reescribe el histórico.

**Criterios de aceptación**

- **AC-01** Dado el amperaje, cuando se escribe 45,6 y se guarda, entonces se
  guarda y se muestra 46.
- **AC-02** Dada una lectura histórica de 1 785,4 rpm, cuando se abre, entonces
  se muestra 1 785.
- **AC-03** Dado el factor de potencia, cuando se escribe 0,86, entonces se
  conserva 0,86.

**Pregunta abierta**: Q6 — el factor de potencia vale entre 0 y 1; en entero
siempre sería 0 o 1. Supuesto: queda con 2 decimales.

---

## V3-31 · Problemas a identificar: opción "Otros"

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, front | — |

**Origen**

> Problemas a identificar: Agregar opciones otros.

**Situación actual**

La pestaña "Problemas" de la visita ofrece los modos de falla de la técnica
(17 en vibraciones, 11 en termografía, 12 en ultrasonido, 5 en aceite). No hay
forma de anotar uno que no esté en la lista.

**Qué hacer**

- Datos: un modo de falla `other` ("Otros") por técnica.
- Back: al marcar "Otros", la visita exige una descripción corta (texto),
  guardada con la visita.
- Front: al marcar "Otros" aparece el campo de texto; en listados y en el
  informe se muestra "Otros: <descripción>".
- Reporte de "Otros" por técnica en Configuración → Modos de falla, para ver
  qué conviene añadir al catálogo.

**Criterios de aceptación**

- **AC-01** Dada una visita de vibraciones, cuando se abre "Problemas", entonces
  aparece "Otros" al final de la lista.
- **AC-02** Dado "Otros" marcado sin descripción, cuando se guarda, entonces el
  sistema pide la descripción.
- **AC-03** Dado "Otros: vibración por tubería suelta", cuando se abre la
  visita, entonces se ve con su descripción.
