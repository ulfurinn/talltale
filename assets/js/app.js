// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let hooks = {};

hooks.Scene = {
  mounted() {
    this.handleEvent("animate", (e) => {
      let js = this.js();
      let { type, duration, after } = e.transition;

      let start = type + "-start";
      let end = type + "-end";
      let transition = type + "-transition";

      let property;
      if (duration) {
        property = "--" + type + "-duration";
      }

      let el = document.getElementById(e.id);
      if (el) {
        js.addClass(el, [start]);
        if (property) {
          el.style.setProperty(property, duration + "ms");
        }

        el.addEventListener("transitionend", () => {
          js.removeClass(el, [end, transition]);
          js.addClass(el, [after]);
          if (property) {
            el.style.removeProperty(property);
          }
          this.pushEvent("transition-ended", { ref: e.ref });
        }, { once: true });

        window.requestAnimationFrame(() => {
          js.addClass(el, [end, transition]);
          js.removeClass(el, [start]);
        });
      }
    })

    this.handleEvent("snapshot", e => {
      console.log(e);
      localStorage.setItem("snapshot", JSON.stringify(e));
    });

    let snapshot = localStorage.getItem("snapshot");
    if (snapshot) {
      // this.pushEvent("restore", JSON.parse(snapshot));
    } else {
      // this.pushEvent("start", JSON.parse(snapshot));
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: undefined,
  params: { _csrf_token: csrfToken },
  hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
  // Enable server log streaming to client.
  // Disable with reloader.disableServerLogs()
  reloader.enableServerLogs()
  window.liveReloader = reloader
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

