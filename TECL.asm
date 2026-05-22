[BITS 16]                   ; Indica al ensamblador código de 16 bits para modo real
[ORG 0x100]                 ; Origen en el desplazamiento 0x100 (Estándar de archivos .COM)

start:
.poll:
    in al, 64h              ; Lee el byte del Registro de Estado del controlador 8042
    test al, 01h            ; Comprueba el Bit 0 (OBF: Output Buffer Full)
    jz .poll                ; Si el bit es 0 (ZF=1), el buffer está vacío; sigue esperando

    in al, 60h              ; El bit OBF se activó (1). Lee el scancode del Puerto de Datos
    mov bl, al              ; Copia temporalmente el scancode al registro BL para procesarlo

    ; --- IMPRESIÓN DEL NIBLE ALTO EN HEXADECIMAL ---
    mov ah, 02h             ; Servicio DOS: Imprimir un único carácter en pantalla
    mov dl, bl              ; Mueve el scancode original a DL para su manipulación
    shr dl, 4               ; Desplaza 4 bits a la derecha para aislar el niple alto (decenas hex)
    add dl, 30h             ; Conversión base: suma el offset para dígitos '0'-'9'
    cmp dl, 3Ah             ; Compara si el resultado está entre '0' y '9' o si es una letra ('A'-'F')
    jl .printH              ; Si es menor que 3Ah, es un número válido. Salta a imprimir
    add dl, 07h             ; Ajuste alfabético: suma 7 para ajustar hacia las letras 'A'-'F'
.printH:
    int 21h                 ; Ejecuta la interrupción del DOS para plasmar el carácter alto

    ; --- IMPRESIÓN DEL NIBLE BAJO EN HEXADECIMAL ---
    mov dl, bl              ; Recupera el scancode original desde el respaldo en BL
    and dl, 0Fh             ; Aplica una máscara AND para limpiar los 4 bits altos e aislar las unidades
    add dl, 30h             ; Intenta la conversión base sumando 30h
    cmp dl, 3Ah             ; Verifica si el carácter resultante es numérico o alfabético
    jl .printL              ; Si es un dígito del 0 al 9, procede directamente
    add dl, 07h             ; Ajuste alfabético para el rango de letras 'A'-'F'
.printL:
    int 21h                 ; Llamada al DOS para imprimir el carácter bajo

    ; --- EMISIÓN DE SALTO DE LÍNEA (CRLF) ---
    mov ah, 02h             ; Mantiene la función de escritura de carácter único
    mov dl, 0Dh             ; Código ASCII para Carriage Return (Retorno de carro)
    int 21h                 ; Ejecución de la salida
    mov dl, 0Ah             ; Código ASCII para Line Feed (Salto de línea)
    int 21h                 ; Ejecución de la salida

    ; --- FINALIZACIÓN ---
    mov ah, 4Ch             ; Función DOS: Terminar el proceso de manera limpia
    xor al, al              ; Pone el código de retorno del programa en 0
    int 21h                 ; Devuelve el control a la terminal de DOSBox