module frontend.lexer.token;

import std.variant;

// Token type
enum TokenType
{
    // keywords
    NEW, // new x = EXPR 0
    MUT, // new mut x = EXPR 1
    IF, // if 2
    ELIF, // } elif () { 3
    ELSE, // else 4
    FOR, // for 5
    WHILE, // while 6
    FN, // fn x() {} 7
    RETURN, // return EXPR 8
    IMPORT, // import x 9
    AS, // import x as y 10
    BREAK, // break 11

    IDENTIFIER, // omg 12

    // Types
    STRING, // "omg" 13
    INT, // 10 14
    FLOAT, // 10.1 15
    NULL, // null 16

    // Especials
    BINARY, // 17

    // Symbols
    EQUALS, // = 18
    PLUS, // + 19
    INCREMENT, // ++ 20
    MINUS, // - 21
    DECREMENT, // -- 22
    SLASH, // / 23
    ASTERISK, // * 24
    EXPONENTIATION, // ** 25
    PERCENT, // % 26
    REMAINDER, // %% 27
    EQUALS_EQUALS, // == 28
    NOT_EQUALS, // != 29
    GREATER_THAN, // > 30
    LESS_THAN, // < 31
    GREATER_THAN_OR_EQUALS, // >= 32
    LESS_THAN_OR_EQUALS, // <= 33
    AND, // && 34
    OR, // || 35
    PIPE, // | // new x: <T> | <T> = <EXPR> 36
    COMMA, // , 37
    COLON, // : 38
    SEMICOLON, // ; 39
    DOT, // . 40
    LPAREN, // ( 41
    RPAREN, // ) 42
    LBRACE, // { 43
    RBRACE, // } 44
    LBRACKET, // [ 45
    RBRACKET, // ] 46
    NOT, // ] 48
    RANGE, // .. 49
    STEP, // step 50

    EOF, // EndOfFile 47
    ARROW, // -> 51
    EXTERN, // keyword 52
    START, // start 53
    END, // start 54
    STRUCT, // struct 55
    C_DIRECTIVE, // # 56
    AMPERSAND, // & 57
    BANG, // ! 58
    FALSE, // false 59
    TRUE, // true 60
    FROM, // from 61
    HEXADECIMAL, // 0x111 62
    OCTAL, // 0o777 63
    QUESTION, // ? 64
}

// Loc from Token
struct Loc
{
    string file;
    size_t line;
    string line_raw;
    size_t start;
    size_t end;
    string dir;
}

// Token
struct Token
{
    TokenType kind;
    Variant value;
    Loc loc;
}

TokenType[string] keywords;

shared static this()
{
    keywords["new"] = TokenType.NEW;
    keywords["mut"] = TokenType.MUT;
    keywords["if"] = TokenType.IF;
    keywords["else"] = TokenType.ELSE;
    keywords["elif"] = TokenType.ELIF;
    keywords["fn"] = TokenType.FN;
    keywords["return"] = TokenType.RETURN;
    keywords["for"] = TokenType.FOR;
    keywords["while"] = TokenType.WHILE;
    keywords["import"] = TokenType.IMPORT;
    keywords["as"] = TokenType.AS;
    keywords["break"] = TokenType.BREAK;
    keywords["step"] = TokenType.STEP;
    keywords["extern"] = TokenType.EXTERN;
    keywords["start"] = TokenType.START;
    keywords["end"] = TokenType.END;
    keywords["struct"] = TokenType.STRUCT;
    keywords["false"] = TokenType.FALSE;
    keywords["true"] = TokenType.TRUE;
    keywords["from"] = TokenType.FROM;
}

bool isTypeToken(Token token)
{
    import std.conv : to;

    if (token.kind != TokenType.IDENTIFIER)
        return false;

    static immutable bool[string] typeKeywords = [
        "int": true,
        "float": true,
        "string": true,
        "bool": true,
        "void": true
    ];

    try
    {
        string tokenValue = token.value.get!string;
        return (tokenValue in typeKeywords) !is null;
    }
    catch (Exception e)
    {
        return false;
    }
}

bool isComplexTypeToken(Token token)
{
    switch (token.kind)
    {
    case TokenType.ASTERISK:
    case TokenType.LBRACKET:
    case TokenType.RBRACKET:
    case TokenType.AMPERSAND:
        return true;
    default:
        return false;
    }
}
