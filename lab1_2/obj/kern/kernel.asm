
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 89 11 f0       	mov    $0xf0118970,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 83 11 f0 	movl   $0xf0118300,(%esp)
f0100063:	e8 bb 39 00 00       	call   f0103a23 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 90 04 00 00       	call   f01004fd <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 3f 10 f0 	movl   $0xf0103f40,(%esp)
f010007c:	e8 27 2e 00 00       	call   f0102ea8 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 c3 11 00 00       	call   f0101249 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 3a 07 00 00       	call   f01007cc <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 89 11 f0 00 	cmpl   $0x0,0xf0118960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 89 11 f0    	mov    %esi,0xf0118960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 5b 3f 10 f0 	movl   $0xf0103f5b,(%esp)
f01000c8:	e8 db 2d 00 00       	call   f0102ea8 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 9c 2d 00 00       	call   f0102e75 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 e1 4e 10 f0 	movl   $0xf0104ee1,(%esp)
f01000e0:	e8 c3 2d 00 00       	call   f0102ea8 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 db 06 00 00       	call   f01007cc <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 73 3f 10 f0 	movl   $0xf0103f73,(%esp)
f0100112:	e8 91 2d 00 00       	call   f0102ea8 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 4f 2d 00 00       	call   f0102e75 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 e1 4e 10 f0 	movl   $0xf0104ee1,(%esp)
f010012d:	e8 76 2d 00 00       	call   f0102ea8 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100157:	a8 01                	test   $0x1,%al
f0100159:	74 08                	je     f0100163 <serial_proc_data+0x15>
f010015b:	b2 f8                	mov    $0xf8,%dl
f010015d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010015e:	0f b6 c0             	movzbl %al,%eax
f0100161:	eb 05                	jmp    f0100168 <serial_proc_data+0x1a>
		return -1;
f0100163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 26                	jmp    f010019b <cons_intr+0x31>
		if (c == 0)
f0100175:	85 d2                	test   %edx,%edx
f0100177:	74 22                	je     f010019b <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	a1 24 85 11 f0       	mov    0xf0118524,%eax
f010017e:	88 90 20 83 11 f0    	mov    %dl,-0xfee7ce0(%eax)
f0100184:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100187:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010018d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100192:	0f 44 d0             	cmove  %eax,%edx
f0100195:	89 15 24 85 11 f0    	mov    %edx,0xf0118524
	while ((c = (*proc)()) != -1) {
f010019b:	ff d3                	call   *%ebx
f010019d:	89 c2                	mov    %eax,%edx
f010019f:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a2:	75 d1                	jne    f0100175 <cons_intr+0xb>
	}
}
f01001a4:	83 c4 04             	add    $0x4,%esp
f01001a7:	5b                   	pop    %ebx
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	57                   	push   %edi
f01001ae:	56                   	push   %esi
f01001af:	53                   	push   %ebx
f01001b0:	83 ec 2c             	sub    $0x2c,%esp
f01001b3:	89 c7                	mov    %eax,%edi
f01001b5:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001ba:	be fd 03 00 00       	mov    $0x3fd,%esi
f01001bf:	eb 05                	jmp    f01001c6 <cons_putc+0x1c>
		delay();
f01001c1:	e8 7a ff ff ff       	call   f0100140 <delay>
f01001c6:	89 f2                	mov    %esi,%edx
f01001c8:	ec                   	in     (%dx),%al
	for (i = 0;
f01001c9:	a8 20                	test   $0x20,%al
f01001cb:	75 05                	jne    f01001d2 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001cd:	83 eb 01             	sub    $0x1,%ebx
f01001d0:	75 ef                	jne    f01001c1 <cons_putc+0x17>
	outb(COM1 + COM_TX, c);
f01001d2:	89 f8                	mov    %edi,%eax
f01001d4:	25 ff 00 00 00       	and    $0xff,%eax
f01001d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001dc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e1:	ee                   	out    %al,(%dx)
f01001e2:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e7:	be 79 03 00 00       	mov    $0x379,%esi
f01001ec:	eb 05                	jmp    f01001f3 <cons_putc+0x49>
		delay();
f01001ee:	e8 4d ff ff ff       	call   f0100140 <delay>
f01001f3:	89 f2                	mov    %esi,%edx
f01001f5:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001f6:	84 c0                	test   %al,%al
f01001f8:	78 05                	js     f01001ff <cons_putc+0x55>
f01001fa:	83 eb 01             	sub    $0x1,%ebx
f01001fd:	75 ef                	jne    f01001ee <cons_putc+0x44>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100204:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100208:	ee                   	out    %al,(%dx)
f0100209:	b2 7a                	mov    $0x7a,%dl
f010020b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100210:	ee                   	out    %al,(%dx)
f0100211:	b8 08 00 00 00       	mov    $0x8,%eax
f0100216:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100217:	89 fa                	mov    %edi,%edx
f0100219:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010021f:	89 f8                	mov    %edi,%eax
f0100221:	80 cc 07             	or     $0x7,%ah
f0100224:	85 d2                	test   %edx,%edx
f0100226:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100229:	89 f8                	mov    %edi,%eax
f010022b:	25 ff 00 00 00       	and    $0xff,%eax
f0100230:	83 f8 09             	cmp    $0x9,%eax
f0100233:	74 7a                	je     f01002af <cons_putc+0x105>
f0100235:	83 f8 09             	cmp    $0x9,%eax
f0100238:	7f 0b                	jg     f0100245 <cons_putc+0x9b>
f010023a:	83 f8 08             	cmp    $0x8,%eax
f010023d:	0f 85 a0 00 00 00    	jne    f01002e3 <cons_putc+0x139>
f0100243:	eb 13                	jmp    f0100258 <cons_putc+0xae>
f0100245:	83 f8 0a             	cmp    $0xa,%eax
f0100248:	74 3f                	je     f0100289 <cons_putc+0xdf>
f010024a:	83 f8 0d             	cmp    $0xd,%eax
f010024d:	8d 76 00             	lea    0x0(%esi),%esi
f0100250:	0f 85 8d 00 00 00    	jne    f01002e3 <cons_putc+0x139>
f0100256:	eb 39                	jmp    f0100291 <cons_putc+0xe7>
		if (crt_pos > 0) {
f0100258:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f010025f:	66 85 c0             	test   %ax,%ax
f0100262:	0f 84 e5 00 00 00    	je     f010034d <cons_putc+0x1a3>
			crt_pos--;
f0100268:	83 e8 01             	sub    $0x1,%eax
f010026b:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100271:	0f b7 c0             	movzwl %ax,%eax
f0100274:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f010027a:	83 cf 20             	or     $0x20,%edi
f010027d:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
f0100283:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100287:	eb 77                	jmp    f0100300 <cons_putc+0x156>
		crt_pos += CRT_COLS;
f0100289:	66 83 05 34 85 11 f0 	addw   $0x50,0xf0118534
f0100290:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f0100291:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f0100298:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010029e:	c1 e8 16             	shr    $0x16,%eax
f01002a1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002a4:	c1 e0 04             	shl    $0x4,%eax
f01002a7:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
f01002ad:	eb 51                	jmp    f0100300 <cons_putc+0x156>
		cons_putc(' ');
f01002af:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b4:	e8 f1 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002b9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002be:	e8 e7 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002c3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c8:	e8 dd fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d2:	e8 d3 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002d7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002dc:	e8 c9 fe ff ff       	call   f01001aa <cons_putc>
f01002e1:	eb 1d                	jmp    f0100300 <cons_putc+0x156>
		crt_buf[crt_pos++] = c;		/* write the character */
f01002e3:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f01002ea:	0f b7 c8             	movzwl %ax,%ecx
f01002ed:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
f01002f3:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01002f7:	83 c0 01             	add    $0x1,%eax
f01002fa:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
	if (crt_pos >= CRT_SIZE) {
f0100300:	66 81 3d 34 85 11 f0 	cmpw   $0x7cf,0xf0118534
f0100307:	cf 07 
f0100309:	76 42                	jbe    f010034d <cons_putc+0x1a3>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010030b:	a1 30 85 11 f0       	mov    0xf0118530,%eax
f0100310:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100317:	00 
f0100318:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010031e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100322:	89 04 24             	mov    %eax,(%esp)
f0100325:	e8 57 37 00 00       	call   f0103a81 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010032a:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100330:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100335:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010033b:	83 c0 01             	add    $0x1,%eax
f010033e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100343:	75 f0                	jne    f0100335 <cons_putc+0x18b>
		crt_pos -= CRT_COLS;
f0100345:	66 83 2d 34 85 11 f0 	subw   $0x50,0xf0118534
f010034c:	50 
	outb(addr_6845, 14);
f010034d:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f0100353:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100358:	89 ca                	mov    %ecx,%edx
f010035a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010035b:	0f b7 1d 34 85 11 f0 	movzwl 0xf0118534,%ebx
f0100362:	8d 71 01             	lea    0x1(%ecx),%esi
f0100365:	89 d8                	mov    %ebx,%eax
f0100367:	66 c1 e8 08          	shr    $0x8,%ax
f010036b:	89 f2                	mov    %esi,%edx
f010036d:	ee                   	out    %al,(%dx)
f010036e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100373:	89 ca                	mov    %ecx,%edx
f0100375:	ee                   	out    %al,(%dx)
f0100376:	89 d8                	mov    %ebx,%eax
f0100378:	89 f2                	mov    %esi,%edx
f010037a:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010037b:	83 c4 2c             	add    $0x2c,%esp
f010037e:	5b                   	pop    %ebx
f010037f:	5e                   	pop    %esi
f0100380:	5f                   	pop    %edi
f0100381:	5d                   	pop    %ebp
f0100382:	c3                   	ret    

f0100383 <kbd_proc_data>:
{
f0100383:	55                   	push   %ebp
f0100384:	89 e5                	mov    %esp,%ebp
f0100386:	53                   	push   %ebx
f0100387:	83 ec 14             	sub    $0x14,%esp
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010038a:	ba 64 00 00 00       	mov    $0x64,%edx
f010038f:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100390:	a8 01                	test   $0x1,%al
f0100392:	0f 84 e5 00 00 00    	je     f010047d <kbd_proc_data+0xfa>
f0100398:	b2 60                	mov    $0x60,%dl
f010039a:	ec                   	in     (%dx),%al
f010039b:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010039d:	3c e0                	cmp    $0xe0,%al
f010039f:	75 11                	jne    f01003b2 <kbd_proc_data+0x2f>
		shift |= E0ESC;
f01003a1:	83 0d 28 85 11 f0 40 	orl    $0x40,0xf0118528
		return 0;
f01003a8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ad:	e9 d0 00 00 00       	jmp    f0100482 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003b2:	84 c0                	test   %al,%al
f01003b4:	79 37                	jns    f01003ed <kbd_proc_data+0x6a>
		data = (shift & E0ESC ? data : data & 0x7F);
f01003b6:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003bc:	89 cb                	mov    %ecx,%ebx
f01003be:	83 e3 40             	and    $0x40,%ebx
f01003c1:	83 e0 7f             	and    $0x7f,%eax
f01003c4:	85 db                	test   %ebx,%ebx
f01003c6:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003c9:	0f b6 d2             	movzbl %dl,%edx
f01003cc:	0f b6 82 c0 3f 10 f0 	movzbl -0xfefc040(%edx),%eax
f01003d3:	83 c8 40             	or     $0x40,%eax
f01003d6:	0f b6 c0             	movzbl %al,%eax
f01003d9:	f7 d0                	not    %eax
f01003db:	21 c1                	and    %eax,%ecx
f01003dd:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
		return 0;
f01003e3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e8:	e9 95 00 00 00       	jmp    f0100482 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01003ed:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003f3:	f6 c1 40             	test   $0x40,%cl
f01003f6:	74 0e                	je     f0100406 <kbd_proc_data+0x83>
		data |= 0x80;
f01003f8:	89 c2                	mov    %eax,%edx
f01003fa:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003fd:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100400:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
	shift |= shiftcode[data];
f0100406:	0f b6 d2             	movzbl %dl,%edx
f0100409:	0f b6 82 c0 3f 10 f0 	movzbl -0xfefc040(%edx),%eax
f0100410:	0b 05 28 85 11 f0    	or     0xf0118528,%eax
	shift ^= togglecode[data];
f0100416:	0f b6 8a c0 40 10 f0 	movzbl -0xfefbf40(%edx),%ecx
f010041d:	31 c8                	xor    %ecx,%eax
f010041f:	a3 28 85 11 f0       	mov    %eax,0xf0118528
	c = charcode[shift & (CTL | SHIFT)][data];
f0100424:	89 c1                	mov    %eax,%ecx
f0100426:	83 e1 03             	and    $0x3,%ecx
f0100429:	8b 0c 8d c0 41 10 f0 	mov    -0xfefbe40(,%ecx,4),%ecx
f0100430:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100434:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100437:	a8 08                	test   $0x8,%al
f0100439:	74 1b                	je     f0100456 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010043b:	89 da                	mov    %ebx,%edx
f010043d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100440:	83 f9 19             	cmp    $0x19,%ecx
f0100443:	77 05                	ja     f010044a <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f0100445:	83 eb 20             	sub    $0x20,%ebx
f0100448:	eb 0c                	jmp    f0100456 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f010044a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010044d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100450:	83 fa 19             	cmp    $0x19,%edx
f0100453:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100456:	f7 d0                	not    %eax
f0100458:	a8 06                	test   $0x6,%al
f010045a:	75 26                	jne    f0100482 <kbd_proc_data+0xff>
f010045c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100462:	75 1e                	jne    f0100482 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f0100464:	c7 04 24 8d 3f 10 f0 	movl   $0xf0103f8d,(%esp)
f010046b:	e8 38 2a 00 00       	call   f0102ea8 <cprintf>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100470:	ba 92 00 00 00       	mov    $0x92,%edx
f0100475:	b8 03 00 00 00       	mov    $0x3,%eax
f010047a:	ee                   	out    %al,(%dx)
f010047b:	eb 05                	jmp    f0100482 <kbd_proc_data+0xff>
		return -1;
f010047d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
}
f0100482:	89 d8                	mov    %ebx,%eax
f0100484:	83 c4 14             	add    $0x14,%esp
f0100487:	5b                   	pop    %ebx
f0100488:	5d                   	pop    %ebp
f0100489:	c3                   	ret    

f010048a <serial_intr>:
	if (serial_exists)
f010048a:	80 3d 00 83 11 f0 00 	cmpb   $0x0,0xf0118300
f0100491:	74 11                	je     f01004a4 <serial_intr+0x1a>
{
f0100493:	55                   	push   %ebp
f0100494:	89 e5                	mov    %esp,%ebp
f0100496:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100499:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f010049e:	e8 c7 fc ff ff       	call   f010016a <cons_intr>
}
f01004a3:	c9                   	leave  
f01004a4:	f3 c3                	repz ret 

f01004a6 <kbd_intr>:
{
f01004a6:	55                   	push   %ebp
f01004a7:	89 e5                	mov    %esp,%ebp
f01004a9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ac:	b8 83 03 10 f0       	mov    $0xf0100383,%eax
f01004b1:	e8 b4 fc ff ff       	call   f010016a <cons_intr>
}
f01004b6:	c9                   	leave  
f01004b7:	c3                   	ret    

f01004b8 <cons_getc>:
{
f01004b8:	55                   	push   %ebp
f01004b9:	89 e5                	mov    %esp,%ebp
f01004bb:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004be:	e8 c7 ff ff ff       	call   f010048a <serial_intr>
	kbd_intr();
f01004c3:	e8 de ff ff ff       	call   f01004a6 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004c8:	8b 15 20 85 11 f0    	mov    0xf0118520,%edx
f01004ce:	3b 15 24 85 11 f0    	cmp    0xf0118524,%edx
f01004d4:	74 20                	je     f01004f6 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004d6:	0f b6 82 20 83 11 f0 	movzbl -0xfee7ce0(%edx),%eax
f01004dd:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f01004e0:	81 fa 00 02 00 00    	cmp    $0x200,%edx
		c = cons.buf[cons.rpos++];
f01004e6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004eb:	0f 44 d1             	cmove  %ecx,%edx
f01004ee:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f01004f4:	eb 05                	jmp    f01004fb <cons_getc+0x43>
	return 0;
f01004f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fb:	c9                   	leave  
f01004fc:	c3                   	ret    

f01004fd <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01004fd:	55                   	push   %ebp
f01004fe:	89 e5                	mov    %esp,%ebp
f0100500:	57                   	push   %edi
f0100501:	56                   	push   %esi
f0100502:	53                   	push   %ebx
f0100503:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100506:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100514:	5a a5 
	if (*cp != 0xA55A) {
f0100516:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100521:	74 11                	je     f0100534 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100523:	c7 05 2c 85 11 f0 b4 	movl   $0x3b4,0xf011852c
f010052a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052d:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100532:	eb 16                	jmp    f010054a <cons_init+0x4d>
		*cp = was;
f0100534:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053b:	c7 05 2c 85 11 f0 d4 	movl   $0x3d4,0xf011852c
f0100542:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100545:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f010054a:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f0100550:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100555:	89 ca                	mov    %ecx,%edx
f0100557:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100558:	8d 59 01             	lea    0x1(%ecx),%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055b:	89 da                	mov    %ebx,%edx
f010055d:	ec                   	in     (%dx),%al
f010055e:	0f b6 f0             	movzbl %al,%esi
f0100561:	c1 e6 08             	shl    $0x8,%esi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100564:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100569:	89 ca                	mov    %ecx,%edx
f010056b:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056c:	89 da                	mov    %ebx,%edx
f010056e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010056f:	89 3d 30 85 11 f0    	mov    %edi,0xf0118530
	pos |= inb(addr_6845 + 1);
f0100575:	0f b6 d8             	movzbl %al,%ebx
f0100578:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010057a:	66 89 35 34 85 11 f0 	mov    %si,0xf0118534
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100581:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100586:	b8 00 00 00 00       	mov    $0x0,%eax
f010058b:	89 f2                	mov    %esi,%edx
f010058d:	ee                   	out    %al,(%dx)
f010058e:	b2 fb                	mov    $0xfb,%dl
f0100590:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100595:	ee                   	out    %al,(%dx)
f0100596:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059b:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a0:	89 da                	mov    %ebx,%edx
f01005a2:	ee                   	out    %al,(%dx)
f01005a3:	b2 f9                	mov    $0xf9,%dl
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	b2 fb                	mov    $0xfb,%dl
f01005ad:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	b2 fc                	mov    $0xfc,%dl
f01005b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ba:	ee                   	out    %al,(%dx)
f01005bb:	b2 f9                	mov    $0xf9,%dl
f01005bd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c2:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c3:	b2 fd                	mov    $0xfd,%dl
f01005c5:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 c1             	setne  %cl
f01005cb:	88 0d 00 83 11 f0    	mov    %cl,0xf0118300
f01005d1:	89 f2                	mov    %esi,%edx
f01005d3:	ec                   	in     (%dx),%al
f01005d4:	89 da                	mov    %ebx,%edx
f01005d6:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d7:	84 c9                	test   %cl,%cl
f01005d9:	75 0c                	jne    f01005e7 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005db:	c7 04 24 99 3f 10 f0 	movl   $0xf0103f99,(%esp)
f01005e2:	e8 c1 28 00 00       	call   f0102ea8 <cprintf>
}
f01005e7:	83 c4 1c             	add    $0x1c,%esp
f01005ea:	5b                   	pop    %ebx
f01005eb:	5e                   	pop    %esi
f01005ec:	5f                   	pop    %edi
f01005ed:	5d                   	pop    %ebp
f01005ee:	c3                   	ret    

f01005ef <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005ef:	55                   	push   %ebp
f01005f0:	89 e5                	mov    %esp,%ebp
f01005f2:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01005f8:	e8 ad fb ff ff       	call   f01001aa <cons_putc>
}
f01005fd:	c9                   	leave  
f01005fe:	c3                   	ret    

f01005ff <getchar>:

int
getchar(void)
{
f01005ff:	55                   	push   %ebp
f0100600:	89 e5                	mov    %esp,%ebp
f0100602:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100605:	e8 ae fe ff ff       	call   f01004b8 <cons_getc>
f010060a:	85 c0                	test   %eax,%eax
f010060c:	74 f7                	je     f0100605 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <iscons>:

int
iscons(int fdnum)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	5d                   	pop    %ebp
f0100619:	c3                   	ret    
f010061a:	66 90                	xchg   %ax,%ax
f010061c:	66 90                	xchg   %ax,%ax
f010061e:	66 90                	xchg   %ax,%ax

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 d0 41 10 f0 	movl   $0xf01041d0,(%esp)
f010062d:	e8 76 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100632:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100639:	00 
f010063a:	c7 04 24 90 42 10 f0 	movl   $0xf0104290,(%esp)
f0100641:	e8 62 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100646:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010064d:	00 
f010064e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 b8 42 10 f0 	movl   $0xf01042b8,(%esp)
f010065d:	e8 46 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100662:	c7 44 24 08 2f 3f 10 	movl   $0x103f2f,0x8(%esp)
f0100669:	00 
f010066a:	c7 44 24 04 2f 3f 10 	movl   $0xf0103f2f,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 dc 42 10 f0 	movl   $0xf01042dc,(%esp)
f0100679:	e8 2a 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010067e:	c7 44 24 08 00 83 11 	movl   $0x118300,0x8(%esp)
f0100685:	00 
f0100686:	c7 44 24 04 00 83 11 	movl   $0xf0118300,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 00 43 10 f0 	movl   $0xf0104300,(%esp)
f0100695:	e8 0e 28 00 00       	call   f0102ea8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010069a:	c7 44 24 08 70 89 11 	movl   $0x118970,0x8(%esp)
f01006a1:	00 
f01006a2:	c7 44 24 04 70 89 11 	movl   $0xf0118970,0x4(%esp)
f01006a9:	f0 
f01006aa:	c7 04 24 24 43 10 f0 	movl   $0xf0104324,(%esp)
f01006b1:	e8 f2 27 00 00       	call   f0102ea8 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006b6:	b8 6f 8d 11 f0       	mov    $0xf0118d6f,%eax
f01006bb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006c0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006c5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006cb:	85 c0                	test   %eax,%eax
f01006cd:	0f 48 c2             	cmovs  %edx,%eax
f01006d0:	c1 f8 0a             	sar    $0xa,%eax
f01006d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006d7:	c7 04 24 48 43 10 f0 	movl   $0xf0104348,(%esp)
f01006de:	e8 c5 27 00 00       	call   f0102ea8 <cprintf>
	return 0;
}
f01006e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e8:	c9                   	leave  
f01006e9:	c3                   	ret    

f01006ea <mon_help>:
{
f01006ea:	55                   	push   %ebp
f01006eb:	89 e5                	mov    %esp,%ebp
f01006ed:	56                   	push   %esi
f01006ee:	53                   	push   %ebx
f01006ef:	83 ec 10             	sub    $0x10,%esp
f01006f2:	bb 64 44 10 f0       	mov    $0xf0104464,%ebx
mon_help(int argc, char **argv, struct Trapframe *tf)
f01006f7:	be 88 44 10 f0       	mov    $0xf0104488,%esi
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006fc:	8b 03                	mov    (%ebx),%eax
f01006fe:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100702:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100705:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100709:	c7 04 24 e9 41 10 f0 	movl   $0xf01041e9,(%esp)
f0100710:	e8 93 27 00 00       	call   f0102ea8 <cprintf>
f0100715:	83 c3 0c             	add    $0xc,%ebx
	for (i = 0; i < NCOMMANDS; i++)
f0100718:	39 f3                	cmp    %esi,%ebx
f010071a:	75 e0                	jne    f01006fc <mon_help+0x12>
}
f010071c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100721:	83 c4 10             	add    $0x10,%esp
f0100724:	5b                   	pop    %ebx
f0100725:	5e                   	pop    %esi
f0100726:	5d                   	pop    %ebp
f0100727:	c3                   	ret    

f0100728 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100728:	55                   	push   %ebp
f0100729:	89 e5                	mov    %esp,%ebp
f010072b:	57                   	push   %edi
f010072c:	56                   	push   %esi
f010072d:	53                   	push   %ebx
f010072e:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	// Read ebp of mon_backtrace()
	unsigned int *ebp = (unsigned int *) read_ebp();
f0100731:	89 eb                	mov    %ebp,%ebx
	// The first five args of the current function
	unsigned int args[5];
	cprintf("Stack backtrace:\n");
f0100733:	c7 04 24 f2 41 10 f0 	movl   $0xf01041f2,(%esp)
f010073a:	e8 69 27 00 00       	call   f0102ea8 <cprintf>
		args[3] = (unsigned int) *(ebp + 5);
		args[4] = (unsigned int) *(ebp + 6);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip,
			args[0], args[1], args[2], args[3], args[4]);
		struct Eipdebuginfo info;
		debuginfo_eip((uintptr_t) eip, &info);
f010073f:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while(ebp) {
f0100742:	eb 77                	jmp    f01007bb <mon_backtrace+0x93>
		unsigned int eip = (unsigned int) *(ebp + 1);
f0100744:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip,
f0100747:	8b 43 18             	mov    0x18(%ebx),%eax
f010074a:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f010074e:	8b 43 14             	mov    0x14(%ebx),%eax
f0100751:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100755:	8b 43 10             	mov    0x10(%ebx),%eax
f0100758:	89 44 24 14          	mov    %eax,0x14(%esp)
f010075c:	8b 43 0c             	mov    0xc(%ebx),%eax
f010075f:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100763:	8b 43 08             	mov    0x8(%ebx),%eax
f0100766:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010076a:	89 74 24 08          	mov    %esi,0x8(%esp)
f010076e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100772:	c7 04 24 74 43 10 f0 	movl   $0xf0104374,(%esp)
f0100779:	e8 2a 27 00 00       	call   f0102ea8 <cprintf>
		debuginfo_eip((uintptr_t) eip, &info);
f010077e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100782:	89 34 24             	mov    %esi,(%esp)
f0100785:	e8 15 28 00 00       	call   f0102f9f <debuginfo_eip>
		cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line,
f010078a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010078d:	89 74 24 14          	mov    %esi,0x14(%esp)
f0100791:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100794:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100798:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010079b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010079f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ad:	c7 04 24 04 42 10 f0 	movl   $0xf0104204,(%esp)
f01007b4:	e8 ef 26 00 00       	call   f0102ea8 <cprintf>
			info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = (unsigned int *) *ebp;
f01007b9:	8b 1b                	mov    (%ebx),%ebx
	while(ebp) {
f01007bb:	85 db                	test   %ebx,%ebx
f01007bd:	75 85                	jne    f0100744 <mon_backtrace+0x1c>
	}
	return 0;
}
f01007bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c4:	83 c4 4c             	add    $0x4c,%esp
f01007c7:	5b                   	pop    %ebx
f01007c8:	5e                   	pop    %esi
f01007c9:	5f                   	pop    %edi
f01007ca:	5d                   	pop    %ebp
f01007cb:	c3                   	ret    

f01007cc <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007cc:	55                   	push   %ebp
f01007cd:	89 e5                	mov    %esp,%ebp
f01007cf:	57                   	push   %edi
f01007d0:	56                   	push   %esi
f01007d1:	53                   	push   %ebx
f01007d2:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007d5:	c7 04 24 ac 43 10 f0 	movl   $0xf01043ac,(%esp)
f01007dc:	e8 c7 26 00 00       	call   f0102ea8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e1:	c7 04 24 d0 43 10 f0 	movl   $0xf01043d0,(%esp)
f01007e8:	e8 bb 26 00 00       	call   f0102ea8 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007ed:	c7 04 24 1d 42 10 f0 	movl   $0xf010421d,(%esp)
f01007f4:	e8 d7 2f 00 00       	call   f01037d0 <readline>
f01007f9:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01007fb:	85 c0                	test   %eax,%eax
f01007fd:	74 ee                	je     f01007ed <monitor+0x21>
	argv[argc] = 0;
f01007ff:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100806:	bb 00 00 00 00       	mov    $0x0,%ebx
f010080b:	eb 06                	jmp    f0100813 <monitor+0x47>
			*buf++ = 0;
f010080d:	c6 06 00             	movb   $0x0,(%esi)
f0100810:	83 c6 01             	add    $0x1,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100813:	0f b6 06             	movzbl (%esi),%eax
f0100816:	84 c0                	test   %al,%al
f0100818:	74 63                	je     f010087d <monitor+0xb1>
f010081a:	0f be c0             	movsbl %al,%eax
f010081d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100821:	c7 04 24 21 42 10 f0 	movl   $0xf0104221,(%esp)
f0100828:	e8 b9 31 00 00       	call   f01039e6 <strchr>
f010082d:	85 c0                	test   %eax,%eax
f010082f:	75 dc                	jne    f010080d <monitor+0x41>
		if (*buf == 0)
f0100831:	80 3e 00             	cmpb   $0x0,(%esi)
f0100834:	74 47                	je     f010087d <monitor+0xb1>
		if (argc == MAXARGS-1) {
f0100836:	83 fb 0f             	cmp    $0xf,%ebx
f0100839:	75 16                	jne    f0100851 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010083b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100842:	00 
f0100843:	c7 04 24 26 42 10 f0 	movl   $0xf0104226,(%esp)
f010084a:	e8 59 26 00 00       	call   f0102ea8 <cprintf>
f010084f:	eb 9c                	jmp    f01007ed <monitor+0x21>
		argv[argc++] = buf;
f0100851:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100855:	83 c3 01             	add    $0x1,%ebx
f0100858:	eb 03                	jmp    f010085d <monitor+0x91>
			buf++;
f010085a:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010085d:	0f b6 06             	movzbl (%esi),%eax
f0100860:	84 c0                	test   %al,%al
f0100862:	74 af                	je     f0100813 <monitor+0x47>
f0100864:	0f be c0             	movsbl %al,%eax
f0100867:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086b:	c7 04 24 21 42 10 f0 	movl   $0xf0104221,(%esp)
f0100872:	e8 6f 31 00 00       	call   f01039e6 <strchr>
f0100877:	85 c0                	test   %eax,%eax
f0100879:	74 df                	je     f010085a <monitor+0x8e>
f010087b:	eb 96                	jmp    f0100813 <monitor+0x47>
	argv[argc] = 0;
f010087d:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100884:	00 
	if (argc == 0)
f0100885:	85 db                	test   %ebx,%ebx
f0100887:	0f 84 60 ff ff ff    	je     f01007ed <monitor+0x21>
f010088d:	bf 60 44 10 f0       	mov    $0xf0104460,%edi
f0100892:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100897:	8b 07                	mov    (%edi),%eax
f0100899:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008a0:	89 04 24             	mov    %eax,(%esp)
f01008a3:	e8 e0 30 00 00       	call   f0103988 <strcmp>
f01008a8:	85 c0                	test   %eax,%eax
f01008aa:	75 24                	jne    f01008d0 <monitor+0x104>
			return commands[i].func(argc, argv, tf);
f01008ac:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008af:	8b 55 08             	mov    0x8(%ebp),%edx
f01008b2:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008b6:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008bd:	89 1c 24             	mov    %ebx,(%esp)
f01008c0:	ff 14 85 68 44 10 f0 	call   *-0xfefbb98(,%eax,4)
			if (runcmd(buf, tf) < 0)
f01008c7:	85 c0                	test   %eax,%eax
f01008c9:	78 28                	js     f01008f3 <monitor+0x127>
f01008cb:	e9 1d ff ff ff       	jmp    f01007ed <monitor+0x21>
	for (i = 0; i < NCOMMANDS; i++) {
f01008d0:	83 c6 01             	add    $0x1,%esi
f01008d3:	83 c7 0c             	add    $0xc,%edi
f01008d6:	83 fe 03             	cmp    $0x3,%esi
f01008d9:	75 bc                	jne    f0100897 <monitor+0xcb>
	cprintf("Unknown command '%s'\n", argv[0]);
f01008db:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e2:	c7 04 24 43 42 10 f0 	movl   $0xf0104243,(%esp)
f01008e9:	e8 ba 25 00 00       	call   f0102ea8 <cprintf>
f01008ee:	e9 fa fe ff ff       	jmp    f01007ed <monitor+0x21>
				break;
	}
}
f01008f3:	83 c4 5c             	add    $0x5c,%esp
f01008f6:	5b                   	pop    %ebx
f01008f7:	5e                   	pop    %esi
f01008f8:	5f                   	pop    %edi
f01008f9:	5d                   	pop    %ebp
f01008fa:	c3                   	ret    

f01008fb <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01008fb:	89 d1                	mov    %edx,%ecx
f01008fd:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100900:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100903:	a8 01                	test   $0x1,%al
f0100905:	74 5d                	je     f0100964 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100907:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010090c:	89 c1                	mov    %eax,%ecx
f010090e:	c1 e9 0c             	shr    $0xc,%ecx
f0100911:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0100917:	72 26                	jb     f010093f <check_va2pa+0x44>
{
f0100919:	55                   	push   %ebp
f010091a:	89 e5                	mov    %esp,%ebp
f010091c:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010091f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100923:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f010092a:	f0 
f010092b:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f0100932:	00 
f0100933:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010093a:	e8 55 f7 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f010093f:	c1 ea 0c             	shr    $0xc,%edx
f0100942:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100948:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010094f:	89 c2                	mov    %eax,%edx
f0100951:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100954:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100959:	85 d2                	test   %edx,%edx
f010095b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100960:	0f 44 c2             	cmove  %edx,%eax
f0100963:	c3                   	ret    
		return ~0;
f0100964:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100969:	c3                   	ret    

f010096a <boot_alloc>:
{
f010096a:	55                   	push   %ebp
f010096b:	89 e5                	mov    %esp,%ebp
f010096d:	83 ec 18             	sub    $0x18,%esp
f0100970:	89 c2                	mov    %eax,%edx
	if (!nextfree) {
f0100972:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f0100979:	75 0f                	jne    f010098a <boot_alloc+0x20>
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010097b:	b8 6f 99 11 f0       	mov    $0xf011996f,%eax
f0100980:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100985:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
		return nextfree;
f010098a:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
	if(n==0)
f010098f:	85 d2                	test   %edx,%edx
f0100991:	74 74                	je     f0100a07 <boot_alloc+0x9d>
	result = nextfree;
f0100993:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100998:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f010099f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009a5:	89 15 3c 85 11 f0    	mov    %edx,0xf011853c
	if ((uint32_t)kva < KERNBASE)
f01009ab:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01009b1:	77 20                	ja     f01009d3 <boot_alloc+0x69>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01009b3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01009b7:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f01009be:	f0 
f01009bf:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
f01009c6:	00 
f01009c7:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01009ce:	e8 c1 f6 ff ff       	call   f0100094 <_panic>
	if((uint32_t)PADDR(nextfree) > npages*(PGSIZE)) {
f01009d3:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f01009d9:	c1 e1 0c             	shl    $0xc,%ecx
	return (physaddr_t)kva - KERNBASE;
f01009dc:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01009e2:	39 d1                	cmp    %edx,%ecx
f01009e4:	73 21                	jae    f0100a07 <boot_alloc+0x9d>
		nextfree = result;
f01009e6:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
		panic("Out of memory!\n");
f01009eb:	c7 44 24 08 2c 4c 10 	movl   $0xf0104c2c,0x8(%esp)
f01009f2:	f0 
f01009f3:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f01009fa:	00 
f01009fb:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100a02:	e8 8d f6 ff ff       	call   f0100094 <_panic>
}
f0100a07:	c9                   	leave  
f0100a08:	c3                   	ret    

f0100a09 <nvram_read>:
{
f0100a09:	55                   	push   %ebp
f0100a0a:	89 e5                	mov    %esp,%ebp
f0100a0c:	83 ec 18             	sub    $0x18,%esp
f0100a0f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a12:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a15:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a17:	89 04 24             	mov    %eax,(%esp)
f0100a1a:	e8 18 24 00 00       	call   f0102e37 <mc146818_read>
f0100a1f:	89 c6                	mov    %eax,%esi
f0100a21:	83 c3 01             	add    $0x1,%ebx
f0100a24:	89 1c 24             	mov    %ebx,(%esp)
f0100a27:	e8 0b 24 00 00       	call   f0102e37 <mc146818_read>
f0100a2c:	c1 e0 08             	shl    $0x8,%eax
f0100a2f:	09 f0                	or     %esi,%eax
}
f0100a31:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a34:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a37:	89 ec                	mov    %ebp,%esp
f0100a39:	5d                   	pop    %ebp
f0100a3a:	c3                   	ret    

f0100a3b <check_page_free_list>:
{
f0100a3b:	55                   	push   %ebp
f0100a3c:	89 e5                	mov    %esp,%ebp
f0100a3e:	57                   	push   %edi
f0100a3f:	56                   	push   %esi
f0100a40:	53                   	push   %ebx
f0100a41:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a44:	84 c0                	test   %al,%al
f0100a46:	0f 85 04 03 00 00    	jne    f0100d50 <check_page_free_list+0x315>
f0100a4c:	e9 11 03 00 00       	jmp    f0100d62 <check_page_free_list+0x327>
		panic("'page_free_list' is a null pointer!");
f0100a51:	c7 44 24 08 cc 44 10 	movl   $0xf01044cc,0x8(%esp)
f0100a58:	f0 
f0100a59:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100a60:	00 
f0100a61:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100a68:	e8 27 f6 ff ff       	call   f0100094 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a6d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a70:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a73:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a76:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a79:	89 c2                	mov    %eax,%edx
f0100a7b:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a81:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a87:	0f 95 c2             	setne  %dl
f0100a8a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a8d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a91:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a93:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a97:	8b 00                	mov    (%eax),%eax
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	75 dc                	jne    f0100a79 <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100a9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aa0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aac:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ab1:	a3 40 85 11 f0       	mov    %eax,0xf0118540
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab6:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100abb:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100ac1:	eb 63                	jmp    f0100b26 <check_page_free_list+0xeb>
f0100ac3:	89 d8                	mov    %ebx,%eax
f0100ac5:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100acb:	c1 f8 03             	sar    $0x3,%eax
f0100ace:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ad1:	89 c2                	mov    %eax,%edx
f0100ad3:	c1 ea 16             	shr    $0x16,%edx
f0100ad6:	39 f2                	cmp    %esi,%edx
f0100ad8:	73 4a                	jae    f0100b24 <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100ada:	89 c2                	mov    %eax,%edx
f0100adc:	c1 ea 0c             	shr    $0xc,%edx
f0100adf:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100ae5:	72 20                	jb     f0100b07 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100aeb:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0100af2:	f0 
f0100af3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100afa:	00 
f0100afb:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0100b02:	e8 8d f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b07:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b0e:	00 
f0100b0f:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b16:	00 
	return (void *)(pa + KERNBASE);
f0100b17:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b1c:	89 04 24             	mov    %eax,(%esp)
f0100b1f:	e8 ff 2e 00 00       	call   f0103a23 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b24:	8b 1b                	mov    (%ebx),%ebx
f0100b26:	85 db                	test   %ebx,%ebx
f0100b28:	75 99                	jne    f0100ac3 <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100b2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b2f:	e8 36 fe ff ff       	call   f010096a <boot_alloc>
f0100b34:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b37:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
		assert(pp >= pages);
f0100b3d:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
		assert(pp < pages + npages);
f0100b43:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100b48:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b4b:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b4e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b51:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b54:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b59:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b5c:	e9 97 01 00 00       	jmp    f0100cf8 <check_page_free_list+0x2bd>
		assert(pp >= pages);
f0100b61:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b64:	73 24                	jae    f0100b8a <check_page_free_list+0x14f>
f0100b66:	c7 44 24 0c 4a 4c 10 	movl   $0xf0104c4a,0xc(%esp)
f0100b6d:	f0 
f0100b6e:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100b75:	f0 
f0100b76:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100b7d:	00 
f0100b7e:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100b85:	e8 0a f5 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100b8a:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b8d:	72 24                	jb     f0100bb3 <check_page_free_list+0x178>
f0100b8f:	c7 44 24 0c 6b 4c 10 	movl   $0xf0104c6b,0xc(%esp)
f0100b96:	f0 
f0100b97:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100b9e:	f0 
f0100b9f:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f0100ba6:	00 
f0100ba7:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100bae:	e8 e1 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bb3:	89 d0                	mov    %edx,%eax
f0100bb5:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bb8:	a8 07                	test   $0x7,%al
f0100bba:	74 24                	je     f0100be0 <check_page_free_list+0x1a5>
f0100bbc:	c7 44 24 0c f0 44 10 	movl   $0xf01044f0,0xc(%esp)
f0100bc3:	f0 
f0100bc4:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100bcb:	f0 
f0100bcc:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0100bd3:	00 
f0100bd4:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100bdb:	e8 b4 f4 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0100be0:	c1 f8 03             	sar    $0x3,%eax
f0100be3:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100be6:	85 c0                	test   %eax,%eax
f0100be8:	75 24                	jne    f0100c0e <check_page_free_list+0x1d3>
f0100bea:	c7 44 24 0c 7f 4c 10 	movl   $0xf0104c7f,0xc(%esp)
f0100bf1:	f0 
f0100bf2:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100bf9:	f0 
f0100bfa:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f0100c01:	00 
f0100c02:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100c09:	e8 86 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c0e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c13:	75 24                	jne    f0100c39 <check_page_free_list+0x1fe>
f0100c15:	c7 44 24 0c 90 4c 10 	movl   $0xf0104c90,0xc(%esp)
f0100c1c:	f0 
f0100c1d:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100c24:	f0 
f0100c25:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f0100c2c:	00 
f0100c2d:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100c34:	e8 5b f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c39:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c3e:	75 24                	jne    f0100c64 <check_page_free_list+0x229>
f0100c40:	c7 44 24 0c 24 45 10 	movl   $0xf0104524,0xc(%esp)
f0100c47:	f0 
f0100c48:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100c4f:	f0 
f0100c50:	c7 44 24 04 59 02 00 	movl   $0x259,0x4(%esp)
f0100c57:	00 
f0100c58:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100c5f:	e8 30 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c64:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c69:	75 24                	jne    f0100c8f <check_page_free_list+0x254>
f0100c6b:	c7 44 24 0c a9 4c 10 	movl   $0xf0104ca9,0xc(%esp)
f0100c72:	f0 
f0100c73:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100c7a:	f0 
f0100c7b:	c7 44 24 04 5a 02 00 	movl   $0x25a,0x4(%esp)
f0100c82:	00 
f0100c83:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100c8a:	e8 05 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c8f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c94:	76 58                	jbe    f0100cee <check_page_free_list+0x2b3>
	if (PGNUM(pa) >= npages)
f0100c96:	89 c1                	mov    %eax,%ecx
f0100c98:	c1 e9 0c             	shr    $0xc,%ecx
f0100c9b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100c9e:	77 20                	ja     f0100cc0 <check_page_free_list+0x285>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ca4:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0100cab:	f0 
f0100cac:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cb3:	00 
f0100cb4:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0100cbb:	e8 d4 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100cc0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cc5:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cc8:	76 29                	jbe    f0100cf3 <check_page_free_list+0x2b8>
f0100cca:	c7 44 24 0c 48 45 10 	movl   $0xf0104548,0xc(%esp)
f0100cd1:	f0 
f0100cd2:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100cd9:	f0 
f0100cda:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f0100ce1:	00 
f0100ce2:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100ce9:	e8 a6 f3 ff ff       	call   f0100094 <_panic>
			++nfree_basemem;
f0100cee:	83 c3 01             	add    $0x1,%ebx
f0100cf1:	eb 03                	jmp    f0100cf6 <check_page_free_list+0x2bb>
			++nfree_extmem;
f0100cf3:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cf6:	8b 12                	mov    (%edx),%edx
f0100cf8:	85 d2                	test   %edx,%edx
f0100cfa:	0f 85 61 fe ff ff    	jne    f0100b61 <check_page_free_list+0x126>
	assert(nfree_basemem > 0);
f0100d00:	85 db                	test   %ebx,%ebx
f0100d02:	7f 24                	jg     f0100d28 <check_page_free_list+0x2ed>
f0100d04:	c7 44 24 0c c3 4c 10 	movl   $0xf0104cc3,0xc(%esp)
f0100d0b:	f0 
f0100d0c:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100d13:	f0 
f0100d14:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0100d1b:	00 
f0100d1c:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100d23:	e8 6c f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d28:	85 ff                	test   %edi,%edi
f0100d2a:	7f 4d                	jg     f0100d79 <check_page_free_list+0x33e>
f0100d2c:	c7 44 24 0c d5 4c 10 	movl   $0xf0104cd5,0xc(%esp)
f0100d33:	f0 
f0100d34:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0100d3b:	f0 
f0100d3c:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0100d43:	00 
f0100d44:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100d4b:	e8 44 f3 ff ff       	call   f0100094 <_panic>
	if (!page_free_list)
f0100d50:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0100d55:	85 c0                	test   %eax,%eax
f0100d57:	0f 85 10 fd ff ff    	jne    f0100a6d <check_page_free_list+0x32>
f0100d5d:	e9 ef fc ff ff       	jmp    f0100a51 <check_page_free_list+0x16>
f0100d62:	83 3d 40 85 11 f0 00 	cmpl   $0x0,0xf0118540
f0100d69:	0f 84 e2 fc ff ff    	je     f0100a51 <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d6f:	be 00 04 00 00       	mov    $0x400,%esi
f0100d74:	e9 42 fd ff ff       	jmp    f0100abb <check_page_free_list+0x80>
}
f0100d79:	83 c4 4c             	add    $0x4c,%esp
f0100d7c:	5b                   	pop    %ebx
f0100d7d:	5e                   	pop    %esi
f0100d7e:	5f                   	pop    %edi
f0100d7f:	5d                   	pop    %ebp
f0100d80:	c3                   	ret    

f0100d81 <page_init>:
{
f0100d81:	55                   	push   %ebp
f0100d82:	89 e5                	mov    %esp,%ebp
f0100d84:	56                   	push   %esi
f0100d85:	53                   	push   %ebx
f0100d86:	83 ec 10             	sub    $0x10,%esp
	pages[0].pp_ref = 1;
f0100d89:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100d8e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++) {
f0100d94:	8b 35 38 85 11 f0    	mov    0xf0118538,%esi
f0100d9a:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100da0:	b8 01 00 00 00       	mov    $0x1,%eax
f0100da5:	eb 22                	jmp    f0100dc9 <page_init+0x48>
page_init(void)
f0100da7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100dae:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f0100db4:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100dbb:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100dbe:	8b 1d 6c 89 11 f0    	mov    0xf011896c,%ebx
f0100dc4:	01 d3                	add    %edx,%ebx
	for (i = 1; i < npages_basemem; i++) {
f0100dc6:	83 c0 01             	add    $0x1,%eax
f0100dc9:	39 f0                	cmp    %esi,%eax
f0100dcb:	72 da                	jb     f0100da7 <page_init+0x26>
f0100dcd:	89 1d 40 85 11 f0    	mov    %ebx,0xf0118540
		pages[i].pp_ref = 1;
f0100dd3:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100dd8:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0100ddd:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
f0100de4:	83 c3 01             	add    $0x1,%ebx
f0100de7:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100ded:	75 ee                	jne    f0100ddd <page_init+0x5c>
	size_t first_free_address = PADDR(boot_alloc(0));
f0100def:	b8 00 00 00 00       	mov    $0x0,%eax
f0100df4:	e8 71 fb ff ff       	call   f010096a <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100df9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100dfe:	77 20                	ja     f0100e20 <page_init+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e00:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e04:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f0100e0b:	f0 
f0100e0c:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f0100e13:	00 
f0100e14:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100e1b:	e8 74 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e20:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
	for (i = EXTPHYSMEM/PGSIZE; i < first_free_address/PGSIZE; i++) {
f0100e26:	c1 ea 0c             	shr    $0xc,%edx
		pages[i].pp_ref = 1;
f0100e29:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
	for (i = EXTPHYSMEM/PGSIZE; i < first_free_address/PGSIZE; i++) {
f0100e2e:	eb 0a                	jmp    f0100e3a <page_init+0xb9>
		pages[i].pp_ref = 1;
f0100e30:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = EXTPHYSMEM/PGSIZE; i < first_free_address/PGSIZE; i++) {
f0100e37:	83 c3 01             	add    $0x1,%ebx
f0100e3a:	39 d3                	cmp    %edx,%ebx
f0100e3c:	72 f2                	jb     f0100e30 <page_init+0xaf>
f0100e3e:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100e44:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100e4b:	eb 1e                	jmp    f0100e6b <page_init+0xea>
		pages[i].pp_ref = 0;
f0100e4d:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f0100e53:	66 c7 44 01 04 00 00 	movw   $0x0,0x4(%ecx,%eax,1)
		pages[i].pp_link = page_free_list;
f0100e5a:	89 1c 01             	mov    %ebx,(%ecx,%eax,1)
		page_free_list = &pages[i];
f0100e5d:	8b 1d 6c 89 11 f0    	mov    0xf011896c,%ebx
f0100e63:	01 c3                	add    %eax,%ebx
	for (i = first_free_address/PGSIZE; i < npages; i++) {
f0100e65:	83 c2 01             	add    $0x1,%edx
f0100e68:	83 c0 08             	add    $0x8,%eax
f0100e6b:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100e71:	72 da                	jb     f0100e4d <page_init+0xcc>
f0100e73:	89 1d 40 85 11 f0    	mov    %ebx,0xf0118540
}
f0100e79:	83 c4 10             	add    $0x10,%esp
f0100e7c:	5b                   	pop    %ebx
f0100e7d:	5e                   	pop    %esi
f0100e7e:	5d                   	pop    %ebp
f0100e7f:	c3                   	ret    

f0100e80 <page_alloc>:
{
f0100e80:	55                   	push   %ebp
f0100e81:	89 e5                	mov    %esp,%ebp
f0100e83:	53                   	push   %ebx
f0100e84:	83 ec 14             	sub    $0x14,%esp
	if(page_free_list == NULL)
f0100e87:	8b 1d 40 85 11 f0    	mov    0xf0118540,%ebx
f0100e8d:	85 db                	test   %ebx,%ebx
f0100e8f:	74 6b                	je     f0100efc <page_alloc+0x7c>
	page_free_list = page->pp_link;
f0100e91:	8b 03                	mov    (%ebx),%eax
f0100e93:	a3 40 85 11 f0       	mov    %eax,0xf0118540
	page->pp_link = 0;
f0100e98:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100e9e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ea2:	74 58                	je     f0100efc <page_alloc+0x7c>
	return (pp - pages) << PGSHIFT;
f0100ea4:	89 d8                	mov    %ebx,%eax
f0100ea6:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100eac:	c1 f8 03             	sar    $0x3,%eax
f0100eaf:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100eb2:	89 c2                	mov    %eax,%edx
f0100eb4:	c1 ea 0c             	shr    $0xc,%edx
f0100eb7:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100ebd:	72 20                	jb     f0100edf <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ebf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ec3:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0100eca:	f0 
f0100ecb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ed2:	00 
f0100ed3:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0100eda:	e8 b5 f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(page), 0, PGSIZE);
f0100edf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100ee6:	00 
f0100ee7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100eee:	00 
	return (void *)(pa + KERNBASE);
f0100eef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ef4:	89 04 24             	mov    %eax,(%esp)
f0100ef7:	e8 27 2b 00 00       	call   f0103a23 <memset>
}
f0100efc:	89 d8                	mov    %ebx,%eax
f0100efe:	83 c4 14             	add    $0x14,%esp
f0100f01:	5b                   	pop    %ebx
f0100f02:	5d                   	pop    %ebp
f0100f03:	c3                   	ret    

f0100f04 <page_free>:
{
f0100f04:	55                   	push   %ebp
f0100f05:	89 e5                	mov    %esp,%ebp
f0100f07:	83 ec 18             	sub    $0x18,%esp
f0100f0a:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref > 0 || pp->pp_link != NULL) {
f0100f0d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f12:	75 05                	jne    f0100f19 <page_free+0x15>
f0100f14:	83 38 00             	cmpl   $0x0,(%eax)
f0100f17:	74 1c                	je     f0100f35 <page_free+0x31>
		panic("Double check failed when dealloc page");
f0100f19:	c7 44 24 08 90 45 10 	movl   $0xf0104590,0x8(%esp)
f0100f20:	f0 
f0100f21:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
f0100f28:	00 
f0100f29:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100f30:	e8 5f f1 ff ff       	call   f0100094 <_panic>
	pp->pp_link = page_free_list;
f0100f35:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
f0100f3b:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f3d:	a3 40 85 11 f0       	mov    %eax,0xf0118540
}
f0100f42:	c9                   	leave  
f0100f43:	c3                   	ret    

f0100f44 <page_decref>:
{
f0100f44:	55                   	push   %ebp
f0100f45:	89 e5                	mov    %esp,%ebp
f0100f47:	83 ec 18             	sub    $0x18,%esp
f0100f4a:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f4d:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f51:	83 ea 01             	sub    $0x1,%edx
f0100f54:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f58:	66 85 d2             	test   %dx,%dx
f0100f5b:	75 08                	jne    f0100f65 <page_decref+0x21>
		page_free(pp);
f0100f5d:	89 04 24             	mov    %eax,(%esp)
f0100f60:	e8 9f ff ff ff       	call   f0100f04 <page_free>
}
f0100f65:	c9                   	leave  
f0100f66:	c3                   	ret    

f0100f67 <pgdir_walk>:
{
f0100f67:	55                   	push   %ebp
f0100f68:	89 e5                	mov    %esp,%ebp
f0100f6a:	56                   	push   %esi
f0100f6b:	53                   	push   %ebx
f0100f6c:	83 ec 10             	sub    $0x10,%esp
f0100f6f:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint32_t page_tab_idx = PTX(va);
f0100f72:	89 c3                	mov    %eax,%ebx
f0100f74:	c1 eb 0c             	shr    $0xc,%ebx
f0100f77:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
	uint32_t page_dir_idx = PDX(va);
f0100f7d:	c1 e8 16             	shr    $0x16,%eax
	if (pgdir[page_dir_idx] & PTE_P) {
f0100f80:	8d 34 85 00 00 00 00 	lea    0x0(,%eax,4),%esi
f0100f87:	03 75 08             	add    0x8(%ebp),%esi
f0100f8a:	8b 06                	mov    (%esi),%eax
f0100f8c:	a8 01                	test   $0x1,%al
f0100f8e:	74 3d                	je     f0100fcd <pgdir_walk+0x66>
		pgtab = KADDR(PTE_ADDR(pgdir[page_dir_idx]));
f0100f90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100f95:	89 c2                	mov    %eax,%edx
f0100f97:	c1 ea 0c             	shr    $0xc,%edx
f0100f9a:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100fa0:	72 20                	jb     f0100fc2 <pgdir_walk+0x5b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fa2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fa6:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0100fad:	f0 
f0100fae:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f0100fb5:	00 
f0100fb6:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0100fbd:	e8 d2 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fc2:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100fc8:	e9 8d 00 00 00       	jmp    f010105a <pgdir_walk+0xf3>
		if (create) {
f0100fcd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fd1:	0f 84 88 00 00 00    	je     f010105f <pgdir_walk+0xf8>
			struct PageInfo *new_pageInfo = page_alloc(ALLOC_ZERO);
f0100fd7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fde:	e8 9d fe ff ff       	call   f0100e80 <page_alloc>
			if (new_pageInfo) {
f0100fe3:	85 c0                	test   %eax,%eax
f0100fe5:	74 7f                	je     f0101066 <pgdir_walk+0xff>
				new_pageInfo->pp_ref += 1;
f0100fe7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0100fec:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100ff2:	c1 f8 03             	sar    $0x3,%eax
f0100ff5:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100ff8:	89 c2                	mov    %eax,%edx
f0100ffa:	c1 ea 0c             	shr    $0xc,%edx
f0100ffd:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101003:	72 20                	jb     f0101025 <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101005:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101009:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0101010:	f0 
f0101011:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101018:	00 
f0101019:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0101020:	e8 6f f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101025:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f010102b:	89 ca                	mov    %ecx,%edx
	if ((uint32_t)kva < KERNBASE)
f010102d:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0101033:	77 20                	ja     f0101055 <pgdir_walk+0xee>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101035:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101039:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f0101040:	f0 
f0101041:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f0101048:	00 
f0101049:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101050:	e8 3f f0 ff ff       	call   f0100094 <_panic>
				pgdir[page_dir_idx] = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
f0101055:	83 c8 07             	or     $0x7,%eax
f0101058:	89 06                	mov    %eax,(%esi)
	return &pgtab[page_tab_idx];
f010105a:	8d 04 9a             	lea    (%edx,%ebx,4),%eax
f010105d:	eb 0c                	jmp    f010106b <pgdir_walk+0x104>
			return NULL;
f010105f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101064:	eb 05                	jmp    f010106b <pgdir_walk+0x104>
				return NULL;
f0101066:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010106b:	83 c4 10             	add    $0x10,%esp
f010106e:	5b                   	pop    %ebx
f010106f:	5e                   	pop    %esi
f0101070:	5d                   	pop    %ebp
f0101071:	c3                   	ret    

f0101072 <boot_map_region>:
{
f0101072:	55                   	push   %ebp
f0101073:	89 e5                	mov    %esp,%ebp
f0101075:	57                   	push   %edi
f0101076:	56                   	push   %esi
f0101077:	53                   	push   %ebx
f0101078:	83 ec 2c             	sub    $0x2c,%esp
f010107b:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010107e:	89 d7                	mov    %edx,%edi
	size_t pg_num = PGNUM(size);
f0101080:	89 c8                	mov    %ecx,%eax
f0101082:	c1 e8 0c             	shr    $0xc,%eax
f0101085:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("map region size = %d, %d pages\n", size, pg_num);
f0101088:	89 44 24 08          	mov    %eax,0x8(%esp)
f010108c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101090:	c7 04 24 b8 45 10 f0 	movl   $0xf01045b8,(%esp)
f0101097:	e8 0c 1e 00 00       	call   f0102ea8 <cprintf>
	for (i = 0; i<pg_num; i++)
f010109c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010109f:	be 00 00 00 00       	mov    $0x0,%esi
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01010a4:	29 df                	sub    %ebx,%edi
		*pgtab = pa | perm | PTE_P;
f01010a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010a9:	83 c8 01             	or     $0x1,%eax
f01010ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i<pg_num; i++)
f01010af:	eb 2e                	jmp    f01010df <boot_map_region+0x6d>
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f01010b1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010b8:	00 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01010b9:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f01010bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010c3:	89 04 24             	mov    %eax,(%esp)
f01010c6:	e8 9c fe ff ff       	call   f0100f67 <pgdir_walk>
		if (!pgtab) {
f01010cb:	85 c0                	test   %eax,%eax
f01010cd:	74 15                	je     f01010e4 <boot_map_region+0x72>
		*pgtab = pa | perm | PTE_P;
f01010cf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010d2:	09 da                	or     %ebx,%edx
f01010d4:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f01010d6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i<pg_num; i++)
f01010dc:	83 c6 01             	add    $0x1,%esi
f01010df:	3b 75 e0             	cmp    -0x20(%ebp),%esi
f01010e2:	75 cd                	jne    f01010b1 <boot_map_region+0x3f>
}
f01010e4:	83 c4 2c             	add    $0x2c,%esp
f01010e7:	5b                   	pop    %ebx
f01010e8:	5e                   	pop    %esi
f01010e9:	5f                   	pop    %edi
f01010ea:	5d                   	pop    %ebp
f01010eb:	c3                   	ret    

f01010ec <page_lookup>:
{
f01010ec:	55                   	push   %ebp
f01010ed:	89 e5                	mov    %esp,%ebp
f01010ef:	53                   	push   %ebx
f01010f0:	83 ec 14             	sub    $0x14,%esp
f01010f3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgtab = pgdir_walk(pgdir, va, 0);
f01010f6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010fd:	00 
f01010fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101101:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101105:	8b 45 08             	mov    0x8(%ebp),%eax
f0101108:	89 04 24             	mov    %eax,(%esp)
f010110b:	e8 57 fe ff ff       	call   f0100f67 <pgdir_walk>
	if (!pgtab) {
f0101110:	85 c0                	test   %eax,%eax
f0101112:	74 3a                	je     f010114e <page_lookup+0x62>
	if (pte_store) {
f0101114:	85 db                	test   %ebx,%ebx
f0101116:	74 02                	je     f010111a <page_lookup+0x2e>
		*pte_store = pgtab;
f0101118:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pgtab));
f010111a:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010111c:	c1 e8 0c             	shr    $0xc,%eax
f010111f:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0101125:	72 1c                	jb     f0101143 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101127:	c7 44 24 08 d8 45 10 	movl   $0xf01045d8,0x8(%esp)
f010112e:	f0 
f010112f:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101136:	00 
f0101137:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f010113e:	e8 51 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101143:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0101149:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010114c:	eb 05                	jmp    f0101153 <page_lookup+0x67>
		return NULL;
f010114e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101153:	83 c4 14             	add    $0x14,%esp
f0101156:	5b                   	pop    %ebx
f0101157:	5d                   	pop    %ebp
f0101158:	c3                   	ret    

f0101159 <tlb_invalidate>:
{
f0101159:	55                   	push   %ebp
f010115a:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010115c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010115f:	0f 01 38             	invlpg (%eax)
}
f0101162:	5d                   	pop    %ebp
f0101163:	c3                   	ret    

f0101164 <page_remove>:
{
f0101164:	55                   	push   %ebp
f0101165:	89 e5                	mov    %esp,%ebp
f0101167:	83 ec 28             	sub    $0x28,%esp
f010116a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f010116d:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101170:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101173:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t **pte_store = &pgtab;
f0101176:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101179:	89 44 24 08          	mov    %eax,0x8(%esp)
	struct PageInfo *pInfo = page_lookup(pgdir, va, pte_store);
f010117d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101181:	89 1c 24             	mov    %ebx,(%esp)
f0101184:	e8 63 ff ff ff       	call   f01010ec <page_lookup>
	if (!pInfo) {
f0101189:	85 c0                	test   %eax,%eax
f010118b:	74 1d                	je     f01011aa <page_remove+0x46>
	page_decref(pInfo);
f010118d:	89 04 24             	mov    %eax,(%esp)
f0101190:	e8 af fd ff ff       	call   f0100f44 <page_decref>
	*pgtab = 0;
f0101195:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101198:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f010119e:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011a2:	89 1c 24             	mov    %ebx,(%esp)
f01011a5:	e8 af ff ff ff       	call   f0101159 <tlb_invalidate>
}
f01011aa:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01011ad:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01011b0:	89 ec                	mov    %ebp,%esp
f01011b2:	5d                   	pop    %ebp
f01011b3:	c3                   	ret    

f01011b4 <page_insert>:
{
f01011b4:	55                   	push   %ebp
f01011b5:	89 e5                	mov    %esp,%ebp
f01011b7:	83 ec 28             	sub    $0x28,%esp
f01011ba:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01011bd:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01011c0:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01011c3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011c6:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pgtab = pgdir_walk(pgdir, va, 1);
f01011c9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011d0:	00 
f01011d1:	8b 45 10             	mov    0x10(%ebp),%eax
f01011d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011d8:	89 1c 24             	mov    %ebx,(%esp)
f01011db:	e8 87 fd ff ff       	call   f0100f67 <pgdir_walk>
f01011e0:	89 c6                	mov    %eax,%esi
	if (!pgtab) {
f01011e2:	85 c0                	test   %eax,%eax
f01011e4:	74 51                	je     f0101237 <page_insert+0x83>
	pp->pp_ref++;
f01011e6:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	if (*pgtab & PTE_P) {
f01011eb:	f6 00 01             	testb  $0x1,(%eax)
f01011ee:	74 1e                	je     f010120e <page_insert+0x5a>
		tlb_invalidate(pgdir, va);
f01011f0:	8b 55 10             	mov    0x10(%ebp),%edx
f01011f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011f7:	89 1c 24             	mov    %ebx,(%esp)
f01011fa:	e8 5a ff ff ff       	call   f0101159 <tlb_invalidate>
		page_remove(pgdir, va);
f01011ff:	8b 45 10             	mov    0x10(%ebp),%eax
f0101202:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101206:	89 1c 24             	mov    %ebx,(%esp)
f0101209:	e8 56 ff ff ff       	call   f0101164 <page_remove>
	*pgtab = page2pa(pp) | perm | PTE_P;
f010120e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101211:	83 c8 01             	or     $0x1,%eax
	return (pp - pages) << PGSHIFT;
f0101214:	2b 3d 6c 89 11 f0    	sub    0xf011896c,%edi
f010121a:	c1 ff 03             	sar    $0x3,%edi
f010121d:	c1 e7 0c             	shl    $0xc,%edi
f0101220:	09 c7                	or     %eax,%edi
f0101222:	89 3e                	mov    %edi,(%esi)
	pgdir[PDX(va)] |= perm;
f0101224:	8b 45 10             	mov    0x10(%ebp),%eax
f0101227:	c1 e8 16             	shr    $0x16,%eax
f010122a:	8b 55 14             	mov    0x14(%ebp),%edx
f010122d:	09 14 83             	or     %edx,(%ebx,%eax,4)
	return 0;
f0101230:	b8 00 00 00 00       	mov    $0x0,%eax
f0101235:	eb 05                	jmp    f010123c <page_insert+0x88>
		return -E_NO_MEM;
f0101237:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f010123c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010123f:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101242:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101245:	89 ec                	mov    %ebp,%esp
f0101247:	5d                   	pop    %ebp
f0101248:	c3                   	ret    

f0101249 <mem_init>:
{
f0101249:	55                   	push   %ebp
f010124a:	89 e5                	mov    %esp,%ebp
f010124c:	57                   	push   %edi
f010124d:	56                   	push   %esi
f010124e:	53                   	push   %ebx
f010124f:	83 ec 3c             	sub    $0x3c,%esp
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101252:	b8 15 00 00 00       	mov    $0x15,%eax
f0101257:	e8 ad f7 ff ff       	call   f0100a09 <nvram_read>
f010125c:	c1 e0 0a             	shl    $0xa,%eax
f010125f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101265:	85 c0                	test   %eax,%eax
f0101267:	0f 48 c2             	cmovs  %edx,%eax
f010126a:	c1 f8 0c             	sar    $0xc,%eax
f010126d:	a3 38 85 11 f0       	mov    %eax,0xf0118538
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101272:	b8 17 00 00 00       	mov    $0x17,%eax
f0101277:	e8 8d f7 ff ff       	call   f0100a09 <nvram_read>
f010127c:	c1 e0 0a             	shl    $0xa,%eax
f010127f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101285:	85 c0                	test   %eax,%eax
f0101287:	0f 48 c2             	cmovs  %edx,%eax
f010128a:	c1 f8 0c             	sar    $0xc,%eax
	if (npages_extmem)
f010128d:	85 c0                	test   %eax,%eax
f010128f:	74 0e                	je     f010129f <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101291:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101297:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
f010129d:	eb 0c                	jmp    f01012ab <mem_init+0x62>
		npages = npages_basemem;
f010129f:	8b 15 38 85 11 f0    	mov    0xf0118538,%edx
f01012a5:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
		npages_extmem * PGSIZE / 1024);
f01012ab:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ae:	c1 e8 0a             	shr    $0xa,%eax
f01012b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages_basemem * PGSIZE / 1024,
f01012b5:	a1 38 85 11 f0       	mov    0xf0118538,%eax
f01012ba:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012bd:	c1 e8 0a             	shr    $0xa,%eax
f01012c0:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012c4:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01012c9:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012cc:	c1 e8 0a             	shr    $0xa,%eax
f01012cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d3:	c7 04 24 f8 45 10 f0 	movl   $0xf01045f8,(%esp)
f01012da:	e8 c9 1b 00 00       	call   f0102ea8 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012df:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012e4:	e8 81 f6 ff ff       	call   f010096a <boot_alloc>
f01012e9:	a3 68 89 11 f0       	mov    %eax,0xf0118968
	memset(kern_pgdir, 0, PGSIZE);
f01012ee:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012f5:	00 
f01012f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012fd:	00 
f01012fe:	89 04 24             	mov    %eax,(%esp)
f0101301:	e8 1d 27 00 00       	call   f0103a23 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101306:	a1 68 89 11 f0       	mov    0xf0118968,%eax
	if ((uint32_t)kva < KERNBASE)
f010130b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101310:	77 20                	ja     f0101332 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101312:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101316:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f010131d:	f0 
f010131e:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
f0101325:	00 
f0101326:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010132d:	e8 62 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101332:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101338:	83 ca 05             	or     $0x5,%edx
f010133b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101341:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0101346:	c1 e0 03             	shl    $0x3,%eax
f0101349:	e8 1c f6 ff ff       	call   f010096a <boot_alloc>
f010134e:	a3 6c 89 11 f0       	mov    %eax,0xf011896c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101353:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f0101359:	c1 e2 03             	shl    $0x3,%edx
f010135c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101360:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101367:	00 
f0101368:	89 04 24             	mov    %eax,(%esp)
f010136b:	e8 b3 26 00 00       	call   f0103a23 <memset>
	page_init();
f0101370:	e8 0c fa ff ff       	call   f0100d81 <page_init>
	check_page_free_list(1);
f0101375:	b8 01 00 00 00       	mov    $0x1,%eax
f010137a:	e8 bc f6 ff ff       	call   f0100a3b <check_page_free_list>
	if (!pages)
f010137f:	83 3d 6c 89 11 f0 00 	cmpl   $0x0,0xf011896c
f0101386:	75 1c                	jne    f01013a4 <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f0101388:	c7 44 24 08 e6 4c 10 	movl   $0xf0104ce6,0x8(%esp)
f010138f:	f0 
f0101390:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101397:	00 
f0101398:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010139f:	e8 f0 ec ff ff       	call   f0100094 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013a4:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f01013a9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013ae:	eb 05                	jmp    f01013b5 <mem_init+0x16c>
		++nfree;
f01013b0:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b3:	8b 00                	mov    (%eax),%eax
f01013b5:	85 c0                	test   %eax,%eax
f01013b7:	75 f7                	jne    f01013b0 <mem_init+0x167>
	assert((pp0 = page_alloc(0)));
f01013b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c0:	e8 bb fa ff ff       	call   f0100e80 <page_alloc>
f01013c5:	89 c7                	mov    %eax,%edi
f01013c7:	85 c0                	test   %eax,%eax
f01013c9:	75 24                	jne    f01013ef <mem_init+0x1a6>
f01013cb:	c7 44 24 0c 01 4d 10 	movl   $0xf0104d01,0xc(%esp)
f01013d2:	f0 
f01013d3:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01013da:	f0 
f01013db:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01013e2:	00 
f01013e3:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01013ea:	e8 a5 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013ef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f6:	e8 85 fa ff ff       	call   f0100e80 <page_alloc>
f01013fb:	89 c6                	mov    %eax,%esi
f01013fd:	85 c0                	test   %eax,%eax
f01013ff:	75 24                	jne    f0101425 <mem_init+0x1dc>
f0101401:	c7 44 24 0c 17 4d 10 	movl   $0xf0104d17,0xc(%esp)
f0101408:	f0 
f0101409:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101410:	f0 
f0101411:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101418:	00 
f0101419:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101420:	e8 6f ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101425:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010142c:	e8 4f fa ff ff       	call   f0100e80 <page_alloc>
f0101431:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101434:	85 c0                	test   %eax,%eax
f0101436:	75 24                	jne    f010145c <mem_init+0x213>
f0101438:	c7 44 24 0c 2d 4d 10 	movl   $0xf0104d2d,0xc(%esp)
f010143f:	f0 
f0101440:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101447:	f0 
f0101448:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f010144f:	00 
f0101450:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101457:	e8 38 ec ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f010145c:	39 f7                	cmp    %esi,%edi
f010145e:	75 24                	jne    f0101484 <mem_init+0x23b>
f0101460:	c7 44 24 0c 43 4d 10 	movl   $0xf0104d43,0xc(%esp)
f0101467:	f0 
f0101468:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010146f:	f0 
f0101470:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0101477:	00 
f0101478:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010147f:	e8 10 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101484:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101487:	74 05                	je     f010148e <mem_init+0x245>
f0101489:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010148c:	75 24                	jne    f01014b2 <mem_init+0x269>
f010148e:	c7 44 24 0c 34 46 10 	movl   $0xf0104634,0xc(%esp)
f0101495:	f0 
f0101496:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010149d:	f0 
f010149e:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f01014a5:	00 
f01014a6:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01014ad:	e8 e2 eb ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f01014b2:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014b8:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01014bd:	c1 e0 0c             	shl    $0xc,%eax
f01014c0:	89 f9                	mov    %edi,%ecx
f01014c2:	29 d1                	sub    %edx,%ecx
f01014c4:	c1 f9 03             	sar    $0x3,%ecx
f01014c7:	c1 e1 0c             	shl    $0xc,%ecx
f01014ca:	39 c1                	cmp    %eax,%ecx
f01014cc:	72 24                	jb     f01014f2 <mem_init+0x2a9>
f01014ce:	c7 44 24 0c 55 4d 10 	movl   $0xf0104d55,0xc(%esp)
f01014d5:	f0 
f01014d6:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01014dd:	f0 
f01014de:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f01014e5:	00 
f01014e6:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01014ed:	e8 a2 eb ff ff       	call   f0100094 <_panic>
f01014f2:	89 f1                	mov    %esi,%ecx
f01014f4:	29 d1                	sub    %edx,%ecx
f01014f6:	c1 f9 03             	sar    $0x3,%ecx
f01014f9:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014fc:	39 c8                	cmp    %ecx,%eax
f01014fe:	77 24                	ja     f0101524 <mem_init+0x2db>
f0101500:	c7 44 24 0c 72 4d 10 	movl   $0xf0104d72,0xc(%esp)
f0101507:	f0 
f0101508:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010150f:	f0 
f0101510:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f0101517:	00 
f0101518:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010151f:	e8 70 eb ff ff       	call   f0100094 <_panic>
f0101524:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101527:	29 d1                	sub    %edx,%ecx
f0101529:	89 ca                	mov    %ecx,%edx
f010152b:	c1 fa 03             	sar    $0x3,%edx
f010152e:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101531:	39 d0                	cmp    %edx,%eax
f0101533:	77 24                	ja     f0101559 <mem_init+0x310>
f0101535:	c7 44 24 0c 8f 4d 10 	movl   $0xf0104d8f,0xc(%esp)
f010153c:	f0 
f010153d:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101544:	f0 
f0101545:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f010154c:	00 
f010154d:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101554:	e8 3b eb ff ff       	call   f0100094 <_panic>
	fl = page_free_list;
f0101559:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f010155e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101561:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f0101568:	00 00 00 
	assert(!page_alloc(0));
f010156b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101572:	e8 09 f9 ff ff       	call   f0100e80 <page_alloc>
f0101577:	85 c0                	test   %eax,%eax
f0101579:	74 24                	je     f010159f <mem_init+0x356>
f010157b:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0101582:	f0 
f0101583:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010158a:	f0 
f010158b:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f0101592:	00 
f0101593:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010159a:	e8 f5 ea ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010159f:	89 3c 24             	mov    %edi,(%esp)
f01015a2:	e8 5d f9 ff ff       	call   f0100f04 <page_free>
	page_free(pp1);
f01015a7:	89 34 24             	mov    %esi,(%esp)
f01015aa:	e8 55 f9 ff ff       	call   f0100f04 <page_free>
	page_free(pp2);
f01015af:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015b2:	89 04 24             	mov    %eax,(%esp)
f01015b5:	e8 4a f9 ff ff       	call   f0100f04 <page_free>
	assert((pp0 = page_alloc(0)));
f01015ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c1:	e8 ba f8 ff ff       	call   f0100e80 <page_alloc>
f01015c6:	89 c6                	mov    %eax,%esi
f01015c8:	85 c0                	test   %eax,%eax
f01015ca:	75 24                	jne    f01015f0 <mem_init+0x3a7>
f01015cc:	c7 44 24 0c 01 4d 10 	movl   $0xf0104d01,0xc(%esp)
f01015d3:	f0 
f01015d4:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01015db:	f0 
f01015dc:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01015e3:	00 
f01015e4:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01015eb:	e8 a4 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f7:	e8 84 f8 ff ff       	call   f0100e80 <page_alloc>
f01015fc:	89 c7                	mov    %eax,%edi
f01015fe:	85 c0                	test   %eax,%eax
f0101600:	75 24                	jne    f0101626 <mem_init+0x3dd>
f0101602:	c7 44 24 0c 17 4d 10 	movl   $0xf0104d17,0xc(%esp)
f0101609:	f0 
f010160a:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101611:	f0 
f0101612:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0101619:	00 
f010161a:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101621:	e8 6e ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101626:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162d:	e8 4e f8 ff ff       	call   f0100e80 <page_alloc>
f0101632:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101635:	85 c0                	test   %eax,%eax
f0101637:	75 24                	jne    f010165d <mem_init+0x414>
f0101639:	c7 44 24 0c 2d 4d 10 	movl   $0xf0104d2d,0xc(%esp)
f0101640:	f0 
f0101641:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101648:	f0 
f0101649:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101650:	00 
f0101651:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101658:	e8 37 ea ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f010165d:	39 fe                	cmp    %edi,%esi
f010165f:	75 24                	jne    f0101685 <mem_init+0x43c>
f0101661:	c7 44 24 0c 43 4d 10 	movl   $0xf0104d43,0xc(%esp)
f0101668:	f0 
f0101669:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101670:	f0 
f0101671:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0101678:	00 
f0101679:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101680:	e8 0f ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101685:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101688:	74 05                	je     f010168f <mem_init+0x446>
f010168a:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010168d:	75 24                	jne    f01016b3 <mem_init+0x46a>
f010168f:	c7 44 24 0c 34 46 10 	movl   $0xf0104634,0xc(%esp)
f0101696:	f0 
f0101697:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010169e:	f0 
f010169f:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f01016a6:	00 
f01016a7:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01016ae:	e8 e1 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016ba:	e8 c1 f7 ff ff       	call   f0100e80 <page_alloc>
f01016bf:	85 c0                	test   %eax,%eax
f01016c1:	74 24                	je     f01016e7 <mem_init+0x49e>
f01016c3:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f01016ca:	f0 
f01016cb:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01016d2:	f0 
f01016d3:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f01016da:	00 
f01016db:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01016e2:	e8 ad e9 ff ff       	call   f0100094 <_panic>
f01016e7:	89 f0                	mov    %esi,%eax
f01016e9:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01016ef:	c1 f8 03             	sar    $0x3,%eax
f01016f2:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01016f5:	89 c2                	mov    %eax,%edx
f01016f7:	c1 ea 0c             	shr    $0xc,%edx
f01016fa:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101700:	72 20                	jb     f0101722 <mem_init+0x4d9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101702:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101706:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f010170d:	f0 
f010170e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101715:	00 
f0101716:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f010171d:	e8 72 e9 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f0101722:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101729:	00 
f010172a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101731:	00 
	return (void *)(pa + KERNBASE);
f0101732:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101737:	89 04 24             	mov    %eax,(%esp)
f010173a:	e8 e4 22 00 00       	call   f0103a23 <memset>
	page_free(pp0);
f010173f:	89 34 24             	mov    %esi,(%esp)
f0101742:	e8 bd f7 ff ff       	call   f0100f04 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101747:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010174e:	e8 2d f7 ff ff       	call   f0100e80 <page_alloc>
f0101753:	85 c0                	test   %eax,%eax
f0101755:	75 24                	jne    f010177b <mem_init+0x532>
f0101757:	c7 44 24 0c bb 4d 10 	movl   $0xf0104dbb,0xc(%esp)
f010175e:	f0 
f010175f:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101766:	f0 
f0101767:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
f010176e:	00 
f010176f:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101776:	e8 19 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010177b:	39 c6                	cmp    %eax,%esi
f010177d:	74 24                	je     f01017a3 <mem_init+0x55a>
f010177f:	c7 44 24 0c d9 4d 10 	movl   $0xf0104dd9,0xc(%esp)
f0101786:	f0 
f0101787:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010178e:	f0 
f010178f:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0101796:	00 
f0101797:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010179e:	e8 f1 e8 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f01017a3:	89 f2                	mov    %esi,%edx
f01017a5:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01017ab:	c1 fa 03             	sar    $0x3,%edx
f01017ae:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01017b1:	89 d0                	mov    %edx,%eax
f01017b3:	c1 e8 0c             	shr    $0xc,%eax
f01017b6:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f01017bc:	72 20                	jb     f01017de <mem_init+0x595>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017be:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017c2:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f01017c9:	f0 
f01017ca:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017d1:	00 
f01017d2:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f01017d9:	e8 b6 e8 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01017de:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
mem_init(void)
f01017e4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01017ea:	80 38 00             	cmpb   $0x0,(%eax)
f01017ed:	74 24                	je     f0101813 <mem_init+0x5ca>
f01017ef:	c7 44 24 0c e9 4d 10 	movl   $0xf0104de9,0xc(%esp)
f01017f6:	f0 
f01017f7:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01017fe:	f0 
f01017ff:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0101806:	00 
f0101807:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010180e:	e8 81 e8 ff ff       	call   f0100094 <_panic>
f0101813:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101816:	39 d0                	cmp    %edx,%eax
f0101818:	75 d0                	jne    f01017ea <mem_init+0x5a1>
	page_free_list = fl;
f010181a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010181d:	89 15 40 85 11 f0    	mov    %edx,0xf0118540
	page_free(pp0);
f0101823:	89 34 24             	mov    %esi,(%esp)
f0101826:	e8 d9 f6 ff ff       	call   f0100f04 <page_free>
	page_free(pp1);
f010182b:	89 3c 24             	mov    %edi,(%esp)
f010182e:	e8 d1 f6 ff ff       	call   f0100f04 <page_free>
	page_free(pp2);
f0101833:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101836:	89 04 24             	mov    %eax,(%esp)
f0101839:	e8 c6 f6 ff ff       	call   f0100f04 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010183e:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f0101843:	eb 05                	jmp    f010184a <mem_init+0x601>
		--nfree;
f0101845:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101848:	8b 00                	mov    (%eax),%eax
f010184a:	85 c0                	test   %eax,%eax
f010184c:	75 f7                	jne    f0101845 <mem_init+0x5fc>
	assert(nfree == 0);
f010184e:	85 db                	test   %ebx,%ebx
f0101850:	74 24                	je     f0101876 <mem_init+0x62d>
f0101852:	c7 44 24 0c f3 4d 10 	movl   $0xf0104df3,0xc(%esp)
f0101859:	f0 
f010185a:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101861:	f0 
f0101862:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f0101869:	00 
f010186a:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101871:	e8 1e e8 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f0101876:	c7 04 24 54 46 10 f0 	movl   $0xf0104654,(%esp)
f010187d:	e8 26 16 00 00       	call   f0102ea8 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101882:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101889:	e8 f2 f5 ff ff       	call   f0100e80 <page_alloc>
f010188e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101891:	85 c0                	test   %eax,%eax
f0101893:	75 24                	jne    f01018b9 <mem_init+0x670>
f0101895:	c7 44 24 0c 01 4d 10 	movl   $0xf0104d01,0xc(%esp)
f010189c:	f0 
f010189d:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01018a4:	f0 
f01018a5:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01018ac:	00 
f01018ad:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01018b4:	e8 db e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018c0:	e8 bb f5 ff ff       	call   f0100e80 <page_alloc>
f01018c5:	89 c3                	mov    %eax,%ebx
f01018c7:	85 c0                	test   %eax,%eax
f01018c9:	75 24                	jne    f01018ef <mem_init+0x6a6>
f01018cb:	c7 44 24 0c 17 4d 10 	movl   $0xf0104d17,0xc(%esp)
f01018d2:	f0 
f01018d3:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01018da:	f0 
f01018db:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f01018e2:	00 
f01018e3:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01018ea:	e8 a5 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018ef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f6:	e8 85 f5 ff ff       	call   f0100e80 <page_alloc>
f01018fb:	89 c6                	mov    %eax,%esi
f01018fd:	85 c0                	test   %eax,%eax
f01018ff:	75 24                	jne    f0101925 <mem_init+0x6dc>
f0101901:	c7 44 24 0c 2d 4d 10 	movl   $0xf0104d2d,0xc(%esp)
f0101908:	f0 
f0101909:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101910:	f0 
f0101911:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101918:	00 
f0101919:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101920:	e8 6f e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101925:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101928:	75 24                	jne    f010194e <mem_init+0x705>
f010192a:	c7 44 24 0c 43 4d 10 	movl   $0xf0104d43,0xc(%esp)
f0101931:	f0 
f0101932:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101939:	f0 
f010193a:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101941:	00 
f0101942:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101949:	e8 46 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010194e:	39 c3                	cmp    %eax,%ebx
f0101950:	74 05                	je     f0101957 <mem_init+0x70e>
f0101952:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101955:	75 24                	jne    f010197b <mem_init+0x732>
f0101957:	c7 44 24 0c 34 46 10 	movl   $0xf0104634,0xc(%esp)
f010195e:	f0 
f010195f:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101966:	f0 
f0101967:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f010196e:	00 
f010196f:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101976:	e8 19 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010197b:	8b 3d 40 85 11 f0    	mov    0xf0118540,%edi
f0101981:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f0101984:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f010198b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010198e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101995:	e8 e6 f4 ff ff       	call   f0100e80 <page_alloc>
f010199a:	85 c0                	test   %eax,%eax
f010199c:	74 24                	je     f01019c2 <mem_init+0x779>
f010199e:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f01019a5:	f0 
f01019a6:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01019ad:	f0 
f01019ae:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f01019b5:	00 
f01019b6:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01019bd:	e8 d2 e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019c2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019d0:	00 
f01019d1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01019d6:	89 04 24             	mov    %eax,(%esp)
f01019d9:	e8 0e f7 ff ff       	call   f01010ec <page_lookup>
f01019de:	85 c0                	test   %eax,%eax
f01019e0:	74 24                	je     f0101a06 <mem_init+0x7bd>
f01019e2:	c7 44 24 0c 74 46 10 	movl   $0xf0104674,0xc(%esp)
f01019e9:	f0 
f01019ea:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01019f1:	f0 
f01019f2:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f01019f9:	00 
f01019fa:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101a01:	e8 8e e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a06:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a0d:	00 
f0101a0e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a15:	00 
f0101a16:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a1a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101a1f:	89 04 24             	mov    %eax,(%esp)
f0101a22:	e8 8d f7 ff ff       	call   f01011b4 <page_insert>
f0101a27:	85 c0                	test   %eax,%eax
f0101a29:	78 24                	js     f0101a4f <mem_init+0x806>
f0101a2b:	c7 44 24 0c ac 46 10 	movl   $0xf01046ac,0xc(%esp)
f0101a32:	f0 
f0101a33:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101a3a:	f0 
f0101a3b:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101a42:	00 
f0101a43:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101a4a:	e8 45 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a52:	89 04 24             	mov    %eax,(%esp)
f0101a55:	e8 aa f4 ff ff       	call   f0100f04 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a5a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a61:	00 
f0101a62:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a69:	00 
f0101a6a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a6e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101a73:	89 04 24             	mov    %eax,(%esp)
f0101a76:	e8 39 f7 ff ff       	call   f01011b4 <page_insert>
f0101a7b:	85 c0                	test   %eax,%eax
f0101a7d:	74 24                	je     f0101aa3 <mem_init+0x85a>
f0101a7f:	c7 44 24 0c dc 46 10 	movl   $0xf01046dc,0xc(%esp)
f0101a86:	f0 
f0101a87:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101a8e:	f0 
f0101a8f:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101a96:	00 
f0101a97:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101a9e:	e8 f1 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101aa3:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
	return (pp - pages) << PGSHIFT;
f0101aa9:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0101aaf:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101ab2:	8b 17                	mov    (%edi),%edx
f0101ab4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101abd:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101ac0:	c1 f8 03             	sar    $0x3,%eax
f0101ac3:	c1 e0 0c             	shl    $0xc,%eax
f0101ac6:	39 c2                	cmp    %eax,%edx
f0101ac8:	74 24                	je     f0101aee <mem_init+0x8a5>
f0101aca:	c7 44 24 0c 0c 47 10 	movl   $0xf010470c,0xc(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101ad9:	f0 
f0101ada:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101ae1:	00 
f0101ae2:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101ae9:	e8 a6 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101aee:	ba 00 00 00 00       	mov    $0x0,%edx
f0101af3:	89 f8                	mov    %edi,%eax
f0101af5:	e8 01 ee ff ff       	call   f01008fb <check_va2pa>
f0101afa:	89 da                	mov    %ebx,%edx
f0101afc:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101aff:	c1 fa 03             	sar    $0x3,%edx
f0101b02:	c1 e2 0c             	shl    $0xc,%edx
f0101b05:	39 d0                	cmp    %edx,%eax
f0101b07:	74 24                	je     f0101b2d <mem_init+0x8e4>
f0101b09:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f0101b10:	f0 
f0101b11:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101b18:	f0 
f0101b19:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101b20:	00 
f0101b21:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101b28:	e8 67 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b2d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b32:	74 24                	je     f0101b58 <mem_init+0x90f>
f0101b34:	c7 44 24 0c fe 4d 10 	movl   $0xf0104dfe,0xc(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101b43:	f0 
f0101b44:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101b4b:	00 
f0101b4c:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101b53:	e8 3c e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b5b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b60:	74 24                	je     f0101b86 <mem_init+0x93d>
f0101b62:	c7 44 24 0c 0f 4e 10 	movl   $0xf0104e0f,0xc(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101b71:	f0 
f0101b72:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101b79:	00 
f0101b7a:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101b81:	e8 0e e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b86:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b8d:	00 
f0101b8e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b95:	00 
f0101b96:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b9a:	89 3c 24             	mov    %edi,(%esp)
f0101b9d:	e8 12 f6 ff ff       	call   f01011b4 <page_insert>
f0101ba2:	85 c0                	test   %eax,%eax
f0101ba4:	74 24                	je     f0101bca <mem_init+0x981>
f0101ba6:	c7 44 24 0c 64 47 10 	movl   $0xf0104764,0xc(%esp)
f0101bad:	f0 
f0101bae:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101bb5:	f0 
f0101bb6:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101bbd:	00 
f0101bbe:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101bc5:	e8 ca e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bca:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bcf:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101bd4:	e8 22 ed ff ff       	call   f01008fb <check_va2pa>
f0101bd9:	89 f2                	mov    %esi,%edx
f0101bdb:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101be1:	c1 fa 03             	sar    $0x3,%edx
f0101be4:	c1 e2 0c             	shl    $0xc,%edx
f0101be7:	39 d0                	cmp    %edx,%eax
f0101be9:	74 24                	je     f0101c0f <mem_init+0x9c6>
f0101beb:	c7 44 24 0c a0 47 10 	movl   $0xf01047a0,0xc(%esp)
f0101bf2:	f0 
f0101bf3:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101bfa:	f0 
f0101bfb:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101c02:	00 
f0101c03:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101c0a:	e8 85 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c0f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c14:	74 24                	je     f0101c3a <mem_init+0x9f1>
f0101c16:	c7 44 24 0c 20 4e 10 	movl   $0xf0104e20,0xc(%esp)
f0101c1d:	f0 
f0101c1e:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101c25:	f0 
f0101c26:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101c2d:	00 
f0101c2e:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101c35:	e8 5a e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c3a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c41:	e8 3a f2 ff ff       	call   f0100e80 <page_alloc>
f0101c46:	85 c0                	test   %eax,%eax
f0101c48:	74 24                	je     f0101c6e <mem_init+0xa25>
f0101c4a:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0101c51:	f0 
f0101c52:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101c59:	f0 
f0101c5a:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101c61:	00 
f0101c62:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101c69:	e8 26 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c6e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c75:	00 
f0101c76:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c7d:	00 
f0101c7e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c82:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101c87:	89 04 24             	mov    %eax,(%esp)
f0101c8a:	e8 25 f5 ff ff       	call   f01011b4 <page_insert>
f0101c8f:	85 c0                	test   %eax,%eax
f0101c91:	74 24                	je     f0101cb7 <mem_init+0xa6e>
f0101c93:	c7 44 24 0c 64 47 10 	movl   $0xf0104764,0xc(%esp)
f0101c9a:	f0 
f0101c9b:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101ca2:	f0 
f0101ca3:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101caa:	00 
f0101cab:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101cb2:	e8 dd e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cb7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cbc:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101cc1:	e8 35 ec ff ff       	call   f01008fb <check_va2pa>
f0101cc6:	89 f2                	mov    %esi,%edx
f0101cc8:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101cce:	c1 fa 03             	sar    $0x3,%edx
f0101cd1:	c1 e2 0c             	shl    $0xc,%edx
f0101cd4:	39 d0                	cmp    %edx,%eax
f0101cd6:	74 24                	je     f0101cfc <mem_init+0xab3>
f0101cd8:	c7 44 24 0c a0 47 10 	movl   $0xf01047a0,0xc(%esp)
f0101cdf:	f0 
f0101ce0:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101ce7:	f0 
f0101ce8:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101cef:	00 
f0101cf0:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101cf7:	e8 98 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cfc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d01:	74 24                	je     f0101d27 <mem_init+0xade>
f0101d03:	c7 44 24 0c 20 4e 10 	movl   $0xf0104e20,0xc(%esp)
f0101d0a:	f0 
f0101d0b:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101d12:	f0 
f0101d13:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101d1a:	00 
f0101d1b:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101d22:	e8 6d e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d27:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d2e:	e8 4d f1 ff ff       	call   f0100e80 <page_alloc>
f0101d33:	85 c0                	test   %eax,%eax
f0101d35:	74 24                	je     f0101d5b <mem_init+0xb12>
f0101d37:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0101d3e:	f0 
f0101d3f:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101d46:	f0 
f0101d47:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101d4e:	00 
f0101d4f:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101d56:	e8 39 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d5b:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0101d61:	8b 02                	mov    (%edx),%eax
f0101d63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d68:	89 c1                	mov    %eax,%ecx
f0101d6a:	c1 e9 0c             	shr    $0xc,%ecx
f0101d6d:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0101d73:	72 20                	jb     f0101d95 <mem_init+0xb4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d75:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d79:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0101d80:	f0 
f0101d81:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101d88:	00 
f0101d89:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101d90:	e8 ff e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d95:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d9d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101da4:	00 
f0101da5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101dac:	00 
f0101dad:	89 14 24             	mov    %edx,(%esp)
f0101db0:	e8 b2 f1 ff ff       	call   f0100f67 <pgdir_walk>
f0101db5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101db8:	83 c2 04             	add    $0x4,%edx
f0101dbb:	39 d0                	cmp    %edx,%eax
f0101dbd:	74 24                	je     f0101de3 <mem_init+0xb9a>
f0101dbf:	c7 44 24 0c d0 47 10 	movl   $0xf01047d0,0xc(%esp)
f0101dc6:	f0 
f0101dc7:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101dce:	f0 
f0101dcf:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101dd6:	00 
f0101dd7:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101dde:	e8 b1 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101de3:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101dea:	00 
f0101deb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101df2:	00 
f0101df3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101df7:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101dfc:	89 04 24             	mov    %eax,(%esp)
f0101dff:	e8 b0 f3 ff ff       	call   f01011b4 <page_insert>
f0101e04:	85 c0                	test   %eax,%eax
f0101e06:	74 24                	je     f0101e2c <mem_init+0xbe3>
f0101e08:	c7 44 24 0c 10 48 10 	movl   $0xf0104810,0xc(%esp)
f0101e0f:	f0 
f0101e10:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101e17:	f0 
f0101e18:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101e1f:	00 
f0101e20:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101e27:	e8 68 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e2c:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0101e32:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e37:	89 f8                	mov    %edi,%eax
f0101e39:	e8 bd ea ff ff       	call   f01008fb <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101e3e:	89 f2                	mov    %esi,%edx
f0101e40:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101e46:	c1 fa 03             	sar    $0x3,%edx
f0101e49:	c1 e2 0c             	shl    $0xc,%edx
f0101e4c:	39 d0                	cmp    %edx,%eax
f0101e4e:	74 24                	je     f0101e74 <mem_init+0xc2b>
f0101e50:	c7 44 24 0c a0 47 10 	movl   $0xf01047a0,0xc(%esp)
f0101e57:	f0 
f0101e58:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101e5f:	f0 
f0101e60:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101e67:	00 
f0101e68:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101e6f:	e8 20 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e74:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e79:	74 24                	je     f0101e9f <mem_init+0xc56>
f0101e7b:	c7 44 24 0c 20 4e 10 	movl   $0xf0104e20,0xc(%esp)
f0101e82:	f0 
f0101e83:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101e8a:	f0 
f0101e8b:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101e92:	00 
f0101e93:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101e9a:	e8 f5 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e9f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ea6:	00 
f0101ea7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101eae:	00 
f0101eaf:	89 3c 24             	mov    %edi,(%esp)
f0101eb2:	e8 b0 f0 ff ff       	call   f0100f67 <pgdir_walk>
f0101eb7:	f6 00 04             	testb  $0x4,(%eax)
f0101eba:	75 24                	jne    f0101ee0 <mem_init+0xc97>
f0101ebc:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0101ec3:	f0 
f0101ec4:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101ecb:	f0 
f0101ecc:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101ed3:	00 
f0101ed4:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101edb:	e8 b4 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ee0:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101ee5:	f6 00 04             	testb  $0x4,(%eax)
f0101ee8:	75 24                	jne    f0101f0e <mem_init+0xcc5>
f0101eea:	c7 44 24 0c 31 4e 10 	movl   $0xf0104e31,0xc(%esp)
f0101ef1:	f0 
f0101ef2:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101ef9:	f0 
f0101efa:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101f01:	00 
f0101f02:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101f09:	e8 86 e1 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f0e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f15:	00 
f0101f16:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f1d:	00 
f0101f1e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f22:	89 04 24             	mov    %eax,(%esp)
f0101f25:	e8 8a f2 ff ff       	call   f01011b4 <page_insert>
f0101f2a:	85 c0                	test   %eax,%eax
f0101f2c:	74 24                	je     f0101f52 <mem_init+0xd09>
f0101f2e:	c7 44 24 0c 64 47 10 	movl   $0xf0104764,0xc(%esp)
f0101f35:	f0 
f0101f36:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101f3d:	f0 
f0101f3e:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101f45:	00 
f0101f46:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101f4d:	e8 42 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f52:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f59:	00 
f0101f5a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f61:	00 
f0101f62:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f67:	89 04 24             	mov    %eax,(%esp)
f0101f6a:	e8 f8 ef ff ff       	call   f0100f67 <pgdir_walk>
f0101f6f:	f6 00 02             	testb  $0x2,(%eax)
f0101f72:	75 24                	jne    f0101f98 <mem_init+0xd4f>
f0101f74:	c7 44 24 0c 84 48 10 	movl   $0xf0104884,0xc(%esp)
f0101f7b:	f0 
f0101f7c:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101f83:	f0 
f0101f84:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101f8b:	00 
f0101f8c:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101f93:	e8 fc e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f98:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f9f:	00 
f0101fa0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fa7:	00 
f0101fa8:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101fad:	89 04 24             	mov    %eax,(%esp)
f0101fb0:	e8 b2 ef ff ff       	call   f0100f67 <pgdir_walk>
f0101fb5:	f6 00 04             	testb  $0x4,(%eax)
f0101fb8:	74 24                	je     f0101fde <mem_init+0xd95>
f0101fba:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f0101fc1:	f0 
f0101fc2:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0101fc9:	f0 
f0101fca:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0101fd1:	00 
f0101fd2:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0101fd9:	e8 b6 e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101fde:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fe5:	00 
f0101fe6:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101fed:	00 
f0101fee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ff1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ff5:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101ffa:	89 04 24             	mov    %eax,(%esp)
f0101ffd:	e8 b2 f1 ff ff       	call   f01011b4 <page_insert>
f0102002:	85 c0                	test   %eax,%eax
f0102004:	78 24                	js     f010202a <mem_init+0xde1>
f0102006:	c7 44 24 0c f0 48 10 	movl   $0xf01048f0,0xc(%esp)
f010200d:	f0 
f010200e:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102015:	f0 
f0102016:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f010201d:	00 
f010201e:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102025:	e8 6a e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010202a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102031:	00 
f0102032:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102039:	00 
f010203a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010203e:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102043:	89 04 24             	mov    %eax,(%esp)
f0102046:	e8 69 f1 ff ff       	call   f01011b4 <page_insert>
f010204b:	85 c0                	test   %eax,%eax
f010204d:	74 24                	je     f0102073 <mem_init+0xe2a>
f010204f:	c7 44 24 0c 28 49 10 	movl   $0xf0104928,0xc(%esp)
f0102056:	f0 
f0102057:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010205e:	f0 
f010205f:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102066:	00 
f0102067:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010206e:	e8 21 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102073:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010207a:	00 
f010207b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102082:	00 
f0102083:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102088:	89 04 24             	mov    %eax,(%esp)
f010208b:	e8 d7 ee ff ff       	call   f0100f67 <pgdir_walk>
f0102090:	f6 00 04             	testb  $0x4,(%eax)
f0102093:	74 24                	je     f01020b9 <mem_init+0xe70>
f0102095:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f010209c:	f0 
f010209d:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01020a4:	f0 
f01020a5:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f01020ac:	00 
f01020ad:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01020b4:	e8 db df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020b9:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f01020bf:	ba 00 00 00 00       	mov    $0x0,%edx
f01020c4:	89 f8                	mov    %edi,%eax
f01020c6:	e8 30 e8 ff ff       	call   f01008fb <check_va2pa>
f01020cb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020ce:	89 d8                	mov    %ebx,%eax
f01020d0:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01020d6:	c1 f8 03             	sar    $0x3,%eax
f01020d9:	c1 e0 0c             	shl    $0xc,%eax
f01020dc:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020df:	74 24                	je     f0102105 <mem_init+0xebc>
f01020e1:	c7 44 24 0c 64 49 10 	movl   $0xf0104964,0xc(%esp)
f01020e8:	f0 
f01020e9:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01020f0:	f0 
f01020f1:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01020f8:	00 
f01020f9:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102100:	e8 8f df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102105:	ba 00 10 00 00       	mov    $0x1000,%edx
f010210a:	89 f8                	mov    %edi,%eax
f010210c:	e8 ea e7 ff ff       	call   f01008fb <check_va2pa>
f0102111:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102114:	74 24                	je     f010213a <mem_init+0xef1>
f0102116:	c7 44 24 0c 90 49 10 	movl   $0xf0104990,0xc(%esp)
f010211d:	f0 
f010211e:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102125:	f0 
f0102126:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f010212d:	00 
f010212e:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102135:	e8 5a df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010213a:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010213f:	74 24                	je     f0102165 <mem_init+0xf1c>
f0102141:	c7 44 24 0c 47 4e 10 	movl   $0xf0104e47,0xc(%esp)
f0102148:	f0 
f0102149:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102150:	f0 
f0102151:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102158:	00 
f0102159:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102160:	e8 2f df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102165:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010216a:	74 24                	je     f0102190 <mem_init+0xf47>
f010216c:	c7 44 24 0c 58 4e 10 	movl   $0xf0104e58,0xc(%esp)
f0102173:	f0 
f0102174:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010217b:	f0 
f010217c:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102183:	00 
f0102184:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010218b:	e8 04 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102190:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102197:	e8 e4 ec ff ff       	call   f0100e80 <page_alloc>
f010219c:	85 c0                	test   %eax,%eax
f010219e:	74 04                	je     f01021a4 <mem_init+0xf5b>
f01021a0:	39 c6                	cmp    %eax,%esi
f01021a2:	74 24                	je     f01021c8 <mem_init+0xf7f>
f01021a4:	c7 44 24 0c c0 49 10 	movl   $0xf01049c0,0xc(%esp)
f01021ab:	f0 
f01021ac:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01021b3:	f0 
f01021b4:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f01021bb:	00 
f01021bc:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01021c3:	e8 cc de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01021c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01021cf:	00 
f01021d0:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01021d5:	89 04 24             	mov    %eax,(%esp)
f01021d8:	e8 87 ef ff ff       	call   f0101164 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021dd:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f01021e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01021e8:	89 f8                	mov    %edi,%eax
f01021ea:	e8 0c e7 ff ff       	call   f01008fb <check_va2pa>
f01021ef:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021f2:	74 24                	je     f0102218 <mem_init+0xfcf>
f01021f4:	c7 44 24 0c e4 49 10 	movl   $0xf01049e4,0xc(%esp)
f01021fb:	f0 
f01021fc:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102203:	f0 
f0102204:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f010220b:	00 
f010220c:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102213:	e8 7c de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102218:	ba 00 10 00 00       	mov    $0x1000,%edx
f010221d:	89 f8                	mov    %edi,%eax
f010221f:	e8 d7 e6 ff ff       	call   f01008fb <check_va2pa>
f0102224:	89 da                	mov    %ebx,%edx
f0102226:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f010222c:	c1 fa 03             	sar    $0x3,%edx
f010222f:	c1 e2 0c             	shl    $0xc,%edx
f0102232:	39 d0                	cmp    %edx,%eax
f0102234:	74 24                	je     f010225a <mem_init+0x1011>
f0102236:	c7 44 24 0c 90 49 10 	movl   $0xf0104990,0xc(%esp)
f010223d:	f0 
f010223e:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102245:	f0 
f0102246:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f010224d:	00 
f010224e:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102255:	e8 3a de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010225a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010225f:	74 24                	je     f0102285 <mem_init+0x103c>
f0102261:	c7 44 24 0c fe 4d 10 	movl   $0xf0104dfe,0xc(%esp)
f0102268:	f0 
f0102269:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102270:	f0 
f0102271:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0102278:	00 
f0102279:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102280:	e8 0f de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102285:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010228a:	74 24                	je     f01022b0 <mem_init+0x1067>
f010228c:	c7 44 24 0c 58 4e 10 	movl   $0xf0104e58,0xc(%esp)
f0102293:	f0 
f0102294:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010229b:	f0 
f010229c:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01022a3:	00 
f01022a4:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01022ab:	e8 e4 dd ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01022b0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01022b7:	00 
f01022b8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022bf:	00 
f01022c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022c4:	89 3c 24             	mov    %edi,(%esp)
f01022c7:	e8 e8 ee ff ff       	call   f01011b4 <page_insert>
f01022cc:	85 c0                	test   %eax,%eax
f01022ce:	74 24                	je     f01022f4 <mem_init+0x10ab>
f01022d0:	c7 44 24 0c 08 4a 10 	movl   $0xf0104a08,0xc(%esp)
f01022d7:	f0 
f01022d8:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01022df:	f0 
f01022e0:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01022e7:	00 
f01022e8:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01022ef:	e8 a0 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f01022f4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01022f9:	75 24                	jne    f010231f <mem_init+0x10d6>
f01022fb:	c7 44 24 0c 69 4e 10 	movl   $0xf0104e69,0xc(%esp)
f0102302:	f0 
f0102303:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010230a:	f0 
f010230b:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0102312:	00 
f0102313:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010231a:	e8 75 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010231f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102322:	74 24                	je     f0102348 <mem_init+0x10ff>
f0102324:	c7 44 24 0c 75 4e 10 	movl   $0xf0104e75,0xc(%esp)
f010232b:	f0 
f010232c:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102333:	f0 
f0102334:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f010233b:	00 
f010233c:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102343:	e8 4c dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102348:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010234f:	00 
f0102350:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102355:	89 04 24             	mov    %eax,(%esp)
f0102358:	e8 07 ee ff ff       	call   f0101164 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010235d:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0102363:	ba 00 00 00 00       	mov    $0x0,%edx
f0102368:	89 f8                	mov    %edi,%eax
f010236a:	e8 8c e5 ff ff       	call   f01008fb <check_va2pa>
f010236f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102372:	74 24                	je     f0102398 <mem_init+0x114f>
f0102374:	c7 44 24 0c e4 49 10 	movl   $0xf01049e4,0xc(%esp)
f010237b:	f0 
f010237c:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102383:	f0 
f0102384:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f010238b:	00 
f010238c:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102393:	e8 fc dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102398:	ba 00 10 00 00       	mov    $0x1000,%edx
f010239d:	89 f8                	mov    %edi,%eax
f010239f:	e8 57 e5 ff ff       	call   f01008fb <check_va2pa>
f01023a4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023a7:	74 24                	je     f01023cd <mem_init+0x1184>
f01023a9:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f01023b0:	f0 
f01023b1:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01023b8:	f0 
f01023b9:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f01023c0:	00 
f01023c1:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01023c8:	e8 c7 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01023cd:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01023d2:	74 24                	je     f01023f8 <mem_init+0x11af>
f01023d4:	c7 44 24 0c 8a 4e 10 	movl   $0xf0104e8a,0xc(%esp)
f01023db:	f0 
f01023dc:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01023e3:	f0 
f01023e4:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01023eb:	00 
f01023ec:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01023f3:	e8 9c dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01023f8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023fd:	74 24                	je     f0102423 <mem_init+0x11da>
f01023ff:	c7 44 24 0c 58 4e 10 	movl   $0xf0104e58,0xc(%esp)
f0102406:	f0 
f0102407:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010240e:	f0 
f010240f:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102416:	00 
f0102417:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010241e:	e8 71 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102423:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010242a:	e8 51 ea ff ff       	call   f0100e80 <page_alloc>
f010242f:	85 c0                	test   %eax,%eax
f0102431:	74 04                	je     f0102437 <mem_init+0x11ee>
f0102433:	39 c3                	cmp    %eax,%ebx
f0102435:	74 24                	je     f010245b <mem_init+0x1212>
f0102437:	c7 44 24 0c 68 4a 10 	movl   $0xf0104a68,0xc(%esp)
f010243e:	f0 
f010243f:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102446:	f0 
f0102447:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f010244e:	00 
f010244f:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102456:	e8 39 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010245b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102462:	e8 19 ea ff ff       	call   f0100e80 <page_alloc>
f0102467:	85 c0                	test   %eax,%eax
f0102469:	74 24                	je     f010248f <mem_init+0x1246>
f010246b:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0102472:	f0 
f0102473:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010247a:	f0 
f010247b:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0102482:	00 
f0102483:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010248a:	e8 05 dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010248f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102494:	8b 08                	mov    (%eax),%ecx
f0102496:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010249c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010249f:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01024a5:	c1 fa 03             	sar    $0x3,%edx
f01024a8:	c1 e2 0c             	shl    $0xc,%edx
f01024ab:	39 d1                	cmp    %edx,%ecx
f01024ad:	74 24                	je     f01024d3 <mem_init+0x128a>
f01024af:	c7 44 24 0c 0c 47 10 	movl   $0xf010470c,0xc(%esp)
f01024b6:	f0 
f01024b7:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01024be:	f0 
f01024bf:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f01024c6:	00 
f01024c7:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01024ce:	e8 c1 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01024d3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024dc:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01024e1:	74 24                	je     f0102507 <mem_init+0x12be>
f01024e3:	c7 44 24 0c 0f 4e 10 	movl   $0xf0104e0f,0xc(%esp)
f01024ea:	f0 
f01024eb:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01024f2:	f0 
f01024f3:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f01024fa:	00 
f01024fb:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102502:	e8 8d db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102507:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010250a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102510:	89 04 24             	mov    %eax,(%esp)
f0102513:	e8 ec e9 ff ff       	call   f0100f04 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102518:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010251f:	00 
f0102520:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102527:	00 
f0102528:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010252d:	89 04 24             	mov    %eax,(%esp)
f0102530:	e8 32 ea ff ff       	call   f0100f67 <pgdir_walk>
f0102535:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102538:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f010253e:	8b 4a 04             	mov    0x4(%edx),%ecx
f0102541:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102547:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	if (PGNUM(pa) >= npages)
f010254a:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f0102550:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102553:	c1 ef 0c             	shr    $0xc,%edi
f0102556:	39 cf                	cmp    %ecx,%edi
f0102558:	72 23                	jb     f010257d <mem_init+0x1334>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010255a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010255d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102561:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0102568:	f0 
f0102569:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102570:	00 
f0102571:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102578:	e8 17 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010257d:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102580:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102586:	39 f8                	cmp    %edi,%eax
f0102588:	74 24                	je     f01025ae <mem_init+0x1365>
f010258a:	c7 44 24 0c 9b 4e 10 	movl   $0xf0104e9b,0xc(%esp)
f0102591:	f0 
f0102592:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102599:	f0 
f010259a:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f01025a1:	00 
f01025a2:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01025a9:	e8 e6 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01025ae:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01025b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025b8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01025be:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01025c4:	c1 f8 03             	sar    $0x3,%eax
f01025c7:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01025ca:	89 c2                	mov    %eax,%edx
f01025cc:	c1 ea 0c             	shr    $0xc,%edx
f01025cf:	39 d1                	cmp    %edx,%ecx
f01025d1:	77 20                	ja     f01025f3 <mem_init+0x13aa>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025d7:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f01025de:	f0 
f01025df:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025e6:	00 
f01025e7:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f01025ee:	e8 a1 da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025f3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025fa:	00 
f01025fb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102602:	00 
	return (void *)(pa + KERNBASE);
f0102603:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102608:	89 04 24             	mov    %eax,(%esp)
f010260b:	e8 13 14 00 00       	call   f0103a23 <memset>
	page_free(pp0);
f0102610:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102613:	89 04 24             	mov    %eax,(%esp)
f0102616:	e8 e9 e8 ff ff       	call   f0100f04 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010261b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102622:	00 
f0102623:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010262a:	00 
f010262b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102630:	89 04 24             	mov    %eax,(%esp)
f0102633:	e8 2f e9 ff ff       	call   f0100f67 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102638:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010263b:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102641:	c1 fa 03             	sar    $0x3,%edx
f0102644:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102647:	89 d0                	mov    %edx,%eax
f0102649:	c1 e8 0c             	shr    $0xc,%eax
f010264c:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0102652:	72 20                	jb     f0102674 <mem_init+0x142b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102654:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102658:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f010265f:	f0 
f0102660:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102667:	00 
f0102668:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f010266f:	e8 20 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102674:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010267a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mem_init(void)
f010267d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102683:	f6 00 01             	testb  $0x1,(%eax)
f0102686:	74 24                	je     f01026ac <mem_init+0x1463>
f0102688:	c7 44 24 0c b3 4e 10 	movl   $0xf0104eb3,0xc(%esp)
f010268f:	f0 
f0102690:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102697:	f0 
f0102698:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f010269f:	00 
f01026a0:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01026a7:	e8 e8 d9 ff ff       	call   f0100094 <_panic>
f01026ac:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01026af:	39 d0                	cmp    %edx,%eax
f01026b1:	75 d0                	jne    f0102683 <mem_init+0x143a>
	kern_pgdir[0] = 0;
f01026b3:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01026b8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01026be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026c1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01026c7:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01026ca:	89 3d 40 85 11 f0    	mov    %edi,0xf0118540

	// free the pages we took
	page_free(pp0);
f01026d0:	89 04 24             	mov    %eax,(%esp)
f01026d3:	e8 2c e8 ff ff       	call   f0100f04 <page_free>
	page_free(pp1);
f01026d8:	89 1c 24             	mov    %ebx,(%esp)
f01026db:	e8 24 e8 ff ff       	call   f0100f04 <page_free>
	page_free(pp2);
f01026e0:	89 34 24             	mov    %esi,(%esp)
f01026e3:	e8 1c e8 ff ff       	call   f0100f04 <page_free>

	cprintf("check_page() succeeded!\n");
f01026e8:	c7 04 24 ca 4e 10 f0 	movl   $0xf0104eca,(%esp)
f01026ef:	e8 b4 07 00 00       	call   f0102ea8 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR((uintptr_t *) pages), PTE_U);
f01026f4:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
	if ((uint32_t)kva < KERNBASE)
f01026f9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026fe:	77 20                	ja     f0102720 <mem_init+0x14d7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102700:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102704:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f010270b:	f0 
f010270c:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
f0102713:	00 
f0102714:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010271b:	e8 74 d9 ff ff       	call   f0100094 <_panic>
f0102720:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102727:	00 
	return (physaddr_t)kva - KERNBASE;
f0102728:	05 00 00 00 10       	add    $0x10000000,%eax
f010272d:	89 04 24             	mov    %eax,(%esp)
f0102730:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102735:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010273a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010273f:	e8 2e e9 ff ff       	call   f0101072 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102744:	b8 00 e0 10 f0       	mov    $0xf010e000,%eax
f0102749:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010274e:	77 20                	ja     f0102770 <mem_init+0x1527>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102750:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102754:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f010275b:	f0 
f010275c:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f0102763:	00 
f0102764:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010276b:	e8 24 d9 ff ff       	call   f0100094 <_panic>
	boot_map_region(kern_pgdir , KSTACKTOP-KSTKSIZE , KSTKSIZE ,PADDR((uintptr_t*) bootstack) , PTE_W);
f0102770:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102777:	00 
f0102778:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f010277f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102784:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102789:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010278e:	e8 df e8 ff ff       	call   f0101072 <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff -KERNBASE,(physaddr_t)0,PTE_W);
f0102793:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010279a:	00 
f010279b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027a2:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01027a7:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027ac:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01027b1:	e8 bc e8 ff ff       	call   f0101072 <boot_map_region>
	pgdir = kern_pgdir;
f01027b6:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027bc:	8b 35 64 89 11 f0    	mov    0xf0118964,%esi
f01027c2:	89 75 c8             	mov    %esi,-0x38(%ebp)
f01027c5:	8d 04 f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%eax
f01027cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027d4:	8b 3d 6c 89 11 f0    	mov    0xf011896c,%edi
f01027da:	89 7d cc             	mov    %edi,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01027dd:	89 7d d0             	mov    %edi,-0x30(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01027e0:	81 c7 00 00 00 10    	add    $0x10000000,%edi
	for (i = 0; i < n; i += PGSIZE)
f01027e6:	be 00 00 00 00       	mov    $0x0,%esi
f01027eb:	eb 6a                	jmp    f0102857 <mem_init+0x160e>
mem_init(void)
f01027ed:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027f3:	89 d8                	mov    %ebx,%eax
f01027f5:	e8 01 e1 ff ff       	call   f01008fb <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01027fa:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102801:	77 23                	ja     f0102826 <mem_init+0x15dd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102803:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102806:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010280a:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f0102811:	f0 
f0102812:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0102819:	00 
f010281a:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102821:	e8 6e d8 ff ff       	call   f0100094 <_panic>
mem_init(void)
f0102826:	8d 14 3e             	lea    (%esi,%edi,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102829:	39 c2                	cmp    %eax,%edx
f010282b:	74 24                	je     f0102851 <mem_init+0x1608>
f010282d:	c7 44 24 0c 8c 4a 10 	movl   $0xf0104a8c,0xc(%esp)
f0102834:	f0 
f0102835:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010283c:	f0 
f010283d:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0102844:	00 
f0102845:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010284c:	e8 43 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102851:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102857:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010285a:	77 91                	ja     f01027ed <mem_init+0x15a4>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010285c:	8b 7d c8             	mov    -0x38(%ebp),%edi
f010285f:	c1 e7 0c             	shl    $0xc,%edi
f0102862:	be 00 00 00 00       	mov    $0x0,%esi
f0102867:	eb 3b                	jmp    f01028a4 <mem_init+0x165b>
mem_init(void)
f0102869:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010286f:	89 d8                	mov    %ebx,%eax
f0102871:	e8 85 e0 ff ff       	call   f01008fb <check_va2pa>
f0102876:	39 c6                	cmp    %eax,%esi
f0102878:	74 24                	je     f010289e <mem_init+0x1655>
f010287a:	c7 44 24 0c c0 4a 10 	movl   $0xf0104ac0,0xc(%esp)
f0102881:	f0 
f0102882:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102889:	f0 
f010288a:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0102891:	00 
f0102892:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102899:	e8 f6 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010289e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028a4:	39 fe                	cmp    %edi,%esi
f01028a6:	72 c1                	jb     f0102869 <mem_init+0x1620>
f01028a8:	be 00 80 ff ef       	mov    $0xefff8000,%esi
mem_init(void)
f01028ad:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
f01028b2:	81 c7 00 80 00 20    	add    $0x20008000,%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028b8:	89 f2                	mov    %esi,%edx
f01028ba:	89 d8                	mov    %ebx,%eax
f01028bc:	e8 3a e0 ff ff       	call   f01008fb <check_va2pa>
mem_init(void)
f01028c1:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028c4:	39 d0                	cmp    %edx,%eax
f01028c6:	74 24                	je     f01028ec <mem_init+0x16a3>
f01028c8:	c7 44 24 0c e8 4a 10 	movl   $0xf0104ae8,0xc(%esp)
f01028cf:	f0 
f01028d0:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01028d7:	f0 
f01028d8:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f01028df:	00 
f01028e0:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01028e7:	e8 a8 d7 ff ff       	call   f0100094 <_panic>
f01028ec:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028f2:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01028f8:	75 be                	jne    f01028b8 <mem_init+0x166f>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028fa:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01028ff:	89 d8                	mov    %ebx,%eax
f0102901:	e8 f5 df ff ff       	call   f01008fb <check_va2pa>
f0102906:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102909:	0f 84 f3 00 00 00    	je     f0102a02 <mem_init+0x17b9>
f010290f:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f0102916:	f0 
f0102917:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f010291e:	f0 
f010291f:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0102926:	00 
f0102927:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010292e:	e8 61 d7 ff ff       	call   f0100094 <_panic>
		switch (i) {
f0102933:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0102939:	83 f9 03             	cmp    $0x3,%ecx
f010293c:	77 39                	ja     f0102977 <mem_init+0x172e>
f010293e:	89 d7                	mov    %edx,%edi
f0102940:	d3 e7                	shl    %cl,%edi
f0102942:	89 f9                	mov    %edi,%ecx
f0102944:	f6 c1 0b             	test   $0xb,%cl
f0102947:	74 2e                	je     f0102977 <mem_init+0x172e>
			assert(pgdir[i] & PTE_P);
f0102949:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010294d:	0f 85 aa 00 00 00    	jne    f01029fd <mem_init+0x17b4>
f0102953:	c7 44 24 0c e3 4e 10 	movl   $0xf0104ee3,0xc(%esp)
f010295a:	f0 
f010295b:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102962:	f0 
f0102963:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f010296a:	00 
f010296b:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102972:	e8 1d d7 ff ff       	call   f0100094 <_panic>
			if (i >= PDX(KERNBASE)) {
f0102977:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010297c:	76 55                	jbe    f01029d3 <mem_init+0x178a>
				assert(pgdir[i] & PTE_P);
f010297e:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0102981:	f6 c1 01             	test   $0x1,%cl
f0102984:	75 24                	jne    f01029aa <mem_init+0x1761>
f0102986:	c7 44 24 0c e3 4e 10 	movl   $0xf0104ee3,0xc(%esp)
f010298d:	f0 
f010298e:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102995:	f0 
f0102996:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f010299d:	00 
f010299e:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01029a5:	e8 ea d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01029aa:	f6 c1 02             	test   $0x2,%cl
f01029ad:	75 4e                	jne    f01029fd <mem_init+0x17b4>
f01029af:	c7 44 24 0c f4 4e 10 	movl   $0xf0104ef4,0xc(%esp)
f01029b6:	f0 
f01029b7:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01029be:	f0 
f01029bf:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01029c6:	00 
f01029c7:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01029ce:	e8 c1 d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] == 0);
f01029d3:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01029d7:	74 24                	je     f01029fd <mem_init+0x17b4>
f01029d9:	c7 44 24 0c 05 4f 10 	movl   $0xf0104f05,0xc(%esp)
f01029e0:	f0 
f01029e1:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f01029e8:	f0 
f01029e9:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f01029f0:	00 
f01029f1:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01029f8:	e8 97 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f01029fd:	83 c0 01             	add    $0x1,%eax
f0102a00:	eb 0a                	jmp    f0102a0c <mem_init+0x17c3>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a02:	b8 00 00 00 00       	mov    $0x0,%eax
		switch (i) {
f0102a07:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 0; i < NPDENTRIES; i++) {
f0102a0c:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a11:	0f 85 1c ff ff ff    	jne    f0102933 <mem_init+0x16ea>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a17:	c7 04 24 60 4b 10 f0 	movl   $0xf0104b60,(%esp)
f0102a1e:	e8 85 04 00 00       	call   f0102ea8 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102a23:	a1 68 89 11 f0       	mov    0xf0118968,%eax
	if ((uint32_t)kva < KERNBASE)
f0102a28:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a2d:	77 20                	ja     f0102a4f <mem_init+0x1806>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a33:	c7 44 24 08 a8 44 10 	movl   $0xf01044a8,0x8(%esp)
f0102a3a:	f0 
f0102a3b:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102a42:	00 
f0102a43:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102a4a:	e8 45 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a4f:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a54:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102a57:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5c:	e8 da df ff ff       	call   f0100a3b <check_page_free_list>
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a61:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a64:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a67:	0d 23 00 05 80       	or     $0x80050023,%eax
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a6c:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a76:	e8 05 e4 ff ff       	call   f0100e80 <page_alloc>
f0102a7b:	89 c3                	mov    %eax,%ebx
f0102a7d:	85 c0                	test   %eax,%eax
f0102a7f:	75 24                	jne    f0102aa5 <mem_init+0x185c>
f0102a81:	c7 44 24 0c 01 4d 10 	movl   $0xf0104d01,0xc(%esp)
f0102a88:	f0 
f0102a89:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102a90:	f0 
f0102a91:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102a98:	00 
f0102a99:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102aa0:	e8 ef d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102aa5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aac:	e8 cf e3 ff ff       	call   f0100e80 <page_alloc>
f0102ab1:	89 c7                	mov    %eax,%edi
f0102ab3:	85 c0                	test   %eax,%eax
f0102ab5:	75 24                	jne    f0102adb <mem_init+0x1892>
f0102ab7:	c7 44 24 0c 17 4d 10 	movl   $0xf0104d17,0xc(%esp)
f0102abe:	f0 
f0102abf:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102ac6:	f0 
f0102ac7:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102ace:	00 
f0102acf:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102ad6:	e8 b9 d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102adb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ae2:	e8 99 e3 ff ff       	call   f0100e80 <page_alloc>
f0102ae7:	89 c6                	mov    %eax,%esi
f0102ae9:	85 c0                	test   %eax,%eax
f0102aeb:	75 24                	jne    f0102b11 <mem_init+0x18c8>
f0102aed:	c7 44 24 0c 2d 4d 10 	movl   $0xf0104d2d,0xc(%esp)
f0102af4:	f0 
f0102af5:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102afc:	f0 
f0102afd:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102b04:	00 
f0102b05:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102b0c:	e8 83 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102b11:	89 1c 24             	mov    %ebx,(%esp)
f0102b14:	e8 eb e3 ff ff       	call   f0100f04 <page_free>
	return (pp - pages) << PGSHIFT;
f0102b19:	89 f8                	mov    %edi,%eax
f0102b1b:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102b21:	c1 f8 03             	sar    $0x3,%eax
f0102b24:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b27:	89 c2                	mov    %eax,%edx
f0102b29:	c1 ea 0c             	shr    $0xc,%edx
f0102b2c:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102b32:	72 20                	jb     f0102b54 <mem_init+0x190b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b34:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b38:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0102b3f:	f0 
f0102b40:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b47:	00 
f0102b48:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0102b4f:	e8 40 d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b5b:	00 
f0102b5c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b63:	00 
	return (void *)(pa + KERNBASE);
f0102b64:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b69:	89 04 24             	mov    %eax,(%esp)
f0102b6c:	e8 b2 0e 00 00       	call   f0103a23 <memset>
	return (pp - pages) << PGSHIFT;
f0102b71:	89 f0                	mov    %esi,%eax
f0102b73:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102b79:	c1 f8 03             	sar    $0x3,%eax
f0102b7c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b7f:	89 c2                	mov    %eax,%edx
f0102b81:	c1 ea 0c             	shr    $0xc,%edx
f0102b84:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102b8a:	72 20                	jb     f0102bac <mem_init+0x1963>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b8c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b90:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0102b97:	f0 
f0102b98:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b9f:	00 
f0102ba0:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0102ba7:	e8 e8 d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bac:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bb3:	00 
f0102bb4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102bbb:	00 
	return (void *)(pa + KERNBASE);
f0102bbc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bc1:	89 04 24             	mov    %eax,(%esp)
f0102bc4:	e8 5a 0e 00 00       	call   f0103a23 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bc9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bd0:	00 
f0102bd1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bd8:	00 
f0102bd9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102bdd:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102be2:	89 04 24             	mov    %eax,(%esp)
f0102be5:	e8 ca e5 ff ff       	call   f01011b4 <page_insert>
	assert(pp1->pp_ref == 1);
f0102bea:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102bef:	74 24                	je     f0102c15 <mem_init+0x19cc>
f0102bf1:	c7 44 24 0c fe 4d 10 	movl   $0xf0104dfe,0xc(%esp)
f0102bf8:	f0 
f0102bf9:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102c00:	f0 
f0102c01:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102c08:	00 
f0102c09:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102c10:	e8 7f d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c15:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c1c:	01 01 01 
f0102c1f:	74 24                	je     f0102c45 <mem_init+0x19fc>
f0102c21:	c7 44 24 0c 80 4b 10 	movl   $0xf0104b80,0xc(%esp)
f0102c28:	f0 
f0102c29:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102c30:	f0 
f0102c31:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0102c38:	00 
f0102c39:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102c40:	e8 4f d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c45:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c4c:	00 
f0102c4d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c54:	00 
f0102c55:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c59:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102c5e:	89 04 24             	mov    %eax,(%esp)
f0102c61:	e8 4e e5 ff ff       	call   f01011b4 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c66:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c6d:	02 02 02 
f0102c70:	74 24                	je     f0102c96 <mem_init+0x1a4d>
f0102c72:	c7 44 24 0c a4 4b 10 	movl   $0xf0104ba4,0xc(%esp)
f0102c79:	f0 
f0102c7a:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102c81:	f0 
f0102c82:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102c89:	00 
f0102c8a:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102c91:	e8 fe d3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102c96:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c9b:	74 24                	je     f0102cc1 <mem_init+0x1a78>
f0102c9d:	c7 44 24 0c 20 4e 10 	movl   $0xf0104e20,0xc(%esp)
f0102ca4:	f0 
f0102ca5:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102cac:	f0 
f0102cad:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102cb4:	00 
f0102cb5:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102cbc:	e8 d3 d3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102cc1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cc6:	74 24                	je     f0102cec <mem_init+0x1aa3>
f0102cc8:	c7 44 24 0c 8a 4e 10 	movl   $0xf0104e8a,0xc(%esp)
f0102ccf:	f0 
f0102cd0:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102cd7:	f0 
f0102cd8:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102cdf:	00 
f0102ce0:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102ce7:	e8 a8 d3 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102cec:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102cf3:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102cf6:	89 f0                	mov    %esi,%eax
f0102cf8:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102cfe:	c1 f8 03             	sar    $0x3,%eax
f0102d01:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d04:	89 c2                	mov    %eax,%edx
f0102d06:	c1 ea 0c             	shr    $0xc,%edx
f0102d09:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102d0f:	72 20                	jb     f0102d31 <mem_init+0x1ae8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d11:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d15:	c7 44 24 08 84 44 10 	movl   $0xf0104484,0x8(%esp)
f0102d1c:	f0 
f0102d1d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d24:	00 
f0102d25:	c7 04 24 3c 4c 10 f0 	movl   $0xf0104c3c,(%esp)
f0102d2c:	e8 63 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d31:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d38:	03 03 03 
f0102d3b:	74 24                	je     f0102d61 <mem_init+0x1b18>
f0102d3d:	c7 44 24 0c c8 4b 10 	movl   $0xf0104bc8,0xc(%esp)
f0102d44:	f0 
f0102d45:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102d4c:	f0 
f0102d4d:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102d54:	00 
f0102d55:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102d5c:	e8 33 d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d61:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d68:	00 
f0102d69:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102d6e:	89 04 24             	mov    %eax,(%esp)
f0102d71:	e8 ee e3 ff ff       	call   f0101164 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d76:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d7b:	74 24                	je     f0102da1 <mem_init+0x1b58>
f0102d7d:	c7 44 24 0c 58 4e 10 	movl   $0xf0104e58,0xc(%esp)
f0102d84:	f0 
f0102d85:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102d8c:	f0 
f0102d8d:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0102d94:	00 
f0102d95:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102d9c:	e8 f3 d2 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102da1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102da6:	8b 08                	mov    (%eax),%ecx
f0102da8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0102dae:	89 da                	mov    %ebx,%edx
f0102db0:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102db6:	c1 fa 03             	sar    $0x3,%edx
f0102db9:	c1 e2 0c             	shl    $0xc,%edx
f0102dbc:	39 d1                	cmp    %edx,%ecx
f0102dbe:	74 24                	je     f0102de4 <mem_init+0x1b9b>
f0102dc0:	c7 44 24 0c 0c 47 10 	movl   $0xf010470c,0xc(%esp)
f0102dc7:	f0 
f0102dc8:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102dcf:	f0 
f0102dd0:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102dd7:	00 
f0102dd8:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102ddf:	e8 b0 d2 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102de4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102dea:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102def:	74 24                	je     f0102e15 <mem_init+0x1bcc>
f0102df1:	c7 44 24 0c 0f 4e 10 	movl   $0xf0104e0f,0xc(%esp)
f0102df8:	f0 
f0102df9:	c7 44 24 08 56 4c 10 	movl   $0xf0104c56,0x8(%esp)
f0102e00:	f0 
f0102e01:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102e08:	00 
f0102e09:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102e10:	e8 7f d2 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102e15:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e1b:	89 1c 24             	mov    %ebx,(%esp)
f0102e1e:	e8 e1 e0 ff ff       	call   f0100f04 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e23:	c7 04 24 f4 4b 10 f0 	movl   $0xf0104bf4,(%esp)
f0102e2a:	e8 79 00 00 00       	call   f0102ea8 <cprintf>
}
f0102e2f:	83 c4 3c             	add    $0x3c,%esp
f0102e32:	5b                   	pop    %ebx
f0102e33:	5e                   	pop    %esi
f0102e34:	5f                   	pop    %edi
f0102e35:	5d                   	pop    %ebp
f0102e36:	c3                   	ret    

f0102e37 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e37:	55                   	push   %ebp
f0102e38:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e3a:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e3e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e43:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e44:	b2 71                	mov    $0x71,%dl
f0102e46:	ec                   	in     (%dx),%al
	return inb(IO_RTC+1);
f0102e47:	0f b6 c0             	movzbl %al,%eax
}
f0102e4a:	5d                   	pop    %ebp
f0102e4b:	c3                   	ret    

f0102e4c <mc146818_write>:
{
f0102e4c:	55                   	push   %ebp
f0102e4d:	89 e5                	mov    %esp,%ebp
}
f0102e4f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e53:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e58:	ee                   	out    %al,(%dx)
f0102e59:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0102e5d:	b2 71                	mov    $0x71,%dl
f0102e5f:	ee                   	out    %al,(%dx)
f0102e60:	5d                   	pop    %ebp
f0102e61:	c3                   	ret    

f0102e62 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e62:	55                   	push   %ebp
f0102e63:	89 e5                	mov    %esp,%ebp
f0102e65:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102e68:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e6b:	89 04 24             	mov    %eax,(%esp)
f0102e6e:	e8 7c d7 ff ff       	call   f01005ef <cputchar>
	*cnt++;
}
f0102e73:	c9                   	leave  
f0102e74:	c3                   	ret    

f0102e75 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e75:	55                   	push   %ebp
f0102e76:	89 e5                	mov    %esp,%ebp
f0102e78:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102e7b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e85:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e89:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e8c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102e90:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e93:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e97:	c7 04 24 62 2e 10 f0 	movl   $0xf0102e62,(%esp)
f0102e9e:	e8 b2 04 00 00       	call   f0103355 <vprintfmt>
	return cnt;
}
f0102ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ea6:	c9                   	leave  
f0102ea7:	c3                   	ret    

f0102ea8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ea8:	55                   	push   %ebp
f0102ea9:	89 e5                	mov    %esp,%ebp
f0102eab:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102eae:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102eb1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102eb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0102eb8:	89 04 24             	mov    %eax,(%esp)
f0102ebb:	e8 b5 ff ff ff       	call   f0102e75 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102ec0:	c9                   	leave  
f0102ec1:	c3                   	ret    

f0102ec2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102ec2:	55                   	push   %ebp
f0102ec3:	89 e5                	mov    %esp,%ebp
f0102ec5:	57                   	push   %edi
f0102ec6:	56                   	push   %esi
f0102ec7:	53                   	push   %ebx
f0102ec8:	83 ec 10             	sub    $0x10,%esp
f0102ecb:	89 c6                	mov    %eax,%esi
f0102ecd:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102ed0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102ed3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102ed6:	8b 1a                	mov    (%edx),%ebx
f0102ed8:	8b 09                	mov    (%ecx),%ecx
f0102eda:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102edd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102ee4:	eb 77                	jmp    f0102f5d <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102ee6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102ee9:	01 d8                	add    %ebx,%eax
f0102eeb:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102ef0:	99                   	cltd   
f0102ef1:	f7 f9                	idiv   %ecx
f0102ef3:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102ef5:	eb 01                	jmp    f0102ef8 <stab_binsearch+0x36>
			m--;
f0102ef7:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0102ef8:	39 d9                	cmp    %ebx,%ecx
f0102efa:	7c 1d                	jl     f0102f19 <stab_binsearch+0x57>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102efc:	6b d1 0c             	imul   $0xc,%ecx,%edx
		while (m >= l && stabs[m].n_type != type)
f0102eff:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102f04:	39 fa                	cmp    %edi,%edx
f0102f06:	75 ef                	jne    f0102ef7 <stab_binsearch+0x35>
f0102f08:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f0b:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102f0e:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102f12:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f15:	73 18                	jae    f0102f2f <stab_binsearch+0x6d>
f0102f17:	eb 05                	jmp    f0102f1e <stab_binsearch+0x5c>
			l = true_m + 1;
f0102f19:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102f1c:	eb 3f                	jmp    f0102f5d <stab_binsearch+0x9b>
			*region_left = m;
f0102f1e:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f21:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0102f23:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0102f26:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102f2d:	eb 2e                	jmp    f0102f5d <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0102f2f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102f32:	73 15                	jae    f0102f49 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102f34:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f37:	49                   	dec    %ecx
f0102f38:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f3e:	89 08                	mov    %ecx,(%eax)
		any_matches = 1;
f0102f40:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102f47:	eb 14                	jmp    f0102f5d <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102f49:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f4c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f4f:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0102f51:	ff 45 0c             	incl   0xc(%ebp)
f0102f54:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0102f56:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0102f5d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102f60:	7e 84                	jle    f0102ee6 <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0102f62:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102f66:	75 0d                	jne    f0102f75 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102f68:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f6b:	8b 02                	mov    (%edx),%eax
f0102f6d:	48                   	dec    %eax
f0102f6e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f71:	89 01                	mov    %eax,(%ecx)
f0102f73:	eb 22                	jmp    f0102f97 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102f75:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f78:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102f7a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f7d:	8b 0a                	mov    (%edx),%ecx
		for (l = *region_right;
f0102f7f:	eb 01                	jmp    f0102f82 <stab_binsearch+0xc0>
		     l--)
f0102f81:	48                   	dec    %eax
		for (l = *region_right;
f0102f82:	39 c1                	cmp    %eax,%ecx
f0102f84:	7d 0c                	jge    f0102f92 <stab_binsearch+0xd0>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102f86:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102f89:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102f8e:	39 fa                	cmp    %edi,%edx
f0102f90:	75 ef                	jne    f0102f81 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0102f92:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f95:	89 02                	mov    %eax,(%edx)
	}
}
f0102f97:	83 c4 10             	add    $0x10,%esp
f0102f9a:	5b                   	pop    %ebx
f0102f9b:	5e                   	pop    %esi
f0102f9c:	5f                   	pop    %edi
f0102f9d:	5d                   	pop    %ebp
f0102f9e:	c3                   	ret    

f0102f9f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102f9f:	55                   	push   %ebp
f0102fa0:	89 e5                	mov    %esp,%ebp
f0102fa2:	83 ec 58             	sub    $0x58,%esp
f0102fa5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102fa8:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102fab:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102fae:	8b 75 08             	mov    0x8(%ebp),%esi
f0102fb1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102fb4:	c7 03 13 4f 10 f0    	movl   $0xf0104f13,(%ebx)
	info->eip_line = 0;
f0102fba:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102fc1:	c7 43 08 13 4f 10 f0 	movl   $0xf0104f13,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102fc8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102fcf:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102fd2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102fd9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102fdf:	76 12                	jbe    f0102ff3 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102fe1:	b8 6d d1 10 f0       	mov    $0xf010d16d,%eax
f0102fe6:	3d 45 b3 10 f0       	cmp    $0xf010b345,%eax
f0102feb:	0f 86 ca 01 00 00    	jbe    f01031bb <debuginfo_eip+0x21c>
f0102ff1:	eb 1c                	jmp    f010300f <debuginfo_eip+0x70>
  	        panic("User address");
f0102ff3:	c7 44 24 08 1d 4f 10 	movl   $0xf0104f1d,0x8(%esp)
f0102ffa:	f0 
f0102ffb:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103002:	00 
f0103003:	c7 04 24 2a 4f 10 f0 	movl   $0xf0104f2a,(%esp)
f010300a:	e8 85 d0 ff ff       	call   f0100094 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010300f:	80 3d 6c d1 10 f0 00 	cmpb   $0x0,0xf010d16c
f0103016:	0f 85 a6 01 00 00    	jne    f01031c2 <debuginfo_eip+0x223>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010301c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103023:	b8 44 b3 10 f0       	mov    $0xf010b344,%eax
f0103028:	2d 70 51 10 f0       	sub    $0xf0105170,%eax
f010302d:	c1 f8 02             	sar    $0x2,%eax
f0103030:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103036:	83 e8 01             	sub    $0x1,%eax
f0103039:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010303c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103040:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103047:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010304a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010304d:	b8 70 51 10 f0       	mov    $0xf0105170,%eax
f0103052:	e8 6b fe ff ff       	call   f0102ec2 <stab_binsearch>
	if (lfile == 0)
f0103057:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010305a:	85 c0                	test   %eax,%eax
f010305c:	0f 84 67 01 00 00    	je     f01031c9 <debuginfo_eip+0x22a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103062:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103065:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103068:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010306b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010306f:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103076:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103079:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010307c:	b8 70 51 10 f0       	mov    $0xf0105170,%eax
f0103081:	e8 3c fe ff ff       	call   f0102ec2 <stab_binsearch>

	if (lfun <= rfun) {
f0103086:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103089:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010308c:	39 d0                	cmp    %edx,%eax
f010308e:	7f 3d                	jg     f01030cd <debuginfo_eip+0x12e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103090:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103093:	8d b9 70 51 10 f0    	lea    -0xfefae90(%ecx),%edi
f0103099:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010309c:	8b 89 70 51 10 f0    	mov    -0xfefae90(%ecx),%ecx
f01030a2:	bf 6d d1 10 f0       	mov    $0xf010d16d,%edi
f01030a7:	81 ef 45 b3 10 f0    	sub    $0xf010b345,%edi
f01030ad:	39 f9                	cmp    %edi,%ecx
f01030af:	73 09                	jae    f01030ba <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01030b1:	81 c1 45 b3 10 f0    	add    $0xf010b345,%ecx
f01030b7:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01030ba:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01030bd:	8b 4f 08             	mov    0x8(%edi),%ecx
f01030c0:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01030c3:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01030c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01030c8:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01030cb:	eb 0f                	jmp    f01030dc <debuginfo_eip+0x13d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01030cd:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01030d0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01030d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030d9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01030dc:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01030e3:	00 
f01030e4:	8b 43 08             	mov    0x8(%ebx),%eax
f01030e7:	89 04 24             	mov    %eax,(%esp)
f01030ea:	e8 18 09 00 00       	call   f0103a07 <strfind>
f01030ef:	2b 43 08             	sub    0x8(%ebx),%eax
f01030f2:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01030f5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030f9:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103100:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103103:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103106:	b8 70 51 10 f0       	mov    $0xf0105170,%eax
f010310b:	e8 b2 fd ff ff       	call   f0102ec2 <stab_binsearch>

	if (lline <= rline) {
f0103110:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103113:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103116:	0f 8f b4 00 00 00    	jg     f01031d0 <debuginfo_eip+0x231>
		info->eip_line = stabs[lline].n_desc;
f010311c:	6b c0 0c             	imul   $0xc,%eax,%eax
f010311f:	0f b7 80 76 51 10 f0 	movzwl -0xfefae8a(%eax),%eax
f0103126:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103129:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010312c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010312f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103132:	6b d0 0c             	imul   $0xc,%eax,%edx
f0103135:	81 c2 70 51 10 f0    	add    $0xf0105170,%edx
	while (lline >= lfile
f010313b:	eb 06                	jmp    f0103143 <debuginfo_eip+0x1a4>
f010313d:	83 e8 01             	sub    $0x1,%eax
f0103140:	83 ea 0c             	sub    $0xc,%edx
f0103143:	89 c6                	mov    %eax,%esi
f0103145:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0103148:	7f 33                	jg     f010317d <debuginfo_eip+0x1de>
	       && stabs[lline].n_type != N_SOL
f010314a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010314e:	80 f9 84             	cmp    $0x84,%cl
f0103151:	74 0b                	je     f010315e <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103153:	80 f9 64             	cmp    $0x64,%cl
f0103156:	75 e5                	jne    f010313d <debuginfo_eip+0x19e>
f0103158:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010315c:	74 df                	je     f010313d <debuginfo_eip+0x19e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010315e:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103161:	8b 86 70 51 10 f0    	mov    -0xfefae90(%esi),%eax
f0103167:	ba 6d d1 10 f0       	mov    $0xf010d16d,%edx
f010316c:	81 ea 45 b3 10 f0    	sub    $0xf010b345,%edx
f0103172:	39 d0                	cmp    %edx,%eax
f0103174:	73 07                	jae    f010317d <debuginfo_eip+0x1de>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103176:	05 45 b3 10 f0       	add    $0xf010b345,%eax
f010317b:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010317d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103180:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103183:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103188:	39 ca                	cmp    %ecx,%edx
f010318a:	7d 50                	jge    f01031dc <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
f010318c:	8d 42 01             	lea    0x1(%edx),%eax
f010318f:	89 c2                	mov    %eax,%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103191:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103194:	05 70 51 10 f0       	add    $0xf0105170,%eax
f0103199:	89 ce                	mov    %ecx,%esi
		for (lline = lfun + 1;
f010319b:	eb 04                	jmp    f01031a1 <debuginfo_eip+0x202>
			info->eip_fn_narg++;
f010319d:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f01031a1:	39 d6                	cmp    %edx,%esi
f01031a3:	7e 32                	jle    f01031d7 <debuginfo_eip+0x238>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01031a5:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01031a9:	83 c2 01             	add    $0x1,%edx
f01031ac:	83 c0 0c             	add    $0xc,%eax
f01031af:	80 f9 a0             	cmp    $0xa0,%cl
f01031b2:	74 e9                	je     f010319d <debuginfo_eip+0x1fe>
	return 0;
f01031b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01031b9:	eb 21                	jmp    f01031dc <debuginfo_eip+0x23d>
		return -1;
f01031bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01031c0:	eb 1a                	jmp    f01031dc <debuginfo_eip+0x23d>
f01031c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01031c7:	eb 13                	jmp    f01031dc <debuginfo_eip+0x23d>
		return -1;
f01031c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01031ce:	eb 0c                	jmp    f01031dc <debuginfo_eip+0x23d>
		return -1;
f01031d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01031d5:	eb 05                	jmp    f01031dc <debuginfo_eip+0x23d>
	return 0;
f01031d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031dc:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01031df:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01031e2:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01031e5:	89 ec                	mov    %ebp,%esp
f01031e7:	5d                   	pop    %ebp
f01031e8:	c3                   	ret    
f01031e9:	66 90                	xchg   %ax,%ax
f01031eb:	66 90                	xchg   %ax,%ax
f01031ed:	66 90                	xchg   %ax,%ax
f01031ef:	90                   	nop

f01031f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01031f0:	55                   	push   %ebp
f01031f1:	89 e5                	mov    %esp,%ebp
f01031f3:	57                   	push   %edi
f01031f4:	56                   	push   %esi
f01031f5:	53                   	push   %ebx
f01031f6:	83 ec 4c             	sub    $0x4c,%esp
f01031f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01031fc:	89 d7                	mov    %edx,%edi
f01031fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103201:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103204:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103207:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010320a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010320d:	85 db                	test   %ebx,%ebx
f010320f:	75 08                	jne    f0103219 <printnum+0x29>
f0103211:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0103214:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0103217:	77 6c                	ja     f0103285 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103219:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010321c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0103220:	83 ee 01             	sub    $0x1,%esi
f0103223:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103227:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010322a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010322e:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103232:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103236:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103239:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010323c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103243:	00 
f0103244:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0103247:	89 1c 24             	mov    %ebx,(%esp)
f010324a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010324d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103251:	e8 fa 09 00 00       	call   f0103c50 <__udivdi3>
f0103256:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103259:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010325c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103260:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103264:	89 04 24             	mov    %eax,(%esp)
f0103267:	89 54 24 04          	mov    %edx,0x4(%esp)
f010326b:	89 fa                	mov    %edi,%edx
f010326d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103270:	e8 7b ff ff ff       	call   f01031f0 <printnum>
f0103275:	eb 1b                	jmp    f0103292 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103277:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010327b:	8b 45 18             	mov    0x18(%ebp),%eax
f010327e:	89 04 24             	mov    %eax,(%esp)
f0103281:	ff d3                	call   *%ebx
f0103283:	eb 03                	jmp    f0103288 <printnum+0x98>
f0103285:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
f0103288:	83 ee 01             	sub    $0x1,%esi
f010328b:	85 f6                	test   %esi,%esi
f010328d:	7f e8                	jg     f0103277 <printnum+0x87>
f010328f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103292:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103296:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010329a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010329d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01032a1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01032a8:	00 
f01032a9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01032ac:	89 1c 24             	mov    %ebx,(%esp)
f01032af:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01032b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032b6:	e8 e5 0a 00 00       	call   f0103da0 <__umoddi3>
f01032bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032bf:	0f be 80 38 4f 10 f0 	movsbl -0xfefb0c8(%eax),%eax
f01032c6:	89 04 24             	mov    %eax,(%esp)
f01032c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032cc:	ff d0                	call   *%eax
}
f01032ce:	83 c4 4c             	add    $0x4c,%esp
f01032d1:	5b                   	pop    %ebx
f01032d2:	5e                   	pop    %esi
f01032d3:	5f                   	pop    %edi
f01032d4:	5d                   	pop    %ebp
f01032d5:	c3                   	ret    

f01032d6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01032d6:	55                   	push   %ebp
f01032d7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01032d9:	83 fa 01             	cmp    $0x1,%edx
f01032dc:	7e 0e                	jle    f01032ec <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01032de:	8b 10                	mov    (%eax),%edx
f01032e0:	8d 4a 08             	lea    0x8(%edx),%ecx
f01032e3:	89 08                	mov    %ecx,(%eax)
f01032e5:	8b 02                	mov    (%edx),%eax
f01032e7:	8b 52 04             	mov    0x4(%edx),%edx
f01032ea:	eb 22                	jmp    f010330e <getuint+0x38>
	else if (lflag)
f01032ec:	85 d2                	test   %edx,%edx
f01032ee:	74 10                	je     f0103300 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01032f0:	8b 10                	mov    (%eax),%edx
f01032f2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01032f5:	89 08                	mov    %ecx,(%eax)
f01032f7:	8b 02                	mov    (%edx),%eax
f01032f9:	ba 00 00 00 00       	mov    $0x0,%edx
f01032fe:	eb 0e                	jmp    f010330e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103300:	8b 10                	mov    (%eax),%edx
f0103302:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103305:	89 08                	mov    %ecx,(%eax)
f0103307:	8b 02                	mov    (%edx),%eax
f0103309:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010330e:	5d                   	pop    %ebp
f010330f:	c3                   	ret    

f0103310 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103310:	55                   	push   %ebp
f0103311:	89 e5                	mov    %esp,%ebp
f0103313:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103316:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010331a:	8b 10                	mov    (%eax),%edx
f010331c:	3b 50 04             	cmp    0x4(%eax),%edx
f010331f:	73 0a                	jae    f010332b <sprintputch+0x1b>
		*b->buf++ = ch;
f0103321:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103324:	88 0a                	mov    %cl,(%edx)
f0103326:	83 c2 01             	add    $0x1,%edx
f0103329:	89 10                	mov    %edx,(%eax)
}
f010332b:	5d                   	pop    %ebp
f010332c:	c3                   	ret    

f010332d <printfmt>:
{
f010332d:	55                   	push   %ebp
f010332e:	89 e5                	mov    %esp,%ebp
f0103330:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0103333:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103336:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010333a:	8b 45 10             	mov    0x10(%ebp),%eax
f010333d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103341:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103344:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103348:	8b 45 08             	mov    0x8(%ebp),%eax
f010334b:	89 04 24             	mov    %eax,(%esp)
f010334e:	e8 02 00 00 00       	call   f0103355 <vprintfmt>
}
f0103353:	c9                   	leave  
f0103354:	c3                   	ret    

f0103355 <vprintfmt>:
{
f0103355:	55                   	push   %ebp
f0103356:	89 e5                	mov    %esp,%ebp
f0103358:	57                   	push   %edi
f0103359:	56                   	push   %esi
f010335a:	53                   	push   %ebx
f010335b:	83 ec 4c             	sub    $0x4c,%esp
f010335e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103361:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103364:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103367:	eb 11                	jmp    f010337a <vprintfmt+0x25>
			if (ch == '\0')
f0103369:	85 c0                	test   %eax,%eax
f010336b:	0f 84 cf 03 00 00    	je     f0103740 <vprintfmt+0x3eb>
			putch(ch, putdat);
f0103371:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103375:	89 04 24             	mov    %eax,(%esp)
f0103378:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010337a:	0f b6 07             	movzbl (%edi),%eax
f010337d:	83 c7 01             	add    $0x1,%edi
f0103380:	83 f8 25             	cmp    $0x25,%eax
f0103383:	75 e4                	jne    f0103369 <vprintfmt+0x14>
f0103385:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0103389:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0103390:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103397:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010339e:	ba 00 00 00 00       	mov    $0x0,%edx
f01033a3:	eb 2b                	jmp    f01033d0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f01033a5:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
f01033a8:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f01033ac:	eb 22                	jmp    f01033d0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f01033ae:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
f01033b1:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f01033b5:	eb 19                	jmp    f01033d0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f01033b7:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
f01033ba:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01033c1:	eb 0d                	jmp    f01033d0 <vprintfmt+0x7b>
				width = precision, precision = -1;
f01033c3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033c6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01033c9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01033d0:	0f b6 07             	movzbl (%edi),%eax
f01033d3:	8d 4f 01             	lea    0x1(%edi),%ecx
f01033d6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01033d9:	0f b6 0f             	movzbl (%edi),%ecx
f01033dc:	83 e9 23             	sub    $0x23,%ecx
f01033df:	80 f9 55             	cmp    $0x55,%cl
f01033e2:	0f 87 3b 03 00 00    	ja     f0103723 <vprintfmt+0x3ce>
f01033e8:	0f b6 c9             	movzbl %cl,%ecx
f01033eb:	ff 24 8d e0 4f 10 f0 	jmp    *-0xfefb020(,%ecx,4)
f01033f2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01033f5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01033fc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01033ff:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
f0103404:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0103407:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f010340b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f010340e:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103411:	83 f9 09             	cmp    $0x9,%ecx
f0103414:	77 2f                	ja     f0103445 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
f0103416:	83 c7 01             	add    $0x1,%edi
			}
f0103419:	eb e9                	jmp    f0103404 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
f010341b:	8b 45 14             	mov    0x14(%ebp),%eax
f010341e:	8d 48 04             	lea    0x4(%eax),%ecx
f0103421:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103424:	8b 00                	mov    (%eax),%eax
f0103426:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103429:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
f010342c:	eb 1d                	jmp    f010344b <vprintfmt+0xf6>
			if (width < 0)
f010342e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103432:	78 83                	js     f01033b7 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
f0103434:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103437:	eb 97                	jmp    f01033d0 <vprintfmt+0x7b>
f0103439:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
f010343c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0103443:	eb 8b                	jmp    f01033d0 <vprintfmt+0x7b>
f0103445:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103448:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
f010344b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010344f:	0f 89 7b ff ff ff    	jns    f01033d0 <vprintfmt+0x7b>
f0103455:	e9 69 ff ff ff       	jmp    f01033c3 <vprintfmt+0x6e>
			lflag++;
f010345a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010345d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
f0103460:	e9 6b ff ff ff       	jmp    f01033d0 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
f0103465:	8b 45 14             	mov    0x14(%ebp),%eax
f0103468:	8d 50 04             	lea    0x4(%eax),%edx
f010346b:	89 55 14             	mov    %edx,0x14(%ebp)
f010346e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103472:	8b 00                	mov    (%eax),%eax
f0103474:	89 04 24             	mov    %eax,(%esp)
f0103477:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f0103479:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f010347c:	e9 f9 fe ff ff       	jmp    f010337a <vprintfmt+0x25>
			err = va_arg(ap, int);
f0103481:	8b 45 14             	mov    0x14(%ebp),%eax
f0103484:	8d 50 04             	lea    0x4(%eax),%edx
f0103487:	89 55 14             	mov    %edx,0x14(%ebp)
f010348a:	8b 00                	mov    (%eax),%eax
f010348c:	89 c2                	mov    %eax,%edx
f010348e:	c1 fa 1f             	sar    $0x1f,%edx
f0103491:	31 d0                	xor    %edx,%eax
f0103493:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103495:	83 f8 07             	cmp    $0x7,%eax
f0103498:	7f 0b                	jg     f01034a5 <vprintfmt+0x150>
f010349a:	8b 14 85 40 51 10 f0 	mov    -0xfefaec0(,%eax,4),%edx
f01034a1:	85 d2                	test   %edx,%edx
f01034a3:	75 20                	jne    f01034c5 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f01034a5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034a9:	c7 44 24 08 50 4f 10 	movl   $0xf0104f50,0x8(%esp)
f01034b0:	f0 
f01034b1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034b5:	89 34 24             	mov    %esi,(%esp)
f01034b8:	e8 70 fe ff ff       	call   f010332d <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f01034bd:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
f01034c0:	e9 b5 fe ff ff       	jmp    f010337a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f01034c5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01034c9:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f01034d0:	f0 
f01034d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034d5:	89 34 24             	mov    %esi,(%esp)
f01034d8:	e8 50 fe ff ff       	call   f010332d <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f01034dd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01034e0:	e9 95 fe ff ff       	jmp    f010337a <vprintfmt+0x25>
f01034e5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01034e8:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01034eb:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f01034ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f1:	8d 50 04             	lea    0x4(%eax),%edx
f01034f4:	89 55 14             	mov    %edx,0x14(%ebp)
f01034f7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01034f9:	85 ff                	test   %edi,%edi
f01034fb:	b8 49 4f 10 f0       	mov    $0xf0104f49,%eax
f0103500:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103503:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0103507:	0f 84 9b 00 00 00    	je     f01035a8 <vprintfmt+0x253>
f010350d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103511:	0f 8e 9f 00 00 00    	jle    f01035b6 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103517:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010351b:	89 3c 24             	mov    %edi,(%esp)
f010351e:	e8 95 03 00 00       	call   f01038b8 <strnlen>
f0103523:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103526:	29 c2                	sub    %eax,%edx
f0103528:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f010352b:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f010352f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103532:	89 7d c8             	mov    %edi,-0x38(%ebp)
f0103535:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103537:	eb 0f                	jmp    f0103548 <vprintfmt+0x1f3>
					putch(padc, putdat);
f0103539:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010353d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103540:	89 04 24             	mov    %eax,(%esp)
f0103543:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103545:	83 ef 01             	sub    $0x1,%edi
f0103548:	85 ff                	test   %edi,%edi
f010354a:	7f ed                	jg     f0103539 <vprintfmt+0x1e4>
f010354c:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010354f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103553:	b8 00 00 00 00       	mov    $0x0,%eax
f0103558:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
f010355c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010355f:	29 c2                	sub    %eax,%edx
f0103561:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103564:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103567:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010356a:	89 d3                	mov    %edx,%ebx
f010356c:	eb 54                	jmp    f01035c2 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
f010356e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103572:	74 20                	je     f0103594 <vprintfmt+0x23f>
f0103574:	0f be d2             	movsbl %dl,%edx
f0103577:	83 ea 20             	sub    $0x20,%edx
f010357a:	83 fa 5e             	cmp    $0x5e,%edx
f010357d:	76 15                	jbe    f0103594 <vprintfmt+0x23f>
					putch('?', putdat);
f010357f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103582:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103586:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010358d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103590:	ff d0                	call   *%eax
f0103592:	eb 0f                	jmp    f01035a3 <vprintfmt+0x24e>
					putch(ch, putdat);
f0103594:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103597:	89 54 24 04          	mov    %edx,0x4(%esp)
f010359b:	89 04 24             	mov    %eax,(%esp)
f010359e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01035a1:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035a3:	83 eb 01             	sub    $0x1,%ebx
f01035a6:	eb 1a                	jmp    f01035c2 <vprintfmt+0x26d>
f01035a8:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01035ab:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01035ae:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01035b1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01035b4:	eb 0c                	jmp    f01035c2 <vprintfmt+0x26d>
f01035b6:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01035b9:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01035bc:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01035bf:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01035c2:	0f b6 17             	movzbl (%edi),%edx
f01035c5:	0f be c2             	movsbl %dl,%eax
f01035c8:	83 c7 01             	add    $0x1,%edi
f01035cb:	85 c0                	test   %eax,%eax
f01035cd:	74 29                	je     f01035f8 <vprintfmt+0x2a3>
f01035cf:	85 f6                	test   %esi,%esi
f01035d1:	78 9b                	js     f010356e <vprintfmt+0x219>
f01035d3:	83 ee 01             	sub    $0x1,%esi
f01035d6:	79 96                	jns    f010356e <vprintfmt+0x219>
f01035d8:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01035db:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01035de:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01035e1:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01035e4:	eb 1a                	jmp    f0103600 <vprintfmt+0x2ab>
				putch(' ', putdat);
f01035e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035ea:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01035f1:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01035f3:	83 ef 01             	sub    $0x1,%edi
f01035f6:	eb 08                	jmp    f0103600 <vprintfmt+0x2ab>
f01035f8:	89 df                	mov    %ebx,%edi
f01035fa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01035fd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103600:	85 ff                	test   %edi,%edi
f0103602:	7f e2                	jg     f01035e6 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
f0103604:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103607:	e9 6e fd ff ff       	jmp    f010337a <vprintfmt+0x25>
	if (lflag >= 2)
f010360c:	83 fa 01             	cmp    $0x1,%edx
f010360f:	7e 16                	jle    f0103627 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f0103611:	8b 45 14             	mov    0x14(%ebp),%eax
f0103614:	8d 50 08             	lea    0x8(%eax),%edx
f0103617:	89 55 14             	mov    %edx,0x14(%ebp)
f010361a:	8b 10                	mov    (%eax),%edx
f010361c:	8b 48 04             	mov    0x4(%eax),%ecx
f010361f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103622:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103625:	eb 32                	jmp    f0103659 <vprintfmt+0x304>
	else if (lflag)
f0103627:	85 d2                	test   %edx,%edx
f0103629:	74 18                	je     f0103643 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
f010362b:	8b 45 14             	mov    0x14(%ebp),%eax
f010362e:	8d 50 04             	lea    0x4(%eax),%edx
f0103631:	89 55 14             	mov    %edx,0x14(%ebp)
f0103634:	8b 00                	mov    (%eax),%eax
f0103636:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103639:	89 c1                	mov    %eax,%ecx
f010363b:	c1 f9 1f             	sar    $0x1f,%ecx
f010363e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103641:	eb 16                	jmp    f0103659 <vprintfmt+0x304>
		return va_arg(*ap, int);
f0103643:	8b 45 14             	mov    0x14(%ebp),%eax
f0103646:	8d 50 04             	lea    0x4(%eax),%edx
f0103649:	89 55 14             	mov    %edx,0x14(%ebp)
f010364c:	8b 00                	mov    (%eax),%eax
f010364e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103651:	89 c7                	mov    %eax,%edi
f0103653:	c1 ff 1f             	sar    $0x1f,%edi
f0103656:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
f0103659:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010365c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
f010365f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0103664:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103668:	79 7d                	jns    f01036e7 <vprintfmt+0x392>
				putch('-', putdat);
f010366a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010366e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103675:	ff d6                	call   *%esi
				num = -(long long) num;
f0103677:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010367a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010367d:	f7 d8                	neg    %eax
f010367f:	83 d2 00             	adc    $0x0,%edx
f0103682:	f7 da                	neg    %edx
			base = 10;
f0103684:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103689:	eb 5c                	jmp    f01036e7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f010368b:	8d 45 14             	lea    0x14(%ebp),%eax
f010368e:	e8 43 fc ff ff       	call   f01032d6 <getuint>
			base = 10;
f0103693:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103698:	eb 4d                	jmp    f01036e7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f010369a:	8d 45 14             	lea    0x14(%ebp),%eax
f010369d:	e8 34 fc ff ff       	call   f01032d6 <getuint>
			base = 8;
f01036a2:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01036a7:	eb 3e                	jmp    f01036e7 <vprintfmt+0x392>
			putch('0', putdat);
f01036a9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01036ad:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01036b4:	ff d6                	call   *%esi
			putch('x', putdat);
f01036b6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01036ba:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01036c1:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f01036c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01036c6:	8d 50 04             	lea    0x4(%eax),%edx
f01036c9:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01036cc:	8b 00                	mov    (%eax),%eax
f01036ce:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01036d3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01036d8:	eb 0d                	jmp    f01036e7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f01036da:	8d 45 14             	lea    0x14(%ebp),%eax
f01036dd:	e8 f4 fb ff ff       	call   f01032d6 <getuint>
			base = 16;
f01036e2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01036e7:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01036eb:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01036ef:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01036f2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01036f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036fa:	89 04 24             	mov    %eax,(%esp)
f01036fd:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103701:	89 da                	mov    %ebx,%edx
f0103703:	89 f0                	mov    %esi,%eax
f0103705:	e8 e6 fa ff ff       	call   f01031f0 <printnum>
			break;
f010370a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010370d:	e9 68 fc ff ff       	jmp    f010337a <vprintfmt+0x25>
			putch(ch, putdat);
f0103712:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103716:	89 04 24             	mov    %eax,(%esp)
f0103719:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f010371b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f010371e:	e9 57 fc ff ff       	jmp    f010337a <vprintfmt+0x25>
			putch('%', putdat);
f0103723:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103727:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010372e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103730:	eb 03                	jmp    f0103735 <vprintfmt+0x3e0>
f0103732:	83 ef 01             	sub    $0x1,%edi
f0103735:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103739:	75 f7                	jne    f0103732 <vprintfmt+0x3dd>
f010373b:	e9 3a fc ff ff       	jmp    f010337a <vprintfmt+0x25>
}
f0103740:	83 c4 4c             	add    $0x4c,%esp
f0103743:	5b                   	pop    %ebx
f0103744:	5e                   	pop    %esi
f0103745:	5f                   	pop    %edi
f0103746:	5d                   	pop    %ebp
f0103747:	c3                   	ret    

f0103748 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103748:	55                   	push   %ebp
f0103749:	89 e5                	mov    %esp,%ebp
f010374b:	83 ec 28             	sub    $0x28,%esp
f010374e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103751:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103754:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103757:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010375b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010375e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103765:	85 d2                	test   %edx,%edx
f0103767:	7e 30                	jle    f0103799 <vsnprintf+0x51>
f0103769:	85 c0                	test   %eax,%eax
f010376b:	74 2c                	je     f0103799 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010376d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103770:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103774:	8b 45 10             	mov    0x10(%ebp),%eax
f0103777:	89 44 24 08          	mov    %eax,0x8(%esp)
f010377b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010377e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103782:	c7 04 24 10 33 10 f0 	movl   $0xf0103310,(%esp)
f0103789:	e8 c7 fb ff ff       	call   f0103355 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010378e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103791:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103794:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103797:	eb 05                	jmp    f010379e <vsnprintf+0x56>
		return -E_INVAL;
f0103799:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f010379e:	c9                   	leave  
f010379f:	c3                   	ret    

f01037a0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01037a0:	55                   	push   %ebp
f01037a1:	89 e5                	mov    %esp,%ebp
f01037a3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01037a6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01037a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01037ad:	8b 45 10             	mov    0x10(%ebp),%eax
f01037b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01037be:	89 04 24             	mov    %eax,(%esp)
f01037c1:	e8 82 ff ff ff       	call   f0103748 <vsnprintf>
	va_end(ap);

	return rc;
}
f01037c6:	c9                   	leave  
f01037c7:	c3                   	ret    
f01037c8:	66 90                	xchg   %ax,%ax
f01037ca:	66 90                	xchg   %ax,%ax
f01037cc:	66 90                	xchg   %ax,%ax
f01037ce:	66 90                	xchg   %ax,%ax

f01037d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01037d0:	55                   	push   %ebp
f01037d1:	89 e5                	mov    %esp,%ebp
f01037d3:	57                   	push   %edi
f01037d4:	56                   	push   %esi
f01037d5:	53                   	push   %ebx
f01037d6:	83 ec 1c             	sub    $0x1c,%esp
f01037d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01037dc:	85 c0                	test   %eax,%eax
f01037de:	74 10                	je     f01037f0 <readline+0x20>
		cprintf("%s", prompt);
f01037e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037e4:	c7 04 24 68 4c 10 f0 	movl   $0xf0104c68,(%esp)
f01037eb:	e8 b8 f6 ff ff       	call   f0102ea8 <cprintf>

	i = 0;
	echoing = iscons(0);
f01037f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01037f7:	e8 14 ce ff ff       	call   f0100610 <iscons>
f01037fc:	89 c7                	mov    %eax,%edi
	i = 0;
f01037fe:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0103803:	e8 f7 cd ff ff       	call   f01005ff <getchar>
f0103808:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010380a:	85 c0                	test   %eax,%eax
f010380c:	79 17                	jns    f0103825 <readline+0x55>
			cprintf("read error: %e\n", c);
f010380e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103812:	c7 04 24 60 51 10 f0 	movl   $0xf0105160,(%esp)
f0103819:	e8 8a f6 ff ff       	call   f0102ea8 <cprintf>
			return NULL;
f010381e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103823:	eb 6d                	jmp    f0103892 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103825:	83 f8 7f             	cmp    $0x7f,%eax
f0103828:	74 05                	je     f010382f <readline+0x5f>
f010382a:	83 f8 08             	cmp    $0x8,%eax
f010382d:	75 19                	jne    f0103848 <readline+0x78>
f010382f:	85 f6                	test   %esi,%esi
f0103831:	7e 15                	jle    f0103848 <readline+0x78>
			if (echoing)
f0103833:	85 ff                	test   %edi,%edi
f0103835:	74 0c                	je     f0103843 <readline+0x73>
				cputchar('\b');
f0103837:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010383e:	e8 ac cd ff ff       	call   f01005ef <cputchar>
			i--;
f0103843:	83 ee 01             	sub    $0x1,%esi
f0103846:	eb bb                	jmp    f0103803 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103848:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010384e:	7f 1c                	jg     f010386c <readline+0x9c>
f0103850:	83 fb 1f             	cmp    $0x1f,%ebx
f0103853:	7e 17                	jle    f010386c <readline+0x9c>
			if (echoing)
f0103855:	85 ff                	test   %edi,%edi
f0103857:	74 08                	je     f0103861 <readline+0x91>
				cputchar(c);
f0103859:	89 1c 24             	mov    %ebx,(%esp)
f010385c:	e8 8e cd ff ff       	call   f01005ef <cputchar>
			buf[i++] = c;
f0103861:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f0103867:	83 c6 01             	add    $0x1,%esi
f010386a:	eb 97                	jmp    f0103803 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010386c:	83 fb 0d             	cmp    $0xd,%ebx
f010386f:	74 05                	je     f0103876 <readline+0xa6>
f0103871:	83 fb 0a             	cmp    $0xa,%ebx
f0103874:	75 8d                	jne    f0103803 <readline+0x33>
			if (echoing)
f0103876:	85 ff                	test   %edi,%edi
f0103878:	74 0c                	je     f0103886 <readline+0xb6>
				cputchar('\n');
f010387a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103881:	e8 69 cd ff ff       	call   f01005ef <cputchar>
			buf[i] = 0;
f0103886:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f010388d:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f0103892:	83 c4 1c             	add    $0x1c,%esp
f0103895:	5b                   	pop    %ebx
f0103896:	5e                   	pop    %esi
f0103897:	5f                   	pop    %edi
f0103898:	5d                   	pop    %ebp
f0103899:	c3                   	ret    
f010389a:	66 90                	xchg   %ax,%ax
f010389c:	66 90                	xchg   %ax,%ax
f010389e:	66 90                	xchg   %ax,%ax

f01038a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01038a0:	55                   	push   %ebp
f01038a1:	89 e5                	mov    %esp,%ebp
f01038a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01038a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01038ab:	eb 03                	jmp    f01038b0 <strlen+0x10>
		n++;
f01038ad:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01038b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01038b4:	75 f7                	jne    f01038ad <strlen+0xd>
	return n;
}
f01038b6:	5d                   	pop    %ebp
f01038b7:	c3                   	ret    

f01038b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01038b8:	55                   	push   %ebp
f01038b9:	89 e5                	mov    %esp,%ebp
f01038bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
f01038be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01038c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01038c6:	eb 03                	jmp    f01038cb <strnlen+0x13>
		n++;
f01038c8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01038cb:	39 d0                	cmp    %edx,%eax
f01038cd:	74 06                	je     f01038d5 <strnlen+0x1d>
f01038cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01038d3:	75 f3                	jne    f01038c8 <strnlen+0x10>
	return n;
}
f01038d5:	5d                   	pop    %ebp
f01038d6:	c3                   	ret    

f01038d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01038d7:	55                   	push   %ebp
f01038d8:	89 e5                	mov    %esp,%ebp
f01038da:	53                   	push   %ebx
f01038db:	8b 45 08             	mov    0x8(%ebp),%eax
f01038de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01038e1:	89 c2                	mov    %eax,%edx
f01038e3:	0f b6 19             	movzbl (%ecx),%ebx
f01038e6:	88 1a                	mov    %bl,(%edx)
f01038e8:	83 c2 01             	add    $0x1,%edx
f01038eb:	83 c1 01             	add    $0x1,%ecx
f01038ee:	84 db                	test   %bl,%bl
f01038f0:	75 f1                	jne    f01038e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01038f2:	5b                   	pop    %ebx
f01038f3:	5d                   	pop    %ebp
f01038f4:	c3                   	ret    

f01038f5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01038f5:	55                   	push   %ebp
f01038f6:	89 e5                	mov    %esp,%ebp
f01038f8:	53                   	push   %ebx
f01038f9:	83 ec 08             	sub    $0x8,%esp
f01038fc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01038ff:	89 1c 24             	mov    %ebx,(%esp)
f0103902:	e8 99 ff ff ff       	call   f01038a0 <strlen>
	strcpy(dst + len, src);
f0103907:	8b 55 0c             	mov    0xc(%ebp),%edx
f010390a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010390e:	01 d8                	add    %ebx,%eax
f0103910:	89 04 24             	mov    %eax,(%esp)
f0103913:	e8 bf ff ff ff       	call   f01038d7 <strcpy>
	return dst;
}
f0103918:	89 d8                	mov    %ebx,%eax
f010391a:	83 c4 08             	add    $0x8,%esp
f010391d:	5b                   	pop    %ebx
f010391e:	5d                   	pop    %ebp
f010391f:	c3                   	ret    

f0103920 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103920:	55                   	push   %ebp
f0103921:	89 e5                	mov    %esp,%ebp
f0103923:	56                   	push   %esi
f0103924:	53                   	push   %ebx
f0103925:	8b 75 08             	mov    0x8(%ebp),%esi
f0103928:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010392b:	89 f3                	mov    %esi,%ebx
f010392d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103930:	89 f2                	mov    %esi,%edx
f0103932:	eb 0e                	jmp    f0103942 <strncpy+0x22>
		*dst++ = *src;
f0103934:	0f b6 01             	movzbl (%ecx),%eax
f0103937:	88 02                	mov    %al,(%edx)
f0103939:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010393c:	80 39 01             	cmpb   $0x1,(%ecx)
f010393f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103942:	39 da                	cmp    %ebx,%edx
f0103944:	75 ee                	jne    f0103934 <strncpy+0x14>
	}
	return ret;
}
f0103946:	89 f0                	mov    %esi,%eax
f0103948:	5b                   	pop    %ebx
f0103949:	5e                   	pop    %esi
f010394a:	5d                   	pop    %ebp
f010394b:	c3                   	ret    

f010394c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010394c:	55                   	push   %ebp
f010394d:	89 e5                	mov    %esp,%ebp
f010394f:	56                   	push   %esi
f0103950:	53                   	push   %ebx
f0103951:	8b 75 08             	mov    0x8(%ebp),%esi
f0103954:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103957:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010395a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
f010395c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
f0103960:	85 c9                	test   %ecx,%ecx
f0103962:	75 0a                	jne    f010396e <strlcpy+0x22>
f0103964:	eb 1c                	jmp    f0103982 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103966:	88 08                	mov    %cl,(%eax)
f0103968:	83 c0 01             	add    $0x1,%eax
f010396b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
f010396e:	39 d8                	cmp    %ebx,%eax
f0103970:	74 0b                	je     f010397d <strlcpy+0x31>
f0103972:	0f b6 0a             	movzbl (%edx),%ecx
f0103975:	84 c9                	test   %cl,%cl
f0103977:	75 ed                	jne    f0103966 <strlcpy+0x1a>
f0103979:	89 c2                	mov    %eax,%edx
f010397b:	eb 02                	jmp    f010397f <strlcpy+0x33>
f010397d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f010397f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103982:	29 f0                	sub    %esi,%eax
}
f0103984:	5b                   	pop    %ebx
f0103985:	5e                   	pop    %esi
f0103986:	5d                   	pop    %ebp
f0103987:	c3                   	ret    

f0103988 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103988:	55                   	push   %ebp
f0103989:	89 e5                	mov    %esp,%ebp
f010398b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010398e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103991:	eb 06                	jmp    f0103999 <strcmp+0x11>
		p++, q++;
f0103993:	83 c1 01             	add    $0x1,%ecx
f0103996:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103999:	0f b6 01             	movzbl (%ecx),%eax
f010399c:	84 c0                	test   %al,%al
f010399e:	74 04                	je     f01039a4 <strcmp+0x1c>
f01039a0:	3a 02                	cmp    (%edx),%al
f01039a2:	74 ef                	je     f0103993 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01039a4:	0f b6 c0             	movzbl %al,%eax
f01039a7:	0f b6 12             	movzbl (%edx),%edx
f01039aa:	29 d0                	sub    %edx,%eax
}
f01039ac:	5d                   	pop    %ebp
f01039ad:	c3                   	ret    

f01039ae <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01039ae:	55                   	push   %ebp
f01039af:	89 e5                	mov    %esp,%ebp
f01039b1:	53                   	push   %ebx
f01039b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b5:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
f01039b8:	89 c3                	mov    %eax,%ebx
f01039ba:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01039bd:	eb 06                	jmp    f01039c5 <strncmp+0x17>
		n--, p++, q++;
f01039bf:	83 c0 01             	add    $0x1,%eax
f01039c2:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01039c5:	39 d8                	cmp    %ebx,%eax
f01039c7:	74 15                	je     f01039de <strncmp+0x30>
f01039c9:	0f b6 08             	movzbl (%eax),%ecx
f01039cc:	84 c9                	test   %cl,%cl
f01039ce:	74 04                	je     f01039d4 <strncmp+0x26>
f01039d0:	3a 0a                	cmp    (%edx),%cl
f01039d2:	74 eb                	je     f01039bf <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01039d4:	0f b6 00             	movzbl (%eax),%eax
f01039d7:	0f b6 12             	movzbl (%edx),%edx
f01039da:	29 d0                	sub    %edx,%eax
f01039dc:	eb 05                	jmp    f01039e3 <strncmp+0x35>
		return 0;
f01039de:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039e3:	5b                   	pop    %ebx
f01039e4:	5d                   	pop    %ebp
f01039e5:	c3                   	ret    

f01039e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01039e6:	55                   	push   %ebp
f01039e7:	89 e5                	mov    %esp,%ebp
f01039e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01039f0:	eb 07                	jmp    f01039f9 <strchr+0x13>
		if (*s == c)
f01039f2:	38 ca                	cmp    %cl,%dl
f01039f4:	74 0f                	je     f0103a05 <strchr+0x1f>
	for (; *s; s++)
f01039f6:	83 c0 01             	add    $0x1,%eax
f01039f9:	0f b6 10             	movzbl (%eax),%edx
f01039fc:	84 d2                	test   %dl,%dl
f01039fe:	75 f2                	jne    f01039f2 <strchr+0xc>
			return (char *) s;
	return 0;
f0103a00:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a05:	5d                   	pop    %ebp
f0103a06:	c3                   	ret    

f0103a07 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103a07:	55                   	push   %ebp
f0103a08:	89 e5                	mov    %esp,%ebp
f0103a0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a0d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103a11:	eb 07                	jmp    f0103a1a <strfind+0x13>
		if (*s == c)
f0103a13:	38 ca                	cmp    %cl,%dl
f0103a15:	74 0a                	je     f0103a21 <strfind+0x1a>
	for (; *s; s++)
f0103a17:	83 c0 01             	add    $0x1,%eax
f0103a1a:	0f b6 10             	movzbl (%eax),%edx
f0103a1d:	84 d2                	test   %dl,%dl
f0103a1f:	75 f2                	jne    f0103a13 <strfind+0xc>
			break;
	return (char *) s;
}
f0103a21:	5d                   	pop    %ebp
f0103a22:	c3                   	ret    

f0103a23 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103a23:	55                   	push   %ebp
f0103a24:	89 e5                	mov    %esp,%ebp
f0103a26:	83 ec 0c             	sub    $0xc,%esp
f0103a29:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103a2c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103a2f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103a32:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a35:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103a38:	85 c9                	test   %ecx,%ecx
f0103a3a:	74 36                	je     f0103a72 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103a3c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103a42:	75 28                	jne    f0103a6c <memset+0x49>
f0103a44:	f6 c1 03             	test   $0x3,%cl
f0103a47:	75 23                	jne    f0103a6c <memset+0x49>
		c &= 0xFF;
f0103a49:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103a4d:	89 d3                	mov    %edx,%ebx
f0103a4f:	c1 e3 08             	shl    $0x8,%ebx
f0103a52:	89 d6                	mov    %edx,%esi
f0103a54:	c1 e6 18             	shl    $0x18,%esi
f0103a57:	89 d0                	mov    %edx,%eax
f0103a59:	c1 e0 10             	shl    $0x10,%eax
f0103a5c:	09 f0                	or     %esi,%eax
f0103a5e:	09 c2                	or     %eax,%edx
f0103a60:	89 d0                	mov    %edx,%eax
f0103a62:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103a64:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103a67:	fc                   	cld    
f0103a68:	f3 ab                	rep stos %eax,%es:(%edi)
f0103a6a:	eb 06                	jmp    f0103a72 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103a6c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a6f:	fc                   	cld    
f0103a70:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103a72:	89 f8                	mov    %edi,%eax
f0103a74:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103a77:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103a7a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a7d:	89 ec                	mov    %ebp,%esp
f0103a7f:	5d                   	pop    %ebp
f0103a80:	c3                   	ret    

f0103a81 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103a81:	55                   	push   %ebp
f0103a82:	89 e5                	mov    %esp,%ebp
f0103a84:	83 ec 08             	sub    $0x8,%esp
f0103a87:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103a8a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103a8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a90:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a93:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103a96:	39 c6                	cmp    %eax,%esi
f0103a98:	73 36                	jae    f0103ad0 <memmove+0x4f>
f0103a9a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103a9d:	39 d0                	cmp    %edx,%eax
f0103a9f:	73 2f                	jae    f0103ad0 <memmove+0x4f>
		s += n;
		d += n;
f0103aa1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103aa4:	f6 c2 03             	test   $0x3,%dl
f0103aa7:	75 1b                	jne    f0103ac4 <memmove+0x43>
f0103aa9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103aaf:	75 13                	jne    f0103ac4 <memmove+0x43>
f0103ab1:	f6 c1 03             	test   $0x3,%cl
f0103ab4:	75 0e                	jne    f0103ac4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103ab6:	83 ef 04             	sub    $0x4,%edi
f0103ab9:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103abc:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103abf:	fd                   	std    
f0103ac0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103ac2:	eb 09                	jmp    f0103acd <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103ac4:	83 ef 01             	sub    $0x1,%edi
f0103ac7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103aca:	fd                   	std    
f0103acb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103acd:	fc                   	cld    
f0103ace:	eb 20                	jmp    f0103af0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ad0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103ad6:	75 13                	jne    f0103aeb <memmove+0x6a>
f0103ad8:	a8 03                	test   $0x3,%al
f0103ada:	75 0f                	jne    f0103aeb <memmove+0x6a>
f0103adc:	f6 c1 03             	test   $0x3,%cl
f0103adf:	75 0a                	jne    f0103aeb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103ae1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103ae4:	89 c7                	mov    %eax,%edi
f0103ae6:	fc                   	cld    
f0103ae7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103ae9:	eb 05                	jmp    f0103af0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
f0103aeb:	89 c7                	mov    %eax,%edi
f0103aed:	fc                   	cld    
f0103aee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103af0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103af3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103af6:	89 ec                	mov    %ebp,%esp
f0103af8:	5d                   	pop    %ebp
f0103af9:	c3                   	ret    

f0103afa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103afa:	55                   	push   %ebp
f0103afb:	89 e5                	mov    %esp,%ebp
f0103afd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103b00:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b03:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b0a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b11:	89 04 24             	mov    %eax,(%esp)
f0103b14:	e8 68 ff ff ff       	call   f0103a81 <memmove>
}
f0103b19:	c9                   	leave  
f0103b1a:	c3                   	ret    

f0103b1b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103b1b:	55                   	push   %ebp
f0103b1c:	89 e5                	mov    %esp,%ebp
f0103b1e:	56                   	push   %esi
f0103b1f:	53                   	push   %ebx
f0103b20:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b23:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
f0103b26:	89 d6                	mov    %edx,%esi
f0103b28:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b2b:	eb 1a                	jmp    f0103b47 <memcmp+0x2c>
		if (*s1 != *s2)
f0103b2d:	0f b6 02             	movzbl (%edx),%eax
f0103b30:	0f b6 19             	movzbl (%ecx),%ebx
f0103b33:	38 d8                	cmp    %bl,%al
f0103b35:	74 0a                	je     f0103b41 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103b37:	0f b6 c0             	movzbl %al,%eax
f0103b3a:	0f b6 db             	movzbl %bl,%ebx
f0103b3d:	29 d8                	sub    %ebx,%eax
f0103b3f:	eb 0f                	jmp    f0103b50 <memcmp+0x35>
		s1++, s2++;
f0103b41:	83 c2 01             	add    $0x1,%edx
f0103b44:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0103b47:	39 f2                	cmp    %esi,%edx
f0103b49:	75 e2                	jne    f0103b2d <memcmp+0x12>
	}

	return 0;
f0103b4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b50:	5b                   	pop    %ebx
f0103b51:	5e                   	pop    %esi
f0103b52:	5d                   	pop    %ebp
f0103b53:	c3                   	ret    

f0103b54 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103b54:	55                   	push   %ebp
f0103b55:	89 e5                	mov    %esp,%ebp
f0103b57:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b5a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103b5d:	89 c2                	mov    %eax,%edx
f0103b5f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103b62:	eb 07                	jmp    f0103b6b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103b64:	38 08                	cmp    %cl,(%eax)
f0103b66:	74 07                	je     f0103b6f <memfind+0x1b>
	for (; s < ends; s++)
f0103b68:	83 c0 01             	add    $0x1,%eax
f0103b6b:	39 d0                	cmp    %edx,%eax
f0103b6d:	72 f5                	jb     f0103b64 <memfind+0x10>
			break;
	return (void *) s;
}
f0103b6f:	5d                   	pop    %ebp
f0103b70:	c3                   	ret    

f0103b71 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103b71:	55                   	push   %ebp
f0103b72:	89 e5                	mov    %esp,%ebp
f0103b74:	57                   	push   %edi
f0103b75:	56                   	push   %esi
f0103b76:	53                   	push   %ebx
f0103b77:	83 ec 04             	sub    $0x4,%esp
f0103b7a:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b7d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b80:	eb 03                	jmp    f0103b85 <strtol+0x14>
		s++;
f0103b82:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0103b85:	0f b6 02             	movzbl (%edx),%eax
f0103b88:	3c 09                	cmp    $0x9,%al
f0103b8a:	74 f6                	je     f0103b82 <strtol+0x11>
f0103b8c:	3c 20                	cmp    $0x20,%al
f0103b8e:	74 f2                	je     f0103b82 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
f0103b90:	3c 2b                	cmp    $0x2b,%al
f0103b92:	75 0a                	jne    f0103b9e <strtol+0x2d>
		s++;
f0103b94:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0103b97:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b9c:	eb 10                	jmp    f0103bae <strtol+0x3d>
f0103b9e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0103ba3:	3c 2d                	cmp    $0x2d,%al
f0103ba5:	75 07                	jne    f0103bae <strtol+0x3d>
		s++, neg = 1;
f0103ba7:	8d 52 01             	lea    0x1(%edx),%edx
f0103baa:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103bae:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103bb4:	75 15                	jne    f0103bcb <strtol+0x5a>
f0103bb6:	80 3a 30             	cmpb   $0x30,(%edx)
f0103bb9:	75 10                	jne    f0103bcb <strtol+0x5a>
f0103bbb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103bbf:	75 0a                	jne    f0103bcb <strtol+0x5a>
		s += 2, base = 16;
f0103bc1:	83 c2 02             	add    $0x2,%edx
f0103bc4:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103bc9:	eb 10                	jmp    f0103bdb <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103bcb:	85 db                	test   %ebx,%ebx
f0103bcd:	75 0c                	jne    f0103bdb <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103bcf:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
f0103bd1:	80 3a 30             	cmpb   $0x30,(%edx)
f0103bd4:	75 05                	jne    f0103bdb <strtol+0x6a>
		s++, base = 8;
f0103bd6:	83 c2 01             	add    $0x1,%edx
f0103bd9:	b3 08                	mov    $0x8,%bl
		base = 10;
f0103bdb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103be0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103be3:	0f b6 0a             	movzbl (%edx),%ecx
f0103be6:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103be9:	89 f3                	mov    %esi,%ebx
f0103beb:	80 fb 09             	cmp    $0x9,%bl
f0103bee:	77 08                	ja     f0103bf8 <strtol+0x87>
			dig = *s - '0';
f0103bf0:	0f be c9             	movsbl %cl,%ecx
f0103bf3:	83 e9 30             	sub    $0x30,%ecx
f0103bf6:	eb 22                	jmp    f0103c1a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f0103bf8:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103bfb:	89 f3                	mov    %esi,%ebx
f0103bfd:	80 fb 19             	cmp    $0x19,%bl
f0103c00:	77 08                	ja     f0103c0a <strtol+0x99>
			dig = *s - 'a' + 10;
f0103c02:	0f be c9             	movsbl %cl,%ecx
f0103c05:	83 e9 57             	sub    $0x57,%ecx
f0103c08:	eb 10                	jmp    f0103c1a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f0103c0a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103c0d:	89 f3                	mov    %esi,%ebx
f0103c0f:	80 fb 19             	cmp    $0x19,%bl
f0103c12:	77 16                	ja     f0103c2a <strtol+0xb9>
			dig = *s - 'A' + 10;
f0103c14:	0f be c9             	movsbl %cl,%ecx
f0103c17:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103c1a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103c1d:	7d 0f                	jge    f0103c2e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103c1f:	83 c2 01             	add    $0x1,%edx
f0103c22:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0103c26:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103c28:	eb b9                	jmp    f0103be3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
f0103c2a:	89 c1                	mov    %eax,%ecx
f0103c2c:	eb 02                	jmp    f0103c30 <strtol+0xbf>
		if (dig >= base)
f0103c2e:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0103c30:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103c34:	74 05                	je     f0103c3b <strtol+0xca>
		*endptr = (char *) s;
f0103c36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c39:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103c3b:	89 ca                	mov    %ecx,%edx
f0103c3d:	f7 da                	neg    %edx
f0103c3f:	85 ff                	test   %edi,%edi
f0103c41:	0f 45 c2             	cmovne %edx,%eax
}
f0103c44:	83 c4 04             	add    $0x4,%esp
f0103c47:	5b                   	pop    %ebx
f0103c48:	5e                   	pop    %esi
f0103c49:	5f                   	pop    %edi
f0103c4a:	5d                   	pop    %ebp
f0103c4b:	c3                   	ret    
f0103c4c:	66 90                	xchg   %ax,%ax
f0103c4e:	66 90                	xchg   %ax,%ax

f0103c50 <__udivdi3>:
f0103c50:	83 ec 1c             	sub    $0x1c,%esp
f0103c53:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0103c57:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103c5b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103c5f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103c63:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0103c67:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0103c6b:	85 c0                	test   %eax,%eax
f0103c6d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103c71:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103c75:	89 ea                	mov    %ebp,%edx
f0103c77:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103c7b:	75 33                	jne    f0103cb0 <__udivdi3+0x60>
f0103c7d:	39 e9                	cmp    %ebp,%ecx
f0103c7f:	77 6f                	ja     f0103cf0 <__udivdi3+0xa0>
f0103c81:	85 c9                	test   %ecx,%ecx
f0103c83:	89 ce                	mov    %ecx,%esi
f0103c85:	75 0b                	jne    f0103c92 <__udivdi3+0x42>
f0103c87:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c8c:	31 d2                	xor    %edx,%edx
f0103c8e:	f7 f1                	div    %ecx
f0103c90:	89 c6                	mov    %eax,%esi
f0103c92:	31 d2                	xor    %edx,%edx
f0103c94:	89 e8                	mov    %ebp,%eax
f0103c96:	f7 f6                	div    %esi
f0103c98:	89 c5                	mov    %eax,%ebp
f0103c9a:	89 f8                	mov    %edi,%eax
f0103c9c:	f7 f6                	div    %esi
f0103c9e:	89 ea                	mov    %ebp,%edx
f0103ca0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ca4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ca8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cac:	83 c4 1c             	add    $0x1c,%esp
f0103caf:	c3                   	ret    
f0103cb0:	39 e8                	cmp    %ebp,%eax
f0103cb2:	77 24                	ja     f0103cd8 <__udivdi3+0x88>
f0103cb4:	0f bd c8             	bsr    %eax,%ecx
f0103cb7:	83 f1 1f             	xor    $0x1f,%ecx
f0103cba:	89 0c 24             	mov    %ecx,(%esp)
f0103cbd:	75 49                	jne    f0103d08 <__udivdi3+0xb8>
f0103cbf:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103cc3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0103cc7:	0f 86 ab 00 00 00    	jbe    f0103d78 <__udivdi3+0x128>
f0103ccd:	39 e8                	cmp    %ebp,%eax
f0103ccf:	0f 82 a3 00 00 00    	jb     f0103d78 <__udivdi3+0x128>
f0103cd5:	8d 76 00             	lea    0x0(%esi),%esi
f0103cd8:	31 d2                	xor    %edx,%edx
f0103cda:	31 c0                	xor    %eax,%eax
f0103cdc:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ce0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ce4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ce8:	83 c4 1c             	add    $0x1c,%esp
f0103ceb:	c3                   	ret    
f0103cec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cf0:	89 f8                	mov    %edi,%eax
f0103cf2:	f7 f1                	div    %ecx
f0103cf4:	31 d2                	xor    %edx,%edx
f0103cf6:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cfa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cfe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d02:	83 c4 1c             	add    $0x1c,%esp
f0103d05:	c3                   	ret    
f0103d06:	66 90                	xchg   %ax,%ax
f0103d08:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103d0c:	89 c6                	mov    %eax,%esi
f0103d0e:	b8 20 00 00 00       	mov    $0x20,%eax
f0103d13:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0103d17:	2b 04 24             	sub    (%esp),%eax
f0103d1a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103d1e:	d3 e6                	shl    %cl,%esi
f0103d20:	89 c1                	mov    %eax,%ecx
f0103d22:	d3 ed                	shr    %cl,%ebp
f0103d24:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103d28:	09 f5                	or     %esi,%ebp
f0103d2a:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103d2e:	d3 e6                	shl    %cl,%esi
f0103d30:	89 c1                	mov    %eax,%ecx
f0103d32:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103d36:	89 d6                	mov    %edx,%esi
f0103d38:	d3 ee                	shr    %cl,%esi
f0103d3a:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103d3e:	d3 e2                	shl    %cl,%edx
f0103d40:	89 c1                	mov    %eax,%ecx
f0103d42:	d3 ef                	shr    %cl,%edi
f0103d44:	09 d7                	or     %edx,%edi
f0103d46:	89 f2                	mov    %esi,%edx
f0103d48:	89 f8                	mov    %edi,%eax
f0103d4a:	f7 f5                	div    %ebp
f0103d4c:	89 d6                	mov    %edx,%esi
f0103d4e:	89 c7                	mov    %eax,%edi
f0103d50:	f7 64 24 04          	mull   0x4(%esp)
f0103d54:	39 d6                	cmp    %edx,%esi
f0103d56:	72 30                	jb     f0103d88 <__udivdi3+0x138>
f0103d58:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103d5c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103d60:	d3 e5                	shl    %cl,%ebp
f0103d62:	39 c5                	cmp    %eax,%ebp
f0103d64:	73 04                	jae    f0103d6a <__udivdi3+0x11a>
f0103d66:	39 d6                	cmp    %edx,%esi
f0103d68:	74 1e                	je     f0103d88 <__udivdi3+0x138>
f0103d6a:	89 f8                	mov    %edi,%eax
f0103d6c:	31 d2                	xor    %edx,%edx
f0103d6e:	e9 69 ff ff ff       	jmp    f0103cdc <__udivdi3+0x8c>
f0103d73:	90                   	nop
f0103d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d78:	31 d2                	xor    %edx,%edx
f0103d7a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d7f:	e9 58 ff ff ff       	jmp    f0103cdc <__udivdi3+0x8c>
f0103d84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d88:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103d8b:	31 d2                	xor    %edx,%edx
f0103d8d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d91:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d95:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d99:	83 c4 1c             	add    $0x1c,%esp
f0103d9c:	c3                   	ret    
f0103d9d:	66 90                	xchg   %ax,%ax
f0103d9f:	90                   	nop

f0103da0 <__umoddi3>:
f0103da0:	83 ec 2c             	sub    $0x2c,%esp
f0103da3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103da7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103dab:	89 74 24 20          	mov    %esi,0x20(%esp)
f0103daf:	8b 74 24 38          	mov    0x38(%esp),%esi
f0103db3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0103db7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0103dbb:	85 c0                	test   %eax,%eax
f0103dbd:	89 c2                	mov    %eax,%edx
f0103dbf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0103dc3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0103dc7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103dcb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103dcf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103dd3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103dd7:	75 1f                	jne    f0103df8 <__umoddi3+0x58>
f0103dd9:	39 fe                	cmp    %edi,%esi
f0103ddb:	76 63                	jbe    f0103e40 <__umoddi3+0xa0>
f0103ddd:	89 c8                	mov    %ecx,%eax
f0103ddf:	89 fa                	mov    %edi,%edx
f0103de1:	f7 f6                	div    %esi
f0103de3:	89 d0                	mov    %edx,%eax
f0103de5:	31 d2                	xor    %edx,%edx
f0103de7:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103deb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103def:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103df3:	83 c4 2c             	add    $0x2c,%esp
f0103df6:	c3                   	ret    
f0103df7:	90                   	nop
f0103df8:	39 f8                	cmp    %edi,%eax
f0103dfa:	77 64                	ja     f0103e60 <__umoddi3+0xc0>
f0103dfc:	0f bd e8             	bsr    %eax,%ebp
f0103dff:	83 f5 1f             	xor    $0x1f,%ebp
f0103e02:	75 74                	jne    f0103e78 <__umoddi3+0xd8>
f0103e04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e08:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0103e0c:	0f 87 0e 01 00 00    	ja     f0103f20 <__umoddi3+0x180>
f0103e12:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0103e16:	29 f1                	sub    %esi,%ecx
f0103e18:	19 c7                	sbb    %eax,%edi
f0103e1a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103e1e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103e22:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103e26:	8b 54 24 18          	mov    0x18(%esp),%edx
f0103e2a:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103e2e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103e32:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103e36:	83 c4 2c             	add    $0x2c,%esp
f0103e39:	c3                   	ret    
f0103e3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e40:	85 f6                	test   %esi,%esi
f0103e42:	89 f5                	mov    %esi,%ebp
f0103e44:	75 0b                	jne    f0103e51 <__umoddi3+0xb1>
f0103e46:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e4b:	31 d2                	xor    %edx,%edx
f0103e4d:	f7 f6                	div    %esi
f0103e4f:	89 c5                	mov    %eax,%ebp
f0103e51:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103e55:	31 d2                	xor    %edx,%edx
f0103e57:	f7 f5                	div    %ebp
f0103e59:	89 c8                	mov    %ecx,%eax
f0103e5b:	f7 f5                	div    %ebp
f0103e5d:	eb 84                	jmp    f0103de3 <__umoddi3+0x43>
f0103e5f:	90                   	nop
f0103e60:	89 c8                	mov    %ecx,%eax
f0103e62:	89 fa                	mov    %edi,%edx
f0103e64:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103e68:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103e6c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103e70:	83 c4 2c             	add    $0x2c,%esp
f0103e73:	c3                   	ret    
f0103e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e78:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103e7c:	be 20 00 00 00       	mov    $0x20,%esi
f0103e81:	89 e9                	mov    %ebp,%ecx
f0103e83:	29 ee                	sub    %ebp,%esi
f0103e85:	d3 e2                	shl    %cl,%edx
f0103e87:	89 f1                	mov    %esi,%ecx
f0103e89:	d3 e8                	shr    %cl,%eax
f0103e8b:	89 e9                	mov    %ebp,%ecx
f0103e8d:	09 d0                	or     %edx,%eax
f0103e8f:	89 fa                	mov    %edi,%edx
f0103e91:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e95:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103e99:	d3 e0                	shl    %cl,%eax
f0103e9b:	89 f1                	mov    %esi,%ecx
f0103e9d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103ea1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0103ea5:	d3 ea                	shr    %cl,%edx
f0103ea7:	89 e9                	mov    %ebp,%ecx
f0103ea9:	d3 e7                	shl    %cl,%edi
f0103eab:	89 f1                	mov    %esi,%ecx
f0103ead:	d3 e8                	shr    %cl,%eax
f0103eaf:	89 e9                	mov    %ebp,%ecx
f0103eb1:	09 f8                	or     %edi,%eax
f0103eb3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103eb7:	f7 74 24 0c          	divl   0xc(%esp)
f0103ebb:	d3 e7                	shl    %cl,%edi
f0103ebd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103ec1:	89 d7                	mov    %edx,%edi
f0103ec3:	f7 64 24 10          	mull   0x10(%esp)
f0103ec7:	39 d7                	cmp    %edx,%edi
f0103ec9:	89 c1                	mov    %eax,%ecx
f0103ecb:	89 54 24 14          	mov    %edx,0x14(%esp)
f0103ecf:	72 3b                	jb     f0103f0c <__umoddi3+0x16c>
f0103ed1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0103ed5:	72 31                	jb     f0103f08 <__umoddi3+0x168>
f0103ed7:	8b 44 24 18          	mov    0x18(%esp),%eax
f0103edb:	29 c8                	sub    %ecx,%eax
f0103edd:	19 d7                	sbb    %edx,%edi
f0103edf:	89 e9                	mov    %ebp,%ecx
f0103ee1:	89 fa                	mov    %edi,%edx
f0103ee3:	d3 e8                	shr    %cl,%eax
f0103ee5:	89 f1                	mov    %esi,%ecx
f0103ee7:	d3 e2                	shl    %cl,%edx
f0103ee9:	89 e9                	mov    %ebp,%ecx
f0103eeb:	09 d0                	or     %edx,%eax
f0103eed:	89 fa                	mov    %edi,%edx
f0103eef:	d3 ea                	shr    %cl,%edx
f0103ef1:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103ef5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103ef9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103efd:	83 c4 2c             	add    $0x2c,%esp
f0103f00:	c3                   	ret    
f0103f01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f08:	39 d7                	cmp    %edx,%edi
f0103f0a:	75 cb                	jne    f0103ed7 <__umoddi3+0x137>
f0103f0c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0103f10:	89 c1                	mov    %eax,%ecx
f0103f12:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0103f16:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0103f1a:	eb bb                	jmp    f0103ed7 <__umoddi3+0x137>
f0103f1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f20:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0103f24:	0f 82 e8 fe ff ff    	jb     f0103e12 <__umoddi3+0x72>
f0103f2a:	e9 f3 fe ff ff       	jmp    f0103e22 <__umoddi3+0x82>
