; positive case for <
constl -1, r0
constl 1, r2
skle r0, r2
constl 5, r5

; positive case for =
constl 1, r10
skle r2, r10
constl 9, r9

; negative case
skle r9, r0
constl 4, r11
halt