# Fase 0 — Cimientos: PostgreSQL, banco de pruebas e integración continua

**Estado: Hecha (2026-10-19).** Commit en `predictive-back` (rama
`onpremise-v1`): `5b1af48`. `predictive-front` no cambia en esta fase.

**Capa del §5:** ninguna directa; es la base sobre la que se prueban todas.
**Estimado:** ~10 h. **Depende de:** nada. **Habilita:** todas las demás.

## Objetivo

Tener dónde probar on-premise de verdad: PostgreSQL 16 (no SQLite), un rol de
aplicación sin privilegios y un inquilino desechable. Sin esto, la huella de
instalación de la Fase 2 (que lee el `system_identifier` de PostgreSQL) no se
puede ni probar.

## Lo que se encontró al revisar el código (corrige la primera versión)

1. **Las 41 pruebas (408 casos) son unitarias y ninguna toca base de datos.**
   El criterio original «pytest pasa contra PostgreSQL» no probaba nada. Se
   reemplazó por una **prueba de humo de integración** (AC-0.2).
2. **TimescaleDB no se usa.** Ninguna migración crea hypertables ni SQL propio,
   así que basta un `postgres:16` normal.
3. **`psycopg` no estaba instalado en el `.venv`**: el desarrollo corría solo en
   SQLite.
4. **El `docker-compose.yml` de desarrollo publica `5432:5432`**, que en la
   máquina de desarrollo ya ocupa el PostgreSQL del sistema. No se tocó (no lo
   usa nadie hoy); el banco usa su propio archivo y puerto.

## Respaldo previo

Antes de empezar se respaldaron las tres bases (`.backup` de SQLite,
`integrity_check = ok`) y la carpeta de media completa en
`predictive-back/data/backups/2026-10-19-before-onpremise-v1/`, con un
`MANIFEST.txt` que trae las sumas SHA-256 y cómo restaurar. IPSA: 47 conjuntos,
98 equipos, 795 puntos, 10 536 lecturas y 258 archivos de media. La carpeta
está fuera de git.

## Qué se hizo (predictive-back)

| Pieza | Qué es |
|---|---|
| `deploy/onprem-test/compose.yml` | PostgreSQL 16 desechable en `127.0.0.1:5437` (puerto configurable con `ONPREM_TEST_PG_PORT`) |
| `deploy/onprem-test/init.sql` | Rol `predictive_app` **sin superusuario**, dueño de `predictive_control` y `predictive_ipsa_test`, como será en el servidor del cliente |
| `scripts/onprem_test.sh` | El banco: `up`, `import`, `start`, `smoke`, `stop`, `down`, `reset` y `manage …` |
| `.github/workflows/ci.yml` | En cada push: `manage.py check`, fronteras hexagonales, pytest y el banco sin los libros (están en otro repo) |
| `pyproject.toml` | `cryptography>=44` para la firma Ed25519 de la Fase 1 |
| `.gitignore` | `data/backups/` y `.onprem-test/` nunca se versionan |

### Cómo se usa

```bash
scripts/onprem_test.sh up       # PostgreSQL, plano de control, inquilino ipsa_test y su licencia
scripts/onprem_test.sh import   # los 47 libros de IPSA y el resto de módulos
scripts/onprem_test.sh start    # API en http://127.0.0.1:8013, en segundo plano
scripts/onprem_test.sh smoke    # las comprobaciones de abajo
scripts/onprem_test.sh down     # apaga API y base, conserva los datos
scripts/onprem_test.sh reset    # borra todo el banco
```

### Aislamiento

El guion exporta cada variable que necesita, y las variables exportadas ganan
sobre el `.env` (python-dotenv no las sobrescribe). Además deja **vacía** toda
`TENANT_*_DATABASE_URL` que declare el `.env`, para que ninguna petición pueda
llegar a una base de desarrollo. Media e historial van a `.onprem-test/`, nunca
a `data/`.

## Criterios de aceptación (resultado)

- ✅ **AC-0.1** `up` levanta el plano de control y el inquilino en PostgreSQL 16
  en ~30 s; `start` sirve la API en el 8013 y `GET /api/v1/license/status/`
  responde `active` con `deployment = on_premise`.
- ✅ **AC-0.2** *(reformulado)* Prueba de humo de integración contra PostgreSQL:
  migraciones completas del plano de control y del inquilino, licencia emitida
  y verificada, e **importación de los 47 libros de IPSA en ~50 s** (47
  conjuntos, 98 equipos, 795 puntos, 10 536 lecturas, 1 101 visitas, 42
  órdenes). La suite unitaria (408 casos) sigue verde.
- ✅ **AC-0.3** El inquilino de prueba es `ipsa_test`. El banco responde **404
  para `ambev`**: no conoce ni puede alcanzar las bases de desarrollo.
- ✅ **AC-0.4** `cryptography` instalada; `manage.py check` y `lint-imports`
  verdes.

## Hallazgos que pasan a otras fases

- **El rol de aplicación sin privilegios sí lee `system_identifier`**
  (`pg_control_system()`). La huella de la Fase 2 no necesita pedirle permisos
  extra al TI del cliente. Riesgo despejado.
- **En una base vacía, `modules bootstrap` falla**: el gancho de instalación de
  `ut_rollers` busca la unidad `mm`, y el catálogo base (unidades, magnitudes,
  estados) solo lo siembran la importación de IPSA y el demo. En el banco se
  resolvió con el orden (importar primero, después instalar módulos). La
  solución de fondo, un catálogo base propio para la instalación limpia, va a la
  **Fase 6** (decisión P0-b).

## Decisiones tomadas

- **P0-a (2026-10-19):** PostgreSQL en Docker + API desde el `.venv`. Base
  aislada y desechable, sin tocar el PostgreSQL del sistema ni otros
  contenedores; cada cambio se prueba sin reconstruir imágenes. La imagen
  completa se arma en la Fase 5.
- **P0-b (2026-10-19):** el catálogo base para instalar en una base vacía se
  resuelve en la Fase 6, con el instalador.

## Pendiente fuera de esta fase

- La integración continua está escrita y sus pasos se probaron en local, pero
  **todavía no corrió en GitHub**: lo hará en el primer push de la rama.
- Ruff no es puerta en la integración continua: el repo arrastra hallazgos
  antiguos y la dejarían siempre en rojo.
