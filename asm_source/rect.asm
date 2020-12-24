           .code 0
           
mainsl:    constl 1, r0                ; main select, allowing assemble-time choice between the TS-enabled
           sknz r0                     ; main and the LCD test main
           jmpt LCDmain
           
TSmain:    const16 60000, r0           ; power-on delay
           pushr r0
           callt ndelay
           popr r0

           callt initscr               ; initialize the screen, draw the lines, draw the buttons

           callt drawlines
           
           const16 obuttontb, r0
           pushr r0
           pushi 120
           pushi 246
           pushi 120
           pushi 74
           const16 ILI9341_BLUE, r0
           pushr r0
           callt drrun
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           
           const16 xbuttontb, r0
           pushr r0
           pushi 0
           pushi 246
           pushi 120
           pushi 74
           const16 ILI9341_RED, r0
           pushr r0
           callt drrun
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           
           callt beginTS               ; push configuration instructions to the touchscreen
           
           const16 10000, r0           ; a delay to let the touchscreen settle - suggested by STMPE610 manual
           pushr r0
           callt ndelay
           popr r0
           
           constl 0, r0                ; loop counter
           constl 65, r1               ; loop limit
           const16 0x80, r2            ; mask for touchscreen reads 
           constl 0, r5                ; xs status - one hot encoded from [8...0]
           constl 0, r6                ; os status, same as above
           const16 S_CS2ASSERT, r12    
           constl 0, r13               ; writing address to access io controller
           const16 S_CS2DEASSERT, r14
rloop:     sklt r0, r1
           jmpt btnloop
           
           callt busy                  ; busy check ahead of writes, to not step on the toes of a previous write cycle
           sto r12, (r13)0             ; assert chip select
           
           pushi 0
           move r0, r3
           ior r2, r3                  ; move to preserve r0 as loop counter, or to set read flag  
           pushr r3
           callt readTS                ; this read is for memory addresses 0...64, which is recommended by Adafruit's sample code
           popr r2
           popr r2
           
           callt busy
           sto r14, (r13)0
           
           inc r0
           jmpt rloop
           
btnloop:   pushi 0
           pushi 0
           callt gRsTouch              ; returns the rescaled x and y of a touch when one happens - will stall and wait for a touch until it gets one
           popr r2
           popr r1
           
           pushi 0
           pushr r1
           pushr r2
           callt startbtnc             ; checks whether the touch is on a start button (0 = x first, 1 = o first, -1 = not on a button)
           popr r3
           popr r3
           popr r3
           
           skpl r3
           jmpt btnloop
           
           skz r3
           jmpt obtnpick
           
           const16 obuttontb, r0       ; being here we must not have had -1 or 1, so we had 0. Thus, clear the o button
           pushr r0
           pushi 120
           pushi 246
           pushi 120
           pushi 74
           const16 ILI9341_WHITE, r0
           pushr r0
           callt drrun                 ; drawing the button with white as the active color results in painting the whole sector
           popr r0                     ; with relatively little overhead
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           
           jmpt inputloop              ; since x is playing first, jump to take player input
           
obtnpick:  const16 xbuttontb, r0       ; being here, o first was picked; therefore, clear the x button
           pushr r0
           pushi 0
           pushi 246
           pushi 120
           pushi 74
           const16 ILI9341_WHITE, r0
           pushr r0
           callt drrun                 ; same as above, painting white over the button clears it 
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           popr r0
           
           jmpt compplayb              ; if the computer plays first, jump down to it instead of entering inputloop at the head

inputloop: pushi 0
           pushi 0
           callt gRsTouch              ; wait for touch, rescale it - remember, x and y come out in reverse
           popr r2
           popr r1
                                       ; at this point, r1 = rescaled x, r2 = rescaled y
           pushi 0
           pushr r1
           pushr r2
           callt touchtoi              ; convert the touch to a 0...8 index on the board
           popr r3
           popr r3
           popr r3                     ; we now have the index, or -1
           
           ; const16 0xfade, r14
           ; const16 debugwd0, r15     ; write a distinctive word to debug so SignalTap could trigger here
           ; sto r14, (r15)0
           ; sto r3, (r15)0
           
           skpl r3
           jmpt inputloop              ; if we didn't skip the touch decoded to a non-index, so we can't mark any squares and have to just go back and wait
           
           constl 1, r7
           move r5, r8
           ior r6, r8                  ; this ior fills r8 with "occupied" flags in bits 0...8, indicating which squares are free and which are taken 
           lsftr r3, r8                ; shift by the index, to move the bit we want to set down to 0
           and r7, r8                  ; and off higher bits
           
           skz r8                      ; to check that we can't re-play on indices by making sure our chosen move has a 0 in both xs and os
           jmpt inputloop              ; if we don't skip the touch wasn't on an empty square, and thus we can't play it, so go back and wait
           
           const16 stdlinew, r14
           
           pushr r3
           pushr r14
           callt drxi                  ; the player always moves as x, so draw an x with standard line width at the index
           popr r7
           popr r7
           
           constl 1, r7
           lsftl r3, r7
           ior r7, r5                  ; shift up a bit to ior into the xs reg, so that the state is in sync with the GUI                
           
compplayb: const16 40000, r7           ; delay the computer response significantly so that the engine doesn't appear to play instantaneously
           pushr r7
           callt ndelay
           popr r7

                                       ; just to note, r5 and r6 are protected but at this point all other registers are free for temps
           pushi 0                     ; retv
           pushr r6
           pushr r5
           pushi 0                     ; move, as an index
           
           ;const16 0xbead, r14        ; these would be SignalTap pushes, but they aren't needed
           ;sto r14, (r15)0
           ;sto r5, (r15)0
           ;sto r6, (r15)0
           ;const16 0x0dab, r14
           ;sto r14, (r15)0
           
           callt ttt_engine
           
           popr r8                     ; the move is now here
           popr r7
           popr r7
           popr r7                     ; this one gets the score
           
           sknz r8                     ; if the move was 0, go start the winner checks - if not, play it
           jmpt checkplr
           
           ;const16 0xfeed, r14
           ;const16 debugwd3, r15
           ;sto r14, (r15)0
           ;sto r8, (r15)0
           ;sto r7, (r15)0
           ;sto r5, (r15)0
           ;sto r6, (r15)0
           ;const16 0xf00d, r14
           ;sto r14, (r15)0
           
           move r8, r7                 ; to preserve the move
           constl 1, r9                ; shift constant
           constl -1, r10              ; the index counter starts at -1 because looping once is an index of 0
logloop:   inc r10
           lsftr r9, r7
           skz r7
           jmpt logloop                ; this is a cheap logarithm, shift - increment - check - repeat
           
           pushr r10                   ; r10 is now the index, shifted down from the mask in logloop
           callt drcirci
           popr r7
           
           ior r8, r6                  ; updates the internal representation of the board state
           
           pushi 0
           pushi 0
           callt getPoint              ; this clears out the buffer so that touches which happened during think time don't get processed
           popr r7
           popr r7
           
checkplr:  pushi 0
           pushr r5                    ; checks the player's win status
           callt checkwin
           popr r14
           popr r14
           
           sknz r14                    ; if the player's win was 0, check the computer's win
           jmpt checkcomp
           
           constl 1, r15               ; this indicates a player victory, as it will match in testred
           jmpt endgame
           
checkcomp: pushi 0
           pushr r6                    ; checks the computer's win status
           callt checkwin
           popr r14
           popr r14
           
           skz r14                     ; if the computer won jump there, otherwise check the draw 
           jmpt compwon
           
           move r5, r14                ; move the board over to a temp and or everyone together - occupied status
           ior r6, r14
           
           ;const16 0xfede, r13
           ;const16 debugwd3, r15
           ;sto r13, (r15)0
           ;sto r5, (r15)0
           ;sto r6, (r15)0
           ;sto r14, (r15)0
           ;const16 0xefed, r13
           ;sto r13, (r15)0
           
           const16 0x1ff, r13          ; the constant for a full board
           
           skeq r13, r14               ; if the board isn't full, we must have a non-draw to have gotten a move of 0
           jmpt reploop
           
           constl 0, r15               ; if we got down here, the move was 0, the board was full, and the score was neutral. This is a draw
           jmpt endgame

compwon:   constl 2, r15               ; this indicates a computer victory, as it will match in testblue
           jmpt endgame
           
reploop:   jmpt inputloop
           
endgame:   constl 0, r13
           skeq r15, r13               ; if the status was 0, it's a draw, otherwise go check player wins
           jmpt testred
           
           const16 drawmsgtb, r13
           pushr r13
           pushi 0
           pushi 100
           pushi 240
           pushi 120
           const16 ILI9341_YELLOW, r13
           pushr r13
           callt drrun                 ; push the draw message out to the screen for draws
           popr r13
           popr r13
           popr r13
           popr r13
           popr r13
           popr r13
           jmpt waitrst
           
testred:   constl 1, r13
           skeq r15, r13               ; if the status was 1, the player won, otherwise go check computer wins
           jmpt testblue
           
           const16 xwonmsgtb, r13
           pushr r13
           pushi 0
           pushi 100
           pushi 240
           pushi 120
           const16 ILI9341_RED, r13
           pushr r13
           callt drrun                 ; push the x won message out to the screen if the player wins - note, cannot happen
           popr r13
           popr r13
           popr r13
           popr r13
           popr r13
           popr r13
           jmpt waitrst
           
testblue:  constl 2, r13
           skeq r15, r13               ; if the status was 2, the computer won, and just continue to qcoldec if something else happened
           jmpt waitrst
           
           const16 owonmsgtb, r13
           pushr r13
           pushi 0
           pushi 100
           pushi 240
           pushi 120
           const16 ILI9341_BLUE, r13
           pushr r13
           callt drrun                 ; push the o won message if the computer won
           popr r13
           popr r13
           popr r13
           popr r13
           popr r13
           popr r13

waitrst:   pushi 0
           pushi 0
           callt getPoint              ; if any touches came in during the draw just ignore them
           popr r13
           popr r13
           
           pushi 0
           pushi 0
           callt gRsTouch              ; loops for us until a touch appears
           popr r13
           popr r13
           
           reset                       ; reset is the most convenient way to go back to a known state,
                                       ; since carefully cleaning up the stack and state registers would be very error-prone
           
gRsTouch:  pushr r0                    ; gets a rescaled touch, expected usage as follows:
           pushr r1                    ; pushi 0
           pushr r2                    ; pushi 0
           pushr r3                    ; callt gRsTouch
           pushr r4                    ; popr reg for y
           pushr r5                    ; popr reg for x
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           pushr r10
           pushr r11
           pushr r12
           pushr r13
           pushr r14
           pushr r15
           
rstouchlp: movspr r0
           const16 USESLOW, r1         ; slow for talking to touchscreen
           const16 S_CS2ASSERT, r12    ; chip select assert
           ;const16 0xDE2E, r13        ; SignalTap constant
           const16 S_CS2DEASSERT, r14  ; chip select deassert
           ;const16 debugwd0, r15      ; debug addr for debug writes
           ;sto r13, (r15)0            
           constl 0, r13               ; io controller addr reg
           
           callt busy                  ; wait for busy, assert chip select
           sto r12, (r13)0             ; select the chip
           
           pushi 0
           pushr r1
           callt readTS                ; read address 0 with slow mode on
           popr r1
           popr r1                     ; r1 is now the read data and temp for the rest of the routine
           
           callt busy
           sto r14, (r13)0             ; deselect the chip
           
           pushi 0
           callt gBufEmpty             ; check if the buffer is empty
           popr r1
           
           ;const16 0xCADA, r13
           ;const16 debugwd0, r15      ; SignalTap debug writes
           ;sto r13, (r15)0
           ;constl 0, r13
           
           skz r1                      ; if the buffer was not empty, skip
           jmpt rstouchlp              ; (if buffer empty = 0 the buffer must be occupied)
           
           ; sto r14, (r15)0
           
           pushi 0
           pushi 0
           callt getPoint              ; since there's something to read, go read it
           popr r2 ; y of the touch
           popr r1 ; x of the touch
           
           constl 4, r7
           
           const16 150, r8
           const16 130, r9
           
           constl 21, r10
           constl 0, r11
           constl 0, r12
           constl 8, r13
           const16 256, r14
           
           ;sto r1, (r15)0
           ;sto r2, (r15)0
           
           sub r8, r1
           sub r9, r2
           
           lsftr r7, r1
           
           move r2, r11
           multl r10, r11
           move r2, r12
           multh r10, r12
           
           lsftr r13, r11
           
           skz r12
           add r14, r11
           
           move r11, r2
           
           ; the above constants and math are the result of several things:
           ;  1. The minimum x value for a TS read is 150
           ;  2. The minimum y value for a TS read is 130
           ;  3. The maximum x value for a TS read is 4000
           ;  4. The maximum y value for a TS read is 3800
           ; to account for this, we first subtract off the minimums. Then,
           ; we shift x right by 4 (divide by 16) since 1/16 is a decent approximation of 240/3850
           ; (240 from the LCD x max, 3850 from 4000 - 150 for real TS x range)
           ; To fix the y, we multiply by 21 across two registers, then shift the low word down 8 (divide by 256)
           ; and add in the high word only if it wasn't 0. This all comes out to 21/256, which is a decent approximation
           ; of 320/3670 (320 for LCD y max, 3670 from 3800 - 130 for real TS y range)
           
           sto r1, (r0)19              ; store the x, then the y - remember to read them in reverse!
           sto r2, (r0)18
           
           popr r15
           popr r14
           popr r13
           popr r12
           popr r11
           popr r10
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
drrun:     pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           pushr r10
           
           movspr r0
           ldo r1, (r0)18              ; table base
           ldo r2, (r0)17              ; x of window
           ldo r3, (r0)16              ; y of window
           ldo r4, (r0)15              ; w of window
           ldo r5, (r0)14              ; h of window
           ldo r6, (r0)13              ; chosen color
           const16 ILI9341_WHITE, r10
           
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           callt setaw                 ; set the addr window for the current paint from the args
           popr r9
           popr r9
           popr r9
           popr r9
           
           constl 0, r2
           constl 1, r3
           
           move r6, r8                 ; preserve the chosen color in r8, since we'll have to flip it to white in the future
tablelp:   ldo r7, (r1)0
           sknz r7
           jmpt qtablelp               ; load the current run
           
           pushr r8
           pushi 0
           pushr r7
           callt wrcolor               ; write the active color for as long as the run specifies 
           popr r9
           popr r9
           popr r9
           
           xor r3, r2                  ; flip r2, so that we toggle the color in the skips
           
           skz r2
           move r10, r8                ; load white on even
           
           sknz r2
           move r6, r8                 ; load active on odd
           
           inc r1                      ; move the table base since we can't offset by registers - have to use constant offset 0, compensate by moving base
           jmpt tablelp
           
qtablelp:  popr r10
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
startbtnc: pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           
           movspr r0
           ldo r1, (r0)13              ; x of touch
           ldo r2, (r0)12              ; y of touch
           constl 60, r3               ; x1 center
           const16 180, r4             ; x2 center
           const16 283, r5             ; y center
           constl 37, r6               ; y tolerance
           constl 60, r7               ; x tolerance
           constl 0, r8                ; temp for x
           constl 0, r9                ; temp for y
           
           move r1, r8
           move r2, r9
           
           sub r3, r8                  ; find distance in x
           sub r5, r9                  ; find distance in y
           
           skpl r8                     ; negate on negative, cheap absolute value
           neg r8
           
           skpl r9
           neg r9
           
           sklt r8, r7                 ; if we aren't less than the x tolerance then try the other button
           jmpt bttn2
           
           sklt r9, r6                 ; same but for the y tolerance
           jmpt bttn2
           
           constl 0, r9                ; must have been button 0, set the flag and jump down
           jmpt clnsbtnc
           
bttn2:     move r1, r8
           move r2, r9
           
           sub r4, r8
           sub r5, r9
           
           skpl r8
           neg r8
           
           skpl r9
           neg r9                      ; all same code as above, but using a different x of center
           
           sklt r8, r7                 ; if either tolerance is violated, set no button
           jmpt nobttn
           
           sklt r9, r6
           jmpt nobttn
           
           constl 1, r9                ; must have been button 1
           jmpt clnsbtnc
           
nobttn:    constl -1, r9
           
clnsbtnc:  sto r9, (r0)14              ; whatever flag we chose, put it in the return slot and then pop
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
LCDmain:   callt initscr               ; test code for the LCD, initialize the LCD
           
           callt drawlines             ; build lines
           
           constl 0, r0
           constl 9, r1
           constl 1, r2
           
fillloop:  sklt r0, r1                 ; fill with alternating xs and os to test drawing, indices
           jmpt end
           
           move r0, r3
           and r2, r3
           sknz r3
           jmpt x
           
           pushr r0
           callt drcirci
           popr r15
           jmpt f
           
x:         pushr r0
           pushi stdlinew
           callt drxi
           popr r15
           popr r15
           
f:         inc r0
           
           jmpt fillloop
           
end:       halt                        ; halt at end of test
           
initscr:   pushr r0                    ; based on Adafruit C library code

           callt begin                 ; read initialization instruction table
           
           pushi 0
           callt setrt                 ; set no rotation
           popr r0
           
           pushi 0
           callt invert                ; set no color inversion
           popr r0
           
           pushi 0
           callt scrollto              ; scroll to 0
           popr r0
           
           pushi 0
           pushi 0
           pushi 400
           pushi 400
           callt setaw                 ; set large address window to catch full screen
           popr r0
           popr r0
           popr r0
           popr r0
           
           const16 ILI9341_WHITE, r0    ; this can be changed to any color
           pushr r0
           pushi 2
           pushi 0
           callt wrcolor               ; write white everywhere to clear screen
           popr r0
           popr r0
           popr r0
           
           popr r0
           
           retn

delay:     pushr r0
           constl 16, r0
dloop:     sknz r0
           jmpt qdelay
           dec r0                      
           jmpt dloop
qdelay:    popr r0
           retn
           
ndelay:    pushr r0                    ; n = 30000 ~= 0.1 seconds
           pushr r1
           
           movspr r0
           ldo r1, (r0)4
nloop:     sknz r1
           jmpt qndelay
           callt delay
           dec r1
           jmpt nloop
qndelay:   popr r1
           popr r0
           retn
           
busy:      pushr r0
busyloop:  constl 0, r0
           ldo r0, (r0)2               ; fetch busy and skip on it not being set - as bit 15 it makes the value negative if set
           skpl r0
           jmpt busyloop
           
           popr r0
           retn
           
readTS:    pushr r0                    ; reading from TS
           pushr r1                    ; based on Adafruit C library code
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           
           movspr r0
           ldo r1, (r0)12
           constl 0, r2                ; here's where we put the ands with the byte, by moving
           const16 0x80, r3            ; anding constant
           constl 16, r4               ; loop variable - this will also clock 8 0's out after the addr
           constl 0, r5                ; for retn accumulated from controller
           constl 0, r6                ; to stay at 0, for addressing the controller
           constl 0, r7                ; to const16 values to write to the controller
           constl 1, r8                ; to stay at 1, for shifts and ands
           constl 0, r9                ; values coming back from controller
           
rbitloop:  sknz r4
           jmpt raloop 
           
           move r1, r2
           and r3, r2
           sknz r2
           jmpt rsetlow
           
           const16 S_MOSIHIGH, r7
           callt busy
           sto r7, (r6)0
           jmpt rsck
           
rsetlow:   const16 S_MOSILOW, r7
           callt busy
           sto r7, (r6)0
           
rsck:      const16 S_SCKHIGH, r7
           callt busy
           sto r7, (r6)0
           
           lsftl r8, r1
           const16 S_SCKLOW, r7
           callt busy
           sto r7, (r6)0
           dec r4                      ; read after the decrements because the last bit comes out post-dec 0
           pushr r4
           popr r4
           
           ldo r9, (r6)1               ; load from controller
           lsftl r8, r5                ; shift in a  blank space
           and r8, r9                  ; mask all but the miso
           ior r9, r5                  ; or in the new bit
           
           jmpt rbitloop
           
raloop:    sto r5, (r0)13
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
writeTS:   pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           
           movspr r0
           ldo r1, (r0)8               ; the address to write this byte to
           ldo r2, (r0)7               ; the byte to write
           constl 0, r3                ; temps, stack
           constl 0, r4                ; write to the controller
           
           const16 S_CS2ASSERT, r3
           callt busy
           sto r3, (r4)0
           
           pushr r1
           const16 USESLOW, r3
           pushr r3
           callt writeByte             ; write the addr byte out
           popr r3
           popr r3
           
           pushr r2
           const16 USESLOW, r3
           pushr r3
           callt writeByte             ; write the data byte out
           popr r3
           popr r3
           
           const16 S_CS2DEASSERT, r3
           callt busy
           sto r3, (r4)0               ; manually disable the chip select to end the write
           
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
writeByte: pushr r0                    ; based on Adafruit C library code
           pushr r1                    ; assumes d/c and cs handled by caller
           pushr r2
           pushr r3
           
           movspr r0
           ldo r1, (r0)7               ; byte to write
           ldo r2, (r0)6               ; use slow mask
           constl 1, r3                ; to write to the controller
           
           ior r2, r1
           callt busy
           sto r1, (r3)0
           
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
writeWord: pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           
           movspr r0
           ldo r1, (r0)8
           constl 0, r2                ; for moving before first call & removing stack bloat
           constl 8, r3                ; shift constant
           ldo r4, (r0)7               ; slowmask for writes
           
           move r1, r2
           lsftr r3, r2
           
           pushr r2
           pushr r4
           callt writeByte
           popr r2                     ; to not pollute the stack
           popr r2
           
           pushr r1                    ; writeByte writes low 8, so no need to mask high byte of r1
           pushr r4
           callt writeByte
           popr r2
           popr r2
           
           popr r4                     ; stack hygiene
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
sendComm:  pushr r0                    ; based on Adafruit C library code       
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           ldo r1, (r0)8               ; r1 is the command byte
           ldo r2, (r0)9               ; r2 is the data_count (also data offset, which has to be done a little differently)
           constl 0, r3                ; r3 is for addressing the controller
           constl 0, r4                ; r4 is for values going to the controller
           constl 0, r5                ; r5 is for stack hygiene, other constants
           
           const16 CS1ASSERT, r4
           callt busy
           sto r4, (r3)0
           
           const16 DCLOW, r4
           callt busy
           sto r4, (r3)0
           
           pushr r1
           pushi 0
           callt writeByte
           popr r5
           popr r5
           
           const16 DCHIGH, r4
           callt busy
           sto r4, (r3)0
           
           constl 9, r5                ; argc offset
           add r5, r0                  ; literally shift the stack frame up to the argc
           add r2, r0                  ; we're now at the top of the data segment
           
dataWloop: sknz r2                     ; post-decrement r2 to check how many data bytes have been written
           jmpt afterwl
           
           ldo r4, (r0)0               ; r0 was at the top of the argv segment, and is post-decremented
           pushr r4
           pushi 0
           callt writeByte
           popr r5
           popr r5
           
           dec r0                      ; move to next data byte, down stack so we didn't have to push them in reverse
           dec r2                      ; dec argc so that we know when to stop
           jmpt dataWloop
           
afterwl:   const16 CS1DEASSERT, r4
           callt busy
           sto r4, (r3)0
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
begin:     pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           
           const16 150, r0             ; delay values, where n = us delay
           const16 baseaddr, r1        ; to address to data memory
           const16 0x0000, r2          ; to address the controller
           constl 0, r3                ; for things that come back from data mem
           constl 0, r4                ; for things that go out to data mem
           const16 0xfff, r5           ; for checking if we hit the sentinel
           const16 0x80, r6            ; for wait checking
           constl 0, r7                ; stack hygiene
           const16 0xffff, r8          ; big sentinel check
           constl 0, r9                ; to count arguments that went up on the stack
           
           const16 ILI9341_SWRESET, r4 ; send out a software reset on its own
           pushi 0                     ; don't push any data, just push a 0 for argc
           pushr r4
           callt sendComm
           popr r7
           popr r7
           
           const16 60000, r0           ; delay after reset as recommended by Adafruit
           pushr r0
           callt ndelay
           popr r0
           
initloop:  ldo r3, (r1)0
           skne r3, r8
           jmpt qinitloop
           
           skne r3, r5
           jmpt makecall
           
           pushr r3
           inc r9
           inc r1
           jmpt initloop
           
makecall:  callt sendComm
cleanuplc: sknz r9
           jmpt initfoot
           
           popr r7
           dec r9                      ; r9 is guaranteed to be back at 0 when we get out of here 
           jmpt cleanuplc
           
initfoot:  inc r1                      ; r1 is not incremented on r3 = r5, so we know we have to do it here
           jmpt initloop
           
qinitloop: popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
setrt:     pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           
           movspr r0
           ldo r1, (r0)7
           constl 3, r2
           const16 debugwd0, r3
           const16 0xC0DE, r4
           
           ;sto r4, (r3)0
           ;sto r1, (r3)0
           ;sto r2, (r3)0
           and r2, r1
           ;sto r1, (r3)0
           ;const16 0xD4C4, r4
           ;sto r4, (r3)0
           
           constl 0, r2
           skeq r1, r2
           jmpt case1
           const16 MADCTL_MX, r1       ; load flags and ior them - set multiple config bits based on the value loaded in r1
           const16 MADCTL_BGR, r2
           ior r2, r1
           jmpt postcase
           
case1:     constl 1, r2
           skeq r1, r2
           jmpt case2
           const16 MADCTL_MV, r1
           const16 MADCTL_BGR, r2
           ior r2, r1
           jmpt postcase
           
case2:     constl 2, r2
           skeq r1, r2
           jmpt case3
           const16 MADCTL_MY, r1
           const16 MADCTL_BGR, r2
           ior r2, r1
           jmpt postcase
           
case3:     constl 3, r2
           skeq r1, r2
           jmpt badbad
           const16 MADCTL_MX, r1
           const16 MADCTL_MY, r2
           ior r2, r1
           const16 MADCTL_MV, r2
           ior r2, r1
           const16 MADCTL_BGR, r2
           ior r2, r1
           jmpt postcase
           
badbad:    halt                        ; if we get here either and doesn't work (processor bug) or the pc is on the fritz (stack frame problem)
           
postcase:  const16 ILI9341_MADCTL, r2
           pushr r1
           pushi 1
           pushr r2
           callt sendComm              ; send the command we were building up above
           popr r2
           popr r2
           popr r2
           
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
invert:    pushr r0                    ; based on Adafruit C library code
           pushr r1                    ; push registers onto the stack to preserve their pre-call vals
           pushr r2                    ; and free them up for use in the subroutine body
           
           movspr r0                   ; load the base pointer for the stack frame
           ldo r1, (r0)5               ; load an argument offset from the bp
           constl 0, r2                ; load a constant into the low byte of a register
           skz r1                      ; skip on the register == 0 
           constl ILI9341_INVON, r2    ; load "ON" if register != 0 (otherwise we would have skipped!) 
           sknz r1                     ; skip on the register != 0 (exclusive with above skip)
           constl ILI9341_INVOFF, r2   ; load "OFF" if the register == 0 (otherwise we would have skipped!)
           
           pushi 0                     ; push a constant 0 for the argc (no additional data bytes)
           pushr r2                    ; push the ON/OFF flag for the command argument
           callt sendComm              ; call into a subroutine
           popr r2                     ; pop each argument off the stack to avoid damaging the stack frame
           popr r2
           
           popr r2                     ; pop the registers we pushed on top to restore their values
           popr r1                     ; (note the reverse pop order as we go up the stack)
           popr r0
           
           retn                        ; return (this will return to whatever is at the sp -- 
                                       ; would be very bad if we hadn't cleaned up our arguments above!)
           
scrollto:                              ; pushr y
                                       ; callt scrollto
           pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           ldo r1, (r0)8
           const16 ILI9341_VSCRSADD, r2
           constl 8, r3
           const16 0x00ff, r4
           constl 0, r5
           
           move r1, r5
           and r4, r5                  ; r5 is the low byte
           lsftr r3, r1                ; r1 is the high byte
           
           pushr r1
           pushr r5
           pushi 2
           pushr r2
           callt sendComm              ; push both, send scroll command
           popr r5
           popr r5
           popr r5
           popr r5
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
setaw:     pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           
           movspr r0
           ldo r1, (r0)14              ; x1
           ldo r2, (r0)13              ; y1
           ldo r3, (r0)12              ; w
           ldo r4, (r0)11              ; h
           constl 0, r5
           
           move r1, r6
           add r3, r6                  ; add x1 + w
           dec r6                      ; -1 = x2
           
           move r2, r7                 
           add r4, r7                  ; add y1 + h
           dec r7                      ; -1 = y2
           
           const16 CS1ASSERT, r8
           callt busy
           sto r8, (r5)0
           
           const16 DCLOW, r8
           callt busy
           sto r8, (r5)0
           
           const16 ILI9341_CASET, r8
           pushr r8
           pushi 0
           callt writeByte
           popr r8
           popr r8
           
           const16 DCHIGH, r8
           callt busy
           sto r8, (r5)0
           
           pushr r1
           pushi 0
           callt writeWord             ; write x1
           popr r8
           popr r8
           
           pushr r6
           pushi 0
           callt writeWord             ; write x2
           popr r8
           popr r8
           
           const16 CS1DEASSERT, r8
           callt busy
           sto r8, (r5)0
           
           
           
           const16 CS1ASSERT, r8
           callt busy
           sto r8, (r5)0
           
           const16 DCLOW, r8
           callt busy
           sto r8, (r5)0
           
           const16 ILI9341_PASET, r8
           pushr r8
           pushi 0
           callt writeByte
           popr r8
           popr r8
           
           const16 DCHIGH, r8
           callt busy
           sto r8, (r5)0
           
           pushr r2
           pushi 0
           callt writeWord             ; write y1
           popr r8
           popr r8
           
           pushr r7
           pushi 0
           callt writeWord             ; write y2
           popr r8
           popr r8
           
           const16 CS1DEASSERT, r8
           callt busy
           sto r8, (r5)0
           
           const16 ILI9341_RAMWR, r8
           pushi 0
           pushr r8
           callt sendComm              ; read ram for extra stability, recommended by Adafruit sample code
           popr r8
           popr r8
           
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
wrcolor:   pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           ldo r1, (r0)10              ; color
           ldo r2, (r0)9               ; msw of len
           ldo r3, (r0)8               ; lsw of len
           constl 0, r4
           constl 0, r5
           
           const16 CS1ASSERT, r5
           callt busy
           sto r5, (r4)0
           
           const16 DCHIGH, r5
           callt busy
           sto r5, (r4)0
           
colorloop: sknz r3
           jmpt decupper
           
declower:  dec r3
           pushr r1
           pushi 0                     ; the mask - no need to use slow here
           callt writeWord
           popr r5
           popr r5
           jmpt colorloop
           
decupper:  dec r2
           skpl r2
           jmpt qcloop
           jmpt declower               ; the point of declower and decupper is to emulate 32 bit math.
                                       ; It counts down in lower until it hits 0,
                                       ; and then decs upper and resets lower to ffff by decrementing it too
           
qcloop:    const16 CS1DEASSERT, r5
           callt busy
           sto r5, (r4)0
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
wrFRP:     pushr r0                    ; writes a rectangle, largely a legacy method from debugging
           pushr r1                    ; based on Adafruit C library code
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           
           movspr r0
           ldo r1, (r0)13              ; x
           ldo r2, (r0)12              ; y
           ldo r3, (r0)11              ; w
           ldo r4, (r0)10              ; h
           ldo r5, (r0)9               ; color
           constl 0, r6
           
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           callt setaw
           popr r6
           popr r6
           popr r6
           popr r6
           
           pushr r5
           
           const16 0xffff, r6
           pushi 0
           pushr r6
           
           ; move r3, r6
           ; multh r4, r6
           ; pushr r6
           
           ; move r3, r6
           ; multl r4, r6
           ; pushr r6
           
           callt wrcolor
           
           popr r6
           popr r6
           popr r6
           
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
dcircle:   pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           pushr r10
           pushr r11
           
           movspr r0
           ldo r1, (r0)15              ; x of top-left corner
           ldo r2, (r0)14              ; y of top-left corner
           const16 octblbase, r3       ; outer circle table base
           constl octbllen, r4         ; outer circle table length
           const16 ictblbase, r5       ; inner circle table base
           constl ictbllen, r6         ; inner circle table length
           constl 0, r7                ; y val from tables
           constl 0, r8                ; min x val offset from tables
           constl 0, r9                ; max x val offset from tables
           constl 0, r10               ; temps
           constl 0, r11               ; stack pops, temps
           
odrloop:   sknz r4                     ; drawing outer circle loop
           jmpt idrloop
           
           ldo r7, (r3)0
           ldo r8, (r3)1
           ldo r9, (r3)2
           
           move r1, r10
           add r8, r10                 ; x coord of min for this row
           pushr r10
           
           move r2, r10
           add r7, r10                 ; y coord for this whole row
           pushr r10
           
           move r9, r10
           sub r8, r10
           inc r10                     ; r10 is now the len for writecolor, also width
           pushr r10
           
           pushi 1
           callt setaw
           popr r11
           popr r11
           popr r11
           popr r11
           
           const16 ILI9341_BLUE, r11
           pushr r11
           pushi 0
           pushr r10                   ; no msw for len, since they all fit in r10
           callt wrcolor
           popr r11
           popr r11
           popr r11
           
           dec r4
           inc r3
           inc r3
           inc r3
           jmpt odrloop
           
idrloop:   sknz r6                     ; drawing inner circle loop
           jmpt qdrloop
           
           ldo r7, (r5)0
           ldo r8, (r5)1
           ldo r9, (r5)2
           
           move r1, r10
           add r8, r10                 ; x coord of min for this row
           pushr r10
           
           move r2, r10
           add r7, r10                 ; y coord for this whole row
           pushr r10
           
           move r9, r10
           sub r8, r10
           inc r10                     ; r10 is now the len for writecolor, also width
           pushr r10
           
           pushi 1
           callt setaw
           popr r11
           popr r11
           popr r11
           popr r11
           
           const16 ILI9341_WHITE, r11
           pushr r11
           pushi 0
           pushr r10                   ; no msw for len, since they all fit in r10
           callt wrcolor
           popr r11
           popr r11
           popr r11
           
           dec r6
           inc r5
           inc r5
           inc r5
           jmpt idrloop
           
qdrloop:   popr r11
           popr r10
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
drawpixel: pushr r0
           pushr r1
           pushr r2
           pushr r3
           
           movspr r0
           ldo r1, (r0)8               ; x
           ldo r2, (r0)7               ; y
           ldo r3, (r0)6               ; color
           pushr r1
           pushr r2
           pushi 1
           pushi 1
           callt setaw
           popr r10
           popr r10
           popr r10
           popr r10
           
           pushr r3
           pushi 0
           pushi 1
           callt wrcolor
           popr r3
           popr r3
           popr r3
           
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
drawxyl:   pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           
           movspr r0
           ldo r1, (r0)15              ; x
           ldo r2, (r0)14              ; y
           ldo r3, (r0)13              ; dx
           ldo r4, (r0)12              ; dy
           ldo r5, (r0)11              ; len
           ldo r6, (r0)10              ; color
           constl 0, r7                ; temps
           
drxylloop: constl 0, r7
           skgt r5, r7
           jmpt qdrawxyl
           
           pushr r1
           pushr r2
           pushr r6
           callt drawpixel
           popr r7
           popr r7
           popr r7
           
           add r3, r1
           add r4, r2
           dec r5
           
           jmpt drxylloop
           
qdrawxyl:  popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
dx:        pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           
           movspr r0
           ldo r1, (r0)13              ; initial x
           ldo r2, (r0)12              ; initial y
           ldo r3, (r0)11              ; line width
           constl BOXSIZE, r4          ; box size
           constl 0, r5                ; active x value
           constl 0, r6                ; len limit
           constl 0, r7                ; loop counter
           constl 0, r8                ; temps
           
           move r1, r5
           move r4, r6
           
downright: sklt r7, r3
           jmpt downleft
           
           pushr r5
           pushr r2
           pushi 1
           pushi 1
           pushr r6
           const16 ILI9341_RED, r8
           pushr r8
           callt drawxyl
           popr r8
           popr r8
           popr r8
           popr r8
           popr r8
           popr r8
           
           inc r5
           dec r6
           inc r7
           jmpt downright
           
downleft:  constl 0, r7                ; reset the loop counter
           add r4, r1                  ; move x to other side of box
           dec r1                      ; decrement to avoid pickett fence error
           
           move r1, r5
           move r4, r6
           
downlloop: sklt r7, r3
           jmpt qdx
           
           pushr r5
           pushr r2
           pushi -1
           pushi 1
           pushr r6
           const16 ILI9341_RED, r8
           pushr r8
           callt drawxyl
           popr r8
           popr r8
           popr r8
           popr r8
           popr r8
           popr r8
           
           dec r5
           dec r6
           inc r7
           jmpt downlloop
           
qdx:       popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
drawlines: pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           
           const16 linetable, r0       ; table base
           move r0, r1                 ; current item
           constl 0, r2                ; loop counter
           constl 10, r3               ; loop limit
           constl 0, r4                ; temps
           
xlineslp:  sklt r2, r3
           jmpt qxlineslp
           
           ldo r4, (r1)0
           pushr r4
           pushi 0
           pushi 0
           pushi 1
           pushi 240
           const16 ILI9341_BLACK, r4
           pushr r4
           callt drawxyl               ; draws lines in x out of the table
           popr r4
           popr r4
           popr r4
           popr r4
           popr r4
           popr r4
           
           inc r1
           inc r2
           jmpt xlineslp
           
qxlineslp: constl 0, r2                ; reset loop counter
           move r0, r1                 ; reset table base, so that the same values are used in y (makes the grid square)
ylineslp:  sklt r2, r3
           jmpt qdrlines
           
           pushi 0
           ldo r4, (r1)0
           pushr r4
           pushi 1
           pushi 0
           pushi 240
           const16 ILI9341_BLACK, r4
           pushr r4
           callt drawxyl               ; draw in the y lines
           popr r4
           popr r4
           popr r4
           popr r4
           popr r4
           popr r4
           
           inc r1
           inc r2
           jmpt ylineslp
           
qdrlines:  popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
drcirci:   pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           
           movspr r0
           ldo r1, (r0)7               ; index
           const16 drawtable, r2
           add r1, r2                  ; add the index into the base
           ldo r2, (r2)0               ; we loaded the table base, added in the index, and then loaded that into itself - end result is indirecting off a table value
           ldo r3, (r2)0               ; x
           ldo r4, (r2)1               ; y
           
           pushr r3
           pushr r4
           callt dcircle
           popr r4
           popr r4
           
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
drxi:      pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           ldo r1, (r0)9               ; index
           const16 drawtable, r2
           add r1, r2
           ldo r2, (r2)0               ; we loaded the table base, added in the index, and then loaded that into itself - end result the same, in-place indirection
           ldo r3, (r2)0               ; x
           ldo r4, (r2)1               ; y
           ldo r5, (r0)8               ; line width
           
           pushr r3
           pushr r4
           pushr r5
           callt dx
           popr r4
           popr r4
           popr r4
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
beginTS:   pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r15
           pushr r14
           pushr r13
           
           ;const16 debugwd0, r13
           ;const16 0xF110, r14
           ;sto r14, (r13)0
           
           const16 STMPE_SYS_CTRL2, r0 ; load and send initialization instructions to TS - don't change these
           constl 0, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_TSC_CTRL, r0
           const16 STMPE_TSC_CTRL_XYZ, r1
           const16 STMPE_TSC_CTRL_EN, r2
           ior r2, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_INT_EN, r0
           const16 STMPE_INT_EN_TOUCHDET, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_ADC_CTRL1, r0
           const16 STMPE_ADC_CTRL1_10BIT, r1
           constl 4, r2
           constl 6, r3
           lsftl r3, r2
           ior r2, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_ADC_CTRL2, r0
           const16 STMPE_ADC_CTRL2_6_5MHZ, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_TSC_CFG, r0
           const16 STMPE_TSC_CFG_4SAMPLE, r1
           const16 STMPE_TSC_CFG_DELAY_1MS, r2
           const16 STMPE_TSC_CFG_SETTLE_5MS, r3
           ior r3, r1
           ior r2, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_TSC_FRACTION_Z, r0
           constl 6, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_FIFO_TH, r0
           constl 1, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_FIFO_STA, r0
           const16 STMPE_FIFO_STA_RESET, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_FIFO_STA, r0
           constl 0, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_TSC_I_DRIVE, r0
           const16 STMPE_TSC_I_DRIVE_50MA, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_INT_STA, r0
           const16 0xff, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           const16 STMPE_INT_CTRL, r0
           const16 STMPE_INT_CTRL_POL_HIGH, r1
           const16 STMPE_INT_CTRL_ENABLE, r2
           ior r2, r1
           pushr r0
           pushr r1
           callt writeTS
           popr r15
           popr r15
           
           ;const16 0xEF1D, r14
           ;sto r14, (r13)0
           
           popr r13
           popr r14
           popr r15
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
gTouched:  pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           const16 STMPE_TSC_CTRL, r1
           const16 0x80, r2
           ior r2, r1
           constl 0, r4
           
           const16 S_CS2ASSERT, r5
           callt busy
           sto r5, (r4)0
           
           pushi 0
           pushr r1
           callt readTS                ; read the ctrl reg for flags
           popr r3
           popr r3
           
           const16 S_CS2DEASSERT, r5
           callt busy
           sto r5, (r4)0
           
           ;const16 debugwd0, r5
           ;sto r3, (r5)0
           
           and r2, r3                  ; mask off high bit for touched status
           sto r3, (r0)8
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
gBufEmpty: pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           const16 STMPE_FIFO_STA, r1
           const16 0x80, r2
           ior r2, r1                  ; force the high bit to be 1 for a read cycle
           const16 STMPE_FIFO_STA_EMPTY, r2
           constl 0, r4
           
           const16 S_CS2ASSERT, r5
           callt busy
           sto r5, (r4)0
           
           pushi 0
           pushr r1
           callt readTS                ; read flags
           popr r3
           popr r3
           
           const16 S_CS2DEASSERT, r5
           callt busy
           sto r5, (r4)0
           
           and r2, r3                  ; mask
           
           sto r3, (r0)8
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
gBufSize:  pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           
           movspr r0
           const16 STMPE_FIFO_SIZE, r1
           const16 0x80, r2
           ior r2, r1
           constl 0, r2
           constl 0, r3
           
           const16 S_CS2ASSERT, r4
           callt busy
           sto r4, (r3)0
           
           pushi 0
           pushr r1
           callt readTS                ; read size reg for size of buffer
           popr r2
           popr r2
           
           const16 S_CS2DEASSERT, r4
           callt busy
           sto r4, (r3)0
           
           sto r2, (r0)7
           
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
readData:  pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           
           movspr r0
           constl 0, r1                ; data[0]
           constl 0, r2                ; data[1]
           constl 0, r3                ; data[2]
           constl 0, r4                ; data[3]
           const16 0xD7, r5
           constl 0, r8                ; fixed waddr
           
           const16 S_CS2ASSERT, r9
           callt busy
           sto r9, (r8)0
           
           pushi 0
           pushr r5
           callt readTS                ; read all the data flags
           popr r1
           popr r1
           
           const16 S_CS2DEASSERT, r9
           callt busy
           sto r9, (r8)0
           
           
           
           const16 S_CS2ASSERT, r9
           callt busy
           sto r9, (r8)0
           
           pushi 0
           pushr r5
           callt readTS
           popr r2
           popr r2
           
           const16 S_CS2DEASSERT, r9
           callt busy
           sto r9, (r8)0
           
           
           
           const16 S_CS2ASSERT, r9
           callt busy
           sto r9, (r8)0
           
           pushi 0
           pushr r5
           callt readTS
           popr r3
           popr r3
           
           const16 S_CS2DEASSERT, r9
           callt busy
           sto r9, (r8)0
           
           
           
           const16 S_CS2ASSERT, r9
           callt busy
           sto r9, (r8)0
           
           pushi 0
           pushr r5
           callt readTS
           popr r4
           popr r4
           
           const16 S_CS2DEASSERT, r9
           callt busy
           sto r9, (r8)0
           
           const16 0x00ff, r8
           and r8, r1
           and r8, r2
           and r8, r3
           and r8, r4
           
           const16 debugwd0, r8
           ;sto r1, (r8)0
           ;sto r2, (r8)0
           ;sto r3, (r8)0
           ;sto r4, (r8)0
           
           constl 4, r6                ; fetch, shift, and mask out 12 bit fields
           lsftl r6, r1
           move r2, r7
           lsftr r6, r7
           ior r7, r1                  ; r1 = x now
           
           constl 0x0f, r6
           and r6, r2
           constl 8, r6
           lsftl r6, r2
           ior r3, r2                  ; r2 = y now
           
           sto r1, (r0)14              ; r4 = z because it already has data[3] 
           sto r2, (r0)13
           sto r4, (r0)12
           
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
getPoint:  pushr r0                    ; based on Adafruit C library code
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           
           movspr r0
           constl 0, r1
           constl 0, r2
           constl 0, r3
           
readaloop: pushi 0
           callt gBufEmpty
           popr r1
           
           skz r1
           jmpt finalread
           
           pushi 0
           pushi 0
           pushi 0
           callt readData
           popr r4
           popr r3
           popr r2
           
           jmpt readaloop 
           
finalread: const16 STMPE_INT_STA, r5
           const16 0xff, r1
           
           pushr r5
           pushr r1
           callt writeTS
           popr r1
           popr r1
           
           sto r2, (r0)9
           sto r3, (r0)8
           
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn
           
touchtoi:  pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           pushr r10
           pushr r11
           pushr r12
           
           movspr r0
           ldo r1, (r0)16              ; touchscreen rescaled x
           ldo r2, (r0)15              ; touchscreen rescaled y
           const16 tstable, r3         ; touchscreen table base
           constl 0, r4                ; touchscreen table values
           constl 0, r5                ; x of center
           constl 0, r6                ; y of center
           constl 0, r7                ; index into tstable, in parallel with r3 increments
           constl 38, r8               ; 38, pure constant for distance comparisons
           constl 9, r9                ; 9, loop limit
           constl -1, r10              ; retv, not changed if we didn't find a value
           const16 debugwd0, r11
           const16 0xD1CE, r12
           
tableloop: sklt r7, r9
           jmpt qtouchi
           ldo r4, (r3)0
           ldo r5, (r4)0
           ldo r6, (r4)1
           
           sub r1, r5                  ; overwrite the table value with the difference
           skpl r5
           neg r5                      ; cheap abs, negate if negative
           
           sub r2, r6
           skpl r6
           neg r6
           
           sto r12, (r11)0
           sto r5, (r11)0
           sto r6, (r11)0
           
           sklt r5, r8
           jmpt tslfoot
           
           sklt r6, r8
           jmpt tslfoot
           
           jmpt foundval
           
tslfoot:   inc r7
           inc r3
           
           jmpt tableloop
           
foundval:  move r7, r10

           const16 0xBADE, r12
           sto r12, (r11)0
           sto r7, (r11)0
           sto r10, (r11)0

           jmpt qtouchi
           
qtouchi:   sto r10, (r0)17             ; store the winning value (or -1)
           
           popr r12
           popr r11
           popr r10
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
           retn

ttt_engine:
           pushr r0
           pushr r1
           pushr r2
           pushr r3
           pushr r4
           pushr r5
           pushr r6
           pushr r7
           pushr r8
           pushr r9
           pushr r10
           pushr r11
           pushr r12
           pushr r13
           pushr r14
           pushr r15
           
           movspr r0                   ; r0 = stack pointer (offset 18 for maddr, 19 for os, 20 for xs, 21 for retv)
           const16 depthword, r15
           ldo r1, (r15)0
           inc r1
           sto r1, (r15)0
           ldo r1, (r0)20              ; r1 = xs
           ldo r2, (r0)19              ; r2 = os
           const16 debugwd2, r3        ; debug writes
           sto r1, (r3)0
           sto r2, (r3)0
           constl 0, r3                ; r3 = dummy, set later by looking down the stack
           constl 0, r4                ; r4 = retv, just to have it
           move r1, r5                 ; r5 = occupied, move then or
           ior r2, r5                  ; r5 = r1 | r2
           const16 0x01ff, r6          ; load a constant
           xor r5, r6                  ; xor r5 into r6, now making r6 = available
                                       ; don't do anything to move right now since we don't have to
                                       ; o always moved last, we move as x
           
           sto r3, (r0)18              ; because move needs to come back as zero if we didn't play
           
           
           pushi 0
           pushr r2
           callt checkwin
           popr r9
           popr r9
           
           skz r9
           jmpt owon
           sknz r6
           jmpt full
           
                                       ; being down here means o didn't win and the board isn't full (the else)
           
                                       ; setup while constants
           constl -2, r10              ; r10 = best
           constl 1, r11               ; r11 = mask
           const16 01000, r12          ; r12 is a constant we need later
           constl 1, r13               ; r13 = 1
  
  
whilehead:
           skne r11, r12               ; mask != 01000
           jmpt postwhile
           skne r10, r13               ; best != 1
           jmpt postwhile
           
                                       ; being here means mask != 01000 and best != 1
           move r11, r14               ; move mask over
           and r5, r14                 ; r14 = mask & occupied
           skz r14
           jmpt moveshift
           
                                       ; being here means we're on r = -eval
           pushi 0                     ; space for retv
           pushr r2                    ; os for xs
           
           move r1, r14                ; r14 is free again, so use it to xor xs and mask
           xor r11, r14
           pushr r14                   ; xs ^ mask for os
           pushi 0                     ; space for move, since we're gonna reach down and grab it
           
                                       ; now that everybody is on the stack, call
           callt ttt_engine
           
                                       ; having come back, the sp is sitting on the old ra space, with (in ascending order) move, os, xs, and the retv above it
                                       ; in order to fetch the retv we have to go through those, and we need to save move because it was assumed we'd load it by reference passing
                                       ; but we don't have that here, so it's effectively a multiple returns situation
           popr r3                     ; put the move from the call into dummy
           popr r14                    ; pop away os, xs
           popr r14
           popr r14                    ; this one puts the retv into r14, which was freed again
           
           neg r14                     ; negate it
           skgt r14, r10               ; if r > best, don't jump away 
           jmpt moveshift
           
                                       ; r > best, make assignments
           move r14, r10               ; move r into best
           sto r11, (r0)18             ; stuff the mask onto the stack position that we fetched the move from, equivalent to move = mask
  
moveshift:
                                       ; r13 is still 1, so use it for the shift
           lsftl r13, r11
           jmpt whilehead              ; don't leave yet
  
                                       ; skipped all the debugging code, it's not really applicable in assembler where we have traces
                                       
                                       ; we're done with the loop, so now we have a few folks who need to do their things and then a cleanup
owon:                                  
                                       ; if owon up at the top, set then clean
           constl -10, r4
           ldo r1, (r15)0
           add r1, r4
           jmpt cleanup
  
full:
                                       ; if we're full, set then clean
           constl 0, r4
           jmpt cleanup
  
postwhile:
           move r10, r4                ; move the best into ret
  
cleanup:
                                       ; store the retv, reverse pop
           sto r4, (r0)21
           
           ldo r1, (r15)0
           dec r1
           sto r1, (r15)0
           
           popr r15
           popr r14
           popr r13
           popr r12
           popr r11
           popr r10
           popr r9
           popr r8
           popr r7
           popr r6
           popr r5
           popr r4
           popr r3
           popr r2
           popr r1
           popr r0
           
                                       ; return from function
           retn
  
checkwin:  pushr r0
           pushr r2
           pushr r7
           pushr r8
           pushr r9
           
           movspr r0
           ldo r2, (r0)7
           
           move r2, r7      ; r7 is a copy of os, will receive and
           const16 0700, r8 ; constants go here
           constl 0, r9     ; r9 = owin
           and r8, r7       ; r7 now contains os & 0700
           skne r7, r8      ; if the and equaled the constant, owin needs to be one and we can stop
           constl 1, r9
           skne r7, r8      ; since it's just one repetition I'm not too distraught about the double skip
           jmpt postcheck
           
           move r2, r7     
           constl 0070, r8  ; each one of these constants represents a different winning combo, ex 0070 = horizontal through the center (0b000111000)
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
             
           move r2, r7     
           constl 0007, r8 
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
             
           move r2, r7     
           const16 0444, r8
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
             
           move r2, r7     
           const16 0222, r8  
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
             
           move r2, r7     
           const16 0111, r8 
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
             
           move r2, r7     
           const16 0421, r8 
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
             
           move r2, r7     
           constl 0124, r8 
           and r8, r7      
           skne r7, r8     
           constl 1, r9
           skne r7, r8     
           jmpt postcheck
           
postcheck: sto r9, (r0)8
           
           popr r9
           popr r8
           popr r7
           popr r2
           popr r0
           
           retn
           
;-------------------------------------------------------------------------------
; 1-hot encoded flags which set and clear the various lines - high bit is whether to use the "slow" busy clock
MOSIHIGH            .eq 0b0100001000000000
MOSILOW             .eq 0b0100000000000010
SCKHIGH             .eq 0b0100000100000000
SCKLOW              .eq 0b0100000000000001
CS1DEASSERT         .eq 0b0100000000001000
CS1ASSERT           .eq 0b0100100000000000
CS2DEASSERT         .eq 0b0100000000010000
CS2ASSERT           .eq 0b0101000000000000
DCLOW               .eq 0b0100000000000100
DCHIGH              .eq 0b0100010000000000

S_MOSIHIGH          .eq 0b1100001000000000
S_MOSILOW           .eq 0b1100000000000010
S_SCKHIGH           .eq 0b1100000100000000
S_SCKLOW            .eq 0b1100000000000001
S_CS1DEASSERT       .eq 0b1100000000001000
S_CS1ASSERT         .eq 0b1100100000000000
S_CS2DEASSERT       .eq 0b1100000000010000
S_CS2ASSERT         .eq 0b1101000000000000
S_DCLOW             .eq 0b1100000000000100
S_DCHIGH            .eq 0b1100010000000000

USESLOW             .eq 0b1000000000000000

ILI9341_TFTWIDTH    .eq 240            ;//<ILI9341 max TFT width
ILI9341_TFTHEIGHT   .eq 320            ;//<ILI9341 max TFT height

ILI9341_NOP         .eq 0x00           ;//< No-op register
ILI9341_SWRESET     .eq 0x01           ;//< Software reset register
ILI9341_RDDID       .eq 0x04           ;//< Read display identification information
ILI9341_RDDST       .eq 0x09           ;//< Read Display Status

ILI9341_SLPIN       .eq 0x10           ;//< Enter Sleep Mode
ILI9341_SLPOUT      .eq 0x11           ;//< Sleep Out
ILI9341_PTLON       .eq 0x12           ;//< Partial Mode ON
ILI9341_NORON       .eq 0x13           ;//< Niormal Display Mode ON

ILI9341_RDMODE      .eq 0x0A           ;//< Read Display Power Mode
ILI9341_RDMADCTL    .eq 0x0B           ;//< Read Display MADCTL
ILI9341_RDPIXFMT    .eq 0x0C           ;//< Read Display Pixel Fiormat
ILI9341_RDIMGFMT    .eq 0x0D           ;//< Read DisplayImage Fiormat
ILI9341_RDSELFDIAG  .eq 0x0F           ;//< Read Display Self-Diagnostic Result

ILI9341_INVOFF      .eq 0x20           ;//< DisplayInversion OFF
ILI9341_INVON       .eq 0x21           ;//< DisplayInversion ON
ILI9341_GAMMASET    .eq 0x26           ;//< Gamma Set
ILI9341_DISPOFF     .eq 0x28           ;//< Display OFF
ILI9341_DISPON      .eq 0x29           ;//< Display ON

ILI9341_CASET       .eq 0x2A           ;//< Column Address Set
ILI9341_PASET       .eq 0x2B           ;//< Page Address Set
ILI9341_RAMWR       .eq 0x2C           ;//< Memory Write
ILI9341_RAMRD       .eq 0x2E           ;//< Memory Read

ILI9341_PTLAR       .eq 0x30           ;//< Partial Area
ILI9341_MADCTL      .eq 0x36           ;//< Memory Access Control
ILI9341_VSCRSADD    .eq 0x37           ;//< Vertical Scrolling Start Address
ILI9341_PIXFMT      .eq 0x3A           ;//< COLMOD: Pixel Fiormat Set

ILI9341_FRMCTR1     .eq 0xB1           ;//< Frame Rate Control (In Niormal Mode/Full Coliors)
ILI9341_FRMCTR2     .eq 0xB2           ;//< Frame Rate Control (InIdle Mode/8 colors)
ILI9341_FRMCTR3     .eq 0xB3           ;//< Frame Rate control (In Partial Mode/Full Coliors)
ILI9341_INVCTR      .eq 0xB4           ;//< DisplayInversion Control
ILI9341_DFUNCTR     .eq 0xB6           ;//< Display Function Control

ILI9341_PWCTR1      .eq 0xC0           ;//< Power Control 1
ILI9341_PWCTR2      .eq 0xC1           ;//< Power Control 2
ILI9341_PWCTR3      .eq 0xC2           ;//< Power Control 3
ILI9341_PWCTR4      .eq 0xC3           ;//< Power Control 4
ILI9341_PWCTR5      .eq 0xC4           ;//< Power Control 5
ILI9341_VMCTR1      .eq 0xC5           ;//< VCOM Control 1
ILI9341_VMCTR2      .eq 0xC7           ;//< VCOM Control 2

ILI9341_RDID1       .eq 0xDA           ;//< ReadID 1
ILI9341_RDID2       .eq 0xDB           ;//< ReadID 2
ILI9341_RDID3       .eq 0xDC           ;//< ReadID 3
ILI9341_RDID4       .eq 0xDD           ;//< ReadID 4

ILI9341_GMCTRP1     .eq 0xE0           ;//< Positive Gamma Correction
ILI9341_GMCTRN1     .eq 0xE1           ;//< Negative Gamma Correction
                                       ;    ILI9341_PWCTR6     .eq 0xFC

                                       ; Color definitions
ILI9341_BLACK       .eq 0x0000         ;//<   0,   0,   0
ILI9341_NAVY        .eq 0x000F         ;//<   0,   0, 123
ILI9341_DARKGREEN   .eq 0x03E0         ;//<   0, 125,   0
ILI9341_DARKCYAN    .eq 0x03EF         ;//<   0, 125, 123
ILI9341_MAROON      .eq 0x7800         ;//< 123,   0,   0
ILI9341_PURPLE      .eq 0x780F         ;//< 123,   0, 123
ILI9341_OLIVE       .eq 0x7BE0         ;//< 123, 125,   0
ILI9341_LIGHTGREY   .eq 0xC618         ;//< 198, 195, 198
ILI9341_DARKGREY    .eq 0x7BEF         ;//< 123, 125, 123
ILI9341_BLUE        .eq 0x001F         ;//<   0,   0, 255
ILI9341_GREEN       .eq 0x07E0         ;//<   0, 255,   0
ILI9341_CYAN        .eq 0x07FF         ;//<   0, 255, 255
ILI9341_RED         .eq 0xF800         ;//< 255,   0,   0
ILI9341_MAGENTA     .eq 0xF81F         ;//< 255,   0, 255
ILI9341_YELLOW      .eq 0xFFE0         ;//< 255, 255,   0
ILI9341_WHITE       .eq 0xFFFF         ;//< 255, 255, 255
ILI9341_ORANGE      .eq 0xFD20         ;//< 255, 165,   0
ILI9341_GREENYELLOW .eq 0xAFE5         ;//< 173, 255,  41
ILI9341_PINK        .eq 0xFC18         ;//< 255, 130, 198

MADCTL_MY           .eq 0x80           ;///< Bottom to top
MADCTL_MX           .eq 0x40           ;///< Right to left
MADCTL_MV           .eq 0x20           ;///< Reverse Mode
MADCTL_ML           .eq 0x10           ;///< LCD refresh Bottom to top
MADCTL_RGB          .eq 0x00           ;///< Red-Green-Blue pixel iorder
MADCTL_BGR          .eq 0x08           ;///< Blue-Green-Red pixel iorder
MADCTL_MH           .eq 0x04           ;///< LCD refresh right to left
BOXSIZE             .eq   77           ;///< Grid box size 
octbllen            .eq   77           ;///< Length of outer circle table
ictbllen            .eq   63           ;///< Length of inner circle table
stdlinew            .eq    9           ;///< Standard line width

STMPE_ADDR                 .eq 0x41

STMPE_SYS_CTRL1            .eq 0x03
STMPE_SYS_CTRL1_RESET      .eq 0x02

STMPE_SYS_CTRL2            .eq 0x04

STMPE_TSC_CTRL             .eq 0x40
STMPE_TSC_CTRL_EN          .eq 0x01
STMPE_TSC_CTRL_XYZ         .eq 0x00
STMPE_TSC_CTRL_XY          .eq 0x02

STMPE_INT_CTRL             .eq 0x09
STMPE_INT_CTRL_POL_HIGH    .eq 0x04
STMPE_INT_CTRL_POL_LOW     .eq 0x00
STMPE_INT_CTRL_EDGE        .eq 0x02
STMPE_INT_CTRL_LEVEL       .eq 0x00
STMPE_INT_CTRL_ENABLE      .eq 0x01
STMPE_INT_CTRL_DISABLE     .eq 0x00

STMPE_INT_EN               .eq 0x0A
STMPE_INT_EN_TOUCHDET      .eq 0x01
STMPE_INT_EN_FIFOTH        .eq 0x02
STMPE_INT_EN_FIFOOF        .eq 0x04
STMPE_INT_EN_FIFOFULL      .eq 0x08
STMPE_INT_EN_FIFOEMPTY     .eq 0x10
STMPE_INT_EN_ADC           .eq 0x40
STMPE_INT_EN_GPIO          .eq 0x80

STMPE_INT_STA              .eq 0x0B
STMPE_INT_STA_TOUCHDET     .eq 0x01

STMPE_ADC_CTRL1            .eq 0x20
STMPE_ADC_CTRL1_12BIT      .eq 0x08
STMPE_ADC_CTRL1_10BIT      .eq 0x00

STMPE_ADC_CTRL2            .eq 0x21
STMPE_ADC_CTRL2_1_625MHZ   .eq 0x00
STMPE_ADC_CTRL2_3_25MHZ    .eq 0x01
STMPE_ADC_CTRL2_6_5MHZ     .eq 0x02

STMPE_TSC_CFG              .eq 0x41
STMPE_TSC_CFG_1SAMPLE      .eq 0x00
STMPE_TSC_CFG_2SAMPLE      .eq 0x40
STMPE_TSC_CFG_4SAMPLE      .eq 0x80
STMPE_TSC_CFG_8SAMPLE      .eq 0xC0
STMPE_TSC_CFG_DELAY_10US   .eq 0x00
STMPE_TSC_CFG_DELAY_50US   .eq 0x08
STMPE_TSC_CFG_DELAY_100US  .eq 0x10
STMPE_TSC_CFG_DELAY_500US  .eq 0x18
STMPE_TSC_CFG_DELAY_1MS    .eq 0x20
STMPE_TSC_CFG_DELAY_5MS    .eq 0x28
STMPE_TSC_CFG_DELAY_10MS   .eq 0x30
STMPE_TSC_CFG_DELAY_50MS   .eq 0x38
STMPE_TSC_CFG_SETTLE_10US  .eq 0x00
STMPE_TSC_CFG_SETTLE_100US .eq 0x01
STMPE_TSC_CFG_SETTLE_500US .eq 0x02
STMPE_TSC_CFG_SETTLE_1MS   .eq 0x03
STMPE_TSC_CFG_SETTLE_5MS   .eq 0x04
STMPE_TSC_CFG_SETTLE_10MS  .eq 0x05
STMPE_TSC_CFG_SETTLE_50MS  .eq 0x06
STMPE_TSC_CFG_SETTLE_100MS .eq 0x07

STMPE_FIFO_TH              .eq 0x4A

STMPE_FIFO_SIZE            .eq 0x4C

STMPE_FIFO_STA             .eq 0x4B
STMPE_FIFO_STA_RESET       .eq 0x01
STMPE_FIFO_STA_OFLOW       .eq 0x80
STMPE_FIFO_STA_FULL        .eq 0x40
STMPE_FIFO_STA_EMPTY       .eq 0x20
STMPE_FIFO_STA_THTRIG      .eq 0x10

STMPE_TSC_I_DRIVE          .eq 0x58
STMPE_TSC_I_DRIVE_20MA     .eq 0x00
STMPE_TSC_I_DRIVE_50MA     .eq 0x01

STMPE_TSC_DATA_X           .eq 0x4D
STMPE_TSC_DATA_Y           .eq 0x4F
STMPE_TSC_FRACTION_Z       .eq 0x56

STMPE_GPIO_SET_PIN         .eq 0x10
STMPE_GPIO_CLR_PIN         .eq 0x11
STMPE_GPIO_DIR             .eq 0x13
STMPE_GPIO_ALT_FUNCT       .eq 0x17

;-------------------------------------------------------------------------------
           .data 1
           .dw 0                       ; initialization instructions, sent to the LCD controller to configure settings and defaults
           .data 0xe000      
baseaddr:  .dw 0x03, 0x80, 0x02,             3, 0xEF,             0xFFF
           .dw 0x00, 0xC1, 0x30,             3, 0xCF,             0xFFF
           .dw 0x64, 0x03, 0x12, 0x81,       4, 0xED,             0xFFF
           .dw 0x85, 0x00, 0x78,             3, 0xE8,             0xFFF
           .dw 0x39, 0x2C, 0x00, 0x34, 0x02, 5, 0xCB,             0xFFF
           .dw 0x20,                         1, 0xF7,             0xFFF
           .dw 0x00, 0x00,                   2, 0xEA,             0xFFF
           .dw 0x23,                         1, ILI9341_PWCTR1,   0xFFF
           .dw 0x10,                         1, ILI9341_PWCTR2,   0xFFF           
           .dw 0x3e, 0x28,                   2, ILI9341_VMCTR1,   0xFFF       
           .dw 0x86,                         1, ILI9341_VMCTR2,   0xFFF            
           .dw 0x48,                         1, ILI9341_MADCTL,   0xFFF            
           .dw 0x00,                         1, ILI9341_VSCRSADD, 0xFFF            
           .dw 0x55,                         1, ILI9341_PIXFMT,   0xFFF
           .dw 0x00, 0x18,                   2, ILI9341_FRMCTR1,  0xFFF
           .dw 0x08, 0x82, 0x27,             3, ILI9341_DFUNCTR,  0xFFF 
           .dw 0x00,                         1, 0xF2,             0xFFF                         
           .dw 0x01,                         1, ILI9341_GAMMASET, 0xFFF           
           .dw 0x0F, 0x31, 0x2B, 0x0C, 0x0E, 0x08, 0x4E, 0xF1, 0x37, 0x07, 0x10, 0x03, 0x0E, 0x09, 0x00, 15, ILI9341_GMCTRP1, 0xFFF
           .dw 0x00, 0x0E, 0x14, 0x03, 0x11, 0x07, 0x31, 0xC1, 0x48, 0x08, 0x0F, 0x0C, 0x31, 0x36, 0x0F, 15, ILI9341_GMCTRN1, 0xFFF
           .dw                               0, ILI9341_SLPOUT,   0xFFF               
           .dw                               0, ILI9341_DISPON,   0xFFF               
           .dw                                                    0xFFFF
depthword: .dw 0                       ; the depth of the engine recursion, tracked in memory to avoid using a register
octblbase: .dw 0, 30, 46               ; outer circle table base - for drawing a larger circle of color
           .dw 1, 26, 50
           .dw 2, 24, 52
           .dw 3, 21, 55
           .dw 4, 19, 57
           .dw 5, 18, 58
           .dw 6, 16, 60
           .dw 7, 15, 61
           .dw 8, 14, 62
           .dw 9, 12, 64
           .dw 10, 11, 65
           .dw 11, 10, 66
           .dw 12, 9, 67
           .dw 13, 9, 67
           .dw 14, 8, 68
           .dw 15, 7, 69
           .dw 16, 6, 70
           .dw 17, 6, 70
           .dw 18, 5, 71
           .dw 19, 4, 72
           .dw 20, 4, 72
           .dw 21, 3, 73
           .dw 22, 3, 73
           .dw 23, 3, 73
           .dw 24, 2, 74
           .dw 25, 2, 74
           .dw 26, 1, 75
           .dw 27, 1, 75
           .dw 28, 1, 75
           .dw 29, 1, 75
           .dw 30, 0, 76
           .dw 31, 0, 76
           .dw 32, 0, 76
           .dw 33, 0, 76
           .dw 34, 0, 76
           .dw 35, 0, 76
           .dw 36, 0, 76
           .dw 37, 0, 76
           .dw 38, 0, 76
           .dw 39, 0, 76
           .dw 40, 0, 76
           .dw 41, 0, 76
           .dw 42, 0, 76
           .dw 43, 0, 76
           .dw 44, 0, 76
           .dw 45, 0, 76
           .dw 46, 0, 76
           .dw 47, 1, 75
           .dw 48, 1, 75
           .dw 49, 1, 75
           .dw 50, 1, 75
           .dw 51, 2, 74
           .dw 52, 2, 74
           .dw 53, 3, 73
           .dw 54, 3, 73
           .dw 55, 3, 73
           .dw 56, 4, 72
           .dw 57, 4, 72
           .dw 58, 5, 71
           .dw 59, 6, 70
           .dw 60, 6, 70
           .dw 61, 7, 69
           .dw 62, 8, 68
           .dw 63, 9, 67
           .dw 64, 9, 67
           .dw 65, 10, 66
           .dw 66, 11, 65
           .dw 67, 12, 64
           .dw 68, 14, 62
           .dw 69, 15, 61
           .dw 70, 16, 60
           .dw 71, 18, 58
           .dw 72, 19, 57
           .dw 73, 21, 55
           .dw 74, 24, 52
           .dw 75, 26, 50
           .dw 76, 30, 46              ; 77 entries

ictblbase: .dw 7, 31, 45               ; inner circle table base - for drawing a smaller circle of white (BG)
           .dw 8, 27, 49
           .dw 9, 25, 51
           .dw 10, 23, 53
           .dw 11, 21, 55
           .dw 12, 20, 56
           .dw 13, 19, 57
           .dw 14, 17, 59
           .dw 15, 16, 60
           .dw 16, 15, 61
           .dw 17, 14, 62
           .dw 18, 14, 62
           .dw 19, 13, 63
           .dw 20, 12, 64
           .dw 21, 11, 65
           .dw 22, 11, 65
           .dw 23, 10, 66
           .dw 24, 10, 66
           .dw 25, 9, 67
           .dw 26, 9, 67
           .dw 27, 8, 68
           .dw 28, 8, 68
           .dw 29, 8, 68
           .dw 30, 8, 68
           .dw 31, 7, 69
           .dw 32, 7, 69
           .dw 33, 7, 69
           .dw 34, 7, 69
           .dw 35, 7, 69
           .dw 36, 7, 69
           .dw 37, 7, 69
           .dw 38, 7, 69
           .dw 39, 7, 69
           .dw 40, 7, 69
           .dw 41, 7, 69
           .dw 42, 7, 69
           .dw 43, 7, 69
           .dw 44, 7, 69
           .dw 45, 7, 69
           .dw 46, 8, 68
           .dw 47, 8, 68
           .dw 48, 8, 68
           .dw 49, 8, 68
           .dw 50, 9, 67
           .dw 51, 9, 67
           .dw 52, 10, 66
           .dw 53, 10, 66
           .dw 54, 11, 65
           .dw 55, 11, 65
           .dw 56, 12, 64
           .dw 57, 13, 63
           .dw 58, 14, 62
           .dw 59, 14, 62
           .dw 60, 15, 61
           .dw 61, 16, 60
           .dw 62, 17, 59
           .dw 63, 19, 57
           .dw 64, 20, 56
           .dw 65, 21, 55
           .dw 66, 23, 53
           .dw 67, 25, 51
           .dw 68, 27, 49
           .dw 69, 31, 45              ; 63 entries
           
dtindex0:  .dw 0, 0                    ; draw table indices, showing the bottom-left corner of each cell
dtindex1:  .dw 83, 0
dtindex2:  .dw 166, 0
dtindex3:  .dw 0, 83
dtindex4:  .dw 83, 83
dtindex5:  .dw 166, 83
dtindex6:  .dw 0, 166
dtindex7:  .dw 83, 166
dtindex8:  .dw 166, 166
                                       ; the draw table allows for indirects to the indices, which come in pairs           
drawtable: .dwu dtindex0, dtindex1, dtindex2
           .dwu dtindex3, dtindex4, dtindex5
           .dwu dtindex6, dtindex7, dtindex8

linetable: .dw 78, 79, 80, 81, 82      ; where to draw each border line in both x and y, to form the grid
           .dw 161, 162, 163, 164, 165
           
tsindex0:  .dw 38, 38                  ; touch screen indices showing the center of each cell - for touch mapping
tsindex1:  .dw 120, 38
tsindex2:  .dw 202, 38
tsindex3:  .dw 38, 120
tsindex4:  .dw 120, 120
tsindex5:  .dw 202, 120
tsindex6:  .dw 38, 202
tsindex7:  .dw 120, 202
tsindex8:  .dw 202, 202
                                       ; the touchscreen table allows for indirects to the indices, which come in pairs
tstable:   .dwu tsindex0, tsindex1, tsindex2
           .dwu tsindex3, tsindex4, tsindex5
           .dwu tsindex6, tsindex7, tsindex8
           
obuttontb: .dw 242                     ; the run-encoded form of the "o first" button, which assumes that
           .dw 116                     ; color is indicated by the first run and alternates for the subsequent runs
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 2
           .dw 8
           .dw 11
           .dw 9
           .dw 10
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 21
           .dw 9
           .dw 10
           .dw 4
           .dw 2
           .dw 9
           .dw 7
           .dw 14
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 19
           .dw 13
           .dw 8
           .dw 4
           .dw 2
           .dw 10
           .dw 6
           .dw 14
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 18
           .dw 16
           .dw 6
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 6
           .dw 6
           .dw 3
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 16
           .dw 19
           .dw 5
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 5
           .dw 9
           .dw 1
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 16
           .dw 7
           .dw 5
           .dw 7
           .dw 5
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 5
           .dw 18
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 15
           .dw 6
           .dw 9
           .dw 6
           .dw 4
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 8
           .dw 15
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 15
           .dw 5
           .dw 11
           .dw 5
           .dw 4
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 12
           .dw 10
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 14
           .dw 6
           .dw 11
           .dw 6
           .dw 3
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 13
           .dw 9
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 14
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 4
           .dw 7
           .dw 5
           .dw 8
           .dw 12
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 14
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 4
           .dw 7
           .dw 5
           .dw 13
           .dw 7
           .dw 7
           .dw 6
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 14
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 1
           .dw 8
           .dw 5
           .dw 1
           .dw 1
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 14
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 3
           .dw 6
           .dw 5
           .dw 1
           .dw 12
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 14
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 4
           .dw 2
           .dw 13
           .dw 3
           .dw 13
           .dw 2
           .dw 12
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 14
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 4
           .dw 2
           .dw 13
           .dw 3
           .dw 13
           .dw 2
           .dw 6
           .dw 1
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 14
           .dw 6
           .dw 11
           .dw 6
           .dw 3
           .dw 4
           .dw 2
           .dw 13
           .dw 5
           .dw 9
           .dw 4
           .dw 4
           .dw 3
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 15
           .dw 5
           .dw 11
           .dw 5
           .dw 4
           .dw 4
           .dw 7
           .dw 5
           .dw 59
           .dw 5
           .dw 15
           .dw 6
           .dw 9
           .dw 6
           .dw 4
           .dw 4
           .dw 7
           .dw 5
           .dw 59
           .dw 5
           .dw 16
           .dw 7
           .dw 5
           .dw 7
           .dw 5
           .dw 4
           .dw 7
           .dw 5
           .dw 38
           .dw 5
           .dw 6
           .dw 15
           .dw 17
           .dw 17
           .dw 6
           .dw 4
           .dw 7
           .dw 5
           .dw 38
           .dw 5
           .dw 6
           .dw 15
           .dw 18
           .dw 15
           .dw 7
           .dw 4
           .dw 7
           .dw 5
           .dw 38
           .dw 5
           .dw 6
           .dw 15
           .dw 19
           .dw 13
           .dw 8
           .dw 4
           .dw 50
           .dw 5
           .dw 6
           .dw 15
           .dw 22
           .dw 8
           .dw 10
           .dw 4
           .dw 50
           .dw 5
           .dw 61
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 242
           .dw 0
           
xbuttontb: .dw 242                     ; much like the o button table, this is a start-on-color run encoding
           .dw 116                     ; of the "x first" button graphic
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 2
           .dw 8
           .dw 11
           .dw 9
           .dw 10
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 40
           .dw 4
           .dw 2
           .dw 9
           .dw 7
           .dw 14
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 13
           .dw 3
           .dw 16
           .dw 3
           .dw 5
           .dw 4
           .dw 2
           .dw 10
           .dw 6
           .dw 14
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 13
           .dw 4
           .dw 14
           .dw 4
           .dw 5
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 6
           .dw 6
           .dw 3
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 13
           .dw 5
           .dw 12
           .dw 5
           .dw 5
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 5
           .dw 9
           .dw 1
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 14
           .dw 5
           .dw 10
           .dw 5
           .dw 6
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 5
           .dw 18
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 15
           .dw 5
           .dw 8
           .dw 5
           .dw 7
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 8
           .dw 15
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 16
           .dw 5
           .dw 6
           .dw 5
           .dw 8
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 12
           .dw 10
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 17
           .dw 5
           .dw 4
           .dw 5
           .dw 9
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 13
           .dw 9
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 18
           .dw 5
           .dw 2
           .dw 5
           .dw 10
           .dw 4
           .dw 7
           .dw 5
           .dw 8
           .dw 12
           .dw 8
           .dw 5
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 19
           .dw 10
           .dw 11
           .dw 4
           .dw 7
           .dw 5
           .dw 13
           .dw 7
           .dw 7
           .dw 6
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 20
           .dw 8
           .dw 12
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 1
           .dw 8
           .dw 5
           .dw 1
           .dw 1
           .dw 4
           .dw 7
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 21
           .dw 6
           .dw 13
           .dw 4
           .dw 7
           .dw 5
           .dw 6
           .dw 3
           .dw 6
           .dw 5
           .dw 1
           .dw 12
           .dw 5
           .dw 5
           .dw 7
           .dw 14
           .dw 21
           .dw 6
           .dw 13
           .dw 4
           .dw 2
           .dw 13
           .dw 3
           .dw 13
           .dw 2
           .dw 12
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 20
           .dw 8
           .dw 12
           .dw 4
           .dw 2
           .dw 13
           .dw 3
           .dw 13
           .dw 2
           .dw 6
           .dw 1
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 19
           .dw 10
           .dw 11
           .dw 4
           .dw 2
           .dw 13
           .dw 5
           .dw 9
           .dw 4
           .dw 4
           .dw 3
           .dw 5
           .dw 5
           .dw 5
           .dw 16
           .dw 5
           .dw 18
           .dw 5
           .dw 2
           .dw 5
           .dw 10
           .dw 4
           .dw 7
           .dw 5
           .dw 59
           .dw 5
           .dw 17
           .dw 5
           .dw 4
           .dw 5
           .dw 9
           .dw 4
           .dw 7
           .dw 5
           .dw 59
           .dw 5
           .dw 16
           .dw 5
           .dw 6
           .dw 5
           .dw 8
           .dw 4
           .dw 7
           .dw 5
           .dw 38
           .dw 5
           .dw 6
           .dw 15
           .dw 15
           .dw 5
           .dw 8
           .dw 5
           .dw 7
           .dw 4
           .dw 7
           .dw 5
           .dw 38
           .dw 5
           .dw 6
           .dw 15
           .dw 14
           .dw 5
           .dw 10
           .dw 5
           .dw 6
           .dw 4
           .dw 7
           .dw 5
           .dw 38
           .dw 5
           .dw 6
           .dw 15
           .dw 13
           .dw 5
           .dw 12
           .dw 5
           .dw 5
           .dw 4
           .dw 50
           .dw 5
           .dw 6
           .dw 15
           .dw 13
           .dw 4
           .dw 14
           .dw 4
           .dw 5
           .dw 4
           .dw 50
           .dw 5
           .dw 34
           .dw 3
           .dw 16
           .dw 3
           .dw 5
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 4
           .dw 116
           .dw 242
           .dw 0
           
xwonmsgtb: .dw 723                     ; the x won message table, encoded the same way as the two above
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 33
           .dw 5
           .dw 8
           .dw 2
           .dw 4
           .dw 2
           .dw 2
           .dw 4
           .dw 3
           .dw 5
           .dw 6
           .dw 6
           .dw 4
           .dw 7
           .dw 4
           .dw 3
           .dw 7
           .dw 2
           .dw 13
           .dw 5
           .dw 4
           .dw 5
           .dw 13
           .dw 6
           .dw 5
           .dw 6
           .dw 4
           .dw 7
           .dw 9
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 6
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 2
           .dw 6
           .dw 4
           .dw 8
           .dw 2
           .dw 9
           .dw 4
           .dw 2
           .dw 7
           .dw 2
           .dw 11
           .dw 9
           .dw 2
           .dw 6
           .dw 11
           .dw 8
           .dw 3
           .dw 8
           .dw 2
           .dw 9
           .dw 8
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 3
           .dw 4
           .dw 3
           .dw 5
           .dw 2
           .dw 3
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 1
           .dw 6
           .dw 3
           .dw 3
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 3
           .dw 4
           .dw 2
           .dw 6
           .dw 2
           .dw 10
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 1
           .dw 6
           .dw 3
           .dw 7
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 6
           .dw 2
           .dw 5
           .dw 2
           .dw 3
           .dw 2
           .dw 17
           .dw 3
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 10
           .dw 3
           .dw 6
           .dw 2
           .dw 5
           .dw 2
           .dw 10
           .dw 2
           .dw 9
           .dw 2
           .dw 17
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 5
           .dw 3
           .dw 5
           .dw 2
           .dw 3
           .dw 3
           .dw 17
           .dw 2
           .dw 3
           .dw 3
           .dw 5
           .dw 2
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 10
           .dw 3
           .dw 8
           .dw 3
           .dw 17
           .dw 2
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 6
           .dw 2
           .dw 4
           .dw 6
           .dw 4
           .dw 11
           .dw 4
           .dw 3
           .dw 4
           .dw 2
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 11
           .dw 6
           .dw 5
           .dw 6
           .dw 4
           .dw 11
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 8
           .dw 7
           .dw 2
           .dw 6
           .dw 6
           .dw 2
           .dw 11
           .dw 5
           .dw 8
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 13
           .dw 6
           .dw 5
           .dw 6
           .dw 2
           .dw 11
           .dw 6
           .dw 2
           .dw 5
           .dw 8
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 13
           .dw 2
           .dw 10
           .dw 2
           .dw 2
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 10
           .dw 3
           .dw 5
           .dw 3
           .dw 5
           .dw 2
           .dw 17
           .dw 2
           .dw 9
           .dw 2
           .dw 2
           .dw 2
           .dw 7
           .dw 2
           .dw 6
           .dw 2
           .dw 4
           .dw 9
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 6
           .dw 3
           .dw 4
           .dw 3
           .dw 5
           .dw 1
           .dw 6
           .dw 2
           .dw 4
           .dw 1
           .dw 5
           .dw 2
           .dw 2
           .dw 3
           .dw 5
           .dw 2
           .dw 4
           .dw 3
           .dw 5
           .dw 2
           .dw 11
           .dw 3
           .dw 3
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 1
           .dw 5
           .dw 2
           .dw 3
           .dw 1
           .dw 5
           .dw 2
           .dw 2
           .dw 3
           .dw 5
           .dw 2
           .dw 6
           .dw 3
           .dw 3
           .dw 3
           .dw 5
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 7
           .dw 1
           .dw 7
           .dw 5
           .dw 8
           .dw 2
           .dw 7
           .dw 3
           .dw 8
           .dw 3
           .dw 8
           .dw 5
           .dw 2
           .dw 6
           .dw 2
           .dw 11
           .dw 9
           .dw 2
           .dw 7
           .dw 10
           .dw 8
           .dw 3
           .dw 8
           .dw 3
           .dw 8
           .dw 3
           .dw 7
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 7
           .dw 1
           .dw 3
           .dw 2
           .dw 2
           .dw 6
           .dw 6
           .dw 3
           .dw 7
           .dw 4
           .dw 5
           .dw 7
           .dw 5
           .dw 6
           .dw 2
           .dw 6
           .dw 2
           .dw 13
           .dw 5
           .dw 4
           .dw 7
           .dw 11
           .dw 5
           .dw 6
           .dw 5
           .dw 7
           .dw 5
           .dw 4
           .dw 3
           .dw 2
           .dw 2
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 28
           .dw 2
           .dw 6
           .dw 2
           .dw 26
           .dw 2
           .dw 54
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 28
           .dw 3
           .dw 5
           .dw 2
           .dw 26
           .dw 2
           .dw 54
           .dw 3
           .dw 5
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 29
           .dw 9
           .dw 26
           .dw 2
           .dw 55
           .dw 9
           .dw 35
           .dw 6
           .dw 99
           .dw 8
           .dw 84
           .dw 8
           .dw 35
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 73
           .dw 9
           .dw 152
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 18
           .dw 15
           .dw 20
           .dw 8
           .dw 19
           .dw 8
           .dw 35
           .dw 8
           .dw 23
           .dw 8
           .dw 20
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 17
           .dw 17
           .dw 19
           .dw 8
           .dw 19
           .dw 8
           .dw 36
           .dw 7
           .dw 23
           .dw 7
           .dw 21
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 15
           .dw 21
           .dw 17
           .dw 9
           .dw 17
           .dw 9
           .dw 37
           .dw 7
           .dw 21
           .dw 7
           .dw 22
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 14
           .dw 23
           .dw 15
           .dw 10
           .dw 17
           .dw 10
           .dw 36
           .dw 8
           .dw 19
           .dw 8
           .dw 22
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 14
           .dw 8
           .dw 7
           .dw 9
           .dw 14
           .dw 10
           .dw 17
           .dw 10
           .dw 37
           .dw 7
           .dw 19
           .dw 7
           .dw 23
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 13
           .dw 8
           .dw 10
           .dw 7
           .dw 14
           .dw 10
           .dw 17
           .dw 10
           .dw 38
           .dw 7
           .dw 17
           .dw 7
           .dw 24
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 13
           .dw 11
           .dw 15
           .dw 11
           .dw 38
           .dw 8
           .dw 15
           .dw 8
           .dw 24
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 12
           .dw 12
           .dw 15
           .dw 12
           .dw 38
           .dw 7
           .dw 15
           .dw 7
           .dw 25
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 7
           .dw 15
           .dw 7
           .dw 11
           .dw 6
           .dw 1
           .dw 5
           .dw 15
           .dw 5
           .dw 1
           .dw 6
           .dw 39
           .dw 7
           .dw 13
           .dw 7
           .dw 26
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 11
           .dw 6
           .dw 1
           .dw 5
           .dw 15
           .dw 5
           .dw 1
           .dw 6
           .dw 39
           .dw 7
           .dw 12
           .dw 8
           .dw 26
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 11
           .dw 6
           .dw 1
           .dw 6
           .dw 13
           .dw 6
           .dw 1
           .dw 6
           .dw 40
           .dw 7
           .dw 11
           .dw 7
           .dw 27
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 10
           .dw 7
           .dw 2
           .dw 5
           .dw 13
           .dw 5
           .dw 2
           .dw 7
           .dw 40
           .dw 7
           .dw 9
           .dw 7
           .dw 28
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 9
           .dw 6
           .dw 3
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 6
           .dw 40
           .dw 7
           .dw 8
           .dw 7
           .dw 29
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 9
           .dw 6
           .dw 3
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 6
           .dw 41
           .dw 7
           .dw 7
           .dw 7
           .dw 29
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 9
           .dw 6
           .dw 3
           .dw 5
           .dw 12
           .dw 6
           .dw 3
           .dw 6
           .dw 42
           .dw 7
           .dw 5
           .dw 7
           .dw 30
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 7
           .dw 4
           .dw 5
           .dw 11
           .dw 5
           .dw 4
           .dw 7
           .dw 41
           .dw 7
           .dw 4
           .dw 7
           .dw 31
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 6
           .dw 5
           .dw 5
           .dw 11
           .dw 5
           .dw 5
           .dw 6
           .dw 42
           .dw 7
           .dw 2
           .dw 8
           .dw 31
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 6
           .dw 5
           .dw 5
           .dw 11
           .dw 5
           .dw 5
           .dw 6
           .dw 43
           .dw 7
           .dw 1
           .dw 7
           .dw 32
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 6
           .dw 5
           .dw 5
           .dw 11
           .dw 5
           .dw 5
           .dw 6
           .dw 43
           .dw 14
           .dw 33
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 7
           .dw 7
           .dw 6
           .dw 5
           .dw 9
           .dw 5
           .dw 6
           .dw 7
           .dw 43
           .dw 13
           .dw 33
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 7
           .dw 6
           .dw 7
           .dw 5
           .dw 9
           .dw 5
           .dw 7
           .dw 6
           .dw 44
           .dw 11
           .dw 34
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 7
           .dw 6
           .dw 7
           .dw 5
           .dw 9
           .dw 5
           .dw 7
           .dw 6
           .dw 44
           .dw 10
           .dw 35
           .dw 6
           .dw 24
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 7
           .dw 7
           .dw 6
           .dw 7
           .dw 5
           .dw 9
           .dw 5
           .dw 7
           .dw 6
           .dw 45
           .dw 9
           .dw 35
           .dw 6
           .dw 24
           .dw 6
           .dw 15
           .dw 7
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 7
           .dw 7
           .dw 8
           .dw 5
           .dw 7
           .dw 5
           .dw 8
           .dw 7
           .dw 45
           .dw 7
           .dw 36
           .dw 6
           .dw 24
           .dw 6
           .dw 15
           .dw 7
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 7
           .dw 6
           .dw 9
           .dw 5
           .dw 7
           .dw 5
           .dw 9
           .dw 6
           .dw 44
           .dw 8
           .dw 36
           .dw 6
           .dw 24
           .dw 7
           .dw 14
           .dw 7
           .dw 11
           .dw 7
           .dw 15
           .dw 7
           .dw 7
           .dw 6
           .dw 9
           .dw 5
           .dw 7
           .dw 5
           .dw 9
           .dw 6
           .dw 43
           .dw 10
           .dw 35
           .dw 6
           .dw 25
           .dw 6
           .dw 13
           .dw 8
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 8
           .dw 6
           .dw 9
           .dw 5
           .dw 7
           .dw 5
           .dw 9
           .dw 6
           .dw 43
           .dw 11
           .dw 34
           .dw 6
           .dw 25
           .dw 7
           .dw 11
           .dw 9
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 7
           .dw 7
           .dw 10
           .dw 5
           .dw 5
           .dw 5
           .dw 10
           .dw 7
           .dw 41
           .dw 12
           .dw 34
           .dw 6
           .dw 25
           .dw 8
           .dw 9
           .dw 10
           .dw 13
           .dw 8
           .dw 9
           .dw 8
           .dw 8
           .dw 6
           .dw 11
           .dw 5
           .dw 5
           .dw 5
           .dw 11
           .dw 6
           .dw 40
           .dw 14
           .dw 33
           .dw 6
           .dw 26
           .dw 8
           .dw 6
           .dw 12
           .dw 14
           .dw 9
           .dw 6
           .dw 8
           .dw 9
           .dw 6
           .dw 11
           .dw 5
           .dw 5
           .dw 5
           .dw 11
           .dw 6
           .dw 40
           .dw 7
           .dw 1
           .dw 7
           .dw 32
           .dw 6
           .dw 26
           .dw 19
           .dw 1
           .dw 6
           .dw 14
           .dw 23
           .dw 9
           .dw 6
           .dw 11
           .dw 5
           .dw 5
           .dw 5
           .dw 11
           .dw 6
           .dw 39
           .dw 7
           .dw 2
           .dw 7
           .dw 32
           .dw 6
           .dw 27
           .dw 17
           .dw 2
           .dw 6
           .dw 15
           .dw 21
           .dw 9
           .dw 7
           .dw 11
           .dw 6
           .dw 3
           .dw 5
           .dw 12
           .dw 7
           .dw 37
           .dw 7
           .dw 4
           .dw 7
           .dw 31
           .dw 6
           .dw 28
           .dw 15
           .dw 3
           .dw 6
           .dw 17
           .dw 17
           .dw 11
           .dw 6
           .dw 13
           .dw 5
           .dw 3
           .dw 5
           .dw 13
           .dw 6
           .dw 37
           .dw 7
           .dw 4
           .dw 8
           .dw 30
           .dw 6
           .dw 29
           .dw 12
           .dw 5
           .dw 6
           .dw 18
           .dw 15
           .dw 12
           .dw 6
           .dw 13
           .dw 5
           .dw 3
           .dw 5
           .dw 13
           .dw 6
           .dw 36
           .dw 7
           .dw 6
           .dw 7
           .dw 30
           .dw 6
           .dw 32
           .dw 7
           .dw 34
           .dw 9
           .dw 15
           .dw 6
           .dw 13
           .dw 5
           .dw 3
           .dw 5
           .dw 13
           .dw 6
           .dw 35
           .dw 7
           .dw 8
           .dw 7
           .dw 29
           .dw 6
           .dw 96
           .dw 7
           .dw 13
           .dw 6
           .dw 1
           .dw 6
           .dw 13
           .dw 7
           .dw 33
           .dw 8
           .dw 8
           .dw 8
           .dw 28
           .dw 6
           .dw 96
           .dw 6
           .dw 15
           .dw 5
           .dw 1
           .dw 5
           .dw 15
           .dw 6
           .dw 33
           .dw 7
           .dw 10
           .dw 7
           .dw 28
           .dw 6
           .dw 96
           .dw 6
           .dw 15
           .dw 5
           .dw 1
           .dw 5
           .dw 15
           .dw 6
           .dw 32
           .dw 7
           .dw 12
           .dw 7
           .dw 27
           .dw 6
           .dw 96
           .dw 6
           .dw 15
           .dw 5
           .dw 1
           .dw 5
           .dw 15
           .dw 6
           .dw 31
           .dw 8
           .dw 12
           .dw 8
           .dw 26
           .dw 6
           .dw 95
           .dw 7
           .dw 15
           .dw 11
           .dw 15
           .dw 7
           .dw 30
           .dw 7
           .dw 14
           .dw 7
           .dw 26
           .dw 6
           .dw 95
           .dw 6
           .dw 17
           .dw 9
           .dw 17
           .dw 6
           .dw 29
           .dw 7
           .dw 16
           .dw 7
           .dw 25
           .dw 6
           .dw 95
           .dw 6
           .dw 17
           .dw 9
           .dw 17
           .dw 6
           .dw 28
           .dw 8
           .dw 16
           .dw 8
           .dw 24
           .dw 6
           .dw 95
           .dw 6
           .dw 17
           .dw 9
           .dw 17
           .dw 6
           .dw 28
           .dw 7
           .dw 18
           .dw 7
           .dw 24
           .dw 6
           .dw 94
           .dw 7
           .dw 17
           .dw 9
           .dw 17
           .dw 7
           .dw 26
           .dw 7
           .dw 20
           .dw 7
           .dw 23
           .dw 6
           .dw 94
           .dw 6
           .dw 19
           .dw 7
           .dw 19
           .dw 6
           .dw 25
           .dw 8
           .dw 20
           .dw 8
           .dw 22
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 723
           .dw 0
owonmsgtb: .dw 723                     ; the o won message table, encoded the same way as above.
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 33
           .dw 5
           .dw 8
           .dw 2
           .dw 4
           .dw 2
           .dw 2
           .dw 4
           .dw 3
           .dw 5
           .dw 6
           .dw 6
           .dw 4
           .dw 7
           .dw 4
           .dw 3
           .dw 7
           .dw 2
           .dw 13
           .dw 5
           .dw 4
           .dw 5
           .dw 13
           .dw 6
           .dw 5
           .dw 6
           .dw 4
           .dw 7
           .dw 9
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 6
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 2
           .dw 6
           .dw 4
           .dw 8
           .dw 2
           .dw 9
           .dw 4
           .dw 2
           .dw 7
           .dw 2
           .dw 11
           .dw 9
           .dw 2
           .dw 6
           .dw 11
           .dw 8
           .dw 3
           .dw 8
           .dw 2
           .dw 9
           .dw 8
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 3
           .dw 4
           .dw 3
           .dw 5
           .dw 2
           .dw 3
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 1
           .dw 6
           .dw 3
           .dw 3
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 3
           .dw 4
           .dw 2
           .dw 6
           .dw 2
           .dw 10
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 1
           .dw 6
           .dw 3
           .dw 7
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 6
           .dw 2
           .dw 5
           .dw 2
           .dw 3
           .dw 2
           .dw 17
           .dw 3
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 10
           .dw 3
           .dw 6
           .dw 2
           .dw 5
           .dw 2
           .dw 10
           .dw 2
           .dw 9
           .dw 2
           .dw 17
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 5
           .dw 3
           .dw 5
           .dw 2
           .dw 3
           .dw 3
           .dw 17
           .dw 2
           .dw 3
           .dw 3
           .dw 5
           .dw 2
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 10
           .dw 3
           .dw 8
           .dw 3
           .dw 17
           .dw 2
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 6
           .dw 2
           .dw 4
           .dw 6
           .dw 4
           .dw 11
           .dw 4
           .dw 3
           .dw 4
           .dw 2
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 11
           .dw 6
           .dw 5
           .dw 6
           .dw 4
           .dw 11
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 8
           .dw 7
           .dw 2
           .dw 6
           .dw 6
           .dw 2
           .dw 11
           .dw 5
           .dw 8
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 13
           .dw 6
           .dw 5
           .dw 6
           .dw 2
           .dw 11
           .dw 6
           .dw 2
           .dw 5
           .dw 8
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 13
           .dw 2
           .dw 10
           .dw 2
           .dw 2
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 10
           .dw 3
           .dw 5
           .dw 3
           .dw 5
           .dw 2
           .dw 17
           .dw 2
           .dw 9
           .dw 2
           .dw 2
           .dw 2
           .dw 7
           .dw 2
           .dw 6
           .dw 2
           .dw 4
           .dw 9
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 6
           .dw 3
           .dw 4
           .dw 3
           .dw 5
           .dw 1
           .dw 6
           .dw 2
           .dw 4
           .dw 1
           .dw 5
           .dw 2
           .dw 2
           .dw 3
           .dw 5
           .dw 2
           .dw 4
           .dw 3
           .dw 5
           .dw 2
           .dw 11
           .dw 3
           .dw 3
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 1
           .dw 5
           .dw 2
           .dw 3
           .dw 1
           .dw 5
           .dw 2
           .dw 2
           .dw 3
           .dw 5
           .dw 2
           .dw 6
           .dw 3
           .dw 3
           .dw 3
           .dw 5
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 7
           .dw 1
           .dw 7
           .dw 5
           .dw 8
           .dw 2
           .dw 7
           .dw 3
           .dw 8
           .dw 3
           .dw 8
           .dw 5
           .dw 2
           .dw 6
           .dw 2
           .dw 11
           .dw 9
           .dw 2
           .dw 7
           .dw 10
           .dw 8
           .dw 3
           .dw 8
           .dw 3
           .dw 8
           .dw 3
           .dw 7
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 7
           .dw 1
           .dw 3
           .dw 2
           .dw 2
           .dw 6
           .dw 6
           .dw 3
           .dw 7
           .dw 4
           .dw 5
           .dw 7
           .dw 5
           .dw 6
           .dw 2
           .dw 6
           .dw 2
           .dw 13
           .dw 5
           .dw 4
           .dw 7
           .dw 11
           .dw 5
           .dw 6
           .dw 5
           .dw 7
           .dw 5
           .dw 4
           .dw 3
           .dw 2
           .dw 2
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 28
           .dw 2
           .dw 6
           .dw 2
           .dw 26
           .dw 2
           .dw 54
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 28
           .dw 3
           .dw 5
           .dw 2
           .dw 26
           .dw 2
           .dw 54
           .dw 3
           .dw 5
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 29
           .dw 9
           .dw 26
           .dw 2
           .dw 55
           .dw 9
           .dw 35
           .dw 6
           .dw 99
           .dw 8
           .dw 84
           .dw 8
           .dw 35
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 70
           .dw 9
           .dw 110
           .dw 10
           .dw 35
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 18
           .dw 15
           .dw 20
           .dw 8
           .dw 19
           .dw 8
           .dw 49
           .dw 16
           .dw 32
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 17
           .dw 17
           .dw 19
           .dw 8
           .dw 19
           .dw 8
           .dw 47
           .dw 20
           .dw 30
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 15
           .dw 21
           .dw 17
           .dw 9
           .dw 17
           .dw 9
           .dw 45
           .dw 24
           .dw 28
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 14
           .dw 23
           .dw 15
           .dw 10
           .dw 17
           .dw 10
           .dw 43
           .dw 26
           .dw 27
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 14
           .dw 8
           .dw 7
           .dw 9
           .dw 14
           .dw 10
           .dw 17
           .dw 10
           .dw 42
           .dw 10
           .dw 8
           .dw 10
           .dw 26
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 13
           .dw 8
           .dw 10
           .dw 7
           .dw 14
           .dw 10
           .dw 17
           .dw 10
           .dw 41
           .dw 8
           .dw 14
           .dw 8
           .dw 25
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 13
           .dw 11
           .dw 15
           .dw 11
           .dw 40
           .dw 8
           .dw 16
           .dw 8
           .dw 24
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 12
           .dw 12
           .dw 15
           .dw 12
           .dw 38
           .dw 7
           .dw 20
           .dw 7
           .dw 23
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 7
           .dw 15
           .dw 7
           .dw 11
           .dw 6
           .dw 1
           .dw 5
           .dw 15
           .dw 5
           .dw 1
           .dw 6
           .dw 37
           .dw 7
           .dw 22
           .dw 7
           .dw 22
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 11
           .dw 6
           .dw 1
           .dw 5
           .dw 15
           .dw 5
           .dw 1
           .dw 6
           .dw 37
           .dw 7
           .dw 22
           .dw 7
           .dw 22
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 11
           .dw 6
           .dw 1
           .dw 6
           .dw 13
           .dw 6
           .dw 1
           .dw 6
           .dw 36
           .dw 7
           .dw 24
           .dw 7
           .dw 21
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 10
           .dw 7
           .dw 2
           .dw 5
           .dw 13
           .dw 5
           .dw 2
           .dw 7
           .dw 35
           .dw 6
           .dw 26
           .dw 6
           .dw 21
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 9
           .dw 6
           .dw 3
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 6
           .dw 35
           .dw 6
           .dw 26
           .dw 6
           .dw 21
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 9
           .dw 6
           .dw 3
           .dw 5
           .dw 13
           .dw 5
           .dw 3
           .dw 6
           .dw 34
           .dw 6
           .dw 28
           .dw 6
           .dw 20
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 9
           .dw 6
           .dw 3
           .dw 5
           .dw 12
           .dw 6
           .dw 3
           .dw 6
           .dw 34
           .dw 6
           .dw 28
           .dw 6
           .dw 20
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 7
           .dw 4
           .dw 5
           .dw 11
           .dw 5
           .dw 4
           .dw 7
           .dw 33
           .dw 6
           .dw 28
           .dw 6
           .dw 20
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 6
           .dw 5
           .dw 5
           .dw 11
           .dw 5
           .dw 5
           .dw 6
           .dw 33
           .dw 6
           .dw 28
           .dw 7
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 6
           .dw 5
           .dw 5
           .dw 11
           .dw 5
           .dw 5
           .dw 6
           .dw 32
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 8
           .dw 6
           .dw 5
           .dw 5
           .dw 11
           .dw 5
           .dw 5
           .dw 6
           .dw 32
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 7
           .dw 7
           .dw 6
           .dw 5
           .dw 9
           .dw 5
           .dw 6
           .dw 7
           .dw 31
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 7
           .dw 6
           .dw 7
           .dw 5
           .dw 9
           .dw 5
           .dw 7
           .dw 6
           .dw 31
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 10
           .dw 6
           .dw 19
           .dw 6
           .dw 7
           .dw 6
           .dw 7
           .dw 5
           .dw 9
           .dw 5
           .dw 7
           .dw 6
           .dw 31
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 16
           .dw 6
           .dw 11
           .dw 6
           .dw 17
           .dw 7
           .dw 7
           .dw 6
           .dw 7
           .dw 5
           .dw 9
           .dw 5
           .dw 7
           .dw 6
           .dw 31
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 15
           .dw 7
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 7
           .dw 7
           .dw 8
           .dw 5
           .dw 7
           .dw 5
           .dw 8
           .dw 7
           .dw 30
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 6
           .dw 15
           .dw 7
           .dw 11
           .dw 6
           .dw 17
           .dw 6
           .dw 7
           .dw 6
           .dw 9
           .dw 5
           .dw 7
           .dw 5
           .dw 9
           .dw 6
           .dw 30
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 21
           .dw 7
           .dw 14
           .dw 7
           .dw 11
           .dw 7
           .dw 15
           .dw 7
           .dw 7
           .dw 6
           .dw 9
           .dw 5
           .dw 7
           .dw 5
           .dw 9
           .dw 6
           .dw 30
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 22
           .dw 6
           .dw 13
           .dw 8
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 8
           .dw 6
           .dw 9
           .dw 5
           .dw 7
           .dw 5
           .dw 9
           .dw 6
           .dw 30
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 22
           .dw 7
           .dw 11
           .dw 9
           .dw 12
           .dw 7
           .dw 13
           .dw 7
           .dw 7
           .dw 7
           .dw 10
           .dw 5
           .dw 5
           .dw 5
           .dw 10
           .dw 7
           .dw 29
           .dw 6
           .dw 30
           .dw 6
           .dw 19
           .dw 6
           .dw 22
           .dw 8
           .dw 9
           .dw 10
           .dw 13
           .dw 8
           .dw 9
           .dw 8
           .dw 8
           .dw 6
           .dw 11
           .dw 5
           .dw 5
           .dw 5
           .dw 11
           .dw 6
           .dw 30
           .dw 6
           .dw 28
           .dw 7
           .dw 19
           .dw 6
           .dw 23
           .dw 8
           .dw 6
           .dw 12
           .dw 14
           .dw 9
           .dw 6
           .dw 8
           .dw 9
           .dw 6
           .dw 11
           .dw 5
           .dw 5
           .dw 5
           .dw 11
           .dw 6
           .dw 30
           .dw 6
           .dw 28
           .dw 6
           .dw 20
           .dw 6
           .dw 23
           .dw 19
           .dw 1
           .dw 6
           .dw 14
           .dw 23
           .dw 9
           .dw 6
           .dw 11
           .dw 5
           .dw 5
           .dw 5
           .dw 11
           .dw 6
           .dw 30
           .dw 6
           .dw 28
           .dw 6
           .dw 20
           .dw 6
           .dw 24
           .dw 17
           .dw 2
           .dw 6
           .dw 15
           .dw 21
           .dw 9
           .dw 7
           .dw 11
           .dw 6
           .dw 3
           .dw 5
           .dw 12
           .dw 7
           .dw 29
           .dw 6
           .dw 28
           .dw 6
           .dw 20
           .dw 6
           .dw 25
           .dw 15
           .dw 3
           .dw 6
           .dw 17
           .dw 17
           .dw 11
           .dw 6
           .dw 13
           .dw 5
           .dw 3
           .dw 5
           .dw 13
           .dw 6
           .dw 30
           .dw 6
           .dw 26
           .dw 6
           .dw 21
           .dw 6
           .dw 26
           .dw 12
           .dw 5
           .dw 6
           .dw 18
           .dw 15
           .dw 12
           .dw 6
           .dw 13
           .dw 5
           .dw 3
           .dw 5
           .dw 13
           .dw 6
           .dw 30
           .dw 6
           .dw 26
           .dw 6
           .dw 21
           .dw 6
           .dw 29
           .dw 7
           .dw 34
           .dw 9
           .dw 15
           .dw 6
           .dw 13
           .dw 5
           .dw 3
           .dw 5
           .dw 13
           .dw 6
           .dw 30
           .dw 7
           .dw 24
           .dw 7
           .dw 21
           .dw 6
           .dw 93
           .dw 7
           .dw 13
           .dw 6
           .dw 1
           .dw 6
           .dw 13
           .dw 7
           .dw 30
           .dw 7
           .dw 22
           .dw 7
           .dw 22
           .dw 6
           .dw 93
           .dw 6
           .dw 15
           .dw 5
           .dw 1
           .dw 5
           .dw 15
           .dw 6
           .dw 30
           .dw 7
           .dw 22
           .dw 7
           .dw 22
           .dw 6
           .dw 93
           .dw 6
           .dw 15
           .dw 5
           .dw 1
           .dw 5
           .dw 15
           .dw 6
           .dw 31
           .dw 7
           .dw 20
           .dw 7
           .dw 23
           .dw 6
           .dw 93
           .dw 6
           .dw 15
           .dw 5
           .dw 1
           .dw 5
           .dw 15
           .dw 6
           .dw 32
           .dw 8
           .dw 16
           .dw 8
           .dw 24
           .dw 6
           .dw 92
           .dw 7
           .dw 15
           .dw 11
           .dw 15
           .dw 7
           .dw 32
           .dw 8
           .dw 14
           .dw 8
           .dw 25
           .dw 6
           .dw 92
           .dw 6
           .dw 17
           .dw 9
           .dw 17
           .dw 6
           .dw 33
           .dw 10
           .dw 8
           .dw 10
           .dw 26
           .dw 6
           .dw 92
           .dw 6
           .dw 17
           .dw 9
           .dw 17
           .dw 6
           .dw 34
           .dw 26
           .dw 27
           .dw 6
           .dw 92
           .dw 6
           .dw 17
           .dw 9
           .dw 17
           .dw 6
           .dw 35
           .dw 24
           .dw 28
           .dw 6
           .dw 91
           .dw 7
           .dw 17
           .dw 9
           .dw 17
           .dw 7
           .dw 36
           .dw 20
           .dw 30
           .dw 6
           .dw 91
           .dw 6
           .dw 19
           .dw 7
           .dw 19
           .dw 6
           .dw 38
           .dw 16
           .dw 32
           .dw 6
           .dw 189
           .dw 10
           .dw 35
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 723
           .dw 0
drawmsgtb: .dw 723                     ; the draw message table, encoded the same way as above
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 33
           .dw 5
           .dw 8
           .dw 2
           .dw 4
           .dw 2
           .dw 2
           .dw 4
           .dw 3
           .dw 5
           .dw 6
           .dw 6
           .dw 4
           .dw 7
           .dw 4
           .dw 3
           .dw 7
           .dw 2
           .dw 13
           .dw 5
           .dw 4
           .dw 5
           .dw 13
           .dw 6
           .dw 5
           .dw 6
           .dw 4
           .dw 7
           .dw 9
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 6
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 2
           .dw 6
           .dw 4
           .dw 8
           .dw 2
           .dw 9
           .dw 4
           .dw 2
           .dw 7
           .dw 2
           .dw 11
           .dw 9
           .dw 2
           .dw 6
           .dw 11
           .dw 8
           .dw 3
           .dw 8
           .dw 2
           .dw 9
           .dw 8
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 3
           .dw 4
           .dw 3
           .dw 5
           .dw 2
           .dw 3
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 1
           .dw 6
           .dw 3
           .dw 3
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 3
           .dw 4
           .dw 2
           .dw 6
           .dw 2
           .dw 10
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 2
           .dw 6
           .dw 1
           .dw 2
           .dw 1
           .dw 6
           .dw 3
           .dw 7
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 6
           .dw 2
           .dw 5
           .dw 2
           .dw 3
           .dw 2
           .dw 17
           .dw 3
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 10
           .dw 3
           .dw 6
           .dw 2
           .dw 5
           .dw 2
           .dw 10
           .dw 2
           .dw 9
           .dw 2
           .dw 17
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 5
           .dw 3
           .dw 5
           .dw 2
           .dw 3
           .dw 3
           .dw 17
           .dw 2
           .dw 3
           .dw 3
           .dw 5
           .dw 2
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 10
           .dw 3
           .dw 8
           .dw 3
           .dw 17
           .dw 2
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 6
           .dw 2
           .dw 4
           .dw 6
           .dw 4
           .dw 11
           .dw 4
           .dw 3
           .dw 4
           .dw 2
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 11
           .dw 6
           .dw 5
           .dw 6
           .dw 4
           .dw 11
           .dw 6
           .dw 2
           .dw 11
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 8
           .dw 7
           .dw 2
           .dw 6
           .dw 6
           .dw 2
           .dw 11
           .dw 5
           .dw 8
           .dw 10
           .dw 2
           .dw 7
           .dw 2
           .dw 5
           .dw 2
           .dw 13
           .dw 6
           .dw 5
           .dw 6
           .dw 2
           .dw 11
           .dw 6
           .dw 2
           .dw 5
           .dw 8
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 2
           .dw 13
           .dw 2
           .dw 10
           .dw 2
           .dw 2
           .dw 2
           .dw 7
           .dw 2
           .dw 4
           .dw 9
           .dw 10
           .dw 3
           .dw 5
           .dw 3
           .dw 5
           .dw 2
           .dw 17
           .dw 2
           .dw 9
           .dw 2
           .dw 2
           .dw 2
           .dw 7
           .dw 2
           .dw 6
           .dw 2
           .dw 4
           .dw 9
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 6
           .dw 3
           .dw 4
           .dw 3
           .dw 5
           .dw 1
           .dw 6
           .dw 2
           .dw 4
           .dw 1
           .dw 5
           .dw 2
           .dw 2
           .dw 3
           .dw 5
           .dw 2
           .dw 4
           .dw 3
           .dw 5
           .dw 2
           .dw 11
           .dw 3
           .dw 3
           .dw 3
           .dw 6
           .dw 2
           .dw 11
           .dw 1
           .dw 5
           .dw 2
           .dw 3
           .dw 1
           .dw 5
           .dw 2
           .dw 2
           .dw 3
           .dw 5
           .dw 2
           .dw 6
           .dw 3
           .dw 3
           .dw 3
           .dw 5
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 7
           .dw 1
           .dw 7
           .dw 5
           .dw 8
           .dw 2
           .dw 7
           .dw 3
           .dw 8
           .dw 3
           .dw 8
           .dw 5
           .dw 2
           .dw 6
           .dw 2
           .dw 11
           .dw 9
           .dw 2
           .dw 7
           .dw 10
           .dw 8
           .dw 3
           .dw 8
           .dw 3
           .dw 8
           .dw 3
           .dw 7
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 33
           .dw 7
           .dw 1
           .dw 3
           .dw 2
           .dw 2
           .dw 6
           .dw 6
           .dw 3
           .dw 7
           .dw 4
           .dw 5
           .dw 7
           .dw 5
           .dw 6
           .dw 2
           .dw 6
           .dw 2
           .dw 13
           .dw 5
           .dw 4
           .dw 7
           .dw 11
           .dw 5
           .dw 6
           .dw 5
           .dw 7
           .dw 5
           .dw 4
           .dw 3
           .dw 2
           .dw 2
           .dw 3
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 28
           .dw 2
           .dw 6
           .dw 2
           .dw 26
           .dw 2
           .dw 54
           .dw 2
           .dw 6
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 28
           .dw 3
           .dw 5
           .dw 2
           .dw 26
           .dw 2
           .dw 54
           .dw 3
           .dw 5
           .dw 2
           .dw 35
           .dw 6
           .dw 37
           .dw 2
           .dw 28
           .dw 2
           .dw 29
           .dw 9
           .dw 26
           .dw 2
           .dw 55
           .dw 9
           .dw 35
           .dw 6
           .dw 99
           .dw 8
           .dw 84
           .dw 8
           .dw 35
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 106
           .dw 9
           .dw 119
           .dw 6
           .dw 47
           .dw 7
           .dw 14
           .dw 7
           .dw 18
           .dw 6
           .dw 5
           .dw 13
           .dw 21
           .dw 6
           .dw 28
           .dw 20
           .dw 42
           .dw 6
           .dw 47
           .dw 7
           .dw 14
           .dw 7
           .dw 18
           .dw 6
           .dw 3
           .dw 17
           .dw 19
           .dw 6
           .dw 24
           .dw 24
           .dw 42
           .dw 6
           .dw 46
           .dw 8
           .dw 14
           .dw 8
           .dw 17
           .dw 6
           .dw 2
           .dw 19
           .dw 18
           .dw 6
           .dw 21
           .dw 27
           .dw 42
           .dw 6
           .dw 46
           .dw 9
           .dw 12
           .dw 9
           .dw 17
           .dw 6
           .dw 1
           .dw 20
           .dw 18
           .dw 6
           .dw 19
           .dw 29
           .dw 42
           .dw 6
           .dw 46
           .dw 9
           .dw 12
           .dw 9
           .dw 17
           .dw 13
           .dw 6
           .dw 9
           .dw 17
           .dw 6
           .dw 17
           .dw 31
           .dw 42
           .dw 6
           .dw 45
           .dw 10
           .dw 12
           .dw 9
           .dw 17
           .dw 10
           .dw 11
           .dw 7
           .dw 17
           .dw 6
           .dw 16
           .dw 13
           .dw 13
           .dw 6
           .dw 42
           .dw 6
           .dw 45
           .dw 10
           .dw 12
           .dw 10
           .dw 16
           .dw 9
           .dw 13
           .dw 7
           .dw 16
           .dw 6
           .dw 15
           .dw 10
           .dw 17
           .dw 6
           .dw 42
           .dw 6
           .dw 45
           .dw 11
           .dw 10
           .dw 11
           .dw 16
           .dw 8
           .dw 15
           .dw 6
           .dw 16
           .dw 6
           .dw 14
           .dw 9
           .dw 19
           .dw 6
           .dw 42
           .dw 6
           .dw 45
           .dw 11
           .dw 10
           .dw 11
           .dw 16
           .dw 8
           .dw 15
           .dw 6
           .dw 16
           .dw 6
           .dw 14
           .dw 7
           .dw 21
           .dw 6
           .dw 42
           .dw 6
           .dw 44
           .dw 12
           .dw 10
           .dw 12
           .dw 15
           .dw 7
           .dw 16
           .dw 6
           .dw 16
           .dw 6
           .dw 13
           .dw 7
           .dw 22
           .dw 6
           .dw 42
           .dw 6
           .dw 44
           .dw 6
           .dw 1
           .dw 5
           .dw 10
           .dw 5
           .dw 1
           .dw 6
           .dw 15
           .dw 7
           .dw 16
           .dw 6
           .dw 16
           .dw 6
           .dw 12
           .dw 7
           .dw 23
           .dw 6
           .dw 42
           .dw 6
           .dw 44
           .dw 6
           .dw 1
           .dw 6
           .dw 8
           .dw 6
           .dw 1
           .dw 6
           .dw 15
           .dw 6
           .dw 17
           .dw 6
           .dw 16
           .dw 6
           .dw 12
           .dw 7
           .dw 23
           .dw 6
           .dw 42
           .dw 6
           .dw 44
           .dw 6
           .dw 2
           .dw 5
           .dw 8
           .dw 5
           .dw 2
           .dw 6
           .dw 15
           .dw 6
           .dw 16
           .dw 7
           .dw 16
           .dw 6
           .dw 12
           .dw 6
           .dw 24
           .dw 6
           .dw 42
           .dw 6
           .dw 43
           .dw 7
           .dw 2
           .dw 5
           .dw 8
           .dw 5
           .dw 2
           .dw 7
           .dw 14
           .dw 6
           .dw 16
           .dw 6
           .dw 17
           .dw 6
           .dw 11
           .dw 7
           .dw 24
           .dw 6
           .dw 42
           .dw 6
           .dw 43
           .dw 6
           .dw 3
           .dw 5
           .dw 8
           .dw 5
           .dw 3
           .dw 6
           .dw 14
           .dw 6
           .dw 15
           .dw 7
           .dw 17
           .dw 6
           .dw 11
           .dw 6
           .dw 25
           .dw 6
           .dw 42
           .dw 6
           .dw 43
           .dw 6
           .dw 4
           .dw 5
           .dw 6
           .dw 5
           .dw 4
           .dw 6
           .dw 14
           .dw 6
           .dw 12
           .dw 10
           .dw 17
           .dw 6
           .dw 11
           .dw 6
           .dw 25
           .dw 6
           .dw 42
           .dw 6
           .dw 43
           .dw 6
           .dw 4
           .dw 5
           .dw 6
           .dw 5
           .dw 4
           .dw 6
           .dw 14
           .dw 27
           .dw 18
           .dw 6
           .dw 10
           .dw 7
           .dw 25
           .dw 6
           .dw 42
           .dw 6
           .dw 42
           .dw 7
           .dw 4
           .dw 5
           .dw 6
           .dw 5
           .dw 4
           .dw 7
           .dw 13
           .dw 26
           .dw 19
           .dw 6
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 42
           .dw 6
           .dw 5
           .dw 5
           .dw 5
           .dw 6
           .dw 5
           .dw 6
           .dw 13
           .dw 25
           .dw 20
           .dw 6
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 42
           .dw 6
           .dw 6
           .dw 5
           .dw 4
           .dw 5
           .dw 6
           .dw 6
           .dw 13
           .dw 23
           .dw 22
           .dw 6
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 42
           .dw 6
           .dw 6
           .dw 5
           .dw 4
           .dw 5
           .dw 6
           .dw 6
           .dw 13
           .dw 19
           .dw 26
           .dw 6
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 41
           .dw 7
           .dw 6
           .dw 5
           .dw 4
           .dw 5
           .dw 7
           .dw 6
           .dw 12
           .dw 6
           .dw 39
           .dw 6
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 41
           .dw 6
           .dw 7
           .dw 6
           .dw 2
           .dw 6
           .dw 7
           .dw 6
           .dw 12
           .dw 6
           .dw 39
           .dw 6
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 41
           .dw 6
           .dw 8
           .dw 5
           .dw 2
           .dw 5
           .dw 8
           .dw 6
           .dw 12
           .dw 6
           .dw 38
           .dw 7
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 40
           .dw 7
           .dw 8
           .dw 5
           .dw 2
           .dw 5
           .dw 8
           .dw 6
           .dw 13
           .dw 5
           .dw 38
           .dw 7
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 40
           .dw 6
           .dw 9
           .dw 5
           .dw 2
           .dw 5
           .dw 9
           .dw 6
           .dw 12
           .dw 6
           .dw 36
           .dw 8
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 40
           .dw 6
           .dw 9
           .dw 12
           .dw 9
           .dw 6
           .dw 12
           .dw 6
           .dw 36
           .dw 8
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 40
           .dw 6
           .dw 10
           .dw 10
           .dw 10
           .dw 6
           .dw 13
           .dw 6
           .dw 18
           .dw 1
           .dw 15
           .dw 9
           .dw 10
           .dw 6
           .dw 26
           .dw 6
           .dw 42
           .dw 6
           .dw 39
           .dw 7
           .dw 10
           .dw 10
           .dw 10
           .dw 7
           .dw 12
           .dw 8
           .dw 14
           .dw 3
           .dw 14
           .dw 10
           .dw 11
           .dw 6
           .dw 25
           .dw 6
           .dw 42
           .dw 6
           .dw 39
           .dw 6
           .dw 11
           .dw 10
           .dw 11
           .dw 6
           .dw 13
           .dw 9
           .dw 9
           .dw 6
           .dw 4
           .dw 1
           .dw 7
           .dw 12
           .dw 11
           .dw 6
           .dw 25
           .dw 6
           .dw 42
           .dw 6
           .dw 39
           .dw 6
           .dw 12
           .dw 8
           .dw 12
           .dw 6
           .dw 13
           .dw 24
           .dw 4
           .dw 13
           .dw 1
           .dw 6
           .dw 11
           .dw 6
           .dw 25
           .dw 6
           .dw 42
           .dw 6
           .dw 39
           .dw 6
           .dw 12
           .dw 8
           .dw 12
           .dw 6
           .dw 14
           .dw 23
           .dw 4
           .dw 12
           .dw 2
           .dw 6
           .dw 11
           .dw 7
           .dw 24
           .dw 6
           .dw 42
           .dw 6
           .dw 38
           .dw 7
           .dw 12
           .dw 8
           .dw 12
           .dw 7
           .dw 15
           .dw 20
           .dw 5
           .dw 11
           .dw 3
           .dw 6
           .dw 12
           .dw 6
           .dw 24
           .dw 6
           .dw 42
           .dw 6
           .dw 38
           .dw 6
           .dw 13
           .dw 8
           .dw 13
           .dw 6
           .dw 16
           .dw 16
           .dw 8
           .dw 10
           .dw 4
           .dw 6
           .dw 12
           .dw 7
           .dw 23
           .dw 6
           .dw 42
           .dw 6
           .dw 103
           .dw 10
           .dw 11
           .dw 7
           .dw 25
           .dw 7
           .dw 23
           .dw 6
           .dw 42
           .dw 6
           .dw 157
           .dw 7
           .dw 22
           .dw 6
           .dw 42
           .dw 6
           .dw 158
           .dw 7
           .dw 21
           .dw 6
           .dw 42
           .dw 6
           .dw 158
           .dw 9
           .dw 19
           .dw 6
           .dw 42
           .dw 6
           .dw 159
           .dw 10
           .dw 17
           .dw 6
           .dw 42
           .dw 6
           .dw 160
           .dw 13
           .dw 13
           .dw 6
           .dw 42
           .dw 6
           .dw 161
           .dw 31
           .dw 42
           .dw 6
           .dw 163
           .dw 29
           .dw 42
           .dw 6
           .dw 165
           .dw 27
           .dw 42
           .dw 6
           .dw 168
           .dw 24
           .dw 42
           .dw 6
           .dw 172
           .dw 20
           .dw 42
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 6
           .dw 234
           .dw 723
           .dw 0

debugwd0:  .dw 0                       ; debug word slots, for writing values into memory
debugwd1:  .dw 0                       ; (useful when trying to debug with SignalTap)
debugwd2:  .dw 0
debugwd3:  .dw 0
           
