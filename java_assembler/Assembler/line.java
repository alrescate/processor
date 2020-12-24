package Assembler;

import java.util.ArrayList;
import Assembler.lexeme;

public class line {
    private boolean           finished;
    private String            oContent;
    private ArrayList<String> aContent;
    private int               ptr_delta;
    private int               oLine;
    private int               pc;
    private ArrayList<lexeme> lexemes;
    
    public line(String _oc, int _ol, ArrayList<lexeme> _l) {
        // this class makes the assumption that the line has already been lexed,
        // but that it has not already been assembled. It also assumes that it
        // cannot be initialized into the finished state.
        finished = false;
        oContent = _oc;
        aContent = new ArrayList<String>();
        ptr_delta = 0;
        oLine = _ol;
        pc = -1;
        lexemes = _l;
    }
    
    public boolean getFinished() { return finished;  }
    public void    finish()      { finished = true;  }
    public void    clear()       { finished = false; }
    
    public String getOContent()           { return oContent; }
    public void   setOContent(String _oc) { oContent = _oc;  }
    
    public ArrayList<String> getAContent() { return aContent; }
    public void   growAContent(String _ac) { aContent.add(_ac);  }
    
    public int  getPtrDelta()      { return ptr_delta; }
    public void setPtrDelta(int n) { ptr_delta = n;    }
    
    public int  getOLine()         { return oLine; }
    public void setOLine(int _ol)  { oLine = _ol;  }
    
    public int getPC()         { return pc; }
    public void setPC(int _pc) { pc = _pc;  }
    
    public lexeme            getLexeme(int pos)                 { if (pos < lexemes.size()) return lexemes.get(pos); else return new lexeme(lexType.whitespace, "", 0, 0); }
    public ArrayList<lexeme> getLArrayRef()                     { return lexemes; }
    public void              setLexeme(int pos, lexeme l)       { lexemes.set(pos, l); }
    public void              pushLexeme(lexeme l)               { lexemes.add(l); }
    public void              setLArrayRef(ArrayList<lexeme> lr) { lexemes = lr; }
    
    public String toString() {
        String ret = "";
        ret += "Original content: \"" + oContent + "\"\n";
        ret += "Original line: " + oLine + "\n";
        ret += "Pointer count: " + pc + "\n";
        ret += "Finished: " + finished + "\n";
        ret += "Assembled content (if any): \"";
        for (int s = 0; s < aContent.size(); s++)
        	ret += aContent.get(s) + ((s==aContent.size()-1)?"":"\n");
        ret += "\"\n";
        ret += "Lexemes: \n";
        for (Object l : lexemes.toArray()) {
            // EXPLANATION:
            //   Though the toArray function demotes all of the types to Object,
            //   java will use a runtime type for the underlying method calls, even if 
            //   the reference does not tell it that such classes actually underlie
            //   the function. This is marginally cheaper than the templatized function
            //   which will ultimately do the same thing (because no arguments go
            //   onto the stack in this version).
            ret += l + "\n";
        }
        
        return ret;
    }
}