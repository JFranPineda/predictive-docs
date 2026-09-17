# 07 — Despliegue

Arranque en **un VPS de Contabo (plan VPS 8)** con Postgres propio, y camino de
salida cuando se quede corto. Todo con Docker Compose, un solo host.

> Antes de provisionar: confirma vCPU, RAM y disco del plan contratado y
> compáralos con el §2. Lo que sigue está dimensionado con la carga real medida
> en doc 00 §7, no con un tamaño de catálogo.

## 1. Topología

```
                    ┌──────────────── VPS Contabo ────────────────┐
   Internet ──443──▶│ Caddy (TLS automático, gzip/brotli)         │
                    │   ├─▶ api        gunicorn, 4 workers        │
                    │   ├─▶ front      estáticos de Vite          │
                    │   └─▶ minio      /media (subida y descarga  │
                    │                   directas, firmadas)       │
                    │ worker  celery -Q celery,media              │
                    │ beat    celery beat (00:15 conversión)      │
                    │ db      postgres 16 + timescaledb           │
                    │ redis   broker + caché                      │
                    └─────────────────────────────────────────────┘
```

**Postgres propio**, no gestionado: la extensión `timescaledb` se instala en la
imagen (`timescale/timescaledb:2.x-pg16`) y las hypertables funcionan igual que
en la nube de Timescale. Si algún día se migra a un gestionado que no la traiga,
la tabla sigue viva como tabla particionada nativa y el repositorio no cambia
(doc 01 §5).

## 2. Dimensionado

Lo que pide esta carga, con una planta tipo AMBEV Huachipa (558 equipos):

| Recurso | Mínimo cómodo | Por qué |
|---|---|---|
| vCPU | 4 | gunicorn (4) + 2 workers de Celery; la conversión nocturna es el pico |
| RAM | 8 GB | Postgres 2 GB · MinIO 1 GB · api 1.5 GB · workers 1.5 GB · resto SO |
| Disco | **400 GB+** | ~100 GB/año/planta de originales (doc 00 §7) |
| Ancho de banda | sin límite práctico | subida de rondas: ~9 GB por ronda completa |

**El disco es lo que aprieta, no la CPU.** 2 200 fotos por ronda en HEIC son
~9 GB; las derivadas AVIF son ~0.5 GB. Un año de una planta cabe en 400 GB con
holgura; dos plantas no.

Regla operativa: **al 60 % de ocupación, mover los originales a Contabo Object
Storage** (S3 compatible) y dejar solo las derivadas en el VPS. El código no
cambia — `ObjectStore` ya habla S3 y el endpoint sale de `.env` (doc 05 §3).

Cuándo subir de plan, en orden de probabilidad:

1. Disco al 60 % → Object Storage, no plan mayor.
2. Segunda planta o segundo cliente grande → más RAM (Postgres se queda corto
   antes que la CPU).
3. La conversión nocturna se pasa de las 06:00 → más vCPU o una segunda
   máquina solo con `worker -Q media`.

> Cuando el cliente pone su propia base de datos, este VPS sigue alojando todo
> menos esa base: ver [doc 08](08-onpremise-and-licensing.md). El
> dimensionado de disco de arriba deja de aplicar a los datos, pero no a las
> imágenes, que siguen siendo nuestras salvo acuerdo distinto.

## 3. Puesta en marcha

```bash
git clone … && cd predictive-back
cp .env.example .env          # secretos, dominio, credenciales de MinIO
docker compose up -d db redis minio

# 1. El plano de control: quién es cliente y qué licencia tiene.
docker compose run --rm api python manage.py migrate --database=default

# 2. El cliente: su base, sus tablas, su licencia.
docker compose run --rm api python manage.py tenants add ambev "AMBEV Perú" \
    --url "postgres://svc:pass@db.ambev.local:5432/predictive?sslmode=verify-full" \
    --deployment on_premise
docker compose run --rm api python manage.py tenants migrate ambev
docker compose run --rm api python manage.py tenants issue ambev \
    --plan enterprise --months 12 --equipment 600
docker compose up -d
```

El front se construye aparte (`npm run build`) y Caddy sirve `dist/`.

## 4. Copias de seguridad

Lo que hay que respaldar es de dos naturalezas y se trata distinto:

| Qué | Cómo | Cada |
|---|---|---|
| Postgres | `pg_dump` comprimido a Object Storage, retención 30 días | noche |
| Originales de media | ya están en object storage; versionado del bucket | continuo |
| Derivadas | **no se respaldan**: se regeneran del original | — |
| `.env` y secretos | fuera del servidor, en el gestor de contraseñas | al cambiar |

Una restauración se prueba **antes** de necesitarla: `pg_restore` sobre una base
vacía y arrancar la API contra ella. Un backup que nadie restauró no es un
backup.

## 5. Seguridad mínima del host

- SSH solo con clave, `root` sin login directo, `fail2ban`.
- Firewall: 80/443 abiertos, 5432/6379/9000 **cerrados desde fuera** — se llega
  a ellos por la red interna de Compose.
- Postgres con contraseña propia y `scram-sha-256`; nada de `trust`.
- Caddy renueva TLS solo; HSTS activo en `prod.py`.
- `DEBUG=0` y `ALLOWED_HOSTS` explícito: `config/settings/prod.py` ya lo exige.

## 6. Lo que este montaje no da (y cuándo importará)

- **No hay alta disponibilidad.** Si el VPS cae, el sistema cae. Aceptable para
  arrancar; deja de serlo cuando el cliente lo use para decidir paradas.
- **No hay réplica de lectura.** Los informes pesados corren contra la misma
  base que la captura. Con una planta no se nota.
- **El object storage está en la misma máquina.** Es el primer trozo que sale
  fuera, y ya está desacoplado para que salir sea cambiar una variable.
