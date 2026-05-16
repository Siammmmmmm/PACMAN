

# *PACMAN*
## Program Overview
**Uses Tiva TM4C123GH6PM Microcontroller**
Program starts with a prompt asking the player to press **`[space]`** to start game.
 
 After starting, `PACMAN` can be controlled using:
  **`[W][A][S][D]`** or **`[up arrow][left arrow][down arrow][right arrow]`**
keys to go *UP, LEFT, DOWN, RIGHT* respectively. 

`GHOSTS` randomly move around the board and `PACMAN` loses **1** life if they come in contact with eachother with the game ending after all **4** lives are lost. 
The lives are shown on the screen and also represented by the *number* of LEDs on the AliceEdu base board. 

Each `PELLET [.]` is eaten when `PACMAN` moves past it and is ***+10*** to the score. There are
`POWER pellets [O]` in each corner that is ***+50*** to the score and makes the `GHOSTS` *FRIGHTENED* for a short time, replacing their character with a green `[W]` and turning the RGB LED *blue* when consumed and then *red* when it is nearing the end. 
`PACMAN` can eat *FRIGHTENED* `GHOSTS` if it moves past them and is **+100 · 2^(x−1)** to the score
with **x** being the number of `GHOSTS` eaten.

Player *wins the round* if `PACMAN` eats all `PELLETS` and advances to the *next level*. 
Levels get progressively harder as `PACMAN` and the `GHOSTS` increase their *movement speed*. 

Player can press **`[SW1]`** on the Tiva board to pause and resume the game. Players are given the option to press **`[space]`** after losing all 4 lives to restart the game.
## Data Structures Summary

### Ghost Data Layout
6 bytes per ghost × 4 ghosts = 24 bytes total.
| Offset | Field | Description |
|--------|-------|-------------|
| 0 | `row` | Current row position |
| 1 | `col` | Current column position |
| 2 | `dir` | Direction (`1=up`, `2=down`, `3=left`, `4=right`) |
| 3 | `home_row` | Home/spawn row |
| 4 | `home_col` | Home/spawn column |
| 5 | `mode` | `0=waiting`, `1=chase`, `2=frightened` |

### Game State Values (`game_started`)
| Value | Constant | Description |
|-------|----------|-------------|
| 0 | `GS_WAITING` | Waiting for SPACE (title / game over) |
| 1 | `GS_RUNNING` | Normal gameplay |
| 2 | `GS_RESPAWN` | Redrawing after death (timer skips) |

### Direction Encoding
| Value | Direction |
|-------|-----------|
| 0 | Stopped |
| 1 | Up |
| 2 | Down |
| 3 | Left |
| 4 | Right |

### Maze Dimensions

| Constant | Value |
|----------|-------|
| `MAZE_COLS` | 28 |
| `MAZE_ROWS` | 33 |
| `BOARD_ROW` | 2 (screen offset) |
| `BOARD_COL` | 4 (screen offset) |
| Ghost House | rows 11–16, cols 9–18 |

 ## Skills demonstrated:
> 
> -  **Bare-metal ARM Cortex-M4 assembly** — game logic, interrupts, and hardware I/O written entirely in `.s` 
> -   **GPIO** — Port F for RGB LED and SW1 button input; Port B for 4-bit LED life counter via bitmask writes to `GPIODATA`
> -   **UART** — interrupt-driven input (`UART0_Handler`) for WASD/arrow key control; polled output for rendering ANSI escape sequences
> -   **Hardware timers** — GP Timer 0A configured for 10 Hz periodic interrupts driving the game loop; period adjusted per level for
> difficulty scaling
> -   **NVIC interrupt management** — registered and prioritized IRQs for UART0 (IRQ5), GP Timer (IRQ19), and Port F GPIO *(IRQ30)*
> -   **ANSI Escape Sequences** — full-screen maze drawn via ESC sequences; per-cell color coding for walls, pellets, ghosts, and
> Pac-Man without a framebuffer
> -   **Memory-mapped I/O** — direct register access to UART, GPIO, and timer peripherals using hardcoded base addresses and offsets


