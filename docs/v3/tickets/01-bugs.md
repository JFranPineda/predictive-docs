# 01 · Bugs

Lo que el cliente encontró roto usando el sistema. Todos se reprodujeron contra
el entorno local (front 5174, back 8010) antes de escribirlos.

---

## V3-01 · Las imágenes no se ven y el clic lleva al inicio de sesión

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| bug | P0 | S | front, infra | — |

**Origen**

> Informes de laboratorio y registro fotográfico del equipo: Cuando le doy clic
> me lleva al inicio de sesión base URL. No puedo visualizar la imagen.
> *(Activos)* Las imágenes no me dejan visualizarlas.

Captura 4 del Word (`/services/visits/4328#operating`): las tarjetas muestran
el texto alternativo ("jpeg", "Base y pernos de anclaje") en lugar de la foto.

**Situación actual**

El almacenamiento local devuelve URLs relativas `/media/<clave>`
(`modules/media/infrastructure/local_store.py:37-38`), pero Vite solo proxya
`/api` (`predictive-front/vite.config.ts:18`). Cualquier otra ruta la contesta
Vite con el `index.html` de la SPA:

```
GET http://127.0.0.1:5174/media/originals/1/7f/7f50…aa1a.jpg  → 200 text/html
GET http://127.0.0.1:8010/media/originals/1/7f/7f50…aa1a.jpg  → 200 image/jpeg
```

- La `<img>` recibe HTML → imagen rota.
- El enlace `<a href={asset.url} target="_blank">` (`media/ui/MediaGallery.tsx:100`)
  abre una ruta que el router no conoce → la SPA redirige al inicio.
- Por el túnel de cloudflared pasa lo mismo, porque solo se tunela el front.

Afecta a todo lo que muestra un fichero: informes de laboratorio, registro
fotográfico, galería por equipo (`/assets/:id/media`) y miniaturas de espectros.

En producción el problema cambia de forma pero no desaparece: `config/urls.py:29`
solo sirve `/media/` con `DEBUG=1`, así que con `DEBUG=0` hace falta que el
proxy inverso sirva esa ruta.

**Qué hacer**

- Front: añadir `/media` al `proxy` de `vite.config.ts`, con el mismo destino
  que `/api` (`VITE_API_PROXY`).
- Infra: documentar en `docs/07-deployment.md` la `location /media/` del proxy
  inverso para el modo `local` (en modo `s3` las URLs ya son prefirmadas).
- Revisar que el enlace abra la imagen original y no una ruta de la SPA.

**Criterios de aceptación**

- **AC-01** Dado un informe de laboratorio subido a una visita, cuando se abre
  `/services/visits/<id>#operating` desde `http://127.0.0.1:5174`, entonces se
  ve la miniatura.
- **AC-02** Dado lo anterior, cuando se hace clic en la miniatura, entonces se
  abre la imagen original en otra pestaña y la sesión sigue abierta en la
  pestaña de origen.
- **AC-03** Dado el sistema expuesto por `cloudflared` (solo el front), cuando
  se abre la galería de un equipo, entonces se ven las miniaturas.
- **AC-04** Dado un PDF de laboratorio, cuando se hace clic, entonces se abre o
  se descarga el PDF, no la SPA.

**Nota de seguridad**: `/media/` se sirve sin autenticación. Las claves son el
SHA-256 del contenido, así que no se pueden adivinar, pero una URL copiada
funciona para cualquiera. Para fotos de planta de un cliente probablemente
baste; si no, el paso siguiente es servir a través de un endpoint autenticado o
con URLs firmadas también en modo local.

---

## V3-02 · No se puede eliminar una imagen

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| bug | P0 | S | back, front | V3-01 (para ver qué se borra) |

**Origen**

> Informes de laboratorio y registro fotográfico del equipo: No puedo eliminar
> la imagen.

**Situación actual**

Tres causas que se suman:

1. **Permiso**: el botón ✕ se muestra cuando la visita es editable
   (`services/ui/VisitDetailPage.tsx:341-384` pasa `canEdit={data.can_edit}`),
   pero el backend exige `media.delete` (`modules/media/interfaces/views.py:120-123`).
   En la base de AMBEV solo `company_admin` tiene ese permiso; `engineer`,
   `technician`, `external_inspector` y `tecnico_campo` tienen `media.view` y
   `media.upload`. Carlos Balta (ingeniero) ve el botón y el servidor le
   contesta 403.
2. **Error silenciado**: `onClick={() => void remove(asset.id)}`
   (`media/ui/MediaGallery.tsx:130`) descarta la respuesta; el 403 no se
   muestra y la foto sigue ahí sin explicación.
3. **Botón invisible en pantalla táctil**: `hidden … group-hover:block`
   (`MediaGallery.tsx:133`). En tablet o móvil no hay hover, así que el botón
   nunca aparece.

**Qué hacer**

- Back: permitir borrar a quien subió la foto mientras la visita esté abierta,
  con la misma regla que ya protege las lecturas (comportamiento del rol +
  autor + visita no cerrada). `media.delete` sigue permitiendo borrar siempre.
  Registrar el borrado en la auditoría.
- Back: devolver en el payload de cada imagen si el usuario actual puede
  borrarla (`can_delete`), en lugar de que el front lo deduzca.
- Front: mostrar el botón según `can_delete`, siempre visible (no solo en hover),
  con confirmación, y mostrar el error si el servidor lo rechaza.

**Criterios de aceptación**

- **AC-01** Dado un ingeniero que subió una foto a una visita abierta, cuando
  pulsa eliminar y confirma, entonces la foto desaparece y queda una línea en
  `/settings/audit`.
- **AC-02** Dado un ingeniero y una foto subida por otra persona, cuando abre la
  visita, entonces no ve el botón de eliminar.
- **AC-03** Dado un usuario sin permiso que fuerza la petición, cuando el
  servidor responde 403, entonces la pantalla muestra el motivo.
- **AC-04** Dado un iPad, cuando se abre la galería con permiso de borrar,
  entonces el botón es visible sin pasar el ratón.
- **AC-05** Dada una visita cerrada, cuando un técnico abre la galería,
  entonces no puede borrar ninguna foto.

**Pregunta abierta**: Q14 del índice (quién puede borrar).

---

## V3-03 · Editor de tipos de conjunto: "El punto 1H está repetido" y plantillas descuadradas

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| bug | P0 | M | back, front, datos | — |

**Origen**

Captura 1 del Word (`/settings/group-kinds`): al editar "Equipo Desacoplado"
con los componentes *Tren de Transm. MP3 (Motor, 2 puntos)* y *Chumaceras
(Chumacera, 22 puntos)*, el guardado falla con "El punto 1H está repetido".

> Word: motor - compresor solo tiene 4 puntos […] ¿por qué? ¿Cómo se configura?

**Situación actual**

Lo que se ve en la base de AMBEV:

```
kind  componentes (point_count)              filas de plantilla  conjuntos que lo usan
2     MOTOR 2 + COMPRESOR 2                  18 (puntos 1–6)      16
7     Tren de Transm. MP3 2 + Chumaceras 22   0                   104
```

1. **El tipo "Equipo Desacoplado" se reutilizó para un tren concreto.** Lo usan
   104 conjuntos, y alguien lo convirtió en el árbol de transmisión de la MP3
   de IPSA (los informes `#037` y `#038` numeran ese tren del 1 al 19+).
   Quedó con componentes nuevos y **sin ninguna fila de plantilla**.
2. **"+ Agregar punto" añade siempre eje H** con el número siguiente
   (`assets/ui/KindFormModal.tsx:246-257`). Para crear 1V hay que cambiar el
   número a 1 y el eje a V; si se cambia el número y no el eje, choca con 1H.
   Con 22 chumaceras son 72 filas a mano.
3. **El error no dice qué fila es.** Sale arriba del modal
   (`modules/assets/interfaces/kind_views.py:283-284`) y la fila repetida puede
   estar treinta filas más abajo.
4. **`point_count` y la plantilla no se hablan.** Cambiar el número de puntos
   de un componente no toca la plantilla; hay que pulsar "Reconstruir" a mano
   (`KindFormModal.tsx:265`). Por eso Motor-Compresor declara `COMPRESOR 2`
   pero su plantilla tiene cuatro puntos de compresor (3–6): el tipo dice
   4 puntos en total y la tabla muestra 6. Es lo que confunde a Jesús.
5. **Las magnitudes por rodamiento cuelgan de un eje distinto según el tipo**:
   en Motor-Reductor van en la fila H; en Motor-Compresor, en la fila V. El
   resultado impreso es el mismo, pero la plantilla es incoherente.

**Qué hacer**

- Front, "+ Agregar punto": añade el **punto completo** (H, V y A) con el
  siguiente número libre y el componente de la última fila.
- Front: marcar en rojo las filas en conflicto y desplazarse a la primera.
  El back devuelve el índice de la fila (`{"row": 17, "detail": "…"}`).
- Front: al cambiar `point_count` de un componente, avisar de que la plantilla
  ya no cuadra y ofrecer reconstruir solo ese componente, conservando lo editado
  en los demás.
- Back: al guardar, rechazar una plantilla en la que un componente tenga un
  número de puntos distinto de su `point_count`, con un mensaje que lo diga.
- Datos: devolver "Equipo Desacoplado" a su forma de fábrica y crear el tren
  de la MP3 como tipo propio (o cargar sus puntos en el conjunto con
  `GroupPointsModal`, que ya permite un trazado por conjunto). Poner
  `COMPRESOR` en 4 puntos y las magnitudes por rodamiento en la fila H en
  todos los tipos (lo hace V3-12).
- Ayuda en el modal: cuándo crear un tipo nuevo y cuándo ajustar los puntos
  de un solo conjunto.

**Criterios de aceptación**

- **AC-01** Dado un tipo con dos puntos de motor, cuando se pulsa "+ Agregar
  punto", entonces aparecen 3H, 3V y 3A.
- **AC-02** Dada una plantilla con dos filas 5H, cuando se guarda, entonces el
  modal marca las dos filas y el mensaje nombra el componente.
- **AC-03** Dado un componente al que se le cambia `point_count` de 2 a 4,
  cuando se intenta guardar sin reconstruir, entonces el modal avisa del
  descuadre y ofrece reconstruir ese componente.
- **AC-04** Dada la base de AMBEV corregida, cuando se abre
  `/settings/group-kinds`, entonces ningún tipo tiene cero filas de plantilla y
  todos cuadran con su `point_count`.
- **AC-05** Dado un tren de 24 puntos como el de la MP3, cuando se crea como
  tipo propio, entonces se puede guardar sin escribir fila por fila.

---

## V3-04 · Los totales de Órdenes mezclan el total con la página cargada

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| bug | P1 | S | back, front | — |

**Origen**

Encontrado al revisar la petición de totales dinámicos (V3-26).

**Situación actual**

En `services/ui/ServiceOrdersPage.tsx:150-160`, "Órdenes" usa `data.count`
(el total del servidor), pero "Visitas" y "Abiertas" suman solo las filas de la
página cargada. El listado pagina de 25 en 25
(`modules/services/interfaces/views.py`, `paginator.page_size = 25`). Hoy hay
18 órdenes y caben en una página, así que el error está latente: con la orden
26, "Visitas" y "Abiertas" dejan de cuadrar con "Órdenes".

De paso, en la misma vista:

- `open_count` hace una consulta por orden (`order.visits.filter(...).count()`).
- `closed_count=Count("visits", filter=None, …)` cuenta lo mismo que
  `visit_count` y nadie lo usa.

**Qué hacer**

- Back: devolver en la respuesta del listado un bloque `totals`
  (`orders`, `visits`, `open`) calculado sobre el queryset filtrado completo,
  no sobre la página. Anotar `open_count` con `Count(..., filter=Q(...))` y
  quitar `closed_count`.
- Front: los tres indicadores leen `totals`.

**Criterios de aceptación**

- **AC-01** Dadas 30 órdenes, cuando se abre `/services`, entonces "Visitas" es
  la suma de las visitas de las 30, no de las 25 primeras.
- **AC-02** Dado un listado de 25 órdenes, cuando se carga, entonces la vista
  hace un número de consultas que no crece con el número de órdenes.
