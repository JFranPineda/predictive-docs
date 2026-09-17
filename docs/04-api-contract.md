# 04 — Contrato de API

`/api/v1/`, JWT (access 15 min, refresh rotatorio 30 días), paginación por
cursor, `X-Company-Id` cuando el usuario pertenece a varias compañías.
OpenAPI generado con drf-spectacular; el front tipa desde ahí y no a mano.

## Convenciones

- Recursos en plural y en inglés; el idioma de la UI lo pone el front.
- Filtros por query string (`?area=12&status=alarm&from=2014-01-01`).
- Errores `application/problem+json`: `{type, title, status, detail, errors[]}`.
- Escrituras con `Idempotency-Key` en ingesta de lecturas y media.
- Todo listado soporta `?fields=` para recortar payload.
- **`X-Language: es|en`** en cada petición. El texto de catálogo (estados,
  técnicas, normas) se sirve **ya traducido**; la interfaz se traduce en el
  cliente. La respuesta devuelve `Content-Language`.

## Sesión y módulos

```
POST   /auth/login/                      → {access, refresh, user, companies[]}
POST   /auth/refresh/
GET    /session/bootstrap/               → {user, company, permissions[], modules[], menu[], settings}
GET    /modules/                         → catálogo con estado y dependencias
POST   /modules/{code}/install/
POST   /modules/{code}/uninstall/
POST   /modules/{code}/upgrade/
GET    /modules/{code}/settings/  · PUT

PUT    /users/me/language/             {"language": "es"|"en"}
GET    /languages/                     idiomas disponibles y el de la empresa
PUT    /companies/{id}/language/       idioma por defecto de la compañía
```

`bootstrap` es **una sola llamada** y es lo que monta el front entero. Cachea con
ETag; se invalida con `ModuleInstalled` o cambio de permisos.

## Activos

```
GET    /plants/ · /areas/ · /sectors/ · /asset-groups/ · /equipments/
GET    /equipments/{id}/                  ficha completa
GET    /equipments/{id}/points/
GET    /equipments/{id}/nameplate/        · PUT (crea versión nueva)
GET    /equipments/{id}/blueprint/        plano vigente + anotaciones
GET    /equipments/{id}/timeline/         diario fechado (doc 02 §7)
GET    /equipments/{id}/trend/?magnitude=vel_rms&from=&to=&points=1H,2H
POST   /equipments/import/                Excel RGP → preview → confirm
GET    /areas/{id}/health/                semáforo agregado
```

## Medición

```
POST   /service-visits/{id}/readings/bulk/   ← la toma de datos de campo, un POST por punto-visita
GET    /readings/?point=&magnitude=&from=&to=
GET    /points/{id}/history/
POST   /spectra/                             metadatos + presigned para parquet/imagen
GET    /spectra/{id}/                        + frecuencias de falla calculadas
POST   /spectra/import/                      fichero de instrumento → parseo
GET    /importers/                           instrumentos soportados (SEMAPI, SKF…)
POST   /imports/                             sube el CSV/XLS del instrumento →
                                             previsualización, emparejado de puntos
POST   /imports/{id}/confirm/                lo carga como servicio realizado
GET    /matrix/?asset_group=&from=&to=       la matriz punto × fecha completa
```

`readings/bulk/` acepta el lote entero de un equipo (4 puntos × 5 magnitudes +
operativos + estado de disponibilidad) en una transacción, con
`Idempotency-Key` — porque en campo la conexión se cae a mitad y el técnico
reintenta.

## Estados, normas y umbrales (T12)

```
GET    /statuses/?kind=condition|availability   · POST · PATCH   (color incluido)
GET    /technique-profiles/          qué estados ofrece cada técnica
PUT    /technique-profiles/{code}/   reordenar, añadir o quitar estados

GET    /standards/ · POST · PATCH                  Configuración global > Normas
GET    /standards/{code}/machine-classes/ · POST
PUT    /equipments/{id}/standard/                  asignar norma + clase de máquina

GET    /threshold-sets/?scope=&magnitude=&aggregation=&standard=
POST   /threshold-sets/                            crea versión, no edita en sitio
POST   /threshold-sets/{id}/simulate/              cuántos equipos cambiarían
POST   /threshold-sets/{id}/apply-recalculation/   recálculo auditado
GET    /equipments/{id}/effective-thresholds/      la cascada ya resuelta, con el
                                                   porqué de cada elección
```

`aggregation` es parte del filtro: `env_accel` en `Gs pico` y en `Gs p-p` son
dos criterios distintos y los dos se sirven.

## Servicios

```
GET    /service-plans/ · /service-orders/ · /service-visits/
GET    /service-visits/authorship/?equipment=&technique=&performed_by=&from=&to=
GET    /service-visits/{id}/authorship/      quién lo hizo + notas/conclusiones/
                                             recomendaciones, cada una con su autor
POST   /service-visits/{id}/participants/    añadir un segundo ejecutante
POST   /service-visits/{id}/close/
POST   /service-orders/{id}/start/ · /complete/
GET    /schedule/?year=2026&plant=1               vista cronograma
GET    /schedule/compliance/                       plan vs ejecutado
GET    /field/route/?service_order=              paquete offline de la ruta
```

## Media

```
POST   /media/upload-batch/       → presigned + dedupe
POST   /media/{id}/complete/
GET    /media/?owner_type=&owner_id=&kind=
GET    /media/{id}/url/?variant=thumb|card|full|original
DELETE /media/{id}/
```

## Informes (semáforo)

```
GET    /summaries/plant/?plant=&technique=&from=&to=
       → [{technique_code, technique_name, generated_at, nodes:[SummaryNode]}]
         SummaryNode = {key, label, level, total, evaluated, coverage,
                        worst:Status, counts:[{status, count}], children:[...]}
GET    /summaries/plant/export/?format=xlsx|pdf
```

Cada nodo trae su color desde el estado, y `coverage` al lado: un área verde con
cobertura baja es un problema de plan, no de salud.

## Análisis de aceite

```
GET    /oil/samples/?equipment=&technique=oil_analysis|insulating_oil
POST   /oil/samples/                  toma de muestra en campo
PUT    /oil/samples/{id}/results/     resultados del laboratorio
GET    /oil/parameters/?technique=    catálogo traducido
```

## Diagnóstico y reportes

```
GET    /fault-modes/
POST   /log-entries/                  nota / observación / hallazgo / conclusión /
                                      recomendación, siempre con visita y autor
GET    /recommendations/?status=open&area=
POST   /reports/                      desde una orden de servicio
GET    /reports/{id}/                 · POST /reports/{id}/issue/
GET    /reports/{id}/pdf/
GET    /plant-narrative/?plant=&from=&to=   el RGP generado
```
