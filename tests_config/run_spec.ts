import fs from "fs";
import { extname, join } from "path";
import prettier from "prettier";
import { wrap } from "jest-snapshot-serializer-raw";
import * as plugin from "../src/index";

const PARSER = "groovy";

function prettyprint(src: string, filepath: string, options: any) {
  return prettier.format(src, { filepath, ...options });
}

(global as any).run_spec = (dirname: string, options: any = {}) => {
  options = { plugins: [plugin], ...options };

  fs.readdirSync(dirname).forEach(filename => {
    const path = join(dirname, filename);
    if (
      extname(filename) === ".snap" ||
      !fs.lstatSync(path).isFile() ||
      filename[0] === "." ||
      filename === "jsfmt.spec.js"
    ) {
      return;
    }

    const source = fs.readFileSync(path, "utf8");
    const output = prettyprint(source, path, { ...options, parser: PARSER });
    test(filename, () =>
      expect(wrap(source + "~".repeat(80) + "\n" + output)).toMatchSnapshot()
    );
  });
};
