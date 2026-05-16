//*****************************************************************************
// tm4c123gh6pm_startup_ccs.c
// Startup file for PacMan Lab 7 - CCS v12.2
//
// HOW THIS DIFFERS FROM THE DEFAULT:
//   Line 1: Added  extern void Timer_Handler(void);
//   Line 2: Added  extern void UART0_Handler(void);
//   Line 3: Added  extern void Switch_Handler(void);
//   Line 4: In the vector table, Timer_Handler replaces IntDefaultHandler
//            at position "Timer 0 subtimer A" (IRQ 19)
//   Line 5: UART0_Handler replaces IntDefaultHandler at "UART0" (IRQ 5)
//   Line 6: Switch_Handler replaces IntDefaultHandler at "GPIO Port F" (IRQ 30)
//
// Everything else is IDENTICAL to the CCS default startup.
// The names Timer_Handler, UART0_Handler, Switch_Handler MUST match
// exactly what is declared with .global in your .s files.
//*****************************************************************************

#include <stdint.h>

void ResetISR(void);
static void NmiSR(void);
static void FaultISR(void);
static void IntDefaultHandler(void);

extern void _c_int00(void);

// === ONLY THESE 3 LINES ARE ADDED vs. the default startup ===
extern void UART0_Handler(void);    // handles keyboard input (WASD, SPACE)
extern void Switch_Handler(void);   // handles SW1 pause/resume
extern void Timer_Handler(void);    // handles game tick (movement, ghosts, etc.)

extern uint32_t __STACK_TOP;

#pragma DATA_SECTION(g_pfnVectors, ".intvecs")
void (* const g_pfnVectors[])(void) =
{
    (void (*)(void))((uint32_t)&__STACK_TOP),
    ResetISR,                   // Reset
    NmiSR,                      // NMI
    FaultISR,                   // HardFault
    IntDefaultHandler,          // MPU Fault
    IntDefaultHandler,          // Bus Fault
    IntDefaultHandler,          // Usage Fault
    0,0,0,0,                    // Reserved
    IntDefaultHandler,          // SVCall
    IntDefaultHandler,          // Debug Monitor
    0,                          // Reserved
    IntDefaultHandler,          // PendSV
    IntDefaultHandler,          // SysTick
    IntDefaultHandler,          // IRQ0  GPIO Port A
    IntDefaultHandler,          // IRQ1  GPIO Port B
    IntDefaultHandler,          // IRQ2  GPIO Port C
    IntDefaultHandler,          // IRQ3  GPIO Port D
    IntDefaultHandler,          // IRQ4  GPIO Port E
    UART0_Handler,              // IRQ5  UART0  <-- CHANGED: keyboard input
    IntDefaultHandler,          // IRQ6  UART1
    IntDefaultHandler,          // IRQ7  SSI0
    IntDefaultHandler,          // IRQ8  I2C0
    IntDefaultHandler,          // IRQ9  PWM Fault
    IntDefaultHandler,          // IRQ10 PWM Gen 0
    IntDefaultHandler,          // IRQ11 PWM Gen 1
    IntDefaultHandler,          // IRQ12 PWM Gen 2
    IntDefaultHandler,          // IRQ13 QEI0
    IntDefaultHandler,          // IRQ14 ADC Seq 0
    IntDefaultHandler,          // IRQ15 ADC Seq 1
    IntDefaultHandler,          // IRQ16 ADC Seq 2
    IntDefaultHandler,          // IRQ17 ADC Seq 3
    IntDefaultHandler,          // IRQ18 Watchdog
    Timer_Handler,              // IRQ19 Timer0A  <-- CHANGED: game tick ISR
    IntDefaultHandler,          // IRQ20 Timer0B
    IntDefaultHandler,          // IRQ21 Timer1A
    IntDefaultHandler,          // IRQ22 Timer1B
    IntDefaultHandler,          // IRQ23 Timer2A
    IntDefaultHandler,          // IRQ24 Timer2B
    IntDefaultHandler,          // IRQ25 Analog Comp 0
    IntDefaultHandler,          // IRQ26 Analog Comp 1
    IntDefaultHandler,          // IRQ27 Analog Comp 2
    IntDefaultHandler,          // IRQ28 System Control
    IntDefaultHandler,          // IRQ29 Flash
    Switch_Handler,             // IRQ30 GPIO Port F  <-- CHANGED: SW1 pause
    IntDefaultHandler,          // IRQ31 GPIO Port G
    IntDefaultHandler,          // IRQ32 GPIO Port H
    IntDefaultHandler,          // IRQ33 UART2
    IntDefaultHandler,          // IRQ34 SSI1
    IntDefaultHandler,          // IRQ35 Timer3A
    IntDefaultHandler,          // IRQ36 Timer3B
    IntDefaultHandler,          // IRQ37 I2C1
    IntDefaultHandler,          // IRQ38 QEI1
    IntDefaultHandler,          // IRQ39 CAN0
    IntDefaultHandler,          // IRQ40 CAN1
    0, 0,                       // Reserved
    IntDefaultHandler,          // IRQ43 Hibernate
    IntDefaultHandler,          // IRQ44 USB0
    IntDefaultHandler,          // IRQ45 PWM Gen 3
    IntDefaultHandler,          // IRQ46 uDMA SW
    IntDefaultHandler,          // IRQ47 uDMA Error
    IntDefaultHandler,          // IRQ48 ADC1 Seq 0
    IntDefaultHandler,          // IRQ49 ADC1 Seq 1
    IntDefaultHandler,          // IRQ50 ADC1 Seq 2
    IntDefaultHandler,          // IRQ51 ADC1 Seq 3
    0, 0,                       // Reserved
    IntDefaultHandler,          // IRQ54 GPIO Port J
    IntDefaultHandler,          // IRQ55 GPIO Port K
    IntDefaultHandler,          // IRQ56 GPIO Port L
    IntDefaultHandler,          // IRQ57 SSI2
    IntDefaultHandler,          // IRQ58 SSI3
    IntDefaultHandler,          // IRQ59 UART3
    IntDefaultHandler,          // IRQ60 UART4
    IntDefaultHandler,          // IRQ61 UART5
    IntDefaultHandler,          // IRQ62 UART6
    IntDefaultHandler,          // IRQ63 UART7
    0, 0, 0, 0,                 // Reserved
    IntDefaultHandler,          // IRQ68 I2C2
    IntDefaultHandler,          // IRQ69 I2C3
    IntDefaultHandler,          // IRQ70 Timer4A
    IntDefaultHandler,          // IRQ71 Timer4B
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // Reserved
    IntDefaultHandler,          // IRQ96  Timer5A
    IntDefaultHandler,          // IRQ97  Timer5B
    IntDefaultHandler,          // IRQ98  Wide Timer0A
    IntDefaultHandler,          // IRQ99  Wide Timer0B
    IntDefaultHandler,          // IRQ100 Wide Timer1A
    IntDefaultHandler,          // IRQ101 Wide Timer1B
    IntDefaultHandler,          // IRQ102 Wide Timer2A
    IntDefaultHandler,          // IRQ103 Wide Timer2B
    IntDefaultHandler,          // IRQ104 Wide Timer3A
    IntDefaultHandler,          // IRQ105 Wide Timer3B
    IntDefaultHandler,          // IRQ106 Wide Timer4A
    IntDefaultHandler,          // IRQ107 Wide Timer4B
    IntDefaultHandler,          // IRQ108 Wide Timer5A
    IntDefaultHandler,          // IRQ109 Wide Timer5B
    IntDefaultHandler,          // IRQ110 FPU
    0, 0,                       // Reserved
    IntDefaultHandler,          // IRQ113 I2C4
    IntDefaultHandler,          // IRQ114 I2C5
    IntDefaultHandler,          // IRQ115 GPIO Port M
    IntDefaultHandler,          // IRQ116 GPIO Port N
    IntDefaultHandler,          // IRQ117 QEI2
    0, 0,
    IntDefaultHandler,          // IRQ120 GPIO Port P0
    IntDefaultHandler,          // IRQ121 GPIO Port P1
    IntDefaultHandler,          // IRQ122 GPIO Port P2
    IntDefaultHandler,          // IRQ123 GPIO Port P3
    IntDefaultHandler,          // IRQ124 GPIO Port P4
    IntDefaultHandler,          // IRQ125 GPIO Port P5
    IntDefaultHandler,          // IRQ126 GPIO Port P6
    IntDefaultHandler,          // IRQ127 GPIO Port P7
    IntDefaultHandler,          // IRQ128 GPIO Port Q0
    IntDefaultHandler,          // IRQ129 GPIO Port Q1
    IntDefaultHandler,          // IRQ130 GPIO Port Q2
    IntDefaultHandler,          // IRQ131 GPIO Port Q3
    IntDefaultHandler,          // IRQ132 GPIO Port Q4
    IntDefaultHandler,          // IRQ133 GPIO Port Q5
    IntDefaultHandler,          // IRQ134 GPIO Port Q6
    IntDefaultHandler,          // IRQ135 GPIO Port Q7
    IntDefaultHandler,          // IRQ136 GPIO Port R
    IntDefaultHandler,          // IRQ137 GPIO Port S
    IntDefaultHandler,          // IRQ138 PWM1 Gen 0
    IntDefaultHandler,          // IRQ139 PWM1 Gen 1
    IntDefaultHandler,          // IRQ140 PWM1 Gen 2
    IntDefaultHandler,          // IRQ141 PWM1 Gen 3
    IntDefaultHandler           // IRQ142 PWM1 Fault
};

void ResetISR(void)
{
    __asm("    .global _c_int00\n"
          "    b.w     _c_int00");
}

static void NmiSR(void)    { while(1){} }
static void FaultISR(void) { while(1){} }
static void IntDefaultHandler(void) { while(1){} }
