;*************************************************;
;	               Lackey KERNEL
;*************************************************;
[bits 16]  
org 0x8000

start:
    
    call main    

    stringCompare:
        pusha                                 ;save all registers
        or cx, -1                             ;set cx to biggest unsigned number
        xor al, al                            ;set al to 0
        repne scasb                           ;scan through di until zero terminator was hit and decrease cx for each scanned character
        neg cx                                ;calculate length of di by negating cx which returns the length of the string including zero terminator
        sub di, cx                            ;reset di by setting it to the original index it started with
        inc di
        repe cmpsb                            ;check if character from di match with si (including zero terminator)
        test cx, cx                           ;test if amount of matching = size of string, set zero flag if equals
        popa                                  ;restore all registers
    ret  

    hexstr2num:
        push ax                                ;save ax and si 
        push si
        push dx
        push cx
        push bx
        xor dx, dx                             ;reset dx and ax to use them for working (dx will contain the resulting number)
        xor ax, ax
        .loop:
            lodsb                              ;load ASCII character from inputed string SI into AL and increase SI
            test al, al                        ;end reading in if reached zero terminator
            jz .end


            push ax

            mov ax, 10
            mul dx

            mov dx, ax

            pop ax


            cmp al, '0'
                jl .error                      ;if character is less than 0x30 it can nott be a number or character
            cmp al, '9'
                jle .num                       ;if character is within the range of 0x30 and 0x39 it is a number
            jmp .error                         ;if it is not a number or a hex character => error
            .num:
                sub al, '0'                    ;subtract 0x30 from ASCII number to get value
                jmp .continue
            .continue:
            add dx, ax                         ;lastResult = (lastResult * 16) + currentNumber;
            jmp .loop	                       ;loop to the next character
        xor ax, ax
        cmp ax, 1                              ;ax != 1 => zero flag not set
        jmp .end
        .error:
            xor dx, dx
            test dx, dx                        ;dx == 0 => zero flag set
        .end:
        mov [decimal_value], dl
        pop bx
        pop cx
        pop dx
        pop si                                 ;restore si and ax
        pop ax
        ret

    ;------------------------------------------------------

    shellprompt db 'command:',0
    shellresult db 'answer->',0

    read_sector db 'sector->',0
    read_track db 'track->',0
    read_head db 'head->',0
    drive_number db 'drive_nr->',0
    input_string db 'data->',0
    about_prompt db 'about->',0

    quote db '"', 0
    birdYpos dw 0
    UpperPillarHeight db 25
    LowerPillarHeight db 25
    SpaceBetweenPillars db 60
    FlappyBirdScore dw 0

    input_sector_value db 0
    input_track_value db 0
    input_head_value db 0

    decimal_value db 0

    draw_command db 'flappy', 0
    read_command db 'read', 0
    write_command db 'write', 0

    clear_command db 'clear', 0
    about_command db 'about', 0

    %define readString_size 32                  ;maximum amount of characters

    main:        
        mov ah,0x03         ; set value for change to cursor position
        mov bh,0x00         ; page
        int 0x10      

        mov cx,1
        mov bl, 0x0F

    jmp .fresh_line

    .read_from_floppy:
            xor al, al
            stosb                              ;zero terminate string by adding a \0 to it
            mov di, .read_sector_buffer                    ;set output to buffer beginning

            mov ah, 0
            int 0x13 ; 0x13 ah=0 dl = drive number

        mov si, .read_drive_buffer
        call hexstr2num
            mov dl, [decimal_value]

            mov bx, 5C00h
            mov es, bx
            
            mov bx, 7C00h     ; bx = address to write the kernel to
            mov al, 4 		   ; al = amount of sectors to read
  
        mov si, .read_track_buffer
        call hexstr2num
            mov ch, [decimal_value]          ; cylinder/track = 0

        mov si, .read_head_buffer
        call hexstr2num
            mov dh, [decimal_value]         ; head           = 0

        mov si, .read_sector_buffer
        call hexstr2num
            mov cl, [decimal_value]          ; sector         = 2

            mov ah, 2          ; ah = 2: read from drive
            int 0x13   		   
            jmp 5C00h:7C00h
        
    .write_to_floppy:
            xor al, al
            stosb                              ;zero terminate string by adding a \0 to it
            mov di, .read_sector_buffer                    ;set output to buffer beginning

            mov ah, 0
            int 0x13 ; 0x13 ah=0 dl = drive number

        mov si, .read_drive_buffer
        call hexstr2num
            mov dl, [decimal_value]
        
            mov bx, .write_string_buffer     ; bx = address to write the kernel to
            mov al, 2 		   ; al = amount of sectors to read

        mov si, .read_track_buffer
        call hexstr2num
            mov ch, [decimal_value]          ; cylinder/track = 0

        mov si, .read_head_buffer
        call hexstr2num
            mov dh, [decimal_value]         ; head           = 0

        mov si, .read_sector_buffer
        call hexstr2num
            mov cl, [decimal_value]          ; sector         = 2

            mov ah, 3          ; ah = 3: write to drive
            int 0x13   		   
    jmp main

    .read_sector_buffer resb (readString_size+1)
    .read_track_buffer resb (readString_size+1)
    .read_head_buffer resb (readString_size+1)
    .read_drive_buffer resb (readString_size+1)

    .write_string_buffer resb (readString_size+1)

    .about:
        
        .about_read:
            pusha ; save registers

            mov ah, 0
            int 0x13 ; 0x13 ah=0 dl = drive number
            mov dl, 0

            mov bx, 0xE000     ; bx = address to write the read info to
            mov al, 1		   ; al = amount of sectors to read
            mov ch, 8          ; cylinder/track = 0
            mov dh, 0         ; head           = 0
            mov cl, 14          ; sector         = 2
            mov ah, 2          ; ah = 2: read from drive
            int 0x13 

            jmp .about_new_line  		        
                

        .prepare_ouput:
            mov ah, 0x0E
            mov si, 0xE000
            mov bl, 0x0F

            jmp .inner_about
                  
        .about_new_line:
            popa  ;restore registers

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dh
            mov dl,0x00
            int 0x10      

            mov ah, 0x0E
            mov si, about_prompt
            mov bl, 0x0F

            jmp .aboutprompt

            .aboutprompt:
                lodsb                ; get character from string
                cmp al, 0                    ; cmp al with end of string
                je .prepare_ouput               ; if char is zero, end of string

                mov ah, 0x09
                int 0x10                     ; otherwise, print it

                mov ah,0x02         ; set value for change to cursor position
                mov bh,0x00         ; page
                inc dl
                int 0x10   

                jmp .aboutprompt        ; jmp to .sectorprompt if not 0 

        .inner_about:    
            lodsb                ; get character from string
            cmp al, 0                    ; cmp al with end of string
            je .fresh_line               ; if char is zero, end of string

            mov ah, 0x09
            int 0x10                     ; otherwise, print it

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10   

            jmp .inner_about        ; jmp to .sectorprompt if not 0 


	.fresh_line:
        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dh
        mov dl,0x00
        int 0x10      

        mov ah, 0x0E
        mov si, shellprompt
        mov bl, 0x0F

        jmp .commandprompt


    .new_line_track:
        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dh
        mov dl,0x00
        int 0x10      
        
        mov ah, 0x0E
        mov si, read_track
        mov bl, 0x0F

        jmp .track_prompt

    .new_line_drive:
        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dh
        mov dl,0x00
        int 0x10      
        
        mov ah, 0x0E
        mov si, drive_number
        mov bl, 0x0F

        jmp .driveprompt

    .new_line_input:
        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dh
        mov dl,0x00
        int 0x10      
        
        mov ah, 0x0E
        mov si, input_string
        mov bl, 0x0F

        jmp .inputprompt

    .inputprompt:
        lodsb                ; get character from string
        cmp al, 0                    ; cmp al with end of string
        je .input_data_loop               ; if char is zero, end of string

        mov ah, 0x09
        int 0x10                     ; otherwise, print it

        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dl
        int 0x10   

        jmp .inputprompt        ; jmp to .sectorprompt if not 0 

    .input_data_loop:
        mov di, .write_string_buffer

        .input_data_inner:
            mov ax,0x00
            int 0x16

            mov bl, 3

            cmp ah, 0x1C             ; compare input is enter(1C) or not
            je .write_to_floppy

            cmp al, 0x08
            je .input_data_backspace

            stosb                ;store character into buffer and increase di
            
            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            int 0x10          

            mov ah, 0x09             ;display input char
            int 0x10

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10    
        jmp .input_data_inner

        .input_data_backspace:

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            dec dl
            int 0x10   

            mov ah, 0x09             ;display input char
            mov al, 0x20
            int 0x10

            cmp di, .write_string_buffer                    ;if di is at index 0 do not remove character as it is already at the beginning
            jle .input_data_inner
            dec di                             ;remove a character by moving one index back
            jmp .input_data_inner

        jmp .input_data_inner

    .new_line_head:
        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dh
        mov dl,0x00
        int 0x10      

        mov ah, 0x0E
        mov si, read_head
        mov bl, 0x0F

        jmp .headprompt

    .new_line_sector:
        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dh
        mov dl,0x00
        int 0x10      

        mov ah, 0x0E
        mov si, read_sector
        mov bl, 0x0F

        jmp .sectorprompt

    .driveprompt:
        lodsb                ; get character from string
        cmp al, 0                    ; cmp al with end of string
        je .input_drive_loop               ; if char is zero, end of string

        mov ah, 0x09
        int 0x10                     ; otherwise, print it

        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dl
        int 0x10   

        jmp .driveprompt        ; jmp to .sectorprompt if not 0 

    .input_drive_loop:
        mov di, .read_drive_buffer

        .drive_inner:
            mov ax,0x00
            int 0x16

            mov bl, 3

            cmp ah, 0x1C             ; compare input is enter(1C) or not
            je .new_line_track

            cmp al, 0x08
            je .drive_backspace

            stosb                ;store character into buffer and increase di
            
            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            int 0x10          

            mov ah, 0x09             ;display input char
            int 0x10

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10    
        jmp .drive_inner

        .drive_backspace:

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            dec dl
            int 0x10   

            mov ah, 0x09             ;display input char
            mov al, 0x20
            int 0x10

            cmp di, .read_drive_buffer                    ;if di is at index 0 do not remove character as it is already at the beginning
            jle .drive_inner
            dec di                             ;remove a character by moving one index back
            jmp .drive_inner

    .sectorprompt:
        lodsb                ; get character from string
        cmp al, 0                    ; cmp al with end of string
        je .input_sector_loop               ; if char is zero, end of string

        mov ah, 0x09
        int 0x10                     ; otherwise, print it

        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dl
        int 0x10   

        jmp .sectorprompt        ; jmp to .sectorprompt if not 0 

    .input_sector_loop:
        mov di, .read_sector_buffer

        .sector_inner:
            mov ax,0x00
            int 0x16

            mov bl, 3

            cmp ah, 0x1C             ; compare input is enter(1C) or not
            je .check_if_write

            cmp al, 0x08
            je .sector_backspace

            stosb                ;store character into buffer and increase di
            
            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            int 0x10          

            mov ah, 0x09             ;display input char
            int 0x10

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10    
        jmp .sector_inner

        .check_if_write:
            mov di, .buffer

            mov si, write_command

            call stringCompare

            jz .new_line_input

            jmp .read_from_floppy

        .sector_backspace:

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            dec dl
            int 0x10   

            mov ah, 0x09             ;display input char
            mov al, 0x20
            int 0x10

            cmp di, .read_sector_buffer                    ;if di is at index 0 do not remove character as it is already at the beginning
            jle .sector_inner
            dec di                             ;remove a character by moving one index back
            jmp .sector_inner

        jmp .sector_inner

    .track_prompt:
        lodsb                ; get character from string
        cmp al, 0                    ; cmp al with end of string
        je .input_track_loop               ; if char is zero, end of string

        mov ah, 0x09
        int 0x10                     ; otherwise, print it

        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dl
        int 0x10   

        jmp .track_prompt        ; jmp to .sectorprompt if not 0 

    .input_track_loop:
        mov di, .read_track_buffer

        .track_inner:
            mov ax,0x00
            int 0x16

            mov bl, 3

            cmp ah, 0x1C             ; compare input is enter(1C) or not
            je .new_line_head

            cmp al, 0x08
            je .track_backspace

            stosb                ;store character into buffer and increase di
            
            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            int 0x10          

            mov ah, 0x09             ;display input char
            int 0x10

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10    
        jmp .track_inner

        .track_backspace:

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            dec dl
            int 0x10   

            mov ah, 0x09             ;display input char
            mov al, 0x20
            int 0x10

            cmp di, .read_track_buffer                    ;if di is at index 0 do not remove character as it is already at the beginning
            jle .track_inner
            dec di                             ;remove a character by moving one index back
            jmp .track_inner

        jmp .track_inner

    .headprompt:
        lodsb                ; get character from string
        cmp al, 0                    ; cmp al with end of string
        je .input_head_loop               ; if char is zero, end of string

        mov ah, 0x09
        int 0x10                     ; otherwise, print it

        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dl
        int 0x10   

        jmp .headprompt        ; jmp to .sectorprompt if not 0 

    .input_head_loop:
        mov di, .read_head_buffer

        .head_inner:
            mov ax,0x00
            int 0x16

            mov bl, 3

            cmp ah, 0x1C             ; compare input is enter(1C) or not
            je .new_line_sector

            cmp al, 0x08
            je .head_backspace

            stosb                ;store character into buffer and increase di
            
            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            int 0x10          

            mov ah, 0x09             ;display input char
            int 0x10

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10    
        jmp .head_inner

        .head_backspace:

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            dec dl
            int 0x10   

            mov ah, 0x09             ;display input char
            mov al, 0x20
            int 0x10

            cmp di, .read_head_buffer                    ;if di is at index 0 do not remove character as it is already at the beginning
            jle .head_inner
            dec di                             ;remove a character by moving one index back
            jmp .head_inner


    .commandprompt:
        lodsb                ; get character from string
        cmp al, 0                    ; cmp al with end of string
        je .inputLoop               ; if char is zero, end of string

        mov ah, 0x09
        int 0x10                     ; otherwise, print it

        mov ah,0x02         ; set value for change to cursor position
        mov bh,0x00         ; page
        inc dl
        int 0x10   

        jmp .commandprompt        ; jmp to .commandprompt if not 0   
        

    .inputLoop:
        mov di, .buffer

        .inner:
            mov ax,0x00
            int 0x16

            mov bl, 3

            cmp ah, 0x1C             ; compare input is enter(1C) or not
            je .check_for_command

            cmp al, 0x08
            je .backspace

            stosb                ;store character into buffer and increase di
            
            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            int 0x10          

            mov ah, 0x09             ;display input char
            int 0x10

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            inc dl
            int 0x10    
        jmp .inner

        .backspace:

            mov ah,0x02         ; set value for change to cursor position
            mov bh,0x00         ; page
            dec dl
            int 0x10   

            mov ah, 0x09             ;display input char
            mov al, 0x20
            int 0x10

            cmp di, .buffer                    ;if di is at index 0 do not remove character as it is already at the beginning
            jle .inner
            dec di                             ;remove a character by moving one index back
            jmp .inner

        jmp .inner
        

    .buffer resb (readString_size+1)
        
    .exitLoop:
        ret      

;------------------------------------------------------  

    .check_for_command:

        xor al, al
        stosb                              ;zero terminate string by adding a \0 to it
        mov di, .buffer                    ;set output to buffer beginning

        mov si, draw_command

        call stringCompare

        jz .draw_command_caught
        
        mov si, read_command

        call stringCompare

        jz .new_line_drive

        mov si, write_command

        call stringCompare

        jz .new_line_drive

        mov si, clear_command

        call stringCompare

        jz .set_text_mode

        mov si, about_command

        call stringCompare

        jz .about

    jmp .fresh_line
    

    .draw_command_caught:
        mov ax,0x13         ;clears the screen
        int 0x10            ;call bios video interrupt

        mov bl, 0           

        mov cx, 0
        mov [FlappyBirdScore], cx
        
        mov cx, 30          ;x pos
        mov dx, 30          ;y pos

        mov al, 3          ;color

        jmp .Draw

    .set_text_mode:
        mov ah, 0x00
        mov al, 3
        mov dx, 0
        int 0x10

        jmp main

    .wait_for_video_input:
        mov ah,0x01
        int 0x16
        jz .moveDown

        mov ah,0x00
        int 0x16
        
        cmp ah, 0x1C             ; compare input is enter(1C) or not
        je .set_text_mode           

        cmp al, 0x77            ; compare input is w or not
        je .move_up     

        cmp ax, 0  
        je .moveDown

    .moveDown:
        mov al, 0
        mov ah, 86h
        mov dx, 60000
        mov cx, 0
        int 15h             ;gravity
        
        mov ax,0x13         ;clears the screen
        int 0x10            ;call bios video interrupt

        call .printScore

        mov dx, [birdYpos]
        mov cx, 30
        inc dx
        mov al, 3

        mov bl, 0

        jmp .DrawBird

    .printScore:

        mov ah, 02  ; set cursor
            mov bh, 0x00
            mov dl, 2
            mov dh, 2
        int 0x10
        
        mov ax, [FlappyBirdScore]
            mov bl, 10
            div bl
            
            mov cl, ah

            add al, 48

            mov ah, 0x0E
            mov bh, 0x00
        int 0x10

        mov ah, 02  ; set cursor
            mov bh, 0x00
            mov dl, 3
            mov dh, 2
        int 0x10

        mov al, cl
            mov ah, 0x0E
            add al, 48
        int 0x10

        ret

    .check_for_collision1:
        cmp cx, 10
        je .check_for_collision2
        jmp .wait_for_video_input
        
    .check_for_collision2:
        movzx cx, [UpperPillarHeight]
        cmp [birdYpos], cx
        jle .set_text_mode

        add cx, 60
        cmp [birdYpos], cx
        jge .set_text_mode

        jmp .wait_for_video_input
        
    .move_up:

        mov al, 0
        mov ah, 86h
        mov dx, 60000
        mov cx, 0
        int 15h             ;gravity

        mov ax,0x13         ;clears the screen
        int 0x10            ;call bios video interrupt

        call .printScore

        mov dx, [birdYpos]
        mov cx, 30
        sub dx, 20
        mov al, 3

        mov bl, 0

        jmp .DrawBird
    .DrawBird:
        .Draw:
            mov ah,0x0C        ; set value for writing pixel
            mov bh,0x00        ; page

            inc cx     
            int 0x10

            cmp bl, 10
            je .Draw2

            inc bl
            
            jmp .Draw

        .Draw2:
            inc dx     
            int 0x10
                            
            cmp bl, 20
            je .Draw3

            inc bl

            jmp .Draw2

        .Draw3:
            dec cx     
            int 0x10
                                                    
            cmp bl, 30
            je .Draw4

            inc bl

            jmp .Draw3

        .Draw4:
            dec dx     
            int 0x10

            cmp bl, 40
            je .Draw5

            inc bl

            jmp .Draw4

        .Draw5:
            inc cx     

            cmp bl, 47
            je .Draw6

            inc bl

            jmp .Draw5

        .Draw6:
            inc dx     

            cmp bl, 50
            je .Draw7

            inc bl

            jmp .Draw6

        .Draw7:
            mov al, 0x0E
            int 0x10    

            jmp .Draw8

        .Draw8:
            dec cx     

            cmp bl, 56
            je .Draw9

            inc bl

            jmp .Draw8

        .Draw9:
            dec dx
            dec cx     
            int 0x10

            cmp bl, 60
            je .Draw10

            inc bl

            jmp .Draw9

        .Draw10:
            inc cx     
            add dx, 2
            int 0x10
            
            cmp bl, 63
            je .Draw11

            inc bl

            jmp .Draw10

        .Draw11:
            sub cx, 2     
            dec dx
            int 0x10
            
            cmp bl, 66
            je .Draw12

            inc bl

            jmp .Draw11

        .Draw12:
            add cx, 2    
            int 0x10
            
            cmp bl, 69
            je .DrawUpperPillar
            
            inc bl

            jmp .Draw12

    .DrawUpperPillar:
        mov [birdYpos], dx

        mov dx, 0
        mov bl, 0
        
        pop cx
        cmp cx, 10
        jl .ifpillarreachedend
        
        mov al, 2
        sub cx, 5
        push cx

        jmp .DrawUpperPillar2

        .ifpillarreachedend:            
            mov cx, 300
            mov al, 2
            push cx

            mov ah, 02  ; set cursor
            mov bh, 0x00
            mov dh, 2
            mov ch, 2
            int 0x10

            call .printScore
            
            mov ax, [FlappyBirdScore]
            inc ax
            mov [FlappyBirdScore], ax
            
            mov ah, 00
            int 0x1A

            mov cx, 300

            shr dl, 1   ;shift random byte right

            mov bl, dl  
            mov [UpperPillarHeight], bl

            mov bl, 0

            mov dx, 0

            jmp .DrawUpperPillar2


        .DrawUpperPillar2:
            mov ah,0x0C        ; set value for writing pixel
            mov bh,0x00        ; page

            inc dx    
            int 0x10

            cmp bl, [UpperPillarHeight]
            je .DrawLowerPillar

            inc bl
            
            jmp .DrawUpperPillar2
    
    .DrawLowerPillar:            
        mov dx, 200

        mov bl, 200
        sub bl, [UpperPillarHeight]
        sub bl, [SpaceBetweenPillars]

        mov [LowerPillarHeight], bl

        mov bl, 0   

        jmp .DrawLowerPillar2


    .DrawLowerPillar2:
        mov ah,0x0C        ; set value for writing pixel
        mov bh,0x00        ; page

        dec dx    
        int 0x10

        cmp bl, [LowerPillarHeight]
        je .check_for_collision1

        inc bl
            
        jmp .DrawLowerPillar2
        


