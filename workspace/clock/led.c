#define uint32 unsigned int
#define uint16 unsigned short int

#define Addr2Reg(x) (*(volatile uint32 *)x)
#define GPIOK_CON (*(volatile uint32 *)0x7F008800UL)
#define GPIOK_DAT (*(volatile uint32 *)0x7F008808UL)

#define GPIOK_OUT 0x11110000UL
#define LEN_ON 0
#define LEN_OFF 0xf0

void Delay(volatile unsigned int count)
{
    while(count > 0)
    {
        count--;
    }
}

int main()
{
    unsigned int delayCount = 0x100000;
    GPIOK_CON = GPIOK_OUT;

    while(1)
    {
        GPIOK_DAT = LEN_ON;
        Delay(2*delayCount);
        GPIOK_DAT = LEN_OFF;
        Delay(delayCount);
    }
    return 0;
}
