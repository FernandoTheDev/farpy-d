module frontend.parser.ast;

import frontend.values;
import frontend.lexer.token;
import std.variant;

enum LLVMType
{
    I1 = "i1", // Bool (1 bit)
    I8 = "i8", // Byte (8 bits)
    I16 = "i16", // Short (16 bits)
    I32 = "i32", // Int (32 bits)
    I64 = "i64", // Long (64 bits)
    I128 = "i128", // Long (128 bits)

    FLOAT = "float",
    DOUBLE = "double",

    VOID = "void",
    LABEL = "label",
    PTR = "ptr",

    STRING = "i8*",
}

struct FTypeInfo
{
    TypesNative baseType;
    bool isArray;
    size_t dimensions;
    bool isPointer;
    bool isStruct;
    size_t pointerLevel;
}

FTypeInfo createTypeInfo(TypesNative baseType, bool s = false)
{
    return FTypeInfo(
        baseType,
        false,
        0,
        false,
        s,
        0
    );
}

FTypeInfo createArrayType(TypesNative baseType, size_t dimensions = 1, bool s = false)
{
    return FTypeInfo(
        baseType,
        true,
        dimensions,
        false,
        s,
        0
    );
}

FTypeInfo createPointerType(TypesNative baseType, size_t pointerLevel, bool s = false)
{
    return FTypeInfo(
        baseType,
        false,
        0,
        true,
        s,
        pointerLevel
    );
}

string strRepeat(string s, size_t times)
{
    string result;
    foreach (_; 0 .. times)
        result ~= s;
    return result;
}

string typeInfoToString(FTypeInfo type)
{
    auto result = type.baseType;

    if (type.isArray)
    {
        for (auto i = 0; i < type.dimensions; i++)
        {
            result ~= "[]";
        }
    }

    if (type.isPointer)
    {
        result ~= strRepeat("*", type.pointerLevel) ~ result;
    }

    return result;
}

enum NodeType
{
    Program,
    BinaryExpr,
    IntLiteral
}

class Stmt
{
    NodeType kind;
    FTypeInfo type;
    Variant value;
    Loc loc;
    LLVMType llvmType;

    // BinaryExpr
    Stmt left;
    Stmt right;
    string op;
}

class Program : Stmt
{
    Stmt[] body;

    this(Stmt[] body)
    {
        this.kind = NodeType.Program;
        this.body = body;
    }
}

class BinaryExpr : Stmt
{
    this(Stmt left, Stmt right, string op)
    {
        this.kind = NodeType.BinaryExpr;
        this.left = left;
        this.right = right;
        this.op = op;
    }
}

class IntLiteral : Stmt
{
    this(size_t value, Loc loc)
    {
        this.kind = NodeType.IntLiteral;
        this.type = createTypeInfo(TypesNative.INT);
        this.value = value;
        this.loc = loc;
    }
}
