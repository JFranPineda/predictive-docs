# Fase 6 — Instalador, actualización sin internet y manual

**Capa del §5:** cierre de §5.10 y §5.11. **Estimado:** ~10 h.
**Depende de:** Fase 5.

## Objetivo

Que instalar y actualizar PREDICTIVE en el servidor de IPSA sea un
procedimiento repetible que su TI pueda seguir, sin internet si hace falta, y
que quede escrito. Es lo que convierte la rama en un producto entregable y lo
que hace rentables los siguientes clientes on-premise.

## Por qué

La propuesta vende «instalación y aseguramiento» como un ítem de 16 h
(§3.4, ítem B). Eso solo se cumple si existe un instalador; a mano serían
muchas más horas y cada cliente sería distinto.

## Qué se toca

### Instalador

- Un `docker-compose.prod.yml` y un `install.sh` que: comprueba requisitos
  (Docker, 4 vCPU, 8 GB, 400 GB), pide los datos del cliente, crea el
  `installation_id` (Fase 2), levanta PostgreSQL 16, migra el plano de control y
  el inquilino, importa el `.lic` (Fase 3) y deja el sistema sirviendo con TLS
  interno.
- Un `.env.example` on-premise, distinto del de desarrollo: sin `DEBUG`, con
  `MEDIA_BACKEND=local`, `HISTORY_ROOT`, y la ruta del archivo de licencia.

### Actualización sin internet

- `update.sh` que recibe el `.tar` firmado de la nueva versión (Fase 5),
  verifica la firma, respalda la base, aplica migraciones y arranca. Si algo
  falla, vuelve a la imagen anterior.
- Es lo que sostiene la «actualización mensual» del Plan 2 y la trimestral del
  Plan 1 (§3.3).

### Respaldo

- `backup.sh`: `pg_dump` comprimido más `MEDIA_ROOT` y `HISTORY_ROOT`, con
  retención, al destino que indique IPSA.
- `restore.sh` y la **prueba de restauración**, que es un ítem cobrado
  (§3.4, ítem B) y un servicio mensual del Plan 2.

### Manual para el TI del cliente

- `predictive-docs/docs/v4/onprem-install-guide.md` (en español, nombre en
  inglés como pide el repo): requisitos, instalación, renovación de licencia por
  archivo, respaldo y restauración, qué hacer si el sistema dice «solo
  exportar», y a quién escribir.
- Qué datos salen de su red y cuáles no (el argumento de la objeción 2).

## Criterios de aceptación

- **AC-6.1** `install.sh` deja un PREDICTIVE sirviendo en un servidor limpio
  (probado en una VM nueva), en menos de 30 minutos y sin pasos manuales fuera
  del guion.
- **AC-6.2** `update.sh` aplica una versión nueva y, ante un fallo de
  migración, vuelve a la anterior sin perder datos.
- **AC-6.3** `backup.sh` + `restore.sh` reconstruyen el sistema en una máquina
  distinta y la API arranca contra la base restaurada.
- **AC-6.4** Todo el ciclo (instalar, renovar por archivo, respaldar, restaurar)
  funciona **sin salida a internet**.
- **AC-6.5** El manual cubre los cuatro procedimientos y lo entiende alguien que
  no conoce el sistema.
- **AC-6.6** Portones verdes.

## Riesgos

- Una restauración no probada no es un respaldo (doc 07 §4). AC-6.3 es
  obligatorio, no opcional.
- El `installation_id` se pierde al reinstalar y la licencia deja de cuadrar.
  Mitigación: vive en el volumen de datos y en el respaldo, y la regla 2 de 3
  (Fase 2) da margen.

## Decisiones pendientes

- **P6-a.** ¿El manual se entrega también impreso/PDF firmado, o basta el
  Markdown del repo? *Recomendado: PDF generado del Markdown, para adjuntar al
  acta de puesta en marcha.*
- **P6-b.** ¿El respaldo va a un disco en su planta, a su NAS, o a un bucket
  nuestro? Lo último choca con su política de datos. *Recomendado: destino que
  elija IPSA dentro de su red; nosotros solo verificamos que la restauración
  funciona.*
