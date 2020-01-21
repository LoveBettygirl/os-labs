
obj/user/evilhello：     文件格式 elf32-i386


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
  80002c:	e8 1e 00 00 00       	call   80004f <libmain>
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
	// try to print the kernel entry point as a string!  mua ha ha!
	sys_cputs((char*)0xf010000c, 100);
  800039:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  800040:	00 
  800041:	c7 04 24 0c 00 10 f0 	movl   $0xf010000c,(%esp)
  800048:	e8 68 00 00 00       	call   8000b5 <sys_cputs>
}
  80004d:	c9                   	leave  
  80004e:	c3                   	ret    

0080004f <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004f:	55                   	push   %ebp
  800050:	89 e5                	mov    %esp,%ebp
  800052:	83 ec 18             	sub    $0x18,%esp
  800055:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800058:	89 75 fc             	mov    %esi,-0x4(%ebp)
  80005b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005e:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	thisenv = &envs[ENVX(sys_getenvid())];
  800061:	e8 0b 01 00 00       	call   800171 <sys_getenvid>
  800066:	25 ff 03 00 00       	and    $0x3ff,%eax
  80006b:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80006e:	c1 e0 05             	shl    $0x5,%eax
  800071:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800076:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80007b:	85 db                	test   %ebx,%ebx
  80007d:	7e 07                	jle    800086 <libmain+0x37>
		binaryname = argv[0];
  80007f:	8b 06                	mov    (%esi),%eax
  800081:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800086:	89 74 24 04          	mov    %esi,0x4(%esp)
  80008a:	89 1c 24             	mov    %ebx,(%esp)
  80008d:	e8 a1 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800092:	e8 0a 00 00 00       	call   8000a1 <exit>
}
  800097:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  80009a:	8b 75 fc             	mov    -0x4(%ebp),%esi
  80009d:	89 ec                	mov    %ebp,%esp
  80009f:	5d                   	pop    %ebp
  8000a0:	c3                   	ret    

008000a1 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a1:	55                   	push   %ebp
  8000a2:	89 e5                	mov    %esp,%ebp
  8000a4:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000ae:	e8 61 00 00 00       	call   800114 <sys_env_destroy>
}
  8000b3:	c9                   	leave  
  8000b4:	c3                   	ret    

008000b5 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000b5:	55                   	push   %ebp
  8000b6:	89 e5                	mov    %esp,%ebp
  8000b8:	83 ec 0c             	sub    $0xc,%esp
  8000bb:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000be:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000c1:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  8000c4:	b8 00 00 00 00       	mov    $0x0,%eax
  8000c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000cc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000cf:	89 c3                	mov    %eax,%ebx
  8000d1:	89 c7                	mov    %eax,%edi
  8000d3:	89 c6                	mov    %eax,%esi
  8000d5:	cd 30                	int    $0x30
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000d7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000da:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000dd:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000e0:	89 ec                	mov    %ebp,%esp
  8000e2:	5d                   	pop    %ebp
  8000e3:	c3                   	ret    

008000e4 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000e4:	55                   	push   %ebp
  8000e5:	89 e5                	mov    %esp,%ebp
  8000e7:	83 ec 0c             	sub    $0xc,%esp
  8000ea:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000ed:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000f0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  8000f3:	ba 00 00 00 00       	mov    $0x0,%edx
  8000f8:	b8 01 00 00 00       	mov    $0x1,%eax
  8000fd:	89 d1                	mov    %edx,%ecx
  8000ff:	89 d3                	mov    %edx,%ebx
  800101:	89 d7                	mov    %edx,%edi
  800103:	89 d6                	mov    %edx,%esi
  800105:	cd 30                	int    $0x30
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800107:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80010a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80010d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800110:	89 ec                	mov    %ebp,%esp
  800112:	5d                   	pop    %ebp
  800113:	c3                   	ret    

00800114 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800114:	55                   	push   %ebp
  800115:	89 e5                	mov    %esp,%ebp
  800117:	83 ec 38             	sub    $0x38,%esp
  80011a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80011d:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800120:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800123:	b9 00 00 00 00       	mov    $0x0,%ecx
  800128:	b8 03 00 00 00       	mov    $0x3,%eax
  80012d:	8b 55 08             	mov    0x8(%ebp),%edx
  800130:	89 cb                	mov    %ecx,%ebx
  800132:	89 cf                	mov    %ecx,%edi
  800134:	89 ce                	mov    %ecx,%esi
  800136:	cd 30                	int    $0x30
	if(check && ret > 0)
  800138:	85 c0                	test   %eax,%eax
  80013a:	7e 28                	jle    800164 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80013c:	89 44 24 10          	mov    %eax,0x10(%esp)
  800140:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800147:	00 
  800148:	c7 44 24 08 4a 0f 80 	movl   $0x800f4a,0x8(%esp)
  80014f:	00 
  800150:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800157:	00 
  800158:	c7 04 24 67 0f 80 00 	movl   $0x800f67,(%esp)
  80015f:	e8 3d 00 00 00       	call   8001a1 <_panic>
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800164:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800167:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80016a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80016d:	89 ec                	mov    %ebp,%esp
  80016f:	5d                   	pop    %ebp
  800170:	c3                   	ret    

00800171 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800171:	55                   	push   %ebp
  800172:	89 e5                	mov    %esp,%ebp
  800174:	83 ec 0c             	sub    $0xc,%esp
  800177:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80017a:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80017d:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  800180:	ba 00 00 00 00       	mov    $0x0,%edx
  800185:	b8 02 00 00 00       	mov    $0x2,%eax
  80018a:	89 d1                	mov    %edx,%ecx
  80018c:	89 d3                	mov    %edx,%ebx
  80018e:	89 d7                	mov    %edx,%edi
  800190:	89 d6                	mov    %edx,%esi
  800192:	cd 30                	int    $0x30
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800194:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800197:	8b 75 f8             	mov    -0x8(%ebp),%esi
  80019a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80019d:	89 ec                	mov    %ebp,%esp
  80019f:	5d                   	pop    %ebp
  8001a0:	c3                   	ret    

008001a1 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001a1:	55                   	push   %ebp
  8001a2:	89 e5                	mov    %esp,%ebp
  8001a4:	56                   	push   %esi
  8001a5:	53                   	push   %ebx
  8001a6:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001a9:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001ac:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001b2:	e8 ba ff ff ff       	call   800171 <sys_getenvid>
  8001b7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001ba:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001be:	8b 55 08             	mov    0x8(%ebp),%edx
  8001c1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001c5:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001cd:	c7 04 24 78 0f 80 00 	movl   $0x800f78,(%esp)
  8001d4:	e8 c1 00 00 00       	call   80029a <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001d9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001dd:	8b 45 10             	mov    0x10(%ebp),%eax
  8001e0:	89 04 24             	mov    %eax,(%esp)
  8001e3:	e8 51 00 00 00       	call   800239 <vcprintf>
	cprintf("\n");
  8001e8:	c7 04 24 9c 0f 80 00 	movl   $0x800f9c,(%esp)
  8001ef:	e8 a6 00 00 00       	call   80029a <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001f4:	cc                   	int3   
  8001f5:	eb fd                	jmp    8001f4 <_panic+0x53>

008001f7 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001f7:	55                   	push   %ebp
  8001f8:	89 e5                	mov    %esp,%ebp
  8001fa:	53                   	push   %ebx
  8001fb:	83 ec 14             	sub    $0x14,%esp
  8001fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800201:	8b 03                	mov    (%ebx),%eax
  800203:	8b 55 08             	mov    0x8(%ebp),%edx
  800206:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  80020a:	83 c0 01             	add    $0x1,%eax
  80020d:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  80020f:	3d ff 00 00 00       	cmp    $0xff,%eax
  800214:	75 19                	jne    80022f <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800216:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80021d:	00 
  80021e:	8d 43 08             	lea    0x8(%ebx),%eax
  800221:	89 04 24             	mov    %eax,(%esp)
  800224:	e8 8c fe ff ff       	call   8000b5 <sys_cputs>
		b->idx = 0;
  800229:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  80022f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800233:	83 c4 14             	add    $0x14,%esp
  800236:	5b                   	pop    %ebx
  800237:	5d                   	pop    %ebp
  800238:	c3                   	ret    

00800239 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800239:	55                   	push   %ebp
  80023a:	89 e5                	mov    %esp,%ebp
  80023c:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800242:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800249:	00 00 00 
	b.cnt = 0;
  80024c:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800253:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800256:	8b 45 0c             	mov    0xc(%ebp),%eax
  800259:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80025d:	8b 45 08             	mov    0x8(%ebp),%eax
  800260:	89 44 24 08          	mov    %eax,0x8(%esp)
  800264:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80026a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80026e:	c7 04 24 f7 01 80 00 	movl   $0x8001f7,(%esp)
  800275:	e8 ab 01 00 00       	call   800425 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80027a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800280:	89 44 24 04          	mov    %eax,0x4(%esp)
  800284:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80028a:	89 04 24             	mov    %eax,(%esp)
  80028d:	e8 23 fe ff ff       	call   8000b5 <sys_cputs>

	return b.cnt;
}
  800292:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800298:	c9                   	leave  
  800299:	c3                   	ret    

0080029a <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80029a:	55                   	push   %ebp
  80029b:	89 e5                	mov    %esp,%ebp
  80029d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002a0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002a7:	8b 45 08             	mov    0x8(%ebp),%eax
  8002aa:	89 04 24             	mov    %eax,(%esp)
  8002ad:	e8 87 ff ff ff       	call   800239 <vcprintf>
	va_end(ap);

	return cnt;
}
  8002b2:	c9                   	leave  
  8002b3:	c3                   	ret    
  8002b4:	66 90                	xchg   %ax,%ax
  8002b6:	66 90                	xchg   %ax,%ax
  8002b8:	66 90                	xchg   %ax,%ax
  8002ba:	66 90                	xchg   %ax,%ax
  8002bc:	66 90                	xchg   %ax,%ax
  8002be:	66 90                	xchg   %ax,%ax

008002c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002c0:	55                   	push   %ebp
  8002c1:	89 e5                	mov    %esp,%ebp
  8002c3:	57                   	push   %edi
  8002c4:	56                   	push   %esi
  8002c5:	53                   	push   %ebx
  8002c6:	83 ec 4c             	sub    $0x4c,%esp
  8002c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002cc:	89 d7                	mov    %edx,%edi
  8002ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8002d1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8002d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002d7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8002da:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002dd:	85 db                	test   %ebx,%ebx
  8002df:	75 08                	jne    8002e9 <printnum+0x29>
  8002e1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002e4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8002e7:	77 6c                	ja     800355 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002e9:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8002ec:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8002f0:	83 ee 01             	sub    $0x1,%esi
  8002f3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002f7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002fa:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002fe:	8b 44 24 08          	mov    0x8(%esp),%eax
  800302:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800306:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800309:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  80030c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800313:	00 
  800314:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800317:	89 1c 24             	mov    %ebx,(%esp)
  80031a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  80031d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800321:	e8 2a 09 00 00       	call   800c50 <__udivdi3>
  800326:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800329:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  80032c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800330:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800334:	89 04 24             	mov    %eax,(%esp)
  800337:	89 54 24 04          	mov    %edx,0x4(%esp)
  80033b:	89 fa                	mov    %edi,%edx
  80033d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800340:	e8 7b ff ff ff       	call   8002c0 <printnum>
  800345:	eb 1b                	jmp    800362 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800347:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80034b:	8b 45 18             	mov    0x18(%ebp),%eax
  80034e:	89 04 24             	mov    %eax,(%esp)
  800351:	ff d3                	call   *%ebx
  800353:	eb 03                	jmp    800358 <printnum+0x98>
  800355:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
  800358:	83 ee 01             	sub    $0x1,%esi
  80035b:	85 f6                	test   %esi,%esi
  80035d:	7f e8                	jg     800347 <printnum+0x87>
  80035f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800362:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800366:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80036a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80036d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800371:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800378:	00 
  800379:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80037c:	89 1c 24             	mov    %ebx,(%esp)
  80037f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800382:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800386:	e8 15 0a 00 00       	call   800da0 <__umoddi3>
  80038b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80038f:	0f be 80 9e 0f 80 00 	movsbl 0x800f9e(%eax),%eax
  800396:	89 04 24             	mov    %eax,(%esp)
  800399:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80039c:	ff d0                	call   *%eax
}
  80039e:	83 c4 4c             	add    $0x4c,%esp
  8003a1:	5b                   	pop    %ebx
  8003a2:	5e                   	pop    %esi
  8003a3:	5f                   	pop    %edi
  8003a4:	5d                   	pop    %ebp
  8003a5:	c3                   	ret    

008003a6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003a6:	55                   	push   %ebp
  8003a7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003a9:	83 fa 01             	cmp    $0x1,%edx
  8003ac:	7e 0e                	jle    8003bc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003ae:	8b 10                	mov    (%eax),%edx
  8003b0:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003b3:	89 08                	mov    %ecx,(%eax)
  8003b5:	8b 02                	mov    (%edx),%eax
  8003b7:	8b 52 04             	mov    0x4(%edx),%edx
  8003ba:	eb 22                	jmp    8003de <getuint+0x38>
	else if (lflag)
  8003bc:	85 d2                	test   %edx,%edx
  8003be:	74 10                	je     8003d0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003c0:	8b 10                	mov    (%eax),%edx
  8003c2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003c5:	89 08                	mov    %ecx,(%eax)
  8003c7:	8b 02                	mov    (%edx),%eax
  8003c9:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ce:	eb 0e                	jmp    8003de <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003d0:	8b 10                	mov    (%eax),%edx
  8003d2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003d5:	89 08                	mov    %ecx,(%eax)
  8003d7:	8b 02                	mov    (%edx),%eax
  8003d9:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003de:	5d                   	pop    %ebp
  8003df:	c3                   	ret    

008003e0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003e0:	55                   	push   %ebp
  8003e1:	89 e5                	mov    %esp,%ebp
  8003e3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003e6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003ea:	8b 10                	mov    (%eax),%edx
  8003ec:	3b 50 04             	cmp    0x4(%eax),%edx
  8003ef:	73 0a                	jae    8003fb <sprintputch+0x1b>
		*b->buf++ = ch;
  8003f1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003f4:	88 0a                	mov    %cl,(%edx)
  8003f6:	83 c2 01             	add    $0x1,%edx
  8003f9:	89 10                	mov    %edx,(%eax)
}
  8003fb:	5d                   	pop    %ebp
  8003fc:	c3                   	ret    

008003fd <printfmt>:
{
  8003fd:	55                   	push   %ebp
  8003fe:	89 e5                	mov    %esp,%ebp
  800400:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
  800403:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800406:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80040a:	8b 45 10             	mov    0x10(%ebp),%eax
  80040d:	89 44 24 08          	mov    %eax,0x8(%esp)
  800411:	8b 45 0c             	mov    0xc(%ebp),%eax
  800414:	89 44 24 04          	mov    %eax,0x4(%esp)
  800418:	8b 45 08             	mov    0x8(%ebp),%eax
  80041b:	89 04 24             	mov    %eax,(%esp)
  80041e:	e8 02 00 00 00       	call   800425 <vprintfmt>
}
  800423:	c9                   	leave  
  800424:	c3                   	ret    

00800425 <vprintfmt>:
{
  800425:	55                   	push   %ebp
  800426:	89 e5                	mov    %esp,%ebp
  800428:	57                   	push   %edi
  800429:	56                   	push   %esi
  80042a:	53                   	push   %ebx
  80042b:	83 ec 4c             	sub    $0x4c,%esp
  80042e:	8b 75 08             	mov    0x8(%ebp),%esi
  800431:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800434:	8b 7d 10             	mov    0x10(%ebp),%edi
  800437:	eb 11                	jmp    80044a <vprintfmt+0x25>
			if (ch == '\0')
  800439:	85 c0                	test   %eax,%eax
  80043b:	0f 84 cf 03 00 00    	je     800810 <vprintfmt+0x3eb>
			putch(ch, putdat);
  800441:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800445:	89 04 24             	mov    %eax,(%esp)
  800448:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80044a:	0f b6 07             	movzbl (%edi),%eax
  80044d:	83 c7 01             	add    $0x1,%edi
  800450:	83 f8 25             	cmp    $0x25,%eax
  800453:	75 e4                	jne    800439 <vprintfmt+0x14>
  800455:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800459:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  800460:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800467:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80046e:	ba 00 00 00 00       	mov    $0x0,%edx
  800473:	eb 2b                	jmp    8004a0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800475:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
  800478:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  80047c:	eb 22                	jmp    8004a0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  80047e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
  800481:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800485:	eb 19                	jmp    8004a0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800487:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
  80048a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800491:	eb 0d                	jmp    8004a0 <vprintfmt+0x7b>
				width = precision, precision = -1;
  800493:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800496:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800499:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8004a0:	0f b6 07             	movzbl (%edi),%eax
  8004a3:	8d 4f 01             	lea    0x1(%edi),%ecx
  8004a6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8004a9:	0f b6 0f             	movzbl (%edi),%ecx
  8004ac:	83 e9 23             	sub    $0x23,%ecx
  8004af:	80 f9 55             	cmp    $0x55,%cl
  8004b2:	0f 87 3b 03 00 00    	ja     8007f3 <vprintfmt+0x3ce>
  8004b8:	0f b6 c9             	movzbl %cl,%ecx
  8004bb:	ff 24 8d 40 10 80 00 	jmp    *0x801040(,%ecx,4)
  8004c2:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004c5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  8004cc:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8004cf:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
  8004d4:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8004d7:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8004db:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8004de:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004e1:	83 f9 09             	cmp    $0x9,%ecx
  8004e4:	77 2f                	ja     800515 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
  8004e6:	83 c7 01             	add    $0x1,%edi
			}
  8004e9:	eb e9                	jmp    8004d4 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
  8004eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ee:	8d 48 04             	lea    0x4(%eax),%ecx
  8004f1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004f4:	8b 00                	mov    (%eax),%eax
  8004f6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8004f9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
  8004fc:	eb 1d                	jmp    80051b <vprintfmt+0xf6>
			if (width < 0)
  8004fe:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800502:	78 83                	js     800487 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
  800504:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800507:	eb 97                	jmp    8004a0 <vprintfmt+0x7b>
  800509:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
  80050c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  800513:	eb 8b                	jmp    8004a0 <vprintfmt+0x7b>
  800515:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800518:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
  80051b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80051f:	0f 89 7b ff ff ff    	jns    8004a0 <vprintfmt+0x7b>
  800525:	e9 69 ff ff ff       	jmp    800493 <vprintfmt+0x6e>
			lflag++;
  80052a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
  80052d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
  800530:	e9 6b ff ff ff       	jmp    8004a0 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
  800535:	8b 45 14             	mov    0x14(%ebp),%eax
  800538:	8d 50 04             	lea    0x4(%eax),%edx
  80053b:	89 55 14             	mov    %edx,0x14(%ebp)
  80053e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800542:	8b 00                	mov    (%eax),%eax
  800544:	89 04 24             	mov    %eax,(%esp)
  800547:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  800549:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  80054c:	e9 f9 fe ff ff       	jmp    80044a <vprintfmt+0x25>
			err = va_arg(ap, int);
  800551:	8b 45 14             	mov    0x14(%ebp),%eax
  800554:	8d 50 04             	lea    0x4(%eax),%edx
  800557:	89 55 14             	mov    %edx,0x14(%ebp)
  80055a:	8b 00                	mov    (%eax),%eax
  80055c:	89 c2                	mov    %eax,%edx
  80055e:	c1 fa 1f             	sar    $0x1f,%edx
  800561:	31 d0                	xor    %edx,%eax
  800563:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800565:	83 f8 07             	cmp    $0x7,%eax
  800568:	7f 0b                	jg     800575 <vprintfmt+0x150>
  80056a:	8b 14 85 a0 11 80 00 	mov    0x8011a0(,%eax,4),%edx
  800571:	85 d2                	test   %edx,%edx
  800573:	75 20                	jne    800595 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
  800575:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800579:	c7 44 24 08 b6 0f 80 	movl   $0x800fb6,0x8(%esp)
  800580:	00 
  800581:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800585:	89 34 24             	mov    %esi,(%esp)
  800588:	e8 70 fe ff ff       	call   8003fd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80058d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
  800590:	e9 b5 fe ff ff       	jmp    80044a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
  800595:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800599:	c7 44 24 08 bf 0f 80 	movl   $0x800fbf,0x8(%esp)
  8005a0:	00 
  8005a1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005a5:	89 34 24             	mov    %esi,(%esp)
  8005a8:	e8 50 fe ff ff       	call   8003fd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  8005ad:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8005b0:	e9 95 fe ff ff       	jmp    80044a <vprintfmt+0x25>
  8005b5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005b8:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8005bb:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
  8005be:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c1:	8d 50 04             	lea    0x4(%eax),%edx
  8005c4:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8005c9:	85 ff                	test   %edi,%edi
  8005cb:	b8 af 0f 80 00       	mov    $0x800faf,%eax
  8005d0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8005d3:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8005d7:	0f 84 9b 00 00 00    	je     800678 <vprintfmt+0x253>
  8005dd:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8005e1:	0f 8e 9f 00 00 00    	jle    800686 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005e7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005eb:	89 3c 24             	mov    %edi,(%esp)
  8005ee:	e8 c5 02 00 00       	call   8008b8 <strnlen>
  8005f3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8005f6:	29 c2                	sub    %eax,%edx
  8005f8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
  8005fb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8005ff:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  800602:	89 7d c8             	mov    %edi,-0x38(%ebp)
  800605:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  800607:	eb 0f                	jmp    800618 <vprintfmt+0x1f3>
					putch(padc, putdat);
  800609:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80060d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800610:	89 04 24             	mov    %eax,(%esp)
  800613:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  800615:	83 ef 01             	sub    $0x1,%edi
  800618:	85 ff                	test   %edi,%edi
  80061a:	7f ed                	jg     800609 <vprintfmt+0x1e4>
  80061c:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  80061f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800623:	b8 00 00 00 00       	mov    $0x0,%eax
  800628:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
  80062c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80062f:	29 c2                	sub    %eax,%edx
  800631:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800634:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800637:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80063a:	89 d3                	mov    %edx,%ebx
  80063c:	eb 54                	jmp    800692 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
  80063e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800642:	74 20                	je     800664 <vprintfmt+0x23f>
  800644:	0f be d2             	movsbl %dl,%edx
  800647:	83 ea 20             	sub    $0x20,%edx
  80064a:	83 fa 5e             	cmp    $0x5e,%edx
  80064d:	76 15                	jbe    800664 <vprintfmt+0x23f>
					putch('?', putdat);
  80064f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800652:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800656:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80065d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800660:	ff d0                	call   *%eax
  800662:	eb 0f                	jmp    800673 <vprintfmt+0x24e>
					putch(ch, putdat);
  800664:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800667:	89 54 24 04          	mov    %edx,0x4(%esp)
  80066b:	89 04 24             	mov    %eax,(%esp)
  80066e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800671:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800673:	83 eb 01             	sub    $0x1,%ebx
  800676:	eb 1a                	jmp    800692 <vprintfmt+0x26d>
  800678:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  80067b:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80067e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800681:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800684:	eb 0c                	jmp    800692 <vprintfmt+0x26d>
  800686:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800689:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80068c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80068f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800692:	0f b6 17             	movzbl (%edi),%edx
  800695:	0f be c2             	movsbl %dl,%eax
  800698:	83 c7 01             	add    $0x1,%edi
  80069b:	85 c0                	test   %eax,%eax
  80069d:	74 29                	je     8006c8 <vprintfmt+0x2a3>
  80069f:	85 f6                	test   %esi,%esi
  8006a1:	78 9b                	js     80063e <vprintfmt+0x219>
  8006a3:	83 ee 01             	sub    $0x1,%esi
  8006a6:	79 96                	jns    80063e <vprintfmt+0x219>
  8006a8:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8006ab:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006ae:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006b1:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8006b4:	eb 1a                	jmp    8006d0 <vprintfmt+0x2ab>
				putch(' ', putdat);
  8006b6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006ba:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006c1:	ff d6                	call   *%esi
			for (; width > 0; width--)
  8006c3:	83 ef 01             	sub    $0x1,%edi
  8006c6:	eb 08                	jmp    8006d0 <vprintfmt+0x2ab>
  8006c8:	89 df                	mov    %ebx,%edi
  8006ca:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006cd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006d0:	85 ff                	test   %edi,%edi
  8006d2:	7f e2                	jg     8006b6 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
  8006d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006d7:	e9 6e fd ff ff       	jmp    80044a <vprintfmt+0x25>
	if (lflag >= 2)
  8006dc:	83 fa 01             	cmp    $0x1,%edx
  8006df:	7e 16                	jle    8006f7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
  8006e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e4:	8d 50 08             	lea    0x8(%eax),%edx
  8006e7:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ea:	8b 10                	mov    (%eax),%edx
  8006ec:	8b 48 04             	mov    0x4(%eax),%ecx
  8006ef:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8006f2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006f5:	eb 32                	jmp    800729 <vprintfmt+0x304>
	else if (lflag)
  8006f7:	85 d2                	test   %edx,%edx
  8006f9:	74 18                	je     800713 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
  8006fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fe:	8d 50 04             	lea    0x4(%eax),%edx
  800701:	89 55 14             	mov    %edx,0x14(%ebp)
  800704:	8b 00                	mov    (%eax),%eax
  800706:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800709:	89 c1                	mov    %eax,%ecx
  80070b:	c1 f9 1f             	sar    $0x1f,%ecx
  80070e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800711:	eb 16                	jmp    800729 <vprintfmt+0x304>
		return va_arg(*ap, int);
  800713:	8b 45 14             	mov    0x14(%ebp),%eax
  800716:	8d 50 04             	lea    0x4(%eax),%edx
  800719:	89 55 14             	mov    %edx,0x14(%ebp)
  80071c:	8b 00                	mov    (%eax),%eax
  80071e:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800721:	89 c7                	mov    %eax,%edi
  800723:	c1 ff 1f             	sar    $0x1f,%edi
  800726:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
  800729:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80072c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
  80072f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
  800734:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800738:	79 7d                	jns    8007b7 <vprintfmt+0x392>
				putch('-', putdat);
  80073a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80073e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800745:	ff d6                	call   *%esi
				num = -(long long) num;
  800747:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80074a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80074d:	f7 d8                	neg    %eax
  80074f:	83 d2 00             	adc    $0x0,%edx
  800752:	f7 da                	neg    %edx
			base = 10;
  800754:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800759:	eb 5c                	jmp    8007b7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80075b:	8d 45 14             	lea    0x14(%ebp),%eax
  80075e:	e8 43 fc ff ff       	call   8003a6 <getuint>
			base = 10;
  800763:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800768:	eb 4d                	jmp    8007b7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80076a:	8d 45 14             	lea    0x14(%ebp),%eax
  80076d:	e8 34 fc ff ff       	call   8003a6 <getuint>
			base = 8;
  800772:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800777:	eb 3e                	jmp    8007b7 <vprintfmt+0x392>
			putch('0', putdat);
  800779:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80077d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800784:	ff d6                	call   *%esi
			putch('x', putdat);
  800786:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80078a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800791:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
  800793:	8b 45 14             	mov    0x14(%ebp),%eax
  800796:	8d 50 04             	lea    0x4(%eax),%edx
  800799:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
  80079c:	8b 00                	mov    (%eax),%eax
  80079e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
  8007a3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007a8:	eb 0d                	jmp    8007b7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  8007aa:	8d 45 14             	lea    0x14(%ebp),%eax
  8007ad:	e8 f4 fb ff ff       	call   8003a6 <getuint>
			base = 16;
  8007b2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
  8007b7:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  8007bb:	89 7c 24 10          	mov    %edi,0x10(%esp)
  8007bf:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8007c2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8007c6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007ca:	89 04 24             	mov    %eax,(%esp)
  8007cd:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007d1:	89 da                	mov    %ebx,%edx
  8007d3:	89 f0                	mov    %esi,%eax
  8007d5:	e8 e6 fa ff ff       	call   8002c0 <printnum>
			break;
  8007da:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007dd:	e9 68 fc ff ff       	jmp    80044a <vprintfmt+0x25>
			putch(ch, putdat);
  8007e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007e6:	89 04 24             	mov    %eax,(%esp)
  8007e9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  8007eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  8007ee:	e9 57 fc ff ff       	jmp    80044a <vprintfmt+0x25>
			putch('%', putdat);
  8007f3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007f7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007fe:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800800:	eb 03                	jmp    800805 <vprintfmt+0x3e0>
  800802:	83 ef 01             	sub    $0x1,%edi
  800805:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800809:	75 f7                	jne    800802 <vprintfmt+0x3dd>
  80080b:	e9 3a fc ff ff       	jmp    80044a <vprintfmt+0x25>
}
  800810:	83 c4 4c             	add    $0x4c,%esp
  800813:	5b                   	pop    %ebx
  800814:	5e                   	pop    %esi
  800815:	5f                   	pop    %edi
  800816:	5d                   	pop    %ebp
  800817:	c3                   	ret    

00800818 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800818:	55                   	push   %ebp
  800819:	89 e5                	mov    %esp,%ebp
  80081b:	83 ec 28             	sub    $0x28,%esp
  80081e:	8b 45 08             	mov    0x8(%ebp),%eax
  800821:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800824:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800827:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80082b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80082e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800835:	85 d2                	test   %edx,%edx
  800837:	7e 30                	jle    800869 <vsnprintf+0x51>
  800839:	85 c0                	test   %eax,%eax
  80083b:	74 2c                	je     800869 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80083d:	8b 45 14             	mov    0x14(%ebp),%eax
  800840:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800844:	8b 45 10             	mov    0x10(%ebp),%eax
  800847:	89 44 24 08          	mov    %eax,0x8(%esp)
  80084b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80084e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800852:	c7 04 24 e0 03 80 00 	movl   $0x8003e0,(%esp)
  800859:	e8 c7 fb ff ff       	call   800425 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80085e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800861:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800864:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800867:	eb 05                	jmp    80086e <vsnprintf+0x56>
		return -E_INVAL;
  800869:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  80086e:	c9                   	leave  
  80086f:	c3                   	ret    

00800870 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800870:	55                   	push   %ebp
  800871:	89 e5                	mov    %esp,%ebp
  800873:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800876:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800879:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80087d:	8b 45 10             	mov    0x10(%ebp),%eax
  800880:	89 44 24 08          	mov    %eax,0x8(%esp)
  800884:	8b 45 0c             	mov    0xc(%ebp),%eax
  800887:	89 44 24 04          	mov    %eax,0x4(%esp)
  80088b:	8b 45 08             	mov    0x8(%ebp),%eax
  80088e:	89 04 24             	mov    %eax,(%esp)
  800891:	e8 82 ff ff ff       	call   800818 <vsnprintf>
	va_end(ap);

	return rc;
}
  800896:	c9                   	leave  
  800897:	c3                   	ret    
  800898:	66 90                	xchg   %ax,%ax
  80089a:	66 90                	xchg   %ax,%ax
  80089c:	66 90                	xchg   %ax,%ax
  80089e:	66 90                	xchg   %ax,%ax

008008a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008a0:	55                   	push   %ebp
  8008a1:	89 e5                	mov    %esp,%ebp
  8008a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008a6:	b8 00 00 00 00       	mov    $0x0,%eax
  8008ab:	eb 03                	jmp    8008b0 <strlen+0x10>
		n++;
  8008ad:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  8008b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008b4:	75 f7                	jne    8008ad <strlen+0xd>
	return n;
}
  8008b6:	5d                   	pop    %ebp
  8008b7:	c3                   	ret    

008008b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008b8:	55                   	push   %ebp
  8008b9:	89 e5                	mov    %esp,%ebp
  8008bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
  8008be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008c1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008c6:	eb 03                	jmp    8008cb <strnlen+0x13>
		n++;
  8008c8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008cb:	39 d0                	cmp    %edx,%eax
  8008cd:	74 06                	je     8008d5 <strnlen+0x1d>
  8008cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8008d3:	75 f3                	jne    8008c8 <strnlen+0x10>
	return n;
}
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	53                   	push   %ebx
  8008db:	8b 45 08             	mov    0x8(%ebp),%eax
  8008de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008e1:	89 c2                	mov    %eax,%edx
  8008e3:	0f b6 19             	movzbl (%ecx),%ebx
  8008e6:	88 1a                	mov    %bl,(%edx)
  8008e8:	83 c2 01             	add    $0x1,%edx
  8008eb:	83 c1 01             	add    $0x1,%ecx
  8008ee:	84 db                	test   %bl,%bl
  8008f0:	75 f1                	jne    8008e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008f2:	5b                   	pop    %ebx
  8008f3:	5d                   	pop    %ebp
  8008f4:	c3                   	ret    

008008f5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008f5:	55                   	push   %ebp
  8008f6:	89 e5                	mov    %esp,%ebp
  8008f8:	53                   	push   %ebx
  8008f9:	83 ec 08             	sub    $0x8,%esp
  8008fc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008ff:	89 1c 24             	mov    %ebx,(%esp)
  800902:	e8 99 ff ff ff       	call   8008a0 <strlen>
	strcpy(dst + len, src);
  800907:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80090e:	01 d8                	add    %ebx,%eax
  800910:	89 04 24             	mov    %eax,(%esp)
  800913:	e8 bf ff ff ff       	call   8008d7 <strcpy>
	return dst;
}
  800918:	89 d8                	mov    %ebx,%eax
  80091a:	83 c4 08             	add    $0x8,%esp
  80091d:	5b                   	pop    %ebx
  80091e:	5d                   	pop    %ebp
  80091f:	c3                   	ret    

00800920 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800920:	55                   	push   %ebp
  800921:	89 e5                	mov    %esp,%ebp
  800923:	56                   	push   %esi
  800924:	53                   	push   %ebx
  800925:	8b 75 08             	mov    0x8(%ebp),%esi
  800928:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80092b:	89 f3                	mov    %esi,%ebx
  80092d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800930:	89 f2                	mov    %esi,%edx
  800932:	eb 0e                	jmp    800942 <strncpy+0x22>
		*dst++ = *src;
  800934:	0f b6 01             	movzbl (%ecx),%eax
  800937:	88 02                	mov    %al,(%edx)
  800939:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80093c:	80 39 01             	cmpb   $0x1,(%ecx)
  80093f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800942:	39 da                	cmp    %ebx,%edx
  800944:	75 ee                	jne    800934 <strncpy+0x14>
	}
	return ret;
}
  800946:	89 f0                	mov    %esi,%eax
  800948:	5b                   	pop    %ebx
  800949:	5e                   	pop    %esi
  80094a:	5d                   	pop    %ebp
  80094b:	c3                   	ret    

0080094c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80094c:	55                   	push   %ebp
  80094d:	89 e5                	mov    %esp,%ebp
  80094f:	56                   	push   %esi
  800950:	53                   	push   %ebx
  800951:	8b 75 08             	mov    0x8(%ebp),%esi
  800954:	8b 55 0c             	mov    0xc(%ebp),%edx
  800957:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80095a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
  80095c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
  800960:	85 c9                	test   %ecx,%ecx
  800962:	75 0a                	jne    80096e <strlcpy+0x22>
  800964:	eb 1c                	jmp    800982 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800966:	88 08                	mov    %cl,(%eax)
  800968:	83 c0 01             	add    $0x1,%eax
  80096b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
  80096e:	39 d8                	cmp    %ebx,%eax
  800970:	74 0b                	je     80097d <strlcpy+0x31>
  800972:	0f b6 0a             	movzbl (%edx),%ecx
  800975:	84 c9                	test   %cl,%cl
  800977:	75 ed                	jne    800966 <strlcpy+0x1a>
  800979:	89 c2                	mov    %eax,%edx
  80097b:	eb 02                	jmp    80097f <strlcpy+0x33>
  80097d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
  80097f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800982:	29 f0                	sub    %esi,%eax
}
  800984:	5b                   	pop    %ebx
  800985:	5e                   	pop    %esi
  800986:	5d                   	pop    %ebp
  800987:	c3                   	ret    

00800988 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800988:	55                   	push   %ebp
  800989:	89 e5                	mov    %esp,%ebp
  80098b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80098e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800991:	eb 06                	jmp    800999 <strcmp+0x11>
		p++, q++;
  800993:	83 c1 01             	add    $0x1,%ecx
  800996:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800999:	0f b6 01             	movzbl (%ecx),%eax
  80099c:	84 c0                	test   %al,%al
  80099e:	74 04                	je     8009a4 <strcmp+0x1c>
  8009a0:	3a 02                	cmp    (%edx),%al
  8009a2:	74 ef                	je     800993 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009a4:	0f b6 c0             	movzbl %al,%eax
  8009a7:	0f b6 12             	movzbl (%edx),%edx
  8009aa:	29 d0                	sub    %edx,%eax
}
  8009ac:	5d                   	pop    %ebp
  8009ad:	c3                   	ret    

008009ae <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009ae:	55                   	push   %ebp
  8009af:	89 e5                	mov    %esp,%ebp
  8009b1:	53                   	push   %ebx
  8009b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b5:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
  8009b8:	89 c3                	mov    %eax,%ebx
  8009ba:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009bd:	eb 06                	jmp    8009c5 <strncmp+0x17>
		n--, p++, q++;
  8009bf:	83 c0 01             	add    $0x1,%eax
  8009c2:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  8009c5:	39 d8                	cmp    %ebx,%eax
  8009c7:	74 15                	je     8009de <strncmp+0x30>
  8009c9:	0f b6 08             	movzbl (%eax),%ecx
  8009cc:	84 c9                	test   %cl,%cl
  8009ce:	74 04                	je     8009d4 <strncmp+0x26>
  8009d0:	3a 0a                	cmp    (%edx),%cl
  8009d2:	74 eb                	je     8009bf <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d4:	0f b6 00             	movzbl (%eax),%eax
  8009d7:	0f b6 12             	movzbl (%edx),%edx
  8009da:	29 d0                	sub    %edx,%eax
  8009dc:	eb 05                	jmp    8009e3 <strncmp+0x35>
		return 0;
  8009de:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e3:	5b                   	pop    %ebx
  8009e4:	5d                   	pop    %ebp
  8009e5:	c3                   	ret    

008009e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009e6:	55                   	push   %ebp
  8009e7:	89 e5                	mov    %esp,%ebp
  8009e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009f0:	eb 07                	jmp    8009f9 <strchr+0x13>
		if (*s == c)
  8009f2:	38 ca                	cmp    %cl,%dl
  8009f4:	74 0f                	je     800a05 <strchr+0x1f>
	for (; *s; s++)
  8009f6:	83 c0 01             	add    $0x1,%eax
  8009f9:	0f b6 10             	movzbl (%eax),%edx
  8009fc:	84 d2                	test   %dl,%dl
  8009fe:	75 f2                	jne    8009f2 <strchr+0xc>
			return (char *) s;
	return 0;
  800a00:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a05:	5d                   	pop    %ebp
  800a06:	c3                   	ret    

00800a07 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a07:	55                   	push   %ebp
  800a08:	89 e5                	mov    %esp,%ebp
  800a0a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a0d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a11:	eb 07                	jmp    800a1a <strfind+0x13>
		if (*s == c)
  800a13:	38 ca                	cmp    %cl,%dl
  800a15:	74 0a                	je     800a21 <strfind+0x1a>
	for (; *s; s++)
  800a17:	83 c0 01             	add    $0x1,%eax
  800a1a:	0f b6 10             	movzbl (%eax),%edx
  800a1d:	84 d2                	test   %dl,%dl
  800a1f:	75 f2                	jne    800a13 <strfind+0xc>
			break;
	return (char *) s;
}
  800a21:	5d                   	pop    %ebp
  800a22:	c3                   	ret    

00800a23 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a23:	55                   	push   %ebp
  800a24:	89 e5                	mov    %esp,%ebp
  800a26:	83 ec 0c             	sub    $0xc,%esp
  800a29:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800a2c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a2f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a32:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a35:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a38:	85 c9                	test   %ecx,%ecx
  800a3a:	74 36                	je     800a72 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a3c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a42:	75 28                	jne    800a6c <memset+0x49>
  800a44:	f6 c1 03             	test   $0x3,%cl
  800a47:	75 23                	jne    800a6c <memset+0x49>
		c &= 0xFF;
  800a49:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a4d:	89 d3                	mov    %edx,%ebx
  800a4f:	c1 e3 08             	shl    $0x8,%ebx
  800a52:	89 d6                	mov    %edx,%esi
  800a54:	c1 e6 18             	shl    $0x18,%esi
  800a57:	89 d0                	mov    %edx,%eax
  800a59:	c1 e0 10             	shl    $0x10,%eax
  800a5c:	09 f0                	or     %esi,%eax
  800a5e:	09 c2                	or     %eax,%edx
  800a60:	89 d0                	mov    %edx,%eax
  800a62:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a64:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800a67:	fc                   	cld    
  800a68:	f3 ab                	rep stos %eax,%es:(%edi)
  800a6a:	eb 06                	jmp    800a72 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a6c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a6f:	fc                   	cld    
  800a70:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a72:	89 f8                	mov    %edi,%eax
  800a74:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a77:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a7a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a7d:	89 ec                	mov    %ebp,%esp
  800a7f:	5d                   	pop    %ebp
  800a80:	c3                   	ret    

00800a81 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a81:	55                   	push   %ebp
  800a82:	89 e5                	mov    %esp,%ebp
  800a84:	83 ec 08             	sub    $0x8,%esp
  800a87:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a8a:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a8d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a90:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a93:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a96:	39 c6                	cmp    %eax,%esi
  800a98:	73 36                	jae    800ad0 <memmove+0x4f>
  800a9a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a9d:	39 d0                	cmp    %edx,%eax
  800a9f:	73 2f                	jae    800ad0 <memmove+0x4f>
		s += n;
		d += n;
  800aa1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800aa4:	f6 c2 03             	test   $0x3,%dl
  800aa7:	75 1b                	jne    800ac4 <memmove+0x43>
  800aa9:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800aaf:	75 13                	jne    800ac4 <memmove+0x43>
  800ab1:	f6 c1 03             	test   $0x3,%cl
  800ab4:	75 0e                	jne    800ac4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ab6:	83 ef 04             	sub    $0x4,%edi
  800ab9:	8d 72 fc             	lea    -0x4(%edx),%esi
  800abc:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  800abf:	fd                   	std    
  800ac0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ac2:	eb 09                	jmp    800acd <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800ac4:	83 ef 01             	sub    $0x1,%edi
  800ac7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  800aca:	fd                   	std    
  800acb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800acd:	fc                   	cld    
  800ace:	eb 20                	jmp    800af0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ad0:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ad6:	75 13                	jne    800aeb <memmove+0x6a>
  800ad8:	a8 03                	test   $0x3,%al
  800ada:	75 0f                	jne    800aeb <memmove+0x6a>
  800adc:	f6 c1 03             	test   $0x3,%cl
  800adf:	75 0a                	jne    800aeb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800ae1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  800ae4:	89 c7                	mov    %eax,%edi
  800ae6:	fc                   	cld    
  800ae7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ae9:	eb 05                	jmp    800af0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
  800aeb:	89 c7                	mov    %eax,%edi
  800aed:	fc                   	cld    
  800aee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800af0:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800af3:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800af6:	89 ec                	mov    %ebp,%esp
  800af8:	5d                   	pop    %ebp
  800af9:	c3                   	ret    

00800afa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800afa:	55                   	push   %ebp
  800afb:	89 e5                	mov    %esp,%ebp
  800afd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b00:	8b 45 10             	mov    0x10(%ebp),%eax
  800b03:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b07:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b0a:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b0e:	8b 45 08             	mov    0x8(%ebp),%eax
  800b11:	89 04 24             	mov    %eax,(%esp)
  800b14:	e8 68 ff ff ff       	call   800a81 <memmove>
}
  800b19:	c9                   	leave  
  800b1a:	c3                   	ret    

00800b1b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b1b:	55                   	push   %ebp
  800b1c:	89 e5                	mov    %esp,%ebp
  800b1e:	56                   	push   %esi
  800b1f:	53                   	push   %ebx
  800b20:	8b 55 08             	mov    0x8(%ebp),%edx
  800b23:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
  800b26:	89 d6                	mov    %edx,%esi
  800b28:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b2b:	eb 1a                	jmp    800b47 <memcmp+0x2c>
		if (*s1 != *s2)
  800b2d:	0f b6 02             	movzbl (%edx),%eax
  800b30:	0f b6 19             	movzbl (%ecx),%ebx
  800b33:	38 d8                	cmp    %bl,%al
  800b35:	74 0a                	je     800b41 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b37:	0f b6 c0             	movzbl %al,%eax
  800b3a:	0f b6 db             	movzbl %bl,%ebx
  800b3d:	29 d8                	sub    %ebx,%eax
  800b3f:	eb 0f                	jmp    800b50 <memcmp+0x35>
		s1++, s2++;
  800b41:	83 c2 01             	add    $0x1,%edx
  800b44:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
  800b47:	39 f2                	cmp    %esi,%edx
  800b49:	75 e2                	jne    800b2d <memcmp+0x12>
	}

	return 0;
  800b4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b50:	5b                   	pop    %ebx
  800b51:	5e                   	pop    %esi
  800b52:	5d                   	pop    %ebp
  800b53:	c3                   	ret    

00800b54 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b54:	55                   	push   %ebp
  800b55:	89 e5                	mov    %esp,%ebp
  800b57:	8b 45 08             	mov    0x8(%ebp),%eax
  800b5a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b5d:	89 c2                	mov    %eax,%edx
  800b5f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b62:	eb 07                	jmp    800b6b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b64:	38 08                	cmp    %cl,(%eax)
  800b66:	74 07                	je     800b6f <memfind+0x1b>
	for (; s < ends; s++)
  800b68:	83 c0 01             	add    $0x1,%eax
  800b6b:	39 d0                	cmp    %edx,%eax
  800b6d:	72 f5                	jb     800b64 <memfind+0x10>
			break;
	return (void *) s;
}
  800b6f:	5d                   	pop    %ebp
  800b70:	c3                   	ret    

00800b71 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b71:	55                   	push   %ebp
  800b72:	89 e5                	mov    %esp,%ebp
  800b74:	57                   	push   %edi
  800b75:	56                   	push   %esi
  800b76:	53                   	push   %ebx
  800b77:	83 ec 04             	sub    $0x4,%esp
  800b7a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b7d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b80:	eb 03                	jmp    800b85 <strtol+0x14>
		s++;
  800b82:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
  800b85:	0f b6 02             	movzbl (%edx),%eax
  800b88:	3c 09                	cmp    $0x9,%al
  800b8a:	74 f6                	je     800b82 <strtol+0x11>
  800b8c:	3c 20                	cmp    $0x20,%al
  800b8e:	74 f2                	je     800b82 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
  800b90:	3c 2b                	cmp    $0x2b,%al
  800b92:	75 0a                	jne    800b9e <strtol+0x2d>
		s++;
  800b94:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
  800b97:	bf 00 00 00 00       	mov    $0x0,%edi
  800b9c:	eb 10                	jmp    800bae <strtol+0x3d>
  800b9e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
  800ba3:	3c 2d                	cmp    $0x2d,%al
  800ba5:	75 07                	jne    800bae <strtol+0x3d>
		s++, neg = 1;
  800ba7:	8d 52 01             	lea    0x1(%edx),%edx
  800baa:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800bae:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800bb4:	75 15                	jne    800bcb <strtol+0x5a>
  800bb6:	80 3a 30             	cmpb   $0x30,(%edx)
  800bb9:	75 10                	jne    800bcb <strtol+0x5a>
  800bbb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800bbf:	75 0a                	jne    800bcb <strtol+0x5a>
		s += 2, base = 16;
  800bc1:	83 c2 02             	add    $0x2,%edx
  800bc4:	bb 10 00 00 00       	mov    $0x10,%ebx
  800bc9:	eb 10                	jmp    800bdb <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800bcb:	85 db                	test   %ebx,%ebx
  800bcd:	75 0c                	jne    800bdb <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800bcf:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
  800bd1:	80 3a 30             	cmpb   $0x30,(%edx)
  800bd4:	75 05                	jne    800bdb <strtol+0x6a>
		s++, base = 8;
  800bd6:	83 c2 01             	add    $0x1,%edx
  800bd9:	b3 08                	mov    $0x8,%bl
		base = 10;
  800bdb:	b8 00 00 00 00       	mov    $0x0,%eax
  800be0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800be3:	0f b6 0a             	movzbl (%edx),%ecx
  800be6:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800be9:	89 f3                	mov    %esi,%ebx
  800beb:	80 fb 09             	cmp    $0x9,%bl
  800bee:	77 08                	ja     800bf8 <strtol+0x87>
			dig = *s - '0';
  800bf0:	0f be c9             	movsbl %cl,%ecx
  800bf3:	83 e9 30             	sub    $0x30,%ecx
  800bf6:	eb 22                	jmp    800c1a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
  800bf8:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bfb:	89 f3                	mov    %esi,%ebx
  800bfd:	80 fb 19             	cmp    $0x19,%bl
  800c00:	77 08                	ja     800c0a <strtol+0x99>
			dig = *s - 'a' + 10;
  800c02:	0f be c9             	movsbl %cl,%ecx
  800c05:	83 e9 57             	sub    $0x57,%ecx
  800c08:	eb 10                	jmp    800c1a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
  800c0a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c0d:	89 f3                	mov    %esi,%ebx
  800c0f:	80 fb 19             	cmp    $0x19,%bl
  800c12:	77 16                	ja     800c2a <strtol+0xb9>
			dig = *s - 'A' + 10;
  800c14:	0f be c9             	movsbl %cl,%ecx
  800c17:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c1a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800c1d:	7d 0f                	jge    800c2e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800c1f:	83 c2 01             	add    $0x1,%edx
  800c22:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c26:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c28:	eb b9                	jmp    800be3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
  800c2a:	89 c1                	mov    %eax,%ecx
  800c2c:	eb 02                	jmp    800c30 <strtol+0xbf>
		if (dig >= base)
  800c2e:	89 c1                	mov    %eax,%ecx

	if (endptr)
  800c30:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c34:	74 05                	je     800c3b <strtol+0xca>
		*endptr = (char *) s;
  800c36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c39:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c3b:	89 ca                	mov    %ecx,%edx
  800c3d:	f7 da                	neg    %edx
  800c3f:	85 ff                	test   %edi,%edi
  800c41:	0f 45 c2             	cmovne %edx,%eax
}
  800c44:	83 c4 04             	add    $0x4,%esp
  800c47:	5b                   	pop    %ebx
  800c48:	5e                   	pop    %esi
  800c49:	5f                   	pop    %edi
  800c4a:	5d                   	pop    %ebp
  800c4b:	c3                   	ret    
  800c4c:	66 90                	xchg   %ax,%ax
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
