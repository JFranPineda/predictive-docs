# 05 — Pipeline de imágenes (R4)

El requisito: ingesta masiva desde móvil, en formato de móvil, convertida por un
cron de medianoche a un formato ligero, sin que el sistema se sature.

## 1. El formato X del enunciado

El formato que usan los móviles hoy es **HEIC/HEIF** (iPhone, y Samsung/Pixel en
modo alta eficiencia). Android por defecto sigue dando **JPEG**. Un tercer caso
real aquí: la cámara termográfica da **JPEG radiométrico** (FLIR) o **TIFF**.

Se aceptan los cuatro en entrada. Conversión de salida:

| | formato | por qué |
|---|---|---|
| Principal | **AVIF** | ~50 % del peso de JPEG a igual calidad percibida. Soportado por Chrome/Edge/Firefox/Safari 16+. |
| Respaldo | **WebP** | para el navegador viejo que se cruce. Se genera solo si `Accept` lo pide. |
| Miniaturas | AVIF 256 px y 1024 px | grillas y galerías nunca descargan la grande |

Números reales para esta carga: foto de móvil HEIC 3–5 MB → AVIF 1024 px
≈ 120–250 KB, miniatura 256 px ≈ 15–25 KB. **Reducción ~95 %** en la imagen que
el usuario ve en un listado. Los ~100 GB/año/planta estimados en doc 00 §7 se
convierten en ~5 GB de derivadas calientes.

## 2. Por qué el original no se borra

La conversión a AVIF es con pérdida. Si el sistema va a entrenar un modelo de
visión (objetivo declarado de R2), tirar los originales es destruir el dataset
antes de tenerlo. Política:

```
originals/    clase estándar → tras 30 días → clase infrecuente → tras 365 → archivo
derivatives/  clase estándar, servidas por CDN, regenerables en cualquier momento
```

El coste de archivo es del orden de 1 USD/TB/mes. Es más barato que volver a
tomar 2 200 fotos.

## 3. Subida: nunca a través de Django

```
Front                          Back                        S3/MinIO
  │ POST /media/upload-batch/     │                            │
  │  {items:[{filename,size,sha256,owner,kind}]}               │
  │──────────────────────────────▶│                            │
  │                               │ dedupe por sha256          │
  │                               │ crea MediaAsset(pending)   │
  │◀── {asset_id, presigned_put, skip:false} ──┤               │
  │                                                            │
  │ PUT binario (directo, multipart si >8 MB) ─────────────────▶│
  │                                                            │
  │ POST /media/{id}/complete/    │                            │
  │──────────────────────────────▶│ verifica HEAD + tamaño     │
  │                               │ publica MediaUploaded      │
```

Puntos que hacen que esto aguante una cuadrilla subiendo 2 000 fotos:

- **Deduplicación por SHA‑256 antes de subir.** La foto ya subida devuelve
  `skip: true` y no viaja. En campo se repiten fotos más de lo que parece.
- **Cola en el cliente** con concurrencia 3–4, reintento exponencial, y
  persistencia en IndexedDB: si el técnico cierra el navegador o pierde
  cobertura, la cola sigue donde estaba.
- **Multipart** para lo grande; una foto HEIC de 5 MB va de una pieza.
- El backend nunca toca el byte. Una instancia pequeña de Django aguanta miles
  de firmas por minuto porque solo firma.

## 4. El cron de medianoche

```python
# celery beat
"convert-media-nightly":  crontab(hour=0, minute=15)   # 00:15 hora de la planta
"prune-originals":        crontab(hour=3, minute=0)
"refresh-plant-kpis":     crontab(minute="*/15")
```

`convert_media_nightly` toma los `MediaAsset` en `pending`, los reparte en lotes
de 50 a una cola dedicada (`media`) con workers propios, y para cada uno:

```
descargar original → extraer EXIF y GPS → (si termográfico: extraer matriz radiométrica)
 → autorrotar por EXIF → AVIF 2048 q=50 · AVIF 1024 q=55 · AVIF 256 q=60
 → subir derivadas → actualizar derivatives{} → processing_state=done
```

Con `pillow` + `pillow-heif` + `pillow-avif-plugin`. Una foto tarda ~0,5–1,5 s de
CPU; 2 200 fotos son ~20–40 min en 4 workers. Entra de sobra en la ventana
nocturna.

### Sin broker también corre

El trabajo vive en `modules/media/infrastructure/conversion.py`, no dentro de la
tarea. La tarea de Celery, el `beat` y el comando de consola son tres llamadas a
lo mismo:

```bash
./.venv/bin/python manage.py tenants run <cliente> media_convert --limit 500
./.venv/bin/python manage.py tenants run <cliente> media_convert --retry-failed
```

Una instalación de un servidor no tiene Redis, y unas miniaturas que dependen de
que un broker esté levantado no son miniaturas. Una línea de cron hace el mismo
trabajo.

**El codificador se degrada solo.** AVIF es lo que pide el requisito, pero
`pillow-avif-plugin` es una dependencia opcional: si no está, se escribe WebP,
que es la mitad de la ganancia y está siempre disponible. Una derivada que no
existe le cuesta al navegador el original entero, que es mucho peor que un WebP.

**Pero el cron no puede ser lo único.** Si un técnico sube fotos a las 10:00 y
las quiere ver en el reporte a las 11:00, esperar a medianoche es inaceptable.
Solución de dos velocidades:

- **Al subir, síncrono y barato:** una miniatura de 256 px generada en el momento
  (o en el propio navegador antes de subir, que es gratis para el servidor). El
  usuario ve su galería al instante.
- **De noche, el trabajo caro:** derivadas completas, recompresión, limpieza del
  original, EXIF profundo, hash perceptual.

El enunciado pedía el cron; esto lo cumple y además evita que el sistema "se vea
lento" durante el día, que era la intención real del requisito.

## 5. Termografía: la excepción que hay que respetar

Un JPEG radiométrico FLIR lleva **la matriz de temperaturas embebida** en
metadatos propietarios. Convertirlo a AVIF la destruye y el termograma pasa a ser
una imagen bonita sin datos.

```
termograma → extraer matriz (modules/media/domain/flir.py) → rejilla cruda en el store
           → guardar emisividad, T reflejada y constantes de Planck en thermal_meta
           → el ORIGINAL nunca se degrada ni se archiva en frío
           → las derivadas son solo para previsualizar
```

El lector del segmento `APP1 FLIR` está escrito en el dominio, con la librería
estándar: recompone los trozos del segmento, recorre la tabla de tags FFF y saca
la imagen cruda (tipo 1) y la calibración (tipo 32). `temperature_at()` invierte
la curva de Planck, que es lo que permite recalcular un ΔT sin la cámara.

**Fallar no puede costar la conversión entera.** Antes esto lanzaba
`NotImplementedError` y el termograma se quedaba sin ninguna derivada. Ahora una
foto normal devuelve `radiometric: false` con el motivo en `notes`, y las
derivadas se generan igual.

Lo mismo aplica a cualquier captura que sea *dato* y no *ilustración*.

## 6. Servido

`GET /api/v1/media/{id}/url/?variant=thumb|card|full|original` devuelve una URL
prefirmada de corta vida, con `Cache-Control` largo y ETag por hash — el
navegador y el CDN cachean, la API deja de verse. La galería pide `thumb`; el
detalle pide `card`; `original` exige permiso explícito y queda en `AuditLog`.

## 6.1 Galería por equipo: miles de imágenes por máquina

Ver un año de espectros de un reductor no puede obligar a abrir visita por
visita, y tampoco puede degradarse cuando la máquina acumula diez mil imágenes.
Tres decisiones, las tres necesarias:

1. **`equipment_ref` y `captured_on` desnormalizados** en `MediaAsset`, escritos
   en la subida a partir de la visita. La galería es un recorrido de índice, no
   un join por visitas. Son enteros y no FKs porque el dueño de un asset siempre
   fue genérico (`owner_type`/`owner_id`).
2. **Índice que carga también el orden**:
   `(company, equipment_ref, kind, -created_at, -id)`. SQLite lo resuelve como
   `SEARCH ... USING COVERING INDEX`: sin paso de ordenación y sin tocar la tabla.
3. **Paginación por cursor, nunca `OFFSET`.** `OFFSET 18000` obliga a la base a
   recorrer dieciocho mil filas que va a tirar.

Medido sobre 20 000 imágenes de un solo equipo (SQLite, portátil):

| Consulta | Tiempo |
|---|---|
| Página 1 (60 filas) | 2,6 ms |
| Página 300 (fila ~18 000) por cursor | **2,3 ms** |
| La misma página por `OFFSET` | 11,2 ms |
| Conteos de los chips (`GROUP BY kind`) | 7,6 ms, sólo en la primera página |
| Visitas de una página | 1 consulta, 2,4 ms |

La página 300 cuesta lo mismo que la 1: ésa es la propiedad que se buscaba.

En el navegador, cada azulejo lleva `content-visibility: auto` con altura
reservada (`contain-intrinsic-size`) y la imagen va `loading="lazy"`: lo que está
fuera de pantalla no se maqueta ni se pinta, y añadir una página no mueve lo que
ya se está mirando. El original sólo se descarga al abrir una imagen.

## 7. Presupuesto de rendimiento (objetivos, no deseos)

| Operación | Objetivo |
|---|---|
| Listado de 50 equipos con estado | < 200 ms p95 |
| Matriz de tendencia, 4 puntos × 3 años | < 400 ms p95 |
| Galería de 200 miniaturas | < 1,5 s hasta imagen completa |
| Firma de lote de 100 subidas | < 500 ms |
| Ronda completa de 2 200 fotos convertidas | < 45 min |
| Render de PDF de reporte | < 3 s |
