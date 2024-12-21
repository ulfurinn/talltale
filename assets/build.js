import esbuild from 'esbuild';
import { sassPlugin } from 'esbuild-sass-plugin'

const args = process.argv.slice(2);
const watch = args.includes('--watch');
const deploy = args.includes('--deploy');

const loader = {
  // Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
};

const plugins = [
  sassPlugin()
];

// Define esbuild options
let opts = {
  entryPoints: ["js/app.js", "css/app.scss"],
  bundle: true,
  logLevel: "info",
  target: "es2017",
  outdir: "../priv/static/assets",
  external: ["*.css", "fonts/*", "images/*"],
  nodePaths: ["../deps"],
  loader: loader,
  plugins: plugins,
};

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
  };
  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
    })
    .catch((error) => {
      console.error(error)
    });
} else {
  esbuild.build(opts);
}
