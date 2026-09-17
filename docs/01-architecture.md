# 01 — Arquitectura

Dos repos, un contrato. `predictive-back` (Python) expone la API;
`predictive-front` (React) la consume. Ninguno de los dos sabe nada del interior
del otro más allá del contrato OpenAPI generado.

```
┌─ predictive-front ─────────┐      ┌─ predictive-back ───────────────────────┐
│ React 19 + TS + Vite       │      │ Django 5 + DRF  (API, ORM, permisos)    │
│ Redux Toolkit + RTK Query  │─────▶│ Celery + Redis  (cron, ingesta, IA)     │
│ registro de módulos        │ HTTP │ PostgreSQL 16 + TimescaleDB (series)    │
│ Tailwind + shadcn/ui       │ JWT  │ S3 / MinIO      (imágenes, espectros)   │
└────────────────────────────┘      └─────────────────────────────────────────┘
                                                   │
                                    ┌──────────────┴───────────────┐
                                    │ predictive-ml (fase 3, FastAPI)│
                                    │ inferencia espectros + visión │
                                    └───────────────────────────────┘
```

---

## 1. Por qué Django y no FastAPI

La petición deja elegir. Se elige **Django 5 + DRF**, y la razón es T2.

Un sistema con "instalación de módulos tipo SAP/Odoo" necesita, el día 1:
migraciones versionadas e independientes por módulo, un modelo de permisos
granular ya resuelto, un ORM con integridad referencial fuerte sobre una
jerarquía de 7 niveles, y admin para el arranque. Django trae las cuatro cosas;
`INSTALLED_APPS` **ya es** un registro de módulos, y las `AppConfig` son
literalmente manifiestos. Con FastAPI habría que construir migraciones por
módulo, RBAC y registro a mano — trabajo que no diferencia al producto.

FastAPI gana en un solo eje: servir inferencia de modelos con `async` y
sobrecarga mínima. Por eso ese trozo **sale a un servicio aparte** (`predictive-ml`)
en fase 3, y el core no paga por ello. Django habla con él por HTTP a través de
un puerto (`InferencePort`), igual que habla con S3.

Sobre el "futuro LLM con imágenes": el cuello de botella no es el framework web
sino el pipeline de datos — etiquetado, trazabilidad imagen↔punto↔falla, y
volumen. Eso se resuelve en el modelo de datos (§ doc 02 y 05), no en el
framework HTTP.

## 2. Hexagonal en Django sin pelearse con Django

La trampa clásica es escribir hexagonal "puro" y acabar reimplementando el ORM.
La regla aquí es concreta:

```
modules/<módulo>/
├── manifest.py                 # metadatos del módulo (T2)
├── domain/                     # PYTHON PURO. cero imports de django
│   ├── entities.py             #   dataclasses inmutables
│   ├── value_objects.py        #   Measurement, Threshold, Unit, Tag…
│   ├── services.py             #   reglas: evaluar estado, calcular tendencia
│   ├── ports.py                #   Protocol: repositorios y gateways
│   └── errors.py
├── application/                # casos de uso. orquesta domain + ports
│   ├── use_cases/
│   └── dto.py
├── infrastructure/             # Django vive aquí y solo aquí
│   ├── models.py               #   ORM
│   ├── repositories.py         #   implementan domain/ports.py
│   ├── mappers.py              #   ORM ⇄ entidad de dominio
│   └── tasks.py                #   Celery
├── interfaces/                 # HTTP
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── permissions.py
└── migrations/
```

Qué se permite y qué no:

| | Puede importar |
|---|---|
| `domain` | solo stdlib y otros `domain` |
| `application` | `domain` |
| `infrastructure` | `domain`, `application`, Django |
| `interfaces` | `application`, `domain` (DTOs), DRF |

La dirección de dependencias se verifica en CI con **import-linter**, no con
buena voluntad. Un `from django...` dentro de `domain/` rompe el build.

**Dónde se relaja a propósito:** las consultas de listado/paginación van directas
del `interfaces` al ORM vía repositorios de lectura (CQRS pobre). Meter cada
listado en un caso de uso y mapear 5 000 filas a dataclasses es puro coste. Las
**escrituras y las reglas** sí pasan siempre por `application` → `domain`.

## 3. El registro de módulos (T2)

Odoo/SAP dan tres cosas: manifiesto con dependencias, ciclo de vida
(instalar/actualizar/desinstalar) y datos de arranque por módulo. Se replican
las tres.

```python
# modules/vibration/manifest.py
MANIFEST = Manifest(
    code="vibration",
    name="Análisis de vibraciones",
    version="1.0.0",
    depends=["core", "assets", "services", "thresholds", "media"],
    category="Análisis predictivo",
    provides_measurement_techniques=["vibration"],
    menu=[MenuItem(label="Vibraciones", route="/vibration", icon="waveform", order=30)],
    permissions=["vibration.view_reading", "vibration.add_reading", "vibration.diagnose"],
    settings_schema=VibrationSettingsSchema,
    data_fixtures=["iso_10816_3.yaml", "point_templates.yaml"],
    on_install=seed_iso_limits,
    on_upgrade=migrate_limits,
)
```

**La honestidad técnica aquí importa:** Django no puede añadir apps a
`INSTALLED_APPS` en caliente sin reiniciar el proceso. Así que:

- Todos los módulos descubiertos se **cargan** siempre (sus tablas existen, sus
  migraciones corren).
- Lo que se **instala** es un estado en base de datos (`InstalledModule`:
  `uninstalled | installed | to_upgrade`).
- Ese estado **cierra** las URLs (router dinámico), los permisos, el menú que
  devuelve `/api/v1/session/bootstrap`, y las suscripciones a eventos.
- Instalar/desinstalar es una llamada API + Celery task; el front recarga su
  registro y el menú cambia. Sin reinicio.

Efecto práctico: un módulo desinstalado es invisible y no autoriza nada, pero sus
datos siguen ahí y reinstalar no pierde histórico. Para un ERP de mantenimiento
eso es lo correcto — desinstalar termografía no puede borrar 3 años de tomas.

Desinstalar un módulo del que otro depende se rechaza con el árbol de
dependencias en el error, igual que Odoo.

## 4. Eventos internos

El reporte, el KPI de planta y el recálculo de estado no pueden vivir en el
controlador que guarda una lectura. Bus de eventos en proceso (síncrono) +
Celery (asíncrono) con el mismo contrato:

```
ReadingRecorded        → evaluar umbrales → EquipmentStatusChanged
EquipmentStatusChanged → recalcular KPI de área → notificar
ServiceCompleted       → generar borrador de reporte → recalcular cumplimiento de plan
MediaUploaded          → extraer EXIF → encolar derivadas
ModuleInstalled        → sembrar fixtures → invalidar bootstrap del front
```

Un módulo nuevo se suscribe; no edita el caso de uso ajeno. Es lo que hace que
añadir "análisis de aceite" (§ doc 00 §6) no toque nada de lo ya escrito.

## 5. Series temporales

Las lecturas escalares (T4/T5/T7/T8) van a una tabla `measurement_reading`
convertida en **hypertable de TimescaleDB**, particionada por tiempo y
`company_id`. Motivo: la consulta dominante es "valor de estos 4 puntos × 5
magnitudes durante 3 años" — exactamente la matriz de `TABLA DE TENDENCIAS`.
Con Timescale eso es un `time_bucket` y una `continuous aggregate` para las
medias mensuales que alimentan los gráficos de tendencia.

Los **espectros** no van a Postgres. Van a S3 en Parquet (`freq[]`, `amp[]`,
metadatos de captura) con una fila de índice en Postgres. Un espectro de 6 400
líneas son 100 KB en Parquet y 0 filas de tabla.

Si Timescale no está disponible en el hosting objetivo, la tabla funciona igual
como tabla particionada nativa de Postgres; el repositorio no cambia.

## 6. Multi-tenant

`Company` (cliente) es la raíz. Todo modelo lleva `company_id`, todo queryset
pasa por un manager que lo filtra a partir del contexto de request, y hay
`RowLevelSecurity` en Postgres como segunda barrera. Un usuario pertenece a una
o varias compañías con rol por compañía (`Membership`), igual que el patrón de
`AccountUser` que ya conoces de Chatwoot.

## 7. Frontend: la misma modularidad, del otro lado

```
src/
├── app/                    # store, router raíz, providers, layout
│   ├── store.ts            #   configureStore + reducer injection
│   ├── moduleRegistry.ts   #   espejo de T2 en el cliente
│   └── api/baseApi.ts      #   RTK Query base, un solo cliente
├── shared/                 # design system, hooks, utils, tipos generados
└── modules/
    └── vibration/
        ├── index.ts            # export default: ModuleDefinition
        ├── domain/             # tipos + reglas puras (mismas que el back)
        ├── application/        # hooks de caso de uso, selectores
        ├── infrastructure/     # endpoints RTK Query (injectEndpoints)
        └── ui/                 # páginas y componentes
```

Cada módulo exporta un `ModuleDefinition` con `routes`, `menu`, `reducer`,
`endpoints` y `requiredPermissions`. En arranque el front pide
`/api/v1/session/bootstrap`, recibe **qué módulos están instalados y qué permisos
tiene el usuario**, y monta solo esos: `store.injectReducer()` y
`api.injectEndpoints()` de los módulos activos, rutas con `React.lazy`. Un módulo
desinstalado no descarga ni un byte de su chunk.

Estado: **RTK Query para todo lo del servidor** (que es el 90 %: es un ERP, no un
editor). Redux "clásico" con slices solo para estado de sesión, preferencias de
UI, filtros persistentes, y la cola de subida de imágenes. Regla dura: **si el
dato vive en el servidor, no se copia a un slice**. Ahí es donde mueren los
frontends de ERP.

Sobre "actions/reducers limpios": con RTK son `createSlice` (sin boilerplate de
action types) y `createEntityAdapter` para colecciones normalizadas. Los `thunks`
explícitos solo donde hay orquestación real (subida por lotes con reintento).

## 8. Rendimiento: las tres decisiones que lo deciden todo

1. **Nunca servir imágenes desde Django.** Subida directa a S3 con URL
   prefirmada, descarga por CDN. Django solo firma y registra (doc 05).
2. **Listados virtualizados y paginación por cursor.** El RGP son 1 086 filas de
   un tirón y crecerá; TanStack Virtual + cursor, nunca `offset` sobre tablas de
   series.
3. **Agregados precalculados.** El estado de un área y el semáforo de planta se
   leen de una vista materializada refrescada por evento, no se calculan en la
   request.

Sin modo offline: no hay cobertura en planta, así que la captura ocurre en
oficina contra la API. Lo que sí se conserva es la idempotencia por lote — una
digitación de una ronda que se corta no puede duplicar al reintentar.

## 9. Bilingüe (español / inglés)

Dos mecanismos, porque hay dos clases de texto:

**Interfaz.** i18next con un namespace por módulo; cada módulo lleva sus
`locales/{es,en}.json` dentro de su propio chunk. Un módulo desinstalado no
descarga ni sus pantallas ni sus textos. El registro se hace en el mismo punto
donde se inyectan reducers y endpoints (`ModuleDefinition.translations`).

**Catálogo.** Los nombres de estados, técnicas, magnitudes, normas y modos de
falla **son datos**: el cliente añade los suyos desde la pantalla. Viven en una
columna `translations` JSONB de la propia fila (`TranslatableModel`), se
resuelven en el servidor con `request.language` y llegan al front ya
traducidos. Por eso cada petición lleva `X-Language` y cambiar de idioma
invalida las cachés de catálogo.

Cadena de resolución, la misma en los dos lados:

```
cabecera X-Language → Accept-Language → preferencia del usuario
                    → idioma de la empresa → es
```

Un idioma no soportado **no** cae al valor por defecto en mitad de la cadena:
devuelve "nada" y deja que siga el siguiente candidato. Si no, la preferencia
de la empresa nunca se aplicaría.

Números y fechas van siempre por `Intl`. Ojo con lo que parece obvio: **`es-PE`
escribe `1,234.50` igual que `en-US`; el que escribe `1234,50` es `es-ES`**.

## 10. Testing y calidad

- `domain/` y `application/`: pytest puro, sin base de datos. Es el 70 % de los
  tests y corre en segundos.
- `infrastructure/`: pytest-django con Postgres real (testcontainers).
- Contrato: OpenAPI generado por drf-spectacular → tipos TS con
  `openapi-typescript`. **El front no escribe tipos de API a mano**, los importa
  generados; si el back rompe el contrato, el build del front falla.
- CI: ruff + mypy (estricto en `domain/`) + import-linter + pytest + vitest +
  playwright en los flujos críticos (toma de datos, subida masiva, reporte).
