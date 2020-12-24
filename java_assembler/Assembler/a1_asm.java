package Assembler;
import java.io.*;
import java.util.*;
import Assembler.a0_asm;
import Assembler.lex;
import Assembler.line;

public class a1_asm {
    private a0_asm a0;
    private ArrayList<line> lexArr;
    private PrintWriter codeOut;
    private PrintWriter dataOut;
    private PrintWriter err;
    private PrintWriter log;
    private BufferedReader src;
    private HashMap<String, Integer> symbolTable;
    private boolean criticalFailure;
    private boolean nonCriticalFailure;
    
    public a1_asm(BufferedReader src, PrintWriter codeOut, PrintWriter dataOut, PrintWriter err, PrintWriter log) {
        // externalize the io elements
        this.src = src;
        this.codeOut = codeOut;
        this.dataOut = dataOut;
        this.err = err;
        this.log = log;
        
        a0 = new a0_asm();
        
        symbolTable = new HashMap<>();
        lexArr = new ArrayList<line>(0);
        criticalFailure = false;
        populateLexArr();
    }
    
    private void reportError(String desc, line l) {
        err.printf("Error issued from line %d, reading \"%s\", %s%n", l.getOLine(), l.getOContent().trim(), desc);
    }
    
    private void reportError(String desc) {
        err.printf("General error issued, %s%n", desc);
    }
    
    private void populateLexArr() {
        String cline = "";
        int ln = 0;
        lexeme reset = new lexeme(lexType.whitespace, "You should not see this", 0, 0);
        lexeme next = reset;
        int pushc = 0, popc = 0; // push count, pop count (for balance checking)
        while (cline != null) {
            lex currentLexer = new lex(cline, err, ln); 
            lexArr.add(new line(cline, ln, new ArrayList<lexeme>(0))); // this adds blank lines without detecting their nothingness
            next = reset;
            while (next.getType() != lexType.eol) {
                next = currentLexer.getNextToken(); 
                if (next.getType() != lexType.comment && next.getType() != lexType.whitespace && next.getType() != lexType.eol) { // don't record meaningless tokens
                    lexArr.get(ln).pushLexeme(next); // push lexemes into lines
                    if (next.getToken().equals("pushi") || next.getToken().equals("pushr")) {
                        pushc++;
                    }
                    else if (next.getToken().equals("popr")) {
                        popc++;
                    }
                }
            }
            try {
                cline = src.readLine();
                ln++;
            }
            catch (Exception e) {
                e.printStackTrace();
            }
        }
        
        // clean up the empty lines
        int bound = lexArr.size();
        for (int i = 0; i < bound; i++) {
            if (lexArr.get(i).getLArrayRef().size() == 0) { 
                lexArr.remove(i);
                i--; // smashing houses error incoming
                bound = lexArr.size(); // change how long we're looping for so that we don't go off the edge
            }
        }
        
        // we already have all of the source packed into lexed lines at this point, so 
        // close the reader
        try {
            src.close();
        }
        
        catch (IOException e) {
            e.printStackTrace();
        }
        
        if (pushc != popc) {
            reportError("Push and pop counts did not appear to be equal, check for imbalances (" + pushc + " push vs " + popc + " pop");
            nonCriticalFailure = true;
        }
    }
    
    private boolean is2regop(String token) {
        return (token.equals("add")   || token.equals("sub")   || token.equals("and")   || token.equals("ior")   || 
                token.equals("xor")   || token.equals("lsftl") || token.equals("asftr") || token.equals("lsftr") || 
                token.equals("multl") || token.equals("multh") || token.equals("move")  || token.equals("sklt")  || 
                token.equals("skgt")  || token.equals("skle")  || token.equals("skge")  || token.equals("skeq")  || 
                token.equals("skne"));
    }
    
    private boolean is1regop(String token) {
        return (token.equals("inc")   || token.equals("dec")  || token.equals("neg")    || token.equals("com")    || 
                token.equals("callr") || token.equals("jmpr") || token.equals("movrsp") || token.equals("movspr") || 
                token.equals("pushr") || token.equals("popr") || token.equals("skz")    || token.equals("sknz")   || 
                token.equals("skmi")  || token.equals("skpl"));
    }
    
    private boolean is0regop(String token) {
        return (token.equals("halt") || token.equals("reset") || token.equals("retn") || token.equals("clr"));
    }
    
    private boolean isRegId(String token) {
        String ts = token.substring(1);
        if ("0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15".contains(ts)) { // test for valid register naming
            int nid = Integer.parseInt(ts);
            return (token.charAt(0) == 'r' && nid >= 0 && nid < 16);
        }
        else
            return false;
    }
    
    private boolean isNumId(lexeme l) {
        // note the different type, as this is too complex to use only token content
        return (l.getType() == lexType.numLiteral) || (l.getType() == lexType.identifier);
    }
    
    private boolean is2RegSkip(String token) {
    	return (token.equals("sklt") || token.equals("skgt") ||
    			token.equals("skeq") || token.equals("skne") ||
    			token.equals("skle") || token.equals("skge"));
    }
    
    private int getNumericVal(lexeme l) {
    	// converts lexeme l into correct int values - signedness is either unary negation or not at all!
    	int val = Integer.parseInt(l.getToken(), l.getRadix());
    	if (l.getNegate()) val *= -1;
    	return val;
    }
    
    private int resolveNumLit(lexeme l) {
        // return out of range sentinel MAX_VALUE if numlit is unresolved
        if (symbolTable.containsKey(l.getToken()))  return symbolTable.get(l.getToken());
        else if (l.getType() == lexType.numLiteral) return getNumericVal(l);
        else                                        return Integer.MAX_VALUE;
    } 
    
    private boolean canFit(int c, int n, boolean signed) {
        int lb = -(1 << (n-1));
        int hb =  (1 << (n-1)) - 1;
        
        if (!signed) { lb = 0; hb = (hb << 1) + 1; }
        
        return (c >= lb && c <= hb);
    }
    
    private void putSafe(String c, int v, line l) {
        if (symbolTable.containsKey(c) && !(symbolTable.get(c) == v)) {
            reportError("attempted reuse of label \"" + c + "\" to different value (" + symbolTable.get(c) + " vs " + v + ")", l);
            criticalFailure = true;
        }
        else {
            symbolTable.put(c, v);
        }
    }
    
    // do a line at a time, adding its outer index to the touched array if it involved references which could not be resolved
    // when resolvable labels or .eq statements are found, update the symbol table
    private int doPass(int lastTouchedCount) {
        int data_ptr = 0;
        int code_ptr = 0;
        boolean code_space = true;
        boolean malformed = false;
        int touchedCount = 0;
        int numberConsumed = 0;
        ArrayList<String> unresolvedTokens = new ArrayList<String>();
        
        for (Object _l : lexArr.toArray()) {
            line l = (line)_l; // the underlying class is known to be line, so no danger here
            if (!l.getFinished()) {
                int cl = 0;
                l.setPtrDelta(0);
                boolean outstandingLexemes = true;
                // figure out which lexical rules are being followed here
                if (l.getLexeme(0).getType() == lexType.label) {
                    // update symbol table with label literal
                    putSafe(l.getLexeme(0).getToken(), code_space?code_ptr:data_ptr, l);
                    cl++;
                    numberConsumed = cl;
                    if (l.getLArrayRef().size() == 1) {
                        l.finish();
                        outstandingLexemes = false;
                        // no pointer count manipulation because there is no code on this line
                    }
                }
                
                if (outstandingLexemes) {
                
                    String c0token = l.getLexeme(cl).getToken();
                    String c1token = l.getLexeme(cl + 1).getToken();
                    String c2token = l.getLexeme(cl + 2).getToken();
                    String c3token = l.getLexeme(cl + 3).getToken();
                    String c4token = l.getLexeme(cl + 4).getToken();
                    String c5token = l.getLexeme(cl + 5).getToken();
                    int num_id_val = 0;
                    
                    if ((c0token.equals("sto") || c0token.equals("ldo")) &&
                         isRegId(c1token)                                &&
                         c2token.equals(",")                             &&
                         c3token.equals("(")                             &&
                         isRegId(c4token)                                &&
                         c5token.equals(")")                             &&
                         isNumId(l.getLexeme(cl+6))) {
                        
                        // getting here means the we've satisfied the grammatical constrains
                        // to be a sto/ldo expression. But we might not be able to assemble
                        // yet due to the symbol table being incomplete on this pass
                        
                        num_id_val = resolveNumLit(l.getLexeme(cl+6));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+6).getToken());
                        }
                        
                        else {
                            if (!canFit(num_id_val, 6, true)) { reportError("value too big for available bits", l); nonCriticalFailure = true; }
                            // symbol table has a value for the num-id or it's a literal, we can assemble
                            l.growAContent(c0token             + " " + 
                                          num_id_val           + " " +
                                          c1token.substring(1) + " " +
                                          c4token.substring(1));
                            l.finish();
                            l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(1);
                        
                        numberConsumed = cl + 7; // optional label plus seven required lexemes
                    }
                    else if ((c0token.equals("jmpt") || c0token.equals("callt")) &&
                    	      isNumId(l.getLexeme(cl+1))) {
                        
                    	num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++; 
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                    	
                        else {
                    	    int jump = num_id_val - (code_space?code_ptr:data_ptr) - 1;
                            if (canFit(jump, 12, true)) {
                                l.growAContent((c0token.equals("jmpt")?"jmpi ":"calli ") + jump);
                                l.finish();
                                l.setPC(code_space?code_ptr:data_ptr);
                            }
                            else {
                                reportError("illegally far jump", l);
                                criticalFailure = true; // illegally far calculated jumps are critical b/c clipping won't work here
                            }
                        }
                        l.setPtrDelta(1);
                        
                        numberConsumed = cl + 2;
                    }
                    
                    else if (c0token.equals("consthh")   &&
                    	      isNumId(l.getLexeme(cl+1)) &&
                    	      c2token.equals(",")        &&
                    	      isRegId(c3token)) {
                        num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                        
                        else {
				    		num_id_val >>= 8;
				    		if (num_id_val > 127) num_id_val -= 256;
				    		
				    		l.growAContent("consth " + num_id_val + " " + c3token.substring(1));
				    		l.finish();
				    		l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(1);
                        
                        numberConsumed = cl + 4;
                    }
                    
                    else if (c0token.equals("const16")   &&
                    	      isNumId(l.getLexeme(cl+1)) &&
                    	      c2token.equals(",")        &&
                    	      isRegId(c3token)) {
                        num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                        
                        else {
                            int low8 = num_id_val & 0x00ff;
                            int high8 = (num_id_val & 0xff00) >> 8;
                            if (low8 > 127) low8 -= 256;
                            if (high8 > 127) high8 -= 256;
                                
                            l.growAContent("constl " + low8  + " " + c3token.substring(1));
                            l.growAContent("consth " + high8 + " " + c3token.substring(1));
                            l.finish();
                            l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(2);
                        
                        numberConsumed = cl + 4;
                    }
                    
                    else if ((c0token.equals("calli") || c0token.equals("jmpi")) &&
                              isNumId(l.getLexeme(cl+1))) {
                         
                        num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                        else {
                            if (!canFit(num_id_val, 12, true)) {
                                reportError("value too big for available bits", l);
                                nonCriticalFailure = true;
                            }
                            
                            l.growAContent(c0token + " " + num_id_val);
                            l.finish();
                            l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(1);
                        
                        numberConsumed = cl + 2;
                    }
                    
                    else if (c0token.equals("pushi") && isNumId(l.getLexeme(cl+1))) {
                        num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                        else {
                            if (!canFit(num_id_val, 13, true)) {
                                reportError("value too big for available bits", l);
                                nonCriticalFailure = true;
                            }
                            
                            l.growAContent(c0token + " " + num_id_val);
                            l.finish();
                            l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(1);
                        
                        numberConsumed = cl + 2;
                    }
                    
                    else if ((c0token.equals(".code") || c0token.equals(".data")) &&
                              isNumId(l.getLexeme(cl+1))) {
                        
                        // we may not have a symbol table entry yet
                        // even though we definitely are a valid expression
                        
                        num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                        
                        else {
                            // symbol table has a value, let's go
                            code_space = c0token.equals(".code");
                            
                            if (canFit(num_id_val, 16, false)) {
                                if (code_space) {
                                    code_ptr = num_id_val;
                                }
                                else {
                                    data_ptr = num_id_val;
                                }
                                
                                l.growAContent(c0token + " " + num_id_val);
                                // l.finish();
                                // NOTE: code/data directives are never finished because
                                // they need to be processed on future passes in order to have correct pointers
                                // and since "finished" means "don't assemble this again"
                                // we would totally miss them. We don't actually run into any issues finishing passes
                                // because it's the touched count that determines completion
                                // of assembly. Also, they do not have a pointer count because they
                                // do not contain real information being stored
                            }
                                
                            else {
                                reportError("cannot move to illegal address", l);
                                criticalFailure = true;
                            }
                        }
                        // no set here, already defaults to 0
                        
                        numberConsumed = cl + 2;
                    }
                    
                    else if ((c0token.equals("constl") || c0token.equals("consth") || c0token.equals("sys")) &&
                              isNumId(l.getLexeme(cl+1))                                                     &&
                              c2token.equals(",")                                                            &&
                              isRegId(c3token)) {
                        
                        // we may not have a symbol table entry yet
                        // even though we have a valid const/sys expression
                        
                        num_id_val = resolveNumLit(l.getLexeme(cl+1));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                        }
                        
                        else {
                            if (!canFit(num_id_val, 8, true)) { reportError("value " + num_id_val + " too big for available bits", l); nonCriticalFailure = true; }
                            if (!canFit(num_id_val, 4, false) && c0token.equals("sys")) { reportError("value too big for available bits", l); nonCriticalFailure = true; }
                            
                            // symbol table has value, assemble
                            l.growAContent(c0token    + " " +
                                          num_id_val + " " +
                            		      c3token.substring(1));
                            l.finish();
                            l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(1);
                        
                        numberConsumed = cl + 4;
                    }
                    
                    else if (is2RegSkip(c0token) &&
                    		 isRegId(c1token)    &&
                    		 c2token.equals(",") &&
                    		 isRegId(c3token)) {
                    	// no symbol table check, same as 2reg just reversed.
                    	l.growAContent(c0token + " " +
                                      c1token.substring(1) + " " +
                                      c3token.substring(1));
                    	l.setPtrDelta(1);
                        l.finish();
                        l.setPC(code_space?code_ptr:data_ptr);
                    
                        numberConsumed = cl + 4;
                    }
                    
                    else if (is2regop(c0token)   &&
                             isRegId(c1token)    &&
                             c2token.equals(",") &&
                             isRegId(c3token)) {
                        
                        // no need for a symbol table check here since reg-ids must be literals
                        l.growAContent(c0token + " " +
                                      c3token.substring(1) + " " +
                                      c1token.substring(1));
                        l.setPtrDelta(1);
                        l.finish();
                        l.setPC(code_space?code_ptr:data_ptr);
                        
                        numberConsumed = cl + 4;
                    }
                    
                    else if (is1regop(c0token) &&
                             isRegId(c1token)) {
                        
                        // no need for a symbol table check
                        l.growAContent(c0token + " " +
                                      c1token.substring(1));
                        l.setPtrDelta(1);
                        l.finish();
                        l.setPC(code_space?code_ptr:data_ptr);
                        
                        numberConsumed = cl + 2;
                    }
                    
                    else if (is0regop(c0token)) {
                             l.growAContent(c0token);
                             l.setPtrDelta(1);
                             l.finish();
                             l.setPC(code_space?code_ptr:data_ptr);
                             
                             numberConsumed = cl + 1;
                    }
                    
                    else if (c0token.equals(".ds") &&
                             l.getLexeme(cl+1).getType() == lexType.stringLiteral) {
                        // direct store a string literal, which is actually just a ton of chars,
                        // into whatever the current active space is
                        String ac = ".ds ";
                        int cc = 0;
                        for (char c : c1token.toCharArray()) {
                            ac += (int)c + " "; 
                            cc++;
                            
                            // HUGE NOTE: this is only pushing 8 bits of information into 16 bit locations!
                            // This is so that the actually ascii values of characters are read out of memory,
                            // instead of some weird packing-like scheme with the high and low 8 bits.
                            // Despite this, the pointer must always move ahead by one full location
                            // because we didn't ignore the high 8 bits, we filled them with 0s. Yes, 0s,
                            // we did not sign extend because these values always come out positive
                        }
                        
                        l.growAContent(ac);
                        l.setPtrDelta(cc);
                        l.finish();
                        l.setPC(code_space?code_ptr:data_ptr);
                        
                        numberConsumed = cl + 2;
                    }
                    
                    
                    else if ((c0token.equals(".dw") || c0token.equals(".dwu")) && 
                             isNumId(l.getLexeme(cl+1))) {
                        
                        boolean resolved = true; // we have to have at least one useful token on this line
                        int stored = 0;
                        String ac = ".ds ";
                        
                        // handle first num-id a bit differently
                        cl++; // to get to num-id
                        num_id_val = resolveNumLit(l.getLexeme(cl));
                        if (num_id_val == Integer.MAX_VALUE) { touchedCount++; resolved = false; unresolvedTokens.add(l.getLexeme(cl).getToken()); }
                        else                                 { ac += num_id_val + " "; }
                        stored++;
                        cl++; // to get to comma, if the special treatment of the first lexeme is confusing
                              // see a1_spec explaining the grammatical descriptions underlying the structure  
                        
                        for (; cl < l.getLArrayRef().size(); cl+= 2) {
                        	if (l.getLexeme(cl).getToken().equals(",") &&
                                isNumId(l.getLexeme(cl+1))) {
                                
                                // we have a full additional num-id to add if its in the symbol table
                                
                                num_id_val = resolveNumLit(l.getLexeme(cl+1));
                               
                                if (num_id_val == Integer.MAX_VALUE) {
                                    touchedCount++;
                                    resolved = false;
                                    unresolvedTokens.add(l.getLexeme(cl+1).getToken());
                                }
                                else {
                                	if (!canFit(num_id_val, 16, c0token.equals(".dw"))) { reportError("value " + num_id_val + " too large for memory storage", l); nonCriticalFailure = true; }
                                    ac += num_id_val + " ";
                                }
                                stored++;
                            }
                        }
                            
                        if (resolved) {
                            // if we exited the loop without finding unresolved num-ids, store the AContent 
                            l.growAContent(ac);
                            l.finish();
                            l.setPC(code_space?code_ptr:data_ptr);
                        }
                        l.setPtrDelta(stored);
                    
                        numberConsumed = l.getLArrayRef().size(); // there were as many lexemes here as appeared in the line - guaranteed to pass the check at the end of the line
                    }
                    
                    else if (l.getLexeme(cl).getType() == lexType.identifier &&
                             c1token.equals(".eq")                          &&
                             isNumId(l.getLexeme(cl+2))) {
                        
                        // we have a new entry into the symbol table, unless it is unresolveable
                        
                        num_id_val = resolveNumLit(l.getLexeme(cl+2));
                        
                        if (num_id_val == Integer.MAX_VALUE) {
                            touchedCount++;
                            unresolvedTokens.add(l.getLexeme(cl+2).getToken());
                        }
                        
                        else {
                            // this can put a negative number into the symbol table
                            putSafe(l.getLexeme(0).getToken(), num_id_val, l);
                            l.finish();
                            // .eq statements do not influence the pointers
                        }
                        
                        numberConsumed = 3;
                    }
                    
                    else {
                        if (numberConsumed != l.getLArrayRef().size()) {
                        	// if there are unconsumed lexemes and we failed to meet any other rule 
                        	// (meaning we won't double-report the additional content error) then
                        	// this line must be malformed
                    	    reportError("malformed expression, could not be interpreted", l);
                    	    nonCriticalFailure = true;
                    	    malformed = true;
                        }
                    }
                    
                    // issue errors for "undeclared comments"
                    if (numberConsumed != l.getLArrayRef().size() && !malformed) {
                        reportError("additional content after full expression", l);
                        nonCriticalFailure = true;
                    }
                }
            }
            
            // handle pointer manipulation
            if (code_space) code_ptr += l.getPtrDelta(); 
            else            data_ptr += l.getPtrDelta();
        }
        
        // issue errors for unresolveable forward references
        if (touchedCount == lastTouchedCount) {
            reportError("unresolveable forward references");
            err.print("Unresolved tokens were: ");
            for (String t : unresolvedTokens) {
                 err.print(t + " ");
            }
            err.println();
            criticalFailure = true;
        }
        
        return touchedCount;
    }
    
    public void asm() {
        int t = -1;
        
        while (!criticalFailure && t != 0) {
            t = doPass(t);
        }
        
        if (!criticalFailure) {
            // since the touched count should have hit 0 by now and all the assembled forms are present,
            // we can pass things along to the a0 assembler
            // use the code/data file arguments from the top + convert the contents of the line arr
            // into a string array for the lower level a0 process
            ArrayList<String> a0_arrl = new ArrayList<String>(lexArr.size());
            int i = 0;
            for (Object o : lexArr.toArray()) {
                // The underlying type is known, no danger in typecasting
                ArrayList<String> val = ((line)o).getAContent();
                if (((line)o).getPC() != -1) {
                    log.printf("%x: %s%n", ((line)o).getPC(), ((line)o).getOContent());
                }
                else {
                    log.printf("      %s%n", ((line)o).getOContent());
                }
                for (int j = 0; j < val.size(); j++) {
                    a0_arrl.add(val.get(j));
                }
            }
            
            String[] a0_arr = new String[a0_arrl.size()]; 
            a0_arr = a0_arrl.toArray(a0_arr);
            
            for (String s: a0_arr) {
                log.printf("%s%n", s);
            }
            
            a0.asm_arr(a0_arr); // fill in the internals of a0 with its assembly of the code
        }
        else {
            System.out.println("Critical failure(s) issued during assembly, please check the .err file.");
        }
        
        if (nonCriticalFailure) {
            System.out.println("Non-critical failure(s) issued during assembly, please check the .err file.");
        }
    }
    
    public void writeBack() throws IOException {
        a0.writeBack(codeOut, dataOut, err); // write back the values
        
        // clean up
        codeOut.close();
        dataOut.close();
        err.close();
        log.close();
    }
    
    public void dumpST() {
        log.printf("%s%n", symbolTable.toString().replaceAll(", ", "\n"));
    }
    
    public static void main(String[] args) throws IOException {
        a1_asm a1 = new a1_asm(new BufferedReader(new FileReader(args[0])), 
                               new PrintWriter   (new FileWriter(args[1])),
                               new PrintWriter   (new FileWriter(args[2])),
                               new PrintWriter   (new FileWriter(args[3])),
                               new PrintWriter   (new FileWriter(args[4])));
        a1.asm();
        a1.dumpST();
        a1.writeBack();
        
    }
}
