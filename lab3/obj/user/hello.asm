
obj/user/hello：     文件格式 elf32-i386


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
  80002c:	e8 2e 00 00 00       	call   80005f <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("hello, world\n");
  800039:	c7 04 24 40 0f 80 00 	movl   $0x800f40,(%esp)
  800040:	e8 23 01 00 00       	call   800168 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800045:	a1 04 20 80 00       	mov    0x802004,%eax
  80004a:	8b 40 48             	mov    0x48(%eax),%eax
  80004d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800051:	c7 04 24 4e 0f 80 00 	movl   $0x800f4e,(%esp)
  800058:	e8 0b 01 00 00       	call   800168 <cprintf>
}
  80005d:	c9                   	leave  
  80005e:	c3                   	ret    

0080005f <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005f:	55                   	push   %ebp
  800060:	89 e5                	mov    %esp,%ebp
  800062:	83 ec 18             	sub    $0x18,%esp
  800065:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800068:	89 75 fc             	mov    %esi,-0x4(%ebp)
  80006b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80006e:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	thisenv = &envs[ENVX(sys_getenvid())];
  800071:	e8 62 0b 00 00       	call   800bd8 <sys_getenvid>
  800076:	25 ff 03 00 00       	and    $0x3ff,%eax
  80007b:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80007e:	c1 e0 05             	shl    $0x5,%eax
  800081:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800086:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80008b:	85 db                	test   %ebx,%ebx
  80008d:	7e 07                	jle    800096 <libmain+0x37>
		binaryname = argv[0];
  80008f:	8b 06                	mov    (%esi),%eax
  800091:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800096:	89 74 24 04          	mov    %esi,0x4(%esp)
  80009a:	89 1c 24             	mov    %ebx,(%esp)
  80009d:	e8 91 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000a2:	e8 0a 00 00 00       	call   8000b1 <exit>
}
  8000a7:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  8000aa:	8b 75 fc             	mov    -0x4(%ebp),%esi
  8000ad:	89 ec                	mov    %ebp,%esp
  8000af:	5d                   	pop    %ebp
  8000b0:	c3                   	ret    

008000b1 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000b1:	55                   	push   %ebp
  8000b2:	89 e5                	mov    %esp,%ebp
  8000b4:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000be:	e8 b8 0a 00 00       	call   800b7b <sys_env_destroy>
}
  8000c3:	c9                   	leave  
  8000c4:	c3                   	ret    

008000c5 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000c5:	55                   	push   %ebp
  8000c6:	89 e5                	mov    %esp,%ebp
  8000c8:	53                   	push   %ebx
  8000c9:	83 ec 14             	sub    $0x14,%esp
  8000cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000cf:	8b 03                	mov    (%ebx),%eax
  8000d1:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d4:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000d8:	83 c0 01             	add    $0x1,%eax
  8000db:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000dd:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000e2:	75 19                	jne    8000fd <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000e4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000eb:	00 
  8000ec:	8d 43 08             	lea    0x8(%ebx),%eax
  8000ef:	89 04 24             	mov    %eax,(%esp)
  8000f2:	e8 25 0a 00 00       	call   800b1c <sys_cputs>
		b->idx = 0;
  8000f7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000fd:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800101:	83 c4 14             	add    $0x14,%esp
  800104:	5b                   	pop    %ebx
  800105:	5d                   	pop    %ebp
  800106:	c3                   	ret    

00800107 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800107:	55                   	push   %ebp
  800108:	89 e5                	mov    %esp,%ebp
  80010a:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800110:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800117:	00 00 00 
	b.cnt = 0;
  80011a:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800121:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800124:	8b 45 0c             	mov    0xc(%ebp),%eax
  800127:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80012b:	8b 45 08             	mov    0x8(%ebp),%eax
  80012e:	89 44 24 08          	mov    %eax,0x8(%esp)
  800132:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800138:	89 44 24 04          	mov    %eax,0x4(%esp)
  80013c:	c7 04 24 c5 00 80 00 	movl   $0x8000c5,(%esp)
  800143:	e8 ad 01 00 00       	call   8002f5 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800148:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80014e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800152:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800158:	89 04 24             	mov    %eax,(%esp)
  80015b:	e8 bc 09 00 00       	call   800b1c <sys_cputs>

	return b.cnt;
}
  800160:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800166:	c9                   	leave  
  800167:	c3                   	ret    

00800168 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80016e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800171:	89 44 24 04          	mov    %eax,0x4(%esp)
  800175:	8b 45 08             	mov    0x8(%ebp),%eax
  800178:	89 04 24             	mov    %eax,(%esp)
  80017b:	e8 87 ff ff ff       	call   800107 <vcprintf>
	va_end(ap);

	return cnt;
}
  800180:	c9                   	leave  
  800181:	c3                   	ret    
  800182:	66 90                	xchg   %ax,%ax
  800184:	66 90                	xchg   %ax,%ax
  800186:	66 90                	xchg   %ax,%ax
  800188:	66 90                	xchg   %ax,%ax
  80018a:	66 90                	xchg   %ax,%ax
  80018c:	66 90                	xchg   %ax,%ax
  80018e:	66 90                	xchg   %ax,%ax

00800190 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800190:	55                   	push   %ebp
  800191:	89 e5                	mov    %esp,%ebp
  800193:	57                   	push   %edi
  800194:	56                   	push   %esi
  800195:	53                   	push   %ebx
  800196:	83 ec 4c             	sub    $0x4c,%esp
  800199:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80019c:	89 d7                	mov    %edx,%edi
  80019e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001a1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8001a4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8001a7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8001aa:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001ad:	85 db                	test   %ebx,%ebx
  8001af:	75 08                	jne    8001b9 <printnum+0x29>
  8001b1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001b4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8001b7:	77 6c                	ja     800225 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001b9:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8001bc:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8001c0:	83 ee 01             	sub    $0x1,%esi
  8001c3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001ca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001ce:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001d2:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001d6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001d9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8001dc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001e3:	00 
  8001e4:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8001e7:	89 1c 24             	mov    %ebx,(%esp)
  8001ea:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8001ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001f1:	e8 6a 0a 00 00       	call   800c60 <__udivdi3>
  8001f6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8001f9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8001fc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800200:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800204:	89 04 24             	mov    %eax,(%esp)
  800207:	89 54 24 04          	mov    %edx,0x4(%esp)
  80020b:	89 fa                	mov    %edi,%edx
  80020d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800210:	e8 7b ff ff ff       	call   800190 <printnum>
  800215:	eb 1b                	jmp    800232 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800217:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80021b:	8b 45 18             	mov    0x18(%ebp),%eax
  80021e:	89 04 24             	mov    %eax,(%esp)
  800221:	ff d3                	call   *%ebx
  800223:	eb 03                	jmp    800228 <printnum+0x98>
  800225:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
  800228:	83 ee 01             	sub    $0x1,%esi
  80022b:	85 f6                	test   %esi,%esi
  80022d:	7f e8                	jg     800217 <printnum+0x87>
  80022f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800232:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800236:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80023a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80023d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800241:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800248:	00 
  800249:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80024c:	89 1c 24             	mov    %ebx,(%esp)
  80024f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800252:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800256:	e8 55 0b 00 00       	call   800db0 <__umoddi3>
  80025b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80025f:	0f be 80 6f 0f 80 00 	movsbl 0x800f6f(%eax),%eax
  800266:	89 04 24             	mov    %eax,(%esp)
  800269:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80026c:	ff d0                	call   *%eax
}
  80026e:	83 c4 4c             	add    $0x4c,%esp
  800271:	5b                   	pop    %ebx
  800272:	5e                   	pop    %esi
  800273:	5f                   	pop    %edi
  800274:	5d                   	pop    %ebp
  800275:	c3                   	ret    

00800276 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800276:	55                   	push   %ebp
  800277:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800279:	83 fa 01             	cmp    $0x1,%edx
  80027c:	7e 0e                	jle    80028c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80027e:	8b 10                	mov    (%eax),%edx
  800280:	8d 4a 08             	lea    0x8(%edx),%ecx
  800283:	89 08                	mov    %ecx,(%eax)
  800285:	8b 02                	mov    (%edx),%eax
  800287:	8b 52 04             	mov    0x4(%edx),%edx
  80028a:	eb 22                	jmp    8002ae <getuint+0x38>
	else if (lflag)
  80028c:	85 d2                	test   %edx,%edx
  80028e:	74 10                	je     8002a0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800290:	8b 10                	mov    (%eax),%edx
  800292:	8d 4a 04             	lea    0x4(%edx),%ecx
  800295:	89 08                	mov    %ecx,(%eax)
  800297:	8b 02                	mov    (%edx),%eax
  800299:	ba 00 00 00 00       	mov    $0x0,%edx
  80029e:	eb 0e                	jmp    8002ae <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002a0:	8b 10                	mov    (%eax),%edx
  8002a2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002a5:	89 08                	mov    %ecx,(%eax)
  8002a7:	8b 02                	mov    (%edx),%eax
  8002a9:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002ae:	5d                   	pop    %ebp
  8002af:	c3                   	ret    

008002b0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002b0:	55                   	push   %ebp
  8002b1:	89 e5                	mov    %esp,%ebp
  8002b3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002b6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002ba:	8b 10                	mov    (%eax),%edx
  8002bc:	3b 50 04             	cmp    0x4(%eax),%edx
  8002bf:	73 0a                	jae    8002cb <sprintputch+0x1b>
		*b->buf++ = ch;
  8002c1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002c4:	88 0a                	mov    %cl,(%edx)
  8002c6:	83 c2 01             	add    $0x1,%edx
  8002c9:	89 10                	mov    %edx,(%eax)
}
  8002cb:	5d                   	pop    %ebp
  8002cc:	c3                   	ret    

008002cd <printfmt>:
{
  8002cd:	55                   	push   %ebp
  8002ce:	89 e5                	mov    %esp,%ebp
  8002d0:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
  8002d3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002da:	8b 45 10             	mov    0x10(%ebp),%eax
  8002dd:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8002eb:	89 04 24             	mov    %eax,(%esp)
  8002ee:	e8 02 00 00 00       	call   8002f5 <vprintfmt>
}
  8002f3:	c9                   	leave  
  8002f4:	c3                   	ret    

008002f5 <vprintfmt>:
{
  8002f5:	55                   	push   %ebp
  8002f6:	89 e5                	mov    %esp,%ebp
  8002f8:	57                   	push   %edi
  8002f9:	56                   	push   %esi
  8002fa:	53                   	push   %ebx
  8002fb:	83 ec 4c             	sub    $0x4c,%esp
  8002fe:	8b 75 08             	mov    0x8(%ebp),%esi
  800301:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800304:	8b 7d 10             	mov    0x10(%ebp),%edi
  800307:	eb 11                	jmp    80031a <vprintfmt+0x25>
			if (ch == '\0')
  800309:	85 c0                	test   %eax,%eax
  80030b:	0f 84 cf 03 00 00    	je     8006e0 <vprintfmt+0x3eb>
			putch(ch, putdat);
  800311:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800315:	89 04 24             	mov    %eax,(%esp)
  800318:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80031a:	0f b6 07             	movzbl (%edi),%eax
  80031d:	83 c7 01             	add    $0x1,%edi
  800320:	83 f8 25             	cmp    $0x25,%eax
  800323:	75 e4                	jne    800309 <vprintfmt+0x14>
  800325:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800329:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  800330:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800337:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80033e:	ba 00 00 00 00       	mov    $0x0,%edx
  800343:	eb 2b                	jmp    800370 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800345:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
  800348:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  80034c:	eb 22                	jmp    800370 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  80034e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
  800351:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800355:	eb 19                	jmp    800370 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800357:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
  80035a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800361:	eb 0d                	jmp    800370 <vprintfmt+0x7b>
				width = precision, precision = -1;
  800363:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800366:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800369:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800370:	0f b6 07             	movzbl (%edi),%eax
  800373:	8d 4f 01             	lea    0x1(%edi),%ecx
  800376:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800379:	0f b6 0f             	movzbl (%edi),%ecx
  80037c:	83 e9 23             	sub    $0x23,%ecx
  80037f:	80 f9 55             	cmp    $0x55,%cl
  800382:	0f 87 3b 03 00 00    	ja     8006c3 <vprintfmt+0x3ce>
  800388:	0f b6 c9             	movzbl %cl,%ecx
  80038b:	ff 24 8d 00 10 80 00 	jmp    *0x801000(,%ecx,4)
  800392:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800395:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  80039c:	89 55 e0             	mov    %edx,-0x20(%ebp)
  80039f:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
  8003a4:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8003a7:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8003ab:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8003ae:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003b1:	83 f9 09             	cmp    $0x9,%ecx
  8003b4:	77 2f                	ja     8003e5 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
  8003b6:	83 c7 01             	add    $0x1,%edi
			}
  8003b9:	eb e9                	jmp    8003a4 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
  8003bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003be:	8d 48 04             	lea    0x4(%eax),%ecx
  8003c1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003c4:	8b 00                	mov    (%eax),%eax
  8003c6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8003c9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
  8003cc:	eb 1d                	jmp    8003eb <vprintfmt+0xf6>
			if (width < 0)
  8003ce:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003d2:	78 83                	js     800357 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
  8003d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8003d7:	eb 97                	jmp    800370 <vprintfmt+0x7b>
  8003d9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
  8003dc:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8003e3:	eb 8b                	jmp    800370 <vprintfmt+0x7b>
  8003e5:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8003e8:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
  8003eb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8003ef:	0f 89 7b ff ff ff    	jns    800370 <vprintfmt+0x7b>
  8003f5:	e9 69 ff ff ff       	jmp    800363 <vprintfmt+0x6e>
			lflag++;
  8003fa:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
  8003fd:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
  800400:	e9 6b ff ff ff       	jmp    800370 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
  800405:	8b 45 14             	mov    0x14(%ebp),%eax
  800408:	8d 50 04             	lea    0x4(%eax),%edx
  80040b:	89 55 14             	mov    %edx,0x14(%ebp)
  80040e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800412:	8b 00                	mov    (%eax),%eax
  800414:	89 04 24             	mov    %eax,(%esp)
  800417:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  800419:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  80041c:	e9 f9 fe ff ff       	jmp    80031a <vprintfmt+0x25>
			err = va_arg(ap, int);
  800421:	8b 45 14             	mov    0x14(%ebp),%eax
  800424:	8d 50 04             	lea    0x4(%eax),%edx
  800427:	89 55 14             	mov    %edx,0x14(%ebp)
  80042a:	8b 00                	mov    (%eax),%eax
  80042c:	89 c2                	mov    %eax,%edx
  80042e:	c1 fa 1f             	sar    $0x1f,%edx
  800431:	31 d0                	xor    %edx,%eax
  800433:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800435:	83 f8 07             	cmp    $0x7,%eax
  800438:	7f 0b                	jg     800445 <vprintfmt+0x150>
  80043a:	8b 14 85 60 11 80 00 	mov    0x801160(,%eax,4),%edx
  800441:	85 d2                	test   %edx,%edx
  800443:	75 20                	jne    800465 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
  800445:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800449:	c7 44 24 08 87 0f 80 	movl   $0x800f87,0x8(%esp)
  800450:	00 
  800451:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800455:	89 34 24             	mov    %esi,(%esp)
  800458:	e8 70 fe ff ff       	call   8002cd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80045d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
  800460:	e9 b5 fe ff ff       	jmp    80031a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
  800465:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800469:	c7 44 24 08 90 0f 80 	movl   $0x800f90,0x8(%esp)
  800470:	00 
  800471:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800475:	89 34 24             	mov    %esi,(%esp)
  800478:	e8 50 fe ff ff       	call   8002cd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80047d:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800480:	e9 95 fe ff ff       	jmp    80031a <vprintfmt+0x25>
  800485:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800488:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80048b:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
  80048e:	8b 45 14             	mov    0x14(%ebp),%eax
  800491:	8d 50 04             	lea    0x4(%eax),%edx
  800494:	89 55 14             	mov    %edx,0x14(%ebp)
  800497:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800499:	85 ff                	test   %edi,%edi
  80049b:	b8 80 0f 80 00       	mov    $0x800f80,%eax
  8004a0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004a3:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8004a7:	0f 84 9b 00 00 00    	je     800548 <vprintfmt+0x253>
  8004ad:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8004b1:	0f 8e 9f 00 00 00    	jle    800556 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004bb:	89 3c 24             	mov    %edi,(%esp)
  8004be:	e8 c5 02 00 00       	call   800788 <strnlen>
  8004c3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8004c6:	29 c2                	sub    %eax,%edx
  8004c8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
  8004cb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8004cf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8004d2:	89 7d c8             	mov    %edi,-0x38(%ebp)
  8004d5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d7:	eb 0f                	jmp    8004e8 <vprintfmt+0x1f3>
					putch(padc, putdat);
  8004d9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004e0:	89 04 24             	mov    %eax,(%esp)
  8004e3:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e5:	83 ef 01             	sub    $0x1,%edi
  8004e8:	85 ff                	test   %edi,%edi
  8004ea:	7f ed                	jg     8004d9 <vprintfmt+0x1e4>
  8004ec:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8004ef:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004f3:	b8 00 00 00 00       	mov    $0x0,%eax
  8004f8:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
  8004fc:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8004ff:	29 c2                	sub    %eax,%edx
  800501:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800504:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800507:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80050a:	89 d3                	mov    %edx,%ebx
  80050c:	eb 54                	jmp    800562 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
  80050e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800512:	74 20                	je     800534 <vprintfmt+0x23f>
  800514:	0f be d2             	movsbl %dl,%edx
  800517:	83 ea 20             	sub    $0x20,%edx
  80051a:	83 fa 5e             	cmp    $0x5e,%edx
  80051d:	76 15                	jbe    800534 <vprintfmt+0x23f>
					putch('?', putdat);
  80051f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800522:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800526:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80052d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800530:	ff d0                	call   *%eax
  800532:	eb 0f                	jmp    800543 <vprintfmt+0x24e>
					putch(ch, putdat);
  800534:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800537:	89 54 24 04          	mov    %edx,0x4(%esp)
  80053b:	89 04 24             	mov    %eax,(%esp)
  80053e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800541:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800543:	83 eb 01             	sub    $0x1,%ebx
  800546:	eb 1a                	jmp    800562 <vprintfmt+0x26d>
  800548:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  80054b:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80054e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800551:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800554:	eb 0c                	jmp    800562 <vprintfmt+0x26d>
  800556:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800559:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80055c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80055f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800562:	0f b6 17             	movzbl (%edi),%edx
  800565:	0f be c2             	movsbl %dl,%eax
  800568:	83 c7 01             	add    $0x1,%edi
  80056b:	85 c0                	test   %eax,%eax
  80056d:	74 29                	je     800598 <vprintfmt+0x2a3>
  80056f:	85 f6                	test   %esi,%esi
  800571:	78 9b                	js     80050e <vprintfmt+0x219>
  800573:	83 ee 01             	sub    $0x1,%esi
  800576:	79 96                	jns    80050e <vprintfmt+0x219>
  800578:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80057b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80057e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800581:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800584:	eb 1a                	jmp    8005a0 <vprintfmt+0x2ab>
				putch(' ', putdat);
  800586:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80058a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800591:	ff d6                	call   *%esi
			for (; width > 0; width--)
  800593:	83 ef 01             	sub    $0x1,%edi
  800596:	eb 08                	jmp    8005a0 <vprintfmt+0x2ab>
  800598:	89 df                	mov    %ebx,%edi
  80059a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80059d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8005a0:	85 ff                	test   %edi,%edi
  8005a2:	7f e2                	jg     800586 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
  8005a4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005a7:	e9 6e fd ff ff       	jmp    80031a <vprintfmt+0x25>
	if (lflag >= 2)
  8005ac:	83 fa 01             	cmp    $0x1,%edx
  8005af:	7e 16                	jle    8005c7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
  8005b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b4:	8d 50 08             	lea    0x8(%eax),%edx
  8005b7:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ba:	8b 10                	mov    (%eax),%edx
  8005bc:	8b 48 04             	mov    0x4(%eax),%ecx
  8005bf:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8005c2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005c5:	eb 32                	jmp    8005f9 <vprintfmt+0x304>
	else if (lflag)
  8005c7:	85 d2                	test   %edx,%edx
  8005c9:	74 18                	je     8005e3 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
  8005cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ce:	8d 50 04             	lea    0x4(%eax),%edx
  8005d1:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d4:	8b 00                	mov    (%eax),%eax
  8005d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005d9:	89 c1                	mov    %eax,%ecx
  8005db:	c1 f9 1f             	sar    $0x1f,%ecx
  8005de:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8005e1:	eb 16                	jmp    8005f9 <vprintfmt+0x304>
		return va_arg(*ap, int);
  8005e3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e6:	8d 50 04             	lea    0x4(%eax),%edx
  8005e9:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ec:	8b 00                	mov    (%eax),%eax
  8005ee:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005f1:	89 c7                	mov    %eax,%edi
  8005f3:	c1 ff 1f             	sar    $0x1f,%edi
  8005f6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
  8005f9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005fc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
  8005ff:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
  800604:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800608:	79 7d                	jns    800687 <vprintfmt+0x392>
				putch('-', putdat);
  80060a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80060e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800615:	ff d6                	call   *%esi
				num = -(long long) num;
  800617:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80061a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80061d:	f7 d8                	neg    %eax
  80061f:	83 d2 00             	adc    $0x0,%edx
  800622:	f7 da                	neg    %edx
			base = 10;
  800624:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800629:	eb 5c                	jmp    800687 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80062b:	8d 45 14             	lea    0x14(%ebp),%eax
  80062e:	e8 43 fc ff ff       	call   800276 <getuint>
			base = 10;
  800633:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800638:	eb 4d                	jmp    800687 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80063a:	8d 45 14             	lea    0x14(%ebp),%eax
  80063d:	e8 34 fc ff ff       	call   800276 <getuint>
			base = 8;
  800642:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800647:	eb 3e                	jmp    800687 <vprintfmt+0x392>
			putch('0', putdat);
  800649:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80064d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800654:	ff d6                	call   *%esi
			putch('x', putdat);
  800656:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80065a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800661:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
  800663:	8b 45 14             	mov    0x14(%ebp),%eax
  800666:	8d 50 04             	lea    0x4(%eax),%edx
  800669:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
  80066c:	8b 00                	mov    (%eax),%eax
  80066e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
  800673:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800678:	eb 0d                	jmp    800687 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80067a:	8d 45 14             	lea    0x14(%ebp),%eax
  80067d:	e8 f4 fb ff ff       	call   800276 <getuint>
			base = 16;
  800682:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
  800687:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80068b:	89 7c 24 10          	mov    %edi,0x10(%esp)
  80068f:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800692:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800696:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80069a:	89 04 24             	mov    %eax,(%esp)
  80069d:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006a1:	89 da                	mov    %ebx,%edx
  8006a3:	89 f0                	mov    %esi,%eax
  8006a5:	e8 e6 fa ff ff       	call   800190 <printnum>
			break;
  8006aa:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006ad:	e9 68 fc ff ff       	jmp    80031a <vprintfmt+0x25>
			putch(ch, putdat);
  8006b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006b6:	89 04 24             	mov    %eax,(%esp)
  8006b9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  8006bb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  8006be:	e9 57 fc ff ff       	jmp    80031a <vprintfmt+0x25>
			putch('%', putdat);
  8006c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006c7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006ce:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d0:	eb 03                	jmp    8006d5 <vprintfmt+0x3e0>
  8006d2:	83 ef 01             	sub    $0x1,%edi
  8006d5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006d9:	75 f7                	jne    8006d2 <vprintfmt+0x3dd>
  8006db:	e9 3a fc ff ff       	jmp    80031a <vprintfmt+0x25>
}
  8006e0:	83 c4 4c             	add    $0x4c,%esp
  8006e3:	5b                   	pop    %ebx
  8006e4:	5e                   	pop    %esi
  8006e5:	5f                   	pop    %edi
  8006e6:	5d                   	pop    %ebp
  8006e7:	c3                   	ret    

008006e8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006e8:	55                   	push   %ebp
  8006e9:	89 e5                	mov    %esp,%ebp
  8006eb:	83 ec 28             	sub    $0x28,%esp
  8006ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006f7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006fb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800705:	85 d2                	test   %edx,%edx
  800707:	7e 30                	jle    800739 <vsnprintf+0x51>
  800709:	85 c0                	test   %eax,%eax
  80070b:	74 2c                	je     800739 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80070d:	8b 45 14             	mov    0x14(%ebp),%eax
  800710:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800714:	8b 45 10             	mov    0x10(%ebp),%eax
  800717:	89 44 24 08          	mov    %eax,0x8(%esp)
  80071b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80071e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800722:	c7 04 24 b0 02 80 00 	movl   $0x8002b0,(%esp)
  800729:	e8 c7 fb ff ff       	call   8002f5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80072e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800731:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800734:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800737:	eb 05                	jmp    80073e <vsnprintf+0x56>
		return -E_INVAL;
  800739:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  80073e:	c9                   	leave  
  80073f:	c3                   	ret    

00800740 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800740:	55                   	push   %ebp
  800741:	89 e5                	mov    %esp,%ebp
  800743:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800746:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800749:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80074d:	8b 45 10             	mov    0x10(%ebp),%eax
  800750:	89 44 24 08          	mov    %eax,0x8(%esp)
  800754:	8b 45 0c             	mov    0xc(%ebp),%eax
  800757:	89 44 24 04          	mov    %eax,0x4(%esp)
  80075b:	8b 45 08             	mov    0x8(%ebp),%eax
  80075e:	89 04 24             	mov    %eax,(%esp)
  800761:	e8 82 ff ff ff       	call   8006e8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800766:	c9                   	leave  
  800767:	c3                   	ret    
  800768:	66 90                	xchg   %ax,%ax
  80076a:	66 90                	xchg   %ax,%ax
  80076c:	66 90                	xchg   %ax,%ax
  80076e:	66 90                	xchg   %ax,%ax

00800770 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800770:	55                   	push   %ebp
  800771:	89 e5                	mov    %esp,%ebp
  800773:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800776:	b8 00 00 00 00       	mov    $0x0,%eax
  80077b:	eb 03                	jmp    800780 <strlen+0x10>
		n++;
  80077d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  800780:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800784:	75 f7                	jne    80077d <strlen+0xd>
	return n;
}
  800786:	5d                   	pop    %ebp
  800787:	c3                   	ret    

00800788 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800788:	55                   	push   %ebp
  800789:	89 e5                	mov    %esp,%ebp
  80078b:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
  80078e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800791:	b8 00 00 00 00       	mov    $0x0,%eax
  800796:	eb 03                	jmp    80079b <strnlen+0x13>
		n++;
  800798:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079b:	39 d0                	cmp    %edx,%eax
  80079d:	74 06                	je     8007a5 <strnlen+0x1d>
  80079f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8007a3:	75 f3                	jne    800798 <strnlen+0x10>
	return n;
}
  8007a5:	5d                   	pop    %ebp
  8007a6:	c3                   	ret    

008007a7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007a7:	55                   	push   %ebp
  8007a8:	89 e5                	mov    %esp,%ebp
  8007aa:	53                   	push   %ebx
  8007ab:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007b1:	89 c2                	mov    %eax,%edx
  8007b3:	0f b6 19             	movzbl (%ecx),%ebx
  8007b6:	88 1a                	mov    %bl,(%edx)
  8007b8:	83 c2 01             	add    $0x1,%edx
  8007bb:	83 c1 01             	add    $0x1,%ecx
  8007be:	84 db                	test   %bl,%bl
  8007c0:	75 f1                	jne    8007b3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007c2:	5b                   	pop    %ebx
  8007c3:	5d                   	pop    %ebp
  8007c4:	c3                   	ret    

008007c5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007c5:	55                   	push   %ebp
  8007c6:	89 e5                	mov    %esp,%ebp
  8007c8:	53                   	push   %ebx
  8007c9:	83 ec 08             	sub    $0x8,%esp
  8007cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007cf:	89 1c 24             	mov    %ebx,(%esp)
  8007d2:	e8 99 ff ff ff       	call   800770 <strlen>
	strcpy(dst + len, src);
  8007d7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007da:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007de:	01 d8                	add    %ebx,%eax
  8007e0:	89 04 24             	mov    %eax,(%esp)
  8007e3:	e8 bf ff ff ff       	call   8007a7 <strcpy>
	return dst;
}
  8007e8:	89 d8                	mov    %ebx,%eax
  8007ea:	83 c4 08             	add    $0x8,%esp
  8007ed:	5b                   	pop    %ebx
  8007ee:	5d                   	pop    %ebp
  8007ef:	c3                   	ret    

008007f0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007f0:	55                   	push   %ebp
  8007f1:	89 e5                	mov    %esp,%ebp
  8007f3:	56                   	push   %esi
  8007f4:	53                   	push   %ebx
  8007f5:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007fb:	89 f3                	mov    %esi,%ebx
  8007fd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800800:	89 f2                	mov    %esi,%edx
  800802:	eb 0e                	jmp    800812 <strncpy+0x22>
		*dst++ = *src;
  800804:	0f b6 01             	movzbl (%ecx),%eax
  800807:	88 02                	mov    %al,(%edx)
  800809:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80080c:	80 39 01             	cmpb   $0x1,(%ecx)
  80080f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800812:	39 da                	cmp    %ebx,%edx
  800814:	75 ee                	jne    800804 <strncpy+0x14>
	}
	return ret;
}
  800816:	89 f0                	mov    %esi,%eax
  800818:	5b                   	pop    %ebx
  800819:	5e                   	pop    %esi
  80081a:	5d                   	pop    %ebp
  80081b:	c3                   	ret    

0080081c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80081c:	55                   	push   %ebp
  80081d:	89 e5                	mov    %esp,%ebp
  80081f:	56                   	push   %esi
  800820:	53                   	push   %ebx
  800821:	8b 75 08             	mov    0x8(%ebp),%esi
  800824:	8b 55 0c             	mov    0xc(%ebp),%edx
  800827:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80082a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
  80082c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
  800830:	85 c9                	test   %ecx,%ecx
  800832:	75 0a                	jne    80083e <strlcpy+0x22>
  800834:	eb 1c                	jmp    800852 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800836:	88 08                	mov    %cl,(%eax)
  800838:	83 c0 01             	add    $0x1,%eax
  80083b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
  80083e:	39 d8                	cmp    %ebx,%eax
  800840:	74 0b                	je     80084d <strlcpy+0x31>
  800842:	0f b6 0a             	movzbl (%edx),%ecx
  800845:	84 c9                	test   %cl,%cl
  800847:	75 ed                	jne    800836 <strlcpy+0x1a>
  800849:	89 c2                	mov    %eax,%edx
  80084b:	eb 02                	jmp    80084f <strlcpy+0x33>
  80084d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
  80084f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800852:	29 f0                	sub    %esi,%eax
}
  800854:	5b                   	pop    %ebx
  800855:	5e                   	pop    %esi
  800856:	5d                   	pop    %ebp
  800857:	c3                   	ret    

00800858 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800858:	55                   	push   %ebp
  800859:	89 e5                	mov    %esp,%ebp
  80085b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80085e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800861:	eb 06                	jmp    800869 <strcmp+0x11>
		p++, q++;
  800863:	83 c1 01             	add    $0x1,%ecx
  800866:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800869:	0f b6 01             	movzbl (%ecx),%eax
  80086c:	84 c0                	test   %al,%al
  80086e:	74 04                	je     800874 <strcmp+0x1c>
  800870:	3a 02                	cmp    (%edx),%al
  800872:	74 ef                	je     800863 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800874:	0f b6 c0             	movzbl %al,%eax
  800877:	0f b6 12             	movzbl (%edx),%edx
  80087a:	29 d0                	sub    %edx,%eax
}
  80087c:	5d                   	pop    %ebp
  80087d:	c3                   	ret    

0080087e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80087e:	55                   	push   %ebp
  80087f:	89 e5                	mov    %esp,%ebp
  800881:	53                   	push   %ebx
  800882:	8b 45 08             	mov    0x8(%ebp),%eax
  800885:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
  800888:	89 c3                	mov    %eax,%ebx
  80088a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80088d:	eb 06                	jmp    800895 <strncmp+0x17>
		n--, p++, q++;
  80088f:	83 c0 01             	add    $0x1,%eax
  800892:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  800895:	39 d8                	cmp    %ebx,%eax
  800897:	74 15                	je     8008ae <strncmp+0x30>
  800899:	0f b6 08             	movzbl (%eax),%ecx
  80089c:	84 c9                	test   %cl,%cl
  80089e:	74 04                	je     8008a4 <strncmp+0x26>
  8008a0:	3a 0a                	cmp    (%edx),%cl
  8008a2:	74 eb                	je     80088f <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008a4:	0f b6 00             	movzbl (%eax),%eax
  8008a7:	0f b6 12             	movzbl (%edx),%edx
  8008aa:	29 d0                	sub    %edx,%eax
  8008ac:	eb 05                	jmp    8008b3 <strncmp+0x35>
		return 0;
  8008ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b3:	5b                   	pop    %ebx
  8008b4:	5d                   	pop    %ebp
  8008b5:	c3                   	ret    

008008b6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008b6:	55                   	push   %ebp
  8008b7:	89 e5                	mov    %esp,%ebp
  8008b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c0:	eb 07                	jmp    8008c9 <strchr+0x13>
		if (*s == c)
  8008c2:	38 ca                	cmp    %cl,%dl
  8008c4:	74 0f                	je     8008d5 <strchr+0x1f>
	for (; *s; s++)
  8008c6:	83 c0 01             	add    $0x1,%eax
  8008c9:	0f b6 10             	movzbl (%eax),%edx
  8008cc:	84 d2                	test   %dl,%dl
  8008ce:	75 f2                	jne    8008c2 <strchr+0xc>
			return (char *) s;
	return 0;
  8008d0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	8b 45 08             	mov    0x8(%ebp),%eax
  8008dd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008e1:	eb 07                	jmp    8008ea <strfind+0x13>
		if (*s == c)
  8008e3:	38 ca                	cmp    %cl,%dl
  8008e5:	74 0a                	je     8008f1 <strfind+0x1a>
	for (; *s; s++)
  8008e7:	83 c0 01             	add    $0x1,%eax
  8008ea:	0f b6 10             	movzbl (%eax),%edx
  8008ed:	84 d2                	test   %dl,%dl
  8008ef:	75 f2                	jne    8008e3 <strfind+0xc>
			break;
	return (char *) s;
}
  8008f1:	5d                   	pop    %ebp
  8008f2:	c3                   	ret    

008008f3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008f3:	55                   	push   %ebp
  8008f4:	89 e5                	mov    %esp,%ebp
  8008f6:	83 ec 0c             	sub    $0xc,%esp
  8008f9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8008fc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8008ff:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800902:	8b 7d 08             	mov    0x8(%ebp),%edi
  800905:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800908:	85 c9                	test   %ecx,%ecx
  80090a:	74 36                	je     800942 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80090c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800912:	75 28                	jne    80093c <memset+0x49>
  800914:	f6 c1 03             	test   $0x3,%cl
  800917:	75 23                	jne    80093c <memset+0x49>
		c &= 0xFF;
  800919:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80091d:	89 d3                	mov    %edx,%ebx
  80091f:	c1 e3 08             	shl    $0x8,%ebx
  800922:	89 d6                	mov    %edx,%esi
  800924:	c1 e6 18             	shl    $0x18,%esi
  800927:	89 d0                	mov    %edx,%eax
  800929:	c1 e0 10             	shl    $0x10,%eax
  80092c:	09 f0                	or     %esi,%eax
  80092e:	09 c2                	or     %eax,%edx
  800930:	89 d0                	mov    %edx,%eax
  800932:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800934:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800937:	fc                   	cld    
  800938:	f3 ab                	rep stos %eax,%es:(%edi)
  80093a:	eb 06                	jmp    800942 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80093c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80093f:	fc                   	cld    
  800940:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800942:	89 f8                	mov    %edi,%eax
  800944:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800947:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80094a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80094d:	89 ec                	mov    %ebp,%esp
  80094f:	5d                   	pop    %ebp
  800950:	c3                   	ret    

00800951 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800951:	55                   	push   %ebp
  800952:	89 e5                	mov    %esp,%ebp
  800954:	83 ec 08             	sub    $0x8,%esp
  800957:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80095a:	89 7d fc             	mov    %edi,-0x4(%ebp)
  80095d:	8b 45 08             	mov    0x8(%ebp),%eax
  800960:	8b 75 0c             	mov    0xc(%ebp),%esi
  800963:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800966:	39 c6                	cmp    %eax,%esi
  800968:	73 36                	jae    8009a0 <memmove+0x4f>
  80096a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80096d:	39 d0                	cmp    %edx,%eax
  80096f:	73 2f                	jae    8009a0 <memmove+0x4f>
		s += n;
		d += n;
  800971:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800974:	f6 c2 03             	test   $0x3,%dl
  800977:	75 1b                	jne    800994 <memmove+0x43>
  800979:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80097f:	75 13                	jne    800994 <memmove+0x43>
  800981:	f6 c1 03             	test   $0x3,%cl
  800984:	75 0e                	jne    800994 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800986:	83 ef 04             	sub    $0x4,%edi
  800989:	8d 72 fc             	lea    -0x4(%edx),%esi
  80098c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  80098f:	fd                   	std    
  800990:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800992:	eb 09                	jmp    80099d <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800994:	83 ef 01             	sub    $0x1,%edi
  800997:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  80099a:	fd                   	std    
  80099b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80099d:	fc                   	cld    
  80099e:	eb 20                	jmp    8009c0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009a0:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009a6:	75 13                	jne    8009bb <memmove+0x6a>
  8009a8:	a8 03                	test   $0x3,%al
  8009aa:	75 0f                	jne    8009bb <memmove+0x6a>
  8009ac:	f6 c1 03             	test   $0x3,%cl
  8009af:	75 0a                	jne    8009bb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  8009b1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  8009b4:	89 c7                	mov    %eax,%edi
  8009b6:	fc                   	cld    
  8009b7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009b9:	eb 05                	jmp    8009c0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
  8009bb:	89 c7                	mov    %eax,%edi
  8009bd:	fc                   	cld    
  8009be:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009c0:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8009c3:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8009c6:	89 ec                	mov    %ebp,%esp
  8009c8:	5d                   	pop    %ebp
  8009c9:	c3                   	ret    

008009ca <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009ca:	55                   	push   %ebp
  8009cb:	89 e5                	mov    %esp,%ebp
  8009cd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  8009d0:	8b 45 10             	mov    0x10(%ebp),%eax
  8009d3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009da:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009de:	8b 45 08             	mov    0x8(%ebp),%eax
  8009e1:	89 04 24             	mov    %eax,(%esp)
  8009e4:	e8 68 ff ff ff       	call   800951 <memmove>
}
  8009e9:	c9                   	leave  
  8009ea:	c3                   	ret    

008009eb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009eb:	55                   	push   %ebp
  8009ec:	89 e5                	mov    %esp,%ebp
  8009ee:	56                   	push   %esi
  8009ef:	53                   	push   %ebx
  8009f0:	8b 55 08             	mov    0x8(%ebp),%edx
  8009f3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
  8009f6:	89 d6                	mov    %edx,%esi
  8009f8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009fb:	eb 1a                	jmp    800a17 <memcmp+0x2c>
		if (*s1 != *s2)
  8009fd:	0f b6 02             	movzbl (%edx),%eax
  800a00:	0f b6 19             	movzbl (%ecx),%ebx
  800a03:	38 d8                	cmp    %bl,%al
  800a05:	74 0a                	je     800a11 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a07:	0f b6 c0             	movzbl %al,%eax
  800a0a:	0f b6 db             	movzbl %bl,%ebx
  800a0d:	29 d8                	sub    %ebx,%eax
  800a0f:	eb 0f                	jmp    800a20 <memcmp+0x35>
		s1++, s2++;
  800a11:	83 c2 01             	add    $0x1,%edx
  800a14:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
  800a17:	39 f2                	cmp    %esi,%edx
  800a19:	75 e2                	jne    8009fd <memcmp+0x12>
	}

	return 0;
  800a1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a20:	5b                   	pop    %ebx
  800a21:	5e                   	pop    %esi
  800a22:	5d                   	pop    %ebp
  800a23:	c3                   	ret    

00800a24 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a24:	55                   	push   %ebp
  800a25:	89 e5                	mov    %esp,%ebp
  800a27:	8b 45 08             	mov    0x8(%ebp),%eax
  800a2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a2d:	89 c2                	mov    %eax,%edx
  800a2f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a32:	eb 07                	jmp    800a3b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a34:	38 08                	cmp    %cl,(%eax)
  800a36:	74 07                	je     800a3f <memfind+0x1b>
	for (; s < ends; s++)
  800a38:	83 c0 01             	add    $0x1,%eax
  800a3b:	39 d0                	cmp    %edx,%eax
  800a3d:	72 f5                	jb     800a34 <memfind+0x10>
			break;
	return (void *) s;
}
  800a3f:	5d                   	pop    %ebp
  800a40:	c3                   	ret    

00800a41 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a41:	55                   	push   %ebp
  800a42:	89 e5                	mov    %esp,%ebp
  800a44:	57                   	push   %edi
  800a45:	56                   	push   %esi
  800a46:	53                   	push   %ebx
  800a47:	83 ec 04             	sub    $0x4,%esp
  800a4a:	8b 55 08             	mov    0x8(%ebp),%edx
  800a4d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a50:	eb 03                	jmp    800a55 <strtol+0x14>
		s++;
  800a52:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
  800a55:	0f b6 02             	movzbl (%edx),%eax
  800a58:	3c 09                	cmp    $0x9,%al
  800a5a:	74 f6                	je     800a52 <strtol+0x11>
  800a5c:	3c 20                	cmp    $0x20,%al
  800a5e:	74 f2                	je     800a52 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
  800a60:	3c 2b                	cmp    $0x2b,%al
  800a62:	75 0a                	jne    800a6e <strtol+0x2d>
		s++;
  800a64:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
  800a67:	bf 00 00 00 00       	mov    $0x0,%edi
  800a6c:	eb 10                	jmp    800a7e <strtol+0x3d>
  800a6e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
  800a73:	3c 2d                	cmp    $0x2d,%al
  800a75:	75 07                	jne    800a7e <strtol+0x3d>
		s++, neg = 1;
  800a77:	8d 52 01             	lea    0x1(%edx),%edx
  800a7a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a7e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a84:	75 15                	jne    800a9b <strtol+0x5a>
  800a86:	80 3a 30             	cmpb   $0x30,(%edx)
  800a89:	75 10                	jne    800a9b <strtol+0x5a>
  800a8b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a8f:	75 0a                	jne    800a9b <strtol+0x5a>
		s += 2, base = 16;
  800a91:	83 c2 02             	add    $0x2,%edx
  800a94:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a99:	eb 10                	jmp    800aab <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a9b:	85 db                	test   %ebx,%ebx
  800a9d:	75 0c                	jne    800aab <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a9f:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
  800aa1:	80 3a 30             	cmpb   $0x30,(%edx)
  800aa4:	75 05                	jne    800aab <strtol+0x6a>
		s++, base = 8;
  800aa6:	83 c2 01             	add    $0x1,%edx
  800aa9:	b3 08                	mov    $0x8,%bl
		base = 10;
  800aab:	b8 00 00 00 00       	mov    $0x0,%eax
  800ab0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ab3:	0f b6 0a             	movzbl (%edx),%ecx
  800ab6:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800ab9:	89 f3                	mov    %esi,%ebx
  800abb:	80 fb 09             	cmp    $0x9,%bl
  800abe:	77 08                	ja     800ac8 <strtol+0x87>
			dig = *s - '0';
  800ac0:	0f be c9             	movsbl %cl,%ecx
  800ac3:	83 e9 30             	sub    $0x30,%ecx
  800ac6:	eb 22                	jmp    800aea <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
  800ac8:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800acb:	89 f3                	mov    %esi,%ebx
  800acd:	80 fb 19             	cmp    $0x19,%bl
  800ad0:	77 08                	ja     800ada <strtol+0x99>
			dig = *s - 'a' + 10;
  800ad2:	0f be c9             	movsbl %cl,%ecx
  800ad5:	83 e9 57             	sub    $0x57,%ecx
  800ad8:	eb 10                	jmp    800aea <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
  800ada:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800add:	89 f3                	mov    %esi,%ebx
  800adf:	80 fb 19             	cmp    $0x19,%bl
  800ae2:	77 16                	ja     800afa <strtol+0xb9>
			dig = *s - 'A' + 10;
  800ae4:	0f be c9             	movsbl %cl,%ecx
  800ae7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800aea:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800aed:	7d 0f                	jge    800afe <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aef:	83 c2 01             	add    $0x1,%edx
  800af2:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800af6:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800af8:	eb b9                	jmp    800ab3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
  800afa:	89 c1                	mov    %eax,%ecx
  800afc:	eb 02                	jmp    800b00 <strtol+0xbf>
		if (dig >= base)
  800afe:	89 c1                	mov    %eax,%ecx

	if (endptr)
  800b00:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b04:	74 05                	je     800b0b <strtol+0xca>
		*endptr = (char *) s;
  800b06:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800b09:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800b0b:	89 ca                	mov    %ecx,%edx
  800b0d:	f7 da                	neg    %edx
  800b0f:	85 ff                	test   %edi,%edi
  800b11:	0f 45 c2             	cmovne %edx,%eax
}
  800b14:	83 c4 04             	add    $0x4,%esp
  800b17:	5b                   	pop    %ebx
  800b18:	5e                   	pop    %esi
  800b19:	5f                   	pop    %edi
  800b1a:	5d                   	pop    %ebp
  800b1b:	c3                   	ret    

00800b1c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b1c:	55                   	push   %ebp
  800b1d:	89 e5                	mov    %esp,%ebp
  800b1f:	83 ec 0c             	sub    $0xc,%esp
  800b22:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b25:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b28:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800b2b:	b8 00 00 00 00       	mov    $0x0,%eax
  800b30:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b33:	8b 55 08             	mov    0x8(%ebp),%edx
  800b36:	89 c3                	mov    %eax,%ebx
  800b38:	89 c7                	mov    %eax,%edi
  800b3a:	89 c6                	mov    %eax,%esi
  800b3c:	cd 30                	int    $0x30
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b3e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b41:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b44:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b47:	89 ec                	mov    %ebp,%esp
  800b49:	5d                   	pop    %ebp
  800b4a:	c3                   	ret    

00800b4b <sys_cgetc>:

int
sys_cgetc(void)
{
  800b4b:	55                   	push   %ebp
  800b4c:	89 e5                	mov    %esp,%ebp
  800b4e:	83 ec 0c             	sub    $0xc,%esp
  800b51:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b54:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b57:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800b5a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b5f:	b8 01 00 00 00       	mov    $0x1,%eax
  800b64:	89 d1                	mov    %edx,%ecx
  800b66:	89 d3                	mov    %edx,%ebx
  800b68:	89 d7                	mov    %edx,%edi
  800b6a:	89 d6                	mov    %edx,%esi
  800b6c:	cd 30                	int    $0x30
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b6e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b71:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b74:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b77:	89 ec                	mov    %ebp,%esp
  800b79:	5d                   	pop    %ebp
  800b7a:	c3                   	ret    

00800b7b <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b7b:	55                   	push   %ebp
  800b7c:	89 e5                	mov    %esp,%ebp
  800b7e:	83 ec 38             	sub    $0x38,%esp
  800b81:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b84:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b87:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800b8a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b8f:	b8 03 00 00 00       	mov    $0x3,%eax
  800b94:	8b 55 08             	mov    0x8(%ebp),%edx
  800b97:	89 cb                	mov    %ecx,%ebx
  800b99:	89 cf                	mov    %ecx,%edi
  800b9b:	89 ce                	mov    %ecx,%esi
  800b9d:	cd 30                	int    $0x30
	if(check && ret > 0)
  800b9f:	85 c0                	test   %eax,%eax
  800ba1:	7e 28                	jle    800bcb <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ba3:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ba7:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800bae:	00 
  800baf:	c7 44 24 08 80 11 80 	movl   $0x801180,0x8(%esp)
  800bb6:	00 
  800bb7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800bbe:	00 
  800bbf:	c7 04 24 9d 11 80 00 	movl   $0x80119d,(%esp)
  800bc6:	e8 3d 00 00 00       	call   800c08 <_panic>
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bcb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800bce:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bd1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bd4:	89 ec                	mov    %ebp,%esp
  800bd6:	5d                   	pop    %ebp
  800bd7:	c3                   	ret    

00800bd8 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bd8:	55                   	push   %ebp
  800bd9:	89 e5                	mov    %esp,%ebp
  800bdb:	83 ec 0c             	sub    $0xc,%esp
  800bde:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800be1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800be4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800be7:	ba 00 00 00 00       	mov    $0x0,%edx
  800bec:	b8 02 00 00 00       	mov    $0x2,%eax
  800bf1:	89 d1                	mov    %edx,%ecx
  800bf3:	89 d3                	mov    %edx,%ebx
  800bf5:	89 d7                	mov    %edx,%edi
  800bf7:	89 d6                	mov    %edx,%esi
  800bf9:	cd 30                	int    $0x30
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800bfb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800bfe:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c01:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c04:	89 ec                	mov    %ebp,%esp
  800c06:	5d                   	pop    %ebp
  800c07:	c3                   	ret    

00800c08 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800c08:	55                   	push   %ebp
  800c09:	89 e5                	mov    %esp,%ebp
  800c0b:	56                   	push   %esi
  800c0c:	53                   	push   %ebx
  800c0d:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800c10:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800c13:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800c19:	e8 ba ff ff ff       	call   800bd8 <sys_getenvid>
  800c1e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c21:	89 54 24 10          	mov    %edx,0x10(%esp)
  800c25:	8b 55 08             	mov    0x8(%ebp),%edx
  800c28:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c2c:	89 74 24 08          	mov    %esi,0x8(%esp)
  800c30:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c34:	c7 04 24 ac 11 80 00 	movl   $0x8011ac,(%esp)
  800c3b:	e8 28 f5 ff ff       	call   800168 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c40:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c44:	8b 45 10             	mov    0x10(%ebp),%eax
  800c47:	89 04 24             	mov    %eax,(%esp)
  800c4a:	e8 b8 f4 ff ff       	call   800107 <vcprintf>
	cprintf("\n");
  800c4f:	c7 04 24 4c 0f 80 00 	movl   $0x800f4c,(%esp)
  800c56:	e8 0d f5 ff ff       	call   800168 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c5b:	cc                   	int3   
  800c5c:	eb fd                	jmp    800c5b <_panic+0x53>
  800c5e:	66 90                	xchg   %ax,%ax

00800c60 <__udivdi3>:
  800c60:	83 ec 1c             	sub    $0x1c,%esp
  800c63:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800c67:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800c6b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c6f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c73:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800c77:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800c7b:	85 c0                	test   %eax,%eax
  800c7d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c81:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c85:	89 ea                	mov    %ebp,%edx
  800c87:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c8b:	75 33                	jne    800cc0 <__udivdi3+0x60>
  800c8d:	39 e9                	cmp    %ebp,%ecx
  800c8f:	77 6f                	ja     800d00 <__udivdi3+0xa0>
  800c91:	85 c9                	test   %ecx,%ecx
  800c93:	89 ce                	mov    %ecx,%esi
  800c95:	75 0b                	jne    800ca2 <__udivdi3+0x42>
  800c97:	b8 01 00 00 00       	mov    $0x1,%eax
  800c9c:	31 d2                	xor    %edx,%edx
  800c9e:	f7 f1                	div    %ecx
  800ca0:	89 c6                	mov    %eax,%esi
  800ca2:	31 d2                	xor    %edx,%edx
  800ca4:	89 e8                	mov    %ebp,%eax
  800ca6:	f7 f6                	div    %esi
  800ca8:	89 c5                	mov    %eax,%ebp
  800caa:	89 f8                	mov    %edi,%eax
  800cac:	f7 f6                	div    %esi
  800cae:	89 ea                	mov    %ebp,%edx
  800cb0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cb4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cb8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800cbc:	83 c4 1c             	add    $0x1c,%esp
  800cbf:	c3                   	ret    
  800cc0:	39 e8                	cmp    %ebp,%eax
  800cc2:	77 24                	ja     800ce8 <__udivdi3+0x88>
  800cc4:	0f bd c8             	bsr    %eax,%ecx
  800cc7:	83 f1 1f             	xor    $0x1f,%ecx
  800cca:	89 0c 24             	mov    %ecx,(%esp)
  800ccd:	75 49                	jne    800d18 <__udivdi3+0xb8>
  800ccf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cd3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800cd7:	0f 86 ab 00 00 00    	jbe    800d88 <__udivdi3+0x128>
  800cdd:	39 e8                	cmp    %ebp,%eax
  800cdf:	0f 82 a3 00 00 00    	jb     800d88 <__udivdi3+0x128>
  800ce5:	8d 76 00             	lea    0x0(%esi),%esi
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	31 c0                	xor    %eax,%eax
  800cec:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cf0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cf4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800cf8:	83 c4 1c             	add    $0x1c,%esp
  800cfb:	c3                   	ret    
  800cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d00:	89 f8                	mov    %edi,%eax
  800d02:	f7 f1                	div    %ecx
  800d04:	31 d2                	xor    %edx,%edx
  800d06:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d0a:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d0e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d12:	83 c4 1c             	add    $0x1c,%esp
  800d15:	c3                   	ret    
  800d16:	66 90                	xchg   %ax,%ax
  800d18:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d1c:	89 c6                	mov    %eax,%esi
  800d1e:	b8 20 00 00 00       	mov    $0x20,%eax
  800d23:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800d27:	2b 04 24             	sub    (%esp),%eax
  800d2a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d2e:	d3 e6                	shl    %cl,%esi
  800d30:	89 c1                	mov    %eax,%ecx
  800d32:	d3 ed                	shr    %cl,%ebp
  800d34:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d38:	09 f5                	or     %esi,%ebp
  800d3a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d3e:	d3 e6                	shl    %cl,%esi
  800d40:	89 c1                	mov    %eax,%ecx
  800d42:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d46:	89 d6                	mov    %edx,%esi
  800d48:	d3 ee                	shr    %cl,%esi
  800d4a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d4e:	d3 e2                	shl    %cl,%edx
  800d50:	89 c1                	mov    %eax,%ecx
  800d52:	d3 ef                	shr    %cl,%edi
  800d54:	09 d7                	or     %edx,%edi
  800d56:	89 f2                	mov    %esi,%edx
  800d58:	89 f8                	mov    %edi,%eax
  800d5a:	f7 f5                	div    %ebp
  800d5c:	89 d6                	mov    %edx,%esi
  800d5e:	89 c7                	mov    %eax,%edi
  800d60:	f7 64 24 04          	mull   0x4(%esp)
  800d64:	39 d6                	cmp    %edx,%esi
  800d66:	72 30                	jb     800d98 <__udivdi3+0x138>
  800d68:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800d6c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d70:	d3 e5                	shl    %cl,%ebp
  800d72:	39 c5                	cmp    %eax,%ebp
  800d74:	73 04                	jae    800d7a <__udivdi3+0x11a>
  800d76:	39 d6                	cmp    %edx,%esi
  800d78:	74 1e                	je     800d98 <__udivdi3+0x138>
  800d7a:	89 f8                	mov    %edi,%eax
  800d7c:	31 d2                	xor    %edx,%edx
  800d7e:	e9 69 ff ff ff       	jmp    800cec <__udivdi3+0x8c>
  800d83:	90                   	nop
  800d84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d88:	31 d2                	xor    %edx,%edx
  800d8a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d8f:	e9 58 ff ff ff       	jmp    800cec <__udivdi3+0x8c>
  800d94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d98:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d9b:	31 d2                	xor    %edx,%edx
  800d9d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800da1:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800da5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800da9:	83 c4 1c             	add    $0x1c,%esp
  800dac:	c3                   	ret    
  800dad:	66 90                	xchg   %ax,%ax
  800daf:	90                   	nop

00800db0 <__umoddi3>:
  800db0:	83 ec 2c             	sub    $0x2c,%esp
  800db3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800db7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800dbb:	89 74 24 20          	mov    %esi,0x20(%esp)
  800dbf:	8b 74 24 38          	mov    0x38(%esp),%esi
  800dc3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800dc7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800dcb:	85 c0                	test   %eax,%eax
  800dcd:	89 c2                	mov    %eax,%edx
  800dcf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800dd3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800dd7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ddb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800ddf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800de3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800de7:	75 1f                	jne    800e08 <__umoddi3+0x58>
  800de9:	39 fe                	cmp    %edi,%esi
  800deb:	76 63                	jbe    800e50 <__umoddi3+0xa0>
  800ded:	89 c8                	mov    %ecx,%eax
  800def:	89 fa                	mov    %edi,%edx
  800df1:	f7 f6                	div    %esi
  800df3:	89 d0                	mov    %edx,%eax
  800df5:	31 d2                	xor    %edx,%edx
  800df7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800dfb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800dff:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e03:	83 c4 2c             	add    $0x2c,%esp
  800e06:	c3                   	ret    
  800e07:	90                   	nop
  800e08:	39 f8                	cmp    %edi,%eax
  800e0a:	77 64                	ja     800e70 <__umoddi3+0xc0>
  800e0c:	0f bd e8             	bsr    %eax,%ebp
  800e0f:	83 f5 1f             	xor    $0x1f,%ebp
  800e12:	75 74                	jne    800e88 <__umoddi3+0xd8>
  800e14:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e18:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800e1c:	0f 87 0e 01 00 00    	ja     800f30 <__umoddi3+0x180>
  800e22:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800e26:	29 f1                	sub    %esi,%ecx
  800e28:	19 c7                	sbb    %eax,%edi
  800e2a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800e2e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800e32:	8b 44 24 14          	mov    0x14(%esp),%eax
  800e36:	8b 54 24 18          	mov    0x18(%esp),%edx
  800e3a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e3e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e42:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e46:	83 c4 2c             	add    $0x2c,%esp
  800e49:	c3                   	ret    
  800e4a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e50:	85 f6                	test   %esi,%esi
  800e52:	89 f5                	mov    %esi,%ebp
  800e54:	75 0b                	jne    800e61 <__umoddi3+0xb1>
  800e56:	b8 01 00 00 00       	mov    $0x1,%eax
  800e5b:	31 d2                	xor    %edx,%edx
  800e5d:	f7 f6                	div    %esi
  800e5f:	89 c5                	mov    %eax,%ebp
  800e61:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e65:	31 d2                	xor    %edx,%edx
  800e67:	f7 f5                	div    %ebp
  800e69:	89 c8                	mov    %ecx,%eax
  800e6b:	f7 f5                	div    %ebp
  800e6d:	eb 84                	jmp    800df3 <__umoddi3+0x43>
  800e6f:	90                   	nop
  800e70:	89 c8                	mov    %ecx,%eax
  800e72:	89 fa                	mov    %edi,%edx
  800e74:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e78:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e7c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e80:	83 c4 2c             	add    $0x2c,%esp
  800e83:	c3                   	ret    
  800e84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e88:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e8c:	be 20 00 00 00       	mov    $0x20,%esi
  800e91:	89 e9                	mov    %ebp,%ecx
  800e93:	29 ee                	sub    %ebp,%esi
  800e95:	d3 e2                	shl    %cl,%edx
  800e97:	89 f1                	mov    %esi,%ecx
  800e99:	d3 e8                	shr    %cl,%eax
  800e9b:	89 e9                	mov    %ebp,%ecx
  800e9d:	09 d0                	or     %edx,%eax
  800e9f:	89 fa                	mov    %edi,%edx
  800ea1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ea5:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ea9:	d3 e0                	shl    %cl,%eax
  800eab:	89 f1                	mov    %esi,%ecx
  800ead:	89 44 24 10          	mov    %eax,0x10(%esp)
  800eb1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800eb5:	d3 ea                	shr    %cl,%edx
  800eb7:	89 e9                	mov    %ebp,%ecx
  800eb9:	d3 e7                	shl    %cl,%edi
  800ebb:	89 f1                	mov    %esi,%ecx
  800ebd:	d3 e8                	shr    %cl,%eax
  800ebf:	89 e9                	mov    %ebp,%ecx
  800ec1:	09 f8                	or     %edi,%eax
  800ec3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800ec7:	f7 74 24 0c          	divl   0xc(%esp)
  800ecb:	d3 e7                	shl    %cl,%edi
  800ecd:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ed1:	89 d7                	mov    %edx,%edi
  800ed3:	f7 64 24 10          	mull   0x10(%esp)
  800ed7:	39 d7                	cmp    %edx,%edi
  800ed9:	89 c1                	mov    %eax,%ecx
  800edb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800edf:	72 3b                	jb     800f1c <__umoddi3+0x16c>
  800ee1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800ee5:	72 31                	jb     800f18 <__umoddi3+0x168>
  800ee7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800eeb:	29 c8                	sub    %ecx,%eax
  800eed:	19 d7                	sbb    %edx,%edi
  800eef:	89 e9                	mov    %ebp,%ecx
  800ef1:	89 fa                	mov    %edi,%edx
  800ef3:	d3 e8                	shr    %cl,%eax
  800ef5:	89 f1                	mov    %esi,%ecx
  800ef7:	d3 e2                	shl    %cl,%edx
  800ef9:	89 e9                	mov    %ebp,%ecx
  800efb:	09 d0                	or     %edx,%eax
  800efd:	89 fa                	mov    %edi,%edx
  800eff:	d3 ea                	shr    %cl,%edx
  800f01:	8b 74 24 20          	mov    0x20(%esp),%esi
  800f05:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800f09:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800f0d:	83 c4 2c             	add    $0x2c,%esp
  800f10:	c3                   	ret    
  800f11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f18:	39 d7                	cmp    %edx,%edi
  800f1a:	75 cb                	jne    800ee7 <__umoddi3+0x137>
  800f1c:	8b 54 24 14          	mov    0x14(%esp),%edx
  800f20:	89 c1                	mov    %eax,%ecx
  800f22:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800f26:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800f2a:	eb bb                	jmp    800ee7 <__umoddi3+0x137>
  800f2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f30:	3b 44 24 18          	cmp    0x18(%esp),%eax
  800f34:	0f 82 e8 fe ff ff    	jb     800e22 <__umoddi3+0x72>
  800f3a:	e9 f3 fe ff ff       	jmp    800e32 <__umoddi3+0x82>
