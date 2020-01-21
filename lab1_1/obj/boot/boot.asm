
obj/boot/boot.out：     文件格式 elf32-i386


Disassembly of section .text:

00007c00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7c00:	fa                   	cli    
  cld                         # String operations increment
    7c01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7c02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0e:	75 fa                	jne    7c0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c18:	75 fa                	jne    7c14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	64 7c 0f             	fs jl  7c33 <protcseg+0x1>
  movl    %cr0, %eax
    7c24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7c26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7c2d:	ea                   	.byte 0xea
    7c2e:	32 7c 08 00          	xor    0x0(%eax,%ecx,1),%bh

00007c32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7c32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7c3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7c3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call bootmain
    7c45:	e8 c1 00 00 00       	call   7d0b <bootmain>

00007c4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7c4a:	eb fe                	jmp    7c4a <spin>

00007c4c <gdt>:
	...
    7c54:	ff                   	(bad)  
    7c55:	ff 00                	incl   (%eax)
    7c57:	00 00                	add    %al,(%eax)
    7c59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c60:	00                   	.byte 0x0
    7c61:	92                   	xchg   %eax,%edx
    7c62:	cf                   	iret   
	...

00007c64 <gdtdesc>:
    7c64:	17                   	pop    %ss
    7c65:	00 4c 7c 00          	add    %cl,0x0(%esp,%edi,2)
	...

00007c6a <waitdisk>:
	}
}

void
waitdisk(void)
{
    7c6a:	55                   	push   %ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7c6b:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c70:	89 e5                	mov    %esp,%ebp
    7c72:	ec                   	in     (%dx),%al
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7c73:	83 e0 c0             	and    $0xffffffc0,%eax
    7c76:	3c 40                	cmp    $0x40,%al
    7c78:	75 f8                	jne    7c72 <waitdisk+0x8>
		/* do nothing */;
}
    7c7a:	5d                   	pop    %ebp
    7c7b:	c3                   	ret    

00007c7c <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7c7c:	55                   	push   %ebp
    7c7d:	89 e5                	mov    %esp,%ebp
    7c7f:	57                   	push   %edi
    7c80:	53                   	push   %ebx
    7c81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// wait for disk to be ready
	waitdisk();
    7c84:	e8 e1 ff ff ff       	call   7c6a <waitdisk>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c89:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7c8e:	b0 01                	mov    $0x1,%al
    7c90:	ee                   	out    %al,(%dx)
	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7c91:	0f b6 c3             	movzbl %bl,%eax
    7c94:	b2 f3                	mov    $0xf3,%dl
    7c96:	ee                   	out    %al,(%dx)
    7c97:	0f b6 c7             	movzbl %bh,%eax
    7c9a:	b2 f4                	mov    $0xf4,%dl
    7c9c:	ee                   	out    %al,(%dx)
	outb(0x1F5, offset >> 16);
    7c9d:	89 d8                	mov    %ebx,%eax
    7c9f:	b2 f5                	mov    $0xf5,%dl
    7ca1:	c1 e8 10             	shr    $0x10,%eax
}
    7ca4:	25 ff 00 00 00       	and    $0xff,%eax
    7ca9:	ee                   	out    %al,(%dx)
    7caa:	89 d8                	mov    %ebx,%eax
    7cac:	b2 f6                	mov    $0xf6,%dl
    7cae:	c1 e8 18             	shr    $0x18,%eax
    7cb1:	0c e0                	or     $0xe0,%al
    7cb3:	ee                   	out    %al,(%dx)
    7cb4:	b0 20                	mov    $0x20,%al
    7cb6:	b2 f7                	mov    $0xf7,%dl
    7cb8:	ee                   	out    %al,(%dx)
	waitdisk();
    7cb9:	e8 ac ff ff ff       	call   7c6a <waitdisk>
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7cbe:	8b 7d 08             	mov    0x8(%ebp),%edi
    7cc1:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cc6:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7ccb:	fc                   	cld    
    7ccc:	f2 6d                	repnz insl (%dx),%es:(%edi)
}
    7cce:	5b                   	pop    %ebx
    7ccf:	5f                   	pop    %edi
    7cd0:	5d                   	pop    %ebp
    7cd1:	c3                   	ret    

00007cd2 <readseg>:
{
    7cd2:	55                   	push   %ebp
    7cd3:	89 e5                	mov    %esp,%ebp
    7cd5:	57                   	push   %edi
	end_pa = pa + count;
    7cd6:	8b 7d 0c             	mov    0xc(%ebp),%edi
{
    7cd9:	56                   	push   %esi
    7cda:	8b 75 10             	mov    0x10(%ebp),%esi
    7cdd:	53                   	push   %ebx
    7cde:	8b 5d 08             	mov    0x8(%ebp),%ebx
	offset = (offset / SECTSIZE) + 1;
    7ce1:	c1 ee 09             	shr    $0x9,%esi
	end_pa = pa + count;
    7ce4:	01 df                	add    %ebx,%edi
	offset = (offset / SECTSIZE) + 1;
    7ce6:	46                   	inc    %esi
	pa &= ~(SECTSIZE - 1);
    7ce7:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
	while (pa < end_pa) {
    7ced:	eb 10                	jmp    7cff <readseg+0x2d>
		readsect((uint8_t*) pa, offset);
    7cef:	56                   	push   %esi
		offset++;
    7cf0:	46                   	inc    %esi
		readsect((uint8_t*) pa, offset);
    7cf1:	53                   	push   %ebx
		pa += SECTSIZE;
    7cf2:	81 c3 00 02 00 00    	add    $0x200,%ebx
		readsect((uint8_t*) pa, offset);
    7cf8:	e8 7f ff ff ff       	call   7c7c <readsect>
		offset++;
    7cfd:	58                   	pop    %eax
    7cfe:	5a                   	pop    %edx
	while (pa < end_pa) {
    7cff:	39 fb                	cmp    %edi,%ebx
    7d01:	72 ec                	jb     7cef <readseg+0x1d>
}
    7d03:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d06:	5b                   	pop    %ebx
    7d07:	5e                   	pop    %esi
    7d08:	5f                   	pop    %edi
    7d09:	5d                   	pop    %ebp
    7d0a:	c3                   	ret    

00007d0b <bootmain>:
{
    7d0b:	55                   	push   %ebp
    7d0c:	89 e5                	mov    %esp,%ebp
    7d0e:	56                   	push   %esi
    7d0f:	53                   	push   %ebx
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7d10:	6a 00                	push   $0x0
    7d12:	68 00 10 00 00       	push   $0x1000
    7d17:	68 00 00 01 00       	push   $0x10000
    7d1c:	e8 b1 ff ff ff       	call   7cd2 <readseg>
	if (ELFHDR->e_magic != ELF_MAGIC)
    7d21:	83 c4 0c             	add    $0xc,%esp
    7d24:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d2b:	45 4c 46 
    7d2e:	75 39                	jne    7d69 <bootmain+0x5e>
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d30:	8b 1d 1c 00 01 00    	mov    0x1001c,%ebx
	eph = ph + ELFHDR->e_phnum;
    7d36:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d3d:	81 c3 00 00 01 00    	add    $0x10000,%ebx
	eph = ph + ELFHDR->e_phnum;
    7d43:	c1 e0 05             	shl    $0x5,%eax
    7d46:	8d 34 03             	lea    (%ebx,%eax,1),%esi
	for (; ph < eph; ph++)
    7d49:	eb 14                	jmp    7d5f <bootmain+0x54>
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7d4b:	ff 73 04             	pushl  0x4(%ebx)
    7d4e:	ff 73 14             	pushl  0x14(%ebx)
    7d51:	ff 73 0c             	pushl  0xc(%ebx)
	for (; ph < eph; ph++)
    7d54:	83 c3 20             	add    $0x20,%ebx
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7d57:	e8 76 ff ff ff       	call   7cd2 <readseg>
	for (; ph < eph; ph++)
    7d5c:	83 c4 0c             	add    $0xc,%esp
    7d5f:	39 f3                	cmp    %esi,%ebx
    7d61:	72 e8                	jb     7d4b <bootmain+0x40>
	((void (*)(void)) (ELFHDR->e_entry))();
    7d63:	ff 15 18 00 01 00    	call   *0x10018
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7d69:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7d6e:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7d73:	66 ef                	out    %ax,(%dx)
    7d75:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7d7a:	66 ef                	out    %ax,(%dx)
    7d7c:	eb fe                	jmp    7d7c <bootmain+0x71>
