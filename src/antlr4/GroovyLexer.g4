/*
 * This file is adapted from the Antlr4 Java grammar which has the following license
 *
 *  Copyright (c) 2013 Terence Parr, Sam Harwell
 *  All rights reserved.
 *  [The "BSD licence"]
 *
 *    http://www.opensource.org/licenses/bsd-license.php
 *
 * Subsequent modifications by the Groovy community have been done under the Apache License v2:
 *
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

/**
 * The Groovy grammar is based on the official grammar for Java:
 * https://github.com/antlr/grammars-v4/blob/master/java/Java.g4
 */
lexer grammar GroovyLexer;

options {
}

@header {
  import { Token } from "antlr4ts/Token";
  import { Character } from "./Character";
  import { SemanticPredicates } from "./SemanticPredicates";

  function requireFn(_b: boolean, _s: string, _n: number, __b: boolean) {
  }

  class Paren {
    private text: string;
    private lastTokenType: number;
    private line: number;
    private column: number;

    constructor(text: string, lastTokenType: number, line: number, column: number) {
      this.text = text;
      this.lastTokenType = lastTokenType;
      this.line = line;
      this.column = column;
    }

    public getText(): string {
      return this.text;
    }

    public getLastTokenType(): number {
      return this.lastTokenType;
    }

    public getLine(): number {
      return this.line;
    }

    public getColumn(): number {
      return this.column;
    }
  }
}

@members {
  private tokenIndex = 0;
  private lastTokenType  = 0;
  private invalidDigitCount = 0;

  /**
   * Record the index and token type of the current token while emitting tokens.
   */
  public emit(token?: Token): Token {
    if (!token) {
      return super.emit();
    }

    this.tokenIndex++;

    const tokenType = token.type;
    if (Token.DEFAULT_CHANNEL == token.channel) {
      this.lastTokenType = tokenType;
    }

    if (GroovyLexer.RollBackOne == tokenType) {
      this.rollbackOneChar();
    }

    return super.emit(token);
  }

  // TODO: set Identifier, CapitalizedIdentifier, NullLiteral, ...
  private static readonly REGEX_CHECK_SET = new Set<number>();

  private isRegexAllowed(): boolean {
    if (GroovyLexer.REGEX_CHECK_SET.has(this.lastTokenType)) {
      return false;
    }

    return true;
  }

  /**
   * just a hook, which will be overrided by GroovyLangLexer
   */
  protected rollbackOneChar(): void {}

  private static readonly PAREN_MAP = new Map<String, String>([
    ["(", ")"],
    ["[", "]"],
    ["{", "}"],
  ]);

  private static readonly parenStack: Paren[] = [];
  private enterParen(): void {
    GroovyLexer.parenStack.push(new Paren(this.text, this.lastTokenType, this.line, this.charPositionInLine));
  }
  private exitParen(): void {
    const paren: Paren = GroovyLexer.parenStack[GroovyLexer.parenStack.length - 1];
    const text: string = this.text;

    // TODO
    // requireFn(null != paren, "Too many '" + text + "'");
    // requireFn(text.equals(PAREN_MAP.get(paren.getText())),
    //         "'" + paren.getText() + "'" + new PositionInfo(paren.getLine(), paren.getColumn()) + " can not match '" + text + "'", -1);

    GroovyLexer.parenStack.pop();
  }
  private isInsideParens(): boolean {
    if (GroovyLexer.parenStack.length === 0) {
      return false;
    }
    const paren: Paren = GroovyLexer.parenStack[GroovyLexer.parenStack.length - 1];
    return ("(" === paren.getText() && GroovyLexer.TRY !== paren.getLastTokenType())
      || "[" === paren.getText();
  }
  private ignoreTokenInsideParens(): void {
    if (!this.isInsideParens()) {
      return;
    }

    this.channel = Token.HIDDEN_CHANNEL;
  }
  private ignoreMultiLineCommentConditionally(): void {
    if (!this.isInsideParens() && SemanticPredicates.isFollowedByWhiteSpaces(this._input)) {
      return;
    }
    this.channel = Token.HIDDEN_CHANNEL;
  }

  public getSyntaxErrorSource(): number {
    // TODO
    // return GroovySyntaxError.LEXER;
    return -1;
  }

  public getErrorLine(): number {
    return this.line;
  }

  public getErrorColumn(): number {
    return this.charPositionInLine + 1;
  }
}


// §3.10.5 String Literals
StringLiteral
    :   GStringQuotationMark    DqStringCharacter* GStringQuotationMark
    |   SqStringQuotationMark   SqStringCharacter* SqStringQuotationMark

    |   Slash      { this.isRegexAllowed() && String.fromCharCode(this._input.LA(1)) !== '*' }?
                 SlashyStringCharacter+       Slash

    |   TdqStringQuotationMark  TdqStringCharacter*    TdqStringQuotationMark
    |   TsqStringQuotationMark  TsqStringCharacter*    TsqStringQuotationMark
    |   DollarSlashyGStringQuotationMarkBegin   DollarSlashyStringCharacter+   DollarSlashyGStringQuotationMarkEnd
    ;

// Groovy gstring
GStringBegin
    :   GStringQuotationMark DqStringCharacter* Dollar -> pushMode(DQ_GSTRING_MODE), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
TdqGStringBegin
    :   TdqStringQuotationMark   TdqStringCharacter* Dollar -> type(GStringBegin), pushMode(TDQ_GSTRING_MODE), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
SlashyGStringBegin
    :   Slash { this.isRegexAllowed() && String.fromCharCode(this._input.LA(1)) !== '*' }? SlashyStringCharacter* Dollar { SemanticPredicates.isFollowedByJavaLetterInGString(this._input) }? -> type(GStringBegin), pushMode(SLASHY_GSTRING_MODE), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
DollarSlashyGStringBegin
    :   DollarSlashyGStringQuotationMarkBegin DollarSlashyStringCharacter* Dollar { SemanticPredicates.isFollowedByJavaLetterInGString(this._input) }? -> type(GStringBegin), pushMode(DOLLAR_SLASHY_GSTRING_MODE), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;

mode DQ_GSTRING_MODE;
GStringEnd
    :   GStringQuotationMark     -> popMode
    ;
GStringPart
    :   Dollar  -> pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
GStringCharacter
    :   DqStringCharacter -> more
    ;

mode TDQ_GSTRING_MODE;
TdqGStringEnd
    :   TdqStringQuotationMark    -> type(GStringEnd), popMode
    ;
TdqGStringPart
    :   Dollar   -> type(GStringPart), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
TdqGStringCharacter
    :   TdqStringCharacter -> more
    ;

mode SLASHY_GSTRING_MODE;
SlashyGStringEnd
    :   Dollar? Slash  -> type(GStringEnd), popMode
    ;
SlashyGStringPart
    :   Dollar { SemanticPredicates.isFollowedByJavaLetterInGString(this._input) }?   -> type(GStringPart), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
SlashyGStringCharacter
    :   SlashyStringCharacter -> more
    ;

mode DOLLAR_SLASHY_GSTRING_MODE;
DollarSlashyGStringEnd
    :   DollarSlashyGStringQuotationMarkEnd      -> type(GStringEnd), popMode
    ;
DollarSlashyGStringPart
    :   Dollar { SemanticPredicates.isFollowedByJavaLetterInGString(this._input) }?   -> type(GStringPart), pushMode(GSTRING_TYPE_SELECTOR_MODE)
    ;
DollarSlashyGStringCharacter
    :   DollarSlashyStringCharacter -> more
    ;

mode GSTRING_TYPE_SELECTOR_MODE;
GStringLBrace
    :   '{' { this.enterParen();  } -> type(LBRACE), popMode, pushMode(DEFAULT_MODE)
    ;
GStringIdentifier
    :   IdentifierInGString -> type(Identifier), popMode, pushMode(GSTRING_PATH_MODE)
    ;


mode GSTRING_PATH_MODE;
GStringPathPart
    :   Dot IdentifierInGString
    ;
RollBackOne
    :   . {
            // a trick to handle GStrings followed by EOF properly
            if (GroovyLexer.EOF === this._input.LA(1) &&
                 ('"' === String.fromCharCode(this._input.LA(-1)) ||
                  '/' === String.fromCharCode(this._input.LA(-1)))) {
                this.type = GroovyLexer.GStringEnd;
            } else {
                this.channel = GroovyLexer.HIDDEN;
            }
          } -> popMode
    ;


mode DEFAULT_MODE;
// character in the double quotation string. e.g. "a"
fragment
DqStringCharacter
    :   ~["\r\n\\$]
    |   EscapeSequence
    ;

// character in the single quotation string. e.g. 'a'
fragment
SqStringCharacter
    :   ~['\r\n\\]
    |   EscapeSequence
    ;

// character in the triple double quotation string. e.g. """a"""
fragment TdqStringCharacter
    :   ~["\\$]
    |   GStringQuotationMark { String.fromCharCode(this._input.LA(1)) !== '"' || String.fromCharCode(this._input.LA(2)) !== '"' || String.fromCharCode(this._input.LA(3)) === '"' && (String.fromCharCode(this._input.LA(4)) !== '"' || String.fromCharCode(this._input.LA(5)) !== '"') }?
    |   EscapeSequence
    ;

// character in the triple single quotation string. e.g. '''a'''
fragment TsqStringCharacter
    :   ~['\\]
    |   SqStringQuotationMark { String.fromCharCode(this._input.LA(1)) !== '\'' || String.fromCharCode(this._input.LA(2)) !== '\'' || String.fromCharCode(this._input.LA(3)) === '\'' && (String.fromCharCode(this._input.LA(4)) !== '\'' || String.fromCharCode(this._input.LA(5)) !== '\'') }?
    |   EscapeSequence
    ;

// character in the slashy string. e.g. /a/
fragment SlashyStringCharacter
    :   SlashEscape
    |   Dollar { !SemanticPredicates.isFollowedByJavaLetterInGString(this._input) }?
    |   ~[/$\u0000]
    ;

// character in the collar slashy string. e.g. $/a/$
fragment DollarSlashyStringCharacter
    :   SlashEscape | DollarSlashEscape | DollarDollarEscape
    |   Slash { String.fromCharCode(this._input.LA(1)) !== '$' }?
    |   Dollar { !SemanticPredicates.isFollowedByJavaLetterInGString(this._input) }?
    |   ~[/$\u0000]
    ;

// Groovy keywords
AS              : 'as';
DEF             : 'def';
IN              : 'in';
TRAIT           : 'trait';
THREADSAFE      : 'threadsafe'; // reserved keyword

// the reserved type name of Java10
VAR             : 'var';

// §3.9 Keywords
BuiltInPrimitiveType
    :   BOOLEAN
    |   CHAR
    |   BYTE
    |   SHORT
    |   INT
    |   LONG
    |   FLOAT
    |   DOUBLE
    ;

ABSTRACT      : 'abstract';
ASSERT        : 'assert';

fragment
BOOLEAN       : 'boolean';

BREAK         : 'break';

fragment
BYTE          : 'byte';

CASE          : 'case';
CATCH         : 'catch';

fragment
CHAR          : 'char';

CLASS         : 'class';
CONST         : 'const';
CONTINUE      : 'continue';
DEFAULT       : 'default';
DO            : 'do';

fragment
DOUBLE        : 'double';

ELSE          : 'else';
ENUM          : 'enum';
EXTENDS       : 'extends';
FINAL         : 'final';
FINALLY       : 'finally';

fragment
FLOAT         : 'float';


FOR           : 'for';
IF            : 'if';
GOTO          : 'goto';
IMPLEMENTS    : 'implements';
IMPORT        : 'import';
INSTANCEOF    : 'instanceof';

fragment
INT           : 'int';

INTERFACE     : 'interface';

fragment
LONG          : 'long';

NATIVE        : 'native';
NEW           : 'new';
PACKAGE       : 'package';
PRIVATE       : 'private';
PROTECTED     : 'protected';
PUBLIC        : 'public';
RETURN        : 'return';

fragment
SHORT         : 'short';


STATIC        : 'static';
STRICTFP      : 'strictfp';
SUPER         : 'super';
SWITCH        : 'switch';
SYNCHRONIZED  : 'synchronized';
THIS          : 'this';
THROW         : 'throw';
THROWS        : 'throws';
TRANSIENT     : 'transient';
TRY           : 'try';
VOID          : 'void';
VOLATILE      : 'volatile';
WHILE         : 'while';


// §3.10.1 Integer Literals

IntegerLiteral
    :   (   DecimalIntegerLiteral
        |   HexIntegerLiteral
        |   OctalIntegerLiteral
        |   BinaryIntegerLiteral
        ) (Underscore { requireFn(false, "Number ending with underscores is invalid", -1, true); })?

    // !!! Error Alternative !!!
    |   Zero ([0-9] { this.invalidDigitCount++; })+ { requireFn(false, "Invalid octal number", -(this.invalidDigitCount + 1), true); } IntegerTypeSuffix?
    ;

fragment
Zero
    :   '0'
    ;

fragment
DecimalIntegerLiteral
    :   DecimalNumeral IntegerTypeSuffix?
    ;

fragment
HexIntegerLiteral
    :   HexNumeral IntegerTypeSuffix?
    ;

fragment
OctalIntegerLiteral
    :   OctalNumeral IntegerTypeSuffix?
    ;

fragment
BinaryIntegerLiteral
    :   BinaryNumeral IntegerTypeSuffix?
    ;

fragment
IntegerTypeSuffix
    :   [lLiIgG]
    ;

fragment
DecimalNumeral
    :   Zero
    |   NonZeroDigit (Digits? | Underscores Digits)
    ;

fragment
Digits
    :   Digit (DigitOrUnderscore* Digit)?
    ;

fragment
Digit
    :   Zero
    |   NonZeroDigit
    ;

fragment
NonZeroDigit
    :   [1-9]
    ;

fragment
DigitOrUnderscore
    :   Digit
    |   Underscore
    ;

fragment
Underscores
    :   Underscore+
    ;

fragment
Underscore
    :   '_'
    ;

fragment
HexNumeral
    :   Zero [xX] HexDigits
    ;

fragment
HexDigits
    :   HexDigit (HexDigitOrUnderscore* HexDigit)?
    ;

fragment
HexDigit
    :   [0-9a-fA-F]
    ;

fragment
HexDigitOrUnderscore
    :   HexDigit
    |   Underscore
    ;

fragment
OctalNumeral
    :   Zero Underscores? OctalDigits
    ;

fragment
OctalDigits
    :   OctalDigit (OctalDigitOrUnderscore* OctalDigit)?
    ;

fragment
OctalDigit
    :   [0-7]
    ;

fragment
OctalDigitOrUnderscore
    :   OctalDigit
    |   Underscore
    ;

fragment
BinaryNumeral
    :   Zero [bB] BinaryDigits
    ;

fragment
BinaryDigits
    :   BinaryDigit (BinaryDigitOrUnderscore* BinaryDigit)?
    ;

fragment
BinaryDigit
    :   [01]
    ;

fragment
BinaryDigitOrUnderscore
    :   BinaryDigit
    |   Underscore
    ;

// §3.10.2 Floating-Point Literals

FloatingPointLiteral
    :   (   DecimalFloatingPointLiteral
        |   HexadecimalFloatingPointLiteral
        ) (Underscore { requireFn(false, "Number ending with underscores is invalid", -1, true); })?
    ;

fragment
DecimalFloatingPointLiteral
    :   Digits Dot Digits ExponentPart? FloatTypeSuffix?
    |   Digits ExponentPart FloatTypeSuffix?
    |   Digits FloatTypeSuffix
    ;

fragment
ExponentPart
    :   ExponentIndicator SignedInteger
    ;

fragment
ExponentIndicator
    :   [eE]
    ;

fragment
SignedInteger
    :   Sign? Digits
    ;

fragment
Sign
    :   [+\-]
    ;

fragment
FloatTypeSuffix
    :   [fFdDgG]
    ;

fragment
HexadecimalFloatingPointLiteral
    :   HexSignificand BinaryExponent FloatTypeSuffix?
    ;

fragment
HexSignificand
    :   HexNumeral Dot?
    |   Zero [xX] HexDigits? Dot HexDigits
    ;

fragment
BinaryExponent
    :   BinaryExponentIndicator SignedInteger
    ;

fragment
BinaryExponentIndicator
    :   [pP]
    ;

fragment
Dot :   '.'
    ;

// §3.10.3 Boolean Literals

BooleanLiteral
    :   'true'
    |   'false'
    ;


// §3.10.6 Escape Sequences for Character and String Literals

fragment
EscapeSequence
    :   Backslash [btnfr"'\\]
    |   OctalEscape
    |   UnicodeEscape
    |   DollarEscape
    |   LineEscape
    ;


fragment
OctalEscape
    :   Backslash OctalDigit
    |   Backslash OctalDigit OctalDigit
    |   Backslash ZeroToThree OctalDigit OctalDigit
    ;

// Groovy allows 1 or more u's after the backslash
fragment
UnicodeEscape
    :   Backslash 'u' HexDigit HexDigit HexDigit HexDigit
    ;

fragment
ZeroToThree
    :   [0-3]
    ;

// Groovy Escape Sequences

fragment
DollarEscape
    :   Backslash Dollar
    ;

fragment
LineEscape
    :   Backslash '\r'? '\n'
    ;

fragment
SlashEscape
    :   Backslash Slash
    ;

fragment
Backslash
    :   '\\'
    ;

fragment
Slash
    :   '/'
    ;

fragment
Dollar
    :   '$'
    ;

fragment
GStringQuotationMark
    :   '"'
    ;

fragment
SqStringQuotationMark
    :   '\''
    ;

fragment
TdqStringQuotationMark
    :   '"""'
    ;

fragment
TsqStringQuotationMark
    :   '\'\'\''
    ;

fragment
DollarSlashyGStringQuotationMarkBegin
    :   '$/'
    ;

fragment
DollarSlashyGStringQuotationMarkEnd
    :   '/$'
    ;

fragment
DollarSlashEscape
    :   '$/$'
    ;

fragment
DollarDollarEscape
    :   '$$'
    ;

// §3.10.7 The Null Literal
NullLiteral
    :   'null'
    ;

// Groovy Operators

RANGE_INCLUSIVE     : '..';
RANGE_EXCLUSIVE     : '..<';
SPREAD_DOT          : '*.';
SAFE_DOT            : '?.';
SAFE_CHAIN_DOT      : '??.';
ELVIS               : '?:';
METHOD_POINTER      : '.&';
METHOD_REFERENCE    : '::';
REGEX_FIND          : '=~';
REGEX_MATCH         : '==~';
POWER               : '**';
POWER_ASSIGN        : '**=';
SPACESHIP           : '<=>';
IDENTICAL           : '===';
NOT_IDENTICAL       : '!==';
ARROW               : '->';

// !internalPromise will be parsed as !in ternalPromise, so semantic predicates are necessary
NOT_INSTANCEOF      : '!instanceof' { SemanticPredicates.isFollowedBy(this._input, ' ', '\t', '\r', '\n') }?;
NOT_IN              : '!in'         { SemanticPredicates.isFollowedBy(this._input, ' ', '\t', '\r', '\n', '[', '(', '{') }?;


// §3.11 Separators

LPAREN          : '('  { this.enterParen();     } -> pushMode(DEFAULT_MODE);
RPAREN          : ')'  { this.exitParen();      } -> popMode;
LBRACE          : '{'  { this.enterParen();     } -> pushMode(DEFAULT_MODE);
RBRACE          : '}'  { this.exitParen();      } -> popMode;
LBRACK          : '['  { this.enterParen();     } -> pushMode(DEFAULT_MODE);
RBRACK          : ']'  { this.exitParen();      } -> popMode;

SEMI            : ';';
COMMA           : ',';
DOT             : Dot;

// §3.12 Operators

ASSIGN          : '=';
GT              : '>';
LT              : '<';
NOT             : '!';
BITNOT          : '~';
QUESTION        : '?';
COLON           : ':';
EQUAL           : '==';
LE              : '<=';
GE              : '>=';
NOTEQUAL        : '!=';
AND             : '&&';
OR              : '||';
INC             : '++';
DEC             : '--';
ADD             : '+';
SUB             : '-';
MUL             : '*';
DIV             : Slash;
BITAND          : '&';
BITOR           : '|';
XOR             : '^';
MOD             : '%';


ADD_ASSIGN      : '+=';
SUB_ASSIGN      : '-=';
MUL_ASSIGN      : '*=';
DIV_ASSIGN      : '/=';
AND_ASSIGN      : '&=';
OR_ASSIGN       : '|=';
XOR_ASSIGN      : '^=';
MOD_ASSIGN      : '%=';
LSHIFT_ASSIGN   : '<<=';
RSHIFT_ASSIGN   : '>>=';
URSHIFT_ASSIGN  : '>>>=';
ELVIS_ASSIGN    : '?=';


// §3.8 Identifiers (must appear after all keywords in the grammar)
CapitalizedIdentifier
    :   [A-Z] JavaLetterOrDigit*
    ;

Identifier
    :   JavaLetter JavaLetterOrDigit*
    ;

fragment
IdentifierInGString
    :   JavaLetterInGString JavaLetterOrDigitInGString*
    ;

fragment
JavaLetterInGString
    :   [a-zA-Z_] // these are the "java letters" below 0x7F, except for $
    |   // covers all characters above 0x7F which are not a surrogate
        ~[\u0000-\u007F\uD800-\uDBFF]
        {Character.isJavaIdentifierStart(this._input.LA(-1))}?
    |   // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
        [\uD800-\uDBFF] [\uDC00-\uDFFF]
        {Character.isJavaIdentifierStart(String.fromCharCode(this._input.LA(-2), this._input.LA(-1)))}?
    ;

fragment
JavaLetterOrDigitInGString
    :   [a-zA-Z0-9_] // these are the "java letters or digits" below 0x7F, except for $
    |   // covers all characters above 0x7F which are not a surrogate
        ~[\u0000-\u007F\uD800-\uDBFF]
        {Character.isJavaIdentifierPart(this._input.LA(-1))}?
    |   // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
        [\uD800-\uDBFF] [\uDC00-\uDFFF]
        {Character.isJavaIdentifierPart(String.fromCharCode(this._input.LA(-2), this._input.LA(-1)))}?
    ;


fragment
JavaLetter
    :   [a-zA-Z$_] // these are the "java letters" below 0x7F
    |   // covers all characters above 0x7F which are not a surrogate
        ~[\u0000-\u007F\uD800-\uDBFF]
        {Character.isJavaIdentifierStart(this._input.LA(-1))}?
    |   // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
        [\uD800-\uDBFF] [\uDC00-\uDFFF]
        {Character.isJavaIdentifierStart(String.fromCharCode(this._input.LA(-2), this._input.LA(-1)))}?
    ;

fragment
JavaLetterOrDigit
    :   [a-zA-Z0-9$_] // these are the "java letters or digits" below 0x7F
    |   // covers all characters above 0x7F which are not a surrogate
        ~[\u0000-\u007F\uD800-\uDBFF]
        {Character.isJavaIdentifierPart(this._input.LA(-1))}?
    |   // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
        [\uD800-\uDBFF] [\uDC00-\uDFFF]
        {Character.isJavaIdentifierPart(String.fromCharCode(this._input.LA(-2), this._input.LA(-1)))}?
    ;

//
// Additional symbols not defined in the lexical specification
//

AT : '@';
ELLIPSIS : '...';

//
// Whitespace, line escape and comments
//
WS  :  ([ \t\u000C]+ | LineEscape+)     -> skip
    ;


// Inside (...) and [...] but not {...}, ignore newlines.
NL  : '\r'? '\n'            { this.ignoreTokenInsideParens(); }
    ;

// Multiple-line comments(including groovydoc comments)
ML_COMMENT
    :   '/*' .*? '*/'       { this.ignoreMultiLineCommentConditionally(); } -> type(NL)
    ;

// Single-line comments
SL_COMMENT
    :   '//' ~[\r\n\uFFFF]* { this.ignoreTokenInsideParens(); }             -> type(NL)
    ;

// Script-header comments.
// The very first characters of the file may be "#!".  If so, ignore the first line.
SH_COMMENT
    :   '#!' { requireFn(0 == this.tokenIndex, "Shebang comment should appear at the first line", -2, true); } ~[\r\n\uFFFF]* -> skip
    ;

// Unexpected characters will be handled by groovy parser later.
UNEXPECTED_CHAR
    :   .
    ;
