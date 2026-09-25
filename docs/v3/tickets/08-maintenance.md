# 08 · Mantenimiento

---

## V3-32 · Registro de mantenimiento correctivo que llenan los técnicos

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P2 | L | back, front | V3-17 (para enlazar el alineamiento) |

**Origen**

> Mantenimiento (los técnicos llenan esta parte): Cambio de rodamiento,
> Alineamiento, Balanceo. Cerrar el registro y guardar. En el informe de
> correctivos debe de haber: fecha y hora inicio y fecha y hora final. Con
> nombres de responsables durante ese día.

**Situación actual**

- La técnica `maintenance` existe (viene del RGP del cliente, módulo
  `operating_data`), pero no tiene ninguna visita ni formato: no hay dónde
  anotar una intervención.
- Las recomendaciones de los informes piden intervenciones concretas
  ("reemplazar rodamientos en la bomba", "balanceo de la polea cónica",
  "torquear pernos de la base del motor"), y el sistema no puede registrar que
  se hicieron. Sin eso no se puede comparar el antes y el después de la
  vibración.
- La captura de ronda ya resuelve lo difícil de la escritura en campo:
  idempotencia, autoría, cierre y candado.

**Qué hacer**

- Back, módulo `maintenance` instalable (como el resto): `WorkRecord` por
  conjunto (y equipo opcional), con:
  - tipo de trabajo: **cambio de rodamiento**, **alineamiento**, **balanceo**,
    y "otro" con descripción; más de uno por registro;
  - **inicio y fin con fecha y hora** (obligatorios al cerrar; fin > inicio);
  - **responsables** del día: usuarios del sistema y, para externos, nombre
    libre; al menos uno;
  - descripción, repuestos usados (texto), fotos con nota, OT del cliente;
  - enlace opcional a la recomendación o diagnóstico que lo motivó, y al
    `AlignmentRecord` de V3-17 si el trabajo fue un alineamiento con medición.
- Estados: **abierto → cerrado**. Abierto lo edita quien lo creó; cerrado queda
  bloqueado (mismas reglas que la visita). Reabrir solo el administrador, con
  auditoría.
- Permisos: lo crean técnicos e ingenieros (`maintenance.add_record`); lo leen
  los perfiles de gerencia.
- Front: pantalla "Mantenimiento" con la lista de registros (filtro por
  conjunto, tipo y mes) y el formulario. Botón **"Cerrar registro"** que
  valida lo obligatorio y guarda.
- El registro cuenta como **intervención** para V3-07, y aparece como marca
  vertical en el gráfico de tendencias del conjunto.
- Informe de correctivos: lista por periodo con conjunto, trabajo, inicio, fin,
  duración y responsables (se integra en V3-23).

**Criterios de aceptación**

- **AC-01** Dado un técnico, cuando crea un registro de "Cambio de rodamiento"
  en la bomba de un conjunto, con inicio 08:15 y fin 11:40 y dos responsables,
  y pulsa "Cerrar registro", entonces queda cerrado con duración 3 h 25 min.
- **AC-02** Dado un registro sin hora de fin, cuando se intenta cerrar,
  entonces el sistema pide la hora de fin.
- **AC-03** Dado un fin anterior al inicio, cuando se guarda, entonces el
  sistema lo rechaza.
- **AC-04** Dado un registro cerrado, cuando su autor intenta editarlo,
  entonces no puede; el administrador puede reabrirlo y queda en la auditoría.
- **AC-05** Dado un registro cerrado el 20-sep en un conjunto, cuando se abre
  el gráfico de tendencias, entonces aparece una marca el 20-sep con el tipo de
  trabajo.
- **AC-06** Dado el informe de correctivos de septiembre, cuando se genera,
  entonces cada fila tiene inicio, fin y responsables.

**Relación con la Fase 3**: la jornada diaria que cierra el ingeniero jefe
(`10-phase-3.md`) agrupará estos registros por día. Conviene que `WorkRecord`
guarde la fecha de jornada desde ya, aunque la jornada todavía no exista.
