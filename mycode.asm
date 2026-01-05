.MODEL SMALL

.STACK 100H

.DATA
    ; Menu strings
    menu1 DB 10,13,'========================================$'
    menu2 DB 10,13,'    SIM REGISTRATION MACHINE$'
    menu3 DB 10,13,'========================================$'
    menu4 DB 10,13,'1. Registration (NID + Fingerprint)$'
    menu5 DB 10,13,'2. Customize SIM Number$'
    menu6 DB 10,13,'3. Buy New SIM Card$'
    menu7 DB 10,13,'4. Check My SIMs Count$'
    menu8 DB 10,13,'5. Exit$'
    menu9 DB 10,13,'========================================$'
    menu10 DB 10,13,'Enter your choice: $'
    
    ; Messages
    msg_nid DB 10,13,'Enter NID (10 digits): $'
    msg_fingerprint DB 10,13,'Enter Fingerprint Password (4 digits): $'
    msg_success DB 10,13,'Registration Successful!$'
    msg_failed DB 10,13,'Registration Failed! Invalid credentials.$'
    msg_sim_count DB 10,13,'You have $'
    msg_sim_count2 DB ' SIM(s) registered.$'
    msg_max_reached DB 10,13,'Maximum limit reached! You can only have 8 SIMs.$'
    msg_customize DB 10,13,'Enter last 3 digits to customize: $'
    msg_available DB 10,13,'SIM number is available!$'
    msg_not_available DB 10,13,'SIM number is not available.$'
    msg_buy_sim DB 10,13,'Buying new SIM card...$'
    msg_invalid DB 10,13,'Invalid choice!$'
    msg_newline DB 10,13,'$'
    
    ; SIM number array (6-digit numbers stored as double words)
    sim_numbers DD 123456, 234567, 345678, 456789, 567890, 678901, 789012, 890123, 901234, 102345
    sim_count DW 10  ; Total available SIM numbers
    
    ; User data
    current_nid DB 11 DUP(0)  ; Store current user's NID
    current_fp DB 5 DUP(0)   ; Store current user's fingerprint password
    user_sim_stack DD 8 DUP(0)  ; Stack to store user's SIM numbers (max 8) - 32-bit
    user_sim_count DW 0      ; Count of user's SIMs
    
    ; Temporary variables
    temp_input DB 12 DUP(0)
    temp_num DW 0
    temp_digits DB 4 DUP(0)
    
.CODE
MAIN PROC
    ; Initialize DS
    MOV AX, @DATA
    MOV DS, AX
    
    ; Main menu loop
MAIN_MENU:
    CALL DISPLAY_MENU
    CALL GET_CHOICE
    
    CMP AL, '1'
    JE REGISTRATION
    CMP AL, '2'
    JE CUSTOMIZE_SIM
    CMP AL, '3'
    JE BUY_SIM
    CMP AL, '4'
    JE CHECK_SIMS
    CMP AL, '5'
    JE EXIT_PROGRAM
    
    ; Invalid choice
    LEA DX, msg_invalid
    MOV AH, 09H
    INT 21H
    JMP MAIN_MENU

REGISTRATION:
    CALL REGISTER_USER
    JMP MAIN_MENU

CUSTOMIZE_SIM:
    CALL CUSTOMIZE_SIM_NUMBER
    JMP MAIN_MENU

BUY_SIM:
    CALL BUY_NEW_SIM
    JMP MAIN_MENU

CHECK_SIMS:
    CALL CHECK_SIM_COUNT
    JMP MAIN_MENU

EXIT_PROGRAM:
    MOV AX, 4C00H
    INT 21H

MAIN ENDP

; Display main menu
DISPLAY_MENU PROC
    PUSH AX
    PUSH DX
    
    LEA DX, menu1
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu2
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu3
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu4
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu5
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu6
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu7
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu8
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu9
    MOV AH, 09H
    INT 21H
    
    LEA DX, menu10
    MOV AH, 09H
    INT 21H
    
    POP DX
    POP AX
    RET
DISPLAY_MENU ENDP

; Get user choice
GET_CHOICE PROC
    MOV AH, 01H
    INT 21H
    RET
GET_CHOICE ENDP

; Registration with NID and Fingerprint
REGISTER_USER PROC
    PUSH AX
    PUSH DX
    PUSH SI
    
    ; Get NID
    LEA DX, msg_nid
    MOV AH, 09H
    INT 21H
    
    LEA SI, current_nid
    MOV CX, 10
READ_NID:
    MOV AH, 01H
    INT 21H
    CMP AL, 0DH  ; Enter key
    JE NID_DONE
    MOV [SI], AL
    INC SI
    LOOP READ_NID
NID_DONE:
    MOV BYTE PTR [SI], 0
    
    ; Get Fingerprint Password
    LEA DX, msg_fingerprint
    MOV AH, 09H
    INT 21H
    
    LEA SI, current_fp
    MOV CX, 4
READ_FP:
    MOV AH, 01H
    INT 21H
    CMP AL, 0DH  ; Enter key
    JE FP_DONE
    MOV [SI], AL
    INC SI
    LOOP READ_FP
FP_DONE:
    MOV BYTE PTR [SI], 0
    
    ; Simple verification (for demo, accept any 10-digit NID and 4-digit password)
    LEA DX, msg_success
    MOV AH, 09H
    INT 21H
    
    POP SI
    POP DX
    POP AX
    RET
REGISTER_USER ENDP

; Customize SIM number (last 3 digits)
CUSTOMIZE_SIM_NUMBER PROC
    PUSH AX
    PUSH DX
    PUSH SI
    PUSH BX
    PUSH CX
    PUSH DI
    
    ; Check if user has registered
    CMP current_nid[0], 0
    JE NOT_REGISTERED
    
    ; Check if user has any SIMs
    CMP user_sim_count, 0
    JE NO_SIMS
    
    ; Get last 3 digits
    LEA DX, msg_customize
    MOV AH, 09H
    INT 21H
    
    ; Read 3 digits
    MOV CX, 3
    MOV BX, 0  ; Will store the 3-digit number
READ_DIGITS:
    MOV AH, 01H
    INT 21H
    CMP AL, 0DH
    JE DIGITS_DONE
    SUB AL, '0'
    CMP AL, 9
    JG DIGITS_DONE
    CMP AL, 0
    JL DIGITS_DONE
    
    ; Build number: BX = BX * 10 + AL
    PUSH AX
    MOV AX, BX
    MOV DX, 10
    MUL DX
    MOV BX, AX
    POP AX
    MOV AH, 0
    ADD BX, AX
    LOOP READ_DIGITS
DIGITS_DONE:
    
    ; Check if number is available (last 3 digits should be 000-999)
    CMP BX, 999
    JG NOT_AVAILABLE_CUSTOM
    
    ; Get the last SIM number from stack
    MOV SI, user_sim_count
    DEC SI
    SHL SI, 1
    MOV AX, user_sim_stack[SI]
    
    ; Modify last 3 digits: keep first 3 digits, replace last 3
    MOV DX, 0
    MOV CX, 1000
    DIV CX  ; AX = first 3 digits, DX = last 3 digits
    MOV CX, 1000
    MUL CX  ; AX = first 3 digits * 1000
    ADD AX, BX  ; Add new last 3 digits
    
    ; Check if this number already exists
    CALL CHECK_NUMBER_EXISTS
    CMP AX, 1
    JE NOT_AVAILABLE_CUSTOM
    
    ; Update the SIM number in stack
    MOV SI, user_sim_count
    DEC SI
    SHL SI, 1
    MOV user_sim_stack[SI], AX
    
    LEA DX, msg_available
    MOV AH, 09H
    INT 21H
    
    ; Display new SIM number
    PUSH AX
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    POP AX
    CALL DISPLAY_NUMBER
    LEA DX, msg_success
    MOV AH, 09H
    INT 21H
    
    JMP CUSTOM_DONE
    
NOT_AVAILABLE_CUSTOM:
    LEA DX, msg_not_available
    MOV AH, 09H
    INT 21H
    JMP CUSTOM_DONE
    
NOT_REGISTERED:
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    JMP CUSTOM_DONE
    
NO_SIMS:
    LEA DX, msg_not_available
    MOV AH, 09H
    INT 21H
    
CUSTOM_DONE:
    POP DI
    POP CX
    POP BX
    POP SI
    POP DX
    POP AX
    RET
CUSTOMIZE_SIM_NUMBER ENDP

; Check if SIM number is available
CHECK_AVAILABILITY PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    
    ; For simplicity, just show available message
    LEA DX, msg_available
    MOV AH, 09H
    INT 21H
    
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
CHECK_AVAILABILITY ENDP

; Check if number exists in user's SIM stack
; Input: AX = number to check
; Output: AX = 1 if exists, 0 if not
CHECK_NUMBER_EXISTS PROC
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DX
    
    MOV CX, user_sim_count
    CMP CX, 0
    JE NOT_FOUND
    
    MOV SI, 0
CHECK_LOOP:
    MOV BX, SI
    SHL BX, 1
    MOV DX, user_sim_stack[BX]
    CMP DX, AX
    JE FOUND
    INC SI
    LOOP CHECK_LOOP
    
NOT_FOUND:
    MOV AX, 0
    JMP CHECK_DONE_EXISTS
    
FOUND:
    MOV AX, 1
    
CHECK_DONE_EXISTS:
    POP DX
    POP SI
    POP CX
    POP BX
    RET
CHECK_NUMBER_EXISTS ENDP

; Buy new SIM card
BUY_NEW_SIM PROC
    PUSH AX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BX
    PUSH CX
    
    ; Check if user has registered
    CMP current_nid[0], 0
    JE NOT_REGISTERED_BUY
    
    ; Check if user has reached maximum (8 SIMs)
    CMP user_sim_count, 8
    JGE MAX_REACHED
    
    ; Verify fingerprint
    LEA DX, msg_fingerprint
    MOV AH, 09H
    INT 21H
    
    LEA SI, temp_input
    MOV CX, 4
READ_FP_VERIFY:
    MOV AH, 01H
    INT 21H
    CMP AL, 0DH
    JE FP_VERIFY_DONE
    MOV [SI], AL
    INC SI
    LOOP READ_FP_VERIFY
FP_VERIFY_DONE:
    MOV BYTE PTR [SI], 0
    
    ; Verify fingerprint password
    LEA SI, current_fp
    LEA DI, temp_input
    MOV CX, 4
VERIFY_LOOP:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE FP_VERIFY_FAILED
    INC SI
    INC DI
    LOOP VERIFY_LOOP
    
    ; Verification successful
    JMP FP_VERIFY_SUCCESS
    
FP_VERIFY_FAILED:
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    JMP BUY_DONE
    
FP_VERIFY_SUCCESS:
    
    ; Select random SIM from array
    CALL SELECT_RANDOM_SIM
    
    ; Add to user's stack
    MOV BX, user_sim_count
    SHL BX, 1  ; Multiply by 2 (word size)
    MOV user_sim_stack[BX], AX  ; Store SIM number
    
    ; Increment count
    INC user_sim_count
    
    LEA DX, msg_buy_sim
    MOV AH, 09H
    INT 21H
    
    ; Display SIM number
    PUSH AX
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    MOV AH, 02H
    MOV DL, 'S'
    INT 21H
    MOV DL, 'I'
    INT 21H
    MOV DL, 'M'
    INT 21H
    MOV DL, ':'
    INT 21H
    MOV DL, ' '
    INT 21H
    POP AX
    CALL DISPLAY_NUMBER
    LEA DX, msg_success
    MOV AH, 09H
    INT 21H
    
    JMP BUY_DONE
    
NOT_REGISTERED_BUY:
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    JMP BUY_DONE
    
MAX_REACHED:
    LEA DX, msg_max_reached
    MOV AH, 09H
    INT 21H
    
BUY_DONE:
    POP CX
    POP BX
    POP DI
    POP SI
    POP DX
    POP AX
    RET
BUY_NEW_SIM ENDP

; Select random SIM from array
SELECT_RANDOM_SIM PROC
    PUSH BX
    PUSH CX
    PUSH SI
    
    ; Simple selection: use current count as index
    MOV BX, user_sim_count
    CMP BX, sim_count
    JL VALID_INDEX
    MOV BX, 0  ; Reset if exceeds array size
VALID_INDEX:
    SHL BX, 1  ; Multiply by 2 (word size)
    MOV AX, sim_numbers[BX]  ; Get SIM number
    
    POP SI
    POP CX
    POP BX
    RET
SELECT_RANDOM_SIM ENDP

; Display number (AX contains the number)
DISPLAY_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10
    MOV CX, 0
    
    ; Convert to string and push to stack
CONVERT_LOOP:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE CONVERT_LOOP
    
    ; Pop and display
DISPLAY_LOOP:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP DISPLAY_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_NUMBER ENDP

; Check SIM count
CHECK_SIM_COUNT PROC
    PUSH AX
    PUSH DX
    
    ; Check if user has registered
    CMP current_nid[0], 0
    JE NOT_REGISTERED_CHECK
    
    LEA DX, msg_sim_count
    MOV AH, 09H
    INT 21H
    
    ; Display count
    MOV AX, user_sim_count
    CALL DISPLAY_NUMBER
    
    LEA DX, msg_sim_count2
    MOV AH, 09H
    INT 21H
    
    JMP CHECK_DONE
    
NOT_REGISTERED_CHECK:
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    
CHECK_DONE:
    POP DX
    POP AX
    RET
CHECK_SIM_COUNT ENDP

END MAIN
