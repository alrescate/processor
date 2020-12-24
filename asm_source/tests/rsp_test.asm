; movrsp, movspr
;///// EXPECTED OUTPUT
; 14 65535 0 
constl 0xe, r0
constl -1, r1
constl 0xb, r2
constl 0xb, r3
constl -1, r4
; sys 0xf, r0
movspr r0
skeq r0, r1
halt
; sys 0xf, r0      ; should show 0xffff since that's where the stack pointer is
movrsp r2        ; sp = 0xb
constl 0, r2
; sys 0xf, r2
movspr r2
skeq r2, r3
halt
pushi -1         ; -1 should now be in memory at 0xb
ldo r5, (r3)0
skne r4, r5
; sys 0xf, r4
movrsp r4         ; put the stack pointer back where it belongs
clr
halt