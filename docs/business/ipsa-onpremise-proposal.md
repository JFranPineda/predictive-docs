# IPSA on-premise: planes, precios y protección de la licencia

Documento **interno** de Industrie Ampel. Contiene costos y márgenes: no se
entrega al cliente.

Versión 2, 14 de octubre de 2026. Incorpora las respuestas del equipo: la hora
cuesta USD 20, IPSA paga con orden de compra a 90 días y el costo de parada
depende del tipo de equipo. Desglosa costo y precio ítem por ítem.

- **T1.** Tres planes para el CONTEXTO B (los datos de IPSA viven en su propio
  servidor), con costos exactos por ítem y precio recomendado. Construidos con
  los marcos de Hormozi: *pricing-strategy* (precio anclado al valor, niveles
  DIY/DWY/DFY) y *objection-destroyer* (objeciones → cambio de creencia →
  prueba).
- **T2.** Cómo proteger el sistema cuando corre en un servidor que no
  controlamos (§5), y cómo registrar marca y software en INDECOPI (§7).

> **Qué cambió respecto de la versión 1.**
>
> - La implementación no sumaba gastos generales ni el costo de cobrar a 90
>   días. Con ambos, los planes 1 y 2 quedaban con 9–10 % de margen.
> - Ahora toda la implementación se valoriza a una sola tarifa de USD 30/h.
> - La licencia vale USD 250/mes en los tres planes.
> - Se agregó el mapa de criticidad.

---

## 0. Supuestos

| Supuesto | Valor | Fuente |
|---|---|---|
| Costo de una hora del equipo (sueldo + cargas) | USD 20/h | Confirmado por el equipo |
| Gastos generales (administración, contabilidad, ventas, herramientas) | +15 % sobre todo costo directo, así que **la hora cargada cuesta USD 23** | Supuesto |
| Tarifa de venta de la implementación | USD 30/h | Recomendación: deja ≈ 20 % después de gastos y financiamiento |
| Traslado Lima ↔ Chaclacayo (Carretera Central km 18,5) | 2,5 h ida y vuelta + USD 30 de movilidad | Supuesto |
| Forma de pago de IPSA | Orden de compra a **90 días** | Confirmado |
| Costo de cobrar a 90 días | **3 % de cada factura** (factoring ≈ 1 %/mes) | Tasa por cotizar con el banco |
| Tipo de cambio | S/ 3,45 por USD | SUNAT, 12-oct-2026 |
| Precios | USD, **sin IGV** (18 %) | |
| Lo que ya está cargado de IPSA | 47 conjuntos, 98 equipos, 795 puntos y 10 536 lecturas, en 5 áreas | Base `tenant_ipsa` |
| Servidor del cliente (planes 1 y 2) | 4 vCPU, 8 GB, 400 GB SSD, Ubuntu Server 24.04 | [doc 07 §2](../07-deployment.md) |
| Servidor en comodato (Plan 3), ≈ USD 2 750 amortizados en 36 meses | Servidor ~1 980, RAM y SSD ~300, UPS ~350, disco de respaldo ~120 | Servidor: Panacompu, sin IGV. Resto: estimado, pedir cotización |

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
  (§3.6).

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

- **El primer año del Plan 2 (USD 13 480) equivale a 4,5 horas de la línea de
  secadores parada.** El del Plan 1 equivale a 2,9 horas y el del Plan 3, a 7,2.
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

> Si PREDICTIVE evita cinco horas de parada de la línea de secadores en un año,
> el Plan 2 ya se pagó.

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

### 3.1 Resumen

| | **Plan 3 — Planta Protegida** | **Plan 2 — Gestionado** ★ | **Plan 1 — Esencial** |
|---|---|---|---|
| Modelo | DFY: servidor de Industrie Ampel en su planta, llave en mano | DWY: su servidor, operado por nosotros | DIY+: su servidor, lo opera su TI |
| Dónde viven los datos | En su planta, en un equipo nuestro en comodato | En su servidor | En su servidor |
| Implementación (pago único) | **USD 6 200** | **USD 5 200** | **USD 3 900** |
| Mensualidad | **USD 1 290** | **USD 690** | **USD 400** |
| … de la cual, licencia | USD 250 | USD 250 | USD 250 |
| Por conjunto (200) al mes | USD 6,45 | USD 3,45 | USD 2,00 |
| Total año 1 | **USD 21 680** | **USD 13 480** | **USD 8 700** |
| Desde el año 2 | USD 15 480/año | USD 8 280/año | USD 4 800/año |
| Margen año 1 | USD 6 957 (32 %) | USD 3 853 (29 %) | USD 3 471 (40 %) |
| Margen desde el año 2 | USD 5 681/año | USD 2 788/año | USD 2 724/año |
| Plazo mínimo | 24 meses | 12 meses | 12 meses |

Cambios contra la versión 1:

- Implementación: 3 500 → 3 900, 4 500 → 5 200 y 6 500 → 6 200.
- Mensualidad del Plan 1: 390 → 400, para que la licencia valga USD 250 en los
  tres planes y su soporte no quede bajo costo.

### 3.2 Qué incluye cada plan

**La licencia de uso PREDICTIVE es igual en los tres planes (USD 250/mes):**

- Todos los módulos: vibraciones, ultrasonido, termografía, END, alineamiento,
  rodillos, mantenimiento, jornada laboral, usuarios e informes.
- Hasta 200 conjuntos (≈ 650 equipos), 40 usuarios y 1 planta.
- Derecho a las nuevas versiones.
- Renovación del archivo de licencia, también sin internet.
- Exportación completa de sus datos, siempre.

| Ítem | Plan 1 | Plan 2 ★ | Plan 3 |
|---|---|---|---|
| **Implementación** | | | |
| Reunión técnica y plan de instalación con su TI | ✓ | ✓ | ✓ |
| Instalación y aseguramiento: Docker, PostgreSQL, HTTPS interno, respaldo diario y prueba de restauración | En su servidor | En su servidor | En nuestro servidor en comodato |
| Carga de los ~153 conjuntos que faltan, con su historial | ✓ | ✓ | ✓ |
| Mapa de criticidad de los 200 conjuntos (1 línea de secadores, 2 con respaldo, 3 auxiliar) | ✓ | ✓ | ✓ |
| Capacitación de 2 días | 1 instructor | 2 instructores | 2 instructores |
| Cambios básicos a medida | 20 h | 30 h | 40 h |
| Acompañamiento después del arranque | 1 semana | 2 semanas | 3 semanas |
| Visitas durante la implementación | 3 | 4 | 5 |
| **Mensualidad** | | | |
| Soporte por ticket, WhatsApp o correo, de lunes a viernes | Respuesta en 48 h, hasta 4 h/mes | Respuesta en 8 h hábiles, hasta 6 h/mes | Respuesta en 4 h hábiles, hasta 8 h/mes |
| Actualizaciones | Trimestral, aplicada junto con su TI | Mensual, la aplicamos nosotros | Mensual, la aplicamos nosotros |
| Chequeo de salud y prueba de restauración del respaldo | — | Mensual | Mensual |
| Informe de uso y confiabilidad para la gerencia | — | Trimestral | Mensual |
| Visita presencial (medio día) | — | Cada 2 meses | Mensual |
| Bolsa de mejoras a medida | — | 4 h/mes, acumulable por trimestre | 8 h/mes, acumulable por trimestre |
| Servidor nuestro en su planta: disco cifrado, UPS, disco de respaldo y reposición a nuestro cargo | — | — | ✓ |

Por qué existe el Plan 3: es el ancla de precio, y además es el diseño que mejor
nos protege (§5.9). Queda pendiente confirmar si su política acepta un equipo
nuestro dentro de su planta.

### 3.3 Implementación: costo y precio por ítem

- **Costo** = horas × USD 23 (la hora más el 15 % de gastos generales), más la
  movilidad con sus gastos.
- **Precio** = horas × USD 30.
- El ítem I incluye la movilidad y absorbe el redondeo del total.
- Formato de cada celda: `horas · costo → precio`, en USD.

| Ítem | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| A. Reunión técnica con TI: red, seguridad, servidor y usuarios | 6 h · 138 → **180** | 6 h · 138 → **180** | 6 h · 138 → **180** |
| B. Instalación y aseguramiento (12 h) + licencia, endurecimiento y prueba de restauración (4 h) | 16 h · 368 → **480** | 16 h · 368 → **480** | 16 h · 368 → **480** |
| C. Carga de ~153 conjuntos (24 h) + historial (8 h), con el importador de sus libros | 32 h · 736 → **960** | 32 h · 736 → **960** | 32 h · 736 → **960** |
| D. Mapa de criticidad, con su jefe de mantenimiento | 4 h · 92 → **120** | 4 h · 92 → **120** | 4 h · 92 → **120** |
| E. Capacitación de 2 días (6 h de preparación + instructores) | 22 h · 506 → **660** | 38 h · 874 → **1 140** | 38 h · 874 → **1 140** |
| F. Cambios básicos a medida | 20 h · 460 → **600** | 30 h · 690 → **900** | 40 h · 920 → **1 200** |
| G. Acompañamiento después del arranque | 8 h · 184 → **240** | 16 h · 368 → **480** | 24 h · 552 → **720** |
| H. Servidor en comodato: cifrado, prueba de 48 h e instalación física | — | — | 8 h · 184 → **240** |
| I. Gestión del proyecto (12 / 15 / 18 h) y traslados (3 / 4 / 5 visitas) | 19,5 h · 552 → **660** | 25 h · 713 → **940** | 30,5 h · 874 → **1 160** |
| **Total** | **127,5 h · 3 036 → 3 900** | **167 h · 3 979 → 5 200** | **198,5 h · 4 738 → 6 200** |

**Desglose del costo:**

| Concepto | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Mano de obra (horas × USD 20) | 2 550 | 3 340 | 3 970 |
| Movilidad (visitas × USD 30) | 90 | 120 | 150 |
| Gastos generales (15 %) | 396 | 519 | 618 |
| Financiamiento de la OC a 90 días (3 % del precio) | 117 | 156 | 186 |
| **Costo exacto** | **3 153** | **4 135** | **4 924** |
| **Precio** | **3 900** | **5 200** | **6 200** |
| **Margen** | **747 (19 %)** | **1 065 (20 %)** | **1 276 (21 %)** |

El hardware del Plan 3 (≈ USD 2 750) no está en la implementación. Se paga con
la mensualidad (USD 210/mes, §3.4), sigue siendo de Industrie Ampel y vuelve a
nosotros si el contrato termina.

### 3.4 Mensualidad: costo y precio por ítem

- **Costo de cada ítem** = horas × USD 23 + gastos directos × 1,15 + 3 % de
  financiamiento.
- Formato de cada celda: `costo → precio`, en USD por mes.

| Ítem | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Licencia de uso (renovación 0,5 h + nuestra infraestructura USD 10) | 30,50 → **250** | 30,50 → **250** | 30,50 → **250** |
| Soporte | 4 h + actualización trimestral (2 h): 142,50 → **150** | 6 h: 142,35 → **145** | 8 h: 191,50 → **250** |
| Actualización mensual | (incluida en soporte) | 3 h: 71,25 → **75** | 3 h: 71,40 → **80** |
| Operación gestionada: salud, prueba de respaldo e informe | — | 2 h: 47,50 → **50** | 4 h: 95,30 → **110** |
| Visita presencial | — | Bimestral (2,25 h/mes + USD 15): 71,25 → **75** | Mensual (4,5 h + USD 30): 143,10 → **170** |
| Bolsa de mejoras | — | 4 h: 94,85 → **95** | 8 h: 190,60 → **220** |
| Servidor en comodato (USD 2 750 / 36 meses) | — | — | 94,15 → **210** |
| **Total** | **6,5 h · 173 → 400** | **17,75 h · 457,70 → 690** | **28 h · 816,55 → 1 290** |
| **Margen mensual** | **227 (57 %)** | **232 (34 %)** | **473 (37 %)** |

**Desglose del costo mensual:**

| Concepto | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Mano de obra (horas × USD 20) | 130 | 355 | 560 |
| Movilidad | — | 15 | 30 |
| Nuestra infraestructura (servidor de licencias, registro privado, copia de versiones) | 10 | 10 | 10 |
| Servidor en comodato | — | — | 76,39 |
| Gastos generales (15 %) | 21 | 57 | 101,46 |
| Financiamiento (3 %) | 12 | 20,70 | 38,70 |
| **Costo exacto** | **173** | **457,70** | **816,55** |

**Dónde está el margen:** en la licencia, que deja USD 219,50 al mes en cada
plan. Los servicios van casi a costo, sobre todo en el Plan 2. De ahí salen dos
reglas:

1. **Las horas fuera de la bolsa se cobran** (USD 35/h, §3.6). Regalar horas en
   el Plan 2 lo deja en pérdida.
2. **Si IPSA quiere quitar un servicio, se puede sin que caiga el margen.** Lo
   que no se negocia es la licencia.

### 3.5 Año 1, año 2 y caja

| | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Ingreso año 1 | 8 700 | 13 480 | 21 680 |
| Costo año 1 (implementación + 12 meses) | 5 229 | 9 627 | 14 723 |
| **Margen año 1** | **3 471 (40 %)** | **3 853 (29 %)** | **6 957 (32 %)** |
| Margen desde el año 2 | 2 724/año | 2 788/año | 5 681/año |
| Lo que adelantamos antes del primer cobro: implementación + inversión de producto (§3.7), más el servidor en el Plan 3 | 5 420 | 6 363 | 9 872 |

- **Por qué el Plan 2 sigue siendo el recomendado.** Deja casi el mismo margen
  mensual que el Plan 1, pero con más ingreso y con presencia cada dos meses
  (de ahí salen las ventas de otros servicios). Además da menos incidentes,
  porque las actualizaciones las aplicamos nosotros.
- **Aun cargando a IPSA toda la inversión de producto y el registro en INDECOPI**
  (USD 2 750, §3.7), el Plan 2 deja USD 1 103 el primer año.

### 3.6 Tarifas adicionales (van en la propuesta)

| Concepto | Precio | Costo |
|---|---|---|
| Hora adicional: desarrollo, soporte o capacitación remota | USD 35 | 24,05 |
| Visita adicional: medio día en planta, incluye traslado | USD 250 | 191,50 |
| Día adicional de capacitación (1 instructor) | USD 450 | 335,50 |
| Bloque de 25 conjuntos sobre los 200 | USD 30/mes + USD 150 de carga | 0,90/mes + 96,50 |
| Levantamiento en campo de datos de placa, si IPSA no los tiene | USD 20 por conjunto | 14,40 |

### 3.7 Inversiones únicas que no dependen del plan

| Inversión | USD | Detalle |
|---|---|---|
| Producto on-premise (§5.10): 92 h × USD 23 | 2 116 | Instalador, licencia Ed25519, compilación, servidor de licencias |
| PyArmor Group (pago único) | 158 | Precio de su documentación v8; verificar antes de comprar |
| 2 llaves físicas para la clave privada | ~110 | Estimado |
| Registro en INDECOPI: marca en clases 9 y 42 + software | ≈ 366 (S/ 1 263,45) | §7 |
| Revisión del contrato de licencia por un abogado | Por cotizar | |
| Servidor en comodato (solo Plan 3) | ≈ 2 750 | Se recupera con la mensualidad (USD 210/mes) |

### 3.8 Sensibilidad y precio mínimo

| Si… | Efecto en el Plan 2 |
|---|---|
| IPSA paga a 30 días (Ley 31362, §3.9) | El financiamiento baja del 3 % al 1 %: +USD 270 de margen en el año 1 |
| La hora sube USD 1 | +USD 192 de costo en la implementación y +USD 20 al mes |
| IPSA no tiene los datos de los 153 conjuntos | +~51 h de levantamiento (USD 1 173 de costo); se cobra con la tarifa de USD 20 por conjunto |

**Piso de negociación** (no bajar de aquí):

| | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Implementación (10 % de margen) | 3 500 | 4 600 | 5 500 |
| Mensualidad (~30 % de margen) | 250 | 650 | 1 170 |

Fórmula:

```
precio mínimo = costo sin financiamiento / (1 − margen objetivo − 0,03)
```

### 3.9 Condiciones de pago con orden de compra a 90 días

1. **Implementación en tres hitos.**
   - 40 % al recibir la OC, con la reunión técnica hecha.
   - 30 % con el servidor instalado y los conjuntos cargados.
   - 30 % con la capacitación y el acta de puesta en marcha.

   El «50 % al firmar» de la versión 1 ya no protegía: con 90 días de plazo,
   llegaba después del arranque.
2. **Mensualidad:** OC anual, con una factura trimestral al inicio de cada
   trimestre.
3. **La licencia sigue al pago** (§5.3).
   - El archivo de cada trimestre vence al cierre del trimestre, más 30 días
     de gracia.
   - El del trimestre siguiente se emite cuando la factura vencida está pagada.
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
   - Conviene facturar la licencia y los servicios en líneas separadas.
   - Confirmar los porcentajes con tu contador.
7. **Pago anual adelantado → bono, no descuento** (regla de Hormozi: agregar
   valor en vez de bajar el precio). Si pagan el año en una sola factura, se
   suman 20 h de mejoras a medida (valor USD 700; nos cuestan USD 460). Si
   piden descuento de todas formas, el máximo es un mes gratis.
8. **Contrato de 12 meses (24 en el Plan 3)**, con renovación automática y
   preaviso de 60 días.
9. **IGV (18 %)** aparte en todos los precios.

### 3.10 Psicología del precio

- **«La licencia no subió».** En la nube les ofrecimos USD 250/mes; la licencia
  sigue costando USD 250 en los tres planes. Lo que se suma es el servicio para
  que el sistema viva en su servidor. Es el argumento más fuerte de la reunión.
- **Ancla:** se muestra primero el Plan 3; el Plan 2 se ve razonable y el
  Plan 1 se ve barato.
- **En horas de parada:** «todo el año del Plan 2 cuesta lo mismo que 4,5 horas
  de su línea de secadores detenida».
- **Por conjunto:** «USD 3,45 por conjunto al mes, 12 centavos al día».
- **Garantías que reducen el riesgo percibido:**
  - **Garantía de arranque:** sus 200 conjuntos cargados y operando en 30 días
    desde que el servidor está listo y recibimos sus datos, o el último hito
    (30 %) no se cobra.
  - **Garantía de salida:** sus datos se exportan completos (Excel y SQL)
    cuando quieran, incluso si no renuevan.

### 3.11 Historia de justificación (para la reunión)

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
> criticidad, visitas, mejoras a medida y su programa predictivo completo por
> USD 3,45 por conjunto al mes. Todo el primer año cuesta lo mismo que 4,5 horas
> de esa línea detenida.

### 3.12 Revisión de riesgos

| Riesgo | Mitigación |
|---|---|
| **Choque contra el ancla de USD 250.** El cliente ya escuchó ese número. | «La licencia no subió»; presentar primero el Plan 3; tener el Plan 1 como entrada. Último recurso: licencia sola a USD 250/mes con soporte por hora (USD 35), siempre con la implementación cobrada. **Nunca** on-premise a USD 250 con la implementación incluida. |
| OC a 90 días | Hitos, licencia por período, Ley 31362 y factoring (§3.9). |
| Su TI no permite acceso remoto | Plan 2 con visita mensual en vez de bimestral (+USD 95/mes), o el Plan 3. |
| Su TI no acepta un servidor ajeno | El Plan 3 se convierte en «su servidor con administración total nuestra», a USD 1 080/mes (sin los USD 210 del hardware). |
| Faltan datos de los conjuntos | Tarifa de levantamiento en campo (USD 20 por conjunto). |
| Los «cambios básicos» crecen sin control | Horas fijas por plan; lo que exceda, a USD 35/h. |
| Cambio USD/PEN | Facturar en USD, o en PEN con el tipo de cambio del día de la factura. |

### 3.13 Experimentos

- En la reunión, presentar primero el Plan 3. Si lo descartan por precio, que
  sea **elección entre el 2 y el 1**, no entre «sí o no».
- Ofrecer el bono del pago anual como cierre: «si firman este mes con pago
  anual, les sumamos 20 h de mejoras».
- En el próximo cliente on-premise, probar la implementación del Plan 2 en
  USD 5 900 para medir la elasticidad.

---

## 4. T1 — Objeciones (objection-destroyer)

| # | Objeción | Creencia escondida | Nueva creencia | Prueba |
|---|---|---|---|---|
| 1 | «Si el servidor lo pongo yo, ¿por qué cuesta más?» | «Me cobran más por menos» | «La licencia no subió; lo que se suma es operar un sistema solo para mí» | La licencia sigue en USD 250 (§3.4). El VPS del escenario A cuesta ~USD 57/mes ([VPSBenchmarks](https://www.vpsbenchmarks.com/hosters/contabo/plans/cloud-vps-60)); la diferencia es trabajo (§2). |
| 2 | «No queremos que nadie externo vea datos ni entre a la red» | «Instalar software de terceros = abrir la puerta» | «El sistema funciona sin enviar un solo dato fuera; el acceso es suyo» | La licencia se renueva con un **archivo** (§5.3), sin internet. Si permiten conexión, solo viajan el id de licencia y conteos, auditables en su propio registro. El soporte remoto lo abre su TI, cuando quiere. |
| 3 | «¿Por qué renovar la licencia? ¿Qué pasa con nuestros datos si no renovamos?» | «Nos van a secuestrar los datos» | «Los datos son de IPSA siempre; lo que se licencia es el software» | Garantía de salida: exportación completa en cualquier momento. Al vencer: aviso de 30 días, gracia en solo lectura y, después, **solo exportar** (§5.6). |
| 4 | «Pagamos con OC a 90 días» | «El proveedor se tiene que adaptar a nosotros» | «Se trabaja con su OC; el precio ya lo contempla» | Factura trimestral contra OC anual; la licencia cubre el trimestre más 30 días (§3.9). |
| 5 | «Antes la implementación estaba incluida» | «Me están cobrando dos veces» | «En la nube se diluía en un servidor compartido; en su planta es trabajo solo para ustedes» | 167 horas de nuestro equipo, ítem por ítem (§3.3). |
| 6 | «¿Y si Industrie Ampel desaparece?» | «Me quedo con un sistema sin dueño» | «Su continuidad está garantizada por contrato» | **Escrow de código:** un depositario neutral guarda el código y se lo entrega solo si dejamos de operar. |

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
solo con las facturas vencidas pagadas** (§3.9). No hace falta apagar nada a
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
- **Escrow opcional del código** (§4, objeción 6): calma el miedo del cliente sin
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

Con las herramientas (PyArmor y llaves físicas) suma USD 2 384 (§3.7). No se
carga entero a IPSA: se recupera con el margen del primer año de cualquiera de
los planes (§3.5).

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

**Pendientes, para el TI de IPSA:**

1. ¿Su servidor puede salir a internet por HTTPS hacia un solo dominio (solo
   para la licencia), o es una red aislada?
2. ¿Darían acceso remoto por VPN para soporte, o todo debe ser presencial?
3. ¿Qué infraestructura tienen (VMware, Hyper-V, Windows Server, Linux)? ¿Pueden
   darnos una máquina virtual con Ubuntu Server?
4. ¿Aceptarían un servidor nuestro en comodato dentro de su planta (Plan 3)?

**Pendientes, para nosotros:**

5. ¿Industrie Ampel ya es una empresa formal (con RUC) y califica como MYPE?
   Decide si aplica la Ley 31362 (§3.9) y a nombre de quién va la marca (§7).
6. ¿IPSA tiene los datos de placa de los 153 conjuntos, o hay que levantarlos
   en campo (§3.6)?

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
