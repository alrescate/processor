def hex_to_mif(indata, base, width, depth):
	# indata is array
	# all types are numerical
	ret = ["", "WIDTH=%d;" % width, "DEPTH=%d;" % depth, "", "ADDRESS_RADIX=HEX;", "DATA_RADIX=HEX;", "", "CONTENT BEGIN"] 
	for i in xrange(base, base+depth):
		ret.append("%x : %x;" % (i-base, indata[i]))
		
	ret.append("END;")
	return ret
	
if __name__ == "__main__":
	import argparse

	parser=argparse.ArgumentParser()
	parser.add_argument('--infile',default='',type=str)
	parser.add_argument('--outfile',default='',type=str)
	parser.add_argument('--base',default='',type=str)
	parser.add_argument('--width',default='',type=str)
	parser.add_argument('--depth',default='',type=str)
	args=vars(parser.parse_args())
	
	infile=args['infile']
	outfile=args['outfile']
	baseaddr=int(args['base'], 0)
	width=int(args['width'], 0)
	depth=int(args['depth'], 0)
	
	print baseaddr
	
	inlines = [int(ln.strip(), 16) for ln in open(infile, 'r')]
	outdata = hex_to_mif(inlines, baseaddr, width, depth)
	out = open(outfile, 'w+')
	
	for ln in outdata: 
		out.write(ln+"\n")
	
	out.close()
