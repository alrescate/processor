constl -1, r0
consth 0, r0
consth -1, r1
constl -1, r2
consth -1, r2
ior r1, r0      ; should set r0 = 0xffff
skeq r0, r2
halt
; sys 0xf, r0     ; should show 0xffff
const16 0, r2
const16 0b1111000011111000, r0
const16 0b0010001001111100, r1
ior r0, r2
ior r1, r2
; sys 0xf, r2     ; should give 0xf2fc

clr
halt