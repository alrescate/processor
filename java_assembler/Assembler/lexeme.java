package Assembler;
// import Assembler.lt.lexType;
public class lexeme {
    
    private lexType t;
    private String c;
    private int homeLine;
    private int startChar;
    private int radix;
    private boolean negate;
    
    public lexeme(lexType _t, String _c, int hl, int sc) {
        t = _t;
        c = _c;
        homeLine = hl;
        startChar = sc;
        negate = false;
        radix = 10;
    }
    
    public void changeType(lexType n) {
        t = n;
    }
    
    public void pushChar(char n) {
        c += n;
    }
    
    public void setNegate(boolean v) {
    	negate = v;
    }
    
    public boolean getNegate() {
    	return negate;
    }
    
    public void setRadix(int n) {
    	radix = n;
    }
    
    public int getRadix() {
    	return radix;
    }
    
    public void popChar() {
        c = c.substring(0, c.length()-1);
    }
    
    public void pushStr(String n) {
        c = c.concat(n);
    }

    public lexType getType() {
        return t;
    }
    
    public String getToken() {
        return c;
    }
    
    public void setToken(String _c) {
        c = _c;
    }
    
    public int getHomeLine() {
        return homeLine;
    }
    
    public int getStartChar() {
        return startChar;
    }
    
    public void setHomeLine(int hl) {
        homeLine = hl;
    }
    
    public void setStartChar(int sc) {
        startChar = sc;
    }
    
    public String toString() {
        return "[\"" + c + "\", " + t + "] ";
    }
}