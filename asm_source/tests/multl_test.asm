; multl
;///// EXPECTED OUTPUT
; 891 20223 61829 61829 61829 20223 61829
const16 0x037b, r0
const16 0x4eff, r1
const16 0xf185, r2
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
multl r1, r0      ; should set r0 = 0xf185
; sys 0xf, r0
skeq r0, r2
halt
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
clr