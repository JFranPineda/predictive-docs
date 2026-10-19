# v4 — On-premise v1: proteger la licencia en un servidor que no controlamos

Plan por fases para implementar el **§5 de la propuesta IPSA**
([`business/ipsa-onpremise-proposal.md`](../business/ipsa-onpremise-proposal.md))
en código. Rama de trabajo: **`onpremise-v1`** en `predictive-back` y
`predictive-front` (creada desde `main` el 2026-10-19).

Es un plan **interactivo**: cada fase tiene una sección «Decisiones pendientes»
que se resuelve con el usuario antes de empezar esa fase, no al principio de
todo. Este README se actualiza cuando una decisión se cierra o una fase termina.

## Objetivo

Que PREDICTIVE pueda correr **entero en el servidor de IPSA** con la licencia
atada a esa instalación y al período pagado, y con el producto entregado
cerrado (compilado y firmado), como hace cualquier proveedor on-premise.

Con la honestidad del §5.0 por delante: ninguna medida técnica es absoluta. Lo
que se consigue es que la licencia no se pueda falsificar, que una instalación
movida se detecte, que el producto no se entregue como código fuente, y que el
contrato y el registro en INDECOPI sostengan la titularidad (§5.8 y §7). Las
tres patas van juntas: técnica, comercial y legal.

## Decisiones ya tomadas (2026-10-19)

| # | Decisión | Elegido | Consecuencia |
|---|---|---|---|
| D1 | Alcance del código de v1 | **Núcleo + compilado + servidor de renovación online** (~76 h) | Entran las capas 1 a 6 del §5 y el servidor de licencias. Las capas 7 (contrato/INDECOPI) y 8 (appliance) no son código y quedan fuera de la rama. |
| D2 | Firma de la licencia | **Todo a Ed25519 (token v2)** | Se reemplaza HMAC en **todos** los clientes, AMBEV incluido. Un solo formato. AMBEV se reemite y hay que verificar que su sistema sigue vigente (Fase 1). |

## Mapa: capa del §5 → fase

| Capa del §5 | Fase |
|---|---|
| — (base: PostgreSQL, imagen, banco de pruebas) | [Fase 0](phase-0-foundations.md) |
| Capa 1 — Licencia Ed25519 | [Fase 1](phase-1-ed25519.md) |
| Capa 3 — Huella fuerte (2 de 3) · Capa 4 — Anti-reloj | [Fase 2](phase-2-fingerprint-clock.md) |
| Capa 2 — Licencias cortas renovables (archivo + servidor online) | [Fase 3](phase-3-renewal.md) |
| Capa 5 — Degradar sin secuestrar (solo exportar) | [Fase 4](phase-4-degrade-export.md) |
| Capa 6 — Distribución compilada y firmada | [Fase 5](phase-5-hardening.md) |
| — (instalador, actualización sin internet, manual) | [Fase 6](phase-6-packaging.md) |
| Capa 7 — Contrato + INDECOPI | Fuera de código: §5.8 y §7 de la propuesta |
| Capa 8 — Servidor en comodato (LUKS+TPM) | Fuera de código: §5.9; es montaje, no rama |

## Fases y estado

| Fase | Qué deja listo | Estimado | Estado |
|---|---|---|---|
| [0 · Cimientos](phase-0-foundations.md) | Banco de pruebas on-prem con PostgreSQL 16, imagen Docker e integración continua | ~10 h | Pendiente |
| [1 · Licencia Ed25519](phase-1-ed25519.md) | Token v2 firmado, clave privada fuera del repo, pública compilada; AMBEV reemitido | ~14 h | Pendiente |
| [2 · Huella y reloj](phase-2-fingerprint-clock.md) | Huella de instalación 2 de 3 y bloqueo por atraso de reloj | ~12 h | Pendiente |
| [3 · Renovación](phase-3-renewal.md) | Licencias cortas, renovación por archivo `.lic` y servidor online | ~18 h | Pendiente |
| [4 · Degradar](phase-4-degrade-export.md) | Al vencer: bloquea el trabajo pero siempre deja exportar | ~6 h | Pendiente |
| [5 · Empaquetado cerrado](phase-5-hardening.md) | Backend y front compilados, imágenes firmadas e identificador de compilación por cliente | ~18 h | Pendiente |
| [6 · Empaquetar](phase-6-packaging.md) | Instalador, actualización sin internet y manual para el TI del cliente | ~10 h | Pendiente |

Las fases 0 a 4 se pueden instalar en IPSA **bajo nuestra supervisión**. La
Fase 5 es la que §5.11 pide **antes de entregarle el instalador a su TI**.

## Orden recomendado y puertas entre fases

```
Fase 0 ─▶ Fase 1 ─▶ Fase 2 ─▶ Fase 3 ─▶ Fase 4 ─┐
                                                 ├─▶ instalable en IPSA (supervisado)
                                   Fase 5 ─▶ Fase 6 ─▶ entregable a su TI
```

Cada fase cierra con los mismos portones verdes que el resto del repo (pytest,
ruff, lint-imports, `manage.py check`, tsc, eslint, vitest, build) y con sus
criterios de aceptación numerados.

## Disciplina de pruebas (igual que v3, con una adición)

- **Nada de datos de prueba sobre la base real de AMBEV** (`tenant_ambev`): solo
  recibe migraciones. El trabajo de escritura va en un espejo en el
  *scratchpad*, backend **8012** y front **5175**.
- **Puertos 8010/5174 y cloudflared son del usuario** ([[predictive-dev-ports]]).
  Mis servidores usan otros puertos y se apagan al terminar.
- **Adición on-prem:** la huella fuerte usa el `system_identifier` de
  PostgreSQL, que SQLite no tiene. Por eso se levanta un **banco de pruebas
  on-prem** con PostgreSQL 16 en un inquilino desechable (Fase 0), nunca sobre
  AMBEV ni IPSA reales.
- La licencia vive en el **plano de control** (nuestra BD, 3 tablas), no en la
  base del cliente. Reemitir la licencia de AMBEV (D2) no toca sus datos de
  mantenimiento.

## Todo modular

Las piezas nuevas viven en el módulo `licensing`, que es infraestructura del
plano de control y está siempre activo. No se agrega ningún módulo instalable
nuevo; lo que se toca de cara al usuario (renovación de licencia, aviso de
vencimiento) se suma a la pantalla existente `/settings/license`.

## Riesgos transversales

| Riesgo | Dónde | Mitigación |
|---|---|---|
| La compilación rompe dependencias nativas (weasyprint, pillow-heif, numpy) | Fase 5 | Se prueba la imagen compilada contra la suite completa antes de dar nada por hecho; si una no compila, se deja ese módulo interpretado y se documenta |
| Reemitir AMBEV lo deja fuera de servicio | Fase 1 | Se reemite primero en el espejo y se verifica el veredicto; el cambio de clave soporta las dos firmas durante la transición |
| El `machine-id` o el `system_identifier` cambian por una operación legítima (restaurar la BD, migrar de host) | Fase 2 | Regla 2 de 3 y reactivación guiada; nunca 3 de 3 |
| Degradar de más y secuestrar datos | Fase 4 | La exportación nunca se bloquea; prohibido borrar o cifrar (Ley 30096) |

## Fuentes

- Propuesta IPSA, §5: [`business/ipsa-onpremise-proposal.md`](../business/ipsa-onpremise-proposal.md)
- Licenciamiento actual: [`08-onpremise-and-licensing.md`](../08-onpremise-and-licensing.md)
- Despliegue: [`07-deployment.md`](../07-deployment.md)
