; skz, sknz, skmi, skpl
;///// EXPECTED OUTPUT
; 0 1 65535 1
constl 0x0, r0
skz r0
halt
; sys 0xf, r0
constl 0x1, r1
sknz r1
halt
; sys 0xf, r1
constl -1, r2
skmi r2
halt
; sys 0xf, r2
dec r1
inc r1
skpl r1
halt
; sys 0xf, r1
clr
halt