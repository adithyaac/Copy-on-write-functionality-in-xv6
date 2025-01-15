
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	89e70713          	addi	a4,a4,-1890 # 800088f0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	13c78793          	addi	a5,a5,316 # 800061a0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc687>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	ecc78793          	addi	a5,a5,-308 # 80000f7a <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	636080e7          	jalr	1590(ra) # 80002762 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b46080e7          	jalr	-1210(ra) # 80000cd8 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	a7c080e7          	jalr	-1412(ra) # 80001c3c <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	3e4080e7          	jalr	996(ra) # 800025ac <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	122080e7          	jalr	290(ra) # 800022f8 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	4fa080e7          	jalr	1274(ra) # 8000270c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b5e080e7          	jalr	-1186(ra) # 80000d8c <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b48080e7          	jalr	-1208(ra) # 80000d8c <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a04080e7          	jalr	-1532(ra) # 80000cd8 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	4c6080e7          	jalr	1222(ra) # 800027b8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a8a080e7          	jalr	-1398(ra) # 80000d8c <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f16080e7          	jalr	-234(ra) # 8000235c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	7e0080e7          	jalr	2016(ra) # 80000c48 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00241797          	auipc	a5,0x241
    8000047c:	b6878793          	addi	a5,a5,-1176 # 80240fe0 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07a323          	sw	zero,1446(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b6c50513          	addi	a0,a0,-1172 # 800080d8 <digits+0x98>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	32f72923          	sw	a5,818(a4) # 800088b0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	536dad83          	lw	s11,1334(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4e050513          	addi	a0,a0,1248 # 80010ad8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	6d8080e7          	jalr	1752(ra) # 80000cd8 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	38250513          	addi	a0,a0,898 # 80010ad8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	62e080e7          	jalr	1582(ra) # 80000d8c <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	36648493          	addi	s1,s1,870 # 80010ad8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	4c4080e7          	jalr	1220(ra) # 80000c48 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	32650513          	addi	a0,a0,806 # 80010af8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	46e080e7          	jalr	1134(ra) # 80000c48 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	496080e7          	jalr	1174(ra) # 80000c8c <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0b27a783          	lw	a5,178(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	508080e7          	jalr	1288(ra) # 80000d2c <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0827b783          	ld	a5,130(a5) # 800088b8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	08273703          	ld	a4,130(a4) # 800088c0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	298a0a13          	addi	s4,s4,664 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	05048493          	addi	s1,s1,80 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	05098993          	addi	s3,s3,80 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	aca080e7          	jalr	-1334(ra) # 8000235c <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	22a50513          	addi	a0,a0,554 # 80010af8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	402080e7          	jalr	1026(ra) # 80000cd8 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fd27a783          	lw	a5,-46(a5) # 800088b0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fd873703          	ld	a4,-40(a4) # 800088c0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fc87b783          	ld	a5,-56(a5) # 800088b8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1fc98993          	addi	s3,s3,508 # 80010af8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fb448493          	addi	s1,s1,-76 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fb490913          	addi	s2,s2,-76 # 800088c0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	9dc080e7          	jalr	-1572(ra) # 800022f8 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1c648493          	addi	s1,s1,454 # 80010af8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f6e7bd23          	sd	a4,-134(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	434080e7          	jalr	1076(ra) # 80000d8c <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	13c48493          	addi	s1,s1,316 # 80010af8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	312080e7          	jalr	786(ra) # 80000cd8 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	3b4080e7          	jalr	948(ra) # 80000d8c <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009ea:	7179                	addi	sp,sp,-48
    800009ec:	f406                	sd	ra,40(sp)
    800009ee:	f022                	sd	s0,32(sp)
    800009f0:	ec26                	sd	s1,24(sp)
    800009f2:	e84a                	sd	s2,16(sp)
    800009f4:	e44e                	sd	s3,8(sp)
    800009f6:	1800                	addi	s0,sp,48
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    800009f8:	03451793          	slli	a5,a0,0x34
    800009fc:	e3dd                	bnez	a5,80000aa2 <kfree+0xb8>
    800009fe:	84aa                	mv	s1,a0
    80000a00:	00241797          	auipc	a5,0x241
    80000a04:	77878793          	addi	a5,a5,1912 # 80242178 <end>
    80000a08:	08f56d63          	bltu	a0,a5,80000aa2 <kfree+0xb8>
    80000a0c:	47c5                	li	a5,17
    80000a0e:	07ee                	slli	a5,a5,0x1b
    80000a10:	08f57963          	bgeu	a0,a5,80000aa2 <kfree+0xb8>
    panic("kfree");

  acquire(&ref_lock);
    80000a14:	00010517          	auipc	a0,0x10
    80000a18:	11c50513          	addi	a0,a0,284 # 80010b30 <ref_lock>
    80000a1c:	00000097          	auipc	ra,0x0
    80000a20:	2bc080e7          	jalr	700(ra) # 80000cd8 <acquire>

  // Decrement the reference count for the page

  // Only proceed to free if the reference count is zero
  if (reference_counters[(uint64)pa / PGSIZE] > 1)
    80000a24:	00c4d793          	srli	a5,s1,0xc
    80000a28:	00279693          	slli	a3,a5,0x2
    80000a2c:	00010717          	auipc	a4,0x10
    80000a30:	13c70713          	addi	a4,a4,316 # 80010b68 <reference_counters>
    80000a34:	9736                	add	a4,a4,a3
    80000a36:	4318                	lw	a4,0(a4)
    80000a38:	4685                	li	a3,1
    80000a3a:	06e6cc63          	blt	a3,a4,80000ab2 <kfree+0xc8>
    reference_counters[(uint64)pa / PGSIZE]--;
    release(&ref_lock);
    return;
  }

  reference_counters[(uint64)pa / PGSIZE] = 0;
    80000a3e:	078a                	slli	a5,a5,0x2
    80000a40:	00010717          	auipc	a4,0x10
    80000a44:	12870713          	addi	a4,a4,296 # 80010b68 <reference_counters>
    80000a48:	97ba                	add	a5,a5,a4
    80000a4a:	0007a023          	sw	zero,0(a5)
  release(&ref_lock);
    80000a4e:	00010917          	auipc	s2,0x10
    80000a52:	0e290913          	addi	s2,s2,226 # 80010b30 <ref_lock>
    80000a56:	854a                	mv	a0,s2
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	334080e7          	jalr	820(ra) # 80000d8c <release>

  memset(pa, 1, PGSIZE);
    80000a60:	6605                	lui	a2,0x1
    80000a62:	4585                	li	a1,1
    80000a64:	8526                	mv	a0,s1
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	36e080e7          	jalr	878(ra) # 80000dd4 <memset>

  r = (struct run *)pa;

  acquire(&kmem.lock);
    80000a6e:	00010997          	auipc	s3,0x10
    80000a72:	0da98993          	addi	s3,s3,218 # 80010b48 <kmem>
    80000a76:	854e                	mv	a0,s3
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	260080e7          	jalr	608(ra) # 80000cd8 <acquire>
  r->next = kmem.freelist;
    80000a80:	03093783          	ld	a5,48(s2)
    80000a84:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a86:	02993823          	sd	s1,48(s2)
  release(&kmem.lock);
    80000a8a:	854e                	mv	a0,s3
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	300080e7          	jalr	768(ra) # 80000d8c <release>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6145                	addi	sp,sp,48
    80000aa0:	8082                	ret
    panic("kfree");
    80000aa2:	00007517          	auipc	a0,0x7
    80000aa6:	5be50513          	addi	a0,a0,1470 # 80008060 <digits+0x20>
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>
    reference_counters[(uint64)pa / PGSIZE]--;
    80000ab2:	078a                	slli	a5,a5,0x2
    80000ab4:	00010697          	auipc	a3,0x10
    80000ab8:	0b468693          	addi	a3,a3,180 # 80010b68 <reference_counters>
    80000abc:	97b6                	add	a5,a5,a3
    80000abe:	377d                	addiw	a4,a4,-1
    80000ac0:	c398                	sw	a4,0(a5)
    release(&ref_lock);
    80000ac2:	00010517          	auipc	a0,0x10
    80000ac6:	06e50513          	addi	a0,a0,110 # 80010b30 <ref_lock>
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	2c2080e7          	jalr	706(ra) # 80000d8c <release>
    return;
    80000ad2:	b7c9                	j	80000a94 <kfree+0xaa>

0000000080000ad4 <freerange>:
{
    80000ad4:	7139                	addi	sp,sp,-64
    80000ad6:	fc06                	sd	ra,56(sp)
    80000ad8:	f822                	sd	s0,48(sp)
    80000ada:	f426                	sd	s1,40(sp)
    80000adc:	f04a                	sd	s2,32(sp)
    80000ade:	ec4e                	sd	s3,24(sp)
    80000ae0:	e852                	sd	s4,16(sp)
    80000ae2:	e456                	sd	s5,8(sp)
    80000ae4:	e05a                	sd	s6,0(sp)
    80000ae6:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000ae8:	6785                	lui	a5,0x1
    80000aea:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000aee:	9526                	add	a0,a0,s1
    80000af0:	74fd                	lui	s1,0xfffff
    80000af2:	8ce9                	and	s1,s1,a0
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000af4:	97a6                	add	a5,a5,s1
    80000af6:	04f5e763          	bltu	a1,a5,80000b44 <freerange+0x70>
    80000afa:	89ae                	mv	s3,a1
    acquire(&ref_lock);
    80000afc:	00010917          	auipc	s2,0x10
    80000b00:	03490913          	addi	s2,s2,52 # 80010b30 <ref_lock>
    reference_counters[((uint64)p) / PGSIZE] = 0;
    80000b04:	00010b17          	auipc	s6,0x10
    80000b08:	064b0b13          	addi	s6,s6,100 # 80010b68 <reference_counters>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b0c:	6a85                	lui	s5,0x1
    80000b0e:	6a09                	lui	s4,0x2
    acquire(&ref_lock);
    80000b10:	854a                	mv	a0,s2
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	1c6080e7          	jalr	454(ra) # 80000cd8 <acquire>
    reference_counters[((uint64)p) / PGSIZE] = 0;
    80000b1a:	00c4d793          	srli	a5,s1,0xc
    80000b1e:	078a                	slli	a5,a5,0x2
    80000b20:	97da                	add	a5,a5,s6
    80000b22:	0007a023          	sw	zero,0(a5)
    release(&ref_lock);
    80000b26:	854a                	mv	a0,s2
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	264080e7          	jalr	612(ra) # 80000d8c <release>
    kfree(p);
    80000b30:	8526                	mv	a0,s1
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	eb8080e7          	jalr	-328(ra) # 800009ea <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b3a:	87a6                	mv	a5,s1
    80000b3c:	94d6                	add	s1,s1,s5
    80000b3e:	97d2                	add	a5,a5,s4
    80000b40:	fcf9f8e3          	bgeu	s3,a5,80000b10 <freerange+0x3c>
}
    80000b44:	70e2                	ld	ra,56(sp)
    80000b46:	7442                	ld	s0,48(sp)
    80000b48:	74a2                	ld	s1,40(sp)
    80000b4a:	7902                	ld	s2,32(sp)
    80000b4c:	69e2                	ld	s3,24(sp)
    80000b4e:	6a42                	ld	s4,16(sp)
    80000b50:	6aa2                	ld	s5,8(sp)
    80000b52:	6b02                	ld	s6,0(sp)
    80000b54:	6121                	addi	sp,sp,64
    80000b56:	8082                	ret

0000000080000b58 <kinit>:
{
    80000b58:	1141                	addi	sp,sp,-16
    80000b5a:	e406                	sd	ra,8(sp)
    80000b5c:	e022                	sd	s0,0(sp)
    80000b5e:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b60:	00007597          	auipc	a1,0x7
    80000b64:	50858593          	addi	a1,a1,1288 # 80008068 <digits+0x28>
    80000b68:	00010517          	auipc	a0,0x10
    80000b6c:	fe050513          	addi	a0,a0,-32 # 80010b48 <kmem>
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	0d8080e7          	jalr	216(ra) # 80000c48 <initlock>
  initlock(&ref_lock, "ref_lock"); // Initialize the reference counter lock
    80000b78:	00007597          	auipc	a1,0x7
    80000b7c:	4f858593          	addi	a1,a1,1272 # 80008070 <digits+0x30>
    80000b80:	00010517          	auipc	a0,0x10
    80000b84:	fb050513          	addi	a0,a0,-80 # 80010b30 <ref_lock>
    80000b88:	00000097          	auipc	ra,0x0
    80000b8c:	0c0080e7          	jalr	192(ra) # 80000c48 <initlock>
  freerange(end, (void *)PHYSTOP);
    80000b90:	45c5                	li	a1,17
    80000b92:	05ee                	slli	a1,a1,0x1b
    80000b94:	00241517          	auipc	a0,0x241
    80000b98:	5e450513          	addi	a0,a0,1508 # 80242178 <end>
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	f38080e7          	jalr	-200(ra) # 80000ad4 <freerange>
}
    80000ba4:	60a2                	ld	ra,8(sp)
    80000ba6:	6402                	ld	s0,0(sp)
    80000ba8:	0141                	addi	sp,sp,16
    80000baa:	8082                	ret

0000000080000bac <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bac:	1101                	addi	sp,sp,-32
    80000bae:	ec06                	sd	ra,24(sp)
    80000bb0:	e822                	sd	s0,16(sp)
    80000bb2:	e426                	sd	s1,8(sp)
    80000bb4:	e04a                	sd	s2,0(sp)
    80000bb6:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bb8:	00010517          	auipc	a0,0x10
    80000bbc:	f9050513          	addi	a0,a0,-112 # 80010b48 <kmem>
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	118080e7          	jalr	280(ra) # 80000cd8 <acquire>
  r = kmem.freelist;
    80000bc8:	00010497          	auipc	s1,0x10
    80000bcc:	f984b483          	ld	s1,-104(s1) # 80010b60 <kmem+0x18>
  if (r)
    80000bd0:	c0bd                	beqz	s1,80000c36 <kalloc+0x8a>
    kmem.freelist = r->next;
    80000bd2:	609c                	ld	a5,0(s1)
    80000bd4:	00010917          	auipc	s2,0x10
    80000bd8:	f5c90913          	addi	s2,s2,-164 # 80010b30 <ref_lock>
    80000bdc:	02f93823          	sd	a5,48(s2)
  release(&kmem.lock);
    80000be0:	00010517          	auipc	a0,0x10
    80000be4:	f6850513          	addi	a0,a0,-152 # 80010b48 <kmem>
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	1a4080e7          	jalr	420(ra) # 80000d8c <release>

  if (r)
  {
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000bf0:	6605                	lui	a2,0x1
    80000bf2:	4595                	li	a1,5
    80000bf4:	8526                	mv	a0,s1
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	1de080e7          	jalr	478(ra) # 80000dd4 <memset>

    acquire(&ref_lock);                         // Acquire the lock for thread safety
    80000bfe:	854a                	mv	a0,s2
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	0d8080e7          	jalr	216(ra) # 80000cd8 <acquire>
    reference_counters[(uint64)r / PGSIZE] = 1; // Set the reference count to 1
    80000c08:	00c4d793          	srli	a5,s1,0xc
    80000c0c:	00279713          	slli	a4,a5,0x2
    80000c10:	00010797          	auipc	a5,0x10
    80000c14:	f5878793          	addi	a5,a5,-168 # 80010b68 <reference_counters>
    80000c18:	97ba                	add	a5,a5,a4
    80000c1a:	4705                	li	a4,1
    80000c1c:	c398                	sw	a4,0(a5)
    release(&ref_lock);                         // Release the lock
    80000c1e:	854a                	mv	a0,s2
    80000c20:	00000097          	auipc	ra,0x0
    80000c24:	16c080e7          	jalr	364(ra) # 80000d8c <release>
  }
  return (void *)r;
}
    80000c28:	8526                	mv	a0,s1
    80000c2a:	60e2                	ld	ra,24(sp)
    80000c2c:	6442                	ld	s0,16(sp)
    80000c2e:	64a2                	ld	s1,8(sp)
    80000c30:	6902                	ld	s2,0(sp)
    80000c32:	6105                	addi	sp,sp,32
    80000c34:	8082                	ret
  release(&kmem.lock);
    80000c36:	00010517          	auipc	a0,0x10
    80000c3a:	f1250513          	addi	a0,a0,-238 # 80010b48 <kmem>
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	14e080e7          	jalr	334(ra) # 80000d8c <release>
  if (r)
    80000c46:	b7cd                	j	80000c28 <kalloc+0x7c>

0000000080000c48 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c48:	1141                	addi	sp,sp,-16
    80000c4a:	e422                	sd	s0,8(sp)
    80000c4c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c4e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c50:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c54:	00053823          	sd	zero,16(a0)
}
    80000c58:	6422                	ld	s0,8(sp)
    80000c5a:	0141                	addi	sp,sp,16
    80000c5c:	8082                	ret

0000000080000c5e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c5e:	411c                	lw	a5,0(a0)
    80000c60:	e399                	bnez	a5,80000c66 <holding+0x8>
    80000c62:	4501                	li	a0,0
  return r;
}
    80000c64:	8082                	ret
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c70:	6904                	ld	s1,16(a0)
    80000c72:	00001097          	auipc	ra,0x1
    80000c76:	fae080e7          	jalr	-82(ra) # 80001c20 <mycpu>
    80000c7a:	40a48533          	sub	a0,s1,a0
    80000c7e:	00153513          	seqz	a0,a0
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret

0000000080000c8c <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c8c:	1101                	addi	sp,sp,-32
    80000c8e:	ec06                	sd	ra,24(sp)
    80000c90:	e822                	sd	s0,16(sp)
    80000c92:	e426                	sd	s1,8(sp)
    80000c94:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c96:	100024f3          	csrr	s1,sstatus
    80000c9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	f7c080e7          	jalr	-132(ra) # 80001c20 <mycpu>
    80000cac:	5d3c                	lw	a5,120(a0)
    80000cae:	cf89                	beqz	a5,80000cc8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cb0:	00001097          	auipc	ra,0x1
    80000cb4:	f70080e7          	jalr	-144(ra) # 80001c20 <mycpu>
    80000cb8:	5d3c                	lw	a5,120(a0)
    80000cba:	2785                	addiw	a5,a5,1
    80000cbc:	dd3c                	sw	a5,120(a0)
}
    80000cbe:	60e2                	ld	ra,24(sp)
    80000cc0:	6442                	ld	s0,16(sp)
    80000cc2:	64a2                	ld	s1,8(sp)
    80000cc4:	6105                	addi	sp,sp,32
    80000cc6:	8082                	ret
    mycpu()->intena = old;
    80000cc8:	00001097          	auipc	ra,0x1
    80000ccc:	f58080e7          	jalr	-168(ra) # 80001c20 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cd0:	8085                	srli	s1,s1,0x1
    80000cd2:	8885                	andi	s1,s1,1
    80000cd4:	dd64                	sw	s1,124(a0)
    80000cd6:	bfe9                	j	80000cb0 <push_off+0x24>

0000000080000cd8 <acquire>:
{
    80000cd8:	1101                	addi	sp,sp,-32
    80000cda:	ec06                	sd	ra,24(sp)
    80000cdc:	e822                	sd	s0,16(sp)
    80000cde:	e426                	sd	s1,8(sp)
    80000ce0:	1000                	addi	s0,sp,32
    80000ce2:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	fa8080e7          	jalr	-88(ra) # 80000c8c <push_off>
  if(holding(lk))
    80000cec:	8526                	mv	a0,s1
    80000cee:	00000097          	auipc	ra,0x0
    80000cf2:	f70080e7          	jalr	-144(ra) # 80000c5e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cf6:	4705                	li	a4,1
  if(holding(lk))
    80000cf8:	e115                	bnez	a0,80000d1c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cfa:	87ba                	mv	a5,a4
    80000cfc:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d00:	2781                	sext.w	a5,a5
    80000d02:	ffe5                	bnez	a5,80000cfa <acquire+0x22>
  __sync_synchronize();
    80000d04:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d08:	00001097          	auipc	ra,0x1
    80000d0c:	f18080e7          	jalr	-232(ra) # 80001c20 <mycpu>
    80000d10:	e888                	sd	a0,16(s1)
}
    80000d12:	60e2                	ld	ra,24(sp)
    80000d14:	6442                	ld	s0,16(sp)
    80000d16:	64a2                	ld	s1,8(sp)
    80000d18:	6105                	addi	sp,sp,32
    80000d1a:	8082                	ret
    panic("acquire");
    80000d1c:	00007517          	auipc	a0,0x7
    80000d20:	36450513          	addi	a0,a0,868 # 80008080 <digits+0x40>
    80000d24:	00000097          	auipc	ra,0x0
    80000d28:	81a080e7          	jalr	-2022(ra) # 8000053e <panic>

0000000080000d2c <pop_off>:

void
pop_off(void)
{
    80000d2c:	1141                	addi	sp,sp,-16
    80000d2e:	e406                	sd	ra,8(sp)
    80000d30:	e022                	sd	s0,0(sp)
    80000d32:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d34:	00001097          	auipc	ra,0x1
    80000d38:	eec080e7          	jalr	-276(ra) # 80001c20 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d40:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d42:	e78d                	bnez	a5,80000d6c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d44:	5d3c                	lw	a5,120(a0)
    80000d46:	02f05b63          	blez	a5,80000d7c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d4a:	37fd                	addiw	a5,a5,-1
    80000d4c:	0007871b          	sext.w	a4,a5
    80000d50:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d52:	eb09                	bnez	a4,80000d64 <pop_off+0x38>
    80000d54:	5d7c                	lw	a5,124(a0)
    80000d56:	c799                	beqz	a5,80000d64 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d5c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d60:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d64:	60a2                	ld	ra,8(sp)
    80000d66:	6402                	ld	s0,0(sp)
    80000d68:	0141                	addi	sp,sp,16
    80000d6a:	8082                	ret
    panic("pop_off - interruptible");
    80000d6c:	00007517          	auipc	a0,0x7
    80000d70:	31c50513          	addi	a0,a0,796 # 80008088 <digits+0x48>
    80000d74:	fffff097          	auipc	ra,0xfffff
    80000d78:	7ca080e7          	jalr	1994(ra) # 8000053e <panic>
    panic("pop_off");
    80000d7c:	00007517          	auipc	a0,0x7
    80000d80:	32450513          	addi	a0,a0,804 # 800080a0 <digits+0x60>
    80000d84:	fffff097          	auipc	ra,0xfffff
    80000d88:	7ba080e7          	jalr	1978(ra) # 8000053e <panic>

0000000080000d8c <release>:
{
    80000d8c:	1101                	addi	sp,sp,-32
    80000d8e:	ec06                	sd	ra,24(sp)
    80000d90:	e822                	sd	s0,16(sp)
    80000d92:	e426                	sd	s1,8(sp)
    80000d94:	1000                	addi	s0,sp,32
    80000d96:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d98:	00000097          	auipc	ra,0x0
    80000d9c:	ec6080e7          	jalr	-314(ra) # 80000c5e <holding>
    80000da0:	c115                	beqz	a0,80000dc4 <release+0x38>
  lk->cpu = 0;
    80000da2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000da6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000daa:	0f50000f          	fence	iorw,ow
    80000dae:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000db2:	00000097          	auipc	ra,0x0
    80000db6:	f7a080e7          	jalr	-134(ra) # 80000d2c <pop_off>
}
    80000dba:	60e2                	ld	ra,24(sp)
    80000dbc:	6442                	ld	s0,16(sp)
    80000dbe:	64a2                	ld	s1,8(sp)
    80000dc0:	6105                	addi	sp,sp,32
    80000dc2:	8082                	ret
    panic("release");
    80000dc4:	00007517          	auipc	a0,0x7
    80000dc8:	2e450513          	addi	a0,a0,740 # 800080a8 <digits+0x68>
    80000dcc:	fffff097          	auipc	ra,0xfffff
    80000dd0:	772080e7          	jalr	1906(ra) # 8000053e <panic>

0000000080000dd4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dd4:	1141                	addi	sp,sp,-16
    80000dd6:	e422                	sd	s0,8(sp)
    80000dd8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dda:	ca19                	beqz	a2,80000df0 <memset+0x1c>
    80000ddc:	87aa                	mv	a5,a0
    80000dde:	1602                	slli	a2,a2,0x20
    80000de0:	9201                	srli	a2,a2,0x20
    80000de2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000de6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dea:	0785                	addi	a5,a5,1
    80000dec:	fee79de3          	bne	a5,a4,80000de6 <memset+0x12>
  }
  return dst;
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret

0000000080000df6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dfc:	ca05                	beqz	a2,80000e2c <memcmp+0x36>
    80000dfe:	fff6069b          	addiw	a3,a2,-1
    80000e02:	1682                	slli	a3,a3,0x20
    80000e04:	9281                	srli	a3,a3,0x20
    80000e06:	0685                	addi	a3,a3,1
    80000e08:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e0a:	00054783          	lbu	a5,0(a0)
    80000e0e:	0005c703          	lbu	a4,0(a1)
    80000e12:	00e79863          	bne	a5,a4,80000e22 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e16:	0505                	addi	a0,a0,1
    80000e18:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e1a:	fed518e3          	bne	a0,a3,80000e0a <memcmp+0x14>
  }

  return 0;
    80000e1e:	4501                	li	a0,0
    80000e20:	a019                	j	80000e26 <memcmp+0x30>
      return *s1 - *s2;
    80000e22:	40e7853b          	subw	a0,a5,a4
}
    80000e26:	6422                	ld	s0,8(sp)
    80000e28:	0141                	addi	sp,sp,16
    80000e2a:	8082                	ret
  return 0;
    80000e2c:	4501                	li	a0,0
    80000e2e:	bfe5                	j	80000e26 <memcmp+0x30>

0000000080000e30 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e30:	1141                	addi	sp,sp,-16
    80000e32:	e422                	sd	s0,8(sp)
    80000e34:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e36:	c205                	beqz	a2,80000e56 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e38:	02a5e263          	bltu	a1,a0,80000e5c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e3c:	1602                	slli	a2,a2,0x20
    80000e3e:	9201                	srli	a2,a2,0x20
    80000e40:	00c587b3          	add	a5,a1,a2
{
    80000e44:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e46:	0585                	addi	a1,a1,1
    80000e48:	0705                	addi	a4,a4,1
    80000e4a:	fff5c683          	lbu	a3,-1(a1)
    80000e4e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e52:	fef59ae3          	bne	a1,a5,80000e46 <memmove+0x16>

  return dst;
}
    80000e56:	6422                	ld	s0,8(sp)
    80000e58:	0141                	addi	sp,sp,16
    80000e5a:	8082                	ret
  if(s < d && s + n > d){
    80000e5c:	02061693          	slli	a3,a2,0x20
    80000e60:	9281                	srli	a3,a3,0x20
    80000e62:	00d58733          	add	a4,a1,a3
    80000e66:	fce57be3          	bgeu	a0,a4,80000e3c <memmove+0xc>
    d += n;
    80000e6a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e6c:	fff6079b          	addiw	a5,a2,-1
    80000e70:	1782                	slli	a5,a5,0x20
    80000e72:	9381                	srli	a5,a5,0x20
    80000e74:	fff7c793          	not	a5,a5
    80000e78:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e7a:	177d                	addi	a4,a4,-1
    80000e7c:	16fd                	addi	a3,a3,-1
    80000e7e:	00074603          	lbu	a2,0(a4)
    80000e82:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e86:	fee79ae3          	bne	a5,a4,80000e7a <memmove+0x4a>
    80000e8a:	b7f1                	j	80000e56 <memmove+0x26>

0000000080000e8c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e406                	sd	ra,8(sp)
    80000e90:	e022                	sd	s0,0(sp)
    80000e92:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e94:	00000097          	auipc	ra,0x0
    80000e98:	f9c080e7          	jalr	-100(ra) # 80000e30 <memmove>
}
    80000e9c:	60a2                	ld	ra,8(sp)
    80000e9e:	6402                	ld	s0,0(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret

0000000080000ea4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ea4:	1141                	addi	sp,sp,-16
    80000ea6:	e422                	sd	s0,8(sp)
    80000ea8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eaa:	ce11                	beqz	a2,80000ec6 <strncmp+0x22>
    80000eac:	00054783          	lbu	a5,0(a0)
    80000eb0:	cf89                	beqz	a5,80000eca <strncmp+0x26>
    80000eb2:	0005c703          	lbu	a4,0(a1)
    80000eb6:	00f71a63          	bne	a4,a5,80000eca <strncmp+0x26>
    n--, p++, q++;
    80000eba:	367d                	addiw	a2,a2,-1
    80000ebc:	0505                	addi	a0,a0,1
    80000ebe:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ec0:	f675                	bnez	a2,80000eac <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ec2:	4501                	li	a0,0
    80000ec4:	a809                	j	80000ed6 <strncmp+0x32>
    80000ec6:	4501                	li	a0,0
    80000ec8:	a039                	j	80000ed6 <strncmp+0x32>
  if(n == 0)
    80000eca:	ca09                	beqz	a2,80000edc <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ecc:	00054503          	lbu	a0,0(a0)
    80000ed0:	0005c783          	lbu	a5,0(a1)
    80000ed4:	9d1d                	subw	a0,a0,a5
}
    80000ed6:	6422                	ld	s0,8(sp)
    80000ed8:	0141                	addi	sp,sp,16
    80000eda:	8082                	ret
    return 0;
    80000edc:	4501                	li	a0,0
    80000ede:	bfe5                	j	80000ed6 <strncmp+0x32>

0000000080000ee0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ee0:	1141                	addi	sp,sp,-16
    80000ee2:	e422                	sd	s0,8(sp)
    80000ee4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ee6:	872a                	mv	a4,a0
    80000ee8:	8832                	mv	a6,a2
    80000eea:	367d                	addiw	a2,a2,-1
    80000eec:	01005963          	blez	a6,80000efe <strncpy+0x1e>
    80000ef0:	0705                	addi	a4,a4,1
    80000ef2:	0005c783          	lbu	a5,0(a1)
    80000ef6:	fef70fa3          	sb	a5,-1(a4)
    80000efa:	0585                	addi	a1,a1,1
    80000efc:	f7f5                	bnez	a5,80000ee8 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000efe:	86ba                	mv	a3,a4
    80000f00:	00c05c63          	blez	a2,80000f18 <strncpy+0x38>
    *s++ = 0;
    80000f04:	0685                	addi	a3,a3,1
    80000f06:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f0a:	fff6c793          	not	a5,a3
    80000f0e:	9fb9                	addw	a5,a5,a4
    80000f10:	010787bb          	addw	a5,a5,a6
    80000f14:	fef048e3          	bgtz	a5,80000f04 <strncpy+0x24>
  return os;
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret

0000000080000f1e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f1e:	1141                	addi	sp,sp,-16
    80000f20:	e422                	sd	s0,8(sp)
    80000f22:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f24:	02c05363          	blez	a2,80000f4a <safestrcpy+0x2c>
    80000f28:	fff6069b          	addiw	a3,a2,-1
    80000f2c:	1682                	slli	a3,a3,0x20
    80000f2e:	9281                	srli	a3,a3,0x20
    80000f30:	96ae                	add	a3,a3,a1
    80000f32:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f34:	00d58963          	beq	a1,a3,80000f46 <safestrcpy+0x28>
    80000f38:	0585                	addi	a1,a1,1
    80000f3a:	0785                	addi	a5,a5,1
    80000f3c:	fff5c703          	lbu	a4,-1(a1)
    80000f40:	fee78fa3          	sb	a4,-1(a5)
    80000f44:	fb65                	bnez	a4,80000f34 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f46:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f4a:	6422                	ld	s0,8(sp)
    80000f4c:	0141                	addi	sp,sp,16
    80000f4e:	8082                	ret

0000000080000f50 <strlen>:

int
strlen(const char *s)
{
    80000f50:	1141                	addi	sp,sp,-16
    80000f52:	e422                	sd	s0,8(sp)
    80000f54:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f56:	00054783          	lbu	a5,0(a0)
    80000f5a:	cf91                	beqz	a5,80000f76 <strlen+0x26>
    80000f5c:	0505                	addi	a0,a0,1
    80000f5e:	87aa                	mv	a5,a0
    80000f60:	4685                	li	a3,1
    80000f62:	9e89                	subw	a3,a3,a0
    80000f64:	00f6853b          	addw	a0,a3,a5
    80000f68:	0785                	addi	a5,a5,1
    80000f6a:	fff7c703          	lbu	a4,-1(a5)
    80000f6e:	fb7d                	bnez	a4,80000f64 <strlen+0x14>
    ;
  return n;
}
    80000f70:	6422                	ld	s0,8(sp)
    80000f72:	0141                	addi	sp,sp,16
    80000f74:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f76:	4501                	li	a0,0
    80000f78:	bfe5                	j	80000f70 <strlen+0x20>

0000000080000f7a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f7a:	1141                	addi	sp,sp,-16
    80000f7c:	e406                	sd	ra,8(sp)
    80000f7e:	e022                	sd	s0,0(sp)
    80000f80:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	c8e080e7          	jalr	-882(ra) # 80001c10 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f8a:	00008717          	auipc	a4,0x8
    80000f8e:	93e70713          	addi	a4,a4,-1730 # 800088c8 <started>
  if(cpuid() == 0){
    80000f92:	c139                	beqz	a0,80000fd8 <main+0x5e>
    while(started == 0)
    80000f94:	431c                	lw	a5,0(a4)
    80000f96:	2781                	sext.w	a5,a5
    80000f98:	dff5                	beqz	a5,80000f94 <main+0x1a>
      ;
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	c72080e7          	jalr	-910(ra) # 80001c10 <cpuid>
    80000fa6:	85aa                	mv	a1,a0
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	12050513          	addi	a0,a0,288 # 800080c8 <digits+0x88>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5d8080e7          	jalr	1496(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000fb8:	00000097          	auipc	ra,0x0
    80000fbc:	0d8080e7          	jalr	216(ra) # 80001090 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fc0:	00002097          	auipc	ra,0x2
    80000fc4:	ae2080e7          	jalr	-1310(ra) # 80002aa2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fc8:	00005097          	auipc	ra,0x5
    80000fcc:	218080e7          	jalr	536(ra) # 800061e0 <plicinithart>
  }

  scheduler();        
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	176080e7          	jalr	374(ra) # 80002146 <scheduler>
    consoleinit();
    80000fd8:	fffff097          	auipc	ra,0xfffff
    80000fdc:	478080e7          	jalr	1144(ra) # 80000450 <consoleinit>
    printfinit();
    80000fe0:	fffff097          	auipc	ra,0xfffff
    80000fe4:	788080e7          	jalr	1928(ra) # 80000768 <printfinit>
    printf("\n");
    80000fe8:	00007517          	auipc	a0,0x7
    80000fec:	0f050513          	addi	a0,a0,240 # 800080d8 <digits+0x98>
    80000ff0:	fffff097          	auipc	ra,0xfffff
    80000ff4:	598080e7          	jalr	1432(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0b850513          	addi	a0,a0,184 # 800080b0 <digits+0x70>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	588080e7          	jalr	1416(ra) # 80000588 <printf>
    printf("\n");
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	0d050513          	addi	a0,a0,208 # 800080d8 <digits+0x98>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	578080e7          	jalr	1400(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001018:	00000097          	auipc	ra,0x0
    8000101c:	b40080e7          	jalr	-1216(ra) # 80000b58 <kinit>
    kvminit();       // create kernel page table
    80001020:	00000097          	auipc	ra,0x0
    80001024:	326080e7          	jalr	806(ra) # 80001346 <kvminit>
    kvminithart();   // turn on paging
    80001028:	00000097          	auipc	ra,0x0
    8000102c:	068080e7          	jalr	104(ra) # 80001090 <kvminithart>
    procinit();      // process table
    80001030:	00001097          	auipc	ra,0x1
    80001034:	b2c080e7          	jalr	-1236(ra) # 80001b5c <procinit>
    trapinit();      // trap vectors
    80001038:	00002097          	auipc	ra,0x2
    8000103c:	a42080e7          	jalr	-1470(ra) # 80002a7a <trapinit>
    trapinithart();  // install kernel trap vector
    80001040:	00002097          	auipc	ra,0x2
    80001044:	a62080e7          	jalr	-1438(ra) # 80002aa2 <trapinithart>
    plicinit();      // set up interrupt controller
    80001048:	00005097          	auipc	ra,0x5
    8000104c:	182080e7          	jalr	386(ra) # 800061ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001050:	00005097          	auipc	ra,0x5
    80001054:	190080e7          	jalr	400(ra) # 800061e0 <plicinithart>
    binit();         // buffer cache
    80001058:	00002097          	auipc	ra,0x2
    8000105c:	332080e7          	jalr	818(ra) # 8000338a <binit>
    iinit();         // inode table
    80001060:	00003097          	auipc	ra,0x3
    80001064:	9d6080e7          	jalr	-1578(ra) # 80003a36 <iinit>
    fileinit();      // file table
    80001068:	00004097          	auipc	ra,0x4
    8000106c:	974080e7          	jalr	-1676(ra) # 800049dc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001070:	00005097          	auipc	ra,0x5
    80001074:	278080e7          	jalr	632(ra) # 800062e8 <virtio_disk_init>
    userinit();      // first user process
    80001078:	00001097          	auipc	ra,0x1
    8000107c:	eb0080e7          	jalr	-336(ra) # 80001f28 <userinit>
    __sync_synchronize();
    80001080:	0ff0000f          	fence
    started = 1;
    80001084:	4785                	li	a5,1
    80001086:	00008717          	auipc	a4,0x8
    8000108a:	84f72123          	sw	a5,-1982(a4) # 800088c8 <started>
    8000108e:	b789                	j	80000fd0 <main+0x56>

0000000080001090 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80001090:	1141                	addi	sp,sp,-16
    80001092:	e422                	sd	s0,8(sp)
    80001094:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001096:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000109a:	00008797          	auipc	a5,0x8
    8000109e:	83e7b783          	ld	a5,-1986(a5) # 800088d8 <kernel_pagetable>
    800010a2:	83b1                	srli	a5,a5,0xc
    800010a4:	577d                	li	a4,-1
    800010a6:	177e                	slli	a4,a4,0x3f
    800010a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010aa:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010ae:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010b2:	6422                	ld	s0,8(sp)
    800010b4:	0141                	addi	sp,sp,16
    800010b6:	8082                	ret

00000000800010b8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010b8:	7139                	addi	sp,sp,-64
    800010ba:	fc06                	sd	ra,56(sp)
    800010bc:	f822                	sd	s0,48(sp)
    800010be:	f426                	sd	s1,40(sp)
    800010c0:	f04a                	sd	s2,32(sp)
    800010c2:	ec4e                	sd	s3,24(sp)
    800010c4:	e852                	sd	s4,16(sp)
    800010c6:	e456                	sd	s5,8(sp)
    800010c8:	e05a                	sd	s6,0(sp)
    800010ca:	0080                	addi	s0,sp,64
    800010cc:	84aa                	mv	s1,a0
    800010ce:	89ae                	mv	s3,a1
    800010d0:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    800010d2:	57fd                	li	a5,-1
    800010d4:	83e9                	srli	a5,a5,0x1a
    800010d6:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    800010d8:	4b31                	li	s6,12
  if (va >= MAXVA)
    800010da:	04b7f263          	bgeu	a5,a1,8000111e <walk+0x66>
    panic("walk");
    800010de:	00007517          	auipc	a0,0x7
    800010e2:	00250513          	addi	a0,a0,2 # 800080e0 <digits+0xa0>
    800010e6:	fffff097          	auipc	ra,0xfffff
    800010ea:	458080e7          	jalr	1112(ra) # 8000053e <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    800010ee:	060a8663          	beqz	s5,8000115a <walk+0xa2>
    800010f2:	00000097          	auipc	ra,0x0
    800010f6:	aba080e7          	jalr	-1350(ra) # 80000bac <kalloc>
    800010fa:	84aa                	mv	s1,a0
    800010fc:	c529                	beqz	a0,80001146 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010fe:	6605                	lui	a2,0x1
    80001100:	4581                	li	a1,0
    80001102:	00000097          	auipc	ra,0x0
    80001106:	cd2080e7          	jalr	-814(ra) # 80000dd4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000110a:	00c4d793          	srli	a5,s1,0xc
    8000110e:	07aa                	slli	a5,a5,0xa
    80001110:	0017e793          	ori	a5,a5,1
    80001114:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    80001118:	3a5d                	addiw	s4,s4,-9
    8000111a:	036a0063          	beq	s4,s6,8000113a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000111e:	0149d933          	srl	s2,s3,s4
    80001122:	1ff97913          	andi	s2,s2,511
    80001126:	090e                	slli	s2,s2,0x3
    80001128:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    8000112a:	00093483          	ld	s1,0(s2)
    8000112e:	0014f793          	andi	a5,s1,1
    80001132:	dfd5                	beqz	a5,800010ee <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001134:	80a9                	srli	s1,s1,0xa
    80001136:	04b2                	slli	s1,s1,0xc
    80001138:	b7c5                	j	80001118 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000113a:	00c9d513          	srli	a0,s3,0xc
    8000113e:	1ff57513          	andi	a0,a0,511
    80001142:	050e                	slli	a0,a0,0x3
    80001144:	9526                	add	a0,a0,s1
}
    80001146:	70e2                	ld	ra,56(sp)
    80001148:	7442                	ld	s0,48(sp)
    8000114a:	74a2                	ld	s1,40(sp)
    8000114c:	7902                	ld	s2,32(sp)
    8000114e:	69e2                	ld	s3,24(sp)
    80001150:	6a42                	ld	s4,16(sp)
    80001152:	6aa2                	ld	s5,8(sp)
    80001154:	6b02                	ld	s6,0(sp)
    80001156:	6121                	addi	sp,sp,64
    80001158:	8082                	ret
        return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7ed                	j	80001146 <walk+0x8e>

000000008000115e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    8000115e:	57fd                	li	a5,-1
    80001160:	83e9                	srli	a5,a5,0x1a
    80001162:	00b7f463          	bgeu	a5,a1,8000116a <walkaddr+0xc>
    return 0;
    80001166:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001168:	8082                	ret
{
    8000116a:	1141                	addi	sp,sp,-16
    8000116c:	e406                	sd	ra,8(sp)
    8000116e:	e022                	sd	s0,0(sp)
    80001170:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001172:	4601                	li	a2,0
    80001174:	00000097          	auipc	ra,0x0
    80001178:	f44080e7          	jalr	-188(ra) # 800010b8 <walk>
  if (pte == 0)
    8000117c:	c105                	beqz	a0,8000119c <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    8000117e:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    80001180:	0117f693          	andi	a3,a5,17
    80001184:	4745                	li	a4,17
    return 0;
    80001186:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001188:	00e68663          	beq	a3,a4,80001194 <walkaddr+0x36>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret
  pa = PTE2PA(*pte);
    80001194:	00a7d513          	srli	a0,a5,0xa
    80001198:	0532                	slli	a0,a0,0xc
  return pa;
    8000119a:	bfcd                	j	8000118c <walkaddr+0x2e>
    return 0;
    8000119c:	4501                	li	a0,0
    8000119e:	b7fd                	j	8000118c <walkaddr+0x2e>

00000000800011a0 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011a0:	715d                	addi	sp,sp,-80
    800011a2:	e486                	sd	ra,72(sp)
    800011a4:	e0a2                	sd	s0,64(sp)
    800011a6:	fc26                	sd	s1,56(sp)
    800011a8:	f84a                	sd	s2,48(sp)
    800011aa:	f44e                	sd	s3,40(sp)
    800011ac:	f052                	sd	s4,32(sp)
    800011ae:	ec56                	sd	s5,24(sp)
    800011b0:	e85a                	sd	s6,16(sp)
    800011b2:	e45e                	sd	s7,8(sp)
    800011b4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    800011b6:	c639                	beqz	a2,80001204 <mappages+0x64>
    800011b8:	8aaa                	mv	s5,a0
    800011ba:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    800011bc:	77fd                	lui	a5,0xfffff
    800011be:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011c2:	15fd                	addi	a1,a1,-1
    800011c4:	00c589b3          	add	s3,a1,a2
    800011c8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011cc:	8952                	mv	s2,s4
    800011ce:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    800011d2:	6b85                	lui	s7,0x1
    800011d4:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    800011d8:	4605                	li	a2,1
    800011da:	85ca                	mv	a1,s2
    800011dc:	8556                	mv	a0,s5
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	eda080e7          	jalr	-294(ra) # 800010b8 <walk>
    800011e6:	cd1d                	beqz	a0,80001224 <mappages+0x84>
    if (*pte & PTE_V)
    800011e8:	611c                	ld	a5,0(a0)
    800011ea:	8b85                	andi	a5,a5,1
    800011ec:	e785                	bnez	a5,80001214 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ee:	80b1                	srli	s1,s1,0xc
    800011f0:	04aa                	slli	s1,s1,0xa
    800011f2:	0164e4b3          	or	s1,s1,s6
    800011f6:	0014e493          	ori	s1,s1,1
    800011fa:	e104                	sd	s1,0(a0)
    if (a == last)
    800011fc:	05390063          	beq	s2,s3,8000123c <mappages+0x9c>
    a += PGSIZE;
    80001200:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001202:	bfc9                	j	800011d4 <mappages+0x34>
    panic("mappages: size");
    80001204:	00007517          	auipc	a0,0x7
    80001208:	ee450513          	addi	a0,a0,-284 # 800080e8 <digits+0xa8>
    8000120c:	fffff097          	auipc	ra,0xfffff
    80001210:	332080e7          	jalr	818(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001214:	00007517          	auipc	a0,0x7
    80001218:	ee450513          	addi	a0,a0,-284 # 800080f8 <digits+0xb8>
    8000121c:	fffff097          	auipc	ra,0xfffff
    80001220:	322080e7          	jalr	802(ra) # 8000053e <panic>
      return -1;
    80001224:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001226:	60a6                	ld	ra,72(sp)
    80001228:	6406                	ld	s0,64(sp)
    8000122a:	74e2                	ld	s1,56(sp)
    8000122c:	7942                	ld	s2,48(sp)
    8000122e:	79a2                	ld	s3,40(sp)
    80001230:	7a02                	ld	s4,32(sp)
    80001232:	6ae2                	ld	s5,24(sp)
    80001234:	6b42                	ld	s6,16(sp)
    80001236:	6ba2                	ld	s7,8(sp)
    80001238:	6161                	addi	sp,sp,80
    8000123a:	8082                	ret
  return 0;
    8000123c:	4501                	li	a0,0
    8000123e:	b7e5                	j	80001226 <mappages+0x86>

0000000080001240 <kvmmap>:
{
    80001240:	1141                	addi	sp,sp,-16
    80001242:	e406                	sd	ra,8(sp)
    80001244:	e022                	sd	s0,0(sp)
    80001246:	0800                	addi	s0,sp,16
    80001248:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000124a:	86b2                	mv	a3,a2
    8000124c:	863e                	mv	a2,a5
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	f52080e7          	jalr	-174(ra) # 800011a0 <mappages>
    80001256:	e509                	bnez	a0,80001260 <kvmmap+0x20>
}
    80001258:	60a2                	ld	ra,8(sp)
    8000125a:	6402                	ld	s0,0(sp)
    8000125c:	0141                	addi	sp,sp,16
    8000125e:	8082                	ret
    panic("kvmmap");
    80001260:	00007517          	auipc	a0,0x7
    80001264:	ea850513          	addi	a0,a0,-344 # 80008108 <digits+0xc8>
    80001268:	fffff097          	auipc	ra,0xfffff
    8000126c:	2d6080e7          	jalr	726(ra) # 8000053e <panic>

0000000080001270 <kvmmake>:
{
    80001270:	1101                	addi	sp,sp,-32
    80001272:	ec06                	sd	ra,24(sp)
    80001274:	e822                	sd	s0,16(sp)
    80001276:	e426                	sd	s1,8(sp)
    80001278:	e04a                	sd	s2,0(sp)
    8000127a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	930080e7          	jalr	-1744(ra) # 80000bac <kalloc>
    80001284:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001286:	6605                	lui	a2,0x1
    80001288:	4581                	li	a1,0
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	b4a080e7          	jalr	-1206(ra) # 80000dd4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001292:	4719                	li	a4,6
    80001294:	6685                	lui	a3,0x1
    80001296:	10000637          	lui	a2,0x10000
    8000129a:	100005b7          	lui	a1,0x10000
    8000129e:	8526                	mv	a0,s1
    800012a0:	00000097          	auipc	ra,0x0
    800012a4:	fa0080e7          	jalr	-96(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012a8:	4719                	li	a4,6
    800012aa:	6685                	lui	a3,0x1
    800012ac:	10001637          	lui	a2,0x10001
    800012b0:	100015b7          	lui	a1,0x10001
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f8a080e7          	jalr	-118(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012be:	4719                	li	a4,6
    800012c0:	004006b7          	lui	a3,0x400
    800012c4:	0c000637          	lui	a2,0xc000
    800012c8:	0c0005b7          	lui	a1,0xc000
    800012cc:	8526                	mv	a0,s1
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	f72080e7          	jalr	-142(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800012d6:	00007917          	auipc	s2,0x7
    800012da:	d2a90913          	addi	s2,s2,-726 # 80008000 <etext>
    800012de:	4729                	li	a4,10
    800012e0:	80007697          	auipc	a3,0x80007
    800012e4:	d2068693          	addi	a3,a3,-736 # 8000 <_entry-0x7fff8000>
    800012e8:	4605                	li	a2,1
    800012ea:	067e                	slli	a2,a2,0x1f
    800012ec:	85b2                	mv	a1,a2
    800012ee:	8526                	mv	a0,s1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	f50080e7          	jalr	-176(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800012f8:	4719                	li	a4,6
    800012fa:	46c5                	li	a3,17
    800012fc:	06ee                	slli	a3,a3,0x1b
    800012fe:	412686b3          	sub	a3,a3,s2
    80001302:	864a                	mv	a2,s2
    80001304:	85ca                	mv	a1,s2
    80001306:	8526                	mv	a0,s1
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	f38080e7          	jalr	-200(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001310:	4729                	li	a4,10
    80001312:	6685                	lui	a3,0x1
    80001314:	00006617          	auipc	a2,0x6
    80001318:	cec60613          	addi	a2,a2,-788 # 80007000 <_trampoline>
    8000131c:	040005b7          	lui	a1,0x4000
    80001320:	15fd                	addi	a1,a1,-1
    80001322:	05b2                	slli	a1,a1,0xc
    80001324:	8526                	mv	a0,s1
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	f1a080e7          	jalr	-230(ra) # 80001240 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000132e:	8526                	mv	a0,s1
    80001330:	00000097          	auipc	ra,0x0
    80001334:	796080e7          	jalr	1942(ra) # 80001ac6 <proc_mapstacks>
}
    80001338:	8526                	mv	a0,s1
    8000133a:	60e2                	ld	ra,24(sp)
    8000133c:	6442                	ld	s0,16(sp)
    8000133e:	64a2                	ld	s1,8(sp)
    80001340:	6902                	ld	s2,0(sp)
    80001342:	6105                	addi	sp,sp,32
    80001344:	8082                	ret

0000000080001346 <kvminit>:
{
    80001346:	1141                	addi	sp,sp,-16
    80001348:	e406                	sd	ra,8(sp)
    8000134a:	e022                	sd	s0,0(sp)
    8000134c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	f22080e7          	jalr	-222(ra) # 80001270 <kvmmake>
    80001356:	00007797          	auipc	a5,0x7
    8000135a:	58a7b123          	sd	a0,1410(a5) # 800088d8 <kernel_pagetable>
}
    8000135e:	60a2                	ld	ra,8(sp)
    80001360:	6402                	ld	s0,0(sp)
    80001362:	0141                	addi	sp,sp,16
    80001364:	8082                	ret

0000000080001366 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001366:	715d                	addi	sp,sp,-80
    80001368:	e486                	sd	ra,72(sp)
    8000136a:	e0a2                	sd	s0,64(sp)
    8000136c:	fc26                	sd	s1,56(sp)
    8000136e:	f84a                	sd	s2,48(sp)
    80001370:	f44e                	sd	s3,40(sp)
    80001372:	f052                	sd	s4,32(sp)
    80001374:	ec56                	sd	s5,24(sp)
    80001376:	e85a                	sd	s6,16(sp)
    80001378:	e45e                	sd	s7,8(sp)
    8000137a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    8000137c:	03459793          	slli	a5,a1,0x34
    80001380:	e795                	bnez	a5,800013ac <uvmunmap+0x46>
    80001382:	8a2a                	mv	s4,a0
    80001384:	892e                	mv	s2,a1
    80001386:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001388:	0632                	slli	a2,a2,0xc
    8000138a:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    8000138e:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001390:	6b05                	lui	s6,0x1
    80001392:	0735e263          	bltu	a1,s3,800013f6 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    80001396:	60a6                	ld	ra,72(sp)
    80001398:	6406                	ld	s0,64(sp)
    8000139a:	74e2                	ld	s1,56(sp)
    8000139c:	7942                	ld	s2,48(sp)
    8000139e:	79a2                	ld	s3,40(sp)
    800013a0:	7a02                	ld	s4,32(sp)
    800013a2:	6ae2                	ld	s5,24(sp)
    800013a4:	6b42                	ld	s6,16(sp)
    800013a6:	6ba2                	ld	s7,8(sp)
    800013a8:	6161                	addi	sp,sp,80
    800013aa:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ac:	00007517          	auipc	a0,0x7
    800013b0:	d6450513          	addi	a0,a0,-668 # 80008110 <digits+0xd0>
    800013b4:	fffff097          	auipc	ra,0xfffff
    800013b8:	18a080e7          	jalr	394(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013bc:	00007517          	auipc	a0,0x7
    800013c0:	d6c50513          	addi	a0,a0,-660 # 80008128 <digits+0xe8>
    800013c4:	fffff097          	auipc	ra,0xfffff
    800013c8:	17a080e7          	jalr	378(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013cc:	00007517          	auipc	a0,0x7
    800013d0:	d6c50513          	addi	a0,a0,-660 # 80008138 <digits+0xf8>
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	16a080e7          	jalr	362(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800013dc:	00007517          	auipc	a0,0x7
    800013e0:	d7450513          	addi	a0,a0,-652 # 80008150 <digits+0x110>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>
    *pte = 0;
    800013ec:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013f0:	995a                	add	s2,s2,s6
    800013f2:	fb3972e3          	bgeu	s2,s3,80001396 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    800013f6:	4601                	li	a2,0
    800013f8:	85ca                	mv	a1,s2
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	cbc080e7          	jalr	-836(ra) # 800010b8 <walk>
    80001404:	84aa                	mv	s1,a0
    80001406:	d95d                	beqz	a0,800013bc <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    80001408:	6108                	ld	a0,0(a0)
    8000140a:	00157793          	andi	a5,a0,1
    8000140e:	dfdd                	beqz	a5,800013cc <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001410:	3ff57793          	andi	a5,a0,1023
    80001414:	fd7784e3          	beq	a5,s7,800013dc <uvmunmap+0x76>
    if (do_free)
    80001418:	fc0a8ae3          	beqz	s5,800013ec <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000141c:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    8000141e:	0532                	slli	a0,a0,0xc
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	5ca080e7          	jalr	1482(ra) # 800009ea <kfree>
    80001428:	b7d1                	j	800013ec <uvmunmap+0x86>

000000008000142a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000142a:	1101                	addi	sp,sp,-32
    8000142c:	ec06                	sd	ra,24(sp)
    8000142e:	e822                	sd	s0,16(sp)
    80001430:	e426                	sd	s1,8(sp)
    80001432:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	778080e7          	jalr	1912(ra) # 80000bac <kalloc>
    8000143c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    8000143e:	c519                	beqz	a0,8000144c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001440:	6605                	lui	a2,0x1
    80001442:	4581                	li	a1,0
    80001444:	00000097          	auipc	ra,0x0
    80001448:	990080e7          	jalr	-1648(ra) # 80000dd4 <memset>
  return pagetable;
}
    8000144c:	8526                	mv	a0,s1
    8000144e:	60e2                	ld	ra,24(sp)
    80001450:	6442                	ld	s0,16(sp)
    80001452:	64a2                	ld	s1,8(sp)
    80001454:	6105                	addi	sp,sp,32
    80001456:	8082                	ret

0000000080001458 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001458:	7179                	addi	sp,sp,-48
    8000145a:	f406                	sd	ra,40(sp)
    8000145c:	f022                	sd	s0,32(sp)
    8000145e:	ec26                	sd	s1,24(sp)
    80001460:	e84a                	sd	s2,16(sp)
    80001462:	e44e                	sd	s3,8(sp)
    80001464:	e052                	sd	s4,0(sp)
    80001466:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001468:	6785                	lui	a5,0x1
    8000146a:	04f67863          	bgeu	a2,a5,800014ba <uvmfirst+0x62>
    8000146e:	8a2a                	mv	s4,a0
    80001470:	89ae                	mv	s3,a1
    80001472:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001474:	fffff097          	auipc	ra,0xfffff
    80001478:	738080e7          	jalr	1848(ra) # 80000bac <kalloc>
    8000147c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000147e:	6605                	lui	a2,0x1
    80001480:	4581                	li	a1,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	952080e7          	jalr	-1710(ra) # 80000dd4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    8000148a:	4779                	li	a4,30
    8000148c:	86ca                	mv	a3,s2
    8000148e:	6605                	lui	a2,0x1
    80001490:	4581                	li	a1,0
    80001492:	8552                	mv	a0,s4
    80001494:	00000097          	auipc	ra,0x0
    80001498:	d0c080e7          	jalr	-756(ra) # 800011a0 <mappages>
  memmove(mem, src, sz);
    8000149c:	8626                	mv	a2,s1
    8000149e:	85ce                	mv	a1,s3
    800014a0:	854a                	mv	a0,s2
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	98e080e7          	jalr	-1650(ra) # 80000e30 <memmove>
}
    800014aa:	70a2                	ld	ra,40(sp)
    800014ac:	7402                	ld	s0,32(sp)
    800014ae:	64e2                	ld	s1,24(sp)
    800014b0:	6942                	ld	s2,16(sp)
    800014b2:	69a2                	ld	s3,8(sp)
    800014b4:	6a02                	ld	s4,0(sp)
    800014b6:	6145                	addi	sp,sp,48
    800014b8:	8082                	ret
    panic("uvmfirst: more than a page");
    800014ba:	00007517          	auipc	a0,0x7
    800014be:	cae50513          	addi	a0,a0,-850 # 80008168 <digits+0x128>
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	07c080e7          	jalr	124(ra) # 8000053e <panic>

00000000800014ca <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014ca:	1101                	addi	sp,sp,-32
    800014cc:	ec06                	sd	ra,24(sp)
    800014ce:	e822                	sd	s0,16(sp)
    800014d0:	e426                	sd	s1,8(sp)
    800014d2:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    800014d4:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    800014d6:	00b67d63          	bgeu	a2,a1,800014f0 <uvmdealloc+0x26>
    800014da:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    800014dc:	6785                	lui	a5,0x1
    800014de:	17fd                	addi	a5,a5,-1
    800014e0:	00f60733          	add	a4,a2,a5
    800014e4:	767d                	lui	a2,0xfffff
    800014e6:	8f71                	and	a4,a4,a2
    800014e8:	97ae                	add	a5,a5,a1
    800014ea:	8ff1                	and	a5,a5,a2
    800014ec:	00f76863          	bltu	a4,a5,800014fc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014f0:	8526                	mv	a0,s1
    800014f2:	60e2                	ld	ra,24(sp)
    800014f4:	6442                	ld	s0,16(sp)
    800014f6:	64a2                	ld	s1,8(sp)
    800014f8:	6105                	addi	sp,sp,32
    800014fa:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014fc:	8f99                	sub	a5,a5,a4
    800014fe:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001500:	4685                	li	a3,1
    80001502:	0007861b          	sext.w	a2,a5
    80001506:	85ba                	mv	a1,a4
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	e5e080e7          	jalr	-418(ra) # 80001366 <uvmunmap>
    80001510:	b7c5                	j	800014f0 <uvmdealloc+0x26>

0000000080001512 <uvmalloc>:
  if (newsz < oldsz)
    80001512:	0ab66563          	bltu	a2,a1,800015bc <uvmalloc+0xaa>
{
    80001516:	7139                	addi	sp,sp,-64
    80001518:	fc06                	sd	ra,56(sp)
    8000151a:	f822                	sd	s0,48(sp)
    8000151c:	f426                	sd	s1,40(sp)
    8000151e:	f04a                	sd	s2,32(sp)
    80001520:	ec4e                	sd	s3,24(sp)
    80001522:	e852                	sd	s4,16(sp)
    80001524:	e456                	sd	s5,8(sp)
    80001526:	e05a                	sd	s6,0(sp)
    80001528:	0080                	addi	s0,sp,64
    8000152a:	8aaa                	mv	s5,a0
    8000152c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000152e:	6985                	lui	s3,0x1
    80001530:	19fd                	addi	s3,s3,-1
    80001532:	95ce                	add	a1,a1,s3
    80001534:	79fd                	lui	s3,0xfffff
    80001536:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000153a:	08c9f363          	bgeu	s3,a2,800015c0 <uvmalloc+0xae>
    8000153e:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001540:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	668080e7          	jalr	1640(ra) # 80000bac <kalloc>
    8000154c:	84aa                	mv	s1,a0
    if (mem == 0)
    8000154e:	c51d                	beqz	a0,8000157c <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001550:	6605                	lui	a2,0x1
    80001552:	4581                	li	a1,0
    80001554:	00000097          	auipc	ra,0x0
    80001558:	880080e7          	jalr	-1920(ra) # 80000dd4 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000155c:	875a                	mv	a4,s6
    8000155e:	86a6                	mv	a3,s1
    80001560:	6605                	lui	a2,0x1
    80001562:	85ca                	mv	a1,s2
    80001564:	8556                	mv	a0,s5
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	c3a080e7          	jalr	-966(ra) # 800011a0 <mappages>
    8000156e:	e90d                	bnez	a0,800015a0 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001570:	6785                	lui	a5,0x1
    80001572:	993e                	add	s2,s2,a5
    80001574:	fd4968e3          	bltu	s2,s4,80001544 <uvmalloc+0x32>
  return newsz;
    80001578:	8552                	mv	a0,s4
    8000157a:	a809                	j	8000158c <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000157c:	864e                	mv	a2,s3
    8000157e:	85ca                	mv	a1,s2
    80001580:	8556                	mv	a0,s5
    80001582:	00000097          	auipc	ra,0x0
    80001586:	f48080e7          	jalr	-184(ra) # 800014ca <uvmdealloc>
      return 0;
    8000158a:	4501                	li	a0,0
}
    8000158c:	70e2                	ld	ra,56(sp)
    8000158e:	7442                	ld	s0,48(sp)
    80001590:	74a2                	ld	s1,40(sp)
    80001592:	7902                	ld	s2,32(sp)
    80001594:	69e2                	ld	s3,24(sp)
    80001596:	6a42                	ld	s4,16(sp)
    80001598:	6aa2                	ld	s5,8(sp)
    8000159a:	6b02                	ld	s6,0(sp)
    8000159c:	6121                	addi	sp,sp,64
    8000159e:	8082                	ret
      kfree(mem);
    800015a0:	8526                	mv	a0,s1
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	448080e7          	jalr	1096(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015aa:	864e                	mv	a2,s3
    800015ac:	85ca                	mv	a1,s2
    800015ae:	8556                	mv	a0,s5
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f1a080e7          	jalr	-230(ra) # 800014ca <uvmdealloc>
      return 0;
    800015b8:	4501                	li	a0,0
    800015ba:	bfc9                	j	8000158c <uvmalloc+0x7a>
    return oldsz;
    800015bc:	852e                	mv	a0,a1
}
    800015be:	8082                	ret
  return newsz;
    800015c0:	8532                	mv	a0,a2
    800015c2:	b7e9                	j	8000158c <uvmalloc+0x7a>

00000000800015c4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800015c4:	7179                	addi	sp,sp,-48
    800015c6:	f406                	sd	ra,40(sp)
    800015c8:	f022                	sd	s0,32(sp)
    800015ca:	ec26                	sd	s1,24(sp)
    800015cc:	e84a                	sd	s2,16(sp)
    800015ce:	e44e                	sd	s3,8(sp)
    800015d0:	e052                	sd	s4,0(sp)
    800015d2:	1800                	addi	s0,sp,48
    800015d4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    800015d6:	84aa                	mv	s1,a0
    800015d8:	6905                	lui	s2,0x1
    800015da:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800015dc:	4985                	li	s3,1
    800015de:	a821                	j	800015f6 <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e2:	0532                	slli	a0,a0,0xc
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	fe0080e7          	jalr	-32(ra) # 800015c4 <freewalk>
      pagetable[i] = 0;
    800015ec:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    800015f0:	04a1                	addi	s1,s1,8
    800015f2:	03248163          	beq	s1,s2,80001614 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015f6:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800015f8:	00f57793          	andi	a5,a0,15
    800015fc:	ff3782e3          	beq	a5,s3,800015e0 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001600:	8905                	andi	a0,a0,1
    80001602:	d57d                	beqz	a0,800015f0 <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    80001604:	00007517          	auipc	a0,0x7
    80001608:	b8450513          	addi	a0,a0,-1148 # 80008188 <digits+0x148>
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>
    }
  }
  kfree((void *)pagetable);
    80001614:	8552                	mv	a0,s4
    80001616:	fffff097          	auipc	ra,0xfffff
    8000161a:	3d4080e7          	jalr	980(ra) # 800009ea <kfree>
}
    8000161e:	70a2                	ld	ra,40(sp)
    80001620:	7402                	ld	s0,32(sp)
    80001622:	64e2                	ld	s1,24(sp)
    80001624:	6942                	ld	s2,16(sp)
    80001626:	69a2                	ld	s3,8(sp)
    80001628:	6a02                	ld	s4,0(sp)
    8000162a:	6145                	addi	sp,sp,48
    8000162c:	8082                	ret

000000008000162e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000162e:	1101                	addi	sp,sp,-32
    80001630:	ec06                	sd	ra,24(sp)
    80001632:	e822                	sd	s0,16(sp)
    80001634:	e426                	sd	s1,8(sp)
    80001636:	1000                	addi	s0,sp,32
    80001638:	84aa                	mv	s1,a0
  if (sz > 0)
    8000163a:	e999                	bnez	a1,80001650 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    8000163c:	8526                	mv	a0,s1
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	f86080e7          	jalr	-122(ra) # 800015c4 <freewalk>
}
    80001646:	60e2                	ld	ra,24(sp)
    80001648:	6442                	ld	s0,16(sp)
    8000164a:	64a2                	ld	s1,8(sp)
    8000164c:	6105                	addi	sp,sp,32
    8000164e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80001650:	6605                	lui	a2,0x1
    80001652:	167d                	addi	a2,a2,-1
    80001654:	962e                	add	a2,a2,a1
    80001656:	4685                	li	a3,1
    80001658:	8231                	srli	a2,a2,0xc
    8000165a:	4581                	li	a1,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	d0a080e7          	jalr	-758(ra) # 80001366 <uvmunmap>
    80001664:	bfe1                	j	8000163c <uvmfree+0xe>

0000000080001666 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    80001666:	c679                	beqz	a2,80001734 <uvmcopy+0xce>
{
    80001668:	715d                	addi	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	0880                	addi	s0,sp,80
    8000167e:	8b2a                	mv	s6,a0
    80001680:	8aae                	mv	s5,a1
    80001682:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    80001684:	4981                	li	s3,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    80001686:	4601                	li	a2,0
    80001688:	85ce                	mv	a1,s3
    8000168a:	855a                	mv	a0,s6
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	a2c080e7          	jalr	-1492(ra) # 800010b8 <walk>
    80001694:	c531                	beqz	a0,800016e0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    80001696:	6118                	ld	a4,0(a0)
    80001698:	00177793          	andi	a5,a4,1
    8000169c:	cbb1                	beqz	a5,800016f0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);
    8000169e:	00a75593          	srli	a1,a4,0xa
    800016a2:	00c59b93          	slli	s7,a1,0xc


    flags = PTE_FLAGS(*pte);
    800016a6:	3ff77493          	andi	s1,a4,1023
    if ((mem = kalloc()) == 0)
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	502080e7          	jalr	1282(ra) # 80000bac <kalloc>
    800016b2:	892a                	mv	s2,a0
    800016b4:	c939                	beqz	a0,8000170a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char *)pa, PGSIZE);
    800016b6:	6605                	lui	a2,0x1
    800016b8:	85de                	mv	a1,s7
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	776080e7          	jalr	1910(ra) # 80000e30 <memmove>
    if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
    800016c2:	8726                	mv	a4,s1
    800016c4:	86ca                	mv	a3,s2
    800016c6:	6605                	lui	a2,0x1
    800016c8:	85ce                	mv	a1,s3
    800016ca:	8556                	mv	a0,s5
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	ad4080e7          	jalr	-1324(ra) # 800011a0 <mappages>
    800016d4:	e515                	bnez	a0,80001700 <uvmcopy+0x9a>
  for (i = 0; i < sz; i += PGSIZE)
    800016d6:	6785                	lui	a5,0x1
    800016d8:	99be                	add	s3,s3,a5
    800016da:	fb49e6e3          	bltu	s3,s4,80001686 <uvmcopy+0x20>
    800016de:	a081                	j	8000171e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016e0:	00007517          	auipc	a0,0x7
    800016e4:	ab850513          	addi	a0,a0,-1352 # 80008198 <digits+0x158>
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	e56080e7          	jalr	-426(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800016f0:	00007517          	auipc	a0,0x7
    800016f4:	ac850513          	addi	a0,a0,-1336 # 800081b8 <digits+0x178>
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	e46080e7          	jalr	-442(ra) # 8000053e <panic>
    {
      kfree(mem);
    80001700:	854a                	mv	a0,s2
    80001702:	fffff097          	auipc	ra,0xfffff
    80001706:	2e8080e7          	jalr	744(ra) # 800009ea <kfree>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000170a:	4685                	li	a3,1
    8000170c:	00c9d613          	srli	a2,s3,0xc
    80001710:	4581                	li	a1,0
    80001712:	8556                	mv	a0,s5
    80001714:	00000097          	auipc	ra,0x0
    80001718:	c52080e7          	jalr	-942(ra) # 80001366 <uvmunmap>
  return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6161                	addi	sp,sp,80
    80001732:	8082                	ret
  return 0;
    80001734:	4501                	li	a0,0
}
    80001736:	8082                	ret

0000000080001738 <uvmcopy2>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE)
    80001738:	c66d                	beqz	a2,80001822 <uvmcopy2+0xea>
{
    8000173a:	715d                	addi	sp,sp,-80
    8000173c:	e486                	sd	ra,72(sp)
    8000173e:	e0a2                	sd	s0,64(sp)
    80001740:	fc26                	sd	s1,56(sp)
    80001742:	f84a                	sd	s2,48(sp)
    80001744:	f44e                	sd	s3,40(sp)
    80001746:	f052                	sd	s4,32(sp)
    80001748:	ec56                	sd	s5,24(sp)
    8000174a:	e85a                	sd	s6,16(sp)
    8000174c:	e45e                	sd	s7,8(sp)
    8000174e:	e062                	sd	s8,0(sp)
    80001750:	0880                	addi	s0,sp,80
    80001752:	8baa                	mv	s7,a0
    80001754:	8b2e                	mv	s6,a1
    80001756:	8ab2                	mv	s5,a2
  for (i = 0; i < sz; i += PGSIZE)
    80001758:	4981                	li	s3,0
    *pte &= ~PTE_W;
    *pte |= PTE_COW;

    pa = PTE2PA(*pte);

    acquire(&ref_lock);
    8000175a:	0000fa17          	auipc	s4,0xf
    8000175e:	3d6a0a13          	addi	s4,s4,982 # 80010b30 <ref_lock>
    reference_counters[pa / PGSIZE] = reference_counters[pa / PGSIZE] + 1;
    80001762:	0000fc17          	auipc	s8,0xf
    80001766:	406c0c13          	addi	s8,s8,1030 # 80010b68 <reference_counters>
    if ((pte = walk(old, i, 0)) == 0)
    8000176a:	4601                	li	a2,0
    8000176c:	85ce                	mv	a1,s3
    8000176e:	855e                	mv	a0,s7
    80001770:	00000097          	auipc	ra,0x0
    80001774:	948080e7          	jalr	-1720(ra) # 800010b8 <walk>
    80001778:	892a                	mv	s2,a0
    8000177a:	cd31                	beqz	a0,800017d6 <uvmcopy2+0x9e>
    if ((*pte & PTE_V) == 0)
    8000177c:	611c                	ld	a5,0(a0)
    8000177e:	0017f713          	andi	a4,a5,1
    80001782:	c335                	beqz	a4,800017e6 <uvmcopy2+0xae>
    *pte &= ~PTE_W;
    80001784:	9bed                	andi	a5,a5,-5
    *pte |= PTE_COW;
    80001786:	1007e793          	ori	a5,a5,256
    8000178a:	e11c                	sd	a5,0(a0)
    pa = PTE2PA(*pte);
    8000178c:	83a9                	srli	a5,a5,0xa
    8000178e:	00c79493          	slli	s1,a5,0xc
    acquire(&ref_lock);
    80001792:	8552                	mv	a0,s4
    80001794:	fffff097          	auipc	ra,0xfffff
    80001798:	544080e7          	jalr	1348(ra) # 80000cd8 <acquire>
    reference_counters[pa / PGSIZE] = reference_counters[pa / PGSIZE] + 1;
    8000179c:	00a4d793          	srli	a5,s1,0xa
    800017a0:	97e2                	add	a5,a5,s8
    800017a2:	4398                	lw	a4,0(a5)
    800017a4:	2705                	addiw	a4,a4,1
    800017a6:	c398                	sw	a4,0(a5)
    release(&ref_lock);
    800017a8:	8552                	mv	a0,s4
    800017aa:	fffff097          	auipc	ra,0xfffff
    800017ae:	5e2080e7          	jalr	1506(ra) # 80000d8c <release>

    flags = PTE_FLAGS(*pte);
    800017b2:	00093703          	ld	a4,0(s2) # 1000 <_entry-0x7ffff000>

    if (mappages(new, i, PGSIZE, (uint64)pa, flags) != 0)
    800017b6:	3ff77713          	andi	a4,a4,1023
    800017ba:	86a6                	mv	a3,s1
    800017bc:	6605                	lui	a2,0x1
    800017be:	85ce                	mv	a1,s3
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	9de080e7          	jalr	-1570(ra) # 800011a0 <mappages>
    800017ca:	e515                	bnez	a0,800017f6 <uvmcopy2+0xbe>
  for (i = 0; i < sz; i += PGSIZE)
    800017cc:	6785                	lui	a5,0x1
    800017ce:	99be                	add	s3,s3,a5
    800017d0:	f959ede3          	bltu	s3,s5,8000176a <uvmcopy2+0x32>
    800017d4:	a81d                	j	8000180a <uvmcopy2+0xd2>
      panic("uvmcopy: pte should exist");
    800017d6:	00007517          	auipc	a0,0x7
    800017da:	9c250513          	addi	a0,a0,-1598 # 80008198 <digits+0x158>
    800017de:	fffff097          	auipc	ra,0xfffff
    800017e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800017e6:	00007517          	auipc	a0,0x7
    800017ea:	9d250513          	addi	a0,a0,-1582 # 800081b8 <digits+0x178>
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017f6:	4685                	li	a3,1
    800017f8:	00c9d613          	srli	a2,s3,0xc
    800017fc:	4581                	li	a1,0
    800017fe:	855a                	mv	a0,s6
    80001800:	00000097          	auipc	ra,0x0
    80001804:	b66080e7          	jalr	-1178(ra) # 80001366 <uvmunmap>
  return -1;
    80001808:	557d                	li	a0,-1
}
    8000180a:	60a6                	ld	ra,72(sp)
    8000180c:	6406                	ld	s0,64(sp)
    8000180e:	74e2                	ld	s1,56(sp)
    80001810:	7942                	ld	s2,48(sp)
    80001812:	79a2                	ld	s3,40(sp)
    80001814:	7a02                	ld	s4,32(sp)
    80001816:	6ae2                	ld	s5,24(sp)
    80001818:	6b42                	ld	s6,16(sp)
    8000181a:	6ba2                	ld	s7,8(sp)
    8000181c:	6c02                	ld	s8,0(sp)
    8000181e:	6161                	addi	sp,sp,80
    80001820:	8082                	ret
  return 0;
    80001822:	4501                	li	a0,0
}
    80001824:	8082                	ret

0000000080001826 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001826:	1141                	addi	sp,sp,-16
    80001828:	e406                	sd	ra,8(sp)
    8000182a:	e022                	sd	s0,0(sp)
    8000182c:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    8000182e:	4601                	li	a2,0
    80001830:	00000097          	auipc	ra,0x0
    80001834:	888080e7          	jalr	-1912(ra) # 800010b8 <walk>
  if (pte == 0)
    80001838:	c901                	beqz	a0,80001848 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000183a:	611c                	ld	a5,0(a0)
    8000183c:	9bbd                	andi	a5,a5,-17
    8000183e:	e11c                	sd	a5,0(a0)
}
    80001840:	60a2                	ld	ra,8(sp)
    80001842:	6402                	ld	s0,0(sp)
    80001844:	0141                	addi	sp,sp,16
    80001846:	8082                	ret
    panic("uvmclear");
    80001848:	00007517          	auipc	a0,0x7
    8000184c:	99050513          	addi	a0,a0,-1648 # 800081d8 <digits+0x198>
    80001850:	fffff097          	auipc	ra,0xfffff
    80001854:	cee080e7          	jalr	-786(ra) # 8000053e <panic>

0000000080001858 <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001858:	cee5                	beqz	a3,80001950 <copyout+0xf8>
{
    8000185a:	7159                	addi	sp,sp,-112
    8000185c:	f486                	sd	ra,104(sp)
    8000185e:	f0a2                	sd	s0,96(sp)
    80001860:	eca6                	sd	s1,88(sp)
    80001862:	e8ca                	sd	s2,80(sp)
    80001864:	e4ce                	sd	s3,72(sp)
    80001866:	e0d2                	sd	s4,64(sp)
    80001868:	fc56                	sd	s5,56(sp)
    8000186a:	f85a                	sd	s6,48(sp)
    8000186c:	f45e                	sd	s7,40(sp)
    8000186e:	f062                	sd	s8,32(sp)
    80001870:	ec66                	sd	s9,24(sp)
    80001872:	e86a                	sd	s10,16(sp)
    80001874:	e46e                	sd	s11,8(sp)
    80001876:	1880                	addi	s0,sp,112
    80001878:	8c2a                	mv	s8,a0
    8000187a:	8aae                	mv	s5,a1
    8000187c:	8bb2                	mv	s7,a2
    8000187e:	8a36                	mv	s4,a3
  {
    va0 = PGROUNDDOWN(dstva);
    80001880:	74fd                	lui	s1,0xfffff
    80001882:	8ced                	and	s1,s1,a1
    if (MAXVA <= va0)
    80001884:	57fd                	li	a5,-1
    80001886:	83e9                	srli	a5,a5,0x1a
    80001888:	0c97e663          	bltu	a5,s1,80001954 <copyout+0xfc>

    if (curr_pte == 0)
    {
      return -1;
    }
    if ((*curr_pte & PTE_V) == 0 || (*curr_pte & PTE_U) == 0)
    8000188c:	4d45                	li	s10,17
    if (MAXVA <= va0)
    8000188e:	57fd                	li	a5,-1
    80001890:	01a7dd93          	srli	s11,a5,0x1a
    80001894:	a89d                	j	8000190a <copyout+0xb2>
    if (*curr_pte & PTE_COW)
    {

      char *new_mem;
      uint flags;
      uint64 phy_addr = PTE2PA(*curr_pte);
    80001896:	00a95c93          	srli	s9,s2,0xa
    8000189a:	0cb2                	slli	s9,s9,0xc

      flags = PTE_FLAGS(*curr_pte);
      flags |= PTE_W; 
      flags &= ~PTE_COW;
    8000189c:	2ff97913          	andi	s2,s2,767
    800018a0:	00496913          	ori	s2,s2,4

      new_mem = kalloc();
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	308080e7          	jalr	776(ra) # 80000bac <kalloc>
    800018ac:	8b2a                	mv	s6,a0
      if (new_mem == 0)
    800018ae:	c50d                	beqz	a0,800018d8 <copyout+0x80>
      {
        exit(-1);
      }

      memmove(new_mem, (char *)phy_addr, PGSIZE);
    800018b0:	6605                	lui	a2,0x1
    800018b2:	85e6                	mv	a1,s9
    800018b4:	855a                	mv	a0,s6
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	57a080e7          	jalr	1402(ra) # 80000e30 <memmove>

      *curr_pte = PA2PTE(new_mem) | flags;
    800018be:	00cb5b13          	srli	s6,s6,0xc
    800018c2:	0b2a                	slli	s6,s6,0xa
    800018c4:	01696b33          	or	s6,s2,s6
    800018c8:	0169b023          	sd	s6,0(s3) # fffffffffffff000 <end+0xffffffff7fdbce88>

      kfree((char *)phy_addr); 
    800018cc:	8566                	mv	a0,s9
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	11c080e7          	jalr	284(ra) # 800009ea <kfree>
    800018d6:	a8a1                	j	8000192e <copyout+0xd6>
        exit(-1);
    800018d8:	557d                	li	a0,-1
    800018da:	00001097          	auipc	ra,0x1
    800018de:	b52080e7          	jalr	-1198(ra) # 8000242c <exit>
    800018e2:	b7f9                	j	800018b0 <copyout+0x58>
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018e4:	409a84b3          	sub	s1,s5,s1
    800018e8:	0009861b          	sext.w	a2,s3
    800018ec:	85de                	mv	a1,s7
    800018ee:	9526                	add	a0,a0,s1
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	540080e7          	jalr	1344(ra) # 80000e30 <memmove>

    len -= n;
    800018f8:	413a0a33          	sub	s4,s4,s3
    src += n;
    800018fc:	9bce                	add	s7,s7,s3
  while (len > 0)
    800018fe:	040a0763          	beqz	s4,8000194c <copyout+0xf4>
    if (MAXVA <= va0)
    80001902:	052deb63          	bltu	s11,s2,80001958 <copyout+0x100>
    va0 = PGROUNDDOWN(dstva);
    80001906:	84ca                	mv	s1,s2
    dstva = va0 + PGSIZE;
    80001908:	8aca                	mv	s5,s2
    pte_t *curr_pte = walk(pagetable, va0, 0);
    8000190a:	4601                	li	a2,0
    8000190c:	85a6                	mv	a1,s1
    8000190e:	8562                	mv	a0,s8
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	7a8080e7          	jalr	1960(ra) # 800010b8 <walk>
    80001918:	89aa                	mv	s3,a0
    if (curr_pte == 0)
    8000191a:	c129                	beqz	a0,8000195c <copyout+0x104>
    if ((*curr_pte & PTE_V) == 0 || (*curr_pte & PTE_U) == 0)
    8000191c:	00053903          	ld	s2,0(a0)
    80001920:	01197793          	andi	a5,s2,17
    80001924:	05a79c63          	bne	a5,s10,8000197c <copyout+0x124>
    if (*curr_pte & PTE_COW)
    80001928:	10097793          	andi	a5,s2,256
    8000192c:	f7ad                	bnez	a5,80001896 <copyout+0x3e>
    pa0 = walkaddr(pagetable, va0);
    8000192e:	85a6                	mv	a1,s1
    80001930:	8562                	mv	a0,s8
    80001932:	00000097          	auipc	ra,0x0
    80001936:	82c080e7          	jalr	-2004(ra) # 8000115e <walkaddr>
    if (pa0 == 0)
    8000193a:	c139                	beqz	a0,80001980 <copyout+0x128>
    n = PGSIZE - (dstva - va0);
    8000193c:	6905                	lui	s2,0x1
    8000193e:	9926                	add	s2,s2,s1
    80001940:	415909b3          	sub	s3,s2,s5
    if (n > len)
    80001944:	fb3a70e3          	bgeu	s4,s3,800018e4 <copyout+0x8c>
    80001948:	89d2                	mv	s3,s4
    8000194a:	bf69                	j	800018e4 <copyout+0x8c>
  }
  return 0;
    8000194c:	4501                	li	a0,0
    8000194e:	a801                	j	8000195e <copyout+0x106>
    80001950:	4501                	li	a0,0
}
    80001952:	8082                	ret
      return -1;
    80001954:	557d                	li	a0,-1
    80001956:	a021                	j	8000195e <copyout+0x106>
    80001958:	557d                	li	a0,-1
    8000195a:	a011                	j	8000195e <copyout+0x106>
      return -1;
    8000195c:	557d                	li	a0,-1
}
    8000195e:	70a6                	ld	ra,104(sp)
    80001960:	7406                	ld	s0,96(sp)
    80001962:	64e6                	ld	s1,88(sp)
    80001964:	6946                	ld	s2,80(sp)
    80001966:	69a6                	ld	s3,72(sp)
    80001968:	6a06                	ld	s4,64(sp)
    8000196a:	7ae2                	ld	s5,56(sp)
    8000196c:	7b42                	ld	s6,48(sp)
    8000196e:	7ba2                	ld	s7,40(sp)
    80001970:	7c02                	ld	s8,32(sp)
    80001972:	6ce2                	ld	s9,24(sp)
    80001974:	6d42                	ld	s10,16(sp)
    80001976:	6da2                	ld	s11,8(sp)
    80001978:	6165                	addi	sp,sp,112
    8000197a:	8082                	ret
      return -1;
    8000197c:	557d                	li	a0,-1
    8000197e:	b7c5                	j	8000195e <copyout+0x106>
      return -1;
    80001980:	557d                	li	a0,-1
    80001982:	bff1                	j	8000195e <copyout+0x106>

0000000080001984 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001984:	caa5                	beqz	a3,800019f4 <copyin+0x70>
{
    80001986:	715d                	addi	sp,sp,-80
    80001988:	e486                	sd	ra,72(sp)
    8000198a:	e0a2                	sd	s0,64(sp)
    8000198c:	fc26                	sd	s1,56(sp)
    8000198e:	f84a                	sd	s2,48(sp)
    80001990:	f44e                	sd	s3,40(sp)
    80001992:	f052                	sd	s4,32(sp)
    80001994:	ec56                	sd	s5,24(sp)
    80001996:	e85a                	sd	s6,16(sp)
    80001998:	e45e                	sd	s7,8(sp)
    8000199a:	e062                	sd	s8,0(sp)
    8000199c:	0880                	addi	s0,sp,80
    8000199e:	8b2a                	mv	s6,a0
    800019a0:	8a2e                	mv	s4,a1
    800019a2:	8c32                	mv	s8,a2
    800019a4:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800019a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019a8:	6a85                	lui	s5,0x1
    800019aa:	a01d                	j	800019d0 <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800019ac:	018505b3          	add	a1,a0,s8
    800019b0:	0004861b          	sext.w	a2,s1
    800019b4:	412585b3          	sub	a1,a1,s2
    800019b8:	8552                	mv	a0,s4
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	476080e7          	jalr	1142(ra) # 80000e30 <memmove>

    len -= n;
    800019c2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800019c6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800019c8:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800019cc:	02098263          	beqz	s3,800019f0 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800019d0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019d4:	85ca                	mv	a1,s2
    800019d6:	855a                	mv	a0,s6
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	786080e7          	jalr	1926(ra) # 8000115e <walkaddr>
    if (pa0 == 0)
    800019e0:	cd01                	beqz	a0,800019f8 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800019e2:	418904b3          	sub	s1,s2,s8
    800019e6:	94d6                	add	s1,s1,s5
    if (n > len)
    800019e8:	fc99f2e3          	bgeu	s3,s1,800019ac <copyin+0x28>
    800019ec:	84ce                	mv	s1,s3
    800019ee:	bf7d                	j	800019ac <copyin+0x28>
  }
  return 0;
    800019f0:	4501                	li	a0,0
    800019f2:	a021                	j	800019fa <copyin+0x76>
    800019f4:	4501                	li	a0,0
}
    800019f6:	8082                	ret
      return -1;
    800019f8:	557d                	li	a0,-1
}
    800019fa:	60a6                	ld	ra,72(sp)
    800019fc:	6406                	ld	s0,64(sp)
    800019fe:	74e2                	ld	s1,56(sp)
    80001a00:	7942                	ld	s2,48(sp)
    80001a02:	79a2                	ld	s3,40(sp)
    80001a04:	7a02                	ld	s4,32(sp)
    80001a06:	6ae2                	ld	s5,24(sp)
    80001a08:	6b42                	ld	s6,16(sp)
    80001a0a:	6ba2                	ld	s7,8(sp)
    80001a0c:	6c02                	ld	s8,0(sp)
    80001a0e:	6161                	addi	sp,sp,80
    80001a10:	8082                	ret

0000000080001a12 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80001a12:	c6c5                	beqz	a3,80001aba <copyinstr+0xa8>
{
    80001a14:	715d                	addi	sp,sp,-80
    80001a16:	e486                	sd	ra,72(sp)
    80001a18:	e0a2                	sd	s0,64(sp)
    80001a1a:	fc26                	sd	s1,56(sp)
    80001a1c:	f84a                	sd	s2,48(sp)
    80001a1e:	f44e                	sd	s3,40(sp)
    80001a20:	f052                	sd	s4,32(sp)
    80001a22:	ec56                	sd	s5,24(sp)
    80001a24:	e85a                	sd	s6,16(sp)
    80001a26:	e45e                	sd	s7,8(sp)
    80001a28:	0880                	addi	s0,sp,80
    80001a2a:	8a2a                	mv	s4,a0
    80001a2c:	8b2e                	mv	s6,a1
    80001a2e:	8bb2                	mv	s7,a2
    80001a30:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001a32:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a34:	6985                	lui	s3,0x1
    80001a36:	a035                	j	80001a62 <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001a38:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a3c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001a3e:	0017b793          	seqz	a5,a5
    80001a42:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001a46:	60a6                	ld	ra,72(sp)
    80001a48:	6406                	ld	s0,64(sp)
    80001a4a:	74e2                	ld	s1,56(sp)
    80001a4c:	7942                	ld	s2,48(sp)
    80001a4e:	79a2                	ld	s3,40(sp)
    80001a50:	7a02                	ld	s4,32(sp)
    80001a52:	6ae2                	ld	s5,24(sp)
    80001a54:	6b42                	ld	s6,16(sp)
    80001a56:	6ba2                	ld	s7,8(sp)
    80001a58:	6161                	addi	sp,sp,80
    80001a5a:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a5c:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001a60:	c8a9                	beqz	s1,80001ab2 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001a62:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a66:	85ca                	mv	a1,s2
    80001a68:	8552                	mv	a0,s4
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	6f4080e7          	jalr	1780(ra) # 8000115e <walkaddr>
    if (pa0 == 0)
    80001a72:	c131                	beqz	a0,80001ab6 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001a74:	41790833          	sub	a6,s2,s7
    80001a78:	984e                	add	a6,a6,s3
    if (n > max)
    80001a7a:	0104f363          	bgeu	s1,a6,80001a80 <copyinstr+0x6e>
    80001a7e:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001a80:	955e                	add	a0,a0,s7
    80001a82:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001a86:	fc080be3          	beqz	a6,80001a5c <copyinstr+0x4a>
    80001a8a:	985a                	add	a6,a6,s6
    80001a8c:	87da                	mv	a5,s6
      if (*p == '\0')
    80001a8e:	41650633          	sub	a2,a0,s6
    80001a92:	14fd                	addi	s1,s1,-1
    80001a94:	9b26                	add	s6,s6,s1
    80001a96:	00f60733          	add	a4,a2,a5
    80001a9a:	00074703          	lbu	a4,0(a4)
    80001a9e:	df49                	beqz	a4,80001a38 <copyinstr+0x26>
        *dst = *p;
    80001aa0:	00e78023          	sb	a4,0(a5)
      --max;
    80001aa4:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001aa8:	0785                	addi	a5,a5,1
    while (n > 0)
    80001aaa:	ff0796e3          	bne	a5,a6,80001a96 <copyinstr+0x84>
      dst++;
    80001aae:	8b42                	mv	s6,a6
    80001ab0:	b775                	j	80001a5c <copyinstr+0x4a>
    80001ab2:	4781                	li	a5,0
    80001ab4:	b769                	j	80001a3e <copyinstr+0x2c>
      return -1;
    80001ab6:	557d                	li	a0,-1
    80001ab8:	b779                	j	80001a46 <copyinstr+0x34>
  int got_null = 0;
    80001aba:	4781                	li	a5,0
  if (got_null)
    80001abc:	0017b793          	seqz	a5,a5
    80001ac0:	40f00533          	neg	a0,a5
}
    80001ac4:	8082                	ret

0000000080001ac6 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001ac6:	7139                	addi	sp,sp,-64
    80001ac8:	fc06                	sd	ra,56(sp)
    80001aca:	f822                	sd	s0,48(sp)
    80001acc:	f426                	sd	s1,40(sp)
    80001ace:	f04a                	sd	s2,32(sp)
    80001ad0:	ec4e                	sd	s3,24(sp)
    80001ad2:	e852                	sd	s4,16(sp)
    80001ad4:	e456                	sd	s5,8(sp)
    80001ad6:	e05a                	sd	s6,0(sp)
    80001ad8:	0080                	addi	s0,sp,64
    80001ada:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001adc:	0022f497          	auipc	s1,0x22f
    80001ae0:	4bc48493          	addi	s1,s1,1212 # 80230f98 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001ae4:	8b26                	mv	s6,s1
    80001ae6:	00006a97          	auipc	s5,0x6
    80001aea:	51aa8a93          	addi	s5,s5,1306 # 80008000 <etext>
    80001aee:	04000937          	lui	s2,0x4000
    80001af2:	197d                	addi	s2,s2,-1
    80001af4:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	00235a17          	auipc	s4,0x235
    80001afa:	2a2a0a13          	addi	s4,s4,674 # 80236d98 <tickslock>
    char *pa = kalloc();
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	0ae080e7          	jalr	174(ra) # 80000bac <kalloc>
    80001b06:	862a                	mv	a2,a0
    if (pa == 0)
    80001b08:	c131                	beqz	a0,80001b4c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001b0a:	416485b3          	sub	a1,s1,s6
    80001b0e:	858d                	srai	a1,a1,0x3
    80001b10:	000ab783          	ld	a5,0(s5)
    80001b14:	02f585b3          	mul	a1,a1,a5
    80001b18:	2585                	addiw	a1,a1,1
    80001b1a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b1e:	4719                	li	a4,6
    80001b20:	6685                	lui	a3,0x1
    80001b22:	40b905b3          	sub	a1,s2,a1
    80001b26:	854e                	mv	a0,s3
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	718080e7          	jalr	1816(ra) # 80001240 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b30:	17848493          	addi	s1,s1,376
    80001b34:	fd4495e3          	bne	s1,s4,80001afe <proc_mapstacks+0x38>
  }
}
    80001b38:	70e2                	ld	ra,56(sp)
    80001b3a:	7442                	ld	s0,48(sp)
    80001b3c:	74a2                	ld	s1,40(sp)
    80001b3e:	7902                	ld	s2,32(sp)
    80001b40:	69e2                	ld	s3,24(sp)
    80001b42:	6a42                	ld	s4,16(sp)
    80001b44:	6aa2                	ld	s5,8(sp)
    80001b46:	6b02                	ld	s6,0(sp)
    80001b48:	6121                	addi	sp,sp,64
    80001b4a:	8082                	ret
      panic("kalloc");
    80001b4c:	00006517          	auipc	a0,0x6
    80001b50:	69c50513          	addi	a0,a0,1692 # 800081e8 <digits+0x1a8>
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	9ea080e7          	jalr	-1558(ra) # 8000053e <panic>

0000000080001b5c <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001b5c:	7139                	addi	sp,sp,-64
    80001b5e:	fc06                	sd	ra,56(sp)
    80001b60:	f822                	sd	s0,48(sp)
    80001b62:	f426                	sd	s1,40(sp)
    80001b64:	f04a                	sd	s2,32(sp)
    80001b66:	ec4e                	sd	s3,24(sp)
    80001b68:	e852                	sd	s4,16(sp)
    80001b6a:	e456                	sd	s5,8(sp)
    80001b6c:	e05a                	sd	s6,0(sp)
    80001b6e:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b70:	00006597          	auipc	a1,0x6
    80001b74:	68058593          	addi	a1,a1,1664 # 800081f0 <digits+0x1b0>
    80001b78:	0022f517          	auipc	a0,0x22f
    80001b7c:	ff050513          	addi	a0,a0,-16 # 80230b68 <pid_lock>
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	0c8080e7          	jalr	200(ra) # 80000c48 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b88:	00006597          	auipc	a1,0x6
    80001b8c:	67058593          	addi	a1,a1,1648 # 800081f8 <digits+0x1b8>
    80001b90:	0022f517          	auipc	a0,0x22f
    80001b94:	ff050513          	addi	a0,a0,-16 # 80230b80 <wait_lock>
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	0b0080e7          	jalr	176(ra) # 80000c48 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ba0:	0022f497          	auipc	s1,0x22f
    80001ba4:	3f848493          	addi	s1,s1,1016 # 80230f98 <proc>
  {
    initlock(&p->lock, "proc");
    80001ba8:	00006b17          	auipc	s6,0x6
    80001bac:	660b0b13          	addi	s6,s6,1632 # 80008208 <digits+0x1c8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001bb0:	8aa6                	mv	s5,s1
    80001bb2:	00006a17          	auipc	s4,0x6
    80001bb6:	44ea0a13          	addi	s4,s4,1102 # 80008000 <etext>
    80001bba:	04000937          	lui	s2,0x4000
    80001bbe:	197d                	addi	s2,s2,-1
    80001bc0:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	00235997          	auipc	s3,0x235
    80001bc6:	1d698993          	addi	s3,s3,470 # 80236d98 <tickslock>
    initlock(&p->lock, "proc");
    80001bca:	85da                	mv	a1,s6
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	07a080e7          	jalr	122(ra) # 80000c48 <initlock>
    p->state = UNUSED;
    80001bd6:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001bda:	415487b3          	sub	a5,s1,s5
    80001bde:	878d                	srai	a5,a5,0x3
    80001be0:	000a3703          	ld	a4,0(s4)
    80001be4:	02e787b3          	mul	a5,a5,a4
    80001be8:	2785                	addiw	a5,a5,1
    80001bea:	00d7979b          	slliw	a5,a5,0xd
    80001bee:	40f907b3          	sub	a5,s2,a5
    80001bf2:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf4:	17848493          	addi	s1,s1,376
    80001bf8:	fd3499e3          	bne	s1,s3,80001bca <procinit+0x6e>
  }
}
    80001bfc:	70e2                	ld	ra,56(sp)
    80001bfe:	7442                	ld	s0,48(sp)
    80001c00:	74a2                	ld	s1,40(sp)
    80001c02:	7902                	ld	s2,32(sp)
    80001c04:	69e2                	ld	s3,24(sp)
    80001c06:	6a42                	ld	s4,16(sp)
    80001c08:	6aa2                	ld	s5,8(sp)
    80001c0a:	6b02                	ld	s6,0(sp)
    80001c0c:	6121                	addi	sp,sp,64
    80001c0e:	8082                	ret

0000000080001c10 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001c10:	1141                	addi	sp,sp,-16
    80001c12:	e422                	sd	s0,8(sp)
    80001c14:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c16:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c18:	2501                	sext.w	a0,a0
    80001c1a:	6422                	ld	s0,8(sp)
    80001c1c:	0141                	addi	sp,sp,16
    80001c1e:	8082                	ret

0000000080001c20 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001c20:	1141                	addi	sp,sp,-16
    80001c22:	e422                	sd	s0,8(sp)
    80001c24:	0800                	addi	s0,sp,16
    80001c26:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c28:	2781                	sext.w	a5,a5
    80001c2a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c2c:	0022f517          	auipc	a0,0x22f
    80001c30:	f6c50513          	addi	a0,a0,-148 # 80230b98 <cpus>
    80001c34:	953e                	add	a0,a0,a5
    80001c36:	6422                	ld	s0,8(sp)
    80001c38:	0141                	addi	sp,sp,16
    80001c3a:	8082                	ret

0000000080001c3c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001c3c:	1101                	addi	sp,sp,-32
    80001c3e:	ec06                	sd	ra,24(sp)
    80001c40:	e822                	sd	s0,16(sp)
    80001c42:	e426                	sd	s1,8(sp)
    80001c44:	1000                	addi	s0,sp,32
  push_off();
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	046080e7          	jalr	70(ra) # 80000c8c <push_off>
    80001c4e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c50:	2781                	sext.w	a5,a5
    80001c52:	079e                	slli	a5,a5,0x7
    80001c54:	0022f717          	auipc	a4,0x22f
    80001c58:	f1470713          	addi	a4,a4,-236 # 80230b68 <pid_lock>
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	0cc080e7          	jalr	204(ra) # 80000d2c <pop_off>
  return p;
}
    80001c68:	8526                	mv	a0,s1
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret

0000000080001c74 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c74:	1141                	addi	sp,sp,-16
    80001c76:	e406                	sd	ra,8(sp)
    80001c78:	e022                	sd	s0,0(sp)
    80001c7a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	fc0080e7          	jalr	-64(ra) # 80001c3c <myproc>
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	108080e7          	jalr	264(ra) # 80000d8c <release>

  if (first)
    80001c8c:	00007797          	auipc	a5,0x7
    80001c90:	bd47a783          	lw	a5,-1068(a5) # 80008860 <first.1>
    80001c94:	eb89                	bnez	a5,80001ca6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c96:	00001097          	auipc	ra,0x1
    80001c9a:	e24080e7          	jalr	-476(ra) # 80002aba <usertrapret>
}
    80001c9e:	60a2                	ld	ra,8(sp)
    80001ca0:	6402                	ld	s0,0(sp)
    80001ca2:	0141                	addi	sp,sp,16
    80001ca4:	8082                	ret
    first = 0;
    80001ca6:	00007797          	auipc	a5,0x7
    80001caa:	ba07ad23          	sw	zero,-1094(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001cae:	4505                	li	a0,1
    80001cb0:	00002097          	auipc	ra,0x2
    80001cb4:	d06080e7          	jalr	-762(ra) # 800039b6 <fsinit>
    80001cb8:	bff9                	j	80001c96 <forkret+0x22>

0000000080001cba <allocpid>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	e04a                	sd	s2,0(sp)
    80001cc4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cc6:	0022f917          	auipc	s2,0x22f
    80001cca:	ea290913          	addi	s2,s2,-350 # 80230b68 <pid_lock>
    80001cce:	854a                	mv	a0,s2
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	008080e7          	jalr	8(ra) # 80000cd8 <acquire>
  pid = nextpid;
    80001cd8:	00007797          	auipc	a5,0x7
    80001cdc:	b8c78793          	addi	a5,a5,-1140 # 80008864 <nextpid>
    80001ce0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ce2:	0014871b          	addiw	a4,s1,1
    80001ce6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ce8:	854a                	mv	a0,s2
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	0a2080e7          	jalr	162(ra) # 80000d8c <release>
}
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	60e2                	ld	ra,24(sp)
    80001cf6:	6442                	ld	s0,16(sp)
    80001cf8:	64a2                	ld	s1,8(sp)
    80001cfa:	6902                	ld	s2,0(sp)
    80001cfc:	6105                	addi	sp,sp,32
    80001cfe:	8082                	ret

0000000080001d00 <proc_pagetable>:
{
    80001d00:	1101                	addi	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	e04a                	sd	s2,0(sp)
    80001d0a:	1000                	addi	s0,sp,32
    80001d0c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	71c080e7          	jalr	1820(ra) # 8000142a <uvmcreate>
    80001d16:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001d18:	c121                	beqz	a0,80001d58 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d1a:	4729                	li	a4,10
    80001d1c:	00005697          	auipc	a3,0x5
    80001d20:	2e468693          	addi	a3,a3,740 # 80007000 <_trampoline>
    80001d24:	6605                	lui	a2,0x1
    80001d26:	040005b7          	lui	a1,0x4000
    80001d2a:	15fd                	addi	a1,a1,-1
    80001d2c:	05b2                	slli	a1,a1,0xc
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	472080e7          	jalr	1138(ra) # 800011a0 <mappages>
    80001d36:	02054863          	bltz	a0,80001d66 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d3a:	4719                	li	a4,6
    80001d3c:	05893683          	ld	a3,88(s2)
    80001d40:	6605                	lui	a2,0x1
    80001d42:	020005b7          	lui	a1,0x2000
    80001d46:	15fd                	addi	a1,a1,-1
    80001d48:	05b6                	slli	a1,a1,0xd
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	454080e7          	jalr	1108(ra) # 800011a0 <mappages>
    80001d54:	02054163          	bltz	a0,80001d76 <proc_pagetable+0x76>
}
    80001d58:	8526                	mv	a0,s1
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    uvmfree(pagetable, 0);
    80001d66:	4581                	li	a1,0
    80001d68:	8526                	mv	a0,s1
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	8c4080e7          	jalr	-1852(ra) # 8000162e <uvmfree>
    return 0;
    80001d72:	4481                	li	s1,0
    80001d74:	b7d5                	j	80001d58 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d76:	4681                	li	a3,0
    80001d78:	4605                	li	a2,1
    80001d7a:	040005b7          	lui	a1,0x4000
    80001d7e:	15fd                	addi	a1,a1,-1
    80001d80:	05b2                	slli	a1,a1,0xc
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	5e2080e7          	jalr	1506(ra) # 80001366 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d8c:	4581                	li	a1,0
    80001d8e:	8526                	mv	a0,s1
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	89e080e7          	jalr	-1890(ra) # 8000162e <uvmfree>
    return 0;
    80001d98:	4481                	li	s1,0
    80001d9a:	bf7d                	j	80001d58 <proc_pagetable+0x58>

0000000080001d9c <proc_freepagetable>:
{
    80001d9c:	1101                	addi	sp,sp,-32
    80001d9e:	ec06                	sd	ra,24(sp)
    80001da0:	e822                	sd	s0,16(sp)
    80001da2:	e426                	sd	s1,8(sp)
    80001da4:	e04a                	sd	s2,0(sp)
    80001da6:	1000                	addi	s0,sp,32
    80001da8:	84aa                	mv	s1,a0
    80001daa:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dac:	4681                	li	a3,0
    80001dae:	4605                	li	a2,1
    80001db0:	040005b7          	lui	a1,0x4000
    80001db4:	15fd                	addi	a1,a1,-1
    80001db6:	05b2                	slli	a1,a1,0xc
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	5ae080e7          	jalr	1454(ra) # 80001366 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dc0:	4681                	li	a3,0
    80001dc2:	4605                	li	a2,1
    80001dc4:	020005b7          	lui	a1,0x2000
    80001dc8:	15fd                	addi	a1,a1,-1
    80001dca:	05b6                	slli	a1,a1,0xd
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	598080e7          	jalr	1432(ra) # 80001366 <uvmunmap>
  uvmfree(pagetable, sz);
    80001dd6:	85ca                	mv	a1,s2
    80001dd8:	8526                	mv	a0,s1
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	854080e7          	jalr	-1964(ra) # 8000162e <uvmfree>
}
    80001de2:	60e2                	ld	ra,24(sp)
    80001de4:	6442                	ld	s0,16(sp)
    80001de6:	64a2                	ld	s1,8(sp)
    80001de8:	6902                	ld	s2,0(sp)
    80001dea:	6105                	addi	sp,sp,32
    80001dec:	8082                	ret

0000000080001dee <freeproc>:
{
    80001dee:	1101                	addi	sp,sp,-32
    80001df0:	ec06                	sd	ra,24(sp)
    80001df2:	e822                	sd	s0,16(sp)
    80001df4:	e426                	sd	s1,8(sp)
    80001df6:	1000                	addi	s0,sp,32
    80001df8:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001dfa:	6d28                	ld	a0,88(a0)
    80001dfc:	c509                	beqz	a0,80001e06 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	bec080e7          	jalr	-1044(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001e06:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001e0a:	68a8                	ld	a0,80(s1)
    80001e0c:	c511                	beqz	a0,80001e18 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e0e:	64ac                	ld	a1,72(s1)
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	f8c080e7          	jalr	-116(ra) # 80001d9c <proc_freepagetable>
  p->pagetable = 0;
    80001e18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e38:	0004ac23          	sw	zero,24(s1)
}
    80001e3c:	60e2                	ld	ra,24(sp)
    80001e3e:	6442                	ld	s0,16(sp)
    80001e40:	64a2                	ld	s1,8(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret

0000000080001e46 <allocproc>:
{
    80001e46:	1101                	addi	sp,sp,-32
    80001e48:	ec06                	sd	ra,24(sp)
    80001e4a:	e822                	sd	s0,16(sp)
    80001e4c:	e426                	sd	s1,8(sp)
    80001e4e:	e04a                	sd	s2,0(sp)
    80001e50:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001e52:	0022f497          	auipc	s1,0x22f
    80001e56:	14648493          	addi	s1,s1,326 # 80230f98 <proc>
    80001e5a:	00235917          	auipc	s2,0x235
    80001e5e:	f3e90913          	addi	s2,s2,-194 # 80236d98 <tickslock>
    acquire(&p->lock);
    80001e62:	8526                	mv	a0,s1
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	e74080e7          	jalr	-396(ra) # 80000cd8 <acquire>
    if (p->state == UNUSED)
    80001e6c:	4c9c                	lw	a5,24(s1)
    80001e6e:	cf81                	beqz	a5,80001e86 <allocproc+0x40>
      release(&p->lock);
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	f1a080e7          	jalr	-230(ra) # 80000d8c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e7a:	17848493          	addi	s1,s1,376
    80001e7e:	ff2492e3          	bne	s1,s2,80001e62 <allocproc+0x1c>
  return 0;
    80001e82:	4481                	li	s1,0
    80001e84:	a09d                	j	80001eea <allocproc+0xa4>
  p->pid = allocpid();
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	e34080e7          	jalr	-460(ra) # 80001cba <allocpid>
    80001e8e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e90:	4785                	li	a5,1
    80001e92:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	d18080e7          	jalr	-744(ra) # 80000bac <kalloc>
    80001e9c:	892a                	mv	s2,a0
    80001e9e:	eca8                	sd	a0,88(s1)
    80001ea0:	cd21                	beqz	a0,80001ef8 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	e5c080e7          	jalr	-420(ra) # 80001d00 <proc_pagetable>
    80001eac:	892a                	mv	s2,a0
    80001eae:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001eb0:	c125                	beqz	a0,80001f10 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001eb2:	07000613          	li	a2,112
    80001eb6:	4581                	li	a1,0
    80001eb8:	06048513          	addi	a0,s1,96
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	f18080e7          	jalr	-232(ra) # 80000dd4 <memset>
  p->context.ra = (uint64)forkret;
    80001ec4:	00000797          	auipc	a5,0x0
    80001ec8:	db078793          	addi	a5,a5,-592 # 80001c74 <forkret>
    80001ecc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ece:	60bc                	ld	a5,64(s1)
    80001ed0:	6705                	lui	a4,0x1
    80001ed2:	97ba                	add	a5,a5,a4
    80001ed4:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001ed6:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001eda:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001ede:	00007797          	auipc	a5,0x7
    80001ee2:	a0a7a783          	lw	a5,-1526(a5) # 800088e8 <ticks>
    80001ee6:	16f4a623          	sw	a5,364(s1)
}
    80001eea:	8526                	mv	a0,s1
    80001eec:	60e2                	ld	ra,24(sp)
    80001eee:	6442                	ld	s0,16(sp)
    80001ef0:	64a2                	ld	s1,8(sp)
    80001ef2:	6902                	ld	s2,0(sp)
    80001ef4:	6105                	addi	sp,sp,32
    80001ef6:	8082                	ret
    freeproc(p);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	00000097          	auipc	ra,0x0
    80001efe:	ef4080e7          	jalr	-268(ra) # 80001dee <freeproc>
    release(&p->lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	e88080e7          	jalr	-376(ra) # 80000d8c <release>
    return 0;
    80001f0c:	84ca                	mv	s1,s2
    80001f0e:	bff1                	j	80001eea <allocproc+0xa4>
    freeproc(p);
    80001f10:	8526                	mv	a0,s1
    80001f12:	00000097          	auipc	ra,0x0
    80001f16:	edc080e7          	jalr	-292(ra) # 80001dee <freeproc>
    release(&p->lock);
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	e70080e7          	jalr	-400(ra) # 80000d8c <release>
    return 0;
    80001f24:	84ca                	mv	s1,s2
    80001f26:	b7d1                	j	80001eea <allocproc+0xa4>

0000000080001f28 <userinit>:
{
    80001f28:	1101                	addi	sp,sp,-32
    80001f2a:	ec06                	sd	ra,24(sp)
    80001f2c:	e822                	sd	s0,16(sp)
    80001f2e:	e426                	sd	s1,8(sp)
    80001f30:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	f14080e7          	jalr	-236(ra) # 80001e46 <allocproc>
    80001f3a:	84aa                	mv	s1,a0
  initproc = p;
    80001f3c:	00007797          	auipc	a5,0x7
    80001f40:	9aa7b223          	sd	a0,-1628(a5) # 800088e0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f44:	03400613          	li	a2,52
    80001f48:	00007597          	auipc	a1,0x7
    80001f4c:	92858593          	addi	a1,a1,-1752 # 80008870 <initcode>
    80001f50:	6928                	ld	a0,80(a0)
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	506080e7          	jalr	1286(ra) # 80001458 <uvmfirst>
  p->sz = PGSIZE;
    80001f5a:	6785                	lui	a5,0x1
    80001f5c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f5e:	6cb8                	ld	a4,88(s1)
    80001f60:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f64:	6cb8                	ld	a4,88(s1)
    80001f66:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f68:	4641                	li	a2,16
    80001f6a:	00006597          	auipc	a1,0x6
    80001f6e:	2a658593          	addi	a1,a1,678 # 80008210 <digits+0x1d0>
    80001f72:	15848513          	addi	a0,s1,344
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	fa8080e7          	jalr	-88(ra) # 80000f1e <safestrcpy>
  p->cwd = namei("/");
    80001f7e:	00006517          	auipc	a0,0x6
    80001f82:	2a250513          	addi	a0,a0,674 # 80008220 <digits+0x1e0>
    80001f86:	00002097          	auipc	ra,0x2
    80001f8a:	452080e7          	jalr	1106(ra) # 800043d8 <namei>
    80001f8e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f92:	478d                	li	a5,3
    80001f94:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	df4080e7          	jalr	-524(ra) # 80000d8c <release>
}
    80001fa0:	60e2                	ld	ra,24(sp)
    80001fa2:	6442                	ld	s0,16(sp)
    80001fa4:	64a2                	ld	s1,8(sp)
    80001fa6:	6105                	addi	sp,sp,32
    80001fa8:	8082                	ret

0000000080001faa <growproc>:
{
    80001faa:	1101                	addi	sp,sp,-32
    80001fac:	ec06                	sd	ra,24(sp)
    80001fae:	e822                	sd	s0,16(sp)
    80001fb0:	e426                	sd	s1,8(sp)
    80001fb2:	e04a                	sd	s2,0(sp)
    80001fb4:	1000                	addi	s0,sp,32
    80001fb6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	c84080e7          	jalr	-892(ra) # 80001c3c <myproc>
    80001fc0:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fc2:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001fc4:	01204c63          	bgtz	s2,80001fdc <growproc+0x32>
  else if (n < 0)
    80001fc8:	02094663          	bltz	s2,80001ff4 <growproc+0x4a>
  p->sz = sz;
    80001fcc:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fce:	4501                	li	a0,0
}
    80001fd0:	60e2                	ld	ra,24(sp)
    80001fd2:	6442                	ld	s0,16(sp)
    80001fd4:	64a2                	ld	s1,8(sp)
    80001fd6:	6902                	ld	s2,0(sp)
    80001fd8:	6105                	addi	sp,sp,32
    80001fda:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fdc:	4691                	li	a3,4
    80001fde:	00b90633          	add	a2,s2,a1
    80001fe2:	6928                	ld	a0,80(a0)
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	52e080e7          	jalr	1326(ra) # 80001512 <uvmalloc>
    80001fec:	85aa                	mv	a1,a0
    80001fee:	fd79                	bnez	a0,80001fcc <growproc+0x22>
      return -1;
    80001ff0:	557d                	li	a0,-1
    80001ff2:	bff9                	j	80001fd0 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ff4:	00b90633          	add	a2,s2,a1
    80001ff8:	6928                	ld	a0,80(a0)
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	4d0080e7          	jalr	1232(ra) # 800014ca <uvmdealloc>
    80002002:	85aa                	mv	a1,a0
    80002004:	b7e1                	j	80001fcc <growproc+0x22>

0000000080002006 <fork>:
{
    80002006:	7139                	addi	sp,sp,-64
    80002008:	fc06                	sd	ra,56(sp)
    8000200a:	f822                	sd	s0,48(sp)
    8000200c:	f426                	sd	s1,40(sp)
    8000200e:	f04a                	sd	s2,32(sp)
    80002010:	ec4e                	sd	s3,24(sp)
    80002012:	e852                	sd	s4,16(sp)
    80002014:	e456                	sd	s5,8(sp)
    80002016:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	c24080e7          	jalr	-988(ra) # 80001c3c <myproc>
    80002020:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80002022:	00000097          	auipc	ra,0x0
    80002026:	e24080e7          	jalr	-476(ra) # 80001e46 <allocproc>
    8000202a:	10050c63          	beqz	a0,80002142 <fork+0x13c>
    8000202e:	8a2a                	mv	s4,a0
  if (uvmcopy2(p->pagetable, np->pagetable, p->sz) < 0)
    80002030:	048ab603          	ld	a2,72(s5)
    80002034:	692c                	ld	a1,80(a0)
    80002036:	050ab503          	ld	a0,80(s5)
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	6fe080e7          	jalr	1790(ra) # 80001738 <uvmcopy2>
    80002042:	04054863          	bltz	a0,80002092 <fork+0x8c>
  np->sz = p->sz;
    80002046:	048ab783          	ld	a5,72(s5)
    8000204a:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    8000204e:	058ab683          	ld	a3,88(s5)
    80002052:	87b6                	mv	a5,a3
    80002054:	058a3703          	ld	a4,88(s4)
    80002058:	12068693          	addi	a3,a3,288
    8000205c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002060:	6788                	ld	a0,8(a5)
    80002062:	6b8c                	ld	a1,16(a5)
    80002064:	6f90                	ld	a2,24(a5)
    80002066:	01073023          	sd	a6,0(a4)
    8000206a:	e708                	sd	a0,8(a4)
    8000206c:	eb0c                	sd	a1,16(a4)
    8000206e:	ef10                	sd	a2,24(a4)
    80002070:	02078793          	addi	a5,a5,32
    80002074:	02070713          	addi	a4,a4,32
    80002078:	fed792e3          	bne	a5,a3,8000205c <fork+0x56>
  np->trapframe->a0 = 0;
    8000207c:	058a3783          	ld	a5,88(s4)
    80002080:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002084:	0d0a8493          	addi	s1,s5,208
    80002088:	0d0a0913          	addi	s2,s4,208
    8000208c:	150a8993          	addi	s3,s5,336
    80002090:	a00d                	j	800020b2 <fork+0xac>
    freeproc(np);
    80002092:	8552                	mv	a0,s4
    80002094:	00000097          	auipc	ra,0x0
    80002098:	d5a080e7          	jalr	-678(ra) # 80001dee <freeproc>
    release(&np->lock);
    8000209c:	8552                	mv	a0,s4
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	cee080e7          	jalr	-786(ra) # 80000d8c <release>
    return -1;
    800020a6:	597d                	li	s2,-1
    800020a8:	a059                	j	8000212e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    800020aa:	04a1                	addi	s1,s1,8
    800020ac:	0921                	addi	s2,s2,8
    800020ae:	01348b63          	beq	s1,s3,800020c4 <fork+0xbe>
    if (p->ofile[i])
    800020b2:	6088                	ld	a0,0(s1)
    800020b4:	d97d                	beqz	a0,800020aa <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800020b6:	00003097          	auipc	ra,0x3
    800020ba:	9b8080e7          	jalr	-1608(ra) # 80004a6e <filedup>
    800020be:	00a93023          	sd	a0,0(s2)
    800020c2:	b7e5                	j	800020aa <fork+0xa4>
  np->cwd = idup(p->cwd);
    800020c4:	150ab503          	ld	a0,336(s5)
    800020c8:	00002097          	auipc	ra,0x2
    800020cc:	b2c080e7          	jalr	-1236(ra) # 80003bf4 <idup>
    800020d0:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020d4:	4641                	li	a2,16
    800020d6:	158a8593          	addi	a1,s5,344
    800020da:	158a0513          	addi	a0,s4,344
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	e40080e7          	jalr	-448(ra) # 80000f1e <safestrcpy>
  pid = np->pid;
    800020e6:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800020ea:	8552                	mv	a0,s4
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	ca0080e7          	jalr	-864(ra) # 80000d8c <release>
  acquire(&wait_lock);
    800020f4:	0022f497          	auipc	s1,0x22f
    800020f8:	a8c48493          	addi	s1,s1,-1396 # 80230b80 <wait_lock>
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	bda080e7          	jalr	-1062(ra) # 80000cd8 <acquire>
  np->parent = p;
    80002106:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	c80080e7          	jalr	-896(ra) # 80000d8c <release>
  acquire(&np->lock);
    80002114:	8552                	mv	a0,s4
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	bc2080e7          	jalr	-1086(ra) # 80000cd8 <acquire>
  np->state = RUNNABLE;
    8000211e:	478d                	li	a5,3
    80002120:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002124:	8552                	mv	a0,s4
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	c66080e7          	jalr	-922(ra) # 80000d8c <release>
}
    8000212e:	854a                	mv	a0,s2
    80002130:	70e2                	ld	ra,56(sp)
    80002132:	7442                	ld	s0,48(sp)
    80002134:	74a2                	ld	s1,40(sp)
    80002136:	7902                	ld	s2,32(sp)
    80002138:	69e2                	ld	s3,24(sp)
    8000213a:	6a42                	ld	s4,16(sp)
    8000213c:	6aa2                	ld	s5,8(sp)
    8000213e:	6121                	addi	sp,sp,64
    80002140:	8082                	ret
    return -1;
    80002142:	597d                	li	s2,-1
    80002144:	b7ed                	j	8000212e <fork+0x128>

0000000080002146 <scheduler>:
{
    80002146:	7139                	addi	sp,sp,-64
    80002148:	fc06                	sd	ra,56(sp)
    8000214a:	f822                	sd	s0,48(sp)
    8000214c:	f426                	sd	s1,40(sp)
    8000214e:	f04a                	sd	s2,32(sp)
    80002150:	ec4e                	sd	s3,24(sp)
    80002152:	e852                	sd	s4,16(sp)
    80002154:	e456                	sd	s5,8(sp)
    80002156:	e05a                	sd	s6,0(sp)
    80002158:	0080                	addi	s0,sp,64
    8000215a:	8792                	mv	a5,tp
  int id = r_tp();
    8000215c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000215e:	00779a93          	slli	s5,a5,0x7
    80002162:	0022f717          	auipc	a4,0x22f
    80002166:	a0670713          	addi	a4,a4,-1530 # 80230b68 <pid_lock>
    8000216a:	9756                	add	a4,a4,s5
    8000216c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002170:	0022f717          	auipc	a4,0x22f
    80002174:	a3070713          	addi	a4,a4,-1488 # 80230ba0 <cpus+0x8>
    80002178:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000217a:	498d                	li	s3,3
        p->state = RUNNING;
    8000217c:	4b11                	li	s6,4
        c->proc = p;
    8000217e:	079e                	slli	a5,a5,0x7
    80002180:	0022fa17          	auipc	s4,0x22f
    80002184:	9e8a0a13          	addi	s4,s4,-1560 # 80230b68 <pid_lock>
    80002188:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000218a:	00235917          	auipc	s2,0x235
    8000218e:	c0e90913          	addi	s2,s2,-1010 # 80236d98 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002192:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002196:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000219a:	10079073          	csrw	sstatus,a5
    8000219e:	0022f497          	auipc	s1,0x22f
    800021a2:	dfa48493          	addi	s1,s1,-518 # 80230f98 <proc>
    800021a6:	a811                	j	800021ba <scheduler+0x74>
      release(&p->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	be2080e7          	jalr	-1054(ra) # 80000d8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800021b2:	17848493          	addi	s1,s1,376
    800021b6:	fd248ee3          	beq	s1,s2,80002192 <scheduler+0x4c>
      acquire(&p->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	b1c080e7          	jalr	-1252(ra) # 80000cd8 <acquire>
      if (p->state == RUNNABLE)
    800021c4:	4c9c                	lw	a5,24(s1)
    800021c6:	ff3791e3          	bne	a5,s3,800021a8 <scheduler+0x62>
        p->state = RUNNING;
    800021ca:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800021ce:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800021d2:	06048593          	addi	a1,s1,96
    800021d6:	8556                	mv	a0,s5
    800021d8:	00001097          	auipc	ra,0x1
    800021dc:	838080e7          	jalr	-1992(ra) # 80002a10 <swtch>
        c->proc = 0;
    800021e0:	020a3823          	sd	zero,48(s4)
    800021e4:	b7d1                	j	800021a8 <scheduler+0x62>

00000000800021e6 <sched>:
{
    800021e6:	7179                	addi	sp,sp,-48
    800021e8:	f406                	sd	ra,40(sp)
    800021ea:	f022                	sd	s0,32(sp)
    800021ec:	ec26                	sd	s1,24(sp)
    800021ee:	e84a                	sd	s2,16(sp)
    800021f0:	e44e                	sd	s3,8(sp)
    800021f2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	a48080e7          	jalr	-1464(ra) # 80001c3c <myproc>
    800021fc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a60080e7          	jalr	-1440(ra) # 80000c5e <holding>
    80002206:	c93d                	beqz	a0,8000227c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002208:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000220a:	2781                	sext.w	a5,a5
    8000220c:	079e                	slli	a5,a5,0x7
    8000220e:	0022f717          	auipc	a4,0x22f
    80002212:	95a70713          	addi	a4,a4,-1702 # 80230b68 <pid_lock>
    80002216:	97ba                	add	a5,a5,a4
    80002218:	0a87a703          	lw	a4,168(a5)
    8000221c:	4785                	li	a5,1
    8000221e:	06f71763          	bne	a4,a5,8000228c <sched+0xa6>
  if (p->state == RUNNING)
    80002222:	4c98                	lw	a4,24(s1)
    80002224:	4791                	li	a5,4
    80002226:	06f70b63          	beq	a4,a5,8000229c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000222a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000222e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002230:	efb5                	bnez	a5,800022ac <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002232:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002234:	0022f917          	auipc	s2,0x22f
    80002238:	93490913          	addi	s2,s2,-1740 # 80230b68 <pid_lock>
    8000223c:	2781                	sext.w	a5,a5
    8000223e:	079e                	slli	a5,a5,0x7
    80002240:	97ca                	add	a5,a5,s2
    80002242:	0ac7a983          	lw	s3,172(a5)
    80002246:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002248:	2781                	sext.w	a5,a5
    8000224a:	079e                	slli	a5,a5,0x7
    8000224c:	0022f597          	auipc	a1,0x22f
    80002250:	95458593          	addi	a1,a1,-1708 # 80230ba0 <cpus+0x8>
    80002254:	95be                	add	a1,a1,a5
    80002256:	06048513          	addi	a0,s1,96
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	7b6080e7          	jalr	1974(ra) # 80002a10 <swtch>
    80002262:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002264:	2781                	sext.w	a5,a5
    80002266:	079e                	slli	a5,a5,0x7
    80002268:	97ca                	add	a5,a5,s2
    8000226a:	0b37a623          	sw	s3,172(a5)
}
    8000226e:	70a2                	ld	ra,40(sp)
    80002270:	7402                	ld	s0,32(sp)
    80002272:	64e2                	ld	s1,24(sp)
    80002274:	6942                	ld	s2,16(sp)
    80002276:	69a2                	ld	s3,8(sp)
    80002278:	6145                	addi	sp,sp,48
    8000227a:	8082                	ret
    panic("sched p->lock");
    8000227c:	00006517          	auipc	a0,0x6
    80002280:	fac50513          	addi	a0,a0,-84 # 80008228 <digits+0x1e8>
    80002284:	ffffe097          	auipc	ra,0xffffe
    80002288:	2ba080e7          	jalr	698(ra) # 8000053e <panic>
    panic("sched locks");
    8000228c:	00006517          	auipc	a0,0x6
    80002290:	fac50513          	addi	a0,a0,-84 # 80008238 <digits+0x1f8>
    80002294:	ffffe097          	auipc	ra,0xffffe
    80002298:	2aa080e7          	jalr	682(ra) # 8000053e <panic>
    panic("sched running");
    8000229c:	00006517          	auipc	a0,0x6
    800022a0:	fac50513          	addi	a0,a0,-84 # 80008248 <digits+0x208>
    800022a4:	ffffe097          	auipc	ra,0xffffe
    800022a8:	29a080e7          	jalr	666(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022ac:	00006517          	auipc	a0,0x6
    800022b0:	fac50513          	addi	a0,a0,-84 # 80008258 <digits+0x218>
    800022b4:	ffffe097          	auipc	ra,0xffffe
    800022b8:	28a080e7          	jalr	650(ra) # 8000053e <panic>

00000000800022bc <yield>:
{
    800022bc:	1101                	addi	sp,sp,-32
    800022be:	ec06                	sd	ra,24(sp)
    800022c0:	e822                	sd	s0,16(sp)
    800022c2:	e426                	sd	s1,8(sp)
    800022c4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	976080e7          	jalr	-1674(ra) # 80001c3c <myproc>
    800022ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	a08080e7          	jalr	-1528(ra) # 80000cd8 <acquire>
  p->state = RUNNABLE;
    800022d8:	478d                	li	a5,3
    800022da:	cc9c                	sw	a5,24(s1)
  sched();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	f0a080e7          	jalr	-246(ra) # 800021e6 <sched>
  release(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	aa6080e7          	jalr	-1370(ra) # 80000d8c <release>
}
    800022ee:	60e2                	ld	ra,24(sp)
    800022f0:	6442                	ld	s0,16(sp)
    800022f2:	64a2                	ld	s1,8(sp)
    800022f4:	6105                	addi	sp,sp,32
    800022f6:	8082                	ret

00000000800022f8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022f8:	7179                	addi	sp,sp,-48
    800022fa:	f406                	sd	ra,40(sp)
    800022fc:	f022                	sd	s0,32(sp)
    800022fe:	ec26                	sd	s1,24(sp)
    80002300:	e84a                	sd	s2,16(sp)
    80002302:	e44e                	sd	s3,8(sp)
    80002304:	1800                	addi	s0,sp,48
    80002306:	89aa                	mv	s3,a0
    80002308:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	932080e7          	jalr	-1742(ra) # 80001c3c <myproc>
    80002312:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	9c4080e7          	jalr	-1596(ra) # 80000cd8 <acquire>
  release(lk);
    8000231c:	854a                	mv	a0,s2
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	a6e080e7          	jalr	-1426(ra) # 80000d8c <release>

  // Go to sleep.
  p->chan = chan;
    80002326:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000232a:	4789                	li	a5,2
    8000232c:	cc9c                	sw	a5,24(s1)

  sched();
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	eb8080e7          	jalr	-328(ra) # 800021e6 <sched>

  // Tidy up.
  p->chan = 0;
    80002336:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	a50080e7          	jalr	-1456(ra) # 80000d8c <release>
  acquire(lk);
    80002344:	854a                	mv	a0,s2
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	992080e7          	jalr	-1646(ra) # 80000cd8 <acquire>
}
    8000234e:	70a2                	ld	ra,40(sp)
    80002350:	7402                	ld	s0,32(sp)
    80002352:	64e2                	ld	s1,24(sp)
    80002354:	6942                	ld	s2,16(sp)
    80002356:	69a2                	ld	s3,8(sp)
    80002358:	6145                	addi	sp,sp,48
    8000235a:	8082                	ret

000000008000235c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000235c:	7139                	addi	sp,sp,-64
    8000235e:	fc06                	sd	ra,56(sp)
    80002360:	f822                	sd	s0,48(sp)
    80002362:	f426                	sd	s1,40(sp)
    80002364:	f04a                	sd	s2,32(sp)
    80002366:	ec4e                	sd	s3,24(sp)
    80002368:	e852                	sd	s4,16(sp)
    8000236a:	e456                	sd	s5,8(sp)
    8000236c:	0080                	addi	s0,sp,64
    8000236e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002370:	0022f497          	auipc	s1,0x22f
    80002374:	c2848493          	addi	s1,s1,-984 # 80230f98 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002378:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000237a:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000237c:	00235917          	auipc	s2,0x235
    80002380:	a1c90913          	addi	s2,s2,-1508 # 80236d98 <tickslock>
    80002384:	a811                	j	80002398 <wakeup+0x3c>
      }
      release(&p->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	a04080e7          	jalr	-1532(ra) # 80000d8c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002390:	17848493          	addi	s1,s1,376
    80002394:	03248663          	beq	s1,s2,800023c0 <wakeup+0x64>
    if (p != myproc())
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	8a4080e7          	jalr	-1884(ra) # 80001c3c <myproc>
    800023a0:	fea488e3          	beq	s1,a0,80002390 <wakeup+0x34>
      acquire(&p->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	932080e7          	jalr	-1742(ra) # 80000cd8 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800023ae:	4c9c                	lw	a5,24(s1)
    800023b0:	fd379be3          	bne	a5,s3,80002386 <wakeup+0x2a>
    800023b4:	709c                	ld	a5,32(s1)
    800023b6:	fd4798e3          	bne	a5,s4,80002386 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023ba:	0154ac23          	sw	s5,24(s1)
    800023be:	b7e1                	j	80002386 <wakeup+0x2a>
    }
  }
}
    800023c0:	70e2                	ld	ra,56(sp)
    800023c2:	7442                	ld	s0,48(sp)
    800023c4:	74a2                	ld	s1,40(sp)
    800023c6:	7902                	ld	s2,32(sp)
    800023c8:	69e2                	ld	s3,24(sp)
    800023ca:	6a42                	ld	s4,16(sp)
    800023cc:	6aa2                	ld	s5,8(sp)
    800023ce:	6121                	addi	sp,sp,64
    800023d0:	8082                	ret

00000000800023d2 <reparent>:
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	e052                	sd	s4,0(sp)
    800023e0:	1800                	addi	s0,sp,48
    800023e2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023e4:	0022f497          	auipc	s1,0x22f
    800023e8:	bb448493          	addi	s1,s1,-1100 # 80230f98 <proc>
      pp->parent = initproc;
    800023ec:	00006a17          	auipc	s4,0x6
    800023f0:	4f4a0a13          	addi	s4,s4,1268 # 800088e0 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023f4:	00235997          	auipc	s3,0x235
    800023f8:	9a498993          	addi	s3,s3,-1628 # 80236d98 <tickslock>
    800023fc:	a029                	j	80002406 <reparent+0x34>
    800023fe:	17848493          	addi	s1,s1,376
    80002402:	01348d63          	beq	s1,s3,8000241c <reparent+0x4a>
    if (pp->parent == p)
    80002406:	7c9c                	ld	a5,56(s1)
    80002408:	ff279be3          	bne	a5,s2,800023fe <reparent+0x2c>
      pp->parent = initproc;
    8000240c:	000a3503          	ld	a0,0(s4)
    80002410:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002412:	00000097          	auipc	ra,0x0
    80002416:	f4a080e7          	jalr	-182(ra) # 8000235c <wakeup>
    8000241a:	b7d5                	j	800023fe <reparent+0x2c>
}
    8000241c:	70a2                	ld	ra,40(sp)
    8000241e:	7402                	ld	s0,32(sp)
    80002420:	64e2                	ld	s1,24(sp)
    80002422:	6942                	ld	s2,16(sp)
    80002424:	69a2                	ld	s3,8(sp)
    80002426:	6a02                	ld	s4,0(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret

000000008000242c <exit>:
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	e052                	sd	s4,0(sp)
    8000243a:	1800                	addi	s0,sp,48
    8000243c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	7fe080e7          	jalr	2046(ra) # 80001c3c <myproc>
    80002446:	89aa                	mv	s3,a0
  if (p == initproc)
    80002448:	00006797          	auipc	a5,0x6
    8000244c:	4987b783          	ld	a5,1176(a5) # 800088e0 <initproc>
    80002450:	0d050493          	addi	s1,a0,208
    80002454:	15050913          	addi	s2,a0,336
    80002458:	02a79363          	bne	a5,a0,8000247e <exit+0x52>
    panic("init exiting");
    8000245c:	00006517          	auipc	a0,0x6
    80002460:	e1450513          	addi	a0,a0,-492 # 80008270 <digits+0x230>
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	0da080e7          	jalr	218(ra) # 8000053e <panic>
      fileclose(f);
    8000246c:	00002097          	auipc	ra,0x2
    80002470:	654080e7          	jalr	1620(ra) # 80004ac0 <fileclose>
      p->ofile[fd] = 0;
    80002474:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002478:	04a1                	addi	s1,s1,8
    8000247a:	01248563          	beq	s1,s2,80002484 <exit+0x58>
    if (p->ofile[fd])
    8000247e:	6088                	ld	a0,0(s1)
    80002480:	f575                	bnez	a0,8000246c <exit+0x40>
    80002482:	bfdd                	j	80002478 <exit+0x4c>
  begin_op();
    80002484:	00002097          	auipc	ra,0x2
    80002488:	170080e7          	jalr	368(ra) # 800045f4 <begin_op>
  iput(p->cwd);
    8000248c:	1509b503          	ld	a0,336(s3)
    80002490:	00002097          	auipc	ra,0x2
    80002494:	95c080e7          	jalr	-1700(ra) # 80003dec <iput>
  end_op();
    80002498:	00002097          	auipc	ra,0x2
    8000249c:	1dc080e7          	jalr	476(ra) # 80004674 <end_op>
  p->cwd = 0;
    800024a0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024a4:	0022e497          	auipc	s1,0x22e
    800024a8:	6dc48493          	addi	s1,s1,1756 # 80230b80 <wait_lock>
    800024ac:	8526                	mv	a0,s1
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	82a080e7          	jalr	-2006(ra) # 80000cd8 <acquire>
  reparent(p);
    800024b6:	854e                	mv	a0,s3
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	f1a080e7          	jalr	-230(ra) # 800023d2 <reparent>
  wakeup(p->parent);
    800024c0:	0389b503          	ld	a0,56(s3)
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	e98080e7          	jalr	-360(ra) # 8000235c <wakeup>
  acquire(&p->lock);
    800024cc:	854e                	mv	a0,s3
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	80a080e7          	jalr	-2038(ra) # 80000cd8 <acquire>
  p->xstate = status;
    800024d6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024da:	4795                	li	a5,5
    800024dc:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800024e0:	00006797          	auipc	a5,0x6
    800024e4:	4087a783          	lw	a5,1032(a5) # 800088e8 <ticks>
    800024e8:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	89e080e7          	jalr	-1890(ra) # 80000d8c <release>
  sched();
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	cf0080e7          	jalr	-784(ra) # 800021e6 <sched>
  panic("zombie exit");
    800024fe:	00006517          	auipc	a0,0x6
    80002502:	d8250513          	addi	a0,a0,-638 # 80008280 <digits+0x240>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	038080e7          	jalr	56(ra) # 8000053e <panic>

000000008000250e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000250e:	7179                	addi	sp,sp,-48
    80002510:	f406                	sd	ra,40(sp)
    80002512:	f022                	sd	s0,32(sp)
    80002514:	ec26                	sd	s1,24(sp)
    80002516:	e84a                	sd	s2,16(sp)
    80002518:	e44e                	sd	s3,8(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000251e:	0022f497          	auipc	s1,0x22f
    80002522:	a7a48493          	addi	s1,s1,-1414 # 80230f98 <proc>
    80002526:	00235997          	auipc	s3,0x235
    8000252a:	87298993          	addi	s3,s3,-1934 # 80236d98 <tickslock>
  {
    acquire(&p->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	7a8080e7          	jalr	1960(ra) # 80000cd8 <acquire>
    if (p->pid == pid)
    80002538:	589c                	lw	a5,48(s1)
    8000253a:	01278d63          	beq	a5,s2,80002554 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000253e:	8526                	mv	a0,s1
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	84c080e7          	jalr	-1972(ra) # 80000d8c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002548:	17848493          	addi	s1,s1,376
    8000254c:	ff3491e3          	bne	s1,s3,8000252e <kill+0x20>
  }
  return -1;
    80002550:	557d                	li	a0,-1
    80002552:	a829                	j	8000256c <kill+0x5e>
      p->killed = 1;
    80002554:	4785                	li	a5,1
    80002556:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002558:	4c98                	lw	a4,24(s1)
    8000255a:	4789                	li	a5,2
    8000255c:	00f70f63          	beq	a4,a5,8000257a <kill+0x6c>
      release(&p->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	82a080e7          	jalr	-2006(ra) # 80000d8c <release>
      return 0;
    8000256a:	4501                	li	a0,0
}
    8000256c:	70a2                	ld	ra,40(sp)
    8000256e:	7402                	ld	s0,32(sp)
    80002570:	64e2                	ld	s1,24(sp)
    80002572:	6942                	ld	s2,16(sp)
    80002574:	69a2                	ld	s3,8(sp)
    80002576:	6145                	addi	sp,sp,48
    80002578:	8082                	ret
        p->state = RUNNABLE;
    8000257a:	478d                	li	a5,3
    8000257c:	cc9c                	sw	a5,24(s1)
    8000257e:	b7cd                	j	80002560 <kill+0x52>

0000000080002580 <setkilled>:

void setkilled(struct proc *p)
{
    80002580:	1101                	addi	sp,sp,-32
    80002582:	ec06                	sd	ra,24(sp)
    80002584:	e822                	sd	s0,16(sp)
    80002586:	e426                	sd	s1,8(sp)
    80002588:	1000                	addi	s0,sp,32
    8000258a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	74c080e7          	jalr	1868(ra) # 80000cd8 <acquire>
  p->killed = 1;
    80002594:	4785                	li	a5,1
    80002596:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	7f2080e7          	jalr	2034(ra) # 80000d8c <release>
}
    800025a2:	60e2                	ld	ra,24(sp)
    800025a4:	6442                	ld	s0,16(sp)
    800025a6:	64a2                	ld	s1,8(sp)
    800025a8:	6105                	addi	sp,sp,32
    800025aa:	8082                	ret

00000000800025ac <killed>:

int killed(struct proc *p)
{
    800025ac:	1101                	addi	sp,sp,-32
    800025ae:	ec06                	sd	ra,24(sp)
    800025b0:	e822                	sd	s0,16(sp)
    800025b2:	e426                	sd	s1,8(sp)
    800025b4:	e04a                	sd	s2,0(sp)
    800025b6:	1000                	addi	s0,sp,32
    800025b8:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	71e080e7          	jalr	1822(ra) # 80000cd8 <acquire>
  k = p->killed;
    800025c2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	7c4080e7          	jalr	1988(ra) # 80000d8c <release>
  return k;
}
    800025d0:	854a                	mv	a0,s2
    800025d2:	60e2                	ld	ra,24(sp)
    800025d4:	6442                	ld	s0,16(sp)
    800025d6:	64a2                	ld	s1,8(sp)
    800025d8:	6902                	ld	s2,0(sp)
    800025da:	6105                	addi	sp,sp,32
    800025dc:	8082                	ret

00000000800025de <wait>:
{
    800025de:	715d                	addi	sp,sp,-80
    800025e0:	e486                	sd	ra,72(sp)
    800025e2:	e0a2                	sd	s0,64(sp)
    800025e4:	fc26                	sd	s1,56(sp)
    800025e6:	f84a                	sd	s2,48(sp)
    800025e8:	f44e                	sd	s3,40(sp)
    800025ea:	f052                	sd	s4,32(sp)
    800025ec:	ec56                	sd	s5,24(sp)
    800025ee:	e85a                	sd	s6,16(sp)
    800025f0:	e45e                	sd	s7,8(sp)
    800025f2:	e062                	sd	s8,0(sp)
    800025f4:	0880                	addi	s0,sp,80
    800025f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	644080e7          	jalr	1604(ra) # 80001c3c <myproc>
    80002600:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002602:	0022e517          	auipc	a0,0x22e
    80002606:	57e50513          	addi	a0,a0,1406 # 80230b80 <wait_lock>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	6ce080e7          	jalr	1742(ra) # 80000cd8 <acquire>
    havekids = 0;
    80002612:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002614:	4a15                	li	s4,5
        havekids = 1;
    80002616:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002618:	00234997          	auipc	s3,0x234
    8000261c:	78098993          	addi	s3,s3,1920 # 80236d98 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002620:	0022ec17          	auipc	s8,0x22e
    80002624:	560c0c13          	addi	s8,s8,1376 # 80230b80 <wait_lock>
    havekids = 0;
    80002628:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000262a:	0022f497          	auipc	s1,0x22f
    8000262e:	96e48493          	addi	s1,s1,-1682 # 80230f98 <proc>
    80002632:	a0bd                	j	800026a0 <wait+0xc2>
          pid = pp->pid;
    80002634:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002638:	000b0e63          	beqz	s6,80002654 <wait+0x76>
    8000263c:	4691                	li	a3,4
    8000263e:	02c48613          	addi	a2,s1,44
    80002642:	85da                	mv	a1,s6
    80002644:	05093503          	ld	a0,80(s2)
    80002648:	fffff097          	auipc	ra,0xfffff
    8000264c:	210080e7          	jalr	528(ra) # 80001858 <copyout>
    80002650:	02054563          	bltz	a0,8000267a <wait+0x9c>
          freeproc(pp);
    80002654:	8526                	mv	a0,s1
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	798080e7          	jalr	1944(ra) # 80001dee <freeproc>
          release(&pp->lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	72c080e7          	jalr	1836(ra) # 80000d8c <release>
          release(&wait_lock);
    80002668:	0022e517          	auipc	a0,0x22e
    8000266c:	51850513          	addi	a0,a0,1304 # 80230b80 <wait_lock>
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	71c080e7          	jalr	1820(ra) # 80000d8c <release>
          return pid;
    80002678:	a0b5                	j	800026e4 <wait+0x106>
            release(&pp->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	710080e7          	jalr	1808(ra) # 80000d8c <release>
            release(&wait_lock);
    80002684:	0022e517          	auipc	a0,0x22e
    80002688:	4fc50513          	addi	a0,a0,1276 # 80230b80 <wait_lock>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	700080e7          	jalr	1792(ra) # 80000d8c <release>
            return -1;
    80002694:	59fd                	li	s3,-1
    80002696:	a0b9                	j	800026e4 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002698:	17848493          	addi	s1,s1,376
    8000269c:	03348463          	beq	s1,s3,800026c4 <wait+0xe6>
      if (pp->parent == p)
    800026a0:	7c9c                	ld	a5,56(s1)
    800026a2:	ff279be3          	bne	a5,s2,80002698 <wait+0xba>
        acquire(&pp->lock);
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	630080e7          	jalr	1584(ra) # 80000cd8 <acquire>
        if (pp->state == ZOMBIE)
    800026b0:	4c9c                	lw	a5,24(s1)
    800026b2:	f94781e3          	beq	a5,s4,80002634 <wait+0x56>
        release(&pp->lock);
    800026b6:	8526                	mv	a0,s1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	6d4080e7          	jalr	1748(ra) # 80000d8c <release>
        havekids = 1;
    800026c0:	8756                	mv	a4,s5
    800026c2:	bfd9                	j	80002698 <wait+0xba>
    if (!havekids || killed(p))
    800026c4:	c719                	beqz	a4,800026d2 <wait+0xf4>
    800026c6:	854a                	mv	a0,s2
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	ee4080e7          	jalr	-284(ra) # 800025ac <killed>
    800026d0:	c51d                	beqz	a0,800026fe <wait+0x120>
      release(&wait_lock);
    800026d2:	0022e517          	auipc	a0,0x22e
    800026d6:	4ae50513          	addi	a0,a0,1198 # 80230b80 <wait_lock>
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	6b2080e7          	jalr	1714(ra) # 80000d8c <release>
      return -1;
    800026e2:	59fd                	li	s3,-1
}
    800026e4:	854e                	mv	a0,s3
    800026e6:	60a6                	ld	ra,72(sp)
    800026e8:	6406                	ld	s0,64(sp)
    800026ea:	74e2                	ld	s1,56(sp)
    800026ec:	7942                	ld	s2,48(sp)
    800026ee:	79a2                	ld	s3,40(sp)
    800026f0:	7a02                	ld	s4,32(sp)
    800026f2:	6ae2                	ld	s5,24(sp)
    800026f4:	6b42                	ld	s6,16(sp)
    800026f6:	6ba2                	ld	s7,8(sp)
    800026f8:	6c02                	ld	s8,0(sp)
    800026fa:	6161                	addi	sp,sp,80
    800026fc:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026fe:	85e2                	mv	a1,s8
    80002700:	854a                	mv	a0,s2
    80002702:	00000097          	auipc	ra,0x0
    80002706:	bf6080e7          	jalr	-1034(ra) # 800022f8 <sleep>
    havekids = 0;
    8000270a:	bf39                	j	80002628 <wait+0x4a>

000000008000270c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000270c:	7179                	addi	sp,sp,-48
    8000270e:	f406                	sd	ra,40(sp)
    80002710:	f022                	sd	s0,32(sp)
    80002712:	ec26                	sd	s1,24(sp)
    80002714:	e84a                	sd	s2,16(sp)
    80002716:	e44e                	sd	s3,8(sp)
    80002718:	e052                	sd	s4,0(sp)
    8000271a:	1800                	addi	s0,sp,48
    8000271c:	84aa                	mv	s1,a0
    8000271e:	892e                	mv	s2,a1
    80002720:	89b2                	mv	s3,a2
    80002722:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	518080e7          	jalr	1304(ra) # 80001c3c <myproc>
  if (user_dst)
    8000272c:	c08d                	beqz	s1,8000274e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000272e:	86d2                	mv	a3,s4
    80002730:	864e                	mv	a2,s3
    80002732:	85ca                	mv	a1,s2
    80002734:	6928                	ld	a0,80(a0)
    80002736:	fffff097          	auipc	ra,0xfffff
    8000273a:	122080e7          	jalr	290(ra) # 80001858 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000273e:	70a2                	ld	ra,40(sp)
    80002740:	7402                	ld	s0,32(sp)
    80002742:	64e2                	ld	s1,24(sp)
    80002744:	6942                	ld	s2,16(sp)
    80002746:	69a2                	ld	s3,8(sp)
    80002748:	6a02                	ld	s4,0(sp)
    8000274a:	6145                	addi	sp,sp,48
    8000274c:	8082                	ret
    memmove((char *)dst, src, len);
    8000274e:	000a061b          	sext.w	a2,s4
    80002752:	85ce                	mv	a1,s3
    80002754:	854a                	mv	a0,s2
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	6da080e7          	jalr	1754(ra) # 80000e30 <memmove>
    return 0;
    8000275e:	8526                	mv	a0,s1
    80002760:	bff9                	j	8000273e <either_copyout+0x32>

0000000080002762 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002762:	7179                	addi	sp,sp,-48
    80002764:	f406                	sd	ra,40(sp)
    80002766:	f022                	sd	s0,32(sp)
    80002768:	ec26                	sd	s1,24(sp)
    8000276a:	e84a                	sd	s2,16(sp)
    8000276c:	e44e                	sd	s3,8(sp)
    8000276e:	e052                	sd	s4,0(sp)
    80002770:	1800                	addi	s0,sp,48
    80002772:	892a                	mv	s2,a0
    80002774:	84ae                	mv	s1,a1
    80002776:	89b2                	mv	s3,a2
    80002778:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	4c2080e7          	jalr	1218(ra) # 80001c3c <myproc>
  if (user_src)
    80002782:	c08d                	beqz	s1,800027a4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002784:	86d2                	mv	a3,s4
    80002786:	864e                	mv	a2,s3
    80002788:	85ca                	mv	a1,s2
    8000278a:	6928                	ld	a0,80(a0)
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	1f8080e7          	jalr	504(ra) # 80001984 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002794:	70a2                	ld	ra,40(sp)
    80002796:	7402                	ld	s0,32(sp)
    80002798:	64e2                	ld	s1,24(sp)
    8000279a:	6942                	ld	s2,16(sp)
    8000279c:	69a2                	ld	s3,8(sp)
    8000279e:	6a02                	ld	s4,0(sp)
    800027a0:	6145                	addi	sp,sp,48
    800027a2:	8082                	ret
    memmove(dst, (char *)src, len);
    800027a4:	000a061b          	sext.w	a2,s4
    800027a8:	85ce                	mv	a1,s3
    800027aa:	854a                	mv	a0,s2
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	684080e7          	jalr	1668(ra) # 80000e30 <memmove>
    return 0;
    800027b4:	8526                	mv	a0,s1
    800027b6:	bff9                	j	80002794 <either_copyin+0x32>

00000000800027b8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027b8:	715d                	addi	sp,sp,-80
    800027ba:	e486                	sd	ra,72(sp)
    800027bc:	e0a2                	sd	s0,64(sp)
    800027be:	fc26                	sd	s1,56(sp)
    800027c0:	f84a                	sd	s2,48(sp)
    800027c2:	f44e                	sd	s3,40(sp)
    800027c4:	f052                	sd	s4,32(sp)
    800027c6:	ec56                	sd	s5,24(sp)
    800027c8:	e85a                	sd	s6,16(sp)
    800027ca:	e45e                	sd	s7,8(sp)
    800027cc:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027ce:	00006517          	auipc	a0,0x6
    800027d2:	90a50513          	addi	a0,a0,-1782 # 800080d8 <digits+0x98>
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	db2080e7          	jalr	-590(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027de:	0022f497          	auipc	s1,0x22f
    800027e2:	91248493          	addi	s1,s1,-1774 # 802310f0 <proc+0x158>
    800027e6:	00234917          	auipc	s2,0x234
    800027ea:	70a90913          	addi	s2,s2,1802 # 80236ef0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ee:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027f0:	00006997          	auipc	s3,0x6
    800027f4:	aa098993          	addi	s3,s3,-1376 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800027f8:	00006a97          	auipc	s5,0x6
    800027fc:	aa0a8a93          	addi	s5,s5,-1376 # 80008298 <digits+0x258>
    printf("\n");
    80002800:	00006a17          	auipc	s4,0x6
    80002804:	8d8a0a13          	addi	s4,s4,-1832 # 800080d8 <digits+0x98>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002808:	00006b97          	auipc	s7,0x6
    8000280c:	ad0b8b93          	addi	s7,s7,-1328 # 800082d8 <states.0>
    80002810:	a00d                	j	80002832 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002812:	ed86a583          	lw	a1,-296(a3)
    80002816:	8556                	mv	a0,s5
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	d70080e7          	jalr	-656(ra) # 80000588 <printf>
    printf("\n");
    80002820:	8552                	mv	a0,s4
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	d66080e7          	jalr	-666(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000282a:	17848493          	addi	s1,s1,376
    8000282e:	03248163          	beq	s1,s2,80002850 <procdump+0x98>
    if (p->state == UNUSED)
    80002832:	86a6                	mv	a3,s1
    80002834:	ec04a783          	lw	a5,-320(s1)
    80002838:	dbed                	beqz	a5,8000282a <procdump+0x72>
      state = "???";
    8000283a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000283c:	fcfb6be3          	bltu	s6,a5,80002812 <procdump+0x5a>
    80002840:	1782                	slli	a5,a5,0x20
    80002842:	9381                	srli	a5,a5,0x20
    80002844:	078e                	slli	a5,a5,0x3
    80002846:	97de                	add	a5,a5,s7
    80002848:	6390                	ld	a2,0(a5)
    8000284a:	f661                	bnez	a2,80002812 <procdump+0x5a>
      state = "???";
    8000284c:	864e                	mv	a2,s3
    8000284e:	b7d1                	j	80002812 <procdump+0x5a>
  }
}
    80002850:	60a6                	ld	ra,72(sp)
    80002852:	6406                	ld	s0,64(sp)
    80002854:	74e2                	ld	s1,56(sp)
    80002856:	7942                	ld	s2,48(sp)
    80002858:	79a2                	ld	s3,40(sp)
    8000285a:	7a02                	ld	s4,32(sp)
    8000285c:	6ae2                	ld	s5,24(sp)
    8000285e:	6b42                	ld	s6,16(sp)
    80002860:	6ba2                	ld	s7,8(sp)
    80002862:	6161                	addi	sp,sp,80
    80002864:	8082                	ret

0000000080002866 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002866:	711d                	addi	sp,sp,-96
    80002868:	ec86                	sd	ra,88(sp)
    8000286a:	e8a2                	sd	s0,80(sp)
    8000286c:	e4a6                	sd	s1,72(sp)
    8000286e:	e0ca                	sd	s2,64(sp)
    80002870:	fc4e                	sd	s3,56(sp)
    80002872:	f852                	sd	s4,48(sp)
    80002874:	f456                	sd	s5,40(sp)
    80002876:	f05a                	sd	s6,32(sp)
    80002878:	ec5e                	sd	s7,24(sp)
    8000287a:	e862                	sd	s8,16(sp)
    8000287c:	e466                	sd	s9,8(sp)
    8000287e:	e06a                	sd	s10,0(sp)
    80002880:	1080                	addi	s0,sp,96
    80002882:	8b2a                	mv	s6,a0
    80002884:	8bae                	mv	s7,a1
    80002886:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	3b4080e7          	jalr	948(ra) # 80001c3c <myproc>
    80002890:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002892:	0022e517          	auipc	a0,0x22e
    80002896:	2ee50513          	addi	a0,a0,750 # 80230b80 <wait_lock>
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	43e080e7          	jalr	1086(ra) # 80000cd8 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800028a2:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800028a4:	4a15                	li	s4,5
        havekids = 1;
    800028a6:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800028a8:	00234997          	auipc	s3,0x234
    800028ac:	4f098993          	addi	s3,s3,1264 # 80236d98 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028b0:	0022ed17          	auipc	s10,0x22e
    800028b4:	2d0d0d13          	addi	s10,s10,720 # 80230b80 <wait_lock>
    havekids = 0;
    800028b8:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800028ba:	0022e497          	auipc	s1,0x22e
    800028be:	6de48493          	addi	s1,s1,1758 # 80230f98 <proc>
    800028c2:	a059                	j	80002948 <waitx+0xe2>
          pid = np->pid;
    800028c4:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800028c8:	1684a703          	lw	a4,360(s1)
    800028cc:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800028d0:	16c4a783          	lw	a5,364(s1)
    800028d4:	9f3d                	addw	a4,a4,a5
    800028d6:	1704a783          	lw	a5,368(s1)
    800028da:	9f99                	subw	a5,a5,a4
    800028dc:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028e0:	000b0e63          	beqz	s6,800028fc <waitx+0x96>
    800028e4:	4691                	li	a3,4
    800028e6:	02c48613          	addi	a2,s1,44
    800028ea:	85da                	mv	a1,s6
    800028ec:	05093503          	ld	a0,80(s2)
    800028f0:	fffff097          	auipc	ra,0xfffff
    800028f4:	f68080e7          	jalr	-152(ra) # 80001858 <copyout>
    800028f8:	02054563          	bltz	a0,80002922 <waitx+0xbc>
          freeproc(np);
    800028fc:	8526                	mv	a0,s1
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	4f0080e7          	jalr	1264(ra) # 80001dee <freeproc>
          release(&np->lock);
    80002906:	8526                	mv	a0,s1
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	484080e7          	jalr	1156(ra) # 80000d8c <release>
          release(&wait_lock);
    80002910:	0022e517          	auipc	a0,0x22e
    80002914:	27050513          	addi	a0,a0,624 # 80230b80 <wait_lock>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	474080e7          	jalr	1140(ra) # 80000d8c <release>
          return pid;
    80002920:	a09d                	j	80002986 <waitx+0x120>
            release(&np->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	468080e7          	jalr	1128(ra) # 80000d8c <release>
            release(&wait_lock);
    8000292c:	0022e517          	auipc	a0,0x22e
    80002930:	25450513          	addi	a0,a0,596 # 80230b80 <wait_lock>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	458080e7          	jalr	1112(ra) # 80000d8c <release>
            return -1;
    8000293c:	59fd                	li	s3,-1
    8000293e:	a0a1                	j	80002986 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002940:	17848493          	addi	s1,s1,376
    80002944:	03348463          	beq	s1,s3,8000296c <waitx+0x106>
      if (np->parent == p)
    80002948:	7c9c                	ld	a5,56(s1)
    8000294a:	ff279be3          	bne	a5,s2,80002940 <waitx+0xda>
        acquire(&np->lock);
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	388080e7          	jalr	904(ra) # 80000cd8 <acquire>
        if (np->state == ZOMBIE)
    80002958:	4c9c                	lw	a5,24(s1)
    8000295a:	f74785e3          	beq	a5,s4,800028c4 <waitx+0x5e>
        release(&np->lock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	42c080e7          	jalr	1068(ra) # 80000d8c <release>
        havekids = 1;
    80002968:	8756                	mv	a4,s5
    8000296a:	bfd9                	j	80002940 <waitx+0xda>
    if (!havekids || p->killed)
    8000296c:	c701                	beqz	a4,80002974 <waitx+0x10e>
    8000296e:	02892783          	lw	a5,40(s2)
    80002972:	cb8d                	beqz	a5,800029a4 <waitx+0x13e>
      release(&wait_lock);
    80002974:	0022e517          	auipc	a0,0x22e
    80002978:	20c50513          	addi	a0,a0,524 # 80230b80 <wait_lock>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	410080e7          	jalr	1040(ra) # 80000d8c <release>
      return -1;
    80002984:	59fd                	li	s3,-1
  }
}
    80002986:	854e                	mv	a0,s3
    80002988:	60e6                	ld	ra,88(sp)
    8000298a:	6446                	ld	s0,80(sp)
    8000298c:	64a6                	ld	s1,72(sp)
    8000298e:	6906                	ld	s2,64(sp)
    80002990:	79e2                	ld	s3,56(sp)
    80002992:	7a42                	ld	s4,48(sp)
    80002994:	7aa2                	ld	s5,40(sp)
    80002996:	7b02                	ld	s6,32(sp)
    80002998:	6be2                	ld	s7,24(sp)
    8000299a:	6c42                	ld	s8,16(sp)
    8000299c:	6ca2                	ld	s9,8(sp)
    8000299e:	6d02                	ld	s10,0(sp)
    800029a0:	6125                	addi	sp,sp,96
    800029a2:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029a4:	85ea                	mv	a1,s10
    800029a6:	854a                	mv	a0,s2
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	950080e7          	jalr	-1712(ra) # 800022f8 <sleep>
    havekids = 0;
    800029b0:	b721                	j	800028b8 <waitx+0x52>

00000000800029b2 <update_time>:

void update_time()
{
    800029b2:	7179                	addi	sp,sp,-48
    800029b4:	f406                	sd	ra,40(sp)
    800029b6:	f022                	sd	s0,32(sp)
    800029b8:	ec26                	sd	s1,24(sp)
    800029ba:	e84a                	sd	s2,16(sp)
    800029bc:	e44e                	sd	s3,8(sp)
    800029be:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800029c0:	0022e497          	auipc	s1,0x22e
    800029c4:	5d848493          	addi	s1,s1,1496 # 80230f98 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800029c8:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800029ca:	00234917          	auipc	s2,0x234
    800029ce:	3ce90913          	addi	s2,s2,974 # 80236d98 <tickslock>
    800029d2:	a811                	j	800029e6 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800029d4:	8526                	mv	a0,s1
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	3b6080e7          	jalr	950(ra) # 80000d8c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800029de:	17848493          	addi	s1,s1,376
    800029e2:	03248063          	beq	s1,s2,80002a02 <update_time+0x50>
    acquire(&p->lock);
    800029e6:	8526                	mv	a0,s1
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	2f0080e7          	jalr	752(ra) # 80000cd8 <acquire>
    if (p->state == RUNNING)
    800029f0:	4c9c                	lw	a5,24(s1)
    800029f2:	ff3791e3          	bne	a5,s3,800029d4 <update_time+0x22>
      p->rtime++;
    800029f6:	1684a783          	lw	a5,360(s1)
    800029fa:	2785                	addiw	a5,a5,1
    800029fc:	16f4a423          	sw	a5,360(s1)
    80002a00:	bfd1                	j	800029d4 <update_time+0x22>
  }
    80002a02:	70a2                	ld	ra,40(sp)
    80002a04:	7402                	ld	s0,32(sp)
    80002a06:	64e2                	ld	s1,24(sp)
    80002a08:	6942                	ld	s2,16(sp)
    80002a0a:	69a2                	ld	s3,8(sp)
    80002a0c:	6145                	addi	sp,sp,48
    80002a0e:	8082                	ret

0000000080002a10 <swtch>:
    80002a10:	00153023          	sd	ra,0(a0)
    80002a14:	00253423          	sd	sp,8(a0)
    80002a18:	e900                	sd	s0,16(a0)
    80002a1a:	ed04                	sd	s1,24(a0)
    80002a1c:	03253023          	sd	s2,32(a0)
    80002a20:	03353423          	sd	s3,40(a0)
    80002a24:	03453823          	sd	s4,48(a0)
    80002a28:	03553c23          	sd	s5,56(a0)
    80002a2c:	05653023          	sd	s6,64(a0)
    80002a30:	05753423          	sd	s7,72(a0)
    80002a34:	05853823          	sd	s8,80(a0)
    80002a38:	05953c23          	sd	s9,88(a0)
    80002a3c:	07a53023          	sd	s10,96(a0)
    80002a40:	07b53423          	sd	s11,104(a0)
    80002a44:	0005b083          	ld	ra,0(a1)
    80002a48:	0085b103          	ld	sp,8(a1)
    80002a4c:	6980                	ld	s0,16(a1)
    80002a4e:	6d84                	ld	s1,24(a1)
    80002a50:	0205b903          	ld	s2,32(a1)
    80002a54:	0285b983          	ld	s3,40(a1)
    80002a58:	0305ba03          	ld	s4,48(a1)
    80002a5c:	0385ba83          	ld	s5,56(a1)
    80002a60:	0405bb03          	ld	s6,64(a1)
    80002a64:	0485bb83          	ld	s7,72(a1)
    80002a68:	0505bc03          	ld	s8,80(a1)
    80002a6c:	0585bc83          	ld	s9,88(a1)
    80002a70:	0605bd03          	ld	s10,96(a1)
    80002a74:	0685bd83          	ld	s11,104(a1)
    80002a78:	8082                	ret

0000000080002a7a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a7a:	1141                	addi	sp,sp,-16
    80002a7c:	e406                	sd	ra,8(sp)
    80002a7e:	e022                	sd	s0,0(sp)
    80002a80:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a82:	00006597          	auipc	a1,0x6
    80002a86:	88658593          	addi	a1,a1,-1914 # 80008308 <states.0+0x30>
    80002a8a:	00234517          	auipc	a0,0x234
    80002a8e:	30e50513          	addi	a0,a0,782 # 80236d98 <tickslock>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	1b6080e7          	jalr	438(ra) # 80000c48 <initlock>
}
    80002a9a:	60a2                	ld	ra,8(sp)
    80002a9c:	6402                	ld	s0,0(sp)
    80002a9e:	0141                	addi	sp,sp,16
    80002aa0:	8082                	ret

0000000080002aa2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002aa2:	1141                	addi	sp,sp,-16
    80002aa4:	e422                	sd	s0,8(sp)
    80002aa6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aa8:	00003797          	auipc	a5,0x3
    80002aac:	66878793          	addi	a5,a5,1640 # 80006110 <kernelvec>
    80002ab0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ab4:	6422                	ld	s0,8(sp)
    80002ab6:	0141                	addi	sp,sp,16
    80002ab8:	8082                	ret

0000000080002aba <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002aba:	1141                	addi	sp,sp,-16
    80002abc:	e406                	sd	ra,8(sp)
    80002abe:	e022                	sd	s0,0(sp)
    80002ac0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	17a080e7          	jalr	378(ra) # 80001c3c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ace:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ad0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ad4:	00004617          	auipc	a2,0x4
    80002ad8:	52c60613          	addi	a2,a2,1324 # 80007000 <_trampoline>
    80002adc:	00004697          	auipc	a3,0x4
    80002ae0:	52468693          	addi	a3,a3,1316 # 80007000 <_trampoline>
    80002ae4:	8e91                	sub	a3,a3,a2
    80002ae6:	040007b7          	lui	a5,0x4000
    80002aea:	17fd                	addi	a5,a5,-1
    80002aec:	07b2                	slli	a5,a5,0xc
    80002aee:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af0:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002af4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002af6:	180026f3          	csrr	a3,satp
    80002afa:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002afc:	6d38                	ld	a4,88(a0)
    80002afe:	6134                	ld	a3,64(a0)
    80002b00:	6585                	lui	a1,0x1
    80002b02:	96ae                	add	a3,a3,a1
    80002b04:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b06:	6d38                	ld	a4,88(a0)
    80002b08:	00000697          	auipc	a3,0x0
    80002b0c:	13e68693          	addi	a3,a3,318 # 80002c46 <usertrap>
    80002b10:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b12:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b14:	8692                	mv	a3,tp
    80002b16:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b1c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b20:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b24:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b28:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b2a:	6f18                	ld	a4,24(a4)
    80002b2c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b30:	6928                	ld	a0,80(a0)
    80002b32:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b34:	00004717          	auipc	a4,0x4
    80002b38:	56870713          	addi	a4,a4,1384 # 8000709c <userret>
    80002b3c:	8f11                	sub	a4,a4,a2
    80002b3e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b40:	577d                	li	a4,-1
    80002b42:	177e                	slli	a4,a4,0x3f
    80002b44:	8d59                	or	a0,a0,a4
    80002b46:	9782                	jalr	a5
}
    80002b48:	60a2                	ld	ra,8(sp)
    80002b4a:	6402                	ld	s0,0(sp)
    80002b4c:	0141                	addi	sp,sp,16
    80002b4e:	8082                	ret

0000000080002b50 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	e04a                	sd	s2,0(sp)
    80002b5a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b5c:	00234917          	auipc	s2,0x234
    80002b60:	23c90913          	addi	s2,s2,572 # 80236d98 <tickslock>
    80002b64:	854a                	mv	a0,s2
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	172080e7          	jalr	370(ra) # 80000cd8 <acquire>
  ticks++;
    80002b6e:	00006497          	auipc	s1,0x6
    80002b72:	d7a48493          	addi	s1,s1,-646 # 800088e8 <ticks>
    80002b76:	409c                	lw	a5,0(s1)
    80002b78:	2785                	addiw	a5,a5,1
    80002b7a:	c09c                	sw	a5,0(s1)
  update_time();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	e36080e7          	jalr	-458(ra) # 800029b2 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002b84:	8526                	mv	a0,s1
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	7d6080e7          	jalr	2006(ra) # 8000235c <wakeup>
  release(&tickslock);
    80002b8e:	854a                	mv	a0,s2
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	1fc080e7          	jalr	508(ra) # 80000d8c <release>
}
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6902                	ld	s2,0(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002bb2:	00074d63          	bltz	a4,80002bcc <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002bb6:	57fd                	li	a5,-1
    80002bb8:	17fe                	slli	a5,a5,0x3f
    80002bba:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002bbc:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002bbe:	06f70363          	beq	a4,a5,80002c24 <devintr+0x80>
  }
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret
      (scause & 0xff) == 9)
    80002bcc:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002bd0:	46a5                	li	a3,9
    80002bd2:	fed792e3          	bne	a5,a3,80002bb6 <devintr+0x12>
    int irq = plic_claim();
    80002bd6:	00003097          	auipc	ra,0x3
    80002bda:	642080e7          	jalr	1602(ra) # 80006218 <plic_claim>
    80002bde:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002be0:	47a9                	li	a5,10
    80002be2:	02f50763          	beq	a0,a5,80002c10 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002be6:	4785                	li	a5,1
    80002be8:	02f50963          	beq	a0,a5,80002c1a <devintr+0x76>
    return 1;
    80002bec:	4505                	li	a0,1
    else if (irq)
    80002bee:	d8f1                	beqz	s1,80002bc2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bf0:	85a6                	mv	a1,s1
    80002bf2:	00005517          	auipc	a0,0x5
    80002bf6:	71e50513          	addi	a0,a0,1822 # 80008310 <states.0+0x38>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	98e080e7          	jalr	-1650(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c02:	8526                	mv	a0,s1
    80002c04:	00003097          	auipc	ra,0x3
    80002c08:	638080e7          	jalr	1592(ra) # 8000623c <plic_complete>
    return 1;
    80002c0c:	4505                	li	a0,1
    80002c0e:	bf55                	j	80002bc2 <devintr+0x1e>
      uartintr();
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	d8a080e7          	jalr	-630(ra) # 8000099a <uartintr>
    80002c18:	b7ed                	j	80002c02 <devintr+0x5e>
      virtio_disk_intr();
    80002c1a:	00004097          	auipc	ra,0x4
    80002c1e:	aee080e7          	jalr	-1298(ra) # 80006708 <virtio_disk_intr>
    80002c22:	b7c5                	j	80002c02 <devintr+0x5e>
    if (cpuid() == 0)
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	fec080e7          	jalr	-20(ra) # 80001c10 <cpuid>
    80002c2c:	c901                	beqz	a0,80002c3c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c2e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c34:	14479073          	csrw	sip,a5
    return 2;
    80002c38:	4509                	li	a0,2
    80002c3a:	b761                	j	80002bc2 <devintr+0x1e>
      clockintr();
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	f14080e7          	jalr	-236(ra) # 80002b50 <clockintr>
    80002c44:	b7ed                	j	80002c2e <devintr+0x8a>

0000000080002c46 <usertrap>:
{
    80002c46:	7139                	addi	sp,sp,-64
    80002c48:	fc06                	sd	ra,56(sp)
    80002c4a:	f822                	sd	s0,48(sp)
    80002c4c:	f426                	sd	s1,40(sp)
    80002c4e:	f04a                	sd	s2,32(sp)
    80002c50:	ec4e                	sd	s3,24(sp)
    80002c52:	e852                	sd	s4,16(sp)
    80002c54:	e456                	sd	s5,8(sp)
    80002c56:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c58:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c5c:	1007f793          	andi	a5,a5,256
    80002c60:	ebd5                	bnez	a5,80002d14 <usertrap+0xce>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c62:	00003797          	auipc	a5,0x3
    80002c66:	4ae78793          	addi	a5,a5,1198 # 80006110 <kernelvec>
    80002c6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	fce080e7          	jalr	-50(ra) # 80001c3c <myproc>
    80002c76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c78:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7a:	14102773          	csrr	a4,sepc
    80002c7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c80:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c84:	47a1                	li	a5,8
    80002c86:	08f70f63          	beq	a4,a5,80002d24 <usertrap+0xde>
  else if ((which_dev = devintr()) != 0)
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	f1a080e7          	jalr	-230(ra) # 80002ba4 <devintr>
    80002c92:	892a                	mv	s2,a0
    80002c94:	18051363          	bnez	a0,80002e1a <usertrap+0x1d4>
    80002c98:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002c9c:	47bd                	li	a5,15
    80002c9e:	14f71163          	bne	a4,a5,80002de0 <usertrap+0x19a>
    pagetable_t curr_pagetable = p->pagetable;
    80002ca2:	0504b903          	ld	s2,80(s1)
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca6:	14302773          	csrr	a4,stval
    if (r_stval() >= MAXVA)
    80002caa:	57fd                	li	a5,-1
    80002cac:	83e9                	srli	a5,a5,0x1a
    80002cae:	0ce7e763          	bltu	a5,a4,80002d7c <usertrap+0x136>
    80002cb2:	143025f3          	csrr	a1,stval
    pte_t *curr_pte = walk(curr_pagetable, r_stval(), 0);
    80002cb6:	4601                	li	a2,0
    80002cb8:	854a                	mv	a0,s2
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	3fe080e7          	jalr	1022(ra) # 800010b8 <walk>
    80002cc2:	892a                	mv	s2,a0
    uint64 phy_addr = PTE2PA(*curr_pte);
    80002cc4:	00053983          	ld	s3,0(a0)
    if (*curr_pte & PTE_COW)
    80002cc8:	1009f793          	andi	a5,s3,256
    80002ccc:	cfbd                	beqz	a5,80002d4a <usertrap+0x104>
    uint64 phy_addr = PTE2PA(*curr_pte);
    80002cce:	00a9da93          	srli	s5,s3,0xa
    80002cd2:	0ab2                	slli	s5,s5,0xc
      counter++;
    80002cd4:	00006717          	auipc	a4,0x6
    80002cd8:	bfc70713          	addi	a4,a4,-1028 # 800088d0 <counter>
    80002cdc:	431c                	lw	a5,0(a4)
    80002cde:	2785                	addiw	a5,a5,1
    80002ce0:	c31c                	sw	a5,0(a4)
      if (reference_counters[(uint64)phy_addr / PGSIZE] > 1)
    80002ce2:	00aad713          	srli	a4,s5,0xa
    80002ce6:	0000e797          	auipc	a5,0xe
    80002cea:	e8278793          	addi	a5,a5,-382 # 80010b68 <reference_counters>
    80002cee:	97ba                	add	a5,a5,a4
    80002cf0:	439c                	lw	a5,0(a5)
    80002cf2:	4705                	li	a4,1
    80002cf4:	08f74c63          	blt	a4,a5,80002d8c <usertrap+0x146>
      else if (reference_counters[(uint64)phy_addr / PGSIZE] == 1)
    80002cf8:	4705                	li	a4,1
    80002cfa:	04e79863          	bne	a5,a4,80002d4a <usertrap+0x104>
        *curr_pte &= ~PTE_COW;
    80002cfe:	611c                	ld	a5,0(a0)
    80002d00:	eff7f793          	andi	a5,a5,-257
    80002d04:	0047e793          	ori	a5,a5,4
    80002d08:	e11c                	sd	a5,0(a0)
        p->trapframe->epc = r_sepc();
    80002d0a:	6cbc                	ld	a5,88(s1)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d0c:	14102773          	csrr	a4,sepc
    80002d10:	ef98                	sd	a4,24(a5)
    80002d12:	a825                	j	80002d4a <usertrap+0x104>
    panic("usertrap: not from user mode");
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	61c50513          	addi	a0,a0,1564 # 80008330 <states.0+0x58>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	822080e7          	jalr	-2014(ra) # 8000053e <panic>
    if (killed(p))
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	888080e7          	jalr	-1912(ra) # 800025ac <killed>
    80002d2c:	e131                	bnez	a0,80002d70 <usertrap+0x12a>
    p->trapframe->epc += 4;
    80002d2e:	6cb8                	ld	a4,88(s1)
    80002d30:	6f1c                	ld	a5,24(a4)
    80002d32:	0791                	addi	a5,a5,4
    80002d34:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d3a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d3e:	10079073          	csrw	sstatus,a5
    syscall();
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	34c080e7          	jalr	844(ra) # 8000308e <syscall>
  if (killed(p))
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	860080e7          	jalr	-1952(ra) # 800025ac <killed>
    80002d54:	e971                	bnez	a0,80002e28 <usertrap+0x1e2>
  usertrapret();
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	d64080e7          	jalr	-668(ra) # 80002aba <usertrapret>
}
    80002d5e:	70e2                	ld	ra,56(sp)
    80002d60:	7442                	ld	s0,48(sp)
    80002d62:	74a2                	ld	s1,40(sp)
    80002d64:	7902                	ld	s2,32(sp)
    80002d66:	69e2                	ld	s3,24(sp)
    80002d68:	6a42                	ld	s4,16(sp)
    80002d6a:	6aa2                	ld	s5,8(sp)
    80002d6c:	6121                	addi	sp,sp,64
    80002d6e:	8082                	ret
      exit(-1);
    80002d70:	557d                	li	a0,-1
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	6ba080e7          	jalr	1722(ra) # 8000242c <exit>
    80002d7a:	bf55                	j	80002d2e <usertrap+0xe8>
      p->killed = 1;
    80002d7c:	4785                	li	a5,1
    80002d7e:	d49c                	sw	a5,40(s1)
      exit(-1);
    80002d80:	557d                	li	a0,-1
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	6aa080e7          	jalr	1706(ra) # 8000242c <exit>
    80002d8a:	b725                	j	80002cb2 <usertrap+0x6c>
        new_mem = kalloc();
    80002d8c:	ffffe097          	auipc	ra,0xffffe
    80002d90:	e20080e7          	jalr	-480(ra) # 80000bac <kalloc>
    80002d94:	8a2a                	mv	s4,a0
        if (new_mem == 0)
    80002d96:	cd0d                	beqz	a0,80002dd0 <usertrap+0x18a>
        memmove(new_mem, (char *)phy_addr, PGSIZE);
    80002d98:	6605                	lui	a2,0x1
    80002d9a:	85d6                	mv	a1,s5
    80002d9c:	8552                	mv	a0,s4
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	092080e7          	jalr	146(ra) # 80000e30 <memmove>
        *curr_pte = PA2PTE(new_mem) | flags;
    80002da6:	00ca5a13          	srli	s4,s4,0xc
    80002daa:	0a2a                	slli	s4,s4,0xa
    flags &= ~PTE_COW;
    80002dac:	2ff9f993          	andi	s3,s3,767
        *curr_pte = PA2PTE(new_mem) | flags;
    80002db0:	0049e993          	ori	s3,s3,4
    80002db4:	013a69b3          	or	s3,s4,s3
    80002db8:	01393023          	sd	s3,0(s2)
        kfree((char *)phy_addr);
    80002dbc:	8556                	mv	a0,s5
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	c2c080e7          	jalr	-980(ra) # 800009ea <kfree>
        p->trapframe->epc = r_sepc();
    80002dc6:	6cbc                	ld	a5,88(s1)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dc8:	14102773          	csrr	a4,sepc
    80002dcc:	ef98                	sd	a4,24(a5)
    80002dce:	bfb5                	j	80002d4a <usertrap+0x104>
          p->killed = 1;
    80002dd0:	4785                	li	a5,1
    80002dd2:	d49c                	sw	a5,40(s1)
          exit(-1);
    80002dd4:	557d                	li	a0,-1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	656080e7          	jalr	1622(ra) # 8000242c <exit>
    80002dde:	bf6d                	j	80002d98 <usertrap+0x152>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002de4:	5890                	lw	a2,48(s1)
    80002de6:	00005517          	auipc	a0,0x5
    80002dea:	56a50513          	addi	a0,a0,1386 # 80008350 <states.0+0x78>
    80002dee:	ffffd097          	auipc	ra,0xffffd
    80002df2:	79a080e7          	jalr	1946(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dfa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dfe:	00005517          	auipc	a0,0x5
    80002e02:	58250513          	addi	a0,a0,1410 # 80008380 <states.0+0xa8>
    80002e06:	ffffd097          	auipc	ra,0xffffd
    80002e0a:	782080e7          	jalr	1922(ra) # 80000588 <printf>
    setkilled(p);
    80002e0e:	8526                	mv	a0,s1
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	770080e7          	jalr	1904(ra) # 80002580 <setkilled>
    80002e18:	bf0d                	j	80002d4a <usertrap+0x104>
  if (killed(p))
    80002e1a:	8526                	mv	a0,s1
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	790080e7          	jalr	1936(ra) # 800025ac <killed>
    80002e24:	c901                	beqz	a0,80002e34 <usertrap+0x1ee>
    80002e26:	a011                	j	80002e2a <usertrap+0x1e4>
    80002e28:	4901                	li	s2,0
    exit(-1);
    80002e2a:	557d                	li	a0,-1
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	600080e7          	jalr	1536(ra) # 8000242c <exit>
  if (which_dev == 2)
    80002e34:	4789                	li	a5,2
    80002e36:	f2f910e3          	bne	s2,a5,80002d56 <usertrap+0x110>
    yield();
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	482080e7          	jalr	1154(ra) # 800022bc <yield>
    80002e42:	bf11                	j	80002d56 <usertrap+0x110>

0000000080002e44 <kerneltrap>:
{
    80002e44:	7179                	addi	sp,sp,-48
    80002e46:	f406                	sd	ra,40(sp)
    80002e48:	f022                	sd	s0,32(sp)
    80002e4a:	ec26                	sd	s1,24(sp)
    80002e4c:	e84a                	sd	s2,16(sp)
    80002e4e:	e44e                	sd	s3,8(sp)
    80002e50:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e52:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e56:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e5a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002e5e:	1004f793          	andi	a5,s1,256
    80002e62:	cb85                	beqz	a5,80002e92 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e64:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e68:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002e6a:	ef85                	bnez	a5,80002ea2 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	d38080e7          	jalr	-712(ra) # 80002ba4 <devintr>
    80002e74:	cd1d                	beqz	a0,80002eb2 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e76:	4789                	li	a5,2
    80002e78:	06f50a63          	beq	a0,a5,80002eec <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e7c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e80:	10049073          	csrw	sstatus,s1
}
    80002e84:	70a2                	ld	ra,40(sp)
    80002e86:	7402                	ld	s0,32(sp)
    80002e88:	64e2                	ld	s1,24(sp)
    80002e8a:	6942                	ld	s2,16(sp)
    80002e8c:	69a2                	ld	s3,8(sp)
    80002e8e:	6145                	addi	sp,sp,48
    80002e90:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e92:	00005517          	auipc	a0,0x5
    80002e96:	50e50513          	addi	a0,a0,1294 # 800083a0 <states.0+0xc8>
    80002e9a:	ffffd097          	auipc	ra,0xffffd
    80002e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	52650513          	addi	a0,a0,1318 # 800083c8 <states.0+0xf0>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002eb2:	85ce                	mv	a1,s3
    80002eb4:	00005517          	auipc	a0,0x5
    80002eb8:	53450513          	addi	a0,a0,1332 # 800083e8 <states.0+0x110>
    80002ebc:	ffffd097          	auipc	ra,0xffffd
    80002ec0:	6cc080e7          	jalr	1740(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ec8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	52c50513          	addi	a0,a0,1324 # 800083f8 <states.0+0x120>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6b4080e7          	jalr	1716(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	53450513          	addi	a0,a0,1332 # 80008410 <states.0+0x138>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	65a080e7          	jalr	1626(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	d50080e7          	jalr	-688(ra) # 80001c3c <myproc>
    80002ef4:	d541                	beqz	a0,80002e7c <kerneltrap+0x38>
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	d46080e7          	jalr	-698(ra) # 80001c3c <myproc>
    80002efe:	4d18                	lw	a4,24(a0)
    80002f00:	4791                	li	a5,4
    80002f02:	f6f71de3          	bne	a4,a5,80002e7c <kerneltrap+0x38>
    yield();
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	3b6080e7          	jalr	950(ra) # 800022bc <yield>
    80002f0e:	b7bd                	j	80002e7c <kerneltrap+0x38>

0000000080002f10 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	e426                	sd	s1,8(sp)
    80002f18:	1000                	addi	s0,sp,32
    80002f1a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	d20080e7          	jalr	-736(ra) # 80001c3c <myproc>
  switch (n) {
    80002f24:	4795                	li	a5,5
    80002f26:	0497e163          	bltu	a5,s1,80002f68 <argraw+0x58>
    80002f2a:	048a                	slli	s1,s1,0x2
    80002f2c:	00005717          	auipc	a4,0x5
    80002f30:	51c70713          	addi	a4,a4,1308 # 80008448 <states.0+0x170>
    80002f34:	94ba                	add	s1,s1,a4
    80002f36:	409c                	lw	a5,0(s1)
    80002f38:	97ba                	add	a5,a5,a4
    80002f3a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f3c:	6d3c                	ld	a5,88(a0)
    80002f3e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f40:	60e2                	ld	ra,24(sp)
    80002f42:	6442                	ld	s0,16(sp)
    80002f44:	64a2                	ld	s1,8(sp)
    80002f46:	6105                	addi	sp,sp,32
    80002f48:	8082                	ret
    return p->trapframe->a1;
    80002f4a:	6d3c                	ld	a5,88(a0)
    80002f4c:	7fa8                	ld	a0,120(a5)
    80002f4e:	bfcd                	j	80002f40 <argraw+0x30>
    return p->trapframe->a2;
    80002f50:	6d3c                	ld	a5,88(a0)
    80002f52:	63c8                	ld	a0,128(a5)
    80002f54:	b7f5                	j	80002f40 <argraw+0x30>
    return p->trapframe->a3;
    80002f56:	6d3c                	ld	a5,88(a0)
    80002f58:	67c8                	ld	a0,136(a5)
    80002f5a:	b7dd                	j	80002f40 <argraw+0x30>
    return p->trapframe->a4;
    80002f5c:	6d3c                	ld	a5,88(a0)
    80002f5e:	6bc8                	ld	a0,144(a5)
    80002f60:	b7c5                	j	80002f40 <argraw+0x30>
    return p->trapframe->a5;
    80002f62:	6d3c                	ld	a5,88(a0)
    80002f64:	6fc8                	ld	a0,152(a5)
    80002f66:	bfe9                	j	80002f40 <argraw+0x30>
  panic("argraw");
    80002f68:	00005517          	auipc	a0,0x5
    80002f6c:	4b850513          	addi	a0,a0,1208 # 80008420 <states.0+0x148>
    80002f70:	ffffd097          	auipc	ra,0xffffd
    80002f74:	5ce080e7          	jalr	1486(ra) # 8000053e <panic>

0000000080002f78 <fetchaddr>:
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	e426                	sd	s1,8(sp)
    80002f80:	e04a                	sd	s2,0(sp)
    80002f82:	1000                	addi	s0,sp,32
    80002f84:	84aa                	mv	s1,a0
    80002f86:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	cb4080e7          	jalr	-844(ra) # 80001c3c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f90:	653c                	ld	a5,72(a0)
    80002f92:	02f4f863          	bgeu	s1,a5,80002fc2 <fetchaddr+0x4a>
    80002f96:	00848713          	addi	a4,s1,8
    80002f9a:	02e7e663          	bltu	a5,a4,80002fc6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f9e:	46a1                	li	a3,8
    80002fa0:	8626                	mv	a2,s1
    80002fa2:	85ca                	mv	a1,s2
    80002fa4:	6928                	ld	a0,80(a0)
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	9de080e7          	jalr	-1570(ra) # 80001984 <copyin>
    80002fae:	00a03533          	snez	a0,a0
    80002fb2:	40a00533          	neg	a0,a0
}
    80002fb6:	60e2                	ld	ra,24(sp)
    80002fb8:	6442                	ld	s0,16(sp)
    80002fba:	64a2                	ld	s1,8(sp)
    80002fbc:	6902                	ld	s2,0(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret
    return -1;
    80002fc2:	557d                	li	a0,-1
    80002fc4:	bfcd                	j	80002fb6 <fetchaddr+0x3e>
    80002fc6:	557d                	li	a0,-1
    80002fc8:	b7fd                	j	80002fb6 <fetchaddr+0x3e>

0000000080002fca <fetchstr>:
{
    80002fca:	7179                	addi	sp,sp,-48
    80002fcc:	f406                	sd	ra,40(sp)
    80002fce:	f022                	sd	s0,32(sp)
    80002fd0:	ec26                	sd	s1,24(sp)
    80002fd2:	e84a                	sd	s2,16(sp)
    80002fd4:	e44e                	sd	s3,8(sp)
    80002fd6:	1800                	addi	s0,sp,48
    80002fd8:	892a                	mv	s2,a0
    80002fda:	84ae                	mv	s1,a1
    80002fdc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	c5e080e7          	jalr	-930(ra) # 80001c3c <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fe6:	86ce                	mv	a3,s3
    80002fe8:	864a                	mv	a2,s2
    80002fea:	85a6                	mv	a1,s1
    80002fec:	6928                	ld	a0,80(a0)
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	a24080e7          	jalr	-1500(ra) # 80001a12 <copyinstr>
    80002ff6:	00054e63          	bltz	a0,80003012 <fetchstr+0x48>
  return strlen(buf);
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	f54080e7          	jalr	-172(ra) # 80000f50 <strlen>
}
    80003004:	70a2                	ld	ra,40(sp)
    80003006:	7402                	ld	s0,32(sp)
    80003008:	64e2                	ld	s1,24(sp)
    8000300a:	6942                	ld	s2,16(sp)
    8000300c:	69a2                	ld	s3,8(sp)
    8000300e:	6145                	addi	sp,sp,48
    80003010:	8082                	ret
    return -1;
    80003012:	557d                	li	a0,-1
    80003014:	bfc5                	j	80003004 <fetchstr+0x3a>

0000000080003016 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003022:	00000097          	auipc	ra,0x0
    80003026:	eee080e7          	jalr	-274(ra) # 80002f10 <argraw>
    8000302a:	c088                	sw	a0,0(s1)
}
    8000302c:	60e2                	ld	ra,24(sp)
    8000302e:	6442                	ld	s0,16(sp)
    80003030:	64a2                	ld	s1,8(sp)
    80003032:	6105                	addi	sp,sp,32
    80003034:	8082                	ret

0000000080003036 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003036:	1101                	addi	sp,sp,-32
    80003038:	ec06                	sd	ra,24(sp)
    8000303a:	e822                	sd	s0,16(sp)
    8000303c:	e426                	sd	s1,8(sp)
    8000303e:	1000                	addi	s0,sp,32
    80003040:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003042:	00000097          	auipc	ra,0x0
    80003046:	ece080e7          	jalr	-306(ra) # 80002f10 <argraw>
    8000304a:	e088                	sd	a0,0(s1)
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret

0000000080003056 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003056:	7179                	addi	sp,sp,-48
    80003058:	f406                	sd	ra,40(sp)
    8000305a:	f022                	sd	s0,32(sp)
    8000305c:	ec26                	sd	s1,24(sp)
    8000305e:	e84a                	sd	s2,16(sp)
    80003060:	1800                	addi	s0,sp,48
    80003062:	84ae                	mv	s1,a1
    80003064:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003066:	fd840593          	addi	a1,s0,-40
    8000306a:	00000097          	auipc	ra,0x0
    8000306e:	fcc080e7          	jalr	-52(ra) # 80003036 <argaddr>
  return fetchstr(addr, buf, max);
    80003072:	864a                	mv	a2,s2
    80003074:	85a6                	mv	a1,s1
    80003076:	fd843503          	ld	a0,-40(s0)
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	f50080e7          	jalr	-176(ra) # 80002fca <fetchstr>
}
    80003082:	70a2                	ld	ra,40(sp)
    80003084:	7402                	ld	s0,32(sp)
    80003086:	64e2                	ld	s1,24(sp)
    80003088:	6942                	ld	s2,16(sp)
    8000308a:	6145                	addi	sp,sp,48
    8000308c:	8082                	ret

000000008000308e <syscall>:
[SYS_counter] sys_counter,
};

void
syscall(void)
{
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	e426                	sd	s1,8(sp)
    80003096:	e04a                	sd	s2,0(sp)
    80003098:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	ba2080e7          	jalr	-1118(ra) # 80001c3c <myproc>
    800030a2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030a4:	05853903          	ld	s2,88(a0)
    800030a8:	0a893783          	ld	a5,168(s2)
    800030ac:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030b0:	37fd                	addiw	a5,a5,-1
    800030b2:	4759                	li	a4,22
    800030b4:	00f76f63          	bltu	a4,a5,800030d2 <syscall+0x44>
    800030b8:	00369713          	slli	a4,a3,0x3
    800030bc:	00005797          	auipc	a5,0x5
    800030c0:	3a478793          	addi	a5,a5,932 # 80008460 <syscalls>
    800030c4:	97ba                	add	a5,a5,a4
    800030c6:	639c                	ld	a5,0(a5)
    800030c8:	c789                	beqz	a5,800030d2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800030ca:	9782                	jalr	a5
    800030cc:	06a93823          	sd	a0,112(s2)
    800030d0:	a839                	j	800030ee <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030d2:	15848613          	addi	a2,s1,344
    800030d6:	588c                	lw	a1,48(s1)
    800030d8:	00005517          	auipc	a0,0x5
    800030dc:	35050513          	addi	a0,a0,848 # 80008428 <states.0+0x150>
    800030e0:	ffffd097          	auipc	ra,0xffffd
    800030e4:	4a8080e7          	jalr	1192(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030e8:	6cbc                	ld	a5,88(s1)
    800030ea:	577d                	li	a4,-1
    800030ec:	fbb8                	sd	a4,112(a5)
  }
}
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	64a2                	ld	s1,8(sp)
    800030f4:	6902                	ld	s2,0(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret

00000000800030fa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030fa:	1101                	addi	sp,sp,-32
    800030fc:	ec06                	sd	ra,24(sp)
    800030fe:	e822                	sd	s0,16(sp)
    80003100:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003102:	fec40593          	addi	a1,s0,-20
    80003106:	4501                	li	a0,0
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	f0e080e7          	jalr	-242(ra) # 80003016 <argint>
  exit(n);
    80003110:	fec42503          	lw	a0,-20(s0)
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	318080e7          	jalr	792(ra) # 8000242c <exit>
  return 0; // not reached
}
    8000311c:	4501                	li	a0,0
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret

0000000080003126 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003126:	1141                	addi	sp,sp,-16
    80003128:	e406                	sd	ra,8(sp)
    8000312a:	e022                	sd	s0,0(sp)
    8000312c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	b0e080e7          	jalr	-1266(ra) # 80001c3c <myproc>
}
    80003136:	5908                	lw	a0,48(a0)
    80003138:	60a2                	ld	ra,8(sp)
    8000313a:	6402                	ld	s0,0(sp)
    8000313c:	0141                	addi	sp,sp,16
    8000313e:	8082                	ret

0000000080003140 <sys_fork>:

uint64
sys_fork(void)
{
    80003140:	1141                	addi	sp,sp,-16
    80003142:	e406                	sd	ra,8(sp)
    80003144:	e022                	sd	s0,0(sp)
    80003146:	0800                	addi	s0,sp,16
  return fork();
    80003148:	fffff097          	auipc	ra,0xfffff
    8000314c:	ebe080e7          	jalr	-322(ra) # 80002006 <fork>
}
    80003150:	60a2                	ld	ra,8(sp)
    80003152:	6402                	ld	s0,0(sp)
    80003154:	0141                	addi	sp,sp,16
    80003156:	8082                	ret

0000000080003158 <sys_wait>:

uint64
sys_wait(void)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003160:	fe840593          	addi	a1,s0,-24
    80003164:	4501                	li	a0,0
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	ed0080e7          	jalr	-304(ra) # 80003036 <argaddr>
  return wait(p);
    8000316e:	fe843503          	ld	a0,-24(s0)
    80003172:	fffff097          	auipc	ra,0xfffff
    80003176:	46c080e7          	jalr	1132(ra) # 800025de <wait>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	6105                	addi	sp,sp,32
    80003180:	8082                	ret

0000000080003182 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003182:	7179                	addi	sp,sp,-48
    80003184:	f406                	sd	ra,40(sp)
    80003186:	f022                	sd	s0,32(sp)
    80003188:	ec26                	sd	s1,24(sp)
    8000318a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000318c:	fdc40593          	addi	a1,s0,-36
    80003190:	4501                	li	a0,0
    80003192:	00000097          	auipc	ra,0x0
    80003196:	e84080e7          	jalr	-380(ra) # 80003016 <argint>
  addr = myproc()->sz;
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	aa2080e7          	jalr	-1374(ra) # 80001c3c <myproc>
    800031a2:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800031a4:	fdc42503          	lw	a0,-36(s0)
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	e02080e7          	jalr	-510(ra) # 80001faa <growproc>
    800031b0:	00054863          	bltz	a0,800031c0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800031b4:	8526                	mv	a0,s1
    800031b6:	70a2                	ld	ra,40(sp)
    800031b8:	7402                	ld	s0,32(sp)
    800031ba:	64e2                	ld	s1,24(sp)
    800031bc:	6145                	addi	sp,sp,48
    800031be:	8082                	ret
    return -1;
    800031c0:	54fd                	li	s1,-1
    800031c2:	bfcd                	j	800031b4 <sys_sbrk+0x32>

00000000800031c4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031c4:	7139                	addi	sp,sp,-64
    800031c6:	fc06                	sd	ra,56(sp)
    800031c8:	f822                	sd	s0,48(sp)
    800031ca:	f426                	sd	s1,40(sp)
    800031cc:	f04a                	sd	s2,32(sp)
    800031ce:	ec4e                	sd	s3,24(sp)
    800031d0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800031d2:	fcc40593          	addi	a1,s0,-52
    800031d6:	4501                	li	a0,0
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	e3e080e7          	jalr	-450(ra) # 80003016 <argint>
  acquire(&tickslock);
    800031e0:	00234517          	auipc	a0,0x234
    800031e4:	bb850513          	addi	a0,a0,-1096 # 80236d98 <tickslock>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	af0080e7          	jalr	-1296(ra) # 80000cd8 <acquire>
  ticks0 = ticks;
    800031f0:	00005917          	auipc	s2,0x5
    800031f4:	6f892903          	lw	s2,1784(s2) # 800088e8 <ticks>
  while (ticks - ticks0 < n)
    800031f8:	fcc42783          	lw	a5,-52(s0)
    800031fc:	cf9d                	beqz	a5,8000323a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031fe:	00234997          	auipc	s3,0x234
    80003202:	b9a98993          	addi	s3,s3,-1126 # 80236d98 <tickslock>
    80003206:	00005497          	auipc	s1,0x5
    8000320a:	6e248493          	addi	s1,s1,1762 # 800088e8 <ticks>
    if (killed(myproc()))
    8000320e:	fffff097          	auipc	ra,0xfffff
    80003212:	a2e080e7          	jalr	-1490(ra) # 80001c3c <myproc>
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	396080e7          	jalr	918(ra) # 800025ac <killed>
    8000321e:	ed15                	bnez	a0,8000325a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003220:	85ce                	mv	a1,s3
    80003222:	8526                	mv	a0,s1
    80003224:	fffff097          	auipc	ra,0xfffff
    80003228:	0d4080e7          	jalr	212(ra) # 800022f8 <sleep>
  while (ticks - ticks0 < n)
    8000322c:	409c                	lw	a5,0(s1)
    8000322e:	412787bb          	subw	a5,a5,s2
    80003232:	fcc42703          	lw	a4,-52(s0)
    80003236:	fce7ece3          	bltu	a5,a4,8000320e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000323a:	00234517          	auipc	a0,0x234
    8000323e:	b5e50513          	addi	a0,a0,-1186 # 80236d98 <tickslock>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	b4a080e7          	jalr	-1206(ra) # 80000d8c <release>
  return 0;
    8000324a:	4501                	li	a0,0
}
    8000324c:	70e2                	ld	ra,56(sp)
    8000324e:	7442                	ld	s0,48(sp)
    80003250:	74a2                	ld	s1,40(sp)
    80003252:	7902                	ld	s2,32(sp)
    80003254:	69e2                	ld	s3,24(sp)
    80003256:	6121                	addi	sp,sp,64
    80003258:	8082                	ret
      release(&tickslock);
    8000325a:	00234517          	auipc	a0,0x234
    8000325e:	b3e50513          	addi	a0,a0,-1218 # 80236d98 <tickslock>
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	b2a080e7          	jalr	-1238(ra) # 80000d8c <release>
      return -1;
    8000326a:	557d                	li	a0,-1
    8000326c:	b7c5                	j	8000324c <sys_sleep+0x88>

000000008000326e <sys_kill>:

uint64
sys_kill(void)
{
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003276:	fec40593          	addi	a1,s0,-20
    8000327a:	4501                	li	a0,0
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	d9a080e7          	jalr	-614(ra) # 80003016 <argint>
  return kill(pid);
    80003284:	fec42503          	lw	a0,-20(s0)
    80003288:	fffff097          	auipc	ra,0xfffff
    8000328c:	286080e7          	jalr	646(ra) # 8000250e <kill>
}
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret

0000000080003298 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032a2:	00234517          	auipc	a0,0x234
    800032a6:	af650513          	addi	a0,a0,-1290 # 80236d98 <tickslock>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	a2e080e7          	jalr	-1490(ra) # 80000cd8 <acquire>
  xticks = ticks;
    800032b2:	00005497          	auipc	s1,0x5
    800032b6:	6364a483          	lw	s1,1590(s1) # 800088e8 <ticks>
  release(&tickslock);
    800032ba:	00234517          	auipc	a0,0x234
    800032be:	ade50513          	addi	a0,a0,-1314 # 80236d98 <tickslock>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	aca080e7          	jalr	-1334(ra) # 80000d8c <release>
  return xticks;
}
    800032ca:	02049513          	slli	a0,s1,0x20
    800032ce:	9101                	srli	a0,a0,0x20
    800032d0:	60e2                	ld	ra,24(sp)
    800032d2:	6442                	ld	s0,16(sp)
    800032d4:	64a2                	ld	s1,8(sp)
    800032d6:	6105                	addi	sp,sp,32
    800032d8:	8082                	ret

00000000800032da <sys_waitx>:

uint64
sys_waitx(void)
{
    800032da:	7139                	addi	sp,sp,-64
    800032dc:	fc06                	sd	ra,56(sp)
    800032de:	f822                	sd	s0,48(sp)
    800032e0:	f426                	sd	s1,40(sp)
    800032e2:	f04a                	sd	s2,32(sp)
    800032e4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800032e6:	fd840593          	addi	a1,s0,-40
    800032ea:	4501                	li	a0,0
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	d4a080e7          	jalr	-694(ra) # 80003036 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800032f4:	fd040593          	addi	a1,s0,-48
    800032f8:	4505                	li	a0,1
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	d3c080e7          	jalr	-708(ra) # 80003036 <argaddr>
  argaddr(2, &addr2);
    80003302:	fc840593          	addi	a1,s0,-56
    80003306:	4509                	li	a0,2
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	d2e080e7          	jalr	-722(ra) # 80003036 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003310:	fc040613          	addi	a2,s0,-64
    80003314:	fc440593          	addi	a1,s0,-60
    80003318:	fd843503          	ld	a0,-40(s0)
    8000331c:	fffff097          	auipc	ra,0xfffff
    80003320:	54a080e7          	jalr	1354(ra) # 80002866 <waitx>
    80003324:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003326:	fffff097          	auipc	ra,0xfffff
    8000332a:	916080e7          	jalr	-1770(ra) # 80001c3c <myproc>
    8000332e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003330:	4691                	li	a3,4
    80003332:	fc440613          	addi	a2,s0,-60
    80003336:	fd043583          	ld	a1,-48(s0)
    8000333a:	6928                	ld	a0,80(a0)
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	51c080e7          	jalr	1308(ra) # 80001858 <copyout>
    return -1;
    80003344:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003346:	00054f63          	bltz	a0,80003364 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000334a:	4691                	li	a3,4
    8000334c:	fc040613          	addi	a2,s0,-64
    80003350:	fc843583          	ld	a1,-56(s0)
    80003354:	68a8                	ld	a0,80(s1)
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	502080e7          	jalr	1282(ra) # 80001858 <copyout>
    8000335e:	00054a63          	bltz	a0,80003372 <sys_waitx+0x98>
    return -1;
  return ret;
    80003362:	87ca                	mv	a5,s2
}
    80003364:	853e                	mv	a0,a5
    80003366:	70e2                	ld	ra,56(sp)
    80003368:	7442                	ld	s0,48(sp)
    8000336a:	74a2                	ld	s1,40(sp)
    8000336c:	7902                	ld	s2,32(sp)
    8000336e:	6121                	addi	sp,sp,64
    80003370:	8082                	ret
    return -1;
    80003372:	57fd                	li	a5,-1
    80003374:	bfc5                	j	80003364 <sys_waitx+0x8a>

0000000080003376 <sys_counter>:

uint64
sys_counter(void){
    80003376:	1141                	addi	sp,sp,-16
    80003378:	e422                	sd	s0,8(sp)
    8000337a:	0800                	addi	s0,sp,16
  return counter;
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	55452503          	lw	a0,1364(a0) # 800088d0 <counter>
    80003384:	6422                	ld	s0,8(sp)
    80003386:	0141                	addi	sp,sp,16
    80003388:	8082                	ret

000000008000338a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000338a:	7179                	addi	sp,sp,-48
    8000338c:	f406                	sd	ra,40(sp)
    8000338e:	f022                	sd	s0,32(sp)
    80003390:	ec26                	sd	s1,24(sp)
    80003392:	e84a                	sd	s2,16(sp)
    80003394:	e44e                	sd	s3,8(sp)
    80003396:	e052                	sd	s4,0(sp)
    80003398:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000339a:	00005597          	auipc	a1,0x5
    8000339e:	18658593          	addi	a1,a1,390 # 80008520 <syscalls+0xc0>
    800033a2:	00234517          	auipc	a0,0x234
    800033a6:	a0e50513          	addi	a0,a0,-1522 # 80236db0 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	89e080e7          	jalr	-1890(ra) # 80000c48 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033b2:	0023c797          	auipc	a5,0x23c
    800033b6:	9fe78793          	addi	a5,a5,-1538 # 8023edb0 <bcache+0x8000>
    800033ba:	0023c717          	auipc	a4,0x23c
    800033be:	c5e70713          	addi	a4,a4,-930 # 8023f018 <bcache+0x8268>
    800033c2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033c6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ca:	00234497          	auipc	s1,0x234
    800033ce:	9fe48493          	addi	s1,s1,-1538 # 80236dc8 <bcache+0x18>
    b->next = bcache.head.next;
    800033d2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033d4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033d6:	00005a17          	auipc	s4,0x5
    800033da:	152a0a13          	addi	s4,s4,338 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    800033de:	2b893783          	ld	a5,696(s2)
    800033e2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033e4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033e8:	85d2                	mv	a1,s4
    800033ea:	01048513          	addi	a0,s1,16
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	4c4080e7          	jalr	1220(ra) # 800048b2 <initsleeplock>
    bcache.head.next->prev = b;
    800033f6:	2b893783          	ld	a5,696(s2)
    800033fa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033fc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003400:	45848493          	addi	s1,s1,1112
    80003404:	fd349de3          	bne	s1,s3,800033de <binit+0x54>
  }
}
    80003408:	70a2                	ld	ra,40(sp)
    8000340a:	7402                	ld	s0,32(sp)
    8000340c:	64e2                	ld	s1,24(sp)
    8000340e:	6942                	ld	s2,16(sp)
    80003410:	69a2                	ld	s3,8(sp)
    80003412:	6a02                	ld	s4,0(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret

0000000080003418 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	1800                	addi	s0,sp,48
    80003426:	892a                	mv	s2,a0
    80003428:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000342a:	00234517          	auipc	a0,0x234
    8000342e:	98650513          	addi	a0,a0,-1658 # 80236db0 <bcache>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	8a6080e7          	jalr	-1882(ra) # 80000cd8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000343a:	0023c497          	auipc	s1,0x23c
    8000343e:	c2e4b483          	ld	s1,-978(s1) # 8023f068 <bcache+0x82b8>
    80003442:	0023c797          	auipc	a5,0x23c
    80003446:	bd678793          	addi	a5,a5,-1066 # 8023f018 <bcache+0x8268>
    8000344a:	02f48f63          	beq	s1,a5,80003488 <bread+0x70>
    8000344e:	873e                	mv	a4,a5
    80003450:	a021                	j	80003458 <bread+0x40>
    80003452:	68a4                	ld	s1,80(s1)
    80003454:	02e48a63          	beq	s1,a4,80003488 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003458:	449c                	lw	a5,8(s1)
    8000345a:	ff279ce3          	bne	a5,s2,80003452 <bread+0x3a>
    8000345e:	44dc                	lw	a5,12(s1)
    80003460:	ff3799e3          	bne	a5,s3,80003452 <bread+0x3a>
      b->refcnt++;
    80003464:	40bc                	lw	a5,64(s1)
    80003466:	2785                	addiw	a5,a5,1
    80003468:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000346a:	00234517          	auipc	a0,0x234
    8000346e:	94650513          	addi	a0,a0,-1722 # 80236db0 <bcache>
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	91a080e7          	jalr	-1766(ra) # 80000d8c <release>
      acquiresleep(&b->lock);
    8000347a:	01048513          	addi	a0,s1,16
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	46e080e7          	jalr	1134(ra) # 800048ec <acquiresleep>
      return b;
    80003486:	a8b9                	j	800034e4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003488:	0023c497          	auipc	s1,0x23c
    8000348c:	bd84b483          	ld	s1,-1064(s1) # 8023f060 <bcache+0x82b0>
    80003490:	0023c797          	auipc	a5,0x23c
    80003494:	b8878793          	addi	a5,a5,-1144 # 8023f018 <bcache+0x8268>
    80003498:	00f48863          	beq	s1,a5,800034a8 <bread+0x90>
    8000349c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000349e:	40bc                	lw	a5,64(s1)
    800034a0:	cf81                	beqz	a5,800034b8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034a2:	64a4                	ld	s1,72(s1)
    800034a4:	fee49de3          	bne	s1,a4,8000349e <bread+0x86>
  panic("bget: no buffers");
    800034a8:	00005517          	auipc	a0,0x5
    800034ac:	08850513          	addi	a0,a0,136 # 80008530 <syscalls+0xd0>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	08e080e7          	jalr	142(ra) # 8000053e <panic>
      b->dev = dev;
    800034b8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034bc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034c0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034c4:	4785                	li	a5,1
    800034c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034c8:	00234517          	auipc	a0,0x234
    800034cc:	8e850513          	addi	a0,a0,-1816 # 80236db0 <bcache>
    800034d0:	ffffe097          	auipc	ra,0xffffe
    800034d4:	8bc080e7          	jalr	-1860(ra) # 80000d8c <release>
      acquiresleep(&b->lock);
    800034d8:	01048513          	addi	a0,s1,16
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	410080e7          	jalr	1040(ra) # 800048ec <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034e4:	409c                	lw	a5,0(s1)
    800034e6:	cb89                	beqz	a5,800034f8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034e8:	8526                	mv	a0,s1
    800034ea:	70a2                	ld	ra,40(sp)
    800034ec:	7402                	ld	s0,32(sp)
    800034ee:	64e2                	ld	s1,24(sp)
    800034f0:	6942                	ld	s2,16(sp)
    800034f2:	69a2                	ld	s3,8(sp)
    800034f4:	6145                	addi	sp,sp,48
    800034f6:	8082                	ret
    virtio_disk_rw(b, 0);
    800034f8:	4581                	li	a1,0
    800034fa:	8526                	mv	a0,s1
    800034fc:	00003097          	auipc	ra,0x3
    80003500:	fd8080e7          	jalr	-40(ra) # 800064d4 <virtio_disk_rw>
    b->valid = 1;
    80003504:	4785                	li	a5,1
    80003506:	c09c                	sw	a5,0(s1)
  return b;
    80003508:	b7c5                	j	800034e8 <bread+0xd0>

000000008000350a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000350a:	1101                	addi	sp,sp,-32
    8000350c:	ec06                	sd	ra,24(sp)
    8000350e:	e822                	sd	s0,16(sp)
    80003510:	e426                	sd	s1,8(sp)
    80003512:	1000                	addi	s0,sp,32
    80003514:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003516:	0541                	addi	a0,a0,16
    80003518:	00001097          	auipc	ra,0x1
    8000351c:	46e080e7          	jalr	1134(ra) # 80004986 <holdingsleep>
    80003520:	cd01                	beqz	a0,80003538 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003522:	4585                	li	a1,1
    80003524:	8526                	mv	a0,s1
    80003526:	00003097          	auipc	ra,0x3
    8000352a:	fae080e7          	jalr	-82(ra) # 800064d4 <virtio_disk_rw>
}
    8000352e:	60e2                	ld	ra,24(sp)
    80003530:	6442                	ld	s0,16(sp)
    80003532:	64a2                	ld	s1,8(sp)
    80003534:	6105                	addi	sp,sp,32
    80003536:	8082                	ret
    panic("bwrite");
    80003538:	00005517          	auipc	a0,0x5
    8000353c:	01050513          	addi	a0,a0,16 # 80008548 <syscalls+0xe8>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>

0000000080003548 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003548:	1101                	addi	sp,sp,-32
    8000354a:	ec06                	sd	ra,24(sp)
    8000354c:	e822                	sd	s0,16(sp)
    8000354e:	e426                	sd	s1,8(sp)
    80003550:	e04a                	sd	s2,0(sp)
    80003552:	1000                	addi	s0,sp,32
    80003554:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003556:	01050913          	addi	s2,a0,16
    8000355a:	854a                	mv	a0,s2
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	42a080e7          	jalr	1066(ra) # 80004986 <holdingsleep>
    80003564:	c92d                	beqz	a0,800035d6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003566:	854a                	mv	a0,s2
    80003568:	00001097          	auipc	ra,0x1
    8000356c:	3da080e7          	jalr	986(ra) # 80004942 <releasesleep>

  acquire(&bcache.lock);
    80003570:	00234517          	auipc	a0,0x234
    80003574:	84050513          	addi	a0,a0,-1984 # 80236db0 <bcache>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	760080e7          	jalr	1888(ra) # 80000cd8 <acquire>
  b->refcnt--;
    80003580:	40bc                	lw	a5,64(s1)
    80003582:	37fd                	addiw	a5,a5,-1
    80003584:	0007871b          	sext.w	a4,a5
    80003588:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000358a:	eb05                	bnez	a4,800035ba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000358c:	68bc                	ld	a5,80(s1)
    8000358e:	64b8                	ld	a4,72(s1)
    80003590:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003592:	64bc                	ld	a5,72(s1)
    80003594:	68b8                	ld	a4,80(s1)
    80003596:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003598:	0023c797          	auipc	a5,0x23c
    8000359c:	81878793          	addi	a5,a5,-2024 # 8023edb0 <bcache+0x8000>
    800035a0:	2b87b703          	ld	a4,696(a5)
    800035a4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035a6:	0023c717          	auipc	a4,0x23c
    800035aa:	a7270713          	addi	a4,a4,-1422 # 8023f018 <bcache+0x8268>
    800035ae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035b0:	2b87b703          	ld	a4,696(a5)
    800035b4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035b6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035ba:	00233517          	auipc	a0,0x233
    800035be:	7f650513          	addi	a0,a0,2038 # 80236db0 <bcache>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	7ca080e7          	jalr	1994(ra) # 80000d8c <release>
}
    800035ca:	60e2                	ld	ra,24(sp)
    800035cc:	6442                	ld	s0,16(sp)
    800035ce:	64a2                	ld	s1,8(sp)
    800035d0:	6902                	ld	s2,0(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret
    panic("brelse");
    800035d6:	00005517          	auipc	a0,0x5
    800035da:	f7a50513          	addi	a0,a0,-134 # 80008550 <syscalls+0xf0>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>

00000000800035e6 <bpin>:

void
bpin(struct buf *b) {
    800035e6:	1101                	addi	sp,sp,-32
    800035e8:	ec06                	sd	ra,24(sp)
    800035ea:	e822                	sd	s0,16(sp)
    800035ec:	e426                	sd	s1,8(sp)
    800035ee:	1000                	addi	s0,sp,32
    800035f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035f2:	00233517          	auipc	a0,0x233
    800035f6:	7be50513          	addi	a0,a0,1982 # 80236db0 <bcache>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	6de080e7          	jalr	1758(ra) # 80000cd8 <acquire>
  b->refcnt++;
    80003602:	40bc                	lw	a5,64(s1)
    80003604:	2785                	addiw	a5,a5,1
    80003606:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003608:	00233517          	auipc	a0,0x233
    8000360c:	7a850513          	addi	a0,a0,1960 # 80236db0 <bcache>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	77c080e7          	jalr	1916(ra) # 80000d8c <release>
}
    80003618:	60e2                	ld	ra,24(sp)
    8000361a:	6442                	ld	s0,16(sp)
    8000361c:	64a2                	ld	s1,8(sp)
    8000361e:	6105                	addi	sp,sp,32
    80003620:	8082                	ret

0000000080003622 <bunpin>:

void
bunpin(struct buf *b) {
    80003622:	1101                	addi	sp,sp,-32
    80003624:	ec06                	sd	ra,24(sp)
    80003626:	e822                	sd	s0,16(sp)
    80003628:	e426                	sd	s1,8(sp)
    8000362a:	1000                	addi	s0,sp,32
    8000362c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000362e:	00233517          	auipc	a0,0x233
    80003632:	78250513          	addi	a0,a0,1922 # 80236db0 <bcache>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	6a2080e7          	jalr	1698(ra) # 80000cd8 <acquire>
  b->refcnt--;
    8000363e:	40bc                	lw	a5,64(s1)
    80003640:	37fd                	addiw	a5,a5,-1
    80003642:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003644:	00233517          	auipc	a0,0x233
    80003648:	76c50513          	addi	a0,a0,1900 # 80236db0 <bcache>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	740080e7          	jalr	1856(ra) # 80000d8c <release>
}
    80003654:	60e2                	ld	ra,24(sp)
    80003656:	6442                	ld	s0,16(sp)
    80003658:	64a2                	ld	s1,8(sp)
    8000365a:	6105                	addi	sp,sp,32
    8000365c:	8082                	ret

000000008000365e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000365e:	1101                	addi	sp,sp,-32
    80003660:	ec06                	sd	ra,24(sp)
    80003662:	e822                	sd	s0,16(sp)
    80003664:	e426                	sd	s1,8(sp)
    80003666:	e04a                	sd	s2,0(sp)
    80003668:	1000                	addi	s0,sp,32
    8000366a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000366c:	00d5d59b          	srliw	a1,a1,0xd
    80003670:	0023c797          	auipc	a5,0x23c
    80003674:	e1c7a783          	lw	a5,-484(a5) # 8023f48c <sb+0x1c>
    80003678:	9dbd                	addw	a1,a1,a5
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	d9e080e7          	jalr	-610(ra) # 80003418 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003682:	0074f713          	andi	a4,s1,7
    80003686:	4785                	li	a5,1
    80003688:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000368c:	14ce                	slli	s1,s1,0x33
    8000368e:	90d9                	srli	s1,s1,0x36
    80003690:	00950733          	add	a4,a0,s1
    80003694:	05874703          	lbu	a4,88(a4)
    80003698:	00e7f6b3          	and	a3,a5,a4
    8000369c:	c69d                	beqz	a3,800036ca <bfree+0x6c>
    8000369e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036a0:	94aa                	add	s1,s1,a0
    800036a2:	fff7c793          	not	a5,a5
    800036a6:	8ff9                	and	a5,a5,a4
    800036a8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	120080e7          	jalr	288(ra) # 800047cc <log_write>
  brelse(bp);
    800036b4:	854a                	mv	a0,s2
    800036b6:	00000097          	auipc	ra,0x0
    800036ba:	e92080e7          	jalr	-366(ra) # 80003548 <brelse>
}
    800036be:	60e2                	ld	ra,24(sp)
    800036c0:	6442                	ld	s0,16(sp)
    800036c2:	64a2                	ld	s1,8(sp)
    800036c4:	6902                	ld	s2,0(sp)
    800036c6:	6105                	addi	sp,sp,32
    800036c8:	8082                	ret
    panic("freeing free block");
    800036ca:	00005517          	auipc	a0,0x5
    800036ce:	e8e50513          	addi	a0,a0,-370 # 80008558 <syscalls+0xf8>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	e6c080e7          	jalr	-404(ra) # 8000053e <panic>

00000000800036da <balloc>:
{
    800036da:	711d                	addi	sp,sp,-96
    800036dc:	ec86                	sd	ra,88(sp)
    800036de:	e8a2                	sd	s0,80(sp)
    800036e0:	e4a6                	sd	s1,72(sp)
    800036e2:	e0ca                	sd	s2,64(sp)
    800036e4:	fc4e                	sd	s3,56(sp)
    800036e6:	f852                	sd	s4,48(sp)
    800036e8:	f456                	sd	s5,40(sp)
    800036ea:	f05a                	sd	s6,32(sp)
    800036ec:	ec5e                	sd	s7,24(sp)
    800036ee:	e862                	sd	s8,16(sp)
    800036f0:	e466                	sd	s9,8(sp)
    800036f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036f4:	0023c797          	auipc	a5,0x23c
    800036f8:	d807a783          	lw	a5,-640(a5) # 8023f474 <sb+0x4>
    800036fc:	10078163          	beqz	a5,800037fe <balloc+0x124>
    80003700:	8baa                	mv	s7,a0
    80003702:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003704:	0023cb17          	auipc	s6,0x23c
    80003708:	d6cb0b13          	addi	s6,s6,-660 # 8023f470 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000370c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000370e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003710:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003712:	6c89                	lui	s9,0x2
    80003714:	a061                	j	8000379c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003716:	974a                	add	a4,a4,s2
    80003718:	8fd5                	or	a5,a5,a3
    8000371a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000371e:	854a                	mv	a0,s2
    80003720:	00001097          	auipc	ra,0x1
    80003724:	0ac080e7          	jalr	172(ra) # 800047cc <log_write>
        brelse(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	e1e080e7          	jalr	-482(ra) # 80003548 <brelse>
  bp = bread(dev, bno);
    80003732:	85a6                	mv	a1,s1
    80003734:	855e                	mv	a0,s7
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	ce2080e7          	jalr	-798(ra) # 80003418 <bread>
    8000373e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003740:	40000613          	li	a2,1024
    80003744:	4581                	li	a1,0
    80003746:	05850513          	addi	a0,a0,88
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	68a080e7          	jalr	1674(ra) # 80000dd4 <memset>
  log_write(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	078080e7          	jalr	120(ra) # 800047cc <log_write>
  brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	dea080e7          	jalr	-534(ra) # 80003548 <brelse>
}
    80003766:	8526                	mv	a0,s1
    80003768:	60e6                	ld	ra,88(sp)
    8000376a:	6446                	ld	s0,80(sp)
    8000376c:	64a6                	ld	s1,72(sp)
    8000376e:	6906                	ld	s2,64(sp)
    80003770:	79e2                	ld	s3,56(sp)
    80003772:	7a42                	ld	s4,48(sp)
    80003774:	7aa2                	ld	s5,40(sp)
    80003776:	7b02                	ld	s6,32(sp)
    80003778:	6be2                	ld	s7,24(sp)
    8000377a:	6c42                	ld	s8,16(sp)
    8000377c:	6ca2                	ld	s9,8(sp)
    8000377e:	6125                	addi	sp,sp,96
    80003780:	8082                	ret
    brelse(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00000097          	auipc	ra,0x0
    80003788:	dc4080e7          	jalr	-572(ra) # 80003548 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000378c:	015c87bb          	addw	a5,s9,s5
    80003790:	00078a9b          	sext.w	s5,a5
    80003794:	004b2703          	lw	a4,4(s6)
    80003798:	06eaf363          	bgeu	s5,a4,800037fe <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000379c:	41fad79b          	sraiw	a5,s5,0x1f
    800037a0:	0137d79b          	srliw	a5,a5,0x13
    800037a4:	015787bb          	addw	a5,a5,s5
    800037a8:	40d7d79b          	sraiw	a5,a5,0xd
    800037ac:	01cb2583          	lw	a1,28(s6)
    800037b0:	9dbd                	addw	a1,a1,a5
    800037b2:	855e                	mv	a0,s7
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	c64080e7          	jalr	-924(ra) # 80003418 <bread>
    800037bc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037be:	004b2503          	lw	a0,4(s6)
    800037c2:	000a849b          	sext.w	s1,s5
    800037c6:	8662                	mv	a2,s8
    800037c8:	faa4fde3          	bgeu	s1,a0,80003782 <balloc+0xa8>
      m = 1 << (bi % 8);
    800037cc:	41f6579b          	sraiw	a5,a2,0x1f
    800037d0:	01d7d69b          	srliw	a3,a5,0x1d
    800037d4:	00c6873b          	addw	a4,a3,a2
    800037d8:	00777793          	andi	a5,a4,7
    800037dc:	9f95                	subw	a5,a5,a3
    800037de:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037e2:	4037571b          	sraiw	a4,a4,0x3
    800037e6:	00e906b3          	add	a3,s2,a4
    800037ea:	0586c683          	lbu	a3,88(a3)
    800037ee:	00d7f5b3          	and	a1,a5,a3
    800037f2:	d195                	beqz	a1,80003716 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f4:	2605                	addiw	a2,a2,1
    800037f6:	2485                	addiw	s1,s1,1
    800037f8:	fd4618e3          	bne	a2,s4,800037c8 <balloc+0xee>
    800037fc:	b759                	j	80003782 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	d7250513          	addi	a0,a0,-654 # 80008570 <syscalls+0x110>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d82080e7          	jalr	-638(ra) # 80000588 <printf>
  return 0;
    8000380e:	4481                	li	s1,0
    80003810:	bf99                	j	80003766 <balloc+0x8c>

0000000080003812 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003812:	7179                	addi	sp,sp,-48
    80003814:	f406                	sd	ra,40(sp)
    80003816:	f022                	sd	s0,32(sp)
    80003818:	ec26                	sd	s1,24(sp)
    8000381a:	e84a                	sd	s2,16(sp)
    8000381c:	e44e                	sd	s3,8(sp)
    8000381e:	e052                	sd	s4,0(sp)
    80003820:	1800                	addi	s0,sp,48
    80003822:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003824:	47ad                	li	a5,11
    80003826:	02b7e763          	bltu	a5,a1,80003854 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000382a:	02059493          	slli	s1,a1,0x20
    8000382e:	9081                	srli	s1,s1,0x20
    80003830:	048a                	slli	s1,s1,0x2
    80003832:	94aa                	add	s1,s1,a0
    80003834:	0504a903          	lw	s2,80(s1)
    80003838:	06091e63          	bnez	s2,800038b4 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000383c:	4108                	lw	a0,0(a0)
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	e9c080e7          	jalr	-356(ra) # 800036da <balloc>
    80003846:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000384a:	06090563          	beqz	s2,800038b4 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000384e:	0524a823          	sw	s2,80(s1)
    80003852:	a08d                	j	800038b4 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003854:	ff45849b          	addiw	s1,a1,-12
    80003858:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000385c:	0ff00793          	li	a5,255
    80003860:	08e7e563          	bltu	a5,a4,800038ea <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003864:	08052903          	lw	s2,128(a0)
    80003868:	00091d63          	bnez	s2,80003882 <bmap+0x70>
      addr = balloc(ip->dev);
    8000386c:	4108                	lw	a0,0(a0)
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	e6c080e7          	jalr	-404(ra) # 800036da <balloc>
    80003876:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000387a:	02090d63          	beqz	s2,800038b4 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000387e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003882:	85ca                	mv	a1,s2
    80003884:	0009a503          	lw	a0,0(s3)
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	b90080e7          	jalr	-1136(ra) # 80003418 <bread>
    80003890:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003892:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003896:	02049593          	slli	a1,s1,0x20
    8000389a:	9181                	srli	a1,a1,0x20
    8000389c:	058a                	slli	a1,a1,0x2
    8000389e:	00b784b3          	add	s1,a5,a1
    800038a2:	0004a903          	lw	s2,0(s1)
    800038a6:	02090063          	beqz	s2,800038c6 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038aa:	8552                	mv	a0,s4
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	c9c080e7          	jalr	-868(ra) # 80003548 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038b4:	854a                	mv	a0,s2
    800038b6:	70a2                	ld	ra,40(sp)
    800038b8:	7402                	ld	s0,32(sp)
    800038ba:	64e2                	ld	s1,24(sp)
    800038bc:	6942                	ld	s2,16(sp)
    800038be:	69a2                	ld	s3,8(sp)
    800038c0:	6a02                	ld	s4,0(sp)
    800038c2:	6145                	addi	sp,sp,48
    800038c4:	8082                	ret
      addr = balloc(ip->dev);
    800038c6:	0009a503          	lw	a0,0(s3)
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	e10080e7          	jalr	-496(ra) # 800036da <balloc>
    800038d2:	0005091b          	sext.w	s2,a0
      if(addr){
    800038d6:	fc090ae3          	beqz	s2,800038aa <bmap+0x98>
        a[bn] = addr;
    800038da:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038de:	8552                	mv	a0,s4
    800038e0:	00001097          	auipc	ra,0x1
    800038e4:	eec080e7          	jalr	-276(ra) # 800047cc <log_write>
    800038e8:	b7c9                	j	800038aa <bmap+0x98>
  panic("bmap: out of range");
    800038ea:	00005517          	auipc	a0,0x5
    800038ee:	c9e50513          	addi	a0,a0,-866 # 80008588 <syscalls+0x128>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	c4c080e7          	jalr	-948(ra) # 8000053e <panic>

00000000800038fa <iget>:
{
    800038fa:	7179                	addi	sp,sp,-48
    800038fc:	f406                	sd	ra,40(sp)
    800038fe:	f022                	sd	s0,32(sp)
    80003900:	ec26                	sd	s1,24(sp)
    80003902:	e84a                	sd	s2,16(sp)
    80003904:	e44e                	sd	s3,8(sp)
    80003906:	e052                	sd	s4,0(sp)
    80003908:	1800                	addi	s0,sp,48
    8000390a:	89aa                	mv	s3,a0
    8000390c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000390e:	0023c517          	auipc	a0,0x23c
    80003912:	b8250513          	addi	a0,a0,-1150 # 8023f490 <itable>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	3c2080e7          	jalr	962(ra) # 80000cd8 <acquire>
  empty = 0;
    8000391e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003920:	0023c497          	auipc	s1,0x23c
    80003924:	b8848493          	addi	s1,s1,-1144 # 8023f4a8 <itable+0x18>
    80003928:	0023d697          	auipc	a3,0x23d
    8000392c:	61068693          	addi	a3,a3,1552 # 80240f38 <log>
    80003930:	a039                	j	8000393e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003932:	02090b63          	beqz	s2,80003968 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003936:	08848493          	addi	s1,s1,136
    8000393a:	02d48a63          	beq	s1,a3,8000396e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000393e:	449c                	lw	a5,8(s1)
    80003940:	fef059e3          	blez	a5,80003932 <iget+0x38>
    80003944:	4098                	lw	a4,0(s1)
    80003946:	ff3716e3          	bne	a4,s3,80003932 <iget+0x38>
    8000394a:	40d8                	lw	a4,4(s1)
    8000394c:	ff4713e3          	bne	a4,s4,80003932 <iget+0x38>
      ip->ref++;
    80003950:	2785                	addiw	a5,a5,1
    80003952:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003954:	0023c517          	auipc	a0,0x23c
    80003958:	b3c50513          	addi	a0,a0,-1220 # 8023f490 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	430080e7          	jalr	1072(ra) # 80000d8c <release>
      return ip;
    80003964:	8926                	mv	s2,s1
    80003966:	a03d                	j	80003994 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003968:	f7f9                	bnez	a5,80003936 <iget+0x3c>
    8000396a:	8926                	mv	s2,s1
    8000396c:	b7e9                	j	80003936 <iget+0x3c>
  if(empty == 0)
    8000396e:	02090c63          	beqz	s2,800039a6 <iget+0xac>
  ip->dev = dev;
    80003972:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003976:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000397a:	4785                	li	a5,1
    8000397c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003980:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003984:	0023c517          	auipc	a0,0x23c
    80003988:	b0c50513          	addi	a0,a0,-1268 # 8023f490 <itable>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	400080e7          	jalr	1024(ra) # 80000d8c <release>
}
    80003994:	854a                	mv	a0,s2
    80003996:	70a2                	ld	ra,40(sp)
    80003998:	7402                	ld	s0,32(sp)
    8000399a:	64e2                	ld	s1,24(sp)
    8000399c:	6942                	ld	s2,16(sp)
    8000399e:	69a2                	ld	s3,8(sp)
    800039a0:	6a02                	ld	s4,0(sp)
    800039a2:	6145                	addi	sp,sp,48
    800039a4:	8082                	ret
    panic("iget: no inodes");
    800039a6:	00005517          	auipc	a0,0x5
    800039aa:	bfa50513          	addi	a0,a0,-1030 # 800085a0 <syscalls+0x140>
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	b90080e7          	jalr	-1136(ra) # 8000053e <panic>

00000000800039b6 <fsinit>:
fsinit(int dev) {
    800039b6:	7179                	addi	sp,sp,-48
    800039b8:	f406                	sd	ra,40(sp)
    800039ba:	f022                	sd	s0,32(sp)
    800039bc:	ec26                	sd	s1,24(sp)
    800039be:	e84a                	sd	s2,16(sp)
    800039c0:	e44e                	sd	s3,8(sp)
    800039c2:	1800                	addi	s0,sp,48
    800039c4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039c6:	4585                	li	a1,1
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	a50080e7          	jalr	-1456(ra) # 80003418 <bread>
    800039d0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039d2:	0023c997          	auipc	s3,0x23c
    800039d6:	a9e98993          	addi	s3,s3,-1378 # 8023f470 <sb>
    800039da:	02000613          	li	a2,32
    800039de:	05850593          	addi	a1,a0,88
    800039e2:	854e                	mv	a0,s3
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	44c080e7          	jalr	1100(ra) # 80000e30 <memmove>
  brelse(bp);
    800039ec:	8526                	mv	a0,s1
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	b5a080e7          	jalr	-1190(ra) # 80003548 <brelse>
  if(sb.magic != FSMAGIC)
    800039f6:	0009a703          	lw	a4,0(s3)
    800039fa:	102037b7          	lui	a5,0x10203
    800039fe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a02:	02f71263          	bne	a4,a5,80003a26 <fsinit+0x70>
  initlog(dev, &sb);
    80003a06:	0023c597          	auipc	a1,0x23c
    80003a0a:	a6a58593          	addi	a1,a1,-1430 # 8023f470 <sb>
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	b40080e7          	jalr	-1216(ra) # 80004550 <initlog>
}
    80003a18:	70a2                	ld	ra,40(sp)
    80003a1a:	7402                	ld	s0,32(sp)
    80003a1c:	64e2                	ld	s1,24(sp)
    80003a1e:	6942                	ld	s2,16(sp)
    80003a20:	69a2                	ld	s3,8(sp)
    80003a22:	6145                	addi	sp,sp,48
    80003a24:	8082                	ret
    panic("invalid file system");
    80003a26:	00005517          	auipc	a0,0x5
    80003a2a:	b8a50513          	addi	a0,a0,-1142 # 800085b0 <syscalls+0x150>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	b10080e7          	jalr	-1264(ra) # 8000053e <panic>

0000000080003a36 <iinit>:
{
    80003a36:	7179                	addi	sp,sp,-48
    80003a38:	f406                	sd	ra,40(sp)
    80003a3a:	f022                	sd	s0,32(sp)
    80003a3c:	ec26                	sd	s1,24(sp)
    80003a3e:	e84a                	sd	s2,16(sp)
    80003a40:	e44e                	sd	s3,8(sp)
    80003a42:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a44:	00005597          	auipc	a1,0x5
    80003a48:	b8458593          	addi	a1,a1,-1148 # 800085c8 <syscalls+0x168>
    80003a4c:	0023c517          	auipc	a0,0x23c
    80003a50:	a4450513          	addi	a0,a0,-1468 # 8023f490 <itable>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	1f4080e7          	jalr	500(ra) # 80000c48 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a5c:	0023c497          	auipc	s1,0x23c
    80003a60:	a5c48493          	addi	s1,s1,-1444 # 8023f4b8 <itable+0x28>
    80003a64:	0023d997          	auipc	s3,0x23d
    80003a68:	4e498993          	addi	s3,s3,1252 # 80240f48 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a6c:	00005917          	auipc	s2,0x5
    80003a70:	b6490913          	addi	s2,s2,-1180 # 800085d0 <syscalls+0x170>
    80003a74:	85ca                	mv	a1,s2
    80003a76:	8526                	mv	a0,s1
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	e3a080e7          	jalr	-454(ra) # 800048b2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a80:	08848493          	addi	s1,s1,136
    80003a84:	ff3498e3          	bne	s1,s3,80003a74 <iinit+0x3e>
}
    80003a88:	70a2                	ld	ra,40(sp)
    80003a8a:	7402                	ld	s0,32(sp)
    80003a8c:	64e2                	ld	s1,24(sp)
    80003a8e:	6942                	ld	s2,16(sp)
    80003a90:	69a2                	ld	s3,8(sp)
    80003a92:	6145                	addi	sp,sp,48
    80003a94:	8082                	ret

0000000080003a96 <ialloc>:
{
    80003a96:	715d                	addi	sp,sp,-80
    80003a98:	e486                	sd	ra,72(sp)
    80003a9a:	e0a2                	sd	s0,64(sp)
    80003a9c:	fc26                	sd	s1,56(sp)
    80003a9e:	f84a                	sd	s2,48(sp)
    80003aa0:	f44e                	sd	s3,40(sp)
    80003aa2:	f052                	sd	s4,32(sp)
    80003aa4:	ec56                	sd	s5,24(sp)
    80003aa6:	e85a                	sd	s6,16(sp)
    80003aa8:	e45e                	sd	s7,8(sp)
    80003aaa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aac:	0023c717          	auipc	a4,0x23c
    80003ab0:	9d072703          	lw	a4,-1584(a4) # 8023f47c <sb+0xc>
    80003ab4:	4785                	li	a5,1
    80003ab6:	04e7fa63          	bgeu	a5,a4,80003b0a <ialloc+0x74>
    80003aba:	8aaa                	mv	s5,a0
    80003abc:	8bae                	mv	s7,a1
    80003abe:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ac0:	0023ca17          	auipc	s4,0x23c
    80003ac4:	9b0a0a13          	addi	s4,s4,-1616 # 8023f470 <sb>
    80003ac8:	00048b1b          	sext.w	s6,s1
    80003acc:	0044d793          	srli	a5,s1,0x4
    80003ad0:	018a2583          	lw	a1,24(s4)
    80003ad4:	9dbd                	addw	a1,a1,a5
    80003ad6:	8556                	mv	a0,s5
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	940080e7          	jalr	-1728(ra) # 80003418 <bread>
    80003ae0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ae2:	05850993          	addi	s3,a0,88
    80003ae6:	00f4f793          	andi	a5,s1,15
    80003aea:	079a                	slli	a5,a5,0x6
    80003aec:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aee:	00099783          	lh	a5,0(s3)
    80003af2:	c3a1                	beqz	a5,80003b32 <ialloc+0x9c>
    brelse(bp);
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	a54080e7          	jalr	-1452(ra) # 80003548 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003afc:	0485                	addi	s1,s1,1
    80003afe:	00ca2703          	lw	a4,12(s4)
    80003b02:	0004879b          	sext.w	a5,s1
    80003b06:	fce7e1e3          	bltu	a5,a4,80003ac8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b0a:	00005517          	auipc	a0,0x5
    80003b0e:	ace50513          	addi	a0,a0,-1330 # 800085d8 <syscalls+0x178>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
  return 0;
    80003b1a:	4501                	li	a0,0
}
    80003b1c:	60a6                	ld	ra,72(sp)
    80003b1e:	6406                	ld	s0,64(sp)
    80003b20:	74e2                	ld	s1,56(sp)
    80003b22:	7942                	ld	s2,48(sp)
    80003b24:	79a2                	ld	s3,40(sp)
    80003b26:	7a02                	ld	s4,32(sp)
    80003b28:	6ae2                	ld	s5,24(sp)
    80003b2a:	6b42                	ld	s6,16(sp)
    80003b2c:	6ba2                	ld	s7,8(sp)
    80003b2e:	6161                	addi	sp,sp,80
    80003b30:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b32:	04000613          	li	a2,64
    80003b36:	4581                	li	a1,0
    80003b38:	854e                	mv	a0,s3
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	29a080e7          	jalr	666(ra) # 80000dd4 <memset>
      dip->type = type;
    80003b42:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b46:	854a                	mv	a0,s2
    80003b48:	00001097          	auipc	ra,0x1
    80003b4c:	c84080e7          	jalr	-892(ra) # 800047cc <log_write>
      brelse(bp);
    80003b50:	854a                	mv	a0,s2
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	9f6080e7          	jalr	-1546(ra) # 80003548 <brelse>
      return iget(dev, inum);
    80003b5a:	85da                	mv	a1,s6
    80003b5c:	8556                	mv	a0,s5
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	d9c080e7          	jalr	-612(ra) # 800038fa <iget>
    80003b66:	bf5d                	j	80003b1c <ialloc+0x86>

0000000080003b68 <iupdate>:
{
    80003b68:	1101                	addi	sp,sp,-32
    80003b6a:	ec06                	sd	ra,24(sp)
    80003b6c:	e822                	sd	s0,16(sp)
    80003b6e:	e426                	sd	s1,8(sp)
    80003b70:	e04a                	sd	s2,0(sp)
    80003b72:	1000                	addi	s0,sp,32
    80003b74:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b76:	415c                	lw	a5,4(a0)
    80003b78:	0047d79b          	srliw	a5,a5,0x4
    80003b7c:	0023c597          	auipc	a1,0x23c
    80003b80:	90c5a583          	lw	a1,-1780(a1) # 8023f488 <sb+0x18>
    80003b84:	9dbd                	addw	a1,a1,a5
    80003b86:	4108                	lw	a0,0(a0)
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	890080e7          	jalr	-1904(ra) # 80003418 <bread>
    80003b90:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b92:	05850793          	addi	a5,a0,88
    80003b96:	40c8                	lw	a0,4(s1)
    80003b98:	893d                	andi	a0,a0,15
    80003b9a:	051a                	slli	a0,a0,0x6
    80003b9c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b9e:	04449703          	lh	a4,68(s1)
    80003ba2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ba6:	04649703          	lh	a4,70(s1)
    80003baa:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bae:	04849703          	lh	a4,72(s1)
    80003bb2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bb6:	04a49703          	lh	a4,74(s1)
    80003bba:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bbe:	44f8                	lw	a4,76(s1)
    80003bc0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bc2:	03400613          	li	a2,52
    80003bc6:	05048593          	addi	a1,s1,80
    80003bca:	0531                	addi	a0,a0,12
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	264080e7          	jalr	612(ra) # 80000e30 <memmove>
  log_write(bp);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	bf6080e7          	jalr	-1034(ra) # 800047cc <log_write>
  brelse(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	968080e7          	jalr	-1688(ra) # 80003548 <brelse>
}
    80003be8:	60e2                	ld	ra,24(sp)
    80003bea:	6442                	ld	s0,16(sp)
    80003bec:	64a2                	ld	s1,8(sp)
    80003bee:	6902                	ld	s2,0(sp)
    80003bf0:	6105                	addi	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <idup>:
{
    80003bf4:	1101                	addi	sp,sp,-32
    80003bf6:	ec06                	sd	ra,24(sp)
    80003bf8:	e822                	sd	s0,16(sp)
    80003bfa:	e426                	sd	s1,8(sp)
    80003bfc:	1000                	addi	s0,sp,32
    80003bfe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c00:	0023c517          	auipc	a0,0x23c
    80003c04:	89050513          	addi	a0,a0,-1904 # 8023f490 <itable>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	0d0080e7          	jalr	208(ra) # 80000cd8 <acquire>
  ip->ref++;
    80003c10:	449c                	lw	a5,8(s1)
    80003c12:	2785                	addiw	a5,a5,1
    80003c14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c16:	0023c517          	auipc	a0,0x23c
    80003c1a:	87a50513          	addi	a0,a0,-1926 # 8023f490 <itable>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	16e080e7          	jalr	366(ra) # 80000d8c <release>
}
    80003c26:	8526                	mv	a0,s1
    80003c28:	60e2                	ld	ra,24(sp)
    80003c2a:	6442                	ld	s0,16(sp)
    80003c2c:	64a2                	ld	s1,8(sp)
    80003c2e:	6105                	addi	sp,sp,32
    80003c30:	8082                	ret

0000000080003c32 <ilock>:
{
    80003c32:	1101                	addi	sp,sp,-32
    80003c34:	ec06                	sd	ra,24(sp)
    80003c36:	e822                	sd	s0,16(sp)
    80003c38:	e426                	sd	s1,8(sp)
    80003c3a:	e04a                	sd	s2,0(sp)
    80003c3c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c3e:	c115                	beqz	a0,80003c62 <ilock+0x30>
    80003c40:	84aa                	mv	s1,a0
    80003c42:	451c                	lw	a5,8(a0)
    80003c44:	00f05f63          	blez	a5,80003c62 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c48:	0541                	addi	a0,a0,16
    80003c4a:	00001097          	auipc	ra,0x1
    80003c4e:	ca2080e7          	jalr	-862(ra) # 800048ec <acquiresleep>
  if(ip->valid == 0){
    80003c52:	40bc                	lw	a5,64(s1)
    80003c54:	cf99                	beqz	a5,80003c72 <ilock+0x40>
}
    80003c56:	60e2                	ld	ra,24(sp)
    80003c58:	6442                	ld	s0,16(sp)
    80003c5a:	64a2                	ld	s1,8(sp)
    80003c5c:	6902                	ld	s2,0(sp)
    80003c5e:	6105                	addi	sp,sp,32
    80003c60:	8082                	ret
    panic("ilock");
    80003c62:	00005517          	auipc	a0,0x5
    80003c66:	98e50513          	addi	a0,a0,-1650 # 800085f0 <syscalls+0x190>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c72:	40dc                	lw	a5,4(s1)
    80003c74:	0047d79b          	srliw	a5,a5,0x4
    80003c78:	0023c597          	auipc	a1,0x23c
    80003c7c:	8105a583          	lw	a1,-2032(a1) # 8023f488 <sb+0x18>
    80003c80:	9dbd                	addw	a1,a1,a5
    80003c82:	4088                	lw	a0,0(s1)
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	794080e7          	jalr	1940(ra) # 80003418 <bread>
    80003c8c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c8e:	05850593          	addi	a1,a0,88
    80003c92:	40dc                	lw	a5,4(s1)
    80003c94:	8bbd                	andi	a5,a5,15
    80003c96:	079a                	slli	a5,a5,0x6
    80003c98:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c9a:	00059783          	lh	a5,0(a1)
    80003c9e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ca2:	00259783          	lh	a5,2(a1)
    80003ca6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003caa:	00459783          	lh	a5,4(a1)
    80003cae:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cb2:	00659783          	lh	a5,6(a1)
    80003cb6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cba:	459c                	lw	a5,8(a1)
    80003cbc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cbe:	03400613          	li	a2,52
    80003cc2:	05b1                	addi	a1,a1,12
    80003cc4:	05048513          	addi	a0,s1,80
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	168080e7          	jalr	360(ra) # 80000e30 <memmove>
    brelse(bp);
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	876080e7          	jalr	-1930(ra) # 80003548 <brelse>
    ip->valid = 1;
    80003cda:	4785                	li	a5,1
    80003cdc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cde:	04449783          	lh	a5,68(s1)
    80003ce2:	fbb5                	bnez	a5,80003c56 <ilock+0x24>
      panic("ilock: no type");
    80003ce4:	00005517          	auipc	a0,0x5
    80003ce8:	91450513          	addi	a0,a0,-1772 # 800085f8 <syscalls+0x198>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	852080e7          	jalr	-1966(ra) # 8000053e <panic>

0000000080003cf4 <iunlock>:
{
    80003cf4:	1101                	addi	sp,sp,-32
    80003cf6:	ec06                	sd	ra,24(sp)
    80003cf8:	e822                	sd	s0,16(sp)
    80003cfa:	e426                	sd	s1,8(sp)
    80003cfc:	e04a                	sd	s2,0(sp)
    80003cfe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d00:	c905                	beqz	a0,80003d30 <iunlock+0x3c>
    80003d02:	84aa                	mv	s1,a0
    80003d04:	01050913          	addi	s2,a0,16
    80003d08:	854a                	mv	a0,s2
    80003d0a:	00001097          	auipc	ra,0x1
    80003d0e:	c7c080e7          	jalr	-900(ra) # 80004986 <holdingsleep>
    80003d12:	cd19                	beqz	a0,80003d30 <iunlock+0x3c>
    80003d14:	449c                	lw	a5,8(s1)
    80003d16:	00f05d63          	blez	a5,80003d30 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	00001097          	auipc	ra,0x1
    80003d20:	c26080e7          	jalr	-986(ra) # 80004942 <releasesleep>
}
    80003d24:	60e2                	ld	ra,24(sp)
    80003d26:	6442                	ld	s0,16(sp)
    80003d28:	64a2                	ld	s1,8(sp)
    80003d2a:	6902                	ld	s2,0(sp)
    80003d2c:	6105                	addi	sp,sp,32
    80003d2e:	8082                	ret
    panic("iunlock");
    80003d30:	00005517          	auipc	a0,0x5
    80003d34:	8d850513          	addi	a0,a0,-1832 # 80008608 <syscalls+0x1a8>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	806080e7          	jalr	-2042(ra) # 8000053e <panic>

0000000080003d40 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d40:	7179                	addi	sp,sp,-48
    80003d42:	f406                	sd	ra,40(sp)
    80003d44:	f022                	sd	s0,32(sp)
    80003d46:	ec26                	sd	s1,24(sp)
    80003d48:	e84a                	sd	s2,16(sp)
    80003d4a:	e44e                	sd	s3,8(sp)
    80003d4c:	e052                	sd	s4,0(sp)
    80003d4e:	1800                	addi	s0,sp,48
    80003d50:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d52:	05050493          	addi	s1,a0,80
    80003d56:	08050913          	addi	s2,a0,128
    80003d5a:	a021                	j	80003d62 <itrunc+0x22>
    80003d5c:	0491                	addi	s1,s1,4
    80003d5e:	01248d63          	beq	s1,s2,80003d78 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d62:	408c                	lw	a1,0(s1)
    80003d64:	dde5                	beqz	a1,80003d5c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d66:	0009a503          	lw	a0,0(s3)
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	8f4080e7          	jalr	-1804(ra) # 8000365e <bfree>
      ip->addrs[i] = 0;
    80003d72:	0004a023          	sw	zero,0(s1)
    80003d76:	b7dd                	j	80003d5c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d78:	0809a583          	lw	a1,128(s3)
    80003d7c:	e185                	bnez	a1,80003d9c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d7e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d82:	854e                	mv	a0,s3
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	de4080e7          	jalr	-540(ra) # 80003b68 <iupdate>
}
    80003d8c:	70a2                	ld	ra,40(sp)
    80003d8e:	7402                	ld	s0,32(sp)
    80003d90:	64e2                	ld	s1,24(sp)
    80003d92:	6942                	ld	s2,16(sp)
    80003d94:	69a2                	ld	s3,8(sp)
    80003d96:	6a02                	ld	s4,0(sp)
    80003d98:	6145                	addi	sp,sp,48
    80003d9a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d9c:	0009a503          	lw	a0,0(s3)
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	678080e7          	jalr	1656(ra) # 80003418 <bread>
    80003da8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003daa:	05850493          	addi	s1,a0,88
    80003dae:	45850913          	addi	s2,a0,1112
    80003db2:	a021                	j	80003dba <itrunc+0x7a>
    80003db4:	0491                	addi	s1,s1,4
    80003db6:	01248b63          	beq	s1,s2,80003dcc <itrunc+0x8c>
      if(a[j])
    80003dba:	408c                	lw	a1,0(s1)
    80003dbc:	dde5                	beqz	a1,80003db4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dbe:	0009a503          	lw	a0,0(s3)
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	89c080e7          	jalr	-1892(ra) # 8000365e <bfree>
    80003dca:	b7ed                	j	80003db4 <itrunc+0x74>
    brelse(bp);
    80003dcc:	8552                	mv	a0,s4
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	77a080e7          	jalr	1914(ra) # 80003548 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dd6:	0809a583          	lw	a1,128(s3)
    80003dda:	0009a503          	lw	a0,0(s3)
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	880080e7          	jalr	-1920(ra) # 8000365e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003de6:	0809a023          	sw	zero,128(s3)
    80003dea:	bf51                	j	80003d7e <itrunc+0x3e>

0000000080003dec <iput>:
{
    80003dec:	1101                	addi	sp,sp,-32
    80003dee:	ec06                	sd	ra,24(sp)
    80003df0:	e822                	sd	s0,16(sp)
    80003df2:	e426                	sd	s1,8(sp)
    80003df4:	e04a                	sd	s2,0(sp)
    80003df6:	1000                	addi	s0,sp,32
    80003df8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dfa:	0023b517          	auipc	a0,0x23b
    80003dfe:	69650513          	addi	a0,a0,1686 # 8023f490 <itable>
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	ed6080e7          	jalr	-298(ra) # 80000cd8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e0a:	4498                	lw	a4,8(s1)
    80003e0c:	4785                	li	a5,1
    80003e0e:	02f70363          	beq	a4,a5,80003e34 <iput+0x48>
  ip->ref--;
    80003e12:	449c                	lw	a5,8(s1)
    80003e14:	37fd                	addiw	a5,a5,-1
    80003e16:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e18:	0023b517          	auipc	a0,0x23b
    80003e1c:	67850513          	addi	a0,a0,1656 # 8023f490 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	f6c080e7          	jalr	-148(ra) # 80000d8c <release>
}
    80003e28:	60e2                	ld	ra,24(sp)
    80003e2a:	6442                	ld	s0,16(sp)
    80003e2c:	64a2                	ld	s1,8(sp)
    80003e2e:	6902                	ld	s2,0(sp)
    80003e30:	6105                	addi	sp,sp,32
    80003e32:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e34:	40bc                	lw	a5,64(s1)
    80003e36:	dff1                	beqz	a5,80003e12 <iput+0x26>
    80003e38:	04a49783          	lh	a5,74(s1)
    80003e3c:	fbf9                	bnez	a5,80003e12 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e3e:	01048913          	addi	s2,s1,16
    80003e42:	854a                	mv	a0,s2
    80003e44:	00001097          	auipc	ra,0x1
    80003e48:	aa8080e7          	jalr	-1368(ra) # 800048ec <acquiresleep>
    release(&itable.lock);
    80003e4c:	0023b517          	auipc	a0,0x23b
    80003e50:	64450513          	addi	a0,a0,1604 # 8023f490 <itable>
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	f38080e7          	jalr	-200(ra) # 80000d8c <release>
    itrunc(ip);
    80003e5c:	8526                	mv	a0,s1
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	ee2080e7          	jalr	-286(ra) # 80003d40 <itrunc>
    ip->type = 0;
    80003e66:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e6a:	8526                	mv	a0,s1
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	cfc080e7          	jalr	-772(ra) # 80003b68 <iupdate>
    ip->valid = 0;
    80003e74:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e78:	854a                	mv	a0,s2
    80003e7a:	00001097          	auipc	ra,0x1
    80003e7e:	ac8080e7          	jalr	-1336(ra) # 80004942 <releasesleep>
    acquire(&itable.lock);
    80003e82:	0023b517          	auipc	a0,0x23b
    80003e86:	60e50513          	addi	a0,a0,1550 # 8023f490 <itable>
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	e4e080e7          	jalr	-434(ra) # 80000cd8 <acquire>
    80003e92:	b741                	j	80003e12 <iput+0x26>

0000000080003e94 <iunlockput>:
{
    80003e94:	1101                	addi	sp,sp,-32
    80003e96:	ec06                	sd	ra,24(sp)
    80003e98:	e822                	sd	s0,16(sp)
    80003e9a:	e426                	sd	s1,8(sp)
    80003e9c:	1000                	addi	s0,sp,32
    80003e9e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	e54080e7          	jalr	-428(ra) # 80003cf4 <iunlock>
  iput(ip);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	f42080e7          	jalr	-190(ra) # 80003dec <iput>
}
    80003eb2:	60e2                	ld	ra,24(sp)
    80003eb4:	6442                	ld	s0,16(sp)
    80003eb6:	64a2                	ld	s1,8(sp)
    80003eb8:	6105                	addi	sp,sp,32
    80003eba:	8082                	ret

0000000080003ebc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ebc:	1141                	addi	sp,sp,-16
    80003ebe:	e422                	sd	s0,8(sp)
    80003ec0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ec2:	411c                	lw	a5,0(a0)
    80003ec4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ec6:	415c                	lw	a5,4(a0)
    80003ec8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003eca:	04451783          	lh	a5,68(a0)
    80003ece:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ed2:	04a51783          	lh	a5,74(a0)
    80003ed6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003eda:	04c56783          	lwu	a5,76(a0)
    80003ede:	e99c                	sd	a5,16(a1)
}
    80003ee0:	6422                	ld	s0,8(sp)
    80003ee2:	0141                	addi	sp,sp,16
    80003ee4:	8082                	ret

0000000080003ee6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ee6:	457c                	lw	a5,76(a0)
    80003ee8:	0ed7e963          	bltu	a5,a3,80003fda <readi+0xf4>
{
    80003eec:	7159                	addi	sp,sp,-112
    80003eee:	f486                	sd	ra,104(sp)
    80003ef0:	f0a2                	sd	s0,96(sp)
    80003ef2:	eca6                	sd	s1,88(sp)
    80003ef4:	e8ca                	sd	s2,80(sp)
    80003ef6:	e4ce                	sd	s3,72(sp)
    80003ef8:	e0d2                	sd	s4,64(sp)
    80003efa:	fc56                	sd	s5,56(sp)
    80003efc:	f85a                	sd	s6,48(sp)
    80003efe:	f45e                	sd	s7,40(sp)
    80003f00:	f062                	sd	s8,32(sp)
    80003f02:	ec66                	sd	s9,24(sp)
    80003f04:	e86a                	sd	s10,16(sp)
    80003f06:	e46e                	sd	s11,8(sp)
    80003f08:	1880                	addi	s0,sp,112
    80003f0a:	8b2a                	mv	s6,a0
    80003f0c:	8bae                	mv	s7,a1
    80003f0e:	8a32                	mv	s4,a2
    80003f10:	84b6                	mv	s1,a3
    80003f12:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f14:	9f35                	addw	a4,a4,a3
    return 0;
    80003f16:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f18:	0ad76063          	bltu	a4,a3,80003fb8 <readi+0xd2>
  if(off + n > ip->size)
    80003f1c:	00e7f463          	bgeu	a5,a4,80003f24 <readi+0x3e>
    n = ip->size - off;
    80003f20:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f24:	0a0a8963          	beqz	s5,80003fd6 <readi+0xf0>
    80003f28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f2e:	5c7d                	li	s8,-1
    80003f30:	a82d                	j	80003f6a <readi+0x84>
    80003f32:	020d1d93          	slli	s11,s10,0x20
    80003f36:	020ddd93          	srli	s11,s11,0x20
    80003f3a:	05890793          	addi	a5,s2,88
    80003f3e:	86ee                	mv	a3,s11
    80003f40:	963e                	add	a2,a2,a5
    80003f42:	85d2                	mv	a1,s4
    80003f44:	855e                	mv	a0,s7
    80003f46:	ffffe097          	auipc	ra,0xffffe
    80003f4a:	7c6080e7          	jalr	1990(ra) # 8000270c <either_copyout>
    80003f4e:	05850d63          	beq	a0,s8,80003fa8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f52:	854a                	mv	a0,s2
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	5f4080e7          	jalr	1524(ra) # 80003548 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f5c:	013d09bb          	addw	s3,s10,s3
    80003f60:	009d04bb          	addw	s1,s10,s1
    80003f64:	9a6e                	add	s4,s4,s11
    80003f66:	0559f763          	bgeu	s3,s5,80003fb4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f6a:	00a4d59b          	srliw	a1,s1,0xa
    80003f6e:	855a                	mv	a0,s6
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	8a2080e7          	jalr	-1886(ra) # 80003812 <bmap>
    80003f78:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f7c:	cd85                	beqz	a1,80003fb4 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f7e:	000b2503          	lw	a0,0(s6)
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	496080e7          	jalr	1174(ra) # 80003418 <bread>
    80003f8a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f8c:	3ff4f613          	andi	a2,s1,1023
    80003f90:	40cc87bb          	subw	a5,s9,a2
    80003f94:	413a873b          	subw	a4,s5,s3
    80003f98:	8d3e                	mv	s10,a5
    80003f9a:	2781                	sext.w	a5,a5
    80003f9c:	0007069b          	sext.w	a3,a4
    80003fa0:	f8f6f9e3          	bgeu	a3,a5,80003f32 <readi+0x4c>
    80003fa4:	8d3a                	mv	s10,a4
    80003fa6:	b771                	j	80003f32 <readi+0x4c>
      brelse(bp);
    80003fa8:	854a                	mv	a0,s2
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	59e080e7          	jalr	1438(ra) # 80003548 <brelse>
      tot = -1;
    80003fb2:	59fd                	li	s3,-1
  }
  return tot;
    80003fb4:	0009851b          	sext.w	a0,s3
}
    80003fb8:	70a6                	ld	ra,104(sp)
    80003fba:	7406                	ld	s0,96(sp)
    80003fbc:	64e6                	ld	s1,88(sp)
    80003fbe:	6946                	ld	s2,80(sp)
    80003fc0:	69a6                	ld	s3,72(sp)
    80003fc2:	6a06                	ld	s4,64(sp)
    80003fc4:	7ae2                	ld	s5,56(sp)
    80003fc6:	7b42                	ld	s6,48(sp)
    80003fc8:	7ba2                	ld	s7,40(sp)
    80003fca:	7c02                	ld	s8,32(sp)
    80003fcc:	6ce2                	ld	s9,24(sp)
    80003fce:	6d42                	ld	s10,16(sp)
    80003fd0:	6da2                	ld	s11,8(sp)
    80003fd2:	6165                	addi	sp,sp,112
    80003fd4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fd6:	89d6                	mv	s3,s5
    80003fd8:	bff1                	j	80003fb4 <readi+0xce>
    return 0;
    80003fda:	4501                	li	a0,0
}
    80003fdc:	8082                	ret

0000000080003fde <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fde:	457c                	lw	a5,76(a0)
    80003fe0:	10d7e863          	bltu	a5,a3,800040f0 <writei+0x112>
{
    80003fe4:	7159                	addi	sp,sp,-112
    80003fe6:	f486                	sd	ra,104(sp)
    80003fe8:	f0a2                	sd	s0,96(sp)
    80003fea:	eca6                	sd	s1,88(sp)
    80003fec:	e8ca                	sd	s2,80(sp)
    80003fee:	e4ce                	sd	s3,72(sp)
    80003ff0:	e0d2                	sd	s4,64(sp)
    80003ff2:	fc56                	sd	s5,56(sp)
    80003ff4:	f85a                	sd	s6,48(sp)
    80003ff6:	f45e                	sd	s7,40(sp)
    80003ff8:	f062                	sd	s8,32(sp)
    80003ffa:	ec66                	sd	s9,24(sp)
    80003ffc:	e86a                	sd	s10,16(sp)
    80003ffe:	e46e                	sd	s11,8(sp)
    80004000:	1880                	addi	s0,sp,112
    80004002:	8aaa                	mv	s5,a0
    80004004:	8bae                	mv	s7,a1
    80004006:	8a32                	mv	s4,a2
    80004008:	8936                	mv	s2,a3
    8000400a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000400c:	00e687bb          	addw	a5,a3,a4
    80004010:	0ed7e263          	bltu	a5,a3,800040f4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004014:	00043737          	lui	a4,0x43
    80004018:	0ef76063          	bltu	a4,a5,800040f8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000401c:	0c0b0863          	beqz	s6,800040ec <writei+0x10e>
    80004020:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004022:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004026:	5c7d                	li	s8,-1
    80004028:	a091                	j	8000406c <writei+0x8e>
    8000402a:	020d1d93          	slli	s11,s10,0x20
    8000402e:	020ddd93          	srli	s11,s11,0x20
    80004032:	05848793          	addi	a5,s1,88
    80004036:	86ee                	mv	a3,s11
    80004038:	8652                	mv	a2,s4
    8000403a:	85de                	mv	a1,s7
    8000403c:	953e                	add	a0,a0,a5
    8000403e:	ffffe097          	auipc	ra,0xffffe
    80004042:	724080e7          	jalr	1828(ra) # 80002762 <either_copyin>
    80004046:	07850263          	beq	a0,s8,800040aa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000404a:	8526                	mv	a0,s1
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	780080e7          	jalr	1920(ra) # 800047cc <log_write>
    brelse(bp);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	4f2080e7          	jalr	1266(ra) # 80003548 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000405e:	013d09bb          	addw	s3,s10,s3
    80004062:	012d093b          	addw	s2,s10,s2
    80004066:	9a6e                	add	s4,s4,s11
    80004068:	0569f663          	bgeu	s3,s6,800040b4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000406c:	00a9559b          	srliw	a1,s2,0xa
    80004070:	8556                	mv	a0,s5
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	7a0080e7          	jalr	1952(ra) # 80003812 <bmap>
    8000407a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000407e:	c99d                	beqz	a1,800040b4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004080:	000aa503          	lw	a0,0(s5)
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	394080e7          	jalr	916(ra) # 80003418 <bread>
    8000408c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408e:	3ff97513          	andi	a0,s2,1023
    80004092:	40ac87bb          	subw	a5,s9,a0
    80004096:	413b073b          	subw	a4,s6,s3
    8000409a:	8d3e                	mv	s10,a5
    8000409c:	2781                	sext.w	a5,a5
    8000409e:	0007069b          	sext.w	a3,a4
    800040a2:	f8f6f4e3          	bgeu	a3,a5,8000402a <writei+0x4c>
    800040a6:	8d3a                	mv	s10,a4
    800040a8:	b749                	j	8000402a <writei+0x4c>
      brelse(bp);
    800040aa:	8526                	mv	a0,s1
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	49c080e7          	jalr	1180(ra) # 80003548 <brelse>
  }

  if(off > ip->size)
    800040b4:	04caa783          	lw	a5,76(s5)
    800040b8:	0127f463          	bgeu	a5,s2,800040c0 <writei+0xe2>
    ip->size = off;
    800040bc:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040c0:	8556                	mv	a0,s5
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	aa6080e7          	jalr	-1370(ra) # 80003b68 <iupdate>

  return tot;
    800040ca:	0009851b          	sext.w	a0,s3
}
    800040ce:	70a6                	ld	ra,104(sp)
    800040d0:	7406                	ld	s0,96(sp)
    800040d2:	64e6                	ld	s1,88(sp)
    800040d4:	6946                	ld	s2,80(sp)
    800040d6:	69a6                	ld	s3,72(sp)
    800040d8:	6a06                	ld	s4,64(sp)
    800040da:	7ae2                	ld	s5,56(sp)
    800040dc:	7b42                	ld	s6,48(sp)
    800040de:	7ba2                	ld	s7,40(sp)
    800040e0:	7c02                	ld	s8,32(sp)
    800040e2:	6ce2                	ld	s9,24(sp)
    800040e4:	6d42                	ld	s10,16(sp)
    800040e6:	6da2                	ld	s11,8(sp)
    800040e8:	6165                	addi	sp,sp,112
    800040ea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ec:	89da                	mv	s3,s6
    800040ee:	bfc9                	j	800040c0 <writei+0xe2>
    return -1;
    800040f0:	557d                	li	a0,-1
}
    800040f2:	8082                	ret
    return -1;
    800040f4:	557d                	li	a0,-1
    800040f6:	bfe1                	j	800040ce <writei+0xf0>
    return -1;
    800040f8:	557d                	li	a0,-1
    800040fa:	bfd1                	j	800040ce <writei+0xf0>

00000000800040fc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040fc:	1141                	addi	sp,sp,-16
    800040fe:	e406                	sd	ra,8(sp)
    80004100:	e022                	sd	s0,0(sp)
    80004102:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004104:	4639                	li	a2,14
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	d9e080e7          	jalr	-610(ra) # 80000ea4 <strncmp>
}
    8000410e:	60a2                	ld	ra,8(sp)
    80004110:	6402                	ld	s0,0(sp)
    80004112:	0141                	addi	sp,sp,16
    80004114:	8082                	ret

0000000080004116 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004116:	7139                	addi	sp,sp,-64
    80004118:	fc06                	sd	ra,56(sp)
    8000411a:	f822                	sd	s0,48(sp)
    8000411c:	f426                	sd	s1,40(sp)
    8000411e:	f04a                	sd	s2,32(sp)
    80004120:	ec4e                	sd	s3,24(sp)
    80004122:	e852                	sd	s4,16(sp)
    80004124:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004126:	04451703          	lh	a4,68(a0)
    8000412a:	4785                	li	a5,1
    8000412c:	00f71a63          	bne	a4,a5,80004140 <dirlookup+0x2a>
    80004130:	892a                	mv	s2,a0
    80004132:	89ae                	mv	s3,a1
    80004134:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004136:	457c                	lw	a5,76(a0)
    80004138:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000413a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413c:	e79d                	bnez	a5,8000416a <dirlookup+0x54>
    8000413e:	a8a5                	j	800041b6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004140:	00004517          	auipc	a0,0x4
    80004144:	4d050513          	addi	a0,a0,1232 # 80008610 <syscalls+0x1b0>
    80004148:	ffffc097          	auipc	ra,0xffffc
    8000414c:	3f6080e7          	jalr	1014(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004150:	00004517          	auipc	a0,0x4
    80004154:	4d850513          	addi	a0,a0,1240 # 80008628 <syscalls+0x1c8>
    80004158:	ffffc097          	auipc	ra,0xffffc
    8000415c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004160:	24c1                	addiw	s1,s1,16
    80004162:	04c92783          	lw	a5,76(s2)
    80004166:	04f4f763          	bgeu	s1,a5,800041b4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000416a:	4741                	li	a4,16
    8000416c:	86a6                	mv	a3,s1
    8000416e:	fc040613          	addi	a2,s0,-64
    80004172:	4581                	li	a1,0
    80004174:	854a                	mv	a0,s2
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	d70080e7          	jalr	-656(ra) # 80003ee6 <readi>
    8000417e:	47c1                	li	a5,16
    80004180:	fcf518e3          	bne	a0,a5,80004150 <dirlookup+0x3a>
    if(de.inum == 0)
    80004184:	fc045783          	lhu	a5,-64(s0)
    80004188:	dfe1                	beqz	a5,80004160 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000418a:	fc240593          	addi	a1,s0,-62
    8000418e:	854e                	mv	a0,s3
    80004190:	00000097          	auipc	ra,0x0
    80004194:	f6c080e7          	jalr	-148(ra) # 800040fc <namecmp>
    80004198:	f561                	bnez	a0,80004160 <dirlookup+0x4a>
      if(poff)
    8000419a:	000a0463          	beqz	s4,800041a2 <dirlookup+0x8c>
        *poff = off;
    8000419e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041a2:	fc045583          	lhu	a1,-64(s0)
    800041a6:	00092503          	lw	a0,0(s2)
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	750080e7          	jalr	1872(ra) # 800038fa <iget>
    800041b2:	a011                	j	800041b6 <dirlookup+0xa0>
  return 0;
    800041b4:	4501                	li	a0,0
}
    800041b6:	70e2                	ld	ra,56(sp)
    800041b8:	7442                	ld	s0,48(sp)
    800041ba:	74a2                	ld	s1,40(sp)
    800041bc:	7902                	ld	s2,32(sp)
    800041be:	69e2                	ld	s3,24(sp)
    800041c0:	6a42                	ld	s4,16(sp)
    800041c2:	6121                	addi	sp,sp,64
    800041c4:	8082                	ret

00000000800041c6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041c6:	711d                	addi	sp,sp,-96
    800041c8:	ec86                	sd	ra,88(sp)
    800041ca:	e8a2                	sd	s0,80(sp)
    800041cc:	e4a6                	sd	s1,72(sp)
    800041ce:	e0ca                	sd	s2,64(sp)
    800041d0:	fc4e                	sd	s3,56(sp)
    800041d2:	f852                	sd	s4,48(sp)
    800041d4:	f456                	sd	s5,40(sp)
    800041d6:	f05a                	sd	s6,32(sp)
    800041d8:	ec5e                	sd	s7,24(sp)
    800041da:	e862                	sd	s8,16(sp)
    800041dc:	e466                	sd	s9,8(sp)
    800041de:	1080                	addi	s0,sp,96
    800041e0:	84aa                	mv	s1,a0
    800041e2:	8aae                	mv	s5,a1
    800041e4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041e6:	00054703          	lbu	a4,0(a0)
    800041ea:	02f00793          	li	a5,47
    800041ee:	02f70363          	beq	a4,a5,80004214 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041f2:	ffffe097          	auipc	ra,0xffffe
    800041f6:	a4a080e7          	jalr	-1462(ra) # 80001c3c <myproc>
    800041fa:	15053503          	ld	a0,336(a0)
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	9f6080e7          	jalr	-1546(ra) # 80003bf4 <idup>
    80004206:	89aa                	mv	s3,a0
  while(*path == '/')
    80004208:	02f00913          	li	s2,47
  len = path - s;
    8000420c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000420e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004210:	4b85                	li	s7,1
    80004212:	a865                	j	800042ca <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004214:	4585                	li	a1,1
    80004216:	4505                	li	a0,1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	6e2080e7          	jalr	1762(ra) # 800038fa <iget>
    80004220:	89aa                	mv	s3,a0
    80004222:	b7dd                	j	80004208 <namex+0x42>
      iunlockput(ip);
    80004224:	854e                	mv	a0,s3
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	c6e080e7          	jalr	-914(ra) # 80003e94 <iunlockput>
      return 0;
    8000422e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004230:	854e                	mv	a0,s3
    80004232:	60e6                	ld	ra,88(sp)
    80004234:	6446                	ld	s0,80(sp)
    80004236:	64a6                	ld	s1,72(sp)
    80004238:	6906                	ld	s2,64(sp)
    8000423a:	79e2                	ld	s3,56(sp)
    8000423c:	7a42                	ld	s4,48(sp)
    8000423e:	7aa2                	ld	s5,40(sp)
    80004240:	7b02                	ld	s6,32(sp)
    80004242:	6be2                	ld	s7,24(sp)
    80004244:	6c42                	ld	s8,16(sp)
    80004246:	6ca2                	ld	s9,8(sp)
    80004248:	6125                	addi	sp,sp,96
    8000424a:	8082                	ret
      iunlock(ip);
    8000424c:	854e                	mv	a0,s3
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	aa6080e7          	jalr	-1370(ra) # 80003cf4 <iunlock>
      return ip;
    80004256:	bfe9                	j	80004230 <namex+0x6a>
      iunlockput(ip);
    80004258:	854e                	mv	a0,s3
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	c3a080e7          	jalr	-966(ra) # 80003e94 <iunlockput>
      return 0;
    80004262:	89e6                	mv	s3,s9
    80004264:	b7f1                	j	80004230 <namex+0x6a>
  len = path - s;
    80004266:	40b48633          	sub	a2,s1,a1
    8000426a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000426e:	099c5463          	bge	s8,s9,800042f6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004272:	4639                	li	a2,14
    80004274:	8552                	mv	a0,s4
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	bba080e7          	jalr	-1094(ra) # 80000e30 <memmove>
  while(*path == '/')
    8000427e:	0004c783          	lbu	a5,0(s1)
    80004282:	01279763          	bne	a5,s2,80004290 <namex+0xca>
    path++;
    80004286:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004288:	0004c783          	lbu	a5,0(s1)
    8000428c:	ff278de3          	beq	a5,s2,80004286 <namex+0xc0>
    ilock(ip);
    80004290:	854e                	mv	a0,s3
    80004292:	00000097          	auipc	ra,0x0
    80004296:	9a0080e7          	jalr	-1632(ra) # 80003c32 <ilock>
    if(ip->type != T_DIR){
    8000429a:	04499783          	lh	a5,68(s3)
    8000429e:	f97793e3          	bne	a5,s7,80004224 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042a2:	000a8563          	beqz	s5,800042ac <namex+0xe6>
    800042a6:	0004c783          	lbu	a5,0(s1)
    800042aa:	d3cd                	beqz	a5,8000424c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042ac:	865a                	mv	a2,s6
    800042ae:	85d2                	mv	a1,s4
    800042b0:	854e                	mv	a0,s3
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	e64080e7          	jalr	-412(ra) # 80004116 <dirlookup>
    800042ba:	8caa                	mv	s9,a0
    800042bc:	dd51                	beqz	a0,80004258 <namex+0x92>
    iunlockput(ip);
    800042be:	854e                	mv	a0,s3
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	bd4080e7          	jalr	-1068(ra) # 80003e94 <iunlockput>
    ip = next;
    800042c8:	89e6                	mv	s3,s9
  while(*path == '/')
    800042ca:	0004c783          	lbu	a5,0(s1)
    800042ce:	05279763          	bne	a5,s2,8000431c <namex+0x156>
    path++;
    800042d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042d4:	0004c783          	lbu	a5,0(s1)
    800042d8:	ff278de3          	beq	a5,s2,800042d2 <namex+0x10c>
  if(*path == 0)
    800042dc:	c79d                	beqz	a5,8000430a <namex+0x144>
    path++;
    800042de:	85a6                	mv	a1,s1
  len = path - s;
    800042e0:	8cda                	mv	s9,s6
    800042e2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800042e4:	01278963          	beq	a5,s2,800042f6 <namex+0x130>
    800042e8:	dfbd                	beqz	a5,80004266 <namex+0xa0>
    path++;
    800042ea:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042ec:	0004c783          	lbu	a5,0(s1)
    800042f0:	ff279ce3          	bne	a5,s2,800042e8 <namex+0x122>
    800042f4:	bf8d                	j	80004266 <namex+0xa0>
    memmove(name, s, len);
    800042f6:	2601                	sext.w	a2,a2
    800042f8:	8552                	mv	a0,s4
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	b36080e7          	jalr	-1226(ra) # 80000e30 <memmove>
    name[len] = 0;
    80004302:	9cd2                	add	s9,s9,s4
    80004304:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004308:	bf9d                	j	8000427e <namex+0xb8>
  if(nameiparent){
    8000430a:	f20a83e3          	beqz	s5,80004230 <namex+0x6a>
    iput(ip);
    8000430e:	854e                	mv	a0,s3
    80004310:	00000097          	auipc	ra,0x0
    80004314:	adc080e7          	jalr	-1316(ra) # 80003dec <iput>
    return 0;
    80004318:	4981                	li	s3,0
    8000431a:	bf19                	j	80004230 <namex+0x6a>
  if(*path == 0)
    8000431c:	d7fd                	beqz	a5,8000430a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000431e:	0004c783          	lbu	a5,0(s1)
    80004322:	85a6                	mv	a1,s1
    80004324:	b7d1                	j	800042e8 <namex+0x122>

0000000080004326 <dirlink>:
{
    80004326:	7139                	addi	sp,sp,-64
    80004328:	fc06                	sd	ra,56(sp)
    8000432a:	f822                	sd	s0,48(sp)
    8000432c:	f426                	sd	s1,40(sp)
    8000432e:	f04a                	sd	s2,32(sp)
    80004330:	ec4e                	sd	s3,24(sp)
    80004332:	e852                	sd	s4,16(sp)
    80004334:	0080                	addi	s0,sp,64
    80004336:	892a                	mv	s2,a0
    80004338:	8a2e                	mv	s4,a1
    8000433a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000433c:	4601                	li	a2,0
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	dd8080e7          	jalr	-552(ra) # 80004116 <dirlookup>
    80004346:	e93d                	bnez	a0,800043bc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004348:	04c92483          	lw	s1,76(s2)
    8000434c:	c49d                	beqz	s1,8000437a <dirlink+0x54>
    8000434e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004350:	4741                	li	a4,16
    80004352:	86a6                	mv	a3,s1
    80004354:	fc040613          	addi	a2,s0,-64
    80004358:	4581                	li	a1,0
    8000435a:	854a                	mv	a0,s2
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	b8a080e7          	jalr	-1142(ra) # 80003ee6 <readi>
    80004364:	47c1                	li	a5,16
    80004366:	06f51163          	bne	a0,a5,800043c8 <dirlink+0xa2>
    if(de.inum == 0)
    8000436a:	fc045783          	lhu	a5,-64(s0)
    8000436e:	c791                	beqz	a5,8000437a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004370:	24c1                	addiw	s1,s1,16
    80004372:	04c92783          	lw	a5,76(s2)
    80004376:	fcf4ede3          	bltu	s1,a5,80004350 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000437a:	4639                	li	a2,14
    8000437c:	85d2                	mv	a1,s4
    8000437e:	fc240513          	addi	a0,s0,-62
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	b5e080e7          	jalr	-1186(ra) # 80000ee0 <strncpy>
  de.inum = inum;
    8000438a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000438e:	4741                	li	a4,16
    80004390:	86a6                	mv	a3,s1
    80004392:	fc040613          	addi	a2,s0,-64
    80004396:	4581                	li	a1,0
    80004398:	854a                	mv	a0,s2
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	c44080e7          	jalr	-956(ra) # 80003fde <writei>
    800043a2:	1541                	addi	a0,a0,-16
    800043a4:	00a03533          	snez	a0,a0
    800043a8:	40a00533          	neg	a0,a0
}
    800043ac:	70e2                	ld	ra,56(sp)
    800043ae:	7442                	ld	s0,48(sp)
    800043b0:	74a2                	ld	s1,40(sp)
    800043b2:	7902                	ld	s2,32(sp)
    800043b4:	69e2                	ld	s3,24(sp)
    800043b6:	6a42                	ld	s4,16(sp)
    800043b8:	6121                	addi	sp,sp,64
    800043ba:	8082                	ret
    iput(ip);
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	a30080e7          	jalr	-1488(ra) # 80003dec <iput>
    return -1;
    800043c4:	557d                	li	a0,-1
    800043c6:	b7dd                	j	800043ac <dirlink+0x86>
      panic("dirlink read");
    800043c8:	00004517          	auipc	a0,0x4
    800043cc:	27050513          	addi	a0,a0,624 # 80008638 <syscalls+0x1d8>
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>

00000000800043d8 <namei>:

struct inode*
namei(char *path)
{
    800043d8:	1101                	addi	sp,sp,-32
    800043da:	ec06                	sd	ra,24(sp)
    800043dc:	e822                	sd	s0,16(sp)
    800043de:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043e0:	fe040613          	addi	a2,s0,-32
    800043e4:	4581                	li	a1,0
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	de0080e7          	jalr	-544(ra) # 800041c6 <namex>
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	6105                	addi	sp,sp,32
    800043f4:	8082                	ret

00000000800043f6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043f6:	1141                	addi	sp,sp,-16
    800043f8:	e406                	sd	ra,8(sp)
    800043fa:	e022                	sd	s0,0(sp)
    800043fc:	0800                	addi	s0,sp,16
    800043fe:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004400:	4585                	li	a1,1
    80004402:	00000097          	auipc	ra,0x0
    80004406:	dc4080e7          	jalr	-572(ra) # 800041c6 <namex>
}
    8000440a:	60a2                	ld	ra,8(sp)
    8000440c:	6402                	ld	s0,0(sp)
    8000440e:	0141                	addi	sp,sp,16
    80004410:	8082                	ret

0000000080004412 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004412:	1101                	addi	sp,sp,-32
    80004414:	ec06                	sd	ra,24(sp)
    80004416:	e822                	sd	s0,16(sp)
    80004418:	e426                	sd	s1,8(sp)
    8000441a:	e04a                	sd	s2,0(sp)
    8000441c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000441e:	0023d917          	auipc	s2,0x23d
    80004422:	b1a90913          	addi	s2,s2,-1254 # 80240f38 <log>
    80004426:	01892583          	lw	a1,24(s2)
    8000442a:	02892503          	lw	a0,40(s2)
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	fea080e7          	jalr	-22(ra) # 80003418 <bread>
    80004436:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004438:	02c92683          	lw	a3,44(s2)
    8000443c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000443e:	02d05763          	blez	a3,8000446c <write_head+0x5a>
    80004442:	0023d797          	auipc	a5,0x23d
    80004446:	b2678793          	addi	a5,a5,-1242 # 80240f68 <log+0x30>
    8000444a:	05c50713          	addi	a4,a0,92
    8000444e:	36fd                	addiw	a3,a3,-1
    80004450:	1682                	slli	a3,a3,0x20
    80004452:	9281                	srli	a3,a3,0x20
    80004454:	068a                	slli	a3,a3,0x2
    80004456:	0023d617          	auipc	a2,0x23d
    8000445a:	b1660613          	addi	a2,a2,-1258 # 80240f6c <log+0x34>
    8000445e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004460:	4390                	lw	a2,0(a5)
    80004462:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004464:	0791                	addi	a5,a5,4
    80004466:	0711                	addi	a4,a4,4
    80004468:	fed79ce3          	bne	a5,a3,80004460 <write_head+0x4e>
  }
  bwrite(buf);
    8000446c:	8526                	mv	a0,s1
    8000446e:	fffff097          	auipc	ra,0xfffff
    80004472:	09c080e7          	jalr	156(ra) # 8000350a <bwrite>
  brelse(buf);
    80004476:	8526                	mv	a0,s1
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	0d0080e7          	jalr	208(ra) # 80003548 <brelse>
}
    80004480:	60e2                	ld	ra,24(sp)
    80004482:	6442                	ld	s0,16(sp)
    80004484:	64a2                	ld	s1,8(sp)
    80004486:	6902                	ld	s2,0(sp)
    80004488:	6105                	addi	sp,sp,32
    8000448a:	8082                	ret

000000008000448c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448c:	0023d797          	auipc	a5,0x23d
    80004490:	ad87a783          	lw	a5,-1320(a5) # 80240f64 <log+0x2c>
    80004494:	0af05d63          	blez	a5,8000454e <install_trans+0xc2>
{
    80004498:	7139                	addi	sp,sp,-64
    8000449a:	fc06                	sd	ra,56(sp)
    8000449c:	f822                	sd	s0,48(sp)
    8000449e:	f426                	sd	s1,40(sp)
    800044a0:	f04a                	sd	s2,32(sp)
    800044a2:	ec4e                	sd	s3,24(sp)
    800044a4:	e852                	sd	s4,16(sp)
    800044a6:	e456                	sd	s5,8(sp)
    800044a8:	e05a                	sd	s6,0(sp)
    800044aa:	0080                	addi	s0,sp,64
    800044ac:	8b2a                	mv	s6,a0
    800044ae:	0023da97          	auipc	s5,0x23d
    800044b2:	abaa8a93          	addi	s5,s5,-1350 # 80240f68 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044b8:	0023d997          	auipc	s3,0x23d
    800044bc:	a8098993          	addi	s3,s3,-1408 # 80240f38 <log>
    800044c0:	a00d                	j	800044e2 <install_trans+0x56>
    brelse(lbuf);
    800044c2:	854a                	mv	a0,s2
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	084080e7          	jalr	132(ra) # 80003548 <brelse>
    brelse(dbuf);
    800044cc:	8526                	mv	a0,s1
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	07a080e7          	jalr	122(ra) # 80003548 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d6:	2a05                	addiw	s4,s4,1
    800044d8:	0a91                	addi	s5,s5,4
    800044da:	02c9a783          	lw	a5,44(s3)
    800044de:	04fa5e63          	bge	s4,a5,8000453a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044e2:	0189a583          	lw	a1,24(s3)
    800044e6:	014585bb          	addw	a1,a1,s4
    800044ea:	2585                	addiw	a1,a1,1
    800044ec:	0289a503          	lw	a0,40(s3)
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	f28080e7          	jalr	-216(ra) # 80003418 <bread>
    800044f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044fa:	000aa583          	lw	a1,0(s5)
    800044fe:	0289a503          	lw	a0,40(s3)
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	f16080e7          	jalr	-234(ra) # 80003418 <bread>
    8000450a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000450c:	40000613          	li	a2,1024
    80004510:	05890593          	addi	a1,s2,88
    80004514:	05850513          	addi	a0,a0,88
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	918080e7          	jalr	-1768(ra) # 80000e30 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	fe8080e7          	jalr	-24(ra) # 8000350a <bwrite>
    if(recovering == 0)
    8000452a:	f80b1ce3          	bnez	s6,800044c2 <install_trans+0x36>
      bunpin(dbuf);
    8000452e:	8526                	mv	a0,s1
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	0f2080e7          	jalr	242(ra) # 80003622 <bunpin>
    80004538:	b769                	j	800044c2 <install_trans+0x36>
}
    8000453a:	70e2                	ld	ra,56(sp)
    8000453c:	7442                	ld	s0,48(sp)
    8000453e:	74a2                	ld	s1,40(sp)
    80004540:	7902                	ld	s2,32(sp)
    80004542:	69e2                	ld	s3,24(sp)
    80004544:	6a42                	ld	s4,16(sp)
    80004546:	6aa2                	ld	s5,8(sp)
    80004548:	6b02                	ld	s6,0(sp)
    8000454a:	6121                	addi	sp,sp,64
    8000454c:	8082                	ret
    8000454e:	8082                	ret

0000000080004550 <initlog>:
{
    80004550:	7179                	addi	sp,sp,-48
    80004552:	f406                	sd	ra,40(sp)
    80004554:	f022                	sd	s0,32(sp)
    80004556:	ec26                	sd	s1,24(sp)
    80004558:	e84a                	sd	s2,16(sp)
    8000455a:	e44e                	sd	s3,8(sp)
    8000455c:	1800                	addi	s0,sp,48
    8000455e:	892a                	mv	s2,a0
    80004560:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004562:	0023d497          	auipc	s1,0x23d
    80004566:	9d648493          	addi	s1,s1,-1578 # 80240f38 <log>
    8000456a:	00004597          	auipc	a1,0x4
    8000456e:	0de58593          	addi	a1,a1,222 # 80008648 <syscalls+0x1e8>
    80004572:	8526                	mv	a0,s1
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	6d4080e7          	jalr	1748(ra) # 80000c48 <initlock>
  log.start = sb->logstart;
    8000457c:	0149a583          	lw	a1,20(s3)
    80004580:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004582:	0109a783          	lw	a5,16(s3)
    80004586:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004588:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000458c:	854a                	mv	a0,s2
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	e8a080e7          	jalr	-374(ra) # 80003418 <bread>
  log.lh.n = lh->n;
    80004596:	4d34                	lw	a3,88(a0)
    80004598:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000459a:	02d05563          	blez	a3,800045c4 <initlog+0x74>
    8000459e:	05c50793          	addi	a5,a0,92
    800045a2:	0023d717          	auipc	a4,0x23d
    800045a6:	9c670713          	addi	a4,a4,-1594 # 80240f68 <log+0x30>
    800045aa:	36fd                	addiw	a3,a3,-1
    800045ac:	1682                	slli	a3,a3,0x20
    800045ae:	9281                	srli	a3,a3,0x20
    800045b0:	068a                	slli	a3,a3,0x2
    800045b2:	06050613          	addi	a2,a0,96
    800045b6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045b8:	4390                	lw	a2,0(a5)
    800045ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045bc:	0791                	addi	a5,a5,4
    800045be:	0711                	addi	a4,a4,4
    800045c0:	fed79ce3          	bne	a5,a3,800045b8 <initlog+0x68>
  brelse(buf);
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	f84080e7          	jalr	-124(ra) # 80003548 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045cc:	4505                	li	a0,1
    800045ce:	00000097          	auipc	ra,0x0
    800045d2:	ebe080e7          	jalr	-322(ra) # 8000448c <install_trans>
  log.lh.n = 0;
    800045d6:	0023d797          	auipc	a5,0x23d
    800045da:	9807a723          	sw	zero,-1650(a5) # 80240f64 <log+0x2c>
  write_head(); // clear the log
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	e34080e7          	jalr	-460(ra) # 80004412 <write_head>
}
    800045e6:	70a2                	ld	ra,40(sp)
    800045e8:	7402                	ld	s0,32(sp)
    800045ea:	64e2                	ld	s1,24(sp)
    800045ec:	6942                	ld	s2,16(sp)
    800045ee:	69a2                	ld	s3,8(sp)
    800045f0:	6145                	addi	sp,sp,48
    800045f2:	8082                	ret

00000000800045f4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045f4:	1101                	addi	sp,sp,-32
    800045f6:	ec06                	sd	ra,24(sp)
    800045f8:	e822                	sd	s0,16(sp)
    800045fa:	e426                	sd	s1,8(sp)
    800045fc:	e04a                	sd	s2,0(sp)
    800045fe:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004600:	0023d517          	auipc	a0,0x23d
    80004604:	93850513          	addi	a0,a0,-1736 # 80240f38 <log>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	6d0080e7          	jalr	1744(ra) # 80000cd8 <acquire>
  while(1){
    if(log.committing){
    80004610:	0023d497          	auipc	s1,0x23d
    80004614:	92848493          	addi	s1,s1,-1752 # 80240f38 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004618:	4979                	li	s2,30
    8000461a:	a039                	j	80004628 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000461c:	85a6                	mv	a1,s1
    8000461e:	8526                	mv	a0,s1
    80004620:	ffffe097          	auipc	ra,0xffffe
    80004624:	cd8080e7          	jalr	-808(ra) # 800022f8 <sleep>
    if(log.committing){
    80004628:	50dc                	lw	a5,36(s1)
    8000462a:	fbed                	bnez	a5,8000461c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000462c:	509c                	lw	a5,32(s1)
    8000462e:	0017871b          	addiw	a4,a5,1
    80004632:	0007069b          	sext.w	a3,a4
    80004636:	0027179b          	slliw	a5,a4,0x2
    8000463a:	9fb9                	addw	a5,a5,a4
    8000463c:	0017979b          	slliw	a5,a5,0x1
    80004640:	54d8                	lw	a4,44(s1)
    80004642:	9fb9                	addw	a5,a5,a4
    80004644:	00f95963          	bge	s2,a5,80004656 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004648:	85a6                	mv	a1,s1
    8000464a:	8526                	mv	a0,s1
    8000464c:	ffffe097          	auipc	ra,0xffffe
    80004650:	cac080e7          	jalr	-852(ra) # 800022f8 <sleep>
    80004654:	bfd1                	j	80004628 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004656:	0023d517          	auipc	a0,0x23d
    8000465a:	8e250513          	addi	a0,a0,-1822 # 80240f38 <log>
    8000465e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	72c080e7          	jalr	1836(ra) # 80000d8c <release>
      break;
    }
  }
}
    80004668:	60e2                	ld	ra,24(sp)
    8000466a:	6442                	ld	s0,16(sp)
    8000466c:	64a2                	ld	s1,8(sp)
    8000466e:	6902                	ld	s2,0(sp)
    80004670:	6105                	addi	sp,sp,32
    80004672:	8082                	ret

0000000080004674 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004674:	7139                	addi	sp,sp,-64
    80004676:	fc06                	sd	ra,56(sp)
    80004678:	f822                	sd	s0,48(sp)
    8000467a:	f426                	sd	s1,40(sp)
    8000467c:	f04a                	sd	s2,32(sp)
    8000467e:	ec4e                	sd	s3,24(sp)
    80004680:	e852                	sd	s4,16(sp)
    80004682:	e456                	sd	s5,8(sp)
    80004684:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004686:	0023d497          	auipc	s1,0x23d
    8000468a:	8b248493          	addi	s1,s1,-1870 # 80240f38 <log>
    8000468e:	8526                	mv	a0,s1
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	648080e7          	jalr	1608(ra) # 80000cd8 <acquire>
  log.outstanding -= 1;
    80004698:	509c                	lw	a5,32(s1)
    8000469a:	37fd                	addiw	a5,a5,-1
    8000469c:	0007891b          	sext.w	s2,a5
    800046a0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046a2:	50dc                	lw	a5,36(s1)
    800046a4:	e7b9                	bnez	a5,800046f2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046a6:	04091e63          	bnez	s2,80004702 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046aa:	0023d497          	auipc	s1,0x23d
    800046ae:	88e48493          	addi	s1,s1,-1906 # 80240f38 <log>
    800046b2:	4785                	li	a5,1
    800046b4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046b6:	8526                	mv	a0,s1
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	6d4080e7          	jalr	1748(ra) # 80000d8c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046c0:	54dc                	lw	a5,44(s1)
    800046c2:	06f04763          	bgtz	a5,80004730 <end_op+0xbc>
    acquire(&log.lock);
    800046c6:	0023d497          	auipc	s1,0x23d
    800046ca:	87248493          	addi	s1,s1,-1934 # 80240f38 <log>
    800046ce:	8526                	mv	a0,s1
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	608080e7          	jalr	1544(ra) # 80000cd8 <acquire>
    log.committing = 0;
    800046d8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046dc:	8526                	mv	a0,s1
    800046de:	ffffe097          	auipc	ra,0xffffe
    800046e2:	c7e080e7          	jalr	-898(ra) # 8000235c <wakeup>
    release(&log.lock);
    800046e6:	8526                	mv	a0,s1
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	6a4080e7          	jalr	1700(ra) # 80000d8c <release>
}
    800046f0:	a03d                	j	8000471e <end_op+0xaa>
    panic("log.committing");
    800046f2:	00004517          	auipc	a0,0x4
    800046f6:	f5e50513          	addi	a0,a0,-162 # 80008650 <syscalls+0x1f0>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>
    wakeup(&log);
    80004702:	0023d497          	auipc	s1,0x23d
    80004706:	83648493          	addi	s1,s1,-1994 # 80240f38 <log>
    8000470a:	8526                	mv	a0,s1
    8000470c:	ffffe097          	auipc	ra,0xffffe
    80004710:	c50080e7          	jalr	-944(ra) # 8000235c <wakeup>
  release(&log.lock);
    80004714:	8526                	mv	a0,s1
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	676080e7          	jalr	1654(ra) # 80000d8c <release>
}
    8000471e:	70e2                	ld	ra,56(sp)
    80004720:	7442                	ld	s0,48(sp)
    80004722:	74a2                	ld	s1,40(sp)
    80004724:	7902                	ld	s2,32(sp)
    80004726:	69e2                	ld	s3,24(sp)
    80004728:	6a42                	ld	s4,16(sp)
    8000472a:	6aa2                	ld	s5,8(sp)
    8000472c:	6121                	addi	sp,sp,64
    8000472e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004730:	0023da97          	auipc	s5,0x23d
    80004734:	838a8a93          	addi	s5,s5,-1992 # 80240f68 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004738:	0023da17          	auipc	s4,0x23d
    8000473c:	800a0a13          	addi	s4,s4,-2048 # 80240f38 <log>
    80004740:	018a2583          	lw	a1,24(s4)
    80004744:	012585bb          	addw	a1,a1,s2
    80004748:	2585                	addiw	a1,a1,1
    8000474a:	028a2503          	lw	a0,40(s4)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	cca080e7          	jalr	-822(ra) # 80003418 <bread>
    80004756:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004758:	000aa583          	lw	a1,0(s5)
    8000475c:	028a2503          	lw	a0,40(s4)
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	cb8080e7          	jalr	-840(ra) # 80003418 <bread>
    80004768:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000476a:	40000613          	li	a2,1024
    8000476e:	05850593          	addi	a1,a0,88
    80004772:	05848513          	addi	a0,s1,88
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	6ba080e7          	jalr	1722(ra) # 80000e30 <memmove>
    bwrite(to);  // write the log
    8000477e:	8526                	mv	a0,s1
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	d8a080e7          	jalr	-630(ra) # 8000350a <bwrite>
    brelse(from);
    80004788:	854e                	mv	a0,s3
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	dbe080e7          	jalr	-578(ra) # 80003548 <brelse>
    brelse(to);
    80004792:	8526                	mv	a0,s1
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	db4080e7          	jalr	-588(ra) # 80003548 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000479c:	2905                	addiw	s2,s2,1
    8000479e:	0a91                	addi	s5,s5,4
    800047a0:	02ca2783          	lw	a5,44(s4)
    800047a4:	f8f94ee3          	blt	s2,a5,80004740 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047a8:	00000097          	auipc	ra,0x0
    800047ac:	c6a080e7          	jalr	-918(ra) # 80004412 <write_head>
    install_trans(0); // Now install writes to home locations
    800047b0:	4501                	li	a0,0
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	cda080e7          	jalr	-806(ra) # 8000448c <install_trans>
    log.lh.n = 0;
    800047ba:	0023c797          	auipc	a5,0x23c
    800047be:	7a07a523          	sw	zero,1962(a5) # 80240f64 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	c50080e7          	jalr	-944(ra) # 80004412 <write_head>
    800047ca:	bdf5                	j	800046c6 <end_op+0x52>

00000000800047cc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	e04a                	sd	s2,0(sp)
    800047d6:	1000                	addi	s0,sp,32
    800047d8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047da:	0023c917          	auipc	s2,0x23c
    800047de:	75e90913          	addi	s2,s2,1886 # 80240f38 <log>
    800047e2:	854a                	mv	a0,s2
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4f4080e7          	jalr	1268(ra) # 80000cd8 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047ec:	02c92603          	lw	a2,44(s2)
    800047f0:	47f5                	li	a5,29
    800047f2:	06c7c563          	blt	a5,a2,8000485c <log_write+0x90>
    800047f6:	0023c797          	auipc	a5,0x23c
    800047fa:	75e7a783          	lw	a5,1886(a5) # 80240f54 <log+0x1c>
    800047fe:	37fd                	addiw	a5,a5,-1
    80004800:	04f65e63          	bge	a2,a5,8000485c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004804:	0023c797          	auipc	a5,0x23c
    80004808:	7547a783          	lw	a5,1876(a5) # 80240f58 <log+0x20>
    8000480c:	06f05063          	blez	a5,8000486c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004810:	4781                	li	a5,0
    80004812:	06c05563          	blez	a2,8000487c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004816:	44cc                	lw	a1,12(s1)
    80004818:	0023c717          	auipc	a4,0x23c
    8000481c:	75070713          	addi	a4,a4,1872 # 80240f68 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004820:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004822:	4314                	lw	a3,0(a4)
    80004824:	04b68c63          	beq	a3,a1,8000487c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004828:	2785                	addiw	a5,a5,1
    8000482a:	0711                	addi	a4,a4,4
    8000482c:	fef61be3          	bne	a2,a5,80004822 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004830:	0621                	addi	a2,a2,8
    80004832:	060a                	slli	a2,a2,0x2
    80004834:	0023c797          	auipc	a5,0x23c
    80004838:	70478793          	addi	a5,a5,1796 # 80240f38 <log>
    8000483c:	963e                	add	a2,a2,a5
    8000483e:	44dc                	lw	a5,12(s1)
    80004840:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004842:	8526                	mv	a0,s1
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	da2080e7          	jalr	-606(ra) # 800035e6 <bpin>
    log.lh.n++;
    8000484c:	0023c717          	auipc	a4,0x23c
    80004850:	6ec70713          	addi	a4,a4,1772 # 80240f38 <log>
    80004854:	575c                	lw	a5,44(a4)
    80004856:	2785                	addiw	a5,a5,1
    80004858:	d75c                	sw	a5,44(a4)
    8000485a:	a835                	j	80004896 <log_write+0xca>
    panic("too big a transaction");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	e0450513          	addi	a0,a0,-508 # 80008660 <syscalls+0x200>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	cda080e7          	jalr	-806(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000486c:	00004517          	auipc	a0,0x4
    80004870:	e0c50513          	addi	a0,a0,-500 # 80008678 <syscalls+0x218>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	cca080e7          	jalr	-822(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000487c:	00878713          	addi	a4,a5,8
    80004880:	00271693          	slli	a3,a4,0x2
    80004884:	0023c717          	auipc	a4,0x23c
    80004888:	6b470713          	addi	a4,a4,1716 # 80240f38 <log>
    8000488c:	9736                	add	a4,a4,a3
    8000488e:	44d4                	lw	a3,12(s1)
    80004890:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004892:	faf608e3          	beq	a2,a5,80004842 <log_write+0x76>
  }
  release(&log.lock);
    80004896:	0023c517          	auipc	a0,0x23c
    8000489a:	6a250513          	addi	a0,a0,1698 # 80240f38 <log>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	4ee080e7          	jalr	1262(ra) # 80000d8c <release>
}
    800048a6:	60e2                	ld	ra,24(sp)
    800048a8:	6442                	ld	s0,16(sp)
    800048aa:	64a2                	ld	s1,8(sp)
    800048ac:	6902                	ld	s2,0(sp)
    800048ae:	6105                	addi	sp,sp,32
    800048b0:	8082                	ret

00000000800048b2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048b2:	1101                	addi	sp,sp,-32
    800048b4:	ec06                	sd	ra,24(sp)
    800048b6:	e822                	sd	s0,16(sp)
    800048b8:	e426                	sd	s1,8(sp)
    800048ba:	e04a                	sd	s2,0(sp)
    800048bc:	1000                	addi	s0,sp,32
    800048be:	84aa                	mv	s1,a0
    800048c0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048c2:	00004597          	auipc	a1,0x4
    800048c6:	dd658593          	addi	a1,a1,-554 # 80008698 <syscalls+0x238>
    800048ca:	0521                	addi	a0,a0,8
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	37c080e7          	jalr	892(ra) # 80000c48 <initlock>
  lk->name = name;
    800048d4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048d8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048dc:	0204a423          	sw	zero,40(s1)
}
    800048e0:	60e2                	ld	ra,24(sp)
    800048e2:	6442                	ld	s0,16(sp)
    800048e4:	64a2                	ld	s1,8(sp)
    800048e6:	6902                	ld	s2,0(sp)
    800048e8:	6105                	addi	sp,sp,32
    800048ea:	8082                	ret

00000000800048ec <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048ec:	1101                	addi	sp,sp,-32
    800048ee:	ec06                	sd	ra,24(sp)
    800048f0:	e822                	sd	s0,16(sp)
    800048f2:	e426                	sd	s1,8(sp)
    800048f4:	e04a                	sd	s2,0(sp)
    800048f6:	1000                	addi	s0,sp,32
    800048f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048fa:	00850913          	addi	s2,a0,8
    800048fe:	854a                	mv	a0,s2
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	3d8080e7          	jalr	984(ra) # 80000cd8 <acquire>
  while (lk->locked) {
    80004908:	409c                	lw	a5,0(s1)
    8000490a:	cb89                	beqz	a5,8000491c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000490c:	85ca                	mv	a1,s2
    8000490e:	8526                	mv	a0,s1
    80004910:	ffffe097          	auipc	ra,0xffffe
    80004914:	9e8080e7          	jalr	-1560(ra) # 800022f8 <sleep>
  while (lk->locked) {
    80004918:	409c                	lw	a5,0(s1)
    8000491a:	fbed                	bnez	a5,8000490c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000491c:	4785                	li	a5,1
    8000491e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004920:	ffffd097          	auipc	ra,0xffffd
    80004924:	31c080e7          	jalr	796(ra) # 80001c3c <myproc>
    80004928:	591c                	lw	a5,48(a0)
    8000492a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000492c:	854a                	mv	a0,s2
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	45e080e7          	jalr	1118(ra) # 80000d8c <release>
}
    80004936:	60e2                	ld	ra,24(sp)
    80004938:	6442                	ld	s0,16(sp)
    8000493a:	64a2                	ld	s1,8(sp)
    8000493c:	6902                	ld	s2,0(sp)
    8000493e:	6105                	addi	sp,sp,32
    80004940:	8082                	ret

0000000080004942 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004942:	1101                	addi	sp,sp,-32
    80004944:	ec06                	sd	ra,24(sp)
    80004946:	e822                	sd	s0,16(sp)
    80004948:	e426                	sd	s1,8(sp)
    8000494a:	e04a                	sd	s2,0(sp)
    8000494c:	1000                	addi	s0,sp,32
    8000494e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004950:	00850913          	addi	s2,a0,8
    80004954:	854a                	mv	a0,s2
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	382080e7          	jalr	898(ra) # 80000cd8 <acquire>
  lk->locked = 0;
    8000495e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004962:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004966:	8526                	mv	a0,s1
    80004968:	ffffe097          	auipc	ra,0xffffe
    8000496c:	9f4080e7          	jalr	-1548(ra) # 8000235c <wakeup>
  release(&lk->lk);
    80004970:	854a                	mv	a0,s2
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	41a080e7          	jalr	1050(ra) # 80000d8c <release>
}
    8000497a:	60e2                	ld	ra,24(sp)
    8000497c:	6442                	ld	s0,16(sp)
    8000497e:	64a2                	ld	s1,8(sp)
    80004980:	6902                	ld	s2,0(sp)
    80004982:	6105                	addi	sp,sp,32
    80004984:	8082                	ret

0000000080004986 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004986:	7179                	addi	sp,sp,-48
    80004988:	f406                	sd	ra,40(sp)
    8000498a:	f022                	sd	s0,32(sp)
    8000498c:	ec26                	sd	s1,24(sp)
    8000498e:	e84a                	sd	s2,16(sp)
    80004990:	e44e                	sd	s3,8(sp)
    80004992:	1800                	addi	s0,sp,48
    80004994:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004996:	00850913          	addi	s2,a0,8
    8000499a:	854a                	mv	a0,s2
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	33c080e7          	jalr	828(ra) # 80000cd8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049a4:	409c                	lw	a5,0(s1)
    800049a6:	ef99                	bnez	a5,800049c4 <holdingsleep+0x3e>
    800049a8:	4481                	li	s1,0
  release(&lk->lk);
    800049aa:	854a                	mv	a0,s2
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	3e0080e7          	jalr	992(ra) # 80000d8c <release>
  return r;
}
    800049b4:	8526                	mv	a0,s1
    800049b6:	70a2                	ld	ra,40(sp)
    800049b8:	7402                	ld	s0,32(sp)
    800049ba:	64e2                	ld	s1,24(sp)
    800049bc:	6942                	ld	s2,16(sp)
    800049be:	69a2                	ld	s3,8(sp)
    800049c0:	6145                	addi	sp,sp,48
    800049c2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049c4:	0284a983          	lw	s3,40(s1)
    800049c8:	ffffd097          	auipc	ra,0xffffd
    800049cc:	274080e7          	jalr	628(ra) # 80001c3c <myproc>
    800049d0:	5904                	lw	s1,48(a0)
    800049d2:	413484b3          	sub	s1,s1,s3
    800049d6:	0014b493          	seqz	s1,s1
    800049da:	bfc1                	j	800049aa <holdingsleep+0x24>

00000000800049dc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049dc:	1141                	addi	sp,sp,-16
    800049de:	e406                	sd	ra,8(sp)
    800049e0:	e022                	sd	s0,0(sp)
    800049e2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049e4:	00004597          	auipc	a1,0x4
    800049e8:	cc458593          	addi	a1,a1,-828 # 800086a8 <syscalls+0x248>
    800049ec:	0023c517          	auipc	a0,0x23c
    800049f0:	69450513          	addi	a0,a0,1684 # 80241080 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	254080e7          	jalr	596(ra) # 80000c48 <initlock>
}
    800049fc:	60a2                	ld	ra,8(sp)
    800049fe:	6402                	ld	s0,0(sp)
    80004a00:	0141                	addi	sp,sp,16
    80004a02:	8082                	ret

0000000080004a04 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a04:	1101                	addi	sp,sp,-32
    80004a06:	ec06                	sd	ra,24(sp)
    80004a08:	e822                	sd	s0,16(sp)
    80004a0a:	e426                	sd	s1,8(sp)
    80004a0c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a0e:	0023c517          	auipc	a0,0x23c
    80004a12:	67250513          	addi	a0,a0,1650 # 80241080 <ftable>
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	2c2080e7          	jalr	706(ra) # 80000cd8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a1e:	0023c497          	auipc	s1,0x23c
    80004a22:	67a48493          	addi	s1,s1,1658 # 80241098 <ftable+0x18>
    80004a26:	0023d717          	auipc	a4,0x23d
    80004a2a:	61270713          	addi	a4,a4,1554 # 80242038 <disk>
    if(f->ref == 0){
    80004a2e:	40dc                	lw	a5,4(s1)
    80004a30:	cf99                	beqz	a5,80004a4e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a32:	02848493          	addi	s1,s1,40
    80004a36:	fee49ce3          	bne	s1,a4,80004a2e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a3a:	0023c517          	auipc	a0,0x23c
    80004a3e:	64650513          	addi	a0,a0,1606 # 80241080 <ftable>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	34a080e7          	jalr	842(ra) # 80000d8c <release>
  return 0;
    80004a4a:	4481                	li	s1,0
    80004a4c:	a819                	j	80004a62 <filealloc+0x5e>
      f->ref = 1;
    80004a4e:	4785                	li	a5,1
    80004a50:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a52:	0023c517          	auipc	a0,0x23c
    80004a56:	62e50513          	addi	a0,a0,1582 # 80241080 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	332080e7          	jalr	818(ra) # 80000d8c <release>
}
    80004a62:	8526                	mv	a0,s1
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret

0000000080004a6e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a6e:	1101                	addi	sp,sp,-32
    80004a70:	ec06                	sd	ra,24(sp)
    80004a72:	e822                	sd	s0,16(sp)
    80004a74:	e426                	sd	s1,8(sp)
    80004a76:	1000                	addi	s0,sp,32
    80004a78:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a7a:	0023c517          	auipc	a0,0x23c
    80004a7e:	60650513          	addi	a0,a0,1542 # 80241080 <ftable>
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	256080e7          	jalr	598(ra) # 80000cd8 <acquire>
  if(f->ref < 1)
    80004a8a:	40dc                	lw	a5,4(s1)
    80004a8c:	02f05263          	blez	a5,80004ab0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a90:	2785                	addiw	a5,a5,1
    80004a92:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a94:	0023c517          	auipc	a0,0x23c
    80004a98:	5ec50513          	addi	a0,a0,1516 # 80241080 <ftable>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	2f0080e7          	jalr	752(ra) # 80000d8c <release>
  return f;
}
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	60e2                	ld	ra,24(sp)
    80004aa8:	6442                	ld	s0,16(sp)
    80004aaa:	64a2                	ld	s1,8(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret
    panic("filedup");
    80004ab0:	00004517          	auipc	a0,0x4
    80004ab4:	c0050513          	addi	a0,a0,-1024 # 800086b0 <syscalls+0x250>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	a86080e7          	jalr	-1402(ra) # 8000053e <panic>

0000000080004ac0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ac0:	7139                	addi	sp,sp,-64
    80004ac2:	fc06                	sd	ra,56(sp)
    80004ac4:	f822                	sd	s0,48(sp)
    80004ac6:	f426                	sd	s1,40(sp)
    80004ac8:	f04a                	sd	s2,32(sp)
    80004aca:	ec4e                	sd	s3,24(sp)
    80004acc:	e852                	sd	s4,16(sp)
    80004ace:	e456                	sd	s5,8(sp)
    80004ad0:	0080                	addi	s0,sp,64
    80004ad2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ad4:	0023c517          	auipc	a0,0x23c
    80004ad8:	5ac50513          	addi	a0,a0,1452 # 80241080 <ftable>
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	1fc080e7          	jalr	508(ra) # 80000cd8 <acquire>
  if(f->ref < 1)
    80004ae4:	40dc                	lw	a5,4(s1)
    80004ae6:	06f05163          	blez	a5,80004b48 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aea:	37fd                	addiw	a5,a5,-1
    80004aec:	0007871b          	sext.w	a4,a5
    80004af0:	c0dc                	sw	a5,4(s1)
    80004af2:	06e04363          	bgtz	a4,80004b58 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004af6:	0004a903          	lw	s2,0(s1)
    80004afa:	0094ca83          	lbu	s5,9(s1)
    80004afe:	0104ba03          	ld	s4,16(s1)
    80004b02:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b06:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b0a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b0e:	0023c517          	auipc	a0,0x23c
    80004b12:	57250513          	addi	a0,a0,1394 # 80241080 <ftable>
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	276080e7          	jalr	630(ra) # 80000d8c <release>

  if(ff.type == FD_PIPE){
    80004b1e:	4785                	li	a5,1
    80004b20:	04f90d63          	beq	s2,a5,80004b7a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b24:	3979                	addiw	s2,s2,-2
    80004b26:	4785                	li	a5,1
    80004b28:	0527e063          	bltu	a5,s2,80004b68 <fileclose+0xa8>
    begin_op();
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	ac8080e7          	jalr	-1336(ra) # 800045f4 <begin_op>
    iput(ff.ip);
    80004b34:	854e                	mv	a0,s3
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	2b6080e7          	jalr	694(ra) # 80003dec <iput>
    end_op();
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	b36080e7          	jalr	-1226(ra) # 80004674 <end_op>
    80004b46:	a00d                	j	80004b68 <fileclose+0xa8>
    panic("fileclose");
    80004b48:	00004517          	auipc	a0,0x4
    80004b4c:	b7050513          	addi	a0,a0,-1168 # 800086b8 <syscalls+0x258>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b58:	0023c517          	auipc	a0,0x23c
    80004b5c:	52850513          	addi	a0,a0,1320 # 80241080 <ftable>
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	22c080e7          	jalr	556(ra) # 80000d8c <release>
  }
}
    80004b68:	70e2                	ld	ra,56(sp)
    80004b6a:	7442                	ld	s0,48(sp)
    80004b6c:	74a2                	ld	s1,40(sp)
    80004b6e:	7902                	ld	s2,32(sp)
    80004b70:	69e2                	ld	s3,24(sp)
    80004b72:	6a42                	ld	s4,16(sp)
    80004b74:	6aa2                	ld	s5,8(sp)
    80004b76:	6121                	addi	sp,sp,64
    80004b78:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b7a:	85d6                	mv	a1,s5
    80004b7c:	8552                	mv	a0,s4
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	34c080e7          	jalr	844(ra) # 80004eca <pipeclose>
    80004b86:	b7cd                	j	80004b68 <fileclose+0xa8>

0000000080004b88 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b88:	715d                	addi	sp,sp,-80
    80004b8a:	e486                	sd	ra,72(sp)
    80004b8c:	e0a2                	sd	s0,64(sp)
    80004b8e:	fc26                	sd	s1,56(sp)
    80004b90:	f84a                	sd	s2,48(sp)
    80004b92:	f44e                	sd	s3,40(sp)
    80004b94:	0880                	addi	s0,sp,80
    80004b96:	84aa                	mv	s1,a0
    80004b98:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	0a2080e7          	jalr	162(ra) # 80001c3c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ba2:	409c                	lw	a5,0(s1)
    80004ba4:	37f9                	addiw	a5,a5,-2
    80004ba6:	4705                	li	a4,1
    80004ba8:	04f76763          	bltu	a4,a5,80004bf6 <filestat+0x6e>
    80004bac:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bae:	6c88                	ld	a0,24(s1)
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	082080e7          	jalr	130(ra) # 80003c32 <ilock>
    stati(f->ip, &st);
    80004bb8:	fb840593          	addi	a1,s0,-72
    80004bbc:	6c88                	ld	a0,24(s1)
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	2fe080e7          	jalr	766(ra) # 80003ebc <stati>
    iunlock(f->ip);
    80004bc6:	6c88                	ld	a0,24(s1)
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	12c080e7          	jalr	300(ra) # 80003cf4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bd0:	46e1                	li	a3,24
    80004bd2:	fb840613          	addi	a2,s0,-72
    80004bd6:	85ce                	mv	a1,s3
    80004bd8:	05093503          	ld	a0,80(s2)
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	c7c080e7          	jalr	-900(ra) # 80001858 <copyout>
    80004be4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004be8:	60a6                	ld	ra,72(sp)
    80004bea:	6406                	ld	s0,64(sp)
    80004bec:	74e2                	ld	s1,56(sp)
    80004bee:	7942                	ld	s2,48(sp)
    80004bf0:	79a2                	ld	s3,40(sp)
    80004bf2:	6161                	addi	sp,sp,80
    80004bf4:	8082                	ret
  return -1;
    80004bf6:	557d                	li	a0,-1
    80004bf8:	bfc5                	j	80004be8 <filestat+0x60>

0000000080004bfa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bfa:	7179                	addi	sp,sp,-48
    80004bfc:	f406                	sd	ra,40(sp)
    80004bfe:	f022                	sd	s0,32(sp)
    80004c00:	ec26                	sd	s1,24(sp)
    80004c02:	e84a                	sd	s2,16(sp)
    80004c04:	e44e                	sd	s3,8(sp)
    80004c06:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c08:	00854783          	lbu	a5,8(a0)
    80004c0c:	c3d5                	beqz	a5,80004cb0 <fileread+0xb6>
    80004c0e:	84aa                	mv	s1,a0
    80004c10:	89ae                	mv	s3,a1
    80004c12:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c14:	411c                	lw	a5,0(a0)
    80004c16:	4705                	li	a4,1
    80004c18:	04e78963          	beq	a5,a4,80004c6a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c1c:	470d                	li	a4,3
    80004c1e:	04e78d63          	beq	a5,a4,80004c78 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c22:	4709                	li	a4,2
    80004c24:	06e79e63          	bne	a5,a4,80004ca0 <fileread+0xa6>
    ilock(f->ip);
    80004c28:	6d08                	ld	a0,24(a0)
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	008080e7          	jalr	8(ra) # 80003c32 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c32:	874a                	mv	a4,s2
    80004c34:	5094                	lw	a3,32(s1)
    80004c36:	864e                	mv	a2,s3
    80004c38:	4585                	li	a1,1
    80004c3a:	6c88                	ld	a0,24(s1)
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	2aa080e7          	jalr	682(ra) # 80003ee6 <readi>
    80004c44:	892a                	mv	s2,a0
    80004c46:	00a05563          	blez	a0,80004c50 <fileread+0x56>
      f->off += r;
    80004c4a:	509c                	lw	a5,32(s1)
    80004c4c:	9fa9                	addw	a5,a5,a0
    80004c4e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c50:	6c88                	ld	a0,24(s1)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	0a2080e7          	jalr	162(ra) # 80003cf4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c5a:	854a                	mv	a0,s2
    80004c5c:	70a2                	ld	ra,40(sp)
    80004c5e:	7402                	ld	s0,32(sp)
    80004c60:	64e2                	ld	s1,24(sp)
    80004c62:	6942                	ld	s2,16(sp)
    80004c64:	69a2                	ld	s3,8(sp)
    80004c66:	6145                	addi	sp,sp,48
    80004c68:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c6a:	6908                	ld	a0,16(a0)
    80004c6c:	00000097          	auipc	ra,0x0
    80004c70:	3c6080e7          	jalr	966(ra) # 80005032 <piperead>
    80004c74:	892a                	mv	s2,a0
    80004c76:	b7d5                	j	80004c5a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c78:	02451783          	lh	a5,36(a0)
    80004c7c:	03079693          	slli	a3,a5,0x30
    80004c80:	92c1                	srli	a3,a3,0x30
    80004c82:	4725                	li	a4,9
    80004c84:	02d76863          	bltu	a4,a3,80004cb4 <fileread+0xba>
    80004c88:	0792                	slli	a5,a5,0x4
    80004c8a:	0023c717          	auipc	a4,0x23c
    80004c8e:	35670713          	addi	a4,a4,854 # 80240fe0 <devsw>
    80004c92:	97ba                	add	a5,a5,a4
    80004c94:	639c                	ld	a5,0(a5)
    80004c96:	c38d                	beqz	a5,80004cb8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c98:	4505                	li	a0,1
    80004c9a:	9782                	jalr	a5
    80004c9c:	892a                	mv	s2,a0
    80004c9e:	bf75                	j	80004c5a <fileread+0x60>
    panic("fileread");
    80004ca0:	00004517          	auipc	a0,0x4
    80004ca4:	a2850513          	addi	a0,a0,-1496 # 800086c8 <syscalls+0x268>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	896080e7          	jalr	-1898(ra) # 8000053e <panic>
    return -1;
    80004cb0:	597d                	li	s2,-1
    80004cb2:	b765                	j	80004c5a <fileread+0x60>
      return -1;
    80004cb4:	597d                	li	s2,-1
    80004cb6:	b755                	j	80004c5a <fileread+0x60>
    80004cb8:	597d                	li	s2,-1
    80004cba:	b745                	j	80004c5a <fileread+0x60>

0000000080004cbc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cbc:	715d                	addi	sp,sp,-80
    80004cbe:	e486                	sd	ra,72(sp)
    80004cc0:	e0a2                	sd	s0,64(sp)
    80004cc2:	fc26                	sd	s1,56(sp)
    80004cc4:	f84a                	sd	s2,48(sp)
    80004cc6:	f44e                	sd	s3,40(sp)
    80004cc8:	f052                	sd	s4,32(sp)
    80004cca:	ec56                	sd	s5,24(sp)
    80004ccc:	e85a                	sd	s6,16(sp)
    80004cce:	e45e                	sd	s7,8(sp)
    80004cd0:	e062                	sd	s8,0(sp)
    80004cd2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cd4:	00954783          	lbu	a5,9(a0)
    80004cd8:	10078663          	beqz	a5,80004de4 <filewrite+0x128>
    80004cdc:	892a                	mv	s2,a0
    80004cde:	8aae                	mv	s5,a1
    80004ce0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ce2:	411c                	lw	a5,0(a0)
    80004ce4:	4705                	li	a4,1
    80004ce6:	02e78263          	beq	a5,a4,80004d0a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cea:	470d                	li	a4,3
    80004cec:	02e78663          	beq	a5,a4,80004d18 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cf0:	4709                	li	a4,2
    80004cf2:	0ee79163          	bne	a5,a4,80004dd4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cf6:	0ac05d63          	blez	a2,80004db0 <filewrite+0xf4>
    int i = 0;
    80004cfa:	4981                	li	s3,0
    80004cfc:	6b05                	lui	s6,0x1
    80004cfe:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d02:	6b85                	lui	s7,0x1
    80004d04:	c00b8b9b          	addiw	s7,s7,-1024
    80004d08:	a861                	j	80004da0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d0a:	6908                	ld	a0,16(a0)
    80004d0c:	00000097          	auipc	ra,0x0
    80004d10:	22e080e7          	jalr	558(ra) # 80004f3a <pipewrite>
    80004d14:	8a2a                	mv	s4,a0
    80004d16:	a045                	j	80004db6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d18:	02451783          	lh	a5,36(a0)
    80004d1c:	03079693          	slli	a3,a5,0x30
    80004d20:	92c1                	srli	a3,a3,0x30
    80004d22:	4725                	li	a4,9
    80004d24:	0cd76263          	bltu	a4,a3,80004de8 <filewrite+0x12c>
    80004d28:	0792                	slli	a5,a5,0x4
    80004d2a:	0023c717          	auipc	a4,0x23c
    80004d2e:	2b670713          	addi	a4,a4,694 # 80240fe0 <devsw>
    80004d32:	97ba                	add	a5,a5,a4
    80004d34:	679c                	ld	a5,8(a5)
    80004d36:	cbdd                	beqz	a5,80004dec <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d38:	4505                	li	a0,1
    80004d3a:	9782                	jalr	a5
    80004d3c:	8a2a                	mv	s4,a0
    80004d3e:	a8a5                	j	80004db6 <filewrite+0xfa>
    80004d40:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	8b0080e7          	jalr	-1872(ra) # 800045f4 <begin_op>
      ilock(f->ip);
    80004d4c:	01893503          	ld	a0,24(s2)
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	ee2080e7          	jalr	-286(ra) # 80003c32 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d58:	8762                	mv	a4,s8
    80004d5a:	02092683          	lw	a3,32(s2)
    80004d5e:	01598633          	add	a2,s3,s5
    80004d62:	4585                	li	a1,1
    80004d64:	01893503          	ld	a0,24(s2)
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	276080e7          	jalr	630(ra) # 80003fde <writei>
    80004d70:	84aa                	mv	s1,a0
    80004d72:	00a05763          	blez	a0,80004d80 <filewrite+0xc4>
        f->off += r;
    80004d76:	02092783          	lw	a5,32(s2)
    80004d7a:	9fa9                	addw	a5,a5,a0
    80004d7c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d80:	01893503          	ld	a0,24(s2)
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	f70080e7          	jalr	-144(ra) # 80003cf4 <iunlock>
      end_op();
    80004d8c:	00000097          	auipc	ra,0x0
    80004d90:	8e8080e7          	jalr	-1816(ra) # 80004674 <end_op>

      if(r != n1){
    80004d94:	009c1f63          	bne	s8,s1,80004db2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d98:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d9c:	0149db63          	bge	s3,s4,80004db2 <filewrite+0xf6>
      int n1 = n - i;
    80004da0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004da4:	84be                	mv	s1,a5
    80004da6:	2781                	sext.w	a5,a5
    80004da8:	f8fb5ce3          	bge	s6,a5,80004d40 <filewrite+0x84>
    80004dac:	84de                	mv	s1,s7
    80004dae:	bf49                	j	80004d40 <filewrite+0x84>
    int i = 0;
    80004db0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004db2:	013a1f63          	bne	s4,s3,80004dd0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004db6:	8552                	mv	a0,s4
    80004db8:	60a6                	ld	ra,72(sp)
    80004dba:	6406                	ld	s0,64(sp)
    80004dbc:	74e2                	ld	s1,56(sp)
    80004dbe:	7942                	ld	s2,48(sp)
    80004dc0:	79a2                	ld	s3,40(sp)
    80004dc2:	7a02                	ld	s4,32(sp)
    80004dc4:	6ae2                	ld	s5,24(sp)
    80004dc6:	6b42                	ld	s6,16(sp)
    80004dc8:	6ba2                	ld	s7,8(sp)
    80004dca:	6c02                	ld	s8,0(sp)
    80004dcc:	6161                	addi	sp,sp,80
    80004dce:	8082                	ret
    ret = (i == n ? n : -1);
    80004dd0:	5a7d                	li	s4,-1
    80004dd2:	b7d5                	j	80004db6 <filewrite+0xfa>
    panic("filewrite");
    80004dd4:	00004517          	auipc	a0,0x4
    80004dd8:	90450513          	addi	a0,a0,-1788 # 800086d8 <syscalls+0x278>
    80004ddc:	ffffb097          	auipc	ra,0xffffb
    80004de0:	762080e7          	jalr	1890(ra) # 8000053e <panic>
    return -1;
    80004de4:	5a7d                	li	s4,-1
    80004de6:	bfc1                	j	80004db6 <filewrite+0xfa>
      return -1;
    80004de8:	5a7d                	li	s4,-1
    80004dea:	b7f1                	j	80004db6 <filewrite+0xfa>
    80004dec:	5a7d                	li	s4,-1
    80004dee:	b7e1                	j	80004db6 <filewrite+0xfa>

0000000080004df0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004df0:	7179                	addi	sp,sp,-48
    80004df2:	f406                	sd	ra,40(sp)
    80004df4:	f022                	sd	s0,32(sp)
    80004df6:	ec26                	sd	s1,24(sp)
    80004df8:	e84a                	sd	s2,16(sp)
    80004dfa:	e44e                	sd	s3,8(sp)
    80004dfc:	e052                	sd	s4,0(sp)
    80004dfe:	1800                	addi	s0,sp,48
    80004e00:	84aa                	mv	s1,a0
    80004e02:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e04:	0005b023          	sd	zero,0(a1)
    80004e08:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	bf8080e7          	jalr	-1032(ra) # 80004a04 <filealloc>
    80004e14:	e088                	sd	a0,0(s1)
    80004e16:	c551                	beqz	a0,80004ea2 <pipealloc+0xb2>
    80004e18:	00000097          	auipc	ra,0x0
    80004e1c:	bec080e7          	jalr	-1044(ra) # 80004a04 <filealloc>
    80004e20:	00aa3023          	sd	a0,0(s4)
    80004e24:	c92d                	beqz	a0,80004e96 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	d86080e7          	jalr	-634(ra) # 80000bac <kalloc>
    80004e2e:	892a                	mv	s2,a0
    80004e30:	c125                	beqz	a0,80004e90 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e32:	4985                	li	s3,1
    80004e34:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e38:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e3c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e40:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e44:	00004597          	auipc	a1,0x4
    80004e48:	8a458593          	addi	a1,a1,-1884 # 800086e8 <syscalls+0x288>
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	dfc080e7          	jalr	-516(ra) # 80000c48 <initlock>
  (*f0)->type = FD_PIPE;
    80004e54:	609c                	ld	a5,0(s1)
    80004e56:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e5a:	609c                	ld	a5,0(s1)
    80004e5c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e60:	609c                	ld	a5,0(s1)
    80004e62:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e66:	609c                	ld	a5,0(s1)
    80004e68:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e6c:	000a3783          	ld	a5,0(s4)
    80004e70:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e74:	000a3783          	ld	a5,0(s4)
    80004e78:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e7c:	000a3783          	ld	a5,0(s4)
    80004e80:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e84:	000a3783          	ld	a5,0(s4)
    80004e88:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e8c:	4501                	li	a0,0
    80004e8e:	a025                	j	80004eb6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e90:	6088                	ld	a0,0(s1)
    80004e92:	e501                	bnez	a0,80004e9a <pipealloc+0xaa>
    80004e94:	a039                	j	80004ea2 <pipealloc+0xb2>
    80004e96:	6088                	ld	a0,0(s1)
    80004e98:	c51d                	beqz	a0,80004ec6 <pipealloc+0xd6>
    fileclose(*f0);
    80004e9a:	00000097          	auipc	ra,0x0
    80004e9e:	c26080e7          	jalr	-986(ra) # 80004ac0 <fileclose>
  if(*f1)
    80004ea2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ea6:	557d                	li	a0,-1
  if(*f1)
    80004ea8:	c799                	beqz	a5,80004eb6 <pipealloc+0xc6>
    fileclose(*f1);
    80004eaa:	853e                	mv	a0,a5
    80004eac:	00000097          	auipc	ra,0x0
    80004eb0:	c14080e7          	jalr	-1004(ra) # 80004ac0 <fileclose>
  return -1;
    80004eb4:	557d                	li	a0,-1
}
    80004eb6:	70a2                	ld	ra,40(sp)
    80004eb8:	7402                	ld	s0,32(sp)
    80004eba:	64e2                	ld	s1,24(sp)
    80004ebc:	6942                	ld	s2,16(sp)
    80004ebe:	69a2                	ld	s3,8(sp)
    80004ec0:	6a02                	ld	s4,0(sp)
    80004ec2:	6145                	addi	sp,sp,48
    80004ec4:	8082                	ret
  return -1;
    80004ec6:	557d                	li	a0,-1
    80004ec8:	b7fd                	j	80004eb6 <pipealloc+0xc6>

0000000080004eca <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004eca:	1101                	addi	sp,sp,-32
    80004ecc:	ec06                	sd	ra,24(sp)
    80004ece:	e822                	sd	s0,16(sp)
    80004ed0:	e426                	sd	s1,8(sp)
    80004ed2:	e04a                	sd	s2,0(sp)
    80004ed4:	1000                	addi	s0,sp,32
    80004ed6:	84aa                	mv	s1,a0
    80004ed8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	dfe080e7          	jalr	-514(ra) # 80000cd8 <acquire>
  if(writable){
    80004ee2:	02090d63          	beqz	s2,80004f1c <pipeclose+0x52>
    pi->writeopen = 0;
    80004ee6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004eea:	21848513          	addi	a0,s1,536
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	46e080e7          	jalr	1134(ra) # 8000235c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ef6:	2204b783          	ld	a5,544(s1)
    80004efa:	eb95                	bnez	a5,80004f2e <pipeclose+0x64>
    release(&pi->lock);
    80004efc:	8526                	mv	a0,s1
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	e8e080e7          	jalr	-370(ra) # 80000d8c <release>
    kfree((char*)pi);
    80004f06:	8526                	mv	a0,s1
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	ae2080e7          	jalr	-1310(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004f10:	60e2                	ld	ra,24(sp)
    80004f12:	6442                	ld	s0,16(sp)
    80004f14:	64a2                	ld	s1,8(sp)
    80004f16:	6902                	ld	s2,0(sp)
    80004f18:	6105                	addi	sp,sp,32
    80004f1a:	8082                	ret
    pi->readopen = 0;
    80004f1c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f20:	21c48513          	addi	a0,s1,540
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	438080e7          	jalr	1080(ra) # 8000235c <wakeup>
    80004f2c:	b7e9                	j	80004ef6 <pipeclose+0x2c>
    release(&pi->lock);
    80004f2e:	8526                	mv	a0,s1
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	e5c080e7          	jalr	-420(ra) # 80000d8c <release>
}
    80004f38:	bfe1                	j	80004f10 <pipeclose+0x46>

0000000080004f3a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f3a:	711d                	addi	sp,sp,-96
    80004f3c:	ec86                	sd	ra,88(sp)
    80004f3e:	e8a2                	sd	s0,80(sp)
    80004f40:	e4a6                	sd	s1,72(sp)
    80004f42:	e0ca                	sd	s2,64(sp)
    80004f44:	fc4e                	sd	s3,56(sp)
    80004f46:	f852                	sd	s4,48(sp)
    80004f48:	f456                	sd	s5,40(sp)
    80004f4a:	f05a                	sd	s6,32(sp)
    80004f4c:	ec5e                	sd	s7,24(sp)
    80004f4e:	e862                	sd	s8,16(sp)
    80004f50:	1080                	addi	s0,sp,96
    80004f52:	84aa                	mv	s1,a0
    80004f54:	8aae                	mv	s5,a1
    80004f56:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	ce4080e7          	jalr	-796(ra) # 80001c3c <myproc>
    80004f60:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f62:	8526                	mv	a0,s1
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	d74080e7          	jalr	-652(ra) # 80000cd8 <acquire>
  while(i < n){
    80004f6c:	0b405663          	blez	s4,80005018 <pipewrite+0xde>
  int i = 0;
    80004f70:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f72:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f74:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f78:	21c48b93          	addi	s7,s1,540
    80004f7c:	a089                	j	80004fbe <pipewrite+0x84>
      release(&pi->lock);
    80004f7e:	8526                	mv	a0,s1
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	e0c080e7          	jalr	-500(ra) # 80000d8c <release>
      return -1;
    80004f88:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f8a:	854a                	mv	a0,s2
    80004f8c:	60e6                	ld	ra,88(sp)
    80004f8e:	6446                	ld	s0,80(sp)
    80004f90:	64a6                	ld	s1,72(sp)
    80004f92:	6906                	ld	s2,64(sp)
    80004f94:	79e2                	ld	s3,56(sp)
    80004f96:	7a42                	ld	s4,48(sp)
    80004f98:	7aa2                	ld	s5,40(sp)
    80004f9a:	7b02                	ld	s6,32(sp)
    80004f9c:	6be2                	ld	s7,24(sp)
    80004f9e:	6c42                	ld	s8,16(sp)
    80004fa0:	6125                	addi	sp,sp,96
    80004fa2:	8082                	ret
      wakeup(&pi->nread);
    80004fa4:	8562                	mv	a0,s8
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	3b6080e7          	jalr	950(ra) # 8000235c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fae:	85a6                	mv	a1,s1
    80004fb0:	855e                	mv	a0,s7
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	346080e7          	jalr	838(ra) # 800022f8 <sleep>
  while(i < n){
    80004fba:	07495063          	bge	s2,s4,8000501a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fbe:	2204a783          	lw	a5,544(s1)
    80004fc2:	dfd5                	beqz	a5,80004f7e <pipewrite+0x44>
    80004fc4:	854e                	mv	a0,s3
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	5e6080e7          	jalr	1510(ra) # 800025ac <killed>
    80004fce:	f945                	bnez	a0,80004f7e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fd0:	2184a783          	lw	a5,536(s1)
    80004fd4:	21c4a703          	lw	a4,540(s1)
    80004fd8:	2007879b          	addiw	a5,a5,512
    80004fdc:	fcf704e3          	beq	a4,a5,80004fa4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fe0:	4685                	li	a3,1
    80004fe2:	01590633          	add	a2,s2,s5
    80004fe6:	faf40593          	addi	a1,s0,-81
    80004fea:	0509b503          	ld	a0,80(s3)
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	996080e7          	jalr	-1642(ra) # 80001984 <copyin>
    80004ff6:	03650263          	beq	a0,s6,8000501a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ffa:	21c4a783          	lw	a5,540(s1)
    80004ffe:	0017871b          	addiw	a4,a5,1
    80005002:	20e4ae23          	sw	a4,540(s1)
    80005006:	1ff7f793          	andi	a5,a5,511
    8000500a:	97a6                	add	a5,a5,s1
    8000500c:	faf44703          	lbu	a4,-81(s0)
    80005010:	00e78c23          	sb	a4,24(a5)
      i++;
    80005014:	2905                	addiw	s2,s2,1
    80005016:	b755                	j	80004fba <pipewrite+0x80>
  int i = 0;
    80005018:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000501a:	21848513          	addi	a0,s1,536
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	33e080e7          	jalr	830(ra) # 8000235c <wakeup>
  release(&pi->lock);
    80005026:	8526                	mv	a0,s1
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	d64080e7          	jalr	-668(ra) # 80000d8c <release>
  return i;
    80005030:	bfa9                	j	80004f8a <pipewrite+0x50>

0000000080005032 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005032:	715d                	addi	sp,sp,-80
    80005034:	e486                	sd	ra,72(sp)
    80005036:	e0a2                	sd	s0,64(sp)
    80005038:	fc26                	sd	s1,56(sp)
    8000503a:	f84a                	sd	s2,48(sp)
    8000503c:	f44e                	sd	s3,40(sp)
    8000503e:	f052                	sd	s4,32(sp)
    80005040:	ec56                	sd	s5,24(sp)
    80005042:	e85a                	sd	s6,16(sp)
    80005044:	0880                	addi	s0,sp,80
    80005046:	84aa                	mv	s1,a0
    80005048:	892e                	mv	s2,a1
    8000504a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000504c:	ffffd097          	auipc	ra,0xffffd
    80005050:	bf0080e7          	jalr	-1040(ra) # 80001c3c <myproc>
    80005054:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005056:	8526                	mv	a0,s1
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	c80080e7          	jalr	-896(ra) # 80000cd8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005060:	2184a703          	lw	a4,536(s1)
    80005064:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005068:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000506c:	02f71763          	bne	a4,a5,8000509a <piperead+0x68>
    80005070:	2244a783          	lw	a5,548(s1)
    80005074:	c39d                	beqz	a5,8000509a <piperead+0x68>
    if(killed(pr)){
    80005076:	8552                	mv	a0,s4
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	534080e7          	jalr	1332(ra) # 800025ac <killed>
    80005080:	e941                	bnez	a0,80005110 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005082:	85a6                	mv	a1,s1
    80005084:	854e                	mv	a0,s3
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	272080e7          	jalr	626(ra) # 800022f8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000508e:	2184a703          	lw	a4,536(s1)
    80005092:	21c4a783          	lw	a5,540(s1)
    80005096:	fcf70de3          	beq	a4,a5,80005070 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000509a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000509c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000509e:	05505363          	blez	s5,800050e4 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800050a2:	2184a783          	lw	a5,536(s1)
    800050a6:	21c4a703          	lw	a4,540(s1)
    800050aa:	02f70d63          	beq	a4,a5,800050e4 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050ae:	0017871b          	addiw	a4,a5,1
    800050b2:	20e4ac23          	sw	a4,536(s1)
    800050b6:	1ff7f793          	andi	a5,a5,511
    800050ba:	97a6                	add	a5,a5,s1
    800050bc:	0187c783          	lbu	a5,24(a5)
    800050c0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050c4:	4685                	li	a3,1
    800050c6:	fbf40613          	addi	a2,s0,-65
    800050ca:	85ca                	mv	a1,s2
    800050cc:	050a3503          	ld	a0,80(s4)
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	788080e7          	jalr	1928(ra) # 80001858 <copyout>
    800050d8:	01650663          	beq	a0,s6,800050e4 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050dc:	2985                	addiw	s3,s3,1
    800050de:	0905                	addi	s2,s2,1
    800050e0:	fd3a91e3          	bne	s5,s3,800050a2 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050e4:	21c48513          	addi	a0,s1,540
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	274080e7          	jalr	628(ra) # 8000235c <wakeup>
  release(&pi->lock);
    800050f0:	8526                	mv	a0,s1
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	c9a080e7          	jalr	-870(ra) # 80000d8c <release>
  return i;
}
    800050fa:	854e                	mv	a0,s3
    800050fc:	60a6                	ld	ra,72(sp)
    800050fe:	6406                	ld	s0,64(sp)
    80005100:	74e2                	ld	s1,56(sp)
    80005102:	7942                	ld	s2,48(sp)
    80005104:	79a2                	ld	s3,40(sp)
    80005106:	7a02                	ld	s4,32(sp)
    80005108:	6ae2                	ld	s5,24(sp)
    8000510a:	6b42                	ld	s6,16(sp)
    8000510c:	6161                	addi	sp,sp,80
    8000510e:	8082                	ret
      release(&pi->lock);
    80005110:	8526                	mv	a0,s1
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	c7a080e7          	jalr	-902(ra) # 80000d8c <release>
      return -1;
    8000511a:	59fd                	li	s3,-1
    8000511c:	bff9                	j	800050fa <piperead+0xc8>

000000008000511e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000511e:	1141                	addi	sp,sp,-16
    80005120:	e422                	sd	s0,8(sp)
    80005122:	0800                	addi	s0,sp,16
    80005124:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005126:	8905                	andi	a0,a0,1
    80005128:	c111                	beqz	a0,8000512c <flags2perm+0xe>
      perm = PTE_X;
    8000512a:	4521                	li	a0,8
    if(flags & 0x2)
    8000512c:	8b89                	andi	a5,a5,2
    8000512e:	c399                	beqz	a5,80005134 <flags2perm+0x16>
      perm |= PTE_W;
    80005130:	00456513          	ori	a0,a0,4
    return perm;
}
    80005134:	6422                	ld	s0,8(sp)
    80005136:	0141                	addi	sp,sp,16
    80005138:	8082                	ret

000000008000513a <exec>:

int
exec(char *path, char **argv)
{
    8000513a:	de010113          	addi	sp,sp,-544
    8000513e:	20113c23          	sd	ra,536(sp)
    80005142:	20813823          	sd	s0,528(sp)
    80005146:	20913423          	sd	s1,520(sp)
    8000514a:	21213023          	sd	s2,512(sp)
    8000514e:	ffce                	sd	s3,504(sp)
    80005150:	fbd2                	sd	s4,496(sp)
    80005152:	f7d6                	sd	s5,488(sp)
    80005154:	f3da                	sd	s6,480(sp)
    80005156:	efde                	sd	s7,472(sp)
    80005158:	ebe2                	sd	s8,464(sp)
    8000515a:	e7e6                	sd	s9,456(sp)
    8000515c:	e3ea                	sd	s10,448(sp)
    8000515e:	ff6e                	sd	s11,440(sp)
    80005160:	1400                	addi	s0,sp,544
    80005162:	892a                	mv	s2,a0
    80005164:	dea43423          	sd	a0,-536(s0)
    80005168:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	ad0080e7          	jalr	-1328(ra) # 80001c3c <myproc>
    80005174:	84aa                	mv	s1,a0

  begin_op();
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	47e080e7          	jalr	1150(ra) # 800045f4 <begin_op>

  if((ip = namei(path)) == 0){
    8000517e:	854a                	mv	a0,s2
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	258080e7          	jalr	600(ra) # 800043d8 <namei>
    80005188:	c93d                	beqz	a0,800051fe <exec+0xc4>
    8000518a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	aa6080e7          	jalr	-1370(ra) # 80003c32 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005194:	04000713          	li	a4,64
    80005198:	4681                	li	a3,0
    8000519a:	e5040613          	addi	a2,s0,-432
    8000519e:	4581                	li	a1,0
    800051a0:	8556                	mv	a0,s5
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	d44080e7          	jalr	-700(ra) # 80003ee6 <readi>
    800051aa:	04000793          	li	a5,64
    800051ae:	00f51a63          	bne	a0,a5,800051c2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051b2:	e5042703          	lw	a4,-432(s0)
    800051b6:	464c47b7          	lui	a5,0x464c4
    800051ba:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051be:	04f70663          	beq	a4,a5,8000520a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051c2:	8556                	mv	a0,s5
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	cd0080e7          	jalr	-816(ra) # 80003e94 <iunlockput>
    end_op();
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	4a8080e7          	jalr	1192(ra) # 80004674 <end_op>
  }
  return -1;
    800051d4:	557d                	li	a0,-1
}
    800051d6:	21813083          	ld	ra,536(sp)
    800051da:	21013403          	ld	s0,528(sp)
    800051de:	20813483          	ld	s1,520(sp)
    800051e2:	20013903          	ld	s2,512(sp)
    800051e6:	79fe                	ld	s3,504(sp)
    800051e8:	7a5e                	ld	s4,496(sp)
    800051ea:	7abe                	ld	s5,488(sp)
    800051ec:	7b1e                	ld	s6,480(sp)
    800051ee:	6bfe                	ld	s7,472(sp)
    800051f0:	6c5e                	ld	s8,464(sp)
    800051f2:	6cbe                	ld	s9,456(sp)
    800051f4:	6d1e                	ld	s10,448(sp)
    800051f6:	7dfa                	ld	s11,440(sp)
    800051f8:	22010113          	addi	sp,sp,544
    800051fc:	8082                	ret
    end_op();
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	476080e7          	jalr	1142(ra) # 80004674 <end_op>
    return -1;
    80005206:	557d                	li	a0,-1
    80005208:	b7f9                	j	800051d6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000520a:	8526                	mv	a0,s1
    8000520c:	ffffd097          	auipc	ra,0xffffd
    80005210:	af4080e7          	jalr	-1292(ra) # 80001d00 <proc_pagetable>
    80005214:	8b2a                	mv	s6,a0
    80005216:	d555                	beqz	a0,800051c2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005218:	e7042783          	lw	a5,-400(s0)
    8000521c:	e8845703          	lhu	a4,-376(s0)
    80005220:	c735                	beqz	a4,8000528c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005222:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005224:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005228:	6a05                	lui	s4,0x1
    8000522a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000522e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005232:	6d85                	lui	s11,0x1
    80005234:	7d7d                	lui	s10,0xfffff
    80005236:	a481                	j	80005476 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005238:	00003517          	auipc	a0,0x3
    8000523c:	4b850513          	addi	a0,a0,1208 # 800086f0 <syscalls+0x290>
    80005240:	ffffb097          	auipc	ra,0xffffb
    80005244:	2fe080e7          	jalr	766(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005248:	874a                	mv	a4,s2
    8000524a:	009c86bb          	addw	a3,s9,s1
    8000524e:	4581                	li	a1,0
    80005250:	8556                	mv	a0,s5
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c94080e7          	jalr	-876(ra) # 80003ee6 <readi>
    8000525a:	2501                	sext.w	a0,a0
    8000525c:	1aa91a63          	bne	s2,a0,80005410 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005260:	009d84bb          	addw	s1,s11,s1
    80005264:	013d09bb          	addw	s3,s10,s3
    80005268:	1f74f763          	bgeu	s1,s7,80005456 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000526c:	02049593          	slli	a1,s1,0x20
    80005270:	9181                	srli	a1,a1,0x20
    80005272:	95e2                	add	a1,a1,s8
    80005274:	855a                	mv	a0,s6
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	ee8080e7          	jalr	-280(ra) # 8000115e <walkaddr>
    8000527e:	862a                	mv	a2,a0
    if(pa == 0)
    80005280:	dd45                	beqz	a0,80005238 <exec+0xfe>
      n = PGSIZE;
    80005282:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005284:	fd49f2e3          	bgeu	s3,s4,80005248 <exec+0x10e>
      n = sz - i;
    80005288:	894e                	mv	s2,s3
    8000528a:	bf7d                	j	80005248 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000528c:	4901                	li	s2,0
  iunlockput(ip);
    8000528e:	8556                	mv	a0,s5
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	c04080e7          	jalr	-1020(ra) # 80003e94 <iunlockput>
  end_op();
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	3dc080e7          	jalr	988(ra) # 80004674 <end_op>
  p = myproc();
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	99c080e7          	jalr	-1636(ra) # 80001c3c <myproc>
    800052a8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052aa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052ae:	6785                	lui	a5,0x1
    800052b0:	17fd                	addi	a5,a5,-1
    800052b2:	993e                	add	s2,s2,a5
    800052b4:	77fd                	lui	a5,0xfffff
    800052b6:	00f977b3          	and	a5,s2,a5
    800052ba:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052be:	4691                	li	a3,4
    800052c0:	6609                	lui	a2,0x2
    800052c2:	963e                	add	a2,a2,a5
    800052c4:	85be                	mv	a1,a5
    800052c6:	855a                	mv	a0,s6
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	24a080e7          	jalr	586(ra) # 80001512 <uvmalloc>
    800052d0:	8c2a                	mv	s8,a0
  ip = 0;
    800052d2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052d4:	12050e63          	beqz	a0,80005410 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052d8:	75f9                	lui	a1,0xffffe
    800052da:	95aa                	add	a1,a1,a0
    800052dc:	855a                	mv	a0,s6
    800052de:	ffffc097          	auipc	ra,0xffffc
    800052e2:	548080e7          	jalr	1352(ra) # 80001826 <uvmclear>
  stackbase = sp - PGSIZE;
    800052e6:	7afd                	lui	s5,0xfffff
    800052e8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800052ea:	df043783          	ld	a5,-528(s0)
    800052ee:	6388                	ld	a0,0(a5)
    800052f0:	c925                	beqz	a0,80005360 <exec+0x226>
    800052f2:	e9040993          	addi	s3,s0,-368
    800052f6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052fa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052fc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	c52080e7          	jalr	-942(ra) # 80000f50 <strlen>
    80005306:	0015079b          	addiw	a5,a0,1
    8000530a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000530e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005312:	13596663          	bltu	s2,s5,8000543e <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005316:	df043d83          	ld	s11,-528(s0)
    8000531a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000531e:	8552                	mv	a0,s4
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	c30080e7          	jalr	-976(ra) # 80000f50 <strlen>
    80005328:	0015069b          	addiw	a3,a0,1
    8000532c:	8652                	mv	a2,s4
    8000532e:	85ca                	mv	a1,s2
    80005330:	855a                	mv	a0,s6
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	526080e7          	jalr	1318(ra) # 80001858 <copyout>
    8000533a:	10054663          	bltz	a0,80005446 <exec+0x30c>
    ustack[argc] = sp;
    8000533e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005342:	0485                	addi	s1,s1,1
    80005344:	008d8793          	addi	a5,s11,8
    80005348:	def43823          	sd	a5,-528(s0)
    8000534c:	008db503          	ld	a0,8(s11)
    80005350:	c911                	beqz	a0,80005364 <exec+0x22a>
    if(argc >= MAXARG)
    80005352:	09a1                	addi	s3,s3,8
    80005354:	fb3c95e3          	bne	s9,s3,800052fe <exec+0x1c4>
  sz = sz1;
    80005358:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000535c:	4a81                	li	s5,0
    8000535e:	a84d                	j	80005410 <exec+0x2d6>
  sp = sz;
    80005360:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005362:	4481                	li	s1,0
  ustack[argc] = 0;
    80005364:	00349793          	slli	a5,s1,0x3
    80005368:	f9040713          	addi	a4,s0,-112
    8000536c:	97ba                	add	a5,a5,a4
    8000536e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7fdbcd88>
  sp -= (argc+1) * sizeof(uint64);
    80005372:	00148693          	addi	a3,s1,1
    80005376:	068e                	slli	a3,a3,0x3
    80005378:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000537c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005380:	01597663          	bgeu	s2,s5,8000538c <exec+0x252>
  sz = sz1;
    80005384:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005388:	4a81                	li	s5,0
    8000538a:	a059                	j	80005410 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000538c:	e9040613          	addi	a2,s0,-368
    80005390:	85ca                	mv	a1,s2
    80005392:	855a                	mv	a0,s6
    80005394:	ffffc097          	auipc	ra,0xffffc
    80005398:	4c4080e7          	jalr	1220(ra) # 80001858 <copyout>
    8000539c:	0a054963          	bltz	a0,8000544e <exec+0x314>
  p->trapframe->a1 = sp;
    800053a0:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800053a4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053a8:	de843783          	ld	a5,-536(s0)
    800053ac:	0007c703          	lbu	a4,0(a5)
    800053b0:	cf11                	beqz	a4,800053cc <exec+0x292>
    800053b2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053b4:	02f00693          	li	a3,47
    800053b8:	a039                	j	800053c6 <exec+0x28c>
      last = s+1;
    800053ba:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053be:	0785                	addi	a5,a5,1
    800053c0:	fff7c703          	lbu	a4,-1(a5)
    800053c4:	c701                	beqz	a4,800053cc <exec+0x292>
    if(*s == '/')
    800053c6:	fed71ce3          	bne	a4,a3,800053be <exec+0x284>
    800053ca:	bfc5                	j	800053ba <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800053cc:	4641                	li	a2,16
    800053ce:	de843583          	ld	a1,-536(s0)
    800053d2:	158b8513          	addi	a0,s7,344
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	b48080e7          	jalr	-1208(ra) # 80000f1e <safestrcpy>
  oldpagetable = p->pagetable;
    800053de:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800053e2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800053e6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053ea:	058bb783          	ld	a5,88(s7)
    800053ee:	e6843703          	ld	a4,-408(s0)
    800053f2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053f4:	058bb783          	ld	a5,88(s7)
    800053f8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053fc:	85ea                	mv	a1,s10
    800053fe:	ffffd097          	auipc	ra,0xffffd
    80005402:	99e080e7          	jalr	-1634(ra) # 80001d9c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005406:	0004851b          	sext.w	a0,s1
    8000540a:	b3f1                	j	800051d6 <exec+0x9c>
    8000540c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005410:	df843583          	ld	a1,-520(s0)
    80005414:	855a                	mv	a0,s6
    80005416:	ffffd097          	auipc	ra,0xffffd
    8000541a:	986080e7          	jalr	-1658(ra) # 80001d9c <proc_freepagetable>
  if(ip){
    8000541e:	da0a92e3          	bnez	s5,800051c2 <exec+0x88>
  return -1;
    80005422:	557d                	li	a0,-1
    80005424:	bb4d                	j	800051d6 <exec+0x9c>
    80005426:	df243c23          	sd	s2,-520(s0)
    8000542a:	b7dd                	j	80005410 <exec+0x2d6>
    8000542c:	df243c23          	sd	s2,-520(s0)
    80005430:	b7c5                	j	80005410 <exec+0x2d6>
    80005432:	df243c23          	sd	s2,-520(s0)
    80005436:	bfe9                	j	80005410 <exec+0x2d6>
    80005438:	df243c23          	sd	s2,-520(s0)
    8000543c:	bfd1                	j	80005410 <exec+0x2d6>
  sz = sz1;
    8000543e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005442:	4a81                	li	s5,0
    80005444:	b7f1                	j	80005410 <exec+0x2d6>
  sz = sz1;
    80005446:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000544a:	4a81                	li	s5,0
    8000544c:	b7d1                	j	80005410 <exec+0x2d6>
  sz = sz1;
    8000544e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005452:	4a81                	li	s5,0
    80005454:	bf75                	j	80005410 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005456:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000545a:	e0843783          	ld	a5,-504(s0)
    8000545e:	0017869b          	addiw	a3,a5,1
    80005462:	e0d43423          	sd	a3,-504(s0)
    80005466:	e0043783          	ld	a5,-512(s0)
    8000546a:	0387879b          	addiw	a5,a5,56
    8000546e:	e8845703          	lhu	a4,-376(s0)
    80005472:	e0e6dee3          	bge	a3,a4,8000528e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005476:	2781                	sext.w	a5,a5
    80005478:	e0f43023          	sd	a5,-512(s0)
    8000547c:	03800713          	li	a4,56
    80005480:	86be                	mv	a3,a5
    80005482:	e1840613          	addi	a2,s0,-488
    80005486:	4581                	li	a1,0
    80005488:	8556                	mv	a0,s5
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	a5c080e7          	jalr	-1444(ra) # 80003ee6 <readi>
    80005492:	03800793          	li	a5,56
    80005496:	f6f51be3          	bne	a0,a5,8000540c <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000549a:	e1842783          	lw	a5,-488(s0)
    8000549e:	4705                	li	a4,1
    800054a0:	fae79de3          	bne	a5,a4,8000545a <exec+0x320>
    if(ph.memsz < ph.filesz)
    800054a4:	e4043483          	ld	s1,-448(s0)
    800054a8:	e3843783          	ld	a5,-456(s0)
    800054ac:	f6f4ede3          	bltu	s1,a5,80005426 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054b0:	e2843783          	ld	a5,-472(s0)
    800054b4:	94be                	add	s1,s1,a5
    800054b6:	f6f4ebe3          	bltu	s1,a5,8000542c <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800054ba:	de043703          	ld	a4,-544(s0)
    800054be:	8ff9                	and	a5,a5,a4
    800054c0:	fbad                	bnez	a5,80005432 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054c2:	e1c42503          	lw	a0,-484(s0)
    800054c6:	00000097          	auipc	ra,0x0
    800054ca:	c58080e7          	jalr	-936(ra) # 8000511e <flags2perm>
    800054ce:	86aa                	mv	a3,a0
    800054d0:	8626                	mv	a2,s1
    800054d2:	85ca                	mv	a1,s2
    800054d4:	855a                	mv	a0,s6
    800054d6:	ffffc097          	auipc	ra,0xffffc
    800054da:	03c080e7          	jalr	60(ra) # 80001512 <uvmalloc>
    800054de:	dea43c23          	sd	a0,-520(s0)
    800054e2:	d939                	beqz	a0,80005438 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054e4:	e2843c03          	ld	s8,-472(s0)
    800054e8:	e2042c83          	lw	s9,-480(s0)
    800054ec:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054f0:	f60b83e3          	beqz	s7,80005456 <exec+0x31c>
    800054f4:	89de                	mv	s3,s7
    800054f6:	4481                	li	s1,0
    800054f8:	bb95                	j	8000526c <exec+0x132>

00000000800054fa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054fa:	7179                	addi	sp,sp,-48
    800054fc:	f406                	sd	ra,40(sp)
    800054fe:	f022                	sd	s0,32(sp)
    80005500:	ec26                	sd	s1,24(sp)
    80005502:	e84a                	sd	s2,16(sp)
    80005504:	1800                	addi	s0,sp,48
    80005506:	892e                	mv	s2,a1
    80005508:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000550a:	fdc40593          	addi	a1,s0,-36
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	b08080e7          	jalr	-1272(ra) # 80003016 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005516:	fdc42703          	lw	a4,-36(s0)
    8000551a:	47bd                	li	a5,15
    8000551c:	02e7eb63          	bltu	a5,a4,80005552 <argfd+0x58>
    80005520:	ffffc097          	auipc	ra,0xffffc
    80005524:	71c080e7          	jalr	1820(ra) # 80001c3c <myproc>
    80005528:	fdc42703          	lw	a4,-36(s0)
    8000552c:	01a70793          	addi	a5,a4,26
    80005530:	078e                	slli	a5,a5,0x3
    80005532:	953e                	add	a0,a0,a5
    80005534:	611c                	ld	a5,0(a0)
    80005536:	c385                	beqz	a5,80005556 <argfd+0x5c>
    return -1;
  if(pfd)
    80005538:	00090463          	beqz	s2,80005540 <argfd+0x46>
    *pfd = fd;
    8000553c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005540:	4501                	li	a0,0
  if(pf)
    80005542:	c091                	beqz	s1,80005546 <argfd+0x4c>
    *pf = f;
    80005544:	e09c                	sd	a5,0(s1)
}
    80005546:	70a2                	ld	ra,40(sp)
    80005548:	7402                	ld	s0,32(sp)
    8000554a:	64e2                	ld	s1,24(sp)
    8000554c:	6942                	ld	s2,16(sp)
    8000554e:	6145                	addi	sp,sp,48
    80005550:	8082                	ret
    return -1;
    80005552:	557d                	li	a0,-1
    80005554:	bfcd                	j	80005546 <argfd+0x4c>
    80005556:	557d                	li	a0,-1
    80005558:	b7fd                	j	80005546 <argfd+0x4c>

000000008000555a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000555a:	1101                	addi	sp,sp,-32
    8000555c:	ec06                	sd	ra,24(sp)
    8000555e:	e822                	sd	s0,16(sp)
    80005560:	e426                	sd	s1,8(sp)
    80005562:	1000                	addi	s0,sp,32
    80005564:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005566:	ffffc097          	auipc	ra,0xffffc
    8000556a:	6d6080e7          	jalr	1750(ra) # 80001c3c <myproc>
    8000556e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005570:	0d050793          	addi	a5,a0,208
    80005574:	4501                	li	a0,0
    80005576:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005578:	6398                	ld	a4,0(a5)
    8000557a:	cb19                	beqz	a4,80005590 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000557c:	2505                	addiw	a0,a0,1
    8000557e:	07a1                	addi	a5,a5,8
    80005580:	fed51ce3          	bne	a0,a3,80005578 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005584:	557d                	li	a0,-1
}
    80005586:	60e2                	ld	ra,24(sp)
    80005588:	6442                	ld	s0,16(sp)
    8000558a:	64a2                	ld	s1,8(sp)
    8000558c:	6105                	addi	sp,sp,32
    8000558e:	8082                	ret
      p->ofile[fd] = f;
    80005590:	01a50793          	addi	a5,a0,26
    80005594:	078e                	slli	a5,a5,0x3
    80005596:	963e                	add	a2,a2,a5
    80005598:	e204                	sd	s1,0(a2)
      return fd;
    8000559a:	b7f5                	j	80005586 <fdalloc+0x2c>

000000008000559c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000559c:	715d                	addi	sp,sp,-80
    8000559e:	e486                	sd	ra,72(sp)
    800055a0:	e0a2                	sd	s0,64(sp)
    800055a2:	fc26                	sd	s1,56(sp)
    800055a4:	f84a                	sd	s2,48(sp)
    800055a6:	f44e                	sd	s3,40(sp)
    800055a8:	f052                	sd	s4,32(sp)
    800055aa:	ec56                	sd	s5,24(sp)
    800055ac:	e85a                	sd	s6,16(sp)
    800055ae:	0880                	addi	s0,sp,80
    800055b0:	8b2e                	mv	s6,a1
    800055b2:	89b2                	mv	s3,a2
    800055b4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055b6:	fb040593          	addi	a1,s0,-80
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	e3c080e7          	jalr	-452(ra) # 800043f6 <nameiparent>
    800055c2:	84aa                	mv	s1,a0
    800055c4:	14050f63          	beqz	a0,80005722 <create+0x186>
    return 0;

  ilock(dp);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	66a080e7          	jalr	1642(ra) # 80003c32 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055d0:	4601                	li	a2,0
    800055d2:	fb040593          	addi	a1,s0,-80
    800055d6:	8526                	mv	a0,s1
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	b3e080e7          	jalr	-1218(ra) # 80004116 <dirlookup>
    800055e0:	8aaa                	mv	s5,a0
    800055e2:	c931                	beqz	a0,80005636 <create+0x9a>
    iunlockput(dp);
    800055e4:	8526                	mv	a0,s1
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	8ae080e7          	jalr	-1874(ra) # 80003e94 <iunlockput>
    ilock(ip);
    800055ee:	8556                	mv	a0,s5
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	642080e7          	jalr	1602(ra) # 80003c32 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055f8:	000b059b          	sext.w	a1,s6
    800055fc:	4789                	li	a5,2
    800055fe:	02f59563          	bne	a1,a5,80005628 <create+0x8c>
    80005602:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbcecc>
    80005606:	37f9                	addiw	a5,a5,-2
    80005608:	17c2                	slli	a5,a5,0x30
    8000560a:	93c1                	srli	a5,a5,0x30
    8000560c:	4705                	li	a4,1
    8000560e:	00f76d63          	bltu	a4,a5,80005628 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005612:	8556                	mv	a0,s5
    80005614:	60a6                	ld	ra,72(sp)
    80005616:	6406                	ld	s0,64(sp)
    80005618:	74e2                	ld	s1,56(sp)
    8000561a:	7942                	ld	s2,48(sp)
    8000561c:	79a2                	ld	s3,40(sp)
    8000561e:	7a02                	ld	s4,32(sp)
    80005620:	6ae2                	ld	s5,24(sp)
    80005622:	6b42                	ld	s6,16(sp)
    80005624:	6161                	addi	sp,sp,80
    80005626:	8082                	ret
    iunlockput(ip);
    80005628:	8556                	mv	a0,s5
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	86a080e7          	jalr	-1942(ra) # 80003e94 <iunlockput>
    return 0;
    80005632:	4a81                	li	s5,0
    80005634:	bff9                	j	80005612 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005636:	85da                	mv	a1,s6
    80005638:	4088                	lw	a0,0(s1)
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	45c080e7          	jalr	1116(ra) # 80003a96 <ialloc>
    80005642:	8a2a                	mv	s4,a0
    80005644:	c539                	beqz	a0,80005692 <create+0xf6>
  ilock(ip);
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	5ec080e7          	jalr	1516(ra) # 80003c32 <ilock>
  ip->major = major;
    8000564e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005652:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005656:	4905                	li	s2,1
    80005658:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000565c:	8552                	mv	a0,s4
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	50a080e7          	jalr	1290(ra) # 80003b68 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005666:	000b059b          	sext.w	a1,s6
    8000566a:	03258b63          	beq	a1,s2,800056a0 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000566e:	004a2603          	lw	a2,4(s4)
    80005672:	fb040593          	addi	a1,s0,-80
    80005676:	8526                	mv	a0,s1
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	cae080e7          	jalr	-850(ra) # 80004326 <dirlink>
    80005680:	06054f63          	bltz	a0,800056fe <create+0x162>
  iunlockput(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	80e080e7          	jalr	-2034(ra) # 80003e94 <iunlockput>
  return ip;
    8000568e:	8ad2                	mv	s5,s4
    80005690:	b749                	j	80005612 <create+0x76>
    iunlockput(dp);
    80005692:	8526                	mv	a0,s1
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	800080e7          	jalr	-2048(ra) # 80003e94 <iunlockput>
    return 0;
    8000569c:	8ad2                	mv	s5,s4
    8000569e:	bf95                	j	80005612 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056a0:	004a2603          	lw	a2,4(s4)
    800056a4:	00003597          	auipc	a1,0x3
    800056a8:	06c58593          	addi	a1,a1,108 # 80008710 <syscalls+0x2b0>
    800056ac:	8552                	mv	a0,s4
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	c78080e7          	jalr	-904(ra) # 80004326 <dirlink>
    800056b6:	04054463          	bltz	a0,800056fe <create+0x162>
    800056ba:	40d0                	lw	a2,4(s1)
    800056bc:	00003597          	auipc	a1,0x3
    800056c0:	05c58593          	addi	a1,a1,92 # 80008718 <syscalls+0x2b8>
    800056c4:	8552                	mv	a0,s4
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	c60080e7          	jalr	-928(ra) # 80004326 <dirlink>
    800056ce:	02054863          	bltz	a0,800056fe <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800056d2:	004a2603          	lw	a2,4(s4)
    800056d6:	fb040593          	addi	a1,s0,-80
    800056da:	8526                	mv	a0,s1
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	c4a080e7          	jalr	-950(ra) # 80004326 <dirlink>
    800056e4:	00054d63          	bltz	a0,800056fe <create+0x162>
    dp->nlink++;  // for ".."
    800056e8:	04a4d783          	lhu	a5,74(s1)
    800056ec:	2785                	addiw	a5,a5,1
    800056ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	474080e7          	jalr	1140(ra) # 80003b68 <iupdate>
    800056fc:	b761                	j	80005684 <create+0xe8>
  ip->nlink = 0;
    800056fe:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005702:	8552                	mv	a0,s4
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	464080e7          	jalr	1124(ra) # 80003b68 <iupdate>
  iunlockput(ip);
    8000570c:	8552                	mv	a0,s4
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	786080e7          	jalr	1926(ra) # 80003e94 <iunlockput>
  iunlockput(dp);
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	77c080e7          	jalr	1916(ra) # 80003e94 <iunlockput>
  return 0;
    80005720:	bdcd                	j	80005612 <create+0x76>
    return 0;
    80005722:	8aaa                	mv	s5,a0
    80005724:	b5fd                	j	80005612 <create+0x76>

0000000080005726 <sys_dup>:
{
    80005726:	7179                	addi	sp,sp,-48
    80005728:	f406                	sd	ra,40(sp)
    8000572a:	f022                	sd	s0,32(sp)
    8000572c:	ec26                	sd	s1,24(sp)
    8000572e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005730:	fd840613          	addi	a2,s0,-40
    80005734:	4581                	li	a1,0
    80005736:	4501                	li	a0,0
    80005738:	00000097          	auipc	ra,0x0
    8000573c:	dc2080e7          	jalr	-574(ra) # 800054fa <argfd>
    return -1;
    80005740:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005742:	02054363          	bltz	a0,80005768 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005746:	fd843503          	ld	a0,-40(s0)
    8000574a:	00000097          	auipc	ra,0x0
    8000574e:	e10080e7          	jalr	-496(ra) # 8000555a <fdalloc>
    80005752:	84aa                	mv	s1,a0
    return -1;
    80005754:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005756:	00054963          	bltz	a0,80005768 <sys_dup+0x42>
  filedup(f);
    8000575a:	fd843503          	ld	a0,-40(s0)
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	310080e7          	jalr	784(ra) # 80004a6e <filedup>
  return fd;
    80005766:	87a6                	mv	a5,s1
}
    80005768:	853e                	mv	a0,a5
    8000576a:	70a2                	ld	ra,40(sp)
    8000576c:	7402                	ld	s0,32(sp)
    8000576e:	64e2                	ld	s1,24(sp)
    80005770:	6145                	addi	sp,sp,48
    80005772:	8082                	ret

0000000080005774 <sys_read>:
{
    80005774:	7179                	addi	sp,sp,-48
    80005776:	f406                	sd	ra,40(sp)
    80005778:	f022                	sd	s0,32(sp)
    8000577a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000577c:	fd840593          	addi	a1,s0,-40
    80005780:	4505                	li	a0,1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	8b4080e7          	jalr	-1868(ra) # 80003036 <argaddr>
  argint(2, &n);
    8000578a:	fe440593          	addi	a1,s0,-28
    8000578e:	4509                	li	a0,2
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	886080e7          	jalr	-1914(ra) # 80003016 <argint>
  if(argfd(0, 0, &f) < 0)
    80005798:	fe840613          	addi	a2,s0,-24
    8000579c:	4581                	li	a1,0
    8000579e:	4501                	li	a0,0
    800057a0:	00000097          	auipc	ra,0x0
    800057a4:	d5a080e7          	jalr	-678(ra) # 800054fa <argfd>
    800057a8:	87aa                	mv	a5,a0
    return -1;
    800057aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057ac:	0007cc63          	bltz	a5,800057c4 <sys_read+0x50>
  return fileread(f, p, n);
    800057b0:	fe442603          	lw	a2,-28(s0)
    800057b4:	fd843583          	ld	a1,-40(s0)
    800057b8:	fe843503          	ld	a0,-24(s0)
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	43e080e7          	jalr	1086(ra) # 80004bfa <fileread>
}
    800057c4:	70a2                	ld	ra,40(sp)
    800057c6:	7402                	ld	s0,32(sp)
    800057c8:	6145                	addi	sp,sp,48
    800057ca:	8082                	ret

00000000800057cc <sys_write>:
{
    800057cc:	7179                	addi	sp,sp,-48
    800057ce:	f406                	sd	ra,40(sp)
    800057d0:	f022                	sd	s0,32(sp)
    800057d2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057d4:	fd840593          	addi	a1,s0,-40
    800057d8:	4505                	li	a0,1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	85c080e7          	jalr	-1956(ra) # 80003036 <argaddr>
  argint(2, &n);
    800057e2:	fe440593          	addi	a1,s0,-28
    800057e6:	4509                	li	a0,2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	82e080e7          	jalr	-2002(ra) # 80003016 <argint>
  if(argfd(0, 0, &f) < 0)
    800057f0:	fe840613          	addi	a2,s0,-24
    800057f4:	4581                	li	a1,0
    800057f6:	4501                	li	a0,0
    800057f8:	00000097          	auipc	ra,0x0
    800057fc:	d02080e7          	jalr	-766(ra) # 800054fa <argfd>
    80005800:	87aa                	mv	a5,a0
    return -1;
    80005802:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005804:	0007cc63          	bltz	a5,8000581c <sys_write+0x50>
  return filewrite(f, p, n);
    80005808:	fe442603          	lw	a2,-28(s0)
    8000580c:	fd843583          	ld	a1,-40(s0)
    80005810:	fe843503          	ld	a0,-24(s0)
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	4a8080e7          	jalr	1192(ra) # 80004cbc <filewrite>
}
    8000581c:	70a2                	ld	ra,40(sp)
    8000581e:	7402                	ld	s0,32(sp)
    80005820:	6145                	addi	sp,sp,48
    80005822:	8082                	ret

0000000080005824 <sys_close>:
{
    80005824:	1101                	addi	sp,sp,-32
    80005826:	ec06                	sd	ra,24(sp)
    80005828:	e822                	sd	s0,16(sp)
    8000582a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000582c:	fe040613          	addi	a2,s0,-32
    80005830:	fec40593          	addi	a1,s0,-20
    80005834:	4501                	li	a0,0
    80005836:	00000097          	auipc	ra,0x0
    8000583a:	cc4080e7          	jalr	-828(ra) # 800054fa <argfd>
    return -1;
    8000583e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005840:	02054463          	bltz	a0,80005868 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005844:	ffffc097          	auipc	ra,0xffffc
    80005848:	3f8080e7          	jalr	1016(ra) # 80001c3c <myproc>
    8000584c:	fec42783          	lw	a5,-20(s0)
    80005850:	07e9                	addi	a5,a5,26
    80005852:	078e                	slli	a5,a5,0x3
    80005854:	97aa                	add	a5,a5,a0
    80005856:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000585a:	fe043503          	ld	a0,-32(s0)
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	262080e7          	jalr	610(ra) # 80004ac0 <fileclose>
  return 0;
    80005866:	4781                	li	a5,0
}
    80005868:	853e                	mv	a0,a5
    8000586a:	60e2                	ld	ra,24(sp)
    8000586c:	6442                	ld	s0,16(sp)
    8000586e:	6105                	addi	sp,sp,32
    80005870:	8082                	ret

0000000080005872 <sys_fstat>:
{
    80005872:	1101                	addi	sp,sp,-32
    80005874:	ec06                	sd	ra,24(sp)
    80005876:	e822                	sd	s0,16(sp)
    80005878:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000587a:	fe040593          	addi	a1,s0,-32
    8000587e:	4505                	li	a0,1
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	7b6080e7          	jalr	1974(ra) # 80003036 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005888:	fe840613          	addi	a2,s0,-24
    8000588c:	4581                	li	a1,0
    8000588e:	4501                	li	a0,0
    80005890:	00000097          	auipc	ra,0x0
    80005894:	c6a080e7          	jalr	-918(ra) # 800054fa <argfd>
    80005898:	87aa                	mv	a5,a0
    return -1;
    8000589a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000589c:	0007ca63          	bltz	a5,800058b0 <sys_fstat+0x3e>
  return filestat(f, st);
    800058a0:	fe043583          	ld	a1,-32(s0)
    800058a4:	fe843503          	ld	a0,-24(s0)
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	2e0080e7          	jalr	736(ra) # 80004b88 <filestat>
}
    800058b0:	60e2                	ld	ra,24(sp)
    800058b2:	6442                	ld	s0,16(sp)
    800058b4:	6105                	addi	sp,sp,32
    800058b6:	8082                	ret

00000000800058b8 <sys_link>:
{
    800058b8:	7169                	addi	sp,sp,-304
    800058ba:	f606                	sd	ra,296(sp)
    800058bc:	f222                	sd	s0,288(sp)
    800058be:	ee26                	sd	s1,280(sp)
    800058c0:	ea4a                	sd	s2,272(sp)
    800058c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058c4:	08000613          	li	a2,128
    800058c8:	ed040593          	addi	a1,s0,-304
    800058cc:	4501                	li	a0,0
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	788080e7          	jalr	1928(ra) # 80003056 <argstr>
    return -1;
    800058d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d8:	10054e63          	bltz	a0,800059f4 <sys_link+0x13c>
    800058dc:	08000613          	li	a2,128
    800058e0:	f5040593          	addi	a1,s0,-176
    800058e4:	4505                	li	a0,1
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	770080e7          	jalr	1904(ra) # 80003056 <argstr>
    return -1;
    800058ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058f0:	10054263          	bltz	a0,800059f4 <sys_link+0x13c>
  begin_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	d00080e7          	jalr	-768(ra) # 800045f4 <begin_op>
  if((ip = namei(old)) == 0){
    800058fc:	ed040513          	addi	a0,s0,-304
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	ad8080e7          	jalr	-1320(ra) # 800043d8 <namei>
    80005908:	84aa                	mv	s1,a0
    8000590a:	c551                	beqz	a0,80005996 <sys_link+0xde>
  ilock(ip);
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	326080e7          	jalr	806(ra) # 80003c32 <ilock>
  if(ip->type == T_DIR){
    80005914:	04449703          	lh	a4,68(s1)
    80005918:	4785                	li	a5,1
    8000591a:	08f70463          	beq	a4,a5,800059a2 <sys_link+0xea>
  ip->nlink++;
    8000591e:	04a4d783          	lhu	a5,74(s1)
    80005922:	2785                	addiw	a5,a5,1
    80005924:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005928:	8526                	mv	a0,s1
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	23e080e7          	jalr	574(ra) # 80003b68 <iupdate>
  iunlock(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	3c0080e7          	jalr	960(ra) # 80003cf4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000593c:	fd040593          	addi	a1,s0,-48
    80005940:	f5040513          	addi	a0,s0,-176
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	ab2080e7          	jalr	-1358(ra) # 800043f6 <nameiparent>
    8000594c:	892a                	mv	s2,a0
    8000594e:	c935                	beqz	a0,800059c2 <sys_link+0x10a>
  ilock(dp);
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	2e2080e7          	jalr	738(ra) # 80003c32 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005958:	00092703          	lw	a4,0(s2)
    8000595c:	409c                	lw	a5,0(s1)
    8000595e:	04f71d63          	bne	a4,a5,800059b8 <sys_link+0x100>
    80005962:	40d0                	lw	a2,4(s1)
    80005964:	fd040593          	addi	a1,s0,-48
    80005968:	854a                	mv	a0,s2
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	9bc080e7          	jalr	-1604(ra) # 80004326 <dirlink>
    80005972:	04054363          	bltz	a0,800059b8 <sys_link+0x100>
  iunlockput(dp);
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	51c080e7          	jalr	1308(ra) # 80003e94 <iunlockput>
  iput(ip);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	46a080e7          	jalr	1130(ra) # 80003dec <iput>
  end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	cea080e7          	jalr	-790(ra) # 80004674 <end_op>
  return 0;
    80005992:	4781                	li	a5,0
    80005994:	a085                	j	800059f4 <sys_link+0x13c>
    end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	cde080e7          	jalr	-802(ra) # 80004674 <end_op>
    return -1;
    8000599e:	57fd                	li	a5,-1
    800059a0:	a891                	j	800059f4 <sys_link+0x13c>
    iunlockput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	4f0080e7          	jalr	1264(ra) # 80003e94 <iunlockput>
    end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	cc8080e7          	jalr	-824(ra) # 80004674 <end_op>
    return -1;
    800059b4:	57fd                	li	a5,-1
    800059b6:	a83d                	j	800059f4 <sys_link+0x13c>
    iunlockput(dp);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	4da080e7          	jalr	1242(ra) # 80003e94 <iunlockput>
  ilock(ip);
    800059c2:	8526                	mv	a0,s1
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	26e080e7          	jalr	622(ra) # 80003c32 <ilock>
  ip->nlink--;
    800059cc:	04a4d783          	lhu	a5,74(s1)
    800059d0:	37fd                	addiw	a5,a5,-1
    800059d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	190080e7          	jalr	400(ra) # 80003b68 <iupdate>
  iunlockput(ip);
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	4b2080e7          	jalr	1202(ra) # 80003e94 <iunlockput>
  end_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	c8a080e7          	jalr	-886(ra) # 80004674 <end_op>
  return -1;
    800059f2:	57fd                	li	a5,-1
}
    800059f4:	853e                	mv	a0,a5
    800059f6:	70b2                	ld	ra,296(sp)
    800059f8:	7412                	ld	s0,288(sp)
    800059fa:	64f2                	ld	s1,280(sp)
    800059fc:	6952                	ld	s2,272(sp)
    800059fe:	6155                	addi	sp,sp,304
    80005a00:	8082                	ret

0000000080005a02 <sys_unlink>:
{
    80005a02:	7151                	addi	sp,sp,-240
    80005a04:	f586                	sd	ra,232(sp)
    80005a06:	f1a2                	sd	s0,224(sp)
    80005a08:	eda6                	sd	s1,216(sp)
    80005a0a:	e9ca                	sd	s2,208(sp)
    80005a0c:	e5ce                	sd	s3,200(sp)
    80005a0e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a10:	08000613          	li	a2,128
    80005a14:	f3040593          	addi	a1,s0,-208
    80005a18:	4501                	li	a0,0
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	63c080e7          	jalr	1596(ra) # 80003056 <argstr>
    80005a22:	18054163          	bltz	a0,80005ba4 <sys_unlink+0x1a2>
  begin_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	bce080e7          	jalr	-1074(ra) # 800045f4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a2e:	fb040593          	addi	a1,s0,-80
    80005a32:	f3040513          	addi	a0,s0,-208
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	9c0080e7          	jalr	-1600(ra) # 800043f6 <nameiparent>
    80005a3e:	84aa                	mv	s1,a0
    80005a40:	c979                	beqz	a0,80005b16 <sys_unlink+0x114>
  ilock(dp);
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	1f0080e7          	jalr	496(ra) # 80003c32 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a4a:	00003597          	auipc	a1,0x3
    80005a4e:	cc658593          	addi	a1,a1,-826 # 80008710 <syscalls+0x2b0>
    80005a52:	fb040513          	addi	a0,s0,-80
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	6a6080e7          	jalr	1702(ra) # 800040fc <namecmp>
    80005a5e:	14050a63          	beqz	a0,80005bb2 <sys_unlink+0x1b0>
    80005a62:	00003597          	auipc	a1,0x3
    80005a66:	cb658593          	addi	a1,a1,-842 # 80008718 <syscalls+0x2b8>
    80005a6a:	fb040513          	addi	a0,s0,-80
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	68e080e7          	jalr	1678(ra) # 800040fc <namecmp>
    80005a76:	12050e63          	beqz	a0,80005bb2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a7a:	f2c40613          	addi	a2,s0,-212
    80005a7e:	fb040593          	addi	a1,s0,-80
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	692080e7          	jalr	1682(ra) # 80004116 <dirlookup>
    80005a8c:	892a                	mv	s2,a0
    80005a8e:	12050263          	beqz	a0,80005bb2 <sys_unlink+0x1b0>
  ilock(ip);
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	1a0080e7          	jalr	416(ra) # 80003c32 <ilock>
  if(ip->nlink < 1)
    80005a9a:	04a91783          	lh	a5,74(s2)
    80005a9e:	08f05263          	blez	a5,80005b22 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005aa2:	04491703          	lh	a4,68(s2)
    80005aa6:	4785                	li	a5,1
    80005aa8:	08f70563          	beq	a4,a5,80005b32 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005aac:	4641                	li	a2,16
    80005aae:	4581                	li	a1,0
    80005ab0:	fc040513          	addi	a0,s0,-64
    80005ab4:	ffffb097          	auipc	ra,0xffffb
    80005ab8:	320080e7          	jalr	800(ra) # 80000dd4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005abc:	4741                	li	a4,16
    80005abe:	f2c42683          	lw	a3,-212(s0)
    80005ac2:	fc040613          	addi	a2,s0,-64
    80005ac6:	4581                	li	a1,0
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	514080e7          	jalr	1300(ra) # 80003fde <writei>
    80005ad2:	47c1                	li	a5,16
    80005ad4:	0af51563          	bne	a0,a5,80005b7e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ad8:	04491703          	lh	a4,68(s2)
    80005adc:	4785                	li	a5,1
    80005ade:	0af70863          	beq	a4,a5,80005b8e <sys_unlink+0x18c>
  iunlockput(dp);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	3b0080e7          	jalr	944(ra) # 80003e94 <iunlockput>
  ip->nlink--;
    80005aec:	04a95783          	lhu	a5,74(s2)
    80005af0:	37fd                	addiw	a5,a5,-1
    80005af2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005af6:	854a                	mv	a0,s2
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	070080e7          	jalr	112(ra) # 80003b68 <iupdate>
  iunlockput(ip);
    80005b00:	854a                	mv	a0,s2
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	392080e7          	jalr	914(ra) # 80003e94 <iunlockput>
  end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	b6a080e7          	jalr	-1174(ra) # 80004674 <end_op>
  return 0;
    80005b12:	4501                	li	a0,0
    80005b14:	a84d                	j	80005bc6 <sys_unlink+0x1c4>
    end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	b5e080e7          	jalr	-1186(ra) # 80004674 <end_op>
    return -1;
    80005b1e:	557d                	li	a0,-1
    80005b20:	a05d                	j	80005bc6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b22:	00003517          	auipc	a0,0x3
    80005b26:	bfe50513          	addi	a0,a0,-1026 # 80008720 <syscalls+0x2c0>
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	a14080e7          	jalr	-1516(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b32:	04c92703          	lw	a4,76(s2)
    80005b36:	02000793          	li	a5,32
    80005b3a:	f6e7f9e3          	bgeu	a5,a4,80005aac <sys_unlink+0xaa>
    80005b3e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b42:	4741                	li	a4,16
    80005b44:	86ce                	mv	a3,s3
    80005b46:	f1840613          	addi	a2,s0,-232
    80005b4a:	4581                	li	a1,0
    80005b4c:	854a                	mv	a0,s2
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	398080e7          	jalr	920(ra) # 80003ee6 <readi>
    80005b56:	47c1                	li	a5,16
    80005b58:	00f51b63          	bne	a0,a5,80005b6e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b5c:	f1845783          	lhu	a5,-232(s0)
    80005b60:	e7a1                	bnez	a5,80005ba8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b62:	29c1                	addiw	s3,s3,16
    80005b64:	04c92783          	lw	a5,76(s2)
    80005b68:	fcf9ede3          	bltu	s3,a5,80005b42 <sys_unlink+0x140>
    80005b6c:	b781                	j	80005aac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b6e:	00003517          	auipc	a0,0x3
    80005b72:	bca50513          	addi	a0,a0,-1078 # 80008738 <syscalls+0x2d8>
    80005b76:	ffffb097          	auipc	ra,0xffffb
    80005b7a:	9c8080e7          	jalr	-1592(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b7e:	00003517          	auipc	a0,0x3
    80005b82:	bd250513          	addi	a0,a0,-1070 # 80008750 <syscalls+0x2f0>
    80005b86:	ffffb097          	auipc	ra,0xffffb
    80005b8a:	9b8080e7          	jalr	-1608(ra) # 8000053e <panic>
    dp->nlink--;
    80005b8e:	04a4d783          	lhu	a5,74(s1)
    80005b92:	37fd                	addiw	a5,a5,-1
    80005b94:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b98:	8526                	mv	a0,s1
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	fce080e7          	jalr	-50(ra) # 80003b68 <iupdate>
    80005ba2:	b781                	j	80005ae2 <sys_unlink+0xe0>
    return -1;
    80005ba4:	557d                	li	a0,-1
    80005ba6:	a005                	j	80005bc6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ba8:	854a                	mv	a0,s2
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	2ea080e7          	jalr	746(ra) # 80003e94 <iunlockput>
  iunlockput(dp);
    80005bb2:	8526                	mv	a0,s1
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	2e0080e7          	jalr	736(ra) # 80003e94 <iunlockput>
  end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	ab8080e7          	jalr	-1352(ra) # 80004674 <end_op>
  return -1;
    80005bc4:	557d                	li	a0,-1
}
    80005bc6:	70ae                	ld	ra,232(sp)
    80005bc8:	740e                	ld	s0,224(sp)
    80005bca:	64ee                	ld	s1,216(sp)
    80005bcc:	694e                	ld	s2,208(sp)
    80005bce:	69ae                	ld	s3,200(sp)
    80005bd0:	616d                	addi	sp,sp,240
    80005bd2:	8082                	ret

0000000080005bd4 <sys_open>:

uint64
sys_open(void)
{
    80005bd4:	7131                	addi	sp,sp,-192
    80005bd6:	fd06                	sd	ra,184(sp)
    80005bd8:	f922                	sd	s0,176(sp)
    80005bda:	f526                	sd	s1,168(sp)
    80005bdc:	f14a                	sd	s2,160(sp)
    80005bde:	ed4e                	sd	s3,152(sp)
    80005be0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005be2:	f4c40593          	addi	a1,s0,-180
    80005be6:	4505                	li	a0,1
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	42e080e7          	jalr	1070(ra) # 80003016 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bf0:	08000613          	li	a2,128
    80005bf4:	f5040593          	addi	a1,s0,-176
    80005bf8:	4501                	li	a0,0
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	45c080e7          	jalr	1116(ra) # 80003056 <argstr>
    80005c02:	87aa                	mv	a5,a0
    return -1;
    80005c04:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c06:	0a07c963          	bltz	a5,80005cb8 <sys_open+0xe4>

  begin_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	9ea080e7          	jalr	-1558(ra) # 800045f4 <begin_op>

  if(omode & O_CREATE){
    80005c12:	f4c42783          	lw	a5,-180(s0)
    80005c16:	2007f793          	andi	a5,a5,512
    80005c1a:	cfc5                	beqz	a5,80005cd2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c1c:	4681                	li	a3,0
    80005c1e:	4601                	li	a2,0
    80005c20:	4589                	li	a1,2
    80005c22:	f5040513          	addi	a0,s0,-176
    80005c26:	00000097          	auipc	ra,0x0
    80005c2a:	976080e7          	jalr	-1674(ra) # 8000559c <create>
    80005c2e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c30:	c959                	beqz	a0,80005cc6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c32:	04449703          	lh	a4,68(s1)
    80005c36:	478d                	li	a5,3
    80005c38:	00f71763          	bne	a4,a5,80005c46 <sys_open+0x72>
    80005c3c:	0464d703          	lhu	a4,70(s1)
    80005c40:	47a5                	li	a5,9
    80005c42:	0ce7ed63          	bltu	a5,a4,80005d1c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	dbe080e7          	jalr	-578(ra) # 80004a04 <filealloc>
    80005c4e:	89aa                	mv	s3,a0
    80005c50:	10050363          	beqz	a0,80005d56 <sys_open+0x182>
    80005c54:	00000097          	auipc	ra,0x0
    80005c58:	906080e7          	jalr	-1786(ra) # 8000555a <fdalloc>
    80005c5c:	892a                	mv	s2,a0
    80005c5e:	0e054763          	bltz	a0,80005d4c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c62:	04449703          	lh	a4,68(s1)
    80005c66:	478d                	li	a5,3
    80005c68:	0cf70563          	beq	a4,a5,80005d32 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c6c:	4789                	li	a5,2
    80005c6e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c72:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c76:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c7a:	f4c42783          	lw	a5,-180(s0)
    80005c7e:	0017c713          	xori	a4,a5,1
    80005c82:	8b05                	andi	a4,a4,1
    80005c84:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c88:	0037f713          	andi	a4,a5,3
    80005c8c:	00e03733          	snez	a4,a4
    80005c90:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c94:	4007f793          	andi	a5,a5,1024
    80005c98:	c791                	beqz	a5,80005ca4 <sys_open+0xd0>
    80005c9a:	04449703          	lh	a4,68(s1)
    80005c9e:	4789                	li	a5,2
    80005ca0:	0af70063          	beq	a4,a5,80005d40 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ca4:	8526                	mv	a0,s1
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	04e080e7          	jalr	78(ra) # 80003cf4 <iunlock>
  end_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	9c6080e7          	jalr	-1594(ra) # 80004674 <end_op>

  return fd;
    80005cb6:	854a                	mv	a0,s2
}
    80005cb8:	70ea                	ld	ra,184(sp)
    80005cba:	744a                	ld	s0,176(sp)
    80005cbc:	74aa                	ld	s1,168(sp)
    80005cbe:	790a                	ld	s2,160(sp)
    80005cc0:	69ea                	ld	s3,152(sp)
    80005cc2:	6129                	addi	sp,sp,192
    80005cc4:	8082                	ret
      end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	9ae080e7          	jalr	-1618(ra) # 80004674 <end_op>
      return -1;
    80005cce:	557d                	li	a0,-1
    80005cd0:	b7e5                	j	80005cb8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cd2:	f5040513          	addi	a0,s0,-176
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	702080e7          	jalr	1794(ra) # 800043d8 <namei>
    80005cde:	84aa                	mv	s1,a0
    80005ce0:	c905                	beqz	a0,80005d10 <sys_open+0x13c>
    ilock(ip);
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	f50080e7          	jalr	-176(ra) # 80003c32 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cea:	04449703          	lh	a4,68(s1)
    80005cee:	4785                	li	a5,1
    80005cf0:	f4f711e3          	bne	a4,a5,80005c32 <sys_open+0x5e>
    80005cf4:	f4c42783          	lw	a5,-180(s0)
    80005cf8:	d7b9                	beqz	a5,80005c46 <sys_open+0x72>
      iunlockput(ip);
    80005cfa:	8526                	mv	a0,s1
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	198080e7          	jalr	408(ra) # 80003e94 <iunlockput>
      end_op();
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	970080e7          	jalr	-1680(ra) # 80004674 <end_op>
      return -1;
    80005d0c:	557d                	li	a0,-1
    80005d0e:	b76d                	j	80005cb8 <sys_open+0xe4>
      end_op();
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	964080e7          	jalr	-1692(ra) # 80004674 <end_op>
      return -1;
    80005d18:	557d                	li	a0,-1
    80005d1a:	bf79                	j	80005cb8 <sys_open+0xe4>
    iunlockput(ip);
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	176080e7          	jalr	374(ra) # 80003e94 <iunlockput>
    end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	94e080e7          	jalr	-1714(ra) # 80004674 <end_op>
    return -1;
    80005d2e:	557d                	li	a0,-1
    80005d30:	b761                	j	80005cb8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d32:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d36:	04649783          	lh	a5,70(s1)
    80005d3a:	02f99223          	sh	a5,36(s3)
    80005d3e:	bf25                	j	80005c76 <sys_open+0xa2>
    itrunc(ip);
    80005d40:	8526                	mv	a0,s1
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	ffe080e7          	jalr	-2(ra) # 80003d40 <itrunc>
    80005d4a:	bfa9                	j	80005ca4 <sys_open+0xd0>
      fileclose(f);
    80005d4c:	854e                	mv	a0,s3
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	d72080e7          	jalr	-654(ra) # 80004ac0 <fileclose>
    iunlockput(ip);
    80005d56:	8526                	mv	a0,s1
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	13c080e7          	jalr	316(ra) # 80003e94 <iunlockput>
    end_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	914080e7          	jalr	-1772(ra) # 80004674 <end_op>
    return -1;
    80005d68:	557d                	li	a0,-1
    80005d6a:	b7b9                	j	80005cb8 <sys_open+0xe4>

0000000080005d6c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d6c:	7175                	addi	sp,sp,-144
    80005d6e:	e506                	sd	ra,136(sp)
    80005d70:	e122                	sd	s0,128(sp)
    80005d72:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	880080e7          	jalr	-1920(ra) # 800045f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d7c:	08000613          	li	a2,128
    80005d80:	f7040593          	addi	a1,s0,-144
    80005d84:	4501                	li	a0,0
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	2d0080e7          	jalr	720(ra) # 80003056 <argstr>
    80005d8e:	02054963          	bltz	a0,80005dc0 <sys_mkdir+0x54>
    80005d92:	4681                	li	a3,0
    80005d94:	4601                	li	a2,0
    80005d96:	4585                	li	a1,1
    80005d98:	f7040513          	addi	a0,s0,-144
    80005d9c:	00000097          	auipc	ra,0x0
    80005da0:	800080e7          	jalr	-2048(ra) # 8000559c <create>
    80005da4:	cd11                	beqz	a0,80005dc0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	0ee080e7          	jalr	238(ra) # 80003e94 <iunlockput>
  end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	8c6080e7          	jalr	-1850(ra) # 80004674 <end_op>
  return 0;
    80005db6:	4501                	li	a0,0
}
    80005db8:	60aa                	ld	ra,136(sp)
    80005dba:	640a                	ld	s0,128(sp)
    80005dbc:	6149                	addi	sp,sp,144
    80005dbe:	8082                	ret
    end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	8b4080e7          	jalr	-1868(ra) # 80004674 <end_op>
    return -1;
    80005dc8:	557d                	li	a0,-1
    80005dca:	b7fd                	j	80005db8 <sys_mkdir+0x4c>

0000000080005dcc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dcc:	7135                	addi	sp,sp,-160
    80005dce:	ed06                	sd	ra,152(sp)
    80005dd0:	e922                	sd	s0,144(sp)
    80005dd2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	820080e7          	jalr	-2016(ra) # 800045f4 <begin_op>
  argint(1, &major);
    80005ddc:	f6c40593          	addi	a1,s0,-148
    80005de0:	4505                	li	a0,1
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	234080e7          	jalr	564(ra) # 80003016 <argint>
  argint(2, &minor);
    80005dea:	f6840593          	addi	a1,s0,-152
    80005dee:	4509                	li	a0,2
    80005df0:	ffffd097          	auipc	ra,0xffffd
    80005df4:	226080e7          	jalr	550(ra) # 80003016 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005df8:	08000613          	li	a2,128
    80005dfc:	f7040593          	addi	a1,s0,-144
    80005e00:	4501                	li	a0,0
    80005e02:	ffffd097          	auipc	ra,0xffffd
    80005e06:	254080e7          	jalr	596(ra) # 80003056 <argstr>
    80005e0a:	02054b63          	bltz	a0,80005e40 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e0e:	f6841683          	lh	a3,-152(s0)
    80005e12:	f6c41603          	lh	a2,-148(s0)
    80005e16:	458d                	li	a1,3
    80005e18:	f7040513          	addi	a0,s0,-144
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	780080e7          	jalr	1920(ra) # 8000559c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e24:	cd11                	beqz	a0,80005e40 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	06e080e7          	jalr	110(ra) # 80003e94 <iunlockput>
  end_op();
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	846080e7          	jalr	-1978(ra) # 80004674 <end_op>
  return 0;
    80005e36:	4501                	li	a0,0
}
    80005e38:	60ea                	ld	ra,152(sp)
    80005e3a:	644a                	ld	s0,144(sp)
    80005e3c:	610d                	addi	sp,sp,160
    80005e3e:	8082                	ret
    end_op();
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	834080e7          	jalr	-1996(ra) # 80004674 <end_op>
    return -1;
    80005e48:	557d                	li	a0,-1
    80005e4a:	b7fd                	j	80005e38 <sys_mknod+0x6c>

0000000080005e4c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e4c:	7135                	addi	sp,sp,-160
    80005e4e:	ed06                	sd	ra,152(sp)
    80005e50:	e922                	sd	s0,144(sp)
    80005e52:	e526                	sd	s1,136(sp)
    80005e54:	e14a                	sd	s2,128(sp)
    80005e56:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	de4080e7          	jalr	-540(ra) # 80001c3c <myproc>
    80005e60:	892a                	mv	s2,a0
  
  begin_op();
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	792080e7          	jalr	1938(ra) # 800045f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e6a:	08000613          	li	a2,128
    80005e6e:	f6040593          	addi	a1,s0,-160
    80005e72:	4501                	li	a0,0
    80005e74:	ffffd097          	auipc	ra,0xffffd
    80005e78:	1e2080e7          	jalr	482(ra) # 80003056 <argstr>
    80005e7c:	04054b63          	bltz	a0,80005ed2 <sys_chdir+0x86>
    80005e80:	f6040513          	addi	a0,s0,-160
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	554080e7          	jalr	1364(ra) # 800043d8 <namei>
    80005e8c:	84aa                	mv	s1,a0
    80005e8e:	c131                	beqz	a0,80005ed2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	da2080e7          	jalr	-606(ra) # 80003c32 <ilock>
  if(ip->type != T_DIR){
    80005e98:	04449703          	lh	a4,68(s1)
    80005e9c:	4785                	li	a5,1
    80005e9e:	04f71063          	bne	a4,a5,80005ede <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ea2:	8526                	mv	a0,s1
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	e50080e7          	jalr	-432(ra) # 80003cf4 <iunlock>
  iput(p->cwd);
    80005eac:	15093503          	ld	a0,336(s2)
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	f3c080e7          	jalr	-196(ra) # 80003dec <iput>
  end_op();
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	7bc080e7          	jalr	1980(ra) # 80004674 <end_op>
  p->cwd = ip;
    80005ec0:	14993823          	sd	s1,336(s2)
  return 0;
    80005ec4:	4501                	li	a0,0
}
    80005ec6:	60ea                	ld	ra,152(sp)
    80005ec8:	644a                	ld	s0,144(sp)
    80005eca:	64aa                	ld	s1,136(sp)
    80005ecc:	690a                	ld	s2,128(sp)
    80005ece:	610d                	addi	sp,sp,160
    80005ed0:	8082                	ret
    end_op();
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	7a2080e7          	jalr	1954(ra) # 80004674 <end_op>
    return -1;
    80005eda:	557d                	li	a0,-1
    80005edc:	b7ed                	j	80005ec6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ede:	8526                	mv	a0,s1
    80005ee0:	ffffe097          	auipc	ra,0xffffe
    80005ee4:	fb4080e7          	jalr	-76(ra) # 80003e94 <iunlockput>
    end_op();
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	78c080e7          	jalr	1932(ra) # 80004674 <end_op>
    return -1;
    80005ef0:	557d                	li	a0,-1
    80005ef2:	bfd1                	j	80005ec6 <sys_chdir+0x7a>

0000000080005ef4 <sys_exec>:

uint64
sys_exec(void)
{
    80005ef4:	7145                	addi	sp,sp,-464
    80005ef6:	e786                	sd	ra,456(sp)
    80005ef8:	e3a2                	sd	s0,448(sp)
    80005efa:	ff26                	sd	s1,440(sp)
    80005efc:	fb4a                	sd	s2,432(sp)
    80005efe:	f74e                	sd	s3,424(sp)
    80005f00:	f352                	sd	s4,416(sp)
    80005f02:	ef56                	sd	s5,408(sp)
    80005f04:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f06:	e3840593          	addi	a1,s0,-456
    80005f0a:	4505                	li	a0,1
    80005f0c:	ffffd097          	auipc	ra,0xffffd
    80005f10:	12a080e7          	jalr	298(ra) # 80003036 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f14:	08000613          	li	a2,128
    80005f18:	f4040593          	addi	a1,s0,-192
    80005f1c:	4501                	li	a0,0
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	138080e7          	jalr	312(ra) # 80003056 <argstr>
    80005f26:	87aa                	mv	a5,a0
    return -1;
    80005f28:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f2a:	0c07c263          	bltz	a5,80005fee <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f2e:	10000613          	li	a2,256
    80005f32:	4581                	li	a1,0
    80005f34:	e4040513          	addi	a0,s0,-448
    80005f38:	ffffb097          	auipc	ra,0xffffb
    80005f3c:	e9c080e7          	jalr	-356(ra) # 80000dd4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f40:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f44:	89a6                	mv	s3,s1
    80005f46:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f48:	02000a13          	li	s4,32
    80005f4c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f50:	00391793          	slli	a5,s2,0x3
    80005f54:	e3040593          	addi	a1,s0,-464
    80005f58:	e3843503          	ld	a0,-456(s0)
    80005f5c:	953e                	add	a0,a0,a5
    80005f5e:	ffffd097          	auipc	ra,0xffffd
    80005f62:	01a080e7          	jalr	26(ra) # 80002f78 <fetchaddr>
    80005f66:	02054a63          	bltz	a0,80005f9a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f6a:	e3043783          	ld	a5,-464(s0)
    80005f6e:	c3b9                	beqz	a5,80005fb4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	c3c080e7          	jalr	-964(ra) # 80000bac <kalloc>
    80005f78:	85aa                	mv	a1,a0
    80005f7a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f7e:	cd11                	beqz	a0,80005f9a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f80:	6605                	lui	a2,0x1
    80005f82:	e3043503          	ld	a0,-464(s0)
    80005f86:	ffffd097          	auipc	ra,0xffffd
    80005f8a:	044080e7          	jalr	68(ra) # 80002fca <fetchstr>
    80005f8e:	00054663          	bltz	a0,80005f9a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f92:	0905                	addi	s2,s2,1
    80005f94:	09a1                	addi	s3,s3,8
    80005f96:	fb491be3          	bne	s2,s4,80005f4c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f9a:	10048913          	addi	s2,s1,256
    80005f9e:	6088                	ld	a0,0(s1)
    80005fa0:	c531                	beqz	a0,80005fec <sys_exec+0xf8>
    kfree(argv[i]);
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	a48080e7          	jalr	-1464(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005faa:	04a1                	addi	s1,s1,8
    80005fac:	ff2499e3          	bne	s1,s2,80005f9e <sys_exec+0xaa>
  return -1;
    80005fb0:	557d                	li	a0,-1
    80005fb2:	a835                	j	80005fee <sys_exec+0xfa>
      argv[i] = 0;
    80005fb4:	0a8e                	slli	s5,s5,0x3
    80005fb6:	fc040793          	addi	a5,s0,-64
    80005fba:	9abe                	add	s5,s5,a5
    80005fbc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fc0:	e4040593          	addi	a1,s0,-448
    80005fc4:	f4040513          	addi	a0,s0,-192
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	172080e7          	jalr	370(ra) # 8000513a <exec>
    80005fd0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd2:	10048993          	addi	s3,s1,256
    80005fd6:	6088                	ld	a0,0(s1)
    80005fd8:	c901                	beqz	a0,80005fe8 <sys_exec+0xf4>
    kfree(argv[i]);
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	a10080e7          	jalr	-1520(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe2:	04a1                	addi	s1,s1,8
    80005fe4:	ff3499e3          	bne	s1,s3,80005fd6 <sys_exec+0xe2>
  return ret;
    80005fe8:	854a                	mv	a0,s2
    80005fea:	a011                	j	80005fee <sys_exec+0xfa>
  return -1;
    80005fec:	557d                	li	a0,-1
}
    80005fee:	60be                	ld	ra,456(sp)
    80005ff0:	641e                	ld	s0,448(sp)
    80005ff2:	74fa                	ld	s1,440(sp)
    80005ff4:	795a                	ld	s2,432(sp)
    80005ff6:	79ba                	ld	s3,424(sp)
    80005ff8:	7a1a                	ld	s4,416(sp)
    80005ffa:	6afa                	ld	s5,408(sp)
    80005ffc:	6179                	addi	sp,sp,464
    80005ffe:	8082                	ret

0000000080006000 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006000:	7139                	addi	sp,sp,-64
    80006002:	fc06                	sd	ra,56(sp)
    80006004:	f822                	sd	s0,48(sp)
    80006006:	f426                	sd	s1,40(sp)
    80006008:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000600a:	ffffc097          	auipc	ra,0xffffc
    8000600e:	c32080e7          	jalr	-974(ra) # 80001c3c <myproc>
    80006012:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006014:	fd840593          	addi	a1,s0,-40
    80006018:	4501                	li	a0,0
    8000601a:	ffffd097          	auipc	ra,0xffffd
    8000601e:	01c080e7          	jalr	28(ra) # 80003036 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006022:	fc840593          	addi	a1,s0,-56
    80006026:	fd040513          	addi	a0,s0,-48
    8000602a:	fffff097          	auipc	ra,0xfffff
    8000602e:	dc6080e7          	jalr	-570(ra) # 80004df0 <pipealloc>
    return -1;
    80006032:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006034:	0c054463          	bltz	a0,800060fc <sys_pipe+0xfc>
  fd0 = -1;
    80006038:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000603c:	fd043503          	ld	a0,-48(s0)
    80006040:	fffff097          	auipc	ra,0xfffff
    80006044:	51a080e7          	jalr	1306(ra) # 8000555a <fdalloc>
    80006048:	fca42223          	sw	a0,-60(s0)
    8000604c:	08054b63          	bltz	a0,800060e2 <sys_pipe+0xe2>
    80006050:	fc843503          	ld	a0,-56(s0)
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	506080e7          	jalr	1286(ra) # 8000555a <fdalloc>
    8000605c:	fca42023          	sw	a0,-64(s0)
    80006060:	06054863          	bltz	a0,800060d0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006064:	4691                	li	a3,4
    80006066:	fc440613          	addi	a2,s0,-60
    8000606a:	fd843583          	ld	a1,-40(s0)
    8000606e:	68a8                	ld	a0,80(s1)
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	7e8080e7          	jalr	2024(ra) # 80001858 <copyout>
    80006078:	02054063          	bltz	a0,80006098 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000607c:	4691                	li	a3,4
    8000607e:	fc040613          	addi	a2,s0,-64
    80006082:	fd843583          	ld	a1,-40(s0)
    80006086:	0591                	addi	a1,a1,4
    80006088:	68a8                	ld	a0,80(s1)
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	7ce080e7          	jalr	1998(ra) # 80001858 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006092:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006094:	06055463          	bgez	a0,800060fc <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006098:	fc442783          	lw	a5,-60(s0)
    8000609c:	07e9                	addi	a5,a5,26
    8000609e:	078e                	slli	a5,a5,0x3
    800060a0:	97a6                	add	a5,a5,s1
    800060a2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060a6:	fc042503          	lw	a0,-64(s0)
    800060aa:	0569                	addi	a0,a0,26
    800060ac:	050e                	slli	a0,a0,0x3
    800060ae:	94aa                	add	s1,s1,a0
    800060b0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060b4:	fd043503          	ld	a0,-48(s0)
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	a08080e7          	jalr	-1528(ra) # 80004ac0 <fileclose>
    fileclose(wf);
    800060c0:	fc843503          	ld	a0,-56(s0)
    800060c4:	fffff097          	auipc	ra,0xfffff
    800060c8:	9fc080e7          	jalr	-1540(ra) # 80004ac0 <fileclose>
    return -1;
    800060cc:	57fd                	li	a5,-1
    800060ce:	a03d                	j	800060fc <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060d0:	fc442783          	lw	a5,-60(s0)
    800060d4:	0007c763          	bltz	a5,800060e2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060d8:	07e9                	addi	a5,a5,26
    800060da:	078e                	slli	a5,a5,0x3
    800060dc:	94be                	add	s1,s1,a5
    800060de:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060e2:	fd043503          	ld	a0,-48(s0)
    800060e6:	fffff097          	auipc	ra,0xfffff
    800060ea:	9da080e7          	jalr	-1574(ra) # 80004ac0 <fileclose>
    fileclose(wf);
    800060ee:	fc843503          	ld	a0,-56(s0)
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	9ce080e7          	jalr	-1586(ra) # 80004ac0 <fileclose>
    return -1;
    800060fa:	57fd                	li	a5,-1
}
    800060fc:	853e                	mv	a0,a5
    800060fe:	70e2                	ld	ra,56(sp)
    80006100:	7442                	ld	s0,48(sp)
    80006102:	74a2                	ld	s1,40(sp)
    80006104:	6121                	addi	sp,sp,64
    80006106:	8082                	ret
	...

0000000080006110 <kernelvec>:
    80006110:	7111                	addi	sp,sp,-256
    80006112:	e006                	sd	ra,0(sp)
    80006114:	e40a                	sd	sp,8(sp)
    80006116:	e80e                	sd	gp,16(sp)
    80006118:	ec12                	sd	tp,24(sp)
    8000611a:	f016                	sd	t0,32(sp)
    8000611c:	f41a                	sd	t1,40(sp)
    8000611e:	f81e                	sd	t2,48(sp)
    80006120:	fc22                	sd	s0,56(sp)
    80006122:	e0a6                	sd	s1,64(sp)
    80006124:	e4aa                	sd	a0,72(sp)
    80006126:	e8ae                	sd	a1,80(sp)
    80006128:	ecb2                	sd	a2,88(sp)
    8000612a:	f0b6                	sd	a3,96(sp)
    8000612c:	f4ba                	sd	a4,104(sp)
    8000612e:	f8be                	sd	a5,112(sp)
    80006130:	fcc2                	sd	a6,120(sp)
    80006132:	e146                	sd	a7,128(sp)
    80006134:	e54a                	sd	s2,136(sp)
    80006136:	e94e                	sd	s3,144(sp)
    80006138:	ed52                	sd	s4,152(sp)
    8000613a:	f156                	sd	s5,160(sp)
    8000613c:	f55a                	sd	s6,168(sp)
    8000613e:	f95e                	sd	s7,176(sp)
    80006140:	fd62                	sd	s8,184(sp)
    80006142:	e1e6                	sd	s9,192(sp)
    80006144:	e5ea                	sd	s10,200(sp)
    80006146:	e9ee                	sd	s11,208(sp)
    80006148:	edf2                	sd	t3,216(sp)
    8000614a:	f1f6                	sd	t4,224(sp)
    8000614c:	f5fa                	sd	t5,232(sp)
    8000614e:	f9fe                	sd	t6,240(sp)
    80006150:	cf5fc0ef          	jal	ra,80002e44 <kerneltrap>
    80006154:	6082                	ld	ra,0(sp)
    80006156:	6122                	ld	sp,8(sp)
    80006158:	61c2                	ld	gp,16(sp)
    8000615a:	7282                	ld	t0,32(sp)
    8000615c:	7322                	ld	t1,40(sp)
    8000615e:	73c2                	ld	t2,48(sp)
    80006160:	7462                	ld	s0,56(sp)
    80006162:	6486                	ld	s1,64(sp)
    80006164:	6526                	ld	a0,72(sp)
    80006166:	65c6                	ld	a1,80(sp)
    80006168:	6666                	ld	a2,88(sp)
    8000616a:	7686                	ld	a3,96(sp)
    8000616c:	7726                	ld	a4,104(sp)
    8000616e:	77c6                	ld	a5,112(sp)
    80006170:	7866                	ld	a6,120(sp)
    80006172:	688a                	ld	a7,128(sp)
    80006174:	692a                	ld	s2,136(sp)
    80006176:	69ca                	ld	s3,144(sp)
    80006178:	6a6a                	ld	s4,152(sp)
    8000617a:	7a8a                	ld	s5,160(sp)
    8000617c:	7b2a                	ld	s6,168(sp)
    8000617e:	7bca                	ld	s7,176(sp)
    80006180:	7c6a                	ld	s8,184(sp)
    80006182:	6c8e                	ld	s9,192(sp)
    80006184:	6d2e                	ld	s10,200(sp)
    80006186:	6dce                	ld	s11,208(sp)
    80006188:	6e6e                	ld	t3,216(sp)
    8000618a:	7e8e                	ld	t4,224(sp)
    8000618c:	7f2e                	ld	t5,232(sp)
    8000618e:	7fce                	ld	t6,240(sp)
    80006190:	6111                	addi	sp,sp,256
    80006192:	10200073          	sret
    80006196:	00000013          	nop
    8000619a:	00000013          	nop
    8000619e:	0001                	nop

00000000800061a0 <timervec>:
    800061a0:	34051573          	csrrw	a0,mscratch,a0
    800061a4:	e10c                	sd	a1,0(a0)
    800061a6:	e510                	sd	a2,8(a0)
    800061a8:	e914                	sd	a3,16(a0)
    800061aa:	6d0c                	ld	a1,24(a0)
    800061ac:	7110                	ld	a2,32(a0)
    800061ae:	6194                	ld	a3,0(a1)
    800061b0:	96b2                	add	a3,a3,a2
    800061b2:	e194                	sd	a3,0(a1)
    800061b4:	4589                	li	a1,2
    800061b6:	14459073          	csrw	sip,a1
    800061ba:	6914                	ld	a3,16(a0)
    800061bc:	6510                	ld	a2,8(a0)
    800061be:	610c                	ld	a1,0(a0)
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	30200073          	mret
	...

00000000800061ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ca:	1141                	addi	sp,sp,-16
    800061cc:	e422                	sd	s0,8(sp)
    800061ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061d0:	0c0007b7          	lui	a5,0xc000
    800061d4:	4705                	li	a4,1
    800061d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061d8:	c3d8                	sw	a4,4(a5)
}
    800061da:	6422                	ld	s0,8(sp)
    800061dc:	0141                	addi	sp,sp,16
    800061de:	8082                	ret

00000000800061e0 <plicinithart>:

void
plicinithart(void)
{
    800061e0:	1141                	addi	sp,sp,-16
    800061e2:	e406                	sd	ra,8(sp)
    800061e4:	e022                	sd	s0,0(sp)
    800061e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	a28080e7          	jalr	-1496(ra) # 80001c10 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061f0:	0085171b          	slliw	a4,a0,0x8
    800061f4:	0c0027b7          	lui	a5,0xc002
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	40200713          	li	a4,1026
    800061fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006202:	00d5151b          	slliw	a0,a0,0xd
    80006206:	0c2017b7          	lui	a5,0xc201
    8000620a:	953e                	add	a0,a0,a5
    8000620c:	00052023          	sw	zero,0(a0)
}
    80006210:	60a2                	ld	ra,8(sp)
    80006212:	6402                	ld	s0,0(sp)
    80006214:	0141                	addi	sp,sp,16
    80006216:	8082                	ret

0000000080006218 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006218:	1141                	addi	sp,sp,-16
    8000621a:	e406                	sd	ra,8(sp)
    8000621c:	e022                	sd	s0,0(sp)
    8000621e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006220:	ffffc097          	auipc	ra,0xffffc
    80006224:	9f0080e7          	jalr	-1552(ra) # 80001c10 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006228:	00d5179b          	slliw	a5,a0,0xd
    8000622c:	0c201537          	lui	a0,0xc201
    80006230:	953e                	add	a0,a0,a5
  return irq;
}
    80006232:	4148                	lw	a0,4(a0)
    80006234:	60a2                	ld	ra,8(sp)
    80006236:	6402                	ld	s0,0(sp)
    80006238:	0141                	addi	sp,sp,16
    8000623a:	8082                	ret

000000008000623c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000623c:	1101                	addi	sp,sp,-32
    8000623e:	ec06                	sd	ra,24(sp)
    80006240:	e822                	sd	s0,16(sp)
    80006242:	e426                	sd	s1,8(sp)
    80006244:	1000                	addi	s0,sp,32
    80006246:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006248:	ffffc097          	auipc	ra,0xffffc
    8000624c:	9c8080e7          	jalr	-1592(ra) # 80001c10 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006250:	00d5151b          	slliw	a0,a0,0xd
    80006254:	0c2017b7          	lui	a5,0xc201
    80006258:	97aa                	add	a5,a5,a0
    8000625a:	c3c4                	sw	s1,4(a5)
}
    8000625c:	60e2                	ld	ra,24(sp)
    8000625e:	6442                	ld	s0,16(sp)
    80006260:	64a2                	ld	s1,8(sp)
    80006262:	6105                	addi	sp,sp,32
    80006264:	8082                	ret

0000000080006266 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006266:	1141                	addi	sp,sp,-16
    80006268:	e406                	sd	ra,8(sp)
    8000626a:	e022                	sd	s0,0(sp)
    8000626c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000626e:	479d                	li	a5,7
    80006270:	04a7cc63          	blt	a5,a0,800062c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006274:	0023c797          	auipc	a5,0x23c
    80006278:	dc478793          	addi	a5,a5,-572 # 80242038 <disk>
    8000627c:	97aa                	add	a5,a5,a0
    8000627e:	0187c783          	lbu	a5,24(a5)
    80006282:	ebb9                	bnez	a5,800062d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006284:	00451613          	slli	a2,a0,0x4
    80006288:	0023c797          	auipc	a5,0x23c
    8000628c:	db078793          	addi	a5,a5,-592 # 80242038 <disk>
    80006290:	6394                	ld	a3,0(a5)
    80006292:	96b2                	add	a3,a3,a2
    80006294:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006298:	6398                	ld	a4,0(a5)
    8000629a:	9732                	add	a4,a4,a2
    8000629c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062a8:	953e                	add	a0,a0,a5
    800062aa:	4785                	li	a5,1
    800062ac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800062b0:	0023c517          	auipc	a0,0x23c
    800062b4:	da050513          	addi	a0,a0,-608 # 80242050 <disk+0x18>
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	0a4080e7          	jalr	164(ra) # 8000235c <wakeup>
}
    800062c0:	60a2                	ld	ra,8(sp)
    800062c2:	6402                	ld	s0,0(sp)
    800062c4:	0141                	addi	sp,sp,16
    800062c6:	8082                	ret
    panic("free_desc 1");
    800062c8:	00002517          	auipc	a0,0x2
    800062cc:	49850513          	addi	a0,a0,1176 # 80008760 <syscalls+0x300>
    800062d0:	ffffa097          	auipc	ra,0xffffa
    800062d4:	26e080e7          	jalr	622(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062d8:	00002517          	auipc	a0,0x2
    800062dc:	49850513          	addi	a0,a0,1176 # 80008770 <syscalls+0x310>
    800062e0:	ffffa097          	auipc	ra,0xffffa
    800062e4:	25e080e7          	jalr	606(ra) # 8000053e <panic>

00000000800062e8 <virtio_disk_init>:
{
    800062e8:	1101                	addi	sp,sp,-32
    800062ea:	ec06                	sd	ra,24(sp)
    800062ec:	e822                	sd	s0,16(sp)
    800062ee:	e426                	sd	s1,8(sp)
    800062f0:	e04a                	sd	s2,0(sp)
    800062f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062f4:	00002597          	auipc	a1,0x2
    800062f8:	48c58593          	addi	a1,a1,1164 # 80008780 <syscalls+0x320>
    800062fc:	0023c517          	auipc	a0,0x23c
    80006300:	e6450513          	addi	a0,a0,-412 # 80242160 <disk+0x128>
    80006304:	ffffb097          	auipc	ra,0xffffb
    80006308:	944080e7          	jalr	-1724(ra) # 80000c48 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000630c:	100017b7          	lui	a5,0x10001
    80006310:	4398                	lw	a4,0(a5)
    80006312:	2701                	sext.w	a4,a4
    80006314:	747277b7          	lui	a5,0x74727
    80006318:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000631c:	14f71c63          	bne	a4,a5,80006474 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006320:	100017b7          	lui	a5,0x10001
    80006324:	43dc                	lw	a5,4(a5)
    80006326:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006328:	4709                	li	a4,2
    8000632a:	14e79563          	bne	a5,a4,80006474 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000632e:	100017b7          	lui	a5,0x10001
    80006332:	479c                	lw	a5,8(a5)
    80006334:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006336:	12e79f63          	bne	a5,a4,80006474 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000633a:	100017b7          	lui	a5,0x10001
    8000633e:	47d8                	lw	a4,12(a5)
    80006340:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006342:	554d47b7          	lui	a5,0x554d4
    80006346:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000634a:	12f71563          	bne	a4,a5,80006474 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000634e:	100017b7          	lui	a5,0x10001
    80006352:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006356:	4705                	li	a4,1
    80006358:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000635a:	470d                	li	a4,3
    8000635c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000635e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006360:	c7ffe737          	lui	a4,0xc7ffe
    80006364:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc5e7>
    80006368:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000636a:	2701                	sext.w	a4,a4
    8000636c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000636e:	472d                	li	a4,11
    80006370:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006372:	5bbc                	lw	a5,112(a5)
    80006374:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006378:	8ba1                	andi	a5,a5,8
    8000637a:	10078563          	beqz	a5,80006484 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000637e:	100017b7          	lui	a5,0x10001
    80006382:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006386:	43fc                	lw	a5,68(a5)
    80006388:	2781                	sext.w	a5,a5
    8000638a:	10079563          	bnez	a5,80006494 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000638e:	100017b7          	lui	a5,0x10001
    80006392:	5bdc                	lw	a5,52(a5)
    80006394:	2781                	sext.w	a5,a5
  if(max == 0)
    80006396:	10078763          	beqz	a5,800064a4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000639a:	471d                	li	a4,7
    8000639c:	10f77c63          	bgeu	a4,a5,800064b4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	80c080e7          	jalr	-2036(ra) # 80000bac <kalloc>
    800063a8:	0023c497          	auipc	s1,0x23c
    800063ac:	c9048493          	addi	s1,s1,-880 # 80242038 <disk>
    800063b0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063b2:	ffffa097          	auipc	ra,0xffffa
    800063b6:	7fa080e7          	jalr	2042(ra) # 80000bac <kalloc>
    800063ba:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063bc:	ffffa097          	auipc	ra,0xffffa
    800063c0:	7f0080e7          	jalr	2032(ra) # 80000bac <kalloc>
    800063c4:	87aa                	mv	a5,a0
    800063c6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063c8:	6088                	ld	a0,0(s1)
    800063ca:	cd6d                	beqz	a0,800064c4 <virtio_disk_init+0x1dc>
    800063cc:	0023c717          	auipc	a4,0x23c
    800063d0:	c7473703          	ld	a4,-908(a4) # 80242040 <disk+0x8>
    800063d4:	cb65                	beqz	a4,800064c4 <virtio_disk_init+0x1dc>
    800063d6:	c7fd                	beqz	a5,800064c4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800063d8:	6605                	lui	a2,0x1
    800063da:	4581                	li	a1,0
    800063dc:	ffffb097          	auipc	ra,0xffffb
    800063e0:	9f8080e7          	jalr	-1544(ra) # 80000dd4 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063e4:	0023c497          	auipc	s1,0x23c
    800063e8:	c5448493          	addi	s1,s1,-940 # 80242038 <disk>
    800063ec:	6605                	lui	a2,0x1
    800063ee:	4581                	li	a1,0
    800063f0:	6488                	ld	a0,8(s1)
    800063f2:	ffffb097          	auipc	ra,0xffffb
    800063f6:	9e2080e7          	jalr	-1566(ra) # 80000dd4 <memset>
  memset(disk.used, 0, PGSIZE);
    800063fa:	6605                	lui	a2,0x1
    800063fc:	4581                	li	a1,0
    800063fe:	6888                	ld	a0,16(s1)
    80006400:	ffffb097          	auipc	ra,0xffffb
    80006404:	9d4080e7          	jalr	-1580(ra) # 80000dd4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006408:	100017b7          	lui	a5,0x10001
    8000640c:	4721                	li	a4,8
    8000640e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006410:	4098                	lw	a4,0(s1)
    80006412:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006416:	40d8                	lw	a4,4(s1)
    80006418:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000641c:	6498                	ld	a4,8(s1)
    8000641e:	0007069b          	sext.w	a3,a4
    80006422:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006426:	9701                	srai	a4,a4,0x20
    80006428:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000642c:	6898                	ld	a4,16(s1)
    8000642e:	0007069b          	sext.w	a3,a4
    80006432:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006436:	9701                	srai	a4,a4,0x20
    80006438:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000643c:	4705                	li	a4,1
    8000643e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006440:	00e48c23          	sb	a4,24(s1)
    80006444:	00e48ca3          	sb	a4,25(s1)
    80006448:	00e48d23          	sb	a4,26(s1)
    8000644c:	00e48da3          	sb	a4,27(s1)
    80006450:	00e48e23          	sb	a4,28(s1)
    80006454:	00e48ea3          	sb	a4,29(s1)
    80006458:	00e48f23          	sb	a4,30(s1)
    8000645c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006460:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006464:	0727a823          	sw	s2,112(a5)
}
    80006468:	60e2                	ld	ra,24(sp)
    8000646a:	6442                	ld	s0,16(sp)
    8000646c:	64a2                	ld	s1,8(sp)
    8000646e:	6902                	ld	s2,0(sp)
    80006470:	6105                	addi	sp,sp,32
    80006472:	8082                	ret
    panic("could not find virtio disk");
    80006474:	00002517          	auipc	a0,0x2
    80006478:	31c50513          	addi	a0,a0,796 # 80008790 <syscalls+0x330>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	0c2080e7          	jalr	194(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006484:	00002517          	auipc	a0,0x2
    80006488:	32c50513          	addi	a0,a0,812 # 800087b0 <syscalls+0x350>
    8000648c:	ffffa097          	auipc	ra,0xffffa
    80006490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006494:	00002517          	auipc	a0,0x2
    80006498:	33c50513          	addi	a0,a0,828 # 800087d0 <syscalls+0x370>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064a4:	00002517          	auipc	a0,0x2
    800064a8:	34c50513          	addi	a0,a0,844 # 800087f0 <syscalls+0x390>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064b4:	00002517          	auipc	a0,0x2
    800064b8:	35c50513          	addi	a0,a0,860 # 80008810 <syscalls+0x3b0>
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	082080e7          	jalr	130(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800064c4:	00002517          	auipc	a0,0x2
    800064c8:	36c50513          	addi	a0,a0,876 # 80008830 <syscalls+0x3d0>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	072080e7          	jalr	114(ra) # 8000053e <panic>

00000000800064d4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064d4:	7119                	addi	sp,sp,-128
    800064d6:	fc86                	sd	ra,120(sp)
    800064d8:	f8a2                	sd	s0,112(sp)
    800064da:	f4a6                	sd	s1,104(sp)
    800064dc:	f0ca                	sd	s2,96(sp)
    800064de:	ecce                	sd	s3,88(sp)
    800064e0:	e8d2                	sd	s4,80(sp)
    800064e2:	e4d6                	sd	s5,72(sp)
    800064e4:	e0da                	sd	s6,64(sp)
    800064e6:	fc5e                	sd	s7,56(sp)
    800064e8:	f862                	sd	s8,48(sp)
    800064ea:	f466                	sd	s9,40(sp)
    800064ec:	f06a                	sd	s10,32(sp)
    800064ee:	ec6e                	sd	s11,24(sp)
    800064f0:	0100                	addi	s0,sp,128
    800064f2:	8aaa                	mv	s5,a0
    800064f4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064f6:	00c52d03          	lw	s10,12(a0)
    800064fa:	001d1d1b          	slliw	s10,s10,0x1
    800064fe:	1d02                	slli	s10,s10,0x20
    80006500:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006504:	0023c517          	auipc	a0,0x23c
    80006508:	c5c50513          	addi	a0,a0,-932 # 80242160 <disk+0x128>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	7cc080e7          	jalr	1996(ra) # 80000cd8 <acquire>
  for(int i = 0; i < 3; i++){
    80006514:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006516:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006518:	0023cb97          	auipc	s7,0x23c
    8000651c:	b20b8b93          	addi	s7,s7,-1248 # 80242038 <disk>
  for(int i = 0; i < 3; i++){
    80006520:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006522:	0023cc97          	auipc	s9,0x23c
    80006526:	c3ec8c93          	addi	s9,s9,-962 # 80242160 <disk+0x128>
    8000652a:	a08d                	j	8000658c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000652c:	00fb8733          	add	a4,s7,a5
    80006530:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006534:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006536:	0207c563          	bltz	a5,80006560 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000653a:	2905                	addiw	s2,s2,1
    8000653c:	0611                	addi	a2,a2,4
    8000653e:	05690c63          	beq	s2,s6,80006596 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006542:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006544:	0023c717          	auipc	a4,0x23c
    80006548:	af470713          	addi	a4,a4,-1292 # 80242038 <disk>
    8000654c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000654e:	01874683          	lbu	a3,24(a4)
    80006552:	fee9                	bnez	a3,8000652c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006554:	2785                	addiw	a5,a5,1
    80006556:	0705                	addi	a4,a4,1
    80006558:	fe979be3          	bne	a5,s1,8000654e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000655c:	57fd                	li	a5,-1
    8000655e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006560:	01205d63          	blez	s2,8000657a <virtio_disk_rw+0xa6>
    80006564:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006566:	000a2503          	lw	a0,0(s4)
    8000656a:	00000097          	auipc	ra,0x0
    8000656e:	cfc080e7          	jalr	-772(ra) # 80006266 <free_desc>
      for(int j = 0; j < i; j++)
    80006572:	2d85                	addiw	s11,s11,1
    80006574:	0a11                	addi	s4,s4,4
    80006576:	ffb918e3          	bne	s2,s11,80006566 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000657a:	85e6                	mv	a1,s9
    8000657c:	0023c517          	auipc	a0,0x23c
    80006580:	ad450513          	addi	a0,a0,-1324 # 80242050 <disk+0x18>
    80006584:	ffffc097          	auipc	ra,0xffffc
    80006588:	d74080e7          	jalr	-652(ra) # 800022f8 <sleep>
  for(int i = 0; i < 3; i++){
    8000658c:	f8040a13          	addi	s4,s0,-128
{
    80006590:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006592:	894e                	mv	s2,s3
    80006594:	b77d                	j	80006542 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006596:	f8042583          	lw	a1,-128(s0)
    8000659a:	00a58793          	addi	a5,a1,10
    8000659e:	0792                	slli	a5,a5,0x4

  if(write)
    800065a0:	0023c617          	auipc	a2,0x23c
    800065a4:	a9860613          	addi	a2,a2,-1384 # 80242038 <disk>
    800065a8:	00f60733          	add	a4,a2,a5
    800065ac:	018036b3          	snez	a3,s8
    800065b0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065b2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800065b6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065ba:	f6078693          	addi	a3,a5,-160
    800065be:	6218                	ld	a4,0(a2)
    800065c0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065c2:	00878513          	addi	a0,a5,8
    800065c6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065c8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065ca:	6208                	ld	a0,0(a2)
    800065cc:	96aa                	add	a3,a3,a0
    800065ce:	4741                	li	a4,16
    800065d0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065d2:	4705                	li	a4,1
    800065d4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800065d8:	f8442703          	lw	a4,-124(s0)
    800065dc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065e0:	0712                	slli	a4,a4,0x4
    800065e2:	953a                	add	a0,a0,a4
    800065e4:	058a8693          	addi	a3,s5,88
    800065e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800065ea:	6208                	ld	a0,0(a2)
    800065ec:	972a                	add	a4,a4,a0
    800065ee:	40000693          	li	a3,1024
    800065f2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065f4:	001c3c13          	seqz	s8,s8
    800065f8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065fa:	001c6c13          	ori	s8,s8,1
    800065fe:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006602:	f8842603          	lw	a2,-120(s0)
    80006606:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000660a:	0023c697          	auipc	a3,0x23c
    8000660e:	a2e68693          	addi	a3,a3,-1490 # 80242038 <disk>
    80006612:	00258713          	addi	a4,a1,2
    80006616:	0712                	slli	a4,a4,0x4
    80006618:	9736                	add	a4,a4,a3
    8000661a:	587d                	li	a6,-1
    8000661c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006620:	0612                	slli	a2,a2,0x4
    80006622:	9532                	add	a0,a0,a2
    80006624:	f9078793          	addi	a5,a5,-112
    80006628:	97b6                	add	a5,a5,a3
    8000662a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000662c:	629c                	ld	a5,0(a3)
    8000662e:	97b2                	add	a5,a5,a2
    80006630:	4605                	li	a2,1
    80006632:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006634:	4509                	li	a0,2
    80006636:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000663a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000663e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006642:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006646:	6698                	ld	a4,8(a3)
    80006648:	00275783          	lhu	a5,2(a4)
    8000664c:	8b9d                	andi	a5,a5,7
    8000664e:	0786                	slli	a5,a5,0x1
    80006650:	97ba                	add	a5,a5,a4
    80006652:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006656:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000665a:	6698                	ld	a4,8(a3)
    8000665c:	00275783          	lhu	a5,2(a4)
    80006660:	2785                	addiw	a5,a5,1
    80006662:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006666:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000666a:	100017b7          	lui	a5,0x10001
    8000666e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006672:	004aa783          	lw	a5,4(s5)
    80006676:	02c79163          	bne	a5,a2,80006698 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000667a:	0023c917          	auipc	s2,0x23c
    8000667e:	ae690913          	addi	s2,s2,-1306 # 80242160 <disk+0x128>
  while(b->disk == 1) {
    80006682:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006684:	85ca                	mv	a1,s2
    80006686:	8556                	mv	a0,s5
    80006688:	ffffc097          	auipc	ra,0xffffc
    8000668c:	c70080e7          	jalr	-912(ra) # 800022f8 <sleep>
  while(b->disk == 1) {
    80006690:	004aa783          	lw	a5,4(s5)
    80006694:	fe9788e3          	beq	a5,s1,80006684 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006698:	f8042903          	lw	s2,-128(s0)
    8000669c:	00290793          	addi	a5,s2,2
    800066a0:	00479713          	slli	a4,a5,0x4
    800066a4:	0023c797          	auipc	a5,0x23c
    800066a8:	99478793          	addi	a5,a5,-1644 # 80242038 <disk>
    800066ac:	97ba                	add	a5,a5,a4
    800066ae:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066b2:	0023c997          	auipc	s3,0x23c
    800066b6:	98698993          	addi	s3,s3,-1658 # 80242038 <disk>
    800066ba:	00491713          	slli	a4,s2,0x4
    800066be:	0009b783          	ld	a5,0(s3)
    800066c2:	97ba                	add	a5,a5,a4
    800066c4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066c8:	854a                	mv	a0,s2
    800066ca:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066ce:	00000097          	auipc	ra,0x0
    800066d2:	b98080e7          	jalr	-1128(ra) # 80006266 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066d6:	8885                	andi	s1,s1,1
    800066d8:	f0ed                	bnez	s1,800066ba <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066da:	0023c517          	auipc	a0,0x23c
    800066de:	a8650513          	addi	a0,a0,-1402 # 80242160 <disk+0x128>
    800066e2:	ffffa097          	auipc	ra,0xffffa
    800066e6:	6aa080e7          	jalr	1706(ra) # 80000d8c <release>
}
    800066ea:	70e6                	ld	ra,120(sp)
    800066ec:	7446                	ld	s0,112(sp)
    800066ee:	74a6                	ld	s1,104(sp)
    800066f0:	7906                	ld	s2,96(sp)
    800066f2:	69e6                	ld	s3,88(sp)
    800066f4:	6a46                	ld	s4,80(sp)
    800066f6:	6aa6                	ld	s5,72(sp)
    800066f8:	6b06                	ld	s6,64(sp)
    800066fa:	7be2                	ld	s7,56(sp)
    800066fc:	7c42                	ld	s8,48(sp)
    800066fe:	7ca2                	ld	s9,40(sp)
    80006700:	7d02                	ld	s10,32(sp)
    80006702:	6de2                	ld	s11,24(sp)
    80006704:	6109                	addi	sp,sp,128
    80006706:	8082                	ret

0000000080006708 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006708:	1101                	addi	sp,sp,-32
    8000670a:	ec06                	sd	ra,24(sp)
    8000670c:	e822                	sd	s0,16(sp)
    8000670e:	e426                	sd	s1,8(sp)
    80006710:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006712:	0023c497          	auipc	s1,0x23c
    80006716:	92648493          	addi	s1,s1,-1754 # 80242038 <disk>
    8000671a:	0023c517          	auipc	a0,0x23c
    8000671e:	a4650513          	addi	a0,a0,-1466 # 80242160 <disk+0x128>
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	5b6080e7          	jalr	1462(ra) # 80000cd8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000672a:	10001737          	lui	a4,0x10001
    8000672e:	533c                	lw	a5,96(a4)
    80006730:	8b8d                	andi	a5,a5,3
    80006732:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006734:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006738:	689c                	ld	a5,16(s1)
    8000673a:	0204d703          	lhu	a4,32(s1)
    8000673e:	0027d783          	lhu	a5,2(a5)
    80006742:	04f70863          	beq	a4,a5,80006792 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006746:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000674a:	6898                	ld	a4,16(s1)
    8000674c:	0204d783          	lhu	a5,32(s1)
    80006750:	8b9d                	andi	a5,a5,7
    80006752:	078e                	slli	a5,a5,0x3
    80006754:	97ba                	add	a5,a5,a4
    80006756:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006758:	00278713          	addi	a4,a5,2
    8000675c:	0712                	slli	a4,a4,0x4
    8000675e:	9726                	add	a4,a4,s1
    80006760:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006764:	e721                	bnez	a4,800067ac <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006766:	0789                	addi	a5,a5,2
    80006768:	0792                	slli	a5,a5,0x4
    8000676a:	97a6                	add	a5,a5,s1
    8000676c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000676e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006772:	ffffc097          	auipc	ra,0xffffc
    80006776:	bea080e7          	jalr	-1046(ra) # 8000235c <wakeup>

    disk.used_idx += 1;
    8000677a:	0204d783          	lhu	a5,32(s1)
    8000677e:	2785                	addiw	a5,a5,1
    80006780:	17c2                	slli	a5,a5,0x30
    80006782:	93c1                	srli	a5,a5,0x30
    80006784:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006788:	6898                	ld	a4,16(s1)
    8000678a:	00275703          	lhu	a4,2(a4)
    8000678e:	faf71ce3          	bne	a4,a5,80006746 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006792:	0023c517          	auipc	a0,0x23c
    80006796:	9ce50513          	addi	a0,a0,-1586 # 80242160 <disk+0x128>
    8000679a:	ffffa097          	auipc	ra,0xffffa
    8000679e:	5f2080e7          	jalr	1522(ra) # 80000d8c <release>
}
    800067a2:	60e2                	ld	ra,24(sp)
    800067a4:	6442                	ld	s0,16(sp)
    800067a6:	64a2                	ld	s1,8(sp)
    800067a8:	6105                	addi	sp,sp,32
    800067aa:	8082                	ret
      panic("virtio_disk_intr status");
    800067ac:	00002517          	auipc	a0,0x2
    800067b0:	09c50513          	addi	a0,a0,156 # 80008848 <syscalls+0x3e8>
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
