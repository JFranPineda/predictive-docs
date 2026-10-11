# Informe de la revisión del 8 de octubre de 2026 (T1–T14)

Las 14 tareas están hechas, probadas en el espejo (8012/5175) y revisadas en la
instancia real (5174). Todo está commiteado y sin push. Las respuestas para el
usuario también quedaron en [screens-guide.md](screens-guide.md).

## Cambios en la interfaz

- **T1 Alineamiento:** ahora tiene CRUD completo.
  - La página es una tabla del mes con buscador.
  - **+ Nuevo alineamiento** registra un trabajo puntual sin orden: eliges el
    conjunto y llenas el mismo formulario SKF que en la visita.
  - Cada fila abre la ficha completa, editable y con botón para eliminar. Solo
    puede editar quien tiene permiso.
  - Probado creando, editando y borrando un registro en el espejo.
- **T2 UT en rodillos:** nueva pestaña **Grupos y rodillos**.
  - Un grupo se crea con su sector, se renombra y se puede borrar si está vacío.
  - Los rodillos se agregan por rangos, se retiran, se vuelven a poner en
    servicio o se eliminan si nunca se midieron. Uno que ya tiene medidas solo
    se puede retirar.
- **T4:** Estructura pasó al bloque Configuración, junto a Tipos de conjunto.
- **T5:** el botón del menú queda marcado en sus páginas internas: en
  `/measurements/groups/122` sigue marcado Mediciones. Comprobado en todas las
  secciones.
- **T7 Informes de Planta:** había un bug, la página mostraba siempre la planta
  1. Ahora hay selector de planta. Además:
  - abre en el servicio que cubre más equipos;
  - tiene «Expandir todo» y la hora de actualización;
  - el nombre de cada conjunto abre su registro de valores;
  - ya no se desborda horizontalmente.
- **T12 Tipos de conjunto:** buscador por nombre del tipo, nombre de un conjunto
  o TAG de un equipo. Si buscas `MR311003`, dice que está en ACCIONAMIENTO
  BARRIDO LENTO.
- **T13 Permisos:**
  - buscador y filtro «solo los concedidos»;
  - contador «x de y» por módulo y botones Todos/Ninguno;
  - barra fija con los cambios sin guardar (Guardar / Descartar);
  - aviso si se cambia de rol con cambios pendientes.
- **T14 Tipos de medición:** agrupado por servicio, con buscador y filtro.
  - Las agregaciones se leen como RMS, Pico, Pico a pico…
  - «Cuadro fijo» y «Solo plantilla» son columnas propias.
  - Altas, ediciones y bajas en un modal, también para las unidades.

Alineamiento, UT, Informes de Planta y Tipos de medición tienen además un
recuadro plegable «¿Qué se registra aquí?» con un ejemplo.

## Respuestas

**T3 · Mediciones, Servicios y Ejecución** (las dos primeras URLs de la
pregunta eran iguales; se asumió que la segunda era Ejecución,
`/services/authorship`):

- **Servicios** responde «¿qué se mandó a hacer?»: las órdenes, con técnica,
  fechas y empresa. Cada orden tiene una visita por equipo.
- **Ejecución** responde «¿quién lo hizo?»: el autor de cada visita, con sus
  lecturas, fotos y firma.
- **Mediciones** responde «¿cómo está este conjunto en el tiempo?»: el registro
  de valores con todas las rondas, las tendencias y los espectros.

**T6 · Jornada**, en este orden:

1. El ingeniero jefe abre el día.
2. Por cada trabajo sobre un conjunto se registra un servicio.
3. El servicio necesita tres firmas de inicio. Sin ellas, los campos de ese
   conjunto quedan bloqueados, salvo que un administrador lo desbloquee.
4. Se llena el ATS y firma el personal que ejecuta.
5. El jefe cierra el servicio con su clave; esa hora queda como hora final.
6. El jefe cierra el día. Solo el jefe o un administrador pueden reabrirlo.

**T7, T8, T9 · Informes:** ninguno se crea a mano.

- **Informes de Planta** es un tablero en vivo. Se calcula solo con la última
  lectura de cada equipo y cambia cada vez que alguien guarda una ronda.
- **Informes MPd y END** se generan de una orden ya trabajada: se elige orden (y
  conjunto, en MPd), se ve tal como se imprimirá y se descarga en PDF o Excel.
- El contenido sale de las visitas: lecturas, diagnóstico y el «Diario del
  equipo» que escribe el analista. Si eso está incompleto, el informe sale
  incompleto.

**T10 · Estados por servicio: sí.** Antes no se podía editar desde la pantalla;
ahora está en Estados → **Condiciones por servicio**. Cada servicio tiene su
conjunto: Alineamiento el suyo (el «01» de la pregunta) y Vibraciones el suyo
(el «02»).

- «Vibraciones 2» como **otro servicio no conviene**: con y sin aisladores es el
  mismo servicio con los mismos estados, y crear otro partiría el historial de
  cada equipo en dos. Lo que cambia son los límites, y eso va en Umbrales.

**T11 · Umbrales: sí a los tres.**

- **11.1** Alineamiento usa la escala por RPM de su norma.
- **11.2** Vibraciones sin aisladores = clase **cimentación rígida** de
  ISO 10816-3, por ejemplo 2,8 / 4,5 mm/s.
- **11.3** Con aisladores = clase **cimentación flexible**, por ejemplo
  4,5 / 7,1 mm/s.
- El sistema elige la clase de cada equipo por su placa: potencia y tipo de
  cimentación. Un equipo que no encaja en la norma usa una norma propia.

## A tener en cuenta

- **Quitar estados de un servicio:** el sistema no deja quitar uno que todavía
  usa un umbral activo de ese servicio. Pero las escalas de alineamiento no se
  revisan, así que hay que comprobar la escala antes de quitarle un estado a
  Alineamiento.
- **Migración nueva:** `thresholds.0005` saca «Observación» de Mantenimiento y
  Lubricación (la había añadido la migración anterior). Ya está aplicada en
  AMBEV e IPSA.
- **Error corregido:** se reformatearon tres ficheros del front con `prettier`
  sin la configuración del repo y cambiaron a comillas dobles. Uno ya estaba en
  el commit `e43b572`. Se rehicieron sobre el original y quedó arreglado en
  `6322d01`.

**Puertas en verde:** pytest, lint-imports (2/2), makemigrations --check, tsc,
eslint y vitest (164).

**Commits:**

- back: `a457daa`, `4897df8`, `974193e`, `aeeffce`, `5cf126f`
- front: `970a677`, `5a34de7`, `e43b572`, `cf8372a`, `6322d01`, `79c30ec`, `3f6f7c9`
- docs: `f9ed083`
