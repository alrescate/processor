const16 0xffff, r0
constl -1, r1
consth 0, r1
consth -1, r2
and r1, r0          ; should set r0 = 0x00ff 
skeq r0, r1
halt
constl -1, r3
consth 0, r3
and r3, r3          ; should do nothing
constl -1, r0
consth -1, r0     ; basically an assembler test, to see if 
                    ; const16 0xffff = constl 0xff consth 0xff (it should)
and r2, r0          ; should set r0 = 0xff00
skeq r0, r2
halt

const16 0b1010101010101010, r4
const16 0b0101010101010101, r5
and r4, r5
and r5, r4

clr
halt