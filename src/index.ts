import {
  AST,
  Doc,
  FastPath,
  Parser,
  ParserOptions,
  Printer,
  SupportLanguage,
} from "prettier";
import { ANTLRInputStream, CommonTokenStream } from "antlr4ts";
import { GroovyLexer } from "./antlr4/GroovyLexer";
import { GroovyParser } from "./antlr4/GroovyParser";

function parse(
  text: string,
  _parsers: { [parserName: string]: Parser },
  _options: ParserOptions
): AST {
  const stream = new ANTLRInputStream(text);
  const lexer = new GroovyLexer(stream);
  const tokens = new CommonTokenStream(lexer);
  const parser = new GroovyParser(tokens);
  return parser.compilationUnit();
}

function printGroovy(
  _path: FastPath<any>,
  _options: ParserOptions,
  _print: (path: FastPath<any>) => Doc
): Doc {
  return "";
}

export const languages: SupportLanguage[] = [
  {
    extensions: [".groovy"],
    name: "GROOVY",
    parsers: ["groovy-parse"]
  } as SupportLanguage
];

export const parsers: { [parserName: string]: Parser } = {
  "groovy-parse": {
    parse,
    astFormat: "groovy-ast",
    locStart: _node => 0,
    locEnd: _node => 0
  }
};

export const printers: { [astFormat: string]: Printer } = {
  "groovy-ast": {
    print: printGroovy
  }
};
