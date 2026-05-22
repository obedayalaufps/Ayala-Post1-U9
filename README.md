# Arquitectura de Computadores - Unidad 9: Post-Contenido 1

## Datos del Estudiante
* **Nombre:** Obed Ayala
* **Institución:** Universidad Francisco de Paula Santander (UFPS)
* **Programa:** Ingeniería de Sistemas
* **Año:** 2026

## Descripción de la Actividad
Este laboratorio práctico aborda el estudio profundo de los modelos de transferencia de Entrada/Salida (E/S) en la arquitectura x86 mediante el acceso directo a puertos de hardware empleando las instrucciones de bajo nivel `IN` y `OUT` (Port-Mapped I/O - PMIO). 

A través de tres fases experimentales en el emulador DOSBox, se analiza el comportamiento de la sincronización por sondeo dinámico (*polling*), el control de excepciones por *timeout* sobre el controlador de teclado de legado 8042, y el protocolo síncrono de comunicación física Centronics aplicado a la interfaz de puerto paralelo.

## Estructura del Repositorio
El repositorio está organizado bajo la estructura formal de ingeniería requerida para la entrega de la asignatura:
```text
Ayala-Post1-U9/
├── capturas/               # Capturas de pantalla de evidencias en DOSBox
├── TECL.ASM                # Código fuente: Lectura de scancodes de teclado
├── POLL_T.ASM              # Código fuente: Bucle de sondeo con control de timeout
├── PARALELO.ASM            # Código fuente: Protocolo Centronics (Puerto Paralelo)
└── README.md               # Documentación técnica del laboratorio (Este archivo)

```

---

## Análisis Técnico y Resultados de los Checkpoints

### Checkpoint 1: Monitoreo del Controlador 8042 (`TECL.ASM`)

El programa realiza un acceso directo al registro de estado `64h` del chip de teclado 8042. Emplea un lazo cerrado de consulta constante buscando la activación del Bit 0 (**OBF - Output Buffer Full**). Una vez que el bit cambia a `1` (indicando que el usuario interactuó con el hardware), la CPU rompe el salto condicional `JZ`, extrae el *scancode* puro desde el puerto de datos `60h` y lo procesa mediante una rutina matemática para imprimir su equivalente en código ASCII hexadecimal en la terminal.

* **Comportamiento observado y diagnóstico de ingeniería:** Al ejecutar `TECL.COM` dentro del entorno emulado de DOSBox, la línea de comandos se queda estancada con el cursor parpadeando indefinidamente y no responde a las pulsaciones comunes.
* **Explicación científica:** Al ser un bucle de *polling* puro sin retardos, el procesador virtual consume el 100% de los ciclos de CPU del emulador en un lazo infinito. Esto satura el hilo de ejecución de DOSBox e impide que los eventos del teclado físico del sistema operativo anfitrión conmuten correctamente el bit `OBF` a nivel de hardware simulado. El programa se queda esperando un cambio eléctrico que la CPU saturada no le permite procesar al emulador.

### Checkpoint 2: Control de Sincronización y Timeout (`POLL_T.ASM`)

Como solución directa al problema de congelamiento del Checkpoint 1, se diseñó un mecanismo de escape controlado por software utilizando una constante límite de reintentos (`MAX_RETRY equ 0FFFFh`) cargada en el registro contador `CX`. El procesador evalúa el estado del hardware, pero si el dispositivo periférico no responde tras agotar las iteraciones del registro, la instrucción `LOOP` disminuye el contador hasta cero, rompiendo el bloqueo y saltando a una sección de manejo de errores.

* **Resultado observado:** Al inicializar la constante en un rango bajo para pruebas de estrés, el programa agota sus intentos en microsegundos antes de que el usuario logre interactuar físicamente, imprimiendo en pantalla de forma limpia y segura el mensaje: `Timeout: sin respuesta del dispositivo` y devolviendo el control al prompt de comandos sin congelar el sistema.

### Checkpoint 3: Interfaz Centronics e Inyección a Puertos (`PARALELO.ASM`)

Este programa emula la transferencia física de datos hacia una impresora tradicional a través de los tres registros base del puerto paralelo: Datos (`0378h`), Estado (`0379h`) y Control (`037Ah`). El software implementa el protocolo síncrono Centronics: sondea que la línea `BUSY#` (Bit 7 de Estado) esté inactiva, inyecta el byte ASCII `41h` ('A') al bus de datos, baja manualmente a cero el bit de control de la línea síncrona `STROBE` para indicarle al periférico que lea las líneas, sostiene un retardo de estabilización eléctrica mediante un bucle de software (`loop .delay`) y vuelve a levantar la señal `STROBE` a alto.

* **Resolución del Conflicto de Nombres Reservados de DOS (Lección Aprendida):** Al intentar compilar originalmente el archivo bajo el nombre `LPT1.ASM`, el compilador NASM y DOSBox se congelaban por completo antes de generar el binario. Esto se debe a que **`LPT1` es un nombre de dispositivo reservado por el sistema operativo DOS** para el hardware físico. Al invocar dicho nombre, DOS intenta desviar el flujo de lectura hacia los canales del puerto paralelo real en lugar de leer el archivo de texto en el disco duro, provocando un bloqueo eterno por hardware. **La solución de ingeniería consistió en renombrar el archivo fuente a `PARALELO.ASM**`, con lo cual NASM pudo leer el código y compilar exitosamente `PARALELO.COM` en un milisegundo.
* **Resultado observado en ejecución:** Al correr `PARALELO.COM` en DOSBox, el programa finaliza instantáneamente volviendo al prompt `C:\>`. Esto ocurre porque DOSBox, al no tener una impresora real asignada, simula que la línea `BUSY#` está siempre libre (alta por defecto). El programa ejecuta la lógica de sincronización, activa y desactiva los registros de control invisibles en memoria y termina limpiamente sin producir excepciones de núcleo.

---

## Conclusiones Técnicas del Laboratorio

1. **Aislamiento de Espacios (PMIO vs MMIO):** Se evidenció la separación lógica de la arquitectura x86 al gestionar periféricos a través de un mapa independiente de 64 KB de puertos utilizando instrucciones dedicadas (`IN`/`OUT`), protegiendo el segmento de memoria RAM convencional contra escrituras corruptas provenientes de dispositivos de hardware inestables.
2. **Infección de Rendimiento por Polling:** El laboratorio demostró que, aunque el *polling* es una técnica simple y directa para interactuar con hardware en sistemas embebidos de un solo propósito, es catastrófica en sistemas operativos multitarea de propósito general. Monopolizar los ciclos del procesador en lazos cerrados degrada el rendimiento global, ratificando por qué las arquitecturas modernas delegan estas tareas a sistemas basados en **Interrupciones** o controladores **DMA (Direct Memory Access)**.
3. **Restricciones Heredadas de Sistemas Operativos:** El desarrollo en modo real de 16 bits expuso limitaciones históricas vigentes, como los nombres de archivos protegidos (`LPT1`, `CON`, `PRN`), recordándonos la importancia de comprender las capas del sistema operativo subyacente al interactuar directamente con la programación a bajo nivel.
