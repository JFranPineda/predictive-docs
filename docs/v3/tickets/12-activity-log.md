# 12 · Registro de actividad (Q20)

> **Estado (2026-09-27): implementado como módulo `activity`** (back `6cc121b`,
> front `18c198b`). Se instala y desinstala desde `/settings/modules`;
> desinstalado, no se registra nada y su historial se conserva.

## Origen

> Necesito un sistema de LOGS + UI tipo tabla pero bien bonito que me permita
> visualizar: 1. Usuario 2. Evento 3. descripción breve 4. fecha y hora. Ese
> log debe de poder registrar CADA EVENTO dentro del sistema, cada clic a un
> botón, cada subida de imagen, dada de alta, modificación o baja de datos,
> imágenes e información en el sistema debe de ser registrado.

## Qué registra

| Evento | Cómo se captura | Ejemplo de descripción |
|---|---|---|
| Inicio de sesión / acceso fallido | El servidor, en `auth/login/` | «Entró al sistema (admin@simiai.pe)» |
| Alta, modificación, baja | El servidor, toda escritura bajo `/api/v1/` | «Modificó orden de servicio #12 · campos: notes, standard» |
| Subida de archivo | El servidor, escritura con archivos | «Subió «IR_0042.jpg» (termograma de visita de servicio #5)» |
| Acción | El servidor, rutas que terminan en un verbo | «Cerró jornada #3», «Instaló módulo «workday»» |
| Rechazado | El servidor, escrituras con 4xx | «No se pudo reabrir jornada #3 (sin permiso)» |
| Clic | El navegador, en todo botón, enlace, pestaña o casilla | «Clic en «Guardar ATS» (/workday/jobs/3)» |
| Navegación | El navegador, cada pantalla abierta | «Abrió /settings/activity · Registro de actividad» |

Nunca se registra lo que se escribe en un campo ni una contraseña: de una
modificación solo se nombran los campos, y los campos secretos se omiten.

## Diseño

- **Núcleo:** nuevo punto de extensión `Manifest.request_observer` y
  `RequestObserverMiddleware`: tras cada respuesta, avisa a los observadores de
  los módulos instalados. Un observador que falla se registra y se ignora; nunca
  cambia la respuesta.
- **Navegador:** nuevo punto de extensión `ModuleDefinition.shell`: componentes
  que un módulo instalado monta una vez en el armazón. El rastreador junta los
  clics y los manda en lotes cada 4 s (`POST activity/events/`); solo acepta
  clics, navegación y cierre de sesión.
- **Pantalla:** Configuración → Registro de actividad (`activity.view`): tabla
  por día con usuario, evento (con color), descripción y fecha y hora; búsqueda,
  usuario, rango de fechas y tipos de evento con su cuenta; «Cargar más» y
  exportación CSV (`activity.export`).
- La tabla es de solo inserción: ningún endpoint edita ni borra filas.

## Pendiente

- Retención: hoy no caduca nada. Con uso real hará falta purgar o archivar.
