# Resumen del proyecto — para retomarlo en otra sesión

Sistema web tipo ERP de **mantenimiento predictivo** (vibraciones, ultrasonido,
termografía, aceite, mantenimiento). Nace de los Excel reales que el cliente
usaba, y su objetivo es reemplazarlos: si el entregable no sale del sistema, la
hoja de cálculo sigue mandando.

Estado al **2026-09-17**: sistema funcionando de punta a punta en local, con
558 equipos reales cargados. **199 tests backend · 87 frontend · 30 commits en
cada repo. Nada está pusheado.**

---

## 1. Los tres repos

| Repo | Qué es |
|---|---|
| `predictive-docs` | Los Excel originales del cliente + el blueprint (`docs/00` a `docs/08`). **Fuente de verdad del diseño.** |
| `predictive-back` | Django 5 + DRF, hexagonal, módulos instalables estilo Odoo |
| `predictive-front` | React 19 + TS + Vite + RTK Query + Tailwind 4, modular |

**Antes de tocar código, leer `docs/00-source-analysis.md` y
`docs/01-architecture.md`.** El modelo sale de los Excel del cliente, no de
suposiciones, y el doc 00 explica por qué cada decisión es como es.

---

## 2. Cómo levantarlo

```bash
# Backend (venv ya creado en el repo)
cd predictive-back
./.venv/bin/python manage.py runserver 127.0.0.1:8010

# Frontend
cd predictive-front
VITE_PORT=5174 VITE_API_PROXY=http://127.0.0.1:8010 npx vite --host 127.0.0.1
```

- Front: **http://127.0.0.1:5174** · API: **http://127.0.0.1:8010/api/docs/**
- Usuarios (contraseña `predictive2026`): `admin@simiai.pe` (administrador),
  `carlos.balta@simiai.pe` (ingeniero), `henry.tejada@contratista.pe`
  (**inspector externo**), `cliente@ambev.com.pe` (solo lectura).

```bash
# Tests
cd predictive-back  && ./.venv/bin/python -m pytest tests/unit   # 199, sin BD
cd predictive-front && npx vitest run && npx tsc --noEmit        # 87

# Resembrar desde cero
cd predictive-back
rm -f data/tenant_ambev.sqlite3
./.venv/bin/python manage.py tenants migrate ambev
./.venv/bin/python manage.py tenants run ambev seed_demo --docs ../predictive-docs
./.venv/bin/python manage.py tenants add ambev "AMBEV Perú — Planta Huachipa" \
    --url "sqlite:///data/tenant_ambev.sqlite3" --deployment on_premise
./.venv/bin/python manage.py tenants issue ambev --plan enterprise --months 12 \
    --equipment 600 --plants 2 --users 25

# Rellenar lo que seed_demo no trae: ultrasonido, aceite, multimedia y espectros.
# Es aditivo e idempotente; correrlo dos veces reporta ceros.
./.venv/bin/python manage.py tenants run ambev seed_more

# Derivadas de imagen (miniaturas y formatos web), sin Redis
./.venv/bin/python manage.py tenants run ambev media_convert
```

> ⚠️ **No usar `pkill -f "manage.py runserver"`**: el patrón coincide con la
> propia línea de comandos del shell y mata la sesión. Ya pasó dos veces.

### Datos sembrados (desde los Excel reales)

558 equipos · 3 348 puntos · 60 264 lecturas · 3 348 visitas · 6 órdenes ·
191 entradas de diario · 528 placas · 19 260 valores operativos ·
7 tipos de conjunto con 78 plantillas de punto · 12 normas · 21 juegos de
umbrales · 45 modos de falla · 8 técnicas · 9 medidas.

Con `seed_more` encima: 5 técnicas con lecturas (vibraciones, termografía,
ultrasonido, análisis de aceite, aceite dieléctrico) · 4 884 visitas ·
1 847 imágenes repartidas en 268 equipos · 432 espectros numéricos, 262 con
diagnóstico · 23 juegos de umbrales.

---

## 3. Lo que los Excel enseñaron (y que no es obvio)

Estas son las trampas del dominio. Romper cualquiera de ellas rompe el sistema
de forma silenciosa.

1. **La jerarquía real tiene 5 niveles**: Área → Sector → Conjunto Rotativo →
   Equipo → Punto. No área→equipo. Los límites y las conclusiones se emiten al
   **conjunto**; el estado y el TAG viven en el **equipo**.
2. **El TAG del cliente no es único**: `MB1141001B` aparece en el motor y en la
   bomba de EB 228. `asset_code` es obligatorio y se autogenera; `client_tag`
   es opcional.
3. **Condición ≠ disponibilidad.** `operativo/alarma/parada` se *calculan*;
   `apagado/retirado/fuera de servicio` se *declaran*. El 13 % del RGP era
   "APAGADO": mezclarlos envenena todo KPI. Y el vocabulario **cambia por
   técnica** (mantenimiento no tiene alarma; vibraciones no retira equipos).
4. **`Gs pico` ≠ `Gs pico-pico`.** La agregación es parte del criterio, no una
   etiqueta: 10 gE es *parada* en una escala y *alarma* en la otra.
5. **Una norma juzga la técnica para la que fue escrita.** NETA MTS no puede
   colgar de una magnitud de vibraciones. Validado en el dominio.
6. **Antecedentes, conclusiones y recomendaciones son líneas fechadas con
   autor**, no un campo de texto. Por eso un antecedente de 2013 convive con
   una conclusión de 2014 en el mismo reporte.
7. **Un termograma radiométrico no se recomprime nunca**: lleva la matriz de
   temperaturas en metadatos y al convertirlo se pierde el dato.
8. **"No medido" es una fila**, no una ausencia de fila. Sin eso no hay KPI de
   cobertura del plan.
9. **Una columna del registro es la orden de servicio, no un instante**: el
   motor y la bomba del mismo tren se visitan con horas de diferencia.
10. **`es-PE` escribe `1,234.50` igual que `en-US`**; el que usa coma decimal
    es `es-ES`. Nunca asumir "español = coma". Todo por `Intl`.
11. **Los componentes de un conjunto no llevan los mismos puntos**, y la
    numeración corre a lo largo del tren, no de la máquina. `docs/vibration/reports`
    trae tres formas: MOTOR 2 + REDUCTOR 4; MOTOR 2 + REDUCTOR 4 + dos
    CHUMACERAS de 2 (1→10); y CHUMACERA 1 + REDUCTOR 5. Suponer dos por máquina
    se come la mitad de un reductor sin avisar.
12. **Un tren puede llevar dos componentes del mismo tipo** (chumacera lado
    mando y lado transmisión). Emparejarlos por tipo y posición no los
    distingue: el equipo guarda su componente (`group_component`) y su orden.
13. **Los límites se resuelven por componente.** El reductor no lo juzga la
    norma del motor; por eso la sección V del reporte lista varias tablas.

---

## 4. Decisiones cerradas (y por qué)

| Decisión | Razón |
|---|---|
| Django + DRF, no FastAPI | La instalación de módulos necesita migraciones por módulo, RBAC y registro; Django los trae. FastAPI queda para `predictive-ml` en fase 3. |
| Hexagonal con `domain/` sin Django | Verificado en CI con `import-linter`. El 70 % de los tests corre sin base de datos, en segundos. |
| Módulos siempre migrados; instalar = estado en BD | Django no recarga `INSTALLED_APPS` en caliente. Desinstalar **nunca** borra histórico. |
| **Dos planos de base de datos** | `default` = nuestro plano de control (Tenant, License, LicenseEvent: 3 tablas). `tenant_<code>` = la base del cliente, puede ser on-premise (39 tablas). Sin FKs entre planos. |
| Licencia HMAC | La verificación corre en *nuestros* servidores; una clave asimétrica sería ceremonia. Degrada a solo lectura antes de bloquear. **Sin caché por proceso**: una revocación que llega "según el worker" no es una revocación. |
| Empresa e idioma en `TenantJWTAuthentication` | El middleware corre antes de que DRF valide el JWT. Un `SimpleLazyObject` con un int tampoco vale: el ORM lo rechaza como filtro. |
| Sesión: 30 min de **inactividad** | `ACCESS_TOKEN_LIFETIME=30m`, refresh rotatorio de 30 min con blacklist. El front renueva ante un 401 y reintenta. |
| i18n en **dos mecanismos** | Interfaz en JSON por módulo (i18next); catálogo (estados, normas, técnicas) en columna `translations` JSONB resuelta en el servidor — el cliente crea estados propios y ningún `.po` llega ahí. |
| Media: `local` por defecto, `s3` en producción | Una instalación de un servidor no tiene MinIO, y una función de fotos que exige levantar object storage no es una función. |
| Nada se borra si tiene historia | Áreas, equipos, umbrales y visitas con lecturas se **desactivan**. Las lecturas congelan el umbral que las juzgó. |

### Respuestas del usuario a las preguntas abiertas

- **Hosting**: VPS 8 de Contabo, Postgres propio (Timescale como extensión).
  El **disco** es el límite (~100 GB/año/planta), no la CPU → `docs/07`.
- **Offline**: no hay cobertura en planta; se digita en oficina. Fuera la PWA.
- **Instrumentos**: SEMAPI y SKF, sin límite. Manual primero; el puerto
  `ReadingImporter` ya existe y está probado, faltan los parsers CSV.
- **Multi-cliente**: sí, multitenant desde el día 1.
- **Análisis de aceite**: entra en alcance.
- **ERP del cliente**: solo anotar la OT (`client_work_order` + `external_refs`).
- **Idioma**: español e inglés, conmutables desde Configuración.

### Requisitos del usuario experto (última ronda)

- **Límites por potencia**: `MachineClass` lleva rango de kW y cimentación; la
  clase se **deriva de la placa** (ISO 10816-1 para 0–60 HP, ISO 10816-3 de
  15 kW en adelante). Una clase puesta a mano gana sobre la derivada.
- **Tableros eléctricos por ΔT** (NETA MTS), dos criterios separados: contra
  componente similar con igual carga (4/15 °C) y sobre ambiente (11/40 °C).
  Para el patio de trafos basta añadir la norma desde la UI.
- **Problemas por servicio**: 45 modos de falla con su norma y su firma, y el
  servidor rechaza uno de otra técnica.

---

## 5. Qué está construido

### Backend — 20 módulos

`core` (registro de módulos, eventos, multitenant) · `security` (roles,
permisos, alcance por área, políticas de dominio) · `licensing` (clientes,
bases on-premise, llaves) · `assets` (jerarquía, tipos de conjunto con
plantilla de puntos, importador RGP) · `nameplate` · `thresholds` (normas,
clases por potencia, estados por técnica, cascada) · `measurements` (lecturas,
registro de valores, exportación a Excel, puerto de importación) · `services`
(órdenes, visitas, ejecutantes, diario) · `diagnostics` (catálogo de fallas) ·
`operating_data` · `media` (subida, miniaturas, conversión nocturna) ·
`summaries` (semáforo) · `oil_analysis` · y los stubs `blueprints`, `reports`,
`vibration`, `ultrasound`, `thermography`.

### Frontend — 12 módulos

`assets` (lista, estructura de planta, tipos de conjunto, puntos por conjunto)
· `measurements` (registro de valores editable + exportación, tendencia) ·
`services` (órdenes, ejecución, formulario de visita completo) · `summaries`
(semáforo con filtros) · `thresholds` (normas, umbrales, estados, medidas) ·
`users` (usuarios + matriz de permisos) · `diagnostics` (selector de
problemas) · `nameplate` · `media` (galería) · `licensing` · `modules_admin` ·
`preferences` (idioma y tema).

### Funciona de punta a punta

- **Registro de valores** con la forma exacta de `TABLA DE TENDENCIAS.xls`
  (bloque por magnitud, filas agrupadas por componente y lado, columna por
  ronda), **editable en sitio**, y **exportable a Excel** con esa misma
  maqueta, sus límites vigentes y los parámetros de funcionamiento.
- **Formulario de servicio** por visita: valores, datos operativos, problemas
  identificados, capturas (espectros/termogramas/ultrasonido), registro
  fotográfico y diario.
- **Semáforo de planta**: gana el peor, lo no medido va aparte, cobertura al
  lado, uno por técnica.
- **CRUD completo**: planta → área → sector → conjunto → equipo → puntos,
  normas, umbrales, estados, medidas, unidades, usuarios, roles y permisos,
  órdenes y visitas, tipos de conjunto con su plantilla de puntos.
- **Licencia**: revocar bloquea con 402 al instante; el estado sigue
  consultable para que la UI pueda explicarlo.
- **Galería por equipo** en `/assets/:id/media`: todas las imágenes de una
  máquina, de todos sus servicios, con filtro por tipo y scroll infinito.
  Paginación por cursor sobre un índice que lleva el orden — medido con 20 000
  imágenes en un equipo, la página 300 cuesta lo mismo que la 1 (2,3 ms). Ver
  `docs/05 §6.1`.
- **Conversión de imágenes** ejecutable sin Redis
  (`manage.py tenants run <cliente> media_convert`), con las tres derivadas y el
  codificador degradando a WebP si no está el plugin AVIF.
- **Termogramas radiométricos**: el segmento `APP1 FLIR` se lee con la librería
  estándar (`modules/media/domain/flir.py`), la rejilla cruda se guarda aparte y
  la calibración queda en `thermal_meta`. Antes esto lanzaba `NotImplementedError`
  y el termograma se quedaba sin ninguna derivada.
- **Espectros numéricos**: modelo `Spectrum`, importación del CSV de SEMAPI/SKF
  y `GET /spectra/{id}/curve/` aparte del listado. Pantalla en
  `/measurements/:id/spectra`: importar CSV, ver la curva, editar el pie.
- **CRUD completo en todas las vistas.** Auditado ruta por ruta: las 11
  mutaciones que existían sin botón están cableadas (editar y borrar equipo,
  renombrar planta/área/sector/conjunto, editar orden, diario editable,
  ejecutantes, simulador de umbrales), y las operaciones que faltaban en el
  backend existen (`PATCH/DELETE` de planta y magnitud, `PATCH` de punto y de
  espectro). Tres pantallas nuevas: **instrumentos** (`/settings/instruments`,
  con aviso de calibración vencida), **modos de falla**
  (`/settings/fault-modes`) y **parámetros operativos**
  (`/settings/operating-parameters`).

> Lo que se borra con historia detrás **se desactiva y se explica**: el
> servidor responde con el conteo ("no se puede borrar: 20 088 lecturas se
> tomaron en esta magnitud") y la UI lo enseña tal cual.

- **Captura de ronda** en `/services/visits/:id/capture`: crea las lecturas de
  una visita de golpe, las gradúa al entrar y **sobrevive al reintento** —
  `Idempotency-Key` devuelve la primera respuesta en vez de duplicar la ronda.
  No es lo mismo que el registro de valores, que edita lecturas que ya existen.

> El caso de uso `RecordReadings` estaba escrito entero desde el principio y
> **ningún adaptador implementaba sus puertos**, así que no había forma de
> entrar. Al cablearlo aparecieron dos fallos que solo se ven ejecutándolo: el
> contexto de evaluación se construía sin la norma del equipo (toda lectura
> salía sin graduar), y el lote de idempotencia guardaba un conteo pero no
> *qué* lecturas produjo, así que un reintento devolvía las primeras N de la
> visita — lecturas de otra ronda. `ReadingBatch.reading_ids` lo arregla.

---

## 6. Qué falta

| Pendiente | Nota |
|---|---|
| Reporte de inspección en **PDF** | El módulo `reports` está vacío. Es el paso que cierra el círculo con `MPd-AV-N°006-13`. |
| Módulo `blueprints` (planos con puntos) | Diseñado en `docs/02 §1`, sin implementar. Es T3 del pedido original. |
| `pillow-heif` y `pillow-avif-plugin` | **No instalados en el venv**: las derivadas salen en WebP y un HEIC de iPhone no se convierte. `pip install -e ".[dev]"` no los trae; están en las deps de runtime. |
| Importador de espectros conectado a la UI | El endpoint y el parser CSV están hechos y probados; falta el botón en la visita. |
| Cifrar `Tenant.database_url` | Hoy es texto; la variable de entorno ya permite no guardarlo. |
| Versionado de `NameplateData` | Hoy es un registro por equipo. Hará falta el día que se rebobine un motor. |
| Migraciones a Postgres real | Todo probado en SQLite. Timescale/hypertables sin ejercitar. |

---

## 7. Convenciones de trabajo

- **Nunca `git push`.** Commits locales sí; el push lo decide el usuario.
- Conventional Commits en inglés, sin co-autoría ni referencias a Claude.
- Código, comentarios y nombres de fichero en **inglés**; contenido de
  documentación y textos de UI en **español** (con su traducción al inglés).
- Comentarios que dicen **por qué**, no qué. Si repite la línea, se borra.
- Tailwind puro: sin CSS propio, sin estilos en línea.
- Un módulo del front no importa el interior de otro: se habla por su `index`.
- El estado del servidor vive en RTK Query, no se copia a un slice.
- Los tipos de la API no se escriben a mano (`npm run api:types`).

---

## 8. Dónde mirar cada cosa

| Tema | Documento |
|---|---|
| Qué dicen los Excel del cliente | `docs/00-source-analysis.md` |
| Arquitectura, hexagonal, i18n | `docs/01-architecture.md` |
| Modelo de dominio, T1–T12 | `docs/02-domain-model.md` |
| Módulos y dependencias | `docs/03-module-catalog.md` |
| Endpoints | `docs/04-api-contract.md` |
| Pipeline de imágenes | `docs/05-media-pipeline.md` |
| Fases y decisiones cerradas | `docs/06-roadmap.md` |
| Despliegue en Contabo | `docs/07-deployment.md` |
| Base de datos del cliente y licencias | `docs/08-onpremise-and-licensing.md` |

Los docs se escribieron antes que parte del código y **algunas cosas
evolucionaron después**: el tipo de conjunto pasó a ser catálogo con plantilla
de puntos, la clase de máquina se deriva de la potencia, y el registro de
valores se exporta a Excel. Si un doc y el código discrepan, **manda el
código** y conviene actualizar el doc.
