# Ollama Nimble Decision Layer

**Tutorial para ejecutar una capa de decisiones local en Windows con Ollama y Nimble 9B.**

Escribe un ticket en español, pulsa **Analizar ticket** y consulta diez decisiones: problemas técnicos, facturación, reembolso, acceso, urgencia, datos personales, atención humana, consulta de cuenta, lenguaje abusivo y baja.

La interfaz funciona en el navegador. Ollama procesa el ticket en tu equipo mediante **`POST http://localhost:11434/v1/systemone`**. No necesitas programar, instalar Python ni instalar Node.js.

## Índice

- [Qué vas a poner en marcha](#qué-vas-a-poner-en-marcha)
- [1. Requisitos y descarga del proyecto](#1-requisitos-y-descarga-del-proyecto)
- [2. Instalar o actualizar Ollama](#2-instalar-o-actualizar-ollama)
- [3. Arrancar Ollama](#3-arrancar-ollama)
- [4. Descargar Nimble 9B](#4-descargar-nimble-9b)
- [5. Abrir la demo](#5-abrir-la-demo)
- [6. Comprobar el resultado](#6-comprobar-el-resultado)
- [7. Apagar y volver a arrancar](#7-apagar-y-volver-a-arrancar)
- [Qué hace cada archivo](#qué-hace-cada-archivo)
- [Cambiar el ticket y las decisiones](#cambiar-el-ticket-y-las-decisiones)
- [Adaptar a agentes y chatbots](#adaptar-a-agentes-y-chatbots)
- [Solución de errores](#solución-de-errores)
- [Referencias](#referencias)

## Qué vas a poner en marcha

```text
Ticket en el navegador
        ↓
Diez preguntas de tipo noul
        ↓ POST /v1/systemone
Ollama + Nimble 9B en tu equipo
        ↓
Diez valores de 0 a 1 → Sí / No según el umbral
```

`noul` es el nombre del tipo de pregunta de sí/no en esta API. Su respuesta es un número: por ejemplo, `0.97` indica una preferencia alta por «true». La demo aplica por defecto el umbral `0.5`: valores iguales o superiores se muestran como **Sí**. El porcentaje no garantiza que el modelo acierte en ese porcentaje de casos.

El modelo clasifica. No redacta respuestas al cliente ni ejecuta reembolsos, herramientas o acciones. Las preguntas se evalúan de forma independiente: una decisión no recibe la respuesta de la anterior.

## 1. Requisitos y descarga del proyecto

| Necesitas | Detalle |
| --- | --- |
| Sistema | Windows 10 o Windows 11 |
| Terminal | Windows PowerShell 5.1 o PowerShell 7 |
| Ollama | **0.35.1 o posterior** para seguir este tutorial |
| Navegador | Edge, Chrome o Firefox actualizado |
| Internet | Para instalar Ollama y descargar el modelo; después la inferencia es local |
| Almacenamiento | Reserva al menos 15 GB libres como margen para Ollama y el modelo |
| Memoria | Nimble 9B necesita memoria para los pesos y la ejecución. 16 GB de RAM o más son un punto de partida; el margen real depende del texto y de otras aplicaciones |
| GPU | Opcional. Una GPU compatible acelera la inferencia. La memoria disponible determina cuánto puede ejecutarse en GPU |

No se exige una tarjeta concreta. Puedes usar la selección predeterminada de Ollama, elegir una NVIDIA o probar en CPU. En CPU y con parte del modelo en RAM los tiempos pueden aumentar considerablemente. No hace falta instalar un CUDA Toolkit para usar la distribución normal de Ollama.

### Descargar sin usar Git

1. En la página del repositorio, pulsa **Code → Download ZIP**.
2. Extrae **todo** el ZIP; no ejecutes los archivos dentro del archivo comprimido.
3. Entra en la carpeta que contiene `README.md`, `app` y `scripts`.
4. En la barra de dirección del Explorador, escribe `powershell` y pulsa Intro. La terminal se abrirá en esa carpeta.
5. Comprueba que estás en el lugar correcto:

```powershell
Get-ChildItem
```

Debes ver `README.md`, `app`, `scripts`, `examples` y `docs`. Los comandos de esta guía se ejecutan desde esa carpeta.

> Si el ZIP se llama `ollama-nimble-decision-layer-main`, esa es la carpeta de trabajo. El nombre exacto de tu carpeta no afecta a los scripts.

## 2. Instalar o actualizar Ollama

1. Abre [la descarga oficial para Windows](https://ollama.com/download/windows).
2. Descarga y ejecuta el instalador. Sigue sus pasos.
3. Cierra y vuelve a abrir PowerShell para que reconozca `ollama`.
4. Comprueba la versión:

```powershell
ollama --version
```

El tutorial usa **0.35.1 o posterior**. `/v1/systemone` existe desde 0.35.0, pero los scripts de este proyecto requieren como mínimo 0.35.1.

### Si tienes una versión anterior

Si aparece `0.34.x`, una versión inferior a `0.35` o `0.35.0`:

1. Sal de Ollama desde su icono junto al reloj, si está abierto.
2. Instala la versión actual desde la misma página oficial.
3. Abre una nueva terminal y repite `ollama --version`.
4. Reinicia el servidor siguiendo el paso 3. Actualizar el programa no reemplaza un servidor antiguo que sigue abierto.

`Warning: could not connect to a running Ollama instance` significa que el servidor no está arrancado. Si también aparece `client version is 0.35.1` o una versión superior, puedes continuar.

## 3. Arrancar Ollama

Se necesitan **dos ventanas de PowerShell**: una mantiene Ollama abierto y otra sirve la web. Para descargar el modelo puedes abrir una tercera temporalmente.

Antes de usar el launcher, sal de la aplicación Ollama desde su icono junto al reloj. Así el servidor nuevo podrá usar el puerto `11434` y leer sus propias opciones.

### Opción A: configuración predeterminada para cualquier equipo

En la primera ventana, desde la carpeta del proyecto:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Ollama.ps1
```

Deja la ventana abierta. Ollama elegirá sus dispositivos según la compatibilidad y las variables que ya existan en esa terminal.

`-ExecutionPolicy Bypass` solo se aplica al proceso iniciado por este comando; no cambia permanentemente la política del equipo. En equipos administrados, una política corporativa puede impedirlo.

### Opción B: elegir una sola GPU NVIDIA

Comprueba las tarjetas disponibles:

```powershell
nvidia-smi -L
```

La salida mostrará un índice y un UUID para cada GPU. **Selecciona el de tu equipo**; el índice de otra persona puede corresponder a una tarjeta diferente.

Por ejemplo, si la tarjeta que quieres usar aparece como **GPU 0**:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Ollama.ps1 -Gpu 0
```

Si aparece como **GPU 1**, cambia `0` por `1`. Una RTX 5070 puede seleccionarse así igual que cualquier otra NVIDIA compatible; no se presupone su índice.

También puedes usar el UUID completo mostrado por `nvidia-smi -L`:

```powershell
$gpu = Read-Host 'Pega el UUID completo de la GPU que quieres usar'
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Ollama.ps1 -Gpu $gpu
```

El launcher resuelve el índice a un UUID para evitar depender del orden de las tarjetas y configura el proceso de Ollama con:

```text
CUDA_VISIBLE_DEVICES = UUID de la GPU elegida
OLLAMA_VULKAN = 0
GGML_VK_VISIBLE_DEVICES = -1
ROCR_VISIBLE_DEVICES = -1
OLLAMA_KEEP_ALIVE = 30m
```

Esto limita los dispositivos de Ollama; no reserva la tarjeta ni impide que otras aplicaciones la usen. Si falta VRAM, puede ejecutarse parte del modelo en CPU. Vulkan se desactiva en esta opción para que la selección CUDA no quede evitada por otro backend.

### Opción C: probar sin GPU

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Ollama.ps1 -Cpu
```

La inferencia en CPU puede ser lenta. Si tarda más de cinco minutos, la demo agotará su espera aunque Ollama pueda seguir procesando.

### Comprobar que el servidor está disponible

En otra terminal:

```powershell
Invoke-RestMethod -Uri 'http://localhost:11434/api/version'
```

Debe devolver una versión igual o superior a `0.35.1`. Si falla, revisa la primera ventana.

## 4. Descargar Nimble 9B

Con Ollama ya arrancado, abre otra terminal en la carpeta del proyecto y ejecuta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Get-Model.ps1
```

El script comprueba las versiones del cliente y del servidor, ejecuta `ollama pull nimble:latest` y muestra los modelos instalados. La descarga puede tardar varios minutos y ocupa varios GB.

Los comandos directos equivalentes para descargar y listar son:

```powershell
ollama pull nimble:latest
ollama list
```

Debes ver `nimble:latest`. `latest` puede cambiar con futuras publicaciones; para reproducir una ejecución, conserva la versión de Ollama y el ID del modelo que aparece en `ollama list`.

No necesitas ejecutar `ollama run nimble`. Esta demo usa la API de decisiones, no un chat de texto.

## 5. Abrir la demo

En una segunda ventana, desde la carpeta del proyecto:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Demo.ps1
```

El navegador se abrirá en **[http://localhost:8080](http://localhost:8080)**. Si no se abre, copia esa dirección manualmente. Mantén ambas ventanas abiertas.

1. Lee el ticket de ejemplo; todos sus datos son ficticios.
2. Mantén el modelo `nimble:latest`.
3. Pulsa **Analizar ticket**.
4. Espera los diez resultados.
5. Abre **Respuesta completa de Ollama** para ver el JSON.
6. Pulsa **Descargar JSON** si quieres guardar el resultado.

**No abras `index.html` con doble clic.** El servidor local permite cargar `decisions.json` y proporciona el origen autorizado por Ollama.

La web llama directamente a `http://localhost:11434/v1/systemone`; el servidor de la demo solo sirve archivos estáticos. No hay un proxy ni dependencias de terceros en el navegador. Ambos servicios escuchan únicamente en el equipo local.

### Si el puerto 8080 está ocupado

Detén el launcher de Ollama y arranca ambos scripts con el mismo puerto alternativo:

```powershell
# Primera ventana
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Ollama.ps1 -DemoPort 8081
```

```powershell
# Segunda ventana
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Start-Demo.ps1 -Port 8081
```

Si estabas usando `-Gpu` o `-Cpu`, añade esa opción también al nuevo comando de Ollama. `-DemoPort` cambia el origen autorizado de la web, no el puerto de la API: Ollama sigue en `11434`.

## 6. Comprobar el resultado

### Prueba sin navegador

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Decision.ps1
```

La prueba envía el ticket y las diez preguntas de la demo al endpoint real y comprueba que cada respuesta tenga `type: noul` y un valor de 0 a 1.

### Ejemplo de salida

Este fragmento es **ilustrativo**, no una medición ni un resultado garantizado:

```json
{
  "model": "nimble:latest",
  "answers": {
    "solicita_reembolso": { "type": "noul", "noul": 0.97 },
    "pide_baja": { "type": "noul", "noul": 0.04 }
  }
}
```

Con umbral `0.5`, se mostraría **Solicita reembolso: Sí · 97 %** y **Solicita baja: No · 4 %**. La respuesta real incluye las diez decisiones y `usage` con el uso de tokens. Puede variar según el ticket, el modelo y su versión.

### Primera ejecución y modelo caliente

Puedes consultar una respuesta completa para el ticket de ejemplo en [`examples/response.json`](examples/response.json). Sus valores sirven como referencia de formato; no son resultados garantizados para otras ejecuciones.

La primera petición puede tardar más porque incluye cargar el modelo en memoria. Las siguientes suelen reducir ese tiempo al estar **caliente**, es decir, ya cargado. No hay un tiempo universal: influyen el equipo, la longitud del ticket, las diez preguntas y la memoria disponible.

El launcher usa `OLLAMA_KEEP_ALIVE=30m` y cada petición de la demo incluye `keep_alive: "30m"`. El modelo permanece cargado durante 30 minutos después de la última petición, salvo descarga, reinicio o presión de recursos. Esto ocupa RAM y/o VRAM mientras permanece cargado.

Para comparar dos peticiones consecutivas:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Decision.ps1 -Repeat 2
```

Si quieres empezar con el modelo descargado de memoria, ejecuta primero `ollama stop nimble:latest`. No habrá una carga fría si otro proceso lo está usando o vuelve a cargarlo antes de la prueba.

Para revisar la carga:

```powershell
ollama ps
```

En NVIDIA, abre otra terminal para ver actividad y memoria por tarjeta:

```powershell
nvidia-smi
```

El campo `PROCESSOR` de `ollama ps` muestra la proporción CPU/GPU; no identifica por sí solo la tarjeta física. Para comprobar la selección, revisa además los registros del launcher y la memoria de las GPUs con `nvidia-smi`.

## 7. Apagar y volver a arrancar

- Detén el servidor web y Ollama con **Ctrl+C** en sus respectivas ventanas. También puedes cerrar las ventanas dedicadas.
- Para descargar solo el modelo de memoria: `ollama stop nimble:latest`.
- La próxima vez, repite los pasos **3 y 5**. No hace falta descargar Nimble otra vez si sigue instalado.
- Para actualizar los pesos del modelo, repite el paso 4. Esto puede cambiar los resultados de clasificación.

## Qué hace cada archivo

```text
ollama-nimble-decision-layer/
├── README.md
├── LICENSE
├── app/
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── decisions.json
├── scripts/
│   ├── Common.ps1
│   ├── Start-Ollama.ps1
│   ├── Get-Model.ps1
│   ├── Start-Demo.ps1
│   └── Test-Decision.ps1
├── examples/
│   ├── request.json
│   └── response.json
├── docs/
│   └── integration.md
├── .gitattributes
└── .gitignore
```

| Archivo | Función |
| --- | --- |
| `app/index.html` | Pantalla en español con el ticket, controles y resultados |
| `app/styles.css` | Diseño adaptable a ordenador y móvil |
| `app/app.js` | Llama a `/v1/systemone`, valida respuestas, aplica el umbral y descarga JSON |
| `app/decisions.json` | Ticket de ejemplo, títulos y diez preguntas compartidas por la web y la prueba |
| `scripts/Common.ps1` | Comprobaciones de versión reutilizadas por los scripts |
| `scripts/Start-Ollama.ps1` | Arranca Ollama; selección opcional de GPU o CPU y permanencia de 30 minutos |
| `scripts/Get-Model.ps1` | Descarga Nimble y muestra los modelos instalados |
| `scripts/Start-Demo.ps1` | Sirve únicamente los archivos de la demo en el equipo local |
| `scripts/Test-Decision.ps1` | Comprueba las diez decisiones contra el servidor real y mide el tiempo total |
| `examples/request.json` | Petición mínima con una pregunta de reembolso |
| `examples/response.json` | Respuesta completa de referencia con las diez decisiones |
| `docs/integration.md` | Ejemplos de routing, herramientas, memoria y envío a otro agente |
| `.gitattributes` | Mantiene finales de línea adecuados para los archivos |
| `.gitignore` | Evita incluir modelos, registros y archivos temporales en Git |
| `LICENSE` | Licencia MIT de la interfaz y los scripts del proyecto |

## Cambiar el ticket y las decisiones

Para otro ticket, escribe directamente en el cuadro de la web. Para cambiar el ejemplo permanente o las preguntas, abre `app/decisions.json` en un editor de texto.

Cada pregunta tiene una clave estable, un tipo y criterios claros:

```json
"solicita_reembolso": {
  "type": "noul",
  "instructions": "¿El cliente solicita explícitamente un reembolso?",
  "criteria": {
    "true": "Pide devolver dinero o reembolsar un cargo.",
    "false": "No solicita devolver dinero."
  }
}
```

1. Cambia `instructions` y los dos criterios.
2. Si cambias una clave, cambia también esa clave en `labels`.
3. Guarda el archivo como UTF-8 y recarga la web.
4. Prueba casos positivos, negativos y ambiguos antes de usarlo en un flujo real.

Respeta las comillas dobles y las comas del JSON. La demo está diseñada para preguntas `noul`; los tipos `choice` y `score` requieren adaptar también su presentación. La API permite hasta 64 preguntas y un cuerpo de hasta 64 KiB sin imágenes. Empieza con tickets cortos y diez preguntas; si el servidor rechaza el contexto, reduce el texto o las preguntas.

## Adaptar a agentes y chatbots

Nimble puede actuar como una capa entre el mensaje y el resto del sistema. El programa recibe su decisión y aplica reglas explícitas:

| Uso | Pregunta o criterio | Acción del programa |
| --- | --- | --- |
| Routing | ¿Es un problema técnico o de facturación? | Seleccionar la ruta adecuada |
| Tool selection | ¿Hace falta consultar un pedido o una cuenta? | Elegir una herramienta permitida |
| Memoria | ¿Contiene una preferencia duradera y permitida? | Guardar solo datos autorizados |
| Escalado | ¿Solicita una persona o hay incertidumbre? | Pasar a revisión humana |
| Moderación | ¿El mensaje incumple una regla definida? | Revisar o limitar el flujo según la política |
| Clasificación | ¿Qué etiqueta encaja mejor? | Añadir la etiqueta al ticket |
| Otro agente | ¿Qué especialidad corresponde? | Entregar el estado al agente elegido |

Las probabilidades no sustituyen permisos, validación ni autenticación. Un resultado de «reembolso: sí» indica una solicitud; no autoriza devolver dinero. Para rutas mutuamente excluyentes conviene usar `choice` con una opción `sin_coincidencia`, en vez de depender de varios sí/no que pueden coincidir.

Consulta [los ejemplos de integración](docs/integration.md) para ver peticiones copiables y cómo separar la clasificación de la ejecución.

## Solución de errores

| Síntoma | Qué hacer |
| --- | --- |
| `ollama` no se reconoce | Instala Ollama y abre una terminal nueva. Comprueba `Get-Command ollama` |
| Versión anterior a 0.35.1 | Actualiza y reinicia Ollama; comprueba también `/api/version` |
| El puerto 11434 ya está ocupado | Sal de Ollama desde el icono junto al reloj o detén la otra consola. El launcher no cierra procesos automáticamente |
| La demo no conecta | Mantén abierto el launcher y comprueba `Invoke-RestMethod 'http://localhost:11434/api/version'` |
| HTTP 404 | Revisa el mensaje: puede faltar `nimble:latest` o estar arrancado un servidor anterior sin `/v1/systemone`. Ejecuta `ollama list` y comprueba la versión del servidor |
| HTTP 400 | Revisa `decisions.json`, el tipo `noul` y sus criterios `true`/`false`; el modelo debe ser compatible con System One |
| HTTP 413 o error de contexto | Reduce el ticket o las preguntas. El límite de cuerpo no garantiza que el texto quepa en el contexto del modelo |
| HTTP 500 / memoria insuficiente | Lee el error de Ollama, cierra aplicaciones que consuman RAM/VRAM y vuelve a probar; usar CPU necesita RAM suficiente |
| `nvidia-smi` no se reconoce | Usa la opción predeterminada o instala/actualiza el controlador NVIDIA si tu equipo tiene esa GPU |
| GPU no encontrada | Repite `nvidia-smi -L`; copia un índice existente o el UUID completo |
| Actividad en otra GPU | Comprueba que el servidor activo se arrancó con `-Gpu`; las opciones no cambian un servidor que ya estaba abierto. Revisa los registros de Ollama y `nvidia-smi` |
| Primera petición lenta | Espera la carga. Compara después dos peticiones con el mismo ticket y el modelo caliente |
| Error de CORS / `Failed to fetch` | Usa `http://localhost:8080` y el launcher. Si cambias el puerto, usa también `-DemoPort` y reinicia Ollama. El navegador puede pedir permiso de acceso a la red local |
| Error al abrir `decisions.json` | Arranca `Start-Demo.ps1`; no abras el HTML con doble clic |
| Puerto 8080 ocupado | Usa los dos comandos con 8081 del paso 5 |
| No se permiten scripts | Usa los comandos completos de la guía. Si una política corporativa bloquea la ejecución, consulta al administrador |
| Cambios de JSON no aparecen | Guarda el archivo y recarga la página; el servidor envía los archivos sin caché |

## Referencias

- [Descarga de Ollama para Windows](https://ollama.com/download/windows)
- [API System One: formato de petición y respuesta](https://docs.ollama.com/api/systemone)
- [Nimble 9B: modelo, descarga y ejemplos](https://ollama.com/library/nimble)
- [GPUs: selección por UUID y control de Vulkan](https://docs.ollama.com/gpu)
- [Preguntas frecuentes de Ollama](https://docs.ollama.com/faq)

La interfaz y los scripts se distribuyen bajo [licencia MIT](LICENSE). El repositorio contiene la interfaz, configuración y scripts; los pesos se descargan desde Ollama y tienen sus propias condiciones de licencia.
