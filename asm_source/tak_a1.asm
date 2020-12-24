; uint32_t tak(uint32_t x, uint32_t y, uint32_t z) {
;     if (y >= x) return z;
;     else return tak(tak(x-1, y, z), tak(y-1, z, x), tak(z-1, x, y));
; }
pushi 0
pushi 9 ; a / x
pushi 7 ; b / y
pushi 1 ; c / z
callt tak

; if we get down here, we must be out of the entire recursion loop, with sp 4 below the final retv
popr r14
popr r14
popr r14
popr r14 ; this one puts in the retv

sys 0xf, r14 ; show retv
sys 0xf, r15 ; show call count
halt 

; test of ds, dw, eq
.data 0
.ds "this is a test"
.dw 0xf, 0xff, 0xfff, 0x7fff, 0x7171, -1, 5, 9, 15, 15, this, that, tak, 13, those, 0b1011, these
this .eq 0x7f7f
that .eq 255
those .eq this
these .eq those
.code 12

tak:
inc r15 ; call counter, to compare against java
pushr r0
pushr r1
pushr r2
pushr r3
movspr r0

ldo r1, (r0)8 ; r1 = a
ldo r2, (r0)7 ; r2 = b
ldo r3, (r0)6 ; r3 = c

skle r1, r2
jmpt takbody

sto r3, (r0)9
popr r3
popr r2
popr r1
popr r0
retn

takbody:
pushi 0
pushi 0 ; reserve two spaces for outer and first inner call retvs
dec r1 ; x-1
pushr r1
pushr r2
pushr r3
callt tak

dec r0
dec r0 ; see diagram, move sp val in r0 down stack
movrsp r0

dec r2 ; y-1
inc r1 ; x-1+1 = x

pushi 0 ; second inner call retv
pushr r2 ; y-1
pushr r3 ; z
pushr r1 ; x
callt tak

dec r0 ; move another space down stack
movrsp r0

dec r3 ; z-1
inc r2 ; y-1+1 = y

pushi 0 ; third inner call retv
pushr r3 ; z-1
pushr r1 ; x
pushr r2 ; y
callt tak

dec r0 ; move down stack so that inner retvs are aligned for outer call
movrsp r0
callt tak

inc r0
inc r0
inc r0
inc r0 ; +4 up stack, to outer retv pos
ldo r5, (r0)0
sto r5, (r0)9 ; switch outer retv up into retv at top of whole stackframe for this call

movrsp r0 ; r0 already has correct position for popping off r0-3
popr r3
popr r2
popr r1
popr r0
; sys 15, r15
retn
