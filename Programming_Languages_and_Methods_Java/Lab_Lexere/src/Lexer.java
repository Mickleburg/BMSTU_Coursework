class Lexer {
    private final String input;
    private int pos = 0;
    private int line = 1;
    private int column = 1;
    private char currentChar;

    public Lexer(String input) {
        this.input = input;
        if (!input.isEmpty()) currentChar = input.charAt(0);
    }

    private void advance() {
        pos++;
        column++;
        if (pos >= input.length()) {
            currentChar = '\0';
        } else {
            currentChar = input.charAt(pos);
            if (currentChar == '\n') {
                line++;
                column = 0;
            }
        }
    }

    public Token nextToken() {
        while (currentChar != '\0') {
            if (Character.isWhitespace(currentChar)) {
                advance();
                continue;
            }

            int startLine = line;
            int startCol = column;

            if (currentChar == 'i') {
                advance();
                if (currentChar == 'f') {
                    advance();
                    return new Token(TokenType.IF, "if", startLine, startCol);
                }
                while (Character.isLetterOrDigit(currentChar)) advance();
                return new Token(TokenType.IDENT, "i", startLine, startCol);
            }

            if (Character.isLetter(currentChar)) {
                StringBuilder sb = new StringBuilder();
                while (Character.isLetterOrDigit(currentChar)) {
                    sb.append(currentChar);
                    advance();
                }
                return new Token(TokenType.IDENT, sb.toString(), startLine, startCol);
            }

            if (Character.isDigit(currentChar)) {
                StringBuilder sb = new StringBuilder();
                while (Character.isDigit(currentChar)) {
                    sb.append(currentChar);
                    advance();
                }
                return new Token(TokenType.NUMBER, sb.toString(), startLine, startCol);
            }

            switch (currentChar) {
                case '(': advance(); return new Token(TokenType.LPAREN, "(", startLine, startCol);
                case ')': advance(); return new Token(TokenType.RPAREN, ")", startLine, startCol);
                case '{': advance(); return new Token(TokenType.LBRACE, "{", startLine, startCol);
                case '}': advance(); return new Token(TokenType.RBRACE, "}", startLine, startCol);
                case '=': advance(); return new Token(TokenType.EQ, "=", startLine, startCol);
                case ';': advance(); return new Token(TokenType.SEMICOLON, ";", startLine, startCol);
                default: throw new RuntimeException("Invalid char: " + currentChar + " at " + line + ":" + column);
            }
        }
        return new Token(TokenType.EOF, "", line, column);
    }
}
