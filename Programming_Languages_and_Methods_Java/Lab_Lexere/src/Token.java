enum TokenType {
    IF, IDENT, NUMBER, LPAREN, RPAREN, LBRACE, RBRACE, EQ, SEMICOLON, EOF
}

class Token {
    TokenType type;
    String value;
    int line;
    int column;

    public Token(TokenType type, String value, int line, int column) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
    }
}