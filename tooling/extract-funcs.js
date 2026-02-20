const fs = require("fs");
const nodePath = require("path");
const inputDir = "../src/api";

let globalLocalOut = createToStringOut();
let globalMetaOut = createToStringOut();
let globalRobotOut = createToStringOut();

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

function extract(filename) {
  const outputFile = "./out/" + filename
    .replace(/^(\.)+\//, "")
    .replace(/\.lua$/, "") + ".txt";

  const content = fs.readFileSync(filename, {encoding: "utf-8"});
  const localFuncRegex = /^\s*(local\s+)function.*$/gm;
  const metaFuncRegex = /^\s*function meta.*$/gm;

  const apiName = nodePath.relative(inputDir, filename).split('/')[0]
  const apiRegex = new RegExp(`^\\s*function ${apiName}.*$`, "gm");

  function printMatches(label, content, regex, out, noLabelOut) {
    const matches = content.match(regex);
    out("----", label.toUpperCase(), "----");

    if (matches) {
      noLabelOut("# " + nodePath.relative("../src", filename));

      for (let match of matches) {
        const text = match.trim().replace(/^function /, "");

        out(text);
        noLabelOut(text);
      }

      noLabelOut();
    }

    out();
  }

  const strOut = createToStringOut();

  try {
    printMatches("local functions", content, localFuncRegex, strOut, globalLocalOut);
    printMatches("meta functions", content, metaFuncRegex, strOut, globalMetaOut);
    printMatches(apiName + " functions", content, apiRegex, strOut, globalRobotOut);
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

let globalStr = "";

globalStr += "---- local functions ----\n".toUpperCase();
globalStr += globalLocalOut.toString();

globalStr += "---- meta functions ----\n".toUpperCase();
globalStr += globalMetaOut.toString();

globalStr += "---- api functions ----\n".toUpperCase();
globalStr += globalRobotOut.toString();

fs.writeFileSync("./out/summary.txt", globalStr, {encoding: "utf-8"});
