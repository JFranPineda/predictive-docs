# IPSA on-premise: planes, precios y protección de la licencia

Documento **interno** de Industrie Ampel. Contiene costos y márgenes: no se
entrega al cliente. Fecha: 14 de octubre de 2026.

- **T1.** Tres planes para el CONTEXTO B (los datos de IPSA viven en su propio
  servidor), con costos detallados y precio recomendado. Construidos con los
  marcos de Hormozi: *pricing-strategy* (precio anclado al valor, niveles
  DIY/DWY/DFY) y *objection-destroyer* (objeciones → cambio de creencia → prueba).
- **T2.** Cómo proteger el sistema cuando corre en un servidor que no
  controlamos.

---

## 0. Supuestos (cámbialos y los números se recalculan)

| Supuesto | Valor usado | Por qué importa |
|---|---|---|
| Costo interno de una hora de trabajo (sueldo + cargas) | **USD 20/h** | Todo el costo es horas. Ver la sensibilidad en §3.5. |
| Gastos generales (administración, contabilidad, ventas) | +15 % sobre el costo mensual | |
| Traslado Lima ↔ Chaclacayo | 2,5 h ida y vuelta + USD 30 de movilidad por visita | |
| Precios | USD, **sin IGV** (18 %) | |
| Lo que ya está cargado de IPSA en el sistema | 47 conjuntos · 98 equipos · 795 puntos · 10 536 lecturas | Faltan ~153 conjuntos de los ~200. |
| Servidor del cliente (planes 1 y 2) | Lo pone IPSA: 4 vCPU · 8 GB RAM · 400 GB SSD · Ubuntu Server 24.04 en VM | Dimensionado de [doc 07 §2](../07-deployment.md). |

---

## 1. T1 — Análisis de valor (por qué el precio no sale del costo)

**Resultado que compra IPSA:** que ninguna máquina de la planta se detenga por
sorpresa, con todo su programa predictivo (vibraciones, ultrasonido,
termografía, END, alineamiento, correctivos y jornada con ATS) en un solo
sistema, **sin que sus datos salgan de su planta**.

**Cuánto vale.**

- **Una parada no planificada.** TAPPI, citando a Frost & Sullivan, estima entre
  **USD 80 000 y 150 000 por hora** en papeleras grandes
  ([TAPPI Paper360](https://paper360.tappi.org/?p=5261)). Una guía de un proveedor
  de CMMS da USD 12 000–35 000 por hora de máquina papelera
  ([Oxmaint](https://oxmaint.com/article/paper-mill-cmms-maintenance-management-guide)).
  Para IPSA usamos una cifra **muy conservadora de USD 3 000/h**, y conviene
  pedirle la suya. Evitar **una sola** parada de 8 horas al año vale **USD 24 000**,
  más que el plan recomendado completo del primer año.
- **El software comparable.** Un CMMS genérico en la nube como MaintainX cobra
  USD 65 por usuario al mes en su plan Premium, con pago anual
  ([Software Advice](https://www.softwareadvice.com/cmms/maintainx-profile/),
  [Toolradar](https://toolradar.com/tools/maintainx/pricing)). Para 15 usuarios
  son **USD 11 700 al año**, solo en la nube y sin módulos predictivos. Las
  versiones on-premise de los grandes se cotizan aparte y cuestan más.
- **Horas de la gente.** Pasar las rondas a Excel y Word, armar los informes MPd
  y END a mano y perseguir recomendaciones son decenas de horas de analista al
  mes que el sistema elimina.

> Si PREDICTIVE evita una parada al año, IPSA recupera varias veces lo que paga.
> El precio no compite con el costo del software: compite con el costo de no
> enterarse a tiempo.

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
cobra la implementación por adelantado.

---

## 3. T1 — Los tres planes

Se presentan **de mayor a menor** (ancla). El recomendado es el 2.

### 3.1 Resumen

| | **Plan 3 — Planta Protegida** | **Plan 2 — Gestionado** ★ | **Plan 1 — Esencial** |
|---|---|---|---|
| Modelo | DFY: servidor de Industrie Ampel instalado en su planta, llave en mano | DWY: su servidor, operado por nosotros | DIY+: su servidor, lo opera su TI |
| Dónde viven los datos | En su planta, en un equipo nuestro en comodato | En su servidor | En su servidor |
| Implementación (pago único) | **USD 6 500** | **USD 4 500** | **USD 3 500** |
| Mensualidad (licencia + soporte) | **USD 1 290** | **USD 690** | **USD 390** |
| Por conjunto (200) | USD 6,45/mes | USD 3,45/mes (≈ USD 0,12 al día) | USD 1,95/mes |
| Total año 1 | **USD 21 980** | **USD 12 780** | **USD 8 180** |
| Desde el año 2 | USD 15 480/año | USD 8 280/año | USD 4 680/año |
| Plazo mínimo | 24 meses | 12 meses | 12 meses |

Condiciones de pago en todos (§3.6): implementación 50 % al firmar y 50 % en la
puesta en marcha; mensualidad por **trimestre adelantado**.

### 3.2 Qué incluye cada plan

**Plan 1 — Ampel Esencial** (para un TI que quiere administrar todo)

- Todos los módulos instalados en su servidor, licencia para ~200 conjuntos.
- Carga de los ~153 conjuntos que faltan e importación de su historial.
- Capacitación de 2 días (1 instructor) y hasta 20 h de cambios básicos.
- Una semana de acompañamiento después del arranque.
- Soporte por ticket o WhatsApp en horario laboral, respuesta en 48 h.
- Actualización **trimestral**, aplicada junto con su TI.

**Plan 2 — Ampel Gestionado** ★ (recomendado: IPSA no carga con la operación)

- Todo lo del Plan 1, más:
  - Capacitación con 2 instructores y hasta 30 h de cambios básicos.
  - Dos semanas de acompañamiento.
  - Soporte prioritario, respuesta en 8 h hábiles.
  - Actualización **mensual**.
  - Chequeo mensual de salud y **prueba de restauración del respaldo**.
  - Visita presencial cada 2 meses.
  - **Bolsa de 4 h al mes de mejoras a medida**, acumulable por trimestre.
  - Informe trimestral de uso y confiabilidad para la gerencia.

**Plan 3 — Ampel Planta Protegida** (llave en mano, máxima protección para ambos)

- Todo lo del Plan 2, más:
  - **Servidor de Industrie Ampel en comodato dentro de su planta**, con disco
    cifrado y fuente ininterrumpida. Los datos nunca salen de la planta y su TI
    no tiene que administrar nada.
  - Soporte con atención en 4 h hábiles y visita mensual.
  - Bolsa de 8 h al mes de mejoras.
  - Tres semanas de acompañamiento y hasta 40 h de cambios.

Por qué existe el Plan 3: es el ancla de precio, y además es el diseño que mejor
nos protege (§5.9). Queda pendiente confirmar si su política acepta un equipo
nuestro dentro de su planta.

### 3.3 Costos detallados: implementación (pago único)

| Actividad | Plan 1 (h) | Plan 2 (h) | Plan 3 (h) |
|---|---|---|---|
| Reunión técnica con TI de IPSA (red, seguridad, cuestionario) | 6 | 6 | 6 |
| Instalación en servidor, HTTPS interno, respaldos | 12 | 12 | 12 |
| Licencia, endurecimiento y prueba de restauración | 4 | 4 | 4 |
| Carga de ~153 conjuntos (equipos, puntos, plantillas) | 24 | 24 | 24 |
| Importación de historial (Excel/RGP) | 8 | 8 | 8 |
| Capacitación de 2 días (preparación + instructores) | 22 | 38 | 38 |
| Cambios básicos a medida | 20 | 30 | 40 |
| Acompañamiento posterior al arranque | 8 | 16 | 24 |
| Preparación del servidor en comodato (cifrado, prueba de 48 h) | — | — | 8 |
| Traslados (3 / 4 / 5 visitas × 2,5 h) | 7,5 | 10 | 12,5 |
| Gestión del proyecto (10 %) | 11,2 | 14,8 | 17,7 |
| **Horas** | **122,7** | **162,8** | **194,2** |
| Mano de obra (× USD 20) | 2 454 | 3 256 | 3 884 |
| Movilidad | 90 | 120 | 150 |
| **Costo directo** | **2 544** | **3 376** | **4 034** |
| **Precio** | **3 500** | **4 500** | **6 500** |
| Margen sobre la implementación | 27 % | 25 % | 38 % |

El hardware del Plan 3 (servidor + UPS, ~USD 2 400) se amortiza en la
mensualidad (§3.4): sigue siendo de Industrie Ampel y vuelve a nosotros si el
contrato termina.

### 3.4 Costos detallados: operación mensual

| Concepto | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Soporte (h) | 4 | 6 | 8 |
| Actualizaciones (h) | 2 (trimestral) | 3 (mensual) | 3 |
| Chequeo de salud y prueba de respaldo (h) | — | 1,5 | 2 |
| Renovación de licencia y control (h) | 0,5 | incl. | incl. |
| Visitas (h, incluido traslado) | — | 2,25 (bimestral) | 4,5 (mensual) |
| Bolsa de mejoras (h) | — | 4 | 8 |
| Informe a gerencia y guardia del SLA (h) | — | 0,5 | 2 |
| **Horas al mes** | **6,5** | **17,25** | **27,5** |
| Mano de obra (× USD 20) | 130 | 345 | 550 |
| Movilidad | — | 15 | 30 |
| Nuestra infraestructura (servidor de licencias, registro privado, copia de versiones) | 10 | 10 | 10 |
| Hardware en comodato (USD 2 400 / 36 meses) | — | — | 67 |
| Gastos generales (+15 %) | 21 | 56 | 99 |
| **Costo mensual** | **161** | **426** | **756** |
| **Precio mensual** | **390** | **690** | **1 290** |
| **Margen mensual** | **229 (59 %)** | **264 (38 %)** | **534 (41 %)** |

**Año 1 por plan:**

| | Plan 1 | Plan 2 | Plan 3 |
|---|---|---|---|
| Ingreso | 8 180 | 12 780 | 21 980 |
| Costo (implementación + 12 meses) | 4 476 | 8 488 | 13 106 |
| **Margen** | **3 704** | **4 292** | **8 874** |

### 3.5 Sensibilidad: si la hora no cuesta USD 20

| Costo de la hora | Plan 2: costo mensual | Margen a USD 690 | Implementación: costo | Margen a USD 4 500 |
|---|---|---|---|---|
| USD 15 | 326 | 53 % | 2 562 | 43 % |
| **USD 20** | **426** | **38 %** | **3 376** | **25 %** |
| USD 30 | 624 | 10 % ⚠ | 5 004 | pérdida ⚠ |

Con un costo de USD 30/h, el Plan 2 debe subir a **≈ USD 890/mes** y su
implementación a **≈ USD 6 500**.

Fórmula del precio mínimo:

```
precio mínimo mensual = costo mensual / (1 − margen objetivo)
```

Con un margen objetivo del 30 %, el Plan 2 a USD 20/h no debería bajar de
426 / 0,7 ≈ **USD 610/mes**.

### 3.6 Condiciones de pago: lo que de verdad protege contra el impago

1. **Implementación 50 % al firmar y 50 % en la puesta en marcha.** El día del
   arranque ya cobramos lo que costó implementar; si después dejan de pagar, no
   perdemos lo invertido.
2. **Mensualidad por trimestre adelantado.** Si IPSA solo emite órdenes de
   compra mensuales, se factura mensualmente, pero la licencia se emite por el
   período ya pagado (§5.3).
3. **Pago anual adelantado → bono, no descuento** (regla de Hormozi: agregar
   valor en vez de bajar el precio). Por ejemplo, **20 h de desarrollo a medida y
   una capacitación de refuerzo** (valor > USD 1 000; nos cuestan ~USD 450). Si
   piden descuento de todas formas, el máximo es un mes gratis.
4. **Contrato de 12 meses (24 en el Plan 3)** con renovación automática y
   preaviso de 60 días.

### 3.7 Psicología del precio

- **Ancla:** se muestra primero el Plan 3; el Plan 2 se ve razonable y el Plan 1
  se ve barato.
- **Por conjunto:** «USD 3,45 por conjunto al mes, 12 centavos al día» se oye
  distinto que «USD 690».
- **Contraste claro entre planes:** cada salto agrega algo visible (visitas,
  bolsa de horas, SLA, servidor llave en mano).
- **Garantías que reducen el riesgo percibido:**
  - **Garantía de arranque:** sus 200 conjuntos cargados y operando en 30 días
    desde que el servidor está listo, o el 50 % final de la implementación no se
    cobra.
  - **Garantía de salida:** sus datos se exportan completos (Excel y SQL)
    cuando quieran, incluso si no renuevan.

### 3.8 Historia de justificación (para la reunión)

> Ustedes nos pidieron que sus datos no salgan de su planta. Eso cambia cómo
> trabajamos: en lugar de cuidar un sistema en la nube para todos, montamos y
> mantenemos uno solo para IPSA, dentro de su red. Por eso la implementación se
> paga aparte y la mensualidad sube.
>
> Pongámoslo en contexto. Una hora de máquina papelera parada les cuesta miles
> de dólares. Si el sistema evita una sola parada de una jornada al año, ya pagó
> varias veces el plan completo. Un CMMS genérico en la nube, sin vibraciones ni
> END, cuesta más de USD 11 000 al año para 15 usuarios. Con el Plan Gestionado
> tienen todo su programa predictivo, sus 200 conjuntos, visitas y mejoras a
> medida por USD 3,45 por conjunto al mes, y sus datos nunca salen de su
> planta.

### 3.9 Revisión de riesgos

| Riesgo | Mitigación |
|---|---|
| **Choque contra el ancla de USD 250.** El cliente ya escuchó ese número. | Explicar el cambio de alcance (§2), presentar el Plan 3 primero y tener el Plan 1 como entrada. Último recurso: Plan 1 con implementación en dos cuotas. **Nunca** on-premise a USD 250 con la implementación incluida. |
| Compras de IPSA paga a 30, 60 o 90 días | Negociar orden de compra anual; licencia emitida por período pagado más 15 días de gracia. |
| Su TI no permite acceso remoto | Precio de visitas más alto (Plan 2 con visita mensual) o el Plan 3. |
| Su TI no acepta un servidor ajeno | El Plan 3 se convierte en «su servidor con administración total nuestra», con la misma mensualidad sin la parte del hardware. |
| Cambio USD/PEN | Facturar en USD, o en PEN con tipo de cambio del día de la factura. |

### 3.10 Experimentos

- En la reunión, presentar primero el Plan 3. Si lo descartan por precio, que
  sea **elección entre el 2 y el 1**, no entre «sí o no».
- Ofrecer el bono del pago anual como cierre: «si firman este mes con pago
  anual, les sumamos 20 h de desarrollo».
- En el próximo cliente on-premise, probar la implementación en USD 4 900 para
  medir la elasticidad.

---

## 4. T1 — Objeciones (objection-destroyer)

| # | Objeción | Creencia escondida | Nueva creencia | Prueba |
|---|---|---|---|---|
| 1 | «Si el servidor lo pongo yo, ¿por qué cuesta más?» | «Me cobran más por menos» | «El servidor es lo barato; lo caro es operar un sistema solo para mí» | §2: actualizaciones, soporte y visitas por cliente. El VPS del escenario A cuesta ~USD 57/mes ([VPSBenchmarks](https://www.vpsbenchmarks.com/hosters/contabo/plans/cloud-vps-60)); la diferencia es trabajo. |
| 2 | «No queremos que nadie externo vea datos ni entre a la red» | «Instalar software de terceros = abrir la puerta» | «El sistema funciona sin enviar un solo dato fuera; el acceso es suyo» | La licencia se renueva con un **archivo** (§5.3), sin internet. Si permiten conexión, solo viajan el id de licencia y conteos, auditables en su propio registro. El soporte remoto lo abre su TI, cuando quiere. |
| 3 | «¿Por qué renovar la licencia? ¿Qué pasa con nuestros datos si no renovamos?» | «Nos van a secuestrar los datos» | «Los datos son de IPSA siempre; lo que se licencia es el software» | Garantía de salida: exportación completa en cualquier momento. Al vencer: aviso de 30 días, 15 días en solo lectura y, después, **solo exportar** (§5.6). |
| 4 | «Queremos pagar mensual» | «No confío en pagar por adelantado» | «El pago adelantado compra estabilidad y un bono» | Bono de pago anual (§3.6). Si Compras exige mensual: se factura mensual y la licencia cubre el período pagado. |
| 5 | «¿Y si Industrie Ampel desaparece?» | «Me quedo con un sistema sin dueño» | «Su continuidad está garantizada por contrato» | **Escrow de código:** un depositario neutral guarda el código y se lo entrega solo si dejamos de operar. |

**Respuestas cortas, listas para WhatsApp:**

1. «El servidor es lo de menos. Lo que cuesta es mantener un sistema solo para
   ustedes dentro de su red: actualizaciones, soporte y visitas. Por eso la
   implementación va aparte.»
2. «El sistema no envía datos a ningún lado. La licencia se renueva con un
   archivo que sube su administrador; si su TI prefiere, ni siquiera necesita
   internet.»
3. «Sus datos son suyos siempre: se exportan completos cuando quieran, incluso si
   un día no renuevan. Lo que licenciamos es el software, no su información.»
4. «Podemos facturar mensual. Si pagan el año completo les sumamos 20 h de
   desarrollo a medida.»

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
  "grace_days": 15,
  "max_version": "3"
}
```

  Va acompañado de una firma Ed25519 de 64 bytes.
- En el código hay que cambiar `issue()` y `verify()` de
  `licensing/domain/license.py` y agregar la librería `cryptography`, que hoy no
  está instalada. Lo demás del módulo se reutiliza.

### 5.3 Capa 2 — Licencias cortas que se renuevan solas solo si pagan

La llave vence con el período pagado (trimestre o mes) más 15 días de gracia.
**Sin pago no hay archivo nuevo.** No hace falta apagar nada a distancia: la
llave caduca sola.

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

Se mantiene el ciclo actual (aviso 30 días → 15 días de solo lectura → bloqueo),
con un cambio para on-premise: **pasada la gracia, se bloquea el trabajo
(registrar datos, generar informes) pero siempre se pueden exportar sus datos.**

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
- **Suspensión por impago** con preaviso (por ejemplo, 15 días), coherente con
  la gracia técnica.
- **Registro del software en INDECOPI** (Dirección de Derecho de Autor): prueba
  de autoría ante cualquier disputa.
- **Escrow opcional del código** (§4, objeción 5): calma el miedo del cliente sin
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
| **Total** | **92 h ≈ USD 1 840** |

No se carga entero a IPSA: se recupera con el margen del primer año de
cualquiera de los planes (§3.4).

### 5.11 Orden recomendado

1. **Antes de firmar:** contrato de licencia y registro en INDECOPI; preguntas
   a TI de IPSA (§6).
2. **Antes de instalar:** capas 1, 2, 3, 4 y 5 (licencia asimétrica, renovación,
   huella, reloj y modo «solo exportar»).
3. **Antes de entregar el primer instalador:** capa 6 (compilación, firma y
   marca de agua).
4. **Si eligen el Plan 3:** preparar el servidor en comodato (capa 8).

---

## 6. Preguntas abiertas

**Para nosotros:**

1. ¿Cuál es el costo real de la hora del equipo? Cambia todos los márgenes
   (§3.5).
2. ¿El nombre es Industrie **Ampel** o **Amfel**? ¿Está registrada la marca o el
   software en INDECOPI?

**Para el TI de IPSA:**

3. ¿Su servidor puede salir a internet por HTTPS hacia un solo dominio (solo
   para la licencia), o es una red aislada?
4. ¿Darían acceso remoto por VPN para soporte, o todo debe ser presencial?
5. ¿Qué infraestructura tienen (VMware, Hyper-V, Windows Server, Linux)? ¿Pueden
   darnos una máquina virtual con Ubuntu Server?
6. ¿Aceptarían un servidor nuestro en comodato dentro de su planta (Plan 3)?

**Para Compras y gerencia de IPSA:**

7. ¿Cómo pagan: orden de compra anual o mensual, y a cuántos días?
8. ¿Cuántos usuarios y cuántos equipos (no conjuntos) tendrán?
9. ¿Cuánto les cuesta una hora de máquina papelera parada? Es el número que
   sostiene todo el precio.

---

## Fuentes

- Contabo Cloud VPS 60 (~€49 ≈ USD 57/mes): [VPSBenchmarks](https://www.vpsbenchmarks.com/hosters/contabo/plans/cloud-vps-60)
- MaintainX, precios por usuario: [Software Advice](https://www.softwareadvice.com/cmms/maintainx-profile/), [Toolradar](https://toolradar.com/tools/maintainx/pricing)
- Costo de parada en papeleras: [TAPPI Paper360](https://paper360.tappi.org/?p=5261), [Oxmaint](https://oxmaint.com/article/paper-mill-cmms-maintenance-management-guide)

Los precios de terceros cambian: verificarlos antes de citarlos ante el cliente.
