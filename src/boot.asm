[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    sti

    mov [boot_drive], dl

    mov si, boot_msg
    call print

    mov bx, 0x1000
    mov ah, 0x02
    mov al, 8
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13

    jmp 0x0000:0x1000

print:
    mov ah, 0x0E
.next:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

boot_msg db 'Loading KaskedOS...', 13, 10, 0
boot_drive db 0

times 510-($-$$) db 0
dw 0xAA55
