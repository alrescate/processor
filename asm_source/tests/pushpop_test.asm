; pushr, popr
;///// EXPECTED OUTPUT
; 14 14 14
constl 0xe, r0
constl 0xe, r1
; sys 0xf, r0
; sys 0xf, r1
pushr r0
constl 0x0, r0
popr r0
skeq r0, r1
halt
; sys 0xf, r0
pushr r1
pushi -3
popr r1
popr r1
skeq r1, r1
; sys 0xf, r1      ; if this ever actually detects a bug it will be hilarious
clr
halt