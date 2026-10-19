# Fase 5 — Empaquetado cerrado: distribución compilada y firmada

**Capa del §5:** Capa 6 (§5.7). **Estimado:** ~18 h. **Depende de:** Fases 1 a 4.
**Puerta:** §5.11 pide esta fase **antes de entregarle el instalador al TI de
IPSA**. Hasta aquí se instala bajo nuestra supervisión.

## Objetivo

Entregar PREDICTIVE como un producto cerrado, igual que cualquier software
comercial que se instala en casa del cliente: se entrega el **artefacto
compilado**, no el código fuente; las imágenes van **firmadas** para garantizar
integridad; y cada entrega lleva un **identificador de compilación por cliente**
para soporte y para fijar la versión. Es protección de propiedad intelectual y
de cadena de suministro, por las buenas prácticas de la industria.

## Por qué

Con las Fases 1 a 4 la licencia es sólida. Entregar el fuente, además, regalaría
el producto: el valor de Industrie Ampel es el código. Compilar y firmar es lo
que hace cualquier proveedor on-premise, y además sostiene la promesa del Plan
Cloud de «versión 1.0» (cada cliente corre la versión que contrató, sellada).

## Qué se toca

### Backend compilado

- **Nuitka** compila los módulos de Python propios a módulos nativos dentro de
  la imagen Docker. Es distribución compilada estándar: el cliente recibe un
  binario, no `.py` legibles.
- Como alternativa, **PyArmor** (empaquetado comercial) si Nuitka choca con
  alguna dependencia. Se elige uno; no hace falta apilar los dos.
- La verificación de licencia **sigue en un solo punto**: el `LicenseMiddleware`
  de hoy. Se mantiene centralizada y mantenible, no se dispersa. Se agrega una
  comprobación de integridad en el arranque (que la imagen firmada es la nuestra).

### Front compilado

- El build de producción de Vite va **sin source maps** (configuración
  estándar). Lo sirve el backend con licencia válida, como ya ocurre.

### Imágenes firmadas (integridad / cadena de suministro)

- Las imágenes Docker se firman con **cosign**. El servidor del cliente
  verifica la firma al desplegar: así se sabe que la imagen es la que publicamos
  y no una alterada en el camino.
- Se entregan por un registro privado, o como archivo `.tar` firmado si IPSA no
  tiene salida a internet.

### Identificador de compilación por cliente

- Cada entrega lleva embebido el código del cliente (p. ej. `ipsa`) y la versión
  (`1.0.x`) en la imagen y en los metadatos de los PDF que genera.
- Para qué sirve: soporte (saber qué versión corre cada cliente), fijar la
  versión contratada del Plan Cloud, y dejar constancia de la titularidad del
  producto, que es la prueba que acompaña al registro de INDECOPI (§5.8, §7).

## Criterios de aceptación

- **AC-5.1** La imagen de producción no contiene `.py` del código propio
  legibles; una inspección de la imagen lo confirma.
- **AC-5.2** La suite completa (pytest, y un recorrido de la UI) pasa **sobre la
  imagen compilada**, no solo sobre el fuente. En especial: generación de PDF
  (weasyprint), lectura de fotos HEIC (pillow-heif) y los cálculos con numpy.
- **AC-5.3** El front de producción no expone source maps.
- **AC-5.4** La imagen está firmada con cosign y el despliegue verifica la firma;
  una imagen sin firmar o alterada no arranca.
- **AC-5.5** Los PDF generados llevan el identificador de cliente y versión en
  sus metadatos.
- **AC-5.6** La verificación de licencia sigue centralizada en el middleware
  (un solo punto), con la comprobación de integridad de arranque añadida.
- **AC-5.7** Portones verdes, también sobre la imagen compilada.

## Riesgos

- **La compilación rompe dependencias nativas** (weasyprint, pillow-heif,
  numpy). Es el riesgo principal de toda la rama. Mitigación: AC-5.2 prueba la
  imagen compilada entera; si un módulo no compila limpio, se deja interpretado
  y se documenta, sin bloquear la entrega.
- Nuitka alarga el tiempo de build. Mitigación: se compila solo para la entrega,
  no en cada iteración de desarrollo.

## Decisiones pendientes

- **P5-a.** ¿Nuitka o PyArmor? Nuitka da binario nativo y es gratis; PyArmor es
  de pago (USD 158, ya presupuestado §3.9) y más simple de integrar pero menos
  hermético. *Recomendado: probar Nuitka primero; si una dependencia nativa da
  guerra, PyArmor como salida.*
- **P5-b.** ¿Registro privado de imágenes o entrega por archivo `.tar` firmado?
  Depende de si IPSA nos deja un canal de salida. *Se cierra con la respuesta
  del TI de IPSA (propuesta §6).*
