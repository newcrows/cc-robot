const fs = require("fs");
const path = require("path");
const inputFile = "../robot/init_inventory.lua";

function extract() {
  const outputFile = "./out/" + inputFile
    .replace(/^(\.)+\//, "")
    .replace(/\.lua$/, "") + ".txt";

  const content = fs.readFileSync(inputFile, {encoding: "utf-8"});
  const localFuncRegex = /^\s*(local\s+)function.*$/gm;
  const metaFuncRegex = /^\s*function meta.*$/gm;
  const robotFuncRegex = /^\s*function robot.*$/gm;

  function printMatches(label, content, regex, out) {
    const matches = content.match(regex);
    out("----", label, "----");

    for (let match of matches) {
      out(match.trim().replace(/^function /, ""));
    }

    out();
  }

  function createToStringOut() {
    let str = "";

    const out = function (...strings) {
      const line = strings.join(" ") + "\n";
      str += line
    }

    out.toString = function () {
      return str;
    }

    return out;
  }

  const strOut = createToStringOut();

  printMatches("local functions", content, localFuncRegex, strOut);
  printMatches("meta functions", content, metaFuncRegex, strOut);
  printMatches("robot functions", content, robotFuncRegex, strOut);

  fs.mkdirSync(path.dirname(outputFile), {recursive: true});
  fs.writeFileSync(outputFile, strOut.toString(), {encoding: "utf-8"});
}

extract();
