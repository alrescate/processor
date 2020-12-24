; lsftl
;//// EXPECTED OUTPUT
; 204 52224 8 8 0
const16 0xcc, r0
const16 0xcc00, r1
constl 0x8, r2
; sys 0xf, r0
; sys 0xf, r1
; sys 0xf, r2     ; should be 0x00cc 0xcc00 0x0008
lsftl r2, r0    ; should set r0 = 0xcc00
skeq r0, r1
halt
; sys 0xf, r2
lsftl r2, r0
; sys 0xf, r0     ; should be 0
skne r0, r1
halt
clr
halt