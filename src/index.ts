import {
  AST,
  Doc,
  FastPath,
  Parser,
  ParserOptions,
  Printer,
  SupportLanguage,
  doc
} from "prettier";
import { ANTLRInputStream, CommonTokenStream } from "antlr4ts";
import * as GroovyLexer from "./antlr4/GroovyLexer";
import * as GroovyParser from "./antlr4/GroovyParser";
import { Context } from "./Context";

const {
  builders: { concat, group, indent, join, line, softline, hardline }
} = doc;

function parse(
  text: string,
  _parsers: { [parserName: string]: Parser },
  _options: ParserOptions
): AST {
  GroovyLexer.GroovyLexer.reset();

  const stream = new ANTLRInputStream(text);
  const lexer = new GroovyLexer.GroovyLexer(stream);
  const tokens = new CommonTokenStream(lexer);
  const parser = new GroovyParser.GroovyParser(tokens);
  return parser.compilationUnit();
}

function printGroovy(
  path: FastPath<Context>,
  _options: ParserOptions,
  print: (path: FastPath<Context>) => Doc
): Doc {
  const node: Context = path.getValue();

  if (node instanceof GroovyParser.CompilationUnitContext) {
    const docs: Doc[] = [];
    (node.children || []).forEach((child, index) => {
      if (
        child instanceof GroovyParser.PackageDeclarationContext ||
        child instanceof GroovyParser.StatementsContext
      ) {
        docs.push(path.call(print, "children", index));
      }
    });
    return concat([join(hardline, docs), hardline]);
  }

  if (node instanceof GroovyParser.StatementsContext) {
    const docs: Doc[] = [];
    (node.children || []).forEach((child, index) => {
      if (child instanceof GroovyParser.StatementContext) {
        docs.push(path.call(print, "children", index));
      }
    });
    return join(hardline, docs);
  }

  if (node instanceof GroovyParser.StatementContext) {
    if (node instanceof GroovyParser.ExpressionStmtAltContext) {
      return path.call(print, "children", 0);
    }
  }

  if (node instanceof GroovyParser.StatementExpressionContext) {
    if (node instanceof GroovyParser.CommandExprAltContext) {
      return path.call(print, "children", 0);
    }
  }

  if (node instanceof GroovyParser.CommandExpressionContext) {
    const expression = path.call(print, "children", 0);
    const argumentList = path.call(print, "children", 1);
    return concat([expression, " ", argumentList]);
  }

  if (node instanceof GroovyParser.ExpressionContext) {
    if (node instanceof GroovyParser.PostfixExprAltContext) {
      return path.call(print, "children", 0);
    }
  }

  if (node instanceof GroovyParser.PostfixExpressionContext) {
    return path.call(print, "children", 0);
  }

  if (node instanceof GroovyParser.PathExpressionContext) {
    return path.call(print, "children", 0);
  }

  if (node instanceof GroovyParser.PrimaryContext) {
    if (node instanceof GroovyParser.IdentifierPrmrAltContext) {
      return path.call(print, "children", 0);
    }

    if (node instanceof GroovyParser.LiteralPrmrAltContext) {
      return node.literal().text;
    }
  }

  if (node instanceof GroovyParser.IdentifierContext) {
    return node.text;
  }

  if (node instanceof GroovyParser.EnhancedArgumentListContext) {
    const docs: Doc[] = [];
    node.children!.forEach((child, index) => {
      if (child instanceof GroovyParser.EnhancedArgumentListElementContext) {
        docs.push(path.call(print, "children", index));
      }
    });
    return join(concat([",", " "]), docs);
  }

  if (node instanceof GroovyParser.EnhancedArgumentListElementContext) {
    return path.call(print, "children", 0);
  }

  if (node instanceof GroovyParser.ExpressionListElementContext) {
    return path.call(print, "children", 0);
  }

  return "";
}

export const languages: SupportLanguage[] = [
  {
    extensions: [".groovy"],
    name: "Groovy",
    parsers: ["groovy"]
  } as SupportLanguage
];

export const parsers: { [parserName: string]: Parser } = {
  groovy: {
    parse,
    astFormat: "groovy",
    locStart: _node => 0,
    locEnd: _node => 0
  }
};

export const printers: { [astFormat: string]: Printer } = {
  groovy: {
    print: printGroovy
  }
};
