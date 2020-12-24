package Assembler;
import Assembler.lexeme;
import Assembler.lexType;
import java.io.*;
/* 
    A numeric literal will always begin with a digit 0-9 or -, and may have a radix (0x, 0b)
    A string literal will always begin/end with ""
    A label will have a final character of : and will be over when that char is found
    An identifier starts with a letter or ., continues with letter/underscore/digit
    Punctuation is () and ,
    Eol is a \n or \r, it means we're done
    Whitespace is a space/tab/formfeed
    Comments MUST begin with ; and end with an eol (which the a1_asm will helpfully insert to enlighten you savages)
*/

/* TO DO:
 *  - Redesign both this and the a1 assembler to handle numeric literals
 *    which may have signs and various raidicies. Current theory: remove
 *    sign handling at the lexer step, let signedness be a grammatical construct
 * */ 

public class lex {
    public enum State {
        idle,
        numLiteral,   
        stringLiteral,
        identifier,   
        whitespace,
        comment       
    }
    private State curState;
    private String line;
    private int cpos;
    private PrintWriter err;
    private boolean errThrown;
    private int lineNumber;
    
    public lex(String _line, PrintWriter err, int lnumber) {
        // System.out.println("We are in the constructor with arg reading: " + _line);
        curState = State.idle; 
        cpos = 0;
        line = _line;
        // System.out.println("Line now reads: " + line);
        char tchar = getChar(line.length()-1);
        if (tchar != '\n' && tchar != '\r') {
            line+='\n'; // try to clean up lines passed without a newline
            // System.out.println("Pushed newline onto end of line");
        }
        this.err = err;
        errThrown = false;
        lineNumber = lnumber;
    }
    
    private char getChar(int n) {
        // returns character n ahead of current position
        // System.out.println("Made a getChar request with n = " + n + " cpos = " + cpos + " and line.length = " + line.length());
        int epos = cpos + n;
        char r = (char)255;
        if (epos < line.length() && epos >= 0) r = line.charAt(cpos + n);
        // System.out.println("Answered last query with ordinal " + (int)r);
        return r;
    }
    
    private boolean isEOL(char n) {
        return (n == '\n' || n == '\r');
    }
    
    private boolean isQuote(char n) {
        return (n == '"');
    }
    
    private boolean isWhitespace(char n) {
        return (n == ' ' || n == '\t');
    }
    
    private boolean isPunctuation(char n) {
        return (n == ',' || n == '(' || n == ')');
    }
    
    private boolean isBase16(char n) {
        return ((n >= '0' && n <= '9') || (n >= 'a' && n <= 'f') || (n >= 'A' && n <= 'F'));
    }
    
    private boolean isBase10(char n) {
        return (n >= '0' && n <= '9');
    }
    
    private boolean isBase8(char n) {
        return (n >= '0' && n <= '7');
    }
    
    private boolean isBase2(char n) {
        return (n == '0' || n == '1');
    }
    
    private boolean validNumTerminator(char n) {
        return (isPunctuation(n) || isWhitespace(n) || isEOL(n) || n == ';');
    }
    
    private boolean canStartIdentifier(char n) {
        return (n >= 'A' && n <= 'Z' ||
                n >= 'a' && n <= 'z' ||
                n == '_' || n == '.');
    }
    
    private boolean isIdentifier(char n) {
        return ((n >= '0' && n <= '9') || 
                (n >= 'A' && n <= 'Z') ||
                (n >= 'a' && n <= 'z') ||
                 n == '_');
    }
    
    private void throwError(int errCol, String errDesc, char errChar, String errMsg) {
        this.err.printf("Error issued from %d:%d, %s at char '%s', %s%n", lineNumber, errCol, errDesc, errChar, errMsg);
        errThrown = true;
    }
    
    private boolean wasError() {
        return errThrown;
    }
    
    public lexeme getNextToken() {
        errThrown = false;
        curState = State.idle;
        lexeme l = new lexeme(lexType.whitespace, "", lineNumber, cpos); 
        char c0 = getChar(0);
        char c1 = getChar(1);
        char c2 = getChar(2);
        boolean negate = false;
        int radix = 10;
        char p;
        switch(c0) {
            case('-'): // decoding a number that begins with a negative
                // System.out.println("We entered the negative case");
                l.setNegate(true);
                // play with fire, shift character content back to avoid reusing code for digit lexing
                c0 = c1;
                c1 = c2;
                cpos++; // so that we're on the first digit
            case('0'): case('1'): 
            case('2'): case('3'): 
            case('4'): case('5'): 
            case('6'): case('7'): 
            case('8'): case('9'): 
                // System.out.println("We entered a numeric case");
                // decode the digits
                if (c0 == '0') {
                    // System.out.println("We entered the 0 case");
                    // determine radix
                    if (c1  == 'x') {
                        // hex
                        // System.out.println("We entered the hex case");
                        l.setRadix(16);
                        cpos += 2; // first digit of actual number
                        l.changeType(lexType.numLiteral);
                        p = getChar(0);
                        do {
                            l.pushChar(p); 
                            cpos++; 
                            p = getChar(0);
                        } while (isBase16(p)); 
                        if (!validNumTerminator(p)) {
                            // throw illegal hexadecimal termination err
                            throwError(cpos, "Illegal hex literal character", p, "hex literal cannot be continued or terminated by that character");
                        }
                    }
                    else if (c1 == 'b') {
                        // binary
                        // System.out.println("We entered the binary case");
                        l.setRadix(2);
                        cpos += 2; // first digit of actual number
                        l.changeType(lexType.numLiteral);
                        p = getChar(0);
                        do {
                            l.pushChar(p); 
                            cpos++; 
                            p = getChar(0);
                        } while (isBase2(p)); 
                        if (!validNumTerminator(p)) {
                            // throw illegal binary termination err
                            throwError(cpos, "Illegal binary literal character", p, "binary literal cannot be continued or terminated by that character");
                        }
                    }
                    else {
                    	// octal
                        // System.out.println("We entered the octal case");
                        l.setRadix(8);
                        // DO NOT step ahead, as a single 0 will cause illegal forward consumption
                        l.changeType(lexType.numLiteral);
                        p = getChar(0);
                        do {
                            l.pushChar(p); 
                            cpos++; 
                            p = getChar(0);
                        } while (isBase8(p)); 
                        if (!validNumTerminator(p)) {
                            // throw illegal octal termination err
                            throwError(cpos, "Illegal octal literal character", p, "octal literal cannot be continued or terminated by that character");
                        }
                        
                        // if a leading 0 followed by additional characters exists, trim it
                        if (l.getToken().length() > 1) l.setToken(l.getToken().substring(1));
                    }
                }
                else {
                    // decimal
                    // System.out.println("We entered the decimal case");
                    // already on first digit of number
                    l.changeType(lexType.numLiteral);
                    p = getChar(0);
                    do {
                        l.pushChar(p); 
                        cpos++; 
                        p = getChar(0);
                    } while (isBase10(p)); 
                    if (!validNumTerminator(p)) {
                            // throw illegal decimal termination err
                            throwError(cpos, "Illegal decimal literal character", p, "decimal literal cannot be continued or terminated by that character");
                    }
                }
                
                // reformat lexeme contents into base 10 - numbers may appear to be negative
                // int v = Integer.parseInt(l.getToken(), radix) & 0xffff;
                // if ((v&0x8000) != 0) v -= (1<<16);
                // l.setToken(negate?Integer.toString(-v):Integer.toString(v));
                // NONE of the above is needed because we'll do it at the asm step
                break;
                
            case('"'): // consume characters until finding an eol or another "
                // System.out.println("We entered the quotes case");
                l.changeType(lexType.stringLiteral);
                cpos++; // always advance past initial quote
                p = getChar(0);
                boolean unterminated = false;
                do {
                    if (isEOL(p)) {
                        // throw illegal string termination err
                        throwError(cpos, "Illegal string literal termination", getChar(-1), "string literal must be terminated before EOL");
                        unterminated = true;
                        break;
                    }
                    l.pushChar(p);
                    cpos++;
                    p = getChar(0);
                } while (!isQuote(p));
                if (!unterminated) cpos++; // advance over last quote only if it was found
                break;
            case(' '): case('\t'): // consume characters until a non-whitespace
                // System.out.println("We entered the whitespace case");
                l.changeType(lexType.whitespace);
                p = getChar(0);
                do {
                    l.pushChar(p); 
                    cpos++; 
                    p = getChar(0);
                } while (isWhitespace(p)); 
                break;
            case('('): case(')'): case (','): // no consuming, just that
                // System.out.println("We entered the punctuation case with char ordinal " + (int)c0);
                l.changeType(lexType.punctuation);
                l.pushChar(c0);
                cpos++;
                break;
            case(';'): // consume until eol
                // System.out.println("We entered the comment case");
                l.changeType(lexType.comment);
                p = getChar(0);
                do {
                    l.pushChar(p);
                    cpos++;
                    p = getChar(0);
                } while (!isEOL(p));
                break;
            case('\n'): case('\r'): // no consuming, we're already done
                // System.out.println("We entered the EOL case");
                l.changeType(lexType.eol);
                break;
            default: // consume until an eol, whitespace, or punctuation
                // System.out.println("We entered the catch-all case with char: " + (int)c0);
                if (canStartIdentifier(c0)) {
                    l.changeType(lexType.identifier);
                    p = getChar(0);
                    do {
                        l.pushChar(p);
                        cpos++;
                        p = getChar(0);
                    } while (isIdentifier(p));
                    
                    if (p == ':') {
                        l.changeType(lexType.label);
                        cpos++;
                    }
                }
                else {
                    throwError(cpos, "Illegal start of identifier", c0, "identifiers must begin with a letter or underscore");
                    cpos++;
                }
                break;
        }
        
        return l;
    }
    
    public void testLexemes(String fn) {
        BufferedReader reader;
        lexeme reset = new lexeme(lexType.whitespace, "You should not see this", 0, 0);
        lexeme next = reset;
        int cLineNumber = 1;
        try {
            reader = new BufferedReader(new FileReader(fn));
            String iline = "sss";
            try { iline = reader.readLine(); } catch (Exception e) { e.printStackTrace(); }
            while (iline != null) {
                lex c = new lex(iline, err, cLineNumber++); // add a \n because readLine ignored it when it produced a string.
                while (next.getType() != lexType.eol) {
                    next = c.getNextToken();
                    // System.out.println("We are running version A");
                    System.out.print(next);
                }
                System.out.println(); System.out.println();
                next = reset;
                try {
                    iline = reader.readLine(); 
                    // System.out.println("iline is: " + iline);
                }
                catch (Exception e) {
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
    
    public static void main(String[] args) {
        PrintWriter e;
        try { 
            e = new PrintWriter(new FileWriter("testLexer.a1e"));
            lex l = new lex("", e, 0);
            l.testLexemes("testLexer.a1");
            e.close();
        }
        catch(Exception ex) {
            ex.printStackTrace();
        }
    }
}