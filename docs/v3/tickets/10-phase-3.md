# 10 · Fase 3: jornada, ATS y cierre del día

> **Estado (2026-09-26): implementada como módulo opcional `workday`**
> (back `1dc832e`, front `d156299`), desinstalado por defecto: se activa desde
> `/settings/modules` y al desinstalarlo sus reglas desaparecen con él.
>
> - F3-01: el ingeniero jefe (`workday.manage`) abre la jornada de hoy por
>   planta y la cierra **con su clave**; una jornada por planta y día.
> - F3-02: los trabajos del día salen de las visitas y, si `maintenance` está
>   instalado, de los correctivos de esa fecha: servicio, orden, personas,
>   hora de inicio y de término.
> - F3-03: cerradas todas las jornadas de una fecha, quien no tiene
>   `workday.manage` recibe 423 en cualquier escritura de datos de campo de
>   ese día (visitas, lecturas, fotos, correctivos). Usuarios, permisos,
>   licencia y preferencias siguen editables. Reabrir exige clave y motivo, y
>   queda en la auditoría.
> - F3-04: sin un ATS del conjunto **con su copia firmada** en la jornada
>   abierta de hoy, el servidor rechaza (428) fotos y observaciones de ese
>   conjunto.
> - F3-05: la observación de campo pide la foto, luego si lo observado es
>   visible en ella, y al final el texto.
> - F3-06: al instalar el módulo se crea el perfil **Jefe de Seguridad**
>   (solo lectura: jornadas, ATS, trabajos del día).
>
> Las reglas cruzan datos de otros módulos, así que el núcleo ganó un punto de
> extensión: un manifiesto declara `write_guard` y el middleware solo consulta
> los guardias de los módulos que el inquilino tiene instalados. Las tres
> preguntas del final se resolvieron con un supuesto (Q17 a Q19 en
> `docs/v3/README.md`).

El cliente lo marcó como **"Fase 3 del sistema (A FUTURO)"**. Se implementó
después de v3, a pedido, como módulo que cada cliente decide instalar. Lo que
sigue es el pedido original y las decisiones que lo dejaron preparado.

## Origen

> El ingeniero jefe (admin): debe de poder agarrar y cerrar con su clave el día
> de trabajo. Comenzó a tal hora y terminó a tal hora. Trabajos del día:
> Servicio X, Orden, Personas involucradas, Hora inicio, Hora término.
>
> Usuario técnico: Pasada la hora final, los técnicos ya no pueden modificar
> nada en el sistema. El usuario debe de colocar número de ATS de apertura.
> Subir ATS cargada.
>
> En observaciones: El operador debe de poner se hizo X Y Z. Antes de eso tomar
> fotos de la observación si es visible o no. Antes de tomar foto al conjunto
> rotórico, primero debe de haber un ATS.
>
> Ingeniero jefe: cambio en motor de la pulpería número 4 a las 2pm. Número de
> ATS xyz. Jefe de Seguridad también debe de ver esto.

**ATS** = Análisis de Trabajo Seguro: el permiso de seguridad que se abre antes
de intervenir un equipo.

## Historias

| ID | Historia | Notas para el diseño |
|---|---|---|
| F3-01 | Como **ingeniero jefe**, abro la jornada y la cierro con mi clave; la jornada registra hora de inicio y de fin. | Reautenticación al cerrar (la clave, no solo la sesión). Una jornada por planta y día. |
| F3-02 | Como ingeniero jefe, veo los **trabajos del día**: servicio, orden, personas involucradas, hora de inicio y de término. | Se arma con visitas (V3-24/28) y registros de mantenimiento (V3-32) de esa fecha. |
| F3-03 | Como **técnico**, pasada la hora de cierre de la jornada ya no puedo modificar nada. | Es la regla del candado de visita, extendida a todo lo de ese día. Distinguir "hora final" (cierre) de la hora de fin de cada trabajo. |
| F3-04 | Como técnico, antes de intervenir o fotografiar un conjunto rotórico registro el **número de ATS** y subo el ATS firmado. | Bloqueo en el servidor: sin ATS vigente para ese conjunto y jornada, no se aceptan fotos ni observaciones del conjunto. |
| F3-05 | Como técnico, en una observación anoto qué se hizo, y antes tomo la foto indicando si la observación es visible o no. | Foto obligatoria con campo "visible / no visible" antes del texto. |
| F3-06 | Como **jefe de seguridad**, veo las jornadas, los ATS y los trabajos del día, sin poder modificarlos. | Nuevo perfil de solo lectura en la matriz de acceso (comportamiento `client_viewer` + permiso de ver ATS). |

## Decisiones de v3 que dejan la puerta abierta

- V3-32 guarda la **fecha de jornada** en cada registro de mantenimiento.
- V3-02 y V3-27 llevan todo cambio de estado y todo borrado a la auditoría: la
  jornada se reconstruye de ahí.
- V3-35 (sesión de 10 minutos) no sustituye el cierre de jornada: son cosas
  distintas. Una sesión que expira no impide volver a entrar y editar.

## Preguntas que habrá que hacer cuando se retome

- ¿El ATS es un documento por trabajo, por conjunto o por jornada?
- ¿Quién puede reabrir una jornada cerrada, y queda rastro?
- ¿"Pasada la hora final" es la hora que declara el ingeniero jefe al cerrar o
  una hora fija de turno (los turnos A/B/C de 8 h ya existen en la membresía)?
