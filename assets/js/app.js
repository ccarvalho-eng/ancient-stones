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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/ancient_stones"
import topbar from "../vendor/topbar"

const themeStorageKey = "phx:theme"
const themes = new Set(["system", "light", "dark"])
const systemThemeQuery = window.matchMedia("(prefers-color-scheme: dark)")

const systemTheme = () => systemThemeQuery.matches ? "dark" : "light"

const storedTheme = () => {
  try {
    const theme = window.localStorage.getItem(themeStorageKey)
    return themes.has(theme) ? theme : null
  } catch (_error) {
    return null
  }
}

const storeTheme = (theme) => {
  if (!themes.has(theme)) {
    return
  }

  try {
    if (theme === "system") {
      window.localStorage.removeItem(themeStorageKey)
    } else {
      window.localStorage.setItem(themeStorageKey, theme)
    }
  } catch (_error) {
    return
  }
}

const applyDocumentTheme = (theme) => {
  if (theme === "system") {
    document.documentElement.setAttribute("data-theme", systemTheme())
    document.documentElement.setAttribute("data-theme-source", "system")
  } else {
    document.documentElement.setAttribute("data-theme", theme)
    document.documentElement.setAttribute("data-theme-source", "user")
  }
}

const applyTheme = (theme) => {
  if (!themes.has(theme)) {
    return
  }

  applyDocumentTheme(theme)

  document.querySelectorAll(".stone-page").forEach((page) => {
    page.classList.remove("stone-theme-system", "stone-theme-light", "stone-theme-dark")
    page.classList.add(`stone-theme-${theme}`)
    page.setAttribute("data-theme", theme === "dark" ? "dark" : "light")
  })
}

const initialStoredTheme = storedTheme()

if (initialStoredTheme) {
  applyTheme(initialStoredTheme)
}

const Hooks = {
  ...colocatedHooks,
  AncientStonesTheme: {
    mounted() {
      const theme = storedTheme()

      if (theme) {
        this.pushEvent("set_theme", {theme})
      }
    },
  },
}

document.addEventListener("click", (event) => {
  const themeButton =
    event.target instanceof Element
      ? event.target.closest("[data-ancient-stones-theme]")
      : null

  if (!themeButton) {
    return
  }

  const theme = themeButton.dataset.ancientStonesTheme

  storeTheme(theme)
  applyTheme(theme)
})

window.addEventListener("storage", (event) => {
  if (event.key === themeStorageKey) {
    applyTheme(storedTheme() || "system")
  }
})

systemThemeQuery.addEventListener("change", () => {
  if (!storedTheme()) {
    applyTheme("system")
  }
})

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
