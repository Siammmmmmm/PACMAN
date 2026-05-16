//*****************************************************************************
// pacman_wrapper.c
// Entry point - identical pattern to lab_6_wrapper.c
// CCS calls main() -> main calls pacman() in assembly
//*****************************************************************************
extern void pacman(void);

int main(void)
{
    pacman();
    return 0;
}
