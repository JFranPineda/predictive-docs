# Fase 1 — Licencia firmada con Ed25519 (token v2)

**Capa del §5:** Capa 1 (§5.2). **Estimado:** ~14 h. **Depende de:** Fase 0.

## Objetivo

Que la licencia se firme con una **clave privada que nunca sale de Industrie
Ampel** y se verifique con una **clave pública compilada dentro del programa**.
Así el servidor de IPSA puede comprobar licencias pero no emitirlas. Decisión D2:
se reemplaza HMAC por Ed25519 en **todos** los clientes (token v2), AMBEV
incluido.

## Por qué

Hoy la llave es `payload.HMAC-SHA256(payload, LICENSE_SECRET)`
(`issue`/`verify` en `predictive-back/modules/licensing/domain/license.py`).
HMAC usa el mismo secreto
para firmar y verificar. En el servidor de IPSA ese secreto estaría en su `.env`
y cualquiera con acceso podría emitirse licencias
([doc 08 §4](../08-onpremise-and-licensing.md)). Ed25519 separa las dos cosas:
firmar necesita la privada; verificar, solo la pública.

## Qué se toca (predictive-back)

- `modules/licensing/domain/license.py`:
  - `TOKEN_VERSION = 2`.
  - `issue(license_, private_key)` firma con Ed25519 (reemplaza `_sign` HMAC).
  - `verify(token, public_key)` valida la firma Ed25519 antes de leer el
    contenido (igual que hoy: firma primero, contenido después).
  - Se mantiene el formato `base64url(payload).base64url(firma)`.
- Clave pública **compilada**: va como constante en un módulo de Python
  (`domain/signing_key.py`), no en `.env`. En la Fase 5 ese módulo se compila
  con el resto; si estuviera en un archivo suelto, bastaría con reemplazarlo.
- Clave privada: solo en la máquina que emite. Se lee de `LICENSE_PRIVATE_KEY`
  (ruta a un archivo fuera del repo) y **nunca** se sube. El comando
  `tenants issue` la usa; el servidor del cliente no la tiene.
- `application/license_service.py`, `interfaces/middleware.py`,
  `management/commands/tenants.py`: pasan de `secret=settings.LICENSE_SECRET` a
  usar la clave pública para verificar y la privada solo al emitir.
- Generación de claves: comando `manage.py license keygen` que crea el par y
  recuerda que la privada va a un lugar seguro.
- Transición: `verify` acepta **token v1 (HMAC) y v2 (Ed25519)** mientras haya
  clientes sin reemitir, mirando el campo `v`. Se quita cuando todos estén en v2.

## Qué se toca (predictive-front)

- Nada funcional. La pantalla `/settings/license` sigue leyendo
  `GET /api/v1/license/status/`, que no cambia de forma.

## AMBEV (por D2)

1. Reemitir su licencia como v2 **en el espejo 8012** y verificar que
   `status/` responde `active` y que una escritura normal funciona.
2. Solo entonces reemitir en el plano de control real (la licencia vive en
   nuestra BD, no toca los datos de AMBEV).
3. La aceptación de v1 en `verify` cubre el instante entre reemitir y desplegar.

## Criterios de aceptación

- **AC-1.1** Una licencia emitida con la privada se verifica con la pública; una
  con la firma cambiada un byte da `BadSignature`.
- **AC-1.2** El servidor de prueba **no** tiene la clave privada y aun así
  verifica su licencia.
- **AC-1.3** `verify` acepta un token v1 (HMAC) y uno v2 (Ed25519) durante la
  transición; un token v3 inexistente da `MalformedToken`.
- **AC-1.4** AMBEV reemitido a v2 en el espejo responde `active` y permite
  escribir.
- **AC-1.5** La clave privada no está en el repo ni en la imagen; `git grep` y
  una inspección de la imagen lo confirman.
- **AC-1.6** Portones verdes: pytest, ruff, lint-imports, `manage.py check`.

## Riesgos

- **Perder la clave privada = no poder emitir más licencias.** Respaldo cifrado
  en dos lugares, documentado en el manual (Fase 6). Dos llaves físicas están
  presupuestadas (propuesta §3.9).
- Reemitir AMBEV mal lo bloquea. Por eso va primero en el espejo (AC-1.4).

## Decisiones pendientes

- **P1-a.** ¿Dónde vive la clave privada al emitir: un archivo cifrado en la
  máquina del usuario, o una llave física (YubiKey) como dice §5.2? La llave
  física es más segura pero agrega pasos a cada emisión. *Recomendado para v1:
  archivo cifrado fuera del repo; la llave física se evalúa en v2.*
- **P1-b.** ¿Cuándo se reemite AMBEV a v2 en producción: dentro de esta rama, o
  en una ventana aparte coordinada contigo? *Recomendado: construir y probar en
  la rama; reemitir en producción contigo presente.*
