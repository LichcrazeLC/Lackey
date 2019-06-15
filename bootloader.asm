;*************************************************;
;	               Lackey BOOTLOADER
;*************************************************;

[bits 16] 
org 0x7C00

  call main

  welcomeprompt db 'This is me, your Lackey. Want me to Boot? y/n',0
  loadingprompt db 'Getting ready to serve.... Please be patient.',0
  notloadingprompt db 'Ok, too bad. Wake me up when you change your mind.....',0
  loadingbar db '..',0

  main:

   xor ax,ax
   xor bx,bx
   xor cx,cx
   xor dx,dx

   mov si, 0

   mov di, 0

   

   mov ah, 0x00
   mov al, 3
   mov dx, 0
   int 0x10

    mov cx,1

    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    mov dl,0x00
    mov dh,0x00
    int 0x10      

    mov ah, 0x0E
    mov bl, 0x0F
    mov si, welcomeprompt
    jmp .printWelcome

 .printWelcome:
    lodsb                ; get character from string
    cmp al, 0                    ; cmp al with end of string
    je .inputLoop               ; if char is zero, end of string

    mov ah, 0x09
    int 0x10                     ; otherwise, print it

    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    inc dl
    int 0x10   

    jmp .printWelcome        ; jmp to .printWelcome if not 0  

.printLoading:
    lodsb                ; get character from string
    cmp al, 0                    ; cmp al with end of string
    je .Draw               ; if char is zero, end of string
   
    mov ah, 0x09
    int 0x10                     ; otherwise, print it

    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    inc dl
    int 0x10   

    jmp .printLoading        ; jmp to .Draw if not 0  

.printIfNotLoading:
    lodsb                ; get character from string
    cmp al, 0                    ; cmp al with end of string
    je .halt               ; if char is zero, end of string
   
    mov ah, 0x09
    int 0x10                     ; otherwise, print it

    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    inc dl
    int 0x10   

    jmp .printIfNotLoading        ; jmp to .Draw if not 0  

.inputLoop:
    mov ax,0x00
    int 0x16

    mov bl, 3

    cmp ah, 0x15             ; compare input is y or not
    je .boot

    cmp al, 0x6E
    je .dontBoot

    mov ah, 0x09             ;display input char
    mov bl, 3
    int 0x10

    jmp .inputLoop

 .dontBoot:
    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    inc dh
    mov dl,0x00

    int 0x10  

    mov si, notloadingprompt
    jmp .printIfNotLoading 

 .halt:
   jmp .halt

 .boot:

    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    inc dh
    mov dl,0x00

    int 0x10  

    mov si, loadingprompt
    jmp .printLoading

 .Draw:

    mov si, loadingbar
    lodsb                ; get character from string
    cmp al, 0                    ; cmp al with end of string
    je .Draw               ; if char is zero, end of string

    mov ah, 0x09
    int 0x10                     ; otherwise, print it

    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    inc dl 
    int 0x10   

    cmp dl, 50
    je .reset_disk

    jmp .Draw        ; jmp to .Draw if not 0  

 .reset_disk:      
    mov ah, 0
    int 0x13 ; 0x13 ah=0 dl = drive number
    mov dl, 0
    jmp .jump_to_kernel

 .jump_to_kernel:
   mov bx, 0000h
   mov es, bx

    mov bx, 8000h     ; bx = address to write the kernel to
    mov al, 4 		   ; al = amount of sectors to read
    mov ch, 8          ; cylinder/track = 0
    mov dh, 0         ; head           = 0
    mov cl, 15          ; sector         = 2
    mov ah, 2          ; ah = 2: read from drive
    int 0x13   		   

    jmp 0000h:8000h
;READING KERNEL FROM SECTOR 303

times 510-($-$$) db 0

db 0x55 ;byte 511 = 0x55
db 0xAA ;byte 512 = 0xAA

times 154112-512 db 0

;db 'this is the about INFO. Author: C.Laurentiu FAF 171'

;FILLING SECTORS UP UNTIL 303 WITH ZEROES
;times 154624-($-$$) db 0


