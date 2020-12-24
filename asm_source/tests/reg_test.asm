.code 0xff20
const16 0xaa, r15
retn
.data 0
.dw 0x9999
.code 0
skz r0
jmpr r0    ; warm footprints check

constl 1, r5
clr            ; we should see sixteen consecutive zeroes with this command. If we ssee
               ; less than fifteen, or we do not get all zeroes, then something bad has 
               ; happened
;///// EXPECTED OUTPUT
; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
; 43605 43605 64263 30325
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
sys 0xf, r3
sys 0xf, r4
sys 0xf, r5
sys 0xf, r6
sys 0xf, r7
sys 0xf, r8
sys 0xf, r9
sys 0xf, r10
sys 0xf, r11
sys 0xf, r12
sys 0xf, r13
sys 0xf, r14
sys 0xf, r15

const16 0b1010101001010101, r0 ; here, we could see the correct value, that only the high
                               ; or low byte is set to the desired value (that's why it's not 
                               ; identical), or that neither has any sets bits. Or we could see
                               ; nothing.
sys 0xf, r0
move r0, r1
sys 0xf, r1 ; again, we could either see the same behavior as r0, or a different behavior, or nothing

const16 0xfb07, r2
sys 0xf, r2
sto r2, (r15)0 ; at this point, r15 should be 0, so we will either see the value 0xfb07 appear at 0, 
               ; or we will see the value not change at all, or we will see r2 change, or something else
               ; completely horrible
const16 0x7675, r3
sys 0xf, r3
ldo r3, (r15)0
sys 0xf, r3    ; the first sys should definitely just show us the value of r3 (7675), but the
               ; after-load sys will either show 0xfb07 (meaning we loaded the value we tried
               ; to store) or it will show the same value, or it will show 0, or something else

const16 0x7070, r5

ldo r14, (r14)0
ldo r13, (r13)0
ldo r12, (r12)0
ldo r11, (r11)0
ldo r10, (r10)0
skne r10, r14
jmpt el1           ; two potential errors can get us here: either the skip doesn't work, or the value 
                   ; from the load didn't get to the register before the skip, which is a hazard
                   ; either way, two repetitions of 0x7070 should tell us that we are definitely in a bad place
sys 0xf, r5
sys 0xf, r5
halt

;///// EXPECTED OUTPUT
; nothing at all

el1:
const16 0x7071, r5
skne r10, r13
jmpt el2
sys 0xf, r5        ; three repetitions of 7071 shows that we failed this check, which would probably be
sys 0xf, r5        ; the result of something like jump interacting with other instructions
sys 0xf, r5

el2:
skne r10, r12
jmpt el3
const16 0x7072, r5
sys 0xf, r5       ; one repetition here, resulting from 10 != 12. Note that the const16 isn't outside
                  ; this time, so that it can't buffer the timing on the jump

el3:
const16 0x7073, r5
inc r5
skne r10, r11
jmpt el4

sys 0xf, r5        ; this produces (probably) a signature of 0x7074, 0x7073, 0x7073, 0x7074, 0x7075
dec r5             ; if it fails. Interestingly, if it doesn't do that, then there is a problem with
sys 0xf, r5        ; the inc/dec AND with equality between registers 10 and 11
sys 0xf, r5
inc r5
sys 0xf, r5
inc r5
sys 0xf, r5

el4:
skne r10, r10
jmpt good
const16 0xdddd, r6
sys 0xf, r5
inc r5
sys 0xf, r5
inc r6
sys 0xf, r5
sys 0xf, r6
sys 0xf, r7         ; in a fully functioning test, this would give you nothing
                    ; and in a test where r5 had become something else, you would see its signature
                    ; again here, assuming conservation of register values. Additionally, if values
                    ; had the ability to bleed into other registers, it might be visible in r7
                    
good: ; so to recap, at this point, we have tested ldo quite a bit, sto a little, 
      ; and the const instructions enough to believe that they work, as well as sys and clr
      ; so it's time to test sto a little more, this time by whacking its address constantly
clr   ; everybody is zero again here, so if the value at 0 in memory doesn't change from 
      ; its value to 0, then we have a problem
;///// EXPECTED OUTPUT
; 0 1 0
sto r0, (r0)0 ; stores 0 at 0
inc r0
sto r0, (r0)1   ; stores a 1 at address 2
move r0, r1     ; sets r1 to 1
sto r1, (r1)2 ; stores a 1 at address 3
constl 0, r0    ; r0 = 0, r1 = 1
sys 0xf, r0     ; should show a 0
ldo r0, (r0)1   ; r0 should be 1
sys 0xf, r1
sto r2, (r0)2   ; should put a 0 at address 3
inc r0
ldo r3, (r0)1   ; should load a 0 into r3
sys 0xf, r3

; pushi test
;///// EXPECTED OUTPUTT
; 4372 65535 1 1 4370 65534 65534 3
const16 0x5657, r0
const16 0x98a5, r1
pushi -1
constl -1, r0
popr r1
skeq r0, r1
sys 0xf, r0  ; we should not see this, but it will give a negative 1 (probably)

const16 0x1112, r0
pushi 2
pushr r0
popr r1  ; r1 = r0 = 0x1112
popr r2
add r1, r2
sys 0xf, r2  ; this should show 0x1114 if all goes well, or may show 0 if it fails

pushi -1
pushi 0
pushi 1
popr r1     ; r1 = 1
popr r2     ; r2 = 0
pushr r1  
popr r2     ; r2 = 1
popr r3     ; r3 = -1
sys 0xf, r3 ; should show -1
sys 0xf, r2 ; should show 1
sys 0xf, r1 ; should show 1
sys 0xf, r0 ; should show 0x1112, probably
sub r2, r3  ; r3 = -2
move r3, r4
sys 0xf, r4 ; -2
sys 0xf, r3 ; -2
sub r3, r1
sys 0xf, r1 ; 1 - -2 = 3, so this should show 3

; add and sub, additional tests
;///// EXPECTED OUTPUT
; [absolutely nothing]
constl 0x10, r0
constl 0x20, r1
add r0, r1      ; this makes r1 = 0x30
constl 0x30, r2 
skeq r1, r2
sys 0xf, r2     ; this shows 0x30, probably, but we should never see it
sub r0, r2
constl 0x20, r4
skeq r4, r2      ; both registers should be equal to 0x20 
sys 0xf, r4     ; again, shows 0x20, but should never appear at all

clr

; and
;///// EXPECTED OUTPUT
; 255 255 65280 0 0
const16 0xffff, r0
constl -1, r1
consth 0, r1
consth -1, r2
and r1, r0          ; should set r0 = 0x00ff 
skeq r0, r1
halt
constl -1, r3
consth 0, r3
sys 0xf, r3         ; we should see 0x00ff
and r3, r3          ; should do nothing
sys 0xf, r3         ; we should see another 0x00ff
constl -1, r0
consth -1, r0     ; basically an assembler test, to see if 
                    ; const16 0xffff = constl 0xff consth 0xff (it should)
and r2, r0          ; should set r0 = 0xff00
skeq r0, r2
halt
sys 0xf, r0          ; should see 0xff00

const16 0b1010101010101010, r4
const16 0b0101010101010101, r5
and r4, r5
sys 0xf, r5          ; should be 0
and r5, r4
sys 0xf, r4          ; should also be 0

clr

; ior
;///// EXPECTED OUTPUT
; 65535 0xf2fc
constl -1, r0
consth -1, r1
constl -1, r2
consth -1, r2
ior r1, r0      ; should set r0 = 0xffff
skeq r0, r2
halt
sys 0xf, r0     ; should show 0xffff
const16 0, r2
const16 0b1111000011111000, r0
const16 0b0010001001111100, r1
ior r0, r2
ior r1, r2
sys 0xf, r2     ; should give 0xf2fc

clr

; xor
;///// EXPECTED OUTPUTT
; 65535 65535 0 0 0
constl -1, r0
consth 0, r0
consth -1, r1
constl -1, r2   ; pretty much an assembler test
constl 0, r3
xor r1, r0      ; should set r0 = 0xffff
sys 0xf, r0     ; should show 0xffff
sys 0xf, r2     ; should show 0xffff
skeq r0, r2
halt
xor r0, r0      ; should set r0 = 0
skeq r0, r3
halt
sys 0xf, r3     ; three repetitions of 0
sys 0xf, r0
sys 0xf, r3
clr 

; lsftl
;//// EXPECTED OUTPUT
; 204 52224 8 8 0
const16 0xcc, r0
const16 0xcc00, r1
constl 0x8, r2
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2     ; should be 0x00cc 0xcc00 0x0008
lsftl r2, r0    ; should set r0 = 0xff00
skeq r0, r1
halt
sys 0xf, r2
lsftl r2, r0
sys 0xf, r0     ; should be 0
skne r0, r1
halt
clr

; asftr
;///// EXPECTED OUTPUT
; 65532 1 65534 65534 1 65534 1 65535
constl -4, r0
constl 1, r1
constl -2, r2
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
asftr r1, r0   ; should set r0 = -2
skeq r0, r2
halt
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
asftr r1, r0   ; should set r0 = -1 (aka 0xffff)
xor r0, r2     ; should set r2 = 1
sys 0xf, r2
sys 0xf, r0
clr

; lsftr
;///// EXPECTED OUTPUT
; 32766 32766 32766 16383
constl -4, r0
constl 1, r1
const16 0xfe, r2
consth 0x7f, r2
sys 0xf, r2      ; should show 0x7ffe
lsftr r1, r0     ; should set r0 = 0x7ffe
skeq r0, r2
halt
sys 0xf, r0
sys 0xf, r2
lsftr r1, r0     ; should set r0 = 0x3fff
sys 0xf, r0
clr

; multl
;///// EXPECTED OUTPUT
; 891 20223 61829 61829 61829 20223 61829
const16 0x037b, r0
const16 0x4eff, r1
const16 0xf185, r2
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
multl r1, r0      ; should set r0 = 0xf185
sys 0xf, r0
skeq r0, r2
halt
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
clr

; multh
;///// EXPECTED OUTPUT
; 891 20223 274 274 20223 274 160 0
const16 0x037b, r0
const16 0x4eff, r1
const16 0x0112, r2
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
multh r1, r0
skeq r0, r2
halt
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
const16 0x00a0, r0
sys 0xf, r0
multh r0, r0       ; should set r0 = 0
sys 0xf, r0
clr

; move
;///// EXPECTED OUTPUT
; 255 238 238 238 238 238
constl -1, r0
consth 0, r0
const16 0xee, r1
sys 0xf, r0
sys 0xf, r1
move r1, r0  ; should set r0 = 0x00ee
skeq r0, r1
halt
sys 0xf, r0
sys 0xf, r1
move r1, r1  ; should not change anything
sys 0xf, r0
sys 0xf, r1
clr

; sklt, skgt, skle, skge, skeq, skne
;///// EXPECTED OUTPUT
; 1 1 2 1 1 1 0 65535 
constl 0x1, r0
constl 0x1, r1
constl 0x2, r2
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
sklt r0, r2
halt
sys 0xf, r0
inc r2      ; r2 = 3
skgt r2, r0
halt
sys 0xf, r1
dec r2
dec r2      ; r2 = 1
skle r2, r1
halt
sys 0xf, r2
dec r0      ; r0 = 0
skle r0, r2
halt
sys 0xf, r0
dec r1      ; r1 = 0
skge r0, r1
halt
dec r0
skge r2, r0 ; real good test here, since r0 = -1 = 0xffff
halt
dec r1      ; r1 = -1
skeq r0, r1 
halt
sys 0xf, r0
skne r0, r2 
halt
clr

; inc, dec, neg, com
;///// EXPECTED OUTPUT
; 0 1 2 65535 2 2 0 0 1 65535 65535
constl 0x1, r1
constl 0x2, r2
constl 0x0, r0
constl -1, r3
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
sys 0xf, r3
inc r1
skeq r1, r2
halt
sys 0xf, r1
sys 0xf, r2
dec r1
dec r1
skeq r1, r0
halt
sys 0xf, r1
sys 0xf, r0
inc r1
sys 0xf, r1
neg r1
skeq r1, r3
halt
sys 0xf, r1
sys 0xf, r3
com r1
skeq r1, r0
halt
clr

; callr
;///// EXPECTED OUTPUT
; 170 170
const16 0xaa, r1
sys 0xf, r1
const16 0xff20, r0
callr r0
skeq r1, r15       ; the timing of all of this is nice and close to maximize the chance of problems
halt
sys 0xf, r1
clr

; jmpi 
;///// EXPECTED OUTPUT
; 5 10 5 10 10
const16 0x0005, r0
constl 0xa, r1
jmpi 5
halt
halt
halt
halt
halt
sys 0xf, r0
sys 0xf, r1
constl 0xa, r2
skeq r1, r2
halt
sys 0xf, r0
sys 0xf, r1
sys 0xf, r2
clr

; movrsp, movspr
;///// EXPECTED OUTPUT
; 14 65535 0 
constl 0xe, r0
constl -1, r1
constl 0xb, r2
constl 0xb, r3
constl -1, r4
sys 0xf, r0
movspr r0
skeq r0, r1
halt
sys 0xf, r0      ; should show 0xffff since that's where the stack pointer is
movrsp r2        ; sp = 0xb
constl 0, r2
sys 0xf, r2
movspr r2
skeq r2, r3
halt
pushi -1         ; -1 should now be in memory at 0xb
ldo r5, (r3)0
skeq r4, r5
sys 0xf, r4
movrsp r4         ; put the stack pointer back where it belongs
clr

; pushr, popr
;///// EXPECTED OUTPUT
; 14 14 14
constl 0xe, r0
constl 0xe, r1
sys 0xf, r0
sys 0xf, r1
pushr r0
constl 0x0, r0
popr r0
skeq r0, r1
halt
sys 0xf, r0
pushr r1
pushi -3
popr r1
popr r1
skeq r1, r1
sys 0xf, r1      ; if this ever actually detects a bug it will be hilarious
clr

; skz, sknz, skmi, skpl
;///// EXPECTED OUTPUT
; 0 1 65535 1
constl 0x0, r0
skz r0
halt
sys 0xf, r0
constl 0x1, r1
sknz r1
halt
sys 0xf, r1
constl -1, r2
skmi r2
halt
sys 0xf, r2
dec r1
inc r1
skpl r1
halt
sys 0xf, r1
clr

; very dangerous test of reset and halt that might not work any more
; (using warm footprints in a register)
;///// EXPECTED OUTPUT
; 43690
const16 0xaaaa, r0
reset
.code 0xaaa9
sys 0xf, r1     ; we should only see this is something is wrong
sys 0xf, r0
halt
sys 0xf, r1     ; we should only see this is something is wrong
