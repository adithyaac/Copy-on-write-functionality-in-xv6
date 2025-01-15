
user/_lazytest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <simpletest>:

// allocate more than half of physical memory,
// then fork. this will fail in the default
// kernel, which does not support copy-on-write.
void simpletest()
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = (phys_size / 3) * 2;

  printf("simple: ");
   e:	00001517          	auipc	a0,0x1
  12:	cd250513          	addi	a0,a0,-814 # ce0 <malloc+0xf0>
  16:	00001097          	auipc	ra,0x1
  1a:	b1c080e7          	jalr	-1252(ra) # b32 <printf>

  char *p = sbrk(sz);
  1e:	05555537          	lui	a0,0x5555
  22:	55450513          	addi	a0,a0,1364 # 5555554 <base+0x5550544>
  26:	00001097          	auipc	ra,0x1
  2a:	80c080e7          	jalr	-2036(ra) # 832 <sbrk>
  if (p == (char *)0xffffffffffffffffL)
  2e:	57fd                	li	a5,-1
  30:	08f50263          	beq	a0,a5,b4 <simpletest+0xb4>
  34:	84aa                	mv	s1,a0
  {
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  for (char *q = p; q < p + sz; q += 4096)
  36:	05556937          	lui	s2,0x5556
  3a:	992a                	add	s2,s2,a0
  3c:	6985                	lui	s3,0x1
  {
    *(int *)q = getpid();
  3e:	00000097          	auipc	ra,0x0
  42:	7ec080e7          	jalr	2028(ra) # 82a <getpid>
  46:	c088                	sw	a0,0(s1)
  for (char *q = p; q < p + sz; q += 4096)
  48:	94ce                	add	s1,s1,s3
  4a:	fe991ae3          	bne	s2,s1,3e <simpletest+0x3e>
  }

  int pid = fork();
  4e:	00000097          	auipc	ra,0x0
  52:	754080e7          	jalr	1876(ra) # 7a2 <fork>
  if (pid < 0)
  56:	08054063          	bltz	a0,d6 <simpletest+0xd6>
  {
    printf("fork() failed\n");
    exit(-1);
  }

  if (pid == 0)
  5a:	c959                	beqz	a0,f0 <simpletest+0xf0>
    exit(0);

  wait(0);
  5c:	4501                	li	a0,0
  5e:	00000097          	auipc	ra,0x0
  62:	754080e7          	jalr	1876(ra) # 7b2 <wait>

  if (sbrk(-sz) == (char *)0xffffffffffffffffL)
  66:	faaab537          	lui	a0,0xfaaab
  6a:	aac50513          	addi	a0,a0,-1364 # fffffffffaaaaaac <base+0xfffffffffaaa5a9c>
  6e:	00000097          	auipc	ra,0x0
  72:	7c4080e7          	jalr	1988(ra) # 832 <sbrk>
  76:	57fd                	li	a5,-1
  78:	08f50063          	beq	a0,a5,f8 <simpletest+0xf8>
  {
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }
  printf("ok\n");
  7c:	00001517          	auipc	a0,0x1
  80:	cb450513          	addi	a0,a0,-844 # d30 <malloc+0x140>
  84:	00001097          	auipc	ra,0x1
  88:	aae080e7          	jalr	-1362(ra) # b32 <printf>
  printf("Number of page faults recorded after simpletest= %d\n", counter());
  8c:	00000097          	auipc	ra,0x0
  90:	7c6080e7          	jalr	1990(ra) # 852 <counter>
  94:	85aa                	mv	a1,a0
  96:	00001517          	auipc	a0,0x1
  9a:	ca250513          	addi	a0,a0,-862 # d38 <malloc+0x148>
  9e:	00001097          	auipc	ra,0x1
  a2:	a94080e7          	jalr	-1388(ra) # b32 <printf>
}
  a6:	70a2                	ld	ra,40(sp)
  a8:	7402                	ld	s0,32(sp)
  aa:	64e2                	ld	s1,24(sp)
  ac:	6942                	ld	s2,16(sp)
  ae:	69a2                	ld	s3,8(sp)
  b0:	6145                	addi	sp,sp,48
  b2:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
  b4:	055555b7          	lui	a1,0x5555
  b8:	55458593          	addi	a1,a1,1364 # 5555554 <base+0x5550544>
  bc:	00001517          	auipc	a0,0x1
  c0:	c3450513          	addi	a0,a0,-972 # cf0 <malloc+0x100>
  c4:	00001097          	auipc	ra,0x1
  c8:	a6e080e7          	jalr	-1426(ra) # b32 <printf>
    exit(-1);
  cc:	557d                	li	a0,-1
  ce:	00000097          	auipc	ra,0x0
  d2:	6dc080e7          	jalr	1756(ra) # 7aa <exit>
    printf("fork() failed\n");
  d6:	00001517          	auipc	a0,0x1
  da:	c3250513          	addi	a0,a0,-974 # d08 <malloc+0x118>
  de:	00001097          	auipc	ra,0x1
  e2:	a54080e7          	jalr	-1452(ra) # b32 <printf>
    exit(-1);
  e6:	557d                	li	a0,-1
  e8:	00000097          	auipc	ra,0x0
  ec:	6c2080e7          	jalr	1730(ra) # 7aa <exit>
    exit(0);
  f0:	00000097          	auipc	ra,0x0
  f4:	6ba080e7          	jalr	1722(ra) # 7aa <exit>
    printf("sbrk(-%d) failed\n", sz);
  f8:	055555b7          	lui	a1,0x5555
  fc:	55458593          	addi	a1,a1,1364 # 5555554 <base+0x5550544>
 100:	00001517          	auipc	a0,0x1
 104:	c1850513          	addi	a0,a0,-1000 # d18 <malloc+0x128>
 108:	00001097          	auipc	ra,0x1
 10c:	a2a080e7          	jalr	-1494(ra) # b32 <printf>
    exit(-1);
 110:	557d                	li	a0,-1
 112:	00000097          	auipc	ra,0x0
 116:	698080e7          	jalr	1688(ra) # 7aa <exit>

000000000000011a <threetest>:
// three processes all write COW memory.
// this causes more than half of physical memory
// to be allocated, so it also checks whether
// copied pages are freed.
void threetest()
{
 11a:	7179                	addi	sp,sp,-48
 11c:	f406                	sd	ra,40(sp)
 11e:	f022                	sd	s0,32(sp)
 120:	ec26                	sd	s1,24(sp)
 122:	e84a                	sd	s2,16(sp)
 124:	e44e                	sd	s3,8(sp)
 126:	e052                	sd	s4,0(sp)
 128:	1800                	addi	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = phys_size / 4;
  int pid1, pid2;

  printf("three: ");
 12a:	00001517          	auipc	a0,0x1
 12e:	c4650513          	addi	a0,a0,-954 # d70 <malloc+0x180>
 132:	00001097          	auipc	ra,0x1
 136:	a00080e7          	jalr	-1536(ra) # b32 <printf>

  char *p = sbrk(sz);
 13a:	02000537          	lui	a0,0x2000
 13e:	00000097          	auipc	ra,0x0
 142:	6f4080e7          	jalr	1780(ra) # 832 <sbrk>
  if (p == (char *)0xffffffffffffffffL)
 146:	57fd                	li	a5,-1
 148:	0af50463          	beq	a0,a5,1f0 <threetest+0xd6>
 14c:	84aa                	mv	s1,a0
  {
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  pid1 = fork();
 14e:	00000097          	auipc	ra,0x0
 152:	654080e7          	jalr	1620(ra) # 7a2 <fork>
  if (pid1 < 0)
 156:	0a054c63          	bltz	a0,20e <threetest+0xf4>
  {
    printf("fork failed\n");
    exit(-1);
  }
  if (pid1 == 0)
 15a:	c579                	beqz	a0,228 <threetest+0x10e>
      *(int *)q = 9999;
    }
    exit(0);
  }

  for (char *q = p; q < p + sz; q += 4096)
 15c:	020009b7          	lui	s3,0x2000
 160:	99a6                	add	s3,s3,s1
 162:	8926                	mv	s2,s1
 164:	6a05                	lui	s4,0x1
  {
    *(int *)q = getpid();
 166:	00000097          	auipc	ra,0x0
 16a:	6c4080e7          	jalr	1732(ra) # 82a <getpid>
 16e:	00a92023          	sw	a0,0(s2) # 5556000 <base+0x5550ff0>
  for (char *q = p; q < p + sz; q += 4096)
 172:	9952                	add	s2,s2,s4
 174:	ff3919e3          	bne	s2,s3,166 <threetest+0x4c>
  }

  wait(0);
 178:	4501                	li	a0,0
 17a:	00000097          	auipc	ra,0x0
 17e:	638080e7          	jalr	1592(ra) # 7b2 <wait>

  sleep(1);
 182:	4505                	li	a0,1
 184:	00000097          	auipc	ra,0x0
 188:	6b6080e7          	jalr	1718(ra) # 83a <sleep>

  for (char *q = p; q < p + sz; q += 4096)
 18c:	6a05                	lui	s4,0x1
  {
    if (*(int *)q != getpid())
 18e:	0004a903          	lw	s2,0(s1)
 192:	00000097          	auipc	ra,0x0
 196:	698080e7          	jalr	1688(ra) # 82a <getpid>
 19a:	12a91763          	bne	s2,a0,2c8 <threetest+0x1ae>
  for (char *q = p; q < p + sz; q += 4096)
 19e:	94d2                	add	s1,s1,s4
 1a0:	ff3497e3          	bne	s1,s3,18e <threetest+0x74>
      printf("wrong content\n");
      exit(-1);
    }
  }

  if (sbrk(-sz) == (char *)0xffffffffffffffffL)
 1a4:	fe000537          	lui	a0,0xfe000
 1a8:	00000097          	auipc	ra,0x0
 1ac:	68a080e7          	jalr	1674(ra) # 832 <sbrk>
 1b0:	57fd                	li	a5,-1
 1b2:	12f50863          	beq	a0,a5,2e2 <threetest+0x1c8>
  {
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }
  printf("ok\n");
 1b6:	00001517          	auipc	a0,0x1
 1ba:	b7a50513          	addi	a0,a0,-1158 # d30 <malloc+0x140>
 1be:	00001097          	auipc	ra,0x1
 1c2:	974080e7          	jalr	-1676(ra) # b32 <printf>
  printf("Number of page faults recorded after threetest test= %d\n", counter());
 1c6:	00000097          	auipc	ra,0x0
 1ca:	68c080e7          	jalr	1676(ra) # 852 <counter>
 1ce:	85aa                	mv	a1,a0
 1d0:	00001517          	auipc	a0,0x1
 1d4:	bd850513          	addi	a0,a0,-1064 # da8 <malloc+0x1b8>
 1d8:	00001097          	auipc	ra,0x1
 1dc:	95a080e7          	jalr	-1702(ra) # b32 <printf>
}
 1e0:	70a2                	ld	ra,40(sp)
 1e2:	7402                	ld	s0,32(sp)
 1e4:	64e2                	ld	s1,24(sp)
 1e6:	6942                	ld	s2,16(sp)
 1e8:	69a2                	ld	s3,8(sp)
 1ea:	6a02                	ld	s4,0(sp)
 1ec:	6145                	addi	sp,sp,48
 1ee:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
 1f0:	020005b7          	lui	a1,0x2000
 1f4:	00001517          	auipc	a0,0x1
 1f8:	afc50513          	addi	a0,a0,-1284 # cf0 <malloc+0x100>
 1fc:	00001097          	auipc	ra,0x1
 200:	936080e7          	jalr	-1738(ra) # b32 <printf>
    exit(-1);
 204:	557d                	li	a0,-1
 206:	00000097          	auipc	ra,0x0
 20a:	5a4080e7          	jalr	1444(ra) # 7aa <exit>
    printf("fork failed\n");
 20e:	00001517          	auipc	a0,0x1
 212:	b6a50513          	addi	a0,a0,-1174 # d78 <malloc+0x188>
 216:	00001097          	auipc	ra,0x1
 21a:	91c080e7          	jalr	-1764(ra) # b32 <printf>
    exit(-1);
 21e:	557d                	li	a0,-1
 220:	00000097          	auipc	ra,0x0
 224:	58a080e7          	jalr	1418(ra) # 7aa <exit>
    pid2 = fork();
 228:	00000097          	auipc	ra,0x0
 22c:	57a080e7          	jalr	1402(ra) # 7a2 <fork>
    if (pid2 < 0)
 230:	04054263          	bltz	a0,274 <threetest+0x15a>
    if (pid2 == 0)
 234:	ed29                	bnez	a0,28e <threetest+0x174>
      for (char *q = p; q < p + (sz / 5) * 4; q += 4096)
 236:	0199a9b7          	lui	s3,0x199a
 23a:	99a6                	add	s3,s3,s1
 23c:	8926                	mv	s2,s1
 23e:	6a05                	lui	s4,0x1
        *(int *)q = getpid();
 240:	00000097          	auipc	ra,0x0
 244:	5ea080e7          	jalr	1514(ra) # 82a <getpid>
 248:	00a92023          	sw	a0,0(s2)
      for (char *q = p; q < p + (sz / 5) * 4; q += 4096)
 24c:	9952                	add	s2,s2,s4
 24e:	ff2999e3          	bne	s3,s2,240 <threetest+0x126>
      for (char *q = p; q < p + (sz / 5) * 4; q += 4096)
 252:	6a05                	lui	s4,0x1
        if (*(int *)q != getpid())
 254:	0004a903          	lw	s2,0(s1)
 258:	00000097          	auipc	ra,0x0
 25c:	5d2080e7          	jalr	1490(ra) # 82a <getpid>
 260:	04a91763          	bne	s2,a0,2ae <threetest+0x194>
      for (char *q = p; q < p + (sz / 5) * 4; q += 4096)
 264:	94d2                	add	s1,s1,s4
 266:	fe9997e3          	bne	s3,s1,254 <threetest+0x13a>
      exit(-1);
 26a:	557d                	li	a0,-1
 26c:	00000097          	auipc	ra,0x0
 270:	53e080e7          	jalr	1342(ra) # 7aa <exit>
      printf("fork failed");
 274:	00001517          	auipc	a0,0x1
 278:	b1450513          	addi	a0,a0,-1260 # d88 <malloc+0x198>
 27c:	00001097          	auipc	ra,0x1
 280:	8b6080e7          	jalr	-1866(ra) # b32 <printf>
      exit(-1);
 284:	557d                	li	a0,-1
 286:	00000097          	auipc	ra,0x0
 28a:	524080e7          	jalr	1316(ra) # 7aa <exit>
    for (char *q = p; q < p + (sz / 2); q += 4096)
 28e:	01000737          	lui	a4,0x1000
 292:	9726                	add	a4,a4,s1
      *(int *)q = 9999;
 294:	6789                	lui	a5,0x2
 296:	70f78793          	addi	a5,a5,1807 # 270f <buf+0x6ff>
    for (char *q = p; q < p + (sz / 2); q += 4096)
 29a:	6685                	lui	a3,0x1
      *(int *)q = 9999;
 29c:	c09c                	sw	a5,0(s1)
    for (char *q = p; q < p + (sz / 2); q += 4096)
 29e:	94b6                	add	s1,s1,a3
 2a0:	fee49ee3          	bne	s1,a4,29c <threetest+0x182>
    exit(0);
 2a4:	4501                	li	a0,0
 2a6:	00000097          	auipc	ra,0x0
 2aa:	504080e7          	jalr	1284(ra) # 7aa <exit>
          printf("wrong content\n");
 2ae:	00001517          	auipc	a0,0x1
 2b2:	aea50513          	addi	a0,a0,-1302 # d98 <malloc+0x1a8>
 2b6:	00001097          	auipc	ra,0x1
 2ba:	87c080e7          	jalr	-1924(ra) # b32 <printf>
          exit(-1);
 2be:	557d                	li	a0,-1
 2c0:	00000097          	auipc	ra,0x0
 2c4:	4ea080e7          	jalr	1258(ra) # 7aa <exit>
      printf("wrong content\n");
 2c8:	00001517          	auipc	a0,0x1
 2cc:	ad050513          	addi	a0,a0,-1328 # d98 <malloc+0x1a8>
 2d0:	00001097          	auipc	ra,0x1
 2d4:	862080e7          	jalr	-1950(ra) # b32 <printf>
      exit(-1);
 2d8:	557d                	li	a0,-1
 2da:	00000097          	auipc	ra,0x0
 2de:	4d0080e7          	jalr	1232(ra) # 7aa <exit>
    printf("sbrk(-%d) failed\n", sz);
 2e2:	020005b7          	lui	a1,0x2000
 2e6:	00001517          	auipc	a0,0x1
 2ea:	a3250513          	addi	a0,a0,-1486 # d18 <malloc+0x128>
 2ee:	00001097          	auipc	ra,0x1
 2f2:	844080e7          	jalr	-1980(ra) # b32 <printf>
    exit(-1);
 2f6:	557d                	li	a0,-1
 2f8:	00000097          	auipc	ra,0x0
 2fc:	4b2080e7          	jalr	1202(ra) # 7aa <exit>

0000000000000300 <filetest>:
char buf[4096];
char junk3[4096];

// test whether copyout() simulates COW faults.
void filetest()
{
 300:	7179                	addi	sp,sp,-48
 302:	f406                	sd	ra,40(sp)
 304:	f022                	sd	s0,32(sp)
 306:	ec26                	sd	s1,24(sp)
 308:	e84a                	sd	s2,16(sp)
 30a:	1800                	addi	s0,sp,48
  printf("file: ");
 30c:	00001517          	auipc	a0,0x1
 310:	adc50513          	addi	a0,a0,-1316 # de8 <malloc+0x1f8>
 314:	00001097          	auipc	ra,0x1
 318:	81e080e7          	jalr	-2018(ra) # b32 <printf>

  buf[0] = 99;
 31c:	06300793          	li	a5,99
 320:	00002717          	auipc	a4,0x2
 324:	cef70823          	sb	a5,-784(a4) # 2010 <buf>

  for (int i = 0; i < 4; i++)
 328:	fc042c23          	sw	zero,-40(s0)
  {
    if (pipe(fds) != 0)
 32c:	00001497          	auipc	s1,0x1
 330:	cd448493          	addi	s1,s1,-812 # 1000 <fds>
  for (int i = 0; i < 4; i++)
 334:	490d                	li	s2,3
    if (pipe(fds) != 0)
 336:	8526                	mv	a0,s1
 338:	00000097          	auipc	ra,0x0
 33c:	482080e7          	jalr	1154(ra) # 7ba <pipe>
 340:	ed51                	bnez	a0,3dc <filetest+0xdc>
    {
      printf("pipe() failed\n");
      exit(-1);
    }
    int pid = fork();
 342:	00000097          	auipc	ra,0x0
 346:	460080e7          	jalr	1120(ra) # 7a2 <fork>
    if (pid < 0)
 34a:	0a054663          	bltz	a0,3f6 <filetest+0xf6>
    {
      printf("fork failed\n");
      exit(-1);
    }
    if (pid == 0)
 34e:	c169                	beqz	a0,410 <filetest+0x110>
        printf("error: read the wrong value\n");
        exit(1);
      }
      exit(0);
    }
    if (write(fds[1], &i, sizeof(i)) != sizeof(i))
 350:	4611                	li	a2,4
 352:	fd840593          	addi	a1,s0,-40
 356:	40c8                	lw	a0,4(s1)
 358:	00000097          	auipc	ra,0x0
 35c:	472080e7          	jalr	1138(ra) # 7ca <write>
 360:	4791                	li	a5,4
 362:	12f51863          	bne	a0,a5,492 <filetest+0x192>
  for (int i = 0; i < 4; i++)
 366:	fd842783          	lw	a5,-40(s0)
 36a:	2785                	addiw	a5,a5,1
 36c:	0007871b          	sext.w	a4,a5
 370:	fcf42c23          	sw	a5,-40(s0)
 374:	fce951e3          	bge	s2,a4,336 <filetest+0x36>
      printf("error: write failed\n");
      exit(-1);
    }
  }

  int xstatus = 0;
 378:	fc042e23          	sw	zero,-36(s0)
 37c:	4491                	li	s1,4
  for (int i = 0; i < 4; i++)
  {
    wait(&xstatus);
 37e:	fdc40513          	addi	a0,s0,-36
 382:	00000097          	auipc	ra,0x0
 386:	430080e7          	jalr	1072(ra) # 7b2 <wait>
    if (xstatus != 0)
 38a:	fdc42783          	lw	a5,-36(s0)
 38e:	10079f63          	bnez	a5,4ac <filetest+0x1ac>
  for (int i = 0; i < 4; i++)
 392:	34fd                	addiw	s1,s1,-1
 394:	f4ed                	bnez	s1,37e <filetest+0x7e>
    {
      exit(1);
    }
  }

  if (buf[0] != 99)
 396:	00002717          	auipc	a4,0x2
 39a:	c7a74703          	lbu	a4,-902(a4) # 2010 <buf>
 39e:	06300793          	li	a5,99
 3a2:	10f71a63          	bne	a4,a5,4b6 <filetest+0x1b6>
  {
    printf("error: child overwrote parent\n");
    exit(1);
  }
  printf("ok\n");
 3a6:	00001517          	auipc	a0,0x1
 3aa:	98a50513          	addi	a0,a0,-1654 # d30 <malloc+0x140>
 3ae:	00000097          	auipc	ra,0x0
 3b2:	784080e7          	jalr	1924(ra) # b32 <printf>
  printf("Number of page faults recorded after filetest test = %d\n", counter());
 3b6:	00000097          	auipc	ra,0x0
 3ba:	49c080e7          	jalr	1180(ra) # 852 <counter>
 3be:	85aa                	mv	a1,a0
 3c0:	00001517          	auipc	a0,0x1
 3c4:	ab050513          	addi	a0,a0,-1360 # e70 <malloc+0x280>
 3c8:	00000097          	auipc	ra,0x0
 3cc:	76a080e7          	jalr	1898(ra) # b32 <printf>

}
 3d0:	70a2                	ld	ra,40(sp)
 3d2:	7402                	ld	s0,32(sp)
 3d4:	64e2                	ld	s1,24(sp)
 3d6:	6942                	ld	s2,16(sp)
 3d8:	6145                	addi	sp,sp,48
 3da:	8082                	ret
      printf("pipe() failed\n");
 3dc:	00001517          	auipc	a0,0x1
 3e0:	a1450513          	addi	a0,a0,-1516 # df0 <malloc+0x200>
 3e4:	00000097          	auipc	ra,0x0
 3e8:	74e080e7          	jalr	1870(ra) # b32 <printf>
      exit(-1);
 3ec:	557d                	li	a0,-1
 3ee:	00000097          	auipc	ra,0x0
 3f2:	3bc080e7          	jalr	956(ra) # 7aa <exit>
      printf("fork failed\n");
 3f6:	00001517          	auipc	a0,0x1
 3fa:	98250513          	addi	a0,a0,-1662 # d78 <malloc+0x188>
 3fe:	00000097          	auipc	ra,0x0
 402:	734080e7          	jalr	1844(ra) # b32 <printf>
      exit(-1);
 406:	557d                	li	a0,-1
 408:	00000097          	auipc	ra,0x0
 40c:	3a2080e7          	jalr	930(ra) # 7aa <exit>
      sleep(1);
 410:	4505                	li	a0,1
 412:	00000097          	auipc	ra,0x0
 416:	428080e7          	jalr	1064(ra) # 83a <sleep>
      if (read(fds[0], buf, sizeof(i)) != sizeof(i))
 41a:	4611                	li	a2,4
 41c:	00002597          	auipc	a1,0x2
 420:	bf458593          	addi	a1,a1,-1036 # 2010 <buf>
 424:	00001517          	auipc	a0,0x1
 428:	bdc52503          	lw	a0,-1060(a0) # 1000 <fds>
 42c:	00000097          	auipc	ra,0x0
 430:	396080e7          	jalr	918(ra) # 7c2 <read>
 434:	4791                	li	a5,4
 436:	02f51c63          	bne	a0,a5,46e <filetest+0x16e>
      sleep(1);
 43a:	4505                	li	a0,1
 43c:	00000097          	auipc	ra,0x0
 440:	3fe080e7          	jalr	1022(ra) # 83a <sleep>
      if (j != i)
 444:	fd842703          	lw	a4,-40(s0)
 448:	00002797          	auipc	a5,0x2
 44c:	bc87a783          	lw	a5,-1080(a5) # 2010 <buf>
 450:	02f70c63          	beq	a4,a5,488 <filetest+0x188>
        printf("error: read the wrong value\n");
 454:	00001517          	auipc	a0,0x1
 458:	9c450513          	addi	a0,a0,-1596 # e18 <malloc+0x228>
 45c:	00000097          	auipc	ra,0x0
 460:	6d6080e7          	jalr	1750(ra) # b32 <printf>
        exit(1);
 464:	4505                	li	a0,1
 466:	00000097          	auipc	ra,0x0
 46a:	344080e7          	jalr	836(ra) # 7aa <exit>
        printf("error: read failed\n");
 46e:	00001517          	auipc	a0,0x1
 472:	99250513          	addi	a0,a0,-1646 # e00 <malloc+0x210>
 476:	00000097          	auipc	ra,0x0
 47a:	6bc080e7          	jalr	1724(ra) # b32 <printf>
        exit(1);
 47e:	4505                	li	a0,1
 480:	00000097          	auipc	ra,0x0
 484:	32a080e7          	jalr	810(ra) # 7aa <exit>
      exit(0);
 488:	4501                	li	a0,0
 48a:	00000097          	auipc	ra,0x0
 48e:	320080e7          	jalr	800(ra) # 7aa <exit>
      printf("error: write failed\n");
 492:	00001517          	auipc	a0,0x1
 496:	9a650513          	addi	a0,a0,-1626 # e38 <malloc+0x248>
 49a:	00000097          	auipc	ra,0x0
 49e:	698080e7          	jalr	1688(ra) # b32 <printf>
      exit(-1);
 4a2:	557d                	li	a0,-1
 4a4:	00000097          	auipc	ra,0x0
 4a8:	306080e7          	jalr	774(ra) # 7aa <exit>
      exit(1);
 4ac:	4505                	li	a0,1
 4ae:	00000097          	auipc	ra,0x0
 4b2:	2fc080e7          	jalr	764(ra) # 7aa <exit>
    printf("error: child overwrote parent\n");
 4b6:	00001517          	auipc	a0,0x1
 4ba:	99a50513          	addi	a0,a0,-1638 # e50 <malloc+0x260>
 4be:	00000097          	auipc	ra,0x0
 4c2:	674080e7          	jalr	1652(ra) # b32 <printf>
    exit(1);
 4c6:	4505                	li	a0,1
 4c8:	00000097          	auipc	ra,0x0
 4cc:	2e2080e7          	jalr	738(ra) # 7aa <exit>

00000000000004d0 <main>:

int main(int argc, char *argv[])
{
 4d0:	1141                	addi	sp,sp,-16
 4d2:	e406                	sd	ra,8(sp)
 4d4:	e022                	sd	s0,0(sp)
 4d6:	0800                	addi	s0,sp,16
  simpletest();
 4d8:	00000097          	auipc	ra,0x0
 4dc:	b28080e7          	jalr	-1240(ra) # 0 <simpletest>

  // check that the first simpletest() freed the physical memory.
  simpletest();
 4e0:	00000097          	auipc	ra,0x0
 4e4:	b20080e7          	jalr	-1248(ra) # 0 <simpletest>

  threetest();
 4e8:	00000097          	auipc	ra,0x0
 4ec:	c32080e7          	jalr	-974(ra) # 11a <threetest>
  threetest();
 4f0:	00000097          	auipc	ra,0x0
 4f4:	c2a080e7          	jalr	-982(ra) # 11a <threetest>
  threetest();
 4f8:	00000097          	auipc	ra,0x0
 4fc:	c22080e7          	jalr	-990(ra) # 11a <threetest>

  filetest();
 500:	00000097          	auipc	ra,0x0
 504:	e00080e7          	jalr	-512(ra) # 300 <filetest>

  printf("ALL COW TESTS PASSED\n");
 508:	00001517          	auipc	a0,0x1
 50c:	9a850513          	addi	a0,a0,-1624 # eb0 <malloc+0x2c0>
 510:	00000097          	auipc	ra,0x0
 514:	622080e7          	jalr	1570(ra) # b32 <printf>

  exit(0);
 518:	4501                	li	a0,0
 51a:	00000097          	auipc	ra,0x0
 51e:	290080e7          	jalr	656(ra) # 7aa <exit>

0000000000000522 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 522:	1141                	addi	sp,sp,-16
 524:	e406                	sd	ra,8(sp)
 526:	e022                	sd	s0,0(sp)
 528:	0800                	addi	s0,sp,16
  extern int main();
  main();
 52a:	00000097          	auipc	ra,0x0
 52e:	fa6080e7          	jalr	-90(ra) # 4d0 <main>
  exit(0);
 532:	4501                	li	a0,0
 534:	00000097          	auipc	ra,0x0
 538:	276080e7          	jalr	630(ra) # 7aa <exit>

000000000000053c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 53c:	1141                	addi	sp,sp,-16
 53e:	e422                	sd	s0,8(sp)
 540:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 542:	87aa                	mv	a5,a0
 544:	0585                	addi	a1,a1,1
 546:	0785                	addi	a5,a5,1
 548:	fff5c703          	lbu	a4,-1(a1)
 54c:	fee78fa3          	sb	a4,-1(a5)
 550:	fb75                	bnez	a4,544 <strcpy+0x8>
    ;
  return os;
}
 552:	6422                	ld	s0,8(sp)
 554:	0141                	addi	sp,sp,16
 556:	8082                	ret

0000000000000558 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 558:	1141                	addi	sp,sp,-16
 55a:	e422                	sd	s0,8(sp)
 55c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 55e:	00054783          	lbu	a5,0(a0)
 562:	cb91                	beqz	a5,576 <strcmp+0x1e>
 564:	0005c703          	lbu	a4,0(a1)
 568:	00f71763          	bne	a4,a5,576 <strcmp+0x1e>
    p++, q++;
 56c:	0505                	addi	a0,a0,1
 56e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 570:	00054783          	lbu	a5,0(a0)
 574:	fbe5                	bnez	a5,564 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 576:	0005c503          	lbu	a0,0(a1)
}
 57a:	40a7853b          	subw	a0,a5,a0
 57e:	6422                	ld	s0,8(sp)
 580:	0141                	addi	sp,sp,16
 582:	8082                	ret

0000000000000584 <strlen>:

uint
strlen(const char *s)
{
 584:	1141                	addi	sp,sp,-16
 586:	e422                	sd	s0,8(sp)
 588:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 58a:	00054783          	lbu	a5,0(a0)
 58e:	cf91                	beqz	a5,5aa <strlen+0x26>
 590:	0505                	addi	a0,a0,1
 592:	87aa                	mv	a5,a0
 594:	4685                	li	a3,1
 596:	9e89                	subw	a3,a3,a0
 598:	00f6853b          	addw	a0,a3,a5
 59c:	0785                	addi	a5,a5,1
 59e:	fff7c703          	lbu	a4,-1(a5)
 5a2:	fb7d                	bnez	a4,598 <strlen+0x14>
    ;
  return n;
}
 5a4:	6422                	ld	s0,8(sp)
 5a6:	0141                	addi	sp,sp,16
 5a8:	8082                	ret
  for(n = 0; s[n]; n++)
 5aa:	4501                	li	a0,0
 5ac:	bfe5                	j	5a4 <strlen+0x20>

00000000000005ae <memset>:

void*
memset(void *dst, int c, uint n)
{
 5ae:	1141                	addi	sp,sp,-16
 5b0:	e422                	sd	s0,8(sp)
 5b2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 5b4:	ca19                	beqz	a2,5ca <memset+0x1c>
 5b6:	87aa                	mv	a5,a0
 5b8:	1602                	slli	a2,a2,0x20
 5ba:	9201                	srli	a2,a2,0x20
 5bc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 5c0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 5c4:	0785                	addi	a5,a5,1
 5c6:	fee79de3          	bne	a5,a4,5c0 <memset+0x12>
  }
  return dst;
}
 5ca:	6422                	ld	s0,8(sp)
 5cc:	0141                	addi	sp,sp,16
 5ce:	8082                	ret

00000000000005d0 <strchr>:

char*
strchr(const char *s, char c)
{
 5d0:	1141                	addi	sp,sp,-16
 5d2:	e422                	sd	s0,8(sp)
 5d4:	0800                	addi	s0,sp,16
  for(; *s; s++)
 5d6:	00054783          	lbu	a5,0(a0)
 5da:	cb99                	beqz	a5,5f0 <strchr+0x20>
    if(*s == c)
 5dc:	00f58763          	beq	a1,a5,5ea <strchr+0x1a>
  for(; *s; s++)
 5e0:	0505                	addi	a0,a0,1
 5e2:	00054783          	lbu	a5,0(a0)
 5e6:	fbfd                	bnez	a5,5dc <strchr+0xc>
      return (char*)s;
  return 0;
 5e8:	4501                	li	a0,0
}
 5ea:	6422                	ld	s0,8(sp)
 5ec:	0141                	addi	sp,sp,16
 5ee:	8082                	ret
  return 0;
 5f0:	4501                	li	a0,0
 5f2:	bfe5                	j	5ea <strchr+0x1a>

00000000000005f4 <gets>:

char*
gets(char *buf, int max)
{
 5f4:	711d                	addi	sp,sp,-96
 5f6:	ec86                	sd	ra,88(sp)
 5f8:	e8a2                	sd	s0,80(sp)
 5fa:	e4a6                	sd	s1,72(sp)
 5fc:	e0ca                	sd	s2,64(sp)
 5fe:	fc4e                	sd	s3,56(sp)
 600:	f852                	sd	s4,48(sp)
 602:	f456                	sd	s5,40(sp)
 604:	f05a                	sd	s6,32(sp)
 606:	ec5e                	sd	s7,24(sp)
 608:	1080                	addi	s0,sp,96
 60a:	8baa                	mv	s7,a0
 60c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 60e:	892a                	mv	s2,a0
 610:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 612:	4aa9                	li	s5,10
 614:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 616:	89a6                	mv	s3,s1
 618:	2485                	addiw	s1,s1,1
 61a:	0344d863          	bge	s1,s4,64a <gets+0x56>
    cc = read(0, &c, 1);
 61e:	4605                	li	a2,1
 620:	faf40593          	addi	a1,s0,-81
 624:	4501                	li	a0,0
 626:	00000097          	auipc	ra,0x0
 62a:	19c080e7          	jalr	412(ra) # 7c2 <read>
    if(cc < 1)
 62e:	00a05e63          	blez	a0,64a <gets+0x56>
    buf[i++] = c;
 632:	faf44783          	lbu	a5,-81(s0)
 636:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 63a:	01578763          	beq	a5,s5,648 <gets+0x54>
 63e:	0905                	addi	s2,s2,1
 640:	fd679be3          	bne	a5,s6,616 <gets+0x22>
  for(i=0; i+1 < max; ){
 644:	89a6                	mv	s3,s1
 646:	a011                	j	64a <gets+0x56>
 648:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 64a:	99de                	add	s3,s3,s7
 64c:	00098023          	sb	zero,0(s3) # 199a000 <base+0x1994ff0>
  return buf;
}
 650:	855e                	mv	a0,s7
 652:	60e6                	ld	ra,88(sp)
 654:	6446                	ld	s0,80(sp)
 656:	64a6                	ld	s1,72(sp)
 658:	6906                	ld	s2,64(sp)
 65a:	79e2                	ld	s3,56(sp)
 65c:	7a42                	ld	s4,48(sp)
 65e:	7aa2                	ld	s5,40(sp)
 660:	7b02                	ld	s6,32(sp)
 662:	6be2                	ld	s7,24(sp)
 664:	6125                	addi	sp,sp,96
 666:	8082                	ret

0000000000000668 <stat>:

int
stat(const char *n, struct stat *st)
{
 668:	1101                	addi	sp,sp,-32
 66a:	ec06                	sd	ra,24(sp)
 66c:	e822                	sd	s0,16(sp)
 66e:	e426                	sd	s1,8(sp)
 670:	e04a                	sd	s2,0(sp)
 672:	1000                	addi	s0,sp,32
 674:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 676:	4581                	li	a1,0
 678:	00000097          	auipc	ra,0x0
 67c:	172080e7          	jalr	370(ra) # 7ea <open>
  if(fd < 0)
 680:	02054563          	bltz	a0,6aa <stat+0x42>
 684:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 686:	85ca                	mv	a1,s2
 688:	00000097          	auipc	ra,0x0
 68c:	17a080e7          	jalr	378(ra) # 802 <fstat>
 690:	892a                	mv	s2,a0
  close(fd);
 692:	8526                	mv	a0,s1
 694:	00000097          	auipc	ra,0x0
 698:	13e080e7          	jalr	318(ra) # 7d2 <close>
  return r;
}
 69c:	854a                	mv	a0,s2
 69e:	60e2                	ld	ra,24(sp)
 6a0:	6442                	ld	s0,16(sp)
 6a2:	64a2                	ld	s1,8(sp)
 6a4:	6902                	ld	s2,0(sp)
 6a6:	6105                	addi	sp,sp,32
 6a8:	8082                	ret
    return -1;
 6aa:	597d                	li	s2,-1
 6ac:	bfc5                	j	69c <stat+0x34>

00000000000006ae <atoi>:

int
atoi(const char *s)
{
 6ae:	1141                	addi	sp,sp,-16
 6b0:	e422                	sd	s0,8(sp)
 6b2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 6b4:	00054603          	lbu	a2,0(a0)
 6b8:	fd06079b          	addiw	a5,a2,-48
 6bc:	0ff7f793          	andi	a5,a5,255
 6c0:	4725                	li	a4,9
 6c2:	02f76963          	bltu	a4,a5,6f4 <atoi+0x46>
 6c6:	86aa                	mv	a3,a0
  n = 0;
 6c8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 6ca:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 6cc:	0685                	addi	a3,a3,1
 6ce:	0025179b          	slliw	a5,a0,0x2
 6d2:	9fa9                	addw	a5,a5,a0
 6d4:	0017979b          	slliw	a5,a5,0x1
 6d8:	9fb1                	addw	a5,a5,a2
 6da:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 6de:	0006c603          	lbu	a2,0(a3) # 1000 <fds>
 6e2:	fd06071b          	addiw	a4,a2,-48
 6e6:	0ff77713          	andi	a4,a4,255
 6ea:	fee5f1e3          	bgeu	a1,a4,6cc <atoi+0x1e>
  return n;
}
 6ee:	6422                	ld	s0,8(sp)
 6f0:	0141                	addi	sp,sp,16
 6f2:	8082                	ret
  n = 0;
 6f4:	4501                	li	a0,0
 6f6:	bfe5                	j	6ee <atoi+0x40>

00000000000006f8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 6f8:	1141                	addi	sp,sp,-16
 6fa:	e422                	sd	s0,8(sp)
 6fc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 6fe:	02b57463          	bgeu	a0,a1,726 <memmove+0x2e>
    while(n-- > 0)
 702:	00c05f63          	blez	a2,720 <memmove+0x28>
 706:	1602                	slli	a2,a2,0x20
 708:	9201                	srli	a2,a2,0x20
 70a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 70e:	872a                	mv	a4,a0
      *dst++ = *src++;
 710:	0585                	addi	a1,a1,1
 712:	0705                	addi	a4,a4,1
 714:	fff5c683          	lbu	a3,-1(a1)
 718:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 71c:	fee79ae3          	bne	a5,a4,710 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 720:	6422                	ld	s0,8(sp)
 722:	0141                	addi	sp,sp,16
 724:	8082                	ret
    dst += n;
 726:	00c50733          	add	a4,a0,a2
    src += n;
 72a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 72c:	fec05ae3          	blez	a2,720 <memmove+0x28>
 730:	fff6079b          	addiw	a5,a2,-1
 734:	1782                	slli	a5,a5,0x20
 736:	9381                	srli	a5,a5,0x20
 738:	fff7c793          	not	a5,a5
 73c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 73e:	15fd                	addi	a1,a1,-1
 740:	177d                	addi	a4,a4,-1
 742:	0005c683          	lbu	a3,0(a1)
 746:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 74a:	fee79ae3          	bne	a5,a4,73e <memmove+0x46>
 74e:	bfc9                	j	720 <memmove+0x28>

0000000000000750 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 750:	1141                	addi	sp,sp,-16
 752:	e422                	sd	s0,8(sp)
 754:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 756:	ca05                	beqz	a2,786 <memcmp+0x36>
 758:	fff6069b          	addiw	a3,a2,-1
 75c:	1682                	slli	a3,a3,0x20
 75e:	9281                	srli	a3,a3,0x20
 760:	0685                	addi	a3,a3,1
 762:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 764:	00054783          	lbu	a5,0(a0)
 768:	0005c703          	lbu	a4,0(a1)
 76c:	00e79863          	bne	a5,a4,77c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 770:	0505                	addi	a0,a0,1
    p2++;
 772:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 774:	fed518e3          	bne	a0,a3,764 <memcmp+0x14>
  }
  return 0;
 778:	4501                	li	a0,0
 77a:	a019                	j	780 <memcmp+0x30>
      return *p1 - *p2;
 77c:	40e7853b          	subw	a0,a5,a4
}
 780:	6422                	ld	s0,8(sp)
 782:	0141                	addi	sp,sp,16
 784:	8082                	ret
  return 0;
 786:	4501                	li	a0,0
 788:	bfe5                	j	780 <memcmp+0x30>

000000000000078a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 78a:	1141                	addi	sp,sp,-16
 78c:	e406                	sd	ra,8(sp)
 78e:	e022                	sd	s0,0(sp)
 790:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 792:	00000097          	auipc	ra,0x0
 796:	f66080e7          	jalr	-154(ra) # 6f8 <memmove>
}
 79a:	60a2                	ld	ra,8(sp)
 79c:	6402                	ld	s0,0(sp)
 79e:	0141                	addi	sp,sp,16
 7a0:	8082                	ret

00000000000007a2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 7a2:	4885                	li	a7,1
 ecall
 7a4:	00000073          	ecall
 ret
 7a8:	8082                	ret

00000000000007aa <exit>:
.global exit
exit:
 li a7, SYS_exit
 7aa:	4889                	li	a7,2
 ecall
 7ac:	00000073          	ecall
 ret
 7b0:	8082                	ret

00000000000007b2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 7b2:	488d                	li	a7,3
 ecall
 7b4:	00000073          	ecall
 ret
 7b8:	8082                	ret

00000000000007ba <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 7ba:	4891                	li	a7,4
 ecall
 7bc:	00000073          	ecall
 ret
 7c0:	8082                	ret

00000000000007c2 <read>:
.global read
read:
 li a7, SYS_read
 7c2:	4895                	li	a7,5
 ecall
 7c4:	00000073          	ecall
 ret
 7c8:	8082                	ret

00000000000007ca <write>:
.global write
write:
 li a7, SYS_write
 7ca:	48c1                	li	a7,16
 ecall
 7cc:	00000073          	ecall
 ret
 7d0:	8082                	ret

00000000000007d2 <close>:
.global close
close:
 li a7, SYS_close
 7d2:	48d5                	li	a7,21
 ecall
 7d4:	00000073          	ecall
 ret
 7d8:	8082                	ret

00000000000007da <kill>:
.global kill
kill:
 li a7, SYS_kill
 7da:	4899                	li	a7,6
 ecall
 7dc:	00000073          	ecall
 ret
 7e0:	8082                	ret

00000000000007e2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 7e2:	489d                	li	a7,7
 ecall
 7e4:	00000073          	ecall
 ret
 7e8:	8082                	ret

00000000000007ea <open>:
.global open
open:
 li a7, SYS_open
 7ea:	48bd                	li	a7,15
 ecall
 7ec:	00000073          	ecall
 ret
 7f0:	8082                	ret

00000000000007f2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 7f2:	48c5                	li	a7,17
 ecall
 7f4:	00000073          	ecall
 ret
 7f8:	8082                	ret

00000000000007fa <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 7fa:	48c9                	li	a7,18
 ecall
 7fc:	00000073          	ecall
 ret
 800:	8082                	ret

0000000000000802 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 802:	48a1                	li	a7,8
 ecall
 804:	00000073          	ecall
 ret
 808:	8082                	ret

000000000000080a <link>:
.global link
link:
 li a7, SYS_link
 80a:	48cd                	li	a7,19
 ecall
 80c:	00000073          	ecall
 ret
 810:	8082                	ret

0000000000000812 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 812:	48d1                	li	a7,20
 ecall
 814:	00000073          	ecall
 ret
 818:	8082                	ret

000000000000081a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 81a:	48a5                	li	a7,9
 ecall
 81c:	00000073          	ecall
 ret
 820:	8082                	ret

0000000000000822 <dup>:
.global dup
dup:
 li a7, SYS_dup
 822:	48a9                	li	a7,10
 ecall
 824:	00000073          	ecall
 ret
 828:	8082                	ret

000000000000082a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 82a:	48ad                	li	a7,11
 ecall
 82c:	00000073          	ecall
 ret
 830:	8082                	ret

0000000000000832 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 832:	48b1                	li	a7,12
 ecall
 834:	00000073          	ecall
 ret
 838:	8082                	ret

000000000000083a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 83a:	48b5                	li	a7,13
 ecall
 83c:	00000073          	ecall
 ret
 840:	8082                	ret

0000000000000842 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 842:	48b9                	li	a7,14
 ecall
 844:	00000073          	ecall
 ret
 848:	8082                	ret

000000000000084a <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 84a:	48d9                	li	a7,22
 ecall
 84c:	00000073          	ecall
 ret
 850:	8082                	ret

0000000000000852 <counter>:
.global counter
counter:
 li a7, SYS_counter
 852:	48dd                	li	a7,23
 ecall
 854:	00000073          	ecall
 ret
 858:	8082                	ret

000000000000085a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 85a:	1101                	addi	sp,sp,-32
 85c:	ec06                	sd	ra,24(sp)
 85e:	e822                	sd	s0,16(sp)
 860:	1000                	addi	s0,sp,32
 862:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 866:	4605                	li	a2,1
 868:	fef40593          	addi	a1,s0,-17
 86c:	00000097          	auipc	ra,0x0
 870:	f5e080e7          	jalr	-162(ra) # 7ca <write>
}
 874:	60e2                	ld	ra,24(sp)
 876:	6442                	ld	s0,16(sp)
 878:	6105                	addi	sp,sp,32
 87a:	8082                	ret

000000000000087c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 87c:	7139                	addi	sp,sp,-64
 87e:	fc06                	sd	ra,56(sp)
 880:	f822                	sd	s0,48(sp)
 882:	f426                	sd	s1,40(sp)
 884:	f04a                	sd	s2,32(sp)
 886:	ec4e                	sd	s3,24(sp)
 888:	0080                	addi	s0,sp,64
 88a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 88c:	c299                	beqz	a3,892 <printint+0x16>
 88e:	0805c863          	bltz	a1,91e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 892:	2581                	sext.w	a1,a1
  neg = 0;
 894:	4881                	li	a7,0
 896:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 89a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 89c:	2601                	sext.w	a2,a2
 89e:	00000517          	auipc	a0,0x0
 8a2:	63250513          	addi	a0,a0,1586 # ed0 <digits>
 8a6:	883a                	mv	a6,a4
 8a8:	2705                	addiw	a4,a4,1
 8aa:	02c5f7bb          	remuw	a5,a1,a2
 8ae:	1782                	slli	a5,a5,0x20
 8b0:	9381                	srli	a5,a5,0x20
 8b2:	97aa                	add	a5,a5,a0
 8b4:	0007c783          	lbu	a5,0(a5)
 8b8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 8bc:	0005879b          	sext.w	a5,a1
 8c0:	02c5d5bb          	divuw	a1,a1,a2
 8c4:	0685                	addi	a3,a3,1
 8c6:	fec7f0e3          	bgeu	a5,a2,8a6 <printint+0x2a>
  if(neg)
 8ca:	00088b63          	beqz	a7,8e0 <printint+0x64>
    buf[i++] = '-';
 8ce:	fd040793          	addi	a5,s0,-48
 8d2:	973e                	add	a4,a4,a5
 8d4:	02d00793          	li	a5,45
 8d8:	fef70823          	sb	a5,-16(a4)
 8dc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 8e0:	02e05863          	blez	a4,910 <printint+0x94>
 8e4:	fc040793          	addi	a5,s0,-64
 8e8:	00e78933          	add	s2,a5,a4
 8ec:	fff78993          	addi	s3,a5,-1
 8f0:	99ba                	add	s3,s3,a4
 8f2:	377d                	addiw	a4,a4,-1
 8f4:	1702                	slli	a4,a4,0x20
 8f6:	9301                	srli	a4,a4,0x20
 8f8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 8fc:	fff94583          	lbu	a1,-1(s2)
 900:	8526                	mv	a0,s1
 902:	00000097          	auipc	ra,0x0
 906:	f58080e7          	jalr	-168(ra) # 85a <putc>
  while(--i >= 0)
 90a:	197d                	addi	s2,s2,-1
 90c:	ff3918e3          	bne	s2,s3,8fc <printint+0x80>
}
 910:	70e2                	ld	ra,56(sp)
 912:	7442                	ld	s0,48(sp)
 914:	74a2                	ld	s1,40(sp)
 916:	7902                	ld	s2,32(sp)
 918:	69e2                	ld	s3,24(sp)
 91a:	6121                	addi	sp,sp,64
 91c:	8082                	ret
    x = -xx;
 91e:	40b005bb          	negw	a1,a1
    neg = 1;
 922:	4885                	li	a7,1
    x = -xx;
 924:	bf8d                	j	896 <printint+0x1a>

0000000000000926 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 926:	7119                	addi	sp,sp,-128
 928:	fc86                	sd	ra,120(sp)
 92a:	f8a2                	sd	s0,112(sp)
 92c:	f4a6                	sd	s1,104(sp)
 92e:	f0ca                	sd	s2,96(sp)
 930:	ecce                	sd	s3,88(sp)
 932:	e8d2                	sd	s4,80(sp)
 934:	e4d6                	sd	s5,72(sp)
 936:	e0da                	sd	s6,64(sp)
 938:	fc5e                	sd	s7,56(sp)
 93a:	f862                	sd	s8,48(sp)
 93c:	f466                	sd	s9,40(sp)
 93e:	f06a                	sd	s10,32(sp)
 940:	ec6e                	sd	s11,24(sp)
 942:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 944:	0005c903          	lbu	s2,0(a1)
 948:	18090f63          	beqz	s2,ae6 <vprintf+0x1c0>
 94c:	8aaa                	mv	s5,a0
 94e:	8b32                	mv	s6,a2
 950:	00158493          	addi	s1,a1,1
  state = 0;
 954:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 956:	02500a13          	li	s4,37
      if(c == 'd'){
 95a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 95e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 962:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 966:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 96a:	00000b97          	auipc	s7,0x0
 96e:	566b8b93          	addi	s7,s7,1382 # ed0 <digits>
 972:	a839                	j	990 <vprintf+0x6a>
        putc(fd, c);
 974:	85ca                	mv	a1,s2
 976:	8556                	mv	a0,s5
 978:	00000097          	auipc	ra,0x0
 97c:	ee2080e7          	jalr	-286(ra) # 85a <putc>
 980:	a019                	j	986 <vprintf+0x60>
    } else if(state == '%'){
 982:	01498f63          	beq	s3,s4,9a0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 986:	0485                	addi	s1,s1,1
 988:	fff4c903          	lbu	s2,-1(s1)
 98c:	14090d63          	beqz	s2,ae6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 990:	0009079b          	sext.w	a5,s2
    if(state == 0){
 994:	fe0997e3          	bnez	s3,982 <vprintf+0x5c>
      if(c == '%'){
 998:	fd479ee3          	bne	a5,s4,974 <vprintf+0x4e>
        state = '%';
 99c:	89be                	mv	s3,a5
 99e:	b7e5                	j	986 <vprintf+0x60>
      if(c == 'd'){
 9a0:	05878063          	beq	a5,s8,9e0 <vprintf+0xba>
      } else if(c == 'l') {
 9a4:	05978c63          	beq	a5,s9,9fc <vprintf+0xd6>
      } else if(c == 'x') {
 9a8:	07a78863          	beq	a5,s10,a18 <vprintf+0xf2>
      } else if(c == 'p') {
 9ac:	09b78463          	beq	a5,s11,a34 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 9b0:	07300713          	li	a4,115
 9b4:	0ce78663          	beq	a5,a4,a80 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 9b8:	06300713          	li	a4,99
 9bc:	0ee78e63          	beq	a5,a4,ab8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 9c0:	11478863          	beq	a5,s4,ad0 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 9c4:	85d2                	mv	a1,s4
 9c6:	8556                	mv	a0,s5
 9c8:	00000097          	auipc	ra,0x0
 9cc:	e92080e7          	jalr	-366(ra) # 85a <putc>
        putc(fd, c);
 9d0:	85ca                	mv	a1,s2
 9d2:	8556                	mv	a0,s5
 9d4:	00000097          	auipc	ra,0x0
 9d8:	e86080e7          	jalr	-378(ra) # 85a <putc>
      }
      state = 0;
 9dc:	4981                	li	s3,0
 9de:	b765                	j	986 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 9e0:	008b0913          	addi	s2,s6,8
 9e4:	4685                	li	a3,1
 9e6:	4629                	li	a2,10
 9e8:	000b2583          	lw	a1,0(s6)
 9ec:	8556                	mv	a0,s5
 9ee:	00000097          	auipc	ra,0x0
 9f2:	e8e080e7          	jalr	-370(ra) # 87c <printint>
 9f6:	8b4a                	mv	s6,s2
      state = 0;
 9f8:	4981                	li	s3,0
 9fa:	b771                	j	986 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 9fc:	008b0913          	addi	s2,s6,8
 a00:	4681                	li	a3,0
 a02:	4629                	li	a2,10
 a04:	000b2583          	lw	a1,0(s6)
 a08:	8556                	mv	a0,s5
 a0a:	00000097          	auipc	ra,0x0
 a0e:	e72080e7          	jalr	-398(ra) # 87c <printint>
 a12:	8b4a                	mv	s6,s2
      state = 0;
 a14:	4981                	li	s3,0
 a16:	bf85                	j	986 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 a18:	008b0913          	addi	s2,s6,8
 a1c:	4681                	li	a3,0
 a1e:	4641                	li	a2,16
 a20:	000b2583          	lw	a1,0(s6)
 a24:	8556                	mv	a0,s5
 a26:	00000097          	auipc	ra,0x0
 a2a:	e56080e7          	jalr	-426(ra) # 87c <printint>
 a2e:	8b4a                	mv	s6,s2
      state = 0;
 a30:	4981                	li	s3,0
 a32:	bf91                	j	986 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 a34:	008b0793          	addi	a5,s6,8
 a38:	f8f43423          	sd	a5,-120(s0)
 a3c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 a40:	03000593          	li	a1,48
 a44:	8556                	mv	a0,s5
 a46:	00000097          	auipc	ra,0x0
 a4a:	e14080e7          	jalr	-492(ra) # 85a <putc>
  putc(fd, 'x');
 a4e:	85ea                	mv	a1,s10
 a50:	8556                	mv	a0,s5
 a52:	00000097          	auipc	ra,0x0
 a56:	e08080e7          	jalr	-504(ra) # 85a <putc>
 a5a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a5c:	03c9d793          	srli	a5,s3,0x3c
 a60:	97de                	add	a5,a5,s7
 a62:	0007c583          	lbu	a1,0(a5)
 a66:	8556                	mv	a0,s5
 a68:	00000097          	auipc	ra,0x0
 a6c:	df2080e7          	jalr	-526(ra) # 85a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a70:	0992                	slli	s3,s3,0x4
 a72:	397d                	addiw	s2,s2,-1
 a74:	fe0914e3          	bnez	s2,a5c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 a78:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 a7c:	4981                	li	s3,0
 a7e:	b721                	j	986 <vprintf+0x60>
        s = va_arg(ap, char*);
 a80:	008b0993          	addi	s3,s6,8
 a84:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 a88:	02090163          	beqz	s2,aaa <vprintf+0x184>
        while(*s != 0){
 a8c:	00094583          	lbu	a1,0(s2)
 a90:	c9a1                	beqz	a1,ae0 <vprintf+0x1ba>
          putc(fd, *s);
 a92:	8556                	mv	a0,s5
 a94:	00000097          	auipc	ra,0x0
 a98:	dc6080e7          	jalr	-570(ra) # 85a <putc>
          s++;
 a9c:	0905                	addi	s2,s2,1
        while(*s != 0){
 a9e:	00094583          	lbu	a1,0(s2)
 aa2:	f9e5                	bnez	a1,a92 <vprintf+0x16c>
        s = va_arg(ap, char*);
 aa4:	8b4e                	mv	s6,s3
      state = 0;
 aa6:	4981                	li	s3,0
 aa8:	bdf9                	j	986 <vprintf+0x60>
          s = "(null)";
 aaa:	00000917          	auipc	s2,0x0
 aae:	41e90913          	addi	s2,s2,1054 # ec8 <malloc+0x2d8>
        while(*s != 0){
 ab2:	02800593          	li	a1,40
 ab6:	bff1                	j	a92 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 ab8:	008b0913          	addi	s2,s6,8
 abc:	000b4583          	lbu	a1,0(s6)
 ac0:	8556                	mv	a0,s5
 ac2:	00000097          	auipc	ra,0x0
 ac6:	d98080e7          	jalr	-616(ra) # 85a <putc>
 aca:	8b4a                	mv	s6,s2
      state = 0;
 acc:	4981                	li	s3,0
 ace:	bd65                	j	986 <vprintf+0x60>
        putc(fd, c);
 ad0:	85d2                	mv	a1,s4
 ad2:	8556                	mv	a0,s5
 ad4:	00000097          	auipc	ra,0x0
 ad8:	d86080e7          	jalr	-634(ra) # 85a <putc>
      state = 0;
 adc:	4981                	li	s3,0
 ade:	b565                	j	986 <vprintf+0x60>
        s = va_arg(ap, char*);
 ae0:	8b4e                	mv	s6,s3
      state = 0;
 ae2:	4981                	li	s3,0
 ae4:	b54d                	j	986 <vprintf+0x60>
    }
  }
}
 ae6:	70e6                	ld	ra,120(sp)
 ae8:	7446                	ld	s0,112(sp)
 aea:	74a6                	ld	s1,104(sp)
 aec:	7906                	ld	s2,96(sp)
 aee:	69e6                	ld	s3,88(sp)
 af0:	6a46                	ld	s4,80(sp)
 af2:	6aa6                	ld	s5,72(sp)
 af4:	6b06                	ld	s6,64(sp)
 af6:	7be2                	ld	s7,56(sp)
 af8:	7c42                	ld	s8,48(sp)
 afa:	7ca2                	ld	s9,40(sp)
 afc:	7d02                	ld	s10,32(sp)
 afe:	6de2                	ld	s11,24(sp)
 b00:	6109                	addi	sp,sp,128
 b02:	8082                	ret

0000000000000b04 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b04:	715d                	addi	sp,sp,-80
 b06:	ec06                	sd	ra,24(sp)
 b08:	e822                	sd	s0,16(sp)
 b0a:	1000                	addi	s0,sp,32
 b0c:	e010                	sd	a2,0(s0)
 b0e:	e414                	sd	a3,8(s0)
 b10:	e818                	sd	a4,16(s0)
 b12:	ec1c                	sd	a5,24(s0)
 b14:	03043023          	sd	a6,32(s0)
 b18:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b1c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b20:	8622                	mv	a2,s0
 b22:	00000097          	auipc	ra,0x0
 b26:	e04080e7          	jalr	-508(ra) # 926 <vprintf>
}
 b2a:	60e2                	ld	ra,24(sp)
 b2c:	6442                	ld	s0,16(sp)
 b2e:	6161                	addi	sp,sp,80
 b30:	8082                	ret

0000000000000b32 <printf>:

void
printf(const char *fmt, ...)
{
 b32:	711d                	addi	sp,sp,-96
 b34:	ec06                	sd	ra,24(sp)
 b36:	e822                	sd	s0,16(sp)
 b38:	1000                	addi	s0,sp,32
 b3a:	e40c                	sd	a1,8(s0)
 b3c:	e810                	sd	a2,16(s0)
 b3e:	ec14                	sd	a3,24(s0)
 b40:	f018                	sd	a4,32(s0)
 b42:	f41c                	sd	a5,40(s0)
 b44:	03043823          	sd	a6,48(s0)
 b48:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b4c:	00840613          	addi	a2,s0,8
 b50:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b54:	85aa                	mv	a1,a0
 b56:	4505                	li	a0,1
 b58:	00000097          	auipc	ra,0x0
 b5c:	dce080e7          	jalr	-562(ra) # 926 <vprintf>
}
 b60:	60e2                	ld	ra,24(sp)
 b62:	6442                	ld	s0,16(sp)
 b64:	6125                	addi	sp,sp,96
 b66:	8082                	ret

0000000000000b68 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b68:	1141                	addi	sp,sp,-16
 b6a:	e422                	sd	s0,8(sp)
 b6c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b6e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b72:	00000797          	auipc	a5,0x0
 b76:	4967b783          	ld	a5,1174(a5) # 1008 <freep>
 b7a:	a805                	j	baa <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b7c:	4618                	lw	a4,8(a2)
 b7e:	9db9                	addw	a1,a1,a4
 b80:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b84:	6398                	ld	a4,0(a5)
 b86:	6318                	ld	a4,0(a4)
 b88:	fee53823          	sd	a4,-16(a0)
 b8c:	a091                	j	bd0 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b8e:	ff852703          	lw	a4,-8(a0)
 b92:	9e39                	addw	a2,a2,a4
 b94:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b96:	ff053703          	ld	a4,-16(a0)
 b9a:	e398                	sd	a4,0(a5)
 b9c:	a099                	j	be2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b9e:	6398                	ld	a4,0(a5)
 ba0:	00e7e463          	bltu	a5,a4,ba8 <free+0x40>
 ba4:	00e6ea63          	bltu	a3,a4,bb8 <free+0x50>
{
 ba8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 baa:	fed7fae3          	bgeu	a5,a3,b9e <free+0x36>
 bae:	6398                	ld	a4,0(a5)
 bb0:	00e6e463          	bltu	a3,a4,bb8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bb4:	fee7eae3          	bltu	a5,a4,ba8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 bb8:	ff852583          	lw	a1,-8(a0)
 bbc:	6390                	ld	a2,0(a5)
 bbe:	02059713          	slli	a4,a1,0x20
 bc2:	9301                	srli	a4,a4,0x20
 bc4:	0712                	slli	a4,a4,0x4
 bc6:	9736                	add	a4,a4,a3
 bc8:	fae60ae3          	beq	a2,a4,b7c <free+0x14>
    bp->s.ptr = p->s.ptr;
 bcc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 bd0:	4790                	lw	a2,8(a5)
 bd2:	02061713          	slli	a4,a2,0x20
 bd6:	9301                	srli	a4,a4,0x20
 bd8:	0712                	slli	a4,a4,0x4
 bda:	973e                	add	a4,a4,a5
 bdc:	fae689e3          	beq	a3,a4,b8e <free+0x26>
  } else
    p->s.ptr = bp;
 be0:	e394                	sd	a3,0(a5)
  freep = p;
 be2:	00000717          	auipc	a4,0x0
 be6:	42f73323          	sd	a5,1062(a4) # 1008 <freep>
}
 bea:	6422                	ld	s0,8(sp)
 bec:	0141                	addi	sp,sp,16
 bee:	8082                	ret

0000000000000bf0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 bf0:	7139                	addi	sp,sp,-64
 bf2:	fc06                	sd	ra,56(sp)
 bf4:	f822                	sd	s0,48(sp)
 bf6:	f426                	sd	s1,40(sp)
 bf8:	f04a                	sd	s2,32(sp)
 bfa:	ec4e                	sd	s3,24(sp)
 bfc:	e852                	sd	s4,16(sp)
 bfe:	e456                	sd	s5,8(sp)
 c00:	e05a                	sd	s6,0(sp)
 c02:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c04:	02051493          	slli	s1,a0,0x20
 c08:	9081                	srli	s1,s1,0x20
 c0a:	04bd                	addi	s1,s1,15
 c0c:	8091                	srli	s1,s1,0x4
 c0e:	0014899b          	addiw	s3,s1,1
 c12:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c14:	00000517          	auipc	a0,0x0
 c18:	3f453503          	ld	a0,1012(a0) # 1008 <freep>
 c1c:	c515                	beqz	a0,c48 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c1e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c20:	4798                	lw	a4,8(a5)
 c22:	02977f63          	bgeu	a4,s1,c60 <malloc+0x70>
 c26:	8a4e                	mv	s4,s3
 c28:	0009871b          	sext.w	a4,s3
 c2c:	6685                	lui	a3,0x1
 c2e:	00d77363          	bgeu	a4,a3,c34 <malloc+0x44>
 c32:	6a05                	lui	s4,0x1
 c34:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c38:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c3c:	00000917          	auipc	s2,0x0
 c40:	3cc90913          	addi	s2,s2,972 # 1008 <freep>
  if(p == (char*)-1)
 c44:	5afd                	li	s5,-1
 c46:	a88d                	j	cb8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 c48:	00004797          	auipc	a5,0x4
 c4c:	3c878793          	addi	a5,a5,968 # 5010 <base>
 c50:	00000717          	auipc	a4,0x0
 c54:	3af73c23          	sd	a5,952(a4) # 1008 <freep>
 c58:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c5a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c5e:	b7e1                	j	c26 <malloc+0x36>
      if(p->s.size == nunits)
 c60:	02e48b63          	beq	s1,a4,c96 <malloc+0xa6>
        p->s.size -= nunits;
 c64:	4137073b          	subw	a4,a4,s3
 c68:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c6a:	1702                	slli	a4,a4,0x20
 c6c:	9301                	srli	a4,a4,0x20
 c6e:	0712                	slli	a4,a4,0x4
 c70:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c72:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c76:	00000717          	auipc	a4,0x0
 c7a:	38a73923          	sd	a0,914(a4) # 1008 <freep>
      return (void*)(p + 1);
 c7e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c82:	70e2                	ld	ra,56(sp)
 c84:	7442                	ld	s0,48(sp)
 c86:	74a2                	ld	s1,40(sp)
 c88:	7902                	ld	s2,32(sp)
 c8a:	69e2                	ld	s3,24(sp)
 c8c:	6a42                	ld	s4,16(sp)
 c8e:	6aa2                	ld	s5,8(sp)
 c90:	6b02                	ld	s6,0(sp)
 c92:	6121                	addi	sp,sp,64
 c94:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c96:	6398                	ld	a4,0(a5)
 c98:	e118                	sd	a4,0(a0)
 c9a:	bff1                	j	c76 <malloc+0x86>
  hp->s.size = nu;
 c9c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 ca0:	0541                	addi	a0,a0,16
 ca2:	00000097          	auipc	ra,0x0
 ca6:	ec6080e7          	jalr	-314(ra) # b68 <free>
  return freep;
 caa:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 cae:	d971                	beqz	a0,c82 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cb0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 cb2:	4798                	lw	a4,8(a5)
 cb4:	fa9776e3          	bgeu	a4,s1,c60 <malloc+0x70>
    if(p == freep)
 cb8:	00093703          	ld	a4,0(s2)
 cbc:	853e                	mv	a0,a5
 cbe:	fef719e3          	bne	a4,a5,cb0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 cc2:	8552                	mv	a0,s4
 cc4:	00000097          	auipc	ra,0x0
 cc8:	b6e080e7          	jalr	-1170(ra) # 832 <sbrk>
  if(p == (char*)-1)
 ccc:	fd5518e3          	bne	a0,s5,c9c <malloc+0xac>
        return 0;
 cd0:	4501                	li	a0,0
 cd2:	bf45                	j	c82 <malloc+0x92>
