# Informe de la revisión del 10 de octubre de 2026

Encargo: guardar el informe anterior (T1), mejorar la experiencia de uso del
front (T2), revisar y reparar el backend (T3), comprobar que la modularidad
funciona de verdad (T4) y dejar Usuarios y Permisos impecables para el
administrador (T5).

Todo se probó en el espejo (copia de la base real, servidores 8012/5175) y no en
la base real. Commits locales, sin push.

## T1 — Informe anterior

Guardado en [review-2026-10-08-report.md](review-2026-10-08-report.md).

## T3 — Backend: cómo se revisó y qué se reparó

No se revisó leyendo: se atacó la API completa con cuatro herramientas.

1. **Rastreo de lectura**: todas las rutas GET (219 patrones) con identificadores
   reales, como administrador y como técnico. Resultado: ningún 500.
2. **Fuzz de escritura**: todas las rutas POST/PATCH/PUT/DELETE con cuerpos vacíos
   y basura, dentro de una transacción que se revierte. **Encontró 26 rutas que
   respondían 500**; hoy, 0 de 1.220 peticiones, para administrador y técnico.
3. **Escenario de usuarios y permisos**: 44 comprobaciones de punta a punta.
4. **Rastreo de alcance por áreas**: un usuario limitado a un área pide datos de
   otra área por su identificador.

Reparado:

- Datos mal formados (una palabra donde va un número o un id) daban 500: ahora
  400 con el motivo; un borrado bloqueado o un choque de datos, 409. Siempre
  queda la traza en el log.
- **Borrar un sector con conjuntos fallaba siempre** (intentaba desactivar un
  campo que los sectores no tienen): ahora se rechaza diciendo por qué.
- Añadir un participante a una visita sin elegir a nadie rompía en la base de
  datos: ahora exige a alguien de la empresa.
- Borrar un estado que solo ofrecían algunos servicios quedaba bloqueado.
- Cinco pantallas con foto o firma (alineamiento, topografía, UT, ATS) daban 500
  si se usaba el método equivocado en su ruta: ahora 405.
- El candado de jornada convertía identificadores basura en 500.
- Una visita inexistente daba 500 en lugar de 404.
- **Al borrar una imagen o un espectro, el fichero se borraba antes de confirmar
  el cambio**: si algo fallaba después, la fila volvía y el fichero ya no. Ahora
  el fichero se borra solo cuando la transacción confirma.
- Ejecución: el backend acepta filtrar por orden, texto y fechas.

## T5 — Usuarios y permisos

Fallos de seguridad encontrados y cerrados:

- **Cualquier usuario veía la lista completa de personas** con correo, rol y
  permisos. Ahora quien no gestiona usuarios recibe solo un directorio (nombre,
  iniciales, rol), que es lo que usan los selectores de participantes.
- **La lista de roles no exigía permiso.** Ahora requiere gestionar roles o
  usuarios.
- **Escalada de privilegios**: un gestor con permiso de roles pero sin ser
  administrador podía darse permisos que no tenía, subir un rol a
  administrador o crear un administrador. Regla nueva: **nadie reparte lo que
  no tiene**; el acceso de un administrador solo lo cambia otro administrador.
- **Instalar, desinstalar y actualizar módulos no exigía ningún permiso**: un
  técnico podía hacerlo por la API. Ahora exige `core.manage_modules`.
- **Quitar el acceso a alguien no lo sacaba**: sus sesiones seguían activas
  hasta caducar y podía volver a entrar a una pantalla vacía. Ahora queda fuera
  al siguiente clic, y el login le dice que su acceso fue retirado.
- **El alcance por áreas solo se cumplía en las listas**: por identificador se
  podía abrir la tendencia, la placa, la galería, el Excel de un equipo, una
  visita, su operación, su levantamiento topográfico, espectros, imágenes e
  informes de otras áreas. Cerrado en todas.
- Editar un usuario partía el nombre completo por el primer espacio y, al
  guardar, «Juan Carlos Pérez» quedaba como nombre «Juan».

Mejoras para el administrador:

- **Alta de usuario**: el rol ya no viene preseleccionado (el primero de la lista
  podía ser Administrador); botón para generar y mostrar la contraseña; al crear,
  las credenciales quedan en pantalla para copiarlas y entregarlas en persona.
- **Quitar acceso, desactivar, reemitir o revocar el código** piden
  confirmación y explican qué pasa con los registros de la persona.
- **Cambiar rol o turno** confirma con un aviso que permite deshacer.
- Los errores salen como aviso visible, no en una línea arriba de la página.
- **Permisos**: los roles nuevos se abren directamente para marcar sus permisos;
  cambiar de rol con cambios pendientes y borrar un rol usan el mismo diálogo.

## T4 — Modularidad, comprobada de punta a punta

- **Ciclo completo**: se desinstalaron por la API los 20 módulos opcionales en
  orden de dependencias. Con solo el núcleo instalado, la API no dio ni un 500 y
  el front cargó todas las pantallas restantes sin una sola petición fallida de
  fondo. Al reinstalarlos todos, órdenes, normas, umbrales y los permisos de
  cada rol quedaron idénticos.
- **Dependencias ocultas del front**: ocho pantallas usaban piezas de módulos que
  se pueden desinstalar por separado (galerías, operación y lista de fallas de la
  visita, imágenes y placa del registro de valores, fallas del espectro, selector
  de norma, filtro de estados, nombres de medidas). Ahora cada una oculta esa
  pieza si su módulo no está instalado.
- El rechazo al desinstalar un módulo requerido ya no sale en inglés con códigos:
  dice «No se puede desinstalar «Umbrales»: lo necesitan «Alineamiento», …».

## T2 — Experiencia de uso

- **Avisos y confirmaciones** comunes a todo el sistema: cada acción dice si salió
  bien o mal donde la persona está mirando, con «Deshacer» cuando se puede.
- **Todo borrado pregunta antes**: 25 botones en 18 pantallas actuaban al primer
  clic.
- **Tablet y móvil**: por debajo de cierto ancho el menú es un cajón con botón ☰
  y nombre de la pantalla actual; los márgenes se adaptan.
- **Buscador en el menú** y **nombre de la pantalla en la pestaña** del navegador.
- **Si una pantalla falla**, se muestra un mensaje con Reintentar/Recargar dentro
  del sistema, no una página en blanco.
- **Aplicaciones**: instalar, desinstalar y actualizar muestran el resultado (el
  rechazo antes desaparecía y parecía que el botón no hacía nada), desinstalar
  pregunta, las dependencias salen con nombre y cada módulo enlaza a Permisos
  para repartir sus permisos nuevos.
- **Ejecución**: con 4.884 visitas no había forma de llegar a la mayoría. Ahora
  tiene buscador, filtro por orden, rango de fechas y páginas; el número de
  equipos de cada orden abre exactamente sus visitas.
- **Servicios**: anular una orden pregunta; los códigos ya no se parten en tres
  líneas.
- **Activos**: las tarjetas «En alarma» y «En parada» filtran la tabla.
- **Jornada**: recuadro «¿Cómo funciona la jornada?» con los seis pasos.
- **Login**: si la contraseña es correcta pero el acceso fue retirado, lo dice.

## Incidente durante la revisión

El fuzz de escritura revierte la base de datos, pero el espejo usaba **la misma
carpeta de ficheros que la instancia real**, y los borrados de ficheros no se
revierten. Se perdieron dos ficheros que la base real referencia:

- **Datos del espectro 432**: era dato de demostración sintético; se regeneró en
  la misma ruta (pico 24,5 Hz, igual al registrado). Restaurado.
- **Una imagen de tipo documento** de la visita 4328 (COMPRESOR C122001, orden
  MPd-AC-N°004-26), subida el 25 de septiembre por carlos.balta@simiai.pe, y su
  miniatura. **No se puede recuperar**: no hay copia en disco. La ficha aparece
  sin imagen; hay que volver a subirla o eliminar esa ficha.

Para que no se repita: el espejo usa ahora su propia carpeta de ficheros, y la
causa de fondo (borrar el fichero antes de confirmar) está corregida en el
código.

## Puertas

pytest en verde, lint-imports 2/2, makemigrations --check sin cambios,
`manage.py check` sin avisos, ruff sin regresiones, tsc, eslint, vitest (164) y
`vite build` en verde. No hubo migraciones nuevas en esta revisión.

## Commits

- back: `c9e0c9e`, `35dbc04`, `3486b68`, `31bfd39`, `5d34ef7`, `ce34331`, `c082df0`, `496e196`
- front: `3740241`, `002f880`, `1bdf7b3`, `3af15ff`, `697865a`, `d0b75af`, `b4060d0`, `4c50237`
