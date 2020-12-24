; move
;///// EXPECTED OUTPUT
; 255 238 238 238 238 238
constl -1, r0
consth 0, r0
const16 0xee, r1
; sys 0xf, r0
; sys 0xf, r1
move r1, r0  ; should set r0 = 0x00ee
skeq r0, r1
halt
; sys 0xf, r0
; sys 0xf, r1
move r1, r1  ; should not change anything
; sys 0xf, r0
; sys 0xf, r1
clr
halt