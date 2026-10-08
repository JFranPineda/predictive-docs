# Guía de pantallas: qué es cada una y cómo se usa

Respuestas a las preguntas de la revisión del 8 de octubre de 2026 (T1–T14),
escritas para quien usa el sistema, no para quien lo programa. Cada pantalla
abre además con un recuadro plegable **«¿Qué se registra aquí?» / «¿Cómo
funciona?»** con lo mismo, resumido.

## Mapa rápido

| Menú | Para qué sirve | Quién la llena |
|---|---|---|
| **Jornada** | Abrir y cerrar el día, registrar cada servicio con su ATS y sus firmas | Ingeniero jefe, líder del servicio, supervisores |
| **Servicios** | Las órdenes de servicio: qué técnica, qué planta, qué fechas, qué empresa | Administración / planificación |
| **Ejecución** | Quién ejecutó cada visita de cada orden | Se llena sola al trabajar; se consulta |
| **Mediciones** | El historial de un conjunto: registro de valores, tendencias, espectros | Se llena con las visitas; se consulta y se corrige |
| **Alineamiento** | Cada alineamiento láser (antes/después, estado, imágenes) | Técnico de alineamiento |
| **UT en rodillos** | Espesores de rodillos, muñones, resumen e informe | Técnico de END |
| **Informes de Planta** | Semáforo en vivo de la planta | Nadie: se calcula solo |
| **Informes MPd / END** | Documentos para el cliente (PDF y Excel) | Nadie: se generan de los datos de la orden |

## T3 · Mediciones, Servicios y Ejecución — la diferencia

Las tres miran los mismos datos desde tres preguntas distintas:

- **Servicios** (`/services`) responde *«¿qué se mandó a hacer?»*. Una **orden de
  servicio** es la ronda programada: técnica (vibraciones, termografía…),
  planta, fechas, empresa ejecutora, OT del cliente y norma del informe. Una
  orden tiene **visitas**: una por equipo inspeccionado. Aquí se crean y
  administran las órdenes.
- **Ejecución** (`/services/authorship`) responde *«¿quién lo hizo?»*: cada
  visita con su autor y participantes, sus lecturas, fotos y firma. Sirve para
  auditar el trabajo de campo y para que cada técnico vea y corrija lo suyo
  («Solo los míos»).
- **Mediciones** (`/measurements`) responde *«¿cómo está este conjunto en el
  tiempo?»*. No se organiza por orden sino por **conjunto**: el registro de
  valores con todas las rondas en columnas, las tendencias y los espectros. Es
  la vista del analista.

Ejemplo: la orden **MPd-AV-N°006-26** (Servicios) visitó 558 equipos; la visita
del REDUCTOR R311003 la hizo Jorge Aliaga (Ejecución); y en Mediciones →
ACCIONAMIENTO BARRIDO LENTO se ve esa lectura como una columna más junto a las
de abril, mayo, junio…

## T1 · Alineamiento (`/alignment`)

**Qué se registra:** el alineamiento láser del eje entre dos máquinas de un
conjunto (motriz → conducida), medido antes y después de corregir.

- Ocho valores: angular y paralelo, horizontal y vertical, antes (As Found) y
  después (As Corrected). Angular en mm/100 mm, paralelo en mm.
- Con las RPM, la norma de alineamiento da la tolerancia y el **estado** del
  equipo antes y después (Operativo, Observación, Alarma…).
- Las imágenes del alineador **por conjunto**: SKF entrega una con antes y
  después; otro alineador, una por fase. Más la foto del conjunto y hasta dos
  de la observación.

> Ejemplo — BBA. AGUA CRUDA TAG:A · Motor → Bomba · 1780 rpm · SKF TKSA 41.
> Antes: angular H 0.08, paralelo H 0.12, angular V 0.05, paralelo V 0.10 →
> **Alarma**. Después: 0.02 · 0.03 · 0.01 · 0.02 → **Operativo**.

**CRUD:** la pantalla lista los alineamientos del mes (buscador por conjunto,
máquinas u orden). **+ Nuevo alineamiento** registra un *trabajo puntual* sin
orden: se elige el conjunto y se llena el mismo formulario que en la visita.
Cada fila abre la ficha completa, editable y eliminable por quien puede
editarla. Si el alineamiento es parte de una orden de alineamiento, se
registra desde la visita de esa orden y aparece aquí con su código.

## T2 · UT en rodillos (`/ut-rollers`)

**Qué se registra:** la inspección por ultrasonido del **espesor de pared** de
rodillos (secadores, prensas), para saber cuánto material les queda.

- **Espesores:** seis medidas por rodillo (P1–P6); la menor decide el estado
  según la norma de UT (Aceptable, Medio, Crítico; Inaccesible si no se llegó).
- **Muñones (prensas):** por lado de la prensa, el rollo, diámetro, longitud
  externa y total, y su estado.
- **Resumen de resultados:** el cuadro de la orden, dato por dato.
- **Informe del conjunto:** conclusiones, recomendaciones, plano y fotos.

> Ejemplo — Orden END-UT-012 · Secadores grupo 1 · Rodillo 7: P1 9.10 · P2 8.95
> · P3 8.40 · P4 8.62 · P5 7.85 · P6 8.90 mm → mínimo 7.85 → **Medio** (entre
> 6.14 y 8.01).

**CRUD:** pestaña **Grupos y rodillos**: crear un grupo con su sector,
renombrarlo, eliminarlo si está vacío; agregar rodillos por rangos (`1-28,
30`), retirarlos, volverlos a servicio, o eliminarlos si nunca se midieron (uno
medido solo se retira: sus órdenes ya se informaron con él). Pestaña
**Registrar una orden**: elegir orden y grupo y llenar las cuatro pestañas.

Paso a paso: 1) crear grupo y rodillos (una vez); 2) en Servicios, crear la
orden con la técnica «END · UT en rodillos»; 3) aquí, llenarla.

## T6 · Jornada (`/workday`)

La jornada es el **día de trabajo en planta**, con candado:

1. **El ingeniero jefe abre la jornada** del día.
2. Por cada trabajo sobre un conjunto se **registra un servicio**: conjunto,
   orden (o trabajo puntual) y actividad.
3. El servicio necesita **tres firmas de inicio** — ingeniero de producción,
   líder del servicio y supervisor de planta. **Sin ellas, los campos de ese
   conjunto quedan bloqueados** para los técnicos (las pantallas lo dicen y el
   servidor rechaza el guardado). Un administrador puede desbloquearlo.
4. Se llena el **ATS** del servicio (formato del cliente: titular, área, zona,
   categoría de riesgo, EPP, herramientas, pasos con peligros, riesgos, IPERC y
   controles) y firma el **personal ejecutor**.
5. **Cierre del servicio:** el ingeniero jefe o un admin firma con su clave; esa
   hora es la **hora final**. Solo se puede con el ATS completo y firmado (la
   pantalla lista lo que falta).
6. **Cierre de la jornada:** con la clave del jefe. Desde ahí los técnicos ya no
   modifican nada de ese día. **Reabrir** solo lo pueden el ingeniero jefe y los
   administradores (permiso propio en Permisos).

El módulo es opcional: desinstalarlo quita el candado.

## T7 · Informes de Planta (`/summaries`)

- **No se crea a mano.** Es un tablero en vivo: se calcula solo con la última
  lectura de cada equipo en cada servicio. Una pestaña por servicio.
- **Cambia cada vez que alguien guarda** una ronda, una visita o el registro de
  valores; cada área muestra qué equipo la pinta, quién lo midió y cuándo.
- El color de un área es el **peor** estado de sus equipos. Se despliega por
  sector y conjunto; el nombre de un conjunto abre su registro de valores.
- **Mejoras:** selector de planta (estaba fijo en la planta 1), abre en el
  servicio que cubre más equipos, «Expandir todo», fecha de actualización,
  leyenda integrada y explicación plegable.

## T8 · Informes MPd (`/reports/mpd`)

- **No se crean a mano:** se **generan** de los datos de una orden ya
  trabajada. Aparecen las órdenes de la familia MPd con al menos una visita.
- Se elige **orden** y **conjunto**; se ve tal como se imprimirá y se descarga
  en **PDF o Excel**. Contiene cabecera, esquema y foto, antecedentes, estado
  actual, recomendaciones, registro de valores, límites, tendencias, espectros,
  termogramas y alineamiento si aplica.
- **De dónde salen los datos:** de las visitas — lecturas, diagnóstico y el
  «Diario del equipo» (conclusiones y recomendaciones) que escribe el analista.
  Para que un informe salga completo hay que completar eso en la visita.
- Pestañas extra: **Resumen mensual** (por planta y mes, con el conteo por
  estado) y **Correctivos** (si el módulo de mantenimiento está instalado).
- Lo ve quien tenga el permiso del módulo de informes.

## T9 · Informes END (`/reports/end`)

Igual que MPd, para la familia **END** (ensayos no destructivos): se elige la
orden y se genera el informe con la tabla de elementos y su estado (p. ej.
rodillos: espesores y resumen por estado), muñones, fotos comentadas,
conclusiones y recomendaciones — lo que se llenó en UT en rodillos, tintes
penetrantes o partículas magnéticas. PDF o Excel.

## T10 · Estados: ¿un conjunto de condiciones por servicio?

**Sí.** En **Estados** → **Condiciones por servicio** cada servicio tiene su
propio conjunto de estados: en cuáles puede calificar su norma y cuáles puede
declarar el técnico en lugar de un valor (Apagado, Fuera de servicio). Un
estado puede llevar otro nombre solo en ese servicio (UT llama «Medio» a la
Alarma).

- Conjunto de condiciones **01 → Alineamiento**: sí, es el de Alineamiento.
- Conjunto **02 → Vibraciones**: sí, es el de Vibraciones.
- «**Vibraciones 2**» (equipos con aisladores) como **otro tipo de servicio**:
  **no hace falta, y no conviene.** Con y sin aisladores es el *mismo* servicio
  con los *mismos* estados; lo que cambia son los **límites**. Eso se resuelve
  en Umbrales (T11). Crear otro servicio partiría el historial de los equipos en
  dos.

El sistema no deja quitar de un servicio un estado que todavía usa algún
umbral activo de ese servicio: primero se cambia el umbral.

## T11 · Umbrales por conjunto de condiciones

- **11.1 Umbrales para el conjunto de Alineamiento:** sí. La norma de
  alineamiento tiene su escala por RPM (Normas → norma SKF): para cada tramo de
  RPM, hasta qué valor es cada estado.
- **11.2 Umbrales para vibraciones sin aisladores:** sí. En ISO 10816-3 / 20816-3
  cada **clase de máquina** tiene sus límites, y las clases ya distinguen
  **cimentación rígida** (sin aisladores) de **flexible** (con aisladores). Un
  juego de umbrales se crea para la clase «Grupo 2 · cimentación rígida»
  (p. ej. 2.8 / 4.5 mm/s).
- **11.3 Umbrales distintos para vibraciones con aisladores:** sí: otro juego
  para «Grupo 2 · cimentación flexible» (p. ej. 4.5 / 7.1 mm/s).

**Cómo sabe el sistema cuál aplica a cada equipo:** por la **placa** del
equipo (Datos de fábrica → potencia y **cimentación rígida/flexible**) clasifica
la máquina sola. Si un equipo no encaja en la norma (como la Pulper Nº 04), se
le asigna una **norma propia** y se marca «mantener su propia norma» (Q16).

## T4, T5, T12, T13, T14 — cambios de interfaz

- **T4** Estructura pasa al bloque **Configuración**, junto a Tipos de conjunto.
- **T5** El botón del menú queda marcado en todas sus páginas internas
  (Mediciones → tendencia de un conjunto sigue marcando Mediciones).
- **T12** Tipos de conjunto tiene buscador por nombre del tipo, nombre de un
  conjunto o **TAG** de un equipo (p. ej. `MR311003`), y dice qué conjuntos
  coincidieron.
- **T13** Permisos: buscador, «solo los concedidos», contador «x de y» por
  módulo, botones **Todos/Ninguno** por módulo, barra fija de cambios sin
  guardar (Guardar / Descartar) y aviso al cambiar de rol con cambios pendientes.
- **T14** Tipos de medición: agrupado por servicio, buscador y filtro, nombres
  legibles de agregación, columnas «Cuadro fijo» y «Solo plantilla», y altas,
  ediciones y bajas en un modal (también para unidades).
