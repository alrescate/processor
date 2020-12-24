; asftr
;///// EXPECTED OUTPUT
; 65532 1 65534 65534 1 65534 1 65535
constl -4, r0
constl 1, r1
constl -2, r2
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
asftr r1, r0   ; should set r0 = -2
skeq r0, r2
halt
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2
asftr r1, r0   ; should set r0 = -1 (aka 0xffff)
xor r0, r2     ; should set r2 = 1
; sys 0xf, r2
; sys 0xf, r0
clr
halt