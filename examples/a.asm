ADDI r4,r0,3123
ADDI r3,r0,81
function1: ADDU r5,r4,r3
SUBU r6,r4,r3
AND r7,r4,r3
OR r8,r4,r3
XOR r9,r4,r3
NOR r10,r3,r4
SLT r11,r3,r4
SLL r12,r10,2
SRL r13,r10,2
SRA r14,r10,2
SLLV r15,r10,r11
SRLV r16,r10,r11
SRAV r17,r10,r11
SB r13,4(r0)
SH r13,8(r0)
SW r13,12(r0)
LB r18,12(r0)
ANDI r19,r18,4172
LH r20,12(r0)
ORI r21,r20,4172
LW r22,12(r0)
XORI r23,r22,4172
LWU r24,12(r0)
LUI r25,4172
LBU r26,12(r0)
SLTI r27,r19,0x1256
BEQ r3,r4,function1
NOP
HALT
