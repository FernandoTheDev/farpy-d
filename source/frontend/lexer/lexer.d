module frontend.lexer.lexer;

import frontend.lexer.token;

class Lexer
{
private:
    string source;
    string file;
    string dir;

    uint line = 1;
    uint offset = 0;
    uint lineOffset = 0;
    uint start = 1;
    Token[] tokens = [];

    string[] lineCache;

    // Estaticos e imutaveis
    static immutable TokenType[string] SINGLE_CHAR_TOKENS = initSingleCharTokens();
    static immutable TokenType[string] MULTI_CHAR_TOKENS = initMultiCharTokens();
    static immutable bool[char] ALPHA_CHARS = initCharSet(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_");
    static immutable bool[char] DIGIT_CHARS = initCharSet("0123456789");
    static immutable bool[char] HEX_CHARS = initCharSet("0123456789abcdefABCDEF");
    static immutable bool[char] OCTAL_CHARS = initCharSet("01234567");
    static immutable bool[char] BINARY_CHARS = initCharSet("01");
    static immutable bool[char] WHITESPACE_CHARS = initCharSet(" \t\r");

    static TokenType[string] initSingleCharTokens()
    {
        TokenType[string] m;
        m["+"] = TokenType.PLUS;
        m["-"] = TokenType.MINUS;
        m["*"] = TokenType.ASTERISK;
        m["/"] = TokenType.SLASH;
        m[">"] = TokenType.GREATER_THAN;
        m["<"] = TokenType.LESS_THAN;
        m[","] = TokenType.COMMA;
        m[";"] = TokenType.SEMICOLON;
        m[":"] = TokenType.COLON;
        m["("] = TokenType.LPAREN;
        m[")"] = TokenType.RPAREN;
        m["{"] = TokenType.LBRACE;
        m["}"] = TokenType.RBRACE;
        m["."] = TokenType.DOT;
        m["%"] = TokenType.PERCENT;
        m["|"] = TokenType.PIPE;
        m["="] = TokenType.EQUALS;
        m["["] = TokenType.LBRACKET;
        m["]"] = TokenType.RBRACKET;
        m["#"] = TokenType.C_DIRECTIVE;
        m["!"] = TokenType.BANG;
        m["&"] = TokenType.AMPERSAND;
        m["?"] = TokenType.QUESTION;
        return m.idup; // idup faz uma cópia imutável
    }

    static TokenType[string] initMultiCharTokens()
    {
        TokenType[string] m;
        m["++"] = TokenType.INCREMENT;
        m["--"] = TokenType.DECREMENT;
        m["**"] = TokenType.EXPONENTIATION;
        m["%%"] = TokenType.REMAINDER;
        m["=="] = TokenType.EQUALS_EQUALS;
        m[">="] = TokenType.GREATER_THAN_OR_EQUALS;
        m["<="] = TokenType.LESS_THAN_OR_EQUALS;
        m["&&"] = TokenType.AND;
        m["||"] = TokenType.OR;
        m["!="] = TokenType.NOT_EQUALS;
        m[".."] = TokenType.RANGE;
        m["->"] = TokenType.ARROW;
        return m.idup;
    }

    static bool[char] initCharSet(string chars)
    {
        bool[char] set;
        foreach (c; chars)
        {
            set[c] = true;
        }
        return set.idup;
    }

public:
    this(string file, string source, string dir)
    {
        this.file = file;
        this.source = source;
        this.dir = dir;
    }

    Token[] tokenize(bool ignoreNewLine = false)
    {
        try
        {
            uint sourceLength = this.source.length;

            while (this.offset < sourceLength)
            {
                //
            }
        }
        catch (Exception e)
        {
            //
        }
    }
}
