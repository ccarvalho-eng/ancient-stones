import {
  ActiveSelection,
  Canvas,
  Control,
  FabricImage,
  Group,
  IText,
  Path,
  PencilBrush,
  Point,
  Polygon,
  controlsUtils,
  util,
} from "../../vendor/fabric.mjs"
import {mapIconPaths, mapIcons} from "../map_icons"
import {
  filterMapIcons,
  gameIconCatalogUrl,
  normalizeGameIcon,
} from "../game_icon_library.mjs"
import {deleteMapDraft, getMapDraft, putMapDraft} from "../map_draft_store"
import {
  appendDistinctPoint,
  contrastingInk,
  editorCanvasBackground,
  erasableInkTarget,
  gridVisiblePreference,
  insertMidpoint,
  removeVertex,
  roughenCoastline,
  zoomFromPinch,
} from "../map_geometry.mjs"

const serializableProperties = [
  "mapKind",
  "mapLayer",
  "mapIconName",
  "mapIconAuthor",
  "mapItemId",
  "mapEntityType",
  "mapEntityId",
  "mapEntityName",
  "mapX",
  "mapY",
  "mapLocked",
  "mapCoastRoughness",
  "mapLandColor",
  "mapExcludeFromExport",
  "mapReferenceSrc",
]
const defaultMapLayers = [
  {id: "terrain", name: "Terrain", visible: true, locked: false},
  {id: "features", name: "Features", visible: true, locked: false},
  {id: "labels", name: "Labels", visible: true, locked: false},
]
const maxMapLayers = 50
const parchment = "#e7ddc4"
const gridPreferenceKey = "ancient-stones:map-grid-visible"

const textureBrushes = {
  forest: {path: mapIconPaths["pine-tree"], filled: true, spacing: 1.1, jitter: 0.35},
  mountains: {path: mapIconPaths.mountain, filled: true, spacing: 1.45, jitter: 0.15},
  grassland: {path: "M 1 14 Q 3 7 7 3 M 7 14 Q 8 6 8 1 M 9 14 Q 12 7 15 5", spacing: 0.8, jitter: 0.45},
  marsh: {path: "M 1 13 Q 4 10 7 13 T 13 13 M 3 9 L 3 2 M 7 10 L 7 4 M 11 9 L 11 1", spacing: 0.95, jitter: 0.3},
  desert: {path: "M 2 8 A 2 2 0 1 0 6 8 A 2 2 0 1 0 2 8 M 11 3 A 1.5 1.5 0 1 0 14 3 A 1.5 1.5 0 1 0 11 3", filled: true, spacing: 0.75, jitter: 0.65},
  waves: {path: "M 1 8 C 4 3 8 3 11 8 C 14 13 18 13 21 8", spacing: 0.8, orient: true, jitter: 0.08},
  road: {path: "M 1 5 L 21 5", spacing: 0.72, orient: true, jitter: 0},
}

function newItemId() {
  return crypto.randomUUID()
}

const InkMap = {
  mounted() {
    const mapDocument = this.parseDocument()
    this.mapId = this.el.dataset.mapId || null
    this.serverRevision = Number.parseInt(this.el.dataset.mapRevision, 10) || 1
    this.width = Number.parseInt(this.el.dataset.mapWidth, 10) || 1600
    this.height = Number.parseInt(this.el.dataset.mapHeight, 10) || 1000
    this.layers = this.normalizeLayers(mapDocument.mapLayers)
    this.activeLayer = this.layers.some((layer) => layer.id === mapDocument.activeMapLayer)
      ? mapDocument.activeMapLayer
      : this.layers[0].id
    this.history = []
    this.historyIndex = -1
    this.restoring = false
    this.dirty = false
    this.ready = false
    this.saving = false
    this.changeVersion = 0
    this.localDraftVersion = -1
    this.draftTimer = null
    this.autosaveTimer = null
    this.saveTimeout = null
    this.saveRequestId = 0
    this.autosaveBlocked = false
    this.draftQueue = Promise.resolve()
    this.textureTool = null
    this.textureStroke = null
    this.panState = null
    this.landmassDraft = null
    this.catalogIcons = []
    this.catalogIconPaths = new Map()
    this.catalogPathIndexes = new Map()
    this.iconCatalogAbort = new AbortController()
    this.iconSearchTimer = null
    this.themeRoot = this.el.closest(".stone-page")
    this.themeMedia = window.matchMedia("(prefers-color-scheme: dark)")
    this.hasExplicitBackground = mapDocument.mapBackgroundExplicit ?? Boolean(mapDocument.mapBackground)
    this.mapBackground = this.hasExplicitBackground
      ? mapDocument.mapBackground
      : this.defaultCanvasBackground()
    this.inkColor = contrastingInk(this.mapBackground)

    this.canvas = new Canvas(this.el.querySelector("#ink-map-canvas"), {
      width: this.width,
      height: this.height,
      enableRetinaScaling: true,
      preserveObjectStacking: true,
      selection: true,
    })

    this.gridVisible = this.loadGridPreference()
    this.applyCanvasAppearance()
    this.setSnap(false)
    this.setGuides(true)
    this.setZoom(1)
    this.setTool("select")
    this.renderLayerPanel()
    this.renderLayerSelect()
    this.bindCanvasEvents()
    this.bindControls()
    this.bindPinchZoom()
    this.renderIconPicker()
    this.loadIconCatalog()
    this.handleFullscreenChange = () => this.syncFullscreenState()
    document.addEventListener("fullscreenchange", this.handleFullscreenChange)
    this.handleEvent("map_resized", ({width, height}) => this.resizeMap(width, height))
    this.handleEvent("map_reference_uploaded", ({url, opacity}) => {
      this.addReferenceImage(url, opacity)
    })
    this.handleThemeChange = () => this.syncImplicitCanvasTheme()
    this.themeObserver = new MutationObserver(this.handleThemeChange)
    if (this.themeRoot) this.themeObserver.observe(this.themeRoot, {attributes: true, attributeFilter: ["class"]})
    this.themeMedia.addEventListener("change", this.handleThemeChange)
    this.syncBackgroundInput()
    this.syncSaveState()

    this.canvas.loadFromJSON(mapDocument).then(() => {
      this.applyCanvasAppearance()
      this.ensureItemIds()
      this.applyLayerStates()
      this.normalizeLayerOrder()
      this.renderLayerPanel()
      this.renderLayerSelect()
      this.syncInspector()
      this.syncSelectionControls()
      this.canvas.requestRenderAll()
      this.captureHistory()
      this.ready = true
      this.syncSaveState()
      this.setStatus("Map ready")
      this.setSaveStatus("saved", "Map saved")
      void this.restoreLocalDraft()
      requestAnimationFrame(() => this.zoomToFit())
    }).catch(() => {
      this.setStatus("The map document could not be loaded")
    })
  },

  destroyed() {
    if (this.dirty) void this.persistLocalDraft()
    window.clearTimeout(this.draftTimer)
    window.clearTimeout(this.autosaveTimer)
    window.clearTimeout(this.saveTimeout)
    this.el.removeEventListener("click", this.handleClick)
    this.el.removeEventListener("input", this.handleInput)
    this.el.removeEventListener("change", this.handleInput)
    this.el.removeEventListener("dblclick", this.handleLayerDoubleClick)
    this.el.removeEventListener("keydown", this.handleLayerNameKeydown)
    this.el.removeEventListener("focusout", this.handleLayerNameBlur)
    this.el.removeEventListener("dragstart", this.handleLayerDragStart)
    this.el.removeEventListener("dragover", this.handleLayerDragOver)
    this.el.removeEventListener("drop", this.handleLayerDrop)
    this.el.removeEventListener("dragend", this.handleLayerDragEnd)
    document.removeEventListener("fullscreenchange", this.handleFullscreenChange)
    document.removeEventListener("click", this.handleLayerMenuClickAway)
    this.themeObserver.disconnect()
    this.themeMedia.removeEventListener("change", this.handleThemeChange)
    document.removeEventListener("click", this.handleNavigation, true)
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
    window.removeEventListener("beforeunload", this.handleBeforeUnload)
    window.removeEventListener("keydown", this.handleKeydown)
    this.pinchTarget.removeEventListener("touchstart", this.handleTouchStart)
    this.pinchTarget.removeEventListener("touchmove", this.handleTouchMove)
    this.pinchTarget.removeEventListener("touchend", this.handleTouchEnd)
    this.pinchTarget.removeEventListener("touchcancel", this.handleTouchEnd)
    this.pinchTarget.removeEventListener("wheel", this.handlePinchWheel)
    window.clearTimeout(this.iconSearchTimer)
    this.iconCatalogAbort.abort()
    this.canvas.dispose()
  },

  disconnected() {
    this.saving = false
    this.saveRequestId += 1
    window.clearTimeout(this.saveTimeout)
    window.clearTimeout(this.autosaveTimer)
    this.autosaveTimer = null
    if (this.dirty) {
      void this.persistLocalDraft()
      this.setSaveStatus("local", "Offline, saved locally")
      this.setStatus("Connection lost. Your current changes are protected on this device.")
    }
    this.syncSaveState()
  },

  reconnected() {
    if (this.dirty) this.scheduleAutosave(1000)
  },

  parseDocument() {
    try {
      const document = JSON.parse(this.el.dataset.mapDocument || "{}")
      return Array.isArray(document.objects) ? document : {objects: []}
    } catch (_error) {
      return {objects: []}
    }
  },

  async restoreLocalDraft() {
    if (!this.mapId) return

    try {
      const draft = await getMapDraft(this.mapId)
      if (!draft?.document || !Array.isArray(draft.document.objects)) return

      const serverDocument = this.parseDocument()
      const sameDocument = JSON.stringify(draft.document) === JSON.stringify(serverDocument)
      const sameSize = draft.width === this.width && draft.height === this.height

      if (sameDocument && sameSize) {
        await this.clearLocalDraft()
        return
      }

      const conflicts = draft.baseRevision !== this.serverRevision
      const prompt = conflicts
        ? "A local recovery draft and the server map both changed. Restore the local draft? Saving it will replace the current server map."
        : "Unsaved map changes were recovered from this device. Restore them?"

      if (!window.confirm(prompt)) {
        await this.clearLocalDraft()
        this.setStatus("Server map kept. The local recovery draft was discarded.")
        return
      }

      this.restoreLocalDraftDocument(draft)
    } catch (_error) {
      this.setSaveStatus("error", "Local recovery unavailable")
      this.setStatus("Local draft storage is unavailable. Manual and server saves still work.")
    }
  },

  restoreLocalDraftDocument(draft) {
    this.restoring = true
    this.width = Number.parseInt(draft.width, 10) || this.width
    this.height = Number.parseInt(draft.height, 10) || this.height
    this.layers = this.normalizeLayers(draft.document.mapLayers)
    this.activeLayer = this.layers.some((layer) => layer.id === draft.document.activeMapLayer)
      ? draft.document.activeMapLayer
      : this.layers[0].id
    this.hasExplicitBackground =
      draft.document.mapBackgroundExplicit ?? Boolean(draft.document.mapBackground)
    this.mapBackground = this.hasExplicitBackground
      ? draft.document.mapBackground
      : this.defaultCanvasBackground()
    this.inkColor = contrastingInk(this.mapBackground)
    this.canvas.setDimensions({width: this.width, height: this.height})
    this.applyCanvasAppearance()
    this.syncBackgroundInput()
    this.renderLayerPanel()
    this.renderLayerSelect()

    this.canvas.loadFromJSON(draft.document).then(() => {
      this.applyCanvasAppearance()
      this.ensureItemIds()
      this.applyLayerStates()
      this.normalizeLayerOrder()
      this.renderLayerPanel()
      this.renderLayerSelect()
      this.syncInspector()
      this.syncSelectionControls()
      this.setZoom(this.zoom)
      this.canvas.requestRenderAll()
      this.history = []
      this.historyIndex = -1
      this.captureHistory()
      this.restoring = false
      this.autosaveBlocked = false
      this.markDirty("Local draft restored")
    }).catch(() => {
      this.restoring = false
      this.setSaveStatus("error", "Recovery failed")
      this.setStatus("The local recovery draft could not be loaded.")
    })
  },

  bindCanvasEvents() {
    this.canvas.on("object:added", ({target}) => {
      queueMicrotask(() => {
        if (!this.ready || this.restoring || !target?.mapLayer) return

        this.normalizeLayerOrder()
        this.renderLayerPanel()
        this.canvas.requestRenderAll()
      })
    })
    this.canvas.on("object:removed", () => {
      queueMicrotask(() => {
        if (!this.ready || this.restoring) return

        this.renderLayerPanel()
      })
    })
    this.canvas.on("path:created", ({path}) => {
      path.set({mapKind: "ink", mapLayer: this.activeLayer, mapItemId: newItemId()})
      this.changed("Stroke added")
    })
    this.canvas.on("mouse:down", (event) => {
      if (this.eraserTool) {
        this.erasingInk = true
        this.eraseInkAt(event)
        return
      }

      if (this.landmassTool) this.addLandmassPoint(event)
      else {
        this.startTextureStroke(event)
        this.startPan(event)
      }
    })
    this.canvas.on("mouse:move", (event) => {
      if (this.eraserTool && this.erasingInk) {
        this.eraseInkAt(event)
        return
      }

      if (this.landmassTool) this.previewLandmass(event)
      else {
        this.continueTextureStroke(event)
        this.continuePan(event)
      }
    })
    this.canvas.on("mouse:up", () => {
      this.finishTextureStroke()
      this.finishPan()
    })
    this.canvas.on("object:moving", ({target}) => {
      const guideSnap = this.snapToCenterGuides(target)
      this.snapObject(target, guideSnap)
      this.showCoordinates(target)
    })
    this.canvas.on("object:modified", ({target}) => {
      this.highlightCenterGuides(false, false)
      this.showCoordinates(target)
      this.changed("Object updated")
    })
    this.canvas.on("text:changed", () => this.markDirty("Label updated"))
    this.canvas.on("editing:exited", () => this.changed("Label updated"))
    this.canvas.on("selection:created", ({selected}) => {
      this.showCoordinates(selected?.[0])
      this.syncEntityLink(selected?.[0])
      this.syncSelectionControls()
      this.setStatus("Object selected")
    })
    this.canvas.on("selection:updated", ({selected}) => {
      this.showCoordinates(selected?.[0])
      this.syncEntityLink(selected?.[0])
      this.syncSelectionControls()
      this.setStatus("Object selected")
    })
    this.canvas.on("selection:cleared", () => {
      this.showCoordinates()
      this.syncEntityLink()
      this.syncSelectionControls()
    })
    this.canvas.on("mouse:up", () => this.finishInkErasing())
    this.canvas.on("mouse:dblclick", ({target}) => {
      if (target?.mapKind === "landmass") this.toggleLandmassEditing(target)
    })
  },

  eraseInkAt(event) {
    const target = erasableInkTarget(event.target)
    if (!target) return

    this.canvas.discardActiveObject()
    this.canvas.remove(target)
    this.erasedInk = true
    this.canvas.requestRenderAll()
  },

  finishInkErasing() {
    if (!this.erasingInk) return

    this.erasingInk = false
    if (!this.erasedInk) return

    this.erasedInk = false
    this.changed("Ink erased")
  },

  bindControls() {
    this.handleClick = (event) => {
      const dialog = this.el.querySelector("[data-map-icon-dialog]")
      if (event.target === dialog) {
        dialog.close()
        return
      }

      const control = event.target.closest("[data-map-tool], [data-map-asset], [data-map-action], [data-map-layer], [data-map-layer-action], [data-map-layer-menu-trigger], [data-map-layer-row]")

      if (!control || !this.el.contains(control)) return
      if (!this.ready) return

      if (control.dataset.mapTool) this.setTool(control.dataset.mapTool)
      else if (control.dataset.mapAsset) this.addStamp(control.dataset.mapAsset)
      else if (control.dataset.mapLayerAction) {
        control.closest("[data-map-layer-menu]")?.removeAttribute("open")
        this.runLayerAction(control.dataset.mapLayerAction, control.dataset.mapLayerId)
      }
      else if (control.hasAttribute("data-map-layer-menu-trigger")) return
      else if (control.dataset.mapLayer) this.setLayer(control.dataset.mapLayer)
      else if (control.dataset.mapLayerRow) this.setLayer(control.dataset.mapLayerRow)
      else this.runAction(control.dataset.mapAction)
    }

    this.handleLayerMenuClickAway = (event) => {
      this.el.querySelectorAll("[data-map-layer-menu][open]").forEach((menu) => {
        if (!menu.contains(event.target)) menu.removeAttribute("open")
      })
    }

    this.handleLayerDoubleClick = (event) => {
      const name = event.target.closest("[data-map-layer-name-display]")
      const row = name?.closest("[data-map-layer-row]")
      if (row) this.startLayerRename(row.dataset.mapLayerRow)
    }

    this.handleLayerNameKeydown = (event) => {
      if (!event.target.matches("[data-map-layer-name]")) return

      if (event.key === "Enter") {
        event.preventDefault()
        event.target.blur()
      } else if (event.key === "Escape") {
        event.target.dataset.cancelLayerRename = "true"
        this.renderLayerPanel()
      }
    }

    this.handleLayerNameBlur = (event) => {
      if (!event.target.matches("[data-map-layer-name]")) return
      if (event.target.dataset.cancelLayerRename) return

      this.renameLayer(event.target.dataset.mapLayerId, event.target.value)
    }

    this.handleLayerDragStart = (event) => {
      const handle = event.target.closest("[data-map-layer-drag]")
      const row = handle?.closest("[data-map-layer-row]")
      if (!row) return

      this.draggedLayerId = row.dataset.mapLayerRow
      event.dataTransfer.effectAllowed = "move"
      event.dataTransfer.setData("text/plain", this.draggedLayerId)
      row.classList.add("opacity-50")
    }

    this.handleLayerDragOver = (event) => {
      const row = event.target.closest("[data-map-layer-row]")
      if (!row || !this.draggedLayerId || row.dataset.mapLayerRow === this.draggedLayerId) return

      event.preventDefault()
      this.clearLayerDropTargets()
      row.classList.add("ring-1", "ring-zinc-400")
      event.dataTransfer.dropEffect = "move"
    }

    this.handleLayerDrop = (event) => {
      const row = event.target.closest("[data-map-layer-row]")
      if (!row || !this.draggedLayerId || row.dataset.mapLayerRow === this.draggedLayerId) return

      event.preventDefault()
      const bounds = row.getBoundingClientRect()
      this.reorderLayerFromDrop(
        this.draggedLayerId,
        row.dataset.mapLayerRow,
        event.clientY < bounds.top + bounds.height / 2,
      )
      this.finishLayerDrag()
    }

    this.handleLayerDragEnd = () => this.finishLayerDrag()

    this.handleInput = (event) => {
      if (event.target.matches("[data-map-brush-size]") && this.canvas.freeDrawingBrush) {
        this.canvas.freeDrawingBrush.width = Number.parseInt(event.target.value, 10)
      } else if (event.target.matches("[data-map-zoom]")) {
        this.setZoom(Number.parseInt(event.target.value, 10) / 100)
      } else if (event.target.matches("[data-map-icon-search], [data-map-icon-category]")) {
        if (event.target.matches("[data-map-icon-category]")) {
          event.target.dataset.mapCategoryChosen = "true"
          this.renderIconPicker()
        } else {
          window.clearTimeout(this.iconSearchTimer)
          this.iconSearchTimer = window.setTimeout(() => this.renderIconPicker(), 120)
        }
      } else if (event.target.matches("[data-map-water-color], [data-map-export-background]")) {
        this.setMapBackground(event.target.value)
      } else if (event.target.matches("[data-map-selected-layer]") && event.type === "change") {
        this.setSelectionLayer(event.target.value)
      } else if (event.target.matches("[data-map-copy-layer]") && event.type === "change") {
        this.copySelectionToLayer(event.target.value)
        event.target.value = ""
      } else if (event.target.matches("[data-map-entity-link]")) {
        this.linkSelection(event.target)
      } else if (event.target.matches("[data-map-property]")) {
        this.updateSelectedProperty(event.target, event.type === "change")
      }
    }

    this.handleKeydown = (event) => {
      const activeObject = this.canvas.getActiveObject()

      if (
        event.target instanceof HTMLInputElement ||
        event.target instanceof HTMLTextAreaElement ||
        event.target instanceof HTMLSelectElement ||
        activeObject?.isEditing
      ) return

      const command = event.metaKey || event.ctrlKey

      if (this.landmassDraft && event.key === "Enter") {
        event.preventDefault()
        this.finishLandmass()
      } else if (this.landmassDraft && event.key === "Escape") {
        event.preventDefault()
        this.cancelLandmass()
      } else if (this.landmassDraft && event.key === "Backspace") {
        event.preventDefault()
        this.undoLandmassPoint()
      } else if (command && event.key.toLowerCase() === "s") {
        event.preventDefault()
        this.save()
      } else if (command && event.key.toLowerCase() === "z" && event.shiftKey) {
        event.preventDefault()
        this.redo()
      } else if (command && event.key.toLowerCase() === "z") {
        event.preventDefault()
        this.undo()
      } else if (command && event.key.toLowerCase() === "d") {
        event.preventDefault()
        this.duplicateSelection()
      } else if (event.key === "Delete" || event.key === "Backspace") {
        event.preventDefault()
        this.deleteSelection()
      } else if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(event.key)) {
        event.preventDefault()
        this.nudgeSelection(event.key, event.shiftKey ? 10 : 1)
      }
    }

    this.el.addEventListener("click", this.handleClick)
    this.el.addEventListener("input", this.handleInput)
    this.el.addEventListener("change", this.handleInput)
    this.el.addEventListener("dblclick", this.handleLayerDoubleClick)
    this.el.addEventListener("keydown", this.handleLayerNameKeydown)
    this.el.addEventListener("focusout", this.handleLayerNameBlur)
    this.el.addEventListener("dragstart", this.handleLayerDragStart)
    this.el.addEventListener("dragover", this.handleLayerDragOver)
    this.el.addEventListener("drop", this.handleLayerDrop)
    this.el.addEventListener("dragend", this.handleLayerDragEnd)
    window.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("click", this.handleLayerMenuClickAway)

    this.handleBeforeUnload = (event) => {
      if (!this.dirty) return

      event.preventDefault()
      event.returnValue = ""
    }

    this.handleNavigation = (event) => {
      if (!this.dirty || !event.target.closest("a[href], #map-new")) return
      if (window.confirm("Discard your unsaved map changes?")) return

      event.preventDefault()
      event.stopImmediatePropagation()
    }

    window.addEventListener("beforeunload", this.handleBeforeUnload)
    document.addEventListener("click", this.handleNavigation, true)
    this.handleVisibilityChange = () => {
      if (document.visibilityState === "hidden" && this.dirty) void this.persistLocalDraft()
    }
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  },

  bindPinchZoom() {
    this.pinchTarget = this.canvas.upperCanvasEl
    this.pinchState = null

    this.handleTouchStart = (event) => {
      if (event.touches.length !== 2) return

      event.preventDefault()
      const first = event.touches[0]
      const second = event.touches[1]
      this.pinchState = {
        distance: Math.hypot(second.clientX - first.clientX, second.clientY - first.clientY),
        zoom: this.zoom,
      }
    }

    this.handleTouchMove = (event) => {
      if (!this.pinchState || event.touches.length !== 2) return

      event.preventDefault()
      const first = event.touches[0]
      const second = event.touches[1]
      const distance = Math.hypot(second.clientX - first.clientX, second.clientY - first.clientY)
      const centerX = (first.clientX + second.clientX) / 2
      const centerY = (first.clientY + second.clientY) / 2
      const zoom = zoomFromPinch(this.pinchState.zoom, this.pinchState.distance, distance)

      this.setZoomAt(zoom, centerX, centerY)
    }

    this.handleTouchEnd = (event) => {
      if (event.touches.length < 2) this.pinchState = null
    }

    this.handlePinchWheel = (event) => {
      if (!event.ctrlKey) return

      event.preventDefault()
      this.setZoomAt(this.zoom * Math.exp(-event.deltaY * 0.01), event.clientX, event.clientY)
    }

    this.pinchTarget.addEventListener("touchstart", this.handleTouchStart, {passive: false})
    this.pinchTarget.addEventListener("touchmove", this.handleTouchMove, {passive: false})
    this.pinchTarget.addEventListener("touchend", this.handleTouchEnd)
    this.pinchTarget.addEventListener("touchcancel", this.handleTouchEnd)
    this.pinchTarget.addEventListener("wheel", this.handlePinchWheel, {passive: false})
  },

  setTool(tool) {
    if (this.eraserTool && tool !== "eraser") this.finishInkErasing()

    const drawing = tool === "ink"
    const erasing = tool === "eraser"
    const panning = tool === "pan"
    const landmass = tool === "landmass"
    const texture = tool.startsWith("texture-") ? tool.replace("texture-", "") : null
    if (!landmass && this.landmassDraft) this.cancelLandmass()
    this.canvas.isDrawingMode = drawing
    this.canvas.selection = !drawing && !erasing && !texture && !panning && !landmass
    this.canvas.skipTargetFind = Boolean(texture) || panning || landmass
    this.canvas.defaultCursor = panning ? "grab" : landmass || erasing ? "crosshair" : "default"
    this.canvas.hoverCursor = panning ? "grab" : landmass || erasing ? "crosshair" : "move"
    this.canvas.targetFindTolerance = erasing ? 10 : 0
    this.textureTool = textureBrushes[texture] ? texture : null
    this.landmassTool = landmass
    this.eraserTool = erasing

    if (drawing) {
      const brush = new PencilBrush(this.canvas)
      brush.color = this.inkColor
      brush.width = Number.parseInt(this.el.querySelector("[data-map-brush-size]").value, 10)
      brush.decimate = 1.5
      brush.limitedToCanvasSize = true
      this.canvas.freeDrawingBrush = brush
    }

    this.el.querySelectorAll("[data-map-tool]").forEach((button) => {
      button.classList.toggle("stone-selected", button.dataset.mapTool === tool)
    })

    if (this.textureTool || landmass) this.setLayer("terrain")

    const toolName = this.textureTool
      ? `${this.textureTool[0].toUpperCase()}${this.textureTool.slice(1)} texture active`
      : erasing
        ? "Eraser active: drag across pencil strokes"
        : drawing
        ? "Ink tool active"
        : panning
          ? "Pan tool active"
          : landmass
            ? "Landmass tool active. Click coastline points and press Enter to finish."
            : "Select tool active"

    this.setStatus(toolName)
  },

  startTextureStroke(event) {
    if (!this.textureTool || this.textureStroke) return

    const point = event.scenePoint || this.canvas.getScenePoint(event.e)
    this.textureStroke = {objects: [], lastPoint: point, remainder: 0}
    this.addTextureStamp(point, 0)
  },

  continueTextureStroke(event) {
    if (!this.textureTool || !this.textureStroke) return

    const point = event.scenePoint || this.canvas.getScenePoint(event.e)
    const previous = this.textureStroke.lastPoint
    const dx = point.x - previous.x
    const dy = point.y - previous.y
    const distance = Math.hypot(dx, dy)
    if (distance === 0) return

    const spacing = this.textureSpacing()
    const angle = Math.atan2(dy, dx) * 180 / Math.PI
    let offset = spacing - this.textureStroke.remainder

    while (offset <= distance && this.textureStroke.objects.length < 250) {
      const ratio = offset / distance
      this.addTextureStamp(
        {x: previous.x + dx * ratio, y: previous.y + dy * ratio},
        angle,
      )
      offset += spacing
    }

    this.textureStroke.remainder = (this.textureStroke.remainder + distance) % spacing
    this.textureStroke.lastPoint = point
    this.canvas.requestRenderAll()
  },

  finishTextureStroke() {
    if (!this.textureStroke) return

    const objects = this.textureStroke.objects
    this.textureStroke = null
    if (objects.length === 0) return

    objects.forEach((object) => this.canvas.remove(object))

    const group = new Group(objects, {
      mapKind: `texture-${this.textureTool}`,
      mapLayer: this.activeLayer,
      mapIconName: `${this.textureTool} texture`,
      mapItemId: newItemId(),
    })

    this.canvas.add(group)
    this.canvas.setActiveObject(group)
    this.canvas.requestRenderAll()
    this.changed(`${this.textureTool} texture added`)
  },

  addTextureStamp(point, direction) {
    const texture = textureBrushes[this.textureTool]
    const size = this.textureSize()
    const variation = 1 + (Math.random() - 0.5) * texture.jitter
    const stamp = new Path(texture.path, {
      left: point.x,
      top: point.y,
      originX: "center",
      originY: "center",
      fill: texture.filled ? this.inkColor : "rgba(255, 255, 255, 0)",
      stroke: texture.filled ? undefined : this.inkColor,
      strokeWidth: texture.filled ? 0 : 1.5,
      angle: texture.orient ? direction : (Math.random() - 0.5) * 16,
      selectable: false,
      evented: false,
    })

    stamp.scale(size * variation / Math.max(stamp.width, stamp.height))
    this.textureStroke.objects.push(stamp)
    this.canvas.add(stamp)
  },

  textureSize() {
    const brushSize = Number.parseInt(this.el.querySelector("[data-map-brush-size]").value, 10)
    return Math.max(14, brushSize * 6)
  },

  textureSpacing() {
    const texture = textureBrushes[this.textureTool]
    const density = Number.parseInt(this.el.querySelector("[data-map-brush-density]").value, 10)
    return this.textureSize() * texture.spacing * (1.35 - density * 0.13)
  },

  addLandmassPoint(event) {
    if (event.e.button !== 0) return

    const point = event.scenePoint || this.canvas.getScenePoint(event.e)
    if (!this.landmassDraft) this.landmassDraft = {points: [], preview: point, object: null}

    const points = appendDistinctPoint(this.landmassDraft.points, point)

    if (points === this.landmassDraft.points) {
      this.setStatus("Move farther before adding another coastline point")
      return
    }

    this.landmassDraft.points = points
    this.landmassDraft.preview = point
    this.renderLandmassDraft()
    this.setStatus(
      `${this.landmassDraft.points.length} coastline points. Press Enter after at least 3.`,
    )
  },

  previewLandmass(event) {
    if (!this.landmassDraft) return

    this.landmassDraft.preview = event.scenePoint || this.canvas.getScenePoint(event.e)
    this.renderLandmassDraft()
  },

  renderLandmassDraft() {
    const draft = this.landmassDraft
    if (!draft) return
    if (draft.object) this.canvas.remove(draft.object)

    const points = [...draft.points, draft.preview].map(({x, y}) => ({x, y}))
    draft.object = new Polygon(points, {
      fill: this.landColor(),
      stroke: this.inkColor,
      strokeWidth: 2,
      opacity: 0.72,
      selectable: false,
      evented: false,
      objectCaching: false,
    })

    this.canvas.add(draft.object)
    this.canvas.sendObjectToBack(draft.object)
    this.canvas.requestRenderAll()
  },

  finishLandmass() {
    const draft = this.landmassDraft
    if (!draft || draft.points.length < 3) {
      this.setStatus("Add at least 3 coastline points")
      return
    }

    if (draft.object) this.canvas.remove(draft.object)
    const roughness = this.coastRoughness()
    const landColor = this.landColor()
    const polygon = new Polygon(this.roughenCoastline(draft.points, roughness), {
      fill: landColor,
      stroke: this.inkColor,
      strokeWidth: 2,
      mapKind: "landmass",
      mapLayer: "terrain",
      mapIconName: "Landmass",
      mapItemId: newItemId(),
      mapCoastRoughness: roughness,
      mapLandColor: landColor,
      objectCaching: false,
    })

    this.landmassDraft = null
    this.canvas.add(polygon)
    this.canvas.sendObjectToBack(polygon)
    this.canvas.setActiveObject(polygon)
    this.canvas.requestRenderAll()
    this.setTool("select")
    this.changed("Landmass added")
  },

  cancelLandmass() {
    if (this.landmassDraft?.object) this.canvas.remove(this.landmassDraft.object)
    this.landmassDraft = null
    this.canvas.requestRenderAll()
    this.setStatus("Landmass cancelled")
  },

  undoLandmassPoint() {
    if (!this.landmassDraft) return

    this.landmassDraft.points.pop()
    if (this.landmassDraft.points.length === 0) this.cancelLandmass()
    else this.renderLandmassDraft()
  },

  roughenCoastline(points, roughness) {
    return roughenCoastline(points, roughness)
  },

  coastRoughness() {
    return Number.parseInt(this.el.querySelector("[data-map-coast-roughness]")?.value, 10) || 0
  },

  landColor() {
    return this.el.querySelector("[data-map-land-color]")?.value || "#c8b88f"
  },

  setMapBackground(color) {
    this.hasExplicitBackground = true
    this.mapBackground = color
    this.inkColor = contrastingInk(color)
    this.applyCanvasAppearance()
    this.syncBackgroundInput()
    this.changed("Background color updated")
  },

  toggleLandmassEditing(object = this.canvas.getActiveObject()) {
    if (!object || object.mapKind !== "landmass" || object.mapLocked) {
      this.setStatus("Select a landmass to edit its coastline")
      return
    }

    object.mapEditing = !object.mapEditing
    object.controls = object.mapEditing
      ? this.createLandmassControls(object)
      : controlsUtils.createObjectDefaultControls()
    object.set({cornerColor: "#92400e", cornerStyle: "circle", transparentCorners: false})
    object.setCoords()
    this.canvas.setActiveObject(object)
    this.canvas.requestRenderAll()
    this.setStatus(
      object.mapEditing
        ? "Click midpoint handles to add points. Alt/Option-click a vertex to remove it."
        : "Coastline editing finished",
    )
  },

  createLandmassControls(object) {
    const controls = controlsUtils.createPolyControls(object)

    object.points.forEach((_point, index) => {
      const vertexControl = controls[`p${index}`]
      const originalMouseUp = vertexControl.mouseUpHandler

      vertexControl.mouseUpHandler = (eventData, transform, ...args) => {
        if (eventData.e?.altKey) {
          this.removeLandmassVertex(transform.target, index)
          return true
        }

        return originalMouseUp?.(eventData, transform, ...args) || false
      }

      controls[`m${index}`] = new Control({
        cursorStyle: "copy",
        sizeX: 8,
        sizeY: 8,
        positionHandler: (_dimensions, _matrix, target) => {
          const point = target.points[index]
          const next = target.points[(index + 1) % target.points.length]
          const midpoint = new Point((point.x + next.x) / 2, (point.y + next.y) / 2)
          const localPoint = midpoint.subtract(target.pathOffset)
          const matrix = util.multiplyTransformMatrices(
            target.canvas.viewportTransform,
            target.calcTransformMatrix(),
          )

          return localPoint.transform(matrix)
        },
        mouseUpHandler: (_eventData, transform) => {
          this.insertLandmassVertex(transform.target, index)
          return true
        },
      })
    })

    return controls
  },

  insertLandmassVertex(object, edgeIndex) {
    object.points = insertMidpoint(object.points, edgeIndex)
    object.controls = this.createLandmassControls(object)
    object.dirty = true
    object.setCoords()
    this.canvas.requestRenderAll()
    this.changed("Coastline point added")
  },

  removeLandmassVertex(object, vertexIndex) {
    const points = removeVertex(object.points, vertexIndex)

    if (points === object.points) {
      this.setStatus("A landmass must keep at least 3 coastline points")
      return
    }

    const center = object.getCenterPoint()
    object.points = points
    object.setDimensions()
    object.setPositionByOrigin(center, "center", "center")
    object.controls = this.createLandmassControls(object)
    object.dirty = true
    object.setCoords()
    this.canvas.requestRenderAll()
    this.changed("Coastline point removed")
  },

  addReferenceImage(url, opacity) {
    FabricImage.fromURL(url).then((image) => {
      const scale = Math.min(
        (this.width * 0.8) / image.width,
        (this.height * 0.8) / image.height,
        1,
      )

      image.set({
        left: this.width / 2,
        top: this.height / 2,
        originX: "center",
        originY: "center",
        opacity: Math.min(1, Math.max(0.1, Number(opacity) || 0.45)),
        scaleX: scale,
        scaleY: scale,
        mapKind: "reference-image",
        mapLayer: "terrain",
        mapIconName: "Reference image",
        mapItemId: newItemId(),
        mapExcludeFromExport: true,
        mapReferenceSrc: url,
      })

      this.canvas.add(image)
      this.canvas.sendObjectToBack(image)
      this.canvas.setActiveObject(image)
      this.canvas.requestRenderAll()
      this.setLayer("terrain")
      this.changed("Reference image added")
    }).catch(() => this.setStatus("The reference image could not be loaded"))
  },

  startPan(event) {
    if (this.canvas.defaultCursor !== "grab") return

    const scroller = this.el.querySelector("#ink-map-stage")?.parentElement
    if (!scroller) return

    this.panState = {
      x: event.e.clientX,
      y: event.e.clientY,
      left: scroller.scrollLeft,
      top: scroller.scrollTop,
      scroller,
    }
    this.canvas.defaultCursor = "grabbing"
  },

  continuePan(event) {
    if (!this.panState) return

    this.panState.scroller.scrollLeft = this.panState.left - (event.e.clientX - this.panState.x)
    this.panState.scroller.scrollTop = this.panState.top - (event.e.clientY - this.panState.y)
  },

  finishPan() {
    if (!this.panState) return

    this.panState = null
    this.canvas.defaultCursor = "grab"
  },

  setLayer(layer) {
    const selectedLayer = this.layers.find((candidate) => candidate.id === layer)
    if (!selectedLayer) return

    if (selectedLayer.locked) {
      this.setStatus(`${selectedLayer.name} is locked`)
      return
    }

    if (!selectedLayer.visible) this.toggleLayerVisibility(layer)

    this.activeLayer = layer
    this.renderLayerPanel()
    this.setStatus(`${selectedLayer.name} layer active`)
  },

  setSelectionLayer(layer) {
    const selectedLayer = this.layers.find((candidate) => candidate.id === layer)
    if (!selectedLayer) return

    const selected = this.canvas.getActiveObjects()
    if (selected.length === 0) return

    selected.forEach((object) => this.applyObjectLayer(object, layer))
    this.applyLayerStates()
    this.normalizeLayerOrder()
    if (!selectedLayer.locked) this.activeLayer = layer
    if (!selectedLayer.visible || selectedLayer.locked) this.canvas.discardActiveObject()
    this.renderLayerPanel()
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed(`Selection moved to ${selectedLayer.name}`)
  },

  applyObjectLayer(object, layer) {
    object.set({mapLayer: layer})

    if (object instanceof Group) {
      object.getObjects().forEach((child) => this.applyObjectLayer(child, layer))
    }
  },

  normalizeLayerOrder() {
    const layerOrder = new Map(this.layers.map((layer, index) => [layer.id, index]))
    const ordered = this.canvas
      .getObjects()
      .map((object, index) => ({object, index}))
      .sort((left, right) => {
        const leftLayer = layerOrder.get(left.object.mapLayer) ?? this.layers.length
        const rightLayer = layerOrder.get(right.object.mapLayer) ?? this.layers.length

        return leftLayer - rightLayer || left.index - right.index
      })

    ordered.forEach(({object}, index) => this.canvas.moveObjectTo(object, index))
  },

  normalizeLayers(layers) {
    if (!Array.isArray(layers) || layers.length === 0) {
      return defaultMapLayers.map((layer) => ({...layer}))
    }

    const ids = new Set()
    const normalized = layers.flatMap((layer) => {
      const id = typeof layer?.id === "string" ? layer.id : ""
      const name = typeof layer?.name === "string" ? layer.name.trim().slice(0, 80) : ""
      if (!id || !name || ids.has(id)) return []

      ids.add(id)
      return [{
        id,
        name,
        visible: layer.visible !== false,
        locked: layer.locked === true,
      }]
    })

    return normalized.length > 0
      ? normalized.slice(0, maxMapLayers)
      : defaultMapLayers.map((layer) => ({...layer}))
  },

  applyLayerStates() {
    const layers = new Map(this.layers.map((layer) => [layer.id, layer]))

    this.canvas.getObjects().forEach((object) => {
      const layer = layers.get(object.mapLayer) || layers.get("features") || this.layers[0]
      if (!layers.has(object.mapLayer)) this.applyObjectLayer(object, layer.id)

      object.set({
        visible: layer.visible,
        selectable: !layer.locked,
        evented: !layer.locked,
      })
    })
  },

  renderLayerPanel() {
    const list = this.el.querySelector("[data-map-layer-list]")
    const template = this.el.querySelector("#map-layer-row-template")
    if (!list || !template) return

    list.replaceChildren()
    const counts = new Map(this.layers.map((layer) => [layer.id, 0]))
    this.canvas.getObjects().forEach((object) => {
      counts.set(object.mapLayer, (counts.get(object.mapLayer) || 0) + 1)
    })

    const displayLayers = [...this.layers].reverse()
    displayLayers.forEach((layer) => {
      const index = this.layers.findIndex((candidate) => candidate.id === layer.id)
      const row = template.content.firstElementChild.cloneNode(true)
      row.dataset.mapLayerRow = layer.id
      row.classList.toggle("stone-selected", layer.id === this.activeLayer)

      const active = row.querySelector("[data-map-layer-active]")
      active.classList.toggle("opacity-100", layer.id === this.activeLayer)
      active.classList.toggle("opacity-0", layer.id !== this.activeLayer)
      row.querySelector("[data-map-layer-name-display]").textContent = layer.name
      const nameInput = row.querySelector("[data-map-layer-name]")
      nameInput.value = layer.name
      nameInput.dataset.mapLayerId = layer.id
      row.querySelector("[data-map-layer-count]").textContent = String(counts.get(layer.id) || 0)
      row.querySelector("[data-map-layer-menu-name]").textContent = layer.name
      row.querySelector("[data-map-layer-menu-trigger]").setAttribute(
        "aria-label",
        `${layer.name} layer actions`,
      )

      const visibility = row.querySelector("[data-map-layer-action='visibility']")
      const lock = row.querySelector("[data-map-layer-action='lock']")
      row.querySelector("[data-map-layer-visible-icon]").classList.toggle("hidden", !layer.visible)
      row.querySelector("[data-map-layer-hidden-icon]").classList.toggle("hidden", layer.visible)
      row.querySelector("[data-map-layer-unlocked-icon]").classList.toggle("hidden", layer.locked)
      row.querySelector("[data-map-layer-locked-icon]").classList.toggle("hidden", !layer.locked)
      visibility.setAttribute("aria-label", `${layer.visible ? "Hide" : "Show"} ${layer.name}`)
      lock.setAttribute("aria-label", `${layer.locked ? "Unlock" : "Lock"} ${layer.name}`)

      row.querySelectorAll("[data-map-layer-action]").forEach((button) => {
        button.dataset.mapLayerId = layer.id
      })
      row.querySelector("[data-map-layer-action='merge-down']").disabled = index === 0
      row.querySelector("[data-map-layer-action='delete']").disabled = this.layers.length === 1
      list.append(row)
    })
  },

  startLayerRename(layerId) {
    const row = this.el.querySelector(`[data-map-layer-row='${layerId}']`)
    if (!row) return

    const display = row.querySelector("[data-map-layer-name-display]")
    const input = row.querySelector("[data-map-layer-name]")
    display.classList.add("hidden")
    input.classList.remove("hidden")
    input.focus()
    input.select()
  },

  clearLayerDropTargets() {
    this.el.querySelectorAll("[data-map-layer-row]").forEach((row) => {
      row.classList.remove("ring-1", "ring-zinc-400", "opacity-50")
    })
  },

  finishLayerDrag() {
    this.draggedLayerId = null
    this.clearLayerDropTargets()
  },

  reorderLayerFromDrop(sourceId, targetId, beforeTarget) {
    const visualIds = [...this.el.querySelectorAll("[data-map-layer-row]")]
      .map((row) => row.dataset.mapLayerRow)
      .filter((id) => id !== sourceId)
    const targetIndex = visualIds.indexOf(targetId)
    if (targetIndex < 0) return

    visualIds.splice(targetIndex + (beforeTarget ? 0 : 1), 0, sourceId)
    const layers = new Map(this.layers.map((layer) => [layer.id, layer]))
    this.layers = visualIds.reverse().map((id) => layers.get(id))
    this.normalizeLayerOrder()
    this.renderLayerPanel()
    this.canvas.requestRenderAll()
    this.changed("Layers reordered")
  },

  renderLayerSelect() {
    const selects = [
      {element: this.el.querySelector("[data-map-selected-layer]"), placeholder: "No selection"},
      {element: this.el.querySelector("[data-map-copy-layer]"), placeholder: "Choose destination"},
    ]
    const displayLayers = [...this.layers].reverse()
    selects.forEach(({element, placeholder: label}) => {
      if (!element) return

      element.replaceChildren()
      const placeholder = document.createElement("option")
      placeholder.value = ""
      placeholder.disabled = true
      placeholder.textContent = label
      element.append(placeholder)

      displayLayers.forEach((layer) => {
        const option = document.createElement("option")
        option.value = layer.id
        option.textContent = layer.name
        option.disabled = layer.locked || !layer.visible
        element.append(option)
      })
    })
  },

  addLayer() {
    if (this.layers.length >= maxMapLayers) {
      this.setStatus(`Maps support up to ${maxMapLayers} layers`)
      return
    }

    let number = this.layers.length + 1
    let name = `Layer ${number}`
    const names = new Set(this.layers.map((layer) => layer.name.toLowerCase()))
    while (names.has(name.toLowerCase())) {
      number += 1
      name = `Layer ${number}`
    }

    const layer = {id: newItemId(), name, visible: true, locked: false}
    this.layers.push(layer)
    this.activeLayer = layer.id
    this.renderLayerPanel()
    this.renderLayerSelect()
    this.syncSelectionControls()
    this.changed(`${name} created`)
  },

  renameLayer(layerId, value) {
    const layer = this.layers.find((candidate) => candidate.id === layerId)
    const name = value.trim().slice(0, 80)
    const duplicate = this.layers.some((candidate) =>
      candidate.id !== layerId && candidate.name.toLowerCase() === name.toLowerCase()
    )

    if (!layer || !name || duplicate) {
      this.renderLayerPanel()
      this.setStatus(duplicate ? "Layer names must be unique" : "Layer names cannot be empty")
      return
    }

    layer.name = name
    this.renderLayerPanel()
    this.renderLayerSelect()
    this.syncSelectionControls()
    this.changed("Layer renamed")
  },

  runLayerAction(action, layerId) {
    const actions = {
      visibility: () => this.toggleLayerVisibility(layerId),
      lock: () => this.toggleLayerLock(layerId),
      select: () => this.selectLayerObjects(layerId),
      rename: () => this.startLayerRename(layerId),
      duplicate: () => this.duplicateLayer(layerId),
      "merge-down": () => this.mergeLayerDown(layerId),
      delete: () => this.deleteLayer(layerId),
    }

    actions[action]?.()
  },

  copySelectionToLayer(layerId) {
    const layer = this.layers.find((candidate) => candidate.id === layerId)
    const selected = this.canvas.getActiveObjects()
    if (!layer || selected.length === 0 || !layer.visible || layer.locked) {
      this.setStatus("Choose a visible, unlocked destination layer")
      return
    }

    Promise.all(selected.map((object) => object.clone(serializableProperties))).then((clones) => {
      this.canvas.discardActiveObject()
      clones.forEach((clone) => {
        clone.set({
          left: clone.left + 24,
          top: clone.top + 24,
          mapItemId: newItemId(),
          mapEntityType: null,
          mapEntityId: null,
          mapEntityName: null,
        })
        this.applyObjectLayer(clone, layerId)
        this.canvas.add(clone)
      })

      this.applyLayerStates()
      this.normalizeLayerOrder()
      this.canvas.setActiveObject(
        clones.length === 1 ? clones[0] : new ActiveSelection(clones, {canvas: this.canvas}),
      )
      this.renderLayerPanel()
      this.syncSelectionControls()
      this.canvas.requestRenderAll()
      this.changed(`Selection copied to ${layer.name}`)
    })
  },

  duplicateLayer(layerId) {
    const sourceIndex = this.layers.findIndex((layer) => layer.id === layerId)
    if (sourceIndex < 0 || this.layers.length >= maxMapLayers) return

    const source = this.layers[sourceIndex]
    const names = new Set(this.layers.map((layer) => layer.name.toLowerCase()))
    let number = 1
    let name = `${source.name} copy`
    while (names.has(name.toLowerCase())) {
      number += 1
      name = `${source.name} copy ${number}`
    }

    const layer = {id: newItemId(), name, visible: true, locked: false}
    const objects = this.canvas.getObjects().filter((object) => object.mapLayer === layerId)
    Promise.all(objects.map((object) => object.clone(serializableProperties))).then((clones) => {
      this.layers.splice(sourceIndex + 1, 0, layer)
      clones.forEach((clone) => {
        clone.set({
          mapItemId: newItemId(),
          mapEntityType: null,
          mapEntityId: null,
          mapEntityName: null,
        })
        this.applyObjectLayer(clone, layer.id)
        this.canvas.add(clone)
      })
      this.activeLayer = layer.id
      this.applyLayerStates()
      this.normalizeLayerOrder()
      this.renderLayerPanel()
      this.renderLayerSelect()
      this.syncSelectionControls()
      this.canvas.requestRenderAll()
      this.changed(`${source.name} duplicated`)
    })
  },

  mergeLayerDown(layerId) {
    const index = this.layers.findIndex((layer) => layer.id === layerId)
    if (index <= 0) return

    const layer = this.layers[index]
    const destination = this.layers[index - 1]
    if (!window.confirm(`Merge ${layer.name} into ${destination.name}?`)) return

    this.canvas.getObjects()
      .filter((object) => object.mapLayer === layerId)
      .forEach((object) => this.applyObjectLayer(object, destination.id))
    this.layers.splice(index, 1)
    if (this.activeLayer === layerId) this.activeLayer = destination.id
    this.applyLayerStates()
    this.normalizeLayerOrder()
    this.renderLayerPanel()
    this.renderLayerSelect()
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed(`${layer.name} merged into ${destination.name}`)
  },

  toggleLayerVisibility(layerId) {
    const layer = this.layers.find((candidate) => candidate.id === layerId)
    if (!layer) return

    layer.visible = !layer.visible
    if (!layer.visible) this.canvas.discardActiveObject()
    if (!layer.visible && layer.id === this.activeLayer) {
      const replacement = this.layers.find((candidate) => candidate.visible && !candidate.locked)
      if (replacement) this.activeLayer = replacement.id
    }

    this.applyLayerStates()
    this.renderLayerPanel()
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed(`${layer.name} ${layer.visible ? "shown" : "hidden"}`)
  },

  toggleLayerLock(layerId) {
    const layer = this.layers.find((candidate) => candidate.id === layerId)
    if (!layer) return

    if (!layer.locked) {
      const otherEditable = this.layers.some((candidate) =>
        candidate.id !== layerId && !candidate.locked
      )
      if (!otherEditable) {
        this.setStatus("At least one layer must remain unlocked")
        return
      }
    }

    layer.locked = !layer.locked
    this.canvas.discardActiveObject()
    if (layer.locked && layer.id === this.activeLayer) {
      const replacement = this.layers.find((candidate) => !candidate.locked)
      if (replacement) this.activeLayer = replacement.id
    }

    this.applyLayerStates()
    this.renderLayerPanel()
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed(`${layer.name} ${layer.locked ? "locked" : "unlocked"}`)
  },

  selectLayerObjects(layerId) {
    const layer = this.layers.find((candidate) => candidate.id === layerId)
    if (!layer || !layer.visible || layer.locked) {
      this.setStatus("Show and unlock the layer before selecting its objects")
      return
    }

    const objects = this.canvas.getObjects().filter((object) => object.mapLayer === layerId)
    this.canvas.discardActiveObject()

    if (objects.length === 1) this.canvas.setActiveObject(objects[0])
    else if (objects.length > 1) {
      this.canvas.setActiveObject(new ActiveSelection(objects, {canvas: this.canvas}))
    }

    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.setStatus(`${objects.length} ${layer.name} objects selected`)
  },

  moveLayer(layerId, offset) {
    const index = this.layers.findIndex((layer) => layer.id === layerId)
    const destination = index + offset
    if (index < 0 || destination < 0 || destination >= this.layers.length) return

    const [layer] = this.layers.splice(index, 1)
    this.layers.splice(destination, 0, layer)
    this.normalizeLayerOrder()
    this.renderLayerPanel()
    this.canvas.requestRenderAll()
    this.changed(`${layer.name} reordered`)
  },

  deleteLayer(layerId) {
    const index = this.layers.findIndex((layer) => layer.id === layerId)
    if (index < 0 || this.layers.length === 1) return

    const layer = this.layers[index]
    const destination = this.layers[index > 0 ? index - 1 : 1]
    const objects = this.canvas.getObjects().filter((object) => object.mapLayer === layerId)
    const confirmed = objects.length === 0 || window.confirm(
      `Move ${objects.length} objects to ${destination.name} and delete ${layer.name}?`,
    )
    if (!confirmed) return

    objects.forEach((object) => this.applyObjectLayer(object, destination.id))
    this.layers.splice(index, 1)
    if (this.activeLayer === layerId) this.activeLayer = destination.id
    this.applyLayerStates()
    this.normalizeLayerOrder()
    this.renderLayerPanel()
    this.renderLayerSelect()
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed(`${layer.name} deleted`)
  },

  syncSelectionControls() {
    const selected = this.canvas.getActiveObjects()
    const activeObject = this.canvas.getActiveObject()
    const layerSelect = this.el.querySelector("[data-map-selected-layer]")
    const copyLayerSelect = this.el.querySelector("[data-map-copy-layer]")
    const groupButton = this.el.querySelector("[data-map-action='group-selection']")
    const ungroupButton = this.el.querySelector("[data-map-action='ungroup-selection']")
    const layers = new Set(selected.map((object) => object.mapLayer || "features"))

    if (layerSelect) {
      layerSelect.disabled = selected.length === 0
      layerSelect.options[0].textContent = selected.length === 0 ? "No selection" : "Mixed layers"
      layerSelect.value = layers.size === 1 ? [...layers][0] : ""
    }

    if (copyLayerSelect) {
      copyLayerSelect.disabled = selected.length === 0
      copyLayerSelect.value = ""
    }

    if (groupButton) {
      groupButton.disabled = !(activeObject instanceof ActiveSelection) || selected.length < 2
    }

    if (ungroupButton) {
      ungroupButton.disabled = !(activeObject instanceof Group) ||
        activeObject instanceof ActiveSelection ||
        activeObject.mapKind !== "group"
    }
  },

  async addStamp(kind) {
    const icon = [...mapIcons, ...this.catalogIcons].find((candidate) => candidate.kind === kind)
    if (!icon) return

    let pathData = mapIconPaths[kind] || this.catalogIconPaths.get(kind)

    if (!pathData && icon.pathUrl) {
      this.setStatus(`Loading ${icon.name}...`)

      try {
        let pathIndex = this.catalogPathIndexes.get(icon.pathUrl)

        if (!pathIndex) {
          const response = await fetch(icon.pathUrl, {signal: this.iconCatalogAbort.signal})
          if (!response.ok) throw new Error(`Icon request failed with ${response.status}`)
          pathIndex = await response.json()
          this.catalogPathIndexes.set(icon.pathUrl, pathIndex)
        }

        pathData = pathIndex[icon.pathKey]
        if (pathData) this.catalogIconPaths.set(kind, pathData)
      } catch (_error) {
        this.setStatus("The selected symbol could not be loaded")
        return
      }
    }

    if (!pathData) return

    const path = new Path(pathData, {
      left: this.width / 2,
      top: this.height / 2,
      originX: "center",
      originY: "center",
      fill: this.inkColor,
      strokeWidth: 0,
      mapKind: kind,
      mapLayer: this.activeLayer,
      mapIconName: icon.name,
      mapIconAuthor: icon.author,
      mapItemId: newItemId(),
    })

    path.scale(64 / Math.max(path.width, path.height))

    this.canvas.add(path)
    this.canvas.setActiveObject(path)
    this.canvas.requestRenderAll()
    this.setTool("select")
    this.closeIconLibrary()
    this.changed(`${icon.name} placed`)
  },

  renderIconPicker() {
    const grid = this.el.querySelector("[data-map-icon-grid]")
    if (!grid) return

    const search = this.el.querySelector("[data-map-icon-search]")?.value.trim().toLowerCase() || ""
    const category = this.el.querySelector("[data-map-icon-category]")?.value || "all"
    const result = filterMapIcons([...mapIcons, ...this.catalogIcons], search, category)

    const buttons = result.icons.map((icon) => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.mapAsset = icon.kind
      button.className = "stone-button group flex h-full w-full min-w-0 flex-col items-center justify-center gap-1 rounded-md border p-2 text-center transition"
      button.title = `${icon.name} by ${icon.author}`
      button.setAttribute("aria-label", `Place ${icon.name}`)

      const preview = document.createElement("img")
      preview.src = icon.url || `data:image/svg+xml;charset=utf-8,${encodeURIComponent(icon.source)}`
      preview.alt = ""
      preview.loading = "lazy"
      preview.decoding = "async"
      preview.className = "size-9 object-contain opacity-75 transition group-hover:opacity-100"

      const label = document.createElement("span")
      label.className = "stone-heading w-full truncate text-[10px] font-medium"
      label.textContent = icon.name

      button.append(preview, label)
      return button
    })

    grid.replaceChildren(...buttons)

    const count = this.el.querySelector("#map-icon-count")
    if (count) {
      count.textContent = result.total > result.icons.length
        ? `${result.icons.length} of ${result.total} symbols`
        : `${result.total} symbols`
    }
  },

  async loadIconCatalog() {
    try {
      const response = await fetch(gameIconCatalogUrl, {signal: this.iconCatalogAbort.signal})
      if (!response.ok) throw new Error(`Catalog request failed with ${response.status}`)

      const catalog = await response.json()
      this.catalogIcons = catalog.icons.map(normalizeGameIcon)
      this.renderIconCategories(catalog.categories)
      const total = this.el.querySelector("#map-icon-total")
      if (total) total.textContent = `${this.catalogIcons.length.toLocaleString()} symbols`
      this.renderIconPicker()
    } catch (error) {
      if (error.name !== "AbortError") this.setStatus("The full symbol catalog could not be loaded")
    }
  },

  renderIconCategories(categories) {
    const select = this.el.querySelector("[data-map-icon-category]")
    if (!select || !Array.isArray(categories)) return

    const group = document.createElement("optgroup")
    group.label = "Game Icons catalog"

    const options = categories.map((category) => {
      const option = document.createElement("option")
      option.value = `game-icons:${category.id}`
      option.textContent = `${category.label} (${category.count})`
      return option
    })

    group.append(...options)
    select.append(group)

    if (!select.dataset.mapCategoryChosen && categories.some(({id}) => id === "viking")) {
      select.value = "game-icons:viking"
    }
  },

  openIconLibrary() {
    const dialog = this.el.querySelector("[data-map-icon-dialog]")
    if (!dialog) return

    if (!dialog.open) dialog.showModal()
    requestAnimationFrame(() => this.el.querySelector("[data-map-icon-search]")?.focus())
  },

  closeIconLibrary() {
    const dialog = this.el.querySelector("[data-map-icon-dialog]")
    if (dialog?.open) dialog.close()
  },

  clearIconFilters() {
    const search = this.el.querySelector("[data-map-icon-search]")
    const category = this.el.querySelector("[data-map-icon-category]")

    window.clearTimeout(this.iconSearchTimer)
    if (search) search.value = ""
    if (category) category.value = "all"
    this.renderIconPicker()
    search?.focus()
  },

  addText() {
    this.setTool("select")

    const label = new IText("Place name", {
      left: this.width / 2,
      top: this.height / 2,
      originX: "center",
      originY: "center",
      fill: this.inkColor,
      fontFamily: "Georgia",
      fontSize: 34,
      fontWeight: "600",
      mapKind: "label",
      mapLayer: "labels",
      mapItemId: newItemId(),
    })

    this.canvas.add(label)
    this.canvas.setActiveObject(label)
    this.canvas.requestRenderAll()
    this.setLayer("labels")
    label.enterEditing()
    label.selectAll()
    this.changed("Label added")
  },

  runAction(action) {
    const actions = {
      "add-text": () => this.addText(),
      "finish-landmass": () => this.finishLandmass(),
      "undo-landmass-point": () => this.undoLandmassPoint(),
      "cancel-landmass": () => this.cancelLandmass(),
      "edit-landmass": () => this.toggleLandmassEditing(),
      delete: () => this.deleteSelection(),
      duplicate: () => this.duplicateSelection(),
      "group-selection": () => this.groupSelection(),
      "ungroup-selection": () => this.ungroupSelection(),
      "add-layer": () => this.addLayer(),
      undo: () => this.undo(),
      redo: () => this.redo(),
      save: () => this.save(),
      export: () => this.exportPng(),
      "zoom-in": () => this.setZoom(this.zoom + 0.1),
      "zoom-out": () => this.setZoom(this.zoom - 0.1),
      "zoom-reset": () => this.setZoom(1),
      "zoom-fit": () => this.zoomToFit(),
      "toggle-grid": () => this.toggleGrid(),
      "toggle-snap": () => this.setSnap(!this.snapEnabled),
      "toggle-guides": () => this.setGuides(!this.guidesEnabled),
      "center-object": () => this.centerSelection(),
      "bring-forward": () => this.reorderSelection("forward"),
      "send-backward": () => this.reorderSelection("backward"),
      "toggle-lock": () => this.toggleSelectionLock(),
      "open-icon-library": () => this.openIconLibrary(),
      "close-icon-library": () => this.closeIconLibrary(),
      "clear-icon-filters": () => this.clearIconFilters(),
      fullscreen: () => this.toggleFullscreen(),
    }

    actions[action]?.()
  },

  toggleFullscreen() {
    const fullscreenRequest = document.fullscreenElement === this.el
      ? document.exitFullscreen()
      : this.el.requestFullscreen()

    fullscreenRequest?.catch(() => this.setStatus("Fullscreen mode is unavailable"))
  },

  syncFullscreenState() {
    const active = document.fullscreenElement === this.el
    const button = this.el.querySelector("#map-fullscreen")
    const label = this.el.querySelector("[data-map-fullscreen-label]")

    button?.setAttribute("aria-pressed", active.toString())
    button?.setAttribute("aria-label", active ? "Exit focus mode" : "Enter focus mode")
    if (label) label.textContent = active ? "Exit focus" : "Focus"
    if (active) requestAnimationFrame(() => this.zoomToFit())

    this.setStatus(active ? "Focus mode active. Press Escape to exit." : "Focus mode closed")
  },

  zoomToFit() {
    const scroller = this.el.querySelector("#ink-map-stage")?.parentElement
    if (!scroller) return

    const horizontal = Math.max(0.05, (scroller.clientWidth - 40) / this.width)
    const vertical = Math.max(0.05, (scroller.clientHeight - 40) / this.height)
    this.setZoom(Math.min(4, horizontal, vertical))
    this.setStatus("Map fitted to the workspace")
  },

  centerSelection() {
    const object = this.canvas.getActiveObject()
    if (!object || object.mapLocked) return

    object.setPositionByOrigin(new Point(this.width / 2, this.height / 2), "center", "center")
    object.setCoords()
    this.canvas.requestRenderAll()
    this.showCoordinates(object)
    this.highlightCenterGuides(true, true)
    this.changed("Selection centered on canvas")
  },

  groupSelection() {
    const activeObject = this.canvas.getActiveObject()
    if (!(activeObject instanceof ActiveSelection)) {
      this.setStatus("Select at least two objects to group")
      return
    }

    const objects = [...activeObject.getObjects()]
    if (objects.length < 2) return

    const layers = new Set(objects.map((object) => object.mapLayer || "features"))
    const layer = layers.size === 1 ? [...layers][0] : this.activeLayer

    this.canvas.discardActiveObject()
    objects.forEach((object) => {
      this.canvas.remove(object)
      this.applyObjectLayer(object, layer)
    })

    const group = new Group(objects, {
      mapKind: "group",
      mapLayer: layer,
      mapIconName: "Grouped objects",
      mapItemId: newItemId(),
    })

    this.canvas.add(group)
    this.normalizeLayerOrder()
    this.canvas.setActiveObject(group)
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed("Objects grouped")
  },

  ungroupSelection() {
    const group = this.canvas.getActiveObject()

    if (!(group instanceof Group) || group instanceof ActiveSelection || group.mapKind !== "group") {
      this.setStatus("Select a manually created group to ungroup")
      return
    }

    const layer = group.mapLayer || "features"
    this.canvas.discardActiveObject()
    const objects = group.removeAll()
    this.canvas.remove(group)

    objects.forEach((object) => {
      this.applyObjectLayer(object, layer)
      if (!object.mapItemId) object.set({mapItemId: newItemId()})
      this.canvas.add(object)
    })

    this.normalizeLayerOrder()
    this.canvas.setActiveObject(new ActiveSelection(objects, {canvas: this.canvas}))
    this.syncSelectionControls()
    this.canvas.requestRenderAll()
    this.changed("Group separated")
  },

  deleteSelection() {
    const selected = this.canvas.getActiveObjects()
    if (selected.length === 0) return

    this.canvas.discardActiveObject()
    selected.forEach((object) => this.canvas.remove(object))
    this.canvas.requestRenderAll()
    this.changed("Selection deleted")
  },

  duplicateSelection() {
    const selected = this.canvas.getActiveObjects()
    if (selected.length === 0) return

    Promise.all(selected.map((object) => object.clone(serializableProperties))).then((clones) => {
      this.canvas.discardActiveObject()

      clones.forEach((clone) => {
        clone.set({
          left: clone.left + 24,
          top: clone.top + 24,
          mapItemId: newItemId(),
          mapEntityType: null,
          mapEntityId: null,
          mapEntityName: null,
        })
        this.canvas.add(clone)
      })

      const duplicate = clones.length === 1
        ? clones[0]
        : new ActiveSelection(clones, {canvas: this.canvas})

      this.canvas.setActiveObject(duplicate)
      this.canvas.requestRenderAll()
      this.showCoordinates(duplicate)
      this.syncEntityLink(duplicate)
      this.changed(clones.length === 1 ? "Item duplicated" : "Items duplicated")
    })
  },

  nudgeSelection(direction, distance) {
    const selected = this.canvas.getActiveObjects()
    if (selected.length === 0) return

    const movement = {
      ArrowUp: {x: 0, y: -distance},
      ArrowDown: {x: 0, y: distance},
      ArrowLeft: {x: -distance, y: 0},
      ArrowRight: {x: distance, y: 0},
    }[direction]

    selected.forEach((object) => {
      if (!object.mapLocked) {
        object.set({left: object.left + movement.x, top: object.top + movement.y})
        object.setCoords()
      }
    })

    this.canvas.requestRenderAll()
    this.showCoordinates(this.canvas.getActiveObject())
    this.changed("Selection moved")
  },

  reorderSelection(direction) {
    const object = this.canvas.getActiveObject()
    if (!object) return

    if (direction === "forward") this.canvas.bringObjectForward(object)
    else this.canvas.sendObjectBackwards(object)

    this.canvas.requestRenderAll()
    this.changed(direction === "forward" ? "Selection moved forward" : "Selection moved backward")
  },

  toggleSelectionLock() {
    const selected = this.canvas.getActiveObjects()
    if (selected.length === 0) return

    const locked = !selected.every((object) => object.mapLocked)
    selected.forEach((object) => this.applyObjectLock(object, locked))
    this.syncInspector(this.canvas.getActiveObject())
    this.canvas.requestRenderAll()
    this.changed(locked ? "Selection locked" : "Selection unlocked")
  },

  applyObjectLock(object, locked) {
    object.set({
      mapLocked: locked,
      lockMovementX: locked,
      lockMovementY: locked,
      lockScalingX: locked,
      lockScalingY: locked,
      lockRotation: locked,
      hasControls: !locked,
    })
  },

  ensureItemIds() {
    this.canvas.getObjects().forEach((object) => {
      if (!object.mapItemId) object.set({mapItemId: newItemId()})
      if (object.mapKind === "landmass") object.set({objectCaching: false})
      this.applyObjectLock(object, Boolean(object.mapLocked))
    })
  },

  updateSelectedProperty(input, commit) {
    const object = this.canvas.getActiveObject()
    if (!object || object.mapLocked) return

    const value = Number.parseFloat(input.value)
    if (!Number.isFinite(value)) return

    const center = object.getCenterPoint()

    if (input.dataset.mapProperty === "x") {
      object.setPositionByOrigin(new Point(value, center.y), "center", "center")
    } else if (input.dataset.mapProperty === "y") {
      object.setPositionByOrigin(new Point(center.x, value), "center", "center")
    } else if (input.dataset.mapProperty === "angle") {
      object.set({angle: value})
    } else if (input.dataset.mapProperty === "opacity") {
      object.set({opacity: Math.min(1, Math.max(0.1, value / 100))})
    }

    object.setCoords()
    this.canvas.requestRenderAll()
    this.showCoordinates(object)
    if (commit) this.changed("Object properties updated")
    else this.markDirty("Object properties updated")
  },

  syncInspector(object) {
    const inputs = this.el.querySelectorAll("[data-map-property]")
    const name = this.el.querySelector("#map-selected-object-name")
    const opacity = this.el.querySelector("#map-object-opacity-value")
    const lockLabel = this.el.querySelector("[data-map-lock-label]")
    const locked = Boolean(object?.mapLocked)

    inputs.forEach((input) => { input.disabled = !object || locked })
    if (name) name.textContent = object?.mapEntityName || object?.mapIconName || object?.mapKind || "Nothing selected"
    if (lockLabel) lockLabel.textContent = locked ? "Unlock" : "Lock"
    if (!object) return

    const center = object.getCenterPoint()
    const values = {
      x: Math.round(center.x),
      y: Math.round(center.y),
      angle: Math.round(object.angle || 0),
      opacity: Math.round((object.opacity ?? 1) * 100),
    }

    inputs.forEach((input) => { input.value = values[input.dataset.mapProperty] })
    if (opacity) opacity.textContent = `${values.opacity}%`
  },

  linkSelection(select) {
    const selected = this.canvas.getActiveObjects()
    if (selected.length !== 1) {
      select.value = ""
      this.setStatus("Select one item before linking geography")
      return
    }

    const object = selected[0]
    const option = select.selectedOptions[0]

    if (!select.value) {
      object.set({mapEntityType: null, mapEntityId: null, mapEntityName: null})
      this.changed("Geography link removed")
      return
    }

    const [type, id] = select.value.split(":", 2)
    object.set({
      mapEntityType: type,
      mapEntityId: id,
      mapEntityName: option.dataset.mapEntityName,
    })
    this.changed(`${option.dataset.mapEntityName} linked`)
  },

  syncEntityLink(object) {
    const select = this.el.querySelector("[data-map-entity-link]")
    if (!select) return

    const value = object?.mapEntityType && object?.mapEntityId
      ? `${object.mapEntityType}:${object.mapEntityId}`
      : ""

    select.value = [...select.options].some((option) => option.value === value) ? value : ""
  },

  serializeDocument() {
    this.canvas.getObjects().forEach((object) => {
      const point = object.getCenterPoint()
      object.set({mapX: point.x, mapY: point.y})
    })

    const document = this.canvas.toJSON(serializableProperties)
    document.objects.forEach((object) => {
      if (object.mapKind === "reference-image" && object.mapReferenceSrc) {
        object.src = object.mapReferenceSrc
      }
    })
    document.mapBackground = this.mapBackground
    document.mapBackgroundExplicit = this.hasExplicitBackground
    document.mapLayers = this.layers.map((layer) => ({...layer}))
    document.activeMapLayer = this.activeLayer
    return document
  },

  setZoom(zoom) {
    this.zoom = Math.min(4, Math.max(0.05, zoom))
    const percentage = Math.round(this.zoom * 100)

    this.canvas.setDimensions(
      {width: this.width * this.zoom, height: this.height * this.zoom},
      {cssOnly: true},
    )

    const input = this.el.querySelector("[data-map-zoom]")
    const value = this.el.querySelector("#map-zoom-value")
    if (input) input.value = percentage
    if (value) value.textContent = `${percentage}%`
    this.setGrid(this.gridVisible)
  },

  setZoomAt(zoom, clientX, clientY) {
    const scroller = this.el.querySelector("#map-canvas-scroller")
    if (!scroller) {
      this.setZoom(zoom)
      return
    }

    const previousZoom = this.zoom
    const bounds = scroller.getBoundingClientRect()
    const offsetX = clientX - bounds.left
    const offsetY = clientY - bounds.top
    const mapX = (scroller.scrollLeft + offsetX) / previousZoom
    const mapY = (scroller.scrollTop + offsetY) / previousZoom

    this.setZoom(zoom)
    scroller.scrollLeft = Math.max(0, mapX * this.zoom - offsetX)
    scroller.scrollTop = Math.max(0, mapY * this.zoom - offsetY)
  },

  resizeMap(width, height) {
    const nextWidth = Math.min(8192, Math.max(640, Number.parseInt(width, 10)))
    const nextHeight = Math.min(8192, Math.max(480, Number.parseInt(height, 10)))

    if (!Number.isFinite(nextWidth) || !Number.isFinite(nextHeight)) return

    this.width = nextWidth
    this.height = nextHeight
    this.canvas.setDimensions({width: this.width, height: this.height})
    this.setZoom(this.zoom)
    this.canvas.calcOffset()
    this.canvas.requestRenderAll()
    this.setStatus(`Canvas resized to ${this.width} × ${this.height}`)
  },

  showCoordinates(object) {
    const readout = this.el.querySelector("#map-coordinate-readout")
    if (!readout) return

    if (!object) {
      readout.textContent = "X -- / Y --"
      this.syncInspector()
      return
    }

    const point = object.getCenterPoint()
    const x = Math.round(point.x)
    const y = Math.round(point.y)
    readout.textContent = `X ${x} / Y ${y}`
    readout.dataset.x = x
    readout.dataset.y = y
    this.syncInspector(object)
  },

  setGrid(visible) {
    this.gridVisible = visible
    this.canvas.backgroundColor = editorCanvasBackground(visible, this.mapBackground)
    this.canvas.lowerCanvasEl.style.backgroundImage = visible
      ? "linear-gradient(rgba(52, 47, 40, 0.09) 1px, transparent 1px), linear-gradient(90deg, rgba(52, 47, 40, 0.09) 1px, transparent 1px)"
      : "none"
    const gridSize = 32 * (this.zoom || 1)
    this.canvas.lowerCanvasEl.style.backgroundSize = `${gridSize}px ${gridSize}px`
    const button = this.el.querySelector("[data-map-action='toggle-grid']")
    button?.classList.toggle("stone-selected", visible)
    button?.setAttribute("aria-pressed", visible.toString())
    this.canvas.requestRenderAll()
  },

  toggleGrid() {
    const visible = !this.gridVisible
    this.setGrid(visible)

    try {
      window.localStorage.setItem(gridPreferenceKey, visible.toString())
    } catch (_error) {
      // The grid still works when browser storage is unavailable.
    }
  },

  applyCanvasAppearance() {
    this.canvas.lowerCanvasEl.style.backgroundColor = this.mapBackground
    this.setGrid(this.gridVisible)
  },

  loadGridPreference() {
    try {
      return gridVisiblePreference(window.localStorage.getItem(gridPreferenceKey))
    } catch (_error) {
      return true
    }
  },

  setSnap(enabled) {
    this.snapEnabled = enabled
    const button = this.el.querySelector("[data-map-action='toggle-snap']")
    button?.classList.toggle("stone-selected", enabled)
    button?.setAttribute("aria-pressed", enabled.toString())
  },

  setGuides(enabled) {
    this.guidesEnabled = enabled
    const button = this.el.querySelector("[data-map-action='toggle-guides']")
    button?.classList.toggle("stone-selected", enabled)
    button?.setAttribute("aria-pressed", enabled.toString())

    this.el.querySelectorAll("[data-map-center-guide]").forEach((guide) => {
      guide.classList.toggle("hidden", !enabled)
    })
  },

  snapObject(object, guideSnap = {}) {
    if (!this.snapEnabled || object.mapLocked) return

    const position = {}
    if (!guideSnap.x) position.left = Math.round(object.left / 32) * 32
    if (!guideSnap.y) position.top = Math.round(object.top / 32) * 32
    object.set(position)
  },

  snapToCenterGuides(object) {
    if (!this.guidesEnabled || object.mapLocked) {
      this.highlightCenterGuides(false, false)
      return {}
    }

    const center = object.getCenterPoint()
    const tolerance = 10 / this.zoom
    const snapX = Math.abs(center.x - this.width / 2) <= tolerance
    const snapY = Math.abs(center.y - this.height / 2) <= tolerance

    if (snapX || snapY) {
      object.setPositionByOrigin(
        new Point(snapX ? this.width / 2 : center.x, snapY ? this.height / 2 : center.y),
        "center",
        "center",
      )
    }

    this.highlightCenterGuides(snapX, snapY)
    return {x: snapX, y: snapY}
  },

  highlightCenterGuides(vertical, horizontal) {
    this.el.querySelector("#map-center-guide-vertical")?.classList.toggle("opacity-100", vertical)
    this.el.querySelector("#map-center-guide-horizontal")?.classList.toggle("opacity-100", horizontal)
  },

  changed(message) {
    if (this.ready && !this.restoring) {
      this.captureHistory()
      this.markDirty(message)
    }
  },

  markDirty(message) {
    if (!this.ready) return

    this.dirty = true
    this.changeVersion += 1
    this.syncSaveState()
    this.setSaveStatus("unsaved", "Unsaved")
    this.setStatus(`${message}. Unsaved changes.`)
    this.scheduleLocalDraft()
    this.scheduleAutosave()
  },

  scheduleLocalDraft() {
    window.clearTimeout(this.draftTimer)
    this.draftTimer = window.setTimeout(() => {
      this.draftTimer = null
      void this.persistLocalDraft()
    }, 750)
  },

  scheduleAutosave(delay = 30000) {
    if (this.autosaveBlocked || this.autosaveTimer || !this.dirty) return

    this.autosaveTimer = window.setTimeout(() => {
      this.autosaveTimer = null
      this.save({automatic: true})
    }, delay)
  },

  queueDraftOperation(operation) {
    this.draftQueue = this.draftQueue.catch(() => undefined).then(operation)
    return this.draftQueue
  },

  persistLocalDraft() {
    if (!this.mapId || !this.ready || !this.dirty) return Promise.resolve()

    window.clearTimeout(this.draftTimer)
    this.draftTimer = null
    const version = this.changeVersion
    const draft = {
      mapId: this.mapId,
      baseRevision: this.serverRevision,
      document: this.serializeDocument(),
      width: this.width,
      height: this.height,
      savedAt: new Date().toISOString(),
    }

    return this.queueDraftOperation(() => putMapDraft(draft)).then(() => {
      if (this.changeVersion !== version || !this.dirty) return

      this.localDraftVersion = version
      this.setSaveStatus("local", "Saved locally")
      this.setStatus("Changes saved locally. Server autosave pending.")
    }).catch(() => {
      this.setSaveStatus("error", "Local save failed")
      this.setStatus("Local draft storage failed. Use Save before leaving this page.")
    })
  },

  clearLocalDraft() {
    if (!this.mapId) return Promise.resolve()

    return this.queueDraftOperation(() => deleteMapDraft(this.mapId)).then(() => {
      this.localDraftVersion = -1
    }).catch(() => {
      this.localDraftVersion = -1
    })
  },

  captureHistory() {
    const snapshot = JSON.stringify(this.serializeDocument())
    if (this.history[this.historyIndex] === snapshot) return

    this.history = this.history.slice(0, this.historyIndex + 1)
    this.history.push(snapshot)
    if (this.history.length > 50) this.history.shift()
    this.historyIndex = this.history.length - 1
  },

  undo() {
    if (this.ready && !this.restoring && this.historyIndex > 0) {
      this.restoreHistory(this.historyIndex - 1, "Undo complete")
    }
  },

  redo() {
    if (this.ready && !this.restoring && this.historyIndex < this.history.length - 1) {
      this.restoreHistory(this.historyIndex + 1, "Redo complete")
    }
  },

  restoreHistory(index, message) {
    this.restoring = true
    this.historyIndex = index
    const document = JSON.parse(this.history[index])
    this.layers = this.normalizeLayers(document.mapLayers)
    this.activeLayer = this.layers.some((layer) => layer.id === document.activeMapLayer)
      ? document.activeMapLayer
      : this.layers[0].id
    this.hasExplicitBackground = document.mapBackgroundExplicit ?? Boolean(document.mapBackground)
    this.mapBackground = this.hasExplicitBackground
      ? document.mapBackground
      : this.defaultCanvasBackground()
    this.inkColor = contrastingInk(this.mapBackground)
    this.applyCanvasAppearance()
    this.syncBackgroundInput()
    this.renderLayerPanel()
    this.renderLayerSelect()
    this.canvas.loadFromJSON(document).then(() => {
      this.applyCanvasAppearance()
      this.ensureItemIds()
      this.applyLayerStates()
      this.normalizeLayerOrder()
      this.renderLayerPanel()
      this.syncSelectionControls()
      this.canvas.requestRenderAll()
      this.restoring = false
      this.markDirty(message)
    }).catch(() => {
      this.restoring = false
      this.setStatus("The map history could not be restored")
    })
  },

  save({automatic = false} = {}) {
    if (!this.ready || this.restoring || this.saving) return

    window.clearTimeout(this.autosaveTimer)
    this.autosaveTimer = null
    this.saving = true
    this.syncSaveState()
    this.setSaveStatus("saving", automatic ? "Autosaving" : "Saving")
    this.setStatus(automatic ? "Autosaving map..." : "Saving map...")
    const document = this.serializeDocument()
    const savedVersion = this.changeVersion
    const requestId = ++this.saveRequestId
    void this.persistLocalDraft()

    this.saveTimeout = window.setTimeout(() => {
      if (!this.saving || requestId !== this.saveRequestId) return

      this.saving = false
      this.saveRequestId += 1
      this.setSaveStatus("local", "Saved locally")
      this.setStatus("Server save timed out. Changes remain protected on this device.")
      this.syncSaveState()
      this.scheduleAutosave(60000)
    }, 15000)

    this.pushEvent("save_map", {document, width: this.width, height: this.height}, (reply) => {
      if (requestId !== this.saveRequestId) return

      window.clearTimeout(this.saveTimeout)
      this.saving = false

      if (reply.ok) {
        this.serverRevision = reply.revision || this.serverRevision
        this.autosaveBlocked = false
        this.dirty = this.changeVersion !== savedVersion
        if (this.dirty) {
          void this.persistLocalDraft()
          this.scheduleAutosave()
          this.setSaveStatus("unsaved", "New changes pending")
          this.setStatus("Map saved. Newer changes remain unsaved.")
        } else {
          void this.clearLocalDraft()
          this.setSaveStatus("saved", "Map saved")
          this.setStatus("")
        }
      } else {
        this.autosaveBlocked = Boolean(reply.conflict)
        this.setSaveStatus(reply.conflict ? "conflict" : "error", reply.conflict ? "Conflict" : "Save failed")
        this.setStatus(reply.error || "The map could not be saved")
        if (!reply.conflict) this.scheduleAutosave(60000)
      }

      this.syncSaveState()
    })
  },

  syncSaveState() {
    const button = this.el.querySelector("[data-map-action='save']")
    if (!button) return

    button.disabled = !this.ready || this.saving
    button.setAttribute("aria-busy", this.saving.toString())
  },

  setSaveStatus(state, label) {
    const indicator = this.el.querySelector("[data-map-save-state]")
    if (!indicator) return

    const colors = {
      saved: "#15803d",
      local: "#a16207",
      unsaved: "#a16207",
      saving: "#2563eb",
      conflict: "#b91c1c",
      error: "#b91c1c",
    }
    indicator.dataset.state = state
    indicator.querySelector("[data-map-save-label]").textContent = label
    indicator.querySelector("[data-map-save-dot]").style.backgroundColor = colors[state] || "#71717a"
  },

  exportPng() {
    const background = this.canvas.backgroundColor
    const exportBackground =
      this.el.querySelector("[data-map-export-background]")?.value || this.mapBackground
    const requestedMultiplier = Number.parseInt(
      this.el.querySelector("[data-map-export-multiplier]")?.value,
      10,
    )
    const multiplier = [1, 2, 4].includes(requestedMultiplier) ? requestedMultiplier : 2
    const excludedObjects = this.canvas.getObjects().filter((object) => object.mapExcludeFromExport)
    const visibility = excludedObjects.map((object) => object.visible)

    try {
      excludedObjects.forEach((object) => object.set({visible: false}))
      this.canvas.backgroundColor = exportBackground
      this.canvas.requestRenderAll()

      const link = document.createElement("a")
      link.download = `world-map-${multiplier}x.png`
      link.href = this.canvas.toDataURL({
        format: "png",
        multiplier,
        enableRetinaScaling: false,
      })
      link.click()
    } finally {
      excludedObjects.forEach((object, index) => object.set({visible: visibility[index]}))
      this.canvas.backgroundColor = background
      this.canvas.requestRenderAll()
    }

    this.setStatus(
      `PNG exported at ${this.width * multiplier} x ${this.height * multiplier}`,
    )
  },

  setStatus(message) {
    const status = this.el.querySelector("#ink-map-status")
    if (status) status.textContent = message
  },

  defaultCanvasBackground() {
    return parchment
  },

  syncImplicitCanvasTheme() {
    if (this.hasExplicitBackground) return

    this.mapBackground = this.defaultCanvasBackground()
    this.inkColor = contrastingInk(this.mapBackground)
    this.applyCanvasAppearance()
    this.syncBackgroundInput()
  },

  syncBackgroundInput() {
    this.el
      .querySelectorAll("[data-map-water-color], [data-map-export-background]")
      .forEach((input) => { input.value = this.mapBackground })
  },
}

export default InkMap
