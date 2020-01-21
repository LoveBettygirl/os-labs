
obj/user/breakpoint：     文件格式 elf32-i386


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
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	83 ec 18             	sub    $0x18,%esp
  80003f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800042:	89 75 fc             	mov    %esi,-0x4(%ebp)
  800045:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800048:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	thisenv = &envs[ENVX(sys_getenvid())];
  80004b:	e8 0b 01 00 00       	call   80015b <sys_getenvid>
  800050:	25 ff 03 00 00       	and    $0x3ff,%eax
  800055:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800058:	c1 e0 05             	shl    $0x5,%eax
  80005b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800060:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800065:	85 db                	test   %ebx,%ebx
  800067:	7e 07                	jle    800070 <libmain+0x37>
		binaryname = argv[0];
  800069:	8b 06                	mov    (%esi),%eax
  80006b:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800070:	89 74 24 04          	mov    %esi,0x4(%esp)
  800074:	89 1c 24             	mov    %ebx,(%esp)
  800077:	e8 b7 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007c:	e8 0a 00 00 00       	call   80008b <exit>
}
  800081:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  800084:	8b 75 fc             	mov    -0x4(%ebp),%esi
  800087:	89 ec                	mov    %ebp,%esp
  800089:	5d                   	pop    %ebp
  80008a:	c3                   	ret    

0080008b <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80008b:	55                   	push   %ebp
  80008c:	89 e5                	mov    %esp,%ebp
  80008e:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800091:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800098:	e8 61 00 00 00       	call   8000fe <sys_env_destroy>
}
  80009d:	c9                   	leave  
  80009e:	c3                   	ret    

0080009f <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80009f:	55                   	push   %ebp
  8000a0:	89 e5                	mov    %esp,%ebp
  8000a2:	83 ec 0c             	sub    $0xc,%esp
  8000a5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000a8:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000ab:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  8000ae:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b6:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b9:	89 c3                	mov    %eax,%ebx
  8000bb:	89 c7                	mov    %eax,%edi
  8000bd:	89 c6                	mov    %eax,%esi
  8000bf:	cd 30                	int    $0x30
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000c4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000c7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000ca:	89 ec                	mov    %ebp,%esp
  8000cc:	5d                   	pop    %ebp
  8000cd:	c3                   	ret    

008000ce <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ce:	55                   	push   %ebp
  8000cf:	89 e5                	mov    %esp,%ebp
  8000d1:	83 ec 0c             	sub    $0xc,%esp
  8000d4:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000d7:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000da:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  8000dd:	ba 00 00 00 00       	mov    $0x0,%edx
  8000e2:	b8 01 00 00 00       	mov    $0x1,%eax
  8000e7:	89 d1                	mov    %edx,%ecx
  8000e9:	89 d3                	mov    %edx,%ebx
  8000eb:	89 d7                	mov    %edx,%edi
  8000ed:	89 d6                	mov    %edx,%esi
  8000ef:	cd 30                	int    $0x30
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000f1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000f4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000f7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000fa:	89 ec                	mov    %ebp,%esp
  8000fc:	5d                   	pop    %ebp
  8000fd:	c3                   	ret    

008000fe <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000fe:	55                   	push   %ebp
  8000ff:	89 e5                	mov    %esp,%ebp
  800101:	83 ec 38             	sub    $0x38,%esp
  800104:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800107:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80010a:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  80010d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800112:	b8 03 00 00 00       	mov    $0x3,%eax
  800117:	8b 55 08             	mov    0x8(%ebp),%edx
  80011a:	89 cb                	mov    %ecx,%ebx
  80011c:	89 cf                	mov    %ecx,%edi
  80011e:	89 ce                	mov    %ecx,%esi
  800120:	cd 30                	int    $0x30
	if(check && ret > 0)
  800122:	85 c0                	test   %eax,%eax
  800124:	7e 28                	jle    80014e <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800126:	89 44 24 10          	mov    %eax,0x10(%esp)
  80012a:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800131:	00 
  800132:	c7 44 24 08 2a 0f 80 	movl   $0x800f2a,0x8(%esp)
  800139:	00 
  80013a:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800141:	00 
  800142:	c7 04 24 47 0f 80 00 	movl   $0x800f47,(%esp)
  800149:	e8 3d 00 00 00       	call   80018b <_panic>
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80014e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800151:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800154:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800157:	89 ec                	mov    %ebp,%esp
  800159:	5d                   	pop    %ebp
  80015a:	c3                   	ret    

0080015b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80015b:	55                   	push   %ebp
  80015c:	89 e5                	mov    %esp,%ebp
  80015e:	83 ec 0c             	sub    $0xc,%esp
  800161:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800164:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800167:	89 7d fc             	mov    %edi,-0x4(%ebp)
	asm volatile("int %1\n"
  80016a:	ba 00 00 00 00       	mov    $0x0,%edx
  80016f:	b8 02 00 00 00       	mov    $0x2,%eax
  800174:	89 d1                	mov    %edx,%ecx
  800176:	89 d3                	mov    %edx,%ebx
  800178:	89 d7                	mov    %edx,%edi
  80017a:	89 d6                	mov    %edx,%esi
  80017c:	cd 30                	int    $0x30
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80017e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800181:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800184:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800187:	89 ec                	mov    %ebp,%esp
  800189:	5d                   	pop    %ebp
  80018a:	c3                   	ret    

0080018b <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80018b:	55                   	push   %ebp
  80018c:	89 e5                	mov    %esp,%ebp
  80018e:	56                   	push   %esi
  80018f:	53                   	push   %ebx
  800190:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800193:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800196:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80019c:	e8 ba ff ff ff       	call   80015b <sys_getenvid>
  8001a1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001a4:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001a8:	8b 55 08             	mov    0x8(%ebp),%edx
  8001ab:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001af:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001b7:	c7 04 24 58 0f 80 00 	movl   $0x800f58,(%esp)
  8001be:	e8 c1 00 00 00       	call   800284 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001c7:	8b 45 10             	mov    0x10(%ebp),%eax
  8001ca:	89 04 24             	mov    %eax,(%esp)
  8001cd:	e8 51 00 00 00       	call   800223 <vcprintf>
	cprintf("\n");
  8001d2:	c7 04 24 7c 0f 80 00 	movl   $0x800f7c,(%esp)
  8001d9:	e8 a6 00 00 00       	call   800284 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001de:	cc                   	int3   
  8001df:	eb fd                	jmp    8001de <_panic+0x53>

008001e1 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001e1:	55                   	push   %ebp
  8001e2:	89 e5                	mov    %esp,%ebp
  8001e4:	53                   	push   %ebx
  8001e5:	83 ec 14             	sub    $0x14,%esp
  8001e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001eb:	8b 03                	mov    (%ebx),%eax
  8001ed:	8b 55 08             	mov    0x8(%ebp),%edx
  8001f0:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8001f4:	83 c0 01             	add    $0x1,%eax
  8001f7:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8001f9:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001fe:	75 19                	jne    800219 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800200:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800207:	00 
  800208:	8d 43 08             	lea    0x8(%ebx),%eax
  80020b:	89 04 24             	mov    %eax,(%esp)
  80020e:	e8 8c fe ff ff       	call   80009f <sys_cputs>
		b->idx = 0;
  800213:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800219:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80021d:	83 c4 14             	add    $0x14,%esp
  800220:	5b                   	pop    %ebx
  800221:	5d                   	pop    %ebp
  800222:	c3                   	ret    

00800223 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800223:	55                   	push   %ebp
  800224:	89 e5                	mov    %esp,%ebp
  800226:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80022c:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800233:	00 00 00 
	b.cnt = 0;
  800236:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80023d:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800240:	8b 45 0c             	mov    0xc(%ebp),%eax
  800243:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800247:	8b 45 08             	mov    0x8(%ebp),%eax
  80024a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80024e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800254:	89 44 24 04          	mov    %eax,0x4(%esp)
  800258:	c7 04 24 e1 01 80 00 	movl   $0x8001e1,(%esp)
  80025f:	e8 a1 01 00 00       	call   800405 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800264:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80026a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80026e:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800274:	89 04 24             	mov    %eax,(%esp)
  800277:	e8 23 fe ff ff       	call   80009f <sys_cputs>

	return b.cnt;
}
  80027c:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800282:	c9                   	leave  
  800283:	c3                   	ret    

00800284 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800284:	55                   	push   %ebp
  800285:	89 e5                	mov    %esp,%ebp
  800287:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80028a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80028d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800291:	8b 45 08             	mov    0x8(%ebp),%eax
  800294:	89 04 24             	mov    %eax,(%esp)
  800297:	e8 87 ff ff ff       	call   800223 <vcprintf>
	va_end(ap);

	return cnt;
}
  80029c:	c9                   	leave  
  80029d:	c3                   	ret    
  80029e:	66 90                	xchg   %ax,%ax

008002a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002a0:	55                   	push   %ebp
  8002a1:	89 e5                	mov    %esp,%ebp
  8002a3:	57                   	push   %edi
  8002a4:	56                   	push   %esi
  8002a5:	53                   	push   %ebx
  8002a6:	83 ec 4c             	sub    $0x4c,%esp
  8002a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8002ac:	89 d7                	mov    %edx,%edi
  8002ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8002b1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8002b4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002b7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  8002ba:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002bd:	85 db                	test   %ebx,%ebx
  8002bf:	75 08                	jne    8002c9 <printnum+0x29>
  8002c1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002c4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
  8002c7:	77 6c                	ja     800335 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002c9:	8b 5d 18             	mov    0x18(%ebp),%ebx
  8002cc:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  8002d0:	83 ee 01             	sub    $0x1,%esi
  8002d3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002da:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002de:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002e2:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002e9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8002ec:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002f3:	00 
  8002f4:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8002f7:	89 1c 24             	mov    %ebx,(%esp)
  8002fa:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8002fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800301:	e8 2a 09 00 00       	call   800c30 <__udivdi3>
  800306:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800309:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  80030c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800310:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800314:	89 04 24             	mov    %eax,(%esp)
  800317:	89 54 24 04          	mov    %edx,0x4(%esp)
  80031b:	89 fa                	mov    %edi,%edx
  80031d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800320:	e8 7b ff ff ff       	call   8002a0 <printnum>
  800325:	eb 1b                	jmp    800342 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800327:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80032b:	8b 45 18             	mov    0x18(%ebp),%eax
  80032e:	89 04 24             	mov    %eax,(%esp)
  800331:	ff d3                	call   *%ebx
  800333:	eb 03                	jmp    800338 <printnum+0x98>
  800335:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
  800338:	83 ee 01             	sub    $0x1,%esi
  80033b:	85 f6                	test   %esi,%esi
  80033d:	7f e8                	jg     800327 <printnum+0x87>
  80033f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800342:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800346:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80034a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80034d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800351:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800358:	00 
  800359:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  80035c:	89 1c 24             	mov    %ebx,(%esp)
  80035f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800362:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800366:	e8 15 0a 00 00       	call   800d80 <__umoddi3>
  80036b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80036f:	0f be 80 7e 0f 80 00 	movsbl 0x800f7e(%eax),%eax
  800376:	89 04 24             	mov    %eax,(%esp)
  800379:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80037c:	ff d0                	call   *%eax
}
  80037e:	83 c4 4c             	add    $0x4c,%esp
  800381:	5b                   	pop    %ebx
  800382:	5e                   	pop    %esi
  800383:	5f                   	pop    %edi
  800384:	5d                   	pop    %ebp
  800385:	c3                   	ret    

00800386 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800386:	55                   	push   %ebp
  800387:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800389:	83 fa 01             	cmp    $0x1,%edx
  80038c:	7e 0e                	jle    80039c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80038e:	8b 10                	mov    (%eax),%edx
  800390:	8d 4a 08             	lea    0x8(%edx),%ecx
  800393:	89 08                	mov    %ecx,(%eax)
  800395:	8b 02                	mov    (%edx),%eax
  800397:	8b 52 04             	mov    0x4(%edx),%edx
  80039a:	eb 22                	jmp    8003be <getuint+0x38>
	else if (lflag)
  80039c:	85 d2                	test   %edx,%edx
  80039e:	74 10                	je     8003b0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003a0:	8b 10                	mov    (%eax),%edx
  8003a2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003a5:	89 08                	mov    %ecx,(%eax)
  8003a7:	8b 02                	mov    (%edx),%eax
  8003a9:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ae:	eb 0e                	jmp    8003be <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003b0:	8b 10                	mov    (%eax),%edx
  8003b2:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003b5:	89 08                	mov    %ecx,(%eax)
  8003b7:	8b 02                	mov    (%edx),%eax
  8003b9:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003be:	5d                   	pop    %ebp
  8003bf:	c3                   	ret    

008003c0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003c0:	55                   	push   %ebp
  8003c1:	89 e5                	mov    %esp,%ebp
  8003c3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003c6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003ca:	8b 10                	mov    (%eax),%edx
  8003cc:	3b 50 04             	cmp    0x4(%eax),%edx
  8003cf:	73 0a                	jae    8003db <sprintputch+0x1b>
		*b->buf++ = ch;
  8003d1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003d4:	88 0a                	mov    %cl,(%edx)
  8003d6:	83 c2 01             	add    $0x1,%edx
  8003d9:	89 10                	mov    %edx,(%eax)
}
  8003db:	5d                   	pop    %ebp
  8003dc:	c3                   	ret    

008003dd <printfmt>:
{
  8003dd:	55                   	push   %ebp
  8003de:	89 e5                	mov    %esp,%ebp
  8003e0:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
  8003e3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003ea:	8b 45 10             	mov    0x10(%ebp),%eax
  8003ed:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003f1:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8003fb:	89 04 24             	mov    %eax,(%esp)
  8003fe:	e8 02 00 00 00       	call   800405 <vprintfmt>
}
  800403:	c9                   	leave  
  800404:	c3                   	ret    

00800405 <vprintfmt>:
{
  800405:	55                   	push   %ebp
  800406:	89 e5                	mov    %esp,%ebp
  800408:	57                   	push   %edi
  800409:	56                   	push   %esi
  80040a:	53                   	push   %ebx
  80040b:	83 ec 4c             	sub    $0x4c,%esp
  80040e:	8b 75 08             	mov    0x8(%ebp),%esi
  800411:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800414:	8b 7d 10             	mov    0x10(%ebp),%edi
  800417:	eb 11                	jmp    80042a <vprintfmt+0x25>
			if (ch == '\0')
  800419:	85 c0                	test   %eax,%eax
  80041b:	0f 84 cf 03 00 00    	je     8007f0 <vprintfmt+0x3eb>
			putch(ch, putdat);
  800421:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800425:	89 04 24             	mov    %eax,(%esp)
  800428:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80042a:	0f b6 07             	movzbl (%edi),%eax
  80042d:	83 c7 01             	add    $0x1,%edi
  800430:	83 f8 25             	cmp    $0x25,%eax
  800433:	75 e4                	jne    800419 <vprintfmt+0x14>
  800435:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
  800439:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  800440:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800447:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
  80044e:	ba 00 00 00 00       	mov    $0x0,%edx
  800453:	eb 2b                	jmp    800480 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800455:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
  800458:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
  80045c:	eb 22                	jmp    800480 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  80045e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
  800461:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
  800465:	eb 19                	jmp    800480 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
  800467:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
  80046a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800471:	eb 0d                	jmp    800480 <vprintfmt+0x7b>
				width = precision, precision = -1;
  800473:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800476:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800479:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  800480:	0f b6 07             	movzbl (%edi),%eax
  800483:	8d 4f 01             	lea    0x1(%edi),%ecx
  800486:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800489:	0f b6 0f             	movzbl (%edi),%ecx
  80048c:	83 e9 23             	sub    $0x23,%ecx
  80048f:	80 f9 55             	cmp    $0x55,%cl
  800492:	0f 87 3b 03 00 00    	ja     8007d3 <vprintfmt+0x3ce>
  800498:	0f b6 c9             	movzbl %cl,%ecx
  80049b:	ff 24 8d 20 10 80 00 	jmp    *0x801020(,%ecx,4)
  8004a2:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004a5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  8004ac:	89 55 e0             	mov    %edx,-0x20(%ebp)
  8004af:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
  8004b4:	8d 14 92             	lea    (%edx,%edx,4),%edx
  8004b7:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  8004bb:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
  8004be:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004c1:	83 f9 09             	cmp    $0x9,%ecx
  8004c4:	77 2f                	ja     8004f5 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
  8004c6:	83 c7 01             	add    $0x1,%edi
			}
  8004c9:	eb e9                	jmp    8004b4 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
  8004cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ce:	8d 48 04             	lea    0x4(%eax),%ecx
  8004d1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004d4:	8b 00                	mov    (%eax),%eax
  8004d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  8004d9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
  8004dc:	eb 1d                	jmp    8004fb <vprintfmt+0xf6>
			if (width < 0)
  8004de:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004e2:	78 83                	js     800467 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
  8004e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8004e7:	eb 97                	jmp    800480 <vprintfmt+0x7b>
  8004e9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
  8004ec:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
  8004f3:	eb 8b                	jmp    800480 <vprintfmt+0x7b>
  8004f5:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004f8:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
  8004fb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004ff:	0f 89 7b ff ff ff    	jns    800480 <vprintfmt+0x7b>
  800505:	e9 69 ff ff ff       	jmp    800473 <vprintfmt+0x6e>
			lflag++;
  80050a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
  80050d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
  800510:	e9 6b ff ff ff       	jmp    800480 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
  800515:	8b 45 14             	mov    0x14(%ebp),%eax
  800518:	8d 50 04             	lea    0x4(%eax),%edx
  80051b:	89 55 14             	mov    %edx,0x14(%ebp)
  80051e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800522:	8b 00                	mov    (%eax),%eax
  800524:	89 04 24             	mov    %eax,(%esp)
  800527:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  800529:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  80052c:	e9 f9 fe ff ff       	jmp    80042a <vprintfmt+0x25>
			err = va_arg(ap, int);
  800531:	8b 45 14             	mov    0x14(%ebp),%eax
  800534:	8d 50 04             	lea    0x4(%eax),%edx
  800537:	89 55 14             	mov    %edx,0x14(%ebp)
  80053a:	8b 00                	mov    (%eax),%eax
  80053c:	89 c2                	mov    %eax,%edx
  80053e:	c1 fa 1f             	sar    $0x1f,%edx
  800541:	31 d0                	xor    %edx,%eax
  800543:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800545:	83 f8 07             	cmp    $0x7,%eax
  800548:	7f 0b                	jg     800555 <vprintfmt+0x150>
  80054a:	8b 14 85 80 11 80 00 	mov    0x801180(,%eax,4),%edx
  800551:	85 d2                	test   %edx,%edx
  800553:	75 20                	jne    800575 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
  800555:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800559:	c7 44 24 08 96 0f 80 	movl   $0x800f96,0x8(%esp)
  800560:	00 
  800561:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800565:	89 34 24             	mov    %esi,(%esp)
  800568:	e8 70 fe ff ff       	call   8003dd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80056d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
  800570:	e9 b5 fe ff ff       	jmp    80042a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
  800575:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800579:	c7 44 24 08 9f 0f 80 	movl   $0x800f9f,0x8(%esp)
  800580:	00 
  800581:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800585:	89 34 24             	mov    %esi,(%esp)
  800588:	e8 50 fe ff ff       	call   8003dd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
  80058d:	8b 7d e0             	mov    -0x20(%ebp),%edi
  800590:	e9 95 fe ff ff       	jmp    80042a <vprintfmt+0x25>
  800595:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800598:	8b 7d d8             	mov    -0x28(%ebp),%edi
  80059b:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
  80059e:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a1:	8d 50 04             	lea    0x4(%eax),%edx
  8005a4:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8005a9:	85 ff                	test   %edi,%edi
  8005ab:	b8 8f 0f 80 00       	mov    $0x800f8f,%eax
  8005b0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8005b3:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
  8005b7:	0f 84 9b 00 00 00    	je     800658 <vprintfmt+0x253>
  8005bd:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  8005c1:	0f 8e 9f 00 00 00    	jle    800666 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005c7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005cb:	89 3c 24             	mov    %edi,(%esp)
  8005ce:	e8 c5 02 00 00       	call   800898 <strnlen>
  8005d3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  8005d6:	29 c2                	sub    %eax,%edx
  8005d8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
  8005db:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
  8005df:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  8005e2:	89 7d c8             	mov    %edi,-0x38(%ebp)
  8005e5:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  8005e7:	eb 0f                	jmp    8005f8 <vprintfmt+0x1f3>
					putch(padc, putdat);
  8005e9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8005f0:	89 04 24             	mov    %eax,(%esp)
  8005f3:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
  8005f5:	83 ef 01             	sub    $0x1,%edi
  8005f8:	85 ff                	test   %edi,%edi
  8005fa:	7f ed                	jg     8005e9 <vprintfmt+0x1e4>
  8005fc:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8005ff:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800603:	b8 00 00 00 00       	mov    $0x0,%eax
  800608:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
  80060c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060f:	29 c2                	sub    %eax,%edx
  800611:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800614:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800617:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80061a:	89 d3                	mov    %edx,%ebx
  80061c:	eb 54                	jmp    800672 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
  80061e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800622:	74 20                	je     800644 <vprintfmt+0x23f>
  800624:	0f be d2             	movsbl %dl,%edx
  800627:	83 ea 20             	sub    $0x20,%edx
  80062a:	83 fa 5e             	cmp    $0x5e,%edx
  80062d:	76 15                	jbe    800644 <vprintfmt+0x23f>
					putch('?', putdat);
  80062f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800632:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800636:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80063d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800640:	ff d0                	call   *%eax
  800642:	eb 0f                	jmp    800653 <vprintfmt+0x24e>
					putch(ch, putdat);
  800644:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800647:	89 54 24 04          	mov    %edx,0x4(%esp)
  80064b:	89 04 24             	mov    %eax,(%esp)
  80064e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800651:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800653:	83 eb 01             	sub    $0x1,%ebx
  800656:	eb 1a                	jmp    800672 <vprintfmt+0x26d>
  800658:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  80065b:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80065e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  800661:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800664:	eb 0c                	jmp    800672 <vprintfmt+0x26d>
  800666:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800669:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80066c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  80066f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  800672:	0f b6 17             	movzbl (%edi),%edx
  800675:	0f be c2             	movsbl %dl,%eax
  800678:	83 c7 01             	add    $0x1,%edi
  80067b:	85 c0                	test   %eax,%eax
  80067d:	74 29                	je     8006a8 <vprintfmt+0x2a3>
  80067f:	85 f6                	test   %esi,%esi
  800681:	78 9b                	js     80061e <vprintfmt+0x219>
  800683:	83 ee 01             	sub    $0x1,%esi
  800686:	79 96                	jns    80061e <vprintfmt+0x219>
  800688:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  80068b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80068e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  800691:	8b 7d d8             	mov    -0x28(%ebp),%edi
  800694:	eb 1a                	jmp    8006b0 <vprintfmt+0x2ab>
				putch(' ', putdat);
  800696:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80069a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006a1:	ff d6                	call   *%esi
			for (; width > 0; width--)
  8006a3:	83 ef 01             	sub    $0x1,%edi
  8006a6:	eb 08                	jmp    8006b0 <vprintfmt+0x2ab>
  8006a8:	89 df                	mov    %ebx,%edi
  8006aa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8006ad:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  8006b0:	85 ff                	test   %edi,%edi
  8006b2:	7f e2                	jg     800696 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
  8006b4:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8006b7:	e9 6e fd ff ff       	jmp    80042a <vprintfmt+0x25>
	if (lflag >= 2)
  8006bc:	83 fa 01             	cmp    $0x1,%edx
  8006bf:	7e 16                	jle    8006d7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
  8006c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c4:	8d 50 08             	lea    0x8(%eax),%edx
  8006c7:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ca:	8b 10                	mov    (%eax),%edx
  8006cc:	8b 48 04             	mov    0x4(%eax),%ecx
  8006cf:	89 55 d0             	mov    %edx,-0x30(%ebp)
  8006d2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006d5:	eb 32                	jmp    800709 <vprintfmt+0x304>
	else if (lflag)
  8006d7:	85 d2                	test   %edx,%edx
  8006d9:	74 18                	je     8006f3 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
  8006db:	8b 45 14             	mov    0x14(%ebp),%eax
  8006de:	8d 50 04             	lea    0x4(%eax),%edx
  8006e1:	89 55 14             	mov    %edx,0x14(%ebp)
  8006e4:	8b 00                	mov    (%eax),%eax
  8006e6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8006e9:	89 c1                	mov    %eax,%ecx
  8006eb:	c1 f9 1f             	sar    $0x1f,%ecx
  8006ee:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8006f1:	eb 16                	jmp    800709 <vprintfmt+0x304>
		return va_arg(*ap, int);
  8006f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f6:	8d 50 04             	lea    0x4(%eax),%edx
  8006f9:	89 55 14             	mov    %edx,0x14(%ebp)
  8006fc:	8b 00                	mov    (%eax),%eax
  8006fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800701:	89 c7                	mov    %eax,%edi
  800703:	c1 ff 1f             	sar    $0x1f,%edi
  800706:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
  800709:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80070c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
  80070f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
  800714:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800718:	79 7d                	jns    800797 <vprintfmt+0x392>
				putch('-', putdat);
  80071a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80071e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  800725:	ff d6                	call   *%esi
				num = -(long long) num;
  800727:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80072a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80072d:	f7 d8                	neg    %eax
  80072f:	83 d2 00             	adc    $0x0,%edx
  800732:	f7 da                	neg    %edx
			base = 10;
  800734:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800739:	eb 5c                	jmp    800797 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80073b:	8d 45 14             	lea    0x14(%ebp),%eax
  80073e:	e8 43 fc ff ff       	call   800386 <getuint>
			base = 10;
  800743:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800748:	eb 4d                	jmp    800797 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80074a:	8d 45 14             	lea    0x14(%ebp),%eax
  80074d:	e8 34 fc ff ff       	call   800386 <getuint>
			base = 8;
  800752:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800757:	eb 3e                	jmp    800797 <vprintfmt+0x392>
			putch('0', putdat);
  800759:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80075d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  800764:	ff d6                	call   *%esi
			putch('x', putdat);
  800766:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80076a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800771:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
  800773:	8b 45 14             	mov    0x14(%ebp),%eax
  800776:	8d 50 04             	lea    0x4(%eax),%edx
  800779:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
  80077c:	8b 00                	mov    (%eax),%eax
  80077e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
  800783:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800788:	eb 0d                	jmp    800797 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
  80078a:	8d 45 14             	lea    0x14(%ebp),%eax
  80078d:	e8 f4 fb ff ff       	call   800386 <getuint>
			base = 16;
  800792:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
  800797:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
  80079b:	89 7c 24 10          	mov    %edi,0x10(%esp)
  80079f:	8b 7d d8             	mov    -0x28(%ebp),%edi
  8007a2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8007a6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007aa:	89 04 24             	mov    %eax,(%esp)
  8007ad:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007b1:	89 da                	mov    %ebx,%edx
  8007b3:	89 f0                	mov    %esi,%eax
  8007b5:	e8 e6 fa ff ff       	call   8002a0 <printnum>
			break;
  8007ba:	8b 7d e0             	mov    -0x20(%ebp),%edi
  8007bd:	e9 68 fc ff ff       	jmp    80042a <vprintfmt+0x25>
			putch(ch, putdat);
  8007c2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007c6:	89 04 24             	mov    %eax,(%esp)
  8007c9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
  8007cb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
  8007ce:	e9 57 fc ff ff       	jmp    80042a <vprintfmt+0x25>
			putch('%', putdat);
  8007d3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007d7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007de:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007e0:	eb 03                	jmp    8007e5 <vprintfmt+0x3e0>
  8007e2:	83 ef 01             	sub    $0x1,%edi
  8007e5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007e9:	75 f7                	jne    8007e2 <vprintfmt+0x3dd>
  8007eb:	e9 3a fc ff ff       	jmp    80042a <vprintfmt+0x25>
}
  8007f0:	83 c4 4c             	add    $0x4c,%esp
  8007f3:	5b                   	pop    %ebx
  8007f4:	5e                   	pop    %esi
  8007f5:	5f                   	pop    %edi
  8007f6:	5d                   	pop    %ebp
  8007f7:	c3                   	ret    

008007f8 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007f8:	55                   	push   %ebp
  8007f9:	89 e5                	mov    %esp,%ebp
  8007fb:	83 ec 28             	sub    $0x28,%esp
  8007fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800801:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800804:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800807:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80080b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80080e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800815:	85 d2                	test   %edx,%edx
  800817:	7e 30                	jle    800849 <vsnprintf+0x51>
  800819:	85 c0                	test   %eax,%eax
  80081b:	74 2c                	je     800849 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80081d:	8b 45 14             	mov    0x14(%ebp),%eax
  800820:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800824:	8b 45 10             	mov    0x10(%ebp),%eax
  800827:	89 44 24 08          	mov    %eax,0x8(%esp)
  80082b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80082e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800832:	c7 04 24 c0 03 80 00 	movl   $0x8003c0,(%esp)
  800839:	e8 c7 fb ff ff       	call   800405 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80083e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800841:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800844:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800847:	eb 05                	jmp    80084e <vsnprintf+0x56>
		return -E_INVAL;
  800849:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
  80084e:	c9                   	leave  
  80084f:	c3                   	ret    

00800850 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800856:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800859:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80085d:	8b 45 10             	mov    0x10(%ebp),%eax
  800860:	89 44 24 08          	mov    %eax,0x8(%esp)
  800864:	8b 45 0c             	mov    0xc(%ebp),%eax
  800867:	89 44 24 04          	mov    %eax,0x4(%esp)
  80086b:	8b 45 08             	mov    0x8(%ebp),%eax
  80086e:	89 04 24             	mov    %eax,(%esp)
  800871:	e8 82 ff ff ff       	call   8007f8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800876:	c9                   	leave  
  800877:	c3                   	ret    
  800878:	66 90                	xchg   %ax,%ax
  80087a:	66 90                	xchg   %ax,%ax
  80087c:	66 90                	xchg   %ax,%ax
  80087e:	66 90                	xchg   %ax,%ax

00800880 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800880:	55                   	push   %ebp
  800881:	89 e5                	mov    %esp,%ebp
  800883:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800886:	b8 00 00 00 00       	mov    $0x0,%eax
  80088b:	eb 03                	jmp    800890 <strlen+0x10>
		n++;
  80088d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  800890:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800894:	75 f7                	jne    80088d <strlen+0xd>
	return n;
}
  800896:	5d                   	pop    %ebp
  800897:	c3                   	ret    

00800898 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800898:	55                   	push   %ebp
  800899:	89 e5                	mov    %esp,%ebp
  80089b:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
  80089e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008a1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008a6:	eb 03                	jmp    8008ab <strnlen+0x13>
		n++;
  8008a8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008ab:	39 d0                	cmp    %edx,%eax
  8008ad:	74 06                	je     8008b5 <strnlen+0x1d>
  8008af:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8008b3:	75 f3                	jne    8008a8 <strnlen+0x10>
	return n;
}
  8008b5:	5d                   	pop    %ebp
  8008b6:	c3                   	ret    

008008b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
  8008ba:	53                   	push   %ebx
  8008bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8008be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008c1:	89 c2                	mov    %eax,%edx
  8008c3:	0f b6 19             	movzbl (%ecx),%ebx
  8008c6:	88 1a                	mov    %bl,(%edx)
  8008c8:	83 c2 01             	add    $0x1,%edx
  8008cb:	83 c1 01             	add    $0x1,%ecx
  8008ce:	84 db                	test   %bl,%bl
  8008d0:	75 f1                	jne    8008c3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008d2:	5b                   	pop    %ebx
  8008d3:	5d                   	pop    %ebp
  8008d4:	c3                   	ret    

008008d5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008d5:	55                   	push   %ebp
  8008d6:	89 e5                	mov    %esp,%ebp
  8008d8:	53                   	push   %ebx
  8008d9:	83 ec 08             	sub    $0x8,%esp
  8008dc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008df:	89 1c 24             	mov    %ebx,(%esp)
  8008e2:	e8 99 ff ff ff       	call   800880 <strlen>
	strcpy(dst + len, src);
  8008e7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ea:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008ee:	01 d8                	add    %ebx,%eax
  8008f0:	89 04 24             	mov    %eax,(%esp)
  8008f3:	e8 bf ff ff ff       	call   8008b7 <strcpy>
	return dst;
}
  8008f8:	89 d8                	mov    %ebx,%eax
  8008fa:	83 c4 08             	add    $0x8,%esp
  8008fd:	5b                   	pop    %ebx
  8008fe:	5d                   	pop    %ebp
  8008ff:	c3                   	ret    

00800900 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800900:	55                   	push   %ebp
  800901:	89 e5                	mov    %esp,%ebp
  800903:	56                   	push   %esi
  800904:	53                   	push   %ebx
  800905:	8b 75 08             	mov    0x8(%ebp),%esi
  800908:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80090b:	89 f3                	mov    %esi,%ebx
  80090d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800910:	89 f2                	mov    %esi,%edx
  800912:	eb 0e                	jmp    800922 <strncpy+0x22>
		*dst++ = *src;
  800914:	0f b6 01             	movzbl (%ecx),%eax
  800917:	88 02                	mov    %al,(%edx)
  800919:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80091c:	80 39 01             	cmpb   $0x1,(%ecx)
  80091f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  800922:	39 da                	cmp    %ebx,%edx
  800924:	75 ee                	jne    800914 <strncpy+0x14>
	}
	return ret;
}
  800926:	89 f0                	mov    %esi,%eax
  800928:	5b                   	pop    %ebx
  800929:	5e                   	pop    %esi
  80092a:	5d                   	pop    %ebp
  80092b:	c3                   	ret    

0080092c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80092c:	55                   	push   %ebp
  80092d:	89 e5                	mov    %esp,%ebp
  80092f:	56                   	push   %esi
  800930:	53                   	push   %ebx
  800931:	8b 75 08             	mov    0x8(%ebp),%esi
  800934:	8b 55 0c             	mov    0xc(%ebp),%edx
  800937:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80093a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
  80093c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
  800940:	85 c9                	test   %ecx,%ecx
  800942:	75 0a                	jne    80094e <strlcpy+0x22>
  800944:	eb 1c                	jmp    800962 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800946:	88 08                	mov    %cl,(%eax)
  800948:	83 c0 01             	add    $0x1,%eax
  80094b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
  80094e:	39 d8                	cmp    %ebx,%eax
  800950:	74 0b                	je     80095d <strlcpy+0x31>
  800952:	0f b6 0a             	movzbl (%edx),%ecx
  800955:	84 c9                	test   %cl,%cl
  800957:	75 ed                	jne    800946 <strlcpy+0x1a>
  800959:	89 c2                	mov    %eax,%edx
  80095b:	eb 02                	jmp    80095f <strlcpy+0x33>
  80095d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
  80095f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800962:	29 f0                	sub    %esi,%eax
}
  800964:	5b                   	pop    %ebx
  800965:	5e                   	pop    %esi
  800966:	5d                   	pop    %ebp
  800967:	c3                   	ret    

00800968 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800968:	55                   	push   %ebp
  800969:	89 e5                	mov    %esp,%ebp
  80096b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80096e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800971:	eb 06                	jmp    800979 <strcmp+0x11>
		p++, q++;
  800973:	83 c1 01             	add    $0x1,%ecx
  800976:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  800979:	0f b6 01             	movzbl (%ecx),%eax
  80097c:	84 c0                	test   %al,%al
  80097e:	74 04                	je     800984 <strcmp+0x1c>
  800980:	3a 02                	cmp    (%edx),%al
  800982:	74 ef                	je     800973 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800984:	0f b6 c0             	movzbl %al,%eax
  800987:	0f b6 12             	movzbl (%edx),%edx
  80098a:	29 d0                	sub    %edx,%eax
}
  80098c:	5d                   	pop    %ebp
  80098d:	c3                   	ret    

0080098e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80098e:	55                   	push   %ebp
  80098f:	89 e5                	mov    %esp,%ebp
  800991:	53                   	push   %ebx
  800992:	8b 45 08             	mov    0x8(%ebp),%eax
  800995:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
  800998:	89 c3                	mov    %eax,%ebx
  80099a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80099d:	eb 06                	jmp    8009a5 <strncmp+0x17>
		n--, p++, q++;
  80099f:	83 c0 01             	add    $0x1,%eax
  8009a2:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  8009a5:	39 d8                	cmp    %ebx,%eax
  8009a7:	74 15                	je     8009be <strncmp+0x30>
  8009a9:	0f b6 08             	movzbl (%eax),%ecx
  8009ac:	84 c9                	test   %cl,%cl
  8009ae:	74 04                	je     8009b4 <strncmp+0x26>
  8009b0:	3a 0a                	cmp    (%edx),%cl
  8009b2:	74 eb                	je     80099f <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009b4:	0f b6 00             	movzbl (%eax),%eax
  8009b7:	0f b6 12             	movzbl (%edx),%edx
  8009ba:	29 d0                	sub    %edx,%eax
  8009bc:	eb 05                	jmp    8009c3 <strncmp+0x35>
		return 0;
  8009be:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c3:	5b                   	pop    %ebx
  8009c4:	5d                   	pop    %ebp
  8009c5:	c3                   	ret    

008009c6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009c6:	55                   	push   %ebp
  8009c7:	89 e5                	mov    %esp,%ebp
  8009c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009d0:	eb 07                	jmp    8009d9 <strchr+0x13>
		if (*s == c)
  8009d2:	38 ca                	cmp    %cl,%dl
  8009d4:	74 0f                	je     8009e5 <strchr+0x1f>
	for (; *s; s++)
  8009d6:	83 c0 01             	add    $0x1,%eax
  8009d9:	0f b6 10             	movzbl (%eax),%edx
  8009dc:	84 d2                	test   %dl,%dl
  8009de:	75 f2                	jne    8009d2 <strchr+0xc>
			return (char *) s;
	return 0;
  8009e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e5:	5d                   	pop    %ebp
  8009e6:	c3                   	ret    

008009e7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009e7:	55                   	push   %ebp
  8009e8:	89 e5                	mov    %esp,%ebp
  8009ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ed:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009f1:	eb 07                	jmp    8009fa <strfind+0x13>
		if (*s == c)
  8009f3:	38 ca                	cmp    %cl,%dl
  8009f5:	74 0a                	je     800a01 <strfind+0x1a>
	for (; *s; s++)
  8009f7:	83 c0 01             	add    $0x1,%eax
  8009fa:	0f b6 10             	movzbl (%eax),%edx
  8009fd:	84 d2                	test   %dl,%dl
  8009ff:	75 f2                	jne    8009f3 <strfind+0xc>
			break;
	return (char *) s;
}
  800a01:	5d                   	pop    %ebp
  800a02:	c3                   	ret    

00800a03 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a03:	55                   	push   %ebp
  800a04:	89 e5                	mov    %esp,%ebp
  800a06:	83 ec 0c             	sub    $0xc,%esp
  800a09:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800a0c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a0f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a12:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a15:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a18:	85 c9                	test   %ecx,%ecx
  800a1a:	74 36                	je     800a52 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a1c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a22:	75 28                	jne    800a4c <memset+0x49>
  800a24:	f6 c1 03             	test   $0x3,%cl
  800a27:	75 23                	jne    800a4c <memset+0x49>
		c &= 0xFF;
  800a29:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a2d:	89 d3                	mov    %edx,%ebx
  800a2f:	c1 e3 08             	shl    $0x8,%ebx
  800a32:	89 d6                	mov    %edx,%esi
  800a34:	c1 e6 18             	shl    $0x18,%esi
  800a37:	89 d0                	mov    %edx,%eax
  800a39:	c1 e0 10             	shl    $0x10,%eax
  800a3c:	09 f0                	or     %esi,%eax
  800a3e:	09 c2                	or     %eax,%edx
  800a40:	89 d0                	mov    %edx,%eax
  800a42:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a44:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  800a47:	fc                   	cld    
  800a48:	f3 ab                	rep stos %eax,%es:(%edi)
  800a4a:	eb 06                	jmp    800a52 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a4c:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a4f:	fc                   	cld    
  800a50:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a52:	89 f8                	mov    %edi,%eax
  800a54:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a57:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a5a:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a5d:	89 ec                	mov    %ebp,%esp
  800a5f:	5d                   	pop    %ebp
  800a60:	c3                   	ret    

00800a61 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a61:	55                   	push   %ebp
  800a62:	89 e5                	mov    %esp,%ebp
  800a64:	83 ec 08             	sub    $0x8,%esp
  800a67:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a6a:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a6d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a70:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a73:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a76:	39 c6                	cmp    %eax,%esi
  800a78:	73 36                	jae    800ab0 <memmove+0x4f>
  800a7a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a7d:	39 d0                	cmp    %edx,%eax
  800a7f:	73 2f                	jae    800ab0 <memmove+0x4f>
		s += n;
		d += n;
  800a81:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a84:	f6 c2 03             	test   $0x3,%dl
  800a87:	75 1b                	jne    800aa4 <memmove+0x43>
  800a89:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a8f:	75 13                	jne    800aa4 <memmove+0x43>
  800a91:	f6 c1 03             	test   $0x3,%cl
  800a94:	75 0e                	jne    800aa4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a96:	83 ef 04             	sub    $0x4,%edi
  800a99:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a9c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  800a9f:	fd                   	std    
  800aa0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aa2:	eb 09                	jmp    800aad <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800aa4:	83 ef 01             	sub    $0x1,%edi
  800aa7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  800aaa:	fd                   	std    
  800aab:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800aad:	fc                   	cld    
  800aae:	eb 20                	jmp    800ad0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ab0:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800ab6:	75 13                	jne    800acb <memmove+0x6a>
  800ab8:	a8 03                	test   $0x3,%al
  800aba:	75 0f                	jne    800acb <memmove+0x6a>
  800abc:	f6 c1 03             	test   $0x3,%cl
  800abf:	75 0a                	jne    800acb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800ac1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  800ac4:	89 c7                	mov    %eax,%edi
  800ac6:	fc                   	cld    
  800ac7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800ac9:	eb 05                	jmp    800ad0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
  800acb:	89 c7                	mov    %eax,%edi
  800acd:	fc                   	cld    
  800ace:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ad0:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ad3:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ad6:	89 ec                	mov    %ebp,%esp
  800ad8:	5d                   	pop    %ebp
  800ad9:	c3                   	ret    

00800ada <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ada:	55                   	push   %ebp
  800adb:	89 e5                	mov    %esp,%ebp
  800add:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ae0:	8b 45 10             	mov    0x10(%ebp),%eax
  800ae3:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ae7:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aea:	89 44 24 04          	mov    %eax,0x4(%esp)
  800aee:	8b 45 08             	mov    0x8(%ebp),%eax
  800af1:	89 04 24             	mov    %eax,(%esp)
  800af4:	e8 68 ff ff ff       	call   800a61 <memmove>
}
  800af9:	c9                   	leave  
  800afa:	c3                   	ret    

00800afb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800afb:	55                   	push   %ebp
  800afc:	89 e5                	mov    %esp,%ebp
  800afe:	56                   	push   %esi
  800aff:	53                   	push   %ebx
  800b00:	8b 55 08             	mov    0x8(%ebp),%edx
  800b03:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
  800b06:	89 d6                	mov    %edx,%esi
  800b08:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b0b:	eb 1a                	jmp    800b27 <memcmp+0x2c>
		if (*s1 != *s2)
  800b0d:	0f b6 02             	movzbl (%edx),%eax
  800b10:	0f b6 19             	movzbl (%ecx),%ebx
  800b13:	38 d8                	cmp    %bl,%al
  800b15:	74 0a                	je     800b21 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b17:	0f b6 c0             	movzbl %al,%eax
  800b1a:	0f b6 db             	movzbl %bl,%ebx
  800b1d:	29 d8                	sub    %ebx,%eax
  800b1f:	eb 0f                	jmp    800b30 <memcmp+0x35>
		s1++, s2++;
  800b21:	83 c2 01             	add    $0x1,%edx
  800b24:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
  800b27:	39 f2                	cmp    %esi,%edx
  800b29:	75 e2                	jne    800b0d <memcmp+0x12>
	}

	return 0;
  800b2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b30:	5b                   	pop    %ebx
  800b31:	5e                   	pop    %esi
  800b32:	5d                   	pop    %ebp
  800b33:	c3                   	ret    

00800b34 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b34:	55                   	push   %ebp
  800b35:	89 e5                	mov    %esp,%ebp
  800b37:	8b 45 08             	mov    0x8(%ebp),%eax
  800b3a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b3d:	89 c2                	mov    %eax,%edx
  800b3f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b42:	eb 07                	jmp    800b4b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b44:	38 08                	cmp    %cl,(%eax)
  800b46:	74 07                	je     800b4f <memfind+0x1b>
	for (; s < ends; s++)
  800b48:	83 c0 01             	add    $0x1,%eax
  800b4b:	39 d0                	cmp    %edx,%eax
  800b4d:	72 f5                	jb     800b44 <memfind+0x10>
			break;
	return (void *) s;
}
  800b4f:	5d                   	pop    %ebp
  800b50:	c3                   	ret    

00800b51 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b51:	55                   	push   %ebp
  800b52:	89 e5                	mov    %esp,%ebp
  800b54:	57                   	push   %edi
  800b55:	56                   	push   %esi
  800b56:	53                   	push   %ebx
  800b57:	83 ec 04             	sub    $0x4,%esp
  800b5a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b5d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b60:	eb 03                	jmp    800b65 <strtol+0x14>
		s++;
  800b62:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
  800b65:	0f b6 02             	movzbl (%edx),%eax
  800b68:	3c 09                	cmp    $0x9,%al
  800b6a:	74 f6                	je     800b62 <strtol+0x11>
  800b6c:	3c 20                	cmp    $0x20,%al
  800b6e:	74 f2                	je     800b62 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
  800b70:	3c 2b                	cmp    $0x2b,%al
  800b72:	75 0a                	jne    800b7e <strtol+0x2d>
		s++;
  800b74:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
  800b77:	bf 00 00 00 00       	mov    $0x0,%edi
  800b7c:	eb 10                	jmp    800b8e <strtol+0x3d>
  800b7e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
  800b83:	3c 2d                	cmp    $0x2d,%al
  800b85:	75 07                	jne    800b8e <strtol+0x3d>
		s++, neg = 1;
  800b87:	8d 52 01             	lea    0x1(%edx),%edx
  800b8a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b8e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b94:	75 15                	jne    800bab <strtol+0x5a>
  800b96:	80 3a 30             	cmpb   $0x30,(%edx)
  800b99:	75 10                	jne    800bab <strtol+0x5a>
  800b9b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b9f:	75 0a                	jne    800bab <strtol+0x5a>
		s += 2, base = 16;
  800ba1:	83 c2 02             	add    $0x2,%edx
  800ba4:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ba9:	eb 10                	jmp    800bbb <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800bab:	85 db                	test   %ebx,%ebx
  800bad:	75 0c                	jne    800bbb <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800baf:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
  800bb1:	80 3a 30             	cmpb   $0x30,(%edx)
  800bb4:	75 05                	jne    800bbb <strtol+0x6a>
		s++, base = 8;
  800bb6:	83 c2 01             	add    $0x1,%edx
  800bb9:	b3 08                	mov    $0x8,%bl
		base = 10;
  800bbb:	b8 00 00 00 00       	mov    $0x0,%eax
  800bc0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bc3:	0f b6 0a             	movzbl (%edx),%ecx
  800bc6:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bc9:	89 f3                	mov    %esi,%ebx
  800bcb:	80 fb 09             	cmp    $0x9,%bl
  800bce:	77 08                	ja     800bd8 <strtol+0x87>
			dig = *s - '0';
  800bd0:	0f be c9             	movsbl %cl,%ecx
  800bd3:	83 e9 30             	sub    $0x30,%ecx
  800bd6:	eb 22                	jmp    800bfa <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
  800bd8:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800bdb:	89 f3                	mov    %esi,%ebx
  800bdd:	80 fb 19             	cmp    $0x19,%bl
  800be0:	77 08                	ja     800bea <strtol+0x99>
			dig = *s - 'a' + 10;
  800be2:	0f be c9             	movsbl %cl,%ecx
  800be5:	83 e9 57             	sub    $0x57,%ecx
  800be8:	eb 10                	jmp    800bfa <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
  800bea:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800bed:	89 f3                	mov    %esi,%ebx
  800bef:	80 fb 19             	cmp    $0x19,%bl
  800bf2:	77 16                	ja     800c0a <strtol+0xb9>
			dig = *s - 'A' + 10;
  800bf4:	0f be c9             	movsbl %cl,%ecx
  800bf7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bfa:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
  800bfd:	7d 0f                	jge    800c0e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bff:	83 c2 01             	add    $0x1,%edx
  800c02:	0f af 45 f0          	imul   -0x10(%ebp),%eax
  800c06:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800c08:	eb b9                	jmp    800bc3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
  800c0a:	89 c1                	mov    %eax,%ecx
  800c0c:	eb 02                	jmp    800c10 <strtol+0xbf>
		if (dig >= base)
  800c0e:	89 c1                	mov    %eax,%ecx

	if (endptr)
  800c10:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c14:	74 05                	je     800c1b <strtol+0xca>
		*endptr = (char *) s;
  800c16:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800c19:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800c1b:	89 ca                	mov    %ecx,%edx
  800c1d:	f7 da                	neg    %edx
  800c1f:	85 ff                	test   %edi,%edi
  800c21:	0f 45 c2             	cmovne %edx,%eax
}
  800c24:	83 c4 04             	add    $0x4,%esp
  800c27:	5b                   	pop    %ebx
  800c28:	5e                   	pop    %esi
  800c29:	5f                   	pop    %edi
  800c2a:	5d                   	pop    %ebp
  800c2b:	c3                   	ret    
  800c2c:	66 90                	xchg   %ax,%ax
  800c2e:	66 90                	xchg   %ax,%ax

00800c30 <__udivdi3>:
  800c30:	83 ec 1c             	sub    $0x1c,%esp
  800c33:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  800c37:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800c3b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c3f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c43:	8b 7c 24 20          	mov    0x20(%esp),%edi
  800c47:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  800c4b:	85 c0                	test   %eax,%eax
  800c4d:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c51:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c55:	89 ea                	mov    %ebp,%edx
  800c57:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c5b:	75 33                	jne    800c90 <__udivdi3+0x60>
  800c5d:	39 e9                	cmp    %ebp,%ecx
  800c5f:	77 6f                	ja     800cd0 <__udivdi3+0xa0>
  800c61:	85 c9                	test   %ecx,%ecx
  800c63:	89 ce                	mov    %ecx,%esi
  800c65:	75 0b                	jne    800c72 <__udivdi3+0x42>
  800c67:	b8 01 00 00 00       	mov    $0x1,%eax
  800c6c:	31 d2                	xor    %edx,%edx
  800c6e:	f7 f1                	div    %ecx
  800c70:	89 c6                	mov    %eax,%esi
  800c72:	31 d2                	xor    %edx,%edx
  800c74:	89 e8                	mov    %ebp,%eax
  800c76:	f7 f6                	div    %esi
  800c78:	89 c5                	mov    %eax,%ebp
  800c7a:	89 f8                	mov    %edi,%eax
  800c7c:	f7 f6                	div    %esi
  800c7e:	89 ea                	mov    %ebp,%edx
  800c80:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c84:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c88:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c8c:	83 c4 1c             	add    $0x1c,%esp
  800c8f:	c3                   	ret    
  800c90:	39 e8                	cmp    %ebp,%eax
  800c92:	77 24                	ja     800cb8 <__udivdi3+0x88>
  800c94:	0f bd c8             	bsr    %eax,%ecx
  800c97:	83 f1 1f             	xor    $0x1f,%ecx
  800c9a:	89 0c 24             	mov    %ecx,(%esp)
  800c9d:	75 49                	jne    800ce8 <__udivdi3+0xb8>
  800c9f:	8b 74 24 08          	mov    0x8(%esp),%esi
  800ca3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  800ca7:	0f 86 ab 00 00 00    	jbe    800d58 <__udivdi3+0x128>
  800cad:	39 e8                	cmp    %ebp,%eax
  800caf:	0f 82 a3 00 00 00    	jb     800d58 <__udivdi3+0x128>
  800cb5:	8d 76 00             	lea    0x0(%esi),%esi
  800cb8:	31 d2                	xor    %edx,%edx
  800cba:	31 c0                	xor    %eax,%eax
  800cbc:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cc0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cc4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800cc8:	83 c4 1c             	add    $0x1c,%esp
  800ccb:	c3                   	ret    
  800ccc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cd0:	89 f8                	mov    %edi,%eax
  800cd2:	f7 f1                	div    %ecx
  800cd4:	31 d2                	xor    %edx,%edx
  800cd6:	8b 74 24 10          	mov    0x10(%esp),%esi
  800cda:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800cde:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800ce2:	83 c4 1c             	add    $0x1c,%esp
  800ce5:	c3                   	ret    
  800ce6:	66 90                	xchg   %ax,%ax
  800ce8:	0f b6 0c 24          	movzbl (%esp),%ecx
  800cec:	89 c6                	mov    %eax,%esi
  800cee:	b8 20 00 00 00       	mov    $0x20,%eax
  800cf3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  800cf7:	2b 04 24             	sub    (%esp),%eax
  800cfa:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800cfe:	d3 e6                	shl    %cl,%esi
  800d00:	89 c1                	mov    %eax,%ecx
  800d02:	d3 ed                	shr    %cl,%ebp
  800d04:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d08:	09 f5                	or     %esi,%ebp
  800d0a:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d0e:	d3 e6                	shl    %cl,%esi
  800d10:	89 c1                	mov    %eax,%ecx
  800d12:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d16:	89 d6                	mov    %edx,%esi
  800d18:	d3 ee                	shr    %cl,%esi
  800d1a:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d1e:	d3 e2                	shl    %cl,%edx
  800d20:	89 c1                	mov    %eax,%ecx
  800d22:	d3 ef                	shr    %cl,%edi
  800d24:	09 d7                	or     %edx,%edi
  800d26:	89 f2                	mov    %esi,%edx
  800d28:	89 f8                	mov    %edi,%eax
  800d2a:	f7 f5                	div    %ebp
  800d2c:	89 d6                	mov    %edx,%esi
  800d2e:	89 c7                	mov    %eax,%edi
  800d30:	f7 64 24 04          	mull   0x4(%esp)
  800d34:	39 d6                	cmp    %edx,%esi
  800d36:	72 30                	jb     800d68 <__udivdi3+0x138>
  800d38:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800d3c:	0f b6 0c 24          	movzbl (%esp),%ecx
  800d40:	d3 e5                	shl    %cl,%ebp
  800d42:	39 c5                	cmp    %eax,%ebp
  800d44:	73 04                	jae    800d4a <__udivdi3+0x11a>
  800d46:	39 d6                	cmp    %edx,%esi
  800d48:	74 1e                	je     800d68 <__udivdi3+0x138>
  800d4a:	89 f8                	mov    %edi,%eax
  800d4c:	31 d2                	xor    %edx,%edx
  800d4e:	e9 69 ff ff ff       	jmp    800cbc <__udivdi3+0x8c>
  800d53:	90                   	nop
  800d54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d58:	31 d2                	xor    %edx,%edx
  800d5a:	b8 01 00 00 00       	mov    $0x1,%eax
  800d5f:	e9 58 ff ff ff       	jmp    800cbc <__udivdi3+0x8c>
  800d64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d68:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d6b:	31 d2                	xor    %edx,%edx
  800d6d:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d71:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d75:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d79:	83 c4 1c             	add    $0x1c,%esp
  800d7c:	c3                   	ret    
  800d7d:	66 90                	xchg   %ax,%ax
  800d7f:	90                   	nop

00800d80 <__umoddi3>:
  800d80:	83 ec 2c             	sub    $0x2c,%esp
  800d83:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  800d87:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d8b:	89 74 24 20          	mov    %esi,0x20(%esp)
  800d8f:	8b 74 24 38          	mov    0x38(%esp),%esi
  800d93:	89 7c 24 24          	mov    %edi,0x24(%esp)
  800d97:	8b 7c 24 34          	mov    0x34(%esp),%edi
  800d9b:	85 c0                	test   %eax,%eax
  800d9d:	89 c2                	mov    %eax,%edx
  800d9f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  800da3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  800da7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dab:	89 74 24 10          	mov    %esi,0x10(%esp)
  800daf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800db3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800db7:	75 1f                	jne    800dd8 <__umoddi3+0x58>
  800db9:	39 fe                	cmp    %edi,%esi
  800dbb:	76 63                	jbe    800e20 <__umoddi3+0xa0>
  800dbd:	89 c8                	mov    %ecx,%eax
  800dbf:	89 fa                	mov    %edi,%edx
  800dc1:	f7 f6                	div    %esi
  800dc3:	89 d0                	mov    %edx,%eax
  800dc5:	31 d2                	xor    %edx,%edx
  800dc7:	8b 74 24 20          	mov    0x20(%esp),%esi
  800dcb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800dcf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800dd3:	83 c4 2c             	add    $0x2c,%esp
  800dd6:	c3                   	ret    
  800dd7:	90                   	nop
  800dd8:	39 f8                	cmp    %edi,%eax
  800dda:	77 64                	ja     800e40 <__umoddi3+0xc0>
  800ddc:	0f bd e8             	bsr    %eax,%ebp
  800ddf:	83 f5 1f             	xor    $0x1f,%ebp
  800de2:	75 74                	jne    800e58 <__umoddi3+0xd8>
  800de4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800de8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  800dec:	0f 87 0e 01 00 00    	ja     800f00 <__umoddi3+0x180>
  800df2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  800df6:	29 f1                	sub    %esi,%ecx
  800df8:	19 c7                	sbb    %eax,%edi
  800dfa:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  800dfe:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800e02:	8b 44 24 14          	mov    0x14(%esp),%eax
  800e06:	8b 54 24 18          	mov    0x18(%esp),%edx
  800e0a:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e0e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e12:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e16:	83 c4 2c             	add    $0x2c,%esp
  800e19:	c3                   	ret    
  800e1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e20:	85 f6                	test   %esi,%esi
  800e22:	89 f5                	mov    %esi,%ebp
  800e24:	75 0b                	jne    800e31 <__umoddi3+0xb1>
  800e26:	b8 01 00 00 00       	mov    $0x1,%eax
  800e2b:	31 d2                	xor    %edx,%edx
  800e2d:	f7 f6                	div    %esi
  800e2f:	89 c5                	mov    %eax,%ebp
  800e31:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e35:	31 d2                	xor    %edx,%edx
  800e37:	f7 f5                	div    %ebp
  800e39:	89 c8                	mov    %ecx,%eax
  800e3b:	f7 f5                	div    %ebp
  800e3d:	eb 84                	jmp    800dc3 <__umoddi3+0x43>
  800e3f:	90                   	nop
  800e40:	89 c8                	mov    %ecx,%eax
  800e42:	89 fa                	mov    %edi,%edx
  800e44:	8b 74 24 20          	mov    0x20(%esp),%esi
  800e48:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800e4c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800e50:	83 c4 2c             	add    $0x2c,%esp
  800e53:	c3                   	ret    
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e5c:	be 20 00 00 00       	mov    $0x20,%esi
  800e61:	89 e9                	mov    %ebp,%ecx
  800e63:	29 ee                	sub    %ebp,%esi
  800e65:	d3 e2                	shl    %cl,%edx
  800e67:	89 f1                	mov    %esi,%ecx
  800e69:	d3 e8                	shr    %cl,%eax
  800e6b:	89 e9                	mov    %ebp,%ecx
  800e6d:	09 d0                	or     %edx,%eax
  800e6f:	89 fa                	mov    %edi,%edx
  800e71:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e75:	8b 44 24 10          	mov    0x10(%esp),%eax
  800e79:	d3 e0                	shl    %cl,%eax
  800e7b:	89 f1                	mov    %esi,%ecx
  800e7d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e81:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  800e85:	d3 ea                	shr    %cl,%edx
  800e87:	89 e9                	mov    %ebp,%ecx
  800e89:	d3 e7                	shl    %cl,%edi
  800e8b:	89 f1                	mov    %esi,%ecx
  800e8d:	d3 e8                	shr    %cl,%eax
  800e8f:	89 e9                	mov    %ebp,%ecx
  800e91:	09 f8                	or     %edi,%eax
  800e93:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800e97:	f7 74 24 0c          	divl   0xc(%esp)
  800e9b:	d3 e7                	shl    %cl,%edi
  800e9d:	89 7c 24 18          	mov    %edi,0x18(%esp)
  800ea1:	89 d7                	mov    %edx,%edi
  800ea3:	f7 64 24 10          	mull   0x10(%esp)
  800ea7:	39 d7                	cmp    %edx,%edi
  800ea9:	89 c1                	mov    %eax,%ecx
  800eab:	89 54 24 14          	mov    %edx,0x14(%esp)
  800eaf:	72 3b                	jb     800eec <__umoddi3+0x16c>
  800eb1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  800eb5:	72 31                	jb     800ee8 <__umoddi3+0x168>
  800eb7:	8b 44 24 18          	mov    0x18(%esp),%eax
  800ebb:	29 c8                	sub    %ecx,%eax
  800ebd:	19 d7                	sbb    %edx,%edi
  800ebf:	89 e9                	mov    %ebp,%ecx
  800ec1:	89 fa                	mov    %edi,%edx
  800ec3:	d3 e8                	shr    %cl,%eax
  800ec5:	89 f1                	mov    %esi,%ecx
  800ec7:	d3 e2                	shl    %cl,%edx
  800ec9:	89 e9                	mov    %ebp,%ecx
  800ecb:	09 d0                	or     %edx,%eax
  800ecd:	89 fa                	mov    %edi,%edx
  800ecf:	d3 ea                	shr    %cl,%edx
  800ed1:	8b 74 24 20          	mov    0x20(%esp),%esi
  800ed5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  800ed9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  800edd:	83 c4 2c             	add    $0x2c,%esp
  800ee0:	c3                   	ret    
  800ee1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ee8:	39 d7                	cmp    %edx,%edi
  800eea:	75 cb                	jne    800eb7 <__umoddi3+0x137>
  800eec:	8b 54 24 14          	mov    0x14(%esp),%edx
  800ef0:	89 c1                	mov    %eax,%ecx
  800ef2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  800ef6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  800efa:	eb bb                	jmp    800eb7 <__umoddi3+0x137>
  800efc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f00:	3b 44 24 18          	cmp    0x18(%esp),%eax
  800f04:	0f 82 e8 fe ff ff    	jb     800df2 <__umoddi3+0x72>
  800f0a:	e9 f3 fe ff ff       	jmp    800e02 <__umoddi3+0x82>
