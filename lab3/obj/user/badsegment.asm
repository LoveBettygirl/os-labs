
obj/user/badsegment：     文件格式 elf32-i386


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
  80002c:	e8 0d 00 00 00       	call   80003e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	// Try to load the kernel's TSS selector into the DS register.
	asm volatile("movw $0x28,%ax; movw %ax,%ds");
  800036:	66 b8 28 00          	mov    $0x28,%ax
  80003a:	8e d8                	mov    %eax,%ds
}
  80003c:	5d                   	pop    %ebp
  80003d:	c3                   	ret    

0080003e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003e:	55                   	push   %ebp
  80003f:	89 e5                	mov    %esp,%ebp
  800041:	83 ec 18             	sub    $0x18,%esp
  800044:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800047:	89 75 fc             	mov    %esi,-0x4(%ebp)
  80004a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80004d:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	thisenv = &envs[ENVX(sys_getenvid())];
  800050:	e8 0b 01 00 00       	call   800160 <sys_getenvid>
  800055:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005a:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80005d:	c1 e0 05             	shl    $0x5,%eax
  800060:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800065:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006a:	85 db                	test   %ebx,%ebx
  80006c:	7e 07                	jle    800075 <libmain+0x37>
		binaryname = argv[0];
  80006e:	8b 06                	mov    (%esi),%eax
  800070:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800075:	89 74 24 04          	mov    %esi,0x4(%esp)
  800079:	89 1c 24             	mov    %ebx,(%esp)
  80007c:	e8 b2 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800081:	e8 0a 00 00 00       	call   800090 <exit>
}
  800086:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  800089:	8b 75 fc             	mov    -0x4(%ebp),%esi
  80008c:	89 ec                	mov    %ebp,%esp
  80008e:	5d                   	pop    %ebp
  80008f:	c3                   	ret    

00800090 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800090:	55                   	push   %ebp
  800091:	89 e5                	mov    %esp,%ebp
  800093:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800096:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80009d:	e8 61 00 00 00       	call   800103 <sys_env_destroy>
}
  8000a2:	c9                   	leave  
  8000a3:	c3                   	ret    

008000a4 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a4:	55                   	push   %ebp
  8000a5:	89 e5                	mov    %esp,%ebp
  8000a7:	83 ec 0c             	sub    $0xc,%esp
  8000aa:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000ad:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000b0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  8000b3:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000bb:	8b 55 08             	mov    0x8(%ebp),%edx
  8000be:	89 c3                	mov    %eax,%ebx
  8000c0:	89 c7                	mov    %eax,%edi
  8000c2:	89 c6                	mov    %eax,%esi
  8000c4:	cd 30                	int    $0x30
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000c9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000cc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000cf:	89 ec                	mov    %ebp,%esp
  8000d1:	5d                   	pop    %ebp
  8000d2:	c3                   	ret    

008000d3 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000d3:	55                   	push   %ebp
  8000d4:	89 e5                	mov    %esp,%ebp
  8000d6:	83 ec 0c             	sub    $0xc,%esp
  8000d9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000dc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000df:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  8000e2:	ba 00 00 00 00       	mov    $0x0,%edx
  8000e7:	b8 01 00 00 00       	mov    $0x1,%eax
  8000ec:	89 d1                	mov    %edx,%ecx
  8000ee:	89 d3                	mov    %edx,%ebx
  8000f0:	89 d7                	mov    %edx,%edi
  8000f2:	89 d6                	mov    %edx,%esi
  8000f4:	cd 30                	int    $0x30
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000f6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000f9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000fc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000ff:	89 ec                	mov    %ebp,%esp
  800101:	5d                   	pop    %ebp
  800102:	c3                   	ret    

00800103 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800103:	55                   	push   %ebp
  800104:	89 e5                	mov    %esp,%ebp
  800106:	83 ec 38             	sub    $0x38,%esp
  800109:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80010c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80010f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800112:	b9 00 00 00 00       	mov    $0x0,%ecx
  800117:	b8 03 00 00 00       	mov    $0x3,%eax
  80011c:	8b 55 08             	mov    0x8(%ebp),%edx
  80011f:	89 cb                	mov    %ecx,%ebx
  800121:	89 cf                	mov    %ecx,%edi
  800123:	89 ce                	mov    %ecx,%esi
  800125:	cd 30                	int    $0x30
	if(check && ret > 0)
  800127:	85 c0                	test   %eax,%eax
  800129:	7e 28                	jle    800153 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80012b:	89 44 24 10          	mov    %eax,0x10(%esp)
  80012f:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800136:	00 
  800137:	c7 44 24 08 2a 0f 80 	movl   $0x800f2a,0x8(%esp)
  80013e:	00 
  80013f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800146:	00 
  800147:	c7 04 24 47 0f 80 00 	movl   $0x800f47,(%esp)
  80014e:	e8 3d 00 00 00       	call   800190 <_panic>
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800153:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800156:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800159:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80015c:	89 ec                	mov    %ebp,%esp
  80015e:	5d                   	pop    %ebp
  80015f:	c3                   	ret    

00800160 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	83 ec 0c             	sub    $0xc,%esp
  800166:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800169:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80016c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  80016f:	ba 00 00 00 00       	mov    $0x0,%edx
  800174:	b8 02 00 00 00       	mov    $0x2,%eax
  800179:	89 d1                	mov    %edx,%ecx
  80017b:	89 d3                	mov    %edx,%ebx
  80017d:	89 d7                	mov    %edx,%edi
  80017f:	89 d6                	mov    %edx,%esi
  800181:	cd 30                	int    $0x30
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800183:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800186:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800189:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80018c:	89 ec                	mov    %ebp,%esp
  80018e:	5d                   	pop    %ebp
  80018f:	c3                   	ret    

00800190 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800190:	55                   	push   %ebp
  800191:	89 e5                	mov    %esp,%ebp
  800193:	56                   	push   %esi
  800194:	53                   	push   %ebx
  800195:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800198:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80019b:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001a1:	e8 ba ff ff ff       	call   800160 <sys_getenvid>
  8001a6:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001a9:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001ad:	8b 55 08             	mov    0x8(%ebp),%edx
  8001b0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001b4:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001bc:	c7 04 24 58 0f 80 00 	movl   $0x800f58,(%esp)
  8001c3:	e8 c1 00 00 00       	call   800289 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001c8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001cc:	8b 45 10             	mov    0x10(%ebp),%eax
  8001cf:	89 04 24             	mov    %eax,(%esp)
  8001d2:	e8 51 00 00 00       	call   800228 <vcprintf>
	cprintf("\n");
  8001d7:	c7 04 24 7c 0f 80 00 	movl   $0x800f7c,(%esp)
  8001de:	e8 a6 00 00 00       	call   800289 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001e3:	cc                   	int3   
  8001e4:	eb fd                	jmp    8001e3 <_panic+0x53>

008001e6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001e6:	55                   	push   %ebp
  8001e7:	89 e5                	mov    %esp,%ebp
  8001e9:	53                   	push   %ebx
  8001ea:	83 ec 14             	sub    $0x14,%esp
  8001ed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001f0:	8b 03                	mov    (%ebx),%eax
  8001f2:	8b 55 08             	mov    0x8(%ebp),%edx
  8001f5:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8001f9:	83 c0 01             	add    $0x1,%eax
  8001fc:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8001fe:	3d ff 00 00 00       	cmp    $0xff,%eax
  800203:	75 19                	jne    80021e <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800205:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80020c:	00 
  80020d:	8d 43 08             	lea    0x8(%ebx),%eax
  800210:	89 04 24             	mov    %eax,(%esp)
  800213:	e8 8c fe ff ff       	call   8000a4 <sys_cputs>
		b->idx = 0;
  800218:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80021e:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800222:	83 c4 14             	add    $0x14,%esp
  800225:	5b                   	pop    %ebx
  800226:	5d                   	pop    %ebp
  800227:	c3                   	ret    

00800228 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800228:	55                   	push   %ebp
  800229:	89 e5                	mov    %esp,%ebp
  80022b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800231:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800238:	00 00 00 
	b.cnt = 0;
  80023b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800242:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800245:	8b 45 0c             	mov    0xc(%ebp),%eax
  800248:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80024c:	8b 45 08             	mov    0x8(%ebp),%eax
  80024f:	89 44 24 08          	mov    %eax,0x8(%esp)
  800253:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800259:	89 44 24 04          	mov    %eax,0x4(%esp)
  80025d:	c7 04 24 e6 01 80 00 	movl   $0x8001e6,(%esp)
  800264:	e8 ac 01 00 00       	call   800415 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800269:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80026f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800273:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800279:	89 04 24             	mov    %eax,(%esp)
  80027c:	e8 23 fe ff ff       	call   8000a4 <sys_cputs>

	return b.cnt;
}
  800281:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800287:	c9                   	leave  
  800288:	c3                   	ret    

00800289 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800289:	55                   	push   %ebp
  80028a:	89 e5                	mov    %esp,%ebp
  80028c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80028f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800292:	89 44 24 04          	mov    %eax,0x4(%esp)
  800296:	8b 45 08             	mov    0x8(%ebp),%eax
  800299:	89 04 24             	mov    %eax,(%esp)
  80029c:	e8 87 ff ff ff       	call   800228 <vcprintf>
	va_end(ap);

	return cnt;
}
  8002a1:	c9                   	leave  
  8002a2:	c3                   	ret    
  8002a3:	66 90                	xchg   %ax,%ax
  8002a5:	66 90                	xchg   %ax,%ax
  8002a7:	66 90                	xchg   %ax,%ax
  8002a9:	66 90                	xchg   %ax,%ax
  8002ab:	66 90                	xchg   %ax,%ax
  8002ad:	66 90                	xchg   %ax,%ax
  8002af:	90                   	nop

008002b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002b0:	55                   	push   %ebp
  8002b1:	89 e5                	mov    %esp,%ebp
  8002b3:	57                   	push   %edi
  8002b4:	56                   	push   %esi
  8002b5:	53                   	push   %ebx
  8002b6:	83 ec 4c             	sub    $0x4c,%esp
  8002b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002bc:	89 d7                	mov    %edx,%edi
  8002be:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8002c1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8002c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002c7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8002ca:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002cd:	85 db                	test   %ebx,%ebx
  8002cf:	75 08                	jne    8002d9 <printnum+0x29>
  8002d1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002d4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8002d7:	77 6c                	ja     800345 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002d9:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8002dc:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8002e0:	83 ee 01             	sub    $0x1,%esi
  8002e3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002e7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002ea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002ee:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002f2:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002f6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002f9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8002fc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800303:	00 
  800304:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800307:	89 1c 24             	mov    %ebx,(%esp)
  80030a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80030d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800311:	e8 2a 09 00 00       	call   800c40 <__udivdi3>
  800316:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800319:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  80031c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800320:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800324:	89 04 24             	mov    %eax,(%esp)
  800327:	89 54 24 04          	mov    %edx,0x4(%esp)
  80032b:	89 fa                	mov    %edi,%edx
  80032d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800330:	e8 7b ff ff ff       	call   8002b0 <printnum>
  800335:	eb 1b                	jmp    800352 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800337:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80033b:	8b 45 18             	mov    0x18(%ebp),%eax
  80033e:	89 04 24             	mov    %eax,(%esp)
  800341:	ff d3                	call   *%ebx
  800343:	eb 03                	jmp    800348 <printnum+0x98>
  800345:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
  800348:	83 ee 01             	sub    $0x1,%esi
  80034b:	85 f6                	test   %esi,%esi
  80034d:	7f e8                	jg     800337 <printnum+0x87>
  80034f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800352:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800356:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80035a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80035d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800361:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800368:	00 
  800369:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80036c:	89 1c 24             	mov    %ebx,(%esp)
  80036f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800372:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800376:	e8 15 0a 00 00       	call   800d90 <__umoddi3>
  80037b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80037f:	0f be 80 7e 0f 80 00 	movsbl 0x800f7e(%eax),%eax
  800386:	89 04 24             	mov    %eax,(%esp)
  800389:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80038c:	ff d0                	call   *%eax
}
  80038e:	83 c4 4c             	add    $0x4c,%esp
  800391:	5b                   	pop    %ebx
  800392:	5e                   	pop    %esi
  800393:	5f                   	pop    %edi
  800394:	5d                   	pop    %ebp
  800395:	c3                   	ret    

00800396 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800396:	55                   	push   %ebp
  800397:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800399:	83 fa 01             	cmp    $0x1,%edx
  80039c:	7e 0e                	jle    8003ac <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80039e:	8b 10                	mov    (%eax),%edx
  8003a0:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003a3:	89 08                	mov    %ecx,(%eax)
  8003a5:	8b 02                	mov    (%edx),%eax
  8003a7:	8b 52 04             	mov    0x4(%edx),%edx
  8003aa:	eb 22                	jmp    8003ce <getuint+0x38>
	else if (lflag)
  8003ac:	85 d2                	test   %edx,%edx
  8003ae:	74 10                	je     8003c0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003b0:	8b 10                	mov    (%eax),%edx
  8003b2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003b5:	89 08                	mov    %ecx,(%eax)
  8003b7:	8b 02                	mov    (%edx),%eax
  8003b9:	ba 00 00 00 00       	mov    $0x0,%edx
  8003be:	eb 0e                	jmp    8003ce <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003c0:	8b 10                	mov    (%eax),%edx
  8003c2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003c5:	89 08                	mov    %ecx,(%eax)
  8003c7:	8b 02                	mov    (%edx),%eax
  8003c9:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003ce:	5d                   	pop    %ebp
  8003cf:	c3                   	ret    

008003d0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003d0:	55                   	push   %ebp
  8003d1:	89 e5                	mov    %esp,%ebp
  8003d3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003d6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003da:	8b 10                	mov    (%eax),%edx
  8003dc:	3b 50 04             	cmp    0x4(%eax),%edx
  8003df:	73 0a                	jae    8003eb <sprintputch+0x1b>
		*b->buf++ = ch;
  8003e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003e4:	88 0a                	mov    %cl,(%edx)
  8003e6:	83 c2 01             	add    $0x1,%edx
  8003e9:	89 10                	mov    %edx,(%eax)
}
  8003eb:	5d                   	pop    %ebp
  8003ec:	c3                   	ret    

008003ed <printfmt>:
{
  8003ed:	55                   	push   %ebp
  8003ee:	89 e5                	mov    %esp,%ebp
  8003f0:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
  8003f3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003fa:	8b 45 10             	mov    0x10(%ebp),%eax
  8003fd:	89 44 24 08          	mov    %eax,0x8(%esp)
  800401:	8b 45 0c             	mov    0xc(%ebp),%eax
  800404:	89 44 24 04          	mov    %eax,0x4(%esp)
  800408:	8b 45 08             	mov    0x8(%ebp),%eax
  80040b:	89 04 24             	mov    %eax,(%esp)
  80040e:	e8 02 00 00 00       	call   800415 <vprintfmt>
}
  800413:	c9                   	leave  
  800414:	c3                   	ret    

00800415 <vprintfmt>:
{
  800415:	55                   	push   %ebp
  800416:	89 e5                	mov    %esp,%ebp
  800418:	57                   	push   %edi
  800419:	56                   	push   %esi
  80041a:	53                   	push   %ebx
  80041b:	83 ec 4c             	sub    $0x4c,%esp
  80041e:	8b 75 08             	mov    0x8(%ebp),%esi
  800421:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800424:	8b 7d 10             	mov    0x10(%ebp),%edi
  800427:	eb 11                	jmp    80043a <vprintfmt+0x25>
			if (ch == '\0')
  800429:	85 c0                	test   %eax,%eax
  80042b:	0f 84 cf 03 00 00    	je     800800 <vprintfmt+0x3eb>
			putch(ch, putdat);
  800431:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800435:	89 04 24             	mov    %eax,(%esp)
  800438:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80043a:	0f b6 07             	movzbl (%edi),%eax
  80043d:	83 c7 01             	add    $0x1,%edi
  800440:	83 f8 25             	cmp    $0x25,%eax
  800443:	75 e4                	jne    800429 <vprintfmt+0x14>
  800445:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800449:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  800450:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800457:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80045e:	ba 00 00 00 00       	mov    $0x0,%edx
  800463:	eb 2b                	jmp    800490 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800465:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
  800468:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  80046c:	eb 22                	jmp    800490 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  80046e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
  800471:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800475:	eb 19                	jmp    800490 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800477:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
  80047a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800481:	eb 0d                	jmp    800490 <vprintfmt+0x7b>
				width = precision, precision = -1;
  800483:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800486:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800489:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800490:	0f b6 07             	movzbl (%edi),%eax
  800493:	8d 4f 01             	lea    0x1(%edi),%ecx
  800496:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800499:	0f b6 0f             	movzbl (%edi),%ecx
  80049c:	83 e9 23             	sub    $0x23,%ecx
  80049f:	80 f9 55             	cmp    $0x55,%cl
  8004a2:	0f 87 3b 03 00 00    	ja     8007e3 <vprintfmt+0x3ce>
  8004a8:	0f b6 c9             	movzbl %cl,%ecx
  8004ab:	ff 24 8d 20 10 80 00 	jmp    *0x801020(,%ecx,4)
  8004b2:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004b5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  8004bc:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8004bf:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
  8004c4:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8004c7:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8004cb:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8004ce:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004d1:	83 f9 09             	cmp    $0x9,%ecx
  8004d4:	77 2f                	ja     800505 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
  8004d6:	83 c7 01             	add    $0x1,%edi
			}
  8004d9:	eb e9                	jmp    8004c4 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
  8004db:	8b 45 14             	mov    0x14(%ebp),%eax
  8004de:	8d 48 04             	lea    0x4(%eax),%ecx
  8004e1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004e4:	8b 00                	mov    (%eax),%eax
  8004e6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8004e9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
  8004ec:	eb 1d                	jmp    80050b <vprintfmt+0xf6>
			if (width < 0)
  8004ee:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004f2:	78 83                	js     800477 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
  8004f4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004f7:	eb 97                	jmp    800490 <vprintfmt+0x7b>
  8004f9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
  8004fc:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800503:	eb 8b                	jmp    800490 <vprintfmt+0x7b>
  800505:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800508:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
  80050b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80050f:	0f 89 7b ff ff ff    	jns    800490 <vprintfmt+0x7b>
  800515:	e9 69 ff ff ff       	jmp    800483 <vprintfmt+0x6e>
			lflag++;
  80051a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
  80051d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
  800520:	e9 6b ff ff ff       	jmp    800490 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
  800525:	8b 45 14             	mov    0x14(%ebp),%eax
  800528:	8d 50 04             	lea    0x4(%eax),%edx
  80052b:	89 55 14             	mov    %edx,0x14(%ebp)
  80052e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800532:	8b 00                	mov    (%eax),%eax
  800534:	89 04 24             	mov    %eax,(%esp)
  800537:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  800539:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  80053c:	e9 f9 fe ff ff       	jmp    80043a <vprintfmt+0x25>
			err = va_arg(ap, int);
  800541:	8b 45 14             	mov    0x14(%ebp),%eax
  800544:	8d 50 04             	lea    0x4(%eax),%edx
  800547:	89 55 14             	mov    %edx,0x14(%ebp)
  80054a:	8b 00                	mov    (%eax),%eax
  80054c:	89 c2                	mov    %eax,%edx
  80054e:	c1 fa 1f             	sar    $0x1f,%edx
  800551:	31 d0                	xor    %edx,%eax
  800553:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800555:	83 f8 07             	cmp    $0x7,%eax
  800558:	7f 0b                	jg     800565 <vprintfmt+0x150>
  80055a:	8b 14 85 80 11 80 00 	mov    0x801180(,%eax,4),%edx
  800561:	85 d2                	test   %edx,%edx
  800563:	75 20                	jne    800585 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
  800565:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800569:	c7 44 24 08 96 0f 80 	movl   $0x800f96,0x8(%esp)
  800570:	00 
  800571:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800575:	89 34 24             	mov    %esi,(%esp)
  800578:	e8 70 fe ff ff       	call   8003ed <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80057d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
  800580:	e9 b5 fe ff ff       	jmp    80043a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
  800585:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800589:	c7 44 24 08 9f 0f 80 	movl   $0x800f9f,0x8(%esp)
  800590:	00 
  800591:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800595:	89 34 24             	mov    %esi,(%esp)
  800598:	e8 50 fe ff ff       	call   8003ed <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80059d:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005a0:	e9 95 fe ff ff       	jmp    80043a <vprintfmt+0x25>
  8005a5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005a8:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8005ab:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
  8005ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b1:	8d 50 04             	lea    0x4(%eax),%edx
  8005b4:	89 55 14             	mov    %edx,0x14(%ebp)
  8005b7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8005b9:	85 ff                	test   %edi,%edi
  8005bb:	b8 8f 0f 80 00       	mov    $0x800f8f,%eax
  8005c0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8005c3:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8005c7:	0f 84 9b 00 00 00    	je     800668 <vprintfmt+0x253>
  8005cd:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8005d1:	0f 8e 9f 00 00 00    	jle    800676 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005d7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005db:	89 3c 24             	mov    %edi,(%esp)
  8005de:	e8 c5 02 00 00       	call   8008a8 <strnlen>
  8005e3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8005e6:	29 c2                	sub    %eax,%edx
  8005e8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
  8005eb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8005ef:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8005f2:	89 7d c8             	mov    %edi,-0x38(%ebp)
  8005f5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  8005f7:	eb 0f                	jmp    800608 <vprintfmt+0x1f3>
					putch(padc, putdat);
  8005f9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800600:	89 04 24             	mov    %eax,(%esp)
  800603:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  800605:	83 ef 01             	sub    $0x1,%edi
  800608:	85 ff                	test   %edi,%edi
  80060a:	7f ed                	jg     8005f9 <vprintfmt+0x1e4>
  80060c:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  80060f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800613:	b8 00 00 00 00       	mov    $0x0,%eax
  800618:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
  80061c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80061f:	29 c2                	sub    %eax,%edx
  800621:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800624:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800627:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80062a:	89 d3                	mov    %edx,%ebx
  80062c:	eb 54                	jmp    800682 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
  80062e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800632:	74 20                	je     800654 <vprintfmt+0x23f>
  800634:	0f be d2             	movsbl %dl,%edx
  800637:	83 ea 20             	sub    $0x20,%edx
  80063a:	83 fa 5e             	cmp    $0x5e,%edx
  80063d:	76 15                	jbe    800654 <vprintfmt+0x23f>
					putch('?', putdat);
  80063f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800642:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800646:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80064d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800650:	ff d0                	call   *%eax
  800652:	eb 0f                	jmp    800663 <vprintfmt+0x24e>
					putch(ch, putdat);
  800654:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800657:	89 54 24 04          	mov    %edx,0x4(%esp)
  80065b:	89 04 24             	mov    %eax,(%esp)
  80065e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800661:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800663:	83 eb 01             	sub    $0x1,%ebx
  800666:	eb 1a                	jmp    800682 <vprintfmt+0x26d>
  800668:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  80066b:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80066e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800671:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800674:	eb 0c                	jmp    800682 <vprintfmt+0x26d>
  800676:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800679:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80067c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80067f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800682:	0f b6 17             	movzbl (%edi),%edx
  800685:	0f be c2             	movsbl %dl,%eax
  800688:	83 c7 01             	add    $0x1,%edi
  80068b:	85 c0                	test   %eax,%eax
  80068d:	74 29                	je     8006b8 <vprintfmt+0x2a3>
  80068f:	85 f6                	test   %esi,%esi
  800691:	78 9b                	js     80062e <vprintfmt+0x219>
  800693:	83 ee 01             	sub    $0x1,%esi
  800696:	79 96                	jns    80062e <vprintfmt+0x219>
  800698:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80069b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80069e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006a1:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8006a4:	eb 1a                	jmp    8006c0 <vprintfmt+0x2ab>
				putch(' ', putdat);
  8006a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006aa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006b1:	ff d6                	call   *%esi
			for (; width > 0; width--)
  8006b3:	83 ef 01             	sub    $0x1,%edi
  8006b6:	eb 08                	jmp    8006c0 <vprintfmt+0x2ab>
  8006b8:	89 df                	mov    %ebx,%edi
  8006ba:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006bd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006c0:	85 ff                	test   %edi,%edi
  8006c2:	7f e2                	jg     8006a6 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
  8006c4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006c7:	e9 6e fd ff ff       	jmp    80043a <vprintfmt+0x25>
	if (lflag >= 2)
  8006cc:	83 fa 01             	cmp    $0x1,%edx
  8006cf:	7e 16                	jle    8006e7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
  8006d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d4:	8d 50 08             	lea    0x8(%eax),%edx
  8006d7:	89 55 14             	mov    %edx,0x14(%ebp)
  8006da:	8b 10                	mov    (%eax),%edx
  8006dc:	8b 48 04             	mov    0x4(%eax),%ecx
  8006df:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8006e2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006e5:	eb 32                	jmp    800719 <vprintfmt+0x304>
	else if (lflag)
  8006e7:	85 d2                	test   %edx,%edx
  8006e9:	74 18                	je     800703 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
  8006eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ee:	8d 50 04             	lea    0x4(%eax),%edx
  8006f1:	89 55 14             	mov    %edx,0x14(%ebp)
  8006f4:	8b 00                	mov    (%eax),%eax
  8006f6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006f9:	89 c1                	mov    %eax,%ecx
  8006fb:	c1 f9 1f             	sar    $0x1f,%ecx
  8006fe:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800701:	eb 16                	jmp    800719 <vprintfmt+0x304>
		return va_arg(*ap, int);
  800703:	8b 45 14             	mov    0x14(%ebp),%eax
  800706:	8d 50 04             	lea    0x4(%eax),%edx
  800709:	89 55 14             	mov    %edx,0x14(%ebp)
  80070c:	8b 00                	mov    (%eax),%eax
  80070e:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800711:	89 c7                	mov    %eax,%edi
  800713:	c1 ff 1f             	sar    $0x1f,%edi
  800716:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
  800719:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80071c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
  80071f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
  800724:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800728:	79 7d                	jns    8007a7 <vprintfmt+0x392>
				putch('-', putdat);
  80072a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80072e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800735:	ff d6                	call   *%esi
				num = -(long long) num;
  800737:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80073a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80073d:	f7 d8                	neg    %eax
  80073f:	83 d2 00             	adc    $0x0,%edx
  800742:	f7 da                	neg    %edx
			base = 10;
  800744:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800749:	eb 5c                	jmp    8007a7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80074b:	8d 45 14             	lea    0x14(%ebp),%eax
  80074e:	e8 43 fc ff ff       	call   800396 <getuint>
			base = 10;
  800753:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800758:	eb 4d                	jmp    8007a7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80075a:	8d 45 14             	lea    0x14(%ebp),%eax
  80075d:	e8 34 fc ff ff       	call   800396 <getuint>
			base = 8;
  800762:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800767:	eb 3e                	jmp    8007a7 <vprintfmt+0x392>
			putch('0', putdat);
  800769:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80076d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800774:	ff d6                	call   *%esi
			putch('x', putdat);
  800776:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80077a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800781:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
  800783:	8b 45 14             	mov    0x14(%ebp),%eax
  800786:	8d 50 04             	lea    0x4(%eax),%edx
  800789:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
  80078c:	8b 00                	mov    (%eax),%eax
  80078e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
  800793:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800798:	eb 0d                	jmp    8007a7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80079a:	8d 45 14             	lea    0x14(%ebp),%eax
  80079d:	e8 f4 fb ff ff       	call   800396 <getuint>
			base = 16;
  8007a2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
  8007a7:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8007ab:	89 7c 24 10          	mov    %edi,0x10(%esp)
  8007af:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8007b2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8007b6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007ba:	89 04 24             	mov    %eax,(%esp)
  8007bd:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007c1:	89 da                	mov    %ebx,%edx
  8007c3:	89 f0                	mov    %esi,%eax
  8007c5:	e8 e6 fa ff ff       	call   8002b0 <printnum>
			break;
  8007ca:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007cd:	e9 68 fc ff ff       	jmp    80043a <vprintfmt+0x25>
			putch(ch, putdat);
  8007d2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007d6:	89 04 24             	mov    %eax,(%esp)
  8007d9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  8007db:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  8007de:	e9 57 fc ff ff       	jmp    80043a <vprintfmt+0x25>
			putch('%', putdat);
  8007e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007e7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007ee:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007f0:	eb 03                	jmp    8007f5 <vprintfmt+0x3e0>
  8007f2:	83 ef 01             	sub    $0x1,%edi
  8007f5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007f9:	75 f7                	jne    8007f2 <vprintfmt+0x3dd>
  8007fb:	e9 3a fc ff ff       	jmp    80043a <vprintfmt+0x25>
}
  800800:	83 c4 4c             	add    $0x4c,%esp
  800803:	5b                   	pop    %ebx
  800804:	5e                   	pop    %esi
  800805:	5f                   	pop    %edi
  800806:	5d                   	pop    %ebp
  800807:	c3                   	ret    

00800808 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800808:	55                   	push   %ebp
  800809:	89 e5                	mov    %esp,%ebp
  80080b:	83 ec 28             	sub    $0x28,%esp
  80080e:	8b 45 08             	mov    0x8(%ebp),%eax
  800811:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800814:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800817:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80081b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80081e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800825:	85 d2                	test   %edx,%edx
  800827:	7e 30                	jle    800859 <vsnprintf+0x51>
  800829:	85 c0                	test   %eax,%eax
  80082b:	74 2c                	je     800859 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80082d:	8b 45 14             	mov    0x14(%ebp),%eax
  800830:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800834:	8b 45 10             	mov    0x10(%ebp),%eax
  800837:	89 44 24 08          	mov    %eax,0x8(%esp)
  80083b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80083e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800842:	c7 04 24 d0 03 80 00 	movl   $0x8003d0,(%esp)
  800849:	e8 c7 fb ff ff       	call   800415 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80084e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800851:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800854:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800857:	eb 05                	jmp    80085e <vsnprintf+0x56>
		return -E_INVAL;
  800859:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  80085e:	c9                   	leave  
  80085f:	c3                   	ret    

00800860 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800860:	55                   	push   %ebp
  800861:	89 e5                	mov    %esp,%ebp
  800863:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800866:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800869:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80086d:	8b 45 10             	mov    0x10(%ebp),%eax
  800870:	89 44 24 08          	mov    %eax,0x8(%esp)
  800874:	8b 45 0c             	mov    0xc(%ebp),%eax
  800877:	89 44 24 04          	mov    %eax,0x4(%esp)
  80087b:	8b 45 08             	mov    0x8(%ebp),%eax
  80087e:	89 04 24             	mov    %eax,(%esp)
  800881:	e8 82 ff ff ff       	call   800808 <vsnprintf>
	va_end(ap);

	return rc;
}
  800886:	c9                   	leave  
  800887:	c3                   	ret    
  800888:	66 90                	xchg   %ax,%ax
  80088a:	66 90                	xchg   %ax,%ax
  80088c:	66 90                	xchg   %ax,%ax
  80088e:	66 90                	xchg   %ax,%ax

00800890 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800890:	55                   	push   %ebp
  800891:	89 e5                	mov    %esp,%ebp
  800893:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800896:	b8 00 00 00 00       	mov    $0x0,%eax
  80089b:	eb 03                	jmp    8008a0 <strlen+0x10>
		n++;
  80089d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  8008a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008a4:	75 f7                	jne    80089d <strlen+0xd>
	return n;
}
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
  8008ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
  8008ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008b6:	eb 03                	jmp    8008bb <strnlen+0x13>
		n++;
  8008b8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008bb:	39 d0                	cmp    %edx,%eax
  8008bd:	74 06                	je     8008c5 <strnlen+0x1d>
  8008bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8008c3:	75 f3                	jne    8008b8 <strnlen+0x10>
	return n;
}
  8008c5:	5d                   	pop    %ebp
  8008c6:	c3                   	ret    

008008c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008c7:	55                   	push   %ebp
  8008c8:	89 e5                	mov    %esp,%ebp
  8008ca:	53                   	push   %ebx
  8008cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008d1:	89 c2                	mov    %eax,%edx
  8008d3:	0f b6 19             	movzbl (%ecx),%ebx
  8008d6:	88 1a                	mov    %bl,(%edx)
  8008d8:	83 c2 01             	add    $0x1,%edx
  8008db:	83 c1 01             	add    $0x1,%ecx
  8008de:	84 db                	test   %bl,%bl
  8008e0:	75 f1                	jne    8008d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008e2:	5b                   	pop    %ebx
  8008e3:	5d                   	pop    %ebp
  8008e4:	c3                   	ret    

008008e5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008e5:	55                   	push   %ebp
  8008e6:	89 e5                	mov    %esp,%ebp
  8008e8:	53                   	push   %ebx
  8008e9:	83 ec 08             	sub    $0x8,%esp
  8008ec:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008ef:	89 1c 24             	mov    %ebx,(%esp)
  8008f2:	e8 99 ff ff ff       	call   800890 <strlen>
	strcpy(dst + len, src);
  8008f7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008fa:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008fe:	01 d8                	add    %ebx,%eax
  800900:	89 04 24             	mov    %eax,(%esp)
  800903:	e8 bf ff ff ff       	call   8008c7 <strcpy>
	return dst;
}
  800908:	89 d8                	mov    %ebx,%eax
  80090a:	83 c4 08             	add    $0x8,%esp
  80090d:	5b                   	pop    %ebx
  80090e:	5d                   	pop    %ebp
  80090f:	c3                   	ret    

00800910 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800910:	55                   	push   %ebp
  800911:	89 e5                	mov    %esp,%ebp
  800913:	56                   	push   %esi
  800914:	53                   	push   %ebx
  800915:	8b 75 08             	mov    0x8(%ebp),%esi
  800918:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80091b:	89 f3                	mov    %esi,%ebx
  80091d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800920:	89 f2                	mov    %esi,%edx
  800922:	eb 0e                	jmp    800932 <strncpy+0x22>
		*dst++ = *src;
  800924:	0f b6 01             	movzbl (%ecx),%eax
  800927:	88 02                	mov    %al,(%edx)
  800929:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80092c:	80 39 01             	cmpb   $0x1,(%ecx)
  80092f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800932:	39 da                	cmp    %ebx,%edx
  800934:	75 ee                	jne    800924 <strncpy+0x14>
	}
	return ret;
}
  800936:	89 f0                	mov    %esi,%eax
  800938:	5b                   	pop    %ebx
  800939:	5e                   	pop    %esi
  80093a:	5d                   	pop    %ebp
  80093b:	c3                   	ret    

0080093c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80093c:	55                   	push   %ebp
  80093d:	89 e5                	mov    %esp,%ebp
  80093f:	56                   	push   %esi
  800940:	53                   	push   %ebx
  800941:	8b 75 08             	mov    0x8(%ebp),%esi
  800944:	8b 55 0c             	mov    0xc(%ebp),%edx
  800947:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80094a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
  80094c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
  800950:	85 c9                	test   %ecx,%ecx
  800952:	75 0a                	jne    80095e <strlcpy+0x22>
  800954:	eb 1c                	jmp    800972 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800956:	88 08                	mov    %cl,(%eax)
  800958:	83 c0 01             	add    $0x1,%eax
  80095b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
  80095e:	39 d8                	cmp    %ebx,%eax
  800960:	74 0b                	je     80096d <strlcpy+0x31>
  800962:	0f b6 0a             	movzbl (%edx),%ecx
  800965:	84 c9                	test   %cl,%cl
  800967:	75 ed                	jne    800956 <strlcpy+0x1a>
  800969:	89 c2                	mov    %eax,%edx
  80096b:	eb 02                	jmp    80096f <strlcpy+0x33>
  80096d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
  80096f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800972:	29 f0                	sub    %esi,%eax
}
  800974:	5b                   	pop    %ebx
  800975:	5e                   	pop    %esi
  800976:	5d                   	pop    %ebp
  800977:	c3                   	ret    

00800978 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800978:	55                   	push   %ebp
  800979:	89 e5                	mov    %esp,%ebp
  80097b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80097e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800981:	eb 06                	jmp    800989 <strcmp+0x11>
		p++, q++;
  800983:	83 c1 01             	add    $0x1,%ecx
  800986:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800989:	0f b6 01             	movzbl (%ecx),%eax
  80098c:	84 c0                	test   %al,%al
  80098e:	74 04                	je     800994 <strcmp+0x1c>
  800990:	3a 02                	cmp    (%edx),%al
  800992:	74 ef                	je     800983 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800994:	0f b6 c0             	movzbl %al,%eax
  800997:	0f b6 12             	movzbl (%edx),%edx
  80099a:	29 d0                	sub    %edx,%eax
}
  80099c:	5d                   	pop    %ebp
  80099d:	c3                   	ret    

0080099e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80099e:	55                   	push   %ebp
  80099f:	89 e5                	mov    %esp,%ebp
  8009a1:	53                   	push   %ebx
  8009a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a5:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
  8009a8:	89 c3                	mov    %eax,%ebx
  8009aa:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009ad:	eb 06                	jmp    8009b5 <strncmp+0x17>
		n--, p++, q++;
  8009af:	83 c0 01             	add    $0x1,%eax
  8009b2:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  8009b5:	39 d8                	cmp    %ebx,%eax
  8009b7:	74 15                	je     8009ce <strncmp+0x30>
  8009b9:	0f b6 08             	movzbl (%eax),%ecx
  8009bc:	84 c9                	test   %cl,%cl
  8009be:	74 04                	je     8009c4 <strncmp+0x26>
  8009c0:	3a 0a                	cmp    (%edx),%cl
  8009c2:	74 eb                	je     8009af <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009c4:	0f b6 00             	movzbl (%eax),%eax
  8009c7:	0f b6 12             	movzbl (%edx),%edx
  8009ca:	29 d0                	sub    %edx,%eax
  8009cc:	eb 05                	jmp    8009d3 <strncmp+0x35>
		return 0;
  8009ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d3:	5b                   	pop    %ebx
  8009d4:	5d                   	pop    %ebp
  8009d5:	c3                   	ret    

008009d6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009d6:	55                   	push   %ebp
  8009d7:	89 e5                	mov    %esp,%ebp
  8009d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009e0:	eb 07                	jmp    8009e9 <strchr+0x13>
		if (*s == c)
  8009e2:	38 ca                	cmp    %cl,%dl
  8009e4:	74 0f                	je     8009f5 <strchr+0x1f>
	for (; *s; s++)
  8009e6:	83 c0 01             	add    $0x1,%eax
  8009e9:	0f b6 10             	movzbl (%eax),%edx
  8009ec:	84 d2                	test   %dl,%dl
  8009ee:	75 f2                	jne    8009e2 <strchr+0xc>
			return (char *) s;
	return 0;
  8009f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f5:	5d                   	pop    %ebp
  8009f6:	c3                   	ret    

008009f7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009f7:	55                   	push   %ebp
  8009f8:	89 e5                	mov    %esp,%ebp
  8009fa:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a01:	eb 07                	jmp    800a0a <strfind+0x13>
		if (*s == c)
  800a03:	38 ca                	cmp    %cl,%dl
  800a05:	74 0a                	je     800a11 <strfind+0x1a>
	for (; *s; s++)
  800a07:	83 c0 01             	add    $0x1,%eax
  800a0a:	0f b6 10             	movzbl (%eax),%edx
  800a0d:	84 d2                	test   %dl,%dl
  800a0f:	75 f2                	jne    800a03 <strfind+0xc>
			break;
	return (char *) s;
}
  800a11:	5d                   	pop    %ebp
  800a12:	c3                   	ret    

00800a13 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a13:	55                   	push   %ebp
  800a14:	89 e5                	mov    %esp,%ebp
  800a16:	83 ec 0c             	sub    $0xc,%esp
  800a19:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800a1c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a1f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a22:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a25:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a28:	85 c9                	test   %ecx,%ecx
  800a2a:	74 36                	je     800a62 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a2c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a32:	75 28                	jne    800a5c <memset+0x49>
  800a34:	f6 c1 03             	test   $0x3,%cl
  800a37:	75 23                	jne    800a5c <memset+0x49>
		c &= 0xFF;
  800a39:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a3d:	89 d3                	mov    %edx,%ebx
  800a3f:	c1 e3 08             	shl    $0x8,%ebx
  800a42:	89 d6                	mov    %edx,%esi
  800a44:	c1 e6 18             	shl    $0x18,%esi
  800a47:	89 d0                	mov    %edx,%eax
  800a49:	c1 e0 10             	shl    $0x10,%eax
  800a4c:	09 f0                	or     %esi,%eax
  800a4e:	09 c2                	or     %eax,%edx
  800a50:	89 d0                	mov    %edx,%eax
  800a52:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a54:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800a57:	fc                   	cld    
  800a58:	f3 ab                	rep stos %eax,%es:(%edi)
  800a5a:	eb 06                	jmp    800a62 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a5c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a5f:	fc                   	cld    
  800a60:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a62:	89 f8                	mov    %edi,%eax
  800a64:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a67:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a6a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a6d:	89 ec                	mov    %ebp,%esp
  800a6f:	5d                   	pop    %ebp
  800a70:	c3                   	ret    

00800a71 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a71:	55                   	push   %ebp
  800a72:	89 e5                	mov    %esp,%ebp
  800a74:	83 ec 08             	sub    $0x8,%esp
  800a77:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a7a:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a7d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a80:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a83:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a86:	39 c6                	cmp    %eax,%esi
  800a88:	73 36                	jae    800ac0 <memmove+0x4f>
  800a8a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a8d:	39 d0                	cmp    %edx,%eax
  800a8f:	73 2f                	jae    800ac0 <memmove+0x4f>
		s += n;
		d += n;
  800a91:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a94:	f6 c2 03             	test   $0x3,%dl
  800a97:	75 1b                	jne    800ab4 <memmove+0x43>
  800a99:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a9f:	75 13                	jne    800ab4 <memmove+0x43>
  800aa1:	f6 c1 03             	test   $0x3,%cl
  800aa4:	75 0e                	jne    800ab4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800aa6:	83 ef 04             	sub    $0x4,%edi
  800aa9:	8d 72 fc             	lea    -0x4(%edx),%esi
  800aac:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  800aaf:	fd                   	std    
  800ab0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ab2:	eb 09                	jmp    800abd <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800ab4:	83 ef 01             	sub    $0x1,%edi
  800ab7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  800aba:	fd                   	std    
  800abb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800abd:	fc                   	cld    
  800abe:	eb 20                	jmp    800ae0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ac0:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ac6:	75 13                	jne    800adb <memmove+0x6a>
  800ac8:	a8 03                	test   $0x3,%al
  800aca:	75 0f                	jne    800adb <memmove+0x6a>
  800acc:	f6 c1 03             	test   $0x3,%cl
  800acf:	75 0a                	jne    800adb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800ad1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  800ad4:	89 c7                	mov    %eax,%edi
  800ad6:	fc                   	cld    
  800ad7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ad9:	eb 05                	jmp    800ae0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
  800adb:	89 c7                	mov    %eax,%edi
  800add:	fc                   	cld    
  800ade:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ae0:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ae3:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ae6:	89 ec                	mov    %ebp,%esp
  800ae8:	5d                   	pop    %ebp
  800ae9:	c3                   	ret    

00800aea <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800aea:	55                   	push   %ebp
  800aeb:	89 e5                	mov    %esp,%ebp
  800aed:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800af0:	8b 45 10             	mov    0x10(%ebp),%eax
  800af3:	89 44 24 08          	mov    %eax,0x8(%esp)
  800af7:	8b 45 0c             	mov    0xc(%ebp),%eax
  800afa:	89 44 24 04          	mov    %eax,0x4(%esp)
  800afe:	8b 45 08             	mov    0x8(%ebp),%eax
  800b01:	89 04 24             	mov    %eax,(%esp)
  800b04:	e8 68 ff ff ff       	call   800a71 <memmove>
}
  800b09:	c9                   	leave  
  800b0a:	c3                   	ret    

00800b0b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b0b:	55                   	push   %ebp
  800b0c:	89 e5                	mov    %esp,%ebp
  800b0e:	56                   	push   %esi
  800b0f:	53                   	push   %ebx
  800b10:	8b 55 08             	mov    0x8(%ebp),%edx
  800b13:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
  800b16:	89 d6                	mov    %edx,%esi
  800b18:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b1b:	eb 1a                	jmp    800b37 <memcmp+0x2c>
		if (*s1 != *s2)
  800b1d:	0f b6 02             	movzbl (%edx),%eax
  800b20:	0f b6 19             	movzbl (%ecx),%ebx
  800b23:	38 d8                	cmp    %bl,%al
  800b25:	74 0a                	je     800b31 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b27:	0f b6 c0             	movzbl %al,%eax
  800b2a:	0f b6 db             	movzbl %bl,%ebx
  800b2d:	29 d8                	sub    %ebx,%eax
  800b2f:	eb 0f                	jmp    800b40 <memcmp+0x35>
		s1++, s2++;
  800b31:	83 c2 01             	add    $0x1,%edx
  800b34:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
  800b37:	39 f2                	cmp    %esi,%edx
  800b39:	75 e2                	jne    800b1d <memcmp+0x12>
	}

	return 0;
  800b3b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b40:	5b                   	pop    %ebx
  800b41:	5e                   	pop    %esi
  800b42:	5d                   	pop    %ebp
  800b43:	c3                   	ret    

00800b44 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b44:	55                   	push   %ebp
  800b45:	89 e5                	mov    %esp,%ebp
  800b47:	8b 45 08             	mov    0x8(%ebp),%eax
  800b4a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b4d:	89 c2                	mov    %eax,%edx
  800b4f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b52:	eb 07                	jmp    800b5b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b54:	38 08                	cmp    %cl,(%eax)
  800b56:	74 07                	je     800b5f <memfind+0x1b>
	for (; s < ends; s++)
  800b58:	83 c0 01             	add    $0x1,%eax
  800b5b:	39 d0                	cmp    %edx,%eax
  800b5d:	72 f5                	jb     800b54 <memfind+0x10>
			break;
	return (void *) s;
}
  800b5f:	5d                   	pop    %ebp
  800b60:	c3                   	ret    

00800b61 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b61:	55                   	push   %ebp
  800b62:	89 e5                	mov    %esp,%ebp
  800b64:	57                   	push   %edi
  800b65:	56                   	push   %esi
  800b66:	53                   	push   %ebx
  800b67:	83 ec 04             	sub    $0x4,%esp
  800b6a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b6d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b70:	eb 03                	jmp    800b75 <strtol+0x14>
		s++;
  800b72:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
  800b75:	0f b6 02             	movzbl (%edx),%eax
  800b78:	3c 09                	cmp    $0x9,%al
  800b7a:	74 f6                	je     800b72 <strtol+0x11>
  800b7c:	3c 20                	cmp    $0x20,%al
  800b7e:	74 f2                	je     800b72 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
  800b80:	3c 2b                	cmp    $0x2b,%al
  800b82:	75 0a                	jne    800b8e <strtol+0x2d>
		s++;
  800b84:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
  800b87:	bf 00 00 00 00       	mov    $0x0,%edi
  800b8c:	eb 10                	jmp    800b9e <strtol+0x3d>
  800b8e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
  800b93:	3c 2d                	cmp    $0x2d,%al
  800b95:	75 07                	jne    800b9e <strtol+0x3d>
		s++, neg = 1;
  800b97:	8d 52 01             	lea    0x1(%edx),%edx
  800b9a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b9e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ba4:	75 15                	jne    800bbb <strtol+0x5a>
  800ba6:	80 3a 30             	cmpb   $0x30,(%edx)
  800ba9:	75 10                	jne    800bbb <strtol+0x5a>
  800bab:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800baf:	75 0a                	jne    800bbb <strtol+0x5a>
		s += 2, base = 16;
  800bb1:	83 c2 02             	add    $0x2,%edx
  800bb4:	bb 10 00 00 00       	mov    $0x10,%ebx
  800bb9:	eb 10                	jmp    800bcb <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800bbb:	85 db                	test   %ebx,%ebx
  800bbd:	75 0c                	jne    800bcb <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bbf:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
  800bc1:	80 3a 30             	cmpb   $0x30,(%edx)
  800bc4:	75 05                	jne    800bcb <strtol+0x6a>
		s++, base = 8;
  800bc6:	83 c2 01             	add    $0x1,%edx
  800bc9:	b3 08                	mov    $0x8,%bl
		base = 10;
  800bcb:	b8 00 00 00 00       	mov    $0x0,%eax
  800bd0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bd3:	0f b6 0a             	movzbl (%edx),%ecx
  800bd6:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bd9:	89 f3                	mov    %esi,%ebx
  800bdb:	80 fb 09             	cmp    $0x9,%bl
  800bde:	77 08                	ja     800be8 <strtol+0x87>
			dig = *s - '0';
  800be0:	0f be c9             	movsbl %cl,%ecx
  800be3:	83 e9 30             	sub    $0x30,%ecx
  800be6:	eb 22                	jmp    800c0a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
  800be8:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800beb:	89 f3                	mov    %esi,%ebx
  800bed:	80 fb 19             	cmp    $0x19,%bl
  800bf0:	77 08                	ja     800bfa <strtol+0x99>
			dig = *s - 'a' + 10;
  800bf2:	0f be c9             	movsbl %cl,%ecx
  800bf5:	83 e9 57             	sub    $0x57,%ecx
  800bf8:	eb 10                	jmp    800c0a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
  800bfa:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bfd:	89 f3                	mov    %esi,%ebx
  800bff:	80 fb 19             	cmp    $0x19,%bl
  800c02:	77 16                	ja     800c1a <strtol+0xb9>
			dig = *s - 'A' + 10;
  800c04:	0f be c9             	movsbl %cl,%ecx
  800c07:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c0a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800c0d:	7d 0f                	jge    800c1e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800c0f:	83 c2 01             	add    $0x1,%edx
  800c12:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c16:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c18:	eb b9                	jmp    800bd3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
  800c1a:	89 c1                	mov    %eax,%ecx
  800c1c:	eb 02                	jmp    800c20 <strtol+0xbf>
		if (dig >= base)
  800c1e:	89 c1                	mov    %eax,%ecx

	if (endptr)
  800c20:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c24:	74 05                	je     800c2b <strtol+0xca>
		*endptr = (char *) s;
  800c26:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c29:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c2b:	89 ca                	mov    %ecx,%edx
  800c2d:	f7 da                	neg    %edx
  800c2f:	85 ff                	test   %edi,%edi
  800c31:	0f 45 c2             	cmovne %edx,%eax
}
  800c34:	83 c4 04             	add    $0x4,%esp
  800c37:	5b                   	pop    %ebx
  800c38:	5e                   	pop    %esi
  800c39:	5f                   	pop    %edi
  800c3a:	5d                   	pop    %ebp
  800c3b:	c3                   	ret    
  800c3c:	66 90                	xchg   %ax,%ax
  800c3e:	66 90                	xchg   %ax,%ax

00800c40 <__udivdi3>:
  800c40:	83 ec 1c             	sub    $0x1c,%esp
  800c43:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800c47:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800c4b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c4f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c53:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800c57:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800c5b:	85 c0                	test   %eax,%eax
  800c5d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c61:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c65:	89 ea                	mov    %ebp,%edx
  800c67:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c6b:	75 33                	jne    800ca0 <__udivdi3+0x60>
  800c6d:	39 e9                	cmp    %ebp,%ecx
  800c6f:	77 6f                	ja     800ce0 <__udivdi3+0xa0>
  800c71:	85 c9                	test   %ecx,%ecx
  800c73:	89 ce                	mov    %ecx,%esi
  800c75:	75 0b                	jne    800c82 <__udivdi3+0x42>
  800c77:	b8 01 00 00 00       	mov    $0x1,%eax
  800c7c:	31 d2                	xor    %edx,%edx
  800c7e:	f7 f1                	div    %ecx
  800c80:	89 c6                	mov    %eax,%esi
  800c82:	31 d2                	xor    %edx,%edx
  800c84:	89 e8                	mov    %ebp,%eax
  800c86:	f7 f6                	div    %esi
  800c88:	89 c5                	mov    %eax,%ebp
  800c8a:	89 f8                	mov    %edi,%eax
  800c8c:	f7 f6                	div    %esi
  800c8e:	89 ea                	mov    %ebp,%edx
  800c90:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c94:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c9c:	83 c4 1c             	add    $0x1c,%esp
  800c9f:	c3                   	ret    
  800ca0:	39 e8                	cmp    %ebp,%eax
  800ca2:	77 24                	ja     800cc8 <__udivdi3+0x88>
  800ca4:	0f bd c8             	bsr    %eax,%ecx
  800ca7:	83 f1 1f             	xor    $0x1f,%ecx
  800caa:	89 0c 24             	mov    %ecx,(%esp)
  800cad:	75 49                	jne    800cf8 <__udivdi3+0xb8>
  800caf:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cb3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800cb7:	0f 86 ab 00 00 00    	jbe    800d68 <__udivdi3+0x128>
  800cbd:	39 e8                	cmp    %ebp,%eax
  800cbf:	0f 82 a3 00 00 00    	jb     800d68 <__udivdi3+0x128>
  800cc5:	8d 76 00             	lea    0x0(%esi),%esi
  800cc8:	31 d2                	xor    %edx,%edx
  800cca:	31 c0                	xor    %eax,%eax
  800ccc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cd0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cd4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800cd8:	83 c4 1c             	add    $0x1c,%esp
  800cdb:	c3                   	ret    
  800cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ce0:	89 f8                	mov    %edi,%eax
  800ce2:	f7 f1                	div    %ecx
  800ce4:	31 d2                	xor    %edx,%edx
  800ce6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cea:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cee:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800cf2:	83 c4 1c             	add    $0x1c,%esp
  800cf5:	c3                   	ret    
  800cf6:	66 90                	xchg   %ax,%ax
  800cf8:	0f b6 0c 24          	movzbl (%esp),%ecx
  800cfc:	89 c6                	mov    %eax,%esi
  800cfe:	b8 20 00 00 00       	mov    $0x20,%eax
  800d03:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800d07:	2b 04 24             	sub    (%esp),%eax
  800d0a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d0e:	d3 e6                	shl    %cl,%esi
  800d10:	89 c1                	mov    %eax,%ecx
  800d12:	d3 ed                	shr    %cl,%ebp
  800d14:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d18:	09 f5                	or     %esi,%ebp
  800d1a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d1e:	d3 e6                	shl    %cl,%esi
  800d20:	89 c1                	mov    %eax,%ecx
  800d22:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d26:	89 d6                	mov    %edx,%esi
  800d28:	d3 ee                	shr    %cl,%esi
  800d2a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d2e:	d3 e2                	shl    %cl,%edx
  800d30:	89 c1                	mov    %eax,%ecx
  800d32:	d3 ef                	shr    %cl,%edi
  800d34:	09 d7                	or     %edx,%edi
  800d36:	89 f2                	mov    %esi,%edx
  800d38:	89 f8                	mov    %edi,%eax
  800d3a:	f7 f5                	div    %ebp
  800d3c:	89 d6                	mov    %edx,%esi
  800d3e:	89 c7                	mov    %eax,%edi
  800d40:	f7 64 24 04          	mull   0x4(%esp)
  800d44:	39 d6                	cmp    %edx,%esi
  800d46:	72 30                	jb     800d78 <__udivdi3+0x138>
  800d48:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800d4c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d50:	d3 e5                	shl    %cl,%ebp
  800d52:	39 c5                	cmp    %eax,%ebp
  800d54:	73 04                	jae    800d5a <__udivdi3+0x11a>
  800d56:	39 d6                	cmp    %edx,%esi
  800d58:	74 1e                	je     800d78 <__udivdi3+0x138>
  800d5a:	89 f8                	mov    %edi,%eax
  800d5c:	31 d2                	xor    %edx,%edx
  800d5e:	e9 69 ff ff ff       	jmp    800ccc <__udivdi3+0x8c>
  800d63:	90                   	nop
  800d64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d68:	31 d2                	xor    %edx,%edx
  800d6a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d6f:	e9 58 ff ff ff       	jmp    800ccc <__udivdi3+0x8c>
  800d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d78:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d7b:	31 d2                	xor    %edx,%edx
  800d7d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d81:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d85:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d89:	83 c4 1c             	add    $0x1c,%esp
  800d8c:	c3                   	ret    
  800d8d:	66 90                	xchg   %ax,%ax
  800d8f:	90                   	nop

00800d90 <__umoddi3>:
  800d90:	83 ec 2c             	sub    $0x2c,%esp
  800d93:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800d97:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d9b:	89 74 24 20          	mov    %esi,0x20(%esp)
  800d9f:	8b 74 24 38          	mov    0x38(%esp),%esi
  800da3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800da7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800dab:	85 c0                	test   %eax,%eax
  800dad:	89 c2                	mov    %eax,%edx
  800daf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800db3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800db7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dbb:	89 74 24 10          	mov    %esi,0x10(%esp)
  800dbf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800dc3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800dc7:	75 1f                	jne    800de8 <__umoddi3+0x58>
  800dc9:	39 fe                	cmp    %edi,%esi
  800dcb:	76 63                	jbe    800e30 <__umoddi3+0xa0>
  800dcd:	89 c8                	mov    %ecx,%eax
  800dcf:	89 fa                	mov    %edi,%edx
  800dd1:	f7 f6                	div    %esi
  800dd3:	89 d0                	mov    %edx,%eax
  800dd5:	31 d2                	xor    %edx,%edx
  800dd7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ddb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ddf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800de3:	83 c4 2c             	add    $0x2c,%esp
  800de6:	c3                   	ret    
  800de7:	90                   	nop
  800de8:	39 f8                	cmp    %edi,%eax
  800dea:	77 64                	ja     800e50 <__umoddi3+0xc0>
  800dec:	0f bd e8             	bsr    %eax,%ebp
  800def:	83 f5 1f             	xor    $0x1f,%ebp
  800df2:	75 74                	jne    800e68 <__umoddi3+0xd8>
  800df4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800df8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800dfc:	0f 87 0e 01 00 00    	ja     800f10 <__umoddi3+0x180>
  800e02:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800e06:	29 f1                	sub    %esi,%ecx
  800e08:	19 c7                	sbb    %eax,%edi
  800e0a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800e0e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800e12:	8b 44 24 14          	mov    0x14(%esp),%eax
  800e16:	8b 54 24 18          	mov    0x18(%esp),%edx
  800e1a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e1e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e22:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e26:	83 c4 2c             	add    $0x2c,%esp
  800e29:	c3                   	ret    
  800e2a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e30:	85 f6                	test   %esi,%esi
  800e32:	89 f5                	mov    %esi,%ebp
  800e34:	75 0b                	jne    800e41 <__umoddi3+0xb1>
  800e36:	b8 01 00 00 00       	mov    $0x1,%eax
  800e3b:	31 d2                	xor    %edx,%edx
  800e3d:	f7 f6                	div    %esi
  800e3f:	89 c5                	mov    %eax,%ebp
  800e41:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e45:	31 d2                	xor    %edx,%edx
  800e47:	f7 f5                	div    %ebp
  800e49:	89 c8                	mov    %ecx,%eax
  800e4b:	f7 f5                	div    %ebp
  800e4d:	eb 84                	jmp    800dd3 <__umoddi3+0x43>
  800e4f:	90                   	nop
  800e50:	89 c8                	mov    %ecx,%eax
  800e52:	89 fa                	mov    %edi,%edx
  800e54:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e58:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e5c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e60:	83 c4 2c             	add    $0x2c,%esp
  800e63:	c3                   	ret    
  800e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e68:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e6c:	be 20 00 00 00       	mov    $0x20,%esi
  800e71:	89 e9                	mov    %ebp,%ecx
  800e73:	29 ee                	sub    %ebp,%esi
  800e75:	d3 e2                	shl    %cl,%edx
  800e77:	89 f1                	mov    %esi,%ecx
  800e79:	d3 e8                	shr    %cl,%eax
  800e7b:	89 e9                	mov    %ebp,%ecx
  800e7d:	09 d0                	or     %edx,%eax
  800e7f:	89 fa                	mov    %edi,%edx
  800e81:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e85:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e89:	d3 e0                	shl    %cl,%eax
  800e8b:	89 f1                	mov    %esi,%ecx
  800e8d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e91:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800e95:	d3 ea                	shr    %cl,%edx
  800e97:	89 e9                	mov    %ebp,%ecx
  800e99:	d3 e7                	shl    %cl,%edi
  800e9b:	89 f1                	mov    %esi,%ecx
  800e9d:	d3 e8                	shr    %cl,%eax
  800e9f:	89 e9                	mov    %ebp,%ecx
  800ea1:	09 f8                	or     %edi,%eax
  800ea3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800ea7:	f7 74 24 0c          	divl   0xc(%esp)
  800eab:	d3 e7                	shl    %cl,%edi
  800ead:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800eb1:	89 d7                	mov    %edx,%edi
  800eb3:	f7 64 24 10          	mull   0x10(%esp)
  800eb7:	39 d7                	cmp    %edx,%edi
  800eb9:	89 c1                	mov    %eax,%ecx
  800ebb:	89 54 24 14          	mov    %edx,0x14(%esp)
  800ebf:	72 3b                	jb     800efc <__umoddi3+0x16c>
  800ec1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800ec5:	72 31                	jb     800ef8 <__umoddi3+0x168>
  800ec7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800ecb:	29 c8                	sub    %ecx,%eax
  800ecd:	19 d7                	sbb    %edx,%edi
  800ecf:	89 e9                	mov    %ebp,%ecx
  800ed1:	89 fa                	mov    %edi,%edx
  800ed3:	d3 e8                	shr    %cl,%eax
  800ed5:	89 f1                	mov    %esi,%ecx
  800ed7:	d3 e2                	shl    %cl,%edx
  800ed9:	89 e9                	mov    %ebp,%ecx
  800edb:	09 d0                	or     %edx,%eax
  800edd:	89 fa                	mov    %edi,%edx
  800edf:	d3 ea                	shr    %cl,%edx
  800ee1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ee5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ee9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800eed:	83 c4 2c             	add    $0x2c,%esp
  800ef0:	c3                   	ret    
  800ef1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ef8:	39 d7                	cmp    %edx,%edi
  800efa:	75 cb                	jne    800ec7 <__umoddi3+0x137>
  800efc:	8b 54 24 14          	mov    0x14(%esp),%edx
  800f00:	89 c1                	mov    %eax,%ecx
  800f02:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800f06:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800f0a:	eb bb                	jmp    800ec7 <__umoddi3+0x137>
  800f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f10:	3b 44 24 18          	cmp    0x18(%esp),%eax
  800f14:	0f 82 e8 fe ff ff    	jb     800e02 <__umoddi3+0x72>
  800f1a:	e9 f3 fe ff ff       	jmp    800e12 <__umoddi3+0x82>
