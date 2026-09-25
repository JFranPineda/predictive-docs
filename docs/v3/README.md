# v3 — Tickets de la revisión con el cliente (septiembre 2026)

Tercera ronda de requerimientos. Sale de la reunión de revisión del sistema en
uso y de la ruta que recorrió Jesús por las pantallas. Cada ticket cita el
texto del cliente que lo origina y apunta al código que hay que tocar.

## Fuentes de esta carpeta

| Fichero | Qué es | Cómo se usó |
|---|---|---|
| `Notas de Meet.txt` | Notas de la reunión, por módulo del sistema | Origen de casi todos los tickets |
| `Ruta Jesus.docx` | 7 capturas anotadas con la URL de cada pantalla | Bugs reproducibles y orden de magnitudes |
| `1A-MIG.jpeg` | Logo de la empresa (502×104, fondo blanco) | V3-33 |
| `EQUIPOS PLANTA IPSA - SEPTIEMBRE/` | 47 informes reales de IPSA + `EQUIPOS - CONCLUSIONES.xlsx` | Contexto de dominio: ver [`tickets/11-ipsa-context.md`](tickets/11-ipsa-context.md) |

Las capturas del Word, en orden: (1) error "El punto 1H está repetido" al
editar un tipo de conjunto; (2) y (7) la lista de tipos de conjunto con
"SE MIDE: vel_rms, env_accel, temp"; (3) visita de análisis de aceite de un
compresor; (4) informes de laboratorio y registro fotográfico con las imágenes
rotas; (5) "Editar orden" sobre una orden de ultrasonido con la técnica
cambiada a *Alineamiento*; (6) el informe "Alignment Results" de SKF que el
cliente quiere reproducir.

## Formato de un ticket

Cada ticket lleva: tipo (bug / cambio / nuevo), prioridad, tamaño, repos que
toca, dependencias, **origen** (cita literal del cliente), **situación actual**
(con evidencia: fichero y línea, o la consulta que lo demuestra), **qué hacer**,
**criterios de aceptación** numerados `AC-nn` en Dado/Cuando/Entonces, y
preguntas abiertas cuando las hay.

- **Prioridad**: P0 bloquea el uso hoy · P1 pedido explícito de cambio visible ·
  P2 capacidad nueva · P3 mejora menor.
- **Tamaño**: S ≤ 1 día · M 2–4 días · L una semana o más.

Las rutas de código son relativas a la raíz de cada repo (`predictive-back/`,
`predictive-front/`).

## Índice

| ID | Título | Tipo | Prio | Tam | Repos |
|---|---|---|---|---|---|
| **[01 · Bugs](tickets/01-bugs.md)** | | | | | |
| V3-01 | Las imágenes no se ven y el clic lleva al inicio de sesión | bug | P0 | S | front, infra |
| V3-02 | No se puede eliminar una imagen | bug | P0 | S | back, front |
| V3-03 | Editor de tipos de conjunto: "El punto 1H está repetido" y plantillas descuadradas | bug | P0 | M | back, front, datos |
| V3-04 | Los totales de Órdenes mezclan el total con la página cargada | bug | P1 | S | back, front |
| **[02 · El conjunto como fila](tickets/02-group-centric.md)** | | | | | |
| V3-05 | Activos: una fila por conjunto | cambio | P1 | M | back, front |
| V3-06 | Mediciones: la tabla "Elige un equipo" pasa a ser por conjunto, y "Medidas" → "Tipos de medición" | cambio | P1 | M | back, front |
| V3-07 | Columna "Última fecha de intervención" | nuevo | P1 | S | back, front |
| V3-08 | Registro de valores: lista de alcance en lugar de dos botones | cambio | P1 | S | front |
| **[03 · Vibraciones y espectros](tickets/03-vibration.md)** | | | | | |
| V3-09 | Espectros de todos los puntos del conjunto | cambio | P1 | S | back, front |
| V3-10 | Orden de los bloques: velocidad → aceleración → envolvente → temperatura | bug | P1 | S | back |
| V3-11 | Nueva magnitud: Aceleración en g RMS | nuevo | P2 | S | back, datos |
| V3-12 | Plantillas de puntos por tipo de conjunto (compresor 6 envolventes + 18 velocidades) | cambio | P1 | S | back, datos |
| V3-13 | "Se mide" legible y cómo se configuran los demás servicios en un punto | cambio | P2 | S | front, docs |
| V3-14 | Esquema del conjunto y fotos reales en la vista de vibraciones | nuevo | P2 | M | back, front |
| V3-15 | Espectros: subir la captura como imagen, texto de varias líneas, editar al abrir | bug + cambio | P1 | M | front |
| **[04 · Termografía](tickets/04-thermography.md)** | | | | | |
| V3-16 | Termografía: subir termogramas y llevar sus temperaturas y el ΔT mayor a la tendencia | nuevo | P2 | M | back, front |
| **[05 · Alineamiento y topografía](tickets/05-alignment-topography.md)** | | | | | |
| V3-17 | Servicio de Alineamiento con el formato SKF (antes / después) | nuevo | P2 | L | back, front |
| V3-18 | Servicio de Topografía: nivelación y paralelismo | nuevo | P2 | M | back, front |
| **[06 · END y familias de servicio](tickets/06-ndt.md)** | | | | | |
| V3-19 | Separar los servicios en dos familias: MPd Predictivo y END | cambio | P2 | M | back, front |
| V3-20 | Tintes penetrantes y partículas magnéticas: fotos y conclusiones | nuevo | P2 | M | back, front |
| V3-21 | Ultrasonido en rodillos: 6 puntos por rodillo, fotos comentadas y conclusiones | nuevo | P2 | L | back, front |
| V3-22 | Ultrasonido aéreo: modos de falla *fluting* (motor) y rascado (chumacera) | cambio | P3 | S | datos |
| V3-23 | Informes MPd e Informes END | nuevo | P2 | L | back, front |
| **[07 · Servicios y ejecución](tickets/07-services-execution.md)** | | | | | |
| V3-24 | Órdenes: columna "Empresa" en lugar de "Analista", editable | cambio + bug | P1 | M | back, front |
| V3-25 | Órdenes: "Fecha de servicio", fuera "Abiertas", aclarar "Visitas" | cambio | P1 | S | front |
| V3-26 | Órdenes: buscador y totales que siguen al filtro | nuevo | P1 | M | back, front |
| V3-27 | Solo el administrador cambia el estado de una orden | cambio | P1 | S | back, front |
| V3-28 | Ejecución: el detalle muestra equipo y conjunto | cambio | P1 | S | back, front |
| V3-29 | Tipo de lubricación por equipo (aceite / grasa) | nuevo | P2 | S | back, front |
| V3-30 | Datos operativos en números enteros | cambio | P1 | S | back, front, datos |
| V3-31 | Problemas a identificar: opción "Otros" | cambio | P1 | S | back, front |
| **[08 · Mantenimiento](tickets/08-maintenance.md)** | | | | | |
| V3-32 | Registro de mantenimiento correctivo que llenan los técnicos | nuevo | P2 | L | back, front |
| **[09 · Plataforma](tickets/09-platform.md)** | | | | | |
| V3-33 | Logo de 1A-MIG en lugar de "Predictive" | cambio | P1 | S | front |
| V3-34 | Botón retroceder | nuevo | P1 | S | front |
| V3-35 | Sesión inactiva: 10 minutos (hoy expulsa también al usuario activo) | cambio + bug | P1 | S | back, front |
| V3-36 | Limitar el plan por cantidad de equipos (el tope existe a medias) | cambio | P1 | S | back, front |
| **[10 · Fase 3 (a futuro)](tickets/10-phase-3.md)** | Jornada diaria, ATS, bloqueo por hora, jefe de seguridad | épica | — | — | — |
| **[11 · Contexto IPSA](tickets/11-ipsa-context.md)** | | | | | |
| V3-37 | Importar la planta IPSA como segundo inquilino *(derivado, no pedido)* | nuevo | P2 | L | back, datos |

## Orden sugerido

1. **Sprint 1 — que lo que ya existe funcione** (≈1 semana): V3-01, V3-02,
   V3-03, V3-04, V3-10, V3-12, V3-25, V3-28, V3-30, V3-31, V3-33, V3-34, V3-35.
   Todos son S salvo V3-03. V3-01 va primero: sin él no se puede revisar
   nada que tenga una foto.
2. **Sprint 2 — el conjunto como unidad de trabajo**: V3-05, V3-06, V3-07,
   V3-08, V3-09, V3-15, V3-24, V3-26, V3-27, V3-36.
3. **Sprint 3 — formatos MPd que faltan**: V3-11, V3-13, V3-14, V3-16,
   V3-17, V3-18, V3-19.
4. **Sprint 4 — END, mantenimiento e informes**: V3-20, V3-21, V3-22,
   V3-23, V3-29, V3-32.
5. **Backlog**: Fase 3. V3-37 conviene antes del sprint 3, porque los
   formatos nuevos se validan mejor contra la planta real que contra la demo.

## Preguntas para el cliente

Bloquean o cambian el alcance del ticket indicado. Mientras no haya respuesta,
el ticket aplica el supuesto que se indica.

| # | Pregunta | Ticket | Supuesto mientras tanto |
|---|---|---|---|
| Q1 | La envolvente, ¿es **gE RMS** (lo escrito en el Word) o **Gs pico** (lo que dicen los límites de los 47 informes de IPSA y lo que usa hoy el sistema)? | V3-10, V3-11 | No se cambia la agregación. Cambiarla recalifica todo el histórico. |
| Q2 | "Motor + reductor: 8 puntos": ¿motor 2 + reductor 6? ¿Y "Turbina: 8 puntos (lado = otro)" es un segundo tipo de conjunto, con motor 2 + turbina 6? ("Otro" es el lado `custom` del editor de tipos.) | V3-12 | Motor 2 + reductor 6; turbina de 8 como tipo aparte, motor 2 + turbina 6 con lado "Otro". |
| Q3 | ¿Qué cuenta como "intervención": cualquier servicio, solo mantenimiento correctivo, o también el alineamiento? | V3-07 | La última visita de cualquier servicio o registro de mantenimiento. |
| Q4 | "Empresa" en las órdenes, ¿es la empresa que ejecuta el servicio (1A-MIG o un contratista)? ¿Sale de una lista o se escribe? | V3-24 | Empresa ejecutora, elegida de un catálogo editable. |
| Q5 | "Visitas" es el número de equipos inspeccionados en la orden, no de personas. ¿Se renombra a "Equipos inspeccionados"? | V3-25 | Sí, con una ayuda al pasar el ratón. |
| Q6 | ¿También el factor de potencia va en enteros? Vale entre 0 y 1: en entero siempre sale 0 o 1. | V3-30 | Excepción: factor de potencia con 2 decimales. |
| Q7 | ¿Dónde se quiere ver el tipo de lubricación: ficha del equipo, visita de lubricación, informe? | V3-29 | En la ficha del equipo y en la cabecera de la visita. |
| Q8 | "Valor delta mayor del elemento observado": ¿ΔT contra qué: componente similar, ambiente, o el mínimo de la misma imagen? | V3-16 | Tmáx del elemento menos la referencia que elija el técnico. |
| Q9 | La escala térmica de IPSA tiene **cuatro** niveles (aceptable < 82 °C, alarma < 121, **alerta** < 148, parada). ¿Se usa en lugar de NETA para IPSA? | V3-16 | Se carga como juego de umbrales propio del inquilino IPSA. |
| Q10 | Tolerancias de alineamiento: ¿las de la tabla SKF por RPM, o una por equipo? | V3-17 | Tabla SKF por RPM, sobrescribible por equipo. |
| Q11 | Topografía: ¿unidades, tolerancias y cuántos puntos? | V3-18 | mm y mm/m, sin veredicto automático hasta tener tolerancias. |
| Q12 | Límite del plan: ¿cuentan los equipos retirados o apagados? ¿Qué pasa al superarlo? | V3-36 | Cuentan los activos no retirados; al superarlo se bloquea el alta, no la lectura. |
| Q13 | ¿Hay versión del logo con fondo transparente (PNG o SVG)? La actual lleva fondo blanco y no funciona en modo oscuro. | V3-33 | Se usa la JPEG sobre una placa blanca. |
| Q14 | ¿Quién puede borrar una foto: solo el administrador, o también quien la subió mientras la visita siga abierta? | V3-02 | Quien la subió, con la visita abierta; el administrador siempre. |
| Q15 | "Medidas de 6 puntos según formato" en ultrasonido de rodillos, ¿son los P1–P6 de `docs/v2/ORDEN_14778(1).xlsx`? | V3-21 | Sí. |

## Hallazgos que el cliente no reportó

Salieron al contrastar cada petición con el código y la base de AMBEV. Van
dentro de su ticket; se listan aquí para que no se pierdan.

- **La sesión expulsa también al usuario activo** (V3-35). Acceso y refresh
  nacen juntos y duran lo mismo, y el refresh solo se pide ante un 401.
  Comprobado con vidas de 1 minuto. Bajar a 10 minutos sin arreglarlo
  expulsaría a los técnicos cada 10 minutos.
- **"Editar orden" ignora planta y técnica sin avisar**, obliga a reelegir la
  planta y su botón dice "Crear orden" (V3-24).
- **"Equipo Desacoplado", usado por 104 conjuntos, quedó sin plantilla** tras
  convertirlo en el tren de la MP3 (V3-03).
- **El Jefe de Mantenimiento puede crear, editar y anular órdenes**
  (`services.manage_order`), aunque la matriz de acceso lo define como solo
  lectura (V3-27).
- **Las lecturas de termografía de AMBEV son la temperatura del colector de
  vibraciones**: no hay ninguna visita de termografía (V3-16).
- **El tope de equipos de la licencia cuenta los retirados** y los comandos de
  carga no lo comprueban (V3-36).
- **Los totales de Órdenes dejarán de cuadrar** en cuanto haya más de 25
  órdenes (V3-04).
- `SUMMARY.md` cita `docs/v2/ORDEN_14778.xlsx`; el fichero real es
  `docs/v2/ORDEN_14778(1).xlsx` (y lo mismo con el informe de ultrasonido).

## Lo que v3 responde de los pendientes anteriores

- **Aceleración en G** (pendiente en `SUMMARY.md` §6: "falta saber si es pico
  o RMS"): el Word dice **"Aceleración gEs RMS"**. Resuelto → V3-11.
- **Datos reales de IPSA sin importar**: ahora hay 47 informes de septiembre
  2025 → V3-37.
- **Módulo `blueprints`**: el cliente pide el esquema del equipo junto a la
  tabla → V3-14 propone un MVP sin esperar al módulo completo.
- **Reporte en PDF**: se parte en dos, Informes MPd e Informes END → V3-23.
