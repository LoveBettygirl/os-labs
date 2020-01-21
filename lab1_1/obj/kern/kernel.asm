
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1a 10 f0 	movl   $0xf0101a40,(%esp)
f0100055:	e8 47 09 00 00       	call   f01009a1 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 01 07 00 00       	call   f0100788 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1a 10 f0 	movl   $0xf0101a5c,(%esp)
f0100092:	e8 0a 09 00 00       	call   f01009a1 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 5e 14 00 00       	call   f0101523 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 93 04 00 00       	call   f010055d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1a 10 f0 	movl   $0xf0101a77,(%esp)
f01000d9:	e8 c3 08 00 00       	call   f01009a1 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 36 07 00 00       	call   f010082c <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 92 1a 10 f0 	movl   $0xf0101a92,(%esp)
f010012c:	e8 70 08 00 00       	call   f01009a1 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 31 08 00 00       	call   f010096e <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ce 1a 10 f0 	movl   $0xf0101ace,(%esp)
f0100144:	e8 58 08 00 00       	call   f01009a1 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 d7 06 00 00       	call   f010082c <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 aa 1a 10 f0 	movl   $0xf0101aaa,(%esp)
f0100176:	e8 26 08 00 00       	call   f01009a1 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 e4 07 00 00       	call   f010096e <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ce 1a 10 f0 	movl   $0xf0101ace,(%esp)
f0100191:	e8 0b 08 00 00       	call   f01009a1 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 26                	jmp    f01001fb <cons_intr+0x31>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 22                	je     f01001fb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f2:	0f 44 d0             	cmove  %eax,%edx
f01001f5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
	while ((c = (*proc)()) != -1) {
f01001fb:	ff d3                	call   *%ebx
f01001fd:	89 c2                	mov    %eax,%edx
f01001ff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100202:	75 d1                	jne    f01001d5 <cons_intr+0xb>
	}
}
f0100204:	83 c4 04             	add    $0x4,%esp
f0100207:	5b                   	pop    %ebx
f0100208:	5d                   	pop    %ebp
f0100209:	c3                   	ret    

f010020a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	57                   	push   %edi
f010020e:	56                   	push   %esi
f010020f:	53                   	push   %ebx
f0100210:	83 ec 2c             	sub    $0x2c,%esp
f0100213:	89 c7                	mov    %eax,%edi
f0100215:	bb 01 32 00 00       	mov    $0x3201,%ebx
f010021a:	be fd 03 00 00       	mov    $0x3fd,%esi
f010021f:	eb 05                	jmp    f0100226 <cons_putc+0x1c>
		delay();
f0100221:	e8 7a ff ff ff       	call   f01001a0 <delay>
f0100226:	89 f2                	mov    %esi,%edx
f0100228:	ec                   	in     (%dx),%al
	for (i = 0;
f0100229:	a8 20                	test   $0x20,%al
f010022b:	75 05                	jne    f0100232 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022d:	83 eb 01             	sub    $0x1,%ebx
f0100230:	75 ef                	jne    f0100221 <cons_putc+0x17>
	outb(COM1 + COM_TX, c);
f0100232:	89 f8                	mov    %edi,%eax
f0100234:	25 ff 00 00 00       	and    $0xff,%eax
f0100239:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100241:	ee                   	out    %al,(%dx)
f0100242:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100247:	be 79 03 00 00       	mov    $0x379,%esi
f010024c:	eb 05                	jmp    f0100253 <cons_putc+0x49>
		delay();
f010024e:	e8 4d ff ff ff       	call   f01001a0 <delay>
f0100253:	89 f2                	mov    %esi,%edx
f0100255:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100256:	84 c0                	test   %al,%al
f0100258:	78 05                	js     f010025f <cons_putc+0x55>
f010025a:	83 eb 01             	sub    $0x1,%ebx
f010025d:	75 ef                	jne    f010024e <cons_putc+0x44>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010025f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100264:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100268:	ee                   	out    %al,(%dx)
f0100269:	b2 7a                	mov    $0x7a,%dl
f010026b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100270:	ee                   	out    %al,(%dx)
f0100271:	b8 08 00 00 00       	mov    $0x8,%eax
f0100276:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100277:	89 fa                	mov    %edi,%edx
f0100279:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010027f:	89 f8                	mov    %edi,%eax
f0100281:	80 cc 07             	or     $0x7,%ah
f0100284:	85 d2                	test   %edx,%edx
f0100286:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100289:	89 f8                	mov    %edi,%eax
f010028b:	25 ff 00 00 00       	and    $0xff,%eax
f0100290:	83 f8 09             	cmp    $0x9,%eax
f0100293:	74 7a                	je     f010030f <cons_putc+0x105>
f0100295:	83 f8 09             	cmp    $0x9,%eax
f0100298:	7f 0b                	jg     f01002a5 <cons_putc+0x9b>
f010029a:	83 f8 08             	cmp    $0x8,%eax
f010029d:	0f 85 a0 00 00 00    	jne    f0100343 <cons_putc+0x139>
f01002a3:	eb 13                	jmp    f01002b8 <cons_putc+0xae>
f01002a5:	83 f8 0a             	cmp    $0xa,%eax
f01002a8:	74 3f                	je     f01002e9 <cons_putc+0xdf>
f01002aa:	83 f8 0d             	cmp    $0xd,%eax
f01002ad:	8d 76 00             	lea    0x0(%esi),%esi
f01002b0:	0f 85 8d 00 00 00    	jne    f0100343 <cons_putc+0x139>
f01002b6:	eb 39                	jmp    f01002f1 <cons_putc+0xe7>
		if (crt_pos > 0) {
f01002b8:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002bf:	66 85 c0             	test   %ax,%ax
f01002c2:	0f 84 e5 00 00 00    	je     f01003ad <cons_putc+0x1a3>
			crt_pos--;
f01002c8:	83 e8 01             	sub    $0x1,%eax
f01002cb:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002d1:	0f b7 c0             	movzwl %ax,%eax
f01002d4:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002da:	83 cf 20             	or     $0x20,%edi
f01002dd:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002e7:	eb 77                	jmp    f0100360 <cons_putc+0x156>
		crt_pos += CRT_COLS;
f01002e9:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002f0:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01002f1:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002f8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002fe:	c1 e8 16             	shr    $0x16,%eax
f0100301:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100304:	c1 e0 04             	shl    $0x4,%eax
f0100307:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f010030d:	eb 51                	jmp    f0100360 <cons_putc+0x156>
		cons_putc(' ');
f010030f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100314:	e8 f1 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 e7 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 dd fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d3 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100337:	b8 20 00 00 00       	mov    $0x20,%eax
f010033c:	e8 c9 fe ff ff       	call   f010020a <cons_putc>
f0100341:	eb 1d                	jmp    f0100360 <cons_putc+0x156>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100343:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f010034a:	0f b7 c8             	movzwl %ax,%ecx
f010034d:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f0100353:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100357:	83 c0 01             	add    $0x1,%eax
f010035a:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
	if (crt_pos >= CRT_SIZE) {
f0100360:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100367:	cf 07 
f0100369:	76 42                	jbe    f01003ad <cons_putc+0x1a3>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010036b:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100370:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100377:	00 
f0100378:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010037e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100382:	89 04 24             	mov    %eax,(%esp)
f0100385:	e8 f7 11 00 00       	call   f0101581 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010038a:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100390:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100395:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039b:	83 c0 01             	add    $0x1,%eax
f010039e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003a3:	75 f0                	jne    f0100395 <cons_putc+0x18b>
		crt_pos -= CRT_COLS;
f01003a5:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003ac:	50 
	outb(addr_6845, 14);
f01003ad:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003b3:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003b8:	89 ca                	mov    %ecx,%edx
f01003ba:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003bb:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003c2:	8d 71 01             	lea    0x1(%ecx),%esi
f01003c5:	89 d8                	mov    %ebx,%eax
f01003c7:	66 c1 e8 08          	shr    $0x8,%ax
f01003cb:	89 f2                	mov    %esi,%edx
f01003cd:	ee                   	out    %al,(%dx)
f01003ce:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003d3:	89 ca                	mov    %ecx,%edx
f01003d5:	ee                   	out    %al,(%dx)
f01003d6:	89 d8                	mov    %ebx,%eax
f01003d8:	89 f2                	mov    %esi,%edx
f01003da:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003db:	83 c4 2c             	add    $0x2c,%esp
f01003de:	5b                   	pop    %ebx
f01003df:	5e                   	pop    %esi
f01003e0:	5f                   	pop    %edi
f01003e1:	5d                   	pop    %ebp
f01003e2:	c3                   	ret    

f01003e3 <kbd_proc_data>:
{
f01003e3:	55                   	push   %ebp
f01003e4:	89 e5                	mov    %esp,%ebp
f01003e6:	53                   	push   %ebx
f01003e7:	83 ec 14             	sub    $0x14,%esp
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ea:	ba 64 00 00 00       	mov    $0x64,%edx
f01003ef:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003f0:	a8 01                	test   $0x1,%al
f01003f2:	0f 84 e5 00 00 00    	je     f01004dd <kbd_proc_data+0xfa>
f01003f8:	b2 60                	mov    $0x60,%dl
f01003fa:	ec                   	in     (%dx),%al
f01003fb:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01003fd:	3c e0                	cmp    $0xe0,%al
f01003ff:	75 11                	jne    f0100412 <kbd_proc_data+0x2f>
		shift |= E0ESC;
f0100401:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100408:	bb 00 00 00 00       	mov    $0x0,%ebx
f010040d:	e9 d0 00 00 00       	jmp    f01004e2 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f0100412:	84 c0                	test   %al,%al
f0100414:	79 37                	jns    f010044d <kbd_proc_data+0x6a>
		data = (shift & E0ESC ? data : data & 0x7F);
f0100416:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010041c:	89 cb                	mov    %ecx,%ebx
f010041e:	83 e3 40             	and    $0x40,%ebx
f0100421:	83 e0 7f             	and    $0x7f,%eax
f0100424:	85 db                	test   %ebx,%ebx
f0100426:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100429:	0f b6 d2             	movzbl %dl,%edx
f010042c:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100433:	83 c8 40             	or     $0x40,%eax
f0100436:	0f b6 c0             	movzbl %al,%eax
f0100439:	f7 d0                	not    %eax
f010043b:	21 c1                	and    %eax,%ecx
f010043d:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100443:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100448:	e9 95 00 00 00       	jmp    f01004e2 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f010044d:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100453:	f6 c1 40             	test   $0x40,%cl
f0100456:	74 0e                	je     f0100466 <kbd_proc_data+0x83>
		data |= 0x80;
f0100458:	89 c2                	mov    %eax,%edx
f010045a:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010045d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100460:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	shift |= shiftcode[data];
f0100466:	0f b6 d2             	movzbl %dl,%edx
f0100469:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100470:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100476:	0f b6 8a 00 1c 10 f0 	movzbl -0xfefe400(%edx),%ecx
f010047d:	31 c8                	xor    %ecx,%eax
f010047f:	a3 28 25 11 f0       	mov    %eax,0xf0112528
	c = charcode[shift & (CTL | SHIFT)][data];
f0100484:	89 c1                	mov    %eax,%ecx
f0100486:	83 e1 03             	and    $0x3,%ecx
f0100489:	8b 0c 8d 00 1d 10 f0 	mov    -0xfefe300(,%ecx,4),%ecx
f0100490:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100494:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100497:	a8 08                	test   $0x8,%al
f0100499:	74 1b                	je     f01004b6 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010049b:	89 da                	mov    %ebx,%edx
f010049d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004a0:	83 f9 19             	cmp    $0x19,%ecx
f01004a3:	77 05                	ja     f01004aa <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004a5:	83 eb 20             	sub    $0x20,%ebx
f01004a8:	eb 0c                	jmp    f01004b6 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004aa:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01004ad:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004b0:	83 fa 19             	cmp    $0x19,%edx
f01004b3:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004b6:	f7 d0                	not    %eax
f01004b8:	a8 06                	test   $0x6,%al
f01004ba:	75 26                	jne    f01004e2 <kbd_proc_data+0xff>
f01004bc:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004c2:	75 1e                	jne    f01004e2 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f01004c4:	c7 04 24 c4 1a 10 f0 	movl   $0xf0101ac4,(%esp)
f01004cb:	e8 d1 04 00 00       	call   f01009a1 <cprintf>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d0:	ba 92 00 00 00       	mov    $0x92,%edx
f01004d5:	b8 03 00 00 00       	mov    $0x3,%eax
f01004da:	ee                   	out    %al,(%dx)
f01004db:	eb 05                	jmp    f01004e2 <kbd_proc_data+0xff>
		return -1;
f01004dd:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
}
f01004e2:	89 d8                	mov    %ebx,%eax
f01004e4:	83 c4 14             	add    $0x14,%esp
f01004e7:	5b                   	pop    %ebx
f01004e8:	5d                   	pop    %ebp
f01004e9:	c3                   	ret    

f01004ea <serial_intr>:
	if (serial_exists)
f01004ea:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004f1:	74 11                	je     f0100504 <serial_intr+0x1a>
{
f01004f3:	55                   	push   %ebp
f01004f4:	89 e5                	mov    %esp,%ebp
f01004f6:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004f9:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f01004fe:	e8 c7 fc ff ff       	call   f01001ca <cons_intr>
}
f0100503:	c9                   	leave  
f0100504:	f3 c3                	repz ret 

f0100506 <kbd_intr>:
{
f0100506:	55                   	push   %ebp
f0100507:	89 e5                	mov    %esp,%ebp
f0100509:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050c:	b8 e3 03 10 f0       	mov    $0xf01003e3,%eax
f0100511:	e8 b4 fc ff ff       	call   f01001ca <cons_intr>
}
f0100516:	c9                   	leave  
f0100517:	c3                   	ret    

f0100518 <cons_getc>:
{
f0100518:	55                   	push   %ebp
f0100519:	89 e5                	mov    %esp,%ebp
f010051b:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010051e:	e8 c7 ff ff ff       	call   f01004ea <serial_intr>
	kbd_intr();
f0100523:	e8 de ff ff ff       	call   f0100506 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100528:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f010052e:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100534:	74 20                	je     f0100556 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100536:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f010053d:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f0100540:	81 fa 00 02 00 00    	cmp    $0x200,%edx
		c = cons.buf[cons.rpos++];
f0100546:	b9 00 00 00 00       	mov    $0x0,%ecx
f010054b:	0f 44 d1             	cmove  %ecx,%edx
f010054e:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100554:	eb 05                	jmp    f010055b <cons_getc+0x43>
	return 0;
f0100556:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055b:	c9                   	leave  
f010055c:	c3                   	ret    

f010055d <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010055d:	55                   	push   %ebp
f010055e:	89 e5                	mov    %esp,%ebp
f0100560:	57                   	push   %edi
f0100561:	56                   	push   %esi
f0100562:	53                   	push   %ebx
f0100563:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100566:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100574:	5a a5 
	if (*cp != 0xA55A) {
f0100576:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100581:	74 11                	je     f0100594 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100583:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f010058a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058d:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100592:	eb 16                	jmp    f01005aa <cons_init+0x4d>
		*cp = was;
f0100594:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059b:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005a2:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a5:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f01005aa:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005b0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b5:	89 ca                	mov    %ecx,%edx
f01005b7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b8:	8d 59 01             	lea    0x1(%ecx),%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bb:	89 da                	mov    %ebx,%edx
f01005bd:	ec                   	in     (%dx),%al
f01005be:	0f b6 f0             	movzbl %al,%esi
f01005c1:	c1 e6 08             	shl    $0x8,%esi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c9:	89 ca                	mov    %ecx,%edx
f01005cb:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	89 da                	mov    %ebx,%edx
f01005ce:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005cf:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530
	pos |= inb(addr_6845 + 1);
f01005d5:	0f b6 d8             	movzbl %al,%ebx
f01005d8:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f01005da:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e1:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01005eb:	89 f2                	mov    %esi,%edx
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	b2 fb                	mov    $0xfb,%dl
f01005f0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f5:	ee                   	out    %al,(%dx)
f01005f6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fb:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100600:	89 da                	mov    %ebx,%edx
f0100602:	ee                   	out    %al,(%dx)
f0100603:	b2 f9                	mov    $0xf9,%dl
f0100605:	b8 00 00 00 00       	mov    $0x0,%eax
f010060a:	ee                   	out    %al,(%dx)
f010060b:	b2 fb                	mov    $0xfb,%dl
f010060d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100612:	ee                   	out    %al,(%dx)
f0100613:	b2 fc                	mov    $0xfc,%dl
f0100615:	b8 00 00 00 00       	mov    $0x0,%eax
f010061a:	ee                   	out    %al,(%dx)
f010061b:	b2 f9                	mov    $0xf9,%dl
f010061d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100622:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100623:	b2 fd                	mov    $0xfd,%dl
f0100625:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100626:	3c ff                	cmp    $0xff,%al
f0100628:	0f 95 c1             	setne  %cl
f010062b:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f0100631:	89 f2                	mov    %esi,%edx
f0100633:	ec                   	in     (%dx),%al
f0100634:	89 da                	mov    %ebx,%edx
f0100636:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100637:	84 c9                	test   %cl,%cl
f0100639:	75 0c                	jne    f0100647 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063b:	c7 04 24 d0 1a 10 f0 	movl   $0xf0101ad0,(%esp)
f0100642:	e8 5a 03 00 00       	call   f01009a1 <cprintf>
}
f0100647:	83 c4 1c             	add    $0x1c,%esp
f010064a:	5b                   	pop    %ebx
f010064b:	5e                   	pop    %esi
f010064c:	5f                   	pop    %edi
f010064d:	5d                   	pop    %ebp
f010064e:	c3                   	ret    

f010064f <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064f:	55                   	push   %ebp
f0100650:	89 e5                	mov    %esp,%ebp
f0100652:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100655:	8b 45 08             	mov    0x8(%ebp),%eax
f0100658:	e8 ad fb ff ff       	call   f010020a <cons_putc>
}
f010065d:	c9                   	leave  
f010065e:	c3                   	ret    

f010065f <getchar>:

int
getchar(void)
{
f010065f:	55                   	push   %ebp
f0100660:	89 e5                	mov    %esp,%ebp
f0100662:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100665:	e8 ae fe ff ff       	call   f0100518 <cons_getc>
f010066a:	85 c0                	test   %eax,%eax
f010066c:	74 f7                	je     f0100665 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066e:	c9                   	leave  
f010066f:	c3                   	ret    

f0100670 <iscons>:

int
iscons(int fdnum)
{
f0100670:	55                   	push   %ebp
f0100671:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100673:	b8 01 00 00 00       	mov    $0x1,%eax
f0100678:	5d                   	pop    %ebp
f0100679:	c3                   	ret    
f010067a:	66 90                	xchg   %ax,%ax
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 10 1d 10 f0 	movl   $0xf0101d10,(%esp)
f010068d:	e8 0f 03 00 00       	call   f01009a1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100692:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100699:	00 
f010069a:	c7 04 24 d0 1d 10 f0 	movl   $0xf0101dd0,(%esp)
f01006a1:	e8 fb 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f01006bd:	e8 df 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c2:	c7 44 24 08 2f 1a 10 	movl   $0x101a2f,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 2f 1a 10 	movl   $0xf0101a2f,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f01006d9:	e8 c3 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006de:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f01006f5:	e8 a7 02 00 00       	call   f01009a1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fa:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 64 1e 10 f0 	movl   $0xf0101e64,(%esp)
f0100711:	e8 8b 02 00 00       	call   f01009a1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100716:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010071b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100720:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100725:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072b:	85 c0                	test   %eax,%eax
f010072d:	0f 48 c2             	cmovs  %edx,%eax
f0100730:	c1 f8 0a             	sar    $0xa,%eax
f0100733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100737:	c7 04 24 88 1e 10 f0 	movl   $0xf0101e88,(%esp)
f010073e:	e8 5e 02 00 00       	call   f01009a1 <cprintf>
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <mon_help>:
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	56                   	push   %esi
f010074e:	53                   	push   %ebx
f010074f:	83 ec 10             	sub    $0x10,%esp
f0100752:	bb a4 1f 10 f0       	mov    $0xf0101fa4,%ebx
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100757:	be c8 1f 10 f0       	mov    $0xf0101fc8,%esi
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010075c:	8b 03                	mov    (%ebx),%eax
f010075e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100762:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100765:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100769:	c7 04 24 29 1d 10 f0 	movl   $0xf0101d29,(%esp)
f0100770:	e8 2c 02 00 00       	call   f01009a1 <cprintf>
f0100775:	83 c3 0c             	add    $0xc,%ebx
	for (i = 0; i < NCOMMANDS; i++)
f0100778:	39 f3                	cmp    %esi,%ebx
f010077a:	75 e0                	jne    f010075c <mon_help+0x12>
}
f010077c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100781:	83 c4 10             	add    $0x10,%esp
f0100784:	5b                   	pop    %ebx
f0100785:	5e                   	pop    %esi
f0100786:	5d                   	pop    %ebp
f0100787:	c3                   	ret    

f0100788 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100788:	55                   	push   %ebp
f0100789:	89 e5                	mov    %esp,%ebp
f010078b:	57                   	push   %edi
f010078c:	56                   	push   %esi
f010078d:	53                   	push   %ebx
f010078e:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	// Read ebp of mon_backtrace()
	unsigned int *ebp = (unsigned int *) read_ebp();
f0100791:	89 eb                	mov    %ebp,%ebx
	// The first five args of the current function
	unsigned int args[5];
	cprintf("Stack backtrace:\n");
f0100793:	c7 04 24 32 1d 10 f0 	movl   $0xf0101d32,(%esp)
f010079a:	e8 02 02 00 00       	call   f01009a1 <cprintf>
		args[3] = (unsigned int) *(ebp + 5);
		args[4] = (unsigned int) *(ebp + 6);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip,
			args[0], args[1], args[2], args[3], args[4]);
		struct Eipdebuginfo info;
		debuginfo_eip((uintptr_t) eip, &info);
f010079f:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while(ebp) {
f01007a2:	eb 77                	jmp    f010081b <mon_backtrace+0x93>
		unsigned int eip = (unsigned int) *(ebp + 1);
f01007a4:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip,
f01007a7:	8b 43 18             	mov    0x18(%ebx),%eax
f01007aa:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007ae:	8b 43 14             	mov    0x14(%ebx),%eax
f01007b1:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007b5:	8b 43 10             	mov    0x10(%ebx),%eax
f01007b8:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007bc:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007bf:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007c3:	8b 43 08             	mov    0x8(%ebx),%eax
f01007c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007ca:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007d2:	c7 04 24 b4 1e 10 f0 	movl   $0xf0101eb4,(%esp)
f01007d9:	e8 c3 01 00 00       	call   f01009a1 <cprintf>
		debuginfo_eip((uintptr_t) eip, &info);
f01007de:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007e2:	89 34 24             	mov    %esi,(%esp)
f01007e5:	e8 ae 02 00 00       	call   f0100a98 <debuginfo_eip>
		cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line,
f01007ea:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01007ed:	89 74 24 14          	mov    %esi,0x14(%esp)
f01007f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007f4:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007f8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100802:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100806:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100809:	89 44 24 04          	mov    %eax,0x4(%esp)
f010080d:	c7 04 24 44 1d 10 f0 	movl   $0xf0101d44,(%esp)
f0100814:	e8 88 01 00 00       	call   f01009a1 <cprintf>
			info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = (unsigned int *) *ebp;
f0100819:	8b 1b                	mov    (%ebx),%ebx
	while(ebp) {
f010081b:	85 db                	test   %ebx,%ebx
f010081d:	75 85                	jne    f01007a4 <mon_backtrace+0x1c>
	}
	return 0;
}
f010081f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100824:	83 c4 4c             	add    $0x4c,%esp
f0100827:	5b                   	pop    %ebx
f0100828:	5e                   	pop    %esi
f0100829:	5f                   	pop    %edi
f010082a:	5d                   	pop    %ebp
f010082b:	c3                   	ret    

f010082c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010082c:	55                   	push   %ebp
f010082d:	89 e5                	mov    %esp,%ebp
f010082f:	57                   	push   %edi
f0100830:	56                   	push   %esi
f0100831:	53                   	push   %ebx
f0100832:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100835:	c7 04 24 ec 1e 10 f0 	movl   $0xf0101eec,(%esp)
f010083c:	e8 60 01 00 00       	call   f01009a1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100841:	c7 04 24 10 1f 10 f0 	movl   $0xf0101f10,(%esp)
f0100848:	e8 54 01 00 00       	call   f01009a1 <cprintf>


	while (1) {
		buf = readline("K> ");
f010084d:	c7 04 24 5d 1d 10 f0 	movl   $0xf0101d5d,(%esp)
f0100854:	e8 77 0a 00 00       	call   f01012d0 <readline>
f0100859:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f010085b:	85 c0                	test   %eax,%eax
f010085d:	74 ee                	je     f010084d <monitor+0x21>
	argv[argc] = 0;
f010085f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100866:	bb 00 00 00 00       	mov    $0x0,%ebx
f010086b:	eb 06                	jmp    f0100873 <monitor+0x47>
			*buf++ = 0;
f010086d:	c6 06 00             	movb   $0x0,(%esi)
f0100870:	83 c6 01             	add    $0x1,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100873:	0f b6 06             	movzbl (%esi),%eax
f0100876:	84 c0                	test   %al,%al
f0100878:	74 63                	je     f01008dd <monitor+0xb1>
f010087a:	0f be c0             	movsbl %al,%eax
f010087d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100881:	c7 04 24 61 1d 10 f0 	movl   $0xf0101d61,(%esp)
f0100888:	e8 59 0c 00 00       	call   f01014e6 <strchr>
f010088d:	85 c0                	test   %eax,%eax
f010088f:	75 dc                	jne    f010086d <monitor+0x41>
		if (*buf == 0)
f0100891:	80 3e 00             	cmpb   $0x0,(%esi)
f0100894:	74 47                	je     f01008dd <monitor+0xb1>
		if (argc == MAXARGS-1) {
f0100896:	83 fb 0f             	cmp    $0xf,%ebx
f0100899:	75 16                	jne    f01008b1 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010089b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008a2:	00 
f01008a3:	c7 04 24 66 1d 10 f0 	movl   $0xf0101d66,(%esp)
f01008aa:	e8 f2 00 00 00       	call   f01009a1 <cprintf>
f01008af:	eb 9c                	jmp    f010084d <monitor+0x21>
		argv[argc++] = buf;
f01008b1:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f01008b5:	83 c3 01             	add    $0x1,%ebx
f01008b8:	eb 03                	jmp    f01008bd <monitor+0x91>
			buf++;
f01008ba:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008bd:	0f b6 06             	movzbl (%esi),%eax
f01008c0:	84 c0                	test   %al,%al
f01008c2:	74 af                	je     f0100873 <monitor+0x47>
f01008c4:	0f be c0             	movsbl %al,%eax
f01008c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cb:	c7 04 24 61 1d 10 f0 	movl   $0xf0101d61,(%esp)
f01008d2:	e8 0f 0c 00 00       	call   f01014e6 <strchr>
f01008d7:	85 c0                	test   %eax,%eax
f01008d9:	74 df                	je     f01008ba <monitor+0x8e>
f01008db:	eb 96                	jmp    f0100873 <monitor+0x47>
	argv[argc] = 0;
f01008dd:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f01008e4:	00 
	if (argc == 0)
f01008e5:	85 db                	test   %ebx,%ebx
f01008e7:	0f 84 60 ff ff ff    	je     f010084d <monitor+0x21>
f01008ed:	bf a0 1f 10 f0       	mov    $0xf0101fa0,%edi
f01008f2:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(argv[0], commands[i].name) == 0)
f01008f7:	8b 07                	mov    (%edi),%eax
f01008f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008fd:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100900:	89 04 24             	mov    %eax,(%esp)
f0100903:	e8 80 0b 00 00       	call   f0101488 <strcmp>
f0100908:	85 c0                	test   %eax,%eax
f010090a:	75 24                	jne    f0100930 <monitor+0x104>
			return commands[i].func(argc, argv, tf);
f010090c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010090f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100912:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100916:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100919:	89 54 24 04          	mov    %edx,0x4(%esp)
f010091d:	89 1c 24             	mov    %ebx,(%esp)
f0100920:	ff 14 85 a8 1f 10 f0 	call   *-0xfefe058(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100927:	85 c0                	test   %eax,%eax
f0100929:	78 28                	js     f0100953 <monitor+0x127>
f010092b:	e9 1d ff ff ff       	jmp    f010084d <monitor+0x21>
	for (i = 0; i < NCOMMANDS; i++) {
f0100930:	83 c6 01             	add    $0x1,%esi
f0100933:	83 c7 0c             	add    $0xc,%edi
f0100936:	83 fe 03             	cmp    $0x3,%esi
f0100939:	75 bc                	jne    f01008f7 <monitor+0xcb>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010093e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100942:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f0100949:	e8 53 00 00 00       	call   f01009a1 <cprintf>
f010094e:	e9 fa fe ff ff       	jmp    f010084d <monitor+0x21>
				break;
	}
}
f0100953:	83 c4 5c             	add    $0x5c,%esp
f0100956:	5b                   	pop    %ebx
f0100957:	5e                   	pop    %esi
f0100958:	5f                   	pop    %edi
f0100959:	5d                   	pop    %ebp
f010095a:	c3                   	ret    

f010095b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010095b:	55                   	push   %ebp
f010095c:	89 e5                	mov    %esp,%ebp
f010095e:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100961:	8b 45 08             	mov    0x8(%ebp),%eax
f0100964:	89 04 24             	mov    %eax,(%esp)
f0100967:	e8 e3 fc ff ff       	call   f010064f <cputchar>
	*cnt++;
}
f010096c:	c9                   	leave  
f010096d:	c3                   	ret    

f010096e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010096e:	55                   	push   %ebp
f010096f:	89 e5                	mov    %esp,%ebp
f0100971:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100974:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010097b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010097e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100982:	8b 45 08             	mov    0x8(%ebp),%eax
f0100985:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100989:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010098c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100990:	c7 04 24 5b 09 10 f0 	movl   $0xf010095b,(%esp)
f0100997:	e8 b9 04 00 00       	call   f0100e55 <vprintfmt>
	return cnt;
}
f010099c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010099f:	c9                   	leave  
f01009a0:	c3                   	ret    

f01009a1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a1:	55                   	push   %ebp
f01009a2:	89 e5                	mov    %esp,%ebp
f01009a4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009a7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009aa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b1:	89 04 24             	mov    %eax,(%esp)
f01009b4:	e8 b5 ff ff ff       	call   f010096e <vcprintf>
	va_end(ap);

	return cnt;
}
f01009b9:	c9                   	leave  
f01009ba:	c3                   	ret    

f01009bb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009bb:	55                   	push   %ebp
f01009bc:	89 e5                	mov    %esp,%ebp
f01009be:	57                   	push   %edi
f01009bf:	56                   	push   %esi
f01009c0:	53                   	push   %ebx
f01009c1:	83 ec 10             	sub    $0x10,%esp
f01009c4:	89 c6                	mov    %eax,%esi
f01009c6:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009c9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009cc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009cf:	8b 1a                	mov    (%edx),%ebx
f01009d1:	8b 09                	mov    (%ecx),%ecx
f01009d3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01009d6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01009dd:	eb 77                	jmp    f0100a56 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01009df:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009e2:	01 d8                	add    %ebx,%eax
f01009e4:	b9 02 00 00 00       	mov    $0x2,%ecx
f01009e9:	99                   	cltd   
f01009ea:	f7 f9                	idiv   %ecx
f01009ec:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ee:	eb 01                	jmp    f01009f1 <stab_binsearch+0x36>
			m--;
f01009f0:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f01009f1:	39 d9                	cmp    %ebx,%ecx
f01009f3:	7c 1d                	jl     f0100a12 <stab_binsearch+0x57>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009f5:	6b d1 0c             	imul   $0xc,%ecx,%edx
		while (m >= l && stabs[m].n_type != type)
f01009f8:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009fd:	39 fa                	cmp    %edi,%edx
f01009ff:	75 ef                	jne    f01009f0 <stab_binsearch+0x35>
f0100a01:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a04:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a07:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a0b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a0e:	73 18                	jae    f0100a28 <stab_binsearch+0x6d>
f0100a10:	eb 05                	jmp    f0100a17 <stab_binsearch+0x5c>
			l = true_m + 1;
f0100a12:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a15:	eb 3f                	jmp    f0100a56 <stab_binsearch+0x9b>
			*region_left = m;
f0100a17:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a1a:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100a1c:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0100a1f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a26:	eb 2e                	jmp    f0100a56 <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0100a28:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a2b:	73 15                	jae    f0100a42 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a2d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a30:	49                   	dec    %ecx
f0100a31:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a37:	89 08                	mov    %ecx,(%eax)
		any_matches = 1;
f0100a39:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a40:	eb 14                	jmp    f0100a56 <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a42:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a45:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a48:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100a4a:	ff 45 0c             	incl   0xc(%ebp)
f0100a4d:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0100a4f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0100a56:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a59:	7e 84                	jle    f01009df <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0100a5b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a5f:	75 0d                	jne    f0100a6e <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a61:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a64:	8b 02                	mov    (%edx),%eax
f0100a66:	48                   	dec    %eax
f0100a67:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a6a:	89 01                	mov    %eax,(%ecx)
f0100a6c:	eb 22                	jmp    f0100a90 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a6e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a71:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a73:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a76:	8b 0a                	mov    (%edx),%ecx
		for (l = *region_right;
f0100a78:	eb 01                	jmp    f0100a7b <stab_binsearch+0xc0>
		     l--)
f0100a7a:	48                   	dec    %eax
		for (l = *region_right;
f0100a7b:	39 c1                	cmp    %eax,%ecx
f0100a7d:	7d 0c                	jge    f0100a8b <stab_binsearch+0xd0>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a7f:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a82:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a87:	39 fa                	cmp    %edi,%edx
f0100a89:	75 ef                	jne    f0100a7a <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0100a8b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a8e:	89 02                	mov    %eax,(%edx)
	}
}
f0100a90:	83 c4 10             	add    $0x10,%esp
f0100a93:	5b                   	pop    %ebx
f0100a94:	5e                   	pop    %esi
f0100a95:	5f                   	pop    %edi
f0100a96:	5d                   	pop    %ebp
f0100a97:	c3                   	ret    

f0100a98 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a98:	55                   	push   %ebp
f0100a99:	89 e5                	mov    %esp,%ebp
f0100a9b:	83 ec 58             	sub    $0x58,%esp
f0100a9e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100aa1:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100aa4:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100aa7:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aaa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aad:	c7 03 c4 1f 10 f0    	movl   $0xf0101fc4,(%ebx)
	info->eip_line = 0;
f0100ab3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aba:	c7 43 08 c4 1f 10 f0 	movl   $0xf0101fc4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ac1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ac8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100acb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ad2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ad8:	76 12                	jbe    f0100aec <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ada:	b8 21 77 10 f0       	mov    $0xf0107721,%eax
f0100adf:	3d d5 5d 10 f0       	cmp    $0xf0105dd5,%eax
f0100ae4:	0f 86 ca 01 00 00    	jbe    f0100cb4 <debuginfo_eip+0x21c>
f0100aea:	eb 1c                	jmp    f0100b08 <debuginfo_eip+0x70>
  	        panic("User address");
f0100aec:	c7 44 24 08 ce 1f 10 	movl   $0xf0101fce,0x8(%esp)
f0100af3:	f0 
f0100af4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100afb:	00 
f0100afc:	c7 04 24 db 1f 10 f0 	movl   $0xf0101fdb,(%esp)
f0100b03:	e8 f0 f5 ff ff       	call   f01000f8 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b08:	80 3d 20 77 10 f0 00 	cmpb   $0x0,0xf0107720
f0100b0f:	0f 85 a6 01 00 00    	jne    f0100cbb <debuginfo_eip+0x223>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b15:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b1c:	b8 d4 5d 10 f0       	mov    $0xf0105dd4,%eax
f0100b21:	2d 10 22 10 f0       	sub    $0xf0102210,%eax
f0100b26:	c1 f8 02             	sar    $0x2,%eax
f0100b29:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b2f:	83 e8 01             	sub    $0x1,%eax
f0100b32:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b35:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b39:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b40:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b43:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b46:	b8 10 22 10 f0       	mov    $0xf0102210,%eax
f0100b4b:	e8 6b fe ff ff       	call   f01009bb <stab_binsearch>
	if (lfile == 0)
f0100b50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b53:	85 c0                	test   %eax,%eax
f0100b55:	0f 84 67 01 00 00    	je     f0100cc2 <debuginfo_eip+0x22a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b5b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b61:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b64:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b68:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b6f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b72:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b75:	b8 10 22 10 f0       	mov    $0xf0102210,%eax
f0100b7a:	e8 3c fe ff ff       	call   f01009bb <stab_binsearch>

	if (lfun <= rfun) {
f0100b7f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b82:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b85:	39 d0                	cmp    %edx,%eax
f0100b87:	7f 3d                	jg     f0100bc6 <debuginfo_eip+0x12e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b89:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100b8c:	8d b9 10 22 10 f0    	lea    -0xfefddf0(%ecx),%edi
f0100b92:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b95:	8b 89 10 22 10 f0    	mov    -0xfefddf0(%ecx),%ecx
f0100b9b:	bf 21 77 10 f0       	mov    $0xf0107721,%edi
f0100ba0:	81 ef d5 5d 10 f0    	sub    $0xf0105dd5,%edi
f0100ba6:	39 f9                	cmp    %edi,%ecx
f0100ba8:	73 09                	jae    f0100bb3 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100baa:	81 c1 d5 5d 10 f0    	add    $0xf0105dd5,%ecx
f0100bb0:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bb3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bb6:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bb9:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bbc:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bbe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bc1:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bc4:	eb 0f                	jmp    f0100bd5 <debuginfo_eip+0x13d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bc6:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bc9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bcc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bcf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bd2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bd5:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bdc:	00 
f0100bdd:	8b 43 08             	mov    0x8(%ebx),%eax
f0100be0:	89 04 24             	mov    %eax,(%esp)
f0100be3:	e8 1f 09 00 00       	call   f0101507 <strfind>
f0100be8:	2b 43 08             	sub    0x8(%ebx),%eax
f0100beb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bee:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bf2:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100bf9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bfc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bff:	b8 10 22 10 f0       	mov    $0xf0102210,%eax
f0100c04:	e8 b2 fd ff ff       	call   f01009bb <stab_binsearch>

	if (lline <= rline) {
f0100c09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c0c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c0f:	0f 8f b4 00 00 00    	jg     f0100cc9 <debuginfo_eip+0x231>
		info->eip_line = stabs[lline].n_desc;
f0100c15:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c18:	0f b7 80 16 22 10 f0 	movzwl -0xfefddea(%eax),%eax
f0100c1f:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c25:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100c2b:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c2e:	81 c2 10 22 10 f0    	add    $0xf0102210,%edx
	while (lline >= lfile
f0100c34:	eb 06                	jmp    f0100c3c <debuginfo_eip+0x1a4>
f0100c36:	83 e8 01             	sub    $0x1,%eax
f0100c39:	83 ea 0c             	sub    $0xc,%edx
f0100c3c:	89 c6                	mov    %eax,%esi
f0100c3e:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c41:	7f 33                	jg     f0100c76 <debuginfo_eip+0x1de>
	       && stabs[lline].n_type != N_SOL
f0100c43:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c47:	80 f9 84             	cmp    $0x84,%cl
f0100c4a:	74 0b                	je     f0100c57 <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c4c:	80 f9 64             	cmp    $0x64,%cl
f0100c4f:	75 e5                	jne    f0100c36 <debuginfo_eip+0x19e>
f0100c51:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c55:	74 df                	je     f0100c36 <debuginfo_eip+0x19e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c57:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c5a:	8b 86 10 22 10 f0    	mov    -0xfefddf0(%esi),%eax
f0100c60:	ba 21 77 10 f0       	mov    $0xf0107721,%edx
f0100c65:	81 ea d5 5d 10 f0    	sub    $0xf0105dd5,%edx
f0100c6b:	39 d0                	cmp    %edx,%eax
f0100c6d:	73 07                	jae    f0100c76 <debuginfo_eip+0x1de>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c6f:	05 d5 5d 10 f0       	add    $0xf0105dd5,%eax
f0100c74:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c76:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c79:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c7c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100c81:	39 ca                	cmp    %ecx,%edx
f0100c83:	7d 50                	jge    f0100cd5 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
f0100c85:	8d 42 01             	lea    0x1(%edx),%eax
f0100c88:	89 c2                	mov    %eax,%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100c8a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c8d:	05 10 22 10 f0       	add    $0xf0102210,%eax
f0100c92:	89 ce                	mov    %ecx,%esi
		for (lline = lfun + 1;
f0100c94:	eb 04                	jmp    f0100c9a <debuginfo_eip+0x202>
			info->eip_fn_narg++;
f0100c96:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0100c9a:	39 d6                	cmp    %edx,%esi
f0100c9c:	7e 32                	jle    f0100cd0 <debuginfo_eip+0x238>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c9e:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100ca2:	83 c2 01             	add    $0x1,%edx
f0100ca5:	83 c0 0c             	add    $0xc,%eax
f0100ca8:	80 f9 a0             	cmp    $0xa0,%cl
f0100cab:	74 e9                	je     f0100c96 <debuginfo_eip+0x1fe>
	return 0;
f0100cad:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb2:	eb 21                	jmp    f0100cd5 <debuginfo_eip+0x23d>
		return -1;
f0100cb4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb9:	eb 1a                	jmp    f0100cd5 <debuginfo_eip+0x23d>
f0100cbb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc0:	eb 13                	jmp    f0100cd5 <debuginfo_eip+0x23d>
		return -1;
f0100cc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc7:	eb 0c                	jmp    f0100cd5 <debuginfo_eip+0x23d>
		return -1;
f0100cc9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cce:	eb 05                	jmp    f0100cd5 <debuginfo_eip+0x23d>
	return 0;
f0100cd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cd5:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100cd8:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100cdb:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100cde:	89 ec                	mov    %ebp,%esp
f0100ce0:	5d                   	pop    %ebp
f0100ce1:	c3                   	ret    
f0100ce2:	66 90                	xchg   %ax,%ax
f0100ce4:	66 90                	xchg   %ax,%ax
f0100ce6:	66 90                	xchg   %ax,%ax
f0100ce8:	66 90                	xchg   %ax,%ax
f0100cea:	66 90                	xchg   %ax,%ax
f0100cec:	66 90                	xchg   %ax,%ax
f0100cee:	66 90                	xchg   %ax,%ax

f0100cf0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cf0:	55                   	push   %ebp
f0100cf1:	89 e5                	mov    %esp,%ebp
f0100cf3:	57                   	push   %edi
f0100cf4:	56                   	push   %esi
f0100cf5:	53                   	push   %ebx
f0100cf6:	83 ec 4c             	sub    $0x4c,%esp
f0100cf9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cfc:	89 d7                	mov    %edx,%edi
f0100cfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d01:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100d04:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d07:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100d0a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d0d:	85 db                	test   %ebx,%ebx
f0100d0f:	75 08                	jne    f0100d19 <printnum+0x29>
f0100d11:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100d14:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100d17:	77 6c                	ja     f0100d85 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d19:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100d1c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100d20:	83 ee 01             	sub    $0x1,%esi
f0100d23:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d27:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d2a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100d2e:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d32:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d36:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d39:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100d3c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d43:	00 
f0100d44:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100d47:	89 1c 24             	mov    %ebx,(%esp)
f0100d4a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d4d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d51:	e8 fa 09 00 00       	call   f0101750 <__udivdi3>
f0100d56:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d59:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d5c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d60:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d64:	89 04 24             	mov    %eax,(%esp)
f0100d67:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d6b:	89 fa                	mov    %edi,%edx
f0100d6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d70:	e8 7b ff ff ff       	call   f0100cf0 <printnum>
f0100d75:	eb 1b                	jmp    f0100d92 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d77:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d7b:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d7e:	89 04 24             	mov    %eax,(%esp)
f0100d81:	ff d3                	call   *%ebx
f0100d83:	eb 03                	jmp    f0100d88 <printnum+0x98>
f0100d85:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
f0100d88:	83 ee 01             	sub    $0x1,%esi
f0100d8b:	85 f6                	test   %esi,%esi
f0100d8d:	7f e8                	jg     f0100d77 <printnum+0x87>
f0100d8f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d92:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d96:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d9a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d9d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100da1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100da8:	00 
f0100da9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100dac:	89 1c 24             	mov    %ebx,(%esp)
f0100daf:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100db2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100db6:	e8 e5 0a 00 00       	call   f01018a0 <__umoddi3>
f0100dbb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dbf:	0f be 80 e9 1f 10 f0 	movsbl -0xfefe017(%eax),%eax
f0100dc6:	89 04 24             	mov    %eax,(%esp)
f0100dc9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dcc:	ff d0                	call   *%eax
}
f0100dce:	83 c4 4c             	add    $0x4c,%esp
f0100dd1:	5b                   	pop    %ebx
f0100dd2:	5e                   	pop    %esi
f0100dd3:	5f                   	pop    %edi
f0100dd4:	5d                   	pop    %ebp
f0100dd5:	c3                   	ret    

f0100dd6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100dd6:	55                   	push   %ebp
f0100dd7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100dd9:	83 fa 01             	cmp    $0x1,%edx
f0100ddc:	7e 0e                	jle    f0100dec <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100dde:	8b 10                	mov    (%eax),%edx
f0100de0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100de3:	89 08                	mov    %ecx,(%eax)
f0100de5:	8b 02                	mov    (%edx),%eax
f0100de7:	8b 52 04             	mov    0x4(%edx),%edx
f0100dea:	eb 22                	jmp    f0100e0e <getuint+0x38>
	else if (lflag)
f0100dec:	85 d2                	test   %edx,%edx
f0100dee:	74 10                	je     f0100e00 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100df0:	8b 10                	mov    (%eax),%edx
f0100df2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100df5:	89 08                	mov    %ecx,(%eax)
f0100df7:	8b 02                	mov    (%edx),%eax
f0100df9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dfe:	eb 0e                	jmp    f0100e0e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e00:	8b 10                	mov    (%eax),%edx
f0100e02:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e05:	89 08                	mov    %ecx,(%eax)
f0100e07:	8b 02                	mov    (%edx),%eax
f0100e09:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e0e:	5d                   	pop    %ebp
f0100e0f:	c3                   	ret    

f0100e10 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e10:	55                   	push   %ebp
f0100e11:	89 e5                	mov    %esp,%ebp
f0100e13:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e16:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e1a:	8b 10                	mov    (%eax),%edx
f0100e1c:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e1f:	73 0a                	jae    f0100e2b <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e21:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e24:	88 0a                	mov    %cl,(%edx)
f0100e26:	83 c2 01             	add    $0x1,%edx
f0100e29:	89 10                	mov    %edx,(%eax)
}
f0100e2b:	5d                   	pop    %ebp
f0100e2c:	c3                   	ret    

f0100e2d <printfmt>:
{
f0100e2d:	55                   	push   %ebp
f0100e2e:	89 e5                	mov    %esp,%ebp
f0100e30:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0100e33:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e36:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e3a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e3d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e41:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e48:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e4b:	89 04 24             	mov    %eax,(%esp)
f0100e4e:	e8 02 00 00 00       	call   f0100e55 <vprintfmt>
}
f0100e53:	c9                   	leave  
f0100e54:	c3                   	ret    

f0100e55 <vprintfmt>:
{
f0100e55:	55                   	push   %ebp
f0100e56:	89 e5                	mov    %esp,%ebp
f0100e58:	57                   	push   %edi
f0100e59:	56                   	push   %esi
f0100e5a:	53                   	push   %ebx
f0100e5b:	83 ec 4c             	sub    $0x4c,%esp
f0100e5e:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e61:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e64:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e67:	eb 11                	jmp    f0100e7a <vprintfmt+0x25>
			if (ch == '\0')
f0100e69:	85 c0                	test   %eax,%eax
f0100e6b:	0f 84 cf 03 00 00    	je     f0101240 <vprintfmt+0x3eb>
			putch(ch, putdat);
f0100e71:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e75:	89 04 24             	mov    %eax,(%esp)
f0100e78:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e7a:	0f b6 07             	movzbl (%edi),%eax
f0100e7d:	83 c7 01             	add    $0x1,%edi
f0100e80:	83 f8 25             	cmp    $0x25,%eax
f0100e83:	75 e4                	jne    f0100e69 <vprintfmt+0x14>
f0100e85:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100e89:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100e90:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100e97:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100e9e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ea3:	eb 2b                	jmp    f0100ed0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0100ea5:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
f0100ea8:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100eac:	eb 22                	jmp    f0100ed0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0100eae:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
f0100eb1:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0100eb5:	eb 19                	jmp    f0100ed0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0100eb7:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
f0100eba:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ec1:	eb 0d                	jmp    f0100ed0 <vprintfmt+0x7b>
				width = precision, precision = -1;
f0100ec3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ec6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ec9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ed0:	0f b6 07             	movzbl (%edi),%eax
f0100ed3:	8d 4f 01             	lea    0x1(%edi),%ecx
f0100ed6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ed9:	0f b6 0f             	movzbl (%edi),%ecx
f0100edc:	83 e9 23             	sub    $0x23,%ecx
f0100edf:	80 f9 55             	cmp    $0x55,%cl
f0100ee2:	0f 87 3b 03 00 00    	ja     f0101223 <vprintfmt+0x3ce>
f0100ee8:	0f b6 c9             	movzbl %cl,%ecx
f0100eeb:	ff 24 8d 80 20 10 f0 	jmp    *-0xfefdf80(,%ecx,4)
f0100ef2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100ef5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100efc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100eff:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
f0100f04:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100f07:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100f0b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100f0e:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f11:	83 f9 09             	cmp    $0x9,%ecx
f0100f14:	77 2f                	ja     f0100f45 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
f0100f16:	83 c7 01             	add    $0x1,%edi
			}
f0100f19:	eb e9                	jmp    f0100f04 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
f0100f1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1e:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f21:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f24:	8b 00                	mov    (%eax),%eax
f0100f26:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f29:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
f0100f2c:	eb 1d                	jmp    f0100f4b <vprintfmt+0xf6>
			if (width < 0)
f0100f2e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f32:	78 83                	js     f0100eb7 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
f0100f34:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100f37:	eb 97                	jmp    f0100ed0 <vprintfmt+0x7b>
f0100f39:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
f0100f3c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100f43:	eb 8b                	jmp    f0100ed0 <vprintfmt+0x7b>
f0100f45:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f48:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
f0100f4b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f4f:	0f 89 7b ff ff ff    	jns    f0100ed0 <vprintfmt+0x7b>
f0100f55:	e9 69 ff ff ff       	jmp    f0100ec3 <vprintfmt+0x6e>
			lflag++;
f0100f5a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f0100f5d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
f0100f60:	e9 6b ff ff ff       	jmp    f0100ed0 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
f0100f65:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f68:	8d 50 04             	lea    0x4(%eax),%edx
f0100f6b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f6e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f72:	8b 00                	mov    (%eax),%eax
f0100f74:	89 04 24             	mov    %eax,(%esp)
f0100f77:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f0100f79:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f0100f7c:	e9 f9 fe ff ff       	jmp    f0100e7a <vprintfmt+0x25>
			err = va_arg(ap, int);
f0100f81:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f84:	8d 50 04             	lea    0x4(%eax),%edx
f0100f87:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f8a:	8b 00                	mov    (%eax),%eax
f0100f8c:	89 c2                	mov    %eax,%edx
f0100f8e:	c1 fa 1f             	sar    $0x1f,%edx
f0100f91:	31 d0                	xor    %edx,%eax
f0100f93:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f95:	83 f8 07             	cmp    $0x7,%eax
f0100f98:	7f 0b                	jg     f0100fa5 <vprintfmt+0x150>
f0100f9a:	8b 14 85 e0 21 10 f0 	mov    -0xfefde20(,%eax,4),%edx
f0100fa1:	85 d2                	test   %edx,%edx
f0100fa3:	75 20                	jne    f0100fc5 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f0100fa5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fa9:	c7 44 24 08 01 20 10 	movl   $0xf0102001,0x8(%esp)
f0100fb0:	f0 
f0100fb1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fb5:	89 34 24             	mov    %esi,(%esp)
f0100fb8:	e8 70 fe ff ff       	call   f0100e2d <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f0100fbd:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
f0100fc0:	e9 b5 fe ff ff       	jmp    f0100e7a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0100fc5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fc9:	c7 44 24 08 0a 20 10 	movl   $0xf010200a,0x8(%esp)
f0100fd0:	f0 
f0100fd1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fd5:	89 34 24             	mov    %esi,(%esp)
f0100fd8:	e8 50 fe ff ff       	call   f0100e2d <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f0100fdd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100fe0:	e9 95 fe ff ff       	jmp    f0100e7a <vprintfmt+0x25>
f0100fe5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100fe8:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100feb:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0100fee:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff1:	8d 50 04             	lea    0x4(%eax),%edx
f0100ff4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ff9:	85 ff                	test   %edi,%edi
f0100ffb:	b8 fa 1f 10 f0       	mov    $0xf0101ffa,%eax
f0101000:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101003:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0101007:	0f 84 9b 00 00 00    	je     f01010a8 <vprintfmt+0x253>
f010100d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101011:	0f 8e 9f 00 00 00    	jle    f01010b6 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101017:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010101b:	89 3c 24             	mov    %edi,(%esp)
f010101e:	e8 95 03 00 00       	call   f01013b8 <strnlen>
f0101023:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101026:	29 c2                	sub    %eax,%edx
f0101028:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f010102b:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f010102f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101032:	89 7d c8             	mov    %edi,-0x38(%ebp)
f0101035:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101037:	eb 0f                	jmp    f0101048 <vprintfmt+0x1f3>
					putch(padc, putdat);
f0101039:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010103d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101040:	89 04 24             	mov    %eax,(%esp)
f0101043:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101045:	83 ef 01             	sub    $0x1,%edi
f0101048:	85 ff                	test   %edi,%edi
f010104a:	7f ed                	jg     f0101039 <vprintfmt+0x1e4>
f010104c:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010104f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101053:	b8 00 00 00 00       	mov    $0x0,%eax
f0101058:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
f010105c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010105f:	29 c2                	sub    %eax,%edx
f0101061:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101064:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101067:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010106a:	89 d3                	mov    %edx,%ebx
f010106c:	eb 54                	jmp    f01010c2 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
f010106e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101072:	74 20                	je     f0101094 <vprintfmt+0x23f>
f0101074:	0f be d2             	movsbl %dl,%edx
f0101077:	83 ea 20             	sub    $0x20,%edx
f010107a:	83 fa 5e             	cmp    $0x5e,%edx
f010107d:	76 15                	jbe    f0101094 <vprintfmt+0x23f>
					putch('?', putdat);
f010107f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101082:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101086:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010108d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101090:	ff d0                	call   *%eax
f0101092:	eb 0f                	jmp    f01010a3 <vprintfmt+0x24e>
					putch(ch, putdat);
f0101094:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101097:	89 54 24 04          	mov    %edx,0x4(%esp)
f010109b:	89 04 24             	mov    %eax,(%esp)
f010109e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01010a1:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010a3:	83 eb 01             	sub    $0x1,%ebx
f01010a6:	eb 1a                	jmp    f01010c2 <vprintfmt+0x26d>
f01010a8:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010ab:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01010ae:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01010b1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010b4:	eb 0c                	jmp    f01010c2 <vprintfmt+0x26d>
f01010b6:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010b9:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01010bc:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01010bf:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010c2:	0f b6 17             	movzbl (%edi),%edx
f01010c5:	0f be c2             	movsbl %dl,%eax
f01010c8:	83 c7 01             	add    $0x1,%edi
f01010cb:	85 c0                	test   %eax,%eax
f01010cd:	74 29                	je     f01010f8 <vprintfmt+0x2a3>
f01010cf:	85 f6                	test   %esi,%esi
f01010d1:	78 9b                	js     f010106e <vprintfmt+0x219>
f01010d3:	83 ee 01             	sub    $0x1,%esi
f01010d6:	79 96                	jns    f010106e <vprintfmt+0x219>
f01010d8:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01010db:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010de:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01010e1:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01010e4:	eb 1a                	jmp    f0101100 <vprintfmt+0x2ab>
				putch(' ', putdat);
f01010e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ea:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010f1:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01010f3:	83 ef 01             	sub    $0x1,%edi
f01010f6:	eb 08                	jmp    f0101100 <vprintfmt+0x2ab>
f01010f8:	89 df                	mov    %ebx,%edi
f01010fa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010fd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101100:	85 ff                	test   %edi,%edi
f0101102:	7f e2                	jg     f01010e6 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
f0101104:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101107:	e9 6e fd ff ff       	jmp    f0100e7a <vprintfmt+0x25>
	if (lflag >= 2)
f010110c:	83 fa 01             	cmp    $0x1,%edx
f010110f:	7e 16                	jle    f0101127 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f0101111:	8b 45 14             	mov    0x14(%ebp),%eax
f0101114:	8d 50 08             	lea    0x8(%eax),%edx
f0101117:	89 55 14             	mov    %edx,0x14(%ebp)
f010111a:	8b 10                	mov    (%eax),%edx
f010111c:	8b 48 04             	mov    0x4(%eax),%ecx
f010111f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101122:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101125:	eb 32                	jmp    f0101159 <vprintfmt+0x304>
	else if (lflag)
f0101127:	85 d2                	test   %edx,%edx
f0101129:	74 18                	je     f0101143 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
f010112b:	8b 45 14             	mov    0x14(%ebp),%eax
f010112e:	8d 50 04             	lea    0x4(%eax),%edx
f0101131:	89 55 14             	mov    %edx,0x14(%ebp)
f0101134:	8b 00                	mov    (%eax),%eax
f0101136:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101139:	89 c1                	mov    %eax,%ecx
f010113b:	c1 f9 1f             	sar    $0x1f,%ecx
f010113e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101141:	eb 16                	jmp    f0101159 <vprintfmt+0x304>
		return va_arg(*ap, int);
f0101143:	8b 45 14             	mov    0x14(%ebp),%eax
f0101146:	8d 50 04             	lea    0x4(%eax),%edx
f0101149:	89 55 14             	mov    %edx,0x14(%ebp)
f010114c:	8b 00                	mov    (%eax),%eax
f010114e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101151:	89 c7                	mov    %eax,%edi
f0101153:	c1 ff 1f             	sar    $0x1f,%edi
f0101156:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
f0101159:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010115c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
f010115f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0101164:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101168:	79 7d                	jns    f01011e7 <vprintfmt+0x392>
				putch('-', putdat);
f010116a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010116e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101175:	ff d6                	call   *%esi
				num = -(long long) num;
f0101177:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010117a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010117d:	f7 d8                	neg    %eax
f010117f:	83 d2 00             	adc    $0x0,%edx
f0101182:	f7 da                	neg    %edx
			base = 10;
f0101184:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101189:	eb 5c                	jmp    f01011e7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f010118b:	8d 45 14             	lea    0x14(%ebp),%eax
f010118e:	e8 43 fc ff ff       	call   f0100dd6 <getuint>
			base = 10;
f0101193:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101198:	eb 4d                	jmp    f01011e7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f010119a:	8d 45 14             	lea    0x14(%ebp),%eax
f010119d:	e8 34 fc ff ff       	call   f0100dd6 <getuint>
			base = 8;
f01011a2:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011a7:	eb 3e                	jmp    f01011e7 <vprintfmt+0x392>
			putch('0', putdat);
f01011a9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ad:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011b4:	ff d6                	call   *%esi
			putch('x', putdat);
f01011b6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ba:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011c1:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f01011c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c6:	8d 50 04             	lea    0x4(%eax),%edx
f01011c9:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01011cc:	8b 00                	mov    (%eax),%eax
f01011ce:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01011d3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011d8:	eb 0d                	jmp    f01011e7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f01011da:	8d 45 14             	lea    0x14(%ebp),%eax
f01011dd:	e8 f4 fb ff ff       	call   f0100dd6 <getuint>
			base = 16;
f01011e2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01011e7:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01011eb:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01011ef:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01011f2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01011f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01011fa:	89 04 24             	mov    %eax,(%esp)
f01011fd:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101201:	89 da                	mov    %ebx,%edx
f0101203:	89 f0                	mov    %esi,%eax
f0101205:	e8 e6 fa ff ff       	call   f0100cf0 <printnum>
			break;
f010120a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010120d:	e9 68 fc ff ff       	jmp    f0100e7a <vprintfmt+0x25>
			putch(ch, putdat);
f0101212:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101216:	89 04 24             	mov    %eax,(%esp)
f0101219:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f010121b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f010121e:	e9 57 fc ff ff       	jmp    f0100e7a <vprintfmt+0x25>
			putch('%', putdat);
f0101223:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101227:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010122e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101230:	eb 03                	jmp    f0101235 <vprintfmt+0x3e0>
f0101232:	83 ef 01             	sub    $0x1,%edi
f0101235:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101239:	75 f7                	jne    f0101232 <vprintfmt+0x3dd>
f010123b:	e9 3a fc ff ff       	jmp    f0100e7a <vprintfmt+0x25>
}
f0101240:	83 c4 4c             	add    $0x4c,%esp
f0101243:	5b                   	pop    %ebx
f0101244:	5e                   	pop    %esi
f0101245:	5f                   	pop    %edi
f0101246:	5d                   	pop    %ebp
f0101247:	c3                   	ret    

f0101248 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101248:	55                   	push   %ebp
f0101249:	89 e5                	mov    %esp,%ebp
f010124b:	83 ec 28             	sub    $0x28,%esp
f010124e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101251:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101254:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101257:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010125b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010125e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101265:	85 d2                	test   %edx,%edx
f0101267:	7e 30                	jle    f0101299 <vsnprintf+0x51>
f0101269:	85 c0                	test   %eax,%eax
f010126b:	74 2c                	je     f0101299 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010126d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101270:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101274:	8b 45 10             	mov    0x10(%ebp),%eax
f0101277:	89 44 24 08          	mov    %eax,0x8(%esp)
f010127b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010127e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101282:	c7 04 24 10 0e 10 f0 	movl   $0xf0100e10,(%esp)
f0101289:	e8 c7 fb ff ff       	call   f0100e55 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010128e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101291:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101294:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101297:	eb 05                	jmp    f010129e <vsnprintf+0x56>
		return -E_INVAL;
f0101299:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f010129e:	c9                   	leave  
f010129f:	c3                   	ret    

f01012a0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012a0:	55                   	push   %ebp
f01012a1:	89 e5                	mov    %esp,%ebp
f01012a3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012a6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ad:	8b 45 10             	mov    0x10(%ebp),%eax
f01012b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01012be:	89 04 24             	mov    %eax,(%esp)
f01012c1:	e8 82 ff ff ff       	call   f0101248 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012c6:	c9                   	leave  
f01012c7:	c3                   	ret    
f01012c8:	66 90                	xchg   %ax,%ax
f01012ca:	66 90                	xchg   %ax,%ax
f01012cc:	66 90                	xchg   %ax,%ax
f01012ce:	66 90                	xchg   %ax,%ax

f01012d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	57                   	push   %edi
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 1c             	sub    $0x1c,%esp
f01012d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 10                	je     f01012f0 <readline+0x20>
		cprintf("%s", prompt);
f01012e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e4:	c7 04 24 0a 20 10 f0 	movl   $0xf010200a,(%esp)
f01012eb:	e8 b1 f6 ff ff       	call   f01009a1 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012f7:	e8 74 f3 ff ff       	call   f0100670 <iscons>
f01012fc:	89 c7                	mov    %eax,%edi
	i = 0;
f01012fe:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101303:	e8 57 f3 ff ff       	call   f010065f <getchar>
f0101308:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010130a:	85 c0                	test   %eax,%eax
f010130c:	79 17                	jns    f0101325 <readline+0x55>
			cprintf("read error: %e\n", c);
f010130e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101312:	c7 04 24 00 22 10 f0 	movl   $0xf0102200,(%esp)
f0101319:	e8 83 f6 ff ff       	call   f01009a1 <cprintf>
			return NULL;
f010131e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101323:	eb 6d                	jmp    f0101392 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101325:	83 f8 7f             	cmp    $0x7f,%eax
f0101328:	74 05                	je     f010132f <readline+0x5f>
f010132a:	83 f8 08             	cmp    $0x8,%eax
f010132d:	75 19                	jne    f0101348 <readline+0x78>
f010132f:	85 f6                	test   %esi,%esi
f0101331:	7e 15                	jle    f0101348 <readline+0x78>
			if (echoing)
f0101333:	85 ff                	test   %edi,%edi
f0101335:	74 0c                	je     f0101343 <readline+0x73>
				cputchar('\b');
f0101337:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010133e:	e8 0c f3 ff ff       	call   f010064f <cputchar>
			i--;
f0101343:	83 ee 01             	sub    $0x1,%esi
f0101346:	eb bb                	jmp    f0101303 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101348:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010134e:	7f 1c                	jg     f010136c <readline+0x9c>
f0101350:	83 fb 1f             	cmp    $0x1f,%ebx
f0101353:	7e 17                	jle    f010136c <readline+0x9c>
			if (echoing)
f0101355:	85 ff                	test   %edi,%edi
f0101357:	74 08                	je     f0101361 <readline+0x91>
				cputchar(c);
f0101359:	89 1c 24             	mov    %ebx,(%esp)
f010135c:	e8 ee f2 ff ff       	call   f010064f <cputchar>
			buf[i++] = c;
f0101361:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101367:	83 c6 01             	add    $0x1,%esi
f010136a:	eb 97                	jmp    f0101303 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010136c:	83 fb 0d             	cmp    $0xd,%ebx
f010136f:	74 05                	je     f0101376 <readline+0xa6>
f0101371:	83 fb 0a             	cmp    $0xa,%ebx
f0101374:	75 8d                	jne    f0101303 <readline+0x33>
			if (echoing)
f0101376:	85 ff                	test   %edi,%edi
f0101378:	74 0c                	je     f0101386 <readline+0xb6>
				cputchar('\n');
f010137a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101381:	e8 c9 f2 ff ff       	call   f010064f <cputchar>
			buf[i] = 0;
f0101386:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010138d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101392:	83 c4 1c             	add    $0x1c,%esp
f0101395:	5b                   	pop    %ebx
f0101396:	5e                   	pop    %esi
f0101397:	5f                   	pop    %edi
f0101398:	5d                   	pop    %ebp
f0101399:	c3                   	ret    
f010139a:	66 90                	xchg   %ax,%ax
f010139c:	66 90                	xchg   %ax,%ax
f010139e:	66 90                	xchg   %ax,%ax

f01013a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ab:	eb 03                	jmp    f01013b0 <strlen+0x10>
		n++;
f01013ad:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01013b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013b4:	75 f7                	jne    f01013ad <strlen+0xd>
	return n;
}
f01013b6:	5d                   	pop    %ebp
f01013b7:	c3                   	ret    

f01013b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013b8:	55                   	push   %ebp
f01013b9:	89 e5                	mov    %esp,%ebp
f01013bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
f01013be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c6:	eb 03                	jmp    f01013cb <strnlen+0x13>
		n++;
f01013c8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013cb:	39 d0                	cmp    %edx,%eax
f01013cd:	74 06                	je     f01013d5 <strnlen+0x1d>
f01013cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013d3:	75 f3                	jne    f01013c8 <strnlen+0x10>
	return n;
}
f01013d5:	5d                   	pop    %ebp
f01013d6:	c3                   	ret    

f01013d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013d7:	55                   	push   %ebp
f01013d8:	89 e5                	mov    %esp,%ebp
f01013da:	53                   	push   %ebx
f01013db:	8b 45 08             	mov    0x8(%ebp),%eax
f01013de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e1:	89 c2                	mov    %eax,%edx
f01013e3:	0f b6 19             	movzbl (%ecx),%ebx
f01013e6:	88 1a                	mov    %bl,(%edx)
f01013e8:	83 c2 01             	add    $0x1,%edx
f01013eb:	83 c1 01             	add    $0x1,%ecx
f01013ee:	84 db                	test   %bl,%bl
f01013f0:	75 f1                	jne    f01013e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013f2:	5b                   	pop    %ebx
f01013f3:	5d                   	pop    %ebp
f01013f4:	c3                   	ret    

f01013f5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013f5:	55                   	push   %ebp
f01013f6:	89 e5                	mov    %esp,%ebp
f01013f8:	53                   	push   %ebx
f01013f9:	83 ec 08             	sub    $0x8,%esp
f01013fc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01013ff:	89 1c 24             	mov    %ebx,(%esp)
f0101402:	e8 99 ff ff ff       	call   f01013a0 <strlen>
	strcpy(dst + len, src);
f0101407:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010140e:	01 d8                	add    %ebx,%eax
f0101410:	89 04 24             	mov    %eax,(%esp)
f0101413:	e8 bf ff ff ff       	call   f01013d7 <strcpy>
	return dst;
}
f0101418:	89 d8                	mov    %ebx,%eax
f010141a:	83 c4 08             	add    $0x8,%esp
f010141d:	5b                   	pop    %ebx
f010141e:	5d                   	pop    %ebp
f010141f:	c3                   	ret    

f0101420 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101420:	55                   	push   %ebp
f0101421:	89 e5                	mov    %esp,%ebp
f0101423:	56                   	push   %esi
f0101424:	53                   	push   %ebx
f0101425:	8b 75 08             	mov    0x8(%ebp),%esi
f0101428:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010142b:	89 f3                	mov    %esi,%ebx
f010142d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101430:	89 f2                	mov    %esi,%edx
f0101432:	eb 0e                	jmp    f0101442 <strncpy+0x22>
		*dst++ = *src;
f0101434:	0f b6 01             	movzbl (%ecx),%eax
f0101437:	88 02                	mov    %al,(%edx)
f0101439:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010143c:	80 39 01             	cmpb   $0x1,(%ecx)
f010143f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101442:	39 da                	cmp    %ebx,%edx
f0101444:	75 ee                	jne    f0101434 <strncpy+0x14>
	}
	return ret;
}
f0101446:	89 f0                	mov    %esi,%eax
f0101448:	5b                   	pop    %ebx
f0101449:	5e                   	pop    %esi
f010144a:	5d                   	pop    %ebp
f010144b:	c3                   	ret    

f010144c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
f010144f:	56                   	push   %esi
f0101450:	53                   	push   %ebx
f0101451:	8b 75 08             	mov    0x8(%ebp),%esi
f0101454:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101457:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010145a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
f010145c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
f0101460:	85 c9                	test   %ecx,%ecx
f0101462:	75 0a                	jne    f010146e <strlcpy+0x22>
f0101464:	eb 1c                	jmp    f0101482 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101466:	88 08                	mov    %cl,(%eax)
f0101468:	83 c0 01             	add    $0x1,%eax
f010146b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
f010146e:	39 d8                	cmp    %ebx,%eax
f0101470:	74 0b                	je     f010147d <strlcpy+0x31>
f0101472:	0f b6 0a             	movzbl (%edx),%ecx
f0101475:	84 c9                	test   %cl,%cl
f0101477:	75 ed                	jne    f0101466 <strlcpy+0x1a>
f0101479:	89 c2                	mov    %eax,%edx
f010147b:	eb 02                	jmp    f010147f <strlcpy+0x33>
f010147d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f010147f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101482:	29 f0                	sub    %esi,%eax
}
f0101484:	5b                   	pop    %ebx
f0101485:	5e                   	pop    %esi
f0101486:	5d                   	pop    %ebp
f0101487:	c3                   	ret    

f0101488 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101488:	55                   	push   %ebp
f0101489:	89 e5                	mov    %esp,%ebp
f010148b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010148e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101491:	eb 06                	jmp    f0101499 <strcmp+0x11>
		p++, q++;
f0101493:	83 c1 01             	add    $0x1,%ecx
f0101496:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101499:	0f b6 01             	movzbl (%ecx),%eax
f010149c:	84 c0                	test   %al,%al
f010149e:	74 04                	je     f01014a4 <strcmp+0x1c>
f01014a0:	3a 02                	cmp    (%edx),%al
f01014a2:	74 ef                	je     f0101493 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014a4:	0f b6 c0             	movzbl %al,%eax
f01014a7:	0f b6 12             	movzbl (%edx),%edx
f01014aa:	29 d0                	sub    %edx,%eax
}
f01014ac:	5d                   	pop    %ebp
f01014ad:	c3                   	ret    

f01014ae <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014ae:	55                   	push   %ebp
f01014af:	89 e5                	mov    %esp,%ebp
f01014b1:	53                   	push   %ebx
f01014b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b5:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
f01014b8:	89 c3                	mov    %eax,%ebx
f01014ba:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014bd:	eb 06                	jmp    f01014c5 <strncmp+0x17>
		n--, p++, q++;
f01014bf:	83 c0 01             	add    $0x1,%eax
f01014c2:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01014c5:	39 d8                	cmp    %ebx,%eax
f01014c7:	74 15                	je     f01014de <strncmp+0x30>
f01014c9:	0f b6 08             	movzbl (%eax),%ecx
f01014cc:	84 c9                	test   %cl,%cl
f01014ce:	74 04                	je     f01014d4 <strncmp+0x26>
f01014d0:	3a 0a                	cmp    (%edx),%cl
f01014d2:	74 eb                	je     f01014bf <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d4:	0f b6 00             	movzbl (%eax),%eax
f01014d7:	0f b6 12             	movzbl (%edx),%edx
f01014da:	29 d0                	sub    %edx,%eax
f01014dc:	eb 05                	jmp    f01014e3 <strncmp+0x35>
		return 0;
f01014de:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014e3:	5b                   	pop    %ebx
f01014e4:	5d                   	pop    %ebp
f01014e5:	c3                   	ret    

f01014e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014e6:	55                   	push   %ebp
f01014e7:	89 e5                	mov    %esp,%ebp
f01014e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014f0:	eb 07                	jmp    f01014f9 <strchr+0x13>
		if (*s == c)
f01014f2:	38 ca                	cmp    %cl,%dl
f01014f4:	74 0f                	je     f0101505 <strchr+0x1f>
	for (; *s; s++)
f01014f6:	83 c0 01             	add    $0x1,%eax
f01014f9:	0f b6 10             	movzbl (%eax),%edx
f01014fc:	84 d2                	test   %dl,%dl
f01014fe:	75 f2                	jne    f01014f2 <strchr+0xc>
			return (char *) s;
	return 0;
f0101500:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101505:	5d                   	pop    %ebp
f0101506:	c3                   	ret    

f0101507 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101507:	55                   	push   %ebp
f0101508:	89 e5                	mov    %esp,%ebp
f010150a:	8b 45 08             	mov    0x8(%ebp),%eax
f010150d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101511:	eb 07                	jmp    f010151a <strfind+0x13>
		if (*s == c)
f0101513:	38 ca                	cmp    %cl,%dl
f0101515:	74 0a                	je     f0101521 <strfind+0x1a>
	for (; *s; s++)
f0101517:	83 c0 01             	add    $0x1,%eax
f010151a:	0f b6 10             	movzbl (%eax),%edx
f010151d:	84 d2                	test   %dl,%dl
f010151f:	75 f2                	jne    f0101513 <strfind+0xc>
			break;
	return (char *) s;
}
f0101521:	5d                   	pop    %ebp
f0101522:	c3                   	ret    

f0101523 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101523:	55                   	push   %ebp
f0101524:	89 e5                	mov    %esp,%ebp
f0101526:	83 ec 0c             	sub    $0xc,%esp
f0101529:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010152c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010152f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101532:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101535:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101538:	85 c9                	test   %ecx,%ecx
f010153a:	74 36                	je     f0101572 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010153c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101542:	75 28                	jne    f010156c <memset+0x49>
f0101544:	f6 c1 03             	test   $0x3,%cl
f0101547:	75 23                	jne    f010156c <memset+0x49>
		c &= 0xFF;
f0101549:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010154d:	89 d3                	mov    %edx,%ebx
f010154f:	c1 e3 08             	shl    $0x8,%ebx
f0101552:	89 d6                	mov    %edx,%esi
f0101554:	c1 e6 18             	shl    $0x18,%esi
f0101557:	89 d0                	mov    %edx,%eax
f0101559:	c1 e0 10             	shl    $0x10,%eax
f010155c:	09 f0                	or     %esi,%eax
f010155e:	09 c2                	or     %eax,%edx
f0101560:	89 d0                	mov    %edx,%eax
f0101562:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101564:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101567:	fc                   	cld    
f0101568:	f3 ab                	rep stos %eax,%es:(%edi)
f010156a:	eb 06                	jmp    f0101572 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010156c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156f:	fc                   	cld    
f0101570:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101572:	89 f8                	mov    %edi,%eax
f0101574:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101577:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010157a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010157d:	89 ec                	mov    %ebp,%esp
f010157f:	5d                   	pop    %ebp
f0101580:	c3                   	ret    

f0101581 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101581:	55                   	push   %ebp
f0101582:	89 e5                	mov    %esp,%ebp
f0101584:	83 ec 08             	sub    $0x8,%esp
f0101587:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010158a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010158d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101590:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101593:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101596:	39 c6                	cmp    %eax,%esi
f0101598:	73 36                	jae    f01015d0 <memmove+0x4f>
f010159a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010159d:	39 d0                	cmp    %edx,%eax
f010159f:	73 2f                	jae    f01015d0 <memmove+0x4f>
		s += n;
		d += n;
f01015a1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015a4:	f6 c2 03             	test   $0x3,%dl
f01015a7:	75 1b                	jne    f01015c4 <memmove+0x43>
f01015a9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015af:	75 13                	jne    f01015c4 <memmove+0x43>
f01015b1:	f6 c1 03             	test   $0x3,%cl
f01015b4:	75 0e                	jne    f01015c4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015b6:	83 ef 04             	sub    $0x4,%edi
f01015b9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015bc:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01015bf:	fd                   	std    
f01015c0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015c2:	eb 09                	jmp    f01015cd <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015c4:	83 ef 01             	sub    $0x1,%edi
f01015c7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01015ca:	fd                   	std    
f01015cb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015cd:	fc                   	cld    
f01015ce:	eb 20                	jmp    f01015f0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015d0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015d6:	75 13                	jne    f01015eb <memmove+0x6a>
f01015d8:	a8 03                	test   $0x3,%al
f01015da:	75 0f                	jne    f01015eb <memmove+0x6a>
f01015dc:	f6 c1 03             	test   $0x3,%cl
f01015df:	75 0a                	jne    f01015eb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015e1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01015e4:	89 c7                	mov    %eax,%edi
f01015e6:	fc                   	cld    
f01015e7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015e9:	eb 05                	jmp    f01015f0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
f01015eb:	89 c7                	mov    %eax,%edi
f01015ed:	fc                   	cld    
f01015ee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015f0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015f3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015f6:	89 ec                	mov    %ebp,%esp
f01015f8:	5d                   	pop    %ebp
f01015f9:	c3                   	ret    

f01015fa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015fa:	55                   	push   %ebp
f01015fb:	89 e5                	mov    %esp,%ebp
f01015fd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101600:	8b 45 10             	mov    0x10(%ebp),%eax
f0101603:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101607:	8b 45 0c             	mov    0xc(%ebp),%eax
f010160a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010160e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101611:	89 04 24             	mov    %eax,(%esp)
f0101614:	e8 68 ff ff ff       	call   f0101581 <memmove>
}
f0101619:	c9                   	leave  
f010161a:	c3                   	ret    

f010161b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010161b:	55                   	push   %ebp
f010161c:	89 e5                	mov    %esp,%ebp
f010161e:	56                   	push   %esi
f010161f:	53                   	push   %ebx
f0101620:	8b 55 08             	mov    0x8(%ebp),%edx
f0101623:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
f0101626:	89 d6                	mov    %edx,%esi
f0101628:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010162b:	eb 1a                	jmp    f0101647 <memcmp+0x2c>
		if (*s1 != *s2)
f010162d:	0f b6 02             	movzbl (%edx),%eax
f0101630:	0f b6 19             	movzbl (%ecx),%ebx
f0101633:	38 d8                	cmp    %bl,%al
f0101635:	74 0a                	je     f0101641 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101637:	0f b6 c0             	movzbl %al,%eax
f010163a:	0f b6 db             	movzbl %bl,%ebx
f010163d:	29 d8                	sub    %ebx,%eax
f010163f:	eb 0f                	jmp    f0101650 <memcmp+0x35>
		s1++, s2++;
f0101641:	83 c2 01             	add    $0x1,%edx
f0101644:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0101647:	39 f2                	cmp    %esi,%edx
f0101649:	75 e2                	jne    f010162d <memcmp+0x12>
	}

	return 0;
f010164b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101650:	5b                   	pop    %ebx
f0101651:	5e                   	pop    %esi
f0101652:	5d                   	pop    %ebp
f0101653:	c3                   	ret    

f0101654 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101654:	55                   	push   %ebp
f0101655:	89 e5                	mov    %esp,%ebp
f0101657:	8b 45 08             	mov    0x8(%ebp),%eax
f010165a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010165d:	89 c2                	mov    %eax,%edx
f010165f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101662:	eb 07                	jmp    f010166b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101664:	38 08                	cmp    %cl,(%eax)
f0101666:	74 07                	je     f010166f <memfind+0x1b>
	for (; s < ends; s++)
f0101668:	83 c0 01             	add    $0x1,%eax
f010166b:	39 d0                	cmp    %edx,%eax
f010166d:	72 f5                	jb     f0101664 <memfind+0x10>
			break;
	return (void *) s;
}
f010166f:	5d                   	pop    %ebp
f0101670:	c3                   	ret    

f0101671 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101671:	55                   	push   %ebp
f0101672:	89 e5                	mov    %esp,%ebp
f0101674:	57                   	push   %edi
f0101675:	56                   	push   %esi
f0101676:	53                   	push   %ebx
f0101677:	83 ec 04             	sub    $0x4,%esp
f010167a:	8b 55 08             	mov    0x8(%ebp),%edx
f010167d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101680:	eb 03                	jmp    f0101685 <strtol+0x14>
		s++;
f0101682:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101685:	0f b6 02             	movzbl (%edx),%eax
f0101688:	3c 09                	cmp    $0x9,%al
f010168a:	74 f6                	je     f0101682 <strtol+0x11>
f010168c:	3c 20                	cmp    $0x20,%al
f010168e:	74 f2                	je     f0101682 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
f0101690:	3c 2b                	cmp    $0x2b,%al
f0101692:	75 0a                	jne    f010169e <strtol+0x2d>
		s++;
f0101694:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0101697:	bf 00 00 00 00       	mov    $0x0,%edi
f010169c:	eb 10                	jmp    f01016ae <strtol+0x3d>
f010169e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f01016a3:	3c 2d                	cmp    $0x2d,%al
f01016a5:	75 07                	jne    f01016ae <strtol+0x3d>
		s++, neg = 1;
f01016a7:	8d 52 01             	lea    0x1(%edx),%edx
f01016aa:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016ae:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01016b4:	75 15                	jne    f01016cb <strtol+0x5a>
f01016b6:	80 3a 30             	cmpb   $0x30,(%edx)
f01016b9:	75 10                	jne    f01016cb <strtol+0x5a>
f01016bb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016bf:	75 0a                	jne    f01016cb <strtol+0x5a>
		s += 2, base = 16;
f01016c1:	83 c2 02             	add    $0x2,%edx
f01016c4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016c9:	eb 10                	jmp    f01016db <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016cb:	85 db                	test   %ebx,%ebx
f01016cd:	75 0c                	jne    f01016db <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016cf:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
f01016d1:	80 3a 30             	cmpb   $0x30,(%edx)
f01016d4:	75 05                	jne    f01016db <strtol+0x6a>
		s++, base = 8;
f01016d6:	83 c2 01             	add    $0x1,%edx
f01016d9:	b3 08                	mov    $0x8,%bl
		base = 10;
f01016db:	b8 00 00 00 00       	mov    $0x0,%eax
f01016e0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016e3:	0f b6 0a             	movzbl (%edx),%ecx
f01016e6:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016e9:	89 f3                	mov    %esi,%ebx
f01016eb:	80 fb 09             	cmp    $0x9,%bl
f01016ee:	77 08                	ja     f01016f8 <strtol+0x87>
			dig = *s - '0';
f01016f0:	0f be c9             	movsbl %cl,%ecx
f01016f3:	83 e9 30             	sub    $0x30,%ecx
f01016f6:	eb 22                	jmp    f010171a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f01016f8:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016fb:	89 f3                	mov    %esi,%ebx
f01016fd:	80 fb 19             	cmp    $0x19,%bl
f0101700:	77 08                	ja     f010170a <strtol+0x99>
			dig = *s - 'a' + 10;
f0101702:	0f be c9             	movsbl %cl,%ecx
f0101705:	83 e9 57             	sub    $0x57,%ecx
f0101708:	eb 10                	jmp    f010171a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f010170a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010170d:	89 f3                	mov    %esi,%ebx
f010170f:	80 fb 19             	cmp    $0x19,%bl
f0101712:	77 16                	ja     f010172a <strtol+0xb9>
			dig = *s - 'A' + 10;
f0101714:	0f be c9             	movsbl %cl,%ecx
f0101717:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010171a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010171d:	7d 0f                	jge    f010172e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010171f:	83 c2 01             	add    $0x1,%edx
f0101722:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101726:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101728:	eb b9                	jmp    f01016e3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
f010172a:	89 c1                	mov    %eax,%ecx
f010172c:	eb 02                	jmp    f0101730 <strtol+0xbf>
		if (dig >= base)
f010172e:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0101730:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101734:	74 05                	je     f010173b <strtol+0xca>
		*endptr = (char *) s;
f0101736:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101739:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010173b:	89 ca                	mov    %ecx,%edx
f010173d:	f7 da                	neg    %edx
f010173f:	85 ff                	test   %edi,%edi
f0101741:	0f 45 c2             	cmovne %edx,%eax
}
f0101744:	83 c4 04             	add    $0x4,%esp
f0101747:	5b                   	pop    %ebx
f0101748:	5e                   	pop    %esi
f0101749:	5f                   	pop    %edi
f010174a:	5d                   	pop    %ebp
f010174b:	c3                   	ret    
f010174c:	66 90                	xchg   %ax,%ax
f010174e:	66 90                	xchg   %ax,%ax

f0101750 <__udivdi3>:
f0101750:	83 ec 1c             	sub    $0x1c,%esp
f0101753:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101757:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010175b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010175f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101763:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101767:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f010176b:	85 c0                	test   %eax,%eax
f010176d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101771:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101775:	89 ea                	mov    %ebp,%edx
f0101777:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010177b:	75 33                	jne    f01017b0 <__udivdi3+0x60>
f010177d:	39 e9                	cmp    %ebp,%ecx
f010177f:	77 6f                	ja     f01017f0 <__udivdi3+0xa0>
f0101781:	85 c9                	test   %ecx,%ecx
f0101783:	89 ce                	mov    %ecx,%esi
f0101785:	75 0b                	jne    f0101792 <__udivdi3+0x42>
f0101787:	b8 01 00 00 00       	mov    $0x1,%eax
f010178c:	31 d2                	xor    %edx,%edx
f010178e:	f7 f1                	div    %ecx
f0101790:	89 c6                	mov    %eax,%esi
f0101792:	31 d2                	xor    %edx,%edx
f0101794:	89 e8                	mov    %ebp,%eax
f0101796:	f7 f6                	div    %esi
f0101798:	89 c5                	mov    %eax,%ebp
f010179a:	89 f8                	mov    %edi,%eax
f010179c:	f7 f6                	div    %esi
f010179e:	89 ea                	mov    %ebp,%edx
f01017a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017ac:	83 c4 1c             	add    $0x1c,%esp
f01017af:	c3                   	ret    
f01017b0:	39 e8                	cmp    %ebp,%eax
f01017b2:	77 24                	ja     f01017d8 <__udivdi3+0x88>
f01017b4:	0f bd c8             	bsr    %eax,%ecx
f01017b7:	83 f1 1f             	xor    $0x1f,%ecx
f01017ba:	89 0c 24             	mov    %ecx,(%esp)
f01017bd:	75 49                	jne    f0101808 <__udivdi3+0xb8>
f01017bf:	8b 74 24 08          	mov    0x8(%esp),%esi
f01017c3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f01017c7:	0f 86 ab 00 00 00    	jbe    f0101878 <__udivdi3+0x128>
f01017cd:	39 e8                	cmp    %ebp,%eax
f01017cf:	0f 82 a3 00 00 00    	jb     f0101878 <__udivdi3+0x128>
f01017d5:	8d 76 00             	lea    0x0(%esi),%esi
f01017d8:	31 d2                	xor    %edx,%edx
f01017da:	31 c0                	xor    %eax,%eax
f01017dc:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017e0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017e4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017e8:	83 c4 1c             	add    $0x1c,%esp
f01017eb:	c3                   	ret    
f01017ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f0:	89 f8                	mov    %edi,%eax
f01017f2:	f7 f1                	div    %ecx
f01017f4:	31 d2                	xor    %edx,%edx
f01017f6:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017fa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017fe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101802:	83 c4 1c             	add    $0x1c,%esp
f0101805:	c3                   	ret    
f0101806:	66 90                	xchg   %ax,%ax
f0101808:	0f b6 0c 24          	movzbl (%esp),%ecx
f010180c:	89 c6                	mov    %eax,%esi
f010180e:	b8 20 00 00 00       	mov    $0x20,%eax
f0101813:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0101817:	2b 04 24             	sub    (%esp),%eax
f010181a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010181e:	d3 e6                	shl    %cl,%esi
f0101820:	89 c1                	mov    %eax,%ecx
f0101822:	d3 ed                	shr    %cl,%ebp
f0101824:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101828:	09 f5                	or     %esi,%ebp
f010182a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010182e:	d3 e6                	shl    %cl,%esi
f0101830:	89 c1                	mov    %eax,%ecx
f0101832:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101836:	89 d6                	mov    %edx,%esi
f0101838:	d3 ee                	shr    %cl,%esi
f010183a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010183e:	d3 e2                	shl    %cl,%edx
f0101840:	89 c1                	mov    %eax,%ecx
f0101842:	d3 ef                	shr    %cl,%edi
f0101844:	09 d7                	or     %edx,%edi
f0101846:	89 f2                	mov    %esi,%edx
f0101848:	89 f8                	mov    %edi,%eax
f010184a:	f7 f5                	div    %ebp
f010184c:	89 d6                	mov    %edx,%esi
f010184e:	89 c7                	mov    %eax,%edi
f0101850:	f7 64 24 04          	mull   0x4(%esp)
f0101854:	39 d6                	cmp    %edx,%esi
f0101856:	72 30                	jb     f0101888 <__udivdi3+0x138>
f0101858:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010185c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101860:	d3 e5                	shl    %cl,%ebp
f0101862:	39 c5                	cmp    %eax,%ebp
f0101864:	73 04                	jae    f010186a <__udivdi3+0x11a>
f0101866:	39 d6                	cmp    %edx,%esi
f0101868:	74 1e                	je     f0101888 <__udivdi3+0x138>
f010186a:	89 f8                	mov    %edi,%eax
f010186c:	31 d2                	xor    %edx,%edx
f010186e:	e9 69 ff ff ff       	jmp    f01017dc <__udivdi3+0x8c>
f0101873:	90                   	nop
f0101874:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101878:	31 d2                	xor    %edx,%edx
f010187a:	b8 01 00 00 00       	mov    $0x1,%eax
f010187f:	e9 58 ff ff ff       	jmp    f01017dc <__udivdi3+0x8c>
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	8d 47 ff             	lea    -0x1(%edi),%eax
f010188b:	31 d2                	xor    %edx,%edx
f010188d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101891:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101895:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101899:	83 c4 1c             	add    $0x1c,%esp
f010189c:	c3                   	ret    
f010189d:	66 90                	xchg   %ax,%ax
f010189f:	90                   	nop

f01018a0 <__umoddi3>:
f01018a0:	83 ec 2c             	sub    $0x2c,%esp
f01018a3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01018a7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01018ab:	89 74 24 20          	mov    %esi,0x20(%esp)
f01018af:	8b 74 24 38          	mov    0x38(%esp),%esi
f01018b3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f01018b7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f01018bb:	85 c0                	test   %eax,%eax
f01018bd:	89 c2                	mov    %eax,%edx
f01018bf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f01018c3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01018c7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018cb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01018cf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01018d3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01018d7:	75 1f                	jne    f01018f8 <__umoddi3+0x58>
f01018d9:	39 fe                	cmp    %edi,%esi
f01018db:	76 63                	jbe    f0101940 <__umoddi3+0xa0>
f01018dd:	89 c8                	mov    %ecx,%eax
f01018df:	89 fa                	mov    %edi,%edx
f01018e1:	f7 f6                	div    %esi
f01018e3:	89 d0                	mov    %edx,%eax
f01018e5:	31 d2                	xor    %edx,%edx
f01018e7:	8b 74 24 20          	mov    0x20(%esp),%esi
f01018eb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01018ef:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01018f3:	83 c4 2c             	add    $0x2c,%esp
f01018f6:	c3                   	ret    
f01018f7:	90                   	nop
f01018f8:	39 f8                	cmp    %edi,%eax
f01018fa:	77 64                	ja     f0101960 <__umoddi3+0xc0>
f01018fc:	0f bd e8             	bsr    %eax,%ebp
f01018ff:	83 f5 1f             	xor    $0x1f,%ebp
f0101902:	75 74                	jne    f0101978 <__umoddi3+0xd8>
f0101904:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101908:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010190c:	0f 87 0e 01 00 00    	ja     f0101a20 <__umoddi3+0x180>
f0101912:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101916:	29 f1                	sub    %esi,%ecx
f0101918:	19 c7                	sbb    %eax,%edi
f010191a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010191e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101922:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101926:	8b 54 24 18          	mov    0x18(%esp),%edx
f010192a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010192e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101932:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101936:	83 c4 2c             	add    $0x2c,%esp
f0101939:	c3                   	ret    
f010193a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101940:	85 f6                	test   %esi,%esi
f0101942:	89 f5                	mov    %esi,%ebp
f0101944:	75 0b                	jne    f0101951 <__umoddi3+0xb1>
f0101946:	b8 01 00 00 00       	mov    $0x1,%eax
f010194b:	31 d2                	xor    %edx,%edx
f010194d:	f7 f6                	div    %esi
f010194f:	89 c5                	mov    %eax,%ebp
f0101951:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101955:	31 d2                	xor    %edx,%edx
f0101957:	f7 f5                	div    %ebp
f0101959:	89 c8                	mov    %ecx,%eax
f010195b:	f7 f5                	div    %ebp
f010195d:	eb 84                	jmp    f01018e3 <__umoddi3+0x43>
f010195f:	90                   	nop
f0101960:	89 c8                	mov    %ecx,%eax
f0101962:	89 fa                	mov    %edi,%edx
f0101964:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101968:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010196c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101970:	83 c4 2c             	add    $0x2c,%esp
f0101973:	c3                   	ret    
f0101974:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101978:	8b 44 24 10          	mov    0x10(%esp),%eax
f010197c:	be 20 00 00 00       	mov    $0x20,%esi
f0101981:	89 e9                	mov    %ebp,%ecx
f0101983:	29 ee                	sub    %ebp,%esi
f0101985:	d3 e2                	shl    %cl,%edx
f0101987:	89 f1                	mov    %esi,%ecx
f0101989:	d3 e8                	shr    %cl,%eax
f010198b:	89 e9                	mov    %ebp,%ecx
f010198d:	09 d0                	or     %edx,%eax
f010198f:	89 fa                	mov    %edi,%edx
f0101991:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101995:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101999:	d3 e0                	shl    %cl,%eax
f010199b:	89 f1                	mov    %esi,%ecx
f010199d:	89 44 24 10          	mov    %eax,0x10(%esp)
f01019a1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01019a5:	d3 ea                	shr    %cl,%edx
f01019a7:	89 e9                	mov    %ebp,%ecx
f01019a9:	d3 e7                	shl    %cl,%edi
f01019ab:	89 f1                	mov    %esi,%ecx
f01019ad:	d3 e8                	shr    %cl,%eax
f01019af:	89 e9                	mov    %ebp,%ecx
f01019b1:	09 f8                	or     %edi,%eax
f01019b3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01019b7:	f7 74 24 0c          	divl   0xc(%esp)
f01019bb:	d3 e7                	shl    %cl,%edi
f01019bd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01019c1:	89 d7                	mov    %edx,%edi
f01019c3:	f7 64 24 10          	mull   0x10(%esp)
f01019c7:	39 d7                	cmp    %edx,%edi
f01019c9:	89 c1                	mov    %eax,%ecx
f01019cb:	89 54 24 14          	mov    %edx,0x14(%esp)
f01019cf:	72 3b                	jb     f0101a0c <__umoddi3+0x16c>
f01019d1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f01019d5:	72 31                	jb     f0101a08 <__umoddi3+0x168>
f01019d7:	8b 44 24 18          	mov    0x18(%esp),%eax
f01019db:	29 c8                	sub    %ecx,%eax
f01019dd:	19 d7                	sbb    %edx,%edi
f01019df:	89 e9                	mov    %ebp,%ecx
f01019e1:	89 fa                	mov    %edi,%edx
f01019e3:	d3 e8                	shr    %cl,%eax
f01019e5:	89 f1                	mov    %esi,%ecx
f01019e7:	d3 e2                	shl    %cl,%edx
f01019e9:	89 e9                	mov    %ebp,%ecx
f01019eb:	09 d0                	or     %edx,%eax
f01019ed:	89 fa                	mov    %edi,%edx
f01019ef:	d3 ea                	shr    %cl,%edx
f01019f1:	8b 74 24 20          	mov    0x20(%esp),%esi
f01019f5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01019f9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01019fd:	83 c4 2c             	add    $0x2c,%esp
f0101a00:	c3                   	ret    
f0101a01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a08:	39 d7                	cmp    %edx,%edi
f0101a0a:	75 cb                	jne    f01019d7 <__umoddi3+0x137>
f0101a0c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101a10:	89 c1                	mov    %eax,%ecx
f0101a12:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101a16:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101a1a:	eb bb                	jmp    f01019d7 <__umoddi3+0x137>
f0101a1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a20:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101a24:	0f 82 e8 fe ff ff    	jb     f0101912 <__umoddi3+0x72>
f0101a2a:	e9 f3 fe ff ff       	jmp    f0101922 <__umoddi3+0x82>
