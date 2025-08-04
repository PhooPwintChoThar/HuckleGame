@ Name: Phoo Pwint Cho Thar
@ Student ID: 67011755
@ Date: 4/8/2025
@ This program implements the Hurkle game where a player tries to find a hidden Hurkle on a 10x10 grid within 10 guesses.


.global _start

@ Constants for random number generation
.equ GRID_SIZE, 10
.equ LCG_A, 1103515245        @ Multiplier for LCG (from glibc)
.equ LCG_C, 12345             @ Increment for LCG
.equ LCG_M, 2147483648        @ Modulus (2^31 for long period)

.section .data
    @ Random number generation variables
    urandom_path:   .asciz "/dev/urandom"
    random_seed_buffer: .space 4      @ 4 bytes for 32-bit seed
    prng_state:     .word 0           @ Store LCG state
    
    @ Game  variables
    hurkle_x:       .word 0         @ Hurkle's X coordinate (0-9)
    hurkle_y:       .word 0         @ Hurkle's Y coordinate (0-9)
    guess_count:    .word 0         @ Number of guesses made
    player_x:       .word 0         @ Player's X guess
    player_y:       .word 0         @ Player's Y guess
    
    @ String constants
    prompt:         .asciz "Enter X Y: "
    win_msg1:       .asciz "You found the Hurkle in "
    win_msg2:       .asciz " guesses!\n"
    lose_msg1:      .asciz "You ran out of guesses! The Hurkle was at ("
    lose_msg2:      .asciz ","
    lose_msg3:      .asciz ")\n"
    too_high:       .asciz "↑ Too high!\n"
    too_low:        .asciz "↓ Too low!\n"  
    too_left:       .asciz "← Too far left!\n"
    too_right:      .asciz "→ Too far right!\n"
    close_msg:      .asciz "You are very close!\n"
    newline:        .asciz "\n"
    
    @ Input buffer
    input_buffer:   .space 16       @ Buffer for user input
    num_buffer:     .space 12       @ Buffer for number to string conversion

.section .text

@---------------
@ Main program entry point
@---------------
_start:
    bl initialize_game              @ Set up the game
    bl game_loop                   @ Run the main game loop
    
    @ Exit program
    mov r0, #0                     @ Exit status
    mov r7, #1                     @ sys_exit
    swi 0                          @ System call

@---------------
@ initialize_game: Sets up the game state
@ Input: None
@ Output: None
@ Modifies: r0, r1, r2
@---------------
initialize_game:
    push {lr}                      @ Save return address
    
    @ Initialize random number generator
    bl init_random
    cmp r0, #-1
    beq init_game_error           @ If random init failed, use fallback
    
    @ Generate random X coordinate (0-9)
    bl generate_one_random_number
    ldr r1, =hurkle_x
    str r0, [r1]                  @ Store hurkle_x
    
    @ Generate random Y coordinate (0-9)
    bl generate_one_random_number
    ldr r1, =hurkle_y
    str r0, [r1]                  @ Store hurkle_y
    
    b init_game_done
    
init_game_error:
    @ Fallback to simple values if /dev/urandom fails
    ldr r0, =hurkle_x
    mov r1, #5
    str r1, [r0]
    ldr r0, =hurkle_y
    mov r1, #3
    str r1, [r0]
    
init_game_done:
    @ Initialize guess count to 0
    ldr r0, =guess_count
    mov r1, #0
    str r1, [r0]
    
    pop {pc}                      @ Return

@---------------
@ game_loop: Main game loop - continues until win or lose
@ Input: None
@ Output: None
@ Modifies: r0, r1, r2, r3
@---------------
game_loop:
    push {lr}
    
game_loop_start:
    @ Check if we've reached max guesses (10)
    ldr r0, =guess_count
    ldr r1, [r0]
    cmp r1, #10
    bge game_lost                 @ Branch if >= 10 guesses
    
    @ Increment guess count
    add r1, r1, #1
    str r1, [r0]
    
    @ Get player's guess
    bl get_player_guess
    
    @ Check if player found the Hurkle
    ldr r0, =player_x
    ldr r1, [r0]
    ldr r0, =hurkle_x
    ldr r2, [r0]
    cmp r1, r2
    bne check_feedback            @ X coordinates don't match
    
    ldr r0, =player_y
    ldr r1, [r0]
    ldr r0, =hurkle_y
    ldr r2, [r0]
    cmp r1, r2
    beq game_won                  @ Y coordinates also match - game won!
    
check_feedback:
    @ Provide feedback to player
    bl process_feedback
    b game_loop_start             @ Continue the game loop
    
game_won:
    @ Print win message with guess count
    ldr r0, =win_msg1
    bl print_string
    
    ldr r0, =guess_count
    ldr r0, [r0]
    bl int_to_str
    ldr r0, =num_buffer
    bl print_string
    
    ldr r0, =win_msg2
    bl print_string
    
    pop {pc}                      @ Return to main
    
game_lost:
    @ Print lose message with Hurkle location
    ldr r0, =lose_msg1
    bl print_string
    
    ldr r0, =hurkle_x
    ldr r0, [r0]
    bl int_to_str
    ldr r0, =num_buffer
    bl print_string
    
    ldr r0, =lose_msg2
    bl print_string
    
    ldr r0, =hurkle_y
    ldr r0, [r0]
    bl int_to_str
    ldr r0, =num_buffer
    bl print_string
    
    ldr r0, =lose_msg3
    bl print_string
    
    pop {pc}                      @ Return to main

@---------------
@ get_player_guess: Prompts user and reads X Y coordinates
@ Input: None
@ Output: Sets player_x and player_y variables
@ Modifies: r0, r1, r2, r3
@---------------
get_player_guess:
    push {lr}
    
    @ Print prompt
    ldr r0, =prompt
    bl print_string
    
    @ Read input from user
    mov r0, #0                    @ stdin
    ldr r1, =input_buffer         @ Buffer address
    mov r2, #16                   @ Buffer size
    mov r7, #3                    @ sys_read
    swi 0
    
    @ Parse the input - extract two single digits
    ldr r0, =input_buffer
    
    @ Find first digit (skip any spaces)
find_first_digit:
    ldrb r1, [r0]
    cmp r1, #' '
    addeq r0, r0, #1
    beq find_first_digit
    
    @ Convert first digit from ASCII to integer
    sub r1, r1, #'0'              @ Convert ASCII to number
    ldr r2, =player_x
    str r1, [r2]                  @ Store player_x
    
    @ Move to next character
    add r0, r0, #1
    
    @ Find second digit (skip spaces)
find_second_digit:
    ldrb r1, [r0]
    cmp r1, #' '
    addeq r0, r0, #1
    beq find_second_digit
    cmp r1, #'\n'
    beq find_second_digit
    cmp r1, #'\t'
    addeq r0, r0, #1
    beq find_second_digit
    
    @ Convert second digit from ASCII to integer
    sub r1, r1, #'0'              @ Convert ASCII to number
    ldr r2, =player_y
    str r1, [r2]                  @ Store player_y
    
    pop {pc}                      @ Return

@---------------
@ process_feedback: Analyzes guess and provides directional/proximity hints
@ Input: Uses player_x, player_y, hurkle_x, hurkle_y variables
@ Output: Prints appropriate feedback messages
@ Modifies: r0, r1, r2, r3, r4, r5
@---------------
process_feedback:
    push {lr}
    
    @ Load coordinates for comparison
    ldr r0, =player_x
    ldr r1, [r0]                  @ r1 = player_x (GX)
    ldr r0, =player_y  
    ldr r2, [r0]                  @ r2 = player_y (GY)
    ldr r0, =hurkle_x
    ldr r3, [r0]                  @ r3 = hurkle_x (HX)
    ldr r0, =hurkle_y
    ldr r4, [r0]                  @ r4 = hurkle_y (HY)
    
    @ Check Y coordinate - Too high/low
    cmp r2, r4
    bgt print_too_high            @ GY > HY
    blt print_too_low             @ GY < HY
    b check_x_coord
    
print_too_high:
    ldr r0, =too_high
    bl print_string
    b check_x_coord
    
print_too_low:
    ldr r0, =too_low
    bl print_string
    
check_x_coord:
    @ Check X coordinate - Too left/right
    cmp r1, r3
    blt print_too_left            @ GX < HX
    bgt print_too_right           @ GX > HX
    b check_proximity
    
print_too_left:
    ldr r0, =too_left
    bl print_string
    b check_proximity
    
print_too_right:
    ldr r0, =too_right
    bl print_string
    
check_proximity:
    @ Calculate Manhattan distance: |GX - HX| + |GY - HY|
    @ Calculate |GX - HX|
    sub r0, r1, r3                @ GX - HX
    cmp r0, #0
    rsblt r0, r0, #0              @ Get absolute value
    
    @ Calculate |GY - HY|
    sub r5, r2, r4                @ GY - HY
    cmp r5, #0
    rsblt r5, r5, #0              @ Get absolute value
    
    @ Sum the distances
    add r0, r0, r5                @ Manhattan distance
    
    @ Check if distance <= 2
    cmp r0, #2
    ble print_close
    
    pop {pc}                      @ Return
    
print_close:
    ldr r0, =close_msg
    bl print_string
    pop {pc}                      @ Return

@---------------
@ print_string: Prints a null-terminated string
@ Input: r0 = address of null-terminated string
@ Output: None
@ Modifies: r0, r1, r2, r7
@---------------
print_string:
    push {lr}
    push {r0}                     @ Save string address
    
    @ Calculate string length
    mov r1, r0                    @ Copy string address
    mov r2, #0                    @ Length counter
    
strlen_loop:
    ldrb r3, [r1, r2]             @ Load byte at position r2
    cmp r3, #0                    @ Check for null terminator
    beq strlen_done
    add r2, r2, #1                @ Increment counter
    b strlen_loop
    
strlen_done:
    @ Print the string
    mov r0, #1                    @ stdout
    pop {r1}                      @ Restore string address
    @ r2 already contains length
    mov r7, #4                    @ sys_write
    swi 0
    
    pop {pc}                      @ Return

@---------------
@ int_to_str: Converts an integer to a string
@ Input: r0 = integer to convert
@ Output: Stores result in num_buffer
@ Modifies: r0, r1, r2, r3, r4
@---------------
int_to_str:
    push {r4, lr}
    
    ldr r1, =num_buffer           @ Buffer address
    add r1, r1, #10               @ Start from end of buffer
    mov r2, #0                    @ Null terminator
    strb r2, [r1]                 @ Store null terminator
    mov r4, r1                    @ Save buffer end position
    
    cmp r0, #0                    @ Check if number is 0
    beq store_zero
    
convert_loop:
    cmp r0, #0
    beq convert_done
    
    @ Simple division by 10
    mov r3, r0                    @ Save original number
    mov r2, #0                    @ Quotient
    mov r1, #10                   @ Divisor
    
divide_by_10:
    cmp r0, r1
    blt division_done
    sub r0, r0, r1
    add r2, r2, #1
    b divide_by_10
    
division_done:
    @ r0 now contains remainder, r2 contains quotient
    add r0, r0, #'0'              @ Convert remainder to ASCII
    sub r4, r4, #1                @ Move back in buffer
    strb r0, [r4]                 @ Store digit
    mov r0, r2                    @ Set up for next iteration
    b convert_loop
    
store_zero:
    sub r4, r4, #1
    mov r2, #'0'
    strb r2, [r4]
    
convert_done:
    @ Copy result to start of buffer
    ldr r2, =num_buffer
    mov r1, r4                    @ Start from where we ended
copy_loop:
    ldrb r3, [r1]
    strb r3, [r2]
    cmp r3, #0
    beq copy_done
    add r1, r1, #1
    add r2, r2, #1
    b copy_loop
    
copy_done:
    pop {r4, pc}                  @ Return

@---------------
@ init_random: Reads 4 bytes from /dev/urandom to seed the PRNG
@ Input: None
@ Output: 0 on success, -1 on error in r0
@ Modifies: r0, r1, r2, r4
@---------------
init_random:
    push {r4, lr}
    
    @ Open /dev/urandom
    ldr r0, =urandom_path         @ Filename pointer
    mov r1, #0                    @ O_RDONLY
    mov r2, #0                    @ Mode
    mov r7, #5                    @ SYS_OPEN
    svc 0
    mov r4, r0                    @ Store file descriptor
    cmp r4, #0
    blt init_error                @ If negative, error
    
    @ Read 4 bytes for seed
    mov r0, r4
    ldr r1, =random_seed_buffer
    mov r2, #4
    mov r7, #3                    @ SYS_READ
    svc 0
    cmp r0, #4
    bne close_and_error           @ If read didn't return 4, error
    
    @ Close /dev/urandom
    mov r0, r4
    mov r7, #6                    @ SYS_CLOSE
    svc 0
    
    @ Load 4-byte seed and store in prng_state
    ldr r1, =random_seed_buffer
    ldr r0, [r1]                  @ Load 32-bit random value
    ldr r1, =prng_state
    str r0, [r1]                  @ Initialize PRNG state
    mov r0, #0                    @ Success
    pop {r4, pc}

close_and_error:
    mov r0, r4
    mov r7, #6                    @ SYS_CLOSE
    svc 0
init_error:
    mov r0, #-1
    pop {r4, pc}

@---------------
@ generate_one_random_number: Generates a single random number between 0-9
@ Input: None
@ Output: Random number (0-9) in r0
@ Modifies: r0, r1, r2, r3, r4
@---------------
generate_one_random_number:
    push {r4, lr}
    
    ldr r4, =prng_state
    ldr r0, [r4]                  @ r0 = current state
    
    @ Apply LCG: state = (a * state + c) mod m
    ldr r1, =LCG_A                @ r1 = a
    mul r2, r0, r1                @ r2 = a * state
    ldr r1, =LCG_C                @ r1 = c
    add r2, r2, r1                @ r2 = a * state + c
    ldr r1, =LCG_M                @ r1 = m
    udiv r3, r2, r1               @ r3 = quotient
    mls r2, r3, r1, r2            @ r2 = (a * state + c) mod m
    
    @ Store new state
    str r2, [r4]                  @ Update prng_state
    
    @ Rejection sampling for uniform [0-9]
    mov r1, #2147483640           @ Largest multiple of 10 <= LCG_M
    cmp r2, r1
    bge generate_one_random_number @ Retry if r2 >= 2147483640
    
    mov r1, #GRID_SIZE            @ r1 = 10
    udiv r3, r2, r1               @ r3 = quotient
    mls r0, r3, r1, r2            @ r0 = remainder (0-9)
    
    pop {r4, pc}
