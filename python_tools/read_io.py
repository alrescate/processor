# read_io.py
import sys
txt = [ln.strip() for ln in open(sys.argv[1],'r')]
labels=txt[0].split()
lookup={}
for k in xrange(len(labels)):
  lookup[labels[k]]=k
  
shift_reg=[0]*8
bit_count=0
last_cs=1
last_sck=0
for k in xrange(1,len(txt)):
  ln=txt[k]
  s=[int(x) for x in ln.split()]
  
  def get(name):
    return s[lookup[name]]
 # BUSY BUSYE SCK MOSI DC CS1N CS2N CS3N
  cs=get('CS1N')
  dc=get('DC')
  mosi=get('MOSI')
  sck=get('SCK')
  #print cs,dc,mosi,sck
  if (last_cs==1) and (cs==0):
    bit_count=0
    
  if (last_sck==0) and (sck==1):
    shift_reg=[mosi]+shift_reg[0:7]
    #print shift_reg
    bit_count=(bit_count+1)%8
    if bit_count==0:
      val=0
      for k in xrange(8):
        val+=(shift_reg[k]<<k)
      if dc==0:
        print "command %02x" % val 
      else:
        print "data %02x" % val
  
  last_sck=sck
  last_cs=cs  
  