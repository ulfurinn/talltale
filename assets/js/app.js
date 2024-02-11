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

import faRegularWoff2 from "@fortawesome/fontawesome-free/webfonts/fa-regular-400.woff2" assert { type: "woff2" };
import faSolidWoff2 from "@fortawesome/fontawesome-free/webfonts/fa-solid-900.woff2" assert { type: "woff2" };
import faRegularTtf from "@fortawesome/fontawesome-free/webfonts/fa-regular-400.ttf" assert { type: "ttf" };
import faSolidTtf from "@fortawesome/fontawesome-free/webfonts/fa-solid-900.ttf" assert { type: "ttf" };
(function () {
  [
    faRegularWoff2,
    faSolidWoff2,
    faRegularTtf,
    faSolidTtf
  ];
})();

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Sortable from "../vendor/sortable"

let hooks = {};
hooks.CheckboxProxy = {
  mounted() {
    this.el.addEventListener("click", e => {
      let checkbox = document.getElementById(this.el.dataset.checkbox);
      if (checkbox) {
        checkbox.checked = !checkbox.checked;
        checkbox.dispatchEvent(new Event("change", { bubbles: true }));
      }
    });
  }
};

hooks.SortableInputsFor = {
  mounted() {
    let group = this.el.dataset.group;
    let sorter = new Sortable(this.el, {
      group: group ? { name: group, pull: true, put: true } : undefined,
      animation: 150,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      handle: "[data-handle]",
      forceFallback: true,
      onEnd: e => {
        this.el.closest("form").querySelector("input").dispatchEvent(new Event("input", { bubbles: true }))
      }
    });
    console.log(sorter);
  }
};

hooks.Deck = {
  mounted() {
    this.el.addEventListener("transitionend", e => {
      this.pushEvent("animation-end", { target: e.target.id });
    })
  }
};

hooks.Card = {
  mounted() {
    const transition = this.el.dataset.transition;
    if (transition) {
      this.liveSocket.execJS(this.el, transition);
    }
  },
  updated() {
    const transition = this.el.dataset.transition;
    if (transition) {
      this.liveSocket.execJS(this.el, transition);
    }
  }
};



let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

