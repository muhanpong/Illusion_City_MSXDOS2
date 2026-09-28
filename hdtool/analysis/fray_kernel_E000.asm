E000: C3 4B E0           JP 0xe04b                    .K.
E003: C3 8A E0           JP 0xe08a                    ...
E006: C3 8E E0           JP 0xe08e                    ...
E009: C3 97 E0           JP 0xe097                    ...
E00C: C3 DC E0           JP 0xe0dc                    ...
E00F: C3 2A E1           JP 0xe12a                    .*.
E012: C3 96 E1           JP 0xe196                    ...
E015: C3 35 E1           JP 0xe135                    .5.
E018: C3 53 E1           JP 0xe153                    .S.
E01B: C3 68 E1           JP 0xe168                    .h.
E01E: C3 A2 E1           JP 0xe1a2                    ...
E021: C3 A8 E1           JP 0xe1a8                    ...
E024: C3 B3 E1           JP 0xe1b3                    ...
E027: C3 FA E1           JP 0xe1fa                    ...
E02A: C3 19 E2           JP 0xe219                    ...
E02D: C3 24 E2           JP 0xe224                    .$.
E030: C3 46 E2           JP 0xe246                    .F.
E033: C3 4B E2           JP 0xe24b                    .K.
E036: C3 A9 E2           JP 0xe2a9                    ...
E039: C3 B0 E2           JP 0xe2b0                    ...
E03C: C3 DD E2           JP 0xe2dd                    ...
E03F: C3 F5 E2           JP 0xe2f5                    ...
E042: C3 23 E6           JP 0xe623                    .#.
E045: C3 F9 E5           JP 0xe5f9                    ...
E048: C3 0B E6           JP 0xe60b                    ...
E04B: 3A 81 00           LD A,(0x0081)                :..
E04E: 5F                 LD E,A                       _
E04F: 16 00              LD D,0                       ..
E051: 21 08 E9           LD HL,0xe908                 !..
E054: 19                 ADD HL,DE                    .
E055: 19                 ADD HL,DE                    .
E056: 19                 ADD HL,DE                    .
E057: 7E                 LD A,(HL)                    ~
E058: E5                 PUSH HL                      .
E059: CD 18 E0           CALL 0xe018                  ...
E05C: E1                 POP HL                       .
E05D: 23                 INC HL                       #
E05E: 5E                 LD E,(HL)                    ^
E05F: 23                 INC HL                       #
E060: 56                 LD D,(HL)                    V
E061: ED 53 88 E7        LD (0xe788),DE               .S..
E065: 3E 03              LD A,3                       >.
E067: 06 00              LD B,0                       ..
E069: CD 46 E2           CALL 0xe246                  .F.
E06C: 3E 02              LD A,2                       >.
E06E: 06 01              LD B,1                       ..
E070: CD 46 E2           CALL 0xe246                  .F.
E073: 3E 01              LD A,1                       >.
E075: 06 02              LD B,2                       ..
E077: CD 46 E2           CALL 0xe246                  .F.
E07A: 3E FF              LD A,0xff                    >.
E07C: ED 5B 88 E7        LD DE,(0xe788)               .[..
E080: CD 1B E0           CALL 0xe01b                  ...
E083: 2A 88 E7           LD HL,(0xe788)               *..
E086: 31 F8 FA           LD SP,0xfaf8                 1..
E089: E9                 JP (HL)                      .
E08A: 2A 8A E7           LD HL,(0xe78a)               *..
E08D: C9                 RET                          .
E08E: E5                 PUSH HL                      .
E08F: 21 00 00           LD HL,0                      !..
E092: 22 8A E7           LD (0xe78a),HL               "..
E095: E1                 POP HL                       .
E096: C9                 RET                          .
E097: C5                 PUSH BC                      .
E098: D5                 PUSH DE                      .
E099: E5                 PUSH HL                      .
E09A: 47                 LD B,A                       G
E09B: 3A 90 E7           LD A,(0xe790)                :..
E09E: B7                 OR A                         .
E09F: 20 36              JR nz,0xe0d7                  6
E0A1: C5                 PUSH BC                      .
E0A2: EB                 EX DE,HL                     .
E0A3: 11 F8 F7           LD DE,0xf7f8                 ...
E0A6: 01 06 00           LD BC,6                      ...
E0A9: ED B0              LDIR                         ..
E0AB: 3A 91 E7           LD A,(0xe791)                :..
E0AE: 21 00 40           LD HL,0x4000                 !.@
E0B1: CD 24 00           CALL 0x0024                  .$.
E0B4: 21 FE 5F           LD HL,0x5ffe                 !._
E0B7: 36 4D              LD (HL),0x4d                 6M
E0B9: 23                 INC HL                       #
E0BA: 36 69              LD (HL),0x69                 6i
E0BC: F1                 POP AF                       .
E0BD: 21 00 40           LD HL,0x4000                 !.@
E0C0: 87                 ADD A,A                      .
E0C1: 87                 ADD A,A                      .
E0C2: 84                 ADD A,H                      .
E0C3: 67                 LD H,A                       g
E0C4: EB                 EX DE,HL                     .
E0C5: 21 00 F4           LD HL,0xf400                 !..
E0C8: 01 FE 03           LD BC,0x3fe                  ...
E0CB: ED B0              LDIR                         ..
E0CD: 3A 42 F3           LD A,(0xf342)                :B.
E0D0: 21 00 40           LD HL,0x4000                 !.@
E0D3: CD 24 00           CALL 0x0024                  .$.
E0D6: AF                 XOR A                        .
E0D7: E1                 POP HL                       .
E0D8: D1                 POP DE                       .
E0D9: C1                 POP BC                       .
E0DA: FB                 EI                           .
E0DB: C9                 RET                          .
E0DC: C5                 PUSH BC                      .
E0DD: D5                 PUSH DE                      .
E0DE: E5                 PUSH HL                      .
E0DF: 47                 LD B,A                       G
E0E0: 3A 90 E7           LD A,(0xe790)                :..
E0E3: B7                 OR A                         .
E0E4: 20 2C              JR nz,0xe112                  ,
E0E6: C5                 PUSH BC                      .
E0E7: 3A 91 E7           LD A,(0xe791)                :..
E0EA: 21 00 40           LD HL,0x4000                 !.@
E0ED: CD 24 00           CALL 0x0024                  .$.
E0F0: 21 FE 5F           LD HL,0x5ffe                 !._
E0F3: 36 4D              LD (HL),0x4d                 6M
E0F5: 23                 INC HL                       #
E0F6: 36 69              LD (HL),0x69                 6i
E0F8: F1                 POP AF                       .
E0F9: 21 00 40           LD HL,0x4000                 !.@
E0FC: 87                 ADD A,A                      .
E0FD: 87                 ADD A,A                      .
E0FE: 84                 ADD A,H                      .
E0FF: 67                 LD H,A                       g
E100: 11 00 F4           LD DE,0xf400                 ...
E103: 01 FE 03           LD BC,0x3fe                  ...
E106: ED B0              LDIR                         ..
E108: 3A 42 F3           LD A,(0xf342)                :B.
E10B: 21 00 40           LD HL,0x4000                 !.@
E10E: CD 24 00           CALL 0x0024                  .$.
E111: AF                 XOR A                        .
E112: E1                 POP HL                       .
E113: D1                 POP DE                       .
E114: C1                 POP BC                       .
E115: FB                 EI                           .
E116: C9                 RET                          .
E117: 7A                 LD A,D                       z
E118: C5                 PUSH BC                      .
E119: D5                 PUSH DE                      .
E11A: CD 0C 00           CALL 0x000c                  ...
E11D: D1                 POP DE                       .
E11E: C1                 POP BC                       .
E11F: C9                 RET                          .
E120: F5                 PUSH AF                      .
E121: C5                 PUSH BC                      .
E122: D5                 PUSH DE                      .
E123: CD 14 00           CALL 0x0014                  ...
E126: D1                 POP DE                       .
E127: C1                 POP BC                       .
E128: F1                 POP AF                       .
E129: C9                 RET                          .
E12A: D5                 PUSH DE                      .
E12B: CD 53 E1           CALL 0xe153                  .S.
E12E: D1                 POP DE                       .
E12F: 3E FF              LD A,0xff                    >.
E131: CD 68 E1           CALL 0xe168                  .h.
E134: C9                 RET                          .
E135: 0E 1A              LD C,0x1a                    ..
E137: 11 00 EA           LD DE,0xea00                 ...
E13A: CD 7D F3           CALL 0xf37d                  .}.
E13D: 21 00 01           LD HL,0x100                  !..
E140: 11 0B 00           LD DE,11                     ...
E143: 0E 2F              LD C,0x2f                    ./
E145: CD 7D F3           CALL 0xf37d                  .}.
E148: AF                 XOR A                        .
E149: 32 94 E7           LD (0xe794),A                2..
E14C: 32 95 E7           LD (0xe795),A                2..
E14F: 32 96 E7           LD (0xe796),A                2..
E152: C9                 RET                          .
E153: 5F                 LD E,A                       _
E154: 16 00              LD D,0                       ..
E156: 21 00 EA           LD HL,0xea00                 !..
E159: 19                 ADD HL,DE                    .
E15A: 19                 ADD HL,DE                    .
E15B: 5E                 LD E,(HL)                    ^
E15C: 16 00              LD D,0                       ..
E15E: 23                 INC HL                       #
E15F: ED 53 94 E7        LD (0xe794),DE               .S..
E163: 7E                 LD A,(HL)                    ~
E164: 32 96 E7           LD (0xe796),A                2..
E167: C9                 RET                          .
E168: F5                 PUSH AF                      .
E169: 0E 1A              LD C,0x1a                    ..
E16B: CD 7D F3           CALL 0xf37d                  .}.
E16E: E1                 POP HL                       .
E16F: 3A 96 E7           LD A,(0xe796)                :..
E172: B7                 OR A                         .
E173: 3F                 CCF                          ?
E174: C8                 RET z                        .
E175: BC                 CP H                         .
E176: 30 01              JR nc,0xe179                 0.
E178: 67                 LD H,A                       g
E179: 94                 SUB H                        .
E17A: 32 96 E7           LD (0xe796),A                2..
E17D: ED 5B 94 E7        LD DE,(0xe794)               .[..
E181: 7B                 LD A,E                       {
E182: 84                 ADD A,H                      .
E183: 4F                 LD C,A                       O
E184: 7A                 LD A,D                       z
E185: CE 00              ADC A,0                      ..
E187: 47                 LD B,A                       G
E188: ED 43 94 E7        LD (0xe794),BC               .C..
E18C: 2E 00              LD L,0                       ..
E18E: 0E 2F              LD C,0x2f                    ./
E190: CD 7D F3           CALL 0xf37d                  .}.
E193: FB                 EI                           .
E194: B7                 OR A                         .
E195: C9                 RET                          .
E196: F3                 DI                           .
E197: 22 8C E7           LD (0xe78c),HL               "..
E19A: 32 8E E7           LD (0xe78e),A                2..
E19D: 32 8F E7           LD (0xe78f),A                2..
E1A0: FB                 EI                           .
E1A1: C9                 RET                          .
E1A2: F3                 DI                           .
E1A3: 32 98 E7           LD (0xe798),A                2..
E1A6: FB                 EI                           .
E1A7: C9                 RET                          .
E1A8: E5                 PUSH HL                      .
E1A9: 2A 97 E7           LD HL,(0xe797)               *..
E1AC: 7C                 LD A,H                       |
E1AD: AD                 XOR L                        .
E1AE: 7C                 LD A,H                       |
E1AF: E1                 POP HL                       .
E1B0: C8                 RET z                        .
E1B1: 37                 SCF                          7
E1B2: C9                 RET                          .
E1B3: 3A 9C E7           LD A,(0xe79c)                :..
E1B6: B7                 OR A                         .
E1B7: 28 22              JR z,0xe1db                  ("
E1B9: F3                 DI                           .
E1BA: 11 BD E7           LD DE,0xe7bd                 ...
E1BD: 01 20 00           LD BC,0x20                   . .
E1C0: ED B0              LDIR                         ..
E1C2: 3E 00              LD A,0                       >.
E1C4: 0E 99              LD C,0x99                    ..
E1C6: ED 79              OUT (C),A                    .y
E1C8: 3E 90              LD A,0x90                    >.
E1CA: ED 79              OUT (C),A                    .y
E1CC: 3A 84 00           LD A,(0x0084)                :..
E1CF: 3C                 INC A                        <
E1D0: 3C                 INC A                        <
E1D1: 4F                 LD C,A                       O
E1D2: 21 BD E7           LD HL,0xe7bd                 !..
E1D5: 06 20              LD B,0x20                    . 
E1D7: ED B3              OTIR                         ..
E1D9: FB                 EI                           .
E1DA: C9                 RET                          .
E1DB: F5                 PUSH AF                      .
E1DC: 3A 99 E7           LD A,(0xe799)                :..
E1DF: B7                 OR A                         .
E1E0: 20 FA              JR nz,0xe1dc                  .
E1E2: F1                 POP AF                       .
E1E3: F3                 DI                           .
E1E4: 11 9D E7           LD DE,0xe79d                 ...
E1E7: 01 20 00           LD BC,0x20                   . .
E1EA: ED B0              LDIR                         ..
E1EC: 2E 01              LD L,1                       ..
E1EE: 26 07              LD H,7                       &.
E1F0: 22 99 E7           LD (0xe799),HL               "..
E1F3: 3E 01              LD A,1                       >.
E1F5: 32 9C E7           LD (0xe79c),A                2..
E1F8: FB                 EI                           .
E1F9: C9                 RET                          .
E1FA: 3A 9C E7           LD A,(0xe79c)                :..
E1FD: B7                 OR A                         .
E1FE: C8                 RET z                        .
E1FF: F5                 PUSH AF                      .
E200: 3A 99 E7           LD A,(0xe799)                :..
E203: B7                 OR A                         .
E204: 20 FA              JR nz,0xe200                  .
E206: F1                 POP AF                       .
E207: F3                 DI                           .
E208: 2E 02              LD L,2                       ..
E20A: 26 07              LD H,7                       &.
E20C: 22 99 E7           LD (0xe799),HL               "..
E20F: FB                 EI                           .
E210: AF                 XOR A                        .
E211: 32 9C E7           LD (0xe79c),A                2..
E214: AF                 XOR A                        .
E215: 32 DE E7           LD (0xe7de),A                2..
E218: C9                 RET                          .
E219: 3A 9C E7           LD A,(0xe79c)                :..
E21C: B7                 OR A                         .
E21D: 20 01              JR nz,0xe220                  .
E21F: 37                 SCF                          7
E220: 3A 99 E7           LD A,(0xe799)                :..
E223: C9                 RET                          .
E224: E5                 PUSH HL                      .
E225: D5                 PUSH DE                      .
E226: C5                 PUSH BC                      .
E227: F5                 PUSH AF                      .
E228: DD 7C              LD A,IXH                     .|
E22A: 21 F7 E8           LD HL,0xe8f7                 !..
E22D: 5F                 LD E,A                       _
E22E: 16 00              LD D,0                       ..
E230: 19                 ADD HL,DE                    .
E231: 46                 LD B,(HL)                    F
E232: CD 46 E2           CALL 0xe246                  .F.
E235: DD E1              POP IX                       ..
E237: F1                 POP AF                       .
E238: C1                 POP BC                       .
E239: D1                 POP DE                       .
E23A: E1                 POP HL                       .
E23B: DD E5              PUSH IX                      ..
E23D: CD 44 E2           CALL 0xe244                  .D.
E240: CD 4B E2           CALL 0xe24b                  .K.
E243: C9                 RET                          .
E244: FD E9              JP (IY)                      ..
E246: CD 5B E2           CALL 0xe25b                  .[.
E249: E3                 EX (SP),HL                   .
E24A: E9                 JP (HL)                      .
E24B: E1                 POP HL                       .
E24C: D1                 POP DE                       .
E24D: E5                 PUSH HL                      .
E24E: F5                 PUSH AF                      .
E24F: C5                 PUSH BC                      .
E250: D5                 PUSH DE                      .
E251: 4B                 LD C,E                       K
E252: 42                 LD B,D                       B
E253: 79                 LD A,C                       y
E254: CD 5B E2           CALL 0xe25b                  .[.
E257: D1                 POP DE                       .
E258: C1                 POP BC                       .
E259: F1                 POP AF                       .
E25A: C9                 RET                          .
E25B: 58                 LD E,B                       X
E25C: 16 00              LD D,0                       ..
E25E: 21 EB E8           LD HL,0xe8eb                 !..
E261: 19                 ADD HL,DE                    .
E262: 19                 ADD HL,DE                    .
E263: 4E                 LD C,(HL)                    N
E264: 77                 LD (HL),A                    w
E265: 23                 INC HL                       #
E266: 5F                 LD E,A                       _
E267: 3A F3 E8           LD A,(0xe8f3)                :..
E26A: 57                 LD D,A                       W
E26B: 7B                 LD A,E                       {
E26C: 92                 SUB D                        .
E26D: 57                 LD D,A                       W
E26E: 3E 83              LD A,0x83                    >.
E270: 38 04              JR c,0xe276                  8.
E272: 5A                 LD E,D                       Z
E273: 3A F4 E8           LD A,(0xe8f4)                :..
E276: BE                 CP (HL)                      .
E277: F3                 DI                           .
E278: 77                 LD (HL),A                    w
E279: 28 24              JR z,0xe29f                  ($
E27B: 60                 LD H,B                       `
E27C: CB 0C              RRC H                        ..
E27E: CB 0C              RRC H                        ..
E280: 08                 EX AF,AF'                    .
E281: D9                 EXX                          .
E282: F5                 PUSH AF                      .
E283: C5                 PUSH BC                      .
E284: D5                 PUSH DE                      .
E285: E5                 PUSH HL                      .
E286: D9                 EXX                          .
E287: 08                 EX AF,AF'                    .
E288: C5                 PUSH BC                      .
E289: D5                 PUSH DE                      .
E28A: DD E5              PUSH IX                      ..
E28C: FD E5              PUSH IY                      ..
E28E: CD 24 00           CALL 0x0024                  .$.
E291: FD E1              POP IY                       ..
E293: DD E1              POP IX                       ..
E295: D1                 POP DE                       .
E296: C1                 POP BC                       .
E297: 08                 EX AF,AF'                    .
E298: D9                 EXX                          .
E299: E1                 POP HL                       .
E29A: D1                 POP DE                       .
E29B: C1                 POP BC                       .
E29C: F1                 POP AF                       .
E29D: D9                 EXX                          .
E29E: 08                 EX AF,AF'                    .
E29F: FB                 EI                           .
E2A0: 69                 LD L,C                       i
E2A1: 60                 LD H,B                       `
E2A2: 78                 LD A,B                       x
E2A3: C6 FC              ADD A,0xfc                   ..
E2A5: 4F                 LD C,A                       O
E2A6: ED 59              OUT (C),E                    .Y
E2A8: C9                 RET                          .
E2A9: F5                 PUSH AF                      .
E2AA: AF                 XOR A                        .
E2AB: 32 E0 E8           LD (0xe8e0),A                2..
E2AE: F1                 POP AF                       .
E2AF: C9                 RET                          .
E2B0: AF                 XOR A                        .
E2B1: 32 E0 E8           LD (0xe8e0),A                2..
E2B4: 7C                 LD A,H                       |
E2B5: A5                 AND L                        .
E2B6: 3C                 INC A                        <
E2B7: 28 03              JR z,0xe2bc                  (.
E2B9: 22 E2 E8           LD (0xe8e2),HL               "..
E2BC: 3E 01              LD A,1                       >.
E2BE: 32 E0 E8           LD (0xe8e0),A                2..
E2C1: 7C                 LD A,H                       |
E2C2: B5                 OR L                         .
E2C3: 20 12              JR nz,0xe2d7                  .
E2C5: AF                 XOR A                        .
E2C6: 32 E8 E8           LD (0xe8e8),A                2..
E2C9: 06 11              LD B,0x11                    ..
E2CB: C5                 PUSH BC                      .
E2CC: CD 32 E4           CALL 0xe432                  .2.
E2CF: C1                 POP BC                       .
E2D0: 10 F9              DJNZ 0xe2cb                  ..
E2D2: 3A E0 E8           LD A,(0xe8e0)                :..
E2D5: B7                 OR A                         .
E2D6: C8                 RET z                        .
E2D7: 3E 01              LD A,1                       >.
E2D9: 32 E0 E8           LD (0xe8e0),A                2..
E2DC: C9                 RET                          .
E2DD: F3                 DI                           .
E2DE: 21 E9 E8           LD HL,0xe8e9                 !..
E2E1: 4E                 LD C,(HL)                    N
E2E2: 23                 INC HL                       #
E2E3: 36 00              LD (HL),0                    6.
E2E5: 21 E4 E8           LD HL,0xe8e4                 !..
E2E8: 7E                 LD A,(HL)                    ~
E2E9: 23                 INC HL                       #
E2EA: 36 00              LD (HL),0                    6.
E2EC: 2A E0 E8           LD HL,(0xe8e0)               *..
E2EF: B5                 OR L                         .
E2F0: 2A E2 E8           LD HL,(0xe8e2)               *..
E2F3: FB                 EI                           .
E2F4: C9                 RET                          .
E2F5: B7                 OR A                         .
E2F6: 20 05              JR nz,0xe2fd                  .
E2F8: AF                 XOR A                        .
E2F9: 32 DE E7           LD (0xe7de),A                2..
E2FC: C9                 RET                          .
E2FD: F3                 DI                           .
E2FE: DD E5              PUSH IX                      ..
E300: D5                 PUSH DE                      .
E301: 11 20 E8           LD DE,0xe820                 . .
E304: 01 40 00           LD BC,0x40                   .@.
E307: ED B0              LDIR                         ..
E309: 11 80 E8           LD DE,0xe880                 ...
E30C: 01 40 00           LD BC,0x40                   .@.
E30F: ED B0              LDIR                         ..
E311: E1                 POP HL                       .
E312: 11 60 E8           LD DE,0xe860                 .`.
E315: 01 20 00           LD BC,0x20                   . .
E318: ED B0              LDIR                         ..
E31A: 06 10              LD B,0x10                    ..
E31C: DD 21 20 E8        LD IX,0xe820                 .! .
E320: DD 7E 00           LD A,(IX)                    .~.
E323: DD 77 01           LD (IX+1),A                  .w.
E326: DD 36 C1 08        LD (IX-0x3f),8               .6..
E32A: DD 36 C0 00        LD (IX-0x40),0               .6..
E32E: 11 04 00           LD DE,4                      ...
E331: DD 19              ADD IX,DE                    ..
E333: 10 EB              DJNZ 0xe320                  ..
E335: 3E 01              LD A,1                       >.
E337: 32 DE E7           LD (0xe7de),A                2..
E33A: DD E1              POP IX                       ..
E33C: FB                 EI                           .
E33D: C9                 RET                          .
E33E: AF                 XOR A                        .
E33F: 32 DF E7           LD (0xe7df),A                2..
E342: 06 10              LD B,0x10                    ..
E344: DD 21 20 E8        LD IX,0xe820                 .! .
E348: C5                 PUSH BC                      .
E349: DD 7E 01           LD A,(IX+1)                  .~.
E34C: B7                 OR A                         .
E34D: CA D8 E3           JP z,0xe3d8                  ...
E350: 3D                 DEC A                        =
E351: DD 77 01           LD (IX+1),A                  .w.
E354: B7                 OR A                         .
E355: C2 D8 E3           JP nz,0xe3d8                 ...
E358: DD 7E 00           LD A,(IX)                    .~.
E35B: DD 77 01           LD (IX+1),A                  .w.
E35E: 3E 10              LD A,0x10                    >.
E360: 90                 SUB B                        .
E361: 87                 ADD A,A                      .
E362: 4F                 LD C,A                       O
E363: 06 00              LD B,0                       ..
E365: DD 35 C1           DEC (IX-0x3f)                .5.
E368: C2 94 E3           JP nz,0xe394                 ...
E36B: DD 36 C1 08        LD (IX-0x3f),8               .6..
E36F: DD 7E C0           LD A,(IX-0x40)               .~.
E372: 3C                 INC A                        <
E373: DD BE 03           CP (IX+3)                    ...
E376: DA 7A E3           JP c,0xe37a                  .z.
E379: AF                 XOR A                        .
E37A: DD 77 C0           LD (IX-0x40),A               .w.
E37D: 87                 ADD A,A                      .
E37E: 87                 ADD A,A                      .
E37F: 87                 ADD A,A                      .
E380: 87                 ADD A,A                      .
E381: 87                 ADD A,A                      .
E382: 5F                 LD E,A                       _
E383: 16 00              LD D,0                       ..
E385: 21 60 E8           LD HL,0xe860                 !`.
E388: 19                 ADD HL,DE                    .
E389: 09                 ADD HL,BC                    .
E38A: 5E                 LD E,(HL)                    ^
E38B: 23                 INC HL                       #
E38C: 56                 LD D,(HL)                    V
E38D: 21 9D E7           LD HL,0xe79d                 !..
E390: 09                 ADD HL,BC                    .
E391: 73                 LD (HL),E                    s
E392: 23                 INC HL                       #
E393: 72                 LD (HL),D                    r
E394: 21 BD E7           LD HL,0xe7bd                 !..
E397: 09                 ADD HL,BC                    .
E398: FD 21 9D E7        LD IY,0xe79d                 .!..
E39C: FD 09              ADD IY,BC                    ..
E39E: 06 02              LD B,2                       ..
E3A0: 56                 LD D,(HL)                    V
E3A1: FD 5E 00           LD E,(IY)                    .^.
E3A4: 0E 02              LD C,2                       ..
E3A6: 7B                 LD A,E                       {
E3A7: E6 0F              AND 15                       ..
E3A9: 92                 SUB D                        .
E3AA: E6 0F              AND 15                       ..
E3AC: CA B9 E3           JP z,0xe3b9                  ...
E3AF: CB 5F              BIT 3,A                      ._
E3B1: C2 B8 E3           JP nz,0xe3b8                 ...
E3B4: 14                 INC D                        .
E3B5: C3 B9 E3           JP 0xe3b9                    ...
E3B8: 15                 DEC D                        .
E3B9: CB 02              RLC D                        ..
E3BB: CB 02              RLC D                        ..
E3BD: CB 02              RLC D                        ..
E3BF: CB 02              RLC D                        ..
E3C1: CB 03              RLC E                        ..
E3C3: CB 03              RLC E                        ..
E3C5: CB 03              RLC E                        ..
E3C7: CB 03              RLC E                        ..
E3C9: 0D                 DEC C                        .
E3CA: C2 A6 E3           JP nz,0xe3a6                 ...
E3CD: 72                 LD (HL),D                    r
E3CE: 23                 INC HL                       #
E3CF: FD 23              INC IY                       .#
E3D1: 10 CD              DJNZ 0xe3a0                  ..
E3D3: 3E 01              LD A,1                       >.
E3D5: 32 DF E7           LD (0xe7df),A                2..
E3D8: 01 04 00           LD BC,4                      ...
E3DB: DD 09              ADD IX,BC                    ..
E3DD: C1                 POP BC                       .
E3DE: 05                 DEC B                        .
E3DF: C2 48 E3           JP nz,0xe348                 .H.
E3E2: 3A DF E7           LD A,(0xe7df)                :..
E3E5: B7                 OR A                         .
E3E6: C4 E0 E5           CALL nz,0xe5e0               ...
E3E9: C9                 RET                          .
E3EA: 21 E1 E8           LD HL,0xe8e1                 !..
E3ED: 7E                 LD A,(HL)                    ~
E3EE: 3C                 INC A                        <
E3EF: 77                 LD (HL),A                    w
E3F0: E6 01              AND 1                        ..
E3F2: 28 2C              JR z,0xe420                  (,
E3F4: DD 21 E9 E8        LD IX,0xe8e9                 .!..
E3F8: DD 7E 01           LD A,(IX+1)                  .~.
E3FB: DD 77 00           LD (IX),A                    .w.
E3FE: CD 00 E5           CALL 0xe500                  ...
E401: DD B6 00           OR (IX)                      ...
E404: DD 77 00           LD (IX),A                    .w.
E407: DD 77 01           LD (IX+1),A                  .w.
E40A: DD 21 E4 E8        LD IX,0xe8e4                 .!..
E40E: DD 7E 01           LD A,(IX+1)                  .~.
E411: DD 77 00           LD (IX),A                    .w.
E414: CD E9 E4           CALL 0xe4e9                  ...
E417: DD B6 00           OR (IX)                      ...
E41A: DD 77 00           LD (IX),A                    .w.
E41D: DD 77 01           LD (IX+1),A                  .w.
E420: 3A E1 E8           LD A,(0xe8e1)                :..
E423: FE 04              CP 4                         ..
E425: D8                 RET c                        .
E426: AF                 XOR A                        .
E427: 77                 LD (HL),A                    w
E428: 3A E0 E8           LD A,(0xe8e0)                :..
E42B: B7                 OR A                         .
E42C: C8                 RET z                        .
E42D: 3A 89 00           LD A,(0x0089)                :..
E430: B7                 OR A                         .
E431: C8                 RET z                        .
E432: 08                 EX AF,AF'                    .
E433: F5                 PUSH AF                      .
E434: D9                 EXX                          .
E435: C5                 PUSH BC                      .
E436: D5                 PUSH DE                      .
E437: E5                 PUSH HL                      .
E438: F3                 DI                           .
E439: 3E 10              LD A,0x10                    >.
E43B: CD B4 E4           CALL 0xe4b4                  ...
E43E: F3                 DI                           .
E43F: 3E 11              LD A,0x11                    >.
E441: CD B4 E4           CALL 0xe4b4                  ...
E444: 32 E6 E8           LD (0xe8e6),A                2..
E447: F3                 DI                           .
E448: 3E 12              LD A,0x12                    >.
E44A: CD B4 E4           CALL 0xe4b4                  ...
E44D: 32 E7 E8           LD (0xe8e7),A                2..
E450: 2A E6 E8           LD HL,(0xe8e6)               *..
E453: 11 01 01           LD DE,0x101                  ...
E456: B7                 OR A                         .
E457: ED 52              SBC HL,DE                    .R
E459: 20 11              JR nz,0xe46c                  .
E45B: 3A E8 E8           LD A,(0xe8e8)                :..
E45E: 3C                 INC A                        <
E45F: 32 E8 E8           LD (0xe8e8),A                2..
E462: FE 10              CP 0x10                      ..
E464: 38 04              JR c,0xe46a                  8.
E466: AF                 XOR A                        .
E467: 32 E0 E8           LD (0xe8e0),A                2..
E46A: 18 04              JR 0xe470                    ..
E46C: AF                 XOR A                        .
E46D: 32 E8 E8           LD (0xe8e8),A                2..
E470: 2A E3 E8           LD HL,(0xe8e3)               *..
E473: 3A E6 E8           LD A,(0xe8e6)                :..
E476: 01 F8 00           LD BC,0xf8                   ...
E479: CD C2 E4           CALL 0xe4c2                  ...
E47C: 32 E3 E8           LD (0xe8e3),A                2..
E47F: 2A E2 E8           LD HL,(0xe8e2)               *..
E482: 3A E7 E8           LD A,(0xe8e7)                :..
E485: CB 2F              SRA A                        ./
E487: 01 BA 00           LD BC,0xba                   ...
E48A: CD C2 E4           CALL 0xe4c2                  ...
E48D: 32 E2 E8           LD (0xe8e2),A                2..
E490: F3                 DI                           .
E491: 21 00 62           LD HL,0x6200                 !.b
E494: CD D3 E4           CALL 0xe4d3                  ...
E497: 2A E2 E8           LD HL,(0xe8e2)               *..
E49A: ED 69              OUT (C),L                    .i
E49C: 00                 NOP                          .
E49D: ED 61              OUT (C),H                    .a
E49F: 21 04 62           LD HL,0x6204                 !.b
E4A2: CD D3 E4           CALL 0xe4d3                  ...
E4A5: 2A E2 E8           LD HL,(0xe8e2)               *..
E4A8: ED 69              OUT (C),L                    .i
E4AA: 00                 NOP                          .
E4AB: ED 61              OUT (C),H                    .a
E4AD: E1                 POP HL                       .
E4AE: D1                 POP DE                       .
E4AF: C1                 POP BC                       .
E4B0: D9                 EXX                          .
E4B1: F1                 POP AF                       .
E4B2: 08                 EX AF,AF'                    .
E4B3: C9                 RET                          .
E4B4: 08                 EX AF,AF'                    .
E4B5: 3A C1 FC           LD A,(0xfcc1)                :..
E4B8: FD 67              LD IYH,A                     .g
E4BA: DD 21 DB 00        LD IX,0xdb                   .!..
E4BE: 08                 EX AF,AF'                    .
E4BF: C3 1C 00           JP 0x001c                    ...
E4C2: 26 00              LD H,0                       &.
E4C4: 5F                 LD E,A                       _
E4C5: 17                 RLA                          .
E4C6: 9F                 SBC A,A                      .
E4C7: 57                 LD D,A                       W
E4C8: 7B                 LD A,E                       {
E4C9: 7D                 LD A,L                       }
E4CA: 19                 ADD HL,DE                    .
E4CB: 5D                 LD E,L                       ]
E4CC: B7                 OR A                         .
E4CD: ED 42              SBC HL,BC                    .B
E4CF: 30 01              JR nc,0xe4d2                 0.
E4D1: 7B                 LD A,E                       {
E4D2: C9                 RET                          .
E4D3: 7C                 LD A,H                       |
E4D4: 07                 RLCA                         .
E4D5: 07                 RLCA                         .
E4D6: E6 01              AND 1                        ..
E4D8: CB F4              SET 6,H                      ..
E4DA: 0E 99              LD C,0x99                    ..
E4DC: ED 79              OUT (C),A                    .y
E4DE: 3E 8E              LD A,0x8e                    >.
E4E0: ED 79              OUT (C),A                    .y
E4E2: ED 69              OUT (C),L                    .i
E4E4: ED 61              OUT (C),H                    .a
E4E6: 0E 98              LD C,0x98                    ..
E4E8: C9                 RET                          .
E4E9: 3E 0F              LD A,15                      >.
E4EB: F3                 DI                           .
E4EC: D3 A0              OUT (0x00a0),A               ..
E4EE: DB A2              IN A,(0x00a2)                ..
E4F0: E6 DF              AND 0xdf                     ..
E4F2: F6 4C              OR 0x4c                      .L
E4F4: D3 A1              OUT (0x00a1),A               ..
E4F6: 3E 0E              LD A,14                      >.
E4F8: D3 A0              OUT (0x00a0),A               ..
E4FA: DB A2              IN A,(0x00a2)                ..
E4FC: 2F                 CPL                          /
E4FD: E6 30              AND 0x30                     .0
E4FF: C9                 RET                          .
E500: C5                 PUSH BC                      .
E501: 3E 0F              LD A,15                      >.
E503: F3                 DI                           .
E504: D3 A0              OUT (0x00a0),A               ..
E506: DB A2              IN A,(0x00a2)                ..
E508: E6 AF              AND 0xaf                     ..
E50A: F6 03              OR 3                         ..
E50C: D3 A1              OUT (0x00a1),A               ..
E50E: 3E 0E              LD A,14                      >.
E510: D3 A0              OUT (0x00a0),A               ..
E512: DB A2              IN A,(0x00a2)                ..
E514: 2F                 CPL                          /
E515: E6 3F              AND 0x3f                     .?
E517: 47                 LD B,A                       G
E518: 3E 06              LD A,6                       >.
E51A: CD 4E E5           CALL 0xe54e                  .N.
E51D: CB 47              BIT 0,A                      .G
E51F: 28 02              JR z,0xe523                  (.
E521: CB E8              SET 5,B                      ..
E523: 3E 07              LD A,7                       >.
E525: CD 4E E5           CALL 0xe54e                  .N.
E528: CB 57              BIT 2,A                      .W
E52A: 28 02              JR z,0xe52e                  (.
E52C: CB E8              SET 5,B                      ..
E52E: CB 7F              BIT 7,A                      ..
E530: 28 02              JR z,0xe534                  (.
E532: CB E0              SET 4,B                      ..
E534: 3E 08              LD A,8                       >.
E536: CD 4E E5           CALL 0xe54e                  .N.
E539: CB 47              BIT 0,A                      .G
E53B: 28 02              JR z,0xe53f                  (.
E53D: CB E0              SET 4,B                      ..
E53F: 07                 RLCA                         .
E540: B7                 OR A                         .
E541: CB 6F              BIT 5,A                      .o
E543: 28 01              JR z,0xe546                  (.
E545: 37                 SCF                          7
E546: 17                 RLA                          .
E547: 17                 RLA                          .
E548: 17                 RLA                          .
E549: E6 0F              AND 15                       ..
E54B: B0                 OR B                         .
E54C: C1                 POP BC                       .
E54D: C9                 RET                          .
E54E: C5                 PUSH BC                      .
E54F: 4F                 LD C,A                       O
E550: DB AA              IN A,(0x00aa)                ..
E552: E6 F0              AND 0xf0                     ..
E554: B1                 OR C                         .
E555: D3 AA              OUT (0x00aa),A               ..
E557: DB A9              IN A,(0x00a9)                ..
E559: 2F                 CPL                          /
E55A: C1                 POP BC                       .
E55B: C9                 RET                          .
E55C: ED 5B 83 00        LD DE,(0x0083)               .[..
E560: 4A                 LD C,D                       J
E561: 0C                 INC C                        .
E562: 3E 02              LD A,2                       >.
E564: ED 79              OUT (C),A                    .y
E566: 3E 8F              LD A,0x8f                    >.
E568: ED 79              OUT (C),A                    .y
E56A: 4B                 LD C,E                       K
E56B: 0C                 INC C                        .
E56C: ED 78              IN A,(C)                     .x
E56E: 0F                 RRCA                         .
E56F: D8                 RET c                        .
E570: 7C                 LD A,H                       |
E571: 32 97 E7           LD (0xe797),A                2..
E574: E6 03              AND 3                        ..
E576: 0F                 RRCA                         .
E577: 0F                 RRCA                         .
E578: 0F                 RRCA                         .
E579: F6 1F              OR 0x1f                      ..
E57B: 0E 99              LD C,0x99                    ..
E57D: ED 79              OUT (C),A                    .y
E57F: 3E 82              LD A,0x82                    >.
E581: ED 79              OUT (C),A                    .y
E583: C9                 RET                          .
E584: F3                 DI                           .
E585: 3A 9B E7           LD A,(0xe79b)                :..
E588: B7                 OR A                         .
E589: 28 05              JR z,0xe590                  (.
E58B: 3D                 DEC A                        =
E58C: 32 9B E7           LD (0xe79b),A                2..
E58F: C9                 RET                          .
E590: 3E 03              LD A,3                       >.
E592: 32 9B E7           LD (0xe79b),A                2..
E595: 7D                 LD A,L                       }
E596: 25                 DEC H                        %
E597: 20 01              JR nz,0xe59a                  .
E599: 6C                 LD L,H                       l
E59A: 22 99 E7           LD (0xe799),HL               "..
E59D: FE 01              CP 1                         ..
E59F: 20 27              JR nz,0xe5c8                  '
E5A1: 21 BD E7           LD HL,0xe7bd                 !..
E5A4: DD 21 9D E7        LD IX,0xe79d                 .!..
E5A8: 06 20              LD B,0x20                    . 
E5AA: 0E 10              LD C,0x10                    ..
E5AC: 56                 LD D,(HL)                    V
E5AD: DD 5E 00           LD E,(IX)                    .^.
E5B0: 7A                 LD A,D                       z
E5B1: AB                 XOR E                        .
E5B2: E6 0F              AND 15                       ..
E5B4: 28 01              JR z,0xe5b7                  (.
E5B6: 14                 INC D                        .
E5B7: 7A                 LD A,D                       z
E5B8: AB                 XOR E                        .
E5B9: E6 F0              AND 0xf0                     ..
E5BB: 28 03              JR z,0xe5c0                  (.
E5BD: 7A                 LD A,D                       z
E5BE: 81                 ADD A,C                      .
E5BF: 57                 LD D,A                       W
E5C0: 72                 LD (HL),D                    r
E5C1: 23                 INC HL                       #
E5C2: DD 23              INC IX                       .#
E5C4: 10 E6              DJNZ 0xe5ac                  ..
E5C6: 18 18              JR 0xe5e0                    ..
E5C8: 21 BD E7           LD HL,0xe7bd                 !..
E5CB: 06 20              LD B,0x20                    . 
E5CD: 4E                 LD C,(HL)                    N
E5CE: 79                 LD A,C                       y
E5CF: E6 0F              AND 15                       ..
E5D1: 79                 LD A,C                       y
E5D2: 28 01              JR z,0xe5d5                  (.
E5D4: 0D                 DEC C                        .
E5D5: E6 F0              AND 0xf0                     ..
E5D7: 79                 LD A,C                       y
E5D8: 28 02              JR z,0xe5dc                  (.
E5DA: C6 F0              ADD A,0xf0                   ..
E5DC: 77                 LD (HL),A                    w
E5DD: 23                 INC HL                       #
E5DE: 10 ED              DJNZ 0xe5cd                  ..
E5E0: F3                 DI                           .
E5E1: 3E 00              LD A,0                       >.
E5E3: 0E 99              LD C,0x99                    ..
E5E5: ED 79              OUT (C),A                    .y
E5E7: 3E 90              LD A,0x90                    >.
E5E9: ED 79              OUT (C),A                    .y
E5EB: 3A 84 00           LD A,(0x0084)                :..
E5EE: 3C                 INC A                        <
E5EF: 3C                 INC A                        <
E5F0: 4F                 LD C,A                       O
E5F1: 21 BD E7           LD HL,0xe7bd                 !..
E5F4: 06 20              LD B,0x20                    . 
E5F6: ED B3              OTIR                         ..
E5F8: C9                 RET                          .
E5F9: DD 67              LD IXH,A                     .g
E5FB: 3A F5 E8           LD A,(0xe8f5)                :..
E5FE: FE 11              CP 0x11                      ..
E600: 38 08              JR c,0xe60a                  8.
E602: DD 7C              LD A,IXH                     .|
E604: DD 26 10           LD IXH,0x10                  .&.
E607: CD 2D E0           CALL 0xe02d                  .-.
E60A: C9                 RET                          .
E60B: 3A F5 E8           LD A,(0xe8f5)                :..
E60E: FE 11              CP 0x11                      ..
E610: DA 7D F3           JP c,0xf37d                  .}.
E613: DD 26 10           LD IXH,0x10                  .&.
E616: FD 21 0C 40        LD IY,0x400c                 .!.@
E61A: CD 2D E0           CALL 0xe02d                  .-.
E61D: C9                 RET                          .
E61E: 20 E6              JR nz,0xe606                  .
E620: 0E 01              LD C,1                       ..
E622: C9                 RET                          .
E623: B7                 OR A                         .
E624: 32 DD E7           LD (0xe7dd),A                2..
E627: 28 20              JR z,0xe649                  ( 
E629: F3                 DI                           .
E62A: 11 C0 E8           LD DE,0xe8c0                 ...
E62D: 01 20 00           LD BC,0x20                   . .
E630: ED B0              LDIR                         ..
E632: 3E 6E              LD A,0x6e                    >n
E634: 0E 99              LD C,0x99                    ..
E636: ED 79              OUT (C),A                    .y
E638: 3E 93              LD A,0x93                    >.
E63A: ED 79              OUT (C),A                    .y
E63C: 3E 16              LD A,0x16                    >.
E63E: 0E 99              LD C,0x99                    ..
E640: ED 79              OUT (C),A                    .y
E642: 3E 80              LD A,0x80                    >.
E644: ED 79              OUT (C),A                    .y
E646: FB                 EI                           .
E647: 18 0C              JR 0xe655                    ..
E649: F3                 DI                           .
E64A: 3E 06              LD A,6                       >.
E64C: 0E 99              LD C,0x99                    ..
E64E: ED 79              OUT (C),A                    .y
E650: 3E 80              LD A,0x80                    >.
E652: ED 79              OUT (C),A                    .y
E654: FB                 EI                           .
E655: C9                 RET                          .
E656: 3A 41 F3           LD A,(0xf341)                :A.
E659: E6 03              AND 3                        ..
E65B: 47                 LD B,A                       G
E65C: 3A 42 F3           LD A,(0xf342)                :B.
E65F: E6 03              AND 3                        ..
E661: 07                 RLCA                         .
E662: 07                 RLCA                         .
E663: 4F                 LD C,A                       O
E664: DB A8              IN A,(0x00a8)                ..
E666: F5                 PUSH AF                      .
E667: E6 F0              AND 0xf0                     ..
E669: B0                 OR B                         .
E66A: B1                 OR C                         .
E66B: D3 A8              OUT (0x00a8),A               ..
E66D: 3A 41 F3           LD A,(0xf341)                :A.
E670: E6 0C              AND 12                       ..
E672: 0F                 RRCA                         .
E673: 0F                 RRCA                         .
E674: 47                 LD B,A                       G
E675: 3A 42 F3           LD A,(0xf342)                :B.
E678: E6 0C              AND 12                       ..
E67A: 4F                 LD C,A                       O
E67B: 3A FF FF           LD A,(0xffff)                :..
E67E: 2F                 CPL                          /
E67F: F5                 PUSH AF                      .
E680: E6 F0              AND 0xf0                     ..
E682: B0                 OR B                         .
E683: B1                 OR C                         .
E684: 32 FF FF           LD (0xffff),A                2..
E687: DD 26 10           LD IXH,0x10                  .&.
E68A: FD 21 00 40        LD IY,0x4000                 .!.@
E68E: CD 2D E0           CALL 0xe02d                  .-.
E691: F1                 POP AF                       .
E692: 32 FF FF           LD (0xffff),A                2..
E695: F1                 POP AF                       .
E696: D3 A8              OUT (0x00a8),A               ..
E698: C3 7A E7           JP 0xe77a                    .z.
E69B: C9                 RET                          .
E69C: 21 C0 E8           LD HL,0xe8c0                 !..
E69F: 3A 99 E7           LD A,(0xe799)                :..
E6A2: B7                 OR A                         .
E6A3: C0                 RET nz                       .
E6A4: 3A 9C E7           LD A,(0xe79c)                :..
E6A7: FE 01              CP 1                         ..
E6A9: C0                 RET nz                       .
E6AA: F3                 DI                           .
E6AB: 3E 00              LD A,0                       >.
E6AD: 0E 99              LD C,0x99                    ..
E6AF: ED 79              OUT (C),A                    .y
E6B1: 3E 90              LD A,0x90                    >.
E6B3: ED 79              OUT (C),A                    .y
E6B5: 3A 84 00           LD A,(0x0084)                :..
E6B8: 3C                 INC A                        <
E6B9: 3C                 INC A                        <
E6BA: 4F                 LD C,A                       O
E6BB: 06 20              LD B,0x20                    . 
E6BD: ED B3              OTIR                         ..
E6BF: C9                 RET                          .
E6C0: 3E 00              LD A,0                       >.
E6C2: 0E 99              LD C,0x99                    ..
E6C4: ED 79              OUT (C),A                    .y
E6C6: 3E 8F              LD A,0x8f                    >.
E6C8: ED 79              OUT (C),A                    .y
E6CA: ED 78              IN A,(C)                     .x
E6CC: C9                 RET                          .
E6CD: F3                 DI                           .
E6CE: F5                 PUSH AF                      .
E6CF: C5                 PUSH BC                      .
E6D0: D5                 PUSH DE                      .
E6D1: E5                 PUSH HL                      .
E6D2: DD E5              PUSH IX                      ..
E6D4: FD E5              PUSH IY                      ..
E6D6: 3A F6 E8           LD A,(0xe8f6)                :..
E6D9: B7                 OR A                         .
E6DA: 28 10              JR z,0xe6ec                  (.
E6DC: DB E9              IN A,(0x00e9)                ..
E6DE: CB 7F              BIT 7,A                      ..
E6E0: 28 0A              JR z,0xe6ec                  (.
E6E2: AF                 XOR A                        .
E6E3: D3 EA              OUT (0x00ea),A               ..
E6E5: 3A 89 00           LD A,(0x0089)                :..
E6E8: B7                 OR A                         .
E6E9: C2 56 E6           JP nz,0xe656                 .V.
E6EC: 3E 01              LD A,1                       >.
E6EE: 0E 99              LD C,0x99                    ..
E6F0: ED 79              OUT (C),A                    .y
E6F2: 3E 8F              LD A,0x8f                    >.
E6F4: ED 79              OUT (C),A                    .y
E6F6: ED 78              IN A,(C)                     .x
E6F8: E6 01              AND 1                        ..
E6FA: C4 9C E6           CALL nz,0xe69c               ...
E6FD: 3E 00              LD A,0                       >.
E6FF: 0E 99              LD C,0x99                    ..
E701: ED 79              OUT (C),A                    .y
E703: 3E 8F              LD A,0x8f                    >.
E705: ED 79              OUT (C),A                    .y
E707: ED 78              IN A,(C)                     .x
E709: E6 80              AND 0x80                     ..
E70B: CA 7A E7           JP z,0xe77a                  .z.
E70E: 21 BD E7           LD HL,0xe7bd                 !..
E711: CD 9F E6           CALL 0xe69f                  ...
E714: CD EA E3           CALL 0xe3ea                  ...
E717: 2A 97 E7           LD HL,(0xe797)               *..
E71A: 7C                 LD A,H                       |
E71B: BD                 CP L                         .
E71C: C4 5C E5           CALL nz,0xe55c               .\.
E71F: 2A 99 E7           LD HL,(0xe799)               *..
E722: 7D                 LD A,L                       }
E723: B7                 OR A                         .
E724: C4 84 E5           CALL nz,0xe584               ...
E727: 3A DE E7           LD A,(0xe7de)                :..
E72A: B7                 OR A                         .
E72B: 28 0E              JR z,0xe73b                  (.
E72D: 3A 99 E7           LD A,(0xe799)                :..
E730: B7                 OR A                         .
E731: 20 08              JR nz,0xe73b                  .
E733: 3A 9C E7           LD A,(0xe79c)                :..
E736: FE 01              CP 1                         ..
E738: CC 3E E3           CALL z,0xe33e                .>.
E73B: 3A 89 00           LD A,(0x0089)                :..
E73E: B7                 OR A                         .
E73F: 28 0A              JR z,0xe74b                  (.
E741: DD 26 04           LD IXH,4                     .&.
E744: FD 21 00 80        LD IY,0x8000                 .!..
E748: CD 2D E0           CALL 0xe02d                  .-.
E74B: 3A 8E E7           LD A,(0xe78e)                :..
E74E: B7                 OR A                         .
E74F: 28 0F              JR z,0xe760                  (.
E751: 3D                 DEC A                        =
E752: 32 8E E7           LD (0xe78e),A                2..
E755: 20 09              JR nz,0xe760                  .
E757: 3A 8F E7           LD A,(0xe78f)                :..
E75A: 32 8E E7           LD (0xe78e),A                2..
E75D: CD 84 E7           CALL 0xe784                  ...
E760: 2A 8A E7           LD HL,(0xe78a)               *..
E763: 23                 INC HL                       #
E764: 22 8A E7           LD (0xe78a),HL               "..
E767: DB A7              IN A,(0x00a7)                ..
E769: 1F                 RRA                          .
E76A: 30 0E              JR nc,0xe77a                 0.
E76C: F3                 DI                           .
E76D: 3E 81              LD A,0x81                    >.
E76F: D3 A7              OUT (0x00a7),A               ..
E771: DB A7              IN A,(0x00a7)                ..
E773: 1F                 RRA                          .
E774: 38 FB              JR c,0xe771                  8.
E776: 3E 80              LD A,0x80                    >.
E778: D3 A7              OUT (0x00a7),A               ..
E77A: FD E1              POP IY                       ..
E77C: DD E1              POP IX                       ..
E77E: E1                 POP HL                       .
E77F: D1                 POP DE                       .
E780: C1                 POP BC                       .
E781: F1                 POP AF                       .
E782: FB                 EI                           .
E783: C9                 RET                          .
E784: 2A 8C E7           LD HL,(0xe78c)               *..
E787: E9                 JP (HL)                      .
E788: 00                 NOP                          .
E789: 00                 NOP                          .
E78A: 00                 NOP                          .
E78B: 00                 NOP                          .
E78C: 00                 NOP                          .
E78D: 00                 NOP                          .
E78E: 00                 NOP                          .
E78F: 00                 NOP                          .
E790: 01 51 01           LD BC,0x151                  .Q.
E793: 50                 LD D,B                       P
E794: 00                 NOP                          .
E795: 00                 NOP                          .
E796: 00                 NOP                          .
E797: 00                 NOP                          .
E798: 00                 NOP                          .
E799: 00                 NOP                          .
E79A: 00                 NOP                          .
E79B: 00                 NOP                          .
E79C: 00                 NOP                          .
E79D: 00                 NOP                          .
E79E: 00                 NOP                          .
E79F: 00                 NOP                          .
E7A0: 00                 NOP                          .
E7A1: 00                 NOP                          .
E7A2: 00                 NOP                          .
E7A3: 00                 NOP                          .
E7A4: 00                 NOP                          .
E7A5: 00                 NOP                          .
E7A6: 00                 NOP                          .
E7A7: 00                 NOP                          .
E7A8: 00                 NOP                          .
E7A9: 00                 NOP                          .
E7AA: 00                 NOP                          .
E7AB: 00                 NOP                          .
E7AC: 00                 NOP                          .
E7AD: 00                 NOP                          .
E7AE: 00                 NOP                          .
E7AF: 00                 NOP                          .
E7B0: 00                 NOP                          .
E7B1: 00                 NOP                          .
E7B2: 00                 NOP                          .
E7B3: 00                 NOP                          .
E7B4: 00                 NOP                          .
E7B5: 00                 NOP                          .
E7B6: 00                 NOP                          .
E7B7: 00                 NOP                          .
E7B8: 00                 NOP                          .
E7B9: 00                 NOP                          .
E7BA: 00                 NOP                          .
E7BB: 00                 NOP                          .
E7BC: 00                 NOP                          .
E7BD: 00                 NOP                          .
E7BE: 00                 NOP                          .
E7BF: 00                 NOP                          .
E7C0: 00                 NOP                          .
E7C1: 00                 NOP                          .
E7C2: 00                 NOP                          .
E7C3: 00                 NOP                          .
E7C4: 00                 NOP                          .
E7C5: 00                 NOP                          .
E7C6: 00                 NOP                          .
E7C7: 00                 NOP                          .
E7C8: 00                 NOP                          .
E7C9: 00                 NOP                          .
E7CA: 00                 NOP                          .
E7CB: 00                 NOP                          .
E7CC: 00                 NOP                          .
E7CD: 00                 NOP                          .
E7CE: 00                 NOP                          .
E7CF: 00                 NOP                          .
E7D0: 00                 NOP                          .
E7D1: 00                 NOP                          .
E7D2: 00                 NOP                          .
E7D3: 00                 NOP                          .
E7D4: 00                 NOP                          .
E7D5: 00                 NOP                          .
E7D6: 00                 NOP                          .
E7D7: 00                 NOP                          .
E7D8: 00                 NOP                          .
E7D9: 00                 NOP                          .
E7DA: 00                 NOP                          .
E7DB: 00                 NOP                          .
E7DC: 00                 NOP                          .
E7DD: 00                 NOP                          .
E7DE: 00                 NOP                          .
E7DF: 00                 NOP                          .
E7E0: 00                 NOP                          .
E7E1: 00                 NOP                          .
E7E2: 00                 NOP                          .
E7E3: 00                 NOP                          .
E7E4: 00                 NOP                          .
E7E5: 00                 NOP                          .
E7E6: 00                 NOP                          .
E7E7: 00                 NOP                          .
E7E8: 00                 NOP                          .
E7E9: 00                 NOP                          .
E7EA: 00                 NOP                          .
E7EB: 00                 NOP                          .
E7EC: 00                 NOP                          .
E7ED: 00                 NOP                          .
E7EE: 00                 NOP                          .
E7EF: 00                 NOP                          .
E7F0: 00                 NOP                          .
E7F1: 00                 NOP                          .
E7F2: 00                 NOP                          .
E7F3: 00                 NOP                          .
E7F4: 00                 NOP                          .
E7F5: 00                 NOP                          .
E7F6: 00                 NOP                          .
E7F7: 00                 NOP                          .
E7F8: 00                 NOP                          .
E7F9: 00                 NOP                          .
E7FA: 00                 NOP                          .
E7FB: 00                 NOP                          .
E7FC: 00                 NOP                          .
E7FD: 00                 NOP                          .
E7FE: 00                 NOP                          .
E7FF: 00                 NOP                          .
E800: 00                 NOP                          .
E801: 00                 NOP                          .
E802: 00                 NOP                          .
E803: 00                 NOP                          .
E804: 00                 NOP                          .
E805: 00                 NOP                          .
E806: 00                 NOP                          .
E807: 00                 NOP                          .
E808: 00                 NOP                          .
E809: 00                 NOP                          .
E80A: 00                 NOP                          .
E80B: 00                 NOP                          .
E80C: 00                 NOP                          .
E80D: 00                 NOP                          .
E80E: 00                 NOP                          .
E80F: 00                 NOP                          .
E810: 00                 NOP                          .
E811: 00                 NOP                          .
E812: 00                 NOP                          .
E813: 00                 NOP                          .
E814: 00                 NOP                          .
E815: 00                 NOP                          .
E816: 00                 NOP                          .
E817: 00                 NOP                          .
E818: 00                 NOP                          .
E819: 00                 NOP                          .
E81A: 00                 NOP                          .
E81B: 00                 NOP                          .
E81C: 00                 NOP                          .
E81D: 00                 NOP                          .
E81E: 00                 NOP                          .
E81F: 00                 NOP                          .
E820: 00                 NOP                          .
E821: 00                 NOP                          .
E822: 00                 NOP                          .
E823: 00                 NOP                          .
E824: 00                 NOP                          .
E825: 00                 NOP                          .
E826: 00                 NOP                          .
E827: 00                 NOP                          .
E828: 00                 NOP                          .
E829: 00                 NOP                          .
E82A: 00                 NOP                          .
E82B: 00                 NOP                          .
E82C: 00                 NOP                          .
E82D: 00                 NOP                          .
E82E: 00                 NOP                          .
E82F: 00                 NOP                          .
E830: 00                 NOP                          .
E831: 00                 NOP                          .
E832: 00                 NOP                          .
E833: 00                 NOP                          .
E834: 00                 NOP                          .
E835: 00                 NOP                          .
E836: 00                 NOP                          .
E837: 00                 NOP                          .
E838: 00                 NOP                          .
E839: 00                 NOP                          .
E83A: 00                 NOP                          .
E83B: 00                 NOP                          .
E83C: 00                 NOP                          .
E83D: 00                 NOP                          .
E83E: 00                 NOP                          .
E83F: 00                 NOP                          .
E840: 00                 NOP                          .
E841: 00                 NOP                          .
E842: 00                 NOP                          .
E843: 00                 NOP                          .
E844: 00                 NOP                          .
E845: 00                 NOP                          .
E846: 00                 NOP                          .
E847: 00                 NOP                          .
E848: 00                 NOP                          .
E849: 00                 NOP                          .
E84A: 00                 NOP                          .
E84B: 00                 NOP                          .
E84C: 00                 NOP                          .
E84D: 00                 NOP                          .
E84E: 00                 NOP                          .
E84F: 00                 NOP                          .
E850: 00                 NOP                          .
E851: 00                 NOP                          .
E852: 00                 NOP                          .
E853: 00                 NOP                          .
E854: 00                 NOP                          .
E855: 00                 NOP                          .
E856: 00                 NOP                          .
E857: 00                 NOP                          .
E858: 00                 NOP                          .
E859: 00                 NOP                          .
E85A: 00                 NOP                          .
E85B: 00                 NOP                          .
E85C: 00                 NOP                          .
E85D: 00                 NOP                          .
E85E: 00                 NOP                          .
E85F: 00                 NOP                          .
E860: 00                 NOP                          .
E861: 00                 NOP                          .
E862: 00                 NOP                          .
E863: 00                 NOP                          .
E864: 00                 NOP                          .
E865: 00                 NOP                          .
E866: 00                 NOP                          .
E867: 00                 NOP                          .
E868: 00                 NOP                          .
E869: 00                 NOP                          .
E86A: 00                 NOP                          .
E86B: 00                 NOP                          .
E86C: 00                 NOP                          .
E86D: 00                 NOP                          .
E86E: 00                 NOP                          .
E86F: 00                 NOP                          .
E870: 00                 NOP                          .
E871: 00                 NOP                          .
E872: 00                 NOP                          .
E873: 00                 NOP                          .
E874: 00                 NOP                          .
E875: 00                 NOP                          .
E876: 00                 NOP                          .
E877: 00                 NOP                          .
E878: 00                 NOP                          .
E879: 00                 NOP                          .
E87A: 00                 NOP                          .
E87B: 00                 NOP                          .
E87C: 00                 NOP                          .
E87D: 00                 NOP                          .
E87E: 00                 NOP                          .
E87F: 00                 NOP                          .
E880: 00                 NOP                          .
E881: 00                 NOP                          .
E882: 00                 NOP                          .
E883: 00                 NOP                          .
E884: 00                 NOP                          .
E885: 00                 NOP                          .
E886: 00                 NOP                          .
E887: 00                 NOP                          .
E888: 00                 NOP                          .
E889: 00                 NOP                          .
E88A: 00                 NOP                          .
E88B: 00                 NOP                          .
E88C: 00                 NOP                          .
E88D: 00                 NOP                          .
E88E: 00                 NOP                          .
E88F: 00                 NOP                          .
E890: 00                 NOP                          .
E891: 00                 NOP                          .
E892: 00                 NOP                          .
E893: 00                 NOP                          .
E894: 00                 NOP                          .
E895: 00                 NOP                          .
E896: 00                 NOP                          .
E897: 00                 NOP                          .
E898: 00                 NOP                          .
E899: 00                 NOP                          .
E89A: 00                 NOP                          .
E89B: 00                 NOP                          .
E89C: 00                 NOP                          .
E89D: 00                 NOP                          .
E89E: 00                 NOP                          .
E89F: 00                 NOP                          .
E8A0: 00                 NOP                          .
E8A1: 00                 NOP                          .
E8A2: 00                 NOP                          .
E8A3: 00                 NOP                          .
E8A4: 00                 NOP                          .
E8A5: 00                 NOP                          .
E8A6: 00                 NOP                          .
E8A7: 00                 NOP                          .
E8A8: 00                 NOP                          .
E8A9: 00                 NOP                          .
E8AA: 00                 NOP                          .
E8AB: 00                 NOP                          .
E8AC: 00                 NOP                          .
E8AD: 00                 NOP                          .
E8AE: 00                 NOP                          .
E8AF: 00                 NOP                          .
E8B0: 00                 NOP                          .
E8B1: 00                 NOP                          .
E8B2: 00                 NOP                          .
E8B3: 00                 NOP                          .
E8B4: 00                 NOP                          .
E8B5: 00                 NOP                          .
E8B6: 00                 NOP                          .
E8B7: 00                 NOP                          .
E8B8: 00                 NOP                          .
E8B9: 00                 NOP                          .
E8BA: 00                 NOP                          .
E8BB: 00                 NOP                          .
E8BC: 00                 NOP                          .
E8BD: 00                 NOP                          .
E8BE: 00                 NOP                          .
E8BF: 00                 NOP                          .
E8C0: 00                 NOP                          .
E8C1: 00                 NOP                          .
E8C2: 00                 NOP                          .
E8C3: 00                 NOP                          .
E8C4: 00                 NOP                          .
E8C5: 00                 NOP                          .
E8C6: 00                 NOP                          .
E8C7: 00                 NOP                          .
E8C8: 00                 NOP                          .
E8C9: 00                 NOP                          .
E8CA: 00                 NOP                          .
E8CB: 00                 NOP                          .
E8CC: 00                 NOP                          .
E8CD: 00                 NOP                          .
E8CE: 00                 NOP                          .
E8CF: 00                 NOP                          .
E8D0: 00                 NOP                          .
E8D1: 00                 NOP                          .
E8D2: 00                 NOP                          .
E8D3: 00                 NOP                          .
E8D4: 00                 NOP                          .
E8D5: 00                 NOP                          .
E8D6: 00                 NOP                          .
E8D7: 00                 NOP                          .
E8D8: 00                 NOP                          .
E8D9: 00                 NOP                          .
E8DA: 00                 NOP                          .
E8DB: 00                 NOP                          .
E8DC: 00                 NOP                          .
E8DD: 00                 NOP                          .
E8DE: 00                 NOP                          .
E8DF: 00                 NOP                          .
E8E0: 00                 NOP                          .
E8E1: 00                 NOP                          .
E8E2: 00                 NOP                          .
E8E3: 00                 NOP                          .
E8E4: 00                 NOP                          .
E8E5: 00                 NOP                          .
E8E6: 00                 NOP                          .
E8E7: 00                 NOP                          .
E8E8: 00                 NOP                          .
E8E9: 00                 NOP                          .
E8EA: 00                 NOP                          .
E8EB: 00                 NOP                          .
E8EC: 00                 NOP                          .
E8ED: 00                 NOP                          .
E8EE: 00                 NOP                          .
E8EF: 00                 NOP                          .
E8F0: 00                 NOP                          .
E8F1: 00                 NOP                          .
E8F2: 00                 NOP                          .
E8F3: 00                 NOP                          .
E8F4: 00                 NOP                          .
E8F5: 00                 NOP                          .
E8F6: 00                 NOP                          .
E8F7: 03                 INC BC                       .
E8F8: 02                 LD (BC),A                    .
E8F9: 01 00 02           LD BC,0x200                  ...
E8FC: 00                 NOP                          .
E8FD: 01 02 02           LD BC,0x202                  ...
E900: 02                 LD (BC),A                    .
E901: 02                 LD (BC),A                    .
E902: 02                 LD (BC),A                    .
E903: 02                 LD (BC),A                    .
E904: 01 02 01           LD BC,0x102                  ...
E907: 01 04 00           LD BC,4                      ...
E90A: 80                 ADD A,B                      .
E90B: 05                 DEC B                        .
E90C: 00                 NOP                          .
E90D: 80                 ADD A,B                      .
E90E: 0E 00              LD C,0                       ..
E910: 80                 ADD A,B                      .
E911: 04                 INC B                        .
E912: 00                 NOP                          .
E913: 80                 ADD A,B                      .
E914: 82                 ADD A,D                      .
E915: 86                 ADD A,(HL)                   .
E916: 82                 ADD A,D                      .
E917: 92                 SUB D                        .
E918: 82                 ADD A,D                      .
E919: 81                 ADD A,C                      .
E91A: 82                 ADD A,D                      .
E91B: 99                 SBC A,C                      .
E91C: 81                 ADD A,C                      .
E91D: 44                 LD B,H                       D
E91E: 82                 ADD A,D                      .
E91F: 63                 LD H,E                       c
E920: 82                 ADD A,D                      .
E921: 6E                 LD L,(HL)                    n
E922: 82                 ADD A,D                      .
E923: 72                 LD (HL),D                    r
E924: 81                 ADD A,C                      .
E925: 40                 LD B,B                       @
E926: 56                 LD D,(HL)                    V
E927: 65                 LD H,L                       e
E928: 72                 LD (HL),D                    r
E929: 20 31              JR nz,0xe95c                  1
E92B: 2E 30              LD L,0x30                    .0
E92D: 30 20              JR nc,0xe94f                 0 
E92F: 31 39 39           LD SP,0x3939                 199
E932: 31 2E 30           LD SP,0x302e                 1.0
E935: 35                 DEC (HL)                     5
E936: 2E 32              LD L,0x32                    .2
E938: 30 20              JR nc,0xe95a                 0 
E93A: 20 42              JR nz,0xe97e                  B
E93C: 79                 LD A,C                       y
E93D: 20 59              JR nz,0xe998                  Y
E93F: 2E 4E              LD L,0x4e                    .N
E941: 61                 LD H,C                       a
E942: 6B                 LD L,E                       k
E943: 61                 LD H,C                       a
E944: 74                 LD (HL),H                    t
E945: 73                 LD (HL),E                    s
E946: 75                 LD (HL),L                    u
