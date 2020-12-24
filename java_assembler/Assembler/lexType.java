package Assembler;
public enum lexType {
    numLiteral,    // base is eliminated after it is parsed
    stringLiteral, // theoretically allows unicode
    label,         // ends in colon
    identifier,    // can be instruction/directive or register
    punctuation,   // commas, parentheses
    eol,           // end of line
    whitespace,    // various items
    comment,       // comments, kept for error reporting reasons
    error          // just so that we can know something went wrong
}
