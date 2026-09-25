# Resumen del proyecto — para retomarlo en otra sesión

Sistema web tipo ERP de **mantenimiento predictivo** (vibraciones, ultrasonido,
termografía, aceite, END por espesores). Nace de los Excel reales que el cliente
usaba, y su objetivo es reemplazarlos: si el entregable no sale del sistema, la
hoja de cálculo sigue mandando.

Estado al **2026-09-25**: sistema funcionando de punta a punta en local, con
558 equipos reales cargados, 63 324 lecturas de 6 servicios, 1 848 imágenes y
431 espectros. **42 commits en `predictive-back`, 42 en `predictive-front`,
5 en `predictive-docs`. Nada está pusheado** — el push lo decide el usuario.

> **Lee primero la sección 7 (bugs encontrados) y la 8 (trampas del entorno).**
> Son lo que no se deduce del código y lo que hace perder una tarde.

---

## 1. Los tres repos

| Repo | Qué es |
|---|---|
| `predictive-docs` | Los Excel originales del cliente + el blueprint (`docs/00` a `docs/08`) + las fuentes v2 de ultrasonido. **Fuente de verdad del diseño.** |
| `predictive-back` | Django 5 + DRF, hexagonal, módulos instalables estilo Odoo |
| `predictive-front` | React 19 + TS + Vite + RTK Query + Tailwind 4, modular |

**Antes de tocar código, leer `docs/00-source-analysis.md` y
`docs/01-architecture.md`.** El modelo sale de los Excel del cliente, no de
suposiciones, y el doc 00 explica por qué cada decisión es como es.

Fuentes que gobiernan partes concretas:

| Carpeta | Qué gobierna |
|---|---|
| `docs/vibration/reports/*.xlsx` | 9 informes reales. Definen la forma de los conjuntos rotativos y del registro de valores |
| `docs/v2/INFORME ULTRASONIDO - IPSA AGOSTO 2026.docx` | UT convencional sobre muñones de polines: fisuras, socavación, espesores |
| `docs/v2/ORDEN_14778.xlsx` | Espesores P1–P6 por polín, con sus veredictos ACEPTABLE/MEDIO/CRÍTICO |
| `docs/v2/Mejoras a los Cuadros de Vista de Planta.docx` | Qué debe mostrar el semáforo: valor + tag, y qué filas sobran del registro |

---

## 2. Cómo levantarlo

### Puertos — hay dos convenciones en conflicto en el repo

| | Puerto en uso | Default del código |
|---|---|---|
| **predictive-front** | **5174** | 5173 (`vite.config.ts`) |
| **predictive-back** | **8010** | 8000 (`make run`) |

El `.env` del backend tiene `CORS_ORIGINS=...:5174` y este documento usa 8010.
Por eso **sin variables de entorno los dos no se encuentran**. Merece la pena
unificarlo algún día; mientras tanto, usar siempre estos comandos:

```bash
# Terminal 1 — backend (venv ya creado en el repo)
cd predictive-back
./.venv/bin/python manage.py runserver 127.0.0.1:8010

# Terminal 2 — frontend
cd predictive-front
VITE_PORT=5174 VITE_API_PROXY=http://127.0.0.1:8010 npx vite --host 127.0.0.1
```

**No hay CORS en desarrollo.** Vite proxya `/api` al backend, así que para el
navegador es el mismo origen y el token no viaja cross-site. Lo único que
importa es que `VITE_API_PROXY` apunte al puerto de `runserver`.

- Front: **http://127.0.0.1:5174** · API: **http://127.0.0.1:8010/api/docs/**

### Usuarios (contraseña `predictive2026`)

| Correo | Rol | Para qué sirve probarlo |
|---|---|---|
| `admin@simiai.pe` | Administrador | Todo; emite códigos de acceso |
| `carlos.balta@simiai.pe` | Ingeniero | Corrige y cierra visitas |
| `gerencia@ambev.com.pe` | Gerente General | Solo lectura: comprueba que **no** puede tocar datos de campo |
| `subgerencia@ambev.com.pe` | Subgerente de Planta | Solo lectura |
| `jefe.mtto@ambev.com.pe` | Jefe de Mantenimiento | Solo lectura + **auditoría** |
| `jorge.a@simiai.pe` | Personal Técnico · Turno A | Entra con **código**, no con correo |
| `henry.tejada@contratista.pe` | Inspector externo | Escribe solo su visita |
| `cliente@ambev.com.pe` | Cliente | Solo lectura |

### Comandos

```bash
# Tests
cd predictive-back  && ./.venv/bin/python -m pytest tests/unit   # ver sección 8: pytest NO está instalado
cd predictive-front && npx vitest run && npx tsc --noEmit        # 101, sí funcionan

# Resembrar desde cero (DESTRUCTIVO: borra la BD del inquilino)
cd predictive-back
rm -f data/tenant_ambev.sqlite3
./.venv/bin/python manage.py tenants migrate ambev
./.venv/bin/python manage.py tenants run ambev seed_demo --docs ../predictive-docs
./.venv/bin/python manage.py tenants add ambev "AMBEV Perú — Planta Huachipa" \
    --url "sqlite:///data/tenant_ambev.sqlite3" --deployment on_premise
./.venv/bin/python manage.py tenants issue ambev --plan enterprise --months 12 \
    --equipment 600 --plants 2 --users 25

# Aditivos e idempotentes (correrlos dos veces reporta ceros)
./.venv/bin/python manage.py tenants run ambev seed_more                    # ultrasonido, aceite, multimedia, espectros
./.venv/bin/python manage.py tenants run ambev seed_profiles --demo-users   # los 4 perfiles de la matriz de acceso
./.venv/bin/python manage.py tenants run ambev media_convert                # derivadas de imagen, sin Redis

# Migrar sin resembrar (aditivo, seguro)
./.venv/bin/python manage.py tenants migrate ambev
```

> ⚠️ **No usar `pkill -f "manage.py runserver"`**: el patrón coincide con la
> propia línea de comandos del shell y mata la sesión. Ya pasó dos veces.

### Exponerlo por un túnel (cloudflared)

Tunelar **solo el front**; Vite proxya `/api` y el backend nunca queda expuesto.

```bash
cloudflared tunnel --url http://127.0.0.1:5174
```

Hacen falta dos cosas, y el comodín importa porque `trycloudflare` estrena
subdominio en cada arranque:

```bash
# predictive-back/.env      (punto inicial = dominio y subdominios, sintaxis de Django)
ALLOWED_HOSTS=localhost,127.0.0.1,.trycloudflare.com
```
```ts
// predictive-front/vite.config.ts, dentro de `server`
allowedHosts: ['.trycloudflare.com'],
```

`CORS_ALLOWED_ORIGINS` **no acepta comodines** (solo cadenas exactas, y una
barra final impide arrancar el servidor). El comodín vive en
`CORS_ALLOWED_ORIGIN_REGEXES`, y solo hace falta si expones el backend por su
propio túnel. Vite **no** recarga `vite.config.ts` en caliente.

> Abrir a internet un servidor con `DEBUG=1` expone tracebacks y `/admin/`.
> Para una demo corta vale; no dejarlo levantado.

### Datos sembrados

558 equipos · 3 348 puntos · **63 324 lecturas** · 4 884 visitas · 18 órdenes ·
1 848 imágenes en 268 equipos · 431 espectros · 24 juegos de umbrales ·
45 modos de falla · 3 instrumentos · 9 usuarios · 9 roles.

Lecturas por servicio: vibraciones 40 176 · termografía 20 088 ·
análisis de aceite 1 152 · ultrasonido 948 · espesores UT 948 ·
aceite dieléctrico 12.

---

## 3. Lo que los Excel enseñaron (y que no es obvio)

Estas son las trampas del dominio. Romper cualquiera de ellas rompe el sistema
de forma silenciosa.

1. **La jerarquía real tiene 5 niveles**: Área → Sector → Conjunto Rotativo →
   Equipo → Punto. No área→equipo. Los límites y las conclusiones se emiten al
   **conjunto**; el estado y el TAG viven en el **equipo**.
2. **El TAG del cliente no es único**: `MB1141001B` aparece en el motor y en la
   bomba de EB 228. `asset_code` es obligatorio y se autogenera; `client_tag`
   es opcional.
3. **Condición ≠ disponibilidad.** `operativo/alarma/parada` se *calculan*;
   `apagado/retirado/fuera de servicio` se *declaran*. El 13 % del RGP era
   "APAGADO": mezclarlos envenena todo KPI. Y el vocabulario **cambia por
   técnica** (mantenimiento no tiene alarma; vibraciones no retira equipos).
4. **`Gs pico` ≠ `Gs pico-pico`.** La agregación es parte del criterio, no una
   etiqueta: 10 gE es *parada* en una escala y *alarma* en la otra.
5. **Una norma juzga la técnica para la que fue escrita.** NETA MTS no puede
   colgar de una magnitud de vibraciones. Validado en el dominio.
6. **Antecedentes, conclusiones y recomendaciones son líneas fechadas con
   autor**, no un campo de texto. Por eso un antecedente de 2013 convive con
   una conclusión de 2014 en el mismo reporte.
7. **Un termograma radiométrico no se recomprime nunca**: lleva la matriz de
   temperaturas en metadatos y al convertirlo se pierde el dato.
8. **"No medido" es una fila**, no una ausencia de fila. Sin eso no hay KPI de
   cobertura del plan.
9. **Una columna del registro es la orden de servicio, no un instante**: el
   motor y la bomba del mismo tren se visitan con horas de diferencia.
10. **`es-PE` escribe `1,234.50` igual que `en-US`**; el que usa coma decimal
    es `es-ES`. Nunca asumir "español = coma". Todo por `Intl`.
11. **Los componentes de un conjunto no llevan los mismos puntos**, y la
    numeración corre a lo largo del tren, no de la máquina.
    `docs/vibration/reports` trae tres formas: MOTOR 2 + REDUCTOR 4;
    MOTOR 2 + REDUCTOR 4 + dos CHUMACERAS de 2 (1→10); y CHUMACERA 1 +
    REDUCTOR 5. Suponer dos por máquina se come la mitad de un reductor sin
    avisar.
12. **Un tren puede llevar dos componentes del mismo tipo** (chumacera lado
    mando y lado transmisión). Emparejarlos por tipo y posición no los
    distingue: el equipo guarda su componente (`group_component`) y su orden.
13. **Los límites se resuelven por componente.** El reductor no lo juzga la
    norma del motor; por eso la sección V del reporte lista varias tablas.
14. **Una magnitud no siempre se mide por eje.** La velocidad sí (H/V/A); la
    envolvente, la temperatura del apoyo y el nivel de ultrasonido se leen
    **una vez por rodamiento**. La hoja imprime `1 ENV` y `TEMP 1`, no
    `1H 1V 1A`. Lo dice `Magnitude.per_axis`, y `short_code` guarda el nombre
    en el orden del cliente (escribe `1 ENV` pero `TEMP 1`: no normalizarlo).
15. **Cada servicio reporta en su unidad**, y cuál manda lo declara la técnica
    en `Technique.headline_magnitude`: vibraciones mm/s, ultrasonido dB,
    termografía °C, aceite cSt, dieléctrico kV, espesores mm. Mezclar dos
    escalas en un eje hace desaparecer la señal pequeña.
16. **El espesor empeora al bajar** (`higher_is_worse=False`), igual que la
    viscosidad y la rigidez dieléctrica. El titular de un área es el
    **mínimo**, no el máximo: tomar el máximo muestra el polín más sano y lo
    llama titular.
17. **Ultrasonido aéreo (dB) ≠ UT convencional (mm).** El primero busca
    fricción y fugas; el segundo es un END con palpador de contacto sobre
    muñones de polines. Son **dos servicios**, no dos magnitudes de uno.
18. **Hora de registro ≠ hora de medición.** Una ronda se mide en planta y a
    menudo se digita en oficina días después. El tablero muestra cuándo entró
    al sistema; la de medición va en el tooltip.
19. **El comportamiento del rol, no el permiso, decide si se pueden alterar
    datos de campo.** Un gerente con `measurements.add_reading` marcado por
    error sigue sin poder tocar una lectura, porque su comportamiento base es
    de solo lectura.

---

## 4. Decisiones cerradas (y por qué)

| Decisión | Razón |
|---|---|
| Django + DRF, no FastAPI | La instalación de módulos necesita migraciones por módulo, RBAC y registro; Django los trae. FastAPI queda para `predictive-ml` en fase 3. |
| Hexagonal con `domain/` sin Django | Verificado en CI con `import-linter`. El 70 % de los tests corre sin base de datos, en segundos. |
| Módulos siempre migrados; instalar = estado en BD | Django no recarga `INSTALLED_APPS` en caliente. Desinstalar **nunca** borra histórico. |
| **Dos planos de base de datos** | `default` = nuestro plano de control (Tenant, License, LicenseEvent: 3 tablas). `tenant_<code>` = la base del cliente, puede ser on-premise. Sin FKs entre planos. |
| Licencia HMAC | La verificación corre en *nuestros* servidores. Degrada a solo lectura antes de bloquear. **Sin caché por proceso**: una revocación que llega "según el worker" no es una revocación. |
| Empresa e idioma en `TenantJWTAuthentication` | El middleware corre antes de que DRF valide el JWT. Un `SimpleLazyObject` con un int tampoco vale: el ORM lo rechaza como filtro. |
| Sesión: 30 min de **inactividad** | `ACCESS_TOKEN_LIFETIME=30m`, refresh rotatorio con blacklist. El front renueva ante un 401 y reintenta. |
| i18n en **dos mecanismos** | Interfaz en JSON por módulo (i18next); catálogo (estados, normas, técnicas) en columna `translations` JSONB resuelta en el servidor. |
| Media: `local` por defecto, `s3` en producción | Una instalación de un servidor no tiene MinIO, y una función de fotos que exige object storage no es una función. |
| Nada se borra si tiene historia | Áreas, equipos, umbrales y visitas con lecturas se **desactivan**. Las lecturas congelan el umbral que las juzgó. |
| Paginación por **cursor**, no `OFFSET` | `OFFSET 18000` recorre 18 000 filas para tirarlas. Medido: página 300 en 2,3 ms con cursor contra 11,2 ms con offset. |
| Un rol = permisos **+ comportamiento base** | Los permisos dicen qué pantallas ve; el comportamiento dice si puede escribir datos de campo y de quién. Un comportamiento desconocido falla cerrado a solo lectura. |
| Código de acceso: generado por el servidor, HMAC, mostrado una vez | La gente elige `123456`. Solo se guarda el digest, así que una copia de la BD no es una lista de códigos válidos. |

### Respuestas del usuario a las preguntas abiertas

- **Hosting**: VPS 8 de Contabo, Postgres propio (Timescale como extensión).
  El **disco** es el límite (~100 GB/año/planta), no la CPU → `docs/07`.
- **Offline**: no hay cobertura en planta; se digita en oficina. Fuera la PWA.
- **Instrumentos**: SEMAPI y SKF, sin límite.
- **Multi-cliente**: sí, multitenant desde el día 1.
- **Análisis de aceite**: entra en alcance.
- **ERP del cliente**: solo anotar la OT (`client_work_order` + `external_refs`).
- **Idioma**: español e inglés, conmutables desde Configuración.

### Requisitos del usuario experto

- **Límites por potencia**: `MachineClass` lleva rango de kW y cimentación; la
  clase se **deriva de la placa** (ISO 10816-1 para 0–60 HP, ISO 10816-3 de
  15 kW en adelante). Una clase puesta a mano gana sobre la derivada.
- **Tableros eléctricos por ΔT** (NETA MTS), dos criterios separados: contra
  componente similar con igual carga (4/15 °C) y sobre ambiente (11/40 °C).
- **Problemas por servicio**: 45 modos de falla con su norma y su firma, y el
  servidor rechaza uno de otra técnica.
- **Tendencias**: hasta **6 series a la vez**, no todas. El caso canónico es
  "punto 1 y punto 2 del motor, los tres ejes". Más de seis líneas no es una
  comparación.
- **Matriz de acceso** (ver sección 5.7): gerencia lee y no altera nada;
  el técnico escribe con código único personalizado.

---

## 5. Qué está construido

### 5.1 Módulos

**Backend — 18 módulos**: `core` (registro de módulos, eventos, multitenant,
**auditoría**) · `security` (roles, permisos, alcance por área, códigos de
acceso, políticas de dominio) · `licensing` · `assets` (jerarquía, tipos de
conjunto con plantilla de puntos, importador RGP) · `nameplate` ·
`thresholds` · `measurements` (lecturas, registro de valores, exportación,
**captura de ronda**, **espectros**, instrumentos) · `services` ·
`diagnostics` · `operating_data` · `media` (subida, conversión, **galería por
equipo**, **FLIR**) · `summaries` · `oil_analysis` · y los stubs `blueprints`,
`reports`, `vibration`, `ultrasound`, `thermography`.

**Frontend — 13 módulos**: `assets` · `measurements` (registro de valores,
tendencia, **gráfico de tendencias**, **espectros**, **captura de ronda**,
**instrumentos**) · `services` · `summaries` · `thresholds` · `users`
(usuarios, roles, **auditoría**) · `diagnostics` (**catálogo de fallas**) ·
`nameplate` · `media` (**galería por equipo**) · `operating_data` (**nuevo**) ·
`licensing` · `modules_admin` · `preferences`.

### 5.2 Conjuntos rotativos y registro de valores

- La numeración de puntos **corre por el tren**, no por la máquina, y cada
  componente declara cuántos puntos se le leen (`AssetGroupComponent.point_count`).
  Dominio puro en `modules/assets/domain/point_layout.py`, con tests.
- `Equipment.group_component` + `order_in_group`: qué hueco del tipo ocupa cada
  máquina y en qué orden se imprime.
- El registro de valores tiene la forma de `TABLA DE TENDENCIAS.xls`, es
  **editable en sitio** y **exportable a Excel** con sus límites por componente.
- Las magnitudes por rodamiento colapsan a una fila por punto, con la etiqueta
  del cliente: `1 ENV`, `TEMP 1`, `01-UT`.

### 5.3 Gráfico de tendencias (sección VI del informe)

En `/measurements/:id`, bajo cada bloque de magnitud. Arranca en **1H**; se
añaden series hasta **6** y al llegar al tope los interruptores restantes se
deshabilitan. Un clic toma el punto entero (sus tres ejes). El selector se
construye de los puntos que ese equipo tiene medidos.

Un gráfico **por magnitud**, nunca dos escalas en un eje. Color = punto,
trazo y marcador = eje; leyenda siempre visible, etiqueta al final de cada
línea, y la tabla numérica justo encima. Paleta validada con el script de
`dataviz` contra las dos superficies (peor par CVD ΔE 9,1 claro / 8,4 oscuro).
ECharts va en su **propio chunk** (481 kB) para no entrar en el arranque.

### 5.4 Multimedia y espectros

- **Galería por equipo** en `/assets/:id/media`. `equipment_ref` y
  `captured_on` desnormalizados en la subida; índice cubriente
  `(company, equipment_ref, kind, -created_at, -id)`; paginación por cursor.
  Medido con 20 000 imágenes en un equipo: página 300 en 2,3 ms, lo mismo que
  la 1. En el navegador, `content-visibility: auto` + altura reservada.
- **Conversión sin broker**: la lógica vive en
  `modules/media/infrastructure/conversion.py`; la llaman la tarea Celery, el
  beat (00:15) y `manage.py media_convert`. El codificador degrada a WebP si
  falta el plugin AVIF.
- **FLIR**: `modules/media/domain/flir.py` lee el segmento `APP1` con la
  librería estándar (rejilla cruda + constantes de Planck). Antes lanzaba
  `NotImplementedError` y el termograma se quedaba sin ninguna derivada.
- **Espectros numéricos**: modelo `Spectrum`; la curva va en JSON gzip en el
  store (1 600 líneas = 3,7 KB) y tiene endpoint aparte del listado. Importa
  el CSV de SEMAPI/SKF con preámbulo, `;`/`,`/tab y coma decimal.

### 5.5 Semáforo de planta

- **Uno por técnica**, calculado de las lecturas de la última ronda (gana el
  peor). Pertenencia a la ruta = "medido alguna vez", así que lo no medido
  cuenta como cobertura perdida, no como verde.
- Cada nodo lleva el **número detrás del color**: valor + unidad del titular de
  esa técnica, el TAG del equipo, **quién lo registró y cuándo**.
- 6 pestañas: vibraciones, termografía, ultrasonido, END · Espesores UT,
  análisis de aceite, aceite dieléctrico.

### 5.6 Captura de ronda

`POST service-visits/<id>/readings/bulk/` con cabecera `Idempotency-Key`, y
pantalla en `/services/visits/:id/capture`. Crea las lecturas de una visita de
golpe y las gradúa al entrar. Una casilla vacía se registra como **no medida**
con su motivo. El reintento devuelve la primera respuesta, no una segunda
ronda (`ReadingBatch.reading_ids`).

### 5.7 Usuarios, permisos y auditoría

La matriz de acceso de la planta, visible en `/settings/users`:

| Perfil | Acceso | Validación | Comportamiento base |
|---|---|---|---|
| Gerente General | Solo lectura | Credencial corporativa | `client_viewer` |
| Subgerente de Planta | Solo lectura | Credencial corporativa | `client_viewer` |
| Jefe de Mantenimiento | Solo lectura + auditoría | Credencial corporativa | `planner` |
| Personal Técnico | Lectura y escritura | **Código único personalizado** | `technician` |

- Un rol = **permisos** (qué pantallas ve) + **comportamiento base** (si puede
  alterar datos de campo y de quién). `behaviour_of()` falla cerrado.
- **Código de acceso** para personal de campo: lo genera el servidor, se
  muestra **una vez**, se guarda solo el HMAC. Login en `/auth/code-login/`,
  limitado a **10 intentos/minuto** (en producción con caché Redis compartida:
  con `LocMemCache` serían 10 por worker).
- **Turnos** A/B/C en la membresía (tres relevos de 8 h).
- **Auditoría** en `/settings/audit` para `core.view_audit`: lecturas
  registradas y corregidas, accesos, roles e inicios por código. Se lee, nunca
  se edita.

### 5.8 CRUD

Completo y auditado ruta por ruta: planta → área → sector → conjunto → equipo →
puntos, normas, umbrales, estados, unidades, magnitudes, instrumentos, modos de
falla, parámetros operativos, usuarios, roles, órdenes, visitas, diario,
ejecutantes, tipos de conjunto, espectros, multimedia.

Lo que tiene historia detrás **se niega con el motivo y el conteo** o se
desactiva:

```
DELETE /magnitudes/1/   ["No se puede borrar: 20088 lectura(s) se tomaron en esta magnitud"]
DELETE /instruments/1/  ["No se puede borrar: 33558 lectura(s) y visita(s) se tomaron con él"]
PATCH  /points/1/       ["El punto 2H ya existe en el conjunto, en MOTOR"]
```

---

## 6. Qué falta

| Pendiente | Nota |
|---|---|
| Reporte de inspección en **PDF** | El módulo `reports` está vacío. Es el paso que cierra el círculo con `MPd-AV-N°006-13`. |
| Módulo `blueprints` (planos con puntos) | Diseñado en `docs/02 §1`, sin implementar. T3 del pedido original. |
| **Polín como activo** e incidencias UT | Para cargar el informe real de IPSA hace falta modelar el polín (rollo, diámetro, longitud externa/total) y las incidencias (fisura/socavación con longitud y profundidad) con su vocabulario ACEPTABLE/MEDIO/INACCESIBLE/CRÍTICO, distinto al del semáforo. |
| Datos reales de IPSA sin importar | El inquilino de demo es AMBEV; el libro es Industrias del Papel. Los espesores sembrados son sintéticos en el rango real (8–12 mm). |
| Aceleración en **G** | La unidad existe, ninguna magnitud la usa. Falta saber si es pico o RMS. |
| `pillow-heif` y `pillow-avif-plugin` | **No instalados**: derivadas en WebP y un HEIC de iPhone no convierte. |
| Importador de espectros en la UI de visita | El endpoint y el parser están hechos; falta el botón dentro del formulario de visita. |
| Costos asociados (Gerente General) | No hay modelo de costos en el sistema. |
| Intentos de código fallidos por compañía | Quedan a nivel plataforma: aún no se sabe de quién son. |
| Cifrar `Tenant.database_url` | Hoy es texto; la variable de entorno ya permite no guardarlo. |
| Versionado de `NameplateData` | Un registro por equipo. Hará falta el día que se rebobine un motor. |
| Migraciones a Postgres real | Todo probado en SQLite. Timescale/hypertables sin ejercitar. |
| `saveVisitReadings` vs `saveMatrixColumn` | Misma petición en dos módulos. Se deja por el aislamiento entre módulos; duplicar 6 líneas cuesta menos que romperlo. |

---

## 7. Bugs encontrados y corregidos (lo que no se deduce del código)

Todos salieron **ejecutando**, no leyendo. Vale la pena conocerlos porque
varios eran del tipo que no falla: devuelve algo plausible y equivocado.

| Bug | Síntoma | Causa |
|---|---|---|
| **Semáforo de una sola técnica** | Termografía tenía 20 088 lecturas graduadas y ninguna pestaña | `technique_code="vibration"` estaba **hardcodeado** en `_to_domain`, contradiciendo el docstring de la propia vista |
| **Cobertura siempre 100 %** | Ningún área mostraba hueco de plan | Solo entraban al semáforo los equipos ya medidos |
| **Roles propios inservibles** | Un usuario con "Gerente General" no cargaba **ninguna** pantalla | `Role(code)` lanzaba `ValueError` con cualquier rol fuera de los 7 del sistema |
| **No se podía asignar un rol propio** | El selector solo ofrecía los 7 del sistema | La validación de alta y edición comprobaba contra el mismo enum |
| **Se borraba quién midió** | Desaparecía el técnico responsable del tablero | Corregir una lectura sobrescribía `operator` con quien corregía |
| **`RecordReadings` inalcanzable** | `POST .../readings/bulk/` daba 404 | El caso de uso estaba escrito entero y **ningún adaptador implementaba sus puertos** |
| **Nada se graduaba en la captura** | Un 4,8 mm/s corriente salía sin veredicto | El contexto de evaluación se construía sin la norma del equipo ni su placa |
| **El reintento devolvía lecturas ajenas** | Misma clave de idempotencia → ids de otra ronda | `ReadingBatch` guardaba un conteo, no *qué* lecturas produjo |
| **Backfill contra la BD equivocada** | La migración fallaba al arrancar | `apps.get_model().objects` usa el alias por defecto: hay que fijar `.using(alias)` |
| **Filas triplicadas** | `1H 1V 1A` donde la hoja imprime `1 ENV` | El seed ignoraba la plantilla de puntos y escribía cada magnitud en los tres ejes |
| **Unidad equivocada en ultrasonido** | La pestaña mostraba mm en vez de dB | El espesor colgaba del servicio de ultrasonido y era su titular |
| **`dB` impreso como `DB`** | Y `gE` como `GE` | La cabecera del bloque pasaba todo a mayúsculas |
| **Tabla de auditoría vacía** | "Nada ha pasado" | `AuditLog` existía desde el principio y **nadie escribía en ella** |
| **El admin no recibía permisos nuevos** | Nadie podía conceder lo recién declarado | Se sembró una vez con `*`; la sincronización no los concedía |
| **`modules upgrade security` siempre fallaba** | `CommandError: No fixture named 'default_roles'` | El manifiesto declaraba un fixture que nunca existió |
| **Hora de registro ≠ la mostrada** | El tablero decía 17 sep para algo registrado el 24 | Se usaba `taken_at` (medición) en vez de `created_at` (registro) |
| **`related_name="+"` dos veces** | 500 en `/units/`, error en borrado de estados | `ThresholdBand.status` y `Magnitude.default_unit` no tienen relación inversa |
| **Título aplastado en tarjetas** | "Acceso / a / la / compañía", una palabra por línea | `min-w-0` en el título dejaba que se encogiera antes de que la barra saltara |
| **Ejes en orden alfabético** | El selector mostraba `A H V` | Venían ordenados del dato; el analista lee `H V A` |
| **Heurística de delimitador CSV** | Un fichero `;` con coma decimal parseaba como una columna | Contar caracteres elegía la coma en `0,0;0,01` |
| **Un tren incompleto se comía puntos ajenos** | Los puntos 7–10 caían sobre el reductor | Al faltar máquinas, el emparejador usaba la última como comodín |
| **Vendor +484 kB** | ECharts entraba en el arranque de todas las pantallas | `manualChunks` mandaba todo `node_modules` a `vendor` |

---

## 8. Trampas del entorno (leer antes de prometer nada)

- **`pytest` y `ruff` NO están instalados** en `predictive-back/.venv`. Solo
  están las dependencias de runtime, así que **los 199 tests del backend no se
  pueden correr**. Para instalarlos: `./.venv/bin/pip install -e ".[dev]"`.
  Mientras tanto se usa `manage.py check` y un runner mínimo para los tests de
  dominio (16 pasan: `test_role_behaviour`, `test_flir`, `test_point_layout`).
  `test_spectra.py` usa `pytest.raises` y no se puede ejecutar así.
- **`pillow-heif` y `pillow-avif-plugin` tampoco están.** Las derivadas salen
  en WebP y un HEIC no convierte.
- **El front sí corre entero**: `npx vitest run` → 101 tests, `npx tsc --noEmit`
  limpio.
- **Lint del front: 9 errores preexistentes** en 7 ficheros
  (`GroupKindsPage`, `PlantStructurePage`, `MeasurementsIndexPage`,
  `NameplateModal`, `ServiceOrdersPage`, `VisitFormModal`, `StandardFormModal`).
  Si `npx eslint src/modules src/app` da **más de 9**, algo nuevo lo rompió.
- **El aviso de "26 migraciones sin aplicar" al arrancar es cosmético.**
  `TenantRouter.allow_migrate` prohíbe esas apps en el plano de control;
  Django avisa porque no conoce el router. Las reales van al inquilino con
  `tenants migrate ambev`.
- **Migraciones aplicadas en esta sesión**: `assets.0007`, `media.0003`,
  `measurements.0003` a `0007`, `security.0002`.
- **Probar contra una copia**, no contra `data/tenant_ambev.sqlite3`: se copia
  el fichero, se registra un alias extra en `settings.DATABASES` y se migra con
  `call_command("migrate", database="probe")`.
- **El código de acceso emitido para Jorge en esta sesión está activo** en la
  BD local y su texto apareció en la conversación. Reemitirlo antes de
  cualquier uso real.

---

## 9. Convenciones de trabajo

- **Nunca `git push`.** Commits locales sí; el push lo decide el usuario.
- Conventional Commits **en inglés**, sin co-autoría ni referencias a Claude.
- Código, comentarios y **nombres de fichero en inglés**; contenido de
  documentación y textos de UI en **español** (con su traducción al inglés).
- Comentarios que dicen **por qué**, no qué. Si repite la línea, se borra.
- Tailwind puro: sin CSS propio, sin estilos en línea.
- Un módulo del front no importa el interior de otro: se habla por su `index`.
- El estado del servidor vive en RTK Query, no se copia a un slice.
- Los tipos de la API no se escriben a mano (`npm run api:types`).
- **Verificar ejecutando**, no leyendo: casi todos los bugs de la sección 7
  salieron al correr el código contra datos reales.
- Antes de dibujar un gráfico, cargar la skill `dataviz` y **correr el
  validador de paleta**; no estimar a ojo si es segura para daltonismo.

---

## 10. Dónde mirar cada cosa

| Tema | Documento |
|---|---|
| Qué dicen los Excel del cliente | `docs/00-source-analysis.md` |
| Arquitectura, hexagonal, i18n | `docs/01-architecture.md` |
| Modelo de dominio, T1–T12, espectros, layout de puntos | `docs/02-domain-model.md` |
| Módulos y dependencias | `docs/03-module-catalog.md` |
| Endpoints | `docs/04-api-contract.md` |
| Pipeline de imágenes, galería por equipo, FLIR | `docs/05-media-pipeline.md` |
| Fases y decisiones cerradas | `docs/06-roadmap.md` |
| Despliegue en Contabo | `docs/07-deployment.md` |
| Base de datos del cliente y licencias | `docs/08-onpremise-and-licensing.md` |
| Informes reales de vibraciones | `docs/vibration/reports/*.xlsx` |
| Ultrasonido END: informe, orden y mejoras pedidas | `docs/v2/` |

Los docs se escribieron antes que parte del código y **algunas cosas
evolucionaron después**. Si un doc y el código discrepan, **manda el código** y
conviene actualizar el doc.

---

## 11. Bitácora de la sesión 2026-09-17 → 2026-09-25

12 commits en `predictive-back`, 12 en `predictive-front`, 3 en `predictive-docs`.

**Backend** (de `4fcbb36` a `153bf93`):

1. `feat(assets)` — numeración de puntos a lo largo del tren
2. `feat(media)` — galería por equipo, conversión sin broker, FLIR
3. `feat(measurements)` — espectros numéricos
4. `fix(summaries)` — un semáforo por técnica y cobertura real
5. `feat(core)` — `seed_more`: los servicios que el demo no tenía
6. `feat(measurements)` — captura de campo cableada
7. `feat` — huecos de CRUD en todos los catálogos
8. `feat(measurements,summaries)` — leer una magnitud como se mide
9. `fix(measurements)` — cada servicio en su unidad (END · Espesores UT)
10. `feat(audit)` — quién cambió qué, y conservar quién midió
11. `feat(summaries)` — responsable y hora detrás de cada color
12. `feat(security)` — matriz de acceso y códigos personales

**Frontend** (de `d39ddec` a `293c5dd`):

1. `feat(assets)` — un tipo de conjunto declara cuántos puntos lleva cada máquina
2. `feat(media)` — galería de toda la historia de una máquina
3. `feat(thresholds,users)` — el CRUD que estas pantallas tenían a medias
4. `feat(assets,services)` — cablear las operaciones que existían sin botón
5. `feat(catalogues)` — pantallas para instrumentos, fallas y parámetros
6. `feat(measurements)` — espectros y captura de ronda
7. `feat(measurements)` — gráfico de tendencias legible
8. `feat(summaries,measurements)` — el número detrás del color
9. `fix(measurements)` — respetar las mayúsculas de la unidad
10. `fix(ui)` — dejar que la barra ancha de una tarjeta salte de línea
11. `feat(summaries)` — quién registró la peor lectura de cada área
12. `feat(users)` — matriz de acceso, códigos personales y auditoría

**Qué pidió el usuario, en orden**: el layout de conjuntos 2+4 → los tres
huecos de multimedia/conversión/espectros → llenar las vistas con datos reales
→ auditar el CRUD de todas las vistas → cerrar los huecos del CRUD → el
gráfico de tendencias con hasta 6 series → las correcciones de las imágenes
(espesor mínimo, valor en la barra, filas por rodamiento) → unidades por
servicio → usuarios y permisos con la matriz de acceso.
