[BITS 16]
[ORG 0x100]

MAX_RETRY equ 0FFFFh        ; Define una constante con el número máximo de reintentos en hex

start:
    mov cx, MAX_RETRY       ; Inicializa el registro contador CX con el límite de intentos
.poll:
    in al, 64h              ; Consulta el registro de estado del controlador de teclado
    test al, 01h            ; Comprueba la disponibilidad de datos en el buffer (Bit 0)
    jnz .dato_listo         ; Si el bit es 1 (ZF=0), rompe el bucle; el hardware respondió
    loop .poll              ; Decrementa CX en 1 de forma automática. Si CX != 0, reintenta

    ; --- CASO EXCEPCIONAL: TIMEOUT ALCANZADO ---
    mov ah, 09h             ; Servicio DOS: Imprimir una cadena de texto completa
    mov dx, msg_timeout     ; Carga la dirección base de la cadena de error en DX
    int 21h                 ; Envía el texto a la pantalla
    jmp .fin                ; Salta incondicionalmente a la sección de salida

.dato_listo:
    in al, 60h              ; Captura el byte de datos remanente del teclado
    mov ah, 02h             ; Servicio DOS: Escritura de carácter único
    mov dl, al              ; Traspasa el dato leído para ser impreso de manera directa
    int 21h                 ; Imprime la representación ASCII directa del byte capturado

.fin:
    mov ah, 4Ch             ; Carga el código de salida del programa
    int 21h                 ; Retorna el control al intérprete de comandos

section .data
    msg_timeout db 'Timeout: sin respuesta del dispositivo$', 0Dh, 0Ah