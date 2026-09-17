# predictive-docs

Fuentes originales del cliente y **blueprint** del sistema de mantenimiento
predictivo. Este repo no tiene código: define qué se construye en
[`predictive-back`](../predictive-back) y [`predictive-front`](../predictive-front).

## Fuentes

| Fichero | Qué es |
|---|---|
| `VIBRACION 2014 AMBEV.xls` · `… - JUNIO.xls` | Maestro de equipos (RGP), 558 equipos, AMBEV Huachipa |
| `TABLA DE TENDENCIAS.xls` | Histórico de 13 tomas de un equipo (EB 228) |
| `MPd-AV-N°006-13-EB P-757 - C.E.C.1.xls` | Reporte de inspección completo (canónico) |
| `111.ETEI - Soplador # 01..xls` | Plantilla de reporte vibracional |
| `2CRONOGRAMA SERVICIOS AMBEV HUACHIPA MPd 2014.xlsx` | Cronograma anual de servicios |

## Documentos

| Doc | Contenido |
|---|---|
| [00 — Análisis de las fuentes](docs/00-source-analysis.md) | Qué dicen realmente los Excel. Leer primero. |
| [01 — Arquitectura](docs/01-architecture.md) | Stack, hexagonal, registro de módulos, series, front |
| [02 — Modelo de dominio](docs/02-domain-model.md) | Entidades, T1–T12 en tablas |
| [03 — Catálogo de módulos](docs/03-module-catalog.md) | Módulos, dependencias, manifiestos, ciclo de vida |
| [04 — Contrato de API](docs/04-api-contract.md) | Endpoints `/api/v1/` |
| [05 — Pipeline de imágenes](docs/05-media-pipeline.md) | R4: ingesta masiva, conversión nocturna, termogramas |
| [06 — Roadmap](docs/06-roadmap.md) | Fases, decisiones tomadas e i18n |
| [07 — Despliegue](docs/07-deployment.md) | VPS Contabo, Postgres propio, dimensionado, backups |
| [08 — On premise y licencias](docs/08-onpremise-and-licensing.md) | Base de datos del cliente, plano de control, llave |

## Trazabilidad

| Req | Dónde |
|---|---|
| T1 usuarios y permisos | doc 02 §9 · módulo `security` |
| T2 instalación de módulos | doc 01 §3 · doc 03 §4–5 |
| T3 planos con puntos | doc 02 §1 · módulo `blueprints` |
| T4 vibraciones | doc 02 §2–3 · módulo `vibration` |
| T5 datos operativos | doc 02 §6 · módulo `operating_data` |
| T6 datos nominales | doc 02 §6 · módulo `nameplate` |
| T7 ultrasonido | módulo `ultrasound` |
| T8 termografía | módulo `thermography` · doc 05 §5 |
| T9 áreas | doc 02 §1 · módulo `assets` |
| T10 equipos por área | doc 02 §1 · módulo `assets` |
| T11 servicios por fecha | doc 02 §5 · módulo `services` |
| T12 umbrales, estados y normas | doc 02 §4 · módulo `thresholds` |
| Inspectores externos y autoría del servicio | doc 02 §5 y §9 · módulos `security`, `services` |
| Informes / semáforo de planta | doc 02 §10 · módulo `summaries` |
| Análisis de aceite | módulo `oil_analysis` |
| Importación desde instrumento | doc 04 · puerto `ReadingImporter` |
| Español e inglés | doc 06 §i18n |
| Despliegue | doc 07 |
| Base de datos del cliente (on premise) | doc 08 |
| Licencia / llave del servicio | doc 08 §4 |
| R1 front React modular | doc 01 §7 |
| R2 back Python + IA futura | doc 01 §1 · doc 06 fase 3 |
| R3 clean + hexagonal | doc 01 §2 |
| R4 ingesta masiva de imágenes | doc 05 |
