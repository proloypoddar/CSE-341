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
    menu8 DB 10,13,'5. Show Available SIM Numbers$'
    menu9 DB 10,13,'6. Exit$'
    menu10 DB 10,13,'========================================$'
    menu11 DB 10,13,'Enter your choice: $'
    
    ; Messages
    msg_nid DB 10,13,'Enter NID (10 digits): $'
    msg_fingerprint DB 10,13,'Enter Fingerprint Password (4 digits): $'
    msg_success DB 10,13,'Registration Successful!$'
    msg_failed DB 10,13,'Registration Failed! Invalid credentials.$'
    msg_sim_count DB 10,13,'You have $'
    msg_sim_count2 DB ' SIM(s) registered.$'
    msg_max_reached DB 10,13,'Maximum limit reached! You can only have 8 SIMs.$'
    msg_customize DB 10,13,'Enter last 4 digits to customize (017XXXX): $'
    msg_customize_help DB 10,13,'Enter 4 digits (0000-9999): $'
    msg_available DB 10,13,'SIM number is available!$'
    msg_not_available DB 10,13,'SIM number is not available.$'
    msg_buy_sim DB 10,13,'Buying new SIM card...$'
    msg_invalid DB 10,13,'Invalid choice!$'
    msg_newline DB 10,13,'$'
    msg_registered_nid DB 10,13,'Your Registered NID: $'
    msg_available_sims DB 10,13,'Available SIM Numbers:$'
    msg_comma DB ', $'
    
    ; Input buffers for buffered input (INT 21H, AH=0AH)
    nid_buffer DB 11, 0, 11 DUP(0)  ; Max 10 chars + null terminator
    fp_buffer DB 5, 0, 5 DUP(0)     ; Max 4 chars + null terminator
    
    ; SIM number array (7-digit numbers starting with 017, stored as double words)
    ; Format: 017XXXX where XXXX is 4 random digits
    ; Stored as decimal: 171234, 175678, etc.
    sim_numbers DD 171234, 175678, 179012, 173456, 177890, 172345, 176789, 170123, 174567, 178901
    sim_count DW 10  ; Total available SIM numbers
    
    ; User data
    current_nid DB 11 DUP(0)  ; Store current user's NID
    current_fp DB 5 DUP(0)   ; Store current user's fingerprint password
    user_sim_stack DD 8 DUP(0)  ; Stack to store user's SIM numbers (max 8) - 32-bit
    user_sim_count DW 0      ; Count of user's SIMs
    customized_sim DD 0      ; Store customized SIM number for next purchase
    has_customized DB 0      ; Flag: 1 if user has customized a number
    
    ; Temporary variables
    temp_input DB 12 DUP(0)
    temp_num DW 0
    temp_digits DB 5 DUP(0)  ; For 4-digit customization input
    customize_buffer DB 6, 0, 6 DUP(0)  ; Buffer for 4-digit customization input
    
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
    JE SHOW_AVAILABLE
    CMP AL, '6'
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

SHOW_AVAILABLE:
    CALL SHOW_AVAILABLE_SIMS
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
    
    LEA DX, menu11
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
    PUSH DI
    
    ; Get NID using buffered input
    LEA DX, msg_nid
    MOV AH, 09H
    INT 21H
    
    ; Read NID (10 digits) using buffered input
    LEA DX, nid_buffer
    MOV AH, 0AH
    INT 21H
    
    ; Copy from buffer to current_nid (skip first 2 bytes: length and actual length)
    LEA SI, nid_buffer
    INC SI  ; Skip max length byte
    MOV CL, [SI]  ; Get actual length
    MOV CH, 0
    INC SI  ; Point to actual data
    LEA DI, current_nid
    
    ; Copy the NID
    CMP CX, 0
    JE NID_COPY_DONE
COPY_NID:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_NID
NID_COPY_DONE:
    MOV BYTE PTR [DI], 0  ; Null terminator
    
    ; Get Fingerprint Password using buffered input
    LEA DX, msg_fingerprint
    MOV AH, 09H
    INT 21H
    
    ; Read fingerprint password (4 digits) using buffered input
    LEA DX, fp_buffer
    MOV AH, 0AH
    INT 21H
    
    ; Copy from buffer to current_fp
    LEA SI, fp_buffer
    INC SI  ; Skip max length byte
    MOV CL, [SI]  ; Get actual length
    MOV CH, 0
    INC SI  ; Point to actual data
    LEA DI, current_fp
    
    ; Copy the password
    CMP CX, 0
    JE FP_COPY_DONE
COPY_FP:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_FP
FP_COPY_DONE:
    MOV BYTE PTR [DI], 0  ; Null terminator
    
    ; Display success message
    LEA DX, msg_success
    MOV AH, 09H
    INT 21H
    
    ; Display registered NID
    LEA DX, msg_registered_nid
    MOV AH, 09H
    INT 21H
    
    LEA DX, current_nid
    MOV AH, 09H
    INT 21H
    
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
    POP DI
    POP SI
    POP DX
    POP AX
    RET
REGISTER_USER ENDP

; Customize SIM number (last 4 digits)
; User enters 4 digits, we check if 017XXXX is available
CUSTOMIZE_SIM_NUMBER PROC
    PUSH AX
    PUSH DX
    PUSH SI
    PUSH BX
    PUSH CX
    PUSH DI
    
    ; Check if user has registered
    CMP current_nid[0], 0
    JE NOT_REGISTERED_CUSTOM
    
    ; Check if user has reached maximum (8 SIMs)
    CMP user_sim_count, 8
    JGE MAX_REACHED_CUSTOM
    
    ; Get last 4 digits using buffered input
    LEA DX, msg_customize
    MOV AH, 09H
    INT 21H
    
    LEA DX, customize_buffer
    MOV AH, 0AH
    INT 21H
    
    ; Validate input: must be exactly 4 digits
    LEA SI, customize_buffer
    INC SI  ; Skip max length byte
    MOV CL, [SI]  ; Get actual length
    MOV CH, 0
    
    ; Check if exactly 4 digits
    CMP CX, 4
    JNE INVALID_INPUT_CUSTOM
    
    ; Validate all characters are digits (0-9)
    INC SI  ; Point to actual data
    MOV DI, SI
    MOV CX, 4
VALIDATE_DIGITS:
    MOV AL, [DI]
    CMP AL, '0'
    JL INVALID_INPUT_CUSTOM
    CMP AL, '9'
    JG INVALID_INPUT_CUSTOM
    INC DI
    LOOP VALIDATE_DIGITS
    
    ; Convert 4-digit string to number
    MOV BX, 0  ; Will store the 4-digit number
    MOV CX, 4
    LEA SI, customize_buffer
    ADD SI, 2  ; Point to actual data
CONVERT_TO_NUMBER:
    MOV AL, [SI]
    SUB AL, '0'
    MOV AH, 0
    
    ; BX = BX * 10 + AL
    PUSH AX
    MOV AX, BX
    MOV DX, 10
    MUL DX
    MOV BX, AX
    POP AX
    ADD BX, AX
    
    INC SI
    LOOP CONVERT_TO_NUMBER
    
    ; Build full SIM number: 017XXXX = 170000 + XXXX
    MOV AX, 170000
    ADD AX, BX
    MOV DX, 0  ; High word is 0 for numbers < 65536
    
    ; Check if this number already exists in user's SIMs
    CALL CHECK_NUMBER_EXISTS
    CMP AX, 1
    JE NOT_AVAILABLE_CUSTOM
    
    ; Also check if number is in valid range (170000-179999)
    CMP AX, 170000
    JL INVALID_INPUT_CUSTOM
    CMP AX, 179999
    JG INVALID_INPUT_CUSTOM
    
    ; Number is available! Store it for next purchase
    ; We'll store it in a temporary location or use the last slot
    ; Actually, let's just mark it as available and use it when buying
    
    LEA DX, msg_available
    MOV AH, 09H
    INT 21H
    
    ; Display the customized SIM number
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    MOV AH, 02H
    MOV DL, '0'
    INT 21H
    MOV DL, '1'
    INT 21H
    MOV DL, '7'
    INT 21H
    ; Display the 4 digits
    LEA SI, customize_buffer
    ADD SI, 2
    MOV CX, 4
DISPLAY_CUSTOM_DIGITS:
    MOV DL, [SI]
    MOV AH, 02H
    INT 21H
    INC SI
    LOOP DISPLAY_CUSTOM_DIGITS
    
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_success
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
    ; Store the customized number for next purchase
    MOV WORD PTR customized_sim, AX      ; Store low word
    MOV WORD PTR customized_sim+2, DX    ; Store high word
    MOV has_customized, 1  ; Set flag
    
    JMP CUSTOM_DONE
    
INVALID_INPUT_CUSTOM:
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    JMP CUSTOM_DONE
    
NOT_AVAILABLE_CUSTOM:
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_not_available
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    JMP CUSTOM_DONE
    
NOT_REGISTERED_CUSTOM:
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    JMP CUSTOM_DONE
    
MAX_REACHED_CUSTOM:
    LEA DX, msg_max_reached
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
; Input: DX:AX = 32-bit number to check
; Output: AX = 1 if exists, 0 if not
CHECK_NUMBER_EXISTS PROC
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH BP
    
    ; Save the number to check (input: DX:AX)
    MOV DI, AX  ; Save low word in DI
    MOV BP, DX  ; Save high word in BP
    
    MOV CX, user_sim_count
    CMP CX, 0
    JE NOT_FOUND
    
    MOV SI, 0
CHECK_LOOP:
    MOV BX, SI
    SHL BX, 2  ; Multiply by 4 (double word)
    
    ; Compare low word
    MOV AX, WORD PTR user_sim_stack[BX]
    CMP AX, DI  ; Compare with saved low word
    JNE NEXT_CHECK
    
    ; Compare high word
    MOV AX, WORD PTR user_sim_stack[BX+2]
    CMP AX, BP  ; Compare with saved high word
    JE FOUND
    
NEXT_CHECK:
    INC SI
    LOOP CHECK_LOOP
    
NOT_FOUND:
    MOV AX, 0
    JMP CHECK_DONE_EXISTS
    
FOUND:
    MOV AX, 1
    
CHECK_DONE_EXISTS:
    POP BP
    POP DI
    POP SI
    POP CX
    POP BX
    RET
CHECK_NUMBER_EXISTS ENDP

; Check if number exists in available SIM array
; Input: DX:AX = 32-bit number to check
; Output: AX = 1 if exists, 0 if not
CHECK_IN_AVAILABLE_ARRAY PROC
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH BP
    
    ; Save the number to check (input: DX:AX)
    MOV DI, AX  ; Save low word in DI
    MOV BP, DX  ; Save high word in BP
    
    MOV CX, sim_count
    CMP CX, 0
    JE NOT_FOUND_ARRAY
    
    MOV SI, 0
CHECK_ARRAY_LOOP:
    MOV BX, SI
    SHL BX, 2  ; Multiply by 4 (double word)
    
    ; Compare low word
    MOV AX, WORD PTR sim_numbers[BX]
    CMP AX, DI  ; Compare with saved low word
    JNE NEXT_ARRAY_CHECK
    
    ; Compare high word
    MOV AX, WORD PTR sim_numbers[BX+2]
    CMP AX, BP  ; Compare with saved high word
    JE FOUND_ARRAY
    
NEXT_ARRAY_CHECK:
    INC SI
    LOOP CHECK_ARRAY_LOOP
    
NOT_FOUND_ARRAY:
    MOV AX, 0
    JMP CHECK_ARRAY_DONE
    
FOUND_ARRAY:
    MOV AX, 1
    
CHECK_ARRAY_DONE:
    POP BP
    POP DI
    POP SI
    POP CX
    POP BX
    RET
CHECK_IN_AVAILABLE_ARRAY ENDP

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
    
    ; Verify fingerprint using buffered input
    LEA DX, msg_fingerprint
    MOV AH, 09H
    INT 21H
    
    ; Read fingerprint password using buffered input
    LEA DX, fp_buffer
    MOV AH, 0AH
    INT 21H
    
    ; Copy from buffer to temp_input for comparison
    LEA SI, fp_buffer
    INC SI  ; Skip max length byte
    MOV CL, [SI]  ; Get actual length
    MOV CH, 0
    INC SI  ; Point to actual data
    LEA DI, temp_input
    
    ; Copy the password
    CMP CX, 0
    JE FP_VERIFY_DONE
COPY_FP_VERIFY:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_FP_VERIFY
FP_VERIFY_DONE:
    MOV BYTE PTR [DI], 0  ; Null terminator
    
    ; Verify fingerprint password
    LEA SI, current_fp
    LEA DI, temp_input
VERIFY_LOOP:
    MOV AL, [SI]
    CMP AL, 0  ; Check if end of string
    JE VERIFY_SUCCESS_CHECK
    MOV BL, [DI]
    CMP BL, 0  ; Check if end of string
    JE FP_VERIFY_FAILED
    CMP AL, BL
    JNE FP_VERIFY_FAILED
    INC SI
    INC DI
    JMP VERIFY_LOOP
    
VERIFY_SUCCESS_CHECK:
    ; Check if both strings ended at the same time
    CMP BYTE PTR [DI], 0
    JNE FP_VERIFY_FAILED
    
    ; Verification successful
    JMP FP_VERIFY_SUCCESS
    
FP_VERIFY_FAILED:
    LEA DX, msg_failed
    MOV AH, 09H
    INT 21H
    JMP BUY_DONE
    
FP_VERIFY_SUCCESS:
    
    ; Check if user has customized a number
    CMP has_customized, 1
    JNE USE_RANDOM_SIM
    
    ; Use customized SIM number
    MOV AX, WORD PTR customized_sim      ; Low word
    MOV DX, WORD PTR customized_sim+2    ; High word
    
    ; Clear the customized flag
    MOV has_customized, 0
    MOV WORD PTR customized_sim, 0
    MOV WORD PTR customized_sim+2, 0
    
    JMP SIM_SELECTED
    
USE_RANDOM_SIM:
    ; Select random SIM from array
    CALL SELECT_RANDOM_SIM
    
SIM_SELECTED:
    
    ; Save SIM number for display later
    PUSH AX
    PUSH DX
    
    ; Add to user's stack (32-bit: DX:AX)
    MOV BX, user_sim_count
    SHL BX, 2  ; Multiply by 4 (double word size)
    MOV WORD PTR user_sim_stack[BX], AX      ; Store low word
    MOV WORD PTR user_sim_stack[BX+2], DX    ; Store high word
    
    ; Increment count
    INC user_sim_count
    
    LEA DX, msg_buy_sim
    MOV AH, 09H
    INT 21H
    
    ; Display SIM number in 017XXXX format
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
    POP DX  ; Restore DX for display
    POP AX  ; Restore AX for display
    CALL DISPLAY_SIM_NUMBER
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
; Returns 32-bit value in DX:AX
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
    SHL BX, 2  ; Multiply by 4 (double word size)
    MOV AX, WORD PTR sim_numbers[BX]      ; Get low word
    MOV DX, WORD PTR sim_numbers[BX+2]    ; Get high word
    
    POP SI
    POP CX
    POP BX
    RET
SELECT_RANDOM_SIM ENDP

; Display number (32-bit: DX:AX contains the number)
; For 6-digit numbers, DX will be 0, so we can simplify
DISPLAY_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; If DX (high word) is not 0, we need 32-bit division
    ; But for our 6-digit numbers (max 999999), DX should be 0
    ; So we can use AX directly
    CMP DX, 0
    JNE DISPLAY_32BIT
    
    ; 16-bit display (DX = 0)
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
    JMP DISPLAY_DONE
    
DISPLAY_32BIT:
    ; Handle 32-bit number (DX:AX)
    ; For numbers > 65535, use a simpler approach
    ; Store in temp and display digit by digit
    PUSH SI
    PUSH DI
    
    MOV SI, AX  ; Low word
    MOV DI, DX  ; High word
    MOV BX, 10
    MOV CX, 0
    
    ; Simple 32-bit to decimal conversion
    ; Divide by 10 repeatedly
CONVERT_32_LOOP:
    ; Check if we can do 16-bit division
    CMP DI, 0
    JE DIV_16BIT
    
    ; Need 32-bit division
    ; Approximation: for our range, this is rare
    ; Use repeated subtraction or proper 32-bit div
    MOV AX, DI
    MOV DX, 0
    DIV BX
    MOV DI, AX
    
    ; Calculate remainder contribution
    MOV AX, SI
    MOV DX, 0
    DIV BX
    MOV SI, AX
    PUSH DX
    INC CX
    
    CMP SI, 0
    JNE CONVERT_32_LOOP
    CMP DI, 0
    JNE CONVERT_32_LOOP
    JMP DISPLAY_32_START
    
DIV_16BIT:
    MOV AX, SI
    MOV DX, 0
    DIV BX
    MOV SI, AX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE CONVERT_32_LOOP
    
DISPLAY_32_START:
    ; Pop and display
DISPLAY_32_LOOP:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP DISPLAY_32_LOOP
    
    POP DI
    POP SI
    
DISPLAY_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_NUMBER ENDP

; Display SIM number in 017XXXX format
; Input: DX:AX = 32-bit number (should be 170000-179999)
DISPLAY_SIM_NUMBER PROC
    PUSH AX
    PUSH DX
    
    ; Display "017" prefix
    MOV AH, 02H
    MOV DL, '0'
    INT 21H
    MOV DL, '1'
    INT 21H
    MOV DL, '7'
    INT 21H
    
    ; The number is stored as 171234, we need to display last 4 digits
    ; So we extract last 4 digits: number % 10000
    POP DX
    POP AX
    PUSH AX
    PUSH DX
    
    ; For numbers 170000-179999, DX should be 0
    CMP DX, 0
    JNE DISPLAY_SIM_DONE
    
    ; Extract last 4 digits: AX % 10000
    MOV DX, 0
    MOV BX, 10000
    DIV BX  ; AX = first part, DX = last 4 digits
    
    ; Display last 4 digits with leading zeros if needed
    MOV AX, DX
    MOV BX, 10
    MOV CX, 0
    
    ; Convert to string and push to stack
CONVERT_SIM_LOOP:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE CONVERT_SIM_LOOP
    
    ; Pad with zeros if less than 4 digits
    CMP CX, 4
    JGE DISPLAY_SIM_DIGITS
PAD_ZEROS:
    PUSH 0
    INC CX
    CMP CX, 4
    JL PAD_ZEROS
    
DISPLAY_SIM_DIGITS:
    ; Pop and display
DISPLAY_SIM_LOOP:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP DISPLAY_SIM_LOOP
    
DISPLAY_SIM_DONE:
    POP DX
    POP AX
    RET
DISPLAY_SIM_NUMBER ENDP

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

; Show available SIM numbers
SHOW_AVAILABLE_SIMS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    LEA DX, msg_available_sims
    MOV AH, 09H
    INT 21H
    
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
    MOV CX, sim_count
    MOV SI, 0
    
SHOW_LOOP:
    ; Get SIM number from array (32-bit)
    MOV BX, SI
    SHL BX, 2  ; Multiply by 4 (double word)
    MOV AX, WORD PTR sim_numbers[BX]      ; Low word
    MOV DX, WORD PTR sim_numbers[BX+2]    ; High word
    
    ; Display the number in 017XXXX format
    CALL DISPLAY_SIM_NUMBER
    
    ; Check if this is the last number
    DEC CX
    CMP CX, 0
    JE SHOW_DONE
    
    ; Print comma and space
    LEA DX, msg_comma
    MOV AH, 09H
    INT 21H
    
    INC SI
    JMP SHOW_LOOP
    
SHOW_DONE:
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_AVAILABLE_SIMS ENDP

END MAIN
