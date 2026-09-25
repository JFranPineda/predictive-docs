# 09 · Plataforma

---

## V3-33 · Logo de 1A-MIG en lugar de "Predictive"

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | front | — |

**Origen**

> Logo de 1A MIG. Reemplazar la palabra superior izquierda que dice Predictive
> por el logo de 1A MIG.

Fichero: `docs/v3/1A-MIG.jpeg`, 502×104 px, JPEG con **fondo blanco**: placa
roja y amarilla con franjas, "1A-MIG" y debajo, muy pequeño, "INDUSTRIAL
PREDICTIVE MAINTENANCE".

**Situación actual**

La palabra sale de la clave `app.name` en tres sitios:

- barra lateral, `src/app/layout/AppShell.tsx:29` (debajo, el nombre de la
  compañía cliente, p. ej. "AMBEV Perú");
- pantalla de inicio de sesión, `src/app/session/LoginPage.tsx:58`;
- título de la pestaña, `index.html:6`.

**Qué hacer**

- Copiar el logo a `predictive-front/src/app/layout/` (o `public/brand/`) y
  mostrarlo en la barra lateral y en el inicio de sesión, con `alt="1A-MIG"`.
  En la barra lateral mide 256 px de ancho: el logo ocupa el ancho útil
  (~216 px, ~45 px de alto).
- El nombre de la compañía cliente se queda debajo del logo.
- Modo oscuro: con la JPEG actual, el logo va sobre una placa blanca con
  esquinas redondeadas, para que el fondo blanco no parezca un error. Si llega
  una versión transparente (Q13), se quita la placa.
- Título de la pestaña: "1A-MIG" (o "1A-MIG · Predictive", a confirmar).
- El logo es del **proveedor** del servicio, no del cliente: es el mismo para
  todos los inquilinos. Los informes PDF (V3-23) lo usan también.

**Criterios de aceptación**

- **AC-01** Dada cualquier pantalla con sesión, cuando se mira la esquina
  superior izquierda, entonces se ve el logo de 1A-MIG y, debajo, el nombre de
  la compañía cliente.
- **AC-02** Dada la pantalla de inicio de sesión, cuando se abre, entonces se ve
  el logo en lugar de "Predictive".
- **AC-03** Dado el modo oscuro, cuando se abre la barra lateral, entonces el
  logo se ve completo y legible.
- **AC-04** Dado un lector de pantalla, cuando pasa por el logo, entonces lee
  "1A-MIG".

---

## V3-34 · Botón retroceder

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| nuevo | P1 | S | front | — |

**Origen**

> Botón retroceder.

**Situación actual**

Solo algunas pantallas tienen su propio "← Volver" (tendencia,
`measurements/locales/es.json` `trend.back`; visita, "← Volver a ejecución"),
cada uno con su destino fijo. En el resto hay que usar el botón del navegador.

**Qué hacer**

- Un botón "← Atrás" común, en la cabecera de página (el componente de título
  que usan todas las pantallas), visible en toda pantalla que no sea de primer
  nivel del menú.
- Comportamiento: vuelve a la pantalla anterior del historial **si** era de la
  aplicación; si se abrió en una pestaña nueva (sin historial), va a la
  pantalla padre de la ruta (`/services/visits/:id` → `/services`).
- Sustituye a los "← Volver" sueltos, para que no convivan dos botones.
- Conserva filtros y búsqueda de la pantalla anterior (viajan en la URL desde
  V3-08 y V3-26).

**Criterios de aceptación**

- **AC-01** Dado un usuario que entra a una visita desde Órdenes, cuando pulsa
  "← Atrás", entonces vuelve a Órdenes con su búsqueda intacta.
- **AC-02** Dada una visita abierta en una pestaña nueva, cuando se pulsa
  "← Atrás", entonces va a `/services`.
- **AC-03** Dada una pantalla de primer nivel (Activos, Servicios…), cuando se
  abre, entonces no muestra el botón.

---

## V3-35 · Sesión inactiva: 10 minutos

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio + bug | P1 | S | back, front | — |

**Origen**

> Límite de sesión inactiva: 10 minutos.

**Situación actual — hoy no es una sesión de inactividad, es una ventana fija**

- Back: `ACCESS_TOKEN_LIFETIME` y `REFRESH_TOKEN_LIFETIME` valen lo mismo, 30
  minutos (`ACCESS_MINUTES` / `IDLE_MINUTES`,
  `config/settings/base.py:125-126`), con rotación del refresh.
- Front: el refresh solo se pide **cuando llega un 401**
  (`src/app/api/baseApi.ts:44-66`). No hay renovación anticipada.
- Como el token de acceso y el de refresh nacen juntos y duran lo mismo, el
  acceso caduca en el mismo instante que el refresh que debería renovarlo.
  **Un usuario que está trabajando es expulsado al cumplirse el plazo**, igual
  que uno que se fue. El comentario de `baseApi.ts:34-37` ("somebody who keeps
  working never sees this happen") no se cumple.

Comprobado ejecutando, con un servidor aparte y vidas de 1 minuto
(`ACCESS_MINUTES=1 IDLE_MINUTES=1`):

```
t=0    login                                   → ok
t=30s  GET /api/v1/techniques/ (actividad)     → 200
t=65s  GET con el mismo acceso                 → 401
t=65s  POST /api/v1/auth/refresh/ (lo que hace el front) → 401  ⇒ fuera
```

**Bajar a 10 minutos sin arreglar esto expulsaría a un técnico cada 10 minutos
aunque esté digitando una ronda.**

**Qué hacer**

- Back: `IDLE_MINUTES=10` (vida del refresh = ventana de inactividad) y un
  acceso **corto**, `ACCESS_MINUTES=5`, para que se renueve varias veces dentro
  de la ventana mientras haya actividad.
- Front: renovación **anticipada**: si el acceso vence en menos de 1 minuto y
  hubo actividad del usuario (tecla, clic, desplazamiento) desde la última
  renovación, pedir el refresh antes de la siguiente petición. Así, cada
  renovación reinicia los 10 minutos solo cuando alguien está trabajando.
- Front: temporizador de inactividad. A los 9 minutos sin actividad, aviso "Tu
  sesión se cerrará en 1 minuto" con botón "Seguir conectado"; a los 10,
  cierre de sesión y el login dice "Sesión cerrada por inactividad".
- Un formulario a medio llenar (captura de ronda) conserva el borrador local
  para no perder lo digitado si la sesión se cierra.
- Actualizar el comentario de `baseApi.ts` y el de `base.py`, que hablan de
  treinta minutos.

**Criterios de aceptación**

- **AC-01** Dado un usuario que hace clic cada 2 minutos durante 30 minutos,
  cuando pasa ese tiempo, entonces sigue con sesión.
- **AC-02** Dado un usuario sin actividad, cuando pasan 9 minutos, entonces ve
  el aviso; si no responde, a los 10 minutos queda fuera con el mensaje de
  inactividad.
- **AC-03** Dado el aviso, cuando pulsa "Seguir conectado", entonces la sesión
  sigue y el contador vuelve a 10 minutos.
- **AC-04** Dado el backend con `IDLE_MINUTES=1`, cuando se reproduce la prueba
  de arriba con actividad a los 30 s y renovación anticipada, entonces la
  petición de los 65 s responde 200.
- **AC-05** Dada una captura de ronda con 12 valores escritos y la sesión
  cerrada por inactividad, cuando el técnico vuelve a entrar y abre la misma
  captura, entonces recupera los 12 valores.

---

## V3-36 · Limitar el plan por cantidad de equipos

| Tipo | Prioridad | Tamaño | Repos | Depende de |
|---|---|---|---|---|
| cambio | P1 | S | back, front | — |

**Origen**

> Limitar el plan de pase a producción: Limitar por cantidad de equipos.

**Situación actual — el tope existe, pero a medias**

La licencia emite y firma `max_plants`, `max_equipment`, `max_users` y
`max_external_users` (`modules/licensing/domain/license.py:59-66`), y el alta
manual de equipos ya lo comprueba: `_check_licence(request, "equipment", …)`
en `modules/assets/interfaces/admin_views.py:264` (y `"plants"` en `:72`).
AMBEV tiene licencia de 600 equipos y 558 dados de alta. Lo que falla:

1. **Cuenta también los retirados**: `self.scoped(Equipment, request).count()`
   no filtra. Un equipo dado de baja sigue ocupando cupo para siempre, porque
   "nada se borra si tiene historia".
2. **El mensaje usa la palabra interna**: "El plan contratado no permite más
   equipment" (`admin_views.py:54-56`).
3. **Los comandos de carga no pasan por ahí**: `seed_demo` (que es el
   importador del RGP) crea equipos directamente; un import de otra planta
   (V3-37) tampoco se frenaría.
4. **No se ve el consumo**: nadie sabe que quedan 42 equipos hasta que falla un
   alta.
5. Usuarios y usuarios externos tienen límite en la licencia y ninguna
   comprobación.

**Qué hacer**

- Back: contar solo equipos **no retirados** (Q12), y comprobar también al
  **reactivar** uno retirado.
- Back: mensaje "Tu plan permite 600 equipos y ya tienes 600. Contacta con
  1A-MIG para ampliarlo", con el nombre del recurso traducido.
- Back: la misma comprobación en los comandos que crean equipos (`seed_*`,
  V3-37), antes de escribir nada: o caben todos, o no se crea ninguno.
- Back: endpoint de uso (`license/usage/`): usados / permitidos por recurso.
- Front: en Configuración → Licencia, barra "558 / 600 equipos"; aviso en la
  cabecera para el administrador al pasar del 90 %.
- Usuarios: mismo mecanismo en el alta de usuarios, si el cliente lo quiere ya;
  si no, ticket aparte.

**Criterios de aceptación**

- **AC-01** Dada una licencia de 600 equipos con 600 activos, cuando se intenta
  crear uno más, entonces se rechaza con el mensaje nuevo, en español.
- **AC-02** Dados 600 equipos de los que 10 están retirados, cuando se crea uno,
  entonces se permite (cuentan 590).
- **AC-03** Dado el cupo lleno, cuando se intenta reactivar un retirado,
  entonces se rechaza igual que un alta.
- **AC-04** Dado el cupo lleno, cuando se registra una lectura en un equipo
  existente, entonces se guarda: se bloquea el crecimiento, no el trabajo.
- **AC-05** Dado un comando que traería 50 equipos con 20 de cupo, cuando se
  ejecuta, entonces no crea ninguno y dice cuántos sobran.
- **AC-06** Dada la pantalla de licencia en AMBEV, cuando se abre, entonces
  muestra "558 / 600 equipos".

**Pregunta abierta**: Q12 (qué cuenta y qué pasa al superar el límite).
