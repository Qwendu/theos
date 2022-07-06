
%define vbs 0x10
%define vbs_str 0x13
%define vbs_tty 0x0e

%define vbs_vesa_info      0x4f00
%define vbs_vesa_mode_info 0x4f01
%define vbs_vesa_set_mode  0x4f02

%define vesa_success 0x4f

%define dbs 0x13
%define dbs_read 0x02
%define dbs_ext_read 0x42
%define dbs_get_parameters 0x48

%define sbe 0x15

%define PRINT_MODES 0

[org 0x7c00]
[bits 16]

    jmp 0:start

%include "generated.asm"

start:
    ; === Segment registers ===
    xor ax, ax
    mov es, ax
    mov ss, ax
    mov ds, ax

    ; === Stack registers ===
    mov bp, 0x7c00
    mov sp, bp

    ; === Save boot drive ===
    mov [.boot_drive], dl
    mov byte [boot_data_area + 4], dl

    ; === Video mode ===
    mov al, 0x3
    int vbs

    ; === Load the rest of the bootloader ===
    mov ah, dbs_read
    mov al, bootloader_sectors - 1
    mov cx, 2
    mov dh, 0
    mov dl, [.boot_drive]
    mov bx, rest_of_the_bootloader

    int dbs

    ; === Unreal mode ===
    cli
    push ds
    push es
    lgdt [unreal_gdt]

    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp $+2
    mov bx, 0x08
    mov ds, bx
    mov bx, 0x10
    mov es, bx

    and al, 0xfe
    mov cr0, eax

    pop es
    pop ds
    sti

    ; === Enable A20 (probably) ===
    mov ax, 0x2401
    int 0x15

    ; === Get boot drive parameters ===
    drive_parameters_buffer_size equ 0x42;
    mov word [boot_data_area + 16], drive_parameters_buffer_size
    mov ah, dbs_get_parameters
    mov si, boot_data_area + 16
    mov dl, [.boot_drive]
    int dbs

    ; === Get memory map ===
    mov word [boot_data_area + 6], 0
    mov di, boot_data_area + (boot_data_size / 2);
    xor ebx, ebx

  .mmap_loop:
    mov eax, 0xe820
    mov edx, 0x534d4150
    mov ecx, 24
    add di, 24

    int sbe

    cmp ebx, 0x0
    je .mmap_end
    inc word [boot_data_area + 6]
    jmp .mmap_loop
  .mmap_end:
    mov word [boot_data_area + 8], boot_data_area + (boot_data_size / 2)

%if ENABLE_VESA
    ; === Get VESA info ===
    mov di, vbe_info_block
    mov ax, vbs_vesa_info
    int vbs
    cmp al, vesa_success
    jne .detect_vbe_fail

    ; === Iterate VESA mode numbers ===
    mov bx, vbe_info_block.video_modes

  .detect_vbe_loop:
    mov cx, [bx]
    cmp cx, 0xffff
    je .detect_vbe_fail

    mov di, vbe_mode
    mov ax, vbs_vesa_mode_info
    int vbs

    ; === Display VESA mode parameters ===
    ; pusha
    ; mov bx, [bx]
    ; call write_hex
    ; 
    ; mov bx, [vbe_mode.width]
    ; call write_hex
    ; 
    ; mov bx, [vbe_mode.height]
    ; call write_hex
    ; 
    ; xor bx, bx
    ; mov byte bl, [vbe_mode.bpp]
    ; call write_hex
    ; call newline
    ; popa

    add bx, 2

    cmp word [vbe_mode.width], vesa_width
    jne .detect_vbe_loop
    cmp word [vbe_mode.height], vesa_height
    jne .detect_vbe_loop
    cmp byte [vbe_mode.bpp], vesa_depth
    jne .detect_vbe_loop
    mov ax, [vbe_mode.attributes]
    test ax, 1 << 7
    jz .detect_vbe_loop

    jmp .detect_vbe_succeed

  .detect_vbe_fail:
    mov bx, .vesa_fail_message
    call write_string
    jmp $

  .detect_vbe_succeed:
    mov ax, vbs_vesa_set_mode
    mov bx, [bx - 2]
    or bx, 0x4000
    int vbs
    cmp ax, vesa_success
    jne .detect_vbe_fail
%endif ; ENABLE_VESA

    mov dword eax, [vbe_mode.buffer]
    mov dword [boot_data_area], eax

    call load_kernel_dbs

    ; === Switch to Long Mode ===
    mov edi, page_table_address
    jmp SwitchToLongMode

  .greeting: db 'Hello, sailor', 0xa, 0xd, 0

  .vesa_fail_message: db '  No appropriate VESA mode was found, or VESA is not supported.', 0xa, 0xd, 0
  .boot_drive: db 0
  .space: db ' ', 0

unreal_gdt:
   dw .end - .start - 1
   dd .start

.start:
   dq 0
   db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
   db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
.end:

times 0x1fe-($-$$) db 0
dw 0xaa55
rest_of_the_bootloader:

write_string:
    pusha
    mov ah, vbs_tty

  .loop:
    mov al, [bx]
    cmp al, 0
    je .end
    inc bx
    int vbs

    jmp .loop

  .end:
    popa
    ret

newline:
    pusha
    mov bx, .lfcr
    call write_string
    popa
    ret

  .lfcr: db 0xa, 0xd, 0

write_hex:
    pusha

    mov cx, bx
    mov bx, .prefix
    call write_string
    mov bx, cx
    mov cx, 12

  .loop:
    push bx
    sar bx, cl
    and bx, 0xf
    mov ax, [.table + bx]
    mov [.char], al
    mov bx, .char
    call write_string

    pop bx
    sub cx, 4
    cmp cx, 0
    jge .loop

    popa
    mov bx, start.space
    call write_string
    ret

  .table: db '0123456789abcdef', 0
  .char: db 0, 0
  .prefix: db '0x', 0

sector_size equ 0x200
sectors_per_load equ 0x10;

[bits 16]
disk_address_packet:
  .size:        db 10h
  .reserved:    db 0
  .num_sectors: dw sectors_per_load
  .buffer:      dw 0
  .segment:     dw kernel_load_buffer >> 4
  .source_lba:  dq bootloader_sectors

load_kernel_dbs:

    xor ebx, ebx
    mov cx, kernel_sectors

    xor ax, ax
    mov ds, ax

    cld
    mov dl, [start.boot_drive]

  .loop:
    ; === Call BIOS extended read ===
    mov ah, dbs_ext_read
    mov al, 0
    mov word [disk_address_packet.num_sectors], sectors_per_load

    mov si, disk_address_packet
    int dbs
    jc .fail

    add word [disk_address_packet.source_lba], sectors_per_load

    ; === Copy to high memory ===
    push cx
    mov ecx, sectors_per_load * sector_size
    mov edi, ebx
    mov esi, kernel_load_buffer
    add edi, 0x500_000

    a32 rep movsb

    add ebx, sectors_per_load * sector_size
    pop cx

    sub cx, sectors_per_load
    jnz .loop
    ret

  .fail:
    mov bx, .message
    call write_string
    mov bx, ax
    call write_hex
    jmp $

  .message: db "There has been an error while reading the disk: "

%include "long.asm"

[bits 64]
long_mode_start:
    mov rbp, 0xffffffff80300000
    mov rsp, rbp

    mov rcx, 0xffffffff80100000
  .clear_loop:
    mov byte [rcx], 0
    inc rcx
    cmp rcx, 0xffffffff80400000
    jne .clear_loop

    cld
    xor rbx, rbx
  .loop:
    cmp rbx, [kernel_section_table.count]
    je .end

    ; === Target address ===
    mov rax, rbx
    imul rax, 32
    add rax, kernel_section_table
    mov rdi, [rax]

    ; === Source address ===
    mov rsi, [rax + 8]

    ; === Copy ===
    mov rcx, [rax + 24]
    rep movsb

    inc rbx
    jmp .loop

  .end:
    jmp kernel_entry_point



vbe_info_block:
  .signature:      dd 0
  .version:        dw 0
  .oem:            dd 0
  .capabilities:   dd 0
  .video_modes:    dd 0
  .total_memory:   dw 0

; === Space, because some implementations put video mode numbers here ===
times 0x200 db 0

vbe_mode:
  .attributes: dw 0
  times 0x10   db 0
  .width:      dw 0
  .height:     dw 0
  times 0x3    db 0
  .bpp:        db 0
  times 0xe    db 0
  .buffer:     dd 0

times (bootloader_sectors * 0x200)-($-$$) db 0
