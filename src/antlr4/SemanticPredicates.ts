import { Character } from "./Character";
import { CharStream } from "antlr4ts/CharStream";
import { IntStream } from "antlr4ts/IntStream";

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

  public static isInvalidLocalVariableDeclaration(ts: any): boolean {
    return true;
  }

  public static isInvalidMethodDeclaration(ts: any): boolean {
    return true;
  }

  public static isFollowingArgumentsOrClosure(context: any): boolean {
    return true;
  }
}
