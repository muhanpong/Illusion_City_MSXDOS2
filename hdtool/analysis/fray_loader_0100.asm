0100: 21 5B 04           LD HL,0x45b                  ![.
0103: 11 00 E0           LD DE,0xe000                 ...
0106: 01 47 09           LD BC,0x947                  .G.
0109: ED B0              LDIR                         ..
010B: CD F0 02           CALL 0x02f0                  ...
010E: CD 15 E0           CALL 0xe015                  ...
0111: CD 5B 03           CALL 0x035b                  .[.
0114: 32 F5 E8           LD (0xe8f5),A                2..
0117: FE 11              CP 0x11                      ..
0119: 38 26              JR c,0x0141                  8&
011B: 3E 10              LD A,0x10                    >.
011D: 06 02              LD B,2                       ..
011F: CD 30 E0           CALL 0xe030                  .0.
0122: 3E 0D              LD A,13                      >.
0124: 11 00 80           LD DE,0x8000                 ...
0127: CD 0F E0           CALL 0xe00f                  ...
012A: CD 33 E0           CALL 0xe033                  .3.
012D: DD 26 10           LD IXH,0x10                  .&.
0130: FD 21 03 40        LD IY,0x4003                 .!.@
0134: CD 2D E0           CALL 0xe02d                  .-.
0137: 38 05              JR c,0x013e                  8.
0139: 3A F5 E8           LD A,(0xe8f5)                :..
013C: 18 01              JR 0x013f                    ..
013E: AF                 XOR A                        .
013F: 18 01              JR 0x0142                    ..
0141: AF                 XOR A                        .
0142: 32 8F 00           LD (0x008f),A                2..
0145: 32 F6 E8           LD (0xe8f6),A                2..
0148: CD 57 01           CALL 0x0157                  .W.
014B: CD 7F 01           CALL 0x017f                  ...
014E: CD B8 01           CALL 0x01b8                  ...
0151: CD CD 01           CALL 0x01cd                  ...
0154: C3 00 E0           JP 0xe000                    ...
0157: F3                 DI                           .
0158: 3E 80              LD A,0x80                    >.
015A: 06 10              LD B,0x10                    ..
015C: C5                 PUSH BC                      .
015D: CD 47 02           CALL 0x0247                  .G.
0160: C1                 POP BC                       .
0161: 38 03              JR c,0x0166                  8.
0163: 3C                 INC A                        <
0164: 10 F6              DJNZ 0x015c                  ..
0166: 3A 93 E7           LD A,(0xe793)                :..
0169: 57                 LD D,A                       W
016A: 21 F6 7F           LD HL,0x7ff6                 !..
016D: 1E 01              LD E,1                       ..
016F: CD 20 E1           CALL 0xe120                  . .
0172: 3A 92 E7           LD A,(0xe792)                :..
0175: EE 01              XOR 1                        ..
0177: 32 88 00           LD (0x0088),A                2..
017A: AF                 XOR A                        .
017B: 32 89 00           LD (0x0089),A                2..
017E: C9                 RET                          .
017F: F3                 DI                           .
0180: 21 52 04           LD HL,0x452                  !R.
0183: 11 38 00           LD DE,0x38                   .8.
0186: 01 03 00           LD BC,3                      ...
0189: ED B0              LDIR                         ..
018B: 21 55 04           LD HL,0x455                  !U.
018E: 11 05 00           LD DE,5                      ...
0191: 01 03 00           LD BC,3                      ...
0194: ED B0              LDIR                         ..
0196: 21 58 04           LD HL,0x458                  !X.
0199: 11 9A FD           LD DE,0xfd9a                 ...
019C: 01 05 00           LD BC,5                      ...
019F: ED B0              LDIR                         ..
01A1: AF                 XOR A                        .
01A2: CD 96 E1           CALL 0xe196                  ...
01A5: FB                 EI                           .
01A6: 2A 85 00           LD HL,(0x0085)               *..
01A9: 11 1E E6           LD DE,0xe61e                 ...
01AC: 73                 LD (HL),E                    s
01AD: 23                 INC HL                       #
01AE: 72                 LD (HL),D                    r
01AF: AF                 XOR A                        .
01B0: 32 87 00           LD (0x0087),A                2..
01B3: 3E 03              LD A,3                       >.
01B5: D3 F5              OUT (0x00f5),A               ..
01B7: C9                 RET                          .
01B8: 3E 81              LD A,0x81                    >.
01BA: F5                 PUSH AF                      .
01BB: CD 75 02           CALL 0x0275                  .u.
01BE: F1                 POP AF                       .
01BF: C6 04              ADD A,4                      ..
01C1: FE 90              CP 0x90                      ..
01C3: 38 F5              JR c,0x01ba                  8.
01C5: E6 83              AND 0x83                     ..
01C7: 3C                 INC A                        <
01C8: FE 84              CP 0x84                      ..
01CA: 38 EE              JR c,0x01ba                  8.
01CC: C9                 RET                          .
01CD: 3E 01              LD A,1                       >.
01CF: CD D8 01           CALL 0x01d8                  ...
01D2: 3C                 INC A                        <
01D3: 20 02              JR nz,0x01d7                  .
01D5: 18 FE              JR 0x01d5                    ..
01D7: C9                 RET                          .
01D8: F5                 PUSH AF                      .
01D9: C5                 PUSH BC                      .
01DA: D5                 PUSH DE                      .
01DB: E5                 PUSH HL                      .
01DC: DD E5              PUSH IX                      ..
01DE: FD E5              PUSH IY                      ..
01E0: 47                 LD B,A                       G
01E1: B7                 OR A                         .
01E2: FA 24 02           JP m,0x0224                  .$.
01E5: 28 1F              JR z,0x0206                  (.
01E7: AF                 XOR A                        .
01E8: 21 2D 00           LD HL,0x2d                   !-.
01EB: CD 0C 00           CALL 0x000c                  ...
01EE: FE 03              CP 3                         ..
01F0: 38 10              JR c,0x0202                  8.
01F2: 3E 81              LD A,0x81                    >.
01F4: FD 26 00           LD IYH,0                     .&.
01F7: DD 21 80 01        LD IX,0x180                  .!..
01FB: CD 1C 00           CALL 0x001c                  ...
01FE: 3E 01              LD A,1                       >.
0200: 18 02              JR 0x0204                    ..
0202: 3E FF              LD A,0xff                    >.
0204: 18 1C              JR 0x0222                    ..
0206: AF                 XOR A                        .
0207: 21 2D 00           LD HL,0x2d                   !-.
020A: CD 0C 00           CALL 0x000c                  ...
020D: FE 03              CP 3                         ..
020F: 38 10              JR c,0x0221                  8.
0211: 3E 80              LD A,0x80                    >.
0213: FD 26 00           LD IYH,0                     .&.
0216: DD 21 80 01        LD IX,0x180                  .!..
021A: CD 1C 00           CALL 0x001c                  ...
021D: AF                 XOR A                        .
021E: 32 A7 00           LD (0x00a7),A                2..
0221: AF                 XOR A                        .
0222: 18 1A              JR 0x023e                    ..
0224: AF                 XOR A                        .
0225: 21 2D 00           LD HL,0x2d                   !-.
0228: CD 0C 00           CALL 0x000c                  ...
022B: FE 03              CP 3                         ..
022D: 38 0E              JR c,0x023d                  8.
022F: 3E 80              LD A,0x80                    >.
0231: FD 26 00           LD IYH,0                     .&.
0234: DD 21 83 01        LD IX,0x183                  .!..
0238: CD 1C 00           CALL 0x001c                  ...
023B: 18 01              JR 0x023e                    ..
023D: AF                 XOR A                        .
023E: FD E1              POP IY                       ..
0240: DD E1              POP IX                       ..
0242: E1                 POP HL                       .
0243: D1                 POP DE                       .
0244: C1                 POP BC                       .
0245: F1                 POP AF                       .
0246: C9                 RET                          .
0247: 57                 LD D,A                       W
0248: 21 1C 40           LD HL,0x401c                 !.@
024B: CD 17 E1           CALL 0xe117                  ...
024E: EE 4F              XOR 0x4f                     .O
0250: 7A                 LD A,D                       z
0251: C0                 RET nz                       .
0252: 23                 INC HL                       #
0253: CD 17 E1           CALL 0xe117                  ...
0256: EE 50              XOR 0x50                     .P
0258: 7A                 LD A,D                       z
0259: C0                 RET nz                       .
025A: 23                 INC HL                       #
025B: CD 17 E1           CALL 0xe117                  ...
025E: EE 4C              XOR 0x4c                     .L
0260: 7A                 LD A,D                       z
0261: C0                 RET nz                       .
0262: 23                 INC HL                       #
0263: CD 17 E1           CALL 0xe117                  ...
0266: EE 4C              XOR 0x4c                     .L
0268: 7A                 LD A,D                       z
0269: C0                 RET nz                       .
026A: AF                 XOR A                        .
026B: 32 92 E7           LD (0xe792),A                2..
026E: 7A                 LD A,D                       z
026F: 32 93 E7           LD (0xe793),A                2..
0272: 7A                 LD A,D                       z
0273: 37                 SCF                          7
0274: C9                 RET                          .
0275: 57                 LD D,A                       W
0276: 21 00 40           LD HL,0x4000                 !.@
0279: CD 17 E1           CALL 0xe117                  ...
027C: 4F                 LD C,A                       O
027D: 23                 INC HL                       #
027E: CD 17 E1           CALL 0xe117                  ...
0281: 47                 LD B,A                       G
0282: ED 43 EE 02        LD (0x02ee),BC               .C..
0286: 7A                 LD A,D                       z
0287: 21 FE 5F           LD HL,0x5ffe                 !._
028A: 1E 4D              LD E,0x4d                    .M
028C: CD 20 E1           CALL 0xe120                  . .
028F: 23                 INC HL                       #
0290: 1E 69              LD E,0x69                    .i
0292: CD 20 E1           CALL 0xe120                  . .
0295: 21 00 40           LD HL,0x4000                 !.@
0298: CD 17 E1           CALL 0xe117                  ...
029B: 4F                 LD C,A                       O
029C: 23                 INC HL                       #
029D: CD 17 E1           CALL 0xe117                  ...
02A0: 47                 LD B,A                       G
02A1: 2A EE 02           LD HL,(0x02ee)               *..
02A4: B7                 OR A                         .
02A5: ED 42              SBC HL,BC                    .B
02A7: C8                 RET z                        .
02A8: 21 00 40           LD HL,0x4000                 !.@
02AB: CD 17 E1           CALL 0xe117                  ...
02AE: 4F                 LD C,A                       O
02AF: 79                 LD A,C                       y
02B0: 2F                 CPL                          /
02B1: 5F                 LD E,A                       _
02B2: 7A                 LD A,D                       z
02B3: 21 00 40           LD HL,0x4000                 !.@
02B6: CD 20 E1           CALL 0xe120                  . .
02B9: 21 00 40           LD HL,0x4000                 !.@
02BC: CD 17 E1           CALL 0xe117                  ...
02BF: BB                 CP E                         .
02C0: C0                 RET nz                       .
02C1: 59                 LD E,C                       Y
02C2: 7A                 LD A,D                       z
02C3: 21 00 40           LD HL,0x4000                 !.@
02C6: CD 20 E1           CALL 0xe120                  . .
02C9: 21 FE 5F           LD HL,0x5ffe                 !._
02CC: 7A                 LD A,D                       z
02CD: 1E 00              LD E,0                       ..
02CF: CD 20 E1           CALL 0xe120                  . .
02D2: 23                 INC HL                       #
02D3: 7A                 LD A,D                       z
02D4: 1E 00              LD E,0                       ..
02D6: CD 20 E1           CALL 0xe120                  . .
02D9: 21 00 40           LD HL,0x4000                 !.@
02DC: ED 4B EE 02        LD BC,(0x02ee)               .K..
02E0: 59                 LD E,C                       Y
02E1: 7A                 LD A,D                       z
02E2: CD 20 E1           CALL 0xe120                  . .
02E5: 7A                 LD A,D                       z
02E6: 32 91 E7           LD (0xe791),A                2..
02E9: AF                 XOR A                        .
02EA: 32 90 E7           LD (0xe790),A                2..
02ED: C9                 RET                          .
02EE: 00                 NOP                          .
02EF: 00                 NOP                          .
02F0: 3E 22              LD A,0x22                    >"
02F2: 0E 99              LD C,0x99                    ..
02F4: ED 79              OUT (C),A                    .y
02F6: 3E 81              LD A,0x81                    >.
02F8: ED 79              OUT (C),A                    .y
02FA: 3E 0A              LD A,10                      >.
02FC: 0E 99              LD C,0x99                    ..
02FE: ED 79              OUT (C),A                    .y
0300: 3E 88              LD A,0x88                    >.
0302: ED 79              OUT (C),A                    .y
0304: 3E 06              LD A,6                       >.
0306: 0E 99              LD C,0x99                    ..
0308: ED 79              OUT (C),A                    .y
030A: 3E 80              LD A,0x80                    >.
030C: ED 79              OUT (C),A                    .y
030E: 3E 1F              LD A,0x1f                    >.
0310: 0E 99              LD C,0x99                    ..
0312: ED 79              OUT (C),A                    .y
0314: 3E 82              LD A,0x82                    >.
0316: ED 79              OUT (C),A                    .y
0318: 3E 00              LD A,0                       >.
031A: 0E 99              LD C,0x99                    ..
031C: ED 79              OUT (C),A                    .y
031E: 3E 89              LD A,0x89                    >.
0320: ED 79              OUT (C),A                    .y
0322: 3E 01              LD A,1                       >.
0324: 0E 99              LD C,0x99                    ..
0326: ED 79              OUT (C),A                    .y
0328: 3E 87              LD A,0x87                    >.
032A: ED 79              OUT (C),A                    .y
032C: 21 BD E7           LD HL,0xe7bd                 !..
032F: 11 BE E7           LD DE,0xe7be                 ...
0332: 01 1F 00           LD BC,0x1f                   ...
0335: 36 00              LD (HL),0                    6.
0337: ED B0              LDIR                         ..
0339: 3E 00              LD A,0                       >.
033B: 0E 99              LD C,0x99                    ..
033D: ED 79              OUT (C),A                    .y
033F: 3E 90              LD A,0x90                    >.
0341: ED 79              OUT (C),A                    .y
0343: 3A 84 00           LD A,(0x0084)                :..
0346: 3C                 INC A                        <
0347: 3C                 INC A                        <
0348: 4F                 LD C,A                       O
0349: 21 BD E7           LD HL,0xe7bd                 !..
034C: 06 20              LD B,0x20                    . 
034E: ED B3              OTIR                         ..
0350: 3E 62              LD A,0x62                    >b
0352: 0E 99              LD C,0x99                    ..
0354: ED 79              OUT (C),A                    .y
0356: 3E 81              LD A,0x81                    >.
0358: ED 79              OUT (C),A                    .y
035A: C9                 RET                          .
