# IPSA on-premise: planes, precios y protección de la licencia

Documento **interno** de Industrie Ampel. Contiene costos, márgenes y los
límites de la negociación: no se entrega al cliente.

Versión 4, 14 de octubre de 2026. Los precios de venta son **precios de lista**
fijados por el equipo, con margen para que IPSA negocie hacia abajo. El
documento dice hasta dónde se puede bajar, a cambio de qué y dónde está el
piso.

- **T1.** Tres planes para el CONTEXTO B (los datos de IPSA viven en su propio
  servidor), con costos exactos por ítem, precio de lista y licencia del primer
  año incluida. Construidos con los marcos de Hormozi: *pricing-strategy*
  (precio anclado al valor, niveles DIY/DWY/DFY) y *objection-destroyer*
  (objeciones → cambio de creencia → prueba).
- **T2.** Cómo proteger el sistema cuando corre en un servidor que no
  controlamos (§5), y cómo registrar marca y software en INDECOPI (§7).

> **Qué cambió respecto de la versión 3.**
>
> - **Capacitación con 1 instructor:** 2 días en el Plan 1 y 3 días en los planes
>   2 y 3.
> - **Visitas durante la implementación:** 2, 3 y 5. Los días de capacitación
>   son presenciales y se cuentan aparte, así que los viajes son 4, 6 y 8.
> - **Informe a gerencia:** trimestral en los planes 2 y 3.
> - **Visitas en la mensualidad:** 1 por trimestre en el Plan 2 y 2 por trimestre
>   en el Plan 3. No son acumulables.
> - **La bolsa de mejoras sale de todos los planes** y se cobra aparte (§3.8).
> - **Los precios de lista no cambian** (6 900 / 9 200 / 11 200 y
>   400 / 690 / 890): con el nuevo alcance ningún plan pierde, ni en el piso. La
>   mensualidad ahora también tiene espacio para negociar (§3.7).

---

## 0. Supuestos

| Supuesto | Valor | Fuente |
|---|---|---|
| Costo de una hora del equipo (sueldo + cargas) | USD 20/h | Confirmado por el equipo |
| Gastos generales (administración, contabilidad, ventas, herramientas) | +15 % sobre todo costo directo, así que **la hora cargada cuesta USD 23** | Supuesto |
| Tarifa de lista de la implementación | USD 53/h | Sale de los precios fijados por el equipo para negociar. El cierre esperado equivale a ~USD 42–45/h |
| Viajes durante la implementación | Días de capacitación + visitas: 4, 6 y 8 | Cada viaje: 2,5 h + USD 30 |
| Traslado Lima ↔ Chaclacayo (Carretera Central km 18,5) | 2,5 h ida y vuelta + USD 30 de movilidad | Supuesto |
| Forma de pago de IPSA | Orden de compra a **90 días** | Confirmado |
| Costo de cobrar a 90 días | **3 % de cada factura** (factoring ≈ 1 %/mes) | Tasa por cotizar con el banco |
| Tipo de cambio | S/ 3,45 por USD | SUNAT, 12-oct-2026 |
| Precios | USD, **sin IGV** (18 %) | |
| Lo que ya está cargado de IPSA | 47 conjuntos, 98 equipos, 795 puntos y 10 536 lecturas, en 5 áreas | Base `tenant_ipsa` |
| Servidor del cliente (planes 1 y 2) | 4 vCPU, 8 GB, 400 GB SSD, Ubuntu Server 24.04 | [doc 07 §2](../07-deployment.md) |
| Servidor en comodato (Plan 3), ≈ USD 2 750 amortizados en 36 meses y cobrados en la mensualidad | Servidor ~1 980, RAM y SSD ~300, UPS ~350, disco de respaldo ~120 | Servidor: Panacompu, sin IGV. Resto: estimado, pedir cotización |

### 0.1 Lo que confirmamos sobre IPSA

**La empresa (internet):**

- Industrias del Papel S.A., RUC 20100151546, es la unidad de papel del
  **Grupo JLB**. El grupo incluye además CERUTI (cajas de cartón corrugado) y
  ACINSA (tubos y conos).
- Recicla papel desde 1957 y trabaja con 100 % de fibra reciclada.
- Su planta en Chaclacayo mide **29 346 m²** y tiene una capacidad instalada de
  **4 000 t/mes** de papel y cartón (Gestión, junio de 2025).
- Tiene alrededor de **134 trabajadores** (marzo de 2025).

**¿Son ~200 conjuntos?** No se puede confirmar en internet, porque el número de
máquinas de una planta no es público. Lo que sí se ve es que la cifra es
coherente:

- Los 47 libros importados (setiembre de 2025) cubren la ruta de vibraciones
  que se mide hoy: pulper N° 04, refinador, ecoscreen, bombas booster y fan,
  prensas, grupos de secadores (área MP3) y filtración.
- Una planta de 4 000 t/mes tiene más líneas que esa. El nombre «MP3» sugiere
  más de una máquina papelera. Hay además servicios: calderos, vacío,
  compresores y tratamiento de aguas.
- **Antes de firmar**, hay que pedir la lista de los 200 conjuntos. El alcance y
  la licencia se fijan sobre esa lista, y lo que exceda se cobra por bloque
  (§3.8).

**¿Cuesta USD 3 000 la hora de parada?** Es coherente:

- **Producción por hora.** A capacidad plena, 4 000 t/mes son ~5,6 t/h. Perder
  USD 3 000/h equivale a ~USD 540 por tonelada no producida, que está en el
  orden del precio del papel reciclado para cartón. No encontré un precio
  público en Perú; para cerrarlo, pedirle a IPSA su precio promedio por
  tonelada.
- **Por qué la línea de secadores es la crítica.** Una máquina de papel es una
  línea continua: la hoja pasa por formación, prensas y secadores sin cortes.
  Si un grupo de secadores se detiene, se detiene la máquina entera. Un equipo
  con respaldo o uno auxiliar casi no afecta la producción. Es lo mismo que dijo
  el cliente, y es la lógica estándar de criticidad.
- **Sus propios datos lo respaldan.** En los libros de setiembre de 2025, 6
  conjuntos estaban en **PARADA** en el semáforo de vibraciones. Entre ellos
  están el **reductor del 1er grupo de secadores**, el **reductor del 3er grupo
  de secadores** y el **motor de transmisión principal R1**.
- **Falta clasificar.** Los 47 conjuntos cargados tienen hoy la misma
  criticidad (3, la más baja). Clasificarlos es parte de la implementación
  (ítem D, mapa de criticidad).

---

## 1. T1 — Análisis de valor (por qué el precio no sale del costo)

**Resultado que compra IPSA:** que ninguna máquina de su línea de secadores se
detenga por sorpresa, con todo su programa predictivo (vibraciones,
ultrasonido, termografía, END, alineamiento, correctivos y jornada con ATS) en
un solo sistema, **sin que sus datos salgan de su planta**.

**Cuánto vale, con los números de IPSA:**

| Tipo de equipo | Costo de una hora de parada | Qué hace el sistema |
|---|---|---|
| Crítico (línea de secadores) | ~USD 3 000 | Alarma temprana; prioridad 1 en rutas e informes |
| De producción con respaldo | Bajo | Programa el cambio al equipo de respaldo |
| Auxiliar | Bajo | Inspección menos frecuente |

- **El primer año del Plan 2 a precio de lista (USD 17 480) equivale a 5,8
  horas de la línea de secadores parada.** El del Plan 1 equivale a 3,9 horas y
  el del Plan 3, a 7,3.
- **Referencias externas.** TAPPI, citando a Frost & Sullivan, estima entre USD
  80 000 y 150 000 por hora en papeleras grandes
  ([TAPPI Paper360](https://paper360.tappi.org/?p=5261)). Una guía de un
  proveedor de CMMS da USD 12 000–35 000 por hora
  ([Oxmaint](https://oxmaint.com/article/paper-mill-cmms-maintenance-management-guide)).
  IPSA es mucho más chica: su cifra es la que se usa.
- **El software comparable.** MaintainX cobra USD 65 por usuario al mes en su
  plan Premium, con pago anual
  ([Software Advice](https://www.softwareadvice.com/cmms/maintainx-profile/),
  [Toolradar](https://toolradar.com/tools/maintainx/pricing)). Para 15
  usuarios son **USD 11 700 al año**, solo en la nube y sin módulos predictivos.
- **Horas de la gente.** Hoy IPSA lleva sus rondas en libros de Excel (uno por
  conjunto) y arma a mano los informes MPd y END. Eso son decenas de horas de
  analista al mes que el sistema elimina.

> Si PREDICTIVE evita seis horas de parada de la línea de secadores en un año,
> el Plan 2 se pagó, aun a precio de lista.

### 1.1 Lo que el CONTEXTO A dejaba en la mesa

Con 250 USD/mes (3 000 USD/año) y la implementación incluida, el primer año
quedaba en pérdida o en cero:

| Concepto (escenario A, SaaS) | Horas | USD |
|---|---|---|
| Implementación: instalación en nuestro VPS, carga de 153 conjuntos, historial, capacitación de 2 días, cambios básicos, acompañamiento, 3 visitas, gestión | ~105 h | 2 190 |
| Operación de 12 meses: soporte (~3 h/mes), parte del VPS, gastos generales | | 1 100 – 1 600 |
| **Costo del año 1** | | **3 300 – 3 800** |
| **Ingreso del año 1** | | **3 000** |

Que al cliente le gustara el precio y no lo regateara es una señal de que estaba
**barato**. El pedido de on-premise cambia el alcance, y es el momento natural
de corregir el precio.

---

## 2. T1 — Por qué on-premise cuesta más que SaaS

On-premise nos quita las economías de escala:

1. **Un ambiente por cliente.** Cada actualización se empaqueta, se prueba y se
   aplica con el TI de IPSA, en lugar de una sola vez para todos.
2. **Soporte a ciegas.** No vemos los registros ni el servidor salvo que su TI
   nos dé acceso, así que cada incidente tarda más.
3. **Visitas presenciales** cuando no hay acceso remoto.
4. **Seguridad y licencia reforzadas** (§5): firmas, compilación y renovaciones.
5. **Riesgo de impago y de copia:** el sistema queda en sus manos.

Por esa misma razón la industria cobra el on-premise más caro que la nube, y
cobra la implementación aparte.

---

## 3. T1 — Los tres planes

Se presentan **de mayor a menor** (ancla). El recomendado es el 2.

### 3.1 Resumen, con la licencia del primer año incluida

Precios de lista, en USD y sin IGV:

| | **Plan 3 — Planta Protegida** | **Plan 2 — Gestionado** ★ | **Plan 1 — Esencial** |
|---|---|---|---|
| Modelo | DFY: servidor de Industrie Ampel en su planta, llave en mano | DWY: su servidor, operado por nosotros | DIY+: su servidor, lo opera su TI |
| Dónde viven los datos | En su planta, en un equipo nuestro en comodato | En su servidor | En su servidor |
| Implementación (pago único) | **11 200** | **9 200** | **6 900** |
| Licencia de uso, 12 meses (250 × 12) | 3 000 | 3 000 | 3 000 |
| Servicios, 12 meses | 7 680 (640 × 12) | 5 280 (440 × 12) | 1 800 (150 × 12) |
| **Total año 1** | **21 880** | **17 480** | **11 700** |
| Mensualidad (licencia + servicios) | 890 | 690 | 400 |
| Por conjunto (200) al mes | 4,45 | 3,45 | 2,00 |
| Desde el año 2 | 10 680/año | 8 280/año | 4 800/año |
| Margen año 1 a precio de lista | 10 601 (48 %) | 9 067 (52 %) | 6 289 (54 %) |
| Margen año 1 al cierre esperado (§3.7) | 7 420 (40 %) | 6 506 (44 %) | 4 465 (45 %) |
| Margen año 1 al piso | 3 986 (26 %) | 2 723 (25 %) | 1 924 (27 %) |
| Margen desde el año 2, a lista | 4 613/año | 4 168/año | 2 724/año |
| Plazo mínimo | 24 meses | 12 meses | 12 meses |

### 3.2 Licencia vs. mensualidad

Son dos cosas distintas, y conviene que IPSA las vea separadas:

| | **Licencia de uso** | **Servicios** |
|---|---|---|
| Qué es | El derecho a usar el software, que es propiedad de Industrie Ampel | El trabajo de nuestro equipo para que el sistema funcione en su planta |
| Qué incluye | Todos los módulos, hasta 200 conjuntos (≈ 650 equipos), 40 usuarios, 1 planta, nuevas versiones y renovación del archivo de licencia | Soporte, actualizaciones, revisión del servidor, informe, visitas y, en el Plan 3, el servidor en comodato. Las mejoras a medida van aparte (§3.8) |
| Precio | USD 250/mes (**USD 3 000/año**), **igual en los tres planes** | USD 150, 440 o 640 al mes, según el plan |
| ¿Se negocia? | **No.** Es lo que protege el archivo `.lic` y donde está casi todo el margen | Solo quitando o agregando ítems, nunca bajando la tarifa |
| Si no se paga | El sistema pasa a solo lectura y luego a «solo exportar» (§5.6) | Se suspende el servicio, y la llave del trimestre siguiente no se emite hasta que se pongan al día (§3.11) |
| Detracción (SPOT) | Cesión en uso de un bien mueble, que tendría el 10 % | Servicios, 12 % |

- **Mensualidad = licencia + servicios.** USD 400 = 250 + 150; 690 = 250 + 440;
  890 = 250 + 640.
- **La implementación** es un tercer concepto: un servicio de pago único, aparte
  de los dos anteriores.

**Cómo facturarlo (recomendado):**

- **La licencia, anual y adelantada:** una factura de USD 3 000 al inicio de cada
  año.
- **Los servicios, por trimestre.**
- Las dos van en líneas o facturas separadas, por la detracción.

**Por qué separarlas:**

1. **«La licencia no subió».** En la nube les ofrecimos USD 250/mes, y la
   licencia sigue costando eso. Lo que se suma es el servicio para que el sistema
   viva en su servidor.
2. **Se negocia sobre servicios, no sobre la licencia.** Si piden bajar la
   mensualidad, la rebaja sale de los servicios (§3.7) y la licencia se queda
   en USD 250.
3. **La llave técnica sigue al pago de la licencia** (§5.3).

### 3.3 Qué incluye cada plan

| Ítem | Plan 1 | Plan 2 ★ | Plan 3 |
|---|---|---|---|
| **Implementación** | | | |
| Reunión técnica y plan de instalación con su TI | ✓ | ✓ | ✓ |
| Instalación y aseguramiento: Docker, PostgreSQL, HTTPS interno, respaldo diario y prueba de restauración | En su servidor | En su servidor | En nuestro servidor en comodato |
| Carga de los ~153 conjuntos que faltan, con su historial | ✓ | ✓ | ✓ |
| Mapa de criticidad de los 200 conjuntos (1 línea de secadores, 2 con respaldo, 3 auxiliar) | ✓ | ✓ | ✓ |
| Capacitación presencial (1 instructor) | 2 días | 3 días | 3 días |
| Cambios básicos a medida | 20 h | 30 h | 40 h |
| Acompañamiento después del arranque | 1 semana | 2 semanas | 3 semanas |
| Visitas durante la implementación, además de los días de capacitación | 2 | 3 | 5 |
| **Mensualidad** | | | |
| Licencia de uso (§3.2) | ✓ | ✓ | ✓ |
| Soporte por ticket, WhatsApp o correo, de lunes a viernes | Respuesta en 48 h, hasta 4 h/mes | Respuesta en 8 h hábiles, hasta 6 h/mes | Respuesta en 4 h hábiles, hasta 6 h/mes |
| Actualizaciones | Trimestral, aplicada junto con su TI | Mensual, la aplicamos nosotros | Mensual, la aplicamos nosotros |
| Revisión del servidor y prueba de restauración del respaldo | — | Mensual | Mensual |
| Informe de uso y confiabilidad para la gerencia | — | Trimestral | Trimestral |
| Visita presencial (medio día) | — | 1 por trimestre | 2 por trimestre, no acumulables |
| Servidor nuestro en su planta: disco cifrado, UPS, disco de respaldo y reposición a nuestro cargo | — | — | ✓ |
| Mejoras a medida | Aparte (§3.8) | Aparte (§3.8) | Aparte (§3.8) |

Por qué existe el Plan 3: es el ancla de precio, y además es el diseño que mejor
nos protege (§5.9). Queda pendiente confirmar si su política acepta un equipo
nuestro dentro de su planta.

### 3.4 Implementación: costo y precio de lista por ítem

- **Costo** = horas × USD 23 (la hora más el 15 % de gastos generales), más la
  movilidad con sus gastos.
- **Precio de lista** = horas × USD 53.
- El ítem I (planes 1 y 2) y el ítem H (Plan 3) absorben el redondeo del total.
- Formato de cada celda: `horas · costo → precio de lista`, en USD.

| Ítem | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| A. Reunión técnica con TI: red, seguridad, servidor y usuarios | 6 h · 138 → **318** | 6 h · 138 → **318** | 6 h · 138 → **318** |
| B. Instalación y aseguramiento (12 h) + licencia, endurecimiento y prueba de restauración (4 h) | 16 h · 368 → **848** | 16 h · 368 → **848** | 16 h · 368 → **848** |
| C. Carga de ~153 conjuntos (24 h) + historial (8 h), con el importador de sus libros | 32 h · 736 → **1 696** | 32 h · 736 → **1 696** | 32 h · 736 → **1 696** |
| D. Mapa de criticidad, con su jefe de mantenimiento | 4 h · 92 → **212** | 4 h · 92 → **212** | 4 h · 92 → **212** |
| E. Capacitación presencial, 1 instructor (2 días: 16 h + 6 h de preparación; 3 días: 24 h + 8 h) | 2 días · 22 h · 506 → **1 166** | 3 días · 32 h · 736 → **1 696** | 3 días · 32 h · 736 → **1 696** |
| F. Cambios básicos a medida | 20 h · 460 → **1 060** | 30 h · 690 → **1 590** | 40 h · 920 → **2 120** |
| G. Acompañamiento después del arranque | 8 h · 184 → **424** | 16 h · 368 → **848** | 24 h · 552 → **1 272** |
| H. Habilitación del servidor en comodato: preparación, cifrado, prueba de 48 h, transporte e instalación | — | — | 8 h · 184 → **1 024** |
| I. Gestión del proyecto (12 / 15 / 18 h) y viajes (4 / 6 / 8: días de capacitación + visitas), con movilidad | 22 h · 644 → **1 176** | 30 h · 897 → **1 992** | 38 h · 1 150 → **2 014** |
| **Total** | **130 h · 3 128 → 6 900** | **166 h · 4 025 → 9 200** | **200 h · 4 876 → 11 200** |

**Desglose del costo, a precio de lista:**

| Concepto | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Mano de obra (horas × USD 20) | 2 600 | 3 320 | 4 000 |
| Movilidad (viajes × USD 30) | 120 | 180 | 240 |
| Gastos generales (15 %) | 408 | 525 | 636 |
| Financiamiento de la OC a 90 días (3 % del precio) | 207 | 276 | 336 |
| **Costo exacto** | **3 335** | **4 301** | **5 212** |
| **Precio de lista** | **6 900** | **9 200** | **11 200** |
| **Margen** | **3 565 (52 %)** | **4 899 (53 %)** | **5 988 (53 %)** |

El hardware del Plan 3 (≈ USD 2 750) no está en la implementación. Se paga con
la mensualidad (USD 100/mes, §3.5), sigue siendo de Industrie Ampel y vuelve a
nosotros si el contrato termina.

### 3.5 Mensualidad: costo y precio por ítem

- **Costo de cada ítem** = horas × USD 23 + gastos directos × 1,15 + 3 % de
  financiamiento.
- Formato de cada celda: `costo → precio`, en USD por mes.

| Ítem | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Licencia de uso (renovación 0,5 h + nuestra infraestructura USD 10) | 30,50 → **250** | 30,50 → **250** | 30,50 → **250** |
| Soporte | 4 h + actualización trimestral (2 h): 142,50 → **150** | 6 h, respuesta en 8 h: 143,70 → **190** | 6 h, respuesta en 4 h: 144,00 → **200** |
| Actualización mensual | (incluida en soporte) | 3 h: 71,85 → **95** | 3 h: 71,85 → **95** |
| Revisión del servidor, prueba de respaldo e informe trimestral a gerencia | — | 2 h: 47,95 → **65** | 3 h, con guardia del tiempo de respuesta: 71,85 → **95** |
| Visitas presenciales (medio día; 4,5 h y USD 30 cada una, con traslado) | — | 1 por trimestre (1,5 h + USD 10 al mes): 48,70 → **90** | 2 por trimestre (3 h + USD 20 al mes): 96,50 → **150** |
| Servidor en comodato (USD 2 750 / 36 meses) | — | — | 90,85 → **100** |
| **Total** | **6,5 h · 173 → 400** | **13 h · 342,70 → 690** | **15,5 h · 505,55 → 890** |
| **Margen mensual** | **227 (57 %)** | **347 (50 %)** | **384 (43 %)** |

**Desglose del costo mensual:**

| Concepto | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Mano de obra (horas × USD 20) | 130 | 260 | 310 |
| Movilidad | — | 10 | 20 |
| Nuestra infraestructura (servidor de licencias, registro privado, copia de versiones) | 10 | 10 | 10 |
| Servidor en comodato | — | — | 76,39 |
| Gastos generales (15 %) | 21 | 42 | 62,46 |
| Financiamiento (3 %) | 12 | 20,70 | 26,70 |
| **Costo exacto** | **173** | **342,70** | **505,55** |

**Dónde está el margen:** sobre todo en la licencia, que deja USD 219,50 al mes
en cada plan. En los planes 2 y 3 los servicios también dejan margen, y ese
margen es el espacio para negociar la mensualidad (§3.7). Las mejoras a medida
nunca van dentro de la mensualidad: se cobran por hora o por bolsa (§3.8).

### 3.6 Año 1, año 2 y caja

| | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Año 1 a precio de lista: ingreso → margen | 11 700 → 6 289 (54 %) | 17 480 → 9 067 (52 %) | 21 880 → 10 601 (48 %) |
| Año 1 al cierre esperado (§3.7): ingreso → margen | 9 820 → 4 465 (45 %) | 14 840 → 6 506 (44 %) | 18 600 → 7 420 (40 %) |
| Año 1 al piso: ingreso → margen | 7 200 → 1 924 (27 %) | 10 940 → 2 723 (25 %) | 15 060 → 3 986 (26 %) |
| Margen desde el año 2: lista / cierre / piso | 2 724 / 2 258 / 1 560 | 4 168 / 3 353 / 2 189 | 4 613 / 3 566 / 3 333 |
| Lo que adelantamos antes del primer cobro: implementación + inversión de producto (§3.9), más el servidor en el Plan 3 | 5 512 | 6 409 | 10 010 |

- **Por qué el Plan 2 sigue siendo el recomendado.** Deja USD 347 al mes, mucho
  más que el Plan 1 (227) y cerca del Plan 3 (384), sin el riesgo ni la caja del
  hardware. Además las actualizaciones las aplicamos nosotros, así que hay menos
  incidentes, y la visita trimestral abre la venta de otros servicios.
- **Aun cargando a IPSA toda la inversión de producto y el registro en INDECOPI**
  (USD 2 750, §3.9), el Plan 2 al cierre esperado deja USD 3 756 el primer año.

### 3.7 Estrategia de negociación: lista → cierre → piso

IPSA va a pedir rebaja. Los precios de lista dejan espacio para darla **sin
regalar nada**: cada concesión se cambia por algo que nos sirve, y cada una es
más chica que la anterior. Así el cliente siente que llegó al límite.

**Implementación** (USD):

| Escalón | Lo que IPSA da a cambio | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|---|
| Lista | — | 6 900 | 9 200 | 11 200 |
| 1. −10 % | Contrato de 24 meses (en el Plan 3, que ya es de 24: contrato de 36 meses, el plazo en que se paga el servidor) | 6 200 | 8 300 | 10 100 |
| 2. −7 % más | Orden de compra emitida antes de una fecha límite (por ejemplo, fin de mes) | 5 700 | 7 600 | 9 300 |
| 3. −3 % más (el último) | Carta de referencia y permiso para usar a IPSA como caso de éxito | **5 500** | **7 400** | **9 000** |
| Piso: solo quitando alcance | — | 3 600 | 4 700 | 5 700 |

**El cierre esperado es el escalón 3.** Por debajo de él, el precio no baja: se
quita alcance, a precio de lista.

- Capacitación de 3 días a 2 (planes 2 y 3): −530.
- Cambios a medida de 30 a 20 h: −530.
- Acompañamiento de 2 semanas a 1: −424.

**Por debajo del piso no se firma:** ahí la implementación deja menos de 10 % de
margen.

**Mensualidad** (USD): la licencia se queda en USD 250; lo que se rebaja sale de
los servicios.

| Escalón | Lo que IPSA da a cambio | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|---|
| Lista | — | 400 | 690 | 890 |
| Cierre: −10 % | Los servicios del año facturados en una sola factura (sin el bono de 20 h) | **360** | **620** | **800** |
| Piso | Solo quitando servicios, por ejemplo una visita | 300 | 520 | 780 |

Margen mensual en el piso: 43 %, 35 % y 36 %.

**Reglas de la mesa:**

1. **Nunca conceder primero ni sin contrapartida.** La frase es «si ustedes…,
   nosotros…».
2. **Ante «está caro», preguntar qué parte del alcance quieren revisar.** No
   responder con un número.
3. **Máximo tres concesiones en la implementación y una en la mensualidad,**
   cada vez más chicas: 10, 7 y 3 %.
4. **La licencia no baja nunca.** Bajo el cierre de la mensualidad, se quita un
   servicio (una visita, por ejemplo) en vez de rebajar.
5. **Si el pago anual adelantado se usó como contrapartida,** ya no se da el bono
   de 20 h (§3.11).

### 3.8 Tarifas adicionales (van en la propuesta)

| Concepto | Precio | Costo |
|---|---|---|
| Mejoras a medida, por hora (desarrollo, soporte o capacitación remota) | USD 35 | 24,05 |
| Bolsa prepagada de 10 h de mejoras, vigente 3 meses | USD 330 | 239,90 |
| Visita adicional: medio día en planta, incluye traslado | USD 250 | 191,50 |
| Día adicional de capacitación (1 instructor) | USD 450 | 335,50 |
| Bloque de 25 conjuntos sobre los 200 | USD 30/mes de licencia + USD 150 de carga | 0,90/mes + 96,50 |
| Levantamiento en campo de datos de placa, si IPSA no los tiene | USD 20 por conjunto | 14,40 |

Las mejoras a medida ya no van dentro de ningún plan: se venden por hora o en
bolsa. Los cambios básicos de la implementación (20, 30 o 40 h) sí siguen
incluidos.

### 3.9 Inversiones únicas que no dependen del plan

| Inversión | USD | Detalle |
|---|---|---|
| Producto on-premise (§5.10): 92 h × USD 23 | 2 116 | Instalador, licencia Ed25519, compilación, servidor de licencias |
| PyArmor Group (pago único) | 158 | Precio de su documentación v8; verificar antes de comprar |
| 2 llaves físicas para la clave privada | ~110 | Estimado |
| Registro en INDECOPI: marca en clases 9 y 42 + software | ≈ 366 (S/ 1 263,45) | §7 |
| Revisión del contrato de licencia por un abogado | Por cotizar | |
| Servidor en comodato (solo Plan 3) | ≈ 2 750 | Se recupera con la mensualidad (USD 100/mes) |

### 3.10 Sensibilidad

| Si… | Efecto en el Plan 2 |
|---|---|
| IPSA paga a 30 días (Ley 31362, §3.11) | El financiamiento baja del 3 % al 1 %: +USD 350 de margen en el año 1 a precio de lista |
| La hora sube USD 1 | +USD 191 de costo en la implementación y +USD 15 al mes |
| IPSA no tiene los datos de los 153 conjuntos | +~51 h de levantamiento (USD 1 173 de costo); se cobra con la tarifa de USD 20 por conjunto |
| Su TI no da acceso remoto | La instalación y el soporte necesitan visitas extra: se cobran a USD 250 cada una |

Fórmula del piso:

```
precio mínimo = costo sin financiamiento / (1 − margen objetivo − 0,03)
```

El piso usa un margen objetivo del 10 % en la implementación y del 35 % en la
mensualidad. En el Plan 1 queda en USD 300, más que la fórmula (USD 260), porque
más abajo el soporte quedaría regalado.

### 3.11 Condiciones de pago con orden de compra a 90 días

1. **Implementación en tres hitos.**
   - 40 % al recibir la OC, con la reunión técnica hecha.
   - 30 % con el servidor instalado y los conjuntos cargados.
   - 30 % con la capacitación y el acta de puesta en marcha.

   Un «50 % al firmar» no protegería: con 90 días de plazo, llegaría después del
   arranque.
2. **Licencia anual y servicios trimestrales** (§3.2), contra una OC anual.
3. **La licencia sigue al pago** (§5.3).
   - El archivo de cada trimestre vence al cierre del trimestre, más 30 días
     de gracia.
   - El del trimestre siguiente se emite cuando las facturas vencidas están
     pagadas.
   - Lo máximo que IPSA puede usar sin pagar es un trimestre y 30 días (en el
     Plan 2, ~USD 2 760).
4. **Ley 31362 (pago a las MYPE en 30 días).** Aplica si Industrie Ampel es una
   empresa formal con ventas anuales de hasta 1 700 UIT (S/ 9,35 millones en
   2026).
   - IPSA debe pagar sus facturas en 30 días calendario desde la emisión.
   - Para pactar un plazo mayor, el reglamento exige un acuerdo escrito con
     firmas legalizadas ante notario o por escritura pública, en el que el
     proveedor declare que no hay abuso.
   - La mora genera intereses.
   - Con cada factura se entrega la declaración jurada anual del impuesto a la
     renta del año anterior y la cuenta bancaria.

   Recomendación: poner «30 días» en la propuesta. Si IPSA exige 90, aceptarlo,
   porque el precio ya lo cubre, y firmar el acuerdo que pide la ley. Confirmarlo
   con tu contador.
5. **Factoring.** Las facturas negociables se pueden vender a un banco o a una
   empresa de factoring tras la conformidad de IPSA (8 días). Se cobra en días,
   a cambio de ~2–5 %. Es el 3 % que ya está en el costo.
6. **Detracción (SPOT).** En facturas de más de S/ 700, IPSA deposita una parte
   en nuestra cuenta del Banco de la Nación, que solo sirve para pagar
   impuestos.
   - SUNAT trata la licencia de software como cesión en uso de un bien mueble,
     que tendría el 10 %; los servicios van al 12 %.
   - Por eso la licencia y los servicios se facturan por separado.
   - Confirmar los porcentajes con tu contador.
7. **Pago anual adelantado → bono, no descuento** (regla de Hormozi: agregar
   valor en vez de bajar el precio). Si pagan el año en una sola factura, se
   suman 20 h de mejoras a medida (valor USD 700; nos cuestan USD 460). No se da
   si el pago anual ya se usó en la escalera (§3.7).
8. **Contrato de 12 meses (24 en el Plan 3)**, con renovación automática y
   preaviso de 60 días.
9. **IGV (18 %)** aparte en todos los precios.

### 3.12 Psicología del precio

- **«La licencia no subió».** En la nube les ofrecimos USD 250/mes; la licencia
  sigue costando USD 250 en los tres planes. Lo que se suma es el servicio para
  que el sistema viva en su servidor. Es el argumento más fuerte de la reunión.
- **Ancla:** se muestra primero el Plan 3; el Plan 2 se ve razonable y el
  Plan 1 se ve barato.
- **En horas de parada:** «todo el primer año del Plan 2 cuesta menos que seis
  horas de su línea de secadores detenida».
- **Por conjunto:** «USD 3,45 por conjunto al mes, 12 centavos al día».
- **Desglose por ítem:** ver las horas de cada ítem hace que la implementación
  se discuta por alcance y no por un número redondo.
- **Garantías que reducen el riesgo percibido:**
  - **Garantía de arranque:** sus 200 conjuntos cargados y operando en 30 días
    desde que el servidor está listo y recibimos sus datos, o el último hito
    (30 %) no se cobra.
  - **Garantía de salida:** sus datos se exportan completos (Excel y SQL)
    cuando quieran, incluso si no renuevan.

### 3.13 Historia de justificación (para la reunión)

> Ustedes nos pidieron que sus datos no salgan de su planta. La licencia del
> sistema sigue costando lo que les ofrecimos: USD 250 al mes. Lo que cambia es
> el trabajo. En lugar de cuidar un sistema en la nube compartido, montamos y
> mantenemos uno solo para IPSA, dentro de su red. Eso es la implementación y el
> servicio mensual.
>
> Pongámoslo en contexto. Ustedes nos dijeron que una hora de la línea de
> secadores parada les cuesta unos USD 3 000. En setiembre de 2025, sus propios
> registros marcaban en parada los reductores del 1er y del 3er grupo de
> secadores. Con el Plan Gestionado tienen sus 200 conjuntos clasificados por
> criticidad, visitas trimestrales, actualizaciones y su programa predictivo
> completo por USD 3,45 por conjunto al mes. Todo el primer año cuesta menos que seis horas
> de esa línea detenida.

### 3.14 Revisión de riesgos

| Riesgo | Mitigación |
|---|---|
| **Ancla demasiado alta.** IPSA escuchó USD 250/mes con todo incluido; el primer año del Plan 2 a lista es 5,8 veces eso. Puede retirarse en vez de negociar. | Abrir con «la licencia no subió» y el desglose por ítem. Si la reacción es muy negativa, pasar rápido al escalón 2 a cambio de la OC con fecha. Tener el Plan 1 como entrada. |
| **Choque contra el ancla de USD 250.** | Último recurso: licencia sola a USD 250/mes con soporte por hora (USD 35), siempre con la implementación cobrada. **Nunca** on-premise a USD 250 con la implementación incluida. |
| OC a 90 días | Hitos, licencia por período, Ley 31362 y factoring (§3.11). |
| Su TI no permite acceso remoto | Visitas extra a USD 250 cada una (§3.8), o el Plan 3. |
| Su TI no acepta un servidor ajeno | El Plan 3 se convierte en «su servidor con administración total nuestra», a USD 790/mes (sin los USD 100 del hardware). |
| Faltan datos de los conjuntos | Tarifa de levantamiento en campo (USD 20 por conjunto). |
| Los «cambios básicos» crecen sin control | Horas fijas por plan; lo que exceda, a USD 35/h. |
| Cambio USD/PEN | Facturar en USD, o en PEN con el tipo de cambio del día de la factura. |

### 3.15 Experimentos

- En la reunión, presentar primero el Plan 3. Si lo descartan por precio, que
  sea **elección entre el 2 y el 1**, no entre «sí o no».
- Ofrecer el bono del pago anual como cierre: «si firman este mes con pago
  anual, les sumamos 20 h de mejoras».
- Anotar en qué escalón cierra IPSA. Si cierra en el 1 o en el 2, la lista del
  próximo cliente on-premise puede subir; si exige el piso, hay que bajarla.

---

## 4. T1 — Objeciones (objection-destroyer)

| # | Objeción | Creencia escondida | Nueva creencia | Prueba |
|---|---|---|---|---|
| 1 | «Si el servidor lo pongo yo, ¿por qué cuesta más?» | «Me cobran más por menos» | «La licencia no subió; lo que se suma es operar un sistema solo para mí» | La licencia sigue en USD 250 (§3.2). El VPS del escenario A cuesta ~USD 57/mes ([VPSBenchmarks](https://www.vpsbenchmarks.com/hosters/contabo/plans/cloud-vps-60)); la diferencia es trabajo (§2). |
| 2 | «No queremos que nadie externo vea datos ni entre a la red» | «Instalar software de terceros = abrir la puerta» | «El sistema funciona sin enviar un solo dato fuera; el acceso es suyo» | La licencia se renueva con un **archivo** (§5.3), sin internet. Si permiten conexión, solo viajan el id de licencia y conteos, auditables en su propio registro. El soporte remoto lo abre su TI, cuando quiere. |
| 3 | «¿Por qué renovar la licencia? ¿Qué pasa con nuestros datos si no renovamos?» | «Nos van a secuestrar los datos» | «Los datos son de IPSA siempre; lo que se licencia es el software» | Garantía de salida: exportación completa en cualquier momento. Al vencer: aviso de 30 días, gracia en solo lectura y, después, **solo exportar** (§5.6). |
| 4 | «Pagamos con OC a 90 días» | «El proveedor se tiene que adaptar a nosotros» | «Se trabaja con su OC; el precio ya lo contempla» | Licencia anual y servicios trimestrales contra una OC anual; la licencia cubre el trimestre más 30 días (§3.11). |
| 5 | «Antes la implementación estaba incluida» | «Me están cobrando dos veces» | «En la nube se diluía en un servidor compartido; en su planta es trabajo solo para ustedes» | 167 horas de nuestro equipo, ítem por ítem (§3.4). |
| 6 | «Está caro, necesitamos un descuento» | «El precio es arbitrario» | «El precio sale del alcance; si cambia el alcance o el compromiso, cambia el precio» | Desglose por ítem (§3.4) y escalera con contrapartidas (§3.7). |
| 7 | «¿Y si Industrie Ampel desaparece?» | «Me quedo con un sistema sin dueño» | «Su continuidad está garantizada por contrato» | **Escrow de código:** un depositario neutral guarda el código y se lo entrega solo si dejamos de operar. |

**Respuestas cortas, listas para WhatsApp:**

1. «La licencia sigue costando lo mismo: USD 250 al mes. Lo que se suma es el
   servicio de mantener un sistema solo para ustedes dentro de su red.»
2. «El sistema no envía datos a ningún lado. La licencia se renueva con un
   archivo que sube su administrador; si su TI prefiere, ni siquiera necesita
   internet.»
3. «Sus datos son suyos siempre: se exportan completos cuando quieran, incluso si
   un día no renuevan. Lo que licenciamos es el software, no su información.»
4. «Trabajamos con su orden de compra. Si pagan el año completo les sumamos
   20 h de mejoras a medida.»
5. «En la nube la instalación se repartía entre todos los clientes. En su planta
   es un trabajo solo para ustedes: les mostramos las horas ítem por ítem.»
6. «Podemos ajustarlo. ¿Qué parte del alcance quieren revisar? Si firmamos a
   24 meses, la implementación baja 10 %.»

---

## 5. T2 — Protección del sistema en un servidor que no controlamos

### 5.0 La verdad primero

**No existe una llave irrompible** cuando el programa corre en un servidor que
controla otra persona. Con tiempo y conocimiento, cualquier verificación se
puede quitar. Lo que sí se logra, y es como protegen su software los grandes
proveedores on-premise, es esto:

- **Que romperla cueste más que pagar.**
- **Que se detecte y se pueda rastrear** de qué instalación salió una copia.
- **Que el contrato haga del uso no autorizado un riesgo legal** que una empresa
  formal como IPSA no corre.

Por eso la protección tiene capas. Ninguna sola basta; juntas hacen que pagar
sea lo más barato.

### 5.1 Por qué la licencia de hoy no sirve en on-premise

Hoy la llave es `payload.HMAC-SHA256(payload, LICENSE_SECRET)`
([doc 08 §4](../08-onpremise-and-licensing.md)). Se diseñó suponiendo que la
aplicación corre **en nuestros servidores**: con HMAC, quien verifica y quien
firma comparten el mismo secreto. En on-premise ese secreto estaría en el
`.env` del servidor de IPSA, así que **cualquiera con acceso podría emitirse
licencias**. Doc 08 lo dice explícitamente: la firma asimétrica «solo aporta
algo cuando el verificador está en manos hostiles». En on-premise lo está.

Lo bueno: el resto del ciclo de vida ya existe. Aviso a 30 días, solo lectura en
la gracia, bloqueo, revocación, límites del plan (equipos, usuarios, plantas) y
el aviso «El plan va por X de Y equipos».

### 5.2 Capa 1 — Licencia firmada con clave asimétrica (Ed25519)

- **La clave privada nunca sale de Industrie Ampel.** Va en un equipo fuera de
  línea o en una llave física (tipo YubiKey), con respaldo cifrado.
- **La clave pública va compilada dentro del programa**, nunca en el `.env`. Si
  estuviera en un archivo, bastaría con cambiarla por otra propia.
- El servidor de IPSA solo puede **verificar** licencias, nunca **crearlas**.
- Ejemplo de archivo de licencia (`ipsa-2026T4.lic`):

```json
{
  "v": 2,
  "license_id": "lic-7f3a9c21",
  "customer": "Industrias del Papel S.A.",
  "tenant": "ipsa",
  "installation_id": "5d2c8e1a-…",
  "fingerprint": { "pg_system_id": "7351…", "machine_id": "a1b2…" },
  "plan": "gestionado",
  "modules": ["*"],
  "limits": { "equipment": 650, "users": 40, "plants": 1 },
  "valid_from": "2026-11-01",
  "valid_until": "2027-01-31",
  "grace_days": 30,
  "max_version": "3"
}
```

  Va acompañado de una firma Ed25519 de 64 bytes.
- En el código hay que cambiar `issue()` y `verify()` de
  `licensing/domain/license.py` y agregar la librería `cryptography`, que hoy no
  está instalada. Lo demás del módulo se reutiliza.

### 5.3 Capa 2 — Licencias cortas que se renuevan solas solo si pagan

La llave vence al cierre del trimestre facturado, más 30 días de gracia. Con la
OC a 90 días, la factura del trimestre vence justo al cierre, así que la gracia
deja un mes para pagos atrasados. **La llave del trimestre siguiente se emite
solo con las facturas vencidas pagadas** (§3.11). No hace falta apagar nada a
distancia: la llave caduca sola.

Dos formas de renovar, según la política de red de IPSA:

| Modo | Cómo funciona | Qué sale de su red |
|---|---|---|
| **En línea** (si TI permite HTTPS saliente a un solo dominio) | Una vez al día el servidor consulta `licencias.industrieampel.com` y, si el período está pagado, recibe el archivo nuevo. | Solo el id de licencia, la huella, la versión y los conteos de equipos y usuarios. **Ningún dato de mantenimiento.** Queda un registro local que su TI puede auditar. |
| **Sin internet** (red aislada) | En *Configuración → Licencia* se genera un **código de solicitud** (texto o QR). El administrador lo envía por correo, devolvemos el `.lic` firmado y él lo sube. Una vez por período. | Nada automático. |

### 5.4 Capa 3 — Atar la licencia a esa instalación

Hoy la huella es `sha256(tenant|nombre de BD|host)`, que se reproduce en otro
servidor con los mismos nombres. La nueva huella combina tres datos:

- `installation_id`: un UUID creado al instalar, guardado en la base y en el
  volumen de datos.
- El identificador de sistema de PostgreSQL (`system_identifier`), único por
  clúster; cambia si se recrea la base.
- El `machine-id` del servidor.

**Regla: 2 de 3 deben coincidir.** Así un cambio legítimo de hardware no rompe
el sistema, pero una copia a otro servidor sí se detecta. Para mudanzas
legítimas, una reactivación guiada (mismo procedimiento que §5.3).

### 5.5 Capa 4 — Que atrasar el reloj no sirva

Se guarda la **marca de tiempo más alta que el sistema ha visto**, firmada con
la clave de la instalación, en la base y en un archivo. Además se contrasta con
la fecha de la lectura más reciente. Si el reloj retrocede más de 24 h, el
sistema pasa a solo lectura hasta que vuelva a la fecha correcta.

### 5.6 Capa 5 — Al vencer: degradar, nunca secuestrar

Se mantiene el ciclo actual (aviso → gracia en solo lectura → bloqueo), con un
cambio para on-premise: **pasada la gracia, se bloquea el trabajo (registrar
datos, generar informes) pero siempre se pueden exportar sus datos.**

⚠️ **Nunca** programar que el sistema borre, cifre o dañe datos del cliente si no
paga. Además de destruir la relación comercial, en Perú puede configurar un
delito informático (Ley 30096, atentado contra la integridad de datos). La
presión legítima es que el **software** deje de trabajar, no la información.

### 5.7 Capa 6 — Que no sea fácil quitar la verificación del código

- **No entregar fuentes.** El backend se entrega **compilado** (Nuitka convierte
  Python en módulos nativos) dentro de imágenes Docker. Como segunda cerradura
  independiente, PyArmor (ofuscación comercial con su propia fecha de
  caducidad y atadura a máquina).
- **La verificación no es un solo `if`.** Comprobaciones repartidas en el
  middleware, la generación de PDF y Excel, las importaciones y las tareas de
  fondo, con verificación de integridad de los propios módulos.
- **El front** va compilado, sin mapas de fuente, y solo lo sirve el backend con
  licencia válida.
- **Imágenes firmadas** (cosign), entregadas por un registro privado o como
  archivo `.tar` firmado si no hay internet.
- **Marca de agua por cliente.** Cada entrega lleva el id de IPSA embebido en el
  binario y en los metadatos de los PDF. Si aparece una copia en otra empresa,
  sabemos de qué instalación salió.

### 5.8 Capa 7 — El contrato (la parte que sí es irrompible)

- **Contrato de licencia de uso, no de venta:** plazo, renovación y alcance (una
  instalación, ~200 conjuntos, N usuarios).
- **Prohibiciones:** copiar, descompilar, hacer ingeniería inversa, ceder a
  terceros o instalar en otro servidor sin autorización.
- **Derecho de auditoría** con preaviso y **penalidad** por uso no autorizado.
- **Suspensión por impago** con preaviso, coherente con la gracia técnica.
- **Marca y software registrados en INDECOPI** (§7): prueba de titularidad y
  autoría ante cualquier disputa.
- **Escrow opcional del código** (§4, objeción 7): calma el miedo del cliente sin
  entregarle el código.
- Revisar con un abogado antes de firmar.

### 5.9 Capa 8 — El servidor en comodato (Plan 3)

Es la opción técnicamente más fuerte:

- El equipo es de Industrie Ampel. Disco cifrado (LUKS) que se desbloquea con el
  chip TPM del propio equipo, arranque seguro y BIOS con contraseña. El cliente
  no tiene acceso de administrador.
- Los datos están **físicamente en su planta y en su red**, que es lo que pide la
  política.
- Si el contrato termina: se exportan sus datos y retiramos el equipo.

Pregunta clave para el TI de IPSA: ¿su política acepta un *appliance* de un
proveedor dentro de su planta, como un firewall o un grabador de cámaras que no
administran?

### 5.10 Cuánto cuesta hacerlo (inversión de producto, una sola vez)

Sirve para IPSA y para **todo cliente on-premise futuro**.

| Trabajo | h |
|---|---|
| Imágenes Docker, instalador y actualización sin internet | 16 |
| Instalación limpia y validada sobre PostgreSQL 16 | 12 |
| Licencia Ed25519, huella fuerte, renovación en línea y por archivo, protección contra reloj | 30 |
| Compilación del backend (Nuitka/PyArmor) y pruebas | 16 |
| Servidor de licencias pequeño (renovaciones) | 10 |
| Manual de instalación y de seguridad para el TI del cliente | 8 |
| **Total** | **92 h × USD 23 = USD 2 116** |

Con las herramientas (PyArmor y llaves físicas) suma USD 2 384 (§3.9). No se
carga entero a IPSA: se recupera con el margen del primer año de cualquiera de
los planes (§3.6).

### 5.11 Orden recomendado

1. **Antes de firmar:** presentar marca y software en INDECOPI (§7), contrato de
   licencia revisado por un abogado y preguntas a TI de IPSA (§6).
2. **Antes de instalar:** capas 1, 2, 3, 4 y 5 (licencia asimétrica, renovación,
   huella, reloj y modo «solo exportar»).
3. **Antes de entregar el primer instalador:** capa 6 (compilación, firma y
   marca de agua).
4. **Si eligen el Plan 3:** preparar el servidor en comodato (capa 8).

---

## 6. Preguntas abiertas

**Respondidas el 14 de octubre de 2026:**

| Pregunta | Respuesta |
|---|---|
| Costo real de la hora | USD 20 |
| Nombre de la empresa | Industrie Ampel («semáforo industrial» en alemán, con espacio); sin registro en INDECOPI (§7) |
| Forma de pago de IPSA | Orden de compra a 90 días |
| Tamaño | Cerca de 200 conjuntos rotativos |
| Costo de una hora de parada | ~USD 3 000 en la línea de secadores; bajo en equipos con respaldo y auxiliares |
| Precios de lista | Implementación 6 900 / 9 200 / 11 200; mensualidad 400 / 690 / 890 (fijados por el equipo para negociar) |
| Alcance (14-oct, segunda ronda) | Capacitación con 1 instructor (2 / 3 / 3 días); 2 / 3 / 5 visitas de implementación; informe trimestral; 1 y 2 visitas por trimestre; mejoras a medida aparte |

**Pendientes, para el TI de IPSA:**

1. ¿Su servidor puede salir a internet por HTTPS hacia un solo dominio (solo
   para la licencia), o es una red aislada?
2. ¿Darían acceso remoto por VPN para soporte, o todo debe ser presencial?
3. ¿Qué infraestructura tienen (VMware, Hyper-V, Windows Server, Linux)? ¿Pueden
   darnos una máquina virtual con Ubuntu Server?
4. ¿Aceptarían un servidor nuestro en comodato dentro de su planta (Plan 3)?

**Pendientes, para nosotros:**

5. ¿Industrie Ampel ya es una empresa formal (con RUC) y califica como MYPE?
   Decide si aplica la Ley 31362 (§3.11) y a nombre de quién va la marca (§7).
6. ¿IPSA tiene los datos de placa de los 153 conjuntos, o hay que levantarlos
   en campo (§3.8)?

**Pendientes, para IPSA:**

7. La lista de los 200 conjuntos, con su criticidad si la tienen.
8. Su precio promedio por tonelada (cierra el cálculo de los USD 3 000/h).
9. ¿Cuántos usuarios tendrán?

---

## 7. Registro en INDECOPI: sí, y antes de firmar

**Recomendación: sí.** Cuesta ≈ S/ 1 263 (USD 366). Sin marca ni software
registrados, probar que el sistema es de Industrie Ampel cuesta mucho más que
eso, y el contrato de licencia (§5.8) se apoya en esa prueba.

### 7.1 La marca «INDUSTRIE AMPEL»

- **Qué registrar:** la denominación «INDUSTRIE AMPEL» en dos clases:
  - Clase 9: software.
  - Clase 42: desarrollo de software, software como servicio, instalación y
    mantenimiento de software.

  Más adelante, si se quiere, el logo como marca mixta.
- **«PREDICTIVE» sola, no.** Para un software de mantenimiento predictivo es una
  palabra descriptiva, y lo más probable es que la rechacen. Se usa como
  «PREDICTIVE de Industrie Ampel».
- **Pasos:**
  1. Buscar antecedentes en BuscaTuMarca (`pi.indecopi.gob.pe/buscatumarca`,
     gratis) por «INDUSTRIE AMPEL» y por «AMPEL» en las clases 9 y 42. Opcional:
     la búsqueda fonética de INDECOPI, a S/ 30,66 por clase.
  2. Crear un usuario en Servicios en Línea
     (`serviciosenlinea.indecopi.gob.pe`).
  3. Pagar en el Banco de la Nación o en Págalo.pe: S/ 534,90 la primera clase y
     S/ 533,30 la segunda, en total S/ 1 068,20. Con inscripción en el REMYPE
     hay 25 % de descuento (S/ 401,20 la primera clase).
  4. Presentar la solicitud. Se publica en la Gaceta Electrónica y terceros
     tienen 30 días hábiles para oponerse.
  5. La resolución sale en ~45 días hábiles si no hay oposición. Vigencia de 10
     años, renovable.
- **Titular:** la empresa. Si todavía no está constituida, a nombre de los
  socios, y después se transfiere.

### 7.2 El software (Dirección de Derecho de Autor)

- **Tasa:** S/ 195,25 (código 203000710).
- **Requisitos:**
  - Solicitud y DNI de los autores.
  - Copia de la obra: código fuente y manual. Confirmar con INDECOPI si basta
    una porción representativa del código.
  - Comprobante de pago.
- **Plazo:** 30 días hábiles sin observaciones; hasta 120 si las hay.
- **Es declarativo:** el derecho nace al crear el software; el registro da fecha
  cierta y prueba de autoría.
- **Antes de presentar:** si el código lo escribieron varias personas, que
  firmen la cesión de sus derechos patrimoniales a la empresa.

### 7.3 Orden

1. Buscar en BuscaTuMarca hoy.
2. Presentar marca y software esta semana. La fecha de presentación ya da
   prioridad: no hace falta esperar la resolución para firmar con IPSA.
3. El contrato con IPSA cita la marca y el registro del software.

---

## Fuentes

**IPSA:**

- Capacidad, planta y proyecto: [Gestión, junio de 2025](https://gestion.pe/economia/empresas/industrias-del-papel-busca-potenciar-produccion-el-proyecto-en-chaclacayo-noticia/)
- Grupo JLB, fibra reciclada y RUC: [indupapel.com](https://www.indupapel.com/)
- Trabajadores: [DatosPerú](https://www.datosperu.org/empresa-industrias-del-papel-sa-20100151546.php)

**Mercado:**

- Costo de parada en papeleras: [TAPPI Paper360](https://paper360.tappi.org/?p=5261), [Oxmaint](https://oxmaint.com/article/paper-mill-cmms-maintenance-management-guide)
- MaintainX, precios por usuario: [Software Advice](https://www.softwareadvice.com/cmms/maintainx-profile/), [Toolradar](https://toolradar.com/tools/maintainx/pricing)
- Contabo Cloud VPS 60 (~€49 ≈ USD 57/mes): [VPSBenchmarks](https://www.vpsbenchmarks.com/hosters/contabo/plans/cloud-vps-60)

**Costos y herramientas:**

- Servidor Dell PowerEdge T160 (S/ 8 055,40 con IGV): [Panacompu](https://www.panacompu.com/peru/en/product-information/dell-poweredge-t160-server-tower-xeon-e-2436-16gb-ram-ddr5-up-to-128gb-ecc-4tb-hdd)
- PyArmor, tipos de licencia y precios: [documentación v8.2](https://pyarmor.readthedocs.io/en/v8.2/licenses.html)
- Tipo de cambio: [La Cámara, 12-oct-2026](https://lacamara.pe/precio-del-dolar-en-peru-hoy-12-de-octubre-de-2026/)

**Pagos e impuestos:**

- Ley 31362 y su reglamento: [La Cámara](https://lacamara.pe/reglamentan-ley-de-pago-de-facturas-mype-a-treinta-dias/)
- UIT 2026 (S/ 5 500): [LP Derecho](https://lpderecho.pe/valor-uit-2026-decreto-supremo-301-2025-ef/)
- Factoring y factura negociable: [Perú Gestiona](https://perugestiona.pe/?p=600)
- Detracción de licencias de software: [Noticiero Contable](https://noticierocontable.com/licencias-software-afecto-detraccion)

**INDECOPI:**

- Tasas y plazos de marca: [Trámites Perú, registro de marca](https://tramitesperu.com/indecopi/registro-marca/)
- Registro de software: [Trámites Perú, registro de obra](https://tramitesperu.com/indecopi/registro-obra/), [Modelo.pe](https://modelo.pe/solicitud-de-registro-de-programa-de-ordenador-software-ante-indecopi/)

Los precios de terceros, las tasas y los porcentajes tributarios cambian:
verificarlos en la fuente oficial (gob.pe, SUNAT) y con el contador antes de
citarlos ante el cliente.
