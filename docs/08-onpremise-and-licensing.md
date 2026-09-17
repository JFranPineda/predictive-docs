# 08 — Base de datos del cliente y licenciamiento

El modelo comercial que hay que sostener: **los datos del cliente viven en su
propia base de datos, en su casa; el sistema que les da sentido corre en la
nuestra.** Este documento describe cómo se separan los dos planos y qué ata el
uno al otro.

## 1. Dos planos

```
┌─ nuestra infraestructura ──────────────┐     ┌─ casa del cliente ──────────┐
│ front (React)                          │     │                             │
│ backend (Django)                       │     │   PostgreSQL                │
│                                        │     │   ├ activos, puntos         │
│ ┌ plano de control (nuestra BD) ┐      │─────▶   ├ lecturas, espectros     │
│ │  Tenant                        │     │ TLS │   ├ servicios, hallazgos    │
│ │  LicenseRecord                 │     │     │   └ usuarios y permisos     │
│ │  LicenseEvent                  │     │     │                             │
│ └ 3 tablas, ningún dato suyo ────┘     │     │   (o alojada por nosotros)  │
└────────────────────────────────────────┘     └─────────────────────────────┘
```

Verificado en el prototipo: el plano de control tiene **3 tablas**, la base del
cliente **39**. Ni una fila de mantenimiento pasa por la nuestra.

| | `default` (nuestro) | `tenant_<código>` (del cliente) |
|---|---|---|
| Qué guarda | quién es cliente, dónde está su BD, qué licencia tiene | todo lo demás, incluidos usuarios y permisos |
| Quién lo administra | nosotros | el cliente es dueño de los datos |
| Tamaño | kilobytes | gigabytes |

**No hay claves foráneas entre planos.** El router (`TenantRouter`) lo impide
explícitamente: `allow_relation` sólo permite relaciones dentro de un plano.

## 2. Cómo se resuelve el cliente en cada petición

```
subdominio (ambev.predictive.app) → cabecera X-Tenant → DEFAULT_TENANT
```

El middleware de cliente corre **antes** que la autenticación, porque "quién es
este usuario" sólo se puede preguntar contra la base correcta. La conexión se
registra en caliente la primera vez que se toca: dar de alta un cliente no
reinicia nada.

Orden completo:

```
TenantMiddleware → LicenseMiddleware → autenticación DRF → vistas
```

La empresa activa y el idioma se resuelven **dentro de la autenticación**, no
en el middleware. No es un detalle: el middleware corre antes de que DRF valide
el JWT, así que ahí el usuario todavía es anónimo — hacerlo antes daba
`company_id = None` y cero permisos en todas las llamadas.

## 3. Todo por `.env`

Ninguna conexión está escrita en código:

```bash
CONTROL_DATABASE_URL=postgres://user:pass@localhost:5432/predictive_control
TENANT_AMBEV_DATABASE_URL=postgres://svc:pass@db.ambev.local:5432/predictive?sslmode=verify-full
DEFAULT_TENANT=ambev
BASE_DOMAIN=predictive.app
LICENSE_SECRET=…
```

La variable de entorno **gana** sobre la fila en la tabla. Dos razones: permite
arrancar el primer cliente antes de que exista el plano de control, y permite a
un cliente que no quiera dejarnos sus credenciales guardarlas sólo en la
configuración del proceso.

El parser (`core/domain/database_url.py`) acepta `postgres://`, `postgresql://`,
`mysql://` y `sqlite:///…`, decodifica contraseñas con símbolos y **rechaza**
opciones que no entiende — tragarse un `sslmode=verify-full` en silencio es
como una conexión deja de estar cifrada sin que nadie se entere.

## 4. La llave

```
token = base64url(payload) . HMAC-SHA256(payload, secreto)
```

Contiene: cliente, plan, fechas, días de gracia, módulos habilitados, límites
(equipos, plantas, usuarios) y la **huella de la base de datos**.

**Por qué HMAC y no firma asimétrica.** La verificación corre en *nuestros*
servidores, nunca en hardware del cliente. Una clave asimétrica sólo aporta algo
cuando el verificador está en manos hostiles; aquí sería ceremonia.

### Qué hace y qué no

- **Sí**: impide que nuestra aplicación sirva a un cliente cuyo contrato
  terminó, en un único punto de control en vez de en cien vistas.
- **Sí**: ata la licencia a *una* base de datos. Apuntar el despliegue a una
  copia no reutiliza la llave en silencio.
- **No**: no cifra la base del cliente. Esas filas son suyas y puede leerlas con
  `psql` cuando quiera. Lo que no se lleva es **el sistema**: un esquema sin la
  aplicación es un archivador sin índice.

Decirlo claro importa, porque la alternativa — prometer que el cliente "no
puede" tocar sus propios datos — es falsa y se descubre el primer día.

### Ciclo de vida

| Situación | Comportamiento |
|---|---|
| Vigente | normal |
| Faltan ≤ 30 días | avisa en la UI, sigue funcionando |
| Vencida, dentro de la gracia (15 días) | **solo lectura** |
| Pasada la gracia | bloquea (HTTP 402) |
| Revocada | bloquea de inmediato |
| Huella de BD distinta | bloquea |

Degrada antes de bloquear a propósito: cortar a una cuadrilla a mitad de ronda
porque una factura lleva tres días de retraso genera un enemigo, no un pago.

`/api/v1/license/status/` **siempre responde**, incluso bloqueada, para que la
interfaz pueda explicar qué pasa en vez de mostrar una pantalla en blanco.

### Sin caché por proceso

La primera versión cacheaba el veredicto cinco minutos. Era un error: la caché
es por proceso, así que revocar desde la consola dejaba a cada worker sirviendo
al cliente hasta que expirara su propia copia. Una revocación que llega "en
algún momento, según el worker" no es una revocación. Ahora es una consulta
indexada sobre una tabla con una fila por contrato; si algún día aparece en un
perfil, la solución es una caché compartida con invalidación explícita, no una
local que miente.

## 5. Operación

```bash
manage.py tenants add ambev "AMBEV Perú" --url postgres://… --deployment on_premise
manage.py tenants migrate ambev
manage.py tenants issue ambev --plan enterprise --months 12 --equipment 600
manage.py tenants list
manage.py tenants revoke ambev --reason "contrato terminado"
manage.py tenants run ambev <cualquier comando>
```

`migrate` aplica al cliente **sólo** lo suyo: el router manda `licensing` al
plano de control y todo lo demás al del cliente.

## 6. Lo que falta antes de producción

1. **Cifrar `Tenant.database_url` en reposo.** Hoy es texto; la variable de
   entorno ya permite no guardarlo, pero la columna debe cifrarse.
2. **TLS obligatorio** contra la base del cliente (`sslmode=verify-full` y su
   CA), y una IP de salida fija que el cliente pueda poner en su cortafuegos.
3. **Rotación del `LICENSE_SECRET`** con licencias firmadas por versión de
   clave.
4. **Un `Tenant` por cliente en el panel**, no sólo por consola.
