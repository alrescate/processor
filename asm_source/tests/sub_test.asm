constl 7, r0
constl 5, r1
sub r1, r0 ; r0 = 0x02 (2)
sub r0, r0 ; r0 = 0x00 (0)
sub r1, r0 ; r0 = 0xFB (-5)
sub r0, r1 ; r1 = 0x0A (10)

constl -5, r2 ; r2 = 0xFB (-5)
constl -6, r3 ; r3 = 0xFA (-6)
constl -7, r4 ; r4 = 0xF9 (-7)
constl -8, r5 ; r5 = 0xF8 (-8)
constl -9, r6 ; r6 = 0xF7 (-9)
constl -10, r7 ; r7 = 0xF6 (-10)
constl -11, r8 ; r8 = 0xF5 (-11)

sub r3, r2 ; r2 = 0x01 (1)
sub r2, r3 ; r3 = 0xF9 (-7)
sub r3, r4 ; r4 = 0x00 (0)
sub r5, r5 ; r5 = 0x00 (0)
sub r5, r6 ; r6 = 0xF7 (-9)
sub r6, r8 ; r8 = 0xFE (-2)
sub r8, r7 ; r7 = 0xF8 (-8)
sub r7, r9 ; r9 = 0x08 (8)
sub r9, r1 ; r1 = 0x02 (2)
halt