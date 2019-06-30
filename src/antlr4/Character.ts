export class Character {
  // https://stackoverflow.com/questions/35578567
  public static isJavaIdentifierStart(c: string | number): boolean {
    if (typeof c === 'number') {
      c = String.fromCharCode(c);
    }
    return /[_a-zA-Z]/.test(c);
  }

  public static isJavaIdentifierPart(c: string | number): boolean {
    if (typeof c === 'number') {
      c = String.fromCharCode(c);
    }
    return /[_a-zA-Z0-9]/.test(c);
  }
}
