# Fase 2 — Huella fuerte (2 de 3) y anti-atraso de reloj

**Capa del §5:** Capa 3 (§5.4) y Capa 4 (§5.5). **Estimado:** ~12 h.
**Depende de:** Fase 1 (la huella viaja dentro del token v2).

## Objetivo

1. Que la licencia quede atada a **esa** instalación, no a un nombre de base de
   datos que se copia fácil.
2. Que atrasar el reloj del servidor no alargue una licencia vencida.

## Por qué

- Hoy la huella es `sha256(tenant|nombre de BD|host)`
  (`database_fingerprint` en `domain/license.py`). En otro servidor con los
  mismos nombres da la misma huella: una copia no se detecta.
- Una licencia que depende de la fecha del sistema se burla retrasando el reloj.

## Qué se toca (predictive-back)

### Huella 2 de 3 (Capa 3)

- Tres identificadores:
  - `installation_id`: UUID creado al instalar, guardado en el plano de control
    **y** en el volumen de datos del cliente (un archivo en `MEDIA_ROOT`).
  - `pg_system_id`: `SELECT system_identifier FROM pg_control_system()` —
    único por clúster de PostgreSQL; cambia si se recrea la base.
  - `machine_id`: `/etc/machine-id` del servidor.
- `domain/license.py`: nueva `installation_fingerprint(installation_id,
  pg_system_id, machine_id)` que guarda los tres en el token.
- `evaluate(...)`: la huella coincide si **2 de 3** coinciden. Un cambio
  legítimo de hardware (nuevo `machine-id`) o una restauración de la base
  (nuevo `pg_system_id`) no rompe; una copia a otro servidor falla los tres.
- `application/license_service.py`: arma los tres identificadores en cada
  petición y se los pasa a `evaluate`.
- Comando `manage.py license fingerprint` que imprime los tres, para el alta y
  para soporte.
- Compatibilidad: el token v2 lleva la huella nueva; la vieja
  `database_fingerprint` se deja para los v1 en transición.

### Anti-reloj (Capa 4)

- Tope de tiempo: la fecha-hora más alta que el sistema ha visto, firmada con
  una clave derivada de la instalación, guardada en el plano de control y en un
  archivo del volumen de datos.
- En cada veredicto se contrasta contra: (a) ese tope y (b) la fecha de la
  lectura más reciente registrada.
- Si el reloj está más de 24 h **por debajo** del tope registrado, el sistema
  pasa a **solo lectura** hasta que la fecha vuelva a ser coherente. No bloquea
  del todo: un reloj mal puesto no debe apagar la planta.

## Criterios de aceptación

- **AC-2.1** Con los tres identificadores correctos, veredicto `active`.
- **AC-2.2** Cambiando **uno** (p. ej. `machine_id`), sigue `active` (2 de 3).
- **AC-2.3** Cambiando **dos**, veredicto `invalid` («no corresponde a esta
  instalación»).
- **AC-2.4** Copiar la base y el token a otro inquilino de prueba con distinto
  `pg_system_id` y `machine_id` da `invalid`.
- **AC-2.5** Retrasar el reloj del contenedor 48 h deja el sistema en solo
  lectura; devolverlo a la fecha correcta lo reactiva.
- **AC-2.6** Reponer el reloj dentro de 24 h no molesta (tolerancia).
- **AC-2.7** Portones verdes.

## Riesgos

- `/etc/machine-id` puede no existir o repetirse en VMs clonadas. Por eso es 2
  de 3 y no obligatorio. Si falta, cuenta como no coincidente, nunca como error.
- El tope de tiempo mal guardado podría trabar el sistema. Se guarda en dos
  lugares y, si no se puede leer, se asume la hora actual (falla hacia
  disponible, no hacia bloqueado).

## Decisiones pendientes

- **P2-a.** Ante una mudanza legítima (IPSA cambia de servidor), ¿la
  reactivación es un archivo nuevo que emitimos (como la renovación de la Fase
  3) o un comando que su TI corre con un código que le damos? *Recomendado:
  archivo nuevo, mismo canal que la renovación — un solo procedimiento que
  aprender.*
- **P2-b.** El umbral de atraso de reloj, ¿24 h está bien, o IPSA tiene equipos
  que se apagan y encienden con el reloj desfasado? Si su hora la fija un
  servidor NTP interno, 24 h sobra. *Recomendado: 24 h; se confirma con su TI.*
