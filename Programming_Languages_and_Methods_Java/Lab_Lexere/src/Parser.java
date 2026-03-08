import java.util.*;

class Parser {
    private Lexer lexer;
    private Token current;
    private List<String> rules = new ArrayList<>();

    public Parser(Lexer lexer) {
        this.lexer = lexer;
        current = lexer.nextToken();
    }

    private void error() {
        throw new RuntimeException("Syntax error at " + current.line + ":" + current.column);
    }

    private void match(TokenType expected) {
        if (current.type == expected) {
            current = lexer.nextToken();
        } else {
            error();
        }
    }

    public List<String> parse() {
        parseStmt();
        match(TokenType.EOF);
        return rules;
    }

    private void parseStmt() {
        if (current.type == TokenType.IF) {
            rules.add("Stmt -> if ( IDENT ) Stmt");
            match(TokenType.IF);
            match(TokenType.LPAREN);
            match(TokenType.IDENT);
            match(TokenType.RPAREN);
            parseStmt();
        } else if (current.type == TokenType.IDENT) {
            rules.add("Stmt -> IDENT = NUMBER ;");
            match(TokenType.IDENT);
            match(TokenType.EQ);
            match(TokenType.NUMBER);
            match(TokenType.SEMICOLON);
        } else if (current.type == TokenType.LBRACE) {
            rules.add("Stmt -> { Seq }");
            match(TokenType.LBRACE);
            parseSeq();
            match(TokenType.RBRACE);
        } else {
            error();
        }
    }

    private void parseSeq() {
        if (current.type == TokenType.RBRACE) {
            rules.add("Seq -> ε");
            return;
        }
        rules.add("Seq -> Stmt Seq");
        parseStmt();
        parseSeq();
    }
}