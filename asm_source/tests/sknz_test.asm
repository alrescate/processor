; positive case
constl 8, r5
sknz r5
constl 1, r1

; negative case
constl 5, r2
constl 5, r3
constl 5, r4
sknz r15
clr
halt