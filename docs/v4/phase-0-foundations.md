# Fase 0 — Cimientos: PostgreSQL, imagen y banco de pruebas

**Capa del §5:** ninguna directa; es la base sobre la que se prueban todas.
**Estimado:** ~10 h. **Depende de:** nada. **Habilita:** todas las demás.

## Objetivo

Tener dónde probar on-premise de verdad: PostgreSQL 16 (no SQLite), un inquilino
desechable y la imagen Docker que después se compilará. Sin esto, la huella
fuerte de la Fase 2 (que lee el `system_identifier` de PostgreSQL) no se puede
ni probar.

## Por qué

- El desarrollo usa SQLite; producción usa PostgreSQL 16 + TimescaleDB
  ([doc 07 §1](../07-deployment.md)). La huella 2 de 3 (Fase 2) lee
  `pg_control_system()`, que SQLite no tiene.
- La base real de AMBEV solo recibe migraciones. Hace falta un inquilino aparte
  para romper cosas sin miedo.

## Qué se toca

- `docker-compose.yml` ya trae `db` (timescale/timescaledb:2.17.2-pg16). Se
  agrega un perfil `onprem-test` que levanta la API contra esa base en un puerto
  mío (8013), con un inquilino `ipsa_test` en PostgreSQL.
- Un script `scripts/onprem_test_up.sh` (nuevo) que: levanta `db`, crea el
  inquilino de prueba, migra el plano de control y el inquilino, y emite una
  licencia de prueba.
- `pyproject.toml`: se agrega `cryptography>=44` (la necesita la Fase 1).
- Integración continua: un trabajo que corre la suite contra PostgreSQL, no solo
  SQLite, para que los cambios de licencia se prueben en el motor real.

## Entregable

Un comando que deja un PREDICTIVE on-prem corriendo en local contra PostgreSQL,
con un inquilino de prueba y su licencia, listo para que las fases siguientes lo
usen. Nada de esto toca AMBEV ni el IPSA real.

## Criterios de aceptación

- **AC-0.1** `scripts/onprem_test_up.sh` levanta la API contra PostgreSQL 16 en
  el puerto 8013 y responde `GET /api/v1/license/status/` con estado `active`.
- **AC-0.2** La suite `pytest` pasa entera corriendo contra PostgreSQL, no solo
  SQLite.
- **AC-0.3** El inquilino de prueba es `ipsa_test`, independiente de `ambev` y
  de `ipsa`; borrarlo no afecta a ninguno de los dos.
- **AC-0.4** `cryptography` queda instalada y `manage.py check` sigue verde.

## Riesgos

- TimescaleDB en la imagen puede pedir pasos extra en PostgreSQL limpio. Si da
  guerra, el banco de pruebas usa `postgres:16` pelado (la hypertable cae a
  tabla particionada nativa, doc 07 §1) y se deja TimescaleDB para el montaje
  real.

## Decisiones pendientes

- **P0-a.** ¿El banco de pruebas on-prem corre con Docker Compose (como
  producción) o directo con un PostgreSQL local y `manage.py`? Compose se parece
  más a lo que tendrá IPSA; local es más rápido para iterar. *Recomendado:
  Compose, para probar lo mismo que se entrega.*
