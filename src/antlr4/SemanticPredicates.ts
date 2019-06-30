import { Character } from "./Character";
import { CharStream } from "antlr4ts/CharStream";
import { IntStream } from "antlr4ts/IntStream";
import { TokenStream } from "antlr4ts/TokenStream";
import {
  GroovyParser,
  ExpressionContext,
  PostfixExprAltContext,
  PostfixExpressionContext,
  PathExpressionContext
} from "./GroovyParser";

export class SemanticPredicates {
  private static readonly NONSPACES_PATTERN = /\S+?/;
  private static readonly LETTER_AND_LEFTCURLY_PATTERN = /[a-zA-Z_{]/;
  private static readonly NONSURROGATE_PATTERN = /[^\u0000-\u007F\uD800-\uDBFF]/;
  private static readonly SURROGATE_PAIR1_PATTERN = /[\uD800-\uDBFF]/;
  private static readonly SURROGATE_PAIR2_PATTERN = /[\uDC00-\uDFFF]/;

  public static isFollowedByWhiteSpaces(cs: CharStream): boolean {
    const matches = (s: string, r: RegExp) => r.test(s);

    for (let index = 1, c = cs.LA(index), s = String.fromCharCode(c);
         !('\r' === s || '\n' === s || IntStream.EOF == c);
         index++, c = cs.LA(index), s = String.fromCharCode(c)) {
      if (matches(s, SemanticPredicates.NONSPACES_PATTERN)) {
        return false;
      }
    }
    return true;
  }

  public static isFollowedBy(cs: CharStream, ...chars: string[]): boolean {
    const c1 = String.fromCharCode(cs.LA(1));

    for (const c of chars) {
      if (c1 === c) {
        return true;
      }
    }

    return false;
  }

  public static isFollowedByJavaLetterInGString(cs: CharStream): boolean {
    const matches = (s: string, r: RegExp) => r.test(s);

    const c1 = cs.LA(1);

    if ('$' === String.fromCharCode(c1)) { // single $ is not a valid identifier
      return false;
    }

    const str1 = String.fromCharCode(c1);

    if (matches(str1, SemanticPredicates.LETTER_AND_LEFTCURLY_PATTERN)) {
      return true;
    }

    if (matches(str1, SemanticPredicates.NONSURROGATE_PATTERN)
        && Character.isJavaIdentifierPart(c1)) {
      return true;
    }

    const c2 = cs.LA(2);
    const str2 = String.fromCharCode(c2);

    if (matches(str1, SemanticPredicates.SURROGATE_PAIR1_PATTERN)
        && matches(str2, SemanticPredicates.SURROGATE_PAIR2_PATTERN)
        && Character.isJavaIdentifierPart(String.fromCharCode(c1, c2))) {

      return true;
    }

    return false;
  }

  private static readonly MODIFIER_SET = new Set([
    -999, // ANNOTATION_TYPE,
    GroovyParser.DEF,
    GroovyParser.VAR,

    GroovyParser.NATIVE,
    GroovyParser.SYNCHRONIZED,
    GroovyParser.TRANSIENT,
    GroovyParser.VOLATILE,

    GroovyParser.PUBLIC,
    GroovyParser.PROTECTED,
    GroovyParser.PRIVATE,
    GroovyParser.STATIC,
    GroovyParser.ABSTRACT,
    GroovyParser.FINAL,
    GroovyParser.STRICTFP,
    GroovyParser.DEFAULT,
  ]);

  public static isInvalidLocalVariableDeclaration(ts: TokenStream): boolean {
    let index = 2;
    let tokenType2 = ts.LT(index).type;

    if (GroovyParser.DOT === tokenType2) {
      let tokeTypeN = tokenType2;

      do {
        index = index + 2;
        tokeTypeN = ts.LT(index).type;
      } while (GroovyParser.DOT === tokeTypeN);

      if (GroovyParser.LT === tokeTypeN || GroovyParser.LBRACK === tokeTypeN) {
        return false;
      }

      index = index - 1;
      tokenType2 = ts.LT(index + 1).type;
    } else {
      index = 1;
    }

    const token = ts.LT(index);
    const tokenType = token.type;
    const tokenType3 = ts.LT(index + 2).type;
    const c = (token.text || '').charAt(0);

    return !(GroovyParser.BuiltInPrimitiveType === tokenType || SemanticPredicates.MODIFIER_SET.has(tokenType))
      && c === c.toLowerCase()
      && !(GroovyParser.ASSIGN === tokenType3 || (GroovyParser.LT === tokenType2 || GroovyParser.LBRACK === tokenType2));
  }

  public static isInvalidMethodDeclaration(ts: TokenStream): boolean {
    const tokenType = ts.LT(1).type;

    return (GroovyParser.Identifier === tokenType || GroovyParser.CapitalizedIdentifier === tokenType || GroovyParser.StringLiteral === tokenType)
      && GroovyParser.LPAREN === (ts.LT(2).type);
  }

  public static isFollowingArgumentsOrClosure(context: ExpressionContext): boolean {
    if (context instanceof PostfixExprAltContext) {
      const peacChildren = context.children || [];

      if (1 === peacChildren.length) {
        const peacChild = peacChildren[0];

        if (peacChild instanceof PostfixExpressionContext) {
          const pecChildren = peacChild.children || [];

          if (1 === pecChildren.length) {
            const pecChild = pecChildren[0];

            if (pecChild instanceof PathExpressionContext) {
              const pec = pecChild;
              const t = pec.t;
              return (2 == t || 3 == t);
            }
          }
        }
      }
    }
    return false;
  }
}
