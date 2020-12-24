; inc, dec, neg, com
;///// EXPECTED OUTPUT
; 0 1 2 65535 2 2 0 0 1 65535 65535
constl 0x1, r1
constl 0x2, r2
constl 0x0, r0
constl -1, r3
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
; sys 0xf, r3
inc r1
skeq r1, r2
halt
; sys 0xf, r1
; sys 0xf, r2
dec r1
dec r1
skeq r1, r0
halt
; sys 0xf, r1
; sys 0xf, r0
inc r1
; sys 0xf, r1
neg r1
skeq r1, r3
halt
; sys 0xf, r1
; sys 0xf, r3
com r1
skeq r1, r0
halt
clr
halt