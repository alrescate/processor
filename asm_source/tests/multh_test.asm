; multh
;///// EXPECTED OUTPUT
; 891 20223 274 274 20223 274 160 0
const16 0x037b, r0
const16 0x4eff, r1
const16 0x0112, r2
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
multh r1, r0
skeq r0, r2
halt
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
const16 0x00a0, r0
; sys 0xf, r0
multh r0, r0       ; should set r0 = 0
; sys 0xf, r0
clr
halt