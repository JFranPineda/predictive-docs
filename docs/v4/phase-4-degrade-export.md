# Fase 4 — Al vencer: degradar sin secuestrar (modo «solo exportar»)

**Capa del §5:** Capa 5 (§5.6). **Estimado:** ~6 h. **Depende de:** Fase 3.

## Objetivo

Que pasada la gracia el sistema **deje de trabajar pero nunca retenga los datos
del cliente**: registrar lecturas, generar informes y cargar fotos se bloquean;
exportar sus datos funciona siempre.

## Por qué

- Es la presión legítima: lo que deja de servir es **el software**, no la
  información.
- ⚠️ Borrar, cifrar o dañar datos del cliente por impago, además de romper la
  relación, en Perú puede configurar un delito informático (**Ley 30096**,
  atentado contra la integridad de datos). Esto no se programa nunca, ni como
  opción apagada.
- Es también la prueba de la objeción 3 de la propuesta («¿qué pasa con nuestros
  datos si no renovamos?») y de la **garantía de salida**.

## Qué se toca (predictive-back)

- `infrastructure/middleware.py`: hoy `LicenseMiddleware` devuelve 402 a todo
  cuando bloquea, salvo las rutas exentas (`/api/v1/auth/`, `/api/v1/license/`,
  esquema, admin). Se agrega un estado intermedio:

  | Situación | Hoy | Con la Fase 4 |
  |---|---|---|
  | Vigente | normal | normal |
  | En gracia (30 días) | solo lectura | solo lectura |
  | Pasada la gracia | **402 a todo** | **solo exportar**: lectura y exportación sí; escritura e informes no |
  | Revocada | bloquea | solo exportar |

- Lista explícita de rutas de exportación permitidas (los `export` de
  actividad/auditoría, el volcado de datos del inquilino y las descargas de
  historial). Se declara una sola vez, igual que `LICENSE_EXEMPT_PREFIXES`, para
  que no se dispersen permisos.
- Nuevo comando `manage.py tenants export <código>` que vuelca **todo** lo del
  inquilino a Excel y SQL, y que funciona con la licencia vencida. Es la
  garantía de salida hecha código.
- El motivo viaja en la respuesta y en `X-License-Status`, para que el front
  explique en vez de mostrar una pantalla en blanco.

## Qué se toca (predictive-front)

- Cuando el estado es «solo exportar»: un aviso fijo que explica la situación y
  deja a la vista el botón de exportar y la pantalla de licencia. Los botones de
  guardar se desactivan con el motivo, no fallan al pulsarlos.
- Traducciones es/en.

## Criterios de aceptación

- **AC-4.1** Pasada la gracia, un `POST` de lectura de vibraciones devuelve 402
  con un motivo legible.
- **AC-4.2** Pasada la gracia, `GET` de listados y **la exportación** responden
  200.
- **AC-4.3** `manage.py tenants export` produce el volcado completo con la
  licencia vencida.
- **AC-4.4** La generación de informes PDF/Excel **de trabajo** queda bloqueada,
  pero la exportación de datos no.
- **AC-4.5** El front explica el estado y no deja botones que fallen.
- **AC-4.6** No existe en el código ninguna ruta que borre o cifre datos del
  inquilino por licencia: se verifica por búsqueda y queda dicho en el manual.
- **AC-4.7** Portones verdes.

## Riesgos

- Marcar mal una ruta como «exportación» abriría un hueco para seguir
  trabajando gratis. La lista es explícita y corta, y se revisa en la revisión
  de código.
- Lo contrario: olvidar una ruta de exportación haría parecer que secuestramos
  datos. AC-4.2 y AC-4.3 lo cubren.

## Decisiones pendientes

- **P4-a.** ¿Los **informes** (PDF de MPd y END) cuentan como «trabajo»
  (bloqueados) o como «sus datos» (permitidos)? Un informe es un entregable que
  normalmente se cobra; un Excel de sus lecturas es su información.
  *Recomendado: informes bloqueados, exportación de datos permitida — es la
  línea que separa el software del dato.*
- **P4-b.** ¿La exportación completa la puede lanzar el administrador de IPSA
  desde la pantalla, o solo nosotros por consola? Desde la pantalla cumple mejor
  la garantía de salida; por consola nos deja ver que se van.
  *Recomendado: desde la pantalla, con permiso propio. La garantía de salida
  vale más que el aviso.*
