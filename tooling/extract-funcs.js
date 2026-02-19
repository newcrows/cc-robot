const fs = require("fs");
const nodePath = require("path");
const inputDir = "../src/api/robot";

function extract(filename) {
  const outputFile = "./out/" + filename
    .replace(/^(\.)+\//, "")
    .replace(/\.lua$/, "") + ".txt";

  const content = fs.readFileSync(filename, {encoding: "utf-8"});
  const localFuncRegex = /^\s*(local\s+)function.*$/gm;
  const metaFuncRegex = /^\s*function meta.*$/gm;
  const robotFuncRegex = /^\s*function robot.*$/gm;

  function printMatches(label, content, regex, out) {
    const matches = content.match(regex);
    out("----", label, "----");

    if (matches) {
      for (let match of matches) {
        out(match.trim().replace(/^function /, ""));
      }
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

  try {
    printMatches("local functions", content, localFuncRegex, strOut);
    printMatches("meta functions", content, metaFuncRegex, strOut);
    printMatches("robot functions", content, robotFuncRegex, strOut);
  } catch (e) {
    console.log("error in", filename);
  }

  fs.mkdirSync(nodePath.dirname(outputFile), {recursive: true});
  fs.writeFileSync(outputFile, strOut.toString(), {encoding: "utf-8"});
}

function traverse(path, callback) {
  if (fs.lstatSync(path).isFile()) {
    callback(path);
  } else {
    const names = fs.readdirSync(path);

    for (let name of names) {
      traverse(nodePath.join(path, name), callback);
    }
  }
}

traverse(inputDir, extract);
