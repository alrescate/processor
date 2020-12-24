; the purpose of this test is to examine whether or not "flush" (p4/p5 branches)
; interacts properly with suppress and the data stall mechanisms. 

.code 0xabac
constl 6, r3
retn

.code 0
; part 1: what if a stall get preempted by a flush?
clr
const16 0xabac, r0
constl 4, r1
constl 5, r2 ; these instructions should ensure that r0 is not being written in the pipe when the call decodes
callr r0
constl 1, r0
add r0, r0

; part 2: what if a flush gets skipped?
skgt r3, r0  ; this will stall versus above
callr r0     ; r3 should be 6 and r0 should be 2, so this should never happen
add r0, r0   ; r0 should become 4

constl 5, r5
constl 5, r6
constl 5, r7 ; now there should be no r0 in the pipeline

skgt r3, r0  ; this should have no stall interfering
callr r0     ; r3 should be 6 and r0 should be 4, so this should never happen
add r0, r0   ; r0 should become 8

; part 3: what happens when many calls are consecutive?
; you probably want to use the assembly log to help debug this
t1:
skz r14
jmpt ending
callt t2
jmpt t1

t5:
constl 1, r14
retn

t3: 
callt t4
retn

t2:
callt t3
retn

t4:
callt t5
retn

ending:
add r14, r14 ; this should set r14 = 2
halt