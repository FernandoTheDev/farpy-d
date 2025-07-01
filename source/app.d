import std.stdio;
import std.file;

import frontend.lexer.lexer;
import frontend.lexer.token;
import frontend.parser.parser;
import frontend.parser.ast;

int main(string[] args)
{
	if (args.length < 2)
	{
		writeln("Error: Missing file.");
		return -1;
	}

	if (!isFile(args[1]))
	{
		writeln("Error: It's not a file.");
		return -1;
	}

	string fileContent = readText(args[1]);

	Lexer lexer = new Lexer(args[1], fileContent, ".");
	Token[] tokens = lexer.tokenize();

	writeln(fileContent);

	foreach (ref tk; tokens)
	{
		writeln(tk.kind);
		writeln(tk.value);
		writeln(tk.loc, "\n");
	}

	Parser parser = new Parser(tokens);
	Program program = parser.parse();

	foreach (node; program.body)
	{
		writeln(node.kind);
		writeln(node.type);
		writeln(node.loc);
		writeln(node.value);

		writeln(node.op);
		writeln(node.left);
		writeln(node.left.value);
		writeln(node.right.value);
	}

	return 0;
}
