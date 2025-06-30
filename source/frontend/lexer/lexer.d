module frontend.lexer.lexer;

import std.variant;
import std.stdio;
import std.conv;
import std.string;

import frontend.lexer.token;

// Lexer
class Lexer
{
private:
    string source;
    string file;
    string dir;

    ulong line = 1;
    ulong offset = 0;
    ulong lineOffset = 0;
    ulong start = 1;
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
        return m; // idup faz uma cópia imutável
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
        return m;
    }

    static bool[char] initCharSet(string chars)
    {
        bool[char] set;
        foreach (c; chars)
        {
            set[c] = true;
        }
        return set;
    }

    string getLineText(ulong line)
    {
        if (!this.lineCache.length)
        {
            this.lineCache = this.source.splitLines();
        }

        // Evita acessar fora do bounds
        if (line == 0 || line > this.lineCache.length)
            return "";

        return this.lineCache[line - 1];
    }

    Loc getLocation(ulong start, ulong end, ulong line = 0)
    {
        ulong currentLine = line == 0 ? this.line : line;
        return Loc(
            this.file,
            currentLine,
            this.getLineText(currentLine),
            start,
            end,
            this.dir
        );
    }

    Token createToken(TokenType kind, Variant value, ulong skipChars = 1)
    {
        auto valueLength = to!string(value).length;
        Token token =
        {
            kind: kind, value: value, loc: this.getLocation(this.start, cast(ulong) this.start + valueLength)
        };
        this.tokens ~= token;
        this.offset += skipChars;
        return token;
    }

    void createTokenWithLocation(TokenType kind, Variant value, ulong start, ulong length)
    {
        this.tokens ~= Token(

            kind,
            value,
            this.getLocation(start, start + length)
        );
    }

    bool lexComment()
    {
        const ulong startPos = this.start;
        const ulong startLine = this.line;
        this.offset++; // Skip the first '/'

        if (this.source[this.offset] == '/')
        {
            this.offset++;
            while (this.offset < this.source.length && this.source[this.offset] != '\n')
            {
                this.offset++;
            }
            return true;
        }

        if (this.source[this.offset] == '*')
        {
            // Multiple-line block comment
            this.offset++;

            while (this.offset + 1 < this.source.length)
            {
                if (this.source[this.offset] == '*' &&
                    this.source[this.offset + 1] == '/')
                {
                    this.offset += 2;
                    return true;
                }

                if (this.source[this.offset] == '\n')
                {
                    this.line++;
                    this.lineOffset = this.offset + 1;
                }
                this.offset++;
            }
            // Error
            throw new Exception("Unclosed block comment");
        }

        this.offset--;
        return false;
    }

    void lexIdentifier()
    {
        const ulong startOffset = this.offset;

        while (this.offset < this.source.length)
        {
            char c = this.source[this.offset];
            if (!(c in this.ALPHA_CHARS) && !(c in this.DIGIT_CHARS))
            {
                break;
            }
            this.offset++;
        }

        string identifier = this.source[startOffset .. this.offset];
        TokenType tokenType = TokenType.IDENTIFIER;
        if (auto keywordType = identifier in keywords) // Verificação segura
        {
            tokenType = *keywordType;
        }

        this.createTokenWithLocation(tokenType, Variant(identifier), startOffset - this.lineOffset, identifier
                .length);
    }

    bool lexSingleCharToken()
    {
        string currentChar = this.source[this.offset .. this.offset + 1];

        if (auto tokenType = currentChar in SINGLE_CHAR_TOKENS)
        {
            this.createToken(*tokenType, Variant(currentChar));
            return true;
        }
        return false;
    }

    bool lexMultiCharToken()
    {
        if (this.offset + 1 >= this.source.length)
            return false;

        string twoChars = this.source[this.offset .. this.offset + 2];

        if (auto tokenType = twoChars in MULTI_CHAR_TOKENS)
        {
            this.createToken(*tokenType, Variant(twoChars), 2);
            return true;
        }
        return false;
    }

    void lexNumber()
    {
        ulong startOffset = this.offset;

        while (this.offset < this.source.length && this.source[this.offset] in DIGIT_CHARS)
        {
            this.offset++;
        }

        if (this.offset < this.source.length && this.source[this.offset] == '.' &&
            this.offset + 1 < this.source.length && this.source[this.offset + 1] in DIGIT_CHARS)
        {
            this.offset++;
            while (this.offset < this.source.length && this.source[this.offset] in DIGIT_CHARS)
            {
                this.offset++;
            }
        }

        string numberStr = this.source[startOffset .. this.offset];
        this.createTokenWithLocation(TokenType.INT, Variant(numberStr), startOffset - this.lineOffset, numberStr
                .length);
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
            ulong sourceLength = cast(ulong) this.source.length;

            while (this.offset < sourceLength)
            {
                this.start = this.offset - this.lineOffset;
                char c = this.source[this.offset];

                if (c == '\n')
                {
                    if (ignoreNewLine)
                    {
                        this.offset++;
                        continue;
                    }
                    this.line++;
                    this.offset++;
                    this.lineOffset = this.offset;
                    continue;
                }

                if (c in this.WHITESPACE_CHARS)
                {
                    this.offset++;
                    continue;
                }

                if (c == '/' && this.offset + 1 < sourceLength)
                {
                    char nextChar = this.source[this.offset + 1];
                    if (nextChar == '/' || nextChar == '*')
                    {
                        if (!this.lexComment())
                        {
                            if (!this.lexSingleCharToken())
                            {
                                throw new Exception("Unexpected character: " ~ c);
                            }
                        }
                        continue;
                    }
                }

                if (c in this.ALPHA_CHARS)
                {
                    this.lexIdentifier();
                    continue;
                }

                if (c in this.DIGIT_CHARS)
                {
                    this.lexNumber();
                    continue;
                }

                if (this.lexMultiCharToken())
                {
                    continue;
                }

                if (this.lexSingleCharToken())
                {
                    continue;
                }

                throw new Exception(
                    "Unexpected character: '" ~ c ~ "' at line " ~ to!string(this.line));
            }

            this.createToken(TokenType.EOF, Variant("\0"), 0);
            return this.tokens;
        }
        catch (Exception e)
        {
            writeln("Lexer error: ", e.msg);
            throw e;
        }
    }
}
