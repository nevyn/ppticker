#import "PPTickerPrettyNumbers.h"


// Narrow space: E2 80 89 (U+2009)

NSString *PrettyStringWithInteger(NSUInteger value)
{
	NSUInteger digits = 0;
	
	NSUInteger temp = value;
	while (temp != 0)
	{
		temp /= 10;
		digits++;
	}
	if (value == 0)  digits = 1;
	
	NSUInteger spaces = (digits - 1) / 3;
	NSUInteger chars = spaces * 3 + digits;
	uint8_t string[chars];
	uint8_t *curr = string + chars - 1;
	NSUInteger count = 0;
	
	while (digits != 0)
	{
		char digit = value % 10;
		value /= 10;
		*curr-- = digit + '0';
		digits--;
		count++;
		
		if ((count % 3) == 0 && digits != 0)
		{
			// Insert Unicode thin space, U+2009, or E2 80 89 in UTF-8.
			*curr-- = 0x89;
			*curr-- = 0x80;
			*curr-- = 0xE2;
		}
	}
	
	return [[[NSString alloc] initWithBytes:string length:chars encoding:NSUTF8StringEncoding] autorelease];
}
