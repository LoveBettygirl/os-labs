
obj/user/faultread：     文件格式 elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	a1 00 00 00 00       	mov    0x0,%eax
  80003e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800042:	c7 04 24 40 0f 80 00 	movl   $0x800f40,(%esp)
  800049:	e8 0b 01 00 00       	call   800159 <cprintf>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	83 ec 18             	sub    $0x18,%esp
  800056:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800059:	89 75 fc             	mov    %esi,-0x4(%ebp)
  80005c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	thisenv = &envs[ENVX(sys_getenvid())];
  800062:	e8 61 0b 00 00       	call   800bc8 <sys_getenvid>
  800067:	25 ff 03 00 00       	and    $0x3ff,%eax
  80006c:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80006f:	c1 e0 05             	shl    $0x5,%eax
  800072:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800077:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80007c:	85 db                	test   %ebx,%ebx
  80007e:	7e 07                	jle    800087 <libmain+0x37>
		binaryname = argv[0];
  800080:	8b 06                	mov    (%esi),%eax
  800082:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800087:	89 74 24 04          	mov    %esi,0x4(%esp)
  80008b:	89 1c 24             	mov    %ebx,(%esp)
  80008e:	e8 a0 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800093:	e8 0a 00 00 00       	call   8000a2 <exit>
}
  800098:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  80009b:	8b 75 fc             	mov    -0x4(%ebp),%esi
  80009e:	89 ec                	mov    %ebp,%esp
  8000a0:	5d                   	pop    %ebp
  8000a1:	c3                   	ret    

008000a2 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a2:	55                   	push   %ebp
  8000a3:	89 e5                	mov    %esp,%ebp
  8000a5:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000af:	e8 b7 0a 00 00       	call   800b6b <sys_env_destroy>
}
  8000b4:	c9                   	leave  
  8000b5:	c3                   	ret    

008000b6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b6:	55                   	push   %ebp
  8000b7:	89 e5                	mov    %esp,%ebp
  8000b9:	53                   	push   %ebx
  8000ba:	83 ec 14             	sub    $0x14,%esp
  8000bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c0:	8b 03                	mov    (%ebx),%eax
  8000c2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000c5:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000c9:	83 c0 01             	add    $0x1,%eax
  8000cc:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000ce:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d3:	75 19                	jne    8000ee <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000d5:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000dc:	00 
  8000dd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e0:	89 04 24             	mov    %eax,(%esp)
  8000e3:	e8 24 0a 00 00       	call   800b0c <sys_cputs>
		b->idx = 0;
  8000e8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000ee:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f2:	83 c4 14             	add    $0x14,%esp
  8000f5:	5b                   	pop    %ebx
  8000f6:	5d                   	pop    %ebp
  8000f7:	c3                   	ret    

008000f8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f8:	55                   	push   %ebp
  8000f9:	89 e5                	mov    %esp,%ebp
  8000fb:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800101:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800108:	00 00 00 
	b.cnt = 0;
  80010b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800112:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800115:	8b 45 0c             	mov    0xc(%ebp),%eax
  800118:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80011c:	8b 45 08             	mov    0x8(%ebp),%eax
  80011f:	89 44 24 08          	mov    %eax,0x8(%esp)
  800123:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800129:	89 44 24 04          	mov    %eax,0x4(%esp)
  80012d:	c7 04 24 b6 00 80 00 	movl   $0x8000b6,(%esp)
  800134:	e8 ac 01 00 00       	call   8002e5 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800139:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80013f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800143:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800149:	89 04 24             	mov    %eax,(%esp)
  80014c:	e8 bb 09 00 00       	call   800b0c <sys_cputs>

	return b.cnt;
}
  800151:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800157:	c9                   	leave  
  800158:	c3                   	ret    

00800159 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800159:	55                   	push   %ebp
  80015a:	89 e5                	mov    %esp,%ebp
  80015c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80015f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800162:	89 44 24 04          	mov    %eax,0x4(%esp)
  800166:	8b 45 08             	mov    0x8(%ebp),%eax
  800169:	89 04 24             	mov    %eax,(%esp)
  80016c:	e8 87 ff ff ff       	call   8000f8 <vcprintf>
	va_end(ap);

	return cnt;
}
  800171:	c9                   	leave  
  800172:	c3                   	ret    
  800173:	66 90                	xchg   %ax,%ax
  800175:	66 90                	xchg   %ax,%ax
  800177:	66 90                	xchg   %ax,%ax
  800179:	66 90                	xchg   %ax,%ax
  80017b:	66 90                	xchg   %ax,%ax
  80017d:	66 90                	xchg   %ax,%ax
  80017f:	90                   	nop

00800180 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	57                   	push   %edi
  800184:	56                   	push   %esi
  800185:	53                   	push   %ebx
  800186:	83 ec 4c             	sub    $0x4c,%esp
  800189:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80018c:	89 d7                	mov    %edx,%edi
  80018e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800191:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  800194:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800197:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80019a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80019d:	85 db                	test   %ebx,%ebx
  80019f:	75 08                	jne    8001a9 <printnum+0x29>
  8001a1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001a4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8001a7:	77 6c                	ja     800215 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001a9:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8001ac:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8001b0:	83 ee 01             	sub    $0x1,%esi
  8001b3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001ba:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001be:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001c2:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001c6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001c9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8001cc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001d3:	00 
  8001d4:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001d7:	89 1c 24             	mov    %ebx,(%esp)
  8001da:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8001dd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001e1:	e8 6a 0a 00 00       	call   800c50 <__udivdi3>
  8001e6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8001e9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8001ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001f0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8001f4:	89 04 24             	mov    %eax,(%esp)
  8001f7:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001fb:	89 fa                	mov    %edi,%edx
  8001fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800200:	e8 7b ff ff ff       	call   800180 <printnum>
  800205:	eb 1b                	jmp    800222 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800207:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80020b:	8b 45 18             	mov    0x18(%ebp),%eax
  80020e:	89 04 24             	mov    %eax,(%esp)
  800211:	ff d3                	call   *%ebx
  800213:	eb 03                	jmp    800218 <printnum+0x98>
  800215:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
  800218:	83 ee 01             	sub    $0x1,%esi
  80021b:	85 f6                	test   %esi,%esi
  80021d:	7f e8                	jg     800207 <printnum+0x87>
  80021f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800222:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800226:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80022a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80022d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800231:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800238:	00 
  800239:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80023c:	89 1c 24             	mov    %ebx,(%esp)
  80023f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800242:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800246:	e8 55 0b 00 00       	call   800da0 <__umoddi3>
  80024b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80024f:	0f be 80 68 0f 80 00 	movsbl 0x800f68(%eax),%eax
  800256:	89 04 24             	mov    %eax,(%esp)
  800259:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80025c:	ff d0                	call   *%eax
}
  80025e:	83 c4 4c             	add    $0x4c,%esp
  800261:	5b                   	pop    %ebx
  800262:	5e                   	pop    %esi
  800263:	5f                   	pop    %edi
  800264:	5d                   	pop    %ebp
  800265:	c3                   	ret    

00800266 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800266:	55                   	push   %ebp
  800267:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800269:	83 fa 01             	cmp    $0x1,%edx
  80026c:	7e 0e                	jle    80027c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80026e:	8b 10                	mov    (%eax),%edx
  800270:	8d 4a 08             	lea    0x8(%edx),%ecx
  800273:	89 08                	mov    %ecx,(%eax)
  800275:	8b 02                	mov    (%edx),%eax
  800277:	8b 52 04             	mov    0x4(%edx),%edx
  80027a:	eb 22                	jmp    80029e <getuint+0x38>
	else if (lflag)
  80027c:	85 d2                	test   %edx,%edx
  80027e:	74 10                	je     800290 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800280:	8b 10                	mov    (%eax),%edx
  800282:	8d 4a 04             	lea    0x4(%edx),%ecx
  800285:	89 08                	mov    %ecx,(%eax)
  800287:	8b 02                	mov    (%edx),%eax
  800289:	ba 00 00 00 00       	mov    $0x0,%edx
  80028e:	eb 0e                	jmp    80029e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800290:	8b 10                	mov    (%eax),%edx
  800292:	8d 4a 04             	lea    0x4(%edx),%ecx
  800295:	89 08                	mov    %ecx,(%eax)
  800297:	8b 02                	mov    (%edx),%eax
  800299:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80029e:	5d                   	pop    %ebp
  80029f:	c3                   	ret    

008002a0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002a0:	55                   	push   %ebp
  8002a1:	89 e5                	mov    %esp,%ebp
  8002a3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002a6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002aa:	8b 10                	mov    (%eax),%edx
  8002ac:	3b 50 04             	cmp    0x4(%eax),%edx
  8002af:	73 0a                	jae    8002bb <sprintputch+0x1b>
		*b->buf++ = ch;
  8002b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002b4:	88 0a                	mov    %cl,(%edx)
  8002b6:	83 c2 01             	add    $0x1,%edx
  8002b9:	89 10                	mov    %edx,(%eax)
}
  8002bb:	5d                   	pop    %ebp
  8002bc:	c3                   	ret    

008002bd <printfmt>:
{
  8002bd:	55                   	push   %ebp
  8002be:	89 e5                	mov    %esp,%ebp
  8002c0:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
  8002c3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002ca:	8b 45 10             	mov    0x10(%ebp),%eax
  8002cd:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8002db:	89 04 24             	mov    %eax,(%esp)
  8002de:	e8 02 00 00 00       	call   8002e5 <vprintfmt>
}
  8002e3:	c9                   	leave  
  8002e4:	c3                   	ret    

008002e5 <vprintfmt>:
{
  8002e5:	55                   	push   %ebp
  8002e6:	89 e5                	mov    %esp,%ebp
  8002e8:	57                   	push   %edi
  8002e9:	56                   	push   %esi
  8002ea:	53                   	push   %ebx
  8002eb:	83 ec 4c             	sub    $0x4c,%esp
  8002ee:	8b 75 08             	mov    0x8(%ebp),%esi
  8002f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002f4:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002f7:	eb 11                	jmp    80030a <vprintfmt+0x25>
			if (ch == '\0')
  8002f9:	85 c0                	test   %eax,%eax
  8002fb:	0f 84 cf 03 00 00    	je     8006d0 <vprintfmt+0x3eb>
			putch(ch, putdat);
  800301:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800305:	89 04 24             	mov    %eax,(%esp)
  800308:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80030a:	0f b6 07             	movzbl (%edi),%eax
  80030d:	83 c7 01             	add    $0x1,%edi
  800310:	83 f8 25             	cmp    $0x25,%eax
  800313:	75 e4                	jne    8002f9 <vprintfmt+0x14>
  800315:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800319:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  800320:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800327:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80032e:	ba 00 00 00 00       	mov    $0x0,%edx
  800333:	eb 2b                	jmp    800360 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800335:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
  800338:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  80033c:	eb 22                	jmp    800360 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  80033e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
  800341:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800345:	eb 19                	jmp    800360 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800347:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
  80034a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800351:	eb 0d                	jmp    800360 <vprintfmt+0x7b>
				width = precision, precision = -1;
  800353:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800356:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800359:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800360:	0f b6 07             	movzbl (%edi),%eax
  800363:	8d 4f 01             	lea    0x1(%edi),%ecx
  800366:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800369:	0f b6 0f             	movzbl (%edi),%ecx
  80036c:	83 e9 23             	sub    $0x23,%ecx
  80036f:	80 f9 55             	cmp    $0x55,%cl
  800372:	0f 87 3b 03 00 00    	ja     8006b3 <vprintfmt+0x3ce>
  800378:	0f b6 c9             	movzbl %cl,%ecx
  80037b:	ff 24 8d 00 10 80 00 	jmp    *0x801000(,%ecx,4)
  800382:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800385:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  80038c:	89 55 e0             	mov    %edx,-0x20(%ebp)
  80038f:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
  800394:	8d 14 92             	lea    (%edx,%edx,4),%edx
  800397:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  80039b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  80039e:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003a1:	83 f9 09             	cmp    $0x9,%ecx
  8003a4:	77 2f                	ja     8003d5 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
  8003a6:	83 c7 01             	add    $0x1,%edi
			}
  8003a9:	eb e9                	jmp    800394 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
  8003ab:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ae:	8d 48 04             	lea    0x4(%eax),%ecx
  8003b1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003b4:	8b 00                	mov    (%eax),%eax
  8003b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8003b9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
  8003bc:	eb 1d                	jmp    8003db <vprintfmt+0xf6>
			if (width < 0)
  8003be:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003c2:	78 83                	js     800347 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
  8003c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003c7:	eb 97                	jmp    800360 <vprintfmt+0x7b>
  8003c9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
  8003cc:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8003d3:	eb 8b                	jmp    800360 <vprintfmt+0x7b>
  8003d5:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8003d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
  8003db:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003df:	0f 89 7b ff ff ff    	jns    800360 <vprintfmt+0x7b>
  8003e5:	e9 69 ff ff ff       	jmp    800353 <vprintfmt+0x6e>
			lflag++;
  8003ea:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
  8003ed:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
  8003f0:	e9 6b ff ff ff       	jmp    800360 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
  8003f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f8:	8d 50 04             	lea    0x4(%eax),%edx
  8003fb:	89 55 14             	mov    %edx,0x14(%ebp)
  8003fe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800402:	8b 00                	mov    (%eax),%eax
  800404:	89 04 24             	mov    %eax,(%esp)
  800407:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  800409:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  80040c:	e9 f9 fe ff ff       	jmp    80030a <vprintfmt+0x25>
			err = va_arg(ap, int);
  800411:	8b 45 14             	mov    0x14(%ebp),%eax
  800414:	8d 50 04             	lea    0x4(%eax),%edx
  800417:	89 55 14             	mov    %edx,0x14(%ebp)
  80041a:	8b 00                	mov    (%eax),%eax
  80041c:	89 c2                	mov    %eax,%edx
  80041e:	c1 fa 1f             	sar    $0x1f,%edx
  800421:	31 d0                	xor    %edx,%eax
  800423:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800425:	83 f8 07             	cmp    $0x7,%eax
  800428:	7f 0b                	jg     800435 <vprintfmt+0x150>
  80042a:	8b 14 85 60 11 80 00 	mov    0x801160(,%eax,4),%edx
  800431:	85 d2                	test   %edx,%edx
  800433:	75 20                	jne    800455 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
  800435:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800439:	c7 44 24 08 80 0f 80 	movl   $0x800f80,0x8(%esp)
  800440:	00 
  800441:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800445:	89 34 24             	mov    %esi,(%esp)
  800448:	e8 70 fe ff ff       	call   8002bd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80044d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
  800450:	e9 b5 fe ff ff       	jmp    80030a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
  800455:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800459:	c7 44 24 08 89 0f 80 	movl   $0x800f89,0x8(%esp)
  800460:	00 
  800461:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800465:	89 34 24             	mov    %esi,(%esp)
  800468:	e8 50 fe ff ff       	call   8002bd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80046d:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800470:	e9 95 fe ff ff       	jmp    80030a <vprintfmt+0x25>
  800475:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800478:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80047b:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
  80047e:	8b 45 14             	mov    0x14(%ebp),%eax
  800481:	8d 50 04             	lea    0x4(%eax),%edx
  800484:	89 55 14             	mov    %edx,0x14(%ebp)
  800487:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800489:	85 ff                	test   %edi,%edi
  80048b:	b8 79 0f 80 00       	mov    $0x800f79,%eax
  800490:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800493:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  800497:	0f 84 9b 00 00 00    	je     800538 <vprintfmt+0x253>
  80049d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8004a1:	0f 8e 9f 00 00 00    	jle    800546 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004ab:	89 3c 24             	mov    %edi,(%esp)
  8004ae:	e8 c5 02 00 00       	call   800778 <strnlen>
  8004b3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8004b6:	29 c2                	sub    %eax,%edx
  8004b8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
  8004bb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8004bf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8004c2:	89 7d c8             	mov    %edi,-0x38(%ebp)
  8004c5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c7:	eb 0f                	jmp    8004d8 <vprintfmt+0x1f3>
					putch(padc, putdat);
  8004c9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004d0:	89 04 24             	mov    %eax,(%esp)
  8004d3:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d5:	83 ef 01             	sub    $0x1,%edi
  8004d8:	85 ff                	test   %edi,%edi
  8004da:	7f ed                	jg     8004c9 <vprintfmt+0x1e4>
  8004dc:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8004df:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004e3:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e8:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
  8004ec:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8004ef:	29 c2                	sub    %eax,%edx
  8004f1:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8004f4:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8004f7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8004fa:	89 d3                	mov    %edx,%ebx
  8004fc:	eb 54                	jmp    800552 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
  8004fe:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800502:	74 20                	je     800524 <vprintfmt+0x23f>
  800504:	0f be d2             	movsbl %dl,%edx
  800507:	83 ea 20             	sub    $0x20,%edx
  80050a:	83 fa 5e             	cmp    $0x5e,%edx
  80050d:	76 15                	jbe    800524 <vprintfmt+0x23f>
					putch('?', putdat);
  80050f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800512:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800516:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80051d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800520:	ff d0                	call   *%eax
  800522:	eb 0f                	jmp    800533 <vprintfmt+0x24e>
					putch(ch, putdat);
  800524:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800527:	89 54 24 04          	mov    %edx,0x4(%esp)
  80052b:	89 04 24             	mov    %eax,(%esp)
  80052e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800531:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800533:	83 eb 01             	sub    $0x1,%ebx
  800536:	eb 1a                	jmp    800552 <vprintfmt+0x26d>
  800538:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  80053b:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80053e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800541:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800544:	eb 0c                	jmp    800552 <vprintfmt+0x26d>
  800546:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800549:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80054c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80054f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800552:	0f b6 17             	movzbl (%edi),%edx
  800555:	0f be c2             	movsbl %dl,%eax
  800558:	83 c7 01             	add    $0x1,%edi
  80055b:	85 c0                	test   %eax,%eax
  80055d:	74 29                	je     800588 <vprintfmt+0x2a3>
  80055f:	85 f6                	test   %esi,%esi
  800561:	78 9b                	js     8004fe <vprintfmt+0x219>
  800563:	83 ee 01             	sub    $0x1,%esi
  800566:	79 96                	jns    8004fe <vprintfmt+0x219>
  800568:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80056b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80056e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800571:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800574:	eb 1a                	jmp    800590 <vprintfmt+0x2ab>
				putch(' ', putdat);
  800576:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80057a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800581:	ff d6                	call   *%esi
			for (; width > 0; width--)
  800583:	83 ef 01             	sub    $0x1,%edi
  800586:	eb 08                	jmp    800590 <vprintfmt+0x2ab>
  800588:	89 df                	mov    %ebx,%edi
  80058a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80058d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800590:	85 ff                	test   %edi,%edi
  800592:	7f e2                	jg     800576 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
  800594:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800597:	e9 6e fd ff ff       	jmp    80030a <vprintfmt+0x25>
	if (lflag >= 2)
  80059c:	83 fa 01             	cmp    $0x1,%edx
  80059f:	7e 16                	jle    8005b7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
  8005a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a4:	8d 50 08             	lea    0x8(%eax),%edx
  8005a7:	89 55 14             	mov    %edx,0x14(%ebp)
  8005aa:	8b 10                	mov    (%eax),%edx
  8005ac:	8b 48 04             	mov    0x4(%eax),%ecx
  8005af:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8005b2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005b5:	eb 32                	jmp    8005e9 <vprintfmt+0x304>
	else if (lflag)
  8005b7:	85 d2                	test   %edx,%edx
  8005b9:	74 18                	je     8005d3 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
  8005bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005be:	8d 50 04             	lea    0x4(%eax),%edx
  8005c1:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c4:	8b 00                	mov    (%eax),%eax
  8005c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005c9:	89 c1                	mov    %eax,%ecx
  8005cb:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ce:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005d1:	eb 16                	jmp    8005e9 <vprintfmt+0x304>
		return va_arg(*ap, int);
  8005d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d6:	8d 50 04             	lea    0x4(%eax),%edx
  8005d9:	89 55 14             	mov    %edx,0x14(%ebp)
  8005dc:	8b 00                	mov    (%eax),%eax
  8005de:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005e1:	89 c7                	mov    %eax,%edi
  8005e3:	c1 ff 1f             	sar    $0x1f,%edi
  8005e6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
  8005e9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005ec:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
  8005ef:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
  8005f4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8005f8:	79 7d                	jns    800677 <vprintfmt+0x392>
				putch('-', putdat);
  8005fa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005fe:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800605:	ff d6                	call   *%esi
				num = -(long long) num;
  800607:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80060a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80060d:	f7 d8                	neg    %eax
  80060f:	83 d2 00             	adc    $0x0,%edx
  800612:	f7 da                	neg    %edx
			base = 10;
  800614:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800619:	eb 5c                	jmp    800677 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80061b:	8d 45 14             	lea    0x14(%ebp),%eax
  80061e:	e8 43 fc ff ff       	call   800266 <getuint>
			base = 10;
  800623:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800628:	eb 4d                	jmp    800677 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80062a:	8d 45 14             	lea    0x14(%ebp),%eax
  80062d:	e8 34 fc ff ff       	call   800266 <getuint>
			base = 8;
  800632:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800637:	eb 3e                	jmp    800677 <vprintfmt+0x392>
			putch('0', putdat);
  800639:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80063d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800644:	ff d6                	call   *%esi
			putch('x', putdat);
  800646:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80064a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800651:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
  800653:	8b 45 14             	mov    0x14(%ebp),%eax
  800656:	8d 50 04             	lea    0x4(%eax),%edx
  800659:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
  80065c:	8b 00                	mov    (%eax),%eax
  80065e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
  800663:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800668:	eb 0d                	jmp    800677 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80066a:	8d 45 14             	lea    0x14(%ebp),%eax
  80066d:	e8 f4 fb ff ff       	call   800266 <getuint>
			base = 16;
  800672:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
  800677:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80067b:	89 7c 24 10          	mov    %edi,0x10(%esp)
  80067f:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800682:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800686:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80068a:	89 04 24             	mov    %eax,(%esp)
  80068d:	89 54 24 04          	mov    %edx,0x4(%esp)
  800691:	89 da                	mov    %ebx,%edx
  800693:	89 f0                	mov    %esi,%eax
  800695:	e8 e6 fa ff ff       	call   800180 <printnum>
			break;
  80069a:	8b 7d e0             	mov    -0x20(%ebp),%edi
  80069d:	e9 68 fc ff ff       	jmp    80030a <vprintfmt+0x25>
			putch(ch, putdat);
  8006a2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006a6:	89 04 24             	mov    %eax,(%esp)
  8006a9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  8006ab:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  8006ae:	e9 57 fc ff ff       	jmp    80030a <vprintfmt+0x25>
			putch('%', putdat);
  8006b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006b7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006be:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006c0:	eb 03                	jmp    8006c5 <vprintfmt+0x3e0>
  8006c2:	83 ef 01             	sub    $0x1,%edi
  8006c5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006c9:	75 f7                	jne    8006c2 <vprintfmt+0x3dd>
  8006cb:	e9 3a fc ff ff       	jmp    80030a <vprintfmt+0x25>
}
  8006d0:	83 c4 4c             	add    $0x4c,%esp
  8006d3:	5b                   	pop    %ebx
  8006d4:	5e                   	pop    %esi
  8006d5:	5f                   	pop    %edi
  8006d6:	5d                   	pop    %ebp
  8006d7:	c3                   	ret    

008006d8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006d8:	55                   	push   %ebp
  8006d9:	89 e5                	mov    %esp,%ebp
  8006db:	83 ec 28             	sub    $0x28,%esp
  8006de:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006e7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006eb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006f5:	85 d2                	test   %edx,%edx
  8006f7:	7e 30                	jle    800729 <vsnprintf+0x51>
  8006f9:	85 c0                	test   %eax,%eax
  8006fb:	74 2c                	je     800729 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800700:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800704:	8b 45 10             	mov    0x10(%ebp),%eax
  800707:	89 44 24 08          	mov    %eax,0x8(%esp)
  80070b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80070e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800712:	c7 04 24 a0 02 80 00 	movl   $0x8002a0,(%esp)
  800719:	e8 c7 fb ff ff       	call   8002e5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80071e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800721:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800724:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800727:	eb 05                	jmp    80072e <vsnprintf+0x56>
		return -E_INVAL;
  800729:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  80072e:	c9                   	leave  
  80072f:	c3                   	ret    

00800730 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800730:	55                   	push   %ebp
  800731:	89 e5                	mov    %esp,%ebp
  800733:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800736:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800739:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80073d:	8b 45 10             	mov    0x10(%ebp),%eax
  800740:	89 44 24 08          	mov    %eax,0x8(%esp)
  800744:	8b 45 0c             	mov    0xc(%ebp),%eax
  800747:	89 44 24 04          	mov    %eax,0x4(%esp)
  80074b:	8b 45 08             	mov    0x8(%ebp),%eax
  80074e:	89 04 24             	mov    %eax,(%esp)
  800751:	e8 82 ff ff ff       	call   8006d8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800756:	c9                   	leave  
  800757:	c3                   	ret    
  800758:	66 90                	xchg   %ax,%ax
  80075a:	66 90                	xchg   %ax,%ax
  80075c:	66 90                	xchg   %ax,%ax
  80075e:	66 90                	xchg   %ax,%ax

00800760 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800766:	b8 00 00 00 00       	mov    $0x0,%eax
  80076b:	eb 03                	jmp    800770 <strlen+0x10>
		n++;
  80076d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  800770:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800774:	75 f7                	jne    80076d <strlen+0xd>
	return n;
}
  800776:	5d                   	pop    %ebp
  800777:	c3                   	ret    

00800778 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800778:	55                   	push   %ebp
  800779:	89 e5                	mov    %esp,%ebp
  80077b:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
  80077e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800781:	b8 00 00 00 00       	mov    $0x0,%eax
  800786:	eb 03                	jmp    80078b <strnlen+0x13>
		n++;
  800788:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078b:	39 d0                	cmp    %edx,%eax
  80078d:	74 06                	je     800795 <strnlen+0x1d>
  80078f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800793:	75 f3                	jne    800788 <strnlen+0x10>
	return n;
}
  800795:	5d                   	pop    %ebp
  800796:	c3                   	ret    

00800797 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800797:	55                   	push   %ebp
  800798:	89 e5                	mov    %esp,%ebp
  80079a:	53                   	push   %ebx
  80079b:	8b 45 08             	mov    0x8(%ebp),%eax
  80079e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007a1:	89 c2                	mov    %eax,%edx
  8007a3:	0f b6 19             	movzbl (%ecx),%ebx
  8007a6:	88 1a                	mov    %bl,(%edx)
  8007a8:	83 c2 01             	add    $0x1,%edx
  8007ab:	83 c1 01             	add    $0x1,%ecx
  8007ae:	84 db                	test   %bl,%bl
  8007b0:	75 f1                	jne    8007a3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007b2:	5b                   	pop    %ebx
  8007b3:	5d                   	pop    %ebp
  8007b4:	c3                   	ret    

008007b5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007b5:	55                   	push   %ebp
  8007b6:	89 e5                	mov    %esp,%ebp
  8007b8:	53                   	push   %ebx
  8007b9:	83 ec 08             	sub    $0x8,%esp
  8007bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007bf:	89 1c 24             	mov    %ebx,(%esp)
  8007c2:	e8 99 ff ff ff       	call   800760 <strlen>
	strcpy(dst + len, src);
  8007c7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007ce:	01 d8                	add    %ebx,%eax
  8007d0:	89 04 24             	mov    %eax,(%esp)
  8007d3:	e8 bf ff ff ff       	call   800797 <strcpy>
	return dst;
}
  8007d8:	89 d8                	mov    %ebx,%eax
  8007da:	83 c4 08             	add    $0x8,%esp
  8007dd:	5b                   	pop    %ebx
  8007de:	5d                   	pop    %ebp
  8007df:	c3                   	ret    

008007e0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007e0:	55                   	push   %ebp
  8007e1:	89 e5                	mov    %esp,%ebp
  8007e3:	56                   	push   %esi
  8007e4:	53                   	push   %ebx
  8007e5:	8b 75 08             	mov    0x8(%ebp),%esi
  8007e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007eb:	89 f3                	mov    %esi,%ebx
  8007ed:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f0:	89 f2                	mov    %esi,%edx
  8007f2:	eb 0e                	jmp    800802 <strncpy+0x22>
		*dst++ = *src;
  8007f4:	0f b6 01             	movzbl (%ecx),%eax
  8007f7:	88 02                	mov    %al,(%edx)
  8007f9:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007fc:	80 39 01             	cmpb   $0x1,(%ecx)
  8007ff:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800802:	39 da                	cmp    %ebx,%edx
  800804:	75 ee                	jne    8007f4 <strncpy+0x14>
	}
	return ret;
}
  800806:	89 f0                	mov    %esi,%eax
  800808:	5b                   	pop    %ebx
  800809:	5e                   	pop    %esi
  80080a:	5d                   	pop    %ebp
  80080b:	c3                   	ret    

0080080c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80080c:	55                   	push   %ebp
  80080d:	89 e5                	mov    %esp,%ebp
  80080f:	56                   	push   %esi
  800810:	53                   	push   %ebx
  800811:	8b 75 08             	mov    0x8(%ebp),%esi
  800814:	8b 55 0c             	mov    0xc(%ebp),%edx
  800817:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80081a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
  80081c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
  800820:	85 c9                	test   %ecx,%ecx
  800822:	75 0a                	jne    80082e <strlcpy+0x22>
  800824:	eb 1c                	jmp    800842 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800826:	88 08                	mov    %cl,(%eax)
  800828:	83 c0 01             	add    $0x1,%eax
  80082b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
  80082e:	39 d8                	cmp    %ebx,%eax
  800830:	74 0b                	je     80083d <strlcpy+0x31>
  800832:	0f b6 0a             	movzbl (%edx),%ecx
  800835:	84 c9                	test   %cl,%cl
  800837:	75 ed                	jne    800826 <strlcpy+0x1a>
  800839:	89 c2                	mov    %eax,%edx
  80083b:	eb 02                	jmp    80083f <strlcpy+0x33>
  80083d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
  80083f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800842:	29 f0                	sub    %esi,%eax
}
  800844:	5b                   	pop    %ebx
  800845:	5e                   	pop    %esi
  800846:	5d                   	pop    %ebp
  800847:	c3                   	ret    

00800848 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800848:	55                   	push   %ebp
  800849:	89 e5                	mov    %esp,%ebp
  80084b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80084e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800851:	eb 06                	jmp    800859 <strcmp+0x11>
		p++, q++;
  800853:	83 c1 01             	add    $0x1,%ecx
  800856:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800859:	0f b6 01             	movzbl (%ecx),%eax
  80085c:	84 c0                	test   %al,%al
  80085e:	74 04                	je     800864 <strcmp+0x1c>
  800860:	3a 02                	cmp    (%edx),%al
  800862:	74 ef                	je     800853 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800864:	0f b6 c0             	movzbl %al,%eax
  800867:	0f b6 12             	movzbl (%edx),%edx
  80086a:	29 d0                	sub    %edx,%eax
}
  80086c:	5d                   	pop    %ebp
  80086d:	c3                   	ret    

0080086e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80086e:	55                   	push   %ebp
  80086f:	89 e5                	mov    %esp,%ebp
  800871:	53                   	push   %ebx
  800872:	8b 45 08             	mov    0x8(%ebp),%eax
  800875:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
  800878:	89 c3                	mov    %eax,%ebx
  80087a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80087d:	eb 06                	jmp    800885 <strncmp+0x17>
		n--, p++, q++;
  80087f:	83 c0 01             	add    $0x1,%eax
  800882:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  800885:	39 d8                	cmp    %ebx,%eax
  800887:	74 15                	je     80089e <strncmp+0x30>
  800889:	0f b6 08             	movzbl (%eax),%ecx
  80088c:	84 c9                	test   %cl,%cl
  80088e:	74 04                	je     800894 <strncmp+0x26>
  800890:	3a 0a                	cmp    (%edx),%cl
  800892:	74 eb                	je     80087f <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800894:	0f b6 00             	movzbl (%eax),%eax
  800897:	0f b6 12             	movzbl (%edx),%edx
  80089a:	29 d0                	sub    %edx,%eax
  80089c:	eb 05                	jmp    8008a3 <strncmp+0x35>
		return 0;
  80089e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008a3:	5b                   	pop    %ebx
  8008a4:	5d                   	pop    %ebp
  8008a5:	c3                   	ret    

008008a6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008a6:	55                   	push   %ebp
  8008a7:	89 e5                	mov    %esp,%ebp
  8008a9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ac:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b0:	eb 07                	jmp    8008b9 <strchr+0x13>
		if (*s == c)
  8008b2:	38 ca                	cmp    %cl,%dl
  8008b4:	74 0f                	je     8008c5 <strchr+0x1f>
	for (; *s; s++)
  8008b6:	83 c0 01             	add    $0x1,%eax
  8008b9:	0f b6 10             	movzbl (%eax),%edx
  8008bc:	84 d2                	test   %dl,%dl
  8008be:	75 f2                	jne    8008b2 <strchr+0xc>
			return (char *) s;
	return 0;
  8008c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008c5:	5d                   	pop    %ebp
  8008c6:	c3                   	ret    

008008c7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008c7:	55                   	push   %ebp
  8008c8:	89 e5                	mov    %esp,%ebp
  8008ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8008cd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d1:	eb 07                	jmp    8008da <strfind+0x13>
		if (*s == c)
  8008d3:	38 ca                	cmp    %cl,%dl
  8008d5:	74 0a                	je     8008e1 <strfind+0x1a>
	for (; *s; s++)
  8008d7:	83 c0 01             	add    $0x1,%eax
  8008da:	0f b6 10             	movzbl (%eax),%edx
  8008dd:	84 d2                	test   %dl,%dl
  8008df:	75 f2                	jne    8008d3 <strfind+0xc>
			break;
	return (char *) s;
}
  8008e1:	5d                   	pop    %ebp
  8008e2:	c3                   	ret    

008008e3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008e3:	55                   	push   %ebp
  8008e4:	89 e5                	mov    %esp,%ebp
  8008e6:	83 ec 0c             	sub    $0xc,%esp
  8008e9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8008ec:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8008ef:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8008f2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008f5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008f8:	85 c9                	test   %ecx,%ecx
  8008fa:	74 36                	je     800932 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008fc:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800902:	75 28                	jne    80092c <memset+0x49>
  800904:	f6 c1 03             	test   $0x3,%cl
  800907:	75 23                	jne    80092c <memset+0x49>
		c &= 0xFF;
  800909:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80090d:	89 d3                	mov    %edx,%ebx
  80090f:	c1 e3 08             	shl    $0x8,%ebx
  800912:	89 d6                	mov    %edx,%esi
  800914:	c1 e6 18             	shl    $0x18,%esi
  800917:	89 d0                	mov    %edx,%eax
  800919:	c1 e0 10             	shl    $0x10,%eax
  80091c:	09 f0                	or     %esi,%eax
  80091e:	09 c2                	or     %eax,%edx
  800920:	89 d0                	mov    %edx,%eax
  800922:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800924:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800927:	fc                   	cld    
  800928:	f3 ab                	rep stos %eax,%es:(%edi)
  80092a:	eb 06                	jmp    800932 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80092c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80092f:	fc                   	cld    
  800930:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800932:	89 f8                	mov    %edi,%eax
  800934:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800937:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80093a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80093d:	89 ec                	mov    %ebp,%esp
  80093f:	5d                   	pop    %ebp
  800940:	c3                   	ret    

00800941 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800941:	55                   	push   %ebp
  800942:	89 e5                	mov    %esp,%ebp
  800944:	83 ec 08             	sub    $0x8,%esp
  800947:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80094a:	89 7d fc             	mov    %edi,-0x4(%ebp)
  80094d:	8b 45 08             	mov    0x8(%ebp),%eax
  800950:	8b 75 0c             	mov    0xc(%ebp),%esi
  800953:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800956:	39 c6                	cmp    %eax,%esi
  800958:	73 36                	jae    800990 <memmove+0x4f>
  80095a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80095d:	39 d0                	cmp    %edx,%eax
  80095f:	73 2f                	jae    800990 <memmove+0x4f>
		s += n;
		d += n;
  800961:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800964:	f6 c2 03             	test   $0x3,%dl
  800967:	75 1b                	jne    800984 <memmove+0x43>
  800969:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80096f:	75 13                	jne    800984 <memmove+0x43>
  800971:	f6 c1 03             	test   $0x3,%cl
  800974:	75 0e                	jne    800984 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800976:	83 ef 04             	sub    $0x4,%edi
  800979:	8d 72 fc             	lea    -0x4(%edx),%esi
  80097c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  80097f:	fd                   	std    
  800980:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800982:	eb 09                	jmp    80098d <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800984:	83 ef 01             	sub    $0x1,%edi
  800987:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  80098a:	fd                   	std    
  80098b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80098d:	fc                   	cld    
  80098e:	eb 20                	jmp    8009b0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800990:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800996:	75 13                	jne    8009ab <memmove+0x6a>
  800998:	a8 03                	test   $0x3,%al
  80099a:	75 0f                	jne    8009ab <memmove+0x6a>
  80099c:	f6 c1 03             	test   $0x3,%cl
  80099f:	75 0a                	jne    8009ab <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  8009a1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  8009a4:	89 c7                	mov    %eax,%edi
  8009a6:	fc                   	cld    
  8009a7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009a9:	eb 05                	jmp    8009b0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
  8009ab:	89 c7                	mov    %eax,%edi
  8009ad:	fc                   	cld    
  8009ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009b0:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8009b3:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8009b6:	89 ec                	mov    %ebp,%esp
  8009b8:	5d                   	pop    %ebp
  8009b9:	c3                   	ret    

008009ba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009ba:	55                   	push   %ebp
  8009bb:	89 e5                	mov    %esp,%ebp
  8009bd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  8009c0:	8b 45 10             	mov    0x10(%ebp),%eax
  8009c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d1:	89 04 24             	mov    %eax,(%esp)
  8009d4:	e8 68 ff ff ff       	call   800941 <memmove>
}
  8009d9:	c9                   	leave  
  8009da:	c3                   	ret    

008009db <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009db:	55                   	push   %ebp
  8009dc:	89 e5                	mov    %esp,%ebp
  8009de:	56                   	push   %esi
  8009df:	53                   	push   %ebx
  8009e0:	8b 55 08             	mov    0x8(%ebp),%edx
  8009e3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
  8009e6:	89 d6                	mov    %edx,%esi
  8009e8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009eb:	eb 1a                	jmp    800a07 <memcmp+0x2c>
		if (*s1 != *s2)
  8009ed:	0f b6 02             	movzbl (%edx),%eax
  8009f0:	0f b6 19             	movzbl (%ecx),%ebx
  8009f3:	38 d8                	cmp    %bl,%al
  8009f5:	74 0a                	je     800a01 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009f7:	0f b6 c0             	movzbl %al,%eax
  8009fa:	0f b6 db             	movzbl %bl,%ebx
  8009fd:	29 d8                	sub    %ebx,%eax
  8009ff:	eb 0f                	jmp    800a10 <memcmp+0x35>
		s1++, s2++;
  800a01:	83 c2 01             	add    $0x1,%edx
  800a04:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
  800a07:	39 f2                	cmp    %esi,%edx
  800a09:	75 e2                	jne    8009ed <memcmp+0x12>
	}

	return 0;
  800a0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a10:	5b                   	pop    %ebx
  800a11:	5e                   	pop    %esi
  800a12:	5d                   	pop    %ebp
  800a13:	c3                   	ret    

00800a14 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a14:	55                   	push   %ebp
  800a15:	89 e5                	mov    %esp,%ebp
  800a17:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a1d:	89 c2                	mov    %eax,%edx
  800a1f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a22:	eb 07                	jmp    800a2b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a24:	38 08                	cmp    %cl,(%eax)
  800a26:	74 07                	je     800a2f <memfind+0x1b>
	for (; s < ends; s++)
  800a28:	83 c0 01             	add    $0x1,%eax
  800a2b:	39 d0                	cmp    %edx,%eax
  800a2d:	72 f5                	jb     800a24 <memfind+0x10>
			break;
	return (void *) s;
}
  800a2f:	5d                   	pop    %ebp
  800a30:	c3                   	ret    

00800a31 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a31:	55                   	push   %ebp
  800a32:	89 e5                	mov    %esp,%ebp
  800a34:	57                   	push   %edi
  800a35:	56                   	push   %esi
  800a36:	53                   	push   %ebx
  800a37:	83 ec 04             	sub    $0x4,%esp
  800a3a:	8b 55 08             	mov    0x8(%ebp),%edx
  800a3d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a40:	eb 03                	jmp    800a45 <strtol+0x14>
		s++;
  800a42:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
  800a45:	0f b6 02             	movzbl (%edx),%eax
  800a48:	3c 09                	cmp    $0x9,%al
  800a4a:	74 f6                	je     800a42 <strtol+0x11>
  800a4c:	3c 20                	cmp    $0x20,%al
  800a4e:	74 f2                	je     800a42 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
  800a50:	3c 2b                	cmp    $0x2b,%al
  800a52:	75 0a                	jne    800a5e <strtol+0x2d>
		s++;
  800a54:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
  800a57:	bf 00 00 00 00       	mov    $0x0,%edi
  800a5c:	eb 10                	jmp    800a6e <strtol+0x3d>
  800a5e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
  800a63:	3c 2d                	cmp    $0x2d,%al
  800a65:	75 07                	jne    800a6e <strtol+0x3d>
		s++, neg = 1;
  800a67:	8d 52 01             	lea    0x1(%edx),%edx
  800a6a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a6e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a74:	75 15                	jne    800a8b <strtol+0x5a>
  800a76:	80 3a 30             	cmpb   $0x30,(%edx)
  800a79:	75 10                	jne    800a8b <strtol+0x5a>
  800a7b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a7f:	75 0a                	jne    800a8b <strtol+0x5a>
		s += 2, base = 16;
  800a81:	83 c2 02             	add    $0x2,%edx
  800a84:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a89:	eb 10                	jmp    800a9b <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a8b:	85 db                	test   %ebx,%ebx
  800a8d:	75 0c                	jne    800a9b <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a8f:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
  800a91:	80 3a 30             	cmpb   $0x30,(%edx)
  800a94:	75 05                	jne    800a9b <strtol+0x6a>
		s++, base = 8;
  800a96:	83 c2 01             	add    $0x1,%edx
  800a99:	b3 08                	mov    $0x8,%bl
		base = 10;
  800a9b:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800aa3:	0f b6 0a             	movzbl (%edx),%ecx
  800aa6:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800aa9:	89 f3                	mov    %esi,%ebx
  800aab:	80 fb 09             	cmp    $0x9,%bl
  800aae:	77 08                	ja     800ab8 <strtol+0x87>
			dig = *s - '0';
  800ab0:	0f be c9             	movsbl %cl,%ecx
  800ab3:	83 e9 30             	sub    $0x30,%ecx
  800ab6:	eb 22                	jmp    800ada <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
  800ab8:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800abb:	89 f3                	mov    %esi,%ebx
  800abd:	80 fb 19             	cmp    $0x19,%bl
  800ac0:	77 08                	ja     800aca <strtol+0x99>
			dig = *s - 'a' + 10;
  800ac2:	0f be c9             	movsbl %cl,%ecx
  800ac5:	83 e9 57             	sub    $0x57,%ecx
  800ac8:	eb 10                	jmp    800ada <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
  800aca:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800acd:	89 f3                	mov    %esi,%ebx
  800acf:	80 fb 19             	cmp    $0x19,%bl
  800ad2:	77 16                	ja     800aea <strtol+0xb9>
			dig = *s - 'A' + 10;
  800ad4:	0f be c9             	movsbl %cl,%ecx
  800ad7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800ada:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800add:	7d 0f                	jge    800aee <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800adf:	83 c2 01             	add    $0x1,%edx
  800ae2:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800ae6:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800ae8:	eb b9                	jmp    800aa3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
  800aea:	89 c1                	mov    %eax,%ecx
  800aec:	eb 02                	jmp    800af0 <strtol+0xbf>
		if (dig >= base)
  800aee:	89 c1                	mov    %eax,%ecx

	if (endptr)
  800af0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800af4:	74 05                	je     800afb <strtol+0xca>
		*endptr = (char *) s;
  800af6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800af9:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800afb:	89 ca                	mov    %ecx,%edx
  800afd:	f7 da                	neg    %edx
  800aff:	85 ff                	test   %edi,%edi
  800b01:	0f 45 c2             	cmovne %edx,%eax
}
  800b04:	83 c4 04             	add    $0x4,%esp
  800b07:	5b                   	pop    %ebx
  800b08:	5e                   	pop    %esi
  800b09:	5f                   	pop    %edi
  800b0a:	5d                   	pop    %ebp
  800b0b:	c3                   	ret    

00800b0c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b0c:	55                   	push   %ebp
  800b0d:	89 e5                	mov    %esp,%ebp
  800b0f:	83 ec 0c             	sub    $0xc,%esp
  800b12:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b15:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b18:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800b1b:	b8 00 00 00 00       	mov    $0x0,%eax
  800b20:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b23:	8b 55 08             	mov    0x8(%ebp),%edx
  800b26:	89 c3                	mov    %eax,%ebx
  800b28:	89 c7                	mov    %eax,%edi
  800b2a:	89 c6                	mov    %eax,%esi
  800b2c:	cd 30                	int    $0x30
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b2e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b31:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b34:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b37:	89 ec                	mov    %ebp,%esp
  800b39:	5d                   	pop    %ebp
  800b3a:	c3                   	ret    

00800b3b <sys_cgetc>:

int
sys_cgetc(void)
{
  800b3b:	55                   	push   %ebp
  800b3c:	89 e5                	mov    %esp,%ebp
  800b3e:	83 ec 0c             	sub    $0xc,%esp
  800b41:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b44:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b47:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800b4a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b4f:	b8 01 00 00 00       	mov    $0x1,%eax
  800b54:	89 d1                	mov    %edx,%ecx
  800b56:	89 d3                	mov    %edx,%ebx
  800b58:	89 d7                	mov    %edx,%edi
  800b5a:	89 d6                	mov    %edx,%esi
  800b5c:	cd 30                	int    $0x30
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b5e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b61:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b64:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b67:	89 ec                	mov    %ebp,%esp
  800b69:	5d                   	pop    %ebp
  800b6a:	c3                   	ret    

00800b6b <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b6b:	55                   	push   %ebp
  800b6c:	89 e5                	mov    %esp,%ebp
  800b6e:	83 ec 38             	sub    $0x38,%esp
  800b71:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b74:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b77:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800b7a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b7f:	b8 03 00 00 00       	mov    $0x3,%eax
  800b84:	8b 55 08             	mov    0x8(%ebp),%edx
  800b87:	89 cb                	mov    %ecx,%ebx
  800b89:	89 cf                	mov    %ecx,%edi
  800b8b:	89 ce                	mov    %ecx,%esi
  800b8d:	cd 30                	int    $0x30
	if(check && ret > 0)
  800b8f:	85 c0                	test   %eax,%eax
  800b91:	7e 28                	jle    800bbb <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b93:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b97:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b9e:	00 
  800b9f:	c7 44 24 08 80 11 80 	movl   $0x801180,0x8(%esp)
  800ba6:	00 
  800ba7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800bae:	00 
  800baf:	c7 04 24 9d 11 80 00 	movl   $0x80119d,(%esp)
  800bb6:	e8 3d 00 00 00       	call   800bf8 <_panic>
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bbb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800bbe:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bc1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bc4:	89 ec                	mov    %ebp,%esp
  800bc6:	5d                   	pop    %ebp
  800bc7:	c3                   	ret    

00800bc8 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bc8:	55                   	push   %ebp
  800bc9:	89 e5                	mov    %esp,%ebp
  800bcb:	83 ec 0c             	sub    $0xc,%esp
  800bce:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800bd1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bd4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800bd7:	ba 00 00 00 00       	mov    $0x0,%edx
  800bdc:	b8 02 00 00 00       	mov    $0x2,%eax
  800be1:	89 d1                	mov    %edx,%ecx
  800be3:	89 d3                	mov    %edx,%ebx
  800be5:	89 d7                	mov    %edx,%edi
  800be7:	89 d6                	mov    %edx,%esi
  800be9:	cd 30                	int    $0x30
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800beb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800bee:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bf1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bf4:	89 ec                	mov    %ebp,%esp
  800bf6:	5d                   	pop    %ebp
  800bf7:	c3                   	ret    

00800bf8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800bf8:	55                   	push   %ebp
  800bf9:	89 e5                	mov    %esp,%ebp
  800bfb:	56                   	push   %esi
  800bfc:	53                   	push   %ebx
  800bfd:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800c00:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800c03:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800c09:	e8 ba ff ff ff       	call   800bc8 <sys_getenvid>
  800c0e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c11:	89 54 24 10          	mov    %edx,0x10(%esp)
  800c15:	8b 55 08             	mov    0x8(%ebp),%edx
  800c18:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c1c:	89 74 24 08          	mov    %esi,0x8(%esp)
  800c20:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c24:	c7 04 24 ac 11 80 00 	movl   $0x8011ac,(%esp)
  800c2b:	e8 29 f5 ff ff       	call   800159 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c30:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c34:	8b 45 10             	mov    0x10(%ebp),%eax
  800c37:	89 04 24             	mov    %eax,(%esp)
  800c3a:	e8 b9 f4 ff ff       	call   8000f8 <vcprintf>
	cprintf("\n");
  800c3f:	c7 04 24 5c 0f 80 00 	movl   $0x800f5c,(%esp)
  800c46:	e8 0e f5 ff ff       	call   800159 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c4b:	cc                   	int3   
  800c4c:	eb fd                	jmp    800c4b <_panic+0x53>
  800c4e:	66 90                	xchg   %ax,%ax

00800c50 <__udivdi3>:
  800c50:	83 ec 1c             	sub    $0x1c,%esp
  800c53:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800c57:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800c5b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c5f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c63:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800c67:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800c6b:	85 c0                	test   %eax,%eax
  800c6d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c71:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c75:	89 ea                	mov    %ebp,%edx
  800c77:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c7b:	75 33                	jne    800cb0 <__udivdi3+0x60>
  800c7d:	39 e9                	cmp    %ebp,%ecx
  800c7f:	77 6f                	ja     800cf0 <__udivdi3+0xa0>
  800c81:	85 c9                	test   %ecx,%ecx
  800c83:	89 ce                	mov    %ecx,%esi
  800c85:	75 0b                	jne    800c92 <__udivdi3+0x42>
  800c87:	b8 01 00 00 00       	mov    $0x1,%eax
  800c8c:	31 d2                	xor    %edx,%edx
  800c8e:	f7 f1                	div    %ecx
  800c90:	89 c6                	mov    %eax,%esi
  800c92:	31 d2                	xor    %edx,%edx
  800c94:	89 e8                	mov    %ebp,%eax
  800c96:	f7 f6                	div    %esi
  800c98:	89 c5                	mov    %eax,%ebp
  800c9a:	89 f8                	mov    %edi,%eax
  800c9c:	f7 f6                	div    %esi
  800c9e:	89 ea                	mov    %ebp,%edx
  800ca0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800ca4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ca8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800cac:	83 c4 1c             	add    $0x1c,%esp
  800caf:	c3                   	ret    
  800cb0:	39 e8                	cmp    %ebp,%eax
  800cb2:	77 24                	ja     800cd8 <__udivdi3+0x88>
  800cb4:	0f bd c8             	bsr    %eax,%ecx
  800cb7:	83 f1 1f             	xor    $0x1f,%ecx
  800cba:	89 0c 24             	mov    %ecx,(%esp)
  800cbd:	75 49                	jne    800d08 <__udivdi3+0xb8>
  800cbf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cc3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800cc7:	0f 86 ab 00 00 00    	jbe    800d78 <__udivdi3+0x128>
  800ccd:	39 e8                	cmp    %ebp,%eax
  800ccf:	0f 82 a3 00 00 00    	jb     800d78 <__udivdi3+0x128>
  800cd5:	8d 76 00             	lea    0x0(%esi),%esi
  800cd8:	31 d2                	xor    %edx,%edx
  800cda:	31 c0                	xor    %eax,%eax
  800cdc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800ce0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ce4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800ce8:	83 c4 1c             	add    $0x1c,%esp
  800ceb:	c3                   	ret    
  800cec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cf0:	89 f8                	mov    %edi,%eax
  800cf2:	f7 f1                	div    %ecx
  800cf4:	31 d2                	xor    %edx,%edx
  800cf6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cfa:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cfe:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d02:	83 c4 1c             	add    $0x1c,%esp
  800d05:	c3                   	ret    
  800d06:	66 90                	xchg   %ax,%ax
  800d08:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d0c:	89 c6                	mov    %eax,%esi
  800d0e:	b8 20 00 00 00       	mov    $0x20,%eax
  800d13:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800d17:	2b 04 24             	sub    (%esp),%eax
  800d1a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d1e:	d3 e6                	shl    %cl,%esi
  800d20:	89 c1                	mov    %eax,%ecx
  800d22:	d3 ed                	shr    %cl,%ebp
  800d24:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d28:	09 f5                	or     %esi,%ebp
  800d2a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d2e:	d3 e6                	shl    %cl,%esi
  800d30:	89 c1                	mov    %eax,%ecx
  800d32:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d36:	89 d6                	mov    %edx,%esi
  800d38:	d3 ee                	shr    %cl,%esi
  800d3a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d3e:	d3 e2                	shl    %cl,%edx
  800d40:	89 c1                	mov    %eax,%ecx
  800d42:	d3 ef                	shr    %cl,%edi
  800d44:	09 d7                	or     %edx,%edi
  800d46:	89 f2                	mov    %esi,%edx
  800d48:	89 f8                	mov    %edi,%eax
  800d4a:	f7 f5                	div    %ebp
  800d4c:	89 d6                	mov    %edx,%esi
  800d4e:	89 c7                	mov    %eax,%edi
  800d50:	f7 64 24 04          	mull   0x4(%esp)
  800d54:	39 d6                	cmp    %edx,%esi
  800d56:	72 30                	jb     800d88 <__udivdi3+0x138>
  800d58:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800d5c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d60:	d3 e5                	shl    %cl,%ebp
  800d62:	39 c5                	cmp    %eax,%ebp
  800d64:	73 04                	jae    800d6a <__udivdi3+0x11a>
  800d66:	39 d6                	cmp    %edx,%esi
  800d68:	74 1e                	je     800d88 <__udivdi3+0x138>
  800d6a:	89 f8                	mov    %edi,%eax
  800d6c:	31 d2                	xor    %edx,%edx
  800d6e:	e9 69 ff ff ff       	jmp    800cdc <__udivdi3+0x8c>
  800d73:	90                   	nop
  800d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d78:	31 d2                	xor    %edx,%edx
  800d7a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d7f:	e9 58 ff ff ff       	jmp    800cdc <__udivdi3+0x8c>
  800d84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d88:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d8b:	31 d2                	xor    %edx,%edx
  800d8d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d91:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d95:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d99:	83 c4 1c             	add    $0x1c,%esp
  800d9c:	c3                   	ret    
  800d9d:	66 90                	xchg   %ax,%ax
  800d9f:	90                   	nop

00800da0 <__umoddi3>:
  800da0:	83 ec 2c             	sub    $0x2c,%esp
  800da3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800da7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800dab:	89 74 24 20          	mov    %esi,0x20(%esp)
  800daf:	8b 74 24 38          	mov    0x38(%esp),%esi
  800db3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800db7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800dbb:	85 c0                	test   %eax,%eax
  800dbd:	89 c2                	mov    %eax,%edx
  800dbf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800dc3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800dc7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dcb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800dcf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800dd3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800dd7:	75 1f                	jne    800df8 <__umoddi3+0x58>
  800dd9:	39 fe                	cmp    %edi,%esi
  800ddb:	76 63                	jbe    800e40 <__umoddi3+0xa0>
  800ddd:	89 c8                	mov    %ecx,%eax
  800ddf:	89 fa                	mov    %edi,%edx
  800de1:	f7 f6                	div    %esi
  800de3:	89 d0                	mov    %edx,%eax
  800de5:	31 d2                	xor    %edx,%edx
  800de7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800deb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800def:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800df3:	83 c4 2c             	add    $0x2c,%esp
  800df6:	c3                   	ret    
  800df7:	90                   	nop
  800df8:	39 f8                	cmp    %edi,%eax
  800dfa:	77 64                	ja     800e60 <__umoddi3+0xc0>
  800dfc:	0f bd e8             	bsr    %eax,%ebp
  800dff:	83 f5 1f             	xor    $0x1f,%ebp
  800e02:	75 74                	jne    800e78 <__umoddi3+0xd8>
  800e04:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e08:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800e0c:	0f 87 0e 01 00 00    	ja     800f20 <__umoddi3+0x180>
  800e12:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800e16:	29 f1                	sub    %esi,%ecx
  800e18:	19 c7                	sbb    %eax,%edi
  800e1a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800e1e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800e22:	8b 44 24 14          	mov    0x14(%esp),%eax
  800e26:	8b 54 24 18          	mov    0x18(%esp),%edx
  800e2a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e2e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e32:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e36:	83 c4 2c             	add    $0x2c,%esp
  800e39:	c3                   	ret    
  800e3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e40:	85 f6                	test   %esi,%esi
  800e42:	89 f5                	mov    %esi,%ebp
  800e44:	75 0b                	jne    800e51 <__umoddi3+0xb1>
  800e46:	b8 01 00 00 00       	mov    $0x1,%eax
  800e4b:	31 d2                	xor    %edx,%edx
  800e4d:	f7 f6                	div    %esi
  800e4f:	89 c5                	mov    %eax,%ebp
  800e51:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e55:	31 d2                	xor    %edx,%edx
  800e57:	f7 f5                	div    %ebp
  800e59:	89 c8                	mov    %ecx,%eax
  800e5b:	f7 f5                	div    %ebp
  800e5d:	eb 84                	jmp    800de3 <__umoddi3+0x43>
  800e5f:	90                   	nop
  800e60:	89 c8                	mov    %ecx,%eax
  800e62:	89 fa                	mov    %edi,%edx
  800e64:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e68:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e6c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e70:	83 c4 2c             	add    $0x2c,%esp
  800e73:	c3                   	ret    
  800e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e78:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e7c:	be 20 00 00 00       	mov    $0x20,%esi
  800e81:	89 e9                	mov    %ebp,%ecx
  800e83:	29 ee                	sub    %ebp,%esi
  800e85:	d3 e2                	shl    %cl,%edx
  800e87:	89 f1                	mov    %esi,%ecx
  800e89:	d3 e8                	shr    %cl,%eax
  800e8b:	89 e9                	mov    %ebp,%ecx
  800e8d:	09 d0                	or     %edx,%eax
  800e8f:	89 fa                	mov    %edi,%edx
  800e91:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e95:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e99:	d3 e0                	shl    %cl,%eax
  800e9b:	89 f1                	mov    %esi,%ecx
  800e9d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ea1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800ea5:	d3 ea                	shr    %cl,%edx
  800ea7:	89 e9                	mov    %ebp,%ecx
  800ea9:	d3 e7                	shl    %cl,%edi
  800eab:	89 f1                	mov    %esi,%ecx
  800ead:	d3 e8                	shr    %cl,%eax
  800eaf:	89 e9                	mov    %ebp,%ecx
  800eb1:	09 f8                	or     %edi,%eax
  800eb3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800eb7:	f7 74 24 0c          	divl   0xc(%esp)
  800ebb:	d3 e7                	shl    %cl,%edi
  800ebd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ec1:	89 d7                	mov    %edx,%edi
  800ec3:	f7 64 24 10          	mull   0x10(%esp)
  800ec7:	39 d7                	cmp    %edx,%edi
  800ec9:	89 c1                	mov    %eax,%ecx
  800ecb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800ecf:	72 3b                	jb     800f0c <__umoddi3+0x16c>
  800ed1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800ed5:	72 31                	jb     800f08 <__umoddi3+0x168>
  800ed7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800edb:	29 c8                	sub    %ecx,%eax
  800edd:	19 d7                	sbb    %edx,%edi
  800edf:	89 e9                	mov    %ebp,%ecx
  800ee1:	89 fa                	mov    %edi,%edx
  800ee3:	d3 e8                	shr    %cl,%eax
  800ee5:	89 f1                	mov    %esi,%ecx
  800ee7:	d3 e2                	shl    %cl,%edx
  800ee9:	89 e9                	mov    %ebp,%ecx
  800eeb:	09 d0                	or     %edx,%eax
  800eed:	89 fa                	mov    %edi,%edx
  800eef:	d3 ea                	shr    %cl,%edx
  800ef1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ef5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ef9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800efd:	83 c4 2c             	add    $0x2c,%esp
  800f00:	c3                   	ret    
  800f01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f08:	39 d7                	cmp    %edx,%edi
  800f0a:	75 cb                	jne    800ed7 <__umoddi3+0x137>
  800f0c:	8b 54 24 14          	mov    0x14(%esp),%edx
  800f10:	89 c1                	mov    %eax,%ecx
  800f12:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800f16:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800f1a:	eb bb                	jmp    800ed7 <__umoddi3+0x137>
  800f1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f20:	3b 44 24 18          	cmp    0x18(%esp),%eax
  800f24:	0f 82 e8 fe ff ff    	jb     800e12 <__umoddi3+0x72>
  800f2a:	e9 f3 fe ff ff       	jmp    800e22 <__umoddi3+0x82>
