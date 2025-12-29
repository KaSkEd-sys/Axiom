[BITS 16]
[ORG 0x1000]

start:
    xor ax, ax
    mov ds, ax

    call clear_screen

    mov si, welcome_msg
    call print_string

main_loop:
    mov si, prompt_msg
    call print_string

    call read_line

    mov si, input_buffer

    mov di, cmd_info
    call strcmp
    cmp ax, 1
    je do_info

    mov di, cmd_time
    call strcmp
    cmp ax, 1
    je do_time

    mov di, cmd_clear
    call strcmp
    cmp ax, 1
    je do_clear

    mov di, cmd_reboot
    call strcmp
    cmp ax, 1
    je do_reboot

    mov di, cmd_ping
    call strcmp
    cmp ax, 1
    je do_ping

    mov di, cmd_shut
    call strcmp
    cmp ax, 1
    je do_shut

    mov di, cmd_help
    call strcmp
    cmp ax, 1
    je do_help

    mov si, input_buffer
    mov di, cmd_opreg
    call strcmp_prefix
    cmp ax, 1
    je do_opreg

    mov di, cmd_fastfetch
    call strcmp
    cmp ax, 1
    je do_fastfetch

    mov si, unknown_msg
    call print_string
    jmp main_loop

do_info:
    mov si, info_msg
    call print_string
    jmp main_loop

do_time:
    mov ah, 0x02
    int 0x1A

    mov si, time_msg
    call print_string

    mov al, ch
    call print_hex
    mov al, ':'
    call print_char

    mov al, cl
    call print_hex
    mov al, ':'
    call print_char

    mov al, dh
    call print_hex

    call newline
    jmp main_loop

do_clear:
    call clear_screen
    mov si, welcome_msg
    call print_string
    jmp main_loop

do_ping:
    mov si, pong_msg
    call print_string
    jmp main_loop

do_reboot:
    mov si, reboot_msg
    call print_string
.wait:
    in al, 0x64
    test al, 2
    jnz .wait
    mov al, 0xFE
    out 0x64, al

do_help:
    mov si, help_msg
    call print_string
    jmp main_loop

do_shut:
    mov si, shut_msg
    call print_string
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
.hang:
    cli
    hlt
    jmp .hang

do_opreg:
    mov si, input_buffer
    mov cx, 5
.skip_cmd:
    lodsb
    loop .skip_cmd
    
.skip_spaces:
    lodsb
    cmp al, ' '
    je .skip_spaces
    cmp al, 0
    je .no_param
    
    cmp al, '-'
    jne .no_param
    
    lodsb
    cmp al, 0
    je .no_param
    
    cmp al, 'r'
    je .read_reg
    cmp al, 'c'
    je .change_reg
    cmp al, 'd'
    je .delete_reg
    jmp .no_param

.no_param:
    mov si, opreg_help_msg
    call print_string
    jmp main_loop

.read_reg:
    mov si, opreg_read_msg
    call print_string
    
    mov si, fastfetch_comp_name
    call print_string
    mov al, [fastfetch_enabled]
    cmp al, 1
    je .show_enabled
    mov si, status_disabled
    call print_string
    jmp main_loop
.show_enabled:
    mov si, status_enabled
    call print_string
    jmp main_loop

.change_reg:
    mov byte [fastfetch_enabled], 1
    mov si, opreg_change_msg
    call print_string
    jmp main_loop

.delete_reg:
    mov byte [fastfetch_enabled], 0
    mov si, opreg_delete_msg
    call print_string
    jmp main_loop

do_fastfetch:
    mov al, [fastfetch_enabled]
    cmp al, 1
    jne .disabled
    
    mov si, tiger_art
    call print_string
    jmp main_loop

.disabled:
    mov si, fastfetch_disabled_msg
    call print_string
    jmp main_loop

strcmp:
    pusha
.next:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    test al, al
    jz .yes
    inc si
    inc di
    jmp .next
.yes:
    popa
    mov ax, 1
    ret
.no:
    popa
    xor ax, ax
    ret

strcmp_prefix:
    pusha
    xor cx, cx
.next:
    mov al, [si]
    mov bl, [di]
    cmp bl, 0
    je .check_end
    cmp al, bl
    jne .no
    inc si
    inc di
    inc cx
    jmp .next
.check_end:
    mov al, [si]
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
.no:
    popa
    xor ax, ax
    ret
.yes:
    popa
    mov ax, 1
    ret

print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

newline:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret

read_line:
    pusha
    mov di, input_buffer
    xor cx, cx
.read:
    xor ah, ah
    int 0x16
    cmp al, 13
    je .done
    cmp al, 8
    je .back
    cmp cx, 63
    jge .read
    stosb
    inc cx
    call print_char
    jmp .read
.back:
    test cx, cx
    jz .read
    dec di
    dec cx
    mov byte [di], 0
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .read
.done:
    mov byte [di], 0
    call newline
    popa
    ret

clear_screen:
    pusha
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    popa
    ret

print_hex:
    pusha
    mov bl, al
    shr al, 4
    call .digit
    mov al, bl
    and al, 0x0F
    call .digit
    popa
    ret
.digit:
    cmp al, 9
    jle .num
    add al, 7
.num:
    add al, '0'
    call print_char
    ret

welcome_msg db '=== KaskedOS v1.2 alpha ===',13,10
             db 'type help for command list',13,10,13,10,0
prompt_msg db '[fastuser]$kaskedos$ > ',0
unknown_msg db 'Unknown command',13,10,0
info_msg db '<< KaskedOS x86 >>',13,10
         db '16 bit operating system written by kasked',13,10,13,10,0
time_msg db 'Time: ',0
reboot_msg db 'Rebooting...',13,10,0
pong_msg db 'pong!',13,10,0
shut_msg db 'Shutting down KaskedOS x86',13,10,0
help_msg db '<< help list KaskedOs v1.2 alpha >>',13,10
         db 'info - shows info about system',13,10
         db 'time - shows current time',13,10
         db 'clear - clear screen',13,10
         db 'reboot - rebooting system',13,10
         db 'ping - pong!',13,10
         db 'shut - shutting down system',13,10
         db 'opreg -[arg] - manage OS components',13,10,0
cmd_help   db 'help',0
cmd_info   db 'info',0
cmd_time   db 'time',0
cmd_clear  db 'clear',0
cmd_reboot db 'reboot',0
cmd_ping   db 'ping',0
cmd_shut   db 'shut',0
cmd_opreg  db 'opreg',0
cmd_fastfetch db 'fastfetch',0

opreg_help_msg db 'opreg - OS Components Registry',13,10
               db 'Usage: opreg -[arg]',13,10
               db '  -r  read OS components status',13,10
               db '  -c  enable OS component',13,10
               db '  -d  disable OS component',13,10,13,10,0
opreg_read_msg db 'OS Components Registry:',13,10,0
opreg_change_msg db 'Component enabled successfully',13,10,0
opreg_delete_msg db 'Component disabled successfully',13,10,0
fastfetch_comp_name db 'fastfetch: ',0
fastfetch_disabled_msg db 'fastfetch is disabled. Use opreg -c to enable',13,10,0
status_enabled db 'ENABLED',13,10,0
status_disabled db 'DISABLED',13,10,0

tiger_art db '            /\\',13,10
          db '           /  \\     fastuser@kaskedos',13,10
          db '          / /\\ \\    ---------------------',13,10
          db '         ( (  ) )   OS: KaskedOS x86 v1.2 alpha',13,10
          db '        (  \\  / )   Kernel: 16-bit Real Mode',13,10
          db '         \\  \\/  /   Architecture: x86',13,10
          db '          \\    /    Shell: kaskedos shell',13,10
          db '       /\\ |  | /\\   Uptime: Since boot',13,10
          db '      /  \\|  |/  \\  ',13,10
          db '     (    \\  /    )',13,10
          db '      \\    \\/    /',13,10
          db '       \\        /',13,10
          db '        \\  __  /',13,10
          db '         \\(  )/',13,10
          db '          \\  /',13,10
          db '           \\/',13,10,13,10,0

fastfetch_enabled db 0

input_buffer times 64 db 0