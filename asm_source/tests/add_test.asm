constl 5, r0
constl 7, r1
add r1, r0 ; r0 = 0xC (12)

add r1, r1 ; r1 = 0xE (14)
add r1, r1 ; r1 = 0x1C (28)
add r0, r1 ; r1 = 0x28 (40)
add r0, r0 ; r0 = 0x18 (24)
add r1, r0 ; r0 = 0x40 (64)

constl -1, r2 ; 0xFF
constl -2, r3 ; 0xFE
constl -3, r4 ; 0xFD
constl -4, r5 ; 0xFC
constl -5, r6 ; 0xFB

add r2, r1 ; r1 = 0x27 (39)
add r3, r1 ; r1 = 0x25 (37)
add r4, r1 ; r1 = 0x22 (34)
add r5, r1 ; r1 = 0x1E (30)
add r6, r1 ; r1 = 0x19 (25)
add r2, r3 ; r3 = 0xFD (-3)
add r3, r4 ; r4 = 0xFA (-6)
add r4, r5 ; r5 = 0xF6 (-10)
add r5, r4 ; r4 = 0xF0 (-16)
add r6, r7 ; r7 = 0xFB (-5)
add r7, r6 ; r6 = 0xF6 (-10)
add r6, r6 ; r6 = 0xEC (-20)
halt