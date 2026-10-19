# Fase 3 — Licencias cortas y renovación (archivo y servidor online)

**Capa del §5:** Capa 2 (§5.3). **Estimado:** ~18 h (8 h archivo + 10 h
servidor). **Depende de:** Fases 1 y 2.

## Objetivo

Que la llave **venza sola** al cierre del trimestre pagado, más 30 días de
gracia, y que se renueve de dos maneras: con un archivo que sube el
administrador (sirve en red aislada) o sola contra un servidor nuestro.
Sin pago no hay archivo nuevo: no hace falta apagar nada a distancia.

## Por qué

Es lo que convierte el contrato en algo que se cumple sin pelear. Con la orden
de compra de IPSA a 90 días, la factura del trimestre vence justo al cierre, así
que la gracia de 30 días cubre el atraso normal
([propuesta §3.11](../business/ipsa-onpremise-proposal.md)).

## Qué se toca (predictive-back)

### Renovación por archivo (sirve sin internet)

- **Código de solicitud**: en `/settings/license`, un botón genera un texto (y
  su QR) con el id de licencia, la huella de instalación, la versión y los
  conteos de equipos y usuarios. **Ningún dato de mantenimiento.**
- El administrador lo envía por correo; nosotros devolvemos el `.lic` firmado.
- **Carga del archivo**: `POST /api/v1/license/renew/` recibe el `.lic`, lo
  verifica con la clave pública y lo guarda como el `LicenseRecord` vigente.
  Si la firma o la huella no cuadran, lo rechaza y dice por qué.
- Comando `manage.py license import <archivo>` para hacerlo sin navegador.

### Servidor de renovación online (D1 lo incluye)

- Servicio pequeño y aparte (no va dentro del backend del cliente) que expone
  `POST /renew`: recibe el código de solicitud, mira si el período está pagado y
  devuelve el `.lic` o un «pendiente de pago».
- En el servidor del cliente, una tarea de Celery diaria consulta ese servicio
  si `LICENSE_RENEW_URL` está configurado. Si no lo está, el sistema funciona
  igual y solo queda el camino por archivo.
- Qué sale de la red de IPSA: id de licencia, huella, versión y conteos.
  Queda un **registro local auditable** de cada consulta, para que su TI lo
  revise.

### Gracia

- `grace_days` pasa a **30** para on-premise (hoy el valor por defecto es 15).
  Se fija al emitir, no en el código.

## Qué se toca (predictive-front)

- `/settings/license`: bloque «Renovar licencia» con las dos vías (copiar el
  código de solicitud / subir el `.lic`), el estado y la fecha de vencimiento.
- Traducciones es/en del módulo `licensing`.

## Criterios de aceptación

- **AC-3.1** El código de solicitud contiene id, huella, versión y conteos, y
  **ningún** dato de mantenimiento (se verifica leyendo el contenido).
- **AC-3.2** Subir un `.lic` válido extiende la vigencia sin reiniciar nada.
- **AC-3.3** Un `.lic` de otra instalación se rechaza con un mensaje claro.
- **AC-3.4** Un `.lic` con la firma alterada se rechaza.
- **AC-3.5** Sin `LICENSE_RENEW_URL`, el sistema funciona y no intenta salir a
  internet (se comprueba sin red).
- **AC-3.6** Con el servidor configurado, la tarea diaria renueva sola cuando el
  período está pagado y no hace nada cuando no lo está.
- **AC-3.7** Cada consulta al servidor queda en un registro local consultable.
- **AC-3.8** Vencida la licencia, hay 30 días de gracia en solo lectura antes de
  lo que define la Fase 4.
- **AC-3.9** Portones verdes.

## Riesgos

- El servidor de renovación es infraestructura nuestra que hay que mantener y
  respaldar; si se cae, nadie puede renovar en línea. Mitigación: el camino por
  archivo siempre funciona y es el oficial para IPSA.
- Un reloj adelantado podría pedir renovación antes de tiempo. Lo cubre la
  Fase 2.

## Decisiones pendientes

- **P3-a.** ¿El servidor de renovación mira el pago **a mano** (nosotros
  marcamos «trimestre pagado» en un panel) o se conecta a algo de facturación?
  *Recomendado: a mano. Con un cliente no se justifica integrar nada, y el panel
  es media hora de trabajo.*
- **P3-b.** ¿Se renueva por trimestre (como dice la propuesta) o por mes?
  Trimestre = menos trámite para IPSA y para nosotros; mes = menos tiempo de uso
  sin pagar si dejan de hacerlo. *Recomendado: trimestre, que es lo ofrecido.*
- **P3-c.** Para el Plan Cloud el sistema corre en nuestros servidores y esto
  no hace falta. ¿Se deja la renovación también activa ahí por uniformidad, o
  solo para `deployment = on_premise`? *Recomendado: solo on-premise; en la nube
  sería ceremonia.*
