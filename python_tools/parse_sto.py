def cchar(st, i, nc):
    return st[:i] + str(nc) + st[(i+1):]
def parse_sto(indata):
    # indata is an array of lines
    vals = [int(k[(k.index("now")+4):]) for k in indata]
    print "BUSY BUSYE SCK MOSI DC CS1N CS2N CS3N"
    o =   " -     -    -   -   -    -   -    - " # magic numbers are...
                                               # 1, 7, 12, 16, 20, 25, 29, 34
    busyi  = 0
    busyei = 0
    scki   = 0
    mosii  = 0
    dci    = 0
    cs1i   = 0
    cs2i   = 0
    cs3i   = 0
    for v in vals:
        busyi  =   v >> 15
        busyei = ( v >> 14) & 1
        scki   = (scki  | ((v >>  8) & 1)) & ~((v >> 0) & 1)
        mosii  = (mosii | ((v >>  9) & 1)) & ~((v >> 1) & 1)
        dci    = (dci   | ((v >> 10) & 1)) & ~((v >> 2) & 1)
        cs1i   = (cs1i | ((v >> 11) & 1)) & ~((v >> 3) & 1)
        cs2i   = (cs2i | ((v >> 12) & 1)) & ~((v >> 4) & 1)
        cs3i   = (cs3i | ((v >> 13) & 1)) & ~((v >> 5) & 1)      
        o =   " -     -    -   -   -    -   -    - "
        
        # print busy, busye, scs3n, scs2n, scs1n, sdc, smosi, ssck, ccs3n, ccs2n, ccs1n, cdc, cmosi, csck
        
        o = cchar(o, 1,  busyi)
        o = cchar(o, 7,  busyei)
        o = cchar(o, 12, scki)
        o = cchar(o, 16, mosii)
        o = cchar(o, 20, dci)
        o = cchar(o, 25, (~cs1i)&1)
        o = cchar(o, 29, (~cs2i)&1)
        o = cchar(o, 34, (~cs3i)&1)
        
        print o

if __name__ == "__main__":
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--infile',default='',type=str)
    args=vars(parser.parse_args())
    infile=args['infile']
    inlines = [ln.strip() for ln in open(infile, 'r')]
    
    parse_sto(inlines)