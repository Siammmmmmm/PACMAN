;=============================================================================
; PAC-MAN
;
; Controls:
;   WASD or arrow keys = Move Pac-Man
;   SPACE              = Start / restart
;   P key              = Pause (SW1 resumes)
;   SW1 (PF4)          = Toggle pause/resume
;=============================================================================

    .data

;--- ANSI color strings (null-terminated) ---
clr_reset:    .byte 27,'[','0','m',0
clr_wall:     .byte 27,'[','4','0','m',0
clr_corridor: .byte 27,'[','4','4','m',0
clr_pellet:   .byte 27,'[','4','4',';','3','7','m',0
clr_power:    .byte 27,'[','4','4',';','1',';','3','7','m',0
clr_score:    .byte 27,'[','1',';','3','2','m',0
clr_clear:    .byte 27,'[','2','J',27,'[','H',0
clr_hide_cur: .byte 27,'[','?','2','5','l',0
clr_pacman:   .byte 27,'[','4','4',';','1',';','9','3','m',0

; Four distinct ghost colors - one per ghost
clr_blinky:   .byte 27,'[','4','4',';','1',';','3','1','m',0  ; bold red
clr_pinky:    .byte 27,'[','4','4',';','1',';','3','5','m',0  ; bold magenta
clr_inky:     .byte 27,'[','4','4',';','1',';','3','6','m',0  ; bold cyan
clr_clyde:    .byte 27,'[','4','4',';','3','8',';','5',';','2','1','4','m',0  ; light orange
clr_ghost_f:  .byte 27,'[','4','4',';','1',';','9','2','m',0  ; bold neon green (frightened)

;--- UI strings ---
str_score:  .string "SCORE: ", 0
str_lives:  .string "   LIVES: ", 0
str_press:  .string "Press SPACE to start", 0
str_over:   .string "GAME OVER", 0
str_win:    .string "YOU WIN!", 0
str_pause:  .string "PAUSED-SW1 to resume", 0
str_level:  .string "   LEVEL: ", 0

;--- Game state ---
    .align 4
score:        .word 0
lives:        .byte 4
paused:       .byte 0
; game_started values:
;   0 = waiting for SPACE (title screen / post game-over)
;   1 = running normally
;   2 = RESPAWNING - board is being redrawn after death, timer must skip
game_started: .byte 0
game_over:    .byte 0
level:        .byte 1
dots_left:    .word 0

;--- Pac-Man ---
pacman_row:   .byte 27
pacman_col:   .byte 12
pacman_dir:   .byte 0           ; 0=none 1=up 2=down 3=left 4=right
pacman_next:  .byte 0

;--- Ghost data: 6 bytes x 4 ghosts ---
; Layout: [row, col, dir, home_row, home_col, mode]
; dir:  1=up 2=down 3=left 4=right
; mode: 0=waiting 1=chase 2=frightened
ghost_data:
    .byte 11,13, 1, 11,13, 1   ; Blinky (red)    row=11 col=13 dir=up mode=chase
    .byte 11,14, 1, 11,14, 1   ; Pinky (magenta) row=11 col=14 dir=up mode=chase
    .byte 13,12, 1, 13,12, 1   ; Inky (cyan)     row=13 col=12 dir=up mode=chase
    .byte 13,15, 1, 13,15, 1   ; Clyde (yellow)  row=13 col=15 dir=up mode=chase

ghost_eaten_count: .byte 0     ; ghosts eaten this power pellet
power_timer:       .byte 0     ; ticks remaining for power mode
tick_count:        .byte 0     ; game tick counter (0-99)

led_table:    .byte 0x00, 0x01, 0x03, 0x07, 0x0F  ; idx = lives count


; Independent LFSR seeds - each ghost gets its own 16-bit RNG
rng_g0: .short 0xACE1          ; Blinky seed
rng_g1: .short 0x4321          ; Pinky seed
rng_g2: .short 0x7FFF          ; Inky seed
rng_g3: .short 0x1357          ; Clyde seed

    .align 4
cursor_buf: .space 16

;--- Maze (RAM, modified during play) ---
maze_data:
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','O','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','O','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','.','#'
    .byte '#','.','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','.','#'
    .byte '#','.','.','.','.','.','.','#','#','.','.','.','.','#','#','.','.','.','.','#','#','.','.','.','.','.','.','#'
    .byte '#','#','#','#','#','#','.','#','#','#','#','#',' ','#','#',' ','#','#','#','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#','#','#','#',' ','#','#',' ','#','#','#','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ','#','#','#',' ',' ','#','#','#',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ','#',' ',' ',' ',' ',' ',' ','#',' ','#','#','.','#','#','#','#','#','#'
    .byte ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
    .byte '#','#','#','#','#','#','.','#','#',' ','#','#','#','#','#','#','#','#',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ','#','#','#','#','#','#','#','#',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','O','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#','#','.','.','O','#'
    .byte '#','#','.','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','.','#','#','#'
    .byte '#','#','.','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','.','#','#','#'
    .byte '#','.','.','.','.','.','#','#','.','.','.','.','.','#','#','.','.','.','.','#','#','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#'
    .byte '#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'


;--- ROM template (never modified - used by reset_maze) ---
maze_rom:
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','O','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','O','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','.','#'
    .byte '#','.','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','.','#'
    .byte '#','.','.','.','.','.','.','#','#','.','.','.','.','#','#','.','.','.','.','#','#','.','.','.','.','.','.','#'
    .byte '#','#','#','#','#','#','.','#','#','#','#','#',' ','#','#',' ','#','#','#','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#','#','#','#',' ','#','#',' ','#','#','#','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ','#','#','#',' ',' ','#','#','#',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ','#',' ',' ',' ',' ',' ',' ','#',' ','#','#','.','#','#','#','#','#','#'
    .byte ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
    .byte '#','#','#','#','#','#','.','#','#',' ','#','#','#','#','#','#','#','#',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','.','#','#',' ','#','#','#','#','#','#','#','#',' ','#','#','.','#','#','#','#','#','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','.','#','#','#','#','.','#','#','#','#','#','.','#','#','.','#','#','#','#','#','.','#','#','#','#','.','#'
    .byte '#','O','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#','#','.','.','O','#'
    .byte '#','#','.','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','.','#','#','#'
    .byte '#','#','.','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','.','#','#','#'
    .byte '#','.','.','.','.','.','#','#','.','.','.','.','.','#','#','.','.','.','.','#','#','.','.','.','.','.','.','#'
    .byte '#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#'
    .byte '#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#'
    .byte '#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'
    .byte '#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'


msg_paused:  .string 13,10,"[PAUSED]",13,10,0

    .text

    .global pacman
    .global Timer_Handler
    .global Switch_Handler
    .global UART0_Handler
    .global illuminate_LED
    .global uart_init
    .global output_character
    .global output_string
    .global simple_read_character
    .global read_string
    .global illuminate_RGB_LED

MAZE_COLS    .equ 28
MAZE_ROWS    .equ 33
BOARD_ROW    .equ 2
BOARD_COL    .equ 4
HOUSE_ROW_T  .equ 11
HOUSE_ROW_B  .equ 16
HOUSE_COL_L  .equ 9
HOUSE_COL_R  .equ 18

PUR     .equ 0x510   ; pull-up select
DIR     .equ 0x400   ; direction (1=output)
DEN     .equ 0x51C   ; digital enable
DATA    .equ 0x3FC   ; data reg, all-pins mask
U0FR    .equ 0x18    ; UART flag reg (TXFF/RXFE bits)

; game_started state values
GS_WAITING   .equ 0
GS_RUNNING   .equ 1
GS_RESPAWN   .equ 2    ; redrawing after death - timer skips all logic

;--- Pointer table ---
ptr_clr_reset:    .word clr_reset
ptr_clr_wall:     .word clr_wall
ptr_clr_corridor: .word clr_corridor
ptr_clr_pellet:   .word clr_pellet
ptr_clr_power:    .word clr_power
ptr_clr_score:    .word clr_score
ptr_clr_clear:    .word clr_clear
ptr_clr_hide:     .word clr_hide_cur
ptr_clr_pacman:   .word clr_pacman
ptr_clr_blinky:   .word clr_blinky
ptr_clr_pinky:    .word clr_pinky
ptr_clr_inky:     .word clr_inky
ptr_clr_clyde:    .word clr_clyde
ptr_clr_ghost_f:  .word clr_ghost_f
ptr_cursor_buf:   .word cursor_buf
ptr_score_label:  .word str_score
ptr_lives_label:  .word str_lives
ptr_press_str:    .word str_press
ptr_over_str:     .word str_over
ptr_win_str:      .word str_win
ptr_pause_msg:    .word str_pause
ptr_level_label:  .word str_level
ptr_score:        .word score
ptr_lives:        .word lives
ptr_paused:       .word paused
ptr_game_started: .word game_started
ptr_game_over:    .word game_over
ptr_level:        .word level
ptr_dots:         .word dots_left
ptr_pacman_row:   .word pacman_row
ptr_pacman_col:   .word pacman_col
ptr_pacman_dir:   .word pacman_dir
ptr_pacman_next:  .word pacman_next
ptr_ghost_data:   .word ghost_data
ptr_ghost_eaten:  .word ghost_eaten_count
ptr_power_timer:  .word power_timer
ptr_tick:         .word tick_count
ptr_rng_g0:       .word rng_g0
ptr_rng_g1:       .word rng_g1
ptr_rng_g2:       .word rng_g2
ptr_rng_g3:       .word rng_g3
ptr_maze:         .word maze_data
ptr_maze_rom:     .word maze_rom
ptr_led_table:    .word led_table

;=== pacman - entry point ===
pacman:
    PUSH {r4-r12, lr}
    BL   uart_init
    BL   gpio_sw1_init          ; Port F + NVIC
    BL   uart_interrupt_init
    BL   count_dots
    BL   draw_full_board
    MOV  r0, #18
    MOV  r1, #5
    BL   move_cursor
    LDR  r0, ptr_clr_score
    BL   output_string
    LDR  r0, ptr_press_str
    BL   output_string
    LDR  r0, ptr_clr_reset
    BL   output_string
    BL   start_timer            ; arm 10Hz timer
    BL   update_LED

idle:
    B    idle                   ; busy-wait
    POP  {r4-r12, lr}
    MOV  pc, lr

; -- init_game: full state reset --
init_game:
    PUSH {r4-r6, lr}
    LDR  r0, ptr_score
    MOV  r1, #0
    STR  r1, [r0]               ; score = 0
    LDR  r0, ptr_lives
    MOV  r1, #4
    STRB r1, [r0]               ; lives = 4
    BL   update_LED
    LDR  r0, ptr_game_started
    MOV  r1, #GS_WAITING
    STRB r1, [r0]               ; state = waiting
    LDR  r0, ptr_game_over
    MOV  r1, #0
    STRB r1, [r0]
    LDR  r0, ptr_paused
    STRB r1, [r0]
    LDR  r0, ptr_power_timer
    STRB r1, [r0]

    LDR  r0, ptr_pacman_row
    MOV  r1, #27
    STRB r1, [r0]               ; spawn row
    LDR  r0, ptr_pacman_col
    MOV  r1, #12
    STRB r1, [r0]
    LDR  r0, ptr_pacman_dir
    MOV  r1, #0
    STRB r1, [r0]               ; dir = stopped
    LDR  r0, ptr_pacman_next
    MOV  r1, #0
    STRB r1, [r0]

    LDR  r0, ptr_ghost_eaten
    STRB r1, [r0]
    ; Re-seed each ghost's LFSR to their original distinct values
    LDR  r0, ptr_rng_g0
    MOV  r1, #0xE1
    MOVT r1, #0x00AC
    STRH r1, [r0]              ; Blinky seed = 0xACE1

    LDR  r0, ptr_rng_g1
    MOV  r1, #0x4321
    STRH r1, [r0]              ; Pinky seed = 0x4321

    LDR  r0, ptr_rng_g2
    MOV  r1, #0x7FFF
    STRH r1, [r0]              ; Inky seed = 0x7FFF

    LDR  r0, ptr_rng_g3
    MOV  r1, #0x1357
    STRH r1, [r0]              ; Clyde seed = 0x1357

    ; Reset ghost positions
    LDR  r4, ptr_ghost_data
    ; Ghost 0 (Blinky): row=11 col=13 dir=up home=(11,13) mode=chase
    MOV  r0, #11
    STRB r0, [r4, #0]          ; row
    MOV  r0, #13
    STRB r0, [r4, #1]          ; col
    MOV  r0, #1
    STRB r0, [r4, #2]          ; dir = up
    MOV  r0, #11
    STRB r0, [r4, #3]          ; home_row
    MOV  r0, #13
    STRB r0, [r4, #4]          ; home_col
    MOV  r0, #1
    STRB r0, [r4, #5]          ; mode = chase

    ; Ghost 1 (Pinky): row=11 col=14 dir=up home=(11,14) mode=chase
    MOV  r0, #11
    STRB r0, [r4, #6]
    MOV  r0, #14
    STRB r0, [r4, #7]
    MOV  r0, #1
    STRB r0, [r4, #8]
    MOV  r0, #11
    STRB r0, [r4, #9]
    MOV  r0, #14
    STRB r0, [r4, #10]
    MOV  r0, #1
    STRB r0, [r4, #11]

    ; Ghost 2 (Inky): row=13 col=12 dir=up home=(13,12) mode=chase
    MOV  r0, #13
    STRB r0, [r4, #12]
    MOV  r0, #12
    STRB r0, [r4, #13]
    MOV  r0, #1
    STRB r0, [r4, #14]
    MOV  r0, #13
    STRB r0, [r4, #15]
    MOV  r0, #12
    STRB r0, [r4, #16]
    MOV  r0, #1
    STRB r0, [r4, #17]

    ; Ghost 3 (Clyde): row=13 col=15 dir=up home=(13,15) mode=chase
    MOV  r0, #13
    STRB r0, [r4, #18]
    MOV  r0, #15
    STRB r0, [r4, #19]
    MOV  r0, #1
    STRB r0, [r4, #20]
    MOV  r0, #13
    STRB r0, [r4, #21]
    MOV  r0, #15
    STRB r0, [r4, #22]
    MOV  r0, #1
    STRB r0, [r4, #23]
    LDR  r0, ptr_level
    MOV  r1, #1
    STRB r1, [r0]               ; level = 1
    MOV  r4, #0x0000
    MOVT r4, #0x4003            ; Timer0A base
    MOV  r1, #0x6A00
    MOVT r1, #0x0018            ; 1,600,000 = 0.1s at 16MHz
    STR  r1, [r4, #0x028]      ; reset GPTMTAILR to level-1 period
    BL   reset_maze             ; restore maze from ROM
    BL   count_dots             ; recount pellets
    MOV  r0, #0
    BL   illuminate_RGB_LED     ; LED off

    POP  {r4-r6, lr}
    MOV  pc, lr

; update_LED
update_LED: PUSH {r4, lr}
    LDR  r4, ptr_lives
    LDRB r0, [r4]              ; lives count (0-4)
    LDR  r4, ptr_led_table
    LDRB r0, [r4, r0]         ; table[lives] = LED bits
    BL   illuminate_LED
    POP  {r4, lr}
    MOV  pc, lr

; reset_maze
reset_maze:
    PUSH {r4-r6, lr}
    LDR  r4, ptr_maze           ; dest: live maze
    LDR  r5, ptr_maze_rom       ; src: original ROM
    MOV  r6, #(MAZE_ROWS * MAZE_COLS) ; total bytes to copy
rm_copy:
    LDRB r0, [r5], #1          ; read + advance src
    STRB r0, [r4], #1          ; write + advance dest
    SUBS r6, r6, #1            ; decrement counter
    BNE  rm_copy               ; loop until done
    POP  {r4-r6, lr}
    MOV  pc, lr

; count_dots
count_dots:
    PUSH {r4-r6, lr}
    MOV  r4, #0
    LDR  r5, ptr_maze
    MOV  r6, #0
cd_loop:
    MOV  r0, #MAZE_COLS
    MOV  r1, #MAZE_ROWS
    MUL  r0, r0, r1            ; total cells
    CMP  r6, r0
    BGE  cd_done
    LDRB r0, [r5, r6]
    CMP  r0, #'.'
    BEQ  cd_add
    CMP  r0, #'O'
    BNE  cd_next
cd_add:
    ADD  r4, r4, #1
cd_next:
    ADD  r6, r6, #1
    B    cd_loop
cd_done:
    LDR  r0, ptr_dots
    STR  r4, [r0]              ; save count
    POP  {r4-r6, lr}
    MOV  pc, lr

; -- draw_full_board --
draw_full_board:
    PUSH {r4-r7, lr}
    LDR  r0, ptr_clr_clear
    BL   output_string
    LDR  r0, ptr_clr_hide
    BL   output_string
    BL   draw_score_line
    MOV  r4, #0
dfb_row:
    CMP  r4, #MAZE_ROWS
    BGE  dfb_sprites
    MOV  r5, #0
dfb_col:
    CMP  r5, #MAZE_COLS
    BGE  dfb_next_row
    ADD  r0, r4, #BOARD_ROW
    ADD  r1, r5, #BOARD_COL
    BL   move_cursor
    MOV  r0, r4
    MOV  r1, r5
    BL   get_maze_cell
    BL   draw_one_cell
    ADD  r5, r5, #1
    B    dfb_col
dfb_next_row:
    ADD  r4, r4, #1
    B    dfb_row
dfb_sprites:
    BL   draw_pacman
    BL   draw_ghosts
    POP  {r4-r7, lr}
    MOV  pc, lr

; -- draw_one_cell --
draw_one_cell:
    PUSH {r4, lr}
    MOV  r4, r0                ; save cell char
    CMP  r4, #'#'
    BEQ  doc_wall              ; is a wall
    CMP  r4, #'.'
    BEQ  doc_pellet            ; is a pellet
    CMP  r4, #'O'
    BEQ  doc_power             ; is power pellet
    LDR  r0, ptr_clr_corridor
    BL   output_string
    MOV  r0, #' '
    BL   output_character
    B    doc_reset
doc_wall:
    LDR  r0, ptr_clr_wall
    BL   output_string
    MOV  r0, #' '
    BL   output_character
    B    doc_reset
doc_pellet:
    LDR  r0, ptr_clr_pellet
    BL   output_string
    MOV  r0, #'.'
    BL   output_character
    B    doc_reset
doc_power:
    LDR  r0, ptr_clr_power
    BL   output_string
    MOV  r0, #'O'
    BL   output_character
doc_reset:
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r4, lr}
    MOV  pc, lr

; -- draw_pacman --
draw_pacman:
    PUSH {r4-r5, lr}
    LDR  r4, ptr_pacman_row
    LDRB r4, [r4]
    LDR  r5, ptr_pacman_col
    LDRB r5, [r5]
    ADD  r0, r4, #BOARD_ROW
    ADD  r1, r5, #BOARD_COL
    BL   move_cursor
    LDR  r0, ptr_clr_pacman
    BL   output_string
    MOV  r0, #'<'
    BL   output_character
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r4-r5, lr}
    MOV  pc, lr

; -- draw_ghosts --
; B=Blinky(red) P=Pinky(mag) I=Inky(cyan) C=Clyde(yellow) W=frightened
draw_ghosts:
    PUSH {r4-r9, lr}
    LDR  r4, ptr_ghost_data
    MOV  r5, #0
dg_loop:
    CMP  r5, #4
    BGE  dg_done
    MOV  r6, #6
    MUL  r7, r5, r6            ; offset = index * 6
    ADD  r8, r4, r7

    LDRB r0, [r8, #0]           ; row
    LDRB r1, [r8, #1]           ; col
    LDRB r6, [r8, #5]           ; mode
    ADD  r0, r0, #BOARD_ROW
    ADD  r1, r1, #BOARD_COL
    PUSH {r4, r5, r6, r8}
    BL   move_cursor
    POP  {r4, r5, r6, r8}

    ; mode=2 frightened or mode=0 waiting: both show 'W'
    CMP  r6, #1
    BEQ  dg_normal

    PUSH {r4, r5, r8}
    LDR  r0, ptr_clr_ghost_f
    BL   output_string
    MOV  r0, #'W'
    BL   output_character
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r4, r5, r8}
    B    dg_next

dg_normal:
    PUSH {r4, r5, r8}
    CMP  r5, #0
    BNE  dg_try1
    LDR  r0, ptr_clr_blinky
    BL   output_string
    MOV  r0, #'B'
    BL   output_character
    B    dg_char_done
dg_try1:
    CMP  r5, #1
    BNE  dg_try2
    LDR  r0, ptr_clr_pinky
    BL   output_string
    MOV  r0, #'P'
    BL   output_character
    B    dg_char_done
dg_try2:
    CMP  r5, #2
    BNE  dg_try3
    LDR  r0, ptr_clr_inky
    BL   output_string
    MOV  r0, #'I'
    BL   output_character
    B    dg_char_done
dg_try3:
    LDR  r0, ptr_clr_clyde
    BL   output_string
    MOV  r0, #'C'
    BL   output_character
dg_char_done:
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r4, r5, r8}

dg_next:
    ADD  r5, r5, #1
    B    dg_loop
dg_done:
    POP  {r4-r9, lr}
    MOV  pc, lr

; -- draw_score_line --
draw_score_line:
    PUSH {lr}
    MOV  r0, #1
    MOV  r1, #1
    BL   move_cursor            ; top-left
    LDR  r0, ptr_clr_score
    BL   output_string
    LDR  r0, ptr_score_label
    BL   output_string
    LDR  r0, ptr_score
    LDR  r0, [r0]
    BL   print_number
    LDR  r0, ptr_lives_label
    BL   output_string
    LDR  r0, ptr_lives
    LDRB r0, [r0]
    ADD  r0, r0, #'0'          ; ASCII digit
    BL   output_character
    LDR  r0, ptr_level_label
    BL   output_string
    LDR  r0, ptr_level
    LDRB r0, [r0]
    BL   print_byte_decimal
    LDR  r0, ptr_clr_reset
    BL   output_string

    POP  {pc}

get_maze_cell:
    PUSH {r2-r4}
    MOV  r2, #MAZE_COLS
    MUL  r3, r0, r2            ; index = row * cols
    ADD  r3, r3, r1            ; + col
    LDR  r4, ptr_maze
    LDRB r0, [r4, r3]         ; load cell byte
    POP  {r2-r4}
    MOV  pc, lr

set_maze_cell:
    PUSH {r3-r5}
    MOV  r3, #MAZE_COLS
    MUL  r4, r0, r3            ; index = row * cols
    ADD  r4, r4, r1            ; + col
    LDR  r5, ptr_maze
    STRB r2, [r5, r4]         ; store new value
    POP  {r3-r5}
    MOV  pc, lr

; -- move_cursor: r0=row r1=col --
; had to hand-build ESC seq, no sprintf
move_cursor:
    PUSH {r4-r7, lr}
    MOV  r4, r0
    MOV  r5, r1
    LDR  r6, ptr_cursor_buf    ; ESC[row;colH buffer
    MOV  r7, #0
    MOV  r0, #27
    STRB r0, [r6, r7]          ; ESC
    ADD  r7, r7, #1
    MOV  r0, #'['
    STRB r0, [r6, r7]
    ADD  r7, r7, #1
    CMP  r4, #10
    BLT  mc_row_ones
    MOV  r0, r4
    MOV  r1, #10
mc_row_div:
    CMP  r0, r1
    BLT  mc_row_tens_done
    SUB  r0, r0, r1
    B    mc_row_div
mc_row_tens_done:
    SUB  r1, r4, r0
    MOV  r2, #10
    UDIV r1, r1, r2            ; tens digit
    ADD  r1, r1, #'0'
    STRB r1, [r6, r7]
    ADD  r7, r7, #1
    MOV  r4, r0
mc_row_ones:
    ADD  r0, r4, #'0'
    STRB r0, [r6, r7]
    ADD  r7, r7, #1
    MOV  r0, #';'
    STRB r0, [r6, r7]
    ADD  r7, r7, #1
    CMP  r5, #10
    BLT  mc_col_ones
    MOV  r0, r5
    MOV  r1, #10
mc_col_div:
    CMP  r0, r1
    BLT  mc_col_tens_done
    SUB  r0, r0, r1
    B    mc_col_div
mc_col_tens_done:
    SUB  r1, r5, r0
    MOV  r2, #10
    UDIV r1, r1, r2            ; tens digit
    ADD  r1, r1, #'0'
    STRB r1, [r6, r7]
    ADD  r7, r7, #1
    MOV  r5, r0
mc_col_ones:
    ADD  r0, r5, #'0'
    STRB r0, [r6, r7]
    ADD  r7, r7, #1
    MOV  r0, #'H'              ; 'H' = cursor position command
    STRB r0, [r6, r7]
    ADD  r7, r7, #1
    MOV  r0, #0
    STRB r0, [r6, r7]          ; null-terminate
    MOV  r0, r6
    BL   output_string
    POP  {r4-r7, lr}
    MOV  pc, lr

; -- print_number / print_byte_decimal --
; no UDIV on base Thumb, subtracting manually
print_byte_decimal:
    PUSH {r4-r6, lr}
    MOV  r4, r0                ; value
    MOV  r5, #0
    MOV  r6, #0

pbd_tens:
    CMP  r4, #10
    BLT  pbd_ones
    ADD  r5, r5, #1
    SUB  r4, r4, #10
    B    pbd_tens

pbd_ones:
    MOV  r6, r4
    CMP  r5, #0
    BEQ  pbd_skip_t            ; skip leading zero
    ADD  r0, r5, #'0'
    BL   output_character

pbd_skip_t:
    ADD  r0, r6, #'0'
    BL   output_character
    POP  {r4-r6, lr}
    MOV  pc, lr

print_number:
    PUSH {r4-r8, lr}
    MOV  r4, r0                ; remaining value
    MOV  r5, #0                ; thousands
    MOV  r6, #0                ; hundreds
    MOV  r7, #0
    MOV  r8, #0

pn_thou:
    CMP  r4, #1000
    BLT  pn_hund
    ADD  r5, r5, #1
    SUB  r4, r4, #1000
    B    pn_thou

pn_hund:
    CMP  r4, #100
    BLT  pn_tens
    ADD  r6, r6, #1
    SUB  r4, r4, #100
    B    pn_hund

pn_tens:
    CMP  r4, #10
    BLT  pn_ones
    ADD  r7, r7, #1
    SUB  r4, r4, #10
    B    pn_tens

    ; skip leading zeros
pn_ones:
    MOV  r8, r4                ; ones = remainder
    MOV  r4, #0                ; printed-flag
    CMP  r5, #0
    BEQ  pn_skip_t
    ADD  r0, r5, #'0'
    BL   output_character       ; thousands
    MOV  r4, #1

pn_skip_t:
    CMP  r4, #0
    BNE  pn_do_h               ; already printed something
    CMP  r6, #0
    BEQ  pn_skip_h
pn_do_h:
    ADD  r0, r6, #'0'
    BL   output_character
    MOV  r4, #1

pn_skip_h:
    CMP  r4, #0
    BNE  pn_do_te
    CMP  r7, #0
    BEQ  pn_skip_te
pn_do_te:
    ADD  r0, r7, #'0'
    BL   output_character

pn_skip_te:
    ADD  r0, r8, #'0'
    BL   output_character       ; ones always prints
    POP  {r4-r8, lr}
    MOV  pc, lr

; redraw_cell
redraw_cell:
    PUSH {r4-r5, lr}
    MOV  r4, r0
    MOV  r5, r1
    ADD  r0, r4, #BOARD_ROW
    ADD  r1, r5, #BOARD_COL
    BL   move_cursor
    MOV  r0, r4
    MOV  r1, r5
    BL   get_maze_cell
    BL   draw_one_cell
    POP  {r4-r5, lr}
    MOV  pc, lr

; can_move / can_move_ghost
; tunnel wraps both sides of row 14
can_move:
    PUSH {r2-r4, lr}

    ; Wrap column if off screen edges
    CMP  r1, #0
    BGE  cm_r
    MOV  r1, #27              ; wrap left → right
    B    cm_cell
cm_r:
    CMP  r1, #MAZE_COLS
    BLT  cm_cell
    MOV  r1, #0               ; wrap right → left

    ; Check row bounds then cell type
cm_cell:
    CMP  r0, #0
    BLT  cm_no                ; above maze
    CMP  r0, #MAZE_ROWS
    BGE  cm_no                ; below maze
    BL   get_maze_cell         ; read cell char
    CMP  r0, #'#'
    BEQ  cm_no                ; wall = blocked
    MOV  r0, #1               ; passable
    B    cm_done
cm_no:
    MOV  r0, #0               ; blocked
cm_done:
    POP  {r2-r4, lr}
    MOV  pc, lr

can_move_ghost:
    PUSH {r2-r4, lr}
    ; Wrap column if off screen edges
    CMP  r1, #0
    BGE  cmg_r
    MOV  r1, #27              ; wrap left → right
    B    cmg_cell
cmg_r:
    CMP  r1, #MAZE_COLS
    BLT  cmg_cell
    MOV  r1, #0               ; wrap right → left

    ; Check row bounds then cell type
cmg_cell:
    CMP  r0, #0
    BLT  cmg_no               ; above maze
    CMP  r0, #MAZE_ROWS
    BGE  cmg_no               ; below maze
    BL   get_maze_cell         ; read cell char
    CMP  r0, #'#'
    BEQ  cmg_no               ; wall = blocked
    MOV  r0, #1               ; passable
    B    cmg_done
cmg_no:
    MOV  r0, #0               ; blocked
cmg_done:
    POP  {r2-r4, lr}
    MOV  pc, lr

;=== Timer_Handler ===
; GS_RESPAWN(2): skip | GS_RUNNING(1): full logic | GS_WAITING(0): skip
Timer_Handler:
    PUSH {r4-r12, lr}

    ; Clear timer interrupt flag first
    MOV  r4, #0x0000
    MOVT r4, #0x4003           ; Timer0A base: 0x40030000
    MOV  r5, #0x01             ; TATOCINT
    STR  r5, [r4, #0x024]      ; GPTMICR

    ; Skip all logic unless fully running
    LDR  r0, ptr_game_started
    LDRB r0, [r0]
    CMP  r0, #GS_RUNNING
    BNE  th_done               ; skip if waiting(0) OR respawning(2)

    ; Skip if paused
    LDR  r0, ptr_paused
    LDRB r0, [r0]
    CMP  r0, #1
    BEQ  th_done

    ; Skip if game over
    LDR  r0, ptr_game_over
    LDRB r0, [r0]
    CMP  r0, #1
    BEQ  th_done

    ; Increment tick counter (wraps at 100)
    LDR  r4, ptr_tick
    LDRB r5, [r4]
    ADD  r5, r5, #1
    CMP  r5, #100
    BLT  th_store_tick
    MOV  r5, #0
th_store_tick:
    STRB r5, [r4]

    BL   move_pacman
    ; bail if death changed game_started
    LDR  r0, ptr_game_started
    LDRB r0, [r0]
    CMP  r0, #GS_RUNNING
    BNE  th_done

    BL   move_ghosts
    ; ghost could kill on same tick
    LDR  r0, ptr_game_started
    LDRB r0, [r0]
    CMP  r0, #GS_RUNNING
    BNE  th_done

    ; power pellet timer + LED feedback
    LDR  r0, ptr_power_timer
    LDRB r1, [r0]
    CMP  r1, #0
    BEQ  th_score              ; no active power
    SUB  r1, r1, #1
    STRB r1, [r0]
    CMP  r1, #0
    BEQ  th_power_end          ; expired
    CMP  r1, #20
    BGT  th_power_blue
    ; blink rate tied to tick_count parity
    AND  r2, r1, #1
    CMP  r2, #0
    BEQ  th_power_off
    MOV  r0, #0x02             ; red = warning flash
    BL   illuminate_RGB_LED
    B    th_score
th_power_off:
    MOV  r0, #0
    BL   illuminate_RGB_LED
    B    th_score
th_power_blue:
    MOV  r0, #0x04             ; blue = fully powered
    BL   illuminate_RGB_LED
    B    th_score
th_power_end:
    BL   reset_ghost_modes

    ; Refresh score display
th_score:
    BL   draw_score_line
th_done:
    LDR  r0, ptr_game_started
    LDRB r1, [r0]
    CMP  r1, #GS_RESPAWN
    BNE  th_exit
    MOV  r1, #GS_RUNNING
    STRB r1, [r0]
th_exit:
    POP  {r4-r12, lr}
    BX   lr

; -- move_pacman --
move_pacman:
    PUSH {r4-r9, lr}

    ; Load current position and buffered direction
    LDR  r4, ptr_pacman_row
    LDRB r5, [r4]              ; current row
    LDR  r6, ptr_pacman_col
    LDRB r7, [r6]              ; current col
    LDR  r8, ptr_pacman_next
    LDRB r9, [r8]              ; buffered next dir

    ; Handle buffered direction input
    CMP  r9, #0
    BEQ  mp_try_cur            ; no buffered dir

    LDR  r3, ptr_pacman_dir
    LDRB r3, [r3]
    CMP  r9, r3
    BNE  mp_try_new            ; different direction
    MOV  r0, #0
    STRB r0, [r8]
    B    mp_try_cur            ; same dir: clear redundant buffer, still move

    ; Try turning to new direction
mp_try_new:
    MOV  r0, r5
    MOV  r1, r7
    MOV  r2, r9
    BL   calc_new_pos          ; compute new position
    PUSH {r0, r1}
    BL   can_move              ; check if passable
    MOV  r3, r0
    POP  {r0, r1}

    CMP  r3, #1
    BNE  mp_try_cur            ; blocked, try current
    LDR  r3, ptr_pacman_dir
    STRB r9, [r3]              ; commit new direction
    MOV  r3, #0
    STRB r3, [r8]              ; clear buffered next
    B    mp_do_move

    ; Try continuing current direction
mp_try_cur:
    LDR  r8, ptr_pacman_dir
    LDRB r9, [r8]
    CMP  r9, #0
    BEQ  mp_done               ; stopped
    MOV  r0, r5
    MOV  r1, r7
    MOV  r2, r9
    BL   calc_new_pos          ; compute ahead cell
    PUSH {r0, r1}
    BL   can_move
    MOV  r3, r0
    POP  {r0, r1}
    CMP  r3, #1
    BNE  mp_done               ; wall ahead, stop

    ; Do the actual move
mp_do_move:
    MOV  r2, r0                ; new row
    MOV  r3, r1                ; new col
    PUSH {r2, r3}
    MOV  r0, r5
    MOV  r1, r7
    BL   redraw_cell            ; erase old position
    POP  {r2, r3}

    ; Wrap column at tunnel edges
    CMP  r3, #0
    BGE  mp_wr
    MOV  r3, #27               ; wrap left → right
    B    mp_upd
mp_wr:
    CMP  r3, #MAZE_COLS
    BLT  mp_upd
    MOV  r3, #0                ; wrap right → left

    ; Update stored position
mp_upd:
    LDR  r4, ptr_pacman_row
    STRB r2, [r4]
    LDR  r6, ptr_pacman_col
    STRB r3, [r6]

    ; Check what's on the new cell
    MOV  r0, r2
    MOV  r1, r3
    BL   get_maze_cell          ; read cell char
    MOV  r8, r0
    CMP  r8, #'.'
    BNE  mp_chk_pow
    BL   eat_dot               ; eat normal pellet
    B    mp_chk_ghost
mp_chk_pow:
    CMP  r8, #'O'
    BNE  mp_chk_ghost
    BL   eat_power             ; eat power pellet

    ; Check ghost collision
mp_chk_ghost:
    BL   check_ghost_collision
    ; If pacman_death was called, game_started is now GS_RESPAWN or
    ; GS_WAITING/GS_OVER. Don't draw_pacman and don't check dots (maze was reset).
    LDR  r0, ptr_game_started
    LDRB r0, [r0]
    CMP  r0, #GS_RUNNING
    BNE  mp_done
    BL   draw_pacman            ; draw at new pos

    ; Check win condition
    LDR  r0, ptr_dots
    LDR  r0, [r0]
    CMP  r0, #0
    BNE  mp_done               ; dots remain
    BL   level_won             ; all eaten = win
mp_done:
    POP  {r4-r9, lr}
    MOV  pc, lr

calc_new_pos:
    ; r2=1 up, 2 down, 3 left, 4 right
    CMP  r2, #1
    BNE  cnp_d
    SUB  r0, r0, #1            ; up: row--
    MOV  pc, lr
cnp_d:
    CMP  r2, #2
    BNE  cnp_l
    ADD  r0, r0, #1            ; down: row++
    MOV  pc, lr
cnp_l:
    CMP  r2, #3
    BNE  cnp_r
    SUB  r1, r1, #1            ; left: col--
    MOV  pc, lr
cnp_r:
    CMP  r2, #4
    BNE  cnp_done
    ADD  r1, r1, #1            ; right: col++
cnp_done:
    MOV  pc, lr

; eat_dot / eat_power
eat_dot:
    PUSH {r4-r5, lr}

    ; Add 10 points to score
    LDR  r4, ptr_score
    LDR  r5, [r4]
    ADD  r5, r5, #10
    STR  r5, [r4]
    LDR  r4, ptr_dots
    LDR  r5, [r4]
    SUB  r5, r5, #1
    STR  r5, [r4]

    LDR  r4, ptr_pacman_row
    LDRB r0, [r4]
    LDR  r4, ptr_pacman_col
    LDRB r1, [r4]
    MOV  r2, #' '
    BL   set_maze_cell          ; replace dot with space
    POP  {r4-r5, lr}
    MOV  pc, lr

eat_power:
    PUSH {r4-r5, lr}

    ; Add 50 points to score
    LDR  r4, ptr_score
    LDR  r5, [r4]
    ADD  r5, r5, #50
    STR  r5, [r4]

    LDR  r4, ptr_dots
    LDR  r5, [r4]
    SUB  r5, r5, #1
    STR  r5, [r4]

    ; Clear power pellet from maze
    LDR  r4, ptr_pacman_row
    LDRB r0, [r4]
    LDR  r4, ptr_pacman_col
    LDRB r1, [r4]
    MOV  r2, #' '
    BL   set_maze_cell          ; replace 'O' with space

    ; Activate power mode: 60 ticks
    LDR  r4, ptr_power_timer
    MOV  r5, #60
    STRB r5, [r4]

    ; Reset eaten ghost combo counter
    LDR  r4, ptr_ghost_eaten
    MOV  r5, #0
    STRB r5, [r4]

    ; Set all ghosts to frightened (mode=2)
    LDR  r4, ptr_ghost_data
    MOV  r5, #2
    STRB r5, [r4, #5]           ; ghost 0 mode
    STRB r5, [r4, #11]          ; ghost 1 mode
    STRB r5, [r4, #17]          ; ghost 2 mode
    STRB r5, [r4, #23]          ; ghost 3 mode

    MOV  r0, #0x04
    BL   illuminate_RGB_LED    ; blue LED on
    POP  {r4-r5, lr}
    MOV  pc, lr

; reset_ghost_modes
reset_ghost_modes:
    PUSH {r4-r5, lr}
    LDR  r4, ptr_ghost_data    ; ghost array base
    MOV  r5, #0                ; ghost index
rgm_loop:
    CMP  r5, #4
    BGE  rgm_done
    MOV  r0, #6
    MUL  r0, r5, r0            ; offset = index * 6
    ADD  r0, r4, r0
    LDRB r1, [r0, #5]
    CMP  r1, #1
    BEQ  rgm_next              ; already chase
    MOV  r1, #1
    STRB r1, [r0, #5]          ; mode = chase
    MOV  r1, #1                ; reset dir UP so they exit house
    STRB r1, [r0, #2]
rgm_next:
    ADD  r5, r5, #1
    B    rgm_loop
rgm_done:
    MOV  r0, #0
    BL   illuminate_RGB_LED    ; LED off
    POP  {r4-r5, lr}
    MOV  pc, lr

; -- move_ghosts --
move_ghosts:
    PUSH {r4-r12, lr}
    LDR  r4, ptr_ghost_data
    MOV  r5, #0                ; ghost index
mg_loop:
    CMP  r5, #4
    BGE  mg_done
    MOV  r6, #6
    MUL  r7, r5, r6            ; offset = index * 6
    ADD  r8, r4, r7

    LDRB r9,  [r8, #0]         ; row
    LDRB r10, [r8, #1]         ; col
    LDRB r11, [r8, #2]         ; direction
    LDRB r12, [r8, #5]         ; mode

    PUSH {r4, r5, r8}
    MOV  r0, r9
    MOV  r1, r10
    BL   redraw_cell
    POP  {r4, r5, r8}

    ; reload - redraw_cell clobbers regs
    LDRB r9,  [r8, #0]
    LDRB r10, [r8, #1]
    LDRB r11, [r8, #2]
    LDRB r12, [r8, #5]

    ; pass this ghost's own LFSR pointer in r4
    PUSH {r4, r5, r8}
    MOV  r0, r9
    MOV  r1, r10
    MOV  r2, r11
    MOV  r3, r12
    CMP  r5, #0
    BNE  mg_rng1
    LDR  r4, ptr_rng_g0        ; Blinky
    B    mg_rng_done
mg_rng1:
    CMP  r5, #1
    BNE  mg_rng2
    LDR  r4, ptr_rng_g1        ; Pinky
    B    mg_rng_done
mg_rng2:
    CMP  r5, #2
    BNE  mg_rng3
    LDR  r4, ptr_rng_g2        ; Inky
    B    mg_rng_done
mg_rng3:
    LDR  r4, ptr_rng_g3        ; Clyde
mg_rng_done:
    BL   ghost_choose_dir       ; r0=row r1=col r2=cur_dir r3=mode r4=rng_ptr
    MOV  r11, r0               ; chosen direction
    POP  {r4, r5, r8}

    ; Compute new position in chosen direction
    LDRB r9,  [r8, #0]
    LDRB r10, [r8, #1]
    PUSH {r4, r5, r8, r11}
    MOV  r0, r9
    MOV  r1, r10
    MOV  r2, r11
    BL   calc_new_pos           ; r0=new row r1=new col
    MOV  r9, r0
    MOV  r10, r1
    POP  {r4, r5, r8, r11}

    ; Wrap column at tunnel edges
    CMP  r10, #0
    BGE  mg_wr
    MOV  r10, #27              ; wrap left → right
    B    mg_upd
mg_wr:
    CMP  r10, #MAZE_COLS
    BLT  mg_upd
    MOV  r10, #0               ; wrap right → left

mg_upd:
    STRB r9,  [r8, #0]
    STRB r10, [r8, #1]
    STRB r11, [r8, #2]         ; new dir
    ADD  r5, r5, #1
    B    mg_loop
mg_done:
    BL   draw_ghosts            ; redraw all ghosts
    BL   check_ghost_collision  ; check after moving
    ; If check_ghost_collision triggered pacman_death, game_started
    ; changed. Either way we just return - Timer_Handler will bail.
    POP  {r4-r12, lr}
    MOV  pc, lr

; -- ghost_choose_dir --
; in: r0=row r1=col r2=cur_dir r3=mode r4=rng_ptr   out: r0=new dir
; house is rows 11-16, cols 9-18
ghost_choose_dir:
    PUSH {r4-r7, lr}

    ; Save inputs on stack
    SUB  sp, sp, #20
    STR  r0, [sp, #0]           ; row
    STR  r1, [sp, #4]           ; col
    STR  r2, [sp, #8]           ; cur_dir
    STR  r3, [sp, #12]          ; mode
    STR  r4, [sp, #16]          ; rng_ptr

    ; Ghost-house exit: if inside house rows 11-16 cols 9-18, go UP first
    LDR  r4, [sp, #0]
    CMP  r4, #HOUSE_ROW_T
    BLT  gcd_normal_ai          ; above house
    CMP  r4, #HOUSE_ROW_B
    BGT  gcd_normal_ai          ; below house
    LDR  r5, [sp, #4]
    CMP  r5, #HOUSE_COL_L
    BLT  gcd_normal_ai          ; left of house
    CMP  r5, #HOUSE_COL_R
    BGT  gcd_normal_ai          ; right of house

    ; Inside house: try UP first
    SUB  r0, r4, #1
    MOV  r1, r5
    BL   can_move_ghost         ; can go up?
    CMP  r0, #1
    BEQ  gcd_house_up
    CMP  r5, #13
    BLT  gcd_house_right        ; left of center: go right
    BGT  gcd_house_left         ; right of center: go left
    LDR  r0, [sp, #8]           ; centered: keep dir
    B    gcd_exit
gcd_house_up:
    MOV  r0, #1
    B    gcd_exit
gcd_house_right:
    MOV  r0, #4
    B    gcd_exit
gcd_house_left:
    MOV  r0, #3
    B    gcd_exit

gcd_normal_ai:
    ; Advance THIS ghost's LFSR (16-bit shift register)
    LDR  r6, [sp, #16]          ; rng_ptr
    LDRH r7, [r6]               ; current state
    AND  r4, r7, #1             ; save LSB (feedback bit)
    LSR  r7, r7, #1             ; shift right
    CMP  r4, #0
    BEQ  gcd_no_fb
;    MOV  r4, #0x0000
    MOV r4, #0xB400             ; need it to be 0x0000B400
    EOR  r7, r7, r4             ; XOR feedback poly
gcd_no_fb:
    STRH r7, [r6]               ; save new LFSR state
    AND  r6, r7, #3
    ADD  r6, r6, #1             ; r6 = start direction to try (1..4)

    ; Try current direction first
;    LDR  r4, [sp, #0]
;    LDR  r5, [sp, #4]
;    LDR  r7, [sp, #8]
;    CMP  r7, #0
;    BEQ  gcd_try_rand           ; no current dir
;    MOV  r0, r4
;    MOV  r1, r5
;    MOV  r2, r7
;    BL   calc_new_pos
;    BL   can_move_ghost         ; passable ahead?
;    CMP  r0, #1
;    BEQ  gcd_keep_cur           ; yes, keep going

    ; Try random direction (skip reverse)
gcd_try_rand:
    MOV  r4, #4                 ; up to 4 tries
gcd_try_loop:
    CMP  r4, #0
    BEQ  gcd_stuck              ; no valid dir found
    LDR  r7, [sp, #8]           ; cur_dir for reversal check

    ; Compute opposite direction
    CMP  r7, #1
    BNE  gcd_opp2
    MOV  r3, #2                 ; opp = down
    B    gcd_opp_done
gcd_opp2:
    CMP  r7, #2
    BNE  gcd_opp3
    MOV  r3, #1                 ; opp = up
    B    gcd_opp_done
gcd_opp3:
    CMP  r7, #3
    BNE  gcd_opp4
    MOV  r3, #4                 ; opp = right
    B    gcd_opp_done
gcd_opp4:
    MOV  r3, #3                 ; opp = left
gcd_opp_done:
    CMP  r6, r3
    BEQ  gcd_next_d             ; skip reverse direction
    LDR  r0, [sp, #0]
    LDR  r1, [sp, #4]
    MOV  r2, r6
    BL   calc_new_pos
    BL   can_move_ghost         ; passable?
    CMP  r0, #1
    BEQ  gcd_found              ; valid direction

gcd_next_d:
    ADD  r6, r6, #1            ; try next direction
    CMP  r6, #5
    BLT  gcd_no_wrap
    MOV  r6, #1                ; wrap 4→1
gcd_no_wrap:
    SUB  r4, r4, #1            ; decrement try count
    B    gcd_try_loop

gcd_found:
    MOV  r0, r6                ; return found direction
    B    gcd_exit
gcd_keep_cur:
    LDR  r0, [sp, #8]          ; return current dir
    B    gcd_exit
gcd_stuck:
    LDR  r0, [sp, #8]          ; nowhere to go
gcd_exit:
    ADD  sp, sp, #20            ; restore stack
    POP  {r4-r7, lr}
    MOV  pc, lr

; -- check_ghost_collision --
check_ghost_collision:
    PUSH {r4-r9, lr}

    LDR  r4, ptr_pacman_row
    LDRB r4, [r4]               ; pacman row
    LDR  r5, ptr_pacman_col
    LDRB r5, [r5]               ; pacman col

    LDR  r6, ptr_ghost_data
    MOV  r7, #0
cgc_loop:
    CMP  r7, #4
    BGE  cgc_done
    MOV  r8, #6
    MUL  r8, r7, r8            ; offset = index * 6
    ADD  r9, r6, r8

    LDRB r0, [r9, #0]          ; ghost row
    LDRB r1, [r9, #1]          ; ghost col
    CMP  r0, r4
    BNE  cgc_next
    CMP  r1, r5
    BNE  cgc_next
    ; same cell - check mode
    LDRB r2, [r9, #5]
    CMP  r2, #2
    BEQ  cgc_eat               ; frightened = eat
    CMP  r2, #0                 ; mode=0 waiting: not dangerous
    BEQ  cgc_next
    BL   pacman_death           ; chase mode = death
    B    cgc_done

    ; score doubles per consecutive eaten ghost
cgc_eat:
    PUSH {r7, r9}
    LDR  r0, ptr_ghost_eaten
    LDRB r1, [r0]
    MOV  r2, #100              ; base score
    CMP  r1, #0
    BEQ  cgc_add_score
    MOV  r3, r1
cgc_shift:
    LSL  r2, r2, #1
    SUBS r3, r3, #1
    BNE  cgc_shift

cgc_add_score:
    ADD  r1, r1, #1
    CMP  r1, #4
    BLT  cgc_no_reset
    MOV  r1, #0                ; reset combo after 4
cgc_no_reset:
    STRB r1, [r0]

    LDR  r0, ptr_score
    LDR  r1, [r0]
    ADD  r1, r1, r2
    STR  r1, [r0]

    ; send ghost back to spawn
    POP  {r7, r9}
    LDRB r0, [r9, #3]           ; home_row
    STRB r0, [r9, #0]
    LDRB r0, [r9, #4]           ; home_col
    STRB r0, [r9, #1]
    MOV  r0, #1                 ; dir = UP
    STRB r0, [r9, #2]
    MOV  r0, #0                 ; mode = waiting
    STRB r0, [r9, #5]
cgc_next:
    ADD  r7, r7, #1
    B    cgc_loop
cgc_done:
    POP  {r4-r9, lr}
    MOV  pc, lr

; -- pacman_death --
; on life lost: RESPAWN, reset, redraw, RUNNING; on last life: WAITING+game over
pacman_death:
    PUSH {r4-r5, lr}
    MOV  r0, #0x0A
    BL   illuminate_RGB_LED

    ; Decrement lives
    LDR  r4, ptr_lives
    LDRB r5, [r4]
    SUB  r5, r5, #1
    STRB r5, [r4]
    BL update_LED 			; base BOARD LED
    CMP  r5, #0
    BEQ  pd_over               ; no lives left

    ; set RESPAWN so timer skips while we redraw
    LDR  r0, ptr_game_started
    MOV  r1, #GS_RESPAWN
    STRB r1, [r0]
    BL   reset_positions
    BL   draw_full_board
    BL   flush          ; discard keys during redraw

    ; th_done sets RUNNING on next tick
    MOV  r0, #0
    BL   illuminate_RGB_LED
    B    pd_done

pd_over:
    LDR  r0, ptr_game_over
    MOV  r1, #1
    STRB r1, [r0]
    LDR  r0, ptr_game_started
    MOV  r1, #GS_WAITING
    STRB r1, [r0]              ; stop game logic

    MOV  r0, #18
    MOV  r1, #10
    BL   move_cursor
    LDR  r0, ptr_clr_score
    BL   output_string
    LDR  r0, ptr_over_str
    BL   output_string          ; "GAME OVER"
    LDR  r0, ptr_clr_reset
    BL   output_string

    MOV  r0, #20
    MOV  r1, #4
    BL   move_cursor
    LDR  r0, ptr_press_str
    BL   output_string
pd_done:
    POP  {r4-r5, lr}
    MOV  pc, lr

; reset_positions  (caller sets game_started)
reset_positions:
    PUSH {r4-r6, lr}

    ; Reset pac-man to spawn position
    LDR  r0, ptr_pacman_row
    MOV  r1, #27               ; spawn row
    STRB r1, [r0]
    LDR  r0, ptr_pacman_col
    MOV  r1, #12
    STRB r1, [r0]
    LDR  r0, ptr_pacman_dir
    MOV  r1, #0
    STRB r1, [r0]              ; stopped
    LDR  r0, ptr_pacman_next
    MOV  r1, #0
    STRB r1, [r0]

    LDR  r0, ptr_paused
    MOV  r1, #0
    STRB r1, [r0]
    LDR  r0, ptr_power_timer
    MOV  r1, #0
    STRB r1, [r0]

    ; reset ghosts to home
    LDR  r4, ptr_ghost_data
    MOV  r5, #0
rp_loop:
    CMP  r5, #4
    BGE  rp_done
    MOV  r6, #6
    MUL  r6, r5, r6            ; offset = index * 6
    ADD  r6, r4, r6
    LDRB r0, [r6, #3]           ; home_row
    STRB r0, [r6, #0]
    LDRB r0, [r6, #4]           ; home_col
    STRB r0, [r6, #1]
    MOV  r0, #1                 ; dir = UP
    STRB r0, [r6, #2]
    MOV  r0, #1                 ; mode = chase
    STRB r0, [r6, #5]
    ADD  r5, r5, #1
    B    rp_loop
rp_done:
    POP  {r4-r6, lr}
    MOV  pc, lr

; level_won
level_won:
    PUSH {r4-r5, lr}

    ; Increment level
    LDR  r4, ptr_level
    LDRB r5, [r4]
    ADD  r5, r5, #1
    STRB r5, [r4]

    ; New period = 1,600,000 - (level-1)*160,000
    ; increase by 0.01s
    SUB  r0, r5, #1
    MOV  r1, #0x7100
    MOVT r1, #0x0002            ; 160,000
    MUL  r0, r0, r1
    MOV  r5, #0x6A00
    MOVT r5, #0x0018            ;1,600,000
    SUB  r0, r5, r0
    MOV  r4, #0x0000
    MOVT r4, #0x4003
    STR  r0, [r4, #0x028]      ; update GPTMTAILR



    MOV  r0, #0x08
    BL   illuminate_RGB_LED

    BL   reset_maze
    BL   count_dots
    BL   reset_positions

    LDR  r0, ptr_game_started
    MOV  r1, #GS_RESPAWN
    STRB r1, [r0]

    BL   draw_full_board
    BL   flush          ; discard keys pressed during level redraw

    MOV  r0, #0
    BL   illuminate_RGB_LED

    POP  {r4-r5, lr}
    MOV  pc, lr

;=== Switch_Handler - PF4 toggle pause ===
Switch_Handler:
    PUSH {r4-r12, lr}

    ; Acknowledge SW1 interrupt (Port F)
    MOV  r4, #0x5000
    MOVT r4, #0x4002           ; Port F base: 0x40025000
    MOV  r5, #0x10             ; PF4 / SW1
    STR  r5, [r4, #0x41C]     ; GPIOICR

    ; Check if currently paused
    LDR  r0, ptr_paused
    LDRB r1, [r0]
    CMP  r1, #0
    BEQ  sh_pause              ; not paused → pause now

    ; Resume: clear paused flag and re-enable timer
    MOV  r1, #0
    STRB r1, [r0]              ; paused = 0
    MOV  r4, #0x0000
    MOVT r4, #0x4003           ; Timer0A base: 0x40030000
    LDR  r5, [r4, #0x00C]     ; GPTMCTL
    ORR  r5, r5, #1            ; TAEN on
    STR  r5, [r4, #0x00C]

    ; Erase PAUSED text from screen
    PUSH {r0-r3}
    MOV  r0, #18
    MOV  r1, #5
    BL   move_cursor
    LDR  r0, ptr_clr_corridor
    BL   output_string
    MOV  r5, #0
sh_clr:
    CMP  r5, #20
    BGE  sh_clr_done
    MOV  r0, #' '
    BL   output_character
    ADD  r5, r5, #1
    B    sh_clr
sh_clr_done:
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r0-r3}
    B    sh_done

    ; pause: set flag and disable timer
sh_pause:
    MOV  r1, #1
    STRB r1, [r0]              ; paused = 1
    MOV  r4, #0x0000
    MOVT r4, #0x4003           ; Timer0A: 0x40030000
    LDR  r5, [r4, #0x00C]     ; GPTMCTL
    BIC  r5, r5, #1            ; TAEN off
    STR  r5, [r4, #0x00C]

    PUSH {r0-r3}
    MOV  r0, #18
    MOV  r1, #5
    BL   move_cursor
    LDR  r0, ptr_clr_score
    BL   output_string
    LDR  r0, ptr_pause_msg
    BL   output_string          ; "PAUSED-SW1 to resume"
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r0-r3}
sh_done:
    POP  {r4-r12, lr}
    BX   lr

;=== UART0_Handler ===
; arrow keys come as 3-byte ESC sequences: ESC [ A/B/C/D
UART0_Handler:
    PUSH {r4-r12, lr}

    ; Acknowledge UART interrupt and read one byte
    MOV  r0, #0xC044
    MOVT r0, #0x4000           ; UART0 ICR: 0x4000C044
    MOV  r1, #0x50             ; bit 4 RXIC + bit 6 RTIC - clear RX and timeout flags
    STR  r1, [r0]              ; UARTICR
    BL   simple_read_character
    AND  r4, r0, #0xFF         ; keep lower byte only

    ; SPACE: start or restart
    CMP  r4, #' '              ; ' ' space key?
    BNE  uh_w

    ; Game over takes priority - restart regardless of running state
    LDR  r0, ptr_game_over
    LDRB r1, [r0]
    CMP  r1, #1
    BEQ  uh_restart
    ; Not game over: ignore if already running or respawning
    LDR  r0, ptr_game_started
    LDRB r1, [r0]
    CMP  r1, #GS_RUNNING
    BEQ  uh_done
    CMP  r1, #GS_RESPAWN
    BEQ  uh_done

    ; First start: just set running and clear prompt
    LDR  r0, ptr_game_started
    MOV  r1, #GS_RUNNING
    STRB r1, [r0]              ; start game
    PUSH {r0-r3}
    MOV  r0, #18
    MOV  r1, #5
    BL   move_cursor
    LDR  r0, ptr_clr_corridor
    BL   output_string
    MOV  r5, #0
uh_clr:
    CMP  r5, #24
    BGE  uh_clr_done
    MOV  r0, #' '
    BL   output_character       ; erase start prompt
    ADD  r5, r5, #1
    B    uh_clr
uh_clr_done:
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r0-r3}
    B    uh_done

    ; Full restart: reinit and redraw
uh_restart:
    PUSH {r0-r3}
    BL   init_game              ; reset all state
    BL   draw_full_board        ; clears screen and redraws everything
    BL   flush          ; discard keys pressed during restart redraw
    LDR  r0, ptr_game_started
    MOV  r1, #GS_RUNNING
    STRB r1, [r0]              ; start running
    MOV  r4, #0x0000
    MOVT r4, #0x4003           ; Timer0A base
    LDR  r5, [r4, #0x00C]
    ORR  r5, r5, #1
    STR  r5, [r4, #0x00C]     ; re-enable timer
    POP  {r0-r3}
    B    uh_done

    ; W/w = move up
uh_w:
    CMP  r4, #'W'              ; 'W' pressed?
    BEQ  uh_up
    CMP  r4, #'w'              ; 'w' pressed?
    BNE  uh_s
uh_up:
    LDR  r0, ptr_pacman_next
    MOV  r1, #1
    STRB r1, [r0]
    B    uh_done

    ; S/s = move down
uh_s:
    CMP  r4, #'S'
    BEQ  uh_down
    CMP  r4, #'s'
    BNE  uh_a
uh_down:
    LDR  r0, ptr_pacman_next
    MOV  r1, #2
    STRB r1, [r0]
    B    uh_done

    ; A/a = move left
uh_a:
    CMP  r4, #'A'
    BEQ  uh_left
    CMP  r4, #'a'
    BNE  uh_d
uh_left:
    LDR  r0, ptr_pacman_next
    MOV  r1, #3
    STRB r1, [r0]
    B    uh_done

    ; D/d = move right
uh_d:
    CMP  r4, #'D'
    BEQ  uh_right
    CMP  r4, #'d'
    BNE  uh_p
uh_right:
    LDR  r0, ptr_pacman_next
    MOV  r1, #4
    STRB r1, [r0]              ; buffer direction
    B    uh_done

    ; P/p = pause (one-way, SW1 resumes)
uh_p:
    CMP  r4, #'P'              ; 'P' pressed?
    BEQ  uh_pause_key
    CMP  r4, #'p'              ; 'p' pressed?
    BNE  uh_esc

uh_pause_key:
    LDR  r0, ptr_paused
    LDRB r1, [r0]
    CMP  r1, #1
    BEQ  uh_done               ; already paused
    MOV  r1, #1
    STRB r1, [r0]              ; set paused
    PUSH {r0-r3}
    MOV  r0, #18
    MOV  r1, #5
    BL   move_cursor
    LDR  r0, ptr_clr_score
    BL   output_string
    LDR  r0, ptr_pause_msg
    BL   output_string          ; "PAUSED-SW1 to resume"
    LDR  r0, ptr_clr_reset
    BL   output_string
    POP  {r0-r3}
    B    uh_done

    ; ESC = start of arrow key sequence
uh_esc:
    CMP  r4, #27               ; ESC byte (0x1B)?
    BNE  uh_done               ; not escape
    BL   simple_read_character
    AND  r4, r0, #0xFF
    CMP  r4, #'['              ; CSI '[' byte?
    BNE  uh_done               ; not CSI bracket
    BL   simple_read_character
    AND  r4, r0, #0xFF         ; 'A'/'B'/'C'/'D'
    CMP  r4, #'A'              ; up arrow code?
    BEQ  uh_arrow_up
    CMP  r4, #'B'              ; down arrow code?
    BEQ  uh_arrow_down
    CMP  r4, #'C'              ; right arrow code?
    BEQ  uh_arrow_right
    CMP  r4, #'D'              ; left arrow code?
    BEQ  uh_arrow_left
    B    uh_done

uh_arrow_up:
    LDR  r0, ptr_pacman_next
    MOV  r1, #1
    STRB r1, [r0]
    B    uh_done
uh_arrow_down:
    LDR  r0, ptr_pacman_next
    MOV  r1, #2
    STRB r1, [r0]
    B    uh_done
uh_arrow_left:
    LDR  r0, ptr_pacman_next
    MOV  r1, #3
    STRB r1, [r0]
    B    uh_done
uh_arrow_right:
    LDR  r0, ptr_pacman_next
    MOV  r1, #4
    STRB r1, [r0]
uh_done:
    POP  {r4-r12, lr}
    BX   lr

;=============================================================
; gpio_sw1_init - Port F: PF1-3 LED outputs, PF4 SW1 input
;=============================================================
gpio_sw1_init:
    PUSH {r4-r5, lr}

    ; Enable clock for Port F via RCGCGPIO
    MOV  r4, #0xE608
    MOVT r4, #0x400F           ; RCGCGPIO: 0x400FE608
    LDR  r5, [r4]              ; RCGCGPIO
    ORR  r5, r5, #0x20         ; bit 5 = Port F
    STR  r5, [r4]

    ; Enable AHB for Port F
    MOV  r4, #0xE604
    MOVT r4, #0x400F           ; GPIOHBCTL: 0x400FE604
    LDR  r5, [r4]
    ORR  r5, r5, #0x01         ; bit 0
    STR  r5, [r4]

    ; Wait for Port F clock ready
    MOV  r4, #0xEA08
    MOVT r4, #0x400F           ; PRGPIO: 0x400FEA08
wgs:
    LDR  r5, [r4]
    TST  r5, #0x20             ; bit 5
    BEQ  wgs

    ; Wait for AHB ready
    MOV  r4, #0xEA04
    MOVT r4, #0x400F           ; PRTIMER: 0x400FEA04
wgt5:
    LDR  r5, [r4]
    TST  r5, #0x01             ; bit 0 ready
    BEQ  wgt5

    ; Configure Port F pins (RGB LED + SW1)
    MOV  r4, #0x5000
    MOVT r4, #0x4002           ; Port F base: 0x40025000

    ; Set pin lock key and commit PF0
    MOV  r5, #0x4B
    MOVT r5, #0x4C4F           ; unlock key 0x4C4F004B
    STR  r5, [r4, #0x520]     ; GPIOLOCK - unlock key

    MOV  r5, #0x1F
    STR  r5, [r4, #0x524]     ; GPIOCR - commit all 5 pins

    ; PF1-PF3 output (LEDs), PF0/PF4 input (switches)
    LDR  r5, [r4, #0x400]     ; GPIODIR
    ORR  r5, r5, #0x0E         ; bits 1-3 out
    BIC  r5, r5, #0x11         ; 0,4 in
    STR  r5, [r4, #0x400]

    ; Digital enable all 5 pins
    LDR  r5, [r4, #0x51C]     ; GPIODEN
    ORR  r5, r5, #0x1F        ; PF0-PF4
    STR  r5, [r4, #0x51C]

    ; Enable pull-up on PF4 (SW1)
    LDR  r5, [r4, #0x510]     ; GPIOPUR
    ORR  r5, r5, #0x10        ; PF4 pull-up
    STR  r5, [r4, #0x510]

    ; edge sense config - clear PF4 for falling-edge only
    LDR  r5, [r4, #0x404]     ; GPIOIS
    BIC  r5, r5, #0x10        ; bit 4
    STR  r5, [r4, #0x404]
    LDR  r5, [r4, #0x408]     ; GPIOIBE
    BIC  r5, r5, #0x10
    STR  r5, [r4, #0x408]
    LDR  r5, [r4, #0x40C]     ; GPIOIEV
    BIC  r5, r5, #0x10        ; PF4
    STR  r5, [r4, #0x40C]

    ; Configure SW1 (PF4) interrupt: edge-triggered, falling edge
    LDR  r5, [r4, #0x41C]     ; GPIOICR
    ORR  r5, r5, #0x10        ; bit 4
    STR  r5, [r4, #0x41C]
    LDR  r5, [r4, #0x410]     ; GPIOIM
    ORR  r5, r5, #0x10        ; unmask PF4
    STR  r5, [r4, #0x410]

    ; Enable Port F interrupt in NVIC
    MOV  r4, #0xE100
    MOVT r4, #0xE000           ; NVIC ISER0: 0xE000E100
    LDR  r5, [r4]
    ORR  r5, r5, #0x40000000  ; IRQ30
    STR  r5, [r4]

;FOR ALICE LED INIT LED0-3 (PortD Pin 0-3)
	MOV r4, #0xE608
    MOVT r4, #0x400F 	;RCGC address 0x400FE608

	LDR r5, [r4]
	ORR r5, r5, #0x02 	;enable port B (bit 1)
	STR r5, [r4]

	MOV r4, #0xEA08
	MOVT r4, #0x400F 	;PRGPIO address 0x400FEA08

waitLED:
	LDR r5, [r4]
	AND r5, r5, #0x02 	;checks if port B is enabled
	CMP r5, #0
	BEQ waitLED			;loop until port B is ready

	MOV r4, #0x5000
	MOVT r4, #0x4000 	;PORT B base address 0x40005000

	LDR r5, [r4, #DIR] 	;GPIODIR
	ORR r5, r5, #0x0F 	;Pin 0, 1, 2, 3
	STR r5, [r4, #DIR] 	;GPIODIR for Port B

	LDR r5, [r4, #DEN] 	;GPIODEN
	ORR r5, r5, #0x0F 	;Pin 0, 1, 2, 3
	STR r5, [r4, #DEN] 	;GPIODEN for Port B

    LDR r5, [r4, #DATA]     ;GPIODATA
    BIC r5, r5, #0x0F       ;clear PB1-4
    ORR r5, r5, #0x00       ;Turns all LEDS off
	STR r5, [r4, #DATA]     ;GPIODATA for Port B

    POP  {r4-r5, lr}
    MOV  pc, lr

; flush - drain UART0 RX FIFO after long redraws
flush:
    PUSH {r4-r5, lr}
    MOV  r4, #0xC000
    MOVT r4, #0x4000           ; UART0 base: 0x4000C000
flush_loop:
    LDRB r5, [r4, #0x18]       ; read UARTFR
    TST  r5, #0x10              ; bit 4 = RXFE (RX FIFO Empty)
    BNE  flush_done             ; if RXFE=1, FIFO empty, done
    LDRB r5, [r4, #0x00]       ; read UARTDR to discard one byte
    B    flush_loop
flush_done:
    ; Also clear any pending RX / RX-timeout interrupt flags
    MOV  r4, #0xC044
    MOVT r4, #0x4000           ; UART0 ICR
    MOV  r5, #0x50             ; RXIC + RTIC
    STR  r5, [r4]
    POP  {r4-r5, lr}
    MOV  pc, lr

;--- uart_interrupt_init ---
uart_interrupt_init:
    PUSH {r4-r5, lr}

    ; Clear any pending UART RX interrupt
    MOV  r4, #0xC044
    MOVT r4, #0x4000           ; UART0 ICR: 0x4000C044
    MOV  r5, #0x10             ; RXIC
    STR  r5, [r4]              ; UARTICR

    ; Unmask RX and RX-timeout interrupts in UART IMSC
    MOV  r4, #0xC038
    MOVT r4, #0x4000           ; UART0 IMSC: 0x4000C038
    LDR  r5, [r4]              ; UARTIM
    ORR  r5, r5, #0x50         ; RXIM + RTIM
    STR  r5, [r4]

    ; Enable UART0 interrupt in NVIC
    MOV  r4, #0xE100
    MOVT r4, #0xE000           ; NVIC ISER0: 0xE000E100
    LDR  r5, [r4]
    ORR  r5, r5, #(1<<5)       ; IRQ5
    STR  r5, [r4]
    POP  {r4-r5, lr}
    MOV  pc, lr

;--- start_timer: 10 Hz, 1,600,000 cycles ---
start_timer:
    PUSH {r4-r5, lr}
    MOV  r4, #0x0000
    MOVT r4, #0x4003           ; Timer0A base: 0x40030000

    ; Disable timer before configuring
    LDR  r5, [r4, #0x00C]     ; GPTMCTL
    BIC  r5, r5, #1            ; TAEN off
    STR  r5, [r4, #0x00C]

    ; Set 32-bit periodic mode
    MOV  r5, #0
    STR  r5, [r4, #0x000]     ; GPTMCFG = 0 (32-bit)
    LDR  r5, [r4, #0x004]     ; GPTMTAMR
    ORR  r5, r5, #2            ; TAMR = periodic
    STR  r5, [r4, #0x004]

    ; Load reload value (1,600,000 = 10Hz at 16MHz)
    MOV  r5, #0x6A00
    MOVT r5, #0x0018           ; 0x00186A00 = 1,600,000
    STR  r5, [r4, #0x028]     ; GPTMTAILR

    ; Enable timeout interrupt
    LDR  r5, [r4, #0x018]     ; GPTMIMR
    ORR  r5, r5, #1            ; TATOIM
    STR  r5, [r4, #0x018]

    ; Enable timer IRQ in NVIC
    MOV  r4, #0xE100
    MOVT r4, #0xE000           ; NVIC: 0xE000E100
    LDR  r5, [r4]
    ORR  r5, r5, #(1<<19)     ; IRQ19
    STR  r5, [r4]

    ; Re-enable timer to start counting
    MOV  r4, #0x0000
    MOVT r4, #0x4003           ; Timer0A base: 0x40030000
    LDR  r5, [r4, #0x00C]     ; GPTMCTL
    ORR  r5, r5, #1            ; TAEN on
    STR  r5, [r4, #0x00C]
    POP  {r4-r5, lr}
    MOV  pc, lr

    .end
