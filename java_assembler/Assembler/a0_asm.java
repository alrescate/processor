package Assembler;
import java.io.*;
public class a0_asm {
    private final int N = 1 << 16;
    private int[] code;
    private int[] data;
    private String[] err;
    
    private int data_ptr;
    private int code_ptr;
    private int err_ptr;
    
    private String addr_space;
    
    public a0_asm() { // potentially a fileIO thing goes here
        // populate code and data arrays with defaults -- 0xfe00 is halt instr
        code = new int[N];    code_ptr = 0;
        data = new int[N];    data_ptr = 0;
        err  = new String[N]; err_ptr = 0;
        for (int i = 0; i < N; i++) { code[i] = 0xfe00; data[i] = 0; err[i] = ""; }
        addr_space = "code";
    }
    
    public int instr(String[] lineItems, int opcode, 
                     int mask1, int shift1, 
                     int mask2, int shift2, 
                     int mask3, int shift3) {
        int op = opcode;
        // masks are used to constrict sign extension from the parseInt function
                         op |= (parseInt(lineItems[1]) & ((1 << mask1) - 1)) << shift1;
        if (mask2 != -1) op |= (parseInt(lineItems[2]) & ((1 << mask2) - 1)) << shift2;
        if (mask3 != -1) op |= (parseInt(lineItems[3]) & ((1 << mask3) - 1)) << shift3;
        return op;
    }
    
    private int parseInt(String in) {
        // System.out.println(in); 
        // we have to do this if first or we might index out of range, please don't write code like this on the AP test
        if (in.length() >= 3) 
            if (in.charAt(0) == '0' && in.charAt(1) == 'x') 
                return Integer.parseInt(in.substring(2), 16);
        return Integer.parseInt(in, 10);
    }
    
    private void reportError(String errDesc, String[] lineItems) {
        String err_line = "";
        for (int i = 0; i < lineItems.length; i++) {
            err_line += lineItems[i] + " ";
        }
           
        this.err[err_ptr++] = errDesc + " from \"" + err_line + "\"" + "\n";
    }
    
    private void processLine(String line)  {
        // System.out.println(line);
        String[] lineItems = line.trim().split(" ");
        if (lineItems.length != 0) {
            if (lineItems[0].length() != 0) {
                if (lineItems[0].charAt(0) != ';') {
                    String op_dir = lineItems[0];
                    if (op_dir.charAt(0) == '.') {
                        // it's a directive
                        String directive = op_dir.substring(1);
                        if (directive.equals("data")) {
                            addr_space = "data";
                            // Java parseInt redefined outside Integer namespace
                            // for shared 10/16 radix by initial characters
                            data_ptr = parseInt(lineItems[1]);
                        }
                        else if (directive.equals("code")) {
                            addr_space = "code";
                            code_ptr = parseInt(lineItems[1]);
                        }
                        else if (directive.equals("ds")) {
                            // ds loads sectors of code/data memory directly
                        	// .ds is lineItems[0]
                            if (addr_space.equals("code")) {
                                for (int a = 1; a < lineItems.length; a++) {
                                    this.code[code_ptr++] = parseInt(lineItems[a]);
                                    if (code_ptr >= N || code_ptr < 0) {
                                        reportError("Illegal code address " + code_ptr, lineItems);
                                        break;
                                    }
                                }
                            }
                            else {
                                for (int a = 1; a < lineItems.length; a++) {
                                    this.data[data_ptr++] = parseInt(lineItems[a]);
                                    if (data_ptr >= N || data_ptr < 0) {
                                        reportError("Illegal data address " + data_ptr, lineItems);
                                        break;
                                    }
                                }
                            }
                        }
                        else {
                            reportError("Illegal directive", lineItems);
                        }
                    }
                    
                    else {
                        // 42 ifs, one for each instruction
                        // the ifs determine how many fields are expected and their purpose.
                        if (op_dir.equals("sto")){
                            if (lineItems.length == 4) {
                                // less than 4 would indicate we didn't have enough args to assemble this
                                this.code[code_ptr] = instr(lineItems, (0x0 << 14), 6, 8, 4, 4, 4, 0);
                                code_ptr++; 
                            }
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("ldo")){
                            if (lineItems.length == 4) {
                                // less than 4 would indicate we didn't have enough args for assembly
                                this.code[code_ptr] = instr(lineItems, (0x1 << 14), 6, 8, 4, 4, 4, 0);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("calli")){
                            if (lineItems.length == 2) {
                                // less than 2 would indicate we didn't have enough args
                                this.code[code_ptr] = instr(lineItems, (0x8 << 12), 12, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("jmpi")){
                            if (lineItems.length == 2) {
                                // check args
                                this.code[code_ptr] = instr(lineItems, (0x9 << 12), 12, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("consth")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xa << 12), 8, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("constl")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xb << 12), 8, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("pushi")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xc << 12), 13, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("add")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe0 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("sub")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe1 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("and")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe2 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                            
                        else if (op_dir.equals("ior")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe3 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("xor")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe4 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("lsftl")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe5 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("asftr")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe6 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("lsftr")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe7 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("multl")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe8 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("multh")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xe9 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("move")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xea << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("sklt")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xf0 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            }
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skgt")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xf1 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skle")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xf2 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skge")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xf3 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skeq")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xf4 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skne")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xf5 << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("inc")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf80 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("dec")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf81 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("neg")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf82 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("com")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf83 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("callr")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf84 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("jmpr")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf85 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("movrsp")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf86 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("movspr")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf87 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("pushr")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf88 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("popr")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xf89 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skz")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xfc0 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("sknz")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xfc1 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skmi")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xfc2 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("skpl")){
                            if (lineItems.length == 2) {
                                this.code[code_ptr] = instr(lineItems, (0xfc3 << 4), 4, 0, -1, -1, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                                
                        else if (op_dir.equals("halt")){
                            this.code[code_ptr] = 0xfe00;
                            code_ptr++; 
                        }
                            
                        else if (op_dir.equals("reset")){
                            this.code[code_ptr] = 0xfe01;
                            code_ptr++; 
                        }
                            
                        else if (op_dir.equals("retn")){
                            this.code[code_ptr] = 0xfe02;
                            code_ptr++; 
                        }
                            
                        else if (op_dir.equals("clr")){
                            this.code[code_ptr] = 0xfe03;
                            code_ptr++; 
                        }
                            
                        else if (op_dir.equals("sys")){
                            if (lineItems.length == 3) {
                                this.code[code_ptr] = instr(lineItems, (0xff << 8), 4, 4, 4, 0, -1, -1);
                                code_ptr++; 
                            } 
                            else reportError("Bad field number", lineItems);
                        }
                        else reportError("Illegal operation", lineItems);
                    }
                }
            }
        }
    }
    
    public void asm_file(String sourceFile) {
        BufferedReader reader;
        try {
            reader = new BufferedReader(new FileReader(sourceFile));
            String line = "";
            while (line != null) {
                processLine(line);
                try {
                    line = reader.readLine();
                }
                catch (IOException e) {
                    e.printStackTrace();
                    break;
                }
            }
            reader.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    public void asm_arr(String[] sourceLines) {
        for (int l = 0; l < sourceLines.length; l++) {
            processLine(sourceLines[l]);
        }
    }
    
    private void writeBack(String destFileCode, String destFileData, String destFileErr) throws IOException {
        PrintWriter codeWriter = new PrintWriter(new FileWriter(destFileCode));
        PrintWriter dataWriter = new PrintWriter(new FileWriter(destFileData));
        PrintWriter errWriter  = new PrintWriter(new FileWriter(destFileErr));
        
        // write assembled results out - note, masking is to prevent
    	// sign extension beyond MINIMUM of 4 from format string, like
    	// with value "-1"
        for (int a = 0; a < N; a++) {
            codeWriter.printf("0x%04x\n", this.code[a] & 0xffff);
            dataWriter.printf("0x%04x\n", this.data[a] & 0xffff);
            errWriter.printf( "%s",       this.err [a]);
        }
        
        codeWriter.close();
        dataWriter.close();
        errWriter.close();
    }
    
    public void writeBack(PrintWriter codeWriter, PrintWriter dataWriter, PrintWriter errWriter) throws IOException {
        // write assembled results out - note, masking is to prevent
    	// sign extension beyond MINIMUM of 4 from format string, like
    	// with value "-1"
        for (int a = 0; a < N; a++) {
            codeWriter.printf("0x%04x\n", this.code[a] & 0xffff);
            dataWriter.printf("0x%04x\n", this.data[a] & 0xffff);
            errWriter.printf( "%s",       this.err [a]);
        }
        
        // NOTE: this version of the function is not responsible for I/O handling
    }
    
    public int getCode(int addr)   { return this.code[addr]; }
    public int getData(int addr)   { return this.data[addr]; }
    public String getErr(int addr) { return this.err [addr]; }
    
    public static void main(String[] args) throws IOException {
        a0_asm test = new a0_asm();
        test.asm_file(args[0]); // assemble based on 0th argument
        test.writeBack(args[1], args[2], args[3]); // codehex then datahex
    }
}
