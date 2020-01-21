
obj/user/testbss：     文件格式 elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 cd 00 00 00       	call   8000fe <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800039:	c7 04 24 e0 0f 80 00 	movl   $0x800fe0,(%esp)
  800040:	e8 18 02 00 00       	call   80025d <cprintf>
	for (i = 0; i < ARRAYSIZE; i++)
  800045:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004a:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800051:	00 
  800052:	74 20                	je     800074 <umain+0x41>
			panic("bigarray[%d] isn't cleared!\n", i);
  800054:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800058:	c7 44 24 08 5b 10 80 	movl   $0x80105b,0x8(%esp)
  80005f:	00 
  800060:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
  800067:	00 
  800068:	c7 04 24 78 10 80 00 	movl   $0x801078,(%esp)
  80006f:	e8 f0 00 00 00       	call   800164 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
  800074:	83 c0 01             	add    $0x1,%eax
  800077:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80007c:	75 cc                	jne    80004a <umain+0x17>
  80007e:	b8 00 00 00 00       	mov    $0x0,%eax
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800083:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)
	for (i = 0; i < ARRAYSIZE; i++)
  80008a:	83 c0 01             	add    $0x1,%eax
  80008d:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800092:	75 ef                	jne    800083 <umain+0x50>
  800094:	b8 00 00 00 00       	mov    $0x0,%eax
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  800099:	39 04 85 20 20 80 00 	cmp    %eax,0x802020(,%eax,4)
  8000a0:	74 20                	je     8000c2 <umain+0x8f>
			panic("bigarray[%d] didn't hold its value!\n", i);
  8000a2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000a6:	c7 44 24 08 00 10 80 	movl   $0x801000,0x8(%esp)
  8000ad:	00 
  8000ae:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
  8000b5:	00 
  8000b6:	c7 04 24 78 10 80 00 	movl   $0x801078,(%esp)
  8000bd:	e8 a2 00 00 00       	call   800164 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
  8000c2:	83 c0 01             	add    $0x1,%eax
  8000c5:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000ca:	75 cd                	jne    800099 <umain+0x66>

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000cc:	c7 04 24 28 10 80 00 	movl   $0x801028,(%esp)
  8000d3:	e8 85 01 00 00       	call   80025d <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000d8:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000df:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000e2:	c7 44 24 08 87 10 80 	movl   $0x801087,0x8(%esp)
  8000e9:	00 
  8000ea:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  8000f1:	00 
  8000f2:	c7 04 24 78 10 80 00 	movl   $0x801078,(%esp)
  8000f9:	e8 66 00 00 00       	call   800164 <_panic>

008000fe <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000fe:	55                   	push   %ebp
  8000ff:	89 e5                	mov    %esp,%ebp
  800101:	83 ec 18             	sub    $0x18,%esp
  800104:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800107:	89 75 fc             	mov    %esi,-0x4(%ebp)
  80010a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80010d:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	thisenv = &envs[ENVX(sys_getenvid())];
  800110:	e8 b3 0b 00 00       	call   800cc8 <sys_getenvid>
  800115:	25 ff 03 00 00       	and    $0x3ff,%eax
  80011a:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80011d:	c1 e0 05             	shl    $0x5,%eax
  800120:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800125:	a3 20 20 c0 00       	mov    %eax,0xc02020

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80012a:	85 db                	test   %ebx,%ebx
  80012c:	7e 07                	jle    800135 <libmain+0x37>
		binaryname = argv[0];
  80012e:	8b 06                	mov    (%esi),%eax
  800130:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800135:	89 74 24 04          	mov    %esi,0x4(%esp)
  800139:	89 1c 24             	mov    %ebx,(%esp)
  80013c:	e8 f2 fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800141:	e8 0a 00 00 00       	call   800150 <exit>
}
  800146:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  800149:	8b 75 fc             	mov    -0x4(%ebp),%esi
  80014c:	89 ec                	mov    %ebp,%esp
  80014e:	5d                   	pop    %ebp
  80014f:	c3                   	ret    

00800150 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800156:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80015d:	e8 09 0b 00 00       	call   800c6b <sys_env_destroy>
}
  800162:	c9                   	leave  
  800163:	c3                   	ret    

00800164 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800164:	55                   	push   %ebp
  800165:	89 e5                	mov    %esp,%ebp
  800167:	56                   	push   %esi
  800168:	53                   	push   %ebx
  800169:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80016c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80016f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800175:	e8 4e 0b 00 00       	call   800cc8 <sys_getenvid>
  80017a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80017d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800181:	8b 55 08             	mov    0x8(%ebp),%edx
  800184:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800188:	89 74 24 08          	mov    %esi,0x8(%esp)
  80018c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800190:	c7 04 24 a8 10 80 00 	movl   $0x8010a8,(%esp)
  800197:	e8 c1 00 00 00       	call   80025d <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80019c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001a0:	8b 45 10             	mov    0x10(%ebp),%eax
  8001a3:	89 04 24             	mov    %eax,(%esp)
  8001a6:	e8 51 00 00 00       	call   8001fc <vcprintf>
	cprintf("\n");
  8001ab:	c7 04 24 76 10 80 00 	movl   $0x801076,(%esp)
  8001b2:	e8 a6 00 00 00       	call   80025d <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001b7:	cc                   	int3   
  8001b8:	eb fd                	jmp    8001b7 <_panic+0x53>

008001ba <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001ba:	55                   	push   %ebp
  8001bb:	89 e5                	mov    %esp,%ebp
  8001bd:	53                   	push   %ebx
  8001be:	83 ec 14             	sub    $0x14,%esp
  8001c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001c4:	8b 03                	mov    (%ebx),%eax
  8001c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8001c9:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8001cd:	83 c0 01             	add    $0x1,%eax
  8001d0:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8001d2:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001d7:	75 19                	jne    8001f2 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001d9:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001e0:	00 
  8001e1:	8d 43 08             	lea    0x8(%ebx),%eax
  8001e4:	89 04 24             	mov    %eax,(%esp)
  8001e7:	e8 20 0a 00 00       	call   800c0c <sys_cputs>
		b->idx = 0;
  8001ec:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001f2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001f6:	83 c4 14             	add    $0x14,%esp
  8001f9:	5b                   	pop    %ebx
  8001fa:	5d                   	pop    %ebp
  8001fb:	c3                   	ret    

008001fc <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
  8001ff:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800205:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80020c:	00 00 00 
	b.cnt = 0;
  80020f:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800216:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800219:	8b 45 0c             	mov    0xc(%ebp),%eax
  80021c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800220:	8b 45 08             	mov    0x8(%ebp),%eax
  800223:	89 44 24 08          	mov    %eax,0x8(%esp)
  800227:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80022d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800231:	c7 04 24 ba 01 80 00 	movl   $0x8001ba,(%esp)
  800238:	e8 a8 01 00 00       	call   8003e5 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80023d:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800243:	89 44 24 04          	mov    %eax,0x4(%esp)
  800247:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80024d:	89 04 24             	mov    %eax,(%esp)
  800250:	e8 b7 09 00 00       	call   800c0c <sys_cputs>

	return b.cnt;
}
  800255:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80025b:	c9                   	leave  
  80025c:	c3                   	ret    

0080025d <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80025d:	55                   	push   %ebp
  80025e:	89 e5                	mov    %esp,%ebp
  800260:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800263:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800266:	89 44 24 04          	mov    %eax,0x4(%esp)
  80026a:	8b 45 08             	mov    0x8(%ebp),%eax
  80026d:	89 04 24             	mov    %eax,(%esp)
  800270:	e8 87 ff ff ff       	call   8001fc <vcprintf>
	va_end(ap);

	return cnt;
}
  800275:	c9                   	leave  
  800276:	c3                   	ret    
  800277:	66 90                	xchg   %ax,%ax
  800279:	66 90                	xchg   %ax,%ax
  80027b:	66 90                	xchg   %ax,%ax
  80027d:	66 90                	xchg   %ax,%ax
  80027f:	90                   	nop

00800280 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800280:	55                   	push   %ebp
  800281:	89 e5                	mov    %esp,%ebp
  800283:	57                   	push   %edi
  800284:	56                   	push   %esi
  800285:	53                   	push   %ebx
  800286:	83 ec 4c             	sub    $0x4c,%esp
  800289:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80028c:	89 d7                	mov    %edx,%edi
  80028e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800291:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800294:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800297:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80029a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80029d:	85 db                	test   %ebx,%ebx
  80029f:	75 08                	jne    8002a9 <printnum+0x29>
  8002a1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002a4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8002a7:	77 6c                	ja     800315 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002a9:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8002ac:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8002b0:	83 ee 01             	sub    $0x1,%esi
  8002b3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002ba:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002be:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002c2:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002c6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002c9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8002cc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002d3:	00 
  8002d4:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002d7:	89 1c 24             	mov    %ebx,(%esp)
  8002da:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8002dd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002e1:	e8 1a 0a 00 00       	call   800d00 <__udivdi3>
  8002e6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8002e9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8002ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002f0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8002f4:	89 04 24             	mov    %eax,(%esp)
  8002f7:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002fb:	89 fa                	mov    %edi,%edx
  8002fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800300:	e8 7b ff ff ff       	call   800280 <printnum>
  800305:	eb 1b                	jmp    800322 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800307:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80030b:	8b 45 18             	mov    0x18(%ebp),%eax
  80030e:	89 04 24             	mov    %eax,(%esp)
  800311:	ff d3                	call   *%ebx
  800313:	eb 03                	jmp    800318 <printnum+0x98>
  800315:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
  800318:	83 ee 01             	sub    $0x1,%esi
  80031b:	85 f6                	test   %esi,%esi
  80031d:	7f e8                	jg     800307 <printnum+0x87>
  80031f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800322:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800326:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80032a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80032d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800331:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800338:	00 
  800339:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80033c:	89 1c 24             	mov    %ebx,(%esp)
  80033f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800342:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800346:	e8 05 0b 00 00       	call   800e50 <__umoddi3>
  80034b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80034f:	0f be 80 cc 10 80 00 	movsbl 0x8010cc(%eax),%eax
  800356:	89 04 24             	mov    %eax,(%esp)
  800359:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80035c:	ff d0                	call   *%eax
}
  80035e:	83 c4 4c             	add    $0x4c,%esp
  800361:	5b                   	pop    %ebx
  800362:	5e                   	pop    %esi
  800363:	5f                   	pop    %edi
  800364:	5d                   	pop    %ebp
  800365:	c3                   	ret    

00800366 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800366:	55                   	push   %ebp
  800367:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800369:	83 fa 01             	cmp    $0x1,%edx
  80036c:	7e 0e                	jle    80037c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80036e:	8b 10                	mov    (%eax),%edx
  800370:	8d 4a 08             	lea    0x8(%edx),%ecx
  800373:	89 08                	mov    %ecx,(%eax)
  800375:	8b 02                	mov    (%edx),%eax
  800377:	8b 52 04             	mov    0x4(%edx),%edx
  80037a:	eb 22                	jmp    80039e <getuint+0x38>
	else if (lflag)
  80037c:	85 d2                	test   %edx,%edx
  80037e:	74 10                	je     800390 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800380:	8b 10                	mov    (%eax),%edx
  800382:	8d 4a 04             	lea    0x4(%edx),%ecx
  800385:	89 08                	mov    %ecx,(%eax)
  800387:	8b 02                	mov    (%edx),%eax
  800389:	ba 00 00 00 00       	mov    $0x0,%edx
  80038e:	eb 0e                	jmp    80039e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800390:	8b 10                	mov    (%eax),%edx
  800392:	8d 4a 04             	lea    0x4(%edx),%ecx
  800395:	89 08                	mov    %ecx,(%eax)
  800397:	8b 02                	mov    (%edx),%eax
  800399:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80039e:	5d                   	pop    %ebp
  80039f:	c3                   	ret    

008003a0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003a0:	55                   	push   %ebp
  8003a1:	89 e5                	mov    %esp,%ebp
  8003a3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003a6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003aa:	8b 10                	mov    (%eax),%edx
  8003ac:	3b 50 04             	cmp    0x4(%eax),%edx
  8003af:	73 0a                	jae    8003bb <sprintputch+0x1b>
		*b->buf++ = ch;
  8003b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003b4:	88 0a                	mov    %cl,(%edx)
  8003b6:	83 c2 01             	add    $0x1,%edx
  8003b9:	89 10                	mov    %edx,(%eax)
}
  8003bb:	5d                   	pop    %ebp
  8003bc:	c3                   	ret    

008003bd <printfmt>:
{
  8003bd:	55                   	push   %ebp
  8003be:	89 e5                	mov    %esp,%ebp
  8003c0:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
  8003c3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003ca:	8b 45 10             	mov    0x10(%ebp),%eax
  8003cd:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8003db:	89 04 24             	mov    %eax,(%esp)
  8003de:	e8 02 00 00 00       	call   8003e5 <vprintfmt>
}
  8003e3:	c9                   	leave  
  8003e4:	c3                   	ret    

008003e5 <vprintfmt>:
{
  8003e5:	55                   	push   %ebp
  8003e6:	89 e5                	mov    %esp,%ebp
  8003e8:	57                   	push   %edi
  8003e9:	56                   	push   %esi
  8003ea:	53                   	push   %ebx
  8003eb:	83 ec 4c             	sub    $0x4c,%esp
  8003ee:	8b 75 08             	mov    0x8(%ebp),%esi
  8003f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003f4:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003f7:	eb 11                	jmp    80040a <vprintfmt+0x25>
			if (ch == '\0')
  8003f9:	85 c0                	test   %eax,%eax
  8003fb:	0f 84 cf 03 00 00    	je     8007d0 <vprintfmt+0x3eb>
			putch(ch, putdat);
  800401:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800405:	89 04 24             	mov    %eax,(%esp)
  800408:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80040a:	0f b6 07             	movzbl (%edi),%eax
  80040d:	83 c7 01             	add    $0x1,%edi
  800410:	83 f8 25             	cmp    $0x25,%eax
  800413:	75 e4                	jne    8003f9 <vprintfmt+0x14>
  800415:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800419:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  800420:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800427:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80042e:	ba 00 00 00 00       	mov    $0x0,%edx
  800433:	eb 2b                	jmp    800460 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800435:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
  800438:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  80043c:	eb 22                	jmp    800460 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  80043e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
  800441:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800445:	eb 19                	jmp    800460 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800447:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
  80044a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800451:	eb 0d                	jmp    800460 <vprintfmt+0x7b>
				width = precision, precision = -1;
  800453:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800456:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800459:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800460:	0f b6 07             	movzbl (%edi),%eax
  800463:	8d 4f 01             	lea    0x1(%edi),%ecx
  800466:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800469:	0f b6 0f             	movzbl (%edi),%ecx
  80046c:	83 e9 23             	sub    $0x23,%ecx
  80046f:	80 f9 55             	cmp    $0x55,%cl
  800472:	0f 87 3b 03 00 00    	ja     8007b3 <vprintfmt+0x3ce>
  800478:	0f b6 c9             	movzbl %cl,%ecx
  80047b:	ff 24 8d 60 11 80 00 	jmp    *0x801160(,%ecx,4)
  800482:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800485:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  80048c:	89 55 e0             	mov    %edx,-0x20(%ebp)
  80048f:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
  800494:	8d 14 92             	lea    (%edx,%edx,4),%edx
  800497:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  80049b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  80049e:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004a1:	83 f9 09             	cmp    $0x9,%ecx
  8004a4:	77 2f                	ja     8004d5 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
  8004a6:	83 c7 01             	add    $0x1,%edi
			}
  8004a9:	eb e9                	jmp    800494 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
  8004ab:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ae:	8d 48 04             	lea    0x4(%eax),%ecx
  8004b1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004b4:	8b 00                	mov    (%eax),%eax
  8004b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8004b9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
  8004bc:	eb 1d                	jmp    8004db <vprintfmt+0xf6>
			if (width < 0)
  8004be:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004c2:	78 83                	js     800447 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
  8004c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004c7:	eb 97                	jmp    800460 <vprintfmt+0x7b>
  8004c9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
  8004cc:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8004d3:	eb 8b                	jmp    800460 <vprintfmt+0x7b>
  8004d5:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
  8004db:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004df:	0f 89 7b ff ff ff    	jns    800460 <vprintfmt+0x7b>
  8004e5:	e9 69 ff ff ff       	jmp    800453 <vprintfmt+0x6e>
			lflag++;
  8004ea:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
  8004ed:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
  8004f0:	e9 6b ff ff ff       	jmp    800460 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
  8004f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f8:	8d 50 04             	lea    0x4(%eax),%edx
  8004fb:	89 55 14             	mov    %edx,0x14(%ebp)
  8004fe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800502:	8b 00                	mov    (%eax),%eax
  800504:	89 04 24             	mov    %eax,(%esp)
  800507:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  800509:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  80050c:	e9 f9 fe ff ff       	jmp    80040a <vprintfmt+0x25>
			err = va_arg(ap, int);
  800511:	8b 45 14             	mov    0x14(%ebp),%eax
  800514:	8d 50 04             	lea    0x4(%eax),%edx
  800517:	89 55 14             	mov    %edx,0x14(%ebp)
  80051a:	8b 00                	mov    (%eax),%eax
  80051c:	89 c2                	mov    %eax,%edx
  80051e:	c1 fa 1f             	sar    $0x1f,%edx
  800521:	31 d0                	xor    %edx,%eax
  800523:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800525:	83 f8 07             	cmp    $0x7,%eax
  800528:	7f 0b                	jg     800535 <vprintfmt+0x150>
  80052a:	8b 14 85 c0 12 80 00 	mov    0x8012c0(,%eax,4),%edx
  800531:	85 d2                	test   %edx,%edx
  800533:	75 20                	jne    800555 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
  800535:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800539:	c7 44 24 08 e4 10 80 	movl   $0x8010e4,0x8(%esp)
  800540:	00 
  800541:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800545:	89 34 24             	mov    %esi,(%esp)
  800548:	e8 70 fe ff ff       	call   8003bd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80054d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
  800550:	e9 b5 fe ff ff       	jmp    80040a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
  800555:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800559:	c7 44 24 08 ed 10 80 	movl   $0x8010ed,0x8(%esp)
  800560:	00 
  800561:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800565:	89 34 24             	mov    %esi,(%esp)
  800568:	e8 50 fe ff ff       	call   8003bd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80056d:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800570:	e9 95 fe ff ff       	jmp    80040a <vprintfmt+0x25>
  800575:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800578:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80057b:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
  80057e:	8b 45 14             	mov    0x14(%ebp),%eax
  800581:	8d 50 04             	lea    0x4(%eax),%edx
  800584:	89 55 14             	mov    %edx,0x14(%ebp)
  800587:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800589:	85 ff                	test   %edi,%edi
  80058b:	b8 dd 10 80 00       	mov    $0x8010dd,%eax
  800590:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800593:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800597:	0f 84 9b 00 00 00    	je     800638 <vprintfmt+0x253>
  80059d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8005a1:	0f 8e 9f 00 00 00    	jle    800646 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005a7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005ab:	89 3c 24             	mov    %edi,(%esp)
  8005ae:	e8 c5 02 00 00       	call   800878 <strnlen>
  8005b3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8005b6:	29 c2                	sub    %eax,%edx
  8005b8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
  8005bb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8005bf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8005c2:	89 7d c8             	mov    %edi,-0x38(%ebp)
  8005c5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  8005c7:	eb 0f                	jmp    8005d8 <vprintfmt+0x1f3>
					putch(padc, putdat);
  8005c9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8005d0:	89 04 24             	mov    %eax,(%esp)
  8005d3:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  8005d5:	83 ef 01             	sub    $0x1,%edi
  8005d8:	85 ff                	test   %edi,%edi
  8005da:	7f ed                	jg     8005c9 <vprintfmt+0x1e4>
  8005dc:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8005df:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005e3:	b8 00 00 00 00       	mov    $0x0,%eax
  8005e8:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
  8005ec:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005ef:	29 c2                	sub    %eax,%edx
  8005f1:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8005f4:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8005f7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8005fa:	89 d3                	mov    %edx,%ebx
  8005fc:	eb 54                	jmp    800652 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
  8005fe:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800602:	74 20                	je     800624 <vprintfmt+0x23f>
  800604:	0f be d2             	movsbl %dl,%edx
  800607:	83 ea 20             	sub    $0x20,%edx
  80060a:	83 fa 5e             	cmp    $0x5e,%edx
  80060d:	76 15                	jbe    800624 <vprintfmt+0x23f>
					putch('?', putdat);
  80060f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800612:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800616:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80061d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800620:	ff d0                	call   *%eax
  800622:	eb 0f                	jmp    800633 <vprintfmt+0x24e>
					putch(ch, putdat);
  800624:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800627:	89 54 24 04          	mov    %edx,0x4(%esp)
  80062b:	89 04 24             	mov    %eax,(%esp)
  80062e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800631:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800633:	83 eb 01             	sub    $0x1,%ebx
  800636:	eb 1a                	jmp    800652 <vprintfmt+0x26d>
  800638:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  80063b:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80063e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800641:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800644:	eb 0c                	jmp    800652 <vprintfmt+0x26d>
  800646:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800649:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80064c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80064f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800652:	0f b6 17             	movzbl (%edi),%edx
  800655:	0f be c2             	movsbl %dl,%eax
  800658:	83 c7 01             	add    $0x1,%edi
  80065b:	85 c0                	test   %eax,%eax
  80065d:	74 29                	je     800688 <vprintfmt+0x2a3>
  80065f:	85 f6                	test   %esi,%esi
  800661:	78 9b                	js     8005fe <vprintfmt+0x219>
  800663:	83 ee 01             	sub    $0x1,%esi
  800666:	79 96                	jns    8005fe <vprintfmt+0x219>
  800668:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80066b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80066e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800671:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800674:	eb 1a                	jmp    800690 <vprintfmt+0x2ab>
				putch(' ', putdat);
  800676:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80067a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800681:	ff d6                	call   *%esi
			for (; width > 0; width--)
  800683:	83 ef 01             	sub    $0x1,%edi
  800686:	eb 08                	jmp    800690 <vprintfmt+0x2ab>
  800688:	89 df                	mov    %ebx,%edi
  80068a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80068d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800690:	85 ff                	test   %edi,%edi
  800692:	7f e2                	jg     800676 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
  800694:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800697:	e9 6e fd ff ff       	jmp    80040a <vprintfmt+0x25>
	if (lflag >= 2)
  80069c:	83 fa 01             	cmp    $0x1,%edx
  80069f:	7e 16                	jle    8006b7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
  8006a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a4:	8d 50 08             	lea    0x8(%eax),%edx
  8006a7:	89 55 14             	mov    %edx,0x14(%ebp)
  8006aa:	8b 10                	mov    (%eax),%edx
  8006ac:	8b 48 04             	mov    0x4(%eax),%ecx
  8006af:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8006b2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006b5:	eb 32                	jmp    8006e9 <vprintfmt+0x304>
	else if (lflag)
  8006b7:	85 d2                	test   %edx,%edx
  8006b9:	74 18                	je     8006d3 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
  8006bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006be:	8d 50 04             	lea    0x4(%eax),%edx
  8006c1:	89 55 14             	mov    %edx,0x14(%ebp)
  8006c4:	8b 00                	mov    (%eax),%eax
  8006c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006c9:	89 c1                	mov    %eax,%ecx
  8006cb:	c1 f9 1f             	sar    $0x1f,%ecx
  8006ce:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006d1:	eb 16                	jmp    8006e9 <vprintfmt+0x304>
		return va_arg(*ap, int);
  8006d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d6:	8d 50 04             	lea    0x4(%eax),%edx
  8006d9:	89 55 14             	mov    %edx,0x14(%ebp)
  8006dc:	8b 00                	mov    (%eax),%eax
  8006de:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006e1:	89 c7                	mov    %eax,%edi
  8006e3:	c1 ff 1f             	sar    $0x1f,%edi
  8006e6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
  8006e9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8006ec:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
  8006ef:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
  8006f4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8006f8:	79 7d                	jns    800777 <vprintfmt+0x392>
				putch('-', putdat);
  8006fa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006fe:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800705:	ff d6                	call   *%esi
				num = -(long long) num;
  800707:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80070a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80070d:	f7 d8                	neg    %eax
  80070f:	83 d2 00             	adc    $0x0,%edx
  800712:	f7 da                	neg    %edx
			base = 10;
  800714:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800719:	eb 5c                	jmp    800777 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80071b:	8d 45 14             	lea    0x14(%ebp),%eax
  80071e:	e8 43 fc ff ff       	call   800366 <getuint>
			base = 10;
  800723:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800728:	eb 4d                	jmp    800777 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80072a:	8d 45 14             	lea    0x14(%ebp),%eax
  80072d:	e8 34 fc ff ff       	call   800366 <getuint>
			base = 8;
  800732:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800737:	eb 3e                	jmp    800777 <vprintfmt+0x392>
			putch('0', putdat);
  800739:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80073d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800744:	ff d6                	call   *%esi
			putch('x', putdat);
  800746:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80074a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800751:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
  800753:	8b 45 14             	mov    0x14(%ebp),%eax
  800756:	8d 50 04             	lea    0x4(%eax),%edx
  800759:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
  80075c:	8b 00                	mov    (%eax),%eax
  80075e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
  800763:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800768:	eb 0d                	jmp    800777 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80076a:	8d 45 14             	lea    0x14(%ebp),%eax
  80076d:	e8 f4 fb ff ff       	call   800366 <getuint>
			base = 16;
  800772:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
  800777:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80077b:	89 7c 24 10          	mov    %edi,0x10(%esp)
  80077f:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800782:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800786:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80078a:	89 04 24             	mov    %eax,(%esp)
  80078d:	89 54 24 04          	mov    %edx,0x4(%esp)
  800791:	89 da                	mov    %ebx,%edx
  800793:	89 f0                	mov    %esi,%eax
  800795:	e8 e6 fa ff ff       	call   800280 <printnum>
			break;
  80079a:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80079d:	e9 68 fc ff ff       	jmp    80040a <vprintfmt+0x25>
			putch(ch, putdat);
  8007a2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007a6:	89 04 24             	mov    %eax,(%esp)
  8007a9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  8007ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  8007ae:	e9 57 fc ff ff       	jmp    80040a <vprintfmt+0x25>
			putch('%', putdat);
  8007b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007b7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007be:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007c0:	eb 03                	jmp    8007c5 <vprintfmt+0x3e0>
  8007c2:	83 ef 01             	sub    $0x1,%edi
  8007c5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007c9:	75 f7                	jne    8007c2 <vprintfmt+0x3dd>
  8007cb:	e9 3a fc ff ff       	jmp    80040a <vprintfmt+0x25>
}
  8007d0:	83 c4 4c             	add    $0x4c,%esp
  8007d3:	5b                   	pop    %ebx
  8007d4:	5e                   	pop    %esi
  8007d5:	5f                   	pop    %edi
  8007d6:	5d                   	pop    %ebp
  8007d7:	c3                   	ret    

008007d8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007d8:	55                   	push   %ebp
  8007d9:	89 e5                	mov    %esp,%ebp
  8007db:	83 ec 28             	sub    $0x28,%esp
  8007de:	8b 45 08             	mov    0x8(%ebp),%eax
  8007e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007e7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007eb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007f5:	85 d2                	test   %edx,%edx
  8007f7:	7e 30                	jle    800829 <vsnprintf+0x51>
  8007f9:	85 c0                	test   %eax,%eax
  8007fb:	74 2c                	je     800829 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800800:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800804:	8b 45 10             	mov    0x10(%ebp),%eax
  800807:	89 44 24 08          	mov    %eax,0x8(%esp)
  80080b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80080e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800812:	c7 04 24 a0 03 80 00 	movl   $0x8003a0,(%esp)
  800819:	e8 c7 fb ff ff       	call   8003e5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80081e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800821:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800824:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800827:	eb 05                	jmp    80082e <vsnprintf+0x56>
		return -E_INVAL;
  800829:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  80082e:	c9                   	leave  
  80082f:	c3                   	ret    

00800830 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800830:	55                   	push   %ebp
  800831:	89 e5                	mov    %esp,%ebp
  800833:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800836:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800839:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80083d:	8b 45 10             	mov    0x10(%ebp),%eax
  800840:	89 44 24 08          	mov    %eax,0x8(%esp)
  800844:	8b 45 0c             	mov    0xc(%ebp),%eax
  800847:	89 44 24 04          	mov    %eax,0x4(%esp)
  80084b:	8b 45 08             	mov    0x8(%ebp),%eax
  80084e:	89 04 24             	mov    %eax,(%esp)
  800851:	e8 82 ff ff ff       	call   8007d8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800856:	c9                   	leave  
  800857:	c3                   	ret    
  800858:	66 90                	xchg   %ax,%ax
  80085a:	66 90                	xchg   %ax,%ax
  80085c:	66 90                	xchg   %ax,%ax
  80085e:	66 90                	xchg   %ax,%ax

00800860 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800860:	55                   	push   %ebp
  800861:	89 e5                	mov    %esp,%ebp
  800863:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800866:	b8 00 00 00 00       	mov    $0x0,%eax
  80086b:	eb 03                	jmp    800870 <strlen+0x10>
		n++;
  80086d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  800870:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800874:	75 f7                	jne    80086d <strlen+0xd>
	return n;
}
  800876:	5d                   	pop    %ebp
  800877:	c3                   	ret    

00800878 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800878:	55                   	push   %ebp
  800879:	89 e5                	mov    %esp,%ebp
  80087b:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
  80087e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800881:	b8 00 00 00 00       	mov    $0x0,%eax
  800886:	eb 03                	jmp    80088b <strnlen+0x13>
		n++;
  800888:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80088b:	39 d0                	cmp    %edx,%eax
  80088d:	74 06                	je     800895 <strnlen+0x1d>
  80088f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800893:	75 f3                	jne    800888 <strnlen+0x10>
	return n;
}
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	53                   	push   %ebx
  80089b:	8b 45 08             	mov    0x8(%ebp),%eax
  80089e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008a1:	89 c2                	mov    %eax,%edx
  8008a3:	0f b6 19             	movzbl (%ecx),%ebx
  8008a6:	88 1a                	mov    %bl,(%edx)
  8008a8:	83 c2 01             	add    $0x1,%edx
  8008ab:	83 c1 01             	add    $0x1,%ecx
  8008ae:	84 db                	test   %bl,%bl
  8008b0:	75 f1                	jne    8008a3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008b2:	5b                   	pop    %ebx
  8008b3:	5d                   	pop    %ebp
  8008b4:	c3                   	ret    

008008b5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008b5:	55                   	push   %ebp
  8008b6:	89 e5                	mov    %esp,%ebp
  8008b8:	53                   	push   %ebx
  8008b9:	83 ec 08             	sub    $0x8,%esp
  8008bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008bf:	89 1c 24             	mov    %ebx,(%esp)
  8008c2:	e8 99 ff ff ff       	call   800860 <strlen>
	strcpy(dst + len, src);
  8008c7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008ce:	01 d8                	add    %ebx,%eax
  8008d0:	89 04 24             	mov    %eax,(%esp)
  8008d3:	e8 bf ff ff ff       	call   800897 <strcpy>
	return dst;
}
  8008d8:	89 d8                	mov    %ebx,%eax
  8008da:	83 c4 08             	add    $0x8,%esp
  8008dd:	5b                   	pop    %ebx
  8008de:	5d                   	pop    %ebp
  8008df:	c3                   	ret    

008008e0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008e0:	55                   	push   %ebp
  8008e1:	89 e5                	mov    %esp,%ebp
  8008e3:	56                   	push   %esi
  8008e4:	53                   	push   %ebx
  8008e5:	8b 75 08             	mov    0x8(%ebp),%esi
  8008e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008eb:	89 f3                	mov    %esi,%ebx
  8008ed:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f0:	89 f2                	mov    %esi,%edx
  8008f2:	eb 0e                	jmp    800902 <strncpy+0x22>
		*dst++ = *src;
  8008f4:	0f b6 01             	movzbl (%ecx),%eax
  8008f7:	88 02                	mov    %al,(%edx)
  8008f9:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008fc:	80 39 01             	cmpb   $0x1,(%ecx)
  8008ff:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800902:	39 da                	cmp    %ebx,%edx
  800904:	75 ee                	jne    8008f4 <strncpy+0x14>
	}
	return ret;
}
  800906:	89 f0                	mov    %esi,%eax
  800908:	5b                   	pop    %ebx
  800909:	5e                   	pop    %esi
  80090a:	5d                   	pop    %ebp
  80090b:	c3                   	ret    

0080090c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80090c:	55                   	push   %ebp
  80090d:	89 e5                	mov    %esp,%ebp
  80090f:	56                   	push   %esi
  800910:	53                   	push   %ebx
  800911:	8b 75 08             	mov    0x8(%ebp),%esi
  800914:	8b 55 0c             	mov    0xc(%ebp),%edx
  800917:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80091a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
  80091c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
  800920:	85 c9                	test   %ecx,%ecx
  800922:	75 0a                	jne    80092e <strlcpy+0x22>
  800924:	eb 1c                	jmp    800942 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800926:	88 08                	mov    %cl,(%eax)
  800928:	83 c0 01             	add    $0x1,%eax
  80092b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
  80092e:	39 d8                	cmp    %ebx,%eax
  800930:	74 0b                	je     80093d <strlcpy+0x31>
  800932:	0f b6 0a             	movzbl (%edx),%ecx
  800935:	84 c9                	test   %cl,%cl
  800937:	75 ed                	jne    800926 <strlcpy+0x1a>
  800939:	89 c2                	mov    %eax,%edx
  80093b:	eb 02                	jmp    80093f <strlcpy+0x33>
  80093d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
  80093f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800942:	29 f0                	sub    %esi,%eax
}
  800944:	5b                   	pop    %ebx
  800945:	5e                   	pop    %esi
  800946:	5d                   	pop    %ebp
  800947:	c3                   	ret    

00800948 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800948:	55                   	push   %ebp
  800949:	89 e5                	mov    %esp,%ebp
  80094b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80094e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800951:	eb 06                	jmp    800959 <strcmp+0x11>
		p++, q++;
  800953:	83 c1 01             	add    $0x1,%ecx
  800956:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800959:	0f b6 01             	movzbl (%ecx),%eax
  80095c:	84 c0                	test   %al,%al
  80095e:	74 04                	je     800964 <strcmp+0x1c>
  800960:	3a 02                	cmp    (%edx),%al
  800962:	74 ef                	je     800953 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800964:	0f b6 c0             	movzbl %al,%eax
  800967:	0f b6 12             	movzbl (%edx),%edx
  80096a:	29 d0                	sub    %edx,%eax
}
  80096c:	5d                   	pop    %ebp
  80096d:	c3                   	ret    

0080096e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80096e:	55                   	push   %ebp
  80096f:	89 e5                	mov    %esp,%ebp
  800971:	53                   	push   %ebx
  800972:	8b 45 08             	mov    0x8(%ebp),%eax
  800975:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
  800978:	89 c3                	mov    %eax,%ebx
  80097a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80097d:	eb 06                	jmp    800985 <strncmp+0x17>
		n--, p++, q++;
  80097f:	83 c0 01             	add    $0x1,%eax
  800982:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  800985:	39 d8                	cmp    %ebx,%eax
  800987:	74 15                	je     80099e <strncmp+0x30>
  800989:	0f b6 08             	movzbl (%eax),%ecx
  80098c:	84 c9                	test   %cl,%cl
  80098e:	74 04                	je     800994 <strncmp+0x26>
  800990:	3a 0a                	cmp    (%edx),%cl
  800992:	74 eb                	je     80097f <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800994:	0f b6 00             	movzbl (%eax),%eax
  800997:	0f b6 12             	movzbl (%edx),%edx
  80099a:	29 d0                	sub    %edx,%eax
  80099c:	eb 05                	jmp    8009a3 <strncmp+0x35>
		return 0;
  80099e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009a3:	5b                   	pop    %ebx
  8009a4:	5d                   	pop    %ebp
  8009a5:	c3                   	ret    

008009a6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009a6:	55                   	push   %ebp
  8009a7:	89 e5                	mov    %esp,%ebp
  8009a9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ac:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009b0:	eb 07                	jmp    8009b9 <strchr+0x13>
		if (*s == c)
  8009b2:	38 ca                	cmp    %cl,%dl
  8009b4:	74 0f                	je     8009c5 <strchr+0x1f>
	for (; *s; s++)
  8009b6:	83 c0 01             	add    $0x1,%eax
  8009b9:	0f b6 10             	movzbl (%eax),%edx
  8009bc:	84 d2                	test   %dl,%dl
  8009be:	75 f2                	jne    8009b2 <strchr+0xc>
			return (char *) s;
	return 0;
  8009c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c5:	5d                   	pop    %ebp
  8009c6:	c3                   	ret    

008009c7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009c7:	55                   	push   %ebp
  8009c8:	89 e5                	mov    %esp,%ebp
  8009ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009d1:	eb 07                	jmp    8009da <strfind+0x13>
		if (*s == c)
  8009d3:	38 ca                	cmp    %cl,%dl
  8009d5:	74 0a                	je     8009e1 <strfind+0x1a>
	for (; *s; s++)
  8009d7:	83 c0 01             	add    $0x1,%eax
  8009da:	0f b6 10             	movzbl (%eax),%edx
  8009dd:	84 d2                	test   %dl,%dl
  8009df:	75 f2                	jne    8009d3 <strfind+0xc>
			break;
	return (char *) s;
}
  8009e1:	5d                   	pop    %ebp
  8009e2:	c3                   	ret    

008009e3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009e3:	55                   	push   %ebp
  8009e4:	89 e5                	mov    %esp,%ebp
  8009e6:	83 ec 0c             	sub    $0xc,%esp
  8009e9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8009ec:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009ef:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009f2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009f5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009f8:	85 c9                	test   %ecx,%ecx
  8009fa:	74 36                	je     800a32 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009fc:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a02:	75 28                	jne    800a2c <memset+0x49>
  800a04:	f6 c1 03             	test   $0x3,%cl
  800a07:	75 23                	jne    800a2c <memset+0x49>
		c &= 0xFF;
  800a09:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a0d:	89 d3                	mov    %edx,%ebx
  800a0f:	c1 e3 08             	shl    $0x8,%ebx
  800a12:	89 d6                	mov    %edx,%esi
  800a14:	c1 e6 18             	shl    $0x18,%esi
  800a17:	89 d0                	mov    %edx,%eax
  800a19:	c1 e0 10             	shl    $0x10,%eax
  800a1c:	09 f0                	or     %esi,%eax
  800a1e:	09 c2                	or     %eax,%edx
  800a20:	89 d0                	mov    %edx,%eax
  800a22:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a24:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800a27:	fc                   	cld    
  800a28:	f3 ab                	rep stos %eax,%es:(%edi)
  800a2a:	eb 06                	jmp    800a32 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a2c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a2f:	fc                   	cld    
  800a30:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a32:	89 f8                	mov    %edi,%eax
  800a34:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a37:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a3a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a3d:	89 ec                	mov    %ebp,%esp
  800a3f:	5d                   	pop    %ebp
  800a40:	c3                   	ret    

00800a41 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a41:	55                   	push   %ebp
  800a42:	89 e5                	mov    %esp,%ebp
  800a44:	83 ec 08             	sub    $0x8,%esp
  800a47:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a4a:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a4d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a50:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a53:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a56:	39 c6                	cmp    %eax,%esi
  800a58:	73 36                	jae    800a90 <memmove+0x4f>
  800a5a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a5d:	39 d0                	cmp    %edx,%eax
  800a5f:	73 2f                	jae    800a90 <memmove+0x4f>
		s += n;
		d += n;
  800a61:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a64:	f6 c2 03             	test   $0x3,%dl
  800a67:	75 1b                	jne    800a84 <memmove+0x43>
  800a69:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a6f:	75 13                	jne    800a84 <memmove+0x43>
  800a71:	f6 c1 03             	test   $0x3,%cl
  800a74:	75 0e                	jne    800a84 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a76:	83 ef 04             	sub    $0x4,%edi
  800a79:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a7c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  800a7f:	fd                   	std    
  800a80:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a82:	eb 09                	jmp    800a8d <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a84:	83 ef 01             	sub    $0x1,%edi
  800a87:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  800a8a:	fd                   	std    
  800a8b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a8d:	fc                   	cld    
  800a8e:	eb 20                	jmp    800ab0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a90:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a96:	75 13                	jne    800aab <memmove+0x6a>
  800a98:	a8 03                	test   $0x3,%al
  800a9a:	75 0f                	jne    800aab <memmove+0x6a>
  800a9c:	f6 c1 03             	test   $0x3,%cl
  800a9f:	75 0a                	jne    800aab <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800aa1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  800aa4:	89 c7                	mov    %eax,%edi
  800aa6:	fc                   	cld    
  800aa7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aa9:	eb 05                	jmp    800ab0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
  800aab:	89 c7                	mov    %eax,%edi
  800aad:	fc                   	cld    
  800aae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ab0:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ab3:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ab6:	89 ec                	mov    %ebp,%esp
  800ab8:	5d                   	pop    %ebp
  800ab9:	c3                   	ret    

00800aba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800aba:	55                   	push   %ebp
  800abb:	89 e5                	mov    %esp,%ebp
  800abd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ac0:	8b 45 10             	mov    0x10(%ebp),%eax
  800ac3:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ac7:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aca:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ace:	8b 45 08             	mov    0x8(%ebp),%eax
  800ad1:	89 04 24             	mov    %eax,(%esp)
  800ad4:	e8 68 ff ff ff       	call   800a41 <memmove>
}
  800ad9:	c9                   	leave  
  800ada:	c3                   	ret    

00800adb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800adb:	55                   	push   %ebp
  800adc:	89 e5                	mov    %esp,%ebp
  800ade:	56                   	push   %esi
  800adf:	53                   	push   %ebx
  800ae0:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
  800ae6:	89 d6                	mov    %edx,%esi
  800ae8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aeb:	eb 1a                	jmp    800b07 <memcmp+0x2c>
		if (*s1 != *s2)
  800aed:	0f b6 02             	movzbl (%edx),%eax
  800af0:	0f b6 19             	movzbl (%ecx),%ebx
  800af3:	38 d8                	cmp    %bl,%al
  800af5:	74 0a                	je     800b01 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800af7:	0f b6 c0             	movzbl %al,%eax
  800afa:	0f b6 db             	movzbl %bl,%ebx
  800afd:	29 d8                	sub    %ebx,%eax
  800aff:	eb 0f                	jmp    800b10 <memcmp+0x35>
		s1++, s2++;
  800b01:	83 c2 01             	add    $0x1,%edx
  800b04:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
  800b07:	39 f2                	cmp    %esi,%edx
  800b09:	75 e2                	jne    800aed <memcmp+0x12>
	}

	return 0;
  800b0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b10:	5b                   	pop    %ebx
  800b11:	5e                   	pop    %esi
  800b12:	5d                   	pop    %ebp
  800b13:	c3                   	ret    

00800b14 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b14:	55                   	push   %ebp
  800b15:	89 e5                	mov    %esp,%ebp
  800b17:	8b 45 08             	mov    0x8(%ebp),%eax
  800b1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b1d:	89 c2                	mov    %eax,%edx
  800b1f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b22:	eb 07                	jmp    800b2b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b24:	38 08                	cmp    %cl,(%eax)
  800b26:	74 07                	je     800b2f <memfind+0x1b>
	for (; s < ends; s++)
  800b28:	83 c0 01             	add    $0x1,%eax
  800b2b:	39 d0                	cmp    %edx,%eax
  800b2d:	72 f5                	jb     800b24 <memfind+0x10>
			break;
	return (void *) s;
}
  800b2f:	5d                   	pop    %ebp
  800b30:	c3                   	ret    

00800b31 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b31:	55                   	push   %ebp
  800b32:	89 e5                	mov    %esp,%ebp
  800b34:	57                   	push   %edi
  800b35:	56                   	push   %esi
  800b36:	53                   	push   %ebx
  800b37:	83 ec 04             	sub    $0x4,%esp
  800b3a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b3d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b40:	eb 03                	jmp    800b45 <strtol+0x14>
		s++;
  800b42:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
  800b45:	0f b6 02             	movzbl (%edx),%eax
  800b48:	3c 09                	cmp    $0x9,%al
  800b4a:	74 f6                	je     800b42 <strtol+0x11>
  800b4c:	3c 20                	cmp    $0x20,%al
  800b4e:	74 f2                	je     800b42 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
  800b50:	3c 2b                	cmp    $0x2b,%al
  800b52:	75 0a                	jne    800b5e <strtol+0x2d>
		s++;
  800b54:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
  800b57:	bf 00 00 00 00       	mov    $0x0,%edi
  800b5c:	eb 10                	jmp    800b6e <strtol+0x3d>
  800b5e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
  800b63:	3c 2d                	cmp    $0x2d,%al
  800b65:	75 07                	jne    800b6e <strtol+0x3d>
		s++, neg = 1;
  800b67:	8d 52 01             	lea    0x1(%edx),%edx
  800b6a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b6e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b74:	75 15                	jne    800b8b <strtol+0x5a>
  800b76:	80 3a 30             	cmpb   $0x30,(%edx)
  800b79:	75 10                	jne    800b8b <strtol+0x5a>
  800b7b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b7f:	75 0a                	jne    800b8b <strtol+0x5a>
		s += 2, base = 16;
  800b81:	83 c2 02             	add    $0x2,%edx
  800b84:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b89:	eb 10                	jmp    800b9b <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b8b:	85 db                	test   %ebx,%ebx
  800b8d:	75 0c                	jne    800b9b <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b8f:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
  800b91:	80 3a 30             	cmpb   $0x30,(%edx)
  800b94:	75 05                	jne    800b9b <strtol+0x6a>
		s++, base = 8;
  800b96:	83 c2 01             	add    $0x1,%edx
  800b99:	b3 08                	mov    $0x8,%bl
		base = 10;
  800b9b:	b8 00 00 00 00       	mov    $0x0,%eax
  800ba0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ba3:	0f b6 0a             	movzbl (%edx),%ecx
  800ba6:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800ba9:	89 f3                	mov    %esi,%ebx
  800bab:	80 fb 09             	cmp    $0x9,%bl
  800bae:	77 08                	ja     800bb8 <strtol+0x87>
			dig = *s - '0';
  800bb0:	0f be c9             	movsbl %cl,%ecx
  800bb3:	83 e9 30             	sub    $0x30,%ecx
  800bb6:	eb 22                	jmp    800bda <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
  800bb8:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bbb:	89 f3                	mov    %esi,%ebx
  800bbd:	80 fb 19             	cmp    $0x19,%bl
  800bc0:	77 08                	ja     800bca <strtol+0x99>
			dig = *s - 'a' + 10;
  800bc2:	0f be c9             	movsbl %cl,%ecx
  800bc5:	83 e9 57             	sub    $0x57,%ecx
  800bc8:	eb 10                	jmp    800bda <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
  800bca:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bcd:	89 f3                	mov    %esi,%ebx
  800bcf:	80 fb 19             	cmp    $0x19,%bl
  800bd2:	77 16                	ja     800bea <strtol+0xb9>
			dig = *s - 'A' + 10;
  800bd4:	0f be c9             	movsbl %cl,%ecx
  800bd7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bda:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800bdd:	7d 0f                	jge    800bee <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bdf:	83 c2 01             	add    $0x1,%edx
  800be2:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800be6:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800be8:	eb b9                	jmp    800ba3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
  800bea:	89 c1                	mov    %eax,%ecx
  800bec:	eb 02                	jmp    800bf0 <strtol+0xbf>
		if (dig >= base)
  800bee:	89 c1                	mov    %eax,%ecx

	if (endptr)
  800bf0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bf4:	74 05                	je     800bfb <strtol+0xca>
		*endptr = (char *) s;
  800bf6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bf9:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800bfb:	89 ca                	mov    %ecx,%edx
  800bfd:	f7 da                	neg    %edx
  800bff:	85 ff                	test   %edi,%edi
  800c01:	0f 45 c2             	cmovne %edx,%eax
}
  800c04:	83 c4 04             	add    $0x4,%esp
  800c07:	5b                   	pop    %ebx
  800c08:	5e                   	pop    %esi
  800c09:	5f                   	pop    %edi
  800c0a:	5d                   	pop    %ebp
  800c0b:	c3                   	ret    

00800c0c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c0c:	55                   	push   %ebp
  800c0d:	89 e5                	mov    %esp,%ebp
  800c0f:	83 ec 0c             	sub    $0xc,%esp
  800c12:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c15:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c18:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800c1b:	b8 00 00 00 00       	mov    $0x0,%eax
  800c20:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c23:	8b 55 08             	mov    0x8(%ebp),%edx
  800c26:	89 c3                	mov    %eax,%ebx
  800c28:	89 c7                	mov    %eax,%edi
  800c2a:	89 c6                	mov    %eax,%esi
  800c2c:	cd 30                	int    $0x30
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c2e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c31:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c34:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c37:	89 ec                	mov    %ebp,%esp
  800c39:	5d                   	pop    %ebp
  800c3a:	c3                   	ret    

00800c3b <sys_cgetc>:

int
sys_cgetc(void)
{
  800c3b:	55                   	push   %ebp
  800c3c:	89 e5                	mov    %esp,%ebp
  800c3e:	83 ec 0c             	sub    $0xc,%esp
  800c41:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c44:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c47:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800c4a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c4f:	b8 01 00 00 00       	mov    $0x1,%eax
  800c54:	89 d1                	mov    %edx,%ecx
  800c56:	89 d3                	mov    %edx,%ebx
  800c58:	89 d7                	mov    %edx,%edi
  800c5a:	89 d6                	mov    %edx,%esi
  800c5c:	cd 30                	int    $0x30
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c5e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c61:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c64:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c67:	89 ec                	mov    %ebp,%esp
  800c69:	5d                   	pop    %ebp
  800c6a:	c3                   	ret    

00800c6b <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c6b:	55                   	push   %ebp
  800c6c:	89 e5                	mov    %esp,%ebp
  800c6e:	83 ec 38             	sub    $0x38,%esp
  800c71:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c74:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c77:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800c7a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c7f:	b8 03 00 00 00       	mov    $0x3,%eax
  800c84:	8b 55 08             	mov    0x8(%ebp),%edx
  800c87:	89 cb                	mov    %ecx,%ebx
  800c89:	89 cf                	mov    %ecx,%edi
  800c8b:	89 ce                	mov    %ecx,%esi
  800c8d:	cd 30                	int    $0x30
	if(check && ret > 0)
  800c8f:	85 c0                	test   %eax,%eax
  800c91:	7e 28                	jle    800cbb <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c93:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c97:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c9e:	00 
  800c9f:	c7 44 24 08 e0 12 80 	movl   $0x8012e0,0x8(%esp)
  800ca6:	00 
  800ca7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cae:	00 
  800caf:	c7 04 24 fd 12 80 00 	movl   $0x8012fd,(%esp)
  800cb6:	e8 a9 f4 ff ff       	call   800164 <_panic>
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800cbb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cbe:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cc1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cc4:	89 ec                	mov    %ebp,%esp
  800cc6:	5d                   	pop    %ebp
  800cc7:	c3                   	ret    

00800cc8 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800cc8:	55                   	push   %ebp
  800cc9:	89 e5                	mov    %esp,%ebp
  800ccb:	83 ec 0c             	sub    $0xc,%esp
  800cce:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800cd1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800cd4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800cd7:	ba 00 00 00 00       	mov    $0x0,%edx
  800cdc:	b8 02 00 00 00       	mov    $0x2,%eax
  800ce1:	89 d1                	mov    %edx,%ecx
  800ce3:	89 d3                	mov    %edx,%ebx
  800ce5:	89 d7                	mov    %edx,%edi
  800ce7:	89 d6                	mov    %edx,%esi
  800ce9:	cd 30                	int    $0x30
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800ceb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800cee:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800cf1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800cf4:	89 ec                	mov    %ebp,%esp
  800cf6:	5d                   	pop    %ebp
  800cf7:	c3                   	ret    
  800cf8:	66 90                	xchg   %ax,%ax
  800cfa:	66 90                	xchg   %ax,%ax
  800cfc:	66 90                	xchg   %ax,%ax
  800cfe:	66 90                	xchg   %ax,%ax

00800d00 <__udivdi3>:
  800d00:	83 ec 1c             	sub    $0x1c,%esp
  800d03:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800d07:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d0b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d0f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d13:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800d17:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800d1b:	85 c0                	test   %eax,%eax
  800d1d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d21:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d25:	89 ea                	mov    %ebp,%edx
  800d27:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d2b:	75 33                	jne    800d60 <__udivdi3+0x60>
  800d2d:	39 e9                	cmp    %ebp,%ecx
  800d2f:	77 6f                	ja     800da0 <__udivdi3+0xa0>
  800d31:	85 c9                	test   %ecx,%ecx
  800d33:	89 ce                	mov    %ecx,%esi
  800d35:	75 0b                	jne    800d42 <__udivdi3+0x42>
  800d37:	b8 01 00 00 00       	mov    $0x1,%eax
  800d3c:	31 d2                	xor    %edx,%edx
  800d3e:	f7 f1                	div    %ecx
  800d40:	89 c6                	mov    %eax,%esi
  800d42:	31 d2                	xor    %edx,%edx
  800d44:	89 e8                	mov    %ebp,%eax
  800d46:	f7 f6                	div    %esi
  800d48:	89 c5                	mov    %eax,%ebp
  800d4a:	89 f8                	mov    %edi,%eax
  800d4c:	f7 f6                	div    %esi
  800d4e:	89 ea                	mov    %ebp,%edx
  800d50:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d54:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d58:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d5c:	83 c4 1c             	add    $0x1c,%esp
  800d5f:	c3                   	ret    
  800d60:	39 e8                	cmp    %ebp,%eax
  800d62:	77 24                	ja     800d88 <__udivdi3+0x88>
  800d64:	0f bd c8             	bsr    %eax,%ecx
  800d67:	83 f1 1f             	xor    $0x1f,%ecx
  800d6a:	89 0c 24             	mov    %ecx,(%esp)
  800d6d:	75 49                	jne    800db8 <__udivdi3+0xb8>
  800d6f:	8b 74 24 08          	mov    0x8(%esp),%esi
  800d73:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800d77:	0f 86 ab 00 00 00    	jbe    800e28 <__udivdi3+0x128>
  800d7d:	39 e8                	cmp    %ebp,%eax
  800d7f:	0f 82 a3 00 00 00    	jb     800e28 <__udivdi3+0x128>
  800d85:	8d 76 00             	lea    0x0(%esi),%esi
  800d88:	31 d2                	xor    %edx,%edx
  800d8a:	31 c0                	xor    %eax,%eax
  800d8c:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d90:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d94:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d98:	83 c4 1c             	add    $0x1c,%esp
  800d9b:	c3                   	ret    
  800d9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800da0:	89 f8                	mov    %edi,%eax
  800da2:	f7 f1                	div    %ecx
  800da4:	31 d2                	xor    %edx,%edx
  800da6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800daa:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dae:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800db2:	83 c4 1c             	add    $0x1c,%esp
  800db5:	c3                   	ret    
  800db6:	66 90                	xchg   %ax,%ax
  800db8:	0f b6 0c 24          	movzbl (%esp),%ecx
  800dbc:	89 c6                	mov    %eax,%esi
  800dbe:	b8 20 00 00 00       	mov    $0x20,%eax
  800dc3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800dc7:	2b 04 24             	sub    (%esp),%eax
  800dca:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800dce:	d3 e6                	shl    %cl,%esi
  800dd0:	89 c1                	mov    %eax,%ecx
  800dd2:	d3 ed                	shr    %cl,%ebp
  800dd4:	0f b6 0c 24          	movzbl (%esp),%ecx
  800dd8:	09 f5                	or     %esi,%ebp
  800dda:	8b 74 24 04          	mov    0x4(%esp),%esi
  800dde:	d3 e6                	shl    %cl,%esi
  800de0:	89 c1                	mov    %eax,%ecx
  800de2:	89 74 24 04          	mov    %esi,0x4(%esp)
  800de6:	89 d6                	mov    %edx,%esi
  800de8:	d3 ee                	shr    %cl,%esi
  800dea:	0f b6 0c 24          	movzbl (%esp),%ecx
  800dee:	d3 e2                	shl    %cl,%edx
  800df0:	89 c1                	mov    %eax,%ecx
  800df2:	d3 ef                	shr    %cl,%edi
  800df4:	09 d7                	or     %edx,%edi
  800df6:	89 f2                	mov    %esi,%edx
  800df8:	89 f8                	mov    %edi,%eax
  800dfa:	f7 f5                	div    %ebp
  800dfc:	89 d6                	mov    %edx,%esi
  800dfe:	89 c7                	mov    %eax,%edi
  800e00:	f7 64 24 04          	mull   0x4(%esp)
  800e04:	39 d6                	cmp    %edx,%esi
  800e06:	72 30                	jb     800e38 <__udivdi3+0x138>
  800e08:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800e0c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800e10:	d3 e5                	shl    %cl,%ebp
  800e12:	39 c5                	cmp    %eax,%ebp
  800e14:	73 04                	jae    800e1a <__udivdi3+0x11a>
  800e16:	39 d6                	cmp    %edx,%esi
  800e18:	74 1e                	je     800e38 <__udivdi3+0x138>
  800e1a:	89 f8                	mov    %edi,%eax
  800e1c:	31 d2                	xor    %edx,%edx
  800e1e:	e9 69 ff ff ff       	jmp    800d8c <__udivdi3+0x8c>
  800e23:	90                   	nop
  800e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e28:	31 d2                	xor    %edx,%edx
  800e2a:	b8 01 00 00 00       	mov    $0x1,%eax
  800e2f:	e9 58 ff ff ff       	jmp    800d8c <__udivdi3+0x8c>
  800e34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e38:	8d 47 ff             	lea    -0x1(%edi),%eax
  800e3b:	31 d2                	xor    %edx,%edx
  800e3d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e41:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e45:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e49:	83 c4 1c             	add    $0x1c,%esp
  800e4c:	c3                   	ret    
  800e4d:	66 90                	xchg   %ax,%ax
  800e4f:	90                   	nop

00800e50 <__umoddi3>:
  800e50:	83 ec 2c             	sub    $0x2c,%esp
  800e53:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800e57:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e5b:	89 74 24 20          	mov    %esi,0x20(%esp)
  800e5f:	8b 74 24 38          	mov    0x38(%esp),%esi
  800e63:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800e67:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800e6b:	85 c0                	test   %eax,%eax
  800e6d:	89 c2                	mov    %eax,%edx
  800e6f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800e73:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800e77:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e7b:	89 74 24 10          	mov    %esi,0x10(%esp)
  800e7f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800e83:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800e87:	75 1f                	jne    800ea8 <__umoddi3+0x58>
  800e89:	39 fe                	cmp    %edi,%esi
  800e8b:	76 63                	jbe    800ef0 <__umoddi3+0xa0>
  800e8d:	89 c8                	mov    %ecx,%eax
  800e8f:	89 fa                	mov    %edi,%edx
  800e91:	f7 f6                	div    %esi
  800e93:	89 d0                	mov    %edx,%eax
  800e95:	31 d2                	xor    %edx,%edx
  800e97:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e9b:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e9f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ea3:	83 c4 2c             	add    $0x2c,%esp
  800ea6:	c3                   	ret    
  800ea7:	90                   	nop
  800ea8:	39 f8                	cmp    %edi,%eax
  800eaa:	77 64                	ja     800f10 <__umoddi3+0xc0>
  800eac:	0f bd e8             	bsr    %eax,%ebp
  800eaf:	83 f5 1f             	xor    $0x1f,%ebp
  800eb2:	75 74                	jne    800f28 <__umoddi3+0xd8>
  800eb4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800eb8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800ebc:	0f 87 0e 01 00 00    	ja     800fd0 <__umoddi3+0x180>
  800ec2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800ec6:	29 f1                	sub    %esi,%ecx
  800ec8:	19 c7                	sbb    %eax,%edi
  800eca:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800ece:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ed2:	8b 44 24 14          	mov    0x14(%esp),%eax
  800ed6:	8b 54 24 18          	mov    0x18(%esp),%edx
  800eda:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ede:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ee2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800ee6:	83 c4 2c             	add    $0x2c,%esp
  800ee9:	c3                   	ret    
  800eea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ef0:	85 f6                	test   %esi,%esi
  800ef2:	89 f5                	mov    %esi,%ebp
  800ef4:	75 0b                	jne    800f01 <__umoddi3+0xb1>
  800ef6:	b8 01 00 00 00       	mov    $0x1,%eax
  800efb:	31 d2                	xor    %edx,%edx
  800efd:	f7 f6                	div    %esi
  800eff:	89 c5                	mov    %eax,%ebp
  800f01:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f05:	31 d2                	xor    %edx,%edx
  800f07:	f7 f5                	div    %ebp
  800f09:	89 c8                	mov    %ecx,%eax
  800f0b:	f7 f5                	div    %ebp
  800f0d:	eb 84                	jmp    800e93 <__umoddi3+0x43>
  800f0f:	90                   	nop
  800f10:	89 c8                	mov    %ecx,%eax
  800f12:	89 fa                	mov    %edi,%edx
  800f14:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f18:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f1c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f20:	83 c4 2c             	add    $0x2c,%esp
  800f23:	c3                   	ret    
  800f24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f28:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f2c:	be 20 00 00 00       	mov    $0x20,%esi
  800f31:	89 e9                	mov    %ebp,%ecx
  800f33:	29 ee                	sub    %ebp,%esi
  800f35:	d3 e2                	shl    %cl,%edx
  800f37:	89 f1                	mov    %esi,%ecx
  800f39:	d3 e8                	shr    %cl,%eax
  800f3b:	89 e9                	mov    %ebp,%ecx
  800f3d:	09 d0                	or     %edx,%eax
  800f3f:	89 fa                	mov    %edi,%edx
  800f41:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f45:	8b 44 24 10          	mov    0x10(%esp),%eax
  800f49:	d3 e0                	shl    %cl,%eax
  800f4b:	89 f1                	mov    %esi,%ecx
  800f4d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f51:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800f55:	d3 ea                	shr    %cl,%edx
  800f57:	89 e9                	mov    %ebp,%ecx
  800f59:	d3 e7                	shl    %cl,%edi
  800f5b:	89 f1                	mov    %esi,%ecx
  800f5d:	d3 e8                	shr    %cl,%eax
  800f5f:	89 e9                	mov    %ebp,%ecx
  800f61:	09 f8                	or     %edi,%eax
  800f63:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800f67:	f7 74 24 0c          	divl   0xc(%esp)
  800f6b:	d3 e7                	shl    %cl,%edi
  800f6d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800f71:	89 d7                	mov    %edx,%edi
  800f73:	f7 64 24 10          	mull   0x10(%esp)
  800f77:	39 d7                	cmp    %edx,%edi
  800f79:	89 c1                	mov    %eax,%ecx
  800f7b:	89 54 24 14          	mov    %edx,0x14(%esp)
  800f7f:	72 3b                	jb     800fbc <__umoddi3+0x16c>
  800f81:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800f85:	72 31                	jb     800fb8 <__umoddi3+0x168>
  800f87:	8b 44 24 18          	mov    0x18(%esp),%eax
  800f8b:	29 c8                	sub    %ecx,%eax
  800f8d:	19 d7                	sbb    %edx,%edi
  800f8f:	89 e9                	mov    %ebp,%ecx
  800f91:	89 fa                	mov    %edi,%edx
  800f93:	d3 e8                	shr    %cl,%eax
  800f95:	89 f1                	mov    %esi,%ecx
  800f97:	d3 e2                	shl    %cl,%edx
  800f99:	89 e9                	mov    %ebp,%ecx
  800f9b:	09 d0                	or     %edx,%eax
  800f9d:	89 fa                	mov    %edi,%edx
  800f9f:	d3 ea                	shr    %cl,%edx
  800fa1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800fa5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800fa9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800fad:	83 c4 2c             	add    $0x2c,%esp
  800fb0:	c3                   	ret    
  800fb1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800fb8:	39 d7                	cmp    %edx,%edi
  800fba:	75 cb                	jne    800f87 <__umoddi3+0x137>
  800fbc:	8b 54 24 14          	mov    0x14(%esp),%edx
  800fc0:	89 c1                	mov    %eax,%ecx
  800fc2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800fc6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800fca:	eb bb                	jmp    800f87 <__umoddi3+0x137>
  800fcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fd0:	3b 44 24 18          	cmp    0x18(%esp),%eax
  800fd4:	0f 82 e8 fe ff ff    	jb     800ec2 <__umoddi3+0x72>
  800fda:	e9 f3 fe ff ff       	jmp    800ed2 <__umoddi3+0x82>
