// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {},
      backgroundImage: {
        'card': "url('/images/card.svg')",
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require('tailwindcss-themer')({
      themes: [
        {
          name: "editor",
          extend: {
            colors: {
              primary: {
                '50': '#f4f4f2',
                '100': '#e4e2dd',
                '200': '#cbc7bd',
                '300': '#aca698',
                '400': '#948b7b',
                '500': '#867b6c',
                '600': '#72675c',
                '700': '#5d534b',
                '800': '#504843',
                '900': '#423b38',
                '950': '#272321',
              }
            }
          }
        },
        {
          name: "game",
          extend: {
            colors: {
              primary: {
                '50': '#f7f7f8',
                '100': '#eeeef0',
                '200': '#d9d9de',
                '300': '#b7b7c2',
                '400': '#9090a0',
                '500': '#737484',
                '600': '#676779',
                '700': '#4c4c58',
                '800': '#41414b',
                '900': '#393941',
                '950': '#26262b',
              }
            }
          }
        }
      ]
    }),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    plugin(({ addVariant }) => addVariant("drag-item", [".drag-item&", ".drag-item &"])),
    plugin(({ addVariant }) => addVariant("drag-ghost", [".drag-ghost&", ".drag-ghost &"])),
    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": theme("spacing.5"),
            "height": theme("spacing.5")
          }
        }
      }, { values })
    })
  ]
}
