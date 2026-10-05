# Integración con agentes y chatbots

El flujo es: **estado → preguntas → respuesta tipada → reglas del programa → acción**. `/v1/systemone` devuelve decisiones; el programa que lo integra ejecuta las acciones.

## Petición mínima en PowerShell

Con Ollama y Nimble preparados, ejecuta desde la raíz del proyecto:

```powershell
$json = Get-Content -LiteralPath .\examples\request.json -Raw -Encoding UTF8
$response = Invoke-RestMethod -Uri 'http://localhost:11434/v1/systemone' -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 300
$response.answers.solicita_reembolso.noul
```

La codificación explícita UTF-8 conserva tildes y eñes en Windows PowerShell 5.1.

## Routing, clasificación y otro agente

Para elegir una ruta entre varias, usa una pregunta `choice`. Este ejemplo solo imprime el destino; conecta después cada ruta con un agente o cola que exista en tu sistema.

```powershell
$request = @{
    model = 'nimble:latest'
    state = 'Me han cobrado dos veces y necesito un reembolso.'
    questions = @{
        destino = @{
            type = 'choice'
            instructions = 'Selecciona el equipo principal para este ticket.'
            criteria = @{
                facturacion = 'Pagos, cargos, facturas y reembolsos.'
                soporte_tecnico = 'Errores y fallos de funcionamiento.'
                sin_coincidencia = 'Información insuficiente o ninguna categoría adecuada.'
            }
        }
    }
    keep_alive = '30m'
}
$json = $request | ConvertTo-Json -Depth 20
$response = Invoke-RestMethod -Uri 'http://localhost:11434/v1/systemone' -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 300
switch ($response.answers.destino.choice) {
    'facturacion' { 'Destino: agente o cola de facturación' }
    'soporte_tecnico' { 'Destino: agente o cola de soporte técnico' }
    default { 'Destino: revisión humana' }
}
```

La respuesta incluye `choice`, `probabilities` y `confidence`. `confidence` mide la concentración de las probabilidades; no es una garantía de acierto. Si varias categorías pueden ser relevantes a la vez, usa preguntas `noul` separadas como la demo y define en tu programa la prioridad de las rutas.

Para enviar el caso a otro agente, entrega el ticket, la ruta elegida y las decisiones necesarias mediante la interfaz de ese agente. `/v1/systemone` no lo envía automáticamente. Valida que el destino pertenezca a una lista permitida; no ejecutes una URL o nombre de herramienta procedente del ticket.

## Tool selection

Define opciones cerradas como `consultar_cuenta`, `consultar_pedido` y `ninguna`. Describe en cada criterio cuándo corresponde usarla. El programa debe comprobar identidad, permisos y parámetros antes de llamar a una herramienta. Solicitar un reembolso no equivale a autorizarlo.

## Memoria

Pregunta si el estado contiene una preferencia duradera útil, por ejemplo el idioma preferido. Define qué información se permite almacenar, obtén la autorización necesaria y aplica filtros de datos personales. Un «Sí» no guarda nada: tu aplicación decide el almacenamiento, duración y eliminación. La detección por modelo puede omitir datos sensibles; usa validaciones adicionales para los datos que no deben persistir.

## Escalado

Puedes enviar a revisión humana cuando el cliente lo pida, cuando falte información o cuando haya resultados contradictorios. Para `noul`, una franja cercana a `0.5` puede tratarse como ambigua, pero el ancho de esa franja debe ajustarse con casos reales etiquetados.

## Moderación

Escribe reglas concretas y criterios positivos y negativos. Incluye ejemplos de reclamaciones legítimas para no confundir urgencia con abuso. Revisa los falsos positivos y negativos antes de aplicar bloqueos. Las decisiones del modelo son una señal dentro de la política, no la única barrera.

## Comprobar antes de automatizar

1. Prepara tickets ficticios positivos, negativos y ambiguos para cada regla.
2. Anota las etiquetas correctas antes de consultar el modelo.
3. Guarda versión de Ollama, ID del modelo, preguntas y resultados.
4. Ajusta umbrales con un grupo de casos y comprueba con otro grupo separado.
5. Define prioridades para respuestas que puedan coincidir.
6. Mantén una ruta de revisión para errores, destinos desconocidos y baja certeza.

Las preguntas de una petición se puntúan independientemente. Para que una segunda etapa dependa de una decisión anterior, realiza otra petición incluyendo esa información en su nuevo `state`.
