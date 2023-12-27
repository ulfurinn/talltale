const sass = require("sass");
const sane = require("sane");
const fs = require("fs");
const { stdout } = require("process");
const path = require("path");

process.stdin.on("end", () => {
  process.exit();
});

process.stdin.resume();

function styleChanged() {
  const before = new Date();
  const styles = renderSCSS("css/main.scss");
  const after = new Date();

  const duration = after - before;

  stylesDistPath = "../priv/static/assets/main.css";

  try {
    fs.writeFileSync(stylesDistPath, styles.css);
  } catch (err) {
    console.error(err);
  }

  console.log(`CSS rebuilt in ${duration}ms`);

  // const devStyles = renderSCSS("css/dev/index.scss");

  // fs.appendFileSync(stylesDistPath, devStyles.css);
}

function renderSCSS(filePath) {
  return sass.compile(filePath, {
    sourceMap: true,
    loadPaths: ["css", "node_modules"],
    logger: {
      debug(message, { span }) {
        fp = path.basename(span.url.toString());
        stdout.write(`\n [DEBUG] ${fp}: ${message}`);
      },
      warn(message, { span }) {
        fp = path.basename(span.url.toString());
        stdout.write(`\n [WARN] ${fp}: ${message}`);
      },
    },
  });
}

const styleWatcher = sane("css", { glob: ["**/*.scss"] });

styleWatcher.on("ready", styleChanged);
styleWatcher.on("add", styleChanged);
styleWatcher.on("delete", styleChanged);
styleWatcher.on("change", styleChanged);
