class iss:
    def __init__(self, __code_lines, __data_lines, trace_file = None, __cycles = 500):
        self.registers = [0x0000] * 16 # registers are always represented as a positive int, and are interpretted as negative through getsigned
        self.code_memory = [int(k, 0) for k in __code_lines]
        self.data_memory = [int(k, 0) for k in __data_lines]
        
        self.pc = 0x0
        self.sp = 0xffff # post decremented on push, pre incremented on pop
        
        self.halted = False
        self.trace = False
        if trace_file is not None:    
            self.trace_file = trace_file
            self.trace = True
            
        self.cycles = __cycles
            
    def reset(self):
        self.pc = 0x0
        self.sp = 0xffff
        self.run()
        
    def run(self):
        # fetch an instruction from code memory using pc, inc pc
        # decode fields by tree
        # make a chain of ifs to call suitable function
        # update registers, sp & mem 
        
        cycles_left = self.cycles
        
        def inc(val):
            return (val + 1) & 0xffff
            
        def dec(val):
            return (val - 1) & 0xffff
            
        def getsigned(reg):
            if (self.registers[reg] >> 15): 
                return (self.registers[reg] - (1 << 16)) 
            else:
                return self.registers[reg]
            
        def setreg(reg, val):
            self.registers[reg] = val & 0xffff
            
        def tosigned(val, width):
            if val >> (width - 1):
                return val - (1 << width)
            else:
                return val
                
        def setmem(addr, val):
            if self.trace:
                self.trace_file.write("set mem %04x to %04x\n" % (addr, val))
            self.data_memory[addr & 0xffff] = val & 0xffff
            
        def getmem(addr, internal = False):
            if (self.trace and not internal):
                self.trace_file.write("get mem %04x\n" % addr)
            return self.data_memory[addr & 0xffff]
        
        while (cycles_left > 0) and (not self.halted):
          ir = self.code_memory[self.pc]
          if (self.trace):
              self.trace_file.write("fetch %04x @pc %04x\n" % (ir, self.pc))
          self.pc = inc(self.pc)
          
          rnb = ir & 0x000f # these are so common we will always extract them
          rna = (ir & 0x00f0) >> 4
          
          if (ir & 0xc000) == 0: 
              # store instruction
              rbuv = self.registers[rnb]
              rav = getsigned(rna)
              offset = tosigned((ir & 0x3f00) >> 8, 6)
              eaddr = rbuv + offset
              was = getmem(eaddr, True)
              
              setmem(eaddr, rav)
              
              if self.trace:
                  self.trace_file.write("sto @%d offset %d rna %d v %d was %d now %d\n" % (rbuv, offset, rna, rav, was, getmem(eaddr))) 
              
          elif (ir & 0xc000) == 0x4000:
              # load instruction
              rbv = self.registers[rnb]
              offset = tosigned((ir & 0x3f00) >> 8, 6)
              eaddr = rbv + offset
              
              got = getmem(eaddr)
              
              setreg(rna, got)
              
              if self.trace:
                  self.trace_file.write("ldo @%d offset %d got %d into %d\n" % (rbv, offset, got, rna))
              
          elif (ir & 0x7000) == 0:
              # calli instruction
              old_pc = self.pc
              old_sp = self.sp
              was = getmem(self.sp, True)
              call = tosigned(ir & 0x0fff, 12)
              
              setmem(self.sp, self.pc)
              now = getmem(self.sp, True)
              
              self.sp = dec(self.sp)
              
              self.pc += call
              
              if self.trace:
                  self.trace_file.write("calli called %d set @%d (now %d) was %d now %d pc was %d now %d\n" % (call, old_sp, self.sp, was, now, old_pc, self.pc))
              
          elif (ir & 0x7000) == 0x1000:
              # jmpi instruction
              jump = tosigned(ir & 0x0fff, 12)
              old_pc = self.pc
              self.pc += jump
              
              if self.trace:
                  self.trace_file.write("jmpi from %d by %d now %d\n" % (old_pc, jump, self.pc))
              
          elif (ir & 0x7000) == 0x2000:
              # consth instruction
              rbv = getsigned(rnb)
              
              self.registers[rnb] &= 0x00ff
              self.registers[rnb] += (ir & 0x0ff0) << 4 # python always interprets everything that it DIDN'T make negative itself as positive
              
              if self.trace:
                  self.trace_file.write("consth reg %d was %d now %d\n" % (rnb, rbv, getsigned(rnb))) 
              
          elif (ir & 0x7000) == 0x3000:
              # constl instruction
              rbv = getsigned(rnb)
              
              setreg(rnb, tosigned((ir & 0x0ff0) >> 4, 8))
              
              if self.trace:
                  self.trace_file.write("constl reg %d was %d now %d\n" % (rnb, rbv, getsigned(rnb)))
              
          elif (ir & 0x2000) == 0:
              # pushi instruction
              was = getmem(self.sp, True)
              setmem(self.sp, tosigned(ir & 0x1fff, 13))
              now = getmem(self.sp, True)
              if self.trace:
                  self.trace_file.write("pushi sp %d was %d now %d\n" % (self.sp, was, now))
              self.sp = dec(self.sp)
              
          elif (ir & 0x1f00) == 0x0000:
              # add instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              
              setreg(rna, rav + rbv)
              
              if self.trace:
                  self.trace_file.write("add rnb %d v %d into rna %d v %d now %d\n" % (rnb, rbv, rna, rav, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0100:
              # sub instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              
              setreg(rna, rav - rbv)
              
              if self.trace:
                  self.trace_file.write("sub rnb %d v %d from rna %d v %d now %d\n" % (rnb, rbv, rna, rav, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0200:
              # and instruction
              rauv = self.registers[rna]
              rbuv = self.registers[rnb]
              
              setreg(rna, rauv & rbuv)
              
              if self.trace:
                  self.trace_file.write("and rnb %d uv %d and rna %d uv %d now %d\n" % (rnb, rbuv, rna, rauv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0300:
              # ior instruction
              rauv = self.registers[rna]
              rbuv = self.registers[rnb]
              
              setreg(rna, rauv | rbuv)
              
              if self.trace:
                  self.trace_file.write("ior rnb %d uv %d and rna %d uv %d now %d\n" % (rnb, rbuv, rna, rauv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0400:
              # xor instruction
              rauv = self.registers[rna]
              rbuv = self.registers[rnb]
              
              setreg(rna, rauv ^ rbuv)
              
              if self.trace:
                  self.trace_file.write("xor rnb %d uv %d and rna %d uv %d now %d\n" % (rnb, rbuv, rna, rauv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0500:
              # logical shift l instruction
              rauv = self.registers[rna]
              rbuv = self.registers[rnb]
              
              setreg(rna, rauv << rbuv)
              
              if self.trace:
                  self.trace_file.write("lsftl rna %d uv %d by rnb %d uv %d now %d\n" % (rna, rauv, rnb, rbuv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0600:
              # arithmetic shift r instruction
              rav = getsigned(rna)
              rbuv = self.registers[rnb]
              
              setreg(rna, rav >> rbuv)
              
              if self.trace:
                  self.trace_file.write("asftr rna %d v %d by rnb %d uv %d now %d\n" % (rna, rav, rnb, rbuv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0700:
              # logical shift r instruction
              rauv = self.registers[rna]
              rbuv = self.registers[rnb]

              setreg(rna, rauv >> rbuv)
              
              if self.trace:
                  self.trace_file.write("lsftr rna %d uv %d by rnb %d uv %d now %d\n" % (rna, rauv, rnb, rbuv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0800:
              # multiply, store the l bits instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              product = rav * rbv
              
              setreg(rna, product)
              
              if self.trace:
                  self.trace_file.write("multl rna %d v %d with rnb %d v %d got %d now %d\n" % (rna, rav, rnb, rbv, product, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0900:
              # multiply, store the h bits instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              product = (rav * rbv) >> 16
              
              setreg(rna, product)
              
              if self.trace:
                  self.trace_file.write("multh rna %d v %d with rnb %d v %d now %d\n" % (rna, rav, rnb, rbv, getsigned(rna)))
              
          elif (ir & 0x1f00) == 0x0a00:
              # move instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)

              self.registers[rna] = self.registers[rnb]
              
              if self.trace:
                  self.trace_file.write("move rnb %d v %d into rna %d v %d now %d\n" % (rnb, rbv, rna, rav, getsigned(rna)))
              
          elif (ir & 0x0f00) == 0:
              # skip less than instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if rav < rbv:
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("sklt rna %d v %d < rnb %d v %d pc was %d now %d Skipped? %s\n" % (rna, rav, rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x0f00) == 0x0100:
              # skip greater than instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if rav > rbv:
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skgt rna %d v %d > rnb %d v %d pc was %d now %d Skipped? %s\n" % (rna, rav, rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x0f00) == 0x0200:
              # skip less than or equal to instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if rav <= rbv:
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skle rna %d v %d <= rnb %d v %d pc was %d now %d Skipped? %s\n" % (rna, rav, rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x0f00) == 0x0300:
              # skip greater than or equal to instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if rav >= rbv:
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skge rna %d v %d >= rnb %d v %d pc was %d now %d Skipped? %s\n" % (rna, rav, rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x0f00) == 0x0400:
              # skip equal to instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if rav == rbv:
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skeq rna %d v %d == rnb %d v %d pc was %d now %d Skipped? %s\n" % (rna, rav, rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x0f00) == 0x0500:
              # skip not equal instruction
              rav = getsigned(rna)
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if rav != rbv:
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skne rna %d v %d != rnb %d v %d pc was %d now %d Skipped? %s\n" % (rna, rav, rnb, rbv, old_pc, self.pc, skip_taken))
                  
          elif (ir & 0x07f0) == 0:
              # inc instruction
              rbv = getsigned(rnb)
              
              setreg(rnb, inc(rbv))
              
              if self.trace:
                  self.trace_file.write("inc rnb %d v %d now %d\n" % (rnb, rbv, getsigned(rnb)))
              
          elif (ir & 0x07f0) == 0x0010:
              # dec instruction
              rbv = getsigned(rnb)

              setreg(rnb, dec(rbv))
              
              if self.trace:
                  self.trace_file.write("dec rnb %d v %d now %d\n" % (rnb, rbv, getsigned(rnb)))
              
          elif (ir & 0x07f0) == 0x0020:
              # negate instruction
              rbv = getsigned(rnb)

              setreg(rnb, -rbv)
              
              if self.trace:
                  self.trace_file.write("neg rnb %d v %d now %d\n" % (rnb, rbv, getsigned(rnb)))
              
          elif (ir & 0x07f0) == 0x0030:
              # complement instruction
              rbuv = self.registers[rnb]
              
              setreg(rnb, ~rbuv)
              
              if self.trace:
                  self.trace_file.write("com rnb %d uv %d now %d\n" % (rnb, rbuv, getsigned(rnb)))
              
          elif (ir & 0x07f0) == 0x0040:
              # call register instruction
              rbuv = self.registers[rnb]
              old_sp = self.sp
              old_pc = self.pc
              was = getmem(self.sp, True)

              setmem(self.sp, self.pc)
              now = getmem(self.sp, True)
              self.sp = dec(self.sp)
              
              self.pc = rbuv
              
              if self.trace:
                  self.trace_file.write("callr sp was %d now %d mem was %d now %d pc was %d now %d = rnb %d uv %d\n" % (old_sp, self.sp, was, now, old_pc, self.pc, rnb, rbuv)) 
          
          elif (ir & 0x07f0) == 0x0050:
              # jump to register instruction
              rbuv = self.registers[rnb]
              old_pc = self.pc

              self.pc = rbuv
              
              if self.trace:
                  self.trace_file.write("jmpr pc was %d now %d = rnb %d uv %d\n" % (old_pc, self.pc, rnb, rbuv))
              
          elif (ir & 0x07f0) == 0x0060:
              # move reg into sp instruction
              rbuv = self.registers[rnb]
              old_sp = self.sp

              self.sp = rbuv
              
              if self.trace:
                  self.trace_file.write("movrsp sp was %d now %d = rnb %d uv %d\n" % (old_sp, self.sp, rnb, rbuv))
              
          elif (ir & 0x07f0) == 0x0070:
              # move sp into reg instruction
              rbuv = self.registers[rnb]

              self.registers[rnb] = self.sp
              
              if self.trace:
                  self.trace_file.write("movspr rnb %d was %d now %d = sp %d\n" % (rnb, rbuv, self.registers[rnb], self.sp))
              
          elif (ir & 0x07f0) == 0x0080:
              # push reg onto stack instruction
              rbuv = self.registers[rnb]
              old_sp = self.sp
              was = getmem(self.sp, True)

              setmem(self.sp, self.registers[rnb])
              now = getmem(self.sp, True)
              self.sp = dec(self.sp)
              
              if self.trace:
                  self.trace_file.write("pushr rnb %d uv %d onto sp %d now %d mem was %d now %d\n" % (rnb, rbuv, old_sp, self.sp, was, now))
              
          elif (ir & 0x07f0) == 0x0090:
              # pop last on stack into reg
              old_sp = self.sp
              self.sp = inc(self.sp) # I need to explain the behavior so I'll do it here
                                     # the sp is always where it can be written unchanged,
                                     # which puts it one address below the last useful entry
                                     # and thus I have to inc it to get the last value that
                                     # actually went on the stack.
              val = getmem(self.sp)
              setreg(rnb, val)
              
              if self.trace:
                  self.trace_file.write("popr sp started %d inc to %d rnb %d set to val %d\n" % (old_sp, self.sp, rnb, val))
              
          elif (ir & 0x03f0) == 0:
              # skip zero instruction
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if (rbv == 0):
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skz rnb %d v %d == 0 pc was %d now %d Skipped? %s\n" % (rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x03f0) == 0x0010:
              # skip not zero instruction
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if (rbv != 0):
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("sknz rnb %d v %d != 0 pc was %d now %d Skipped? %s\n" % (rnb, rbv, old_pc, self.pc, skip_taken))
                  
          elif (ir & 0x03f0) == 0x0020:
              # skip minus instruction
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if (rbv < 0):
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skmi rnb %d v %d < 0 pc was %d now %d Skipped? %s\n" % (rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif (ir & 0x03f0) == 0x0030:
              # skip plus instruction
              rbv = getsigned(rnb)
              old_pc = self.pc
              skip_taken = False

              if (rbv >= 0):
                  self.pc = inc(self.pc)
                  skip_taken = True
                  
              if self.trace:
                  self.trace_file.write("skz rnb %d v %d >= 0 pc was %d now %d Skipped? %s\n" % (rnb, rbv, old_pc, self.pc, skip_taken))
              
          elif ir == 0xfe00:
              # halt instruction
              if self.trace:
                  self.trace_file.write("halt\n")
              self.halted = True
              
          elif ir == 0xfe01:
              # reset instruction
              if self.trace:
                  self.trace_file.write("reset\n")
              self.reset()
              
          elif ir == 0xfe02:
              # return instruction
              # note, this returns from exactly one (the most recent) call.
              old_sp = self.sp
              old_pc = self.pc
              self.sp = inc(self.sp)
              val = getmem(self.sp)
              self.pc = val # the sp is now consumed, therefore we can write this same address
              
              if self.trace:
                  self.trace_file.write("retn sp started %d inc to %d pc was %d now %d = val %d\n" % (old_sp, self.sp, old_pc, self.pc, val))
                  
          elif ir == 0xfe03:
              # clr instruction
              self.registers = [0] * 16
              if self.trace:
                  self.trace_file.write("clr\n")
              
          # sys instructions
          elif (ir & 0xff00) == 0xff00:
              # rna happens to be the right 4 bits. IT IS NOT A REGISTER HERE!
              if   rna == 0x0:
                  # print the character in rnb
                  rbch = chr(self.registers[rnb])
                  print rbch,
                  if self.trace:
                      self.trace_file.write("sys 0 %s\n" % rbch)
              elif rna == 0xf:
                  rbuv = self.registers[rnb]
                  print rbuv,
                  if self.trace:
                      self.trace_file.write("sys f %d\n" % rbuv)
              
          cycles_left -= 1
        
if __name__ == "__main__":
    import sys
    hsm = sys.argv[1]
    data = sys.argv[2]
    trc = sys.argv[3]
    
    cycles = int(sys.argv[4], 0)
    
    hsm_lines = [ln.strip() for ln in open(hsm, 'r')]
    data_lines = [ln.strip() for ln in open(data, 'r')]
    trc_file = open(trc, 'w')
    
    sim = iss(hsm_lines, data_lines, trc_file, cycles)
    sim.run()
