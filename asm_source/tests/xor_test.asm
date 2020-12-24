; xor
;///// EXPECTED OUTPUTT
; 65535 65535 0 0 0
constl -1, r0
consth 0, r0
consth -1, r1
constl -1, r2   ; pretty much an assembler test
constl 0, r3
xor r1, r0      ; should set r0 = 0xffff
; sys 0xf, r0     ; should show 0xffff
; sys 0xf, r2     ; should show 0xffff
skeq r0, r2
halt
xor r0, r0      ; should set r0 = 0
skeq r0, r3
halt
; sys 0xf, r3     ; three repetitions of 0
; sys 0xf, r0
; sys 0xf, r3
clr 
halt