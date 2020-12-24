; lsftr
;///// EXPECTED OUTPUT
; 32766 32766 32766 16383
constl -4, r0
constl 1, r1
const16 0xfe, r2
consth 0x7f, r2
; sys 0xf, r2      ; should show 0x7ffe
lsftr r1, r0     ; should set r0 = 0x7ffe
skeq r0, r2
halt
; sys 0xf, r0
; sys 0xf, r2
lsftr r1, r0     ; should set r0 = 0x3fff
; sys 0xf, r0
clr
halt
