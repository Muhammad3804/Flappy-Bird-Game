[org 0x0100]
jmp start

; Game data and variables
gameString: db '====== Flappy Bird ======Loading...'  ; Title screen text
deathPrint: db '     Flappy Died :(     '            ; Game over message
gameEnd: db 0                                         ; Flag to indicate game end (0=running, 1=ended)
birdPosition: dw 2000                                 ; Current position of the bird in video memory
upperBarPos: dw 148                                   ; Position of the top pipe/barrel
cloudPos: dw 380                                      ; Position of first cloud
cloud2Pos: dw 586                                     ; Position of second cloud
gamePauseMsg: db ' Game Paused. Press P to continue ' ; Pause screen message
barrelLocation: dw 9,2,10,15,4,8 ,12,6, 14, 3         ; Array of heights for the barrels/pipes
player1: db 'Player Score: '                          ; Score label text
playerScore: dw 0                                     ; Player's current score
isPaused: db 0                                        ; Pause state flag (0=not paused, 1=paused)

start:
	call clearScreen                                  ; Clear the screen at game start
	call printGameName                                ; Display the title screen
	mov cx, word[barrelLocation]                      ; Load first barrel height into cx
	mov si, 2                                         ; Initialize si for barrel height array index
	
    programEnd:                                       ; Main game loop
        call detectKeyInt                             ; Check for keyboard input
        cmp byte [isPaused], 1                        ; Check if game is paused
                je skipGameLogic                      ; Skip game logic processing if paused

        call printBackground                          ; Draw the game background
        call printClouds                              ; Draw clouds
		
		push cx                                       ; Save barrel height
        call printBarrel                              ; Draw the pipes/barrels
		
		; Logic to cycle through barrel heights
		cmp si, 8                                     ; Check if we've used all barrel heights
		jne dontResetsi                              
		xor si, si                                    ; Reset the barrel array index
		mov word[cloudPos], 380                       ; Reset first cloud position
		mov word[cloud2Pos], 586                      ; Reset second cloud position
		
		dontResetsi:
		cmp word[upperBarPos], 4                      ; Check if barrel has moved off-screen
		jae moveBarrelLeft                            ; If not, continue moving it left
		mov word[upperBarPos], 148                    ; Reset barrel position (right side)
		mov cx, word[barrelLocation+si]               ; Load next barrel height
		add si, 2                                     ; Increment barrel array index
		
		moveBarrelLeft:
        sub word[upperBarPos], 2                      ; Move barrel left by 2 screen units
		
		call printplayerScore                         ; Update and display score
        call printFlappy                              ; Draw the bird and handle collision
        call delay                                    ; Main game delay
        call delayShort                               ; Short delay for smoother animation

        skipGameLogic:                                ; Label to skip game logic when paused
        cmp byte[gameEnd], 1                          ; Check if game has ended
        jne programEnd                                ; If not, continue game loop
		call DeathScreen                              ; Display death screen when game ends
end:
    mov ax, 0x4c00                                    ; DOS interrupt to exit program
    int 0x21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FLAPPY BIRD PRINT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

printFlappy:
    pusha
        mov ax, 0xb800                                ; Set ES to point to video memory
        mov es, ax

        mov di, [birdPosition]                        ; Get bird position in video memory
        mov ax, 0x60d4                                ; Bird character and color (brown ◔)
        mov bx, 0x0adb                                ; Barrel/pipe character and color (green █)
        mov word [es:di], ax                          ; Draw the bird
        push di
        sub di, 2                                     ; Position to draw bird's wing/beak
        mov word [es:di], 0x06db                      ; Draw bird wing/beak (brown █)
        pop di

        ;;;;;;;;;;;;;;;; BIRD TOUCHING BARRELS ;;;;;;;;;;;;;;;;    
        ; Collision detection logic - checks if bird hits pipes
        mov di, [birdPosition]
        add di, 2                                     ; Check right side of bird
        cmp word[es:di], bx                           ; Is there a barrel?
        je gameBandKaro                               ; If collision, end game

        mov di, [birdPosition]
        add di, 160                                   ; Check below bird (next row)
        cmp word[es:di], bx                           ; Is there a barrel?
        je gameBandKaro                               ; If collision, end game

        mov di, [birdPosition]
        sub di, 160                                   ; Check above bird (previous row)
        cmp word[es:di], bx                           ; Is there a barrel?
        je gameBandKaro                               ; If collision, end game

        add word[birdPosition], 160                   ; Bird gravity - move down one row

        ;;;;;;;;;;;;;;;; BIRD TOUCHING GROUND ;;;;;;;;;;;;;;;;
        ; Check if bird hits the ground
        cmp word[birdPosition], 4000                  ; Is bird at/beyond ground level?
        jl printEnd                                   ; If not, continue
        mov byte[gameEnd], 1                          ; If yes, end game
        jmp printEnd

        gameBandKaro:                                 ; Game end routine for collision
            mov byte[gameEnd], 1                      ; Set game end flag

    printEnd:    
    popa
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; BARREL PRINT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

printBarrel:
    push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es

        mov ax, 0xb800                                ; Set ES to point to video memory
        mov es, ax
        mov di, word[upperBarPos]                     ; Current position of top pipe
        mov ax, 0x0adb                                ; Barrel/pipe character and color (green █)
        mov cx, [bp+4]                                ; Get barrel height from stack
		
        upperbarrelloop:                              ; Draw the upper pipe segment
            mov si, 5                                 ; Width of pipe (5 characters)
            innerloopUpper:                           ; Loop to draw one row of pipe
                mov word [es:di], ax                  ; Draw pipe segment
                add di, 2                             ; Move right
                sub si, 1
                cmp si, 0
                jne innerloopUpper
                add di, 150                           ; Move to next row (160-10 to account for width)
            loop upperbarrelloop                      ; Repeat for height of pipe
            sub di, 150
            push di                                   ; Save position for score detection
            mov word [es:di], 0x6add                  ; Draw pipe end cap with different color
            sub di, 12
            mov word [es:di], ax                      ; Draw left side of pipe

        ;;;;;;;;; LOWER BARREL ;;;;;;;;;;
            ; Logic for drawing bottom pipe with appropriate gap
			add di, 1280                              ; Create gap between pipes (8 rows down)
			mov word [es:di], ax                      ; Draw first segment of bottom pipe
			add di, 12                                ; Move to right side
			mov word [es:di], 0x6add                  ; Draw pipe end cap
			sub di, 10                                ; Position for drawing pipe width
		lowerbarrelloop:                              ; Draw the lower pipe segment
			mov si, 5                                 ; Width of pipe (5 characters)
			innerloopLower:                           ; Loop to draw one row of pipe
                mov word [es:di], ax
                add di, 2
                sub si, 1
                cmp si, 0
                jne innerloopLower
            add di, 150                               ; Move to next row
			cmp di, 4000                              ; Check if we've reached bottom of screen
			jbe lowerbarrelloop                       ; If not, continue drawing pipe down


        ;;;;;;; INVISIBLE BARREL FOR SCORING ;;;;;;;;;;
        ; Creates invisible detection area for scoring
        pop di 
        add di, 158                                   ; Position just past the pipe gap
        mov ax, 0x33de                                ; Invisible score trigger character
        mov cx, 7                                     ; Height of score detection area
        invisibleBARloop:
            mov word [es:di], ax                      ; Place invisible score trigger
            add di, 160                               ; Move down one row
            loop invisibleBARloop

        ; Score detection logic
        mov di, [birdPosition]
        sub di, 2                                     ; Check position in front of bird
        cmp word[es:di], 0x33de                       ; Did bird pass through score trigger?
        jne endCalcScore                              ; If not, skip scoring
        add word[playerScore], 1                      ; Increment score

    endCalcScore:
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
    pop bp
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GAME NAME / LOADING SCREEN / DEATH / PAUSE PRINT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

printGameName:
	pusha
		
		mov di, 1656                                  ; Position for game title (center screen)
		mov ax, 0xb800                                ; Set ES to point to video memory
		mov es, ax
		mov si, gameString                            ; Load game title string
		mov ah, 0x0C                                  ; Color attribute (light red)
		mov cx, 25                                    ; Length of title text
	
		gamenameLoop:                                 ; Loop to print game title
			lodsb                                     ; Load character from string
			stosw                                     ; Store character with attribute
			loop gamenameLoop
		
		mov cx, 10                                    ; Length of "Loading..." text
		mov ah, 0x07                                  ; Color attribute (light gray)
		mov di, 2312                                  ; Position for "Loading..." text
		loadingLoop:                                  ; Loop to print loading text
			lodsb                                     ; Load character from string
			stosw                                     ; Store character with attribute
			loop loadingLoop
				
		mov di, 2452                                  ; Position for loading bar background
		mov cx, 28                                    ; Width of loading bar
		mov ax, 0x07b0                                ; Loading bar background character
		rep stosw                                     ; Fill loading bar background
		
		mov di, 2452                                  ; Position for loading bar progress
		mov cx, 29                                    ; Width of loading bar
		mov ax, 0x07db                                ; Loading bar fill character
		l1:                                           ; Loop to animate loading bar
			call delay                                ; Delay for animation effect
			call delay
			call delay
			mov word[es:di], ax                       ; Draw loading bar segment
			add di, 2                                 ; Move to next position
			loop l1

	popa 
	ret

DeathScreen:
        pusha
        xor ax, ax
        mov ah, 0xf8                                  ; Color attribute (white on red background)
        mov di, 1976                                  ; Position for death message (center screen)
        mov si, deathPrint                            ; Load death message string
        mov cx, 24                                    ; Length of death message
        DeathMsgLoop:                                 ; Loop to print death message
            lodsb                                     ; Load character from string
            stosw                                     ; Store character with attribute
            loop DeathMsgLoop

    popa
    ret

PauseGameScreen:
        pusha

        xor ax, ax
        mov ah, 0x70                                  ; Color attribute (black on white background)
        mov di, 1966                                  ; Position for pause message (center screen)
        mov si, gamePauseMsg                          ; Load pause message string
        mov cx, 34                                    ; Length of pause message
        PauseMsgLoop:                                 ; Loop to print pause message
            lodsb                                     ; Load character from string
            stosw                                     ; Store character with attribute
            loop PauseMsgLoop

    popa
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DELAYS / CLS / BACKGROUND PRINT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delay:                                                ; Long delay function (double loop)
        pusha
        mov cx, 0xffff                                ; Maximum loop counter
        delayLoop:                                    ; First delay loop
            sub cx, 1
            jne delayLoop

            mov cx, 0xffff                            ; Maximum loop counter
        delayLoop2:                                   ; Second delay loop for extra delay
            sub cx, 1
            jne delayLoop2

        popa
        ret    

delayShort:                                           ; Short delay function (single loop)
        pusha
        mov cx, 0xffff                                ; Maximum loop counter
        delayShortLoop:                               ; Single delay loop
            sub cx, 1
            jne delayShortLoop
		popa
		ret

clearScreen:                                          ; Function to clear entire screen
    pusha

    xor di, di                                        ; Start at top-left of screen
    mov ax, 0xb800                                    ; Set ES to point to video memory
    mov es, ax
    mov ax, 0x0720                                    ; Space character with black background
    mov cx, 2000                                      ; Fill entire screen (80x25 characters)
    rep stosw                                         ; Repeat store word

    popa
    ret

;;;;;;; background ;;;;;;;;;

printBackground:                                      ; Function to draw game background
pusha 
        mov ax, 0xb800                                ; Set ES to point to video memory
        mov es, ax
        mov ax, 0x03db                                ; Sky color (blue █)
        xor di, di                                    ; Start at top of screen
        mov cx, 1840                                  ; Fill most of screen with sky
        rep stosw                                     ; Repeat store word

        mov ax, 0x02db                                ; Ground color (green █)
        mov di, 3680                                  ; Position for ground (bottom of screen)
        mov cx, 160                                   ; One row of ground (80 characters)
        rep stosw                                     ; Repeat store word

popa
ret

printClouds:                                          ; Function to draw and animate clouds
pusha 
        mov ax, 0xb800                                ; Set ES to point to video memory
        mov es, ax
        mov di, word[cloudPos]                        ; Position of first cloud
        mov ax, 0x07db                                ; Cloud character and color (light gray █)
        xor dx, dx                                    ; Initialize dx for cloud size

        mov cx, 3                                     ; Height of cloud
        sub word[cloudPos], 2                         ; Move cloud left for animation
        cloud1loop:                                   ; Draw first cloud
            add dx, 2                                 ; Increase cloud width for each row
            mov si, dx                                ; Set inner loop counter

            innerCloud1:                              ; Draw one row of cloud
                mov word[es:di], ax                   ; Draw cloud segment
                add di, 2                             ; Move right
                sub si, 1
                cmp si, 0
                jne innerCloud1

        mov di, word[cloud2Pos]                       ; Position of second cloud
        mov cx, 3                                     ; Height of cloud
        sub word[cloud2Pos], 2                        ; Move cloud left for animation
        cloud2loop:                                   ; Draw second cloud
            add dx, 2                                 ; Increase cloud width for each row
            mov si, dx                                ; Set inner loop counter

            innerCloud2:                              ; Draw one row of cloud
                mov word[es:di], ax                   ; Draw cloud segment
                add di, 2                             ; Move right
                sub si, 1
                cmp si, 0
                jne innerCloud2

            add di, 154                               ; Move to next row
            loop cloud2loop                           ; Repeat for cloud height

popa
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SCORE LOGIC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

printplayerScore:                                     ; Function to display player score
    pusha
        mov di, 162                                   ; Position for score (top-left)
        mov ax, 0xb800                                ; Set ES to point to video memory
        mov es, ax
        mov si, player1                               ; Load "Player Score: " string

        mov ah, 0x30                                  ; Color attribute (cyan)

        mov cx, 14                                    ; Length of score label
        p1Loop:                                       ; Loop to print score label
            lodsb                                     ; Load character from string
            stosw                                     ; Store character with attribute
            loop p1Loop    

		mov bx, 10                                    ; Base 10 for division
		mov ax, [playerScore]                         ; Load current score
		xor cx, cx                                    ; Clear digit counter

	pushNumbers:                                      ; Convert number to digits
		xor dx, dx
		div bx                                        ; Divide by 10, remainder is digit
		add dl, 0x30                                  ; Convert to ASCII
		push dx                                       ; Push digit on stack
		inc cx                                        ; Increment digit count
		test ax, ax                                   ; Check if more digits
		jnz pushNumbers                               ; If more digits, continue

	printNumbers:                                     ; Print digits in correct order
		pop ax                                        ; Get digit from stack
		mov ah, 0x30                                  ; Color attribute (cyan)
		mov word [es:di], ax                          ; Display digit
		add di, 2                                     ; Move to next position
		loop printNumbers                             ; Repeat for all digits

    popa 
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; KEY DETECT AND INTERRUPTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    detectKeyInt:                                     ; Function to detect keyboard input
        pusha
            xor si, si
            mov cx, 5                                 ; For loop counter
            xor ax, ax

            mov ah, 0x01                              ; BIOS keyboard service - check for key
            int 0x16                                  ; Keyboard interrupt
            jz noKeyDetected                          ; Jump if no key pressed

            mov ah, 0x00                              ; BIOS keyboard service - get key
            int 0x16                                  ; Keyboard interrupt

            cmp ah, 0x22                              ; Check for 'G' key (scan code)
            je endFlappy                              ; end game if 'G' pressed

            cmp al, 0x20                              ; Check for space key (ASCII)
            je jumpFlappy                             ; Make bird jump if space pressed

            cmp ah, 0x19                              ; Check for 'P' key (scan code)
            je PauseGame                              ; Toggle pause if 'P' pressed

            noKeyDetected:                            ; No key was pressed
                jmp endDetectKey                      ; End keyboard detection

            endFlappy:                                ; 'G' key was pressed
                mov byte[gameEnd], 1                  ; End game
                jmp endDetectKey                      ; End keyboard detection

            jumpFlappy:                               ; Space key was pressed
                sub word[birdPosition], 640           ; Move bird up 4 rows (jump)
                jmp endDetectKey                      ; End keyboard detection

            PauseGame:                                ; 'P' key was pressed
                    cmp byte[isPaused], 1             ; Check current pause state
                    call PauseGameScreen              ; Show pause message

                    mov al, [isPaused]
                    xor al, 1                         ; Toggle pause state (0->1, 1->0)
                    mov [isPaused], al
                    jmp endDetectKey                  ; End keyboard detection

        endDetectKey:
        popa
        ret