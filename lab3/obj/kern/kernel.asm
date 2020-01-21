
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
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 30 ec 17 f0       	mov    $0xf017ec30,%eax
f010004b:	2d 26 dd 17 f0       	sub    $0xf017dd26,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 26 dd 17 f0 	movl   $0xf017dd26,(%esp)
f0100063:	e8 3b 4d 00 00       	call   f0104da3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b0 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 c0 52 10 f0 	movl   $0xf01052c0,(%esp)
f010007c:	e8 b8 37 00 00       	call   f0103839 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 f8 11 00 00       	call   f010127e <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 22 31 00 00       	call   f01031ad <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 28 38 00 00       	call   f01038bd <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 c6 2b 13 f0 	movl   $0xf0132bc6,(%esp)
f01000a4:	e8 f4 32 00 00       	call   f010339d <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 a6 36 00 00       	call   f010375c <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d 20 ec 17 f0 00 	cmpl   $0x0,0xf017ec20
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 20 ec 17 f0    	mov    %esi,0xf017ec20

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 db 52 10 f0 	movl   $0xf01052db,(%esp)
f01000ea:	e8 4a 37 00 00       	call   f0103839 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 0b 37 00 00       	call   f0103806 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 ca 62 10 f0 	movl   $0xf01062ca,(%esp)
f0100102:	e8 32 37 00 00       	call   f0103839 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 d9 06 00 00       	call   f01007ec <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 f3 52 10 f0 	movl   $0xf01052f3,(%esp)
f0100134:	e8 00 37 00 00       	call   f0103839 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 be 36 00 00       	call   f0103806 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 ca 62 10 f0 	movl   $0xf01062ca,(%esp)
f010014f:	e8 e5 36 00 00       	call   f0103839 <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba 84 00 00 00       	mov    $0x84,%edx
f0100168:	ec                   	in     (%dx),%al
f0100169:	ec                   	in     (%dx),%al
f010016a:	ec                   	in     (%dx),%al
f010016b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010016c:	5d                   	pop    %ebp
f010016d:	c3                   	ret    

f010016e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016e:	55                   	push   %ebp
f010016f:	89 e5                	mov    %esp,%ebp
f0100171:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100176:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100177:	a8 01                	test   $0x1,%al
f0100179:	74 08                	je     f0100183 <serial_proc_data+0x15>
f010017b:	b2 f8                	mov    $0xf8,%dl
f010017d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017e:	0f b6 c0             	movzbl %al,%eax
f0100181:	eb 05                	jmp    f0100188 <serial_proc_data+0x1a>
		return -1;
f0100183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100188:	5d                   	pop    %ebp
f0100189:	c3                   	ret    

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	53                   	push   %ebx
f010018e:	83 ec 04             	sub    $0x4,%esp
f0100191:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100193:	eb 26                	jmp    f01001bb <cons_intr+0x31>
		if (c == 0)
f0100195:	85 d2                	test   %edx,%edx
f0100197:	74 22                	je     f01001bb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100199:	a1 64 df 17 f0       	mov    0xf017df64,%eax
f010019e:	88 90 60 dd 17 f0    	mov    %dl,-0xfe822a0(%eax)
f01001a4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001a7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01001b2:	0f 44 d0             	cmove  %eax,%edx
f01001b5:	89 15 64 df 17 f0    	mov    %edx,0xf017df64
	while ((c = (*proc)()) != -1) {
f01001bb:	ff d3                	call   *%ebx
f01001bd:	89 c2                	mov    %eax,%edx
f01001bf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001c2:	75 d1                	jne    f0100195 <cons_intr+0xb>
	}
}
f01001c4:	83 c4 04             	add    $0x4,%esp
f01001c7:	5b                   	pop    %ebx
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	57                   	push   %edi
f01001ce:	56                   	push   %esi
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 2c             	sub    $0x2c,%esp
f01001d3:	89 c7                	mov    %eax,%edi
f01001d5:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001da:	be fd 03 00 00       	mov    $0x3fd,%esi
f01001df:	eb 05                	jmp    f01001e6 <cons_putc+0x1c>
		delay();
f01001e1:	e8 7a ff ff ff       	call   f0100160 <delay>
f01001e6:	89 f2                	mov    %esi,%edx
f01001e8:	ec                   	in     (%dx),%al
	for (i = 0;
f01001e9:	a8 20                	test   $0x20,%al
f01001eb:	75 05                	jne    f01001f2 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001ed:	83 eb 01             	sub    $0x1,%ebx
f01001f0:	75 ef                	jne    f01001e1 <cons_putc+0x17>
	outb(COM1 + COM_TX, c);
f01001f2:	89 f8                	mov    %edi,%eax
f01001f4:	25 ff 00 00 00       	and    $0xff,%eax
f01001f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001fc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100201:	ee                   	out    %al,(%dx)
f0100202:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100207:	be 79 03 00 00       	mov    $0x379,%esi
f010020c:	eb 05                	jmp    f0100213 <cons_putc+0x49>
		delay();
f010020e:	e8 4d ff ff ff       	call   f0100160 <delay>
f0100213:	89 f2                	mov    %esi,%edx
f0100215:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100216:	84 c0                	test   %al,%al
f0100218:	78 05                	js     f010021f <cons_putc+0x55>
f010021a:	83 eb 01             	sub    $0x1,%ebx
f010021d:	75 ef                	jne    f010020e <cons_putc+0x44>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010021f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100224:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100228:	ee                   	out    %al,(%dx)
f0100229:	b2 7a                	mov    $0x7a,%dl
f010022b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100230:	ee                   	out    %al,(%dx)
f0100231:	b8 08 00 00 00       	mov    $0x8,%eax
f0100236:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010023f:	89 f8                	mov    %edi,%eax
f0100241:	80 cc 07             	or     $0x7,%ah
f0100244:	85 d2                	test   %edx,%edx
f0100246:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100249:	89 f8                	mov    %edi,%eax
f010024b:	25 ff 00 00 00       	and    $0xff,%eax
f0100250:	83 f8 09             	cmp    $0x9,%eax
f0100253:	74 7a                	je     f01002cf <cons_putc+0x105>
f0100255:	83 f8 09             	cmp    $0x9,%eax
f0100258:	7f 0b                	jg     f0100265 <cons_putc+0x9b>
f010025a:	83 f8 08             	cmp    $0x8,%eax
f010025d:	0f 85 a0 00 00 00    	jne    f0100303 <cons_putc+0x139>
f0100263:	eb 13                	jmp    f0100278 <cons_putc+0xae>
f0100265:	83 f8 0a             	cmp    $0xa,%eax
f0100268:	74 3f                	je     f01002a9 <cons_putc+0xdf>
f010026a:	83 f8 0d             	cmp    $0xd,%eax
f010026d:	8d 76 00             	lea    0x0(%esi),%esi
f0100270:	0f 85 8d 00 00 00    	jne    f0100303 <cons_putc+0x139>
f0100276:	eb 39                	jmp    f01002b1 <cons_putc+0xe7>
		if (crt_pos > 0) {
f0100278:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f010027f:	66 85 c0             	test   %ax,%ax
f0100282:	0f 84 e5 00 00 00    	je     f010036d <cons_putc+0x1a3>
			crt_pos--;
f0100288:	83 e8 01             	sub    $0x1,%eax
f010028b:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100291:	0f b7 c0             	movzwl %ax,%eax
f0100294:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f010029a:	83 cf 20             	or     $0x20,%edi
f010029d:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
f01002a3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002a7:	eb 77                	jmp    f0100320 <cons_putc+0x156>
		crt_pos += CRT_COLS;
f01002a9:	66 83 05 74 df 17 f0 	addw   $0x50,0xf017df74
f01002b0:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01002b1:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f01002b8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002be:	c1 e8 16             	shr    $0x16,%eax
f01002c1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002c4:	c1 e0 04             	shl    $0x4,%eax
f01002c7:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
f01002cd:	eb 51                	jmp    f0100320 <cons_putc+0x156>
		cons_putc(' ');
f01002cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d4:	e8 f1 fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002de:	e8 e7 fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e8:	e8 dd fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f2:	e8 d3 fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002fc:	e8 c9 fe ff ff       	call   f01001ca <cons_putc>
f0100301:	eb 1d                	jmp    f0100320 <cons_putc+0x156>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100303:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f010030a:	0f b7 c8             	movzwl %ax,%ecx
f010030d:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
f0100313:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100317:	83 c0 01             	add    $0x1,%eax
f010031a:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
	if (crt_pos >= CRT_SIZE) {
f0100320:	66 81 3d 74 df 17 f0 	cmpw   $0x7cf,0xf017df74
f0100327:	cf 07 
f0100329:	76 42                	jbe    f010036d <cons_putc+0x1a3>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010032b:	a1 70 df 17 f0       	mov    0xf017df70,%eax
f0100330:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100337:	00 
f0100338:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010033e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100342:	89 04 24             	mov    %eax,(%esp)
f0100345:	e8 b7 4a 00 00       	call   f0104e01 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010034a:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100350:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100355:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010035b:	83 c0 01             	add    $0x1,%eax
f010035e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100363:	75 f0                	jne    f0100355 <cons_putc+0x18b>
		crt_pos -= CRT_COLS;
f0100365:	66 83 2d 74 df 17 f0 	subw   $0x50,0xf017df74
f010036c:	50 
	outb(addr_6845, 14);
f010036d:	8b 0d 6c df 17 f0    	mov    0xf017df6c,%ecx
f0100373:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100378:	89 ca                	mov    %ecx,%edx
f010037a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010037b:	0f b7 1d 74 df 17 f0 	movzwl 0xf017df74,%ebx
f0100382:	8d 71 01             	lea    0x1(%ecx),%esi
f0100385:	89 d8                	mov    %ebx,%eax
f0100387:	66 c1 e8 08          	shr    $0x8,%ax
f010038b:	89 f2                	mov    %esi,%edx
f010038d:	ee                   	out    %al,(%dx)
f010038e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100393:	89 ca                	mov    %ecx,%edx
f0100395:	ee                   	out    %al,(%dx)
f0100396:	89 d8                	mov    %ebx,%eax
f0100398:	89 f2                	mov    %esi,%edx
f010039a:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010039b:	83 c4 2c             	add    $0x2c,%esp
f010039e:	5b                   	pop    %ebx
f010039f:	5e                   	pop    %esi
f01003a0:	5f                   	pop    %edi
f01003a1:	5d                   	pop    %ebp
f01003a2:	c3                   	ret    

f01003a3 <kbd_proc_data>:
{
f01003a3:	55                   	push   %ebp
f01003a4:	89 e5                	mov    %esp,%ebp
f01003a6:	53                   	push   %ebx
f01003a7:	83 ec 14             	sub    $0x14,%esp
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003aa:	ba 64 00 00 00       	mov    $0x64,%edx
f01003af:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003b0:	a8 01                	test   $0x1,%al
f01003b2:	0f 84 e5 00 00 00    	je     f010049d <kbd_proc_data+0xfa>
f01003b8:	b2 60                	mov    $0x60,%dl
f01003ba:	ec                   	in     (%dx),%al
f01003bb:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01003bd:	3c e0                	cmp    $0xe0,%al
f01003bf:	75 11                	jne    f01003d2 <kbd_proc_data+0x2f>
		shift |= E0ESC;
f01003c1:	83 0d 68 df 17 f0 40 	orl    $0x40,0xf017df68
		return 0;
f01003c8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003cd:	e9 d0 00 00 00       	jmp    f01004a2 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003d2:	84 c0                	test   %al,%al
f01003d4:	79 37                	jns    f010040d <kbd_proc_data+0x6a>
		data = (shift & E0ESC ? data : data & 0x7F);
f01003d6:	8b 0d 68 df 17 f0    	mov    0xf017df68,%ecx
f01003dc:	89 cb                	mov    %ecx,%ebx
f01003de:	83 e3 40             	and    $0x40,%ebx
f01003e1:	83 e0 7f             	and    $0x7f,%eax
f01003e4:	85 db                	test   %ebx,%ebx
f01003e6:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003e9:	0f b6 d2             	movzbl %dl,%edx
f01003ec:	0f b6 82 40 53 10 f0 	movzbl -0xfefacc0(%edx),%eax
f01003f3:	83 c8 40             	or     $0x40,%eax
f01003f6:	0f b6 c0             	movzbl %al,%eax
f01003f9:	f7 d0                	not    %eax
f01003fb:	21 c1                	and    %eax,%ecx
f01003fd:	89 0d 68 df 17 f0    	mov    %ecx,0xf017df68
		return 0;
f0100403:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100408:	e9 95 00 00 00       	jmp    f01004a2 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f010040d:	8b 0d 68 df 17 f0    	mov    0xf017df68,%ecx
f0100413:	f6 c1 40             	test   $0x40,%cl
f0100416:	74 0e                	je     f0100426 <kbd_proc_data+0x83>
		data |= 0x80;
f0100418:	89 c2                	mov    %eax,%edx
f010041a:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010041d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100420:	89 0d 68 df 17 f0    	mov    %ecx,0xf017df68
	shift |= shiftcode[data];
f0100426:	0f b6 d2             	movzbl %dl,%edx
f0100429:	0f b6 82 40 53 10 f0 	movzbl -0xfefacc0(%edx),%eax
f0100430:	0b 05 68 df 17 f0    	or     0xf017df68,%eax
	shift ^= togglecode[data];
f0100436:	0f b6 8a 40 54 10 f0 	movzbl -0xfefabc0(%edx),%ecx
f010043d:	31 c8                	xor    %ecx,%eax
f010043f:	a3 68 df 17 f0       	mov    %eax,0xf017df68
	c = charcode[shift & (CTL | SHIFT)][data];
f0100444:	89 c1                	mov    %eax,%ecx
f0100446:	83 e1 03             	and    $0x3,%ecx
f0100449:	8b 0c 8d 40 55 10 f0 	mov    -0xfefaac0(,%ecx,4),%ecx
f0100450:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100454:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100457:	a8 08                	test   $0x8,%al
f0100459:	74 1b                	je     f0100476 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010045b:	89 da                	mov    %ebx,%edx
f010045d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100460:	83 f9 19             	cmp    $0x19,%ecx
f0100463:	77 05                	ja     f010046a <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f0100465:	83 eb 20             	sub    $0x20,%ebx
f0100468:	eb 0c                	jmp    f0100476 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f010046a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010046d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100470:	83 fa 19             	cmp    $0x19,%edx
f0100473:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100476:	f7 d0                	not    %eax
f0100478:	a8 06                	test   $0x6,%al
f010047a:	75 26                	jne    f01004a2 <kbd_proc_data+0xff>
f010047c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100482:	75 1e                	jne    f01004a2 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f0100484:	c7 04 24 0d 53 10 f0 	movl   $0xf010530d,(%esp)
f010048b:	e8 a9 33 00 00       	call   f0103839 <cprintf>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100490:	ba 92 00 00 00       	mov    $0x92,%edx
f0100495:	b8 03 00 00 00       	mov    $0x3,%eax
f010049a:	ee                   	out    %al,(%dx)
f010049b:	eb 05                	jmp    f01004a2 <kbd_proc_data+0xff>
		return -1;
f010049d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
}
f01004a2:	89 d8                	mov    %ebx,%eax
f01004a4:	83 c4 14             	add    $0x14,%esp
f01004a7:	5b                   	pop    %ebx
f01004a8:	5d                   	pop    %ebp
f01004a9:	c3                   	ret    

f01004aa <serial_intr>:
	if (serial_exists)
f01004aa:	80 3d 40 dd 17 f0 00 	cmpb   $0x0,0xf017dd40
f01004b1:	74 11                	je     f01004c4 <serial_intr+0x1a>
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004b9:	b8 6e 01 10 f0       	mov    $0xf010016e,%eax
f01004be:	e8 c7 fc ff ff       	call   f010018a <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	f3 c3                	repz ret 

f01004c6 <kbd_intr>:
{
f01004c6:	55                   	push   %ebp
f01004c7:	89 e5                	mov    %esp,%ebp
f01004c9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004cc:	b8 a3 03 10 f0       	mov    $0xf01003a3,%eax
f01004d1:	e8 b4 fc ff ff       	call   f010018a <cons_intr>
}
f01004d6:	c9                   	leave  
f01004d7:	c3                   	ret    

f01004d8 <cons_getc>:
{
f01004d8:	55                   	push   %ebp
f01004d9:	89 e5                	mov    %esp,%ebp
f01004db:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004de:	e8 c7 ff ff ff       	call   f01004aa <serial_intr>
	kbd_intr();
f01004e3:	e8 de ff ff ff       	call   f01004c6 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004e8:	8b 15 60 df 17 f0    	mov    0xf017df60,%edx
f01004ee:	3b 15 64 df 17 f0    	cmp    0xf017df64,%edx
f01004f4:	74 20                	je     f0100516 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004f6:	0f b6 82 60 dd 17 f0 	movzbl -0xfe822a0(%edx),%eax
f01004fd:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f0100500:	81 fa 00 02 00 00    	cmp    $0x200,%edx
		c = cons.buf[cons.rpos++];
f0100506:	b9 00 00 00 00       	mov    $0x0,%ecx
f010050b:	0f 44 d1             	cmove  %ecx,%edx
f010050e:	89 15 60 df 17 f0    	mov    %edx,0xf017df60
f0100514:	eb 05                	jmp    f010051b <cons_getc+0x43>
	return 0;
f0100516:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051b:	c9                   	leave  
f010051c:	c3                   	ret    

f010051d <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010051d:	55                   	push   %ebp
f010051e:	89 e5                	mov    %esp,%ebp
f0100520:	57                   	push   %edi
f0100521:	56                   	push   %esi
f0100522:	53                   	push   %ebx
f0100523:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100526:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100534:	5a a5 
	if (*cp != 0xA55A) {
f0100536:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100541:	74 11                	je     f0100554 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100543:	c7 05 6c df 17 f0 b4 	movl   $0x3b4,0xf017df6c
f010054a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054d:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100552:	eb 16                	jmp    f010056a <cons_init+0x4d>
		*cp = was;
f0100554:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055b:	c7 05 6c df 17 f0 d4 	movl   $0x3d4,0xf017df6c
f0100562:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100565:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f010056a:	8b 0d 6c df 17 f0    	mov    0xf017df6c,%ecx
f0100570:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100575:	89 ca                	mov    %ecx,%edx
f0100577:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100578:	8d 59 01             	lea    0x1(%ecx),%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057b:	89 da                	mov    %ebx,%edx
f010057d:	ec                   	in     (%dx),%al
f010057e:	0f b6 f0             	movzbl %al,%esi
f0100581:	c1 e6 08             	shl    $0x8,%esi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100584:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100589:	89 ca                	mov    %ecx,%edx
f010058b:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058c:	89 da                	mov    %ebx,%edx
f010058e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010058f:	89 3d 70 df 17 f0    	mov    %edi,0xf017df70
	pos |= inb(addr_6845 + 1);
f0100595:	0f b6 d8             	movzbl %al,%ebx
f0100598:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010059a:	66 89 35 74 df 17 f0 	mov    %si,0xf017df74
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a1:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ab:	89 f2                	mov    %esi,%edx
f01005ad:	ee                   	out    %al,(%dx)
f01005ae:	b2 fb                	mov    $0xfb,%dl
f01005b0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bb:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c0:	89 da                	mov    %ebx,%edx
f01005c2:	ee                   	out    %al,(%dx)
f01005c3:	b2 f9                	mov    $0xf9,%dl
f01005c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	b2 fb                	mov    $0xfb,%dl
f01005cd:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d2:	ee                   	out    %al,(%dx)
f01005d3:	b2 fc                	mov    $0xfc,%dl
f01005d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005da:	ee                   	out    %al,(%dx)
f01005db:	b2 f9                	mov    $0xf9,%dl
f01005dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e2:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e3:	b2 fd                	mov    $0xfd,%dl
f01005e5:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e6:	3c ff                	cmp    $0xff,%al
f01005e8:	0f 95 c1             	setne  %cl
f01005eb:	88 0d 40 dd 17 f0    	mov    %cl,0xf017dd40
f01005f1:	89 f2                	mov    %esi,%edx
f01005f3:	ec                   	in     (%dx),%al
f01005f4:	89 da                	mov    %ebx,%edx
f01005f6:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f7:	84 c9                	test   %cl,%cl
f01005f9:	75 0c                	jne    f0100607 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005fb:	c7 04 24 19 53 10 f0 	movl   $0xf0105319,(%esp)
f0100602:	e8 32 32 00 00       	call   f0103839 <cprintf>
}
f0100607:	83 c4 1c             	add    $0x1c,%esp
f010060a:	5b                   	pop    %ebx
f010060b:	5e                   	pop    %esi
f010060c:	5f                   	pop    %edi
f010060d:	5d                   	pop    %ebp
f010060e:	c3                   	ret    

f010060f <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010060f:	55                   	push   %ebp
f0100610:	89 e5                	mov    %esp,%ebp
f0100612:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100615:	8b 45 08             	mov    0x8(%ebp),%eax
f0100618:	e8 ad fb ff ff       	call   f01001ca <cons_putc>
}
f010061d:	c9                   	leave  
f010061e:	c3                   	ret    

f010061f <getchar>:

int
getchar(void)
{
f010061f:	55                   	push   %ebp
f0100620:	89 e5                	mov    %esp,%ebp
f0100622:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100625:	e8 ae fe ff ff       	call   f01004d8 <cons_getc>
f010062a:	85 c0                	test   %eax,%eax
f010062c:	74 f7                	je     f0100625 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010062e:	c9                   	leave  
f010062f:	c3                   	ret    

f0100630 <iscons>:

int
iscons(int fdnum)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100633:	b8 01 00 00 00       	mov    $0x1,%eax
f0100638:	5d                   	pop    %ebp
f0100639:	c3                   	ret    
f010063a:	66 90                	xchg   %ax,%ax
f010063c:	66 90                	xchg   %ax,%ax
f010063e:	66 90                	xchg   %ax,%ax

f0100640 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100646:	c7 04 24 50 55 10 f0 	movl   $0xf0105550,(%esp)
f010064d:	e8 e7 31 00 00       	call   f0103839 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100652:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100659:	00 
f010065a:	c7 04 24 10 56 10 f0 	movl   $0xf0105610,(%esp)
f0100661:	e8 d3 31 00 00       	call   f0103839 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100666:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010066d:	00 
f010066e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100675:	f0 
f0100676:	c7 04 24 38 56 10 f0 	movl   $0xf0105638,(%esp)
f010067d:	e8 b7 31 00 00       	call   f0103839 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100682:	c7 44 24 08 af 52 10 	movl   $0x1052af,0x8(%esp)
f0100689:	00 
f010068a:	c7 44 24 04 af 52 10 	movl   $0xf01052af,0x4(%esp)
f0100691:	f0 
f0100692:	c7 04 24 5c 56 10 f0 	movl   $0xf010565c,(%esp)
f0100699:	e8 9b 31 00 00       	call   f0103839 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010069e:	c7 44 24 08 26 dd 17 	movl   $0x17dd26,0x8(%esp)
f01006a5:	00 
f01006a6:	c7 44 24 04 26 dd 17 	movl   $0xf017dd26,0x4(%esp)
f01006ad:	f0 
f01006ae:	c7 04 24 80 56 10 f0 	movl   $0xf0105680,(%esp)
f01006b5:	e8 7f 31 00 00       	call   f0103839 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ba:	c7 44 24 08 30 ec 17 	movl   $0x17ec30,0x8(%esp)
f01006c1:	00 
f01006c2:	c7 44 24 04 30 ec 17 	movl   $0xf017ec30,0x4(%esp)
f01006c9:	f0 
f01006ca:	c7 04 24 a4 56 10 f0 	movl   $0xf01056a4,(%esp)
f01006d1:	e8 63 31 00 00       	call   f0103839 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d6:	b8 2f f0 17 f0       	mov    $0xf017f02f,%eax
f01006db:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f7:	c7 04 24 c8 56 10 f0 	movl   $0xf01056c8,(%esp)
f01006fe:	e8 36 31 00 00       	call   f0103839 <cprintf>
	return 0;
}
f0100703:	b8 00 00 00 00       	mov    $0x0,%eax
f0100708:	c9                   	leave  
f0100709:	c3                   	ret    

f010070a <mon_help>:
{
f010070a:	55                   	push   %ebp
f010070b:	89 e5                	mov    %esp,%ebp
f010070d:	56                   	push   %esi
f010070e:	53                   	push   %ebx
f010070f:	83 ec 10             	sub    $0x10,%esp
f0100712:	bb e4 57 10 f0       	mov    $0xf01057e4,%ebx
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100717:	be 08 58 10 f0       	mov    $0xf0105808,%esi
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010071c:	8b 03                	mov    (%ebx),%eax
f010071e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100722:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100725:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100729:	c7 04 24 69 55 10 f0 	movl   $0xf0105569,(%esp)
f0100730:	e8 04 31 00 00       	call   f0103839 <cprintf>
f0100735:	83 c3 0c             	add    $0xc,%ebx
	for (i = 0; i < NCOMMANDS; i++)
f0100738:	39 f3                	cmp    %esi,%ebx
f010073a:	75 e0                	jne    f010071c <mon_help+0x12>
}
f010073c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100741:	83 c4 10             	add    $0x10,%esp
f0100744:	5b                   	pop    %ebx
f0100745:	5e                   	pop    %esi
f0100746:	5d                   	pop    %ebp
f0100747:	c3                   	ret    

f0100748 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100748:	55                   	push   %ebp
f0100749:	89 e5                	mov    %esp,%ebp
f010074b:	57                   	push   %edi
f010074c:	56                   	push   %esi
f010074d:	53                   	push   %ebx
f010074e:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	// Read ebp of mon_backtrace()
	unsigned int *ebp = (unsigned int *) read_ebp();
f0100751:	89 eb                	mov    %ebp,%ebx
	// The first five args of the current function
	unsigned int args[5];
	cprintf("Stack backtrace:\n");
f0100753:	c7 04 24 72 55 10 f0 	movl   $0xf0105572,(%esp)
f010075a:	e8 da 30 00 00       	call   f0103839 <cprintf>
		args[3] = (unsigned int) *(ebp + 5);
		args[4] = (unsigned int) *(ebp + 6);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip,
			args[0], args[1], args[2], args[3], args[4]);
		struct Eipdebuginfo info;
		debuginfo_eip((uintptr_t) eip, &info);
f010075f:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while(ebp) {
f0100762:	eb 77                	jmp    f01007db <mon_backtrace+0x93>
		unsigned int eip = (unsigned int) *(ebp + 1);
f0100764:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip,
f0100767:	8b 43 18             	mov    0x18(%ebx),%eax
f010076a:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f010076e:	8b 43 14             	mov    0x14(%ebx),%eax
f0100771:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100775:	8b 43 10             	mov    0x10(%ebx),%eax
f0100778:	89 44 24 14          	mov    %eax,0x14(%esp)
f010077c:	8b 43 0c             	mov    0xc(%ebx),%eax
f010077f:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100783:	8b 43 08             	mov    0x8(%ebx),%eax
f0100786:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010078a:	89 74 24 08          	mov    %esi,0x8(%esp)
f010078e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100792:	c7 04 24 f4 56 10 f0 	movl   $0xf01056f4,(%esp)
f0100799:	e8 9b 30 00 00       	call   f0103839 <cprintf>
		debuginfo_eip((uintptr_t) eip, &info);
f010079e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007a2:	89 34 24             	mov    %esi,(%esp)
f01007a5:	e8 c7 3a 00 00       	call   f0104271 <debuginfo_eip>
		cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line,
f01007aa:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01007ad:	89 74 24 14          	mov    %esi,0x14(%esp)
f01007b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007b4:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007b8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007c6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cd:	c7 04 24 84 55 10 f0 	movl   $0xf0105584,(%esp)
f01007d4:	e8 60 30 00 00       	call   f0103839 <cprintf>
			info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = (unsigned int *) *ebp;
f01007d9:	8b 1b                	mov    (%ebx),%ebx
	while(ebp) {
f01007db:	85 db                	test   %ebx,%ebx
f01007dd:	75 85                	jne    f0100764 <mon_backtrace+0x1c>
	}
	return 0;
}
f01007df:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e4:	83 c4 4c             	add    $0x4c,%esp
f01007e7:	5b                   	pop    %ebx
f01007e8:	5e                   	pop    %esi
f01007e9:	5f                   	pop    %edi
f01007ea:	5d                   	pop    %ebp
f01007eb:	c3                   	ret    

f01007ec <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ec:	55                   	push   %ebp
f01007ed:	89 e5                	mov    %esp,%ebp
f01007ef:	57                   	push   %edi
f01007f0:	56                   	push   %esi
f01007f1:	53                   	push   %ebx
f01007f2:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007f5:	c7 04 24 2c 57 10 f0 	movl   $0xf010572c,(%esp)
f01007fc:	e8 38 30 00 00       	call   f0103839 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100801:	c7 04 24 50 57 10 f0 	movl   $0xf0105750,(%esp)
f0100808:	e8 2c 30 00 00       	call   f0103839 <cprintf>

	if (tf != NULL)
f010080d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100811:	74 0b                	je     f010081e <monitor+0x32>
		print_trapframe(tf);
f0100813:	8b 45 08             	mov    0x8(%ebp),%eax
f0100816:	89 04 24             	mov    %eax,(%esp)
f0100819:	e8 81 34 00 00       	call   f0103c9f <print_trapframe>

	while (1) {
		buf = readline("K> ");
f010081e:	c7 04 24 9d 55 10 f0 	movl   $0xf010559d,(%esp)
f0100825:	e8 26 43 00 00       	call   f0104b50 <readline>
f010082a:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f010082c:	85 c0                	test   %eax,%eax
f010082e:	74 ee                	je     f010081e <monitor+0x32>
	argv[argc] = 0;
f0100830:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100837:	bb 00 00 00 00       	mov    $0x0,%ebx
f010083c:	eb 06                	jmp    f0100844 <monitor+0x58>
			*buf++ = 0;
f010083e:	c6 06 00             	movb   $0x0,(%esi)
f0100841:	83 c6 01             	add    $0x1,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100844:	0f b6 06             	movzbl (%esi),%eax
f0100847:	84 c0                	test   %al,%al
f0100849:	74 63                	je     f01008ae <monitor+0xc2>
f010084b:	0f be c0             	movsbl %al,%eax
f010084e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100852:	c7 04 24 a1 55 10 f0 	movl   $0xf01055a1,(%esp)
f0100859:	e8 08 45 00 00       	call   f0104d66 <strchr>
f010085e:	85 c0                	test   %eax,%eax
f0100860:	75 dc                	jne    f010083e <monitor+0x52>
		if (*buf == 0)
f0100862:	80 3e 00             	cmpb   $0x0,(%esi)
f0100865:	74 47                	je     f01008ae <monitor+0xc2>
		if (argc == MAXARGS-1) {
f0100867:	83 fb 0f             	cmp    $0xf,%ebx
f010086a:	75 16                	jne    f0100882 <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100873:	00 
f0100874:	c7 04 24 a6 55 10 f0 	movl   $0xf01055a6,(%esp)
f010087b:	e8 b9 2f 00 00       	call   f0103839 <cprintf>
f0100880:	eb 9c                	jmp    f010081e <monitor+0x32>
		argv[argc++] = buf;
f0100882:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100886:	83 c3 01             	add    $0x1,%ebx
f0100889:	eb 03                	jmp    f010088e <monitor+0xa2>
			buf++;
f010088b:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010088e:	0f b6 06             	movzbl (%esi),%eax
f0100891:	84 c0                	test   %al,%al
f0100893:	74 af                	je     f0100844 <monitor+0x58>
f0100895:	0f be c0             	movsbl %al,%eax
f0100898:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089c:	c7 04 24 a1 55 10 f0 	movl   $0xf01055a1,(%esp)
f01008a3:	e8 be 44 00 00       	call   f0104d66 <strchr>
f01008a8:	85 c0                	test   %eax,%eax
f01008aa:	74 df                	je     f010088b <monitor+0x9f>
f01008ac:	eb 96                	jmp    f0100844 <monitor+0x58>
	argv[argc] = 0;
f01008ae:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f01008b5:	00 
	if (argc == 0)
f01008b6:	85 db                	test   %ebx,%ebx
f01008b8:	0f 84 60 ff ff ff    	je     f010081e <monitor+0x32>
f01008be:	bf e0 57 10 f0       	mov    $0xf01057e0,%edi
f01008c3:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c8:	8b 07                	mov    (%edi),%eax
f01008ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ce:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 2f 44 00 00       	call   f0104d08 <strcmp>
f01008d9:	85 c0                	test   %eax,%eax
f01008db:	75 24                	jne    f0100901 <monitor+0x115>
			return commands[i].func(argc, argv, tf);
f01008dd:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008e0:	8b 55 08             	mov    0x8(%ebp),%edx
f01008e3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008e7:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008ea:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008ee:	89 1c 24             	mov    %ebx,(%esp)
f01008f1:	ff 14 85 e8 57 10 f0 	call   *-0xfefa818(,%eax,4)
			if (runcmd(buf, tf) < 0)
f01008f8:	85 c0                	test   %eax,%eax
f01008fa:	78 28                	js     f0100924 <monitor+0x138>
f01008fc:	e9 1d ff ff ff       	jmp    f010081e <monitor+0x32>
	for (i = 0; i < NCOMMANDS; i++) {
f0100901:	83 c6 01             	add    $0x1,%esi
f0100904:	83 c7 0c             	add    $0xc,%edi
f0100907:	83 fe 03             	cmp    $0x3,%esi
f010090a:	75 bc                	jne    f01008c8 <monitor+0xdc>
	cprintf("Unknown command '%s'\n", argv[0]);
f010090c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010090f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100913:	c7 04 24 c3 55 10 f0 	movl   $0xf01055c3,(%esp)
f010091a:	e8 1a 2f 00 00       	call   f0103839 <cprintf>
f010091f:	e9 fa fe ff ff       	jmp    f010081e <monitor+0x32>
				break;
	}
}
f0100924:	83 c4 5c             	add    $0x5c,%esp
f0100927:	5b                   	pop    %ebx
f0100928:	5e                   	pop    %esi
f0100929:	5f                   	pop    %edi
f010092a:	5d                   	pop    %ebp
f010092b:	c3                   	ret    
f010092c:	66 90                	xchg   %ax,%ax
f010092e:	66 90                	xchg   %ax,%ax

f0100930 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100930:	89 d1                	mov    %edx,%ecx
f0100932:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100935:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100938:	a8 01                	test   $0x1,%al
f010093a:	74 5d                	je     f0100999 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010093c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100941:	89 c1                	mov    %eax,%ecx
f0100943:	c1 e9 0c             	shr    $0xc,%ecx
f0100946:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f010094c:	72 26                	jb     f0100974 <check_va2pa+0x44>
{
f010094e:	55                   	push   %ebp
f010094f:	89 e5                	mov    %esp,%ebp
f0100951:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100954:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100958:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f010095f:	f0 
f0100960:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0100967:	00 
f0100968:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010096f:	e8 42 f7 ff ff       	call   f01000b6 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100974:	c1 ea 0c             	shr    $0xc,%edx
f0100977:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010097d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100984:	89 c2                	mov    %eax,%edx
f0100986:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100989:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010098e:	85 d2                	test   %edx,%edx
f0100990:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100995:	0f 44 c2             	cmove  %edx,%eax
f0100998:	c3                   	ret    
		return ~0;
f0100999:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010099e:	c3                   	ret    

f010099f <boot_alloc>:
{
f010099f:	55                   	push   %ebp
f01009a0:	89 e5                	mov    %esp,%ebp
f01009a2:	83 ec 18             	sub    $0x18,%esp
f01009a5:	89 c2                	mov    %eax,%edx
	if (!nextfree) {
f01009a7:	83 3d 7c df 17 f0 00 	cmpl   $0x0,0xf017df7c
f01009ae:	75 0f                	jne    f01009bf <boot_alloc+0x20>
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009b0:	b8 2f fc 17 f0       	mov    $0xf017fc2f,%eax
f01009b5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ba:	a3 7c df 17 f0       	mov    %eax,0xf017df7c
		return nextfree;
f01009bf:	a1 7c df 17 f0       	mov    0xf017df7c,%eax
	if(n==0)
f01009c4:	85 d2                	test   %edx,%edx
f01009c6:	74 74                	je     f0100a3c <boot_alloc+0x9d>
	result = nextfree;
f01009c8:	a1 7c df 17 f0       	mov    0xf017df7c,%eax
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f01009cd:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009d4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009da:	89 15 7c df 17 f0    	mov    %edx,0xf017df7c
	if ((uint32_t)kva < KERNBASE)
f01009e0:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01009e6:	77 20                	ja     f0100a08 <boot_alloc+0x69>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01009e8:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01009ec:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f01009f3:	f0 
f01009f4:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
f01009fb:	00 
f01009fc:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100a03:	e8 ae f6 ff ff       	call   f01000b6 <_panic>
	if((uint32_t)PADDR(nextfree) > npages*(PGSIZE)) {
f0100a08:	8b 0d 24 ec 17 f0    	mov    0xf017ec24,%ecx
f0100a0e:	c1 e1 0c             	shl    $0xc,%ecx
	return (physaddr_t)kva - KERNBASE;
f0100a11:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100a17:	39 d1                	cmp    %edx,%ecx
f0100a19:	73 21                	jae    f0100a3c <boot_alloc+0x9d>
		nextfree = result;
f0100a1b:	a3 7c df 17 f0       	mov    %eax,0xf017df7c
		panic("Out of memory!\n");
f0100a20:	c7 44 24 08 15 60 10 	movl   $0xf0106015,0x8(%esp)
f0100a27:	f0 
f0100a28:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100a2f:	00 
f0100a30:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100a37:	e8 7a f6 ff ff       	call   f01000b6 <_panic>
}
f0100a3c:	c9                   	leave  
f0100a3d:	c3                   	ret    

f0100a3e <nvram_read>:
{
f0100a3e:	55                   	push   %ebp
f0100a3f:	89 e5                	mov    %esp,%ebp
f0100a41:	83 ec 18             	sub    $0x18,%esp
f0100a44:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a47:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a4a:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a4c:	89 04 24             	mov    %eax,(%esp)
f0100a4f:	e8 74 2d 00 00       	call   f01037c8 <mc146818_read>
f0100a54:	89 c6                	mov    %eax,%esi
f0100a56:	83 c3 01             	add    $0x1,%ebx
f0100a59:	89 1c 24             	mov    %ebx,(%esp)
f0100a5c:	e8 67 2d 00 00       	call   f01037c8 <mc146818_read>
f0100a61:	c1 e0 08             	shl    $0x8,%eax
f0100a64:	09 f0                	or     %esi,%eax
}
f0100a66:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a69:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a6c:	89 ec                	mov    %ebp,%esp
f0100a6e:	5d                   	pop    %ebp
f0100a6f:	c3                   	ret    

f0100a70 <check_page_free_list>:
{
f0100a70:	55                   	push   %ebp
f0100a71:	89 e5                	mov    %esp,%ebp
f0100a73:	57                   	push   %edi
f0100a74:	56                   	push   %esi
f0100a75:	53                   	push   %ebx
f0100a76:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a79:	84 c0                	test   %al,%al
f0100a7b:	0f 85 04 03 00 00    	jne    f0100d85 <check_page_free_list+0x315>
f0100a81:	e9 11 03 00 00       	jmp    f0100d97 <check_page_free_list+0x327>
		panic("'page_free_list' is a null pointer!");
f0100a86:	c7 44 24 08 4c 58 10 	movl   $0xf010584c,0x8(%esp)
f0100a8d:	f0 
f0100a8e:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0100a95:	00 
f0100a96:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100a9d:	e8 14 f6 ff ff       	call   f01000b6 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aa2:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aa5:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100aa8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aab:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aae:	89 c2                	mov    %eax,%edx
f0100ab0:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ab6:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100abc:	0f 95 c2             	setne  %dl
f0100abf:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ac2:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ac6:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ac8:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acc:	8b 00                	mov    (%eax),%eax
f0100ace:	85 c0                	test   %eax,%eax
f0100ad0:	75 dc                	jne    f0100aae <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100ad2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100adb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ade:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ae1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ae3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae6:	a3 80 df 17 f0       	mov    %eax,0xf017df80
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aeb:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100af0:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100af6:	eb 63                	jmp    f0100b5b <check_page_free_list+0xeb>
f0100af8:	89 d8                	mov    %ebx,%eax
f0100afa:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100b00:	c1 f8 03             	sar    $0x3,%eax
f0100b03:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b06:	89 c2                	mov    %eax,%edx
f0100b08:	c1 ea 16             	shr    $0x16,%edx
f0100b0b:	39 f2                	cmp    %esi,%edx
f0100b0d:	73 4a                	jae    f0100b59 <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100b0f:	89 c2                	mov    %eax,%edx
f0100b11:	c1 ea 0c             	shr    $0xc,%edx
f0100b14:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100b1a:	72 20                	jb     f0100b3c <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b20:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0100b27:	f0 
f0100b28:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b2f:	00 
f0100b30:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0100b37:	e8 7a f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b3c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b43:	00 
f0100b44:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b4b:	00 
	return (void *)(pa + KERNBASE);
f0100b4c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b51:	89 04 24             	mov    %eax,(%esp)
f0100b54:	e8 4a 42 00 00       	call   f0104da3 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b59:	8b 1b                	mov    (%ebx),%ebx
f0100b5b:	85 db                	test   %ebx,%ebx
f0100b5d:	75 99                	jne    f0100af8 <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100b5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b64:	e8 36 fe ff ff       	call   f010099f <boot_alloc>
f0100b69:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b6c:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
		assert(pp >= pages);
f0100b72:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
		assert(pp < pages + npages);
f0100b78:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0100b7d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b80:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b86:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b89:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b8e:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b91:	e9 97 01 00 00       	jmp    f0100d2d <check_page_free_list+0x2bd>
		assert(pp >= pages);
f0100b96:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b99:	73 24                	jae    f0100bbf <check_page_free_list+0x14f>
f0100b9b:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f0100ba2:	f0 
f0100ba3:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100baa:	f0 
f0100bab:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0100bb2:	00 
f0100bb3:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100bba:	e8 f7 f4 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100bbf:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bc2:	72 24                	jb     f0100be8 <check_page_free_list+0x178>
f0100bc4:	c7 44 24 0c 54 60 10 	movl   $0xf0106054,0xc(%esp)
f0100bcb:	f0 
f0100bcc:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100bd3:	f0 
f0100bd4:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
f0100bdb:	00 
f0100bdc:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100be3:	e8 ce f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100be8:	89 d0                	mov    %edx,%eax
f0100bea:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bed:	a8 07                	test   $0x7,%al
f0100bef:	74 24                	je     f0100c15 <check_page_free_list+0x1a5>
f0100bf1:	c7 44 24 0c 70 58 10 	movl   $0xf0105870,0xc(%esp)
f0100bf8:	f0 
f0100bf9:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100c00:	f0 
f0100c01:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0100c08:	00 
f0100c09:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100c10:	e8 a1 f4 ff ff       	call   f01000b6 <_panic>
	return (pp - pages) << PGSHIFT;
f0100c15:	c1 f8 03             	sar    $0x3,%eax
f0100c18:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100c1b:	85 c0                	test   %eax,%eax
f0100c1d:	75 24                	jne    f0100c43 <check_page_free_list+0x1d3>
f0100c1f:	c7 44 24 0c 68 60 10 	movl   $0xf0106068,0xc(%esp)
f0100c26:	f0 
f0100c27:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100c2e:	f0 
f0100c2f:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0100c36:	00 
f0100c37:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100c3e:	e8 73 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c43:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c48:	75 24                	jne    f0100c6e <check_page_free_list+0x1fe>
f0100c4a:	c7 44 24 0c 79 60 10 	movl   $0xf0106079,0xc(%esp)
f0100c51:	f0 
f0100c52:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100c59:	f0 
f0100c5a:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0100c61:	00 
f0100c62:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100c69:	e8 48 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c6e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c73:	75 24                	jne    f0100c99 <check_page_free_list+0x229>
f0100c75:	c7 44 24 0c a4 58 10 	movl   $0xf01058a4,0xc(%esp)
f0100c7c:	f0 
f0100c7d:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100c84:	f0 
f0100c85:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f0100c8c:	00 
f0100c8d:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100c94:	e8 1d f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c99:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c9e:	75 24                	jne    f0100cc4 <check_page_free_list+0x254>
f0100ca0:	c7 44 24 0c 92 60 10 	movl   $0xf0106092,0xc(%esp)
f0100ca7:	f0 
f0100ca8:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100caf:	f0 
f0100cb0:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0100cb7:	00 
f0100cb8:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100cbf:	e8 f2 f3 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cc4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cc9:	76 58                	jbe    f0100d23 <check_page_free_list+0x2b3>
	if (PGNUM(pa) >= npages)
f0100ccb:	89 c1                	mov    %eax,%ecx
f0100ccd:	c1 e9 0c             	shr    $0xc,%ecx
f0100cd0:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100cd3:	77 20                	ja     f0100cf5 <check_page_free_list+0x285>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cd5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cd9:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0100ce0:	f0 
f0100ce1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ce8:	00 
f0100ce9:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0100cf0:	e8 c1 f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100cf5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cfa:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cfd:	76 29                	jbe    f0100d28 <check_page_free_list+0x2b8>
f0100cff:	c7 44 24 0c c8 58 10 	movl   $0xf01058c8,0xc(%esp)
f0100d06:	f0 
f0100d07:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100d0e:	f0 
f0100d0f:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f0100d16:	00 
f0100d17:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100d1e:	e8 93 f3 ff ff       	call   f01000b6 <_panic>
			++nfree_basemem;
f0100d23:	83 c3 01             	add    $0x1,%ebx
f0100d26:	eb 03                	jmp    f0100d2b <check_page_free_list+0x2bb>
			++nfree_extmem;
f0100d28:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2b:	8b 12                	mov    (%edx),%edx
f0100d2d:	85 d2                	test   %edx,%edx
f0100d2f:	0f 85 61 fe ff ff    	jne    f0100b96 <check_page_free_list+0x126>
	assert(nfree_basemem > 0);
f0100d35:	85 db                	test   %ebx,%ebx
f0100d37:	7f 24                	jg     f0100d5d <check_page_free_list+0x2ed>
f0100d39:	c7 44 24 0c ac 60 10 	movl   $0xf01060ac,0xc(%esp)
f0100d40:	f0 
f0100d41:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100d48:	f0 
f0100d49:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0100d50:	00 
f0100d51:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100d58:	e8 59 f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100d5d:	85 ff                	test   %edi,%edi
f0100d5f:	7f 4d                	jg     f0100dae <check_page_free_list+0x33e>
f0100d61:	c7 44 24 0c be 60 10 	movl   $0xf01060be,0xc(%esp)
f0100d68:	f0 
f0100d69:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0100d70:	f0 
f0100d71:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f0100d78:	00 
f0100d79:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100d80:	e8 31 f3 ff ff       	call   f01000b6 <_panic>
	if (!page_free_list)
f0100d85:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f0100d8a:	85 c0                	test   %eax,%eax
f0100d8c:	0f 85 10 fd ff ff    	jne    f0100aa2 <check_page_free_list+0x32>
f0100d92:	e9 ef fc ff ff       	jmp    f0100a86 <check_page_free_list+0x16>
f0100d97:	83 3d 80 df 17 f0 00 	cmpl   $0x0,0xf017df80
f0100d9e:	0f 84 e2 fc ff ff    	je     f0100a86 <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100da4:	be 00 04 00 00       	mov    $0x400,%esi
f0100da9:	e9 42 fd ff ff       	jmp    f0100af0 <check_page_free_list+0x80>
}
f0100dae:	83 c4 4c             	add    $0x4c,%esp
f0100db1:	5b                   	pop    %ebx
f0100db2:	5e                   	pop    %esi
f0100db3:	5f                   	pop    %edi
f0100db4:	5d                   	pop    %ebp
f0100db5:	c3                   	ret    

f0100db6 <page_init>:
{
f0100db6:	55                   	push   %ebp
f0100db7:	89 e5                	mov    %esp,%ebp
f0100db9:	56                   	push   %esi
f0100dba:	53                   	push   %ebx
f0100dbb:	83 ec 10             	sub    $0x10,%esp
	pages[0].pp_ref = 1;
f0100dbe:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f0100dc3:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++) {
f0100dc9:	8b 35 78 df 17 f0    	mov    0xf017df78,%esi
f0100dcf:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100dd5:	b8 01 00 00 00       	mov    $0x1,%eax
f0100dda:	eb 22                	jmp    f0100dfe <page_init+0x48>
page_init(void)
f0100ddc:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100de3:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
f0100de9:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100df0:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100df3:	8b 1d 2c ec 17 f0    	mov    0xf017ec2c,%ebx
f0100df9:	01 d3                	add    %edx,%ebx
	for (i = 1; i < npages_basemem; i++) {
f0100dfb:	83 c0 01             	add    $0x1,%eax
f0100dfe:	39 f0                	cmp    %esi,%eax
f0100e00:	72 da                	jb     f0100ddc <page_init+0x26>
f0100e02:	89 1d 80 df 17 f0    	mov    %ebx,0xf017df80
		pages[i].pp_ref = 1;
f0100e08:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f0100e0d:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0100e12:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
f0100e19:	83 c3 01             	add    $0x1,%ebx
f0100e1c:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100e22:	75 ee                	jne    f0100e12 <page_init+0x5c>
	size_t first_free_address = PADDR(boot_alloc(0));
f0100e24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e29:	e8 71 fb ff ff       	call   f010099f <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100e2e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e33:	77 20                	ja     f0100e55 <page_init+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e35:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e39:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0100e40:	f0 
f0100e41:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
f0100e48:	00 
f0100e49:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100e50:	e8 61 f2 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e55:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
	for (i = EXTPHYSMEM/PGSIZE; i < first_free_address/PGSIZE; i++) {
f0100e5b:	c1 ea 0c             	shr    $0xc,%edx
		pages[i].pp_ref = 1;
f0100e5e:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
	for (i = EXTPHYSMEM/PGSIZE; i < first_free_address/PGSIZE; i++) {
f0100e63:	eb 0a                	jmp    f0100e6f <page_init+0xb9>
		pages[i].pp_ref = 1;
f0100e65:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = EXTPHYSMEM/PGSIZE; i < first_free_address/PGSIZE; i++) {
f0100e6c:	83 c3 01             	add    $0x1,%ebx
f0100e6f:	39 d3                	cmp    %edx,%ebx
f0100e71:	72 f2                	jb     f0100e65 <page_init+0xaf>
f0100e73:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100e79:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100e80:	eb 1e                	jmp    f0100ea0 <page_init+0xea>
		pages[i].pp_ref = 0;
f0100e82:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
f0100e88:	66 c7 44 01 04 00 00 	movw   $0x0,0x4(%ecx,%eax,1)
		pages[i].pp_link = page_free_list;
f0100e8f:	89 1c 01             	mov    %ebx,(%ecx,%eax,1)
		page_free_list = &pages[i];
f0100e92:	8b 1d 2c ec 17 f0    	mov    0xf017ec2c,%ebx
f0100e98:	01 c3                	add    %eax,%ebx
	for (i = first_free_address/PGSIZE; i < npages; i++) {
f0100e9a:	83 c2 01             	add    $0x1,%edx
f0100e9d:	83 c0 08             	add    $0x8,%eax
f0100ea0:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100ea6:	72 da                	jb     f0100e82 <page_init+0xcc>
f0100ea8:	89 1d 80 df 17 f0    	mov    %ebx,0xf017df80
}
f0100eae:	83 c4 10             	add    $0x10,%esp
f0100eb1:	5b                   	pop    %ebx
f0100eb2:	5e                   	pop    %esi
f0100eb3:	5d                   	pop    %ebp
f0100eb4:	c3                   	ret    

f0100eb5 <page_alloc>:
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	53                   	push   %ebx
f0100eb9:	83 ec 14             	sub    $0x14,%esp
	if(page_free_list == NULL)
f0100ebc:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100ec2:	85 db                	test   %ebx,%ebx
f0100ec4:	74 6b                	je     f0100f31 <page_alloc+0x7c>
	page_free_list = page->pp_link;
f0100ec6:	8b 03                	mov    (%ebx),%eax
f0100ec8:	a3 80 df 17 f0       	mov    %eax,0xf017df80
	page->pp_link = 0;
f0100ecd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100ed3:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ed7:	74 58                	je     f0100f31 <page_alloc+0x7c>
	return (pp - pages) << PGSHIFT;
f0100ed9:	89 d8                	mov    %ebx,%eax
f0100edb:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100ee1:	c1 f8 03             	sar    $0x3,%eax
f0100ee4:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100ee7:	89 c2                	mov    %eax,%edx
f0100ee9:	c1 ea 0c             	shr    $0xc,%edx
f0100eec:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100ef2:	72 20                	jb     f0100f14 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ef4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ef8:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0100eff:	f0 
f0100f00:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f07:	00 
f0100f08:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0100f0f:	e8 a2 f1 ff ff       	call   f01000b6 <_panic>
		memset(page2kva(page), 0, PGSIZE);
f0100f14:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f1b:	00 
f0100f1c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f23:	00 
	return (void *)(pa + KERNBASE);
f0100f24:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f29:	89 04 24             	mov    %eax,(%esp)
f0100f2c:	e8 72 3e 00 00       	call   f0104da3 <memset>
}
f0100f31:	89 d8                	mov    %ebx,%eax
f0100f33:	83 c4 14             	add    $0x14,%esp
f0100f36:	5b                   	pop    %ebx
f0100f37:	5d                   	pop    %ebp
f0100f38:	c3                   	ret    

f0100f39 <page_free>:
{
f0100f39:	55                   	push   %ebp
f0100f3a:	89 e5                	mov    %esp,%ebp
f0100f3c:	83 ec 18             	sub    $0x18,%esp
f0100f3f:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref > 0 || pp->pp_link != NULL) {
f0100f42:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f47:	75 05                	jne    f0100f4e <page_free+0x15>
f0100f49:	83 38 00             	cmpl   $0x0,(%eax)
f0100f4c:	74 1c                	je     f0100f6a <page_free+0x31>
		panic("Double check failed when dealloc page");
f0100f4e:	c7 44 24 08 10 59 10 	movl   $0xf0105910,0x8(%esp)
f0100f55:	f0 
f0100f56:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0100f5d:	00 
f0100f5e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100f65:	e8 4c f1 ff ff       	call   f01000b6 <_panic>
	pp->pp_link = page_free_list;
f0100f6a:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
f0100f70:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f72:	a3 80 df 17 f0       	mov    %eax,0xf017df80
}
f0100f77:	c9                   	leave  
f0100f78:	c3                   	ret    

f0100f79 <page_decref>:
{
f0100f79:	55                   	push   %ebp
f0100f7a:	89 e5                	mov    %esp,%ebp
f0100f7c:	83 ec 18             	sub    $0x18,%esp
f0100f7f:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f82:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f86:	83 ea 01             	sub    $0x1,%edx
f0100f89:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f8d:	66 85 d2             	test   %dx,%dx
f0100f90:	75 08                	jne    f0100f9a <page_decref+0x21>
		page_free(pp);
f0100f92:	89 04 24             	mov    %eax,(%esp)
f0100f95:	e8 9f ff ff ff       	call   f0100f39 <page_free>
}
f0100f9a:	c9                   	leave  
f0100f9b:	c3                   	ret    

f0100f9c <pgdir_walk>:
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	56                   	push   %esi
f0100fa0:	53                   	push   %ebx
f0100fa1:	83 ec 10             	sub    $0x10,%esp
f0100fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint32_t page_tab_idx = PTX(va);
f0100fa7:	89 c3                	mov    %eax,%ebx
f0100fa9:	c1 eb 0c             	shr    $0xc,%ebx
f0100fac:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
	uint32_t page_dir_idx = PDX(va);
f0100fb2:	c1 e8 16             	shr    $0x16,%eax
	if (pgdir[page_dir_idx] & PTE_P) {
f0100fb5:	8d 34 85 00 00 00 00 	lea    0x0(,%eax,4),%esi
f0100fbc:	03 75 08             	add    0x8(%ebp),%esi
f0100fbf:	8b 06                	mov    (%esi),%eax
f0100fc1:	a8 01                	test   $0x1,%al
f0100fc3:	74 3d                	je     f0101002 <pgdir_walk+0x66>
		pgtab = KADDR(PTE_ADDR(pgdir[page_dir_idx]));
f0100fc5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100fca:	89 c2                	mov    %eax,%edx
f0100fcc:	c1 ea 0c             	shr    $0xc,%edx
f0100fcf:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100fd5:	72 20                	jb     f0100ff7 <pgdir_walk+0x5b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fdb:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0100fe2:	f0 
f0100fe3:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f0100fea:	00 
f0100feb:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0100ff2:	e8 bf f0 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100ff7:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100ffd:	e9 8d 00 00 00       	jmp    f010108f <pgdir_walk+0xf3>
		if (create) {
f0101002:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101006:	0f 84 88 00 00 00    	je     f0101094 <pgdir_walk+0xf8>
			struct PageInfo *new_pageInfo = page_alloc(ALLOC_ZERO);
f010100c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101013:	e8 9d fe ff ff       	call   f0100eb5 <page_alloc>
			if (new_pageInfo) {
f0101018:	85 c0                	test   %eax,%eax
f010101a:	74 7f                	je     f010109b <pgdir_walk+0xff>
				new_pageInfo->pp_ref += 1;
f010101c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101021:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0101027:	c1 f8 03             	sar    $0x3,%eax
f010102a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010102d:	89 c2                	mov    %eax,%edx
f010102f:	c1 ea 0c             	shr    $0xc,%edx
f0101032:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0101038:	72 20                	jb     f010105a <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010103a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010103e:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0101045:	f0 
f0101046:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010104d:	00 
f010104e:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0101055:	e8 5c f0 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010105a:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0101060:	89 ca                	mov    %ecx,%edx
	if ((uint32_t)kva < KERNBASE)
f0101062:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0101068:	77 20                	ja     f010108a <pgdir_walk+0xee>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010106a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010106e:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0101075:	f0 
f0101076:	c7 44 24 04 9d 01 00 	movl   $0x19d,0x4(%esp)
f010107d:	00 
f010107e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101085:	e8 2c f0 ff ff       	call   f01000b6 <_panic>
				pgdir[page_dir_idx] = PADDR(pgtab) | PTE_P | PTE_W | PTE_U;
f010108a:	83 c8 07             	or     $0x7,%eax
f010108d:	89 06                	mov    %eax,(%esi)
	return &pgtab[page_tab_idx];
f010108f:	8d 04 9a             	lea    (%edx,%ebx,4),%eax
f0101092:	eb 0c                	jmp    f01010a0 <pgdir_walk+0x104>
			return NULL;
f0101094:	b8 00 00 00 00       	mov    $0x0,%eax
f0101099:	eb 05                	jmp    f01010a0 <pgdir_walk+0x104>
				return NULL;
f010109b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010a0:	83 c4 10             	add    $0x10,%esp
f01010a3:	5b                   	pop    %ebx
f01010a4:	5e                   	pop    %esi
f01010a5:	5d                   	pop    %ebp
f01010a6:	c3                   	ret    

f01010a7 <boot_map_region>:
{
f01010a7:	55                   	push   %ebp
f01010a8:	89 e5                	mov    %esp,%ebp
f01010aa:	57                   	push   %edi
f01010ab:	56                   	push   %esi
f01010ac:	53                   	push   %ebx
f01010ad:	83 ec 2c             	sub    $0x2c,%esp
f01010b0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010b3:	89 d7                	mov    %edx,%edi
	size_t pg_num = PGNUM(size);
f01010b5:	89 c8                	mov    %ecx,%eax
f01010b7:	c1 e8 0c             	shr    $0xc,%eax
f01010ba:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("map region size = %d, %d pages\n", size, pg_num);
f01010bd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010c1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010c5:	c7 04 24 38 59 10 f0 	movl   $0xf0105938,(%esp)
f01010cc:	e8 68 27 00 00       	call   f0103839 <cprintf>
	for (i = 0; i<pg_num; i++)
f01010d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01010d4:	be 00 00 00 00       	mov    $0x0,%esi
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01010d9:	29 df                	sub    %ebx,%edi
		*pgtab = pa | perm | PTE_P;
f01010db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010de:	83 c8 01             	or     $0x1,%eax
f01010e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i<pg_num; i++)
f01010e4:	eb 2e                	jmp    f0101114 <boot_map_region+0x6d>
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f01010e6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010ed:	00 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f01010ee:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f01010f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010f5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010f8:	89 04 24             	mov    %eax,(%esp)
f01010fb:	e8 9c fe ff ff       	call   f0100f9c <pgdir_walk>
		if (!pgtab) {
f0101100:	85 c0                	test   %eax,%eax
f0101102:	74 15                	je     f0101119 <boot_map_region+0x72>
		*pgtab = pa | perm | PTE_P;
f0101104:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101107:	09 da                	or     %ebx,%edx
f0101109:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f010110b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i<pg_num; i++)
f0101111:	83 c6 01             	add    $0x1,%esi
f0101114:	3b 75 e0             	cmp    -0x20(%ebp),%esi
f0101117:	75 cd                	jne    f01010e6 <boot_map_region+0x3f>
}
f0101119:	83 c4 2c             	add    $0x2c,%esp
f010111c:	5b                   	pop    %ebx
f010111d:	5e                   	pop    %esi
f010111e:	5f                   	pop    %edi
f010111f:	5d                   	pop    %ebp
f0101120:	c3                   	ret    

f0101121 <page_lookup>:
{
f0101121:	55                   	push   %ebp
f0101122:	89 e5                	mov    %esp,%ebp
f0101124:	53                   	push   %ebx
f0101125:	83 ec 14             	sub    $0x14,%esp
f0101128:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgtab = pgdir_walk(pgdir, va, 0);
f010112b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101132:	00 
f0101133:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101136:	89 44 24 04          	mov    %eax,0x4(%esp)
f010113a:	8b 45 08             	mov    0x8(%ebp),%eax
f010113d:	89 04 24             	mov    %eax,(%esp)
f0101140:	e8 57 fe ff ff       	call   f0100f9c <pgdir_walk>
	if (!pgtab) {
f0101145:	85 c0                	test   %eax,%eax
f0101147:	74 3a                	je     f0101183 <page_lookup+0x62>
	if (pte_store) {
f0101149:	85 db                	test   %ebx,%ebx
f010114b:	74 02                	je     f010114f <page_lookup+0x2e>
		*pte_store = pgtab;
f010114d:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pgtab));
f010114f:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101151:	c1 e8 0c             	shr    $0xc,%eax
f0101154:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f010115a:	72 1c                	jb     f0101178 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f010115c:	c7 44 24 08 58 59 10 	movl   $0xf0105958,0x8(%esp)
f0101163:	f0 
f0101164:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010116b:	00 
f010116c:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0101173:	e8 3e ef ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0101178:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
f010117e:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101181:	eb 05                	jmp    f0101188 <page_lookup+0x67>
		return NULL;
f0101183:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101188:	83 c4 14             	add    $0x14,%esp
f010118b:	5b                   	pop    %ebx
f010118c:	5d                   	pop    %ebp
f010118d:	c3                   	ret    

f010118e <tlb_invalidate>:
{
f010118e:	55                   	push   %ebp
f010118f:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101191:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101194:	0f 01 38             	invlpg (%eax)
}
f0101197:	5d                   	pop    %ebp
f0101198:	c3                   	ret    

f0101199 <page_remove>:
{
f0101199:	55                   	push   %ebp
f010119a:	89 e5                	mov    %esp,%ebp
f010119c:	83 ec 28             	sub    $0x28,%esp
f010119f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01011a2:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01011a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011a8:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t **pte_store = &pgtab;
f01011ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011ae:	89 44 24 08          	mov    %eax,0x8(%esp)
	struct PageInfo *pInfo = page_lookup(pgdir, va, pte_store);
f01011b2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011b6:	89 1c 24             	mov    %ebx,(%esp)
f01011b9:	e8 63 ff ff ff       	call   f0101121 <page_lookup>
	if (!pInfo) {
f01011be:	85 c0                	test   %eax,%eax
f01011c0:	74 1d                	je     f01011df <page_remove+0x46>
	page_decref(pInfo);
f01011c2:	89 04 24             	mov    %eax,(%esp)
f01011c5:	e8 af fd ff ff       	call   f0100f79 <page_decref>
	*pgtab = 0;
f01011ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01011d3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011d7:	89 1c 24             	mov    %ebx,(%esp)
f01011da:	e8 af ff ff ff       	call   f010118e <tlb_invalidate>
}
f01011df:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01011e2:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01011e5:	89 ec                	mov    %ebp,%esp
f01011e7:	5d                   	pop    %ebp
f01011e8:	c3                   	ret    

f01011e9 <page_insert>:
{
f01011e9:	55                   	push   %ebp
f01011ea:	89 e5                	mov    %esp,%ebp
f01011ec:	83 ec 28             	sub    $0x28,%esp
f01011ef:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01011f2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01011f5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01011f8:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011fb:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pgtab = pgdir_walk(pgdir, va, 1);
f01011fe:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101205:	00 
f0101206:	8b 45 10             	mov    0x10(%ebp),%eax
f0101209:	89 44 24 04          	mov    %eax,0x4(%esp)
f010120d:	89 1c 24             	mov    %ebx,(%esp)
f0101210:	e8 87 fd ff ff       	call   f0100f9c <pgdir_walk>
f0101215:	89 c6                	mov    %eax,%esi
	if (!pgtab) {
f0101217:	85 c0                	test   %eax,%eax
f0101219:	74 51                	je     f010126c <page_insert+0x83>
	pp->pp_ref++;
f010121b:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	if (*pgtab & PTE_P) {
f0101220:	f6 00 01             	testb  $0x1,(%eax)
f0101223:	74 1e                	je     f0101243 <page_insert+0x5a>
		tlb_invalidate(pgdir, va);
f0101225:	8b 55 10             	mov    0x10(%ebp),%edx
f0101228:	89 54 24 04          	mov    %edx,0x4(%esp)
f010122c:	89 1c 24             	mov    %ebx,(%esp)
f010122f:	e8 5a ff ff ff       	call   f010118e <tlb_invalidate>
		page_remove(pgdir, va);
f0101234:	8b 45 10             	mov    0x10(%ebp),%eax
f0101237:	89 44 24 04          	mov    %eax,0x4(%esp)
f010123b:	89 1c 24             	mov    %ebx,(%esp)
f010123e:	e8 56 ff ff ff       	call   f0101199 <page_remove>
	*pgtab = page2pa(pp) | perm | PTE_P;
f0101243:	8b 45 14             	mov    0x14(%ebp),%eax
f0101246:	83 c8 01             	or     $0x1,%eax
	return (pp - pages) << PGSHIFT;
f0101249:	2b 3d 2c ec 17 f0    	sub    0xf017ec2c,%edi
f010124f:	c1 ff 03             	sar    $0x3,%edi
f0101252:	c1 e7 0c             	shl    $0xc,%edi
f0101255:	09 c7                	or     %eax,%edi
f0101257:	89 3e                	mov    %edi,(%esi)
	pgdir[PDX(va)] |= perm;
f0101259:	8b 45 10             	mov    0x10(%ebp),%eax
f010125c:	c1 e8 16             	shr    $0x16,%eax
f010125f:	8b 55 14             	mov    0x14(%ebp),%edx
f0101262:	09 14 83             	or     %edx,(%ebx,%eax,4)
	return 0;
f0101265:	b8 00 00 00 00       	mov    $0x0,%eax
f010126a:	eb 05                	jmp    f0101271 <page_insert+0x88>
		return -E_NO_MEM;
f010126c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0101271:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101274:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101277:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010127a:	89 ec                	mov    %ebp,%esp
f010127c:	5d                   	pop    %ebp
f010127d:	c3                   	ret    

f010127e <mem_init>:
{
f010127e:	55                   	push   %ebp
f010127f:	89 e5                	mov    %esp,%ebp
f0101281:	57                   	push   %edi
f0101282:	56                   	push   %esi
f0101283:	53                   	push   %ebx
f0101284:	83 ec 3c             	sub    $0x3c,%esp
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101287:	b8 15 00 00 00       	mov    $0x15,%eax
f010128c:	e8 ad f7 ff ff       	call   f0100a3e <nvram_read>
f0101291:	c1 e0 0a             	shl    $0xa,%eax
f0101294:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010129a:	85 c0                	test   %eax,%eax
f010129c:	0f 48 c2             	cmovs  %edx,%eax
f010129f:	c1 f8 0c             	sar    $0xc,%eax
f01012a2:	a3 78 df 17 f0       	mov    %eax,0xf017df78
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012a7:	b8 17 00 00 00       	mov    $0x17,%eax
f01012ac:	e8 8d f7 ff ff       	call   f0100a3e <nvram_read>
f01012b1:	c1 e0 0a             	shl    $0xa,%eax
f01012b4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012ba:	85 c0                	test   %eax,%eax
f01012bc:	0f 48 c2             	cmovs  %edx,%eax
f01012bf:	c1 f8 0c             	sar    $0xc,%eax
	if (npages_extmem)
f01012c2:	85 c0                	test   %eax,%eax
f01012c4:	74 0e                	je     f01012d4 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012c6:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012cc:	89 15 24 ec 17 f0    	mov    %edx,0xf017ec24
f01012d2:	eb 0c                	jmp    f01012e0 <mem_init+0x62>
		npages = npages_basemem;
f01012d4:	8b 15 78 df 17 f0    	mov    0xf017df78,%edx
f01012da:	89 15 24 ec 17 f0    	mov    %edx,0xf017ec24
		npages_extmem * PGSIZE / 1024);
f01012e0:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012e3:	c1 e8 0a             	shr    $0xa,%eax
f01012e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages_basemem * PGSIZE / 1024,
f01012ea:	a1 78 df 17 f0       	mov    0xf017df78,%eax
f01012ef:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f2:	c1 e8 0a             	shr    $0xa,%eax
f01012f5:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012f9:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f01012fe:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101301:	c1 e8 0a             	shr    $0xa,%eax
f0101304:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101308:	c7 04 24 78 59 10 f0 	movl   $0xf0105978,(%esp)
f010130f:	e8 25 25 00 00       	call   f0103839 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101314:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101319:	e8 81 f6 ff ff       	call   f010099f <boot_alloc>
f010131e:	a3 28 ec 17 f0       	mov    %eax,0xf017ec28
	memset(kern_pgdir, 0, PGSIZE);
f0101323:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010132a:	00 
f010132b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101332:	00 
f0101333:	89 04 24             	mov    %eax,(%esp)
f0101336:	e8 68 3a 00 00       	call   f0104da3 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010133b:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
	if ((uint32_t)kva < KERNBASE)
f0101340:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101345:	77 20                	ja     f0101367 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101347:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010134b:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0101352:	f0 
f0101353:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f010135a:	00 
f010135b:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101362:	e8 4f ed ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101367:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010136d:	83 ca 05             	or     $0x5,%edx
f0101370:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101376:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f010137b:	c1 e0 03             	shl    $0x3,%eax
f010137e:	e8 1c f6 ff ff       	call   f010099f <boot_alloc>
f0101383:	a3 2c ec 17 f0       	mov    %eax,0xf017ec2c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101388:	8b 15 24 ec 17 f0    	mov    0xf017ec24,%edx
f010138e:	c1 e2 03             	shl    $0x3,%edx
f0101391:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101395:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010139c:	00 
f010139d:	89 04 24             	mov    %eax,(%esp)
f01013a0:	e8 fe 39 00 00       	call   f0104da3 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01013a5:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013aa:	e8 f0 f5 ff ff       	call   f010099f <boot_alloc>
f01013af:	a3 8c df 17 f0       	mov    %eax,0xf017df8c
	memset(envs, 0, NENV * sizeof(struct Env));
f01013b4:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f01013bb:	00 
f01013bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01013c3:	00 
f01013c4:	89 04 24             	mov    %eax,(%esp)
f01013c7:	e8 d7 39 00 00       	call   f0104da3 <memset>
	page_init();
f01013cc:	e8 e5 f9 ff ff       	call   f0100db6 <page_init>
	check_page_free_list(1);
f01013d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01013d6:	e8 95 f6 ff ff       	call   f0100a70 <check_page_free_list>
	if (!pages)
f01013db:	83 3d 2c ec 17 f0 00 	cmpl   $0x0,0xf017ec2c
f01013e2:	75 1c                	jne    f0101400 <mem_init+0x182>
		panic("'pages' is a null pointer!");
f01013e4:	c7 44 24 08 cf 60 10 	movl   $0xf01060cf,0x8(%esp)
f01013eb:	f0 
f01013ec:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f01013f3:	00 
f01013f4:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01013fb:	e8 b6 ec ff ff       	call   f01000b6 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101400:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f0101405:	bb 00 00 00 00       	mov    $0x0,%ebx
f010140a:	eb 05                	jmp    f0101411 <mem_init+0x193>
		++nfree;
f010140c:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010140f:	8b 00                	mov    (%eax),%eax
f0101411:	85 c0                	test   %eax,%eax
f0101413:	75 f7                	jne    f010140c <mem_init+0x18e>
	assert((pp0 = page_alloc(0)));
f0101415:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010141c:	e8 94 fa ff ff       	call   f0100eb5 <page_alloc>
f0101421:	89 c7                	mov    %eax,%edi
f0101423:	85 c0                	test   %eax,%eax
f0101425:	75 24                	jne    f010144b <mem_init+0x1cd>
f0101427:	c7 44 24 0c ea 60 10 	movl   $0xf01060ea,0xc(%esp)
f010142e:	f0 
f010142f:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101436:	f0 
f0101437:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f010143e:	00 
f010143f:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101446:	e8 6b ec ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f010144b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101452:	e8 5e fa ff ff       	call   f0100eb5 <page_alloc>
f0101457:	89 c6                	mov    %eax,%esi
f0101459:	85 c0                	test   %eax,%eax
f010145b:	75 24                	jne    f0101481 <mem_init+0x203>
f010145d:	c7 44 24 0c 00 61 10 	movl   $0xf0106100,0xc(%esp)
f0101464:	f0 
f0101465:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010146c:	f0 
f010146d:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f0101474:	00 
f0101475:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010147c:	e8 35 ec ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101481:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101488:	e8 28 fa ff ff       	call   f0100eb5 <page_alloc>
f010148d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101490:	85 c0                	test   %eax,%eax
f0101492:	75 24                	jne    f01014b8 <mem_init+0x23a>
f0101494:	c7 44 24 0c 16 61 10 	movl   $0xf0106116,0xc(%esp)
f010149b:	f0 
f010149c:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01014a3:	f0 
f01014a4:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f01014ab:	00 
f01014ac:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01014b3:	e8 fe eb ff ff       	call   f01000b6 <_panic>
	assert(pp1 && pp1 != pp0);
f01014b8:	39 f7                	cmp    %esi,%edi
f01014ba:	75 24                	jne    f01014e0 <mem_init+0x262>
f01014bc:	c7 44 24 0c 2c 61 10 	movl   $0xf010612c,0xc(%esp)
f01014c3:	f0 
f01014c4:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01014cb:	f0 
f01014cc:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f01014d3:	00 
f01014d4:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01014db:	e8 d6 eb ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014e0:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01014e3:	74 05                	je     f01014ea <mem_init+0x26c>
f01014e5:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01014e8:	75 24                	jne    f010150e <mem_init+0x290>
f01014ea:	c7 44 24 0c b4 59 10 	movl   $0xf01059b4,0xc(%esp)
f01014f1:	f0 
f01014f2:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01014f9:	f0 
f01014fa:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101501:	00 
f0101502:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101509:	e8 a8 eb ff ff       	call   f01000b6 <_panic>
	return (pp - pages) << PGSHIFT;
f010150e:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101514:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0101519:	c1 e0 0c             	shl    $0xc,%eax
f010151c:	89 f9                	mov    %edi,%ecx
f010151e:	29 d1                	sub    %edx,%ecx
f0101520:	c1 f9 03             	sar    $0x3,%ecx
f0101523:	c1 e1 0c             	shl    $0xc,%ecx
f0101526:	39 c1                	cmp    %eax,%ecx
f0101528:	72 24                	jb     f010154e <mem_init+0x2d0>
f010152a:	c7 44 24 0c 3e 61 10 	movl   $0xf010613e,0xc(%esp)
f0101531:	f0 
f0101532:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101539:	f0 
f010153a:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f0101541:	00 
f0101542:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101549:	e8 68 eb ff ff       	call   f01000b6 <_panic>
f010154e:	89 f1                	mov    %esi,%ecx
f0101550:	29 d1                	sub    %edx,%ecx
f0101552:	c1 f9 03             	sar    $0x3,%ecx
f0101555:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101558:	39 c8                	cmp    %ecx,%eax
f010155a:	77 24                	ja     f0101580 <mem_init+0x302>
f010155c:	c7 44 24 0c 5b 61 10 	movl   $0xf010615b,0xc(%esp)
f0101563:	f0 
f0101564:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010156b:	f0 
f010156c:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f0101573:	00 
f0101574:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010157b:	e8 36 eb ff ff       	call   f01000b6 <_panic>
f0101580:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101583:	29 d1                	sub    %edx,%ecx
f0101585:	89 ca                	mov    %ecx,%edx
f0101587:	c1 fa 03             	sar    $0x3,%edx
f010158a:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010158d:	39 d0                	cmp    %edx,%eax
f010158f:	77 24                	ja     f01015b5 <mem_init+0x337>
f0101591:	c7 44 24 0c 78 61 10 	movl   $0xf0106178,0xc(%esp)
f0101598:	f0 
f0101599:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01015a0:	f0 
f01015a1:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f01015a8:	00 
f01015a9:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01015b0:	e8 01 eb ff ff       	call   f01000b6 <_panic>
	fl = page_free_list;
f01015b5:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f01015ba:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015bd:	c7 05 80 df 17 f0 00 	movl   $0x0,0xf017df80
f01015c4:	00 00 00 
	assert(!page_alloc(0));
f01015c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ce:	e8 e2 f8 ff ff       	call   f0100eb5 <page_alloc>
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	74 24                	je     f01015fb <mem_init+0x37d>
f01015d7:	c7 44 24 0c 95 61 10 	movl   $0xf0106195,0xc(%esp)
f01015de:	f0 
f01015df:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01015e6:	f0 
f01015e7:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f01015ee:	00 
f01015ef:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01015f6:	e8 bb ea ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f01015fb:	89 3c 24             	mov    %edi,(%esp)
f01015fe:	e8 36 f9 ff ff       	call   f0100f39 <page_free>
	page_free(pp1);
f0101603:	89 34 24             	mov    %esi,(%esp)
f0101606:	e8 2e f9 ff ff       	call   f0100f39 <page_free>
	page_free(pp2);
f010160b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010160e:	89 04 24             	mov    %eax,(%esp)
f0101611:	e8 23 f9 ff ff       	call   f0100f39 <page_free>
	assert((pp0 = page_alloc(0)));
f0101616:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010161d:	e8 93 f8 ff ff       	call   f0100eb5 <page_alloc>
f0101622:	89 c6                	mov    %eax,%esi
f0101624:	85 c0                	test   %eax,%eax
f0101626:	75 24                	jne    f010164c <mem_init+0x3ce>
f0101628:	c7 44 24 0c ea 60 10 	movl   $0xf01060ea,0xc(%esp)
f010162f:	f0 
f0101630:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101637:	f0 
f0101638:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010163f:	00 
f0101640:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101647:	e8 6a ea ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f010164c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101653:	e8 5d f8 ff ff       	call   f0100eb5 <page_alloc>
f0101658:	89 c7                	mov    %eax,%edi
f010165a:	85 c0                	test   %eax,%eax
f010165c:	75 24                	jne    f0101682 <mem_init+0x404>
f010165e:	c7 44 24 0c 00 61 10 	movl   $0xf0106100,0xc(%esp)
f0101665:	f0 
f0101666:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010166d:	f0 
f010166e:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101675:	00 
f0101676:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010167d:	e8 34 ea ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101682:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101689:	e8 27 f8 ff ff       	call   f0100eb5 <page_alloc>
f010168e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101691:	85 c0                	test   %eax,%eax
f0101693:	75 24                	jne    f01016b9 <mem_init+0x43b>
f0101695:	c7 44 24 0c 16 61 10 	movl   $0xf0106116,0xc(%esp)
f010169c:	f0 
f010169d:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01016a4:	f0 
f01016a5:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f01016ac:	00 
f01016ad:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01016b4:	e8 fd e9 ff ff       	call   f01000b6 <_panic>
	assert(pp1 && pp1 != pp0);
f01016b9:	39 fe                	cmp    %edi,%esi
f01016bb:	75 24                	jne    f01016e1 <mem_init+0x463>
f01016bd:	c7 44 24 0c 2c 61 10 	movl   $0xf010612c,0xc(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01016cc:	f0 
f01016cd:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f01016d4:	00 
f01016d5:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01016dc:	e8 d5 e9 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016e1:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01016e4:	74 05                	je     f01016eb <mem_init+0x46d>
f01016e6:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01016e9:	75 24                	jne    f010170f <mem_init+0x491>
f01016eb:	c7 44 24 0c b4 59 10 	movl   $0xf01059b4,0xc(%esp)
f01016f2:	f0 
f01016f3:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01016fa:	f0 
f01016fb:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f0101702:	00 
f0101703:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010170a:	e8 a7 e9 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f010170f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101716:	e8 9a f7 ff ff       	call   f0100eb5 <page_alloc>
f010171b:	85 c0                	test   %eax,%eax
f010171d:	74 24                	je     f0101743 <mem_init+0x4c5>
f010171f:	c7 44 24 0c 95 61 10 	movl   $0xf0106195,0xc(%esp)
f0101726:	f0 
f0101727:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010172e:	f0 
f010172f:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0101736:	00 
f0101737:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010173e:	e8 73 e9 ff ff       	call   f01000b6 <_panic>
f0101743:	89 f0                	mov    %esi,%eax
f0101745:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f010174b:	c1 f8 03             	sar    $0x3,%eax
f010174e:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101751:	89 c2                	mov    %eax,%edx
f0101753:	c1 ea 0c             	shr    $0xc,%edx
f0101756:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f010175c:	72 20                	jb     f010177e <mem_init+0x500>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010175e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101762:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0101769:	f0 
f010176a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101771:	00 
f0101772:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0101779:	e8 38 e9 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f010177e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101785:	00 
f0101786:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010178d:	00 
	return (void *)(pa + KERNBASE);
f010178e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101793:	89 04 24             	mov    %eax,(%esp)
f0101796:	e8 08 36 00 00       	call   f0104da3 <memset>
	page_free(pp0);
f010179b:	89 34 24             	mov    %esi,(%esp)
f010179e:	e8 96 f7 ff ff       	call   f0100f39 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017a3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017aa:	e8 06 f7 ff ff       	call   f0100eb5 <page_alloc>
f01017af:	85 c0                	test   %eax,%eax
f01017b1:	75 24                	jne    f01017d7 <mem_init+0x559>
f01017b3:	c7 44 24 0c a4 61 10 	movl   $0xf01061a4,0xc(%esp)
f01017ba:	f0 
f01017bb:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01017c2:	f0 
f01017c3:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f01017ca:	00 
f01017cb:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01017d2:	e8 df e8 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f01017d7:	39 c6                	cmp    %eax,%esi
f01017d9:	74 24                	je     f01017ff <mem_init+0x581>
f01017db:	c7 44 24 0c c2 61 10 	movl   $0xf01061c2,0xc(%esp)
f01017e2:	f0 
f01017e3:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01017ea:	f0 
f01017eb:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01017f2:	00 
f01017f3:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01017fa:	e8 b7 e8 ff ff       	call   f01000b6 <_panic>
	return (pp - pages) << PGSHIFT;
f01017ff:	89 f2                	mov    %esi,%edx
f0101801:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101807:	c1 fa 03             	sar    $0x3,%edx
f010180a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010180d:	89 d0                	mov    %edx,%eax
f010180f:	c1 e8 0c             	shr    $0xc,%eax
f0101812:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f0101818:	72 20                	jb     f010183a <mem_init+0x5bc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010181a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010181e:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0101825:	f0 
f0101826:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010182d:	00 
f010182e:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0101835:	e8 7c e8 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010183a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
mem_init(void)
f0101840:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101846:	80 38 00             	cmpb   $0x0,(%eax)
f0101849:	74 24                	je     f010186f <mem_init+0x5f1>
f010184b:	c7 44 24 0c d2 61 10 	movl   $0xf01061d2,0xc(%esp)
f0101852:	f0 
f0101853:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010185a:	f0 
f010185b:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0101862:	00 
f0101863:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010186a:	e8 47 e8 ff ff       	call   f01000b6 <_panic>
f010186f:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101872:	39 d0                	cmp    %edx,%eax
f0101874:	75 d0                	jne    f0101846 <mem_init+0x5c8>
	page_free_list = fl;
f0101876:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101879:	89 15 80 df 17 f0    	mov    %edx,0xf017df80
	page_free(pp0);
f010187f:	89 34 24             	mov    %esi,(%esp)
f0101882:	e8 b2 f6 ff ff       	call   f0100f39 <page_free>
	page_free(pp1);
f0101887:	89 3c 24             	mov    %edi,(%esp)
f010188a:	e8 aa f6 ff ff       	call   f0100f39 <page_free>
	page_free(pp2);
f010188f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101892:	89 04 24             	mov    %eax,(%esp)
f0101895:	e8 9f f6 ff ff       	call   f0100f39 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010189a:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f010189f:	eb 05                	jmp    f01018a6 <mem_init+0x628>
		--nfree;
f01018a1:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018a4:	8b 00                	mov    (%eax),%eax
f01018a6:	85 c0                	test   %eax,%eax
f01018a8:	75 f7                	jne    f01018a1 <mem_init+0x623>
	assert(nfree == 0);
f01018aa:	85 db                	test   %ebx,%ebx
f01018ac:	74 24                	je     f01018d2 <mem_init+0x654>
f01018ae:	c7 44 24 0c dc 61 10 	movl   $0xf01061dc,0xc(%esp)
f01018b5:	f0 
f01018b6:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01018bd:	f0 
f01018be:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f01018c5:	00 
f01018c6:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01018cd:	e8 e4 e7 ff ff       	call   f01000b6 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f01018d2:	c7 04 24 d4 59 10 f0 	movl   $0xf01059d4,(%esp)
f01018d9:	e8 5b 1f 00 00       	call   f0103839 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018e5:	e8 cb f5 ff ff       	call   f0100eb5 <page_alloc>
f01018ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018ed:	85 c0                	test   %eax,%eax
f01018ef:	75 24                	jne    f0101915 <mem_init+0x697>
f01018f1:	c7 44 24 0c ea 60 10 	movl   $0xf01060ea,0xc(%esp)
f01018f8:	f0 
f01018f9:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101900:	f0 
f0101901:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101908:	00 
f0101909:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101910:	e8 a1 e7 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101915:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010191c:	e8 94 f5 ff ff       	call   f0100eb5 <page_alloc>
f0101921:	89 c3                	mov    %eax,%ebx
f0101923:	85 c0                	test   %eax,%eax
f0101925:	75 24                	jne    f010194b <mem_init+0x6cd>
f0101927:	c7 44 24 0c 00 61 10 	movl   $0xf0106100,0xc(%esp)
f010192e:	f0 
f010192f:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101936:	f0 
f0101937:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f010193e:	00 
f010193f:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101946:	e8 6b e7 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010194b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101952:	e8 5e f5 ff ff       	call   f0100eb5 <page_alloc>
f0101957:	89 c6                	mov    %eax,%esi
f0101959:	85 c0                	test   %eax,%eax
f010195b:	75 24                	jne    f0101981 <mem_init+0x703>
f010195d:	c7 44 24 0c 16 61 10 	movl   $0xf0106116,0xc(%esp)
f0101964:	f0 
f0101965:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010196c:	f0 
f010196d:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101974:	00 
f0101975:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010197c:	e8 35 e7 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101981:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101984:	75 24                	jne    f01019aa <mem_init+0x72c>
f0101986:	c7 44 24 0c 2c 61 10 	movl   $0xf010612c,0xc(%esp)
f010198d:	f0 
f010198e:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101995:	f0 
f0101996:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f010199d:	00 
f010199e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01019a5:	e8 0c e7 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019aa:	39 c3                	cmp    %eax,%ebx
f01019ac:	74 05                	je     f01019b3 <mem_init+0x735>
f01019ae:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019b1:	75 24                	jne    f01019d7 <mem_init+0x759>
f01019b3:	c7 44 24 0c b4 59 10 	movl   $0xf01059b4,0xc(%esp)
f01019ba:	f0 
f01019bb:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01019c2:	f0 
f01019c3:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01019ca:	00 
f01019cb:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01019d2:	e8 df e6 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019d7:	8b 3d 80 df 17 f0    	mov    0xf017df80,%edi
f01019dd:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f01019e0:	c7 05 80 df 17 f0 00 	movl   $0x0,0xf017df80
f01019e7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019f1:	e8 bf f4 ff ff       	call   f0100eb5 <page_alloc>
f01019f6:	85 c0                	test   %eax,%eax
f01019f8:	74 24                	je     f0101a1e <mem_init+0x7a0>
f01019fa:	c7 44 24 0c 95 61 10 	movl   $0xf0106195,0xc(%esp)
f0101a01:	f0 
f0101a02:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101a09:	f0 
f0101a0a:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101a11:	00 
f0101a12:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101a19:	e8 98 e6 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a1e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a25:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a2c:	00 
f0101a2d:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101a32:	89 04 24             	mov    %eax,(%esp)
f0101a35:	e8 e7 f6 ff ff       	call   f0101121 <page_lookup>
f0101a3a:	85 c0                	test   %eax,%eax
f0101a3c:	74 24                	je     f0101a62 <mem_init+0x7e4>
f0101a3e:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f0101a45:	f0 
f0101a46:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101a4d:	f0 
f0101a4e:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101a55:	00 
f0101a56:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101a5d:	e8 54 e6 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a62:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a69:	00 
f0101a6a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a71:	00 
f0101a72:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a76:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101a7b:	89 04 24             	mov    %eax,(%esp)
f0101a7e:	e8 66 f7 ff ff       	call   f01011e9 <page_insert>
f0101a83:	85 c0                	test   %eax,%eax
f0101a85:	78 24                	js     f0101aab <mem_init+0x82d>
f0101a87:	c7 44 24 0c 2c 5a 10 	movl   $0xf0105a2c,0xc(%esp)
f0101a8e:	f0 
f0101a8f:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101a96:	f0 
f0101a97:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101a9e:	00 
f0101a9f:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101aa6:	e8 0b e6 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aae:	89 04 24             	mov    %eax,(%esp)
f0101ab1:	e8 83 f4 ff ff       	call   f0100f39 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ab6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101abd:	00 
f0101abe:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ac5:	00 
f0101ac6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101aca:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101acf:	89 04 24             	mov    %eax,(%esp)
f0101ad2:	e8 12 f7 ff ff       	call   f01011e9 <page_insert>
f0101ad7:	85 c0                	test   %eax,%eax
f0101ad9:	74 24                	je     f0101aff <mem_init+0x881>
f0101adb:	c7 44 24 0c 5c 5a 10 	movl   $0xf0105a5c,0xc(%esp)
f0101ae2:	f0 
f0101ae3:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101aea:	f0 
f0101aeb:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0101af2:	00 
f0101af3:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101afa:	e8 b7 e5 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101aff:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
	return (pp - pages) << PGSHIFT;
f0101b05:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
f0101b0b:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101b0e:	8b 17                	mov    (%edi),%edx
f0101b10:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b16:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b19:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101b1c:	c1 f8 03             	sar    $0x3,%eax
f0101b1f:	c1 e0 0c             	shl    $0xc,%eax
f0101b22:	39 c2                	cmp    %eax,%edx
f0101b24:	74 24                	je     f0101b4a <mem_init+0x8cc>
f0101b26:	c7 44 24 0c 8c 5a 10 	movl   $0xf0105a8c,0xc(%esp)
f0101b2d:	f0 
f0101b2e:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101b35:	f0 
f0101b36:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0101b3d:	00 
f0101b3e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101b45:	e8 6c e5 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b4a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b4f:	89 f8                	mov    %edi,%eax
f0101b51:	e8 da ed ff ff       	call   f0100930 <check_va2pa>
f0101b56:	89 da                	mov    %ebx,%edx
f0101b58:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b5b:	c1 fa 03             	sar    $0x3,%edx
f0101b5e:	c1 e2 0c             	shl    $0xc,%edx
f0101b61:	39 d0                	cmp    %edx,%eax
f0101b63:	74 24                	je     f0101b89 <mem_init+0x90b>
f0101b65:	c7 44 24 0c b4 5a 10 	movl   $0xf0105ab4,0xc(%esp)
f0101b6c:	f0 
f0101b6d:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101b74:	f0 
f0101b75:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101b7c:	00 
f0101b7d:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101b84:	e8 2d e5 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101b89:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b8e:	74 24                	je     f0101bb4 <mem_init+0x936>
f0101b90:	c7 44 24 0c e7 61 10 	movl   $0xf01061e7,0xc(%esp)
f0101b97:	f0 
f0101b98:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101b9f:	f0 
f0101ba0:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101ba7:	00 
f0101ba8:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101baf:	e8 02 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101bb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bb7:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bbc:	74 24                	je     f0101be2 <mem_init+0x964>
f0101bbe:	c7 44 24 0c f8 61 10 	movl   $0xf01061f8,0xc(%esp)
f0101bc5:	f0 
f0101bc6:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101bcd:	f0 
f0101bce:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101bd5:	00 
f0101bd6:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101bdd:	e8 d4 e4 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101be2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101be9:	00 
f0101bea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bf1:	00 
f0101bf2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bf6:	89 3c 24             	mov    %edi,(%esp)
f0101bf9:	e8 eb f5 ff ff       	call   f01011e9 <page_insert>
f0101bfe:	85 c0                	test   %eax,%eax
f0101c00:	74 24                	je     f0101c26 <mem_init+0x9a8>
f0101c02:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0101c09:	f0 
f0101c0a:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101c11:	f0 
f0101c12:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0101c19:	00 
f0101c1a:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101c21:	e8 90 e4 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c26:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c2b:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101c30:	e8 fb ec ff ff       	call   f0100930 <check_va2pa>
f0101c35:	89 f2                	mov    %esi,%edx
f0101c37:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101c3d:	c1 fa 03             	sar    $0x3,%edx
f0101c40:	c1 e2 0c             	shl    $0xc,%edx
f0101c43:	39 d0                	cmp    %edx,%eax
f0101c45:	74 24                	je     f0101c6b <mem_init+0x9ed>
f0101c47:	c7 44 24 0c 20 5b 10 	movl   $0xf0105b20,0xc(%esp)
f0101c4e:	f0 
f0101c4f:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101c56:	f0 
f0101c57:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101c5e:	00 
f0101c5f:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101c66:	e8 4b e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101c6b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c70:	74 24                	je     f0101c96 <mem_init+0xa18>
f0101c72:	c7 44 24 0c 09 62 10 	movl   $0xf0106209,0xc(%esp)
f0101c79:	f0 
f0101c7a:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101c81:	f0 
f0101c82:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0101c89:	00 
f0101c8a:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101c91:	e8 20 e4 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c96:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c9d:	e8 13 f2 ff ff       	call   f0100eb5 <page_alloc>
f0101ca2:	85 c0                	test   %eax,%eax
f0101ca4:	74 24                	je     f0101cca <mem_init+0xa4c>
f0101ca6:	c7 44 24 0c 95 61 10 	movl   $0xf0106195,0xc(%esp)
f0101cad:	f0 
f0101cae:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101cb5:	f0 
f0101cb6:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101cbd:	00 
f0101cbe:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101cc5:	e8 ec e3 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cca:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cd1:	00 
f0101cd2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cd9:	00 
f0101cda:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cde:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101ce3:	89 04 24             	mov    %eax,(%esp)
f0101ce6:	e8 fe f4 ff ff       	call   f01011e9 <page_insert>
f0101ceb:	85 c0                	test   %eax,%eax
f0101ced:	74 24                	je     f0101d13 <mem_init+0xa95>
f0101cef:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0101cf6:	f0 
f0101cf7:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101cfe:	f0 
f0101cff:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101d06:	00 
f0101d07:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101d0e:	e8 a3 e3 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d13:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d18:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101d1d:	e8 0e ec ff ff       	call   f0100930 <check_va2pa>
f0101d22:	89 f2                	mov    %esi,%edx
f0101d24:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101d2a:	c1 fa 03             	sar    $0x3,%edx
f0101d2d:	c1 e2 0c             	shl    $0xc,%edx
f0101d30:	39 d0                	cmp    %edx,%eax
f0101d32:	74 24                	je     f0101d58 <mem_init+0xada>
f0101d34:	c7 44 24 0c 20 5b 10 	movl   $0xf0105b20,0xc(%esp)
f0101d3b:	f0 
f0101d3c:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101d43:	f0 
f0101d44:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101d4b:	00 
f0101d4c:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101d53:	e8 5e e3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101d58:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d5d:	74 24                	je     f0101d83 <mem_init+0xb05>
f0101d5f:	c7 44 24 0c 09 62 10 	movl   $0xf0106209,0xc(%esp)
f0101d66:	f0 
f0101d67:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101d6e:	f0 
f0101d6f:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101d76:	00 
f0101d77:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101d7e:	e8 33 e3 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d83:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d8a:	e8 26 f1 ff ff       	call   f0100eb5 <page_alloc>
f0101d8f:	85 c0                	test   %eax,%eax
f0101d91:	74 24                	je     f0101db7 <mem_init+0xb39>
f0101d93:	c7 44 24 0c 95 61 10 	movl   $0xf0106195,0xc(%esp)
f0101d9a:	f0 
f0101d9b:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101da2:	f0 
f0101da3:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0101daa:	00 
f0101dab:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101db2:	e8 ff e2 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101db7:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f0101dbd:	8b 02                	mov    (%edx),%eax
f0101dbf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101dc4:	89 c1                	mov    %eax,%ecx
f0101dc6:	c1 e9 0c             	shr    $0xc,%ecx
f0101dc9:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f0101dcf:	72 20                	jb     f0101df1 <mem_init+0xb73>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101dd1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101dd5:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0101ddc:	f0 
f0101ddd:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0101de4:	00 
f0101de5:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101dec:	e8 c5 e2 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101df1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101df6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101df9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e00:	00 
f0101e01:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e08:	00 
f0101e09:	89 14 24             	mov    %edx,(%esp)
f0101e0c:	e8 8b f1 ff ff       	call   f0100f9c <pgdir_walk>
f0101e11:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101e14:	83 c2 04             	add    $0x4,%edx
f0101e17:	39 d0                	cmp    %edx,%eax
f0101e19:	74 24                	je     f0101e3f <mem_init+0xbc1>
f0101e1b:	c7 44 24 0c 50 5b 10 	movl   $0xf0105b50,0xc(%esp)
f0101e22:	f0 
f0101e23:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101e2a:	f0 
f0101e2b:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0101e32:	00 
f0101e33:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101e3a:	e8 77 e2 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e3f:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e46:	00 
f0101e47:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e4e:	00 
f0101e4f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e53:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101e58:	89 04 24             	mov    %eax,(%esp)
f0101e5b:	e8 89 f3 ff ff       	call   f01011e9 <page_insert>
f0101e60:	85 c0                	test   %eax,%eax
f0101e62:	74 24                	je     f0101e88 <mem_init+0xc0a>
f0101e64:	c7 44 24 0c 90 5b 10 	movl   $0xf0105b90,0xc(%esp)
f0101e6b:	f0 
f0101e6c:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101e73:	f0 
f0101e74:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0101e7b:	00 
f0101e7c:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101e83:	e8 2e e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e88:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f0101e8e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e93:	89 f8                	mov    %edi,%eax
f0101e95:	e8 96 ea ff ff       	call   f0100930 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101e9a:	89 f2                	mov    %esi,%edx
f0101e9c:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101ea2:	c1 fa 03             	sar    $0x3,%edx
f0101ea5:	c1 e2 0c             	shl    $0xc,%edx
f0101ea8:	39 d0                	cmp    %edx,%eax
f0101eaa:	74 24                	je     f0101ed0 <mem_init+0xc52>
f0101eac:	c7 44 24 0c 20 5b 10 	movl   $0xf0105b20,0xc(%esp)
f0101eb3:	f0 
f0101eb4:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101ebb:	f0 
f0101ebc:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0101ec3:	00 
f0101ec4:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101ecb:	e8 e6 e1 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ed0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ed5:	74 24                	je     f0101efb <mem_init+0xc7d>
f0101ed7:	c7 44 24 0c 09 62 10 	movl   $0xf0106209,0xc(%esp)
f0101ede:	f0 
f0101edf:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101ee6:	f0 
f0101ee7:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0101eee:	00 
f0101eef:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101ef6:	e8 bb e1 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101efb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f02:	00 
f0101f03:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f0a:	00 
f0101f0b:	89 3c 24             	mov    %edi,(%esp)
f0101f0e:	e8 89 f0 ff ff       	call   f0100f9c <pgdir_walk>
f0101f13:	f6 00 04             	testb  $0x4,(%eax)
f0101f16:	75 24                	jne    f0101f3c <mem_init+0xcbe>
f0101f18:	c7 44 24 0c d0 5b 10 	movl   $0xf0105bd0,0xc(%esp)
f0101f1f:	f0 
f0101f20:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101f27:	f0 
f0101f28:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0101f2f:	00 
f0101f30:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101f37:	e8 7a e1 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f3c:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101f41:	f6 00 04             	testb  $0x4,(%eax)
f0101f44:	75 24                	jne    f0101f6a <mem_init+0xcec>
f0101f46:	c7 44 24 0c 1a 62 10 	movl   $0xf010621a,0xc(%esp)
f0101f4d:	f0 
f0101f4e:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101f55:	f0 
f0101f56:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0101f5d:	00 
f0101f5e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101f65:	e8 4c e1 ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f6a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f71:	00 
f0101f72:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f79:	00 
f0101f7a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f7e:	89 04 24             	mov    %eax,(%esp)
f0101f81:	e8 63 f2 ff ff       	call   f01011e9 <page_insert>
f0101f86:	85 c0                	test   %eax,%eax
f0101f88:	74 24                	je     f0101fae <mem_init+0xd30>
f0101f8a:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0101f91:	f0 
f0101f92:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101f99:	f0 
f0101f9a:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0101fa1:	00 
f0101fa2:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101fa9:	e8 08 e1 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101fae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fb5:	00 
f0101fb6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fbd:	00 
f0101fbe:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101fc3:	89 04 24             	mov    %eax,(%esp)
f0101fc6:	e8 d1 ef ff ff       	call   f0100f9c <pgdir_walk>
f0101fcb:	f6 00 02             	testb  $0x2,(%eax)
f0101fce:	75 24                	jne    f0101ff4 <mem_init+0xd76>
f0101fd0:	c7 44 24 0c 04 5c 10 	movl   $0xf0105c04,0xc(%esp)
f0101fd7:	f0 
f0101fd8:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0101fdf:	f0 
f0101fe0:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0101fe7:	00 
f0101fe8:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0101fef:	e8 c2 e0 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ff4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ffb:	00 
f0101ffc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102003:	00 
f0102004:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102009:	89 04 24             	mov    %eax,(%esp)
f010200c:	e8 8b ef ff ff       	call   f0100f9c <pgdir_walk>
f0102011:	f6 00 04             	testb  $0x4,(%eax)
f0102014:	74 24                	je     f010203a <mem_init+0xdbc>
f0102016:	c7 44 24 0c 38 5c 10 	movl   $0xf0105c38,0xc(%esp)
f010201d:	f0 
f010201e:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102025:	f0 
f0102026:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f010202d:	00 
f010202e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102035:	e8 7c e0 ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010203a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102041:	00 
f0102042:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102049:	00 
f010204a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010204d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102051:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102056:	89 04 24             	mov    %eax,(%esp)
f0102059:	e8 8b f1 ff ff       	call   f01011e9 <page_insert>
f010205e:	85 c0                	test   %eax,%eax
f0102060:	78 24                	js     f0102086 <mem_init+0xe08>
f0102062:	c7 44 24 0c 70 5c 10 	movl   $0xf0105c70,0xc(%esp)
f0102069:	f0 
f010206a:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102071:	f0 
f0102072:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102079:	00 
f010207a:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102081:	e8 30 e0 ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102086:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010208d:	00 
f010208e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102095:	00 
f0102096:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010209a:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010209f:	89 04 24             	mov    %eax,(%esp)
f01020a2:	e8 42 f1 ff ff       	call   f01011e9 <page_insert>
f01020a7:	85 c0                	test   %eax,%eax
f01020a9:	74 24                	je     f01020cf <mem_init+0xe51>
f01020ab:	c7 44 24 0c a8 5c 10 	movl   $0xf0105ca8,0xc(%esp)
f01020b2:	f0 
f01020b3:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01020ba:	f0 
f01020bb:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f01020c2:	00 
f01020c3:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01020ca:	e8 e7 df ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01020cf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020d6:	00 
f01020d7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020de:	00 
f01020df:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01020e4:	89 04 24             	mov    %eax,(%esp)
f01020e7:	e8 b0 ee ff ff       	call   f0100f9c <pgdir_walk>
f01020ec:	f6 00 04             	testb  $0x4,(%eax)
f01020ef:	74 24                	je     f0102115 <mem_init+0xe97>
f01020f1:	c7 44 24 0c 38 5c 10 	movl   $0xf0105c38,0xc(%esp)
f01020f8:	f0 
f01020f9:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102100:	f0 
f0102101:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102108:	00 
f0102109:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102110:	e8 a1 df ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102115:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f010211b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102120:	89 f8                	mov    %edi,%eax
f0102122:	e8 09 e8 ff ff       	call   f0100930 <check_va2pa>
f0102127:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010212a:	89 d8                	mov    %ebx,%eax
f010212c:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102132:	c1 f8 03             	sar    $0x3,%eax
f0102135:	c1 e0 0c             	shl    $0xc,%eax
f0102138:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010213b:	74 24                	je     f0102161 <mem_init+0xee3>
f010213d:	c7 44 24 0c e4 5c 10 	movl   $0xf0105ce4,0xc(%esp)
f0102144:	f0 
f0102145:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010214c:	f0 
f010214d:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102154:	00 
f0102155:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010215c:	e8 55 df ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102161:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102166:	89 f8                	mov    %edi,%eax
f0102168:	e8 c3 e7 ff ff       	call   f0100930 <check_va2pa>
f010216d:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102170:	74 24                	je     f0102196 <mem_init+0xf18>
f0102172:	c7 44 24 0c 10 5d 10 	movl   $0xf0105d10,0xc(%esp)
f0102179:	f0 
f010217a:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102181:	f0 
f0102182:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102189:	00 
f010218a:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102191:	e8 20 df ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102196:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010219b:	74 24                	je     f01021c1 <mem_init+0xf43>
f010219d:	c7 44 24 0c 30 62 10 	movl   $0xf0106230,0xc(%esp)
f01021a4:	f0 
f01021a5:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01021ac:	f0 
f01021ad:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f01021b4:	00 
f01021b5:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01021bc:	e8 f5 de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01021c1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021c6:	74 24                	je     f01021ec <mem_init+0xf6e>
f01021c8:	c7 44 24 0c 41 62 10 	movl   $0xf0106241,0xc(%esp)
f01021cf:	f0 
f01021d0:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01021d7:	f0 
f01021d8:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01021df:	00 
f01021e0:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01021e7:	e8 ca de ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01021ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021f3:	e8 bd ec ff ff       	call   f0100eb5 <page_alloc>
f01021f8:	85 c0                	test   %eax,%eax
f01021fa:	74 04                	je     f0102200 <mem_init+0xf82>
f01021fc:	39 c6                	cmp    %eax,%esi
f01021fe:	74 24                	je     f0102224 <mem_init+0xfa6>
f0102200:	c7 44 24 0c 40 5d 10 	movl   $0xf0105d40,0xc(%esp)
f0102207:	f0 
f0102208:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010220f:	f0 
f0102210:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102217:	00 
f0102218:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010221f:	e8 92 de ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102224:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010222b:	00 
f010222c:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102231:	89 04 24             	mov    %eax,(%esp)
f0102234:	e8 60 ef ff ff       	call   f0101199 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102239:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f010223f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102244:	89 f8                	mov    %edi,%eax
f0102246:	e8 e5 e6 ff ff       	call   f0100930 <check_va2pa>
f010224b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010224e:	74 24                	je     f0102274 <mem_init+0xff6>
f0102250:	c7 44 24 0c 64 5d 10 	movl   $0xf0105d64,0xc(%esp)
f0102257:	f0 
f0102258:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010225f:	f0 
f0102260:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102267:	00 
f0102268:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010226f:	e8 42 de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102274:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102279:	89 f8                	mov    %edi,%eax
f010227b:	e8 b0 e6 ff ff       	call   f0100930 <check_va2pa>
f0102280:	89 da                	mov    %ebx,%edx
f0102282:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0102288:	c1 fa 03             	sar    $0x3,%edx
f010228b:	c1 e2 0c             	shl    $0xc,%edx
f010228e:	39 d0                	cmp    %edx,%eax
f0102290:	74 24                	je     f01022b6 <mem_init+0x1038>
f0102292:	c7 44 24 0c 10 5d 10 	movl   $0xf0105d10,0xc(%esp)
f0102299:	f0 
f010229a:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01022a1:	f0 
f01022a2:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f01022a9:	00 
f01022aa:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01022b1:	e8 00 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f01022b6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01022bb:	74 24                	je     f01022e1 <mem_init+0x1063>
f01022bd:	c7 44 24 0c e7 61 10 	movl   $0xf01061e7,0xc(%esp)
f01022c4:	f0 
f01022c5:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01022cc:	f0 
f01022cd:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f01022d4:	00 
f01022d5:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01022dc:	e8 d5 dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01022e1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022e6:	74 24                	je     f010230c <mem_init+0x108e>
f01022e8:	c7 44 24 0c 41 62 10 	movl   $0xf0106241,0xc(%esp)
f01022ef:	f0 
f01022f0:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01022f7:	f0 
f01022f8:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f01022ff:	00 
f0102300:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102307:	e8 aa dd ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010230c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102313:	00 
f0102314:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010231b:	00 
f010231c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102320:	89 3c 24             	mov    %edi,(%esp)
f0102323:	e8 c1 ee ff ff       	call   f01011e9 <page_insert>
f0102328:	85 c0                	test   %eax,%eax
f010232a:	74 24                	je     f0102350 <mem_init+0x10d2>
f010232c:	c7 44 24 0c 88 5d 10 	movl   $0xf0105d88,0xc(%esp)
f0102333:	f0 
f0102334:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010233b:	f0 
f010233c:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0102343:	00 
f0102344:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010234b:	e8 66 dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f0102350:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102355:	75 24                	jne    f010237b <mem_init+0x10fd>
f0102357:	c7 44 24 0c 52 62 10 	movl   $0xf0106252,0xc(%esp)
f010235e:	f0 
f010235f:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102366:	f0 
f0102367:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f010236e:	00 
f010236f:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102376:	e8 3b dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f010237b:	83 3b 00             	cmpl   $0x0,(%ebx)
f010237e:	74 24                	je     f01023a4 <mem_init+0x1126>
f0102380:	c7 44 24 0c 5e 62 10 	movl   $0xf010625e,0xc(%esp)
f0102387:	f0 
f0102388:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010238f:	f0 
f0102390:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102397:	00 
f0102398:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010239f:	e8 12 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01023a4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01023ab:	00 
f01023ac:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01023b1:	89 04 24             	mov    %eax,(%esp)
f01023b4:	e8 e0 ed ff ff       	call   f0101199 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01023b9:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f01023bf:	ba 00 00 00 00       	mov    $0x0,%edx
f01023c4:	89 f8                	mov    %edi,%eax
f01023c6:	e8 65 e5 ff ff       	call   f0100930 <check_va2pa>
f01023cb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023ce:	74 24                	je     f01023f4 <mem_init+0x1176>
f01023d0:	c7 44 24 0c 64 5d 10 	movl   $0xf0105d64,0xc(%esp)
f01023d7:	f0 
f01023d8:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01023df:	f0 
f01023e0:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f01023e7:	00 
f01023e8:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01023ef:	e8 c2 dc ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01023f4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023f9:	89 f8                	mov    %edi,%eax
f01023fb:	e8 30 e5 ff ff       	call   f0100930 <check_va2pa>
f0102400:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102403:	74 24                	je     f0102429 <mem_init+0x11ab>
f0102405:	c7 44 24 0c c0 5d 10 	movl   $0xf0105dc0,0xc(%esp)
f010240c:	f0 
f010240d:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102414:	f0 
f0102415:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f010241c:	00 
f010241d:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102424:	e8 8d dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102429:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010242e:	74 24                	je     f0102454 <mem_init+0x11d6>
f0102430:	c7 44 24 0c 73 62 10 	movl   $0xf0106273,0xc(%esp)
f0102437:	f0 
f0102438:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010243f:	f0 
f0102440:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0102447:	00 
f0102448:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010244f:	e8 62 dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f0102454:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102459:	74 24                	je     f010247f <mem_init+0x1201>
f010245b:	c7 44 24 0c 41 62 10 	movl   $0xf0106241,0xc(%esp)
f0102462:	f0 
f0102463:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010246a:	f0 
f010246b:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0102472:	00 
f0102473:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010247a:	e8 37 dc ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010247f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102486:	e8 2a ea ff ff       	call   f0100eb5 <page_alloc>
f010248b:	85 c0                	test   %eax,%eax
f010248d:	74 04                	je     f0102493 <mem_init+0x1215>
f010248f:	39 c3                	cmp    %eax,%ebx
f0102491:	74 24                	je     f01024b7 <mem_init+0x1239>
f0102493:	c7 44 24 0c e8 5d 10 	movl   $0xf0105de8,0xc(%esp)
f010249a:	f0 
f010249b:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01024a2:	f0 
f01024a3:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f01024aa:	00 
f01024ab:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01024b2:	e8 ff db ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01024b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01024be:	e8 f2 e9 ff ff       	call   f0100eb5 <page_alloc>
f01024c3:	85 c0                	test   %eax,%eax
f01024c5:	74 24                	je     f01024eb <mem_init+0x126d>
f01024c7:	c7 44 24 0c 95 61 10 	movl   $0xf0106195,0xc(%esp)
f01024ce:	f0 
f01024cf:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01024d6:	f0 
f01024d7:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f01024de:	00 
f01024df:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01024e6:	e8 cb db ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01024eb:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01024f0:	8b 08                	mov    (%eax),%ecx
f01024f2:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01024f8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024fb:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0102501:	c1 fa 03             	sar    $0x3,%edx
f0102504:	c1 e2 0c             	shl    $0xc,%edx
f0102507:	39 d1                	cmp    %edx,%ecx
f0102509:	74 24                	je     f010252f <mem_init+0x12b1>
f010250b:	c7 44 24 0c 8c 5a 10 	movl   $0xf0105a8c,0xc(%esp)
f0102512:	f0 
f0102513:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010251a:	f0 
f010251b:	c7 44 24 04 c3 03 00 	movl   $0x3c3,0x4(%esp)
f0102522:	00 
f0102523:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010252a:	e8 87 db ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f010252f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102535:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102538:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010253d:	74 24                	je     f0102563 <mem_init+0x12e5>
f010253f:	c7 44 24 0c f8 61 10 	movl   $0xf01061f8,0xc(%esp)
f0102546:	f0 
f0102547:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f010254e:	f0 
f010254f:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f0102556:	00 
f0102557:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010255e:	e8 53 db ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102563:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102566:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010256c:	89 04 24             	mov    %eax,(%esp)
f010256f:	e8 c5 e9 ff ff       	call   f0100f39 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102574:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010257b:	00 
f010257c:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102583:	00 
f0102584:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102589:	89 04 24             	mov    %eax,(%esp)
f010258c:	e8 0b ea ff ff       	call   f0100f9c <pgdir_walk>
f0102591:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102594:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f010259a:	8b 4a 04             	mov    0x4(%edx),%ecx
f010259d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01025a3:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	if (PGNUM(pa) >= npages)
f01025a6:	8b 0d 24 ec 17 f0    	mov    0xf017ec24,%ecx
f01025ac:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01025af:	c1 ef 0c             	shr    $0xc,%edi
f01025b2:	39 cf                	cmp    %ecx,%edi
f01025b4:	72 23                	jb     f01025d9 <mem_init+0x135b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01025b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025bd:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f01025c4:	f0 
f01025c5:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f01025cc:	00 
f01025cd:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01025d4:	e8 dd da ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01025d9:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01025dc:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01025e2:	39 f8                	cmp    %edi,%eax
f01025e4:	74 24                	je     f010260a <mem_init+0x138c>
f01025e6:	c7 44 24 0c 84 62 10 	movl   $0xf0106284,0xc(%esp)
f01025ed:	f0 
f01025ee:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01025f5:	f0 
f01025f6:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f01025fd:	00 
f01025fe:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102605:	e8 ac da ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010260a:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102611:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102614:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010261a:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102620:	c1 f8 03             	sar    $0x3,%eax
f0102623:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102626:	89 c2                	mov    %eax,%edx
f0102628:	c1 ea 0c             	shr    $0xc,%edx
f010262b:	39 d1                	cmp    %edx,%ecx
f010262d:	77 20                	ja     f010264f <mem_init+0x13d1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010262f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102633:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f010263a:	f0 
f010263b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102642:	00 
f0102643:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f010264a:	e8 67 da ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010264f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102656:	00 
f0102657:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010265e:	00 
	return (void *)(pa + KERNBASE);
f010265f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102664:	89 04 24             	mov    %eax,(%esp)
f0102667:	e8 37 27 00 00       	call   f0104da3 <memset>
	page_free(pp0);
f010266c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010266f:	89 04 24             	mov    %eax,(%esp)
f0102672:	e8 c2 e8 ff ff       	call   f0100f39 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102677:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010267e:	00 
f010267f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102686:	00 
f0102687:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010268c:	89 04 24             	mov    %eax,(%esp)
f010268f:	e8 08 e9 ff ff       	call   f0100f9c <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102694:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102697:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f010269d:	c1 fa 03             	sar    $0x3,%edx
f01026a0:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01026a3:	89 d0                	mov    %edx,%eax
f01026a5:	c1 e8 0c             	shr    $0xc,%eax
f01026a8:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01026ae:	72 20                	jb     f01026d0 <mem_init+0x1452>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026b0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026b4:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f01026bb:	f0 
f01026bc:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01026c3:	00 
f01026c4:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f01026cb:	e8 e6 d9 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01026d0:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01026d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mem_init(void)
f01026d9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01026df:	f6 00 01             	testb  $0x1,(%eax)
f01026e2:	74 24                	je     f0102708 <mem_init+0x148a>
f01026e4:	c7 44 24 0c 9c 62 10 	movl   $0xf010629c,0xc(%esp)
f01026eb:	f0 
f01026ec:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01026f3:	f0 
f01026f4:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f01026fb:	00 
f01026fc:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102703:	e8 ae d9 ff ff       	call   f01000b6 <_panic>
f0102708:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f010270b:	39 d0                	cmp    %edx,%eax
f010270d:	75 d0                	jne    f01026df <mem_init+0x1461>
	kern_pgdir[0] = 0;
f010270f:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102714:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010271a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010271d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102723:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102726:	89 3d 80 df 17 f0    	mov    %edi,0xf017df80

	// free the pages we took
	page_free(pp0);
f010272c:	89 04 24             	mov    %eax,(%esp)
f010272f:	e8 05 e8 ff ff       	call   f0100f39 <page_free>
	page_free(pp1);
f0102734:	89 1c 24             	mov    %ebx,(%esp)
f0102737:	e8 fd e7 ff ff       	call   f0100f39 <page_free>
	page_free(pp2);
f010273c:	89 34 24             	mov    %esi,(%esp)
f010273f:	e8 f5 e7 ff ff       	call   f0100f39 <page_free>

	cprintf("check_page() succeeded!\n");
f0102744:	c7 04 24 b3 62 10 f0 	movl   $0xf01062b3,(%esp)
f010274b:	e8 e9 10 00 00       	call   f0103839 <cprintf>
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR((uintptr_t *) pages), PTE_U);
f0102750:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102755:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010275a:	77 20                	ja     f010277c <mem_init+0x14fe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010275c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102760:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0102767:	f0 
f0102768:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f010276f:	00 
f0102770:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102777:	e8 3a d9 ff ff       	call   f01000b6 <_panic>
f010277c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102783:	00 
	return (physaddr_t)kva - KERNBASE;
f0102784:	05 00 00 00 10       	add    $0x10000000,%eax
f0102789:	89 04 24             	mov    %eax,(%esp)
f010278c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102791:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102796:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010279b:	e8 07 e9 ff ff       	call   f01010a7 <boot_map_region>
	boot_map_region(kern_pgdir, (uintptr_t) UENVS, ROUNDUP(NENV * sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U | PTE_P);
f01027a0:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01027a5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01027aa:	77 20                	ja     f01027cc <mem_init+0x154e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027b0:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f01027b7:	f0 
f01027b8:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
f01027bf:	00 
f01027c0:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01027c7:	e8 ea d8 ff ff       	call   f01000b6 <_panic>
f01027cc:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01027d3:	00 
	return (physaddr_t)kva - KERNBASE;
f01027d4:	05 00 00 00 10       	add    $0x10000000,%eax
f01027d9:	89 04 24             	mov    %eax,(%esp)
f01027dc:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01027e1:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01027e6:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01027eb:	e8 b7 e8 ff ff       	call   f01010a7 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01027f0:	b8 00 20 11 f0       	mov    $0xf0112000,%eax
f01027f5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01027fa:	77 20                	ja     f010281c <mem_init+0x159e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102800:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0102807:	f0 
f0102808:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f010280f:	00 
f0102810:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102817:	e8 9a d8 ff ff       	call   f01000b6 <_panic>
	boot_map_region(kern_pgdir , KSTACKTOP-KSTKSIZE , KSTKSIZE ,PADDR((uintptr_t*) bootstack) , PTE_W);
f010281c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102823:	00 
f0102824:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f010282b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102830:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102835:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010283a:	e8 68 e8 ff ff       	call   f01010a7 <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff -KERNBASE,(physaddr_t)0,PTE_W);
f010283f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102846:	00 
f0102847:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010284e:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102853:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102858:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010285d:	e8 45 e8 ff ff       	call   f01010a7 <boot_map_region>
	pgdir = kern_pgdir;
f0102862:	8b 1d 28 ec 17 f0    	mov    0xf017ec28,%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102868:	8b 35 24 ec 17 f0    	mov    0xf017ec24,%esi
f010286e:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0102871:	8d 04 f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%eax
f0102878:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010287d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102880:	8b 3d 2c ec 17 f0    	mov    0xf017ec2c,%edi
f0102886:	89 7d cc             	mov    %edi,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102889:	89 7d d0             	mov    %edi,-0x30(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010288c:	81 c7 00 00 00 10    	add    $0x10000000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102892:	be 00 00 00 00       	mov    $0x0,%esi
f0102897:	eb 6a                	jmp    f0102903 <mem_init+0x1685>
mem_init(void)
f0102899:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010289f:	89 d8                	mov    %ebx,%eax
f01028a1:	e8 8a e0 ff ff       	call   f0100930 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01028a6:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01028ad:	77 23                	ja     f01028d2 <mem_init+0x1654>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028af:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01028b2:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01028b6:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f01028bd:	f0 
f01028be:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01028c5:	00 
f01028c6:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01028cd:	e8 e4 d7 ff ff       	call   f01000b6 <_panic>
mem_init(void)
f01028d2:	8d 14 3e             	lea    (%esi,%edi,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01028d5:	39 d0                	cmp    %edx,%eax
f01028d7:	74 24                	je     f01028fd <mem_init+0x167f>
f01028d9:	c7 44 24 0c 0c 5e 10 	movl   $0xf0105e0c,0xc(%esp)
f01028e0:	f0 
f01028e1:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01028e8:	f0 
f01028e9:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01028f0:	00 
f01028f1:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01028f8:	e8 b9 d7 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f01028fd:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102903:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102906:	77 91                	ja     f0102899 <mem_init+0x161b>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102908:	8b 35 8c df 17 f0    	mov    0xf017df8c,%esi
	if ((uint32_t)kva < KERNBASE)
f010290e:	89 f7                	mov    %esi,%edi
f0102910:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102915:	89 d8                	mov    %ebx,%eax
f0102917:	e8 14 e0 ff ff       	call   f0100930 <check_va2pa>
f010291c:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102922:	77 20                	ja     f0102944 <mem_init+0x16c6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102924:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102928:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f010292f:	f0 
f0102930:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0102937:	00 
f0102938:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f010293f:	e8 72 d7 ff ff       	call   f01000b6 <_panic>
	if ((uint32_t)kva < KERNBASE)
f0102944:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
mem_init(void)
f0102949:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f010294f:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102952:	39 c2                	cmp    %eax,%edx
f0102954:	74 24                	je     f010297a <mem_init+0x16fc>
f0102956:	c7 44 24 0c 40 5e 10 	movl   $0xf0105e40,0xc(%esp)
f010295d:	f0 
f010295e:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102965:	f0 
f0102966:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f010296d:	00 
f010296e:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102975:	e8 3c d7 ff ff       	call   f01000b6 <_panic>
f010297a:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
f0102980:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102986:	0f 85 d5 05 00 00    	jne    f0102f61 <mem_init+0x1ce3>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010298c:	8b 7d c8             	mov    -0x38(%ebp),%edi
f010298f:	c1 e7 0c             	shl    $0xc,%edi
f0102992:	be 00 00 00 00       	mov    $0x0,%esi
f0102997:	eb 3b                	jmp    f01029d4 <mem_init+0x1756>
mem_init(void)
f0102999:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010299f:	89 d8                	mov    %ebx,%eax
f01029a1:	e8 8a df ff ff       	call   f0100930 <check_va2pa>
f01029a6:	39 c6                	cmp    %eax,%esi
f01029a8:	74 24                	je     f01029ce <mem_init+0x1750>
f01029aa:	c7 44 24 0c 74 5e 10 	movl   $0xf0105e74,0xc(%esp)
f01029b1:	f0 
f01029b2:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f01029b9:	f0 
f01029ba:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f01029c1:	00 
f01029c2:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f01029c9:	e8 e8 d6 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029ce:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01029d4:	39 fe                	cmp    %edi,%esi
f01029d6:	72 c1                	jb     f0102999 <mem_init+0x171b>
f01029d8:	be 00 80 ff ef       	mov    $0xefff8000,%esi
mem_init(void)
f01029dd:	bf 00 20 11 f0       	mov    $0xf0112000,%edi
f01029e2:	81 c7 00 80 00 20    	add    $0x20008000,%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029e8:	89 f2                	mov    %esi,%edx
f01029ea:	89 d8                	mov    %ebx,%eax
f01029ec:	e8 3f df ff ff       	call   f0100930 <check_va2pa>
mem_init(void)
f01029f1:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029f4:	39 d0                	cmp    %edx,%eax
f01029f6:	74 24                	je     f0102a1c <mem_init+0x179e>
f01029f8:	c7 44 24 0c 9c 5e 10 	movl   $0xf0105e9c,0xc(%esp)
f01029ff:	f0 
f0102a00:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102a07:	f0 
f0102a08:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0102a0f:	00 
f0102a10:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102a17:	e8 9a d6 ff ff       	call   f01000b6 <_panic>
f0102a1c:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a22:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102a28:	75 be                	jne    f01029e8 <mem_init+0x176a>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a2a:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a2f:	89 d8                	mov    %ebx,%eax
f0102a31:	e8 fa de ff ff       	call   f0100930 <check_va2pa>
f0102a36:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a39:	0f 84 f3 00 00 00    	je     f0102b32 <mem_init+0x18b4>
f0102a3f:	c7 44 24 0c e4 5e 10 	movl   $0xf0105ee4,0xc(%esp)
f0102a46:	f0 
f0102a47:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102a4e:	f0 
f0102a4f:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0102a56:	00 
f0102a57:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102a5e:	e8 53 d6 ff ff       	call   f01000b6 <_panic>
		switch (i) {
f0102a63:	8d 88 45 fc ff ff    	lea    -0x3bb(%eax),%ecx
f0102a69:	83 f9 04             	cmp    $0x4,%ecx
f0102a6c:	77 39                	ja     f0102aa7 <mem_init+0x1829>
f0102a6e:	89 d7                	mov    %edx,%edi
f0102a70:	d3 e7                	shl    %cl,%edi
f0102a72:	89 f9                	mov    %edi,%ecx
f0102a74:	f6 c1 17             	test   $0x17,%cl
f0102a77:	74 2e                	je     f0102aa7 <mem_init+0x1829>
			assert(pgdir[i] & PTE_P);
f0102a79:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102a7d:	0f 85 aa 00 00 00    	jne    f0102b2d <mem_init+0x18af>
f0102a83:	c7 44 24 0c cc 62 10 	movl   $0xf01062cc,0xc(%esp)
f0102a8a:	f0 
f0102a8b:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102a92:	f0 
f0102a93:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102a9a:	00 
f0102a9b:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102aa2:	e8 0f d6 ff ff       	call   f01000b6 <_panic>
			if (i >= PDX(KERNBASE)) {
f0102aa7:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102aac:	76 55                	jbe    f0102b03 <mem_init+0x1885>
				assert(pgdir[i] & PTE_P);
f0102aae:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0102ab1:	f6 c1 01             	test   $0x1,%cl
f0102ab4:	75 24                	jne    f0102ada <mem_init+0x185c>
f0102ab6:	c7 44 24 0c cc 62 10 	movl   $0xf01062cc,0xc(%esp)
f0102abd:	f0 
f0102abe:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102ac5:	f0 
f0102ac6:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0102acd:	00 
f0102ace:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102ad5:	e8 dc d5 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102ada:	f6 c1 02             	test   $0x2,%cl
f0102add:	75 4e                	jne    f0102b2d <mem_init+0x18af>
f0102adf:	c7 44 24 0c dd 62 10 	movl   $0xf01062dd,0xc(%esp)
f0102ae6:	f0 
f0102ae7:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102aee:	f0 
f0102aef:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0102af6:	00 
f0102af7:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102afe:	e8 b3 d5 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] == 0);
f0102b03:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102b07:	74 24                	je     f0102b2d <mem_init+0x18af>
f0102b09:	c7 44 24 0c ee 62 10 	movl   $0xf01062ee,0xc(%esp)
f0102b10:	f0 
f0102b11:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102b18:	f0 
f0102b19:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0102b20:	00 
f0102b21:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102b28:	e8 89 d5 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b2d:	83 c0 01             	add    $0x1,%eax
f0102b30:	eb 0a                	jmp    f0102b3c <mem_init+0x18be>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b32:	b8 00 00 00 00       	mov    $0x0,%eax
		switch (i) {
f0102b37:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 0; i < NPDENTRIES; i++) {
f0102b3c:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102b41:	0f 85 1c ff ff ff    	jne    f0102a63 <mem_init+0x17e5>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b47:	c7 04 24 14 5f 10 f0 	movl   $0xf0105f14,(%esp)
f0102b4e:	e8 e6 0c 00 00       	call   f0103839 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b53:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102b58:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b5d:	77 20                	ja     f0102b7f <mem_init+0x1901>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b5f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b63:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0102b6a:	f0 
f0102b6b:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
f0102b72:	00 
f0102b73:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102b7a:	e8 37 d5 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b7f:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b84:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102b87:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b8c:	e8 df de ff ff       	call   f0100a70 <check_page_free_list>
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b91:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b94:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b97:	0d 23 00 05 80       	or     $0x80050023,%eax
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b9c:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b9f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ba6:	e8 0a e3 ff ff       	call   f0100eb5 <page_alloc>
f0102bab:	89 c3                	mov    %eax,%ebx
f0102bad:	85 c0                	test   %eax,%eax
f0102baf:	75 24                	jne    f0102bd5 <mem_init+0x1957>
f0102bb1:	c7 44 24 0c ea 60 10 	movl   $0xf01060ea,0xc(%esp)
f0102bb8:	f0 
f0102bb9:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102bc0:	f0 
f0102bc1:	c7 44 24 04 f2 03 00 	movl   $0x3f2,0x4(%esp)
f0102bc8:	00 
f0102bc9:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102bd0:	e8 e1 d4 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102bd5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bdc:	e8 d4 e2 ff ff       	call   f0100eb5 <page_alloc>
f0102be1:	89 c7                	mov    %eax,%edi
f0102be3:	85 c0                	test   %eax,%eax
f0102be5:	75 24                	jne    f0102c0b <mem_init+0x198d>
f0102be7:	c7 44 24 0c 00 61 10 	movl   $0xf0106100,0xc(%esp)
f0102bee:	f0 
f0102bef:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102bf6:	f0 
f0102bf7:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f0102bfe:	00 
f0102bff:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102c06:	e8 ab d4 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102c0b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c12:	e8 9e e2 ff ff       	call   f0100eb5 <page_alloc>
f0102c17:	89 c6                	mov    %eax,%esi
f0102c19:	85 c0                	test   %eax,%eax
f0102c1b:	75 24                	jne    f0102c41 <mem_init+0x19c3>
f0102c1d:	c7 44 24 0c 16 61 10 	movl   $0xf0106116,0xc(%esp)
f0102c24:	f0 
f0102c25:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102c2c:	f0 
f0102c2d:	c7 44 24 04 f4 03 00 	movl   $0x3f4,0x4(%esp)
f0102c34:	00 
f0102c35:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102c3c:	e8 75 d4 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102c41:	89 1c 24             	mov    %ebx,(%esp)
f0102c44:	e8 f0 e2 ff ff       	call   f0100f39 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c49:	89 f8                	mov    %edi,%eax
f0102c4b:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102c51:	c1 f8 03             	sar    $0x3,%eax
f0102c54:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c57:	89 c2                	mov    %eax,%edx
f0102c59:	c1 ea 0c             	shr    $0xc,%edx
f0102c5c:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102c62:	72 20                	jb     f0102c84 <mem_init+0x1a06>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c64:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c68:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0102c6f:	f0 
f0102c70:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102c77:	00 
f0102c78:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0102c7f:	e8 32 d4 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c84:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c8b:	00 
f0102c8c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102c93:	00 
	return (void *)(pa + KERNBASE);
f0102c94:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c99:	89 04 24             	mov    %eax,(%esp)
f0102c9c:	e8 02 21 00 00       	call   f0104da3 <memset>
	return (pp - pages) << PGSHIFT;
f0102ca1:	89 f0                	mov    %esi,%eax
f0102ca3:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102ca9:	c1 f8 03             	sar    $0x3,%eax
f0102cac:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102caf:	89 c2                	mov    %eax,%edx
f0102cb1:	c1 ea 0c             	shr    $0xc,%edx
f0102cb4:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102cba:	72 20                	jb     f0102cdc <mem_init+0x1a5e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cc0:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0102cc7:	f0 
f0102cc8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102ccf:	00 
f0102cd0:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0102cd7:	e8 da d3 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102cdc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ce3:	00 
f0102ce4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102ceb:	00 
	return (void *)(pa + KERNBASE);
f0102cec:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102cf1:	89 04 24             	mov    %eax,(%esp)
f0102cf4:	e8 aa 20 00 00       	call   f0104da3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102cf9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d00:	00 
f0102d01:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d08:	00 
f0102d09:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d0d:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102d12:	89 04 24             	mov    %eax,(%esp)
f0102d15:	e8 cf e4 ff ff       	call   f01011e9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d1a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d1f:	74 24                	je     f0102d45 <mem_init+0x1ac7>
f0102d21:	c7 44 24 0c e7 61 10 	movl   $0xf01061e7,0xc(%esp)
f0102d28:	f0 
f0102d29:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102d30:	f0 
f0102d31:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0102d38:	00 
f0102d39:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102d40:	e8 71 d3 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d45:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d4c:	01 01 01 
f0102d4f:	74 24                	je     f0102d75 <mem_init+0x1af7>
f0102d51:	c7 44 24 0c 34 5f 10 	movl   $0xf0105f34,0xc(%esp)
f0102d58:	f0 
f0102d59:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102d60:	f0 
f0102d61:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0102d68:	00 
f0102d69:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102d70:	e8 41 d3 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d75:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d7c:	00 
f0102d7d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d84:	00 
f0102d85:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d89:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102d8e:	89 04 24             	mov    %eax,(%esp)
f0102d91:	e8 53 e4 ff ff       	call   f01011e9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d96:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d9d:	02 02 02 
f0102da0:	74 24                	je     f0102dc6 <mem_init+0x1b48>
f0102da2:	c7 44 24 0c 58 5f 10 	movl   $0xf0105f58,0xc(%esp)
f0102da9:	f0 
f0102daa:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102db1:	f0 
f0102db2:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f0102db9:	00 
f0102dba:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102dc1:	e8 f0 d2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102dc6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102dcb:	74 24                	je     f0102df1 <mem_init+0x1b73>
f0102dcd:	c7 44 24 0c 09 62 10 	movl   $0xf0106209,0xc(%esp)
f0102dd4:	f0 
f0102dd5:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102ddc:	f0 
f0102ddd:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0102de4:	00 
f0102de5:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102dec:	e8 c5 d2 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102df1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102df6:	74 24                	je     f0102e1c <mem_init+0x1b9e>
f0102df8:	c7 44 24 0c 73 62 10 	movl   $0xf0106273,0xc(%esp)
f0102dff:	f0 
f0102e00:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102e07:	f0 
f0102e08:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f0102e0f:	00 
f0102e10:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102e17:	e8 9a d2 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e1c:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e23:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102e26:	89 f0                	mov    %esi,%eax
f0102e28:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102e2e:	c1 f8 03             	sar    $0x3,%eax
f0102e31:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e34:	89 c2                	mov    %eax,%edx
f0102e36:	c1 ea 0c             	shr    $0xc,%edx
f0102e39:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102e3f:	72 20                	jb     f0102e61 <mem_init+0x1be3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e41:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e45:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0102e4c:	f0 
f0102e4d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102e54:	00 
f0102e55:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0102e5c:	e8 55 d2 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102e61:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102e68:	03 03 03 
f0102e6b:	74 24                	je     f0102e91 <mem_init+0x1c13>
f0102e6d:	c7 44 24 0c 7c 5f 10 	movl   $0xf0105f7c,0xc(%esp)
f0102e74:	f0 
f0102e75:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102e7c:	f0 
f0102e7d:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
f0102e84:	00 
f0102e85:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102e8c:	e8 25 d2 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e91:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102e98:	00 
f0102e99:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102e9e:	89 04 24             	mov    %eax,(%esp)
f0102ea1:	e8 f3 e2 ff ff       	call   f0101199 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ea6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102eab:	74 24                	je     f0102ed1 <mem_init+0x1c53>
f0102ead:	c7 44 24 0c 41 62 10 	movl   $0xf0106241,0xc(%esp)
f0102eb4:	f0 
f0102eb5:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102ebc:	f0 
f0102ebd:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f0102ec4:	00 
f0102ec5:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102ecc:	e8 e5 d1 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ed1:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102ed6:	8b 08                	mov    (%eax),%ecx
f0102ed8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0102ede:	89 da                	mov    %ebx,%edx
f0102ee0:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0102ee6:	c1 fa 03             	sar    $0x3,%edx
f0102ee9:	c1 e2 0c             	shl    $0xc,%edx
f0102eec:	39 d1                	cmp    %edx,%ecx
f0102eee:	74 24                	je     f0102f14 <mem_init+0x1c96>
f0102ef0:	c7 44 24 0c 8c 5a 10 	movl   $0xf0105a8c,0xc(%esp)
f0102ef7:	f0 
f0102ef8:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102eff:	f0 
f0102f00:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f0102f07:	00 
f0102f08:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102f0f:	e8 a2 d1 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102f14:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102f1a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102f1f:	74 24                	je     f0102f45 <mem_init+0x1cc7>
f0102f21:	c7 44 24 0c f8 61 10 	movl   $0xf01061f8,0xc(%esp)
f0102f28:	f0 
f0102f29:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0102f30:	f0 
f0102f31:	c7 44 24 04 07 04 00 	movl   $0x407,0x4(%esp)
f0102f38:	00 
f0102f39:	c7 04 24 09 60 10 f0 	movl   $0xf0106009,(%esp)
f0102f40:	e8 71 d1 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102f45:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102f4b:	89 1c 24             	mov    %ebx,(%esp)
f0102f4e:	e8 e6 df ff ff       	call   f0100f39 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102f53:	c7 04 24 a8 5f 10 f0 	movl   $0xf0105fa8,(%esp)
f0102f5a:	e8 da 08 00 00       	call   f0103839 <cprintf>
f0102f5f:	eb 0e                	jmp    f0102f6f <mem_init+0x1cf1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102f61:	89 f2                	mov    %esi,%edx
f0102f63:	89 d8                	mov    %ebx,%eax
f0102f65:	e8 c6 d9 ff ff       	call   f0100930 <check_va2pa>
f0102f6a:	e9 e0 f9 ff ff       	jmp    f010294f <mem_init+0x16d1>
}
f0102f6f:	83 c4 3c             	add    $0x3c,%esp
f0102f72:	5b                   	pop    %ebx
f0102f73:	5e                   	pop    %esi
f0102f74:	5f                   	pop    %edi
f0102f75:	5d                   	pop    %ebp
f0102f76:	c3                   	ret    

f0102f77 <user_mem_check>:
{
f0102f77:	55                   	push   %ebp
f0102f78:	89 e5                	mov    %esp,%ebp
f0102f7a:	57                   	push   %edi
f0102f7b:	56                   	push   %esi
f0102f7c:	53                   	push   %ebx
f0102f7d:	83 ec 2c             	sub    $0x2c,%esp
f0102f80:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102f83:	8b 75 14             	mov    0x14(%ebp),%esi
	char * end = ROUNDUP((char *)(va + len), PGSIZE);
f0102f86:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f89:	03 45 10             	add    0x10(%ebp),%eax
f0102f8c:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102f91:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f96:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char * start = ROUNDDOWN((char *)va, PGSIZE);
f0102f99:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f9c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102fa1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102fa4:	89 c3                	mov    %eax,%ebx
	for (; start < end; start += PGSIZE) {
f0102fa6:	eb 54                	jmp    f0102ffc <user_mem_check+0x85>
		curr = pgdir_walk(env->env_pgdir, (void *)start, 0);
f0102fa8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102faf:	00 
f0102fb0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102fb4:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102fb7:	89 04 24             	mov    %eax,(%esp)
f0102fba:	e8 dd df ff ff       	call   f0100f9c <pgdir_walk>
		if ((int)start > ULIM || curr == NULL || ((uint32_t)(*curr) & perm) != perm) {
f0102fbf:	89 da                	mov    %ebx,%edx
f0102fc1:	85 c0                	test   %eax,%eax
f0102fc3:	74 10                	je     f0102fd5 <user_mem_check+0x5e>
f0102fc5:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f0102fcb:	77 08                	ja     f0102fd5 <user_mem_check+0x5e>
f0102fcd:	8b 00                	mov    (%eax),%eax
f0102fcf:	21 f0                	and    %esi,%eax
f0102fd1:	39 c6                	cmp    %eax,%esi
f0102fd3:	74 21                	je     f0102ff6 <user_mem_check+0x7f>
			if (start == ROUNDDOWN((char *)va, PGSIZE)) {
f0102fd5:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0102fd8:	75 0f                	jne    f0102fe9 <user_mem_check+0x72>
				user_mem_check_addr = (uintptr_t)va;
f0102fda:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fdd:	a3 84 df 17 f0       	mov    %eax,0xf017df84
			return -E_FAULT;
f0102fe2:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102fe7:	eb 1d                	jmp    f0103006 <user_mem_check+0x8f>
				user_mem_check_addr = (uintptr_t)start;
f0102fe9:	89 15 84 df 17 f0    	mov    %edx,0xf017df84
			return -E_FAULT;
f0102fef:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ff4:	eb 10                	jmp    f0103006 <user_mem_check+0x8f>
	for (; start < end; start += PGSIZE) {
f0102ff6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ffc:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102fff:	72 a7                	jb     f0102fa8 <user_mem_check+0x31>
	return 0;
f0103001:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103006:	83 c4 2c             	add    $0x2c,%esp
f0103009:	5b                   	pop    %ebx
f010300a:	5e                   	pop    %esi
f010300b:	5f                   	pop    %edi
f010300c:	5d                   	pop    %ebp
f010300d:	c3                   	ret    

f010300e <user_mem_assert>:
{
f010300e:	55                   	push   %ebp
f010300f:	89 e5                	mov    %esp,%ebp
f0103011:	53                   	push   %ebx
f0103012:	83 ec 14             	sub    $0x14,%esp
f0103015:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103018:	8b 45 14             	mov    0x14(%ebp),%eax
f010301b:	83 c8 04             	or     $0x4,%eax
f010301e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103022:	8b 45 10             	mov    0x10(%ebp),%eax
f0103025:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103029:	8b 45 0c             	mov    0xc(%ebp),%eax
f010302c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103030:	89 1c 24             	mov    %ebx,(%esp)
f0103033:	e8 3f ff ff ff       	call   f0102f77 <user_mem_check>
f0103038:	85 c0                	test   %eax,%eax
f010303a:	79 24                	jns    f0103060 <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f010303c:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f0103041:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103045:	8b 43 48             	mov    0x48(%ebx),%eax
f0103048:	89 44 24 04          	mov    %eax,0x4(%esp)
f010304c:	c7 04 24 d4 5f 10 f0 	movl   $0xf0105fd4,(%esp)
f0103053:	e8 e1 07 00 00       	call   f0103839 <cprintf>
		env_destroy(env);	// may not return
f0103058:	89 1c 24             	mov    %ebx,(%esp)
f010305b:	e8 a5 06 00 00       	call   f0103705 <env_destroy>
}
f0103060:	83 c4 14             	add    $0x14,%esp
f0103063:	5b                   	pop    %ebx
f0103064:	5d                   	pop    %ebp
f0103065:	c3                   	ret    

f0103066 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103066:	55                   	push   %ebp
f0103067:	89 e5                	mov    %esp,%ebp
f0103069:	57                   	push   %edi
f010306a:	56                   	push   %esi
f010306b:	53                   	push   %ebx
f010306c:	83 ec 1c             	sub    $0x1c,%esp
f010306f:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f0103071:	89 d3                	mov    %edx,%ebx
f0103073:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
f0103079:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103080:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	void* i;
	int ret;
	for(i=start; i<end; i+=PGSIZE) {
f0103086:	eb 71                	jmp    f01030f9 <region_alloc+0x93>
		p = page_alloc(0);
f0103088:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010308f:	e8 21 de ff ff       	call   f0100eb5 <page_alloc>
		if(p == NULL)
f0103094:	85 c0                	test   %eax,%eax
f0103096:	75 1c                	jne    f01030b4 <region_alloc+0x4e>
			panic("region_alloc error: physical page allocation failed!\n");
f0103098:	c7 44 24 08 fc 62 10 	movl   $0xf01062fc,0x8(%esp)
f010309f:	f0 
f01030a0:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
f01030a7:	00 
f01030a8:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01030af:	e8 02 d0 ff ff       	call   f01000b6 <_panic>
		ret = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f01030b4:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01030bb:	00 
f01030bc:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030c4:	8b 47 5c             	mov    0x5c(%edi),%eax
f01030c7:	89 04 24             	mov    %eax,(%esp)
f01030ca:	e8 1a e1 ff ff       	call   f01011e9 <page_insert>
		if(ret != 0) {
f01030cf:	85 c0                	test   %eax,%eax
f01030d1:	74 20                	je     f01030f3 <region_alloc+0x8d>
			panic("region_alloc error: page mapping failed! %e\n", ret);
f01030d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030d7:	c7 44 24 08 34 63 10 	movl   $0xf0106334,0x8(%esp)
f01030de:	f0 
f01030df:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f01030e6:	00 
f01030e7:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01030ee:	e8 c3 cf ff ff       	call   f01000b6 <_panic>
	for(i=start; i<end; i+=PGSIZE) {
f01030f3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01030f9:	39 f3                	cmp    %esi,%ebx
f01030fb:	72 8b                	jb     f0103088 <region_alloc+0x22>
		}
	}
}
f01030fd:	83 c4 1c             	add    $0x1c,%esp
f0103100:	5b                   	pop    %ebx
f0103101:	5e                   	pop    %esi
f0103102:	5f                   	pop    %edi
f0103103:	5d                   	pop    %ebp
f0103104:	c3                   	ret    

f0103105 <envid2env>:
{
f0103105:	55                   	push   %ebp
f0103106:	89 e5                	mov    %esp,%ebp
f0103108:	8b 45 08             	mov    0x8(%ebp),%eax
f010310b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	if (envid == 0) {
f010310e:	85 c0                	test   %eax,%eax
f0103110:	75 11                	jne    f0103123 <envid2env+0x1e>
		*env_store = curenv;
f0103112:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103117:	8b 55 0c             	mov    0xc(%ebp),%edx
f010311a:	89 02                	mov    %eax,(%edx)
		return 0;
f010311c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103121:	eb 5e                	jmp    f0103181 <envid2env+0x7c>
	e = &envs[ENVX(envid)];
f0103123:	89 c2                	mov    %eax,%edx
f0103125:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010312b:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010312e:	c1 e2 05             	shl    $0x5,%edx
f0103131:	03 15 8c df 17 f0    	add    0xf017df8c,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103137:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f010313b:	74 05                	je     f0103142 <envid2env+0x3d>
f010313d:	39 42 48             	cmp    %eax,0x48(%edx)
f0103140:	74 10                	je     f0103152 <envid2env+0x4d>
		*env_store = 0;
f0103142:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103145:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f010314b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103150:	eb 2f                	jmp    f0103181 <envid2env+0x7c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103152:	84 c9                	test   %cl,%cl
f0103154:	74 21                	je     f0103177 <envid2env+0x72>
f0103156:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010315b:	39 c2                	cmp    %eax,%edx
f010315d:	74 18                	je     f0103177 <envid2env+0x72>
f010315f:	8b 48 48             	mov    0x48(%eax),%ecx
f0103162:	39 4a 4c             	cmp    %ecx,0x4c(%edx)
f0103165:	74 10                	je     f0103177 <envid2env+0x72>
		*env_store = 0;
f0103167:	8b 45 0c             	mov    0xc(%ebp),%eax
f010316a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103170:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103175:	eb 0a                	jmp    f0103181 <envid2env+0x7c>
	*env_store = e;
f0103177:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010317a:	89 11                	mov    %edx,(%ecx)
	return 0;
f010317c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103181:	5d                   	pop    %ebp
f0103182:	c3                   	ret    

f0103183 <env_init_percpu>:
{
f0103183:	55                   	push   %ebp
f0103184:	89 e5                	mov    %esp,%ebp
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103186:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f010318b:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010318e:	b8 23 00 00 00       	mov    $0x23,%eax
f0103193:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103195:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103197:	b0 10                	mov    $0x10,%al
f0103199:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010319b:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010319d:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010319f:	ea a6 31 10 f0 08 00 	ljmp   $0x8,$0xf01031a6
	__asm __volatile("lldt %0" : : "r" (sel));
f01031a6:	b0 00                	mov    $0x0,%al
f01031a8:	0f 00 d0             	lldt   %ax
}
f01031ab:	5d                   	pop    %ebp
f01031ac:	c3                   	ret    

f01031ad <env_init>:
{
f01031ad:	55                   	push   %ebp
f01031ae:	89 e5                	mov    %esp,%ebp
f01031b0:	56                   	push   %esi
f01031b1:	53                   	push   %ebx
		envs[i].env_id = 0;
f01031b2:	8b 35 8c df 17 f0    	mov    0xf017df8c,%esi
env_init(void)
f01031b8:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01031be:	ba 00 04 00 00       	mov    $0x400,%edx
f01031c3:	b9 00 00 00 00       	mov    $0x0,%ecx
		envs[i].env_id = 0;
f01031c8:	89 c3                	mov    %eax,%ebx
f01031ca:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_parent_id = 0;
f01031d1:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		envs[i].env_type = ENV_TYPE_USER;
f01031d8:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
		envs[i].env_status = ENV_FREE;
f01031df:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_runs = 0;
f01031e6:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
		envs[i].env_link = env_free_list;
f01031ed:	89 48 44             	mov    %ecx,0x44(%eax)
f01031f0:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f01031f3:	89 d9                	mov    %ebx,%ecx
	for(i = NENV - 1; i >= 0; i--) {
f01031f5:	83 ea 01             	sub    $0x1,%edx
f01031f8:	75 ce                	jne    f01031c8 <env_init+0x1b>
f01031fa:	89 35 90 df 17 f0    	mov    %esi,0xf017df90
	env_init_percpu();
f0103200:	e8 7e ff ff ff       	call   f0103183 <env_init_percpu>
}
f0103205:	5b                   	pop    %ebx
f0103206:	5e                   	pop    %esi
f0103207:	5d                   	pop    %ebp
f0103208:	c3                   	ret    

f0103209 <env_alloc>:
{
f0103209:	55                   	push   %ebp
f010320a:	89 e5                	mov    %esp,%ebp
f010320c:	53                   	push   %ebx
f010320d:	83 ec 14             	sub    $0x14,%esp
	if (!(e = env_free_list))
f0103210:	8b 1d 90 df 17 f0    	mov    0xf017df90,%ebx
f0103216:	85 db                	test   %ebx,%ebx
f0103218:	0f 84 6d 01 00 00    	je     f010338b <env_alloc+0x182>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010321e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103225:	e8 8b dc ff ff       	call   f0100eb5 <page_alloc>
f010322a:	85 c0                	test   %eax,%eax
f010322c:	0f 84 60 01 00 00    	je     f0103392 <env_alloc+0x189>
f0103232:	89 c2                	mov    %eax,%edx
f0103234:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f010323a:	c1 fa 03             	sar    $0x3,%edx
f010323d:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0103240:	89 d1                	mov    %edx,%ecx
f0103242:	c1 e9 0c             	shr    $0xc,%ecx
f0103245:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f010324b:	72 20                	jb     f010326d <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010324d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103251:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f0103258:	f0 
f0103259:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0103260:	00 
f0103261:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0103268:	e8 49 ce ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010326d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103273:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f0103276:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f010327b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103282:	00 
f0103283:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0103288:	89 44 24 04          	mov    %eax,0x4(%esp)
f010328c:	8b 43 5c             	mov    0x5c(%ebx),%eax
f010328f:	89 04 24             	mov    %eax,(%esp)
f0103292:	e8 6a 1b 00 00       	call   f0104e01 <memmove>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103297:	8b 43 5c             	mov    0x5c(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f010329a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010329f:	77 20                	ja     f01032c1 <env_alloc+0xb8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032a5:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f01032ac:	f0 
f01032ad:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f01032b4:	00 
f01032b5:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01032bc:	e8 f5 cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032c1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01032c7:	83 ca 05             	or     $0x5,%edx
f01032ca:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01032d0:	8b 43 48             	mov    0x48(%ebx),%eax
f01032d3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01032d8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01032dd:	ba 00 10 00 00       	mov    $0x1000,%edx
f01032e2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01032e5:	89 da                	mov    %ebx,%edx
f01032e7:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f01032ed:	c1 fa 05             	sar    $0x5,%edx
f01032f0:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032f6:	09 d0                	or     %edx,%eax
f01032f8:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f01032fb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032fe:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103301:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103308:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010330f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103316:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f010331d:	00 
f010331e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103325:	00 
f0103326:	89 1c 24             	mov    %ebx,(%esp)
f0103329:	e8 75 1a 00 00       	call   f0104da3 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f010332e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103334:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010333a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103340:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103347:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	env_free_list = e->env_link;
f010334d:	8b 43 44             	mov    0x44(%ebx),%eax
f0103350:	a3 90 df 17 f0       	mov    %eax,0xf017df90
	*newenv_store = e;
f0103355:	8b 45 08             	mov    0x8(%ebp),%eax
f0103358:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010335a:	8b 53 48             	mov    0x48(%ebx),%edx
f010335d:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103362:	85 c0                	test   %eax,%eax
f0103364:	74 05                	je     f010336b <env_alloc+0x162>
f0103366:	8b 40 48             	mov    0x48(%eax),%eax
f0103369:	eb 05                	jmp    f0103370 <env_alloc+0x167>
f010336b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103370:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103374:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103378:	c7 04 24 35 64 10 f0 	movl   $0xf0106435,(%esp)
f010337f:	e8 b5 04 00 00       	call   f0103839 <cprintf>
	return 0;
f0103384:	b8 00 00 00 00       	mov    $0x0,%eax
f0103389:	eb 0c                	jmp    f0103397 <env_alloc+0x18e>
		return -E_NO_FREE_ENV;
f010338b:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103390:	eb 05                	jmp    f0103397 <env_alloc+0x18e>
		return -E_NO_MEM;
f0103392:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0103397:	83 c4 14             	add    $0x14,%esp
f010339a:	5b                   	pop    %ebx
f010339b:	5d                   	pop    %ebp
f010339c:	c3                   	ret    

f010339d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010339d:	55                   	push   %ebp
f010339e:	89 e5                	mov    %esp,%ebp
f01033a0:	57                   	push   %edi
f01033a1:	56                   	push   %esi
f01033a2:	53                   	push   %ebx
f01033a3:	83 ec 3c             	sub    $0x3c,%esp
f01033a6:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int ret;
	if ((ret = env_alloc(&e, 0)) != 0)
f01033a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01033b0:	00 
f01033b1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01033b4:	89 04 24             	mov    %eax,(%esp)
f01033b7:	e8 4d fe ff ff       	call   f0103209 <env_alloc>
f01033bc:	85 c0                	test   %eax,%eax
f01033be:	74 1c                	je     f01033dc <env_create+0x3f>
		panic("env_create failed: env_alloc failed!\n");
f01033c0:	c7 44 24 08 64 63 10 	movl   $0xf0106364,0x8(%esp)
f01033c7:	f0 
f01033c8:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
f01033cf:	00 
f01033d0:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01033d7:	e8 da cc ff ff       	call   f01000b6 <_panic>

	load_icode(e, binary);
f01033dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033df:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (header->e_magic != ELF_MAGIC)
f01033e2:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01033e8:	74 1c                	je     f0103406 <env_create+0x69>
		panic("load_icode error: The binary we load is not elf!\n");
f01033ea:	c7 44 24 08 8c 63 10 	movl   $0xf010638c,0x8(%esp)
f01033f1:	f0 
f01033f2:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
f01033f9:	00 
f01033fa:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f0103401:	e8 b0 cc ff ff       	call   f01000b6 <_panic>
	if (header->e_entry == 0)
f0103406:	8b 47 18             	mov    0x18(%edi),%eax
f0103409:	85 c0                	test   %eax,%eax
f010340b:	75 1c                	jne    f0103429 <env_create+0x8c>
		panic("load_icode error: The elf file can't be executed!\n");
f010340d:	c7 44 24 08 c0 63 10 	movl   $0xf01063c0,0x8(%esp)
f0103414:	f0 
f0103415:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f010341c:	00 
f010341d:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f0103424:	e8 8d cc ff ff       	call   f01000b6 <_panic>
	e->env_tf.tf_eip = header->e_entry;
f0103429:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010342c:	89 42 30             	mov    %eax,0x30(%edx)
	lcr3(PADDR(e->env_pgdir));
f010342f:	8b 42 5c             	mov    0x5c(%edx),%eax
	if ((uint32_t)kva < KERNBASE)
f0103432:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103437:	77 20                	ja     f0103459 <env_create+0xbc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103439:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010343d:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f0103444:	f0 
f0103445:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f010344c:	00 
f010344d:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f0103454:	e8 5d cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103459:	05 00 00 00 10       	add    $0x10000000,%eax
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010345e:	0f 22 d8             	mov    %eax,%cr3
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f0103461:	89 fb                	mov    %edi,%ebx
f0103463:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + header->e_phnum;
f0103466:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f010346a:	c1 e6 05             	shl    $0x5,%esi
f010346d:	01 de                	add    %ebx,%esi
f010346f:	eb 50                	jmp    f01034c1 <env_create+0x124>
		if(ph->p_type == ELF_PROG_LOAD) {
f0103471:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103474:	75 48                	jne    f01034be <env_create+0x121>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103476:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103479:	8b 53 08             	mov    0x8(%ebx),%edx
f010347c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010347f:	e8 e2 fb ff ff       	call   f0103066 <region_alloc>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103484:	8b 43 10             	mov    0x10(%ebx),%eax
f0103487:	89 44 24 08          	mov    %eax,0x8(%esp)
f010348b:	89 f8                	mov    %edi,%eax
f010348d:	03 43 04             	add    0x4(%ebx),%eax
f0103490:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103494:	8b 43 08             	mov    0x8(%ebx),%eax
f0103497:	89 04 24             	mov    %eax,(%esp)
f010349a:	e8 62 19 00 00       	call   f0104e01 <memmove>
			memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f010349f:	8b 43 10             	mov    0x10(%ebx),%eax
f01034a2:	8b 53 14             	mov    0x14(%ebx),%edx
f01034a5:	29 c2                	sub    %eax,%edx
f01034a7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01034ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01034b2:	00 
f01034b3:	03 43 08             	add    0x8(%ebx),%eax
f01034b6:	89 04 24             	mov    %eax,(%esp)
f01034b9:	e8 e5 18 00 00       	call   f0104da3 <memset>
	for(; ph < eph; ph++) {
f01034be:	83 c3 20             	add    $0x20,%ebx
f01034c1:	39 de                	cmp    %ebx,%esi
f01034c3:	77 ac                	ja     f0103471 <env_create+0xd4>
	region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f01034c5:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01034ca:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01034cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01034d2:	e8 8f fb ff ff       	call   f0103066 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01034d7:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
	if ((uint32_t)kva < KERNBASE)
f01034dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034e1:	77 20                	ja     f0103503 <env_create+0x166>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034e7:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f01034ee:	f0 
f01034ef:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
f01034f6:	00 
f01034f7:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01034fe:	e8 b3 cb ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103503:	05 00 00 00 10       	add    $0x10000000,%eax
f0103508:	0f 22 d8             	mov    %eax,%cr3
	e->env_type = type;
f010350b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010350e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103511:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103514:	83 c4 3c             	add    $0x3c,%esp
f0103517:	5b                   	pop    %ebx
f0103518:	5e                   	pop    %esi
f0103519:	5f                   	pop    %edi
f010351a:	5d                   	pop    %ebp
f010351b:	c3                   	ret    

f010351c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010351c:	55                   	push   %ebp
f010351d:	89 e5                	mov    %esp,%ebp
f010351f:	57                   	push   %edi
f0103520:	56                   	push   %esi
f0103521:	53                   	push   %ebx
f0103522:	83 ec 2c             	sub    $0x2c,%esp
f0103525:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103528:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010352d:	39 c7                	cmp    %eax,%edi
f010352f:	75 37                	jne    f0103568 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103531:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
	if ((uint32_t)kva < KERNBASE)
f0103537:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010353d:	77 20                	ja     f010355f <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010353f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103543:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f010354a:	f0 
f010354b:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
f0103552:	00 
f0103553:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f010355a:	e8 57 cb ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010355f:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103565:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103568:	8b 57 48             	mov    0x48(%edi),%edx
f010356b:	85 c0                	test   %eax,%eax
f010356d:	74 05                	je     f0103574 <env_free+0x58>
f010356f:	8b 40 48             	mov    0x48(%eax),%eax
f0103572:	eb 05                	jmp    f0103579 <env_free+0x5d>
f0103574:	b8 00 00 00 00       	mov    $0x0,%eax
f0103579:	89 54 24 08          	mov    %edx,0x8(%esp)
f010357d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103581:	c7 04 24 4a 64 10 f0 	movl   $0xf010644a,(%esp)
f0103588:	e8 ac 02 00 00       	call   f0103839 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010358d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
env_free(struct Env *e)
f0103594:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103597:	c1 e0 02             	shl    $0x2,%eax
f010359a:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010359d:	8b 47 5c             	mov    0x5c(%edi),%eax
f01035a0:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035a3:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01035a6:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01035ac:	0f 84 b7 00 00 00    	je     f0103669 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01035b2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f01035b8:	89 f0                	mov    %esi,%eax
f01035ba:	c1 e8 0c             	shr    $0xc,%eax
f01035bd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01035c0:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01035c6:	72 20                	jb     f01035e8 <env_free+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01035c8:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01035cc:	c7 44 24 08 04 58 10 	movl   $0xf0105804,0x8(%esp)
f01035d3:	f0 
f01035d4:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
f01035db:	00 
f01035dc:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01035e3:	e8 ce ca ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01035e8:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035eb:	c1 e2 16             	shl    $0x16,%edx
f01035ee:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01035f1:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01035f6:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01035fd:	01 
f01035fe:	74 17                	je     f0103617 <env_free+0xfb>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103600:	89 d8                	mov    %ebx,%eax
f0103602:	c1 e0 0c             	shl    $0xc,%eax
f0103605:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103608:	89 44 24 04          	mov    %eax,0x4(%esp)
f010360c:	8b 47 5c             	mov    0x5c(%edi),%eax
f010360f:	89 04 24             	mov    %eax,(%esp)
f0103612:	e8 82 db ff ff       	call   f0101199 <page_remove>
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103617:	83 c3 01             	add    $0x1,%ebx
f010361a:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103620:	75 d4                	jne    f01035f6 <env_free+0xda>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103622:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103625:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103628:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f010362f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103632:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f0103638:	72 1c                	jb     f0103656 <env_free+0x13a>
		panic("pa2page called with invalid pa");
f010363a:	c7 44 24 08 58 59 10 	movl   $0xf0105958,0x8(%esp)
f0103641:	f0 
f0103642:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103649:	00 
f010364a:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f0103651:	e8 60 ca ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103656:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f010365b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010365e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103661:	89 04 24             	mov    %eax,(%esp)
f0103664:	e8 10 d9 ff ff       	call   f0100f79 <page_decref>
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103669:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010366d:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103674:	0f 85 1a ff ff ff    	jne    f0103594 <env_free+0x78>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010367a:	8b 47 5c             	mov    0x5c(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f010367d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103682:	77 20                	ja     f01036a4 <env_free+0x188>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103684:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103688:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f010368f:	f0 
f0103690:	c7 44 24 04 bf 01 00 	movl   $0x1bf,0x4(%esp)
f0103697:	00 
f0103698:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f010369f:	e8 12 ca ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f01036a4:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01036ab:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f01036b0:	c1 e8 0c             	shr    $0xc,%eax
f01036b3:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01036b9:	72 1c                	jb     f01036d7 <env_free+0x1bb>
		panic("pa2page called with invalid pa");
f01036bb:	c7 44 24 08 58 59 10 	movl   $0xf0105958,0x8(%esp)
f01036c2:	f0 
f01036c3:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01036ca:	00 
f01036cb:	c7 04 24 25 60 10 f0 	movl   $0xf0106025,(%esp)
f01036d2:	e8 df c9 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01036d7:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
f01036dd:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f01036e0:	89 04 24             	mov    %eax,(%esp)
f01036e3:	e8 91 d8 ff ff       	call   f0100f79 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01036e8:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01036ef:	a1 90 df 17 f0       	mov    0xf017df90,%eax
f01036f4:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01036f7:	89 3d 90 df 17 f0    	mov    %edi,0xf017df90
}
f01036fd:	83 c4 2c             	add    $0x2c,%esp
f0103700:	5b                   	pop    %ebx
f0103701:	5e                   	pop    %esi
f0103702:	5f                   	pop    %edi
f0103703:	5d                   	pop    %ebp
f0103704:	c3                   	ret    

f0103705 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103705:	55                   	push   %ebp
f0103706:	89 e5                	mov    %esp,%ebp
f0103708:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f010370b:	8b 45 08             	mov    0x8(%ebp),%eax
f010370e:	89 04 24             	mov    %eax,(%esp)
f0103711:	e8 06 fe ff ff       	call   f010351c <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103716:	c7 04 24 f4 63 10 f0 	movl   $0xf01063f4,(%esp)
f010371d:	e8 17 01 00 00       	call   f0103839 <cprintf>
	while (1)
		monitor(NULL);
f0103722:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103729:	e8 be d0 ff ff       	call   f01007ec <monitor>
f010372e:	eb f2                	jmp    f0103722 <env_destroy+0x1d>

f0103730 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103730:	55                   	push   %ebp
f0103731:	89 e5                	mov    %esp,%ebp
f0103733:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103736:	8b 65 08             	mov    0x8(%ebp),%esp
f0103739:	61                   	popa   
f010373a:	07                   	pop    %es
f010373b:	1f                   	pop    %ds
f010373c:	83 c4 08             	add    $0x8,%esp
f010373f:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103740:	c7 44 24 08 60 64 10 	movl   $0xf0106460,0x8(%esp)
f0103747:	f0 
f0103748:	c7 44 24 04 e7 01 00 	movl   $0x1e7,0x4(%esp)
f010374f:	00 
f0103750:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f0103757:	e8 5a c9 ff ff       	call   f01000b6 <_panic>

f010375c <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010375c:	55                   	push   %ebp
f010375d:	89 e5                	mov    %esp,%ebp
f010375f:	83 ec 18             	sub    $0x18,%esp
f0103762:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING)
f0103765:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f010376b:	85 d2                	test   %edx,%edx
f010376d:	74 0d                	je     f010377c <env_run+0x20>
f010376f:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103773:	75 07                	jne    f010377c <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0103775:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)

	curenv = e;
f010377c:	a3 88 df 17 f0       	mov    %eax,0xf017df88
	curenv->env_status = ENV_RUNNING;
f0103781:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103788:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f010378c:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f010378f:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103795:	77 20                	ja     f01037b7 <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103797:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010379b:	c7 44 24 08 28 58 10 	movl   $0xf0105828,0x8(%esp)
f01037a2:	f0 
f01037a3:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
f01037aa:	00 
f01037ab:	c7 04 24 2a 64 10 f0 	movl   $0xf010642a,(%esp)
f01037b2:	e8 ff c8 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01037b7:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01037bd:	0f 22 da             	mov    %edx,%cr3

	env_pop_tf(&curenv->env_tf);
f01037c0:	89 04 24             	mov    %eax,(%esp)
f01037c3:	e8 68 ff ff ff       	call   f0103730 <env_pop_tf>

f01037c8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01037c8:	55                   	push   %ebp
f01037c9:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01037cb:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01037cf:	ba 70 00 00 00       	mov    $0x70,%edx
f01037d4:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01037d5:	b2 71                	mov    $0x71,%dl
f01037d7:	ec                   	in     (%dx),%al
	return inb(IO_RTC+1);
f01037d8:	0f b6 c0             	movzbl %al,%eax
}
f01037db:	5d                   	pop    %ebp
f01037dc:	c3                   	ret    

f01037dd <mc146818_write>:
{
f01037dd:	55                   	push   %ebp
f01037de:	89 e5                	mov    %esp,%ebp
}
f01037e0:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01037e4:	ba 70 00 00 00       	mov    $0x70,%edx
f01037e9:	ee                   	out    %al,(%dx)
f01037ea:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f01037ee:	b2 71                	mov    $0x71,%dl
f01037f0:	ee                   	out    %al,(%dx)
f01037f1:	5d                   	pop    %ebp
f01037f2:	c3                   	ret    

f01037f3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01037f3:	55                   	push   %ebp
f01037f4:	89 e5                	mov    %esp,%ebp
f01037f6:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01037f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01037fc:	89 04 24             	mov    %eax,(%esp)
f01037ff:	e8 0b ce ff ff       	call   f010060f <cputchar>
	*cnt++;
}
f0103804:	c9                   	leave  
f0103805:	c3                   	ret    

f0103806 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103806:	55                   	push   %ebp
f0103807:	89 e5                	mov    %esp,%ebp
f0103809:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010380c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103813:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103816:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010381a:	8b 45 08             	mov    0x8(%ebp),%eax
f010381d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103821:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103824:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103828:	c7 04 24 f3 37 10 f0 	movl   $0xf01037f3,(%esp)
f010382f:	e8 a1 0e 00 00       	call   f01046d5 <vprintfmt>
	return cnt;
}
f0103834:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103837:	c9                   	leave  
f0103838:	c3                   	ret    

f0103839 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103839:	55                   	push   %ebp
f010383a:	89 e5                	mov    %esp,%ebp
f010383c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010383f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103842:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103846:	8b 45 08             	mov    0x8(%ebp),%eax
f0103849:	89 04 24             	mov    %eax,(%esp)
f010384c:	e8 b5 ff ff ff       	call   f0103806 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103851:	c9                   	leave  
f0103852:	c3                   	ret    
f0103853:	66 90                	xchg   %ax,%ax
f0103855:	66 90                	xchg   %ax,%ax
f0103857:	66 90                	xchg   %ax,%ax
f0103859:	66 90                	xchg   %ax,%ax
f010385b:	66 90                	xchg   %ax,%ax
f010385d:	66 90                	xchg   %ax,%ax
f010385f:	90                   	nop

f0103860 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103860:	55                   	push   %ebp
f0103861:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103863:	c7 05 a4 e7 17 f0 00 	movl   $0xf0000000,0xf017e7a4
f010386a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010386d:	66 c7 05 a8 e7 17 f0 	movw   $0x10,0xf017e7a8
f0103874:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103876:	66 c7 05 48 c3 11 f0 	movw   $0x67,0xf011c348
f010387d:	67 00 
f010387f:	b8 a0 e7 17 f0       	mov    $0xf017e7a0,%eax
f0103884:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f010388a:	89 c2                	mov    %eax,%edx
f010388c:	c1 ea 10             	shr    $0x10,%edx
f010388f:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103895:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f010389c:	c1 e8 18             	shr    $0x18,%eax
f010389f:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01038a4:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
	__asm __volatile("ltr %0" : : "r" (sel));
f01038ab:	b8 28 00 00 00       	mov    $0x28,%eax
f01038b0:	0f 00 d8             	ltr    %ax
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038b3:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f01038b8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01038bb:	5d                   	pop    %ebp
f01038bc:	c3                   	ret    

f01038bd <trap_init>:
{
f01038bd:	55                   	push   %ebp
f01038be:	89 e5                	mov    %esp,%ebp
	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_handler, 0);
f01038c0:	b8 fc 3f 10 f0       	mov    $0xf0103ffc,%eax
f01038c5:	66 a3 a0 df 17 f0    	mov    %ax,0xf017dfa0
f01038cb:	66 c7 05 a2 df 17 f0 	movw   $0x8,0xf017dfa2
f01038d2:	08 00 
f01038d4:	c6 05 a4 df 17 f0 00 	movb   $0x0,0xf017dfa4
f01038db:	c6 05 a5 df 17 f0 8f 	movb   $0x8f,0xf017dfa5
f01038e2:	c1 e8 10             	shr    $0x10,%eax
f01038e5:	66 a3 a6 df 17 f0    	mov    %ax,0xf017dfa6
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_handler, 0);
f01038eb:	b8 02 40 10 f0       	mov    $0xf0104002,%eax
f01038f0:	66 a3 a8 df 17 f0    	mov    %ax,0xf017dfa8
f01038f6:	66 c7 05 aa df 17 f0 	movw   $0x8,0xf017dfaa
f01038fd:	08 00 
f01038ff:	c6 05 ac df 17 f0 00 	movb   $0x0,0xf017dfac
f0103906:	c6 05 ad df 17 f0 8f 	movb   $0x8f,0xf017dfad
f010390d:	c1 e8 10             	shr    $0x10,%eax
f0103910:	66 a3 ae df 17 f0    	mov    %ax,0xf017dfae
	SETGATE(idt[T_NMI], 0, GD_KT, nmi_handler, 0);//non-maskable interrupt
f0103916:	b8 08 40 10 f0       	mov    $0xf0104008,%eax
f010391b:	66 a3 b0 df 17 f0    	mov    %ax,0xf017dfb0
f0103921:	66 c7 05 b2 df 17 f0 	movw   $0x8,0xf017dfb2
f0103928:	08 00 
f010392a:	c6 05 b4 df 17 f0 00 	movb   $0x0,0xf017dfb4
f0103931:	c6 05 b5 df 17 f0 8e 	movb   $0x8e,0xf017dfb5
f0103938:	c1 e8 10             	shr    $0x10,%eax
f010393b:	66 a3 b6 df 17 f0    	mov    %ax,0xf017dfb6
	SETGATE(idt[T_BRKPT], 1, GD_KT, brkpt_handler, 3);
f0103941:	b8 0e 40 10 f0       	mov    $0xf010400e,%eax
f0103946:	66 a3 b8 df 17 f0    	mov    %ax,0xf017dfb8
f010394c:	66 c7 05 ba df 17 f0 	movw   $0x8,0xf017dfba
f0103953:	08 00 
f0103955:	c6 05 bc df 17 f0 00 	movb   $0x0,0xf017dfbc
f010395c:	c6 05 bd df 17 f0 ef 	movb   $0xef,0xf017dfbd
f0103963:	c1 e8 10             	shr    $0x10,%eax
f0103966:	66 a3 be df 17 f0    	mov    %ax,0xf017dfbe
	SETGATE(idt[T_OFLOW], 1, GD_KT, oflow_handler, 0);
f010396c:	b8 14 40 10 f0       	mov    $0xf0104014,%eax
f0103971:	66 a3 c0 df 17 f0    	mov    %ax,0xf017dfc0
f0103977:	66 c7 05 c2 df 17 f0 	movw   $0x8,0xf017dfc2
f010397e:	08 00 
f0103980:	c6 05 c4 df 17 f0 00 	movb   $0x0,0xf017dfc4
f0103987:	c6 05 c5 df 17 f0 8f 	movb   $0x8f,0xf017dfc5
f010398e:	c1 e8 10             	shr    $0x10,%eax
f0103991:	66 a3 c6 df 17 f0    	mov    %ax,0xf017dfc6
	SETGATE(idt[T_BOUND], 1, GD_KT, bound_handler, 0);
f0103997:	b8 1a 40 10 f0       	mov    $0xf010401a,%eax
f010399c:	66 a3 c8 df 17 f0    	mov    %ax,0xf017dfc8
f01039a2:	66 c7 05 ca df 17 f0 	movw   $0x8,0xf017dfca
f01039a9:	08 00 
f01039ab:	c6 05 cc df 17 f0 00 	movb   $0x0,0xf017dfcc
f01039b2:	c6 05 cd df 17 f0 8f 	movb   $0x8f,0xf017dfcd
f01039b9:	c1 e8 10             	shr    $0x10,%eax
f01039bc:	66 a3 ce df 17 f0    	mov    %ax,0xf017dfce
	SETGATE(idt[T_ILLOP], 1, GD_KT, illop_handler, 0);
f01039c2:	b8 20 40 10 f0       	mov    $0xf0104020,%eax
f01039c7:	66 a3 d0 df 17 f0    	mov    %ax,0xf017dfd0
f01039cd:	66 c7 05 d2 df 17 f0 	movw   $0x8,0xf017dfd2
f01039d4:	08 00 
f01039d6:	c6 05 d4 df 17 f0 00 	movb   $0x0,0xf017dfd4
f01039dd:	c6 05 d5 df 17 f0 8f 	movb   $0x8f,0xf017dfd5
f01039e4:	c1 e8 10             	shr    $0x10,%eax
f01039e7:	66 a3 d6 df 17 f0    	mov    %ax,0xf017dfd6
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_handler, 0);
f01039ed:	b8 26 40 10 f0       	mov    $0xf0104026,%eax
f01039f2:	66 a3 d8 df 17 f0    	mov    %ax,0xf017dfd8
f01039f8:	66 c7 05 da df 17 f0 	movw   $0x8,0xf017dfda
f01039ff:	08 00 
f0103a01:	c6 05 dc df 17 f0 00 	movb   $0x0,0xf017dfdc
f0103a08:	c6 05 dd df 17 f0 8f 	movb   $0x8f,0xf017dfdd
f0103a0f:	c1 e8 10             	shr    $0x10,%eax
f0103a12:	66 a3 de df 17 f0    	mov    %ax,0xf017dfde
	SETGATE(idt[T_DBLFLT], 1, GD_KT, dblflt_handler, 0);
f0103a18:	b8 2c 40 10 f0       	mov    $0xf010402c,%eax
f0103a1d:	66 a3 e0 df 17 f0    	mov    %ax,0xf017dfe0
f0103a23:	66 c7 05 e2 df 17 f0 	movw   $0x8,0xf017dfe2
f0103a2a:	08 00 
f0103a2c:	c6 05 e4 df 17 f0 00 	movb   $0x0,0xf017dfe4
f0103a33:	c6 05 e5 df 17 f0 8f 	movb   $0x8f,0xf017dfe5
f0103a3a:	c1 e8 10             	shr    $0x10,%eax
f0103a3d:	66 a3 e6 df 17 f0    	mov    %ax,0xf017dfe6
	SETGATE(idt[T_TSS], 1, GD_KT, tss_handler, 0);
f0103a43:	b8 30 40 10 f0       	mov    $0xf0104030,%eax
f0103a48:	66 a3 f0 df 17 f0    	mov    %ax,0xf017dff0
f0103a4e:	66 c7 05 f2 df 17 f0 	movw   $0x8,0xf017dff2
f0103a55:	08 00 
f0103a57:	c6 05 f4 df 17 f0 00 	movb   $0x0,0xf017dff4
f0103a5e:	c6 05 f5 df 17 f0 8f 	movb   $0x8f,0xf017dff5
f0103a65:	c1 e8 10             	shr    $0x10,%eax
f0103a68:	66 a3 f6 df 17 f0    	mov    %ax,0xf017dff6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segnp_handler, 0);
f0103a6e:	b8 34 40 10 f0       	mov    $0xf0104034,%eax
f0103a73:	66 a3 f8 df 17 f0    	mov    %ax,0xf017dff8
f0103a79:	66 c7 05 fa df 17 f0 	movw   $0x8,0xf017dffa
f0103a80:	08 00 
f0103a82:	c6 05 fc df 17 f0 00 	movb   $0x0,0xf017dffc
f0103a89:	c6 05 fd df 17 f0 8f 	movb   $0x8f,0xf017dffd
f0103a90:	c1 e8 10             	shr    $0x10,%eax
f0103a93:	66 a3 fe df 17 f0    	mov    %ax,0xf017dffe
	SETGATE(idt[T_STACK], 1, GD_KT, stack_handler, 0);
f0103a99:	b8 38 40 10 f0       	mov    $0xf0104038,%eax
f0103a9e:	66 a3 00 e0 17 f0    	mov    %ax,0xf017e000
f0103aa4:	66 c7 05 02 e0 17 f0 	movw   $0x8,0xf017e002
f0103aab:	08 00 
f0103aad:	c6 05 04 e0 17 f0 00 	movb   $0x0,0xf017e004
f0103ab4:	c6 05 05 e0 17 f0 8f 	movb   $0x8f,0xf017e005
f0103abb:	c1 e8 10             	shr    $0x10,%eax
f0103abe:	66 a3 06 e0 17 f0    	mov    %ax,0xf017e006
	SETGATE(idt[T_GPFLT], 1, GD_KT, gpflt_handler, 0);
f0103ac4:	b8 3c 40 10 f0       	mov    $0xf010403c,%eax
f0103ac9:	66 a3 08 e0 17 f0    	mov    %ax,0xf017e008
f0103acf:	66 c7 05 0a e0 17 f0 	movw   $0x8,0xf017e00a
f0103ad6:	08 00 
f0103ad8:	c6 05 0c e0 17 f0 00 	movb   $0x0,0xf017e00c
f0103adf:	c6 05 0d e0 17 f0 8f 	movb   $0x8f,0xf017e00d
f0103ae6:	c1 e8 10             	shr    $0x10,%eax
f0103ae9:	66 a3 0e e0 17 f0    	mov    %ax,0xf017e00e
	SETGATE(idt[T_PGFLT], 1, GD_KT, pgflt_handler, 0);
f0103aef:	b8 40 40 10 f0       	mov    $0xf0104040,%eax
f0103af4:	66 a3 10 e0 17 f0    	mov    %ax,0xf017e010
f0103afa:	66 c7 05 12 e0 17 f0 	movw   $0x8,0xf017e012
f0103b01:	08 00 
f0103b03:	c6 05 14 e0 17 f0 00 	movb   $0x0,0xf017e014
f0103b0a:	c6 05 15 e0 17 f0 8f 	movb   $0x8f,0xf017e015
f0103b11:	c1 e8 10             	shr    $0x10,%eax
f0103b14:	66 a3 16 e0 17 f0    	mov    %ax,0xf017e016
	SETGATE(idt[T_FPERR], 1, GD_KT, fperr_handler, 0);
f0103b1a:	b8 44 40 10 f0       	mov    $0xf0104044,%eax
f0103b1f:	66 a3 20 e0 17 f0    	mov    %ax,0xf017e020
f0103b25:	66 c7 05 22 e0 17 f0 	movw   $0x8,0xf017e022
f0103b2c:	08 00 
f0103b2e:	c6 05 24 e0 17 f0 00 	movb   $0x0,0xf017e024
f0103b35:	c6 05 25 e0 17 f0 8f 	movb   $0x8f,0xf017e025
f0103b3c:	c1 e8 10             	shr    $0x10,%eax
f0103b3f:	66 a3 26 e0 17 f0    	mov    %ax,0xf017e026
	SETGATE(idt[T_ALIGN], 1, GD_KT, align_handler, 0);
f0103b45:	b8 4a 40 10 f0       	mov    $0xf010404a,%eax
f0103b4a:	66 a3 28 e0 17 f0    	mov    %ax,0xf017e028
f0103b50:	66 c7 05 2a e0 17 f0 	movw   $0x8,0xf017e02a
f0103b57:	08 00 
f0103b59:	c6 05 2c e0 17 f0 00 	movb   $0x0,0xf017e02c
f0103b60:	c6 05 2d e0 17 f0 8f 	movb   $0x8f,0xf017e02d
f0103b67:	c1 e8 10             	shr    $0x10,%eax
f0103b6a:	66 a3 2e e0 17 f0    	mov    %ax,0xf017e02e
	SETGATE(idt[T_MCHK], 1, GD_KT, mchk_handler, 0);
f0103b70:	b8 4e 40 10 f0       	mov    $0xf010404e,%eax
f0103b75:	66 a3 30 e0 17 f0    	mov    %ax,0xf017e030
f0103b7b:	66 c7 05 32 e0 17 f0 	movw   $0x8,0xf017e032
f0103b82:	08 00 
f0103b84:	c6 05 34 e0 17 f0 00 	movb   $0x0,0xf017e034
f0103b8b:	c6 05 35 e0 17 f0 8f 	movb   $0x8f,0xf017e035
f0103b92:	c1 e8 10             	shr    $0x10,%eax
f0103b95:	66 a3 36 e0 17 f0    	mov    %ax,0xf017e036
	SETGATE(idt[T_SIMDERR], 1, GD_KT, simderr_handler, 0);
f0103b9b:	b8 54 40 10 f0       	mov    $0xf0104054,%eax
f0103ba0:	66 a3 38 e0 17 f0    	mov    %ax,0xf017e038
f0103ba6:	66 c7 05 3a e0 17 f0 	movw   $0x8,0xf017e03a
f0103bad:	08 00 
f0103baf:	c6 05 3c e0 17 f0 00 	movb   $0x0,0xf017e03c
f0103bb6:	c6 05 3d e0 17 f0 8f 	movb   $0x8f,0xf017e03d
f0103bbd:	c1 e8 10             	shr    $0x10,%eax
f0103bc0:	66 a3 3e e0 17 f0    	mov    %ax,0xf017e03e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, syscall_handler, 3);
f0103bc6:	b8 5a 40 10 f0       	mov    $0xf010405a,%eax
f0103bcb:	66 a3 20 e1 17 f0    	mov    %ax,0xf017e120
f0103bd1:	66 c7 05 22 e1 17 f0 	movw   $0x8,0xf017e122
f0103bd8:	08 00 
f0103bda:	c6 05 24 e1 17 f0 00 	movb   $0x0,0xf017e124
f0103be1:	c6 05 25 e1 17 f0 ee 	movb   $0xee,0xf017e125
f0103be8:	c1 e8 10             	shr    $0x10,%eax
f0103beb:	66 a3 26 e1 17 f0    	mov    %ax,0xf017e126
	trap_init_percpu();
f0103bf1:	e8 6a fc ff ff       	call   f0103860 <trap_init_percpu>
}
f0103bf6:	5d                   	pop    %ebp
f0103bf7:	c3                   	ret    

f0103bf8 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103bf8:	55                   	push   %ebp
f0103bf9:	89 e5                	mov    %esp,%ebp
f0103bfb:	53                   	push   %ebx
f0103bfc:	83 ec 14             	sub    $0x14,%esp
f0103bff:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103c02:	8b 03                	mov    (%ebx),%eax
f0103c04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c08:	c7 04 24 6c 64 10 f0 	movl   $0xf010646c,(%esp)
f0103c0f:	e8 25 fc ff ff       	call   f0103839 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103c14:	8b 43 04             	mov    0x4(%ebx),%eax
f0103c17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1b:	c7 04 24 7b 64 10 f0 	movl   $0xf010647b,(%esp)
f0103c22:	e8 12 fc ff ff       	call   f0103839 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103c27:	8b 43 08             	mov    0x8(%ebx),%eax
f0103c2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c2e:	c7 04 24 8a 64 10 f0 	movl   $0xf010648a,(%esp)
f0103c35:	e8 ff fb ff ff       	call   f0103839 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103c3a:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103c3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c41:	c7 04 24 99 64 10 f0 	movl   $0xf0106499,(%esp)
f0103c48:	e8 ec fb ff ff       	call   f0103839 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103c4d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103c50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c54:	c7 04 24 a8 64 10 f0 	movl   $0xf01064a8,(%esp)
f0103c5b:	e8 d9 fb ff ff       	call   f0103839 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103c60:	8b 43 14             	mov    0x14(%ebx),%eax
f0103c63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c67:	c7 04 24 b7 64 10 f0 	movl   $0xf01064b7,(%esp)
f0103c6e:	e8 c6 fb ff ff       	call   f0103839 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103c73:	8b 43 18             	mov    0x18(%ebx),%eax
f0103c76:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c7a:	c7 04 24 c6 64 10 f0 	movl   $0xf01064c6,(%esp)
f0103c81:	e8 b3 fb ff ff       	call   f0103839 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103c86:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103c89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c8d:	c7 04 24 d5 64 10 f0 	movl   $0xf01064d5,(%esp)
f0103c94:	e8 a0 fb ff ff       	call   f0103839 <cprintf>
}
f0103c99:	83 c4 14             	add    $0x14,%esp
f0103c9c:	5b                   	pop    %ebx
f0103c9d:	5d                   	pop    %ebp
f0103c9e:	c3                   	ret    

f0103c9f <print_trapframe>:
{
f0103c9f:	55                   	push   %ebp
f0103ca0:	89 e5                	mov    %esp,%ebp
f0103ca2:	56                   	push   %esi
f0103ca3:	53                   	push   %ebx
f0103ca4:	83 ec 10             	sub    $0x10,%esp
f0103ca7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103caa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103cae:	c7 04 24 0b 66 10 f0 	movl   $0xf010660b,(%esp)
f0103cb5:	e8 7f fb ff ff       	call   f0103839 <cprintf>
	print_regs(&tf->tf_regs);
f0103cba:	89 1c 24             	mov    %ebx,(%esp)
f0103cbd:	e8 36 ff ff ff       	call   f0103bf8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103cc2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103cc6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cca:	c7 04 24 26 65 10 f0 	movl   $0xf0106526,(%esp)
f0103cd1:	e8 63 fb ff ff       	call   f0103839 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103cd6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103cda:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cde:	c7 04 24 39 65 10 f0 	movl   $0xf0106539,(%esp)
f0103ce5:	e8 4f fb ff ff       	call   f0103839 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103cea:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103ced:	83 f8 13             	cmp    $0x13,%eax
f0103cf0:	77 09                	ja     f0103cfb <print_trapframe+0x5c>
		return excnames[trapno];
f0103cf2:	8b 14 85 20 68 10 f0 	mov    -0xfef97e0(,%eax,4),%edx
f0103cf9:	eb 10                	jmp    f0103d0b <print_trapframe+0x6c>
		return "System call";
f0103cfb:	83 f8 30             	cmp    $0x30,%eax
f0103cfe:	ba e4 64 10 f0       	mov    $0xf01064e4,%edx
f0103d03:	b9 f0 64 10 f0       	mov    $0xf01064f0,%ecx
f0103d08:	0f 45 d1             	cmovne %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103d0b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103d0f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d13:	c7 04 24 4c 65 10 f0 	movl   $0xf010654c,(%esp)
f0103d1a:	e8 1a fb ff ff       	call   f0103839 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103d1f:	3b 1d 08 e8 17 f0    	cmp    0xf017e808,%ebx
f0103d25:	75 19                	jne    f0103d40 <print_trapframe+0xa1>
f0103d27:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103d2b:	75 13                	jne    f0103d40 <print_trapframe+0xa1>
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103d2d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103d30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d34:	c7 04 24 5e 65 10 f0 	movl   $0xf010655e,(%esp)
f0103d3b:	e8 f9 fa ff ff       	call   f0103839 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103d40:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103d43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d47:	c7 04 24 6d 65 10 f0 	movl   $0xf010656d,(%esp)
f0103d4e:	e8 e6 fa ff ff       	call   f0103839 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103d53:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103d57:	75 51                	jne    f0103daa <print_trapframe+0x10b>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103d59:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0103d5c:	89 c2                	mov    %eax,%edx
f0103d5e:	83 e2 01             	and    $0x1,%edx
f0103d61:	ba ff 64 10 f0       	mov    $0xf01064ff,%edx
f0103d66:	b9 0a 65 10 f0       	mov    $0xf010650a,%ecx
f0103d6b:	0f 45 ca             	cmovne %edx,%ecx
f0103d6e:	89 c2                	mov    %eax,%edx
f0103d70:	83 e2 02             	and    $0x2,%edx
f0103d73:	ba 16 65 10 f0       	mov    $0xf0106516,%edx
f0103d78:	be 1c 65 10 f0       	mov    $0xf010651c,%esi
f0103d7d:	0f 44 d6             	cmove  %esi,%edx
f0103d80:	83 e0 04             	and    $0x4,%eax
f0103d83:	b8 21 65 10 f0       	mov    $0xf0106521,%eax
f0103d88:	be 36 66 10 f0       	mov    $0xf0106636,%esi
f0103d8d:	0f 44 c6             	cmove  %esi,%eax
f0103d90:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103d94:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103d98:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d9c:	c7 04 24 7b 65 10 f0 	movl   $0xf010657b,(%esp)
f0103da3:	e8 91 fa ff ff       	call   f0103839 <cprintf>
f0103da8:	eb 0c                	jmp    f0103db6 <print_trapframe+0x117>
		cprintf("\n");
f0103daa:	c7 04 24 ca 62 10 f0 	movl   $0xf01062ca,(%esp)
f0103db1:	e8 83 fa ff ff       	call   f0103839 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103db6:	8b 43 30             	mov    0x30(%ebx),%eax
f0103db9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dbd:	c7 04 24 8a 65 10 f0 	movl   $0xf010658a,(%esp)
f0103dc4:	e8 70 fa ff ff       	call   f0103839 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103dc9:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103dcd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dd1:	c7 04 24 99 65 10 f0 	movl   $0xf0106599,(%esp)
f0103dd8:	e8 5c fa ff ff       	call   f0103839 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103ddd:	8b 43 38             	mov    0x38(%ebx),%eax
f0103de0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103de4:	c7 04 24 ac 65 10 f0 	movl   $0xf01065ac,(%esp)
f0103deb:	e8 49 fa ff ff       	call   f0103839 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103df0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103df4:	74 27                	je     f0103e1d <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103df6:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103df9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dfd:	c7 04 24 bb 65 10 f0 	movl   $0xf01065bb,(%esp)
f0103e04:	e8 30 fa ff ff       	call   f0103839 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103e09:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103e0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e11:	c7 04 24 ca 65 10 f0 	movl   $0xf01065ca,(%esp)
f0103e18:	e8 1c fa ff ff       	call   f0103839 <cprintf>
}
f0103e1d:	83 c4 10             	add    $0x10,%esp
f0103e20:	5b                   	pop    %ebx
f0103e21:	5e                   	pop    %esi
f0103e22:	5d                   	pop    %ebp
f0103e23:	c3                   	ret    

f0103e24 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103e24:	55                   	push   %ebp
f0103e25:	89 e5                	mov    %esp,%ebp
f0103e27:	53                   	push   %ebx
f0103e28:	83 ec 14             	sub    $0x14,%esp
f0103e2b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103e2e:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) {
f0103e31:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103e35:	75 20                	jne    f0103e57 <page_fault_handler+0x33>
		panic("page_fault in kernel mode, fault address 0x%08x\n", fault_va);
f0103e37:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e3b:	c7 44 24 08 80 67 10 	movl   $0xf0106780,0x8(%esp)
f0103e42:	f0 
f0103e43:	c7 44 24 04 0b 01 00 	movl   $0x10b,0x4(%esp)
f0103e4a:	00 
f0103e4b:	c7 04 24 dd 65 10 f0 	movl   $0xf01065dd,(%esp)
f0103e52:	e8 5f c2 ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e57:	8b 53 30             	mov    0x30(%ebx),%edx
f0103e5a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103e5e:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103e62:	a1 88 df 17 f0       	mov    0xf017df88,%eax
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e67:	8b 40 48             	mov    0x48(%eax),%eax
f0103e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e6e:	c7 04 24 b4 67 10 f0 	movl   $0xf01067b4,(%esp)
f0103e75:	e8 bf f9 ff ff       	call   f0103839 <cprintf>
	print_trapframe(tf);
f0103e7a:	89 1c 24             	mov    %ebx,(%esp)
f0103e7d:	e8 1d fe ff ff       	call   f0103c9f <print_trapframe>
	env_destroy(curenv);
f0103e82:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103e87:	89 04 24             	mov    %eax,(%esp)
f0103e8a:	e8 76 f8 ff ff       	call   f0103705 <env_destroy>
}
f0103e8f:	83 c4 14             	add    $0x14,%esp
f0103e92:	5b                   	pop    %ebx
f0103e93:	5d                   	pop    %ebp
f0103e94:	c3                   	ret    

f0103e95 <trap>:
{
f0103e95:	55                   	push   %ebp
f0103e96:	89 e5                	mov    %esp,%ebp
f0103e98:	57                   	push   %edi
f0103e99:	56                   	push   %esi
f0103e9a:	83 ec 20             	sub    $0x20,%esp
f0103e9d:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0103ea0:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103ea1:	9c                   	pushf  
f0103ea2:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0103ea3:	f6 c4 02             	test   $0x2,%ah
f0103ea6:	74 24                	je     f0103ecc <trap+0x37>
f0103ea8:	c7 44 24 0c e9 65 10 	movl   $0xf01065e9,0xc(%esp)
f0103eaf:	f0 
f0103eb0:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0103eb7:	f0 
f0103eb8:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
f0103ebf:	00 
f0103ec0:	c7 04 24 dd 65 10 f0 	movl   $0xf01065dd,(%esp)
f0103ec7:	e8 ea c1 ff ff       	call   f01000b6 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f0103ecc:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103ed0:	c7 04 24 02 66 10 f0 	movl   $0xf0106602,(%esp)
f0103ed7:	e8 5d f9 ff ff       	call   f0103839 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f0103edc:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103ee0:	83 e0 03             	and    $0x3,%eax
f0103ee3:	66 83 f8 03          	cmp    $0x3,%ax
f0103ee7:	75 3c                	jne    f0103f25 <trap+0x90>
		assert(curenv);
f0103ee9:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103eee:	85 c0                	test   %eax,%eax
f0103ef0:	75 24                	jne    f0103f16 <trap+0x81>
f0103ef2:	c7 44 24 0c 1d 66 10 	movl   $0xf010661d,0xc(%esp)
f0103ef9:	f0 
f0103efa:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0103f01:	f0 
f0103f02:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
f0103f09:	00 
f0103f0a:	c7 04 24 dd 65 10 f0 	movl   $0xf01065dd,(%esp)
f0103f11:	e8 a0 c1 ff ff       	call   f01000b6 <_panic>
		curenv->env_tf = *tf;
f0103f16:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103f1b:	89 c7                	mov    %eax,%edi
f0103f1d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0103f1f:	8b 35 88 df 17 f0    	mov    0xf017df88,%esi
	last_tf = tf;
f0103f25:	89 35 08 e8 17 f0    	mov    %esi,0xf017e808
	switch(tf->tf_trapno) {
f0103f2b:	8b 46 28             	mov    0x28(%esi),%eax
f0103f2e:	83 f8 0e             	cmp    $0xe,%eax
f0103f31:	74 0f                	je     f0103f42 <trap+0xad>
f0103f33:	83 f8 30             	cmp    $0x30,%eax
f0103f36:	74 1e                	je     f0103f56 <trap+0xc1>
f0103f38:	83 f8 03             	cmp    $0x3,%eax
f0103f3b:	75 4b                	jne    f0103f88 <trap+0xf3>
f0103f3d:	8d 76 00             	lea    0x0(%esi),%esi
f0103f40:	eb 0a                	jmp    f0103f4c <trap+0xb7>
		page_fault_handler(tf);
f0103f42:	89 34 24             	mov    %esi,(%esp)
f0103f45:	e8 da fe ff ff       	call   f0103e24 <page_fault_handler>
f0103f4a:	eb 74                	jmp    f0103fc0 <trap+0x12b>
		monitor(tf);
f0103f4c:	89 34 24             	mov    %esi,(%esp)
f0103f4f:	e8 98 c8 ff ff       	call   f01007ec <monitor>
f0103f54:	eb 6a                	jmp    f0103fc0 <trap+0x12b>
		tf->tf_regs.reg_eax = syscall(
f0103f56:	8b 46 04             	mov    0x4(%esi),%eax
f0103f59:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103f5d:	8b 06                	mov    (%esi),%eax
f0103f5f:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103f63:	8b 46 10             	mov    0x10(%esi),%eax
f0103f66:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f6a:	8b 46 18             	mov    0x18(%esi),%eax
f0103f6d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f71:	8b 46 14             	mov    0x14(%esi),%eax
f0103f74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f78:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103f7b:	89 04 24             	mov    %eax,(%esp)
f0103f7e:	e8 fd 00 00 00       	call   f0104080 <syscall>
f0103f83:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103f86:	eb 38                	jmp    f0103fc0 <trap+0x12b>
	print_trapframe(tf);
f0103f88:	89 34 24             	mov    %esi,(%esp)
f0103f8b:	e8 0f fd ff ff       	call   f0103c9f <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103f90:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103f95:	75 1c                	jne    f0103fb3 <trap+0x11e>
		panic("unhandled trap in kernel");
f0103f97:	c7 44 24 08 24 66 10 	movl   $0xf0106624,0x8(%esp)
f0103f9e:	f0 
f0103f9f:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
f0103fa6:	00 
f0103fa7:	c7 04 24 dd 65 10 f0 	movl   $0xf01065dd,(%esp)
f0103fae:	e8 03 c1 ff ff       	call   f01000b6 <_panic>
		env_destroy(curenv);
f0103fb3:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103fb8:	89 04 24             	mov    %eax,(%esp)
f0103fbb:	e8 45 f7 ff ff       	call   f0103705 <env_destroy>
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103fc0:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103fc5:	85 c0                	test   %eax,%eax
f0103fc7:	74 06                	je     f0103fcf <trap+0x13a>
f0103fc9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103fcd:	74 24                	je     f0103ff3 <trap+0x15e>
f0103fcf:	c7 44 24 0c d8 67 10 	movl   $0xf01067d8,0xc(%esp)
f0103fd6:	f0 
f0103fd7:	c7 44 24 08 3f 60 10 	movl   $0xf010603f,0x8(%esp)
f0103fde:	f0 
f0103fdf:	c7 44 24 04 fa 00 00 	movl   $0xfa,0x4(%esp)
f0103fe6:	00 
f0103fe7:	c7 04 24 dd 65 10 f0 	movl   $0xf01065dd,(%esp)
f0103fee:	e8 c3 c0 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103ff3:	89 04 24             	mov    %eax,(%esp)
f0103ff6:	e8 61 f7 ff ff       	call   f010375c <env_run>
f0103ffb:	90                   	nop

f0103ffc <divide_handler>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(divide_handler, T_DIVIDE);
f0103ffc:	6a 00                	push   $0x0
f0103ffe:	6a 00                	push   $0x0
f0104000:	eb 5e                	jmp    f0104060 <_alltraps>

f0104002 <debug_handler>:
TRAPHANDLER_NOEC(debug_handler, T_DEBUG);
f0104002:	6a 00                	push   $0x0
f0104004:	6a 01                	push   $0x1
f0104006:	eb 58                	jmp    f0104060 <_alltraps>

f0104008 <nmi_handler>:
TRAPHANDLER_NOEC(nmi_handler, T_NMI);
f0104008:	6a 00                	push   $0x0
f010400a:	6a 02                	push   $0x2
f010400c:	eb 52                	jmp    f0104060 <_alltraps>

f010400e <brkpt_handler>:
TRAPHANDLER_NOEC(brkpt_handler, T_BRKPT);
f010400e:	6a 00                	push   $0x0
f0104010:	6a 03                	push   $0x3
f0104012:	eb 4c                	jmp    f0104060 <_alltraps>

f0104014 <oflow_handler>:
TRAPHANDLER_NOEC(oflow_handler, T_OFLOW);
f0104014:	6a 00                	push   $0x0
f0104016:	6a 04                	push   $0x4
f0104018:	eb 46                	jmp    f0104060 <_alltraps>

f010401a <bound_handler>:
TRAPHANDLER_NOEC(bound_handler, T_BOUND);
f010401a:	6a 00                	push   $0x0
f010401c:	6a 05                	push   $0x5
f010401e:	eb 40                	jmp    f0104060 <_alltraps>

f0104020 <illop_handler>:
TRAPHANDLER_NOEC(illop_handler, T_ILLOP);
f0104020:	6a 00                	push   $0x0
f0104022:	6a 06                	push   $0x6
f0104024:	eb 3a                	jmp    f0104060 <_alltraps>

f0104026 <device_handler>:
TRAPHANDLER_NOEC(device_handler, T_DEVICE);
f0104026:	6a 00                	push   $0x0
f0104028:	6a 07                	push   $0x7
f010402a:	eb 34                	jmp    f0104060 <_alltraps>

f010402c <dblflt_handler>:
TRAPHANDLER(dblflt_handler, T_DBLFLT);
f010402c:	6a 08                	push   $0x8
f010402e:	eb 30                	jmp    f0104060 <_alltraps>

f0104030 <tss_handler>:
// 9 deprecated since 386
TRAPHANDLER(tss_handler, T_TSS);
f0104030:	6a 0a                	push   $0xa
f0104032:	eb 2c                	jmp    f0104060 <_alltraps>

f0104034 <segnp_handler>:
TRAPHANDLER(segnp_handler, T_SEGNP);
f0104034:	6a 0b                	push   $0xb
f0104036:	eb 28                	jmp    f0104060 <_alltraps>

f0104038 <stack_handler>:
TRAPHANDLER(stack_handler, T_STACK);
f0104038:	6a 0c                	push   $0xc
f010403a:	eb 24                	jmp    f0104060 <_alltraps>

f010403c <gpflt_handler>:
TRAPHANDLER(gpflt_handler, T_GPFLT);
f010403c:	6a 0d                	push   $0xd
f010403e:	eb 20                	jmp    f0104060 <_alltraps>

f0104040 <pgflt_handler>:
TRAPHANDLER(pgflt_handler, T_PGFLT);
f0104040:	6a 0e                	push   $0xe
f0104042:	eb 1c                	jmp    f0104060 <_alltraps>

f0104044 <fperr_handler>:
// 15 reserved by intel
TRAPHANDLER_NOEC(fperr_handler, T_FPERR);
f0104044:	6a 00                	push   $0x0
f0104046:	6a 10                	push   $0x10
f0104048:	eb 16                	jmp    f0104060 <_alltraps>

f010404a <align_handler>:
TRAPHANDLER(align_handler, T_ALIGN);
f010404a:	6a 11                	push   $0x11
f010404c:	eb 12                	jmp    f0104060 <_alltraps>

f010404e <mchk_handler>:
TRAPHANDLER_NOEC(mchk_handler, T_MCHK);
f010404e:	6a 00                	push   $0x0
f0104050:	6a 12                	push   $0x12
f0104052:	eb 0c                	jmp    f0104060 <_alltraps>

f0104054 <simderr_handler>:
TRAPHANDLER_NOEC(simderr_handler, T_SIMDERR);
f0104054:	6a 00                	push   $0x0
f0104056:	6a 13                	push   $0x13
f0104058:	eb 06                	jmp    f0104060 <_alltraps>

f010405a <syscall_handler>:
// system call (interrupt)
TRAPHANDLER_NOEC(syscall_handler, T_SYSCALL);
f010405a:	6a 00                	push   $0x0
f010405c:	6a 30                	push   $0x30
f010405e:	eb 00                	jmp    f0104060 <_alltraps>

f0104060 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0104060:	1e                   	push   %ds
	pushl %es
f0104061:	06                   	push   %es
	pushal
f0104062:	60                   	pusha  

	movl $GD_KD, %eax
f0104063:	b8 10 00 00 00       	mov    $0x10,%eax
	movl %eax, %ds
f0104068:	8e d8                	mov    %eax,%ds
	movl %eax, %es
f010406a:	8e c0                	mov    %eax,%es

	pushl %esp
f010406c:	54                   	push   %esp
	call trap
f010406d:	e8 23 fe ff ff       	call   f0103e95 <trap>
f0104072:	66 90                	xchg   %ax,%ax
f0104074:	66 90                	xchg   %ax,%ax
f0104076:	66 90                	xchg   %ax,%ax
f0104078:	66 90                	xchg   %ax,%ax
f010407a:	66 90                	xchg   %ax,%ax
f010407c:	66 90                	xchg   %ax,%ax
f010407e:	66 90                	xchg   %ax,%ax

f0104080 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104080:	55                   	push   %ebp
f0104081:	89 e5                	mov    %esp,%ebp
f0104083:	83 ec 28             	sub    $0x28,%esp
f0104086:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0104089:	83 f8 01             	cmp    $0x1,%eax
f010408c:	74 5c                	je     f01040ea <syscall+0x6a>
f010408e:	83 f8 01             	cmp    $0x1,%eax
f0104091:	72 10                	jb     f01040a3 <syscall+0x23>
f0104093:	83 f8 02             	cmp    $0x2,%eax
f0104096:	74 5a                	je     f01040f2 <syscall+0x72>
f0104098:	83 f8 03             	cmp    $0x3,%eax
f010409b:	0f 85 c7 00 00 00    	jne    f0104168 <syscall+0xe8>
f01040a1:	eb 59                	jmp    f01040fc <syscall+0x7c>
	user_mem_assert(curenv, s ,len, 0);
f01040a3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01040aa:	00 
f01040ab:	8b 45 10             	mov    0x10(%ebp),%eax
f01040ae:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040b2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01040b5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01040b9:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01040be:	89 04 24             	mov    %eax,(%esp)
f01040c1:	e8 48 ef ff ff       	call   f010300e <user_mem_assert>
	cprintf("%.*s", len, s);
f01040c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040c9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040cd:	8b 55 10             	mov    0x10(%ebp),%edx
f01040d0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01040d4:	c7 04 24 70 68 10 f0 	movl   $0xf0106870,(%esp)
f01040db:	e8 59 f7 ff ff       	call   f0103839 <cprintf>
        case SYS_cputs:
		sys_cputs((const char *)a1, a2);
		return 0;
f01040e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01040e5:	e9 83 00 00 00       	jmp    f010416d <syscall+0xed>
	return cons_getc();
f01040ea:	e8 e9 c3 ff ff       	call   f01004d8 <cons_getc>
	case SYS_cgetc:
		return sys_cgetc();
f01040ef:	90                   	nop
f01040f0:	eb 7b                	jmp    f010416d <syscall+0xed>
	return curenv->env_id;
f01040f2:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01040f7:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_getenvid:
		return sys_getenvid();
f01040fa:	eb 71                	jmp    f010416d <syscall+0xed>
	if ((r = envid2env(envid, &e, 1)) < 0)
f01040fc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104103:	00 
f0104104:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010410b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010410e:	89 04 24             	mov    %eax,(%esp)
f0104111:	e8 ef ef ff ff       	call   f0103105 <envid2env>
f0104116:	85 c0                	test   %eax,%eax
f0104118:	78 53                	js     f010416d <syscall+0xed>
	if (e == curenv)
f010411a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010411d:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f0104123:	39 d0                	cmp    %edx,%eax
f0104125:	75 15                	jne    f010413c <syscall+0xbc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104127:	8b 40 48             	mov    0x48(%eax),%eax
f010412a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010412e:	c7 04 24 75 68 10 f0 	movl   $0xf0106875,(%esp)
f0104135:	e8 ff f6 ff ff       	call   f0103839 <cprintf>
f010413a:	eb 1a                	jmp    f0104156 <syscall+0xd6>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010413c:	8b 40 48             	mov    0x48(%eax),%eax
f010413f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104143:	8b 42 48             	mov    0x48(%edx),%eax
f0104146:	89 44 24 04          	mov    %eax,0x4(%esp)
f010414a:	c7 04 24 90 68 10 f0 	movl   $0xf0106890,(%esp)
f0104151:	e8 e3 f6 ff ff       	call   f0103839 <cprintf>
	env_destroy(e);
f0104156:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104159:	89 04 24             	mov    %eax,(%esp)
f010415c:	e8 a4 f5 ff ff       	call   f0103705 <env_destroy>
	return 0;
f0104161:	b8 00 00 00 00       	mov    $0x0,%eax
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104166:	eb 05                	jmp    f010416d <syscall+0xed>
	default:
		return -E_INVAL;
f0104168:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f010416d:	c9                   	leave  
f010416e:	c3                   	ret    

f010416f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010416f:	55                   	push   %ebp
f0104170:	89 e5                	mov    %esp,%ebp
f0104172:	57                   	push   %edi
f0104173:	56                   	push   %esi
f0104174:	53                   	push   %ebx
f0104175:	83 ec 14             	sub    $0x14,%esp
f0104178:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010417b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010417e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104181:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104184:	8b 1a                	mov    (%edx),%ebx
f0104186:	8b 01                	mov    (%ecx),%eax
f0104188:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010418b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

	while (l <= r) {
f0104192:	e9 88 00 00 00       	jmp    f010421f <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104197:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010419a:	01 d8                	add    %ebx,%eax
f010419c:	89 c7                	mov    %eax,%edi
f010419e:	c1 ef 1f             	shr    $0x1f,%edi
f01041a1:	01 c7                	add    %eax,%edi
f01041a3:	d1 ff                	sar    %edi

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041a5:	8d 04 7f             	lea    (%edi,%edi,2),%eax
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01041a8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041ab:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
		int true_m = (l + r) / 2, m = true_m;
f01041af:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01041b1:	eb 03                	jmp    f01041b6 <stab_binsearch+0x47>
			m--;
f01041b3:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01041b6:	39 c3                	cmp    %eax,%ebx
f01041b8:	7f 1e                	jg     f01041d8 <stab_binsearch+0x69>
f01041ba:	0f b6 0a             	movzbl (%edx),%ecx
f01041bd:	83 ea 0c             	sub    $0xc,%edx
f01041c0:	39 f1                	cmp    %esi,%ecx
f01041c2:	75 ef                	jne    f01041b3 <stab_binsearch+0x44>
f01041c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01041c7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01041ca:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041cd:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01041d1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041d4:	76 18                	jbe    f01041ee <stab_binsearch+0x7f>
f01041d6:	eb 05                	jmp    f01041dd <stab_binsearch+0x6e>
			l = true_m + 1;
f01041d8:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01041db:	eb 42                	jmp    f010421f <stab_binsearch+0xb0>
			*region_left = m;
f01041dd:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01041e0:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f01041e2:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01041e5:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01041ec:	eb 31                	jmp    f010421f <stab_binsearch+0xb0>
		} else if (stabs[m].n_value > addr) {
f01041ee:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041f1:	73 17                	jae    f010420a <stab_binsearch+0x9b>
			*region_right = m - 1;
f01041f3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01041f6:	83 e9 01             	sub    $0x1,%ecx
f01041f9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01041fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01041ff:	89 08                	mov    %ecx,(%eax)
		any_matches = 1;
f0104201:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0104208:	eb 15                	jmp    f010421f <stab_binsearch+0xb0>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010420a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010420d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104210:	89 0a                	mov    %ecx,(%edx)
			l = m;
			addr++;
f0104212:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104216:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104218:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	while (l <= r) {
f010421f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104222:	0f 8e 6f ff ff ff    	jle    f0104197 <stab_binsearch+0x28>
		}
	}

	if (!any_matches)
f0104228:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010422c:	75 0f                	jne    f010423d <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010422e:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104231:	8b 02                	mov    (%edx),%eax
f0104233:	83 e8 01             	sub    $0x1,%eax
f0104236:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104239:	89 01                	mov    %eax,(%ecx)
f010423b:	eb 2c                	jmp    f0104269 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010423d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104240:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104242:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104245:	8b 0a                	mov    (%edx),%ecx
f0104247:	8d 14 40             	lea    (%eax,%eax,2),%edx
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010424a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f010424d:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		for (l = *region_right;
f0104251:	eb 03                	jmp    f0104256 <stab_binsearch+0xe7>
		     l--)
f0104253:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104256:	39 c8                	cmp    %ecx,%eax
f0104258:	7e 0a                	jle    f0104264 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010425a:	0f b6 1a             	movzbl (%edx),%ebx
f010425d:	83 ea 0c             	sub    $0xc,%edx
f0104260:	39 f3                	cmp    %esi,%ebx
f0104262:	75 ef                	jne    f0104253 <stab_binsearch+0xe4>
			/* do nothing */;
		*region_left = l;
f0104264:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104267:	89 02                	mov    %eax,(%edx)
	}
}
f0104269:	83 c4 14             	add    $0x14,%esp
f010426c:	5b                   	pop    %ebx
f010426d:	5e                   	pop    %esi
f010426e:	5f                   	pop    %edi
f010426f:	5d                   	pop    %ebp
f0104270:	c3                   	ret    

f0104271 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104271:	55                   	push   %ebp
f0104272:	89 e5                	mov    %esp,%ebp
f0104274:	57                   	push   %edi
f0104275:	56                   	push   %esi
f0104276:	53                   	push   %ebx
f0104277:	83 ec 5c             	sub    $0x5c,%esp
f010427a:	8b 75 08             	mov    0x8(%ebp),%esi
f010427d:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104280:	c7 07 a8 68 10 f0    	movl   $0xf01068a8,(%edi)
	info->eip_line = 0;
f0104286:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010428d:	c7 47 08 a8 68 10 f0 	movl   $0xf01068a8,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104294:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f010429b:	89 77 10             	mov    %esi,0x10(%edi)
	info->eip_fn_narg = 0;
f010429e:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01042a5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01042ab:	0f 87 b2 00 00 00    	ja     f0104363 <debuginfo_eip+0xf2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(usd), PTE_U) < 0)
f01042b1:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01042b8:	00 
f01042b9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01042c0:	00 
f01042c1:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01042c8:	00 
f01042c9:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01042ce:	89 04 24             	mov    %eax,(%esp)
f01042d1:	e8 a1 ec ff ff       	call   f0102f77 <user_mem_check>
f01042d6:	85 c0                	test   %eax,%eax
f01042d8:	0f 88 49 02 00 00    	js     f0104527 <debuginfo_eip+0x2b6>
			return -1;

		stabs = usd->stabs;
f01042de:	8b 1d 00 00 20 00    	mov    0x200000,%ebx
f01042e4:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01042e7:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01042ed:	a1 08 00 20 00       	mov    0x200008,%eax
f01042f2:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr_end = usd->stabstr_end;
f01042f5:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01042fb:	89 55 c0             	mov    %edx,-0x40(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) < 0)
f01042fe:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104305:	00 
f0104306:	89 d8                	mov    %ebx,%eax
f0104308:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f010430b:	c1 f8 02             	sar    $0x2,%eax
f010430e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104314:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104318:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010431b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010431f:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104324:	89 04 24             	mov    %eax,(%esp)
f0104327:	e8 4b ec ff ff       	call   f0102f77 <user_mem_check>
f010432c:	85 c0                	test   %eax,%eax
f010432e:	0f 88 fa 01 00 00    	js     f010452e <debuginfo_eip+0x2bd>
			return -1;
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) < 0)
f0104334:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010433b:	00 
f010433c:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010433f:	2b 45 bc             	sub    -0x44(%ebp),%eax
f0104342:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104346:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104349:	89 44 24 04          	mov    %eax,0x4(%esp)
f010434d:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104352:	89 04 24             	mov    %eax,(%esp)
f0104355:	e8 1d ec ff ff       	call   f0102f77 <user_mem_check>
f010435a:	85 c0                	test   %eax,%eax
f010435c:	79 1f                	jns    f010437d <debuginfo_eip+0x10c>
f010435e:	e9 d2 01 00 00       	jmp    f0104535 <debuginfo_eip+0x2c4>
		stabstr_end = __STABSTR_END__;
f0104363:	c7 45 c0 6b 18 11 f0 	movl   $0xf011186b,-0x40(%ebp)
		stabstr = __STABSTR_BEGIN__;
f010436a:	c7 45 bc 5d ed 10 f0 	movl   $0xf010ed5d,-0x44(%ebp)
		stab_end = __STAB_END__;
f0104371:	bb 5c ed 10 f0       	mov    $0xf010ed5c,%ebx
		stabs = __STAB_BEGIN__;
f0104376:	c7 45 c4 d0 6a 10 f0 	movl   $0xf0106ad0,-0x3c(%ebp)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010437d:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104380:	39 55 bc             	cmp    %edx,-0x44(%ebp)
f0104383:	0f 83 b3 01 00 00    	jae    f010453c <debuginfo_eip+0x2cb>
f0104389:	80 7a ff 00          	cmpb   $0x0,-0x1(%edx)
f010438d:	0f 85 b0 01 00 00    	jne    f0104543 <debuginfo_eip+0x2d2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104393:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010439a:	2b 5d c4             	sub    -0x3c(%ebp),%ebx
f010439d:	c1 fb 02             	sar    $0x2,%ebx
f01043a0:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01043a6:	83 e8 01             	sub    $0x1,%eax
f01043a9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01043ac:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043b0:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01043b7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01043ba:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01043bd:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01043c0:	e8 aa fd ff ff       	call   f010416f <stab_binsearch>
	if (lfile == 0)
f01043c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043c8:	85 c0                	test   %eax,%eax
f01043ca:	0f 84 7a 01 00 00    	je     f010454a <debuginfo_eip+0x2d9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01043d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01043d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043d6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01043d9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043dd:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01043e4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01043e7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01043ea:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01043ed:	e8 7d fd ff ff       	call   f010416f <stab_binsearch>

	if (lfun <= rfun) {
f01043f2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01043f5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01043f8:	39 c8                	cmp    %ecx,%eax
f01043fa:	7f 32                	jg     f010442e <debuginfo_eip+0x1bd>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01043fc:	8d 1c 40             	lea    (%eax,%eax,2),%ebx
f01043ff:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104402:	8d 1c 9a             	lea    (%edx,%ebx,4),%ebx
f0104405:	8b 13                	mov    (%ebx),%edx
f0104407:	89 55 b4             	mov    %edx,-0x4c(%ebp)
f010440a:	8b 55 c0             	mov    -0x40(%ebp),%edx
f010440d:	2b 55 bc             	sub    -0x44(%ebp),%edx
f0104410:	39 55 b4             	cmp    %edx,-0x4c(%ebp)
f0104413:	73 09                	jae    f010441e <debuginfo_eip+0x1ad>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104415:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0104418:	03 55 bc             	add    -0x44(%ebp),%edx
f010441b:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010441e:	8b 53 08             	mov    0x8(%ebx),%edx
f0104421:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104424:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104426:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104429:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010442c:	eb 0f                	jmp    f010443d <debuginfo_eip+0x1cc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010442e:	89 77 10             	mov    %esi,0x10(%edi)
		lline = lfile;
f0104431:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104434:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104437:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010443a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010443d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104444:	00 
f0104445:	8b 47 08             	mov    0x8(%edi),%eax
f0104448:	89 04 24             	mov    %eax,(%esp)
f010444b:	e8 37 09 00 00       	call   f0104d87 <strfind>
f0104450:	2b 47 08             	sub    0x8(%edi),%eax
f0104453:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104456:	89 74 24 04          	mov    %esi,0x4(%esp)
f010445a:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104461:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104464:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104467:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010446a:	e8 00 fd ff ff       	call   f010416f <stab_binsearch>

	if (lline <= rline) {
f010446f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104472:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104475:	0f 8f d6 00 00 00    	jg     f0104551 <debuginfo_eip+0x2e0>
		info->eip_line = stabs[lline].n_desc;
f010447b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010447e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104481:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104486:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104489:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010448c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010448f:	8d 14 40             	lea    (%eax,%eax,2),%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0104492:	8d 54 93 08          	lea    0x8(%ebx,%edx,4),%edx
f0104496:	89 7d b8             	mov    %edi,-0x48(%ebp)
f0104499:	89 cf                	mov    %ecx,%edi
	while (lline >= lfile
f010449b:	eb 06                	jmp    f01044a3 <debuginfo_eip+0x232>
f010449d:	83 e8 01             	sub    $0x1,%eax
f01044a0:	83 ea 0c             	sub    $0xc,%edx
f01044a3:	89 c6                	mov    %eax,%esi
f01044a5:	39 c7                	cmp    %eax,%edi
f01044a7:	7f 3b                	jg     f01044e4 <debuginfo_eip+0x273>
	       && stabs[lline].n_type != N_SOL
f01044a9:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
f01044ad:	80 f9 84             	cmp    $0x84,%cl
f01044b0:	75 08                	jne    f01044ba <debuginfo_eip+0x249>
f01044b2:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01044b5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01044b8:	eb 10                	jmp    f01044ca <debuginfo_eip+0x259>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01044ba:	80 f9 64             	cmp    $0x64,%cl
f01044bd:	75 de                	jne    f010449d <debuginfo_eip+0x22c>
f01044bf:	83 3a 00             	cmpl   $0x0,(%edx)
f01044c2:	74 d9                	je     f010449d <debuginfo_eip+0x22c>
f01044c4:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01044c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01044ca:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01044cd:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01044d0:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f01044d3:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01044d6:	2b 55 bc             	sub    -0x44(%ebp),%edx
f01044d9:	39 d0                	cmp    %edx,%eax
f01044db:	73 0a                	jae    f01044e7 <debuginfo_eip+0x276>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01044dd:	03 45 bc             	add    -0x44(%ebp),%eax
f01044e0:	89 07                	mov    %eax,(%edi)
f01044e2:	eb 03                	jmp    f01044e7 <debuginfo_eip+0x276>
f01044e4:	8b 7d b8             	mov    -0x48(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044e7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01044ea:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044ed:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01044f2:	39 da                	cmp    %ebx,%edx
f01044f4:	7d 67                	jge    f010455d <debuginfo_eip+0x2ec>
		for (lline = lfun + 1;
f01044f6:	83 c2 01             	add    $0x1,%edx
f01044f9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01044fc:	89 d0                	mov    %edx,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01044fe:	8d 14 52             	lea    (%edx,%edx,2),%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0104501:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104504:	8d 54 91 04          	lea    0x4(%ecx,%edx,4),%edx
		for (lline = lfun + 1;
f0104508:	eb 04                	jmp    f010450e <debuginfo_eip+0x29d>
			info->eip_fn_narg++;
f010450a:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f010450e:	39 c3                	cmp    %eax,%ebx
f0104510:	7e 46                	jle    f0104558 <debuginfo_eip+0x2e7>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104512:	0f b6 0a             	movzbl (%edx),%ecx
f0104515:	83 c0 01             	add    $0x1,%eax
f0104518:	83 c2 0c             	add    $0xc,%edx
f010451b:	80 f9 a0             	cmp    $0xa0,%cl
f010451e:	74 ea                	je     f010450a <debuginfo_eip+0x299>
	return 0;
f0104520:	b8 00 00 00 00       	mov    $0x0,%eax
f0104525:	eb 36                	jmp    f010455d <debuginfo_eip+0x2ec>
			return -1;
f0104527:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010452c:	eb 2f                	jmp    f010455d <debuginfo_eip+0x2ec>
			return -1;
f010452e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104533:	eb 28                	jmp    f010455d <debuginfo_eip+0x2ec>
			return -1;
f0104535:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010453a:	eb 21                	jmp    f010455d <debuginfo_eip+0x2ec>
		return -1;
f010453c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104541:	eb 1a                	jmp    f010455d <debuginfo_eip+0x2ec>
f0104543:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104548:	eb 13                	jmp    f010455d <debuginfo_eip+0x2ec>
		return -1;
f010454a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010454f:	eb 0c                	jmp    f010455d <debuginfo_eip+0x2ec>
		return -1;
f0104551:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104556:	eb 05                	jmp    f010455d <debuginfo_eip+0x2ec>
	return 0;
f0104558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010455d:	83 c4 5c             	add    $0x5c,%esp
f0104560:	5b                   	pop    %ebx
f0104561:	5e                   	pop    %esi
f0104562:	5f                   	pop    %edi
f0104563:	5d                   	pop    %ebp
f0104564:	c3                   	ret    
f0104565:	66 90                	xchg   %ax,%ax
f0104567:	66 90                	xchg   %ax,%ax
f0104569:	66 90                	xchg   %ax,%ax
f010456b:	66 90                	xchg   %ax,%ax
f010456d:	66 90                	xchg   %ax,%ax
f010456f:	90                   	nop

f0104570 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104570:	55                   	push   %ebp
f0104571:	89 e5                	mov    %esp,%ebp
f0104573:	57                   	push   %edi
f0104574:	56                   	push   %esi
f0104575:	53                   	push   %ebx
f0104576:	83 ec 4c             	sub    $0x4c,%esp
f0104579:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010457c:	89 d7                	mov    %edx,%edi
f010457e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104581:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0104584:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104587:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010458a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010458d:	85 db                	test   %ebx,%ebx
f010458f:	75 08                	jne    f0104599 <printnum+0x29>
f0104591:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104594:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0104597:	77 6c                	ja     f0104605 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104599:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010459c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01045a0:	83 ee 01             	sub    $0x1,%esi
f01045a3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01045a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01045aa:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01045ae:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045b2:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01045b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01045b9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01045bc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01045c3:	00 
f01045c4:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01045c7:	89 1c 24             	mov    %ebx,(%esp)
f01045ca:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01045cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045d1:	e8 fa 09 00 00       	call   f0104fd0 <__udivdi3>
f01045d6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01045d9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01045dc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01045e0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01045e4:	89 04 24             	mov    %eax,(%esp)
f01045e7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01045eb:	89 fa                	mov    %edi,%edx
f01045ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01045f0:	e8 7b ff ff ff       	call   f0104570 <printnum>
f01045f5:	eb 1b                	jmp    f0104612 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01045f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045fb:	8b 45 18             	mov    0x18(%ebp),%eax
f01045fe:	89 04 24             	mov    %eax,(%esp)
f0104601:	ff d3                	call   *%ebx
f0104603:	eb 03                	jmp    f0104608 <printnum+0x98>
f0104605:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
f0104608:	83 ee 01             	sub    $0x1,%esi
f010460b:	85 f6                	test   %esi,%esi
f010460d:	7f e8                	jg     f01045f7 <printnum+0x87>
f010460f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104612:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104616:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010461a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010461d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104621:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104628:	00 
f0104629:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010462c:	89 1c 24             	mov    %ebx,(%esp)
f010462f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104632:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104636:	e8 e5 0a 00 00       	call   f0105120 <__umoddi3>
f010463b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010463f:	0f be 80 b2 68 10 f0 	movsbl -0xfef974e(%eax),%eax
f0104646:	89 04 24             	mov    %eax,(%esp)
f0104649:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010464c:	ff d0                	call   *%eax
}
f010464e:	83 c4 4c             	add    $0x4c,%esp
f0104651:	5b                   	pop    %ebx
f0104652:	5e                   	pop    %esi
f0104653:	5f                   	pop    %edi
f0104654:	5d                   	pop    %ebp
f0104655:	c3                   	ret    

f0104656 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104656:	55                   	push   %ebp
f0104657:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104659:	83 fa 01             	cmp    $0x1,%edx
f010465c:	7e 0e                	jle    f010466c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010465e:	8b 10                	mov    (%eax),%edx
f0104660:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104663:	89 08                	mov    %ecx,(%eax)
f0104665:	8b 02                	mov    (%edx),%eax
f0104667:	8b 52 04             	mov    0x4(%edx),%edx
f010466a:	eb 22                	jmp    f010468e <getuint+0x38>
	else if (lflag)
f010466c:	85 d2                	test   %edx,%edx
f010466e:	74 10                	je     f0104680 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104670:	8b 10                	mov    (%eax),%edx
f0104672:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104675:	89 08                	mov    %ecx,(%eax)
f0104677:	8b 02                	mov    (%edx),%eax
f0104679:	ba 00 00 00 00       	mov    $0x0,%edx
f010467e:	eb 0e                	jmp    f010468e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104680:	8b 10                	mov    (%eax),%edx
f0104682:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104685:	89 08                	mov    %ecx,(%eax)
f0104687:	8b 02                	mov    (%edx),%eax
f0104689:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010468e:	5d                   	pop    %ebp
f010468f:	c3                   	ret    

f0104690 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104690:	55                   	push   %ebp
f0104691:	89 e5                	mov    %esp,%ebp
f0104693:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104696:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010469a:	8b 10                	mov    (%eax),%edx
f010469c:	3b 50 04             	cmp    0x4(%eax),%edx
f010469f:	73 0a                	jae    f01046ab <sprintputch+0x1b>
		*b->buf++ = ch;
f01046a1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01046a4:	88 0a                	mov    %cl,(%edx)
f01046a6:	83 c2 01             	add    $0x1,%edx
f01046a9:	89 10                	mov    %edx,(%eax)
}
f01046ab:	5d                   	pop    %ebp
f01046ac:	c3                   	ret    

f01046ad <printfmt>:
{
f01046ad:	55                   	push   %ebp
f01046ae:	89 e5                	mov    %esp,%ebp
f01046b0:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f01046b3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01046b6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046ba:	8b 45 10             	mov    0x10(%ebp),%eax
f01046bd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01046cb:	89 04 24             	mov    %eax,(%esp)
f01046ce:	e8 02 00 00 00       	call   f01046d5 <vprintfmt>
}
f01046d3:	c9                   	leave  
f01046d4:	c3                   	ret    

f01046d5 <vprintfmt>:
{
f01046d5:	55                   	push   %ebp
f01046d6:	89 e5                	mov    %esp,%ebp
f01046d8:	57                   	push   %edi
f01046d9:	56                   	push   %esi
f01046da:	53                   	push   %ebx
f01046db:	83 ec 4c             	sub    $0x4c,%esp
f01046de:	8b 75 08             	mov    0x8(%ebp),%esi
f01046e1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01046e4:	8b 7d 10             	mov    0x10(%ebp),%edi
f01046e7:	eb 11                	jmp    f01046fa <vprintfmt+0x25>
			if (ch == '\0')
f01046e9:	85 c0                	test   %eax,%eax
f01046eb:	0f 84 cf 03 00 00    	je     f0104ac0 <vprintfmt+0x3eb>
			putch(ch, putdat);
f01046f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01046f5:	89 04 24             	mov    %eax,(%esp)
f01046f8:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01046fa:	0f b6 07             	movzbl (%edi),%eax
f01046fd:	83 c7 01             	add    $0x1,%edi
f0104700:	83 f8 25             	cmp    $0x25,%eax
f0104703:	75 e4                	jne    f01046e9 <vprintfmt+0x14>
f0104705:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0104709:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0104710:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104717:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010471e:	ba 00 00 00 00       	mov    $0x0,%edx
f0104723:	eb 2b                	jmp    f0104750 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0104725:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
f0104728:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f010472c:	eb 22                	jmp    f0104750 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f010472e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
f0104731:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0104735:	eb 19                	jmp    f0104750 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0104737:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
f010473a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104741:	eb 0d                	jmp    f0104750 <vprintfmt+0x7b>
				width = precision, precision = -1;
f0104743:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104746:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104749:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104750:	0f b6 07             	movzbl (%edi),%eax
f0104753:	8d 4f 01             	lea    0x1(%edi),%ecx
f0104756:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104759:	0f b6 0f             	movzbl (%edi),%ecx
f010475c:	83 e9 23             	sub    $0x23,%ecx
f010475f:	80 f9 55             	cmp    $0x55,%cl
f0104762:	0f 87 3b 03 00 00    	ja     f0104aa3 <vprintfmt+0x3ce>
f0104768:	0f b6 c9             	movzbl %cl,%ecx
f010476b:	ff 24 8d 40 69 10 f0 	jmp    *-0xfef96c0(,%ecx,4)
f0104772:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104775:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f010477c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010477f:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
f0104784:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0104787:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f010478b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f010478e:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0104791:	83 f9 09             	cmp    $0x9,%ecx
f0104794:	77 2f                	ja     f01047c5 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
f0104796:	83 c7 01             	add    $0x1,%edi
			}
f0104799:	eb e9                	jmp    f0104784 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
f010479b:	8b 45 14             	mov    0x14(%ebp),%eax
f010479e:	8d 48 04             	lea    0x4(%eax),%ecx
f01047a1:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01047a4:	8b 00                	mov    (%eax),%eax
f01047a6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01047a9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
f01047ac:	eb 1d                	jmp    f01047cb <vprintfmt+0xf6>
			if (width < 0)
f01047ae:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01047b2:	78 83                	js     f0104737 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
f01047b4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01047b7:	eb 97                	jmp    f0104750 <vprintfmt+0x7b>
f01047b9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
f01047bc:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01047c3:	eb 8b                	jmp    f0104750 <vprintfmt+0x7b>
f01047c5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01047c8:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
f01047cb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01047cf:	0f 89 7b ff ff ff    	jns    f0104750 <vprintfmt+0x7b>
f01047d5:	e9 69 ff ff ff       	jmp    f0104743 <vprintfmt+0x6e>
			lflag++;
f01047da:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f01047dd:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
f01047e0:	e9 6b ff ff ff       	jmp    f0104750 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
f01047e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01047e8:	8d 50 04             	lea    0x4(%eax),%edx
f01047eb:	89 55 14             	mov    %edx,0x14(%ebp)
f01047ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047f2:	8b 00                	mov    (%eax),%eax
f01047f4:	89 04 24             	mov    %eax,(%esp)
f01047f7:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f01047f9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f01047fc:	e9 f9 fe ff ff       	jmp    f01046fa <vprintfmt+0x25>
			err = va_arg(ap, int);
f0104801:	8b 45 14             	mov    0x14(%ebp),%eax
f0104804:	8d 50 04             	lea    0x4(%eax),%edx
f0104807:	89 55 14             	mov    %edx,0x14(%ebp)
f010480a:	8b 00                	mov    (%eax),%eax
f010480c:	89 c2                	mov    %eax,%edx
f010480e:	c1 fa 1f             	sar    $0x1f,%edx
f0104811:	31 d0                	xor    %edx,%eax
f0104813:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104815:	83 f8 07             	cmp    $0x7,%eax
f0104818:	7f 0b                	jg     f0104825 <vprintfmt+0x150>
f010481a:	8b 14 85 a0 6a 10 f0 	mov    -0xfef9560(,%eax,4),%edx
f0104821:	85 d2                	test   %edx,%edx
f0104823:	75 20                	jne    f0104845 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f0104825:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104829:	c7 44 24 08 ca 68 10 	movl   $0xf01068ca,0x8(%esp)
f0104830:	f0 
f0104831:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104835:	89 34 24             	mov    %esi,(%esp)
f0104838:	e8 70 fe ff ff       	call   f01046ad <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f010483d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
f0104840:	e9 b5 fe ff ff       	jmp    f01046fa <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0104845:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104849:	c7 44 24 08 51 60 10 	movl   $0xf0106051,0x8(%esp)
f0104850:	f0 
f0104851:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104855:	89 34 24             	mov    %esi,(%esp)
f0104858:	e8 50 fe ff ff       	call   f01046ad <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f010485d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104860:	e9 95 fe ff ff       	jmp    f01046fa <vprintfmt+0x25>
f0104865:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104868:	8b 7d d8             	mov    -0x28(%ebp),%edi
f010486b:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f010486e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104871:	8d 50 04             	lea    0x4(%eax),%edx
f0104874:	89 55 14             	mov    %edx,0x14(%ebp)
f0104877:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104879:	85 ff                	test   %edi,%edi
f010487b:	b8 c3 68 10 f0       	mov    $0xf01068c3,%eax
f0104880:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104883:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0104887:	0f 84 9b 00 00 00    	je     f0104928 <vprintfmt+0x253>
f010488d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104891:	0f 8e 9f 00 00 00    	jle    f0104936 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104897:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010489b:	89 3c 24             	mov    %edi,(%esp)
f010489e:	e8 95 03 00 00       	call   f0104c38 <strnlen>
f01048a3:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01048a6:	29 c2                	sub    %eax,%edx
f01048a8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f01048ab:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01048af:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01048b2:	89 7d c8             	mov    %edi,-0x38(%ebp)
f01048b5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01048b7:	eb 0f                	jmp    f01048c8 <vprintfmt+0x1f3>
					putch(padc, putdat);
f01048b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01048bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048c0:	89 04 24             	mov    %eax,(%esp)
f01048c3:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01048c5:	83 ef 01             	sub    $0x1,%edi
f01048c8:	85 ff                	test   %edi,%edi
f01048ca:	7f ed                	jg     f01048b9 <vprintfmt+0x1e4>
f01048cc:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f01048cf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01048d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01048d8:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
f01048dc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01048df:	29 c2                	sub    %eax,%edx
f01048e1:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01048e4:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01048e7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01048ea:	89 d3                	mov    %edx,%ebx
f01048ec:	eb 54                	jmp    f0104942 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
f01048ee:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01048f2:	74 20                	je     f0104914 <vprintfmt+0x23f>
f01048f4:	0f be d2             	movsbl %dl,%edx
f01048f7:	83 ea 20             	sub    $0x20,%edx
f01048fa:	83 fa 5e             	cmp    $0x5e,%edx
f01048fd:	76 15                	jbe    f0104914 <vprintfmt+0x23f>
					putch('?', putdat);
f01048ff:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104902:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104906:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010490d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104910:	ff d0                	call   *%eax
f0104912:	eb 0f                	jmp    f0104923 <vprintfmt+0x24e>
					putch(ch, putdat);
f0104914:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104917:	89 54 24 04          	mov    %edx,0x4(%esp)
f010491b:	89 04 24             	mov    %eax,(%esp)
f010491e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104921:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104923:	83 eb 01             	sub    $0x1,%ebx
f0104926:	eb 1a                	jmp    f0104942 <vprintfmt+0x26d>
f0104928:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010492b:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010492e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0104931:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104934:	eb 0c                	jmp    f0104942 <vprintfmt+0x26d>
f0104936:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0104939:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010493c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010493f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104942:	0f b6 17             	movzbl (%edi),%edx
f0104945:	0f be c2             	movsbl %dl,%eax
f0104948:	83 c7 01             	add    $0x1,%edi
f010494b:	85 c0                	test   %eax,%eax
f010494d:	74 29                	je     f0104978 <vprintfmt+0x2a3>
f010494f:	85 f6                	test   %esi,%esi
f0104951:	78 9b                	js     f01048ee <vprintfmt+0x219>
f0104953:	83 ee 01             	sub    $0x1,%esi
f0104956:	79 96                	jns    f01048ee <vprintfmt+0x219>
f0104958:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010495b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010495e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104961:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0104964:	eb 1a                	jmp    f0104980 <vprintfmt+0x2ab>
				putch(' ', putdat);
f0104966:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010496a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104971:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0104973:	83 ef 01             	sub    $0x1,%edi
f0104976:	eb 08                	jmp    f0104980 <vprintfmt+0x2ab>
f0104978:	89 df                	mov    %ebx,%edi
f010497a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010497d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104980:	85 ff                	test   %edi,%edi
f0104982:	7f e2                	jg     f0104966 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
f0104984:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104987:	e9 6e fd ff ff       	jmp    f01046fa <vprintfmt+0x25>
	if (lflag >= 2)
f010498c:	83 fa 01             	cmp    $0x1,%edx
f010498f:	7e 16                	jle    f01049a7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f0104991:	8b 45 14             	mov    0x14(%ebp),%eax
f0104994:	8d 50 08             	lea    0x8(%eax),%edx
f0104997:	89 55 14             	mov    %edx,0x14(%ebp)
f010499a:	8b 10                	mov    (%eax),%edx
f010499c:	8b 48 04             	mov    0x4(%eax),%ecx
f010499f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01049a2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01049a5:	eb 32                	jmp    f01049d9 <vprintfmt+0x304>
	else if (lflag)
f01049a7:	85 d2                	test   %edx,%edx
f01049a9:	74 18                	je     f01049c3 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
f01049ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01049ae:	8d 50 04             	lea    0x4(%eax),%edx
f01049b1:	89 55 14             	mov    %edx,0x14(%ebp)
f01049b4:	8b 00                	mov    (%eax),%eax
f01049b6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01049b9:	89 c1                	mov    %eax,%ecx
f01049bb:	c1 f9 1f             	sar    $0x1f,%ecx
f01049be:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01049c1:	eb 16                	jmp    f01049d9 <vprintfmt+0x304>
		return va_arg(*ap, int);
f01049c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01049c6:	8d 50 04             	lea    0x4(%eax),%edx
f01049c9:	89 55 14             	mov    %edx,0x14(%ebp)
f01049cc:	8b 00                	mov    (%eax),%eax
f01049ce:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01049d1:	89 c7                	mov    %eax,%edi
f01049d3:	c1 ff 1f             	sar    $0x1f,%edi
f01049d6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
f01049d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01049dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
f01049df:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f01049e4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01049e8:	79 7d                	jns    f0104a67 <vprintfmt+0x392>
				putch('-', putdat);
f01049ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01049ee:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01049f5:	ff d6                	call   *%esi
				num = -(long long) num;
f01049f7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01049fa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01049fd:	f7 d8                	neg    %eax
f01049ff:	83 d2 00             	adc    $0x0,%edx
f0104a02:	f7 da                	neg    %edx
			base = 10;
f0104a04:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104a09:	eb 5c                	jmp    f0104a67 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f0104a0b:	8d 45 14             	lea    0x14(%ebp),%eax
f0104a0e:	e8 43 fc ff ff       	call   f0104656 <getuint>
			base = 10;
f0104a13:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104a18:	eb 4d                	jmp    f0104a67 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f0104a1a:	8d 45 14             	lea    0x14(%ebp),%eax
f0104a1d:	e8 34 fc ff ff       	call   f0104656 <getuint>
			base = 8;
f0104a22:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104a27:	eb 3e                	jmp    f0104a67 <vprintfmt+0x392>
			putch('0', putdat);
f0104a29:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a2d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0104a34:	ff d6                	call   *%esi
			putch('x', putdat);
f0104a36:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a3a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104a41:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f0104a43:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a46:	8d 50 04             	lea    0x4(%eax),%edx
f0104a49:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f0104a4c:	8b 00                	mov    (%eax),%eax
f0104a4e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f0104a53:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104a58:	eb 0d                	jmp    f0104a67 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f0104a5a:	8d 45 14             	lea    0x14(%ebp),%eax
f0104a5d:	e8 f4 fb ff ff       	call   f0104656 <getuint>
			base = 16;
f0104a62:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f0104a67:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f0104a6b:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0104a6f:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0104a72:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104a76:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104a7a:	89 04 24             	mov    %eax,(%esp)
f0104a7d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a81:	89 da                	mov    %ebx,%edx
f0104a83:	89 f0                	mov    %esi,%eax
f0104a85:	e8 e6 fa ff ff       	call   f0104570 <printnum>
			break;
f0104a8a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104a8d:	e9 68 fc ff ff       	jmp    f01046fa <vprintfmt+0x25>
			putch(ch, putdat);
f0104a92:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a96:	89 04 24             	mov    %eax,(%esp)
f0104a99:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f0104a9b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f0104a9e:	e9 57 fc ff ff       	jmp    f01046fa <vprintfmt+0x25>
			putch('%', putdat);
f0104aa3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104aa7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104aae:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104ab0:	eb 03                	jmp    f0104ab5 <vprintfmt+0x3e0>
f0104ab2:	83 ef 01             	sub    $0x1,%edi
f0104ab5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104ab9:	75 f7                	jne    f0104ab2 <vprintfmt+0x3dd>
f0104abb:	e9 3a fc ff ff       	jmp    f01046fa <vprintfmt+0x25>
}
f0104ac0:	83 c4 4c             	add    $0x4c,%esp
f0104ac3:	5b                   	pop    %ebx
f0104ac4:	5e                   	pop    %esi
f0104ac5:	5f                   	pop    %edi
f0104ac6:	5d                   	pop    %ebp
f0104ac7:	c3                   	ret    

f0104ac8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104ac8:	55                   	push   %ebp
f0104ac9:	89 e5                	mov    %esp,%ebp
f0104acb:	83 ec 28             	sub    $0x28,%esp
f0104ace:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ad1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104ad4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104ad7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104adb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104ade:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104ae5:	85 d2                	test   %edx,%edx
f0104ae7:	7e 30                	jle    f0104b19 <vsnprintf+0x51>
f0104ae9:	85 c0                	test   %eax,%eax
f0104aeb:	74 2c                	je     f0104b19 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104aed:	8b 45 14             	mov    0x14(%ebp),%eax
f0104af0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104af4:	8b 45 10             	mov    0x10(%ebp),%eax
f0104af7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104afb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104afe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b02:	c7 04 24 90 46 10 f0 	movl   $0xf0104690,(%esp)
f0104b09:	e8 c7 fb ff ff       	call   f01046d5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104b0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104b11:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104b14:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b17:	eb 05                	jmp    f0104b1e <vsnprintf+0x56>
		return -E_INVAL;
f0104b19:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f0104b1e:	c9                   	leave  
f0104b1f:	c3                   	ret    

f0104b20 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104b20:	55                   	push   %ebp
f0104b21:	89 e5                	mov    %esp,%ebp
f0104b23:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104b26:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104b29:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b2d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b30:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b34:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b3e:	89 04 24             	mov    %eax,(%esp)
f0104b41:	e8 82 ff ff ff       	call   f0104ac8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104b46:	c9                   	leave  
f0104b47:	c3                   	ret    
f0104b48:	66 90                	xchg   %ax,%ax
f0104b4a:	66 90                	xchg   %ax,%ax
f0104b4c:	66 90                	xchg   %ax,%ax
f0104b4e:	66 90                	xchg   %ax,%ax

f0104b50 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104b50:	55                   	push   %ebp
f0104b51:	89 e5                	mov    %esp,%ebp
f0104b53:	57                   	push   %edi
f0104b54:	56                   	push   %esi
f0104b55:	53                   	push   %ebx
f0104b56:	83 ec 1c             	sub    $0x1c,%esp
f0104b59:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104b5c:	85 c0                	test   %eax,%eax
f0104b5e:	74 10                	je     f0104b70 <readline+0x20>
		cprintf("%s", prompt);
f0104b60:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b64:	c7 04 24 51 60 10 f0 	movl   $0xf0106051,(%esp)
f0104b6b:	e8 c9 ec ff ff       	call   f0103839 <cprintf>

	i = 0;
	echoing = iscons(0);
f0104b70:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104b77:	e8 b4 ba ff ff       	call   f0100630 <iscons>
f0104b7c:	89 c7                	mov    %eax,%edi
	i = 0;
f0104b7e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0104b83:	e8 97 ba ff ff       	call   f010061f <getchar>
f0104b88:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104b8a:	85 c0                	test   %eax,%eax
f0104b8c:	79 17                	jns    f0104ba5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104b8e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b92:	c7 04 24 c0 6a 10 f0 	movl   $0xf0106ac0,(%esp)
f0104b99:	e8 9b ec ff ff       	call   f0103839 <cprintf>
			return NULL;
f0104b9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ba3:	eb 6d                	jmp    f0104c12 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104ba5:	83 f8 7f             	cmp    $0x7f,%eax
f0104ba8:	74 05                	je     f0104baf <readline+0x5f>
f0104baa:	83 f8 08             	cmp    $0x8,%eax
f0104bad:	75 19                	jne    f0104bc8 <readline+0x78>
f0104baf:	85 f6                	test   %esi,%esi
f0104bb1:	7e 15                	jle    f0104bc8 <readline+0x78>
			if (echoing)
f0104bb3:	85 ff                	test   %edi,%edi
f0104bb5:	74 0c                	je     f0104bc3 <readline+0x73>
				cputchar('\b');
f0104bb7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104bbe:	e8 4c ba ff ff       	call   f010060f <cputchar>
			i--;
f0104bc3:	83 ee 01             	sub    $0x1,%esi
f0104bc6:	eb bb                	jmp    f0104b83 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104bc8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104bce:	7f 1c                	jg     f0104bec <readline+0x9c>
f0104bd0:	83 fb 1f             	cmp    $0x1f,%ebx
f0104bd3:	7e 17                	jle    f0104bec <readline+0x9c>
			if (echoing)
f0104bd5:	85 ff                	test   %edi,%edi
f0104bd7:	74 08                	je     f0104be1 <readline+0x91>
				cputchar(c);
f0104bd9:	89 1c 24             	mov    %ebx,(%esp)
f0104bdc:	e8 2e ba ff ff       	call   f010060f <cputchar>
			buf[i++] = c;
f0104be1:	88 9e 20 e8 17 f0    	mov    %bl,-0xfe817e0(%esi)
f0104be7:	83 c6 01             	add    $0x1,%esi
f0104bea:	eb 97                	jmp    f0104b83 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104bec:	83 fb 0d             	cmp    $0xd,%ebx
f0104bef:	74 05                	je     f0104bf6 <readline+0xa6>
f0104bf1:	83 fb 0a             	cmp    $0xa,%ebx
f0104bf4:	75 8d                	jne    f0104b83 <readline+0x33>
			if (echoing)
f0104bf6:	85 ff                	test   %edi,%edi
f0104bf8:	74 0c                	je     f0104c06 <readline+0xb6>
				cputchar('\n');
f0104bfa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104c01:	e8 09 ba ff ff       	call   f010060f <cputchar>
			buf[i] = 0;
f0104c06:	c6 86 20 e8 17 f0 00 	movb   $0x0,-0xfe817e0(%esi)
			return buf;
f0104c0d:	b8 20 e8 17 f0       	mov    $0xf017e820,%eax
		}
	}
}
f0104c12:	83 c4 1c             	add    $0x1c,%esp
f0104c15:	5b                   	pop    %ebx
f0104c16:	5e                   	pop    %esi
f0104c17:	5f                   	pop    %edi
f0104c18:	5d                   	pop    %ebp
f0104c19:	c3                   	ret    
f0104c1a:	66 90                	xchg   %ax,%ax
f0104c1c:	66 90                	xchg   %ax,%ax
f0104c1e:	66 90                	xchg   %ax,%ax

f0104c20 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104c20:	55                   	push   %ebp
f0104c21:	89 e5                	mov    %esp,%ebp
f0104c23:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104c26:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c2b:	eb 03                	jmp    f0104c30 <strlen+0x10>
		n++;
f0104c2d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104c30:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104c34:	75 f7                	jne    f0104c2d <strlen+0xd>
	return n;
}
f0104c36:	5d                   	pop    %ebp
f0104c37:	c3                   	ret    

f0104c38 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104c38:	55                   	push   %ebp
f0104c39:	89 e5                	mov    %esp,%ebp
f0104c3b:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
f0104c3e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104c41:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c46:	eb 03                	jmp    f0104c4b <strnlen+0x13>
		n++;
f0104c48:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104c4b:	39 d0                	cmp    %edx,%eax
f0104c4d:	74 06                	je     f0104c55 <strnlen+0x1d>
f0104c4f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104c53:	75 f3                	jne    f0104c48 <strnlen+0x10>
	return n;
}
f0104c55:	5d                   	pop    %ebp
f0104c56:	c3                   	ret    

f0104c57 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104c57:	55                   	push   %ebp
f0104c58:	89 e5                	mov    %esp,%ebp
f0104c5a:	53                   	push   %ebx
f0104c5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c5e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104c61:	89 c2                	mov    %eax,%edx
f0104c63:	0f b6 19             	movzbl (%ecx),%ebx
f0104c66:	88 1a                	mov    %bl,(%edx)
f0104c68:	83 c2 01             	add    $0x1,%edx
f0104c6b:	83 c1 01             	add    $0x1,%ecx
f0104c6e:	84 db                	test   %bl,%bl
f0104c70:	75 f1                	jne    f0104c63 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104c72:	5b                   	pop    %ebx
f0104c73:	5d                   	pop    %ebp
f0104c74:	c3                   	ret    

f0104c75 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104c75:	55                   	push   %ebp
f0104c76:	89 e5                	mov    %esp,%ebp
f0104c78:	53                   	push   %ebx
f0104c79:	83 ec 08             	sub    $0x8,%esp
f0104c7c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104c7f:	89 1c 24             	mov    %ebx,(%esp)
f0104c82:	e8 99 ff ff ff       	call   f0104c20 <strlen>
	strcpy(dst + len, src);
f0104c87:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c8a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104c8e:	01 d8                	add    %ebx,%eax
f0104c90:	89 04 24             	mov    %eax,(%esp)
f0104c93:	e8 bf ff ff ff       	call   f0104c57 <strcpy>
	return dst;
}
f0104c98:	89 d8                	mov    %ebx,%eax
f0104c9a:	83 c4 08             	add    $0x8,%esp
f0104c9d:	5b                   	pop    %ebx
f0104c9e:	5d                   	pop    %ebp
f0104c9f:	c3                   	ret    

f0104ca0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104ca0:	55                   	push   %ebp
f0104ca1:	89 e5                	mov    %esp,%ebp
f0104ca3:	56                   	push   %esi
f0104ca4:	53                   	push   %ebx
f0104ca5:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ca8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104cab:	89 f3                	mov    %esi,%ebx
f0104cad:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104cb0:	89 f2                	mov    %esi,%edx
f0104cb2:	eb 0e                	jmp    f0104cc2 <strncpy+0x22>
		*dst++ = *src;
f0104cb4:	0f b6 01             	movzbl (%ecx),%eax
f0104cb7:	88 02                	mov    %al,(%edx)
f0104cb9:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104cbc:	80 39 01             	cmpb   $0x1,(%ecx)
f0104cbf:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104cc2:	39 da                	cmp    %ebx,%edx
f0104cc4:	75 ee                	jne    f0104cb4 <strncpy+0x14>
	}
	return ret;
}
f0104cc6:	89 f0                	mov    %esi,%eax
f0104cc8:	5b                   	pop    %ebx
f0104cc9:	5e                   	pop    %esi
f0104cca:	5d                   	pop    %ebp
f0104ccb:	c3                   	ret    

f0104ccc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104ccc:	55                   	push   %ebp
f0104ccd:	89 e5                	mov    %esp,%ebp
f0104ccf:	56                   	push   %esi
f0104cd0:	53                   	push   %ebx
f0104cd1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104cd4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cd7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104cda:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
f0104cdc:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
f0104ce0:	85 c9                	test   %ecx,%ecx
f0104ce2:	75 0a                	jne    f0104cee <strlcpy+0x22>
f0104ce4:	eb 1c                	jmp    f0104d02 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104ce6:	88 08                	mov    %cl,(%eax)
f0104ce8:	83 c0 01             	add    $0x1,%eax
f0104ceb:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
f0104cee:	39 d8                	cmp    %ebx,%eax
f0104cf0:	74 0b                	je     f0104cfd <strlcpy+0x31>
f0104cf2:	0f b6 0a             	movzbl (%edx),%ecx
f0104cf5:	84 c9                	test   %cl,%cl
f0104cf7:	75 ed                	jne    f0104ce6 <strlcpy+0x1a>
f0104cf9:	89 c2                	mov    %eax,%edx
f0104cfb:	eb 02                	jmp    f0104cff <strlcpy+0x33>
f0104cfd:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0104cff:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104d02:	29 f0                	sub    %esi,%eax
}
f0104d04:	5b                   	pop    %ebx
f0104d05:	5e                   	pop    %esi
f0104d06:	5d                   	pop    %ebp
f0104d07:	c3                   	ret    

f0104d08 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104d08:	55                   	push   %ebp
f0104d09:	89 e5                	mov    %esp,%ebp
f0104d0b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104d0e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104d11:	eb 06                	jmp    f0104d19 <strcmp+0x11>
		p++, q++;
f0104d13:	83 c1 01             	add    $0x1,%ecx
f0104d16:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104d19:	0f b6 01             	movzbl (%ecx),%eax
f0104d1c:	84 c0                	test   %al,%al
f0104d1e:	74 04                	je     f0104d24 <strcmp+0x1c>
f0104d20:	3a 02                	cmp    (%edx),%al
f0104d22:	74 ef                	je     f0104d13 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104d24:	0f b6 c0             	movzbl %al,%eax
f0104d27:	0f b6 12             	movzbl (%edx),%edx
f0104d2a:	29 d0                	sub    %edx,%eax
}
f0104d2c:	5d                   	pop    %ebp
f0104d2d:	c3                   	ret    

f0104d2e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104d2e:	55                   	push   %ebp
f0104d2f:	89 e5                	mov    %esp,%ebp
f0104d31:	53                   	push   %ebx
f0104d32:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d35:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
f0104d38:	89 c3                	mov    %eax,%ebx
f0104d3a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104d3d:	eb 06                	jmp    f0104d45 <strncmp+0x17>
		n--, p++, q++;
f0104d3f:	83 c0 01             	add    $0x1,%eax
f0104d42:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0104d45:	39 d8                	cmp    %ebx,%eax
f0104d47:	74 15                	je     f0104d5e <strncmp+0x30>
f0104d49:	0f b6 08             	movzbl (%eax),%ecx
f0104d4c:	84 c9                	test   %cl,%cl
f0104d4e:	74 04                	je     f0104d54 <strncmp+0x26>
f0104d50:	3a 0a                	cmp    (%edx),%cl
f0104d52:	74 eb                	je     f0104d3f <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104d54:	0f b6 00             	movzbl (%eax),%eax
f0104d57:	0f b6 12             	movzbl (%edx),%edx
f0104d5a:	29 d0                	sub    %edx,%eax
f0104d5c:	eb 05                	jmp    f0104d63 <strncmp+0x35>
		return 0;
f0104d5e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d63:	5b                   	pop    %ebx
f0104d64:	5d                   	pop    %ebp
f0104d65:	c3                   	ret    

f0104d66 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104d66:	55                   	push   %ebp
f0104d67:	89 e5                	mov    %esp,%ebp
f0104d69:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d6c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104d70:	eb 07                	jmp    f0104d79 <strchr+0x13>
		if (*s == c)
f0104d72:	38 ca                	cmp    %cl,%dl
f0104d74:	74 0f                	je     f0104d85 <strchr+0x1f>
	for (; *s; s++)
f0104d76:	83 c0 01             	add    $0x1,%eax
f0104d79:	0f b6 10             	movzbl (%eax),%edx
f0104d7c:	84 d2                	test   %dl,%dl
f0104d7e:	75 f2                	jne    f0104d72 <strchr+0xc>
			return (char *) s;
	return 0;
f0104d80:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d85:	5d                   	pop    %ebp
f0104d86:	c3                   	ret    

f0104d87 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104d87:	55                   	push   %ebp
f0104d88:	89 e5                	mov    %esp,%ebp
f0104d8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d8d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104d91:	eb 07                	jmp    f0104d9a <strfind+0x13>
		if (*s == c)
f0104d93:	38 ca                	cmp    %cl,%dl
f0104d95:	74 0a                	je     f0104da1 <strfind+0x1a>
	for (; *s; s++)
f0104d97:	83 c0 01             	add    $0x1,%eax
f0104d9a:	0f b6 10             	movzbl (%eax),%edx
f0104d9d:	84 d2                	test   %dl,%dl
f0104d9f:	75 f2                	jne    f0104d93 <strfind+0xc>
			break;
	return (char *) s;
}
f0104da1:	5d                   	pop    %ebp
f0104da2:	c3                   	ret    

f0104da3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104da3:	55                   	push   %ebp
f0104da4:	89 e5                	mov    %esp,%ebp
f0104da6:	83 ec 0c             	sub    $0xc,%esp
f0104da9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0104dac:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104daf:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104db2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104db5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104db8:	85 c9                	test   %ecx,%ecx
f0104dba:	74 36                	je     f0104df2 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104dbc:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104dc2:	75 28                	jne    f0104dec <memset+0x49>
f0104dc4:	f6 c1 03             	test   $0x3,%cl
f0104dc7:	75 23                	jne    f0104dec <memset+0x49>
		c &= 0xFF;
f0104dc9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104dcd:	89 d3                	mov    %edx,%ebx
f0104dcf:	c1 e3 08             	shl    $0x8,%ebx
f0104dd2:	89 d6                	mov    %edx,%esi
f0104dd4:	c1 e6 18             	shl    $0x18,%esi
f0104dd7:	89 d0                	mov    %edx,%eax
f0104dd9:	c1 e0 10             	shl    $0x10,%eax
f0104ddc:	09 f0                	or     %esi,%eax
f0104dde:	09 c2                	or     %eax,%edx
f0104de0:	89 d0                	mov    %edx,%eax
f0104de2:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104de4:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104de7:	fc                   	cld    
f0104de8:	f3 ab                	rep stos %eax,%es:(%edi)
f0104dea:	eb 06                	jmp    f0104df2 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104dec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104def:	fc                   	cld    
f0104df0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104df2:	89 f8                	mov    %edi,%eax
f0104df4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104df7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104dfa:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104dfd:	89 ec                	mov    %ebp,%esp
f0104dff:	5d                   	pop    %ebp
f0104e00:	c3                   	ret    

f0104e01 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104e01:	55                   	push   %ebp
f0104e02:	89 e5                	mov    %esp,%ebp
f0104e04:	83 ec 08             	sub    $0x8,%esp
f0104e07:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104e0a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104e0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e10:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e13:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104e16:	39 c6                	cmp    %eax,%esi
f0104e18:	73 36                	jae    f0104e50 <memmove+0x4f>
f0104e1a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104e1d:	39 d0                	cmp    %edx,%eax
f0104e1f:	73 2f                	jae    f0104e50 <memmove+0x4f>
		s += n;
		d += n;
f0104e21:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104e24:	f6 c2 03             	test   $0x3,%dl
f0104e27:	75 1b                	jne    f0104e44 <memmove+0x43>
f0104e29:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104e2f:	75 13                	jne    f0104e44 <memmove+0x43>
f0104e31:	f6 c1 03             	test   $0x3,%cl
f0104e34:	75 0e                	jne    f0104e44 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104e36:	83 ef 04             	sub    $0x4,%edi
f0104e39:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104e3c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0104e3f:	fd                   	std    
f0104e40:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104e42:	eb 09                	jmp    f0104e4d <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104e44:	83 ef 01             	sub    $0x1,%edi
f0104e47:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0104e4a:	fd                   	std    
f0104e4b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104e4d:	fc                   	cld    
f0104e4e:	eb 20                	jmp    f0104e70 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104e50:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104e56:	75 13                	jne    f0104e6b <memmove+0x6a>
f0104e58:	a8 03                	test   $0x3,%al
f0104e5a:	75 0f                	jne    f0104e6b <memmove+0x6a>
f0104e5c:	f6 c1 03             	test   $0x3,%cl
f0104e5f:	75 0a                	jne    f0104e6b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104e61:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0104e64:	89 c7                	mov    %eax,%edi
f0104e66:	fc                   	cld    
f0104e67:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104e69:	eb 05                	jmp    f0104e70 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
f0104e6b:	89 c7                	mov    %eax,%edi
f0104e6d:	fc                   	cld    
f0104e6e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104e70:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104e73:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104e76:	89 ec                	mov    %ebp,%esp
f0104e78:	5d                   	pop    %ebp
f0104e79:	c3                   	ret    

f0104e7a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104e7a:	55                   	push   %ebp
f0104e7b:	89 e5                	mov    %esp,%ebp
f0104e7d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104e80:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e83:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e87:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e91:	89 04 24             	mov    %eax,(%esp)
f0104e94:	e8 68 ff ff ff       	call   f0104e01 <memmove>
}
f0104e99:	c9                   	leave  
f0104e9a:	c3                   	ret    

f0104e9b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104e9b:	55                   	push   %ebp
f0104e9c:	89 e5                	mov    %esp,%ebp
f0104e9e:	56                   	push   %esi
f0104e9f:	53                   	push   %ebx
f0104ea0:	8b 55 08             	mov    0x8(%ebp),%edx
f0104ea3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
f0104ea6:	89 d6                	mov    %edx,%esi
f0104ea8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104eab:	eb 1a                	jmp    f0104ec7 <memcmp+0x2c>
		if (*s1 != *s2)
f0104ead:	0f b6 02             	movzbl (%edx),%eax
f0104eb0:	0f b6 19             	movzbl (%ecx),%ebx
f0104eb3:	38 d8                	cmp    %bl,%al
f0104eb5:	74 0a                	je     f0104ec1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104eb7:	0f b6 c0             	movzbl %al,%eax
f0104eba:	0f b6 db             	movzbl %bl,%ebx
f0104ebd:	29 d8                	sub    %ebx,%eax
f0104ebf:	eb 0f                	jmp    f0104ed0 <memcmp+0x35>
		s1++, s2++;
f0104ec1:	83 c2 01             	add    $0x1,%edx
f0104ec4:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0104ec7:	39 f2                	cmp    %esi,%edx
f0104ec9:	75 e2                	jne    f0104ead <memcmp+0x12>
	}

	return 0;
f0104ecb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ed0:	5b                   	pop    %ebx
f0104ed1:	5e                   	pop    %esi
f0104ed2:	5d                   	pop    %ebp
f0104ed3:	c3                   	ret    

f0104ed4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104ed4:	55                   	push   %ebp
f0104ed5:	89 e5                	mov    %esp,%ebp
f0104ed7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eda:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104edd:	89 c2                	mov    %eax,%edx
f0104edf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104ee2:	eb 07                	jmp    f0104eeb <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104ee4:	38 08                	cmp    %cl,(%eax)
f0104ee6:	74 07                	je     f0104eef <memfind+0x1b>
	for (; s < ends; s++)
f0104ee8:	83 c0 01             	add    $0x1,%eax
f0104eeb:	39 d0                	cmp    %edx,%eax
f0104eed:	72 f5                	jb     f0104ee4 <memfind+0x10>
			break;
	return (void *) s;
}
f0104eef:	5d                   	pop    %ebp
f0104ef0:	c3                   	ret    

f0104ef1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104ef1:	55                   	push   %ebp
f0104ef2:	89 e5                	mov    %esp,%ebp
f0104ef4:	57                   	push   %edi
f0104ef5:	56                   	push   %esi
f0104ef6:	53                   	push   %ebx
f0104ef7:	83 ec 04             	sub    $0x4,%esp
f0104efa:	8b 55 08             	mov    0x8(%ebp),%edx
f0104efd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104f00:	eb 03                	jmp    f0104f05 <strtol+0x14>
		s++;
f0104f02:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0104f05:	0f b6 02             	movzbl (%edx),%eax
f0104f08:	3c 09                	cmp    $0x9,%al
f0104f0a:	74 f6                	je     f0104f02 <strtol+0x11>
f0104f0c:	3c 20                	cmp    $0x20,%al
f0104f0e:	74 f2                	je     f0104f02 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
f0104f10:	3c 2b                	cmp    $0x2b,%al
f0104f12:	75 0a                	jne    f0104f1e <strtol+0x2d>
		s++;
f0104f14:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0104f17:	bf 00 00 00 00       	mov    $0x0,%edi
f0104f1c:	eb 10                	jmp    f0104f2e <strtol+0x3d>
f0104f1e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0104f23:	3c 2d                	cmp    $0x2d,%al
f0104f25:	75 07                	jne    f0104f2e <strtol+0x3d>
		s++, neg = 1;
f0104f27:	8d 52 01             	lea    0x1(%edx),%edx
f0104f2a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104f2e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104f34:	75 15                	jne    f0104f4b <strtol+0x5a>
f0104f36:	80 3a 30             	cmpb   $0x30,(%edx)
f0104f39:	75 10                	jne    f0104f4b <strtol+0x5a>
f0104f3b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104f3f:	75 0a                	jne    f0104f4b <strtol+0x5a>
		s += 2, base = 16;
f0104f41:	83 c2 02             	add    $0x2,%edx
f0104f44:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104f49:	eb 10                	jmp    f0104f5b <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104f4b:	85 db                	test   %ebx,%ebx
f0104f4d:	75 0c                	jne    f0104f5b <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104f4f:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
f0104f51:	80 3a 30             	cmpb   $0x30,(%edx)
f0104f54:	75 05                	jne    f0104f5b <strtol+0x6a>
		s++, base = 8;
f0104f56:	83 c2 01             	add    $0x1,%edx
f0104f59:	b3 08                	mov    $0x8,%bl
		base = 10;
f0104f5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f60:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104f63:	0f b6 0a             	movzbl (%edx),%ecx
f0104f66:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104f69:	89 f3                	mov    %esi,%ebx
f0104f6b:	80 fb 09             	cmp    $0x9,%bl
f0104f6e:	77 08                	ja     f0104f78 <strtol+0x87>
			dig = *s - '0';
f0104f70:	0f be c9             	movsbl %cl,%ecx
f0104f73:	83 e9 30             	sub    $0x30,%ecx
f0104f76:	eb 22                	jmp    f0104f9a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f0104f78:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104f7b:	89 f3                	mov    %esi,%ebx
f0104f7d:	80 fb 19             	cmp    $0x19,%bl
f0104f80:	77 08                	ja     f0104f8a <strtol+0x99>
			dig = *s - 'a' + 10;
f0104f82:	0f be c9             	movsbl %cl,%ecx
f0104f85:	83 e9 57             	sub    $0x57,%ecx
f0104f88:	eb 10                	jmp    f0104f9a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f0104f8a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104f8d:	89 f3                	mov    %esi,%ebx
f0104f8f:	80 fb 19             	cmp    $0x19,%bl
f0104f92:	77 16                	ja     f0104faa <strtol+0xb9>
			dig = *s - 'A' + 10;
f0104f94:	0f be c9             	movsbl %cl,%ecx
f0104f97:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104f9a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0104f9d:	7d 0f                	jge    f0104fae <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104f9f:	83 c2 01             	add    $0x1,%edx
f0104fa2:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0104fa6:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104fa8:	eb b9                	jmp    f0104f63 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
f0104faa:	89 c1                	mov    %eax,%ecx
f0104fac:	eb 02                	jmp    f0104fb0 <strtol+0xbf>
		if (dig >= base)
f0104fae:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0104fb0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104fb4:	74 05                	je     f0104fbb <strtol+0xca>
		*endptr = (char *) s;
f0104fb6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fb9:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104fbb:	89 ca                	mov    %ecx,%edx
f0104fbd:	f7 da                	neg    %edx
f0104fbf:	85 ff                	test   %edi,%edi
f0104fc1:	0f 45 c2             	cmovne %edx,%eax
}
f0104fc4:	83 c4 04             	add    $0x4,%esp
f0104fc7:	5b                   	pop    %ebx
f0104fc8:	5e                   	pop    %esi
f0104fc9:	5f                   	pop    %edi
f0104fca:	5d                   	pop    %ebp
f0104fcb:	c3                   	ret    
f0104fcc:	66 90                	xchg   %ax,%ax
f0104fce:	66 90                	xchg   %ax,%ax

f0104fd0 <__udivdi3>:
f0104fd0:	83 ec 1c             	sub    $0x1c,%esp
f0104fd3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0104fd7:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104fdb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104fdf:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104fe3:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0104fe7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0104feb:	85 c0                	test   %eax,%eax
f0104fed:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104ff1:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104ff5:	89 ea                	mov    %ebp,%edx
f0104ff7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104ffb:	75 33                	jne    f0105030 <__udivdi3+0x60>
f0104ffd:	39 e9                	cmp    %ebp,%ecx
f0104fff:	77 6f                	ja     f0105070 <__udivdi3+0xa0>
f0105001:	85 c9                	test   %ecx,%ecx
f0105003:	89 ce                	mov    %ecx,%esi
f0105005:	75 0b                	jne    f0105012 <__udivdi3+0x42>
f0105007:	b8 01 00 00 00       	mov    $0x1,%eax
f010500c:	31 d2                	xor    %edx,%edx
f010500e:	f7 f1                	div    %ecx
f0105010:	89 c6                	mov    %eax,%esi
f0105012:	31 d2                	xor    %edx,%edx
f0105014:	89 e8                	mov    %ebp,%eax
f0105016:	f7 f6                	div    %esi
f0105018:	89 c5                	mov    %eax,%ebp
f010501a:	89 f8                	mov    %edi,%eax
f010501c:	f7 f6                	div    %esi
f010501e:	89 ea                	mov    %ebp,%edx
f0105020:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105024:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105028:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010502c:	83 c4 1c             	add    $0x1c,%esp
f010502f:	c3                   	ret    
f0105030:	39 e8                	cmp    %ebp,%eax
f0105032:	77 24                	ja     f0105058 <__udivdi3+0x88>
f0105034:	0f bd c8             	bsr    %eax,%ecx
f0105037:	83 f1 1f             	xor    $0x1f,%ecx
f010503a:	89 0c 24             	mov    %ecx,(%esp)
f010503d:	75 49                	jne    f0105088 <__udivdi3+0xb8>
f010503f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105043:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0105047:	0f 86 ab 00 00 00    	jbe    f01050f8 <__udivdi3+0x128>
f010504d:	39 e8                	cmp    %ebp,%eax
f010504f:	0f 82 a3 00 00 00    	jb     f01050f8 <__udivdi3+0x128>
f0105055:	8d 76 00             	lea    0x0(%esi),%esi
f0105058:	31 d2                	xor    %edx,%edx
f010505a:	31 c0                	xor    %eax,%eax
f010505c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105060:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105064:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0105068:	83 c4 1c             	add    $0x1c,%esp
f010506b:	c3                   	ret    
f010506c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105070:	89 f8                	mov    %edi,%eax
f0105072:	f7 f1                	div    %ecx
f0105074:	31 d2                	xor    %edx,%edx
f0105076:	8b 74 24 10          	mov    0x10(%esp),%esi
f010507a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010507e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0105082:	83 c4 1c             	add    $0x1c,%esp
f0105085:	c3                   	ret    
f0105086:	66 90                	xchg   %ax,%ax
f0105088:	0f b6 0c 24          	movzbl (%esp),%ecx
f010508c:	89 c6                	mov    %eax,%esi
f010508e:	b8 20 00 00 00       	mov    $0x20,%eax
f0105093:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0105097:	2b 04 24             	sub    (%esp),%eax
f010509a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010509e:	d3 e6                	shl    %cl,%esi
f01050a0:	89 c1                	mov    %eax,%ecx
f01050a2:	d3 ed                	shr    %cl,%ebp
f01050a4:	0f b6 0c 24          	movzbl (%esp),%ecx
f01050a8:	09 f5                	or     %esi,%ebp
f01050aa:	8b 74 24 04          	mov    0x4(%esp),%esi
f01050ae:	d3 e6                	shl    %cl,%esi
f01050b0:	89 c1                	mov    %eax,%ecx
f01050b2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01050b6:	89 d6                	mov    %edx,%esi
f01050b8:	d3 ee                	shr    %cl,%esi
f01050ba:	0f b6 0c 24          	movzbl (%esp),%ecx
f01050be:	d3 e2                	shl    %cl,%edx
f01050c0:	89 c1                	mov    %eax,%ecx
f01050c2:	d3 ef                	shr    %cl,%edi
f01050c4:	09 d7                	or     %edx,%edi
f01050c6:	89 f2                	mov    %esi,%edx
f01050c8:	89 f8                	mov    %edi,%eax
f01050ca:	f7 f5                	div    %ebp
f01050cc:	89 d6                	mov    %edx,%esi
f01050ce:	89 c7                	mov    %eax,%edi
f01050d0:	f7 64 24 04          	mull   0x4(%esp)
f01050d4:	39 d6                	cmp    %edx,%esi
f01050d6:	72 30                	jb     f0105108 <__udivdi3+0x138>
f01050d8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01050dc:	0f b6 0c 24          	movzbl (%esp),%ecx
f01050e0:	d3 e5                	shl    %cl,%ebp
f01050e2:	39 c5                	cmp    %eax,%ebp
f01050e4:	73 04                	jae    f01050ea <__udivdi3+0x11a>
f01050e6:	39 d6                	cmp    %edx,%esi
f01050e8:	74 1e                	je     f0105108 <__udivdi3+0x138>
f01050ea:	89 f8                	mov    %edi,%eax
f01050ec:	31 d2                	xor    %edx,%edx
f01050ee:	e9 69 ff ff ff       	jmp    f010505c <__udivdi3+0x8c>
f01050f3:	90                   	nop
f01050f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01050f8:	31 d2                	xor    %edx,%edx
f01050fa:	b8 01 00 00 00       	mov    $0x1,%eax
f01050ff:	e9 58 ff ff ff       	jmp    f010505c <__udivdi3+0x8c>
f0105104:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105108:	8d 47 ff             	lea    -0x1(%edi),%eax
f010510b:	31 d2                	xor    %edx,%edx
f010510d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105111:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105115:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0105119:	83 c4 1c             	add    $0x1c,%esp
f010511c:	c3                   	ret    
f010511d:	66 90                	xchg   %ax,%ax
f010511f:	90                   	nop

f0105120 <__umoddi3>:
f0105120:	83 ec 2c             	sub    $0x2c,%esp
f0105123:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105127:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010512b:	89 74 24 20          	mov    %esi,0x20(%esp)
f010512f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0105133:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0105137:	8b 7c 24 34          	mov    0x34(%esp),%edi
f010513b:	85 c0                	test   %eax,%eax
f010513d:	89 c2                	mov    %eax,%edx
f010513f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0105143:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105147:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010514b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010514f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105153:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0105157:	75 1f                	jne    f0105178 <__umoddi3+0x58>
f0105159:	39 fe                	cmp    %edi,%esi
f010515b:	76 63                	jbe    f01051c0 <__umoddi3+0xa0>
f010515d:	89 c8                	mov    %ecx,%eax
f010515f:	89 fa                	mov    %edi,%edx
f0105161:	f7 f6                	div    %esi
f0105163:	89 d0                	mov    %edx,%eax
f0105165:	31 d2                	xor    %edx,%edx
f0105167:	8b 74 24 20          	mov    0x20(%esp),%esi
f010516b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010516f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0105173:	83 c4 2c             	add    $0x2c,%esp
f0105176:	c3                   	ret    
f0105177:	90                   	nop
f0105178:	39 f8                	cmp    %edi,%eax
f010517a:	77 64                	ja     f01051e0 <__umoddi3+0xc0>
f010517c:	0f bd e8             	bsr    %eax,%ebp
f010517f:	83 f5 1f             	xor    $0x1f,%ebp
f0105182:	75 74                	jne    f01051f8 <__umoddi3+0xd8>
f0105184:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105188:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010518c:	0f 87 0e 01 00 00    	ja     f01052a0 <__umoddi3+0x180>
f0105192:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0105196:	29 f1                	sub    %esi,%ecx
f0105198:	19 c7                	sbb    %eax,%edi
f010519a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010519e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01051a2:	8b 44 24 14          	mov    0x14(%esp),%eax
f01051a6:	8b 54 24 18          	mov    0x18(%esp),%edx
f01051aa:	8b 74 24 20          	mov    0x20(%esp),%esi
f01051ae:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01051b2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01051b6:	83 c4 2c             	add    $0x2c,%esp
f01051b9:	c3                   	ret    
f01051ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01051c0:	85 f6                	test   %esi,%esi
f01051c2:	89 f5                	mov    %esi,%ebp
f01051c4:	75 0b                	jne    f01051d1 <__umoddi3+0xb1>
f01051c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01051cb:	31 d2                	xor    %edx,%edx
f01051cd:	f7 f6                	div    %esi
f01051cf:	89 c5                	mov    %eax,%ebp
f01051d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01051d5:	31 d2                	xor    %edx,%edx
f01051d7:	f7 f5                	div    %ebp
f01051d9:	89 c8                	mov    %ecx,%eax
f01051db:	f7 f5                	div    %ebp
f01051dd:	eb 84                	jmp    f0105163 <__umoddi3+0x43>
f01051df:	90                   	nop
f01051e0:	89 c8                	mov    %ecx,%eax
f01051e2:	89 fa                	mov    %edi,%edx
f01051e4:	8b 74 24 20          	mov    0x20(%esp),%esi
f01051e8:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01051ec:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01051f0:	83 c4 2c             	add    $0x2c,%esp
f01051f3:	c3                   	ret    
f01051f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01051f8:	8b 44 24 10          	mov    0x10(%esp),%eax
f01051fc:	be 20 00 00 00       	mov    $0x20,%esi
f0105201:	89 e9                	mov    %ebp,%ecx
f0105203:	29 ee                	sub    %ebp,%esi
f0105205:	d3 e2                	shl    %cl,%edx
f0105207:	89 f1                	mov    %esi,%ecx
f0105209:	d3 e8                	shr    %cl,%eax
f010520b:	89 e9                	mov    %ebp,%ecx
f010520d:	09 d0                	or     %edx,%eax
f010520f:	89 fa                	mov    %edi,%edx
f0105211:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105215:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105219:	d3 e0                	shl    %cl,%eax
f010521b:	89 f1                	mov    %esi,%ecx
f010521d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105221:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105225:	d3 ea                	shr    %cl,%edx
f0105227:	89 e9                	mov    %ebp,%ecx
f0105229:	d3 e7                	shl    %cl,%edi
f010522b:	89 f1                	mov    %esi,%ecx
f010522d:	d3 e8                	shr    %cl,%eax
f010522f:	89 e9                	mov    %ebp,%ecx
f0105231:	09 f8                	or     %edi,%eax
f0105233:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0105237:	f7 74 24 0c          	divl   0xc(%esp)
f010523b:	d3 e7                	shl    %cl,%edi
f010523d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0105241:	89 d7                	mov    %edx,%edi
f0105243:	f7 64 24 10          	mull   0x10(%esp)
f0105247:	39 d7                	cmp    %edx,%edi
f0105249:	89 c1                	mov    %eax,%ecx
f010524b:	89 54 24 14          	mov    %edx,0x14(%esp)
f010524f:	72 3b                	jb     f010528c <__umoddi3+0x16c>
f0105251:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0105255:	72 31                	jb     f0105288 <__umoddi3+0x168>
f0105257:	8b 44 24 18          	mov    0x18(%esp),%eax
f010525b:	29 c8                	sub    %ecx,%eax
f010525d:	19 d7                	sbb    %edx,%edi
f010525f:	89 e9                	mov    %ebp,%ecx
f0105261:	89 fa                	mov    %edi,%edx
f0105263:	d3 e8                	shr    %cl,%eax
f0105265:	89 f1                	mov    %esi,%ecx
f0105267:	d3 e2                	shl    %cl,%edx
f0105269:	89 e9                	mov    %ebp,%ecx
f010526b:	09 d0                	or     %edx,%eax
f010526d:	89 fa                	mov    %edi,%edx
f010526f:	d3 ea                	shr    %cl,%edx
f0105271:	8b 74 24 20          	mov    0x20(%esp),%esi
f0105275:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0105279:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f010527d:	83 c4 2c             	add    $0x2c,%esp
f0105280:	c3                   	ret    
f0105281:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105288:	39 d7                	cmp    %edx,%edi
f010528a:	75 cb                	jne    f0105257 <__umoddi3+0x137>
f010528c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0105290:	89 c1                	mov    %eax,%ecx
f0105292:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0105296:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010529a:	eb bb                	jmp    f0105257 <__umoddi3+0x137>
f010529c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01052a0:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01052a4:	0f 82 e8 fe ff ff    	jb     f0105192 <__umoddi3+0x72>
f01052aa:	e9 f3 fe ff ff       	jmp    f01051a2 <__umoddi3+0x82>
