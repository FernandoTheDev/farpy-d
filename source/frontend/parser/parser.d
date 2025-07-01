module frontend.parser.parser;

import std.stdio;
import std.conv;
import std.variant;
import frontend.lexer.token;
import frontend.values;
import frontend.parser.ast;

enum Precedence
{
    LOWEST = 1,
    ASSIGN = 2, // =
    TERNARY = 3, // ? :
    OR = 4, // ||
    AND = 5, // &&
    EQUALS = 6, // == !=
    COMPARISON = 7, // < > <= >=
    SUM = 8, // + -
    PRODUCT = 9, // * / %
    EXPONENT = 10, // **
    PREFIX = 11, // -x !x
    CALL = 12, // myFunction(x)
}

class Parser
{
private:
    Token[] tokens;
    size_t pos = 0;

    Stmt parsePrefix()
    {
        Token token = this.advance();

        switch (token.kind)
        {
        case TokenType.INT:
            return new IntLiteral(to!ulong(token.value.get!string), token.loc);
            break;
        default:
            throw new Exception("No prefix parse function for " ~ to!string(token));
        }
    }

    Stmt parseBinaryInfix(Stmt left)
    {
        this.advance();
        Token operatorToken = this.previous();

        Precedence precedence = this.getPrecedence(operatorToken.kind);
        Stmt right = this.parseExpression(precedence);
        FTypeInfo type = this.inferType(left, right);

        BinaryExpr node = new BinaryExpr(left, right, operatorToken.value.get!string);
        node.type = type;
        node.loc = this.makeLoc(left.loc, right.loc);
        return node;
    }

    void infix(ref Stmt leftOld)
    {
        switch (this.peek().kind)
        {
        case TokenType.PLUS:
        case TokenType.MINUS:
        case TokenType.SLASH:
        case TokenType.ASTERISK:
        case TokenType.EXPONENTIATION:
        case TokenType.PERCENT:
        case TokenType.REMAINDER:
        case TokenType.EQUALS_EQUALS:
        case TokenType.NOT_EQUALS:
        case TokenType.GREATER_THAN:
        case TokenType.LESS_THAN:
        case TokenType.GREATER_THAN_OR_EQUALS:
        case TokenType.LESS_THAN_OR_EQUALS:
        case TokenType.AND:
        case TokenType.OR:
            leftOld = this.parseBinaryInfix(leftOld);
            return;
        case TokenType.QUESTION: // TODO: left = this.parseTernaryInfix(left);
            return;
        default:
            return;
        }
    }

    Stmt parseExpression(Precedence precedence)
    {
        Stmt left = this.parsePrefix();

        while (!this.isAtEnd() && precedence < this.peekPrecedence())
        {
            this.infix(left);
        }

        return left;
    }

    Stmt parseStmt()
    {
        Stmt stmt = this.parseExpression(Precedence.LOWEST);
        this.match([TokenType.SEMICOLON]);
        return stmt;
    }

public:
    this(Token[] tokens = [])
    {
        this.tokens = tokens;
    }

    Program parse()
    {
        Program program = new Program([]);
        program.type = createTypeInfo(TypesNative.NULL);
        program.value = null;

        try
        {
            while (!this.isAtEnd())
            {
                program.body ~= this.parseStmt();
            }

            if (this.tokens.length == 0)
            {
                return program;
            }

            program.loc = this.makeLoc(this.tokens[0].loc, this
                    .tokens[$ - 1].loc);
        }
        catch (Exception e)
        {

            writeln("Erro:", e.msg);
            throw e;
        }

        return program;
    }

    // Helpers
private:
    bool isAtEnd()
    {
        return this.peek().kind == TokenType.EOF;
    }

    Variant next()
    {
        if (this.isAtEnd())
            return Variant(false);
        return Variant(this.tokens[this.pos + 1]);
    }

    Token peek()
    {
        return this.tokens[this.pos];
    }

    Token previous(size_t i = 1)
    {
        return this.tokens[this.pos - i];
    }

    Token advance()
    {
        if (!this.isAtEnd())
            this.pos++;
        return this.previous();
    }

    bool match(TokenType[] kinds)
    {
        foreach (kind; kinds)
        {
            if (this.check(kind))
            {
                this.advance();
                return true;
            }
        }
        return false;
    }

    bool check(TokenType kind)
    {
        if (this.isAtEnd())
            return false;
        return this.peek().kind == kind;
    }

    Token consume(TokenType expected, string message)
    {
        if (this.check(expected))
            return this.advance();
        const token = this.peek();
        throw new Error(`Erro de parsing: ${message}`);
    }

    Precedence getPrecedence(TokenType kind)
    {
        switch (kind)
        {
        case TokenType.EQUALS:
            return Precedence.ASSIGN;
        case TokenType.QUESTION:
            return Precedence.TERNARY;
        case TokenType.OR:
            return Precedence.OR;
        case TokenType.AND:
            return Precedence.AND;
        case TokenType.EQUALS_EQUALS:
        case TokenType.NOT_EQUALS:
            return Precedence.EQUALS;
        case TokenType.LESS_THAN:
        case TokenType.GREATER_THAN:
        case TokenType.LESS_THAN_OR_EQUALS:
        case TokenType.GREATER_THAN_OR_EQUALS:
            return Precedence.COMPARISON;
        case TokenType.PLUS:
        case TokenType.MINUS:
            return Precedence.SUM;
        case TokenType.SLASH:
        case TokenType.ASTERISK:
        case TokenType.PERCENT:
        case TokenType.REMAINDER:
            return Precedence.PRODUCT;
        case TokenType.EXPONENTIATION:
            return Precedence.EXPONENT;
        case TokenType.LPAREN:
            return Precedence.CALL;
        default:
            return Precedence.LOWEST;
        }
    }

    Precedence peekPrecedence()
    {
        return this.getPrecedence(this.peek().kind);
    }

    FTypeInfo inferType(Stmt left, Stmt right)
    {
        if (left.type.baseType == "string" || right.type.baseType == "string")
        {
            return createTypeInfo(TypesNative.STRING);
        }

        if (left.type.baseType == "float" || right.type.baseType == "float")
        {
            return createTypeInfo(TypesNative.FLOAT);
        }
        return createTypeInfo(TypesNative.INT);
    }

    Loc makeLoc(ref Loc start, ref Loc end)
    {
        return Loc(start.file, start.line, start.line_raw, start.start, end.end, start.dir);
    }
}
