"use strict";

const fs = require("fs");
const extname = require("path").extname;
const prettier = require("prettier");
const raw = require("jest-snapshot-serializer-raw").wrap;

function prettyprint(src, filepath, options) {
  return prettier.format(src, Object.assign({ filepath }, options));
}

global.run_spec = (dirname, parsers, options) => {
  /* instabul ignore if */
  if (!parsers || !parsers.length) {
    throw new Error(`No parsers were specified for ${dirname}`);
  }

  options = Object.assign(
    {
      plugins: ["."]
    },
    options
  );

  fs.readdirSync(dirname).forEach(filename => {
    const path = dirname + "/" + filename;
    if (
      extname(filename) !== ".snap" &&
        fs.lstatSync(path).isFile() &&
        filename[0] !== "." &&
        filename !== "jsfmt.spec.js"
    ) {
      const source = fs.readFileSync(path, "utf8");
      const mergedOptions = Object.assign({}, options, {
        parser: parsers[0]
      });
      const output = prettyprint(source, path, mergedOptions);
      test(filename, () => {
        expect(raw(source + "~".repeat(80) + "\n" + output)).toMatchSnapshot();
      });
    }
  });
};
