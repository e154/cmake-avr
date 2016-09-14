/*
 * blink
 */

#include <avr/io.h>
#include <util/delay.h>

int main(void)
{
    DDRD |= (1 << PD0);

	for(;;)
	{
		PORTD ^= ~(1 << PD0);
		_delay_ms(250);
	}
}
