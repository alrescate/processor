class a0_asm:
    
    def __init__(self, __line_array):
        N = (1 << 16)
        self.code = [0xfe00] * N
        self.data = [0] * N
        
        data_ptr = 0
        code_ptr = 0
        
        address_space = "code"
        
        def instr(s, opcode, align1, align2 = (-1, -1), align3 = (-1, -1)):
            op = opcode # opcode bits, shifted by caller (not function)
            # masked so that Python sign ex to 32 bits doesn't break or
            # shifted for placement, thus align tuples are (precision, shift)
            op |= (int(s[1], 0) & ((1 << align1[0]) - 1)) << align1[1]
            if align2[0] != -1:
                op |= (int(s[2], 0) & ((1 << align2[0]) - 1)) << align2[1]
            if align3[0] != -1:
                op |= (int(s[3], 0) & ((1 << align3[0]) - 1)) << align3[1]
            
            return op
        
        for ln in __line_array:
            s = ln.split()
            if (len(s) != 0):
                if s[0][0] == ';':
                    # it's a comment, we're done here
                    pass
                else:
                    op_dir = s[0]
                    if op_dir[0] == '.':
                        # directive
                        directive = op_dir[1:]
                        if (directive == "data"):
                            address_space = "data"
                            data_ptr = int(s[1], 0)
                        elif (directive == "code"):
                            address_space = "code"
                            code_ptr = int(s[1], 0)
                        elif (directive == "ds"):
                            # the rest of the arguments are headed into the correct space
                            if address_space == "code":
                                for a in s[1:]:
                                    self.code[code_ptr] = int(a, 0)
                                    code_ptr += 1
                            else:
                                for a in s[1:]:
                                    self.data[data_ptr] = int(a, 0)
                                    data_ptr += 1
                    else:
                        # 42 ifs, one for each instruction
                        # the ifs determine how many fields are expected and their purpose.
                        if op_dir == "sto":
                            if len(s) == 4:
                                # less than 4 would indicate we didn't have enough args to assemble this
                                self.code[code_ptr] = instr(s, (0x0 << 14), (6, 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "ldo":
                            if len(s) == 4:
                                # less than 4 would indicate we didn't have enough args for assembly
                                self.code[code_ptr] = instr(s, (0x1 << 14), (6, 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "calli":
                            if len(s) == 2:
                                # less than 2 would indicate we didn't have enough args
                                self.code[code_ptr] = instr(s, (0x8 << 12), (12, 0))
                                code_ptr += 1
                                
                        elif op_dir == "jmpi":
                            if len(s) == 2:
                                # check args
                                self.code[code_ptr] = instr(s, (0x9 << 12), (12, 0))
                                code_ptr += 1
                                
                        elif op_dir == "consth":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xa << 12), (8, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "constl":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xb << 12), (8, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "pushi":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xc << 12), (13, 0))
                                code_ptr += 1
                                
                        elif op_dir == "add":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe0 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "sub":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe1 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "and":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe2 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "ior":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe3 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "xor":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe4 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "lsftl":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe5 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "asftr":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe6 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "lsftr":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe7 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "multl":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe8 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "multh":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xe9 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "move":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xea << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "sklt":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xf0 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skgt":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xf1 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skle":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xf2 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skge":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xf3 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skeq":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xf4 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skne":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xf5 << 8), (4, 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "inc":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf80 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "dec":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf81 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "neg":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf82 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "com":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf83 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "callr":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf84 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "jmpr":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf85 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "movrsp":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf86 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "movspr":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf87 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "pushr":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf88 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "popr":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xf89 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skz":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xfc0 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "sknz":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xfc1 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skmi":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xfc2 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "skpl":
                            if len(s) == 2:
                                self.code[code_ptr] = instr(s, (0xfc3 << 4), (4, 0))
                                code_ptr += 1
                                
                        elif op_dir == "halt":
                            self.code[code_ptr] = 0xfe00
                            code_ptr += 1
                            
                        elif op_dir == "reset":
                            self.code[code_ptr] = 0xfe01
                            code_ptr += 1
                            
                        elif op_dir == "retn":
                            self.code[code_ptr] = 0xfe02
                            code_ptr += 1
                            
                        elif op_dir == "clr":
                            self.code[code_ptr] = 0xfe03
                            code_ptr += 1
                            
                        elif op_dir == "sys":
                            if len(s) == 3:
                                self.code[code_ptr] = instr(s, (0xff << 8), (4, 4), (4, 0))
                                code_ptr += 1
                            
                        
        
if __name__ == "__main__":
    import sys

    a0file = sys.argv[1]
    codehex = open(sys.argv[2], 'w')
    datahex = open(sys.argv[3], 'w')
    text = [ln.strip() for ln in open(a0file, 'r')]
    
    a0 = a0_asm(text)
    for c in a0.code:
        codehex.write("0x%04x\n" % c)
        
    for d in a0.data:
        datahex.write("0x%04x\n" % d)
        
    codehex.close()
    datahex.close()