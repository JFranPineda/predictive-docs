# 03 · Vibraciones y espectros

---

## V3-09 · Espectros de todos los puntos del conjunto

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, front | V3-06 |

**Origen**

> Activos: Espectros deben de verse todos los puntos del conjunto.

**Situación actual**

`/measurements/:equipmentId/spectra` lista los espectros de **un** equipo
(`measurements/ui/SpectraPage.tsx:34-52`; el back filtra por `equipment` en
`modules/measurements/interfaces/spectrum_views.py:42-45`). En cambio, el
formulario para importar ya ofrece los puntos de todo el conjunto
(`SpectraPage.tsx:238`, `scope: 'group'`). Se puede subir un espectro de la
bomba desde el motor y después no verlo ahí.

El listado corta en `limit` (máx. 200) sin paginar.

**Qué hacer**

- Back: filtro `group=<id>` en `spectra/`, y paginación por cursor igual que la
  galería (`created_at`, `id`).
- Front: la página muestra el conjunto entero, agrupado por punto en el orden
  del tren (1H, 1V, 1A, 2H…), con la misma lista de alcance de V3-08 para
  quedarse con un solo equipo.

**Criterios de aceptación**

- **AC-01** Dado un espectro del punto 3H (bomba), cuando se abren los
  espectros desde el motor del mismo conjunto, entonces aparece.
- **AC-02** Dado un conjunto con 250 espectros, cuando se baja hasta el final,
  entonces se cargan todos por páginas.

---

## V3-10 · Orden de los bloques: velocidad → aceleración → envolvente → temperatura

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| bug | P1 | S | back | — |

**Origen**

> Orden de tablas: Vibraciones: 1) velocidad, 2) aceleración, 3) envolvente
> aceleración.

Word, ruta `/measurements/3`: Velocidad mm/s RMS · Aceleración gEs RMS ·
Envolvente Aceleración gE RMS · Temperatura.

**Situación actual**

Los bloques del registro se ordenan por su clave `"<código>:<agregación>"`
(`modules/measurements/interfaces/matrix_views.py:188` y `:193-196`). El orden
alfabético da `env_accel:peak` → `temp:max` → `vel_rms:rms`: **la envolvente
sale primero y la velocidad, que es la magnitud titular, sale la última**.
Es justo al revés que la hoja del cliente.

**Qué hacer**

- Back: campo `display_order` en `Magnitude` (migración + valores iniciales:
  vel_rms 10, accel 20, env_accel 30, temp 40; el resto de técnicas en
  decenas propias). Ordenar los bloques por `display_order` y, en empate, por
  la clave actual.
- Front: el orden viene del servidor; no reordenar en el cliente.
- La exportación a Excel usa el mismo orden.
- Configuración → Tipos de medición permite cambiar el orden.

**Criterios de aceptación**

- **AC-01** Dado un motor con velocidad, envolvente y temperatura, cuando se
  abre su registro, entonces los bloques salen en ese orden: velocidad,
  envolvente, temperatura.
- **AC-02** Dada la magnitud de aceleración de V3-11 con lecturas, cuando se
  abre el registro, entonces sale entre velocidad y envolvente.
- **AC-03** Dada la exportación a Excel, cuando se abre el fichero, entonces las
  tablas siguen el mismo orden que la pantalla.

**Pregunta abierta — Q1, no tocar sin respuesta**: el Word escribe
"Envolvente Aceleración gE **RMS**", pero los 47 informes de IPSA dicen
"Límites permisibles de Envolvente de aceleración (Gs **Pico**)" y el sistema
guarda la envolvente como `peak`. En este dominio la agregación **es parte del
criterio** (`SUMMARY.md` §3.4: 10 gE es parada en una escala y alarma en la
otra). Este ticket solo cambia el orden; la agregación no se toca hasta que el
cliente responda.

---

## V3-11 · Nueva magnitud: Aceleración en g RMS

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | S | back, datos | V3-10 |

**Origen**

Word: "Aceleración gEs RMS", entre velocidad y envolvente. Responde el pendiente
de `SUMMARY.md` §6: "Aceleración en G — la unidad existe, ninguna magnitud la
usa. Falta saber si es pico o RMS".

**Situación actual**

La unidad `g` existe (id 3, "Aceleración") y ninguna magnitud la usa. Hoy
vibraciones tiene `vel_rms` (mm/s, rms, por eje) y `env_accel` (gE, pico, por
rodamiento).

**Qué hacer**

- Datos: magnitud `accel_rms` — técnica vibraciones, unidad `g`, agregación
  `rms`, `per_axis=True` (la aceleración global se lee por eje, como la
  velocidad), `higher_is_worse=True`, 2 decimales, `display_order` 20.
- Umbrales: no hay norma cargada para aceleración global. Sin juego de
  umbrales, la lectura se registra **sin veredicto** y así se muestra; no se
  inventan límites.
- Captura de ronda e importación: aceptan la nueva magnitud en los puntos cuya
  plantilla la incluya.
- No se añade a las plantillas por defecto hasta que el cliente diga en qué
  conjuntos la mide (los informes de IPSA no la traen).

**Criterios de aceptación**

- **AC-01** Dado un punto cuya plantilla incluye `accel_rms`, cuando se captura
  una ronda, entonces aparecen tres casillas (H, V, A) en g.
- **AC-02** Dada una lectura de aceleración sin umbral configurado, cuando se
  muestra, entonces sale el valor sin color de estado y con la marca "sin
  norma".

---

## V3-12 · Plantillas de puntos por tipo de conjunto

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, datos | V3-03 |

**Origen**

> Inger soll rand es un compresor: 6 envolventes y 18 velocidades.
>
> Motor + reductor: 8 puntos · Compresor: 6 puntos · Bomba: 4 puntos ·
> Ventilador: 4 puntos · Soplador: 4 puntos · Turbina: 4 puntos
> —— Turbina: 8 puntos (lado = otro)

**Situación actual**

| Tipo | Hoy (componentes) | Hoy (plantilla) | Pedido |
|---|---|---|---|
| Motor-Bomba | 2 + 2 | 4 puntos | 4 ✔ |
| Motor-Compresor | 2 + **2** | 6 puntos; envolvente solo en 1–4 | 6 puntos, **envolvente en los 6** |
| Motor-Reductor | 2 + 2 | 4 puntos | **8** |
| Motor-Ventilador | 2 + 2 | 4 puntos | 4 ✔ |
| Motor-Soplador | 2 + 2 | 4 puntos | 4 ✔ |
| Motor-Turbina | 2 + 2 | 4 puntos | 4 ✔, y otro de **8** |

"6 envolventes y 18 velocidades" = 6 puntos × (H, V, A) de velocidad + una
envolvente por rodamiento. Hoy los puntos 5 y 6 del compresor solo miden
velocidad (captura 2 del Word: "5 · COMPRESOR · A H V · vel_rms").

**Qué hacer**

- Datos (migración de datos, idempotente):
  - Motor-Compresor: `COMPRESOR` con `point_count=4`; `env_accel` y `temp` en
    los seis puntos, en la fila H (hoy van en la V; ver V3-03 punto 5).
  - Motor-Reductor: `REDUCTOR` con `point_count=6` → 8 puntos en total.
  - Nuevo tipo "Motor-Turbina (8 puntos)": motor 2 + turbina 6, con lado
    `custom` en los puntos de la turbina. "Lado = otro" es ese valor: el editor
    de tipos lo rotula **"Otro"** (`assets/locales/es.json:167`) y el registro
    de valores lo rotula **"General"** (`measurements/locales/es.json:70`).
    Unificar el rótulo en las dos pantallas.
- Los conjuntos que ya existen **no cambian sus puntos**: una plantilla solo se
  aplica al crear el conjunto o al pulsar "Aplicar plantilla" en
  `GroupPointsModal`, que añade lo que falta sin tocar lo que hay.
- Actualizar `seed_demo` para que un resembrado dé lo mismo.

**Criterios de aceptación**

- **AC-01** Dado un conjunto Motor-Compresor nuevo, cuando se crea, entonces
  tiene 18 puntos de velocidad (1–6 × H/V/A) y 6 de envolvente.
- **AC-02** Dado un conjunto Motor-Reductor existente con 4 puntos y lecturas,
  cuando se aplica la migración, entonces conserva sus 4 puntos y sus lecturas.
- **AC-03** Dado ese mismo conjunto, cuando se pulsa "Aplicar plantilla",
  entonces se añaden los puntos 5–8 y no se duplican los 1–4.
- **AC-04** Dado `/settings/group-kinds`, cuando se abre, entonces cada tipo
  muestra un total de puntos igual a la suma de sus componentes.

**Pregunta abierta**: Q2 del índice (reparto de los 8 puntos del
motor-reductor, y reparto de los 8 de la turbina).

---

## V3-13 · "Se mide" legible, y cómo se configuran los demás servicios en un punto

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P2 | S | front, docs | — |

**Origen**

> Word: motor - compresor solo tiene 4 puntos y dice […] no dicen los demás
> servicios, ¿por qué? ¿Cómo se configura?

Capturas 2 y 7: la columna "SE MIDE" muestra `vel_rms, env_accel, temp`.

**Situación actual**

- `/settings/group-kinds` pinta los códigos internos
  (`assets/ui/GroupKindsPage.tsx:144-151`, `magnitudes.join(', ')`).
- La plantilla de un punto admite magnitudes de cualquier técnica (por ejemplo
  `us_db` para ultrasonido), pero nada en la pantalla lo dice. Como las
  plantillas de fábrica solo traen vibraciones, parece que el conjunto no
  admite otros servicios.
- Lo de "4 puntos" es el descuadre de V3-03 (`COMPRESOR` con `point_count=2`).

**Qué hacer**

- Front: mostrar el nombre corto de cada magnitud en el idioma del usuario,
  agrupado por servicio: "Vibraciones: velocidad, envolvente · Termografía:
  temperatura".
- Front: en el editor de tipo, el selector de "Se mide" agrupa las magnitudes
  por servicio, y una línea de ayuda explica que un punto puede llevar
  magnitudes de varios servicios.
- Docs: respuesta para Jesús (abajo) en la ayuda de usuario.

**Respuesta para el cliente** (copiar a la ayuda):

> Cada punto de la plantilla dice qué se mide en él. Si un conjunto también
> recibe ultrasonido o termografía, se edita su tipo en Configuración → Tipos
> de conjunto y, en cada punto, se añade la magnitud de ese servicio (por
> ejemplo, "Nivel de ultrasonido"). Los conjuntos ya creados reciben los puntos
> nuevos con "Aplicar plantilla", sin perder sus lecturas.

**Criterios de aceptación**

- **AC-01** Dado `/settings/group-kinds` en español, cuando se abre, entonces
  no aparece ningún código tipo `vel_rms`.
- **AC-02** Dado el editor de un tipo, cuando se abre el selector "Se mide" de
  un punto, entonces las magnitudes aparecen agrupadas por servicio.

---

## V3-14 · Esquema del conjunto y fotos reales en la vista de vibraciones

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | M | back, front | V3-01 |

**Origen**

> Vibraciones: 1) velocidad, 2) aceleración, 3) envolvente aceleración.
> Con el esquema (planos del equipo). Con subir fotos (real del equipo).

Cada informe de IPSA lleva, en la cabecera, un esquema del tren con los puntos
marcados (P01…P05, piñones, relación de transmisión) y una foto real del
equipo (ver `11-ipsa-context.md`).

**Situación actual**

El módulo `blueprints` (planos con puntos) está diseñado en
`docs/02-domain-model.md` §1 y sin implementar. La galería por equipo existe
(`/assets/:id/media`), pero el registro de valores no muestra ninguna imagen.

**Qué hacer** (MVP, sin esperar a `blueprints`)

- Back: dos tipos de imagen nuevos a nivel de **conjunto**: `schematic`
  (esquema) y `site_photo` (foto real), con la misma subida, derivadas y
  auditoría que el resto.
- Front: en `/measurements/groups/:groupId`, encima de las tablas, el esquema
  a la izquierda y la foto a la derecha, a tamaño de lectura; clic para ampliar.
  Si no hay, un hueco con "Subir esquema" / "Subir foto" para quien tenga
  permiso.
- Se conserva el último subido de cada tipo; los anteriores quedan en la
  galería del conjunto.
- Fuera de alcance: marcar los puntos sobre el plano. Eso es `blueprints`.

**Criterios de aceptación**

- **AC-01** Dado un conjunto sin esquema, cuando un ingeniero sube una imagen
  como esquema, entonces aparece encima del registro de valores.
- **AC-02** Dado un esquema nuevo sobre uno anterior, cuando se sube, entonces
  el registro muestra el nuevo y el anterior sigue en la galería.
- **AC-03** Dado un usuario de solo lectura, cuando abre el registro, entonces
  ve el esquema y no ve el botón para subir.

---

## V3-15 · Espectros: subir la captura como imagen, texto de varias líneas, editar al abrir

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| bug + cambio | P1 | M | front | V3-01, V3-09 |

**Origen**

> Activos: Al subir imágenes, ¿qué formato debo de subir? Me dice no tiene
> pares amplitud ni frecuencia.
> El campo de texto del espectro importado solo muestra una línea.
> Solamente al hacer clic sobre una imagen que se muestren sus campos: y ahí se
> pueden editar el texto y detalles.

**Situación actual**

- **La captura en imagen no tiene por dónde entrar.** El back acepta un
  espectro que sea solo imagen (`spectrum_views.py:80-86`: exige "al menos una
  captura o un archivo de datos"), pero el formulario solo tiene un campo de
  fichero con `accept=".csv,.txt"` (`SpectraPage.tsx:302`) y lo manda como
  `data`. Si el usuario elige un PNG, el parser lo lee como texto y responde
  "El archivo no tiene pares frecuencia/amplitud reconocibles"
  (`modules/measurements/domain/spectra.py:69-72`).
- Los espectros de IPSA son **imágenes** exportadas del software de SKF
  (gráficos de cascada, 1908×663), no CSV. Es el caso normal, no el raro.
- El tipo "cascada" no existe: `Spectrum.TYPES` tiene velocidad, envolvente,
  aceleración, demodulación y forma de onda.
- El comentario es un `TextInput` de una línea (`SpectraPage.tsx:122-133`); los
  hallazgos de los informes ocupan varias frases.
- Cada tarjeta lleva el campo editable siempre abierto.

**Qué hacer**

- Front, formulario de importación: dos entradas separadas y opcionales,
  **Captura (imagen)** y **Datos (CSV)**; al menos una. La imagen se sube como
  `MediaAsset` y se enlaza por `image`. Texto de ayuda: "Sube la imagen que
  exporta el software, el CSV, o ambos".
- Back: si llega un fichero de imagen en `data`, responder "Eso es una imagen:
  súbela como captura", no el error del parser.
- Datos: tipo `waterfall` ("Cascada").
- Front, tarjetas: compactas (miniatura, punto, tipo, fecha, primera línea del
  comentario). Clic → panel de detalle con la imagen grande, la curva si hay
  datos, y los campos editables: comentario en `textarea` de varias líneas,
  tipo, RPM, diagnóstico.
- Mismo patrón en las galerías de fotos (`media/ui/MediaGallery.tsx:114-126`,
  y la galería por equipo): hoy cada foto lleva su pie editable siempre
  abierto debajo. La cuadrícula muestra solo miniaturas; el pie y los detalles
  se editan en el panel que abre el clic.

**Criterios de aceptación**

- **AC-01** Dado un PNG exportado del software SKF, cuando se sube como captura
  sin CSV, entonces se crea el espectro y se ve la imagen.
- **AC-02** Dado un PNG puesto por error en el campo de datos, cuando se
  importa, entonces el mensaje dice que es una imagen y cómo subirla.
- **AC-03** Dado un espectro, cuando se hace clic en su tarjeta, entonces se
  abre el detalle con el comentario en un campo de varias líneas.
- **AC-04** Dado un comentario de tres párrafos, cuando se guarda y se vuelve a
  abrir, entonces conserva los saltos de línea.
- **AC-05** Dada la lista de espectros, cuando no se ha hecho clic en ninguno,
  entonces no hay campos editables a la vista.
- **AC-06** Dado el registro fotográfico de una visita, cuando se abre,
  entonces se ven solo miniaturas; al hacer clic en una se abre con su pie
  editable.
