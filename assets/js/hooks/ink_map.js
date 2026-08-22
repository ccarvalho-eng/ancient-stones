import {
  ActiveSelection,
  Canvas,
  Group,
  IText,
  Path,
  PencilBrush,
  Point,
  Polygon,
  controlsUtils,
} from "../../vendor/fabric.mjs"
import {mapIconPaths, mapIcons} from "../map_icons"
import {appendDistinctPoint, roughenCoastline, zoomFromPinch} from "../map_geometry.mjs"

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
]
const layerOrder = {terrain: 0, features: 1, labels: 2}
const parchment = "#e7ddc4"
const ink = "#342f28"

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
    this.width = Number.parseInt(this.el.dataset.mapWidth, 10) || 1600
    this.height = Number.parseInt(this.el.dataset.mapHeight, 10) || 1000
    this.activeLayer = "terrain"
    this.history = []
    this.historyIndex = -1
    this.restoring = false
    this.dirty = false
    this.ready = false
    this.saving = false
    this.changeVersion = 0
    this.textureTool = null
    this.textureStroke = null
    this.panState = null
    this.landmassDraft = null
    this.mapBackground = mapDocument.mapBackground || parchment

    this.canvas = new Canvas(this.el.querySelector("#ink-map-canvas"), {
      width: this.width,
      height: this.height,
      preserveObjectStacking: true,
      selection: true,
    })

    this.canvas.backgroundColor = this.mapBackground
    this.canvas.lowerCanvasEl.style.backgroundColor = this.mapBackground
    this.setGrid(true)
    this.setSnap(false)
    this.setGuides(true)
    this.setZoom(1)
    this.setTool("select")
    this.bindCanvasEvents()
    this.bindControls()
    this.bindPinchZoom()
    this.renderIconPicker()
    this.handleFullscreenChange = () => this.syncFullscreenState()
    document.addEventListener("fullscreenchange", this.handleFullscreenChange)
    this.handleEvent("map_resized", ({width, height}) => this.resizeMap(width, height))
    this.syncSaveState()

    this.canvas.loadFromJSON(mapDocument).then(() => {
      this.ensureItemIds()
      this.syncInspector()
      this.canvas.requestRenderAll()
      this.captureHistory()
      this.ready = true
      this.syncSaveState()
      this.setStatus("Map ready")
      requestAnimationFrame(() => this.zoomToFit())
    }).catch(() => {
      this.setStatus("The map document could not be loaded")
    })
  },

  destroyed() {
    this.el.removeEventListener("click", this.handleClick)
    this.el.removeEventListener("input", this.handleInput)
    this.el.removeEventListener("change", this.handleInput)
    document.removeEventListener("fullscreenchange", this.handleFullscreenChange)
    document.removeEventListener("click", this.handleNavigation, true)
    window.removeEventListener("beforeunload", this.handleBeforeUnload)
    window.removeEventListener("keydown", this.handleKeydown)
    this.pinchTarget.removeEventListener("touchstart", this.handleTouchStart)
    this.pinchTarget.removeEventListener("touchmove", this.handleTouchMove)
    this.pinchTarget.removeEventListener("touchend", this.handleTouchEnd)
    this.pinchTarget.removeEventListener("touchcancel", this.handleTouchEnd)
    this.pinchTarget.removeEventListener("wheel", this.handlePinchWheel)
    this.canvas.dispose()
  },

  parseDocument() {
    try {
      const document = JSON.parse(this.el.dataset.mapDocument || "{}")
      return Array.isArray(document.objects) ? document : {objects: []}
    } catch (_error) {
      return {objects: []}
    }
  },

  bindCanvasEvents() {
    this.canvas.on("path:created", ({path}) => {
      path.set({mapKind: "ink", mapLayer: this.activeLayer, mapItemId: newItemId()})
      this.changed("Stroke added")
    })
    this.canvas.on("mouse:down", (event) => {
      if (this.landmassTool) this.addLandmassPoint(event)
      else {
        this.startTextureStroke(event)
        this.startPan(event)
      }
    })
    this.canvas.on("mouse:move", (event) => {
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
      this.setStatus("Object selected")
    })
    this.canvas.on("selection:updated", ({selected}) => {
      this.showCoordinates(selected?.[0])
      this.syncEntityLink(selected?.[0])
      this.setStatus("Object selected")
    })
    this.canvas.on("selection:cleared", () => {
      this.showCoordinates()
      this.syncEntityLink()
    })
    this.canvas.on("mouse:dblclick", ({target}) => {
      if (target?.mapKind === "landmass") this.toggleLandmassEditing(target)
    })
  },

  bindControls() {
    this.handleClick = (event) => {
      const control = event.target.closest("[data-map-tool], [data-map-asset], [data-map-action], [data-map-layer]")

      if (!control || !this.el.contains(control)) return
      if (!this.ready) return

      if (control.dataset.mapTool) this.setTool(control.dataset.mapTool)
      else if (control.dataset.mapAsset) this.addStamp(control.dataset.mapAsset)
      else if (control.dataset.mapLayer) this.setLayer(control.dataset.mapLayer)
      else this.runAction(control.dataset.mapAction)
    }

    this.handleInput = (event) => {
      if (event.target.matches("[data-map-brush-size]") && this.canvas.freeDrawingBrush) {
        this.canvas.freeDrawingBrush.width = Number.parseInt(event.target.value, 10)
      } else if (event.target.matches("[data-map-zoom]")) {
        this.setZoom(Number.parseInt(event.target.value, 10) / 100)
      } else if (event.target.matches("[data-map-icon-search], [data-map-icon-category]")) {
        this.renderIconPicker()
      } else if (event.target.matches("[data-map-water-color]")) {
        this.setMapBackground(event.target.value)
      } else if (event.target.matches("[data-map-entity-link]")) {
        this.linkSelection(event.target)
      } else if (event.target.matches("[data-map-property]")) {
        this.updateSelectedProperty(event.target, event.type === "change")
      }
    }

    this.handleKeydown = (event) => {
      const activeObject = this.canvas.getActiveObject()

      if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement || activeObject?.isEditing) return

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
    window.addEventListener("keydown", this.handleKeydown)

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
    const drawing = tool === "ink"
    const panning = tool === "pan"
    const landmass = tool === "landmass"
    const texture = tool.startsWith("texture-") ? tool.replace("texture-", "") : null
    if (!landmass && this.landmassDraft) this.cancelLandmass()
    this.canvas.isDrawingMode = drawing
    this.canvas.selection = !drawing && !texture && !panning && !landmass
    this.canvas.skipTargetFind = Boolean(texture) || panning || landmass
    this.canvas.defaultCursor = panning ? "grab" : landmass ? "crosshair" : "default"
    this.canvas.hoverCursor = panning ? "grab" : landmass ? "crosshair" : "move"
    this.textureTool = textureBrushes[texture] ? texture : null
    this.landmassTool = landmass

    if (drawing) {
      const brush = new PencilBrush(this.canvas)
      brush.color = ink
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
      fill: texture.filled ? ink : "rgba(255, 255, 255, 0)",
      stroke: texture.filled ? undefined : ink,
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
      stroke: ink,
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
      stroke: ink,
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
    this.mapBackground = color
    this.canvas.backgroundColor = color
    this.canvas.lowerCanvasEl.style.backgroundColor = color
    this.canvas.requestRenderAll()
    this.changed("Water color updated")
  },

  toggleLandmassEditing(object = this.canvas.getActiveObject()) {
    if (!object || object.mapKind !== "landmass" || object.mapLocked) {
      this.setStatus("Select a landmass to edit its coastline")
      return
    }

    object.mapEditing = !object.mapEditing
    object.controls = object.mapEditing
      ? controlsUtils.createPolyControls(object)
      : controlsUtils.createObjectDefaultControls()
    object.set({cornerColor: "#92400e", cornerStyle: "circle", transparentCorners: false})
    object.setCoords()
    this.canvas.setActiveObject(object)
    this.canvas.requestRenderAll()
    this.setStatus(object.mapEditing ? "Coastline vertex editing active" : "Coastline editing finished")
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
    if (!(layer in layerOrder)) return

    this.activeLayer = layer
    this.el.querySelectorAll("[data-map-layer]").forEach((button) => {
      button.classList.toggle("stone-selected", button.dataset.mapLayer === layer)
    })
    this.setStatus(`${layer[0].toUpperCase()}${layer.slice(1)} layer active`)
  },

  addStamp(kind) {
    const icon = mapIcons.find((candidate) => candidate.kind === kind)
    if (!mapIconPaths[kind] || !icon) return

    const path = new Path(mapIconPaths[kind], {
      left: this.width / 2,
      top: this.height / 2,
      originX: "center",
      originY: "center",
      fill: ink,
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
    this.changed(`${icon.name} placed`)
  },

  renderIconPicker() {
    const grid = this.el.querySelector("[data-map-icon-grid]")
    if (!grid) return

    const search = this.el.querySelector("[data-map-icon-search]")?.value.trim().toLowerCase() || ""
    const category = this.el.querySelector("[data-map-icon-category]")?.value || "all"
    const matches = mapIcons.filter((icon) => {
      const categoryMatches = category === "all" || icon.category === category
      return categoryMatches && (!search || icon.tags.includes(search))
    })

    const buttons = matches.map((icon) => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.mapAsset = icon.kind
      button.className = "stone-button group flex min-w-0 flex-col items-center gap-1 rounded-md border p-2 text-center transition"
      button.title = `${icon.name} by ${icon.author}`
      button.setAttribute("aria-label", `Place ${icon.name}`)

      const preview = document.createElement("img")
      preview.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(icon.source)}`
      preview.alt = ""
      preview.className = "size-9 object-contain opacity-75 transition group-hover:opacity-100"

      const label = document.createElement("span")
      label.className = "stone-heading w-full truncate text-[10px] font-medium"
      label.textContent = icon.name

      button.append(preview, label)
      return button
    })

    grid.replaceChildren(...buttons)

    const count = this.el.querySelector("#map-icon-count")
    if (count) count.textContent = `${matches.length} symbols`
  },

  addText() {
    this.setTool("select")

    const label = new IText("Place name", {
      left: this.width / 2,
      top: this.height / 2,
      originX: "center",
      originY: "center",
      fill: ink,
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
      undo: () => this.undo(),
      redo: () => this.redo(),
      save: () => this.save(),
      export: () => this.exportPng(),
      "zoom-in": () => this.setZoom(this.zoom + 0.1),
      "zoom-out": () => this.setZoom(this.zoom - 0.1),
      "zoom-reset": () => this.setZoom(1),
      "zoom-fit": () => this.zoomToFit(),
      "toggle-grid": () => this.setGrid(!this.gridVisible),
      "toggle-snap": () => this.setSnap(!this.snapEnabled),
      "toggle-guides": () => this.setGuides(!this.guidesEnabled),
      "center-object": () => this.centerSelection(),
      "bring-forward": () => this.reorderSelection("forward"),
      "send-backward": () => this.reorderSelection("backward"),
      "toggle-lock": () => this.toggleSelectionLock(),
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
    document.mapBackground = this.mapBackground
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
    this.canvas.lowerCanvasEl.style.backgroundImage = visible
      ? "linear-gradient(rgba(52, 47, 40, 0.09) 1px, transparent 1px), linear-gradient(90deg, rgba(52, 47, 40, 0.09) 1px, transparent 1px)"
      : "none"
    const gridSize = 32 * (this.zoom || 1)
    this.canvas.lowerCanvasEl.style.backgroundSize = `${gridSize}px ${gridSize}px`
    this.el.querySelector("[data-map-action='toggle-grid']")?.classList.toggle("stone-selected", visible)
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
    this.setStatus(`${message}. Unsaved changes.`)
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
    this.mapBackground = document.mapBackground || parchment
    this.canvas.backgroundColor = this.mapBackground
    this.canvas.lowerCanvasEl.style.backgroundColor = this.mapBackground
    this.canvas.loadFromJSON(document).then(() => {
      this.ensureItemIds()
      this.canvas.requestRenderAll()
      this.restoring = false
      this.markDirty(message)
    }).catch(() => {
      this.restoring = false
      this.setStatus("The map history could not be restored")
    })
  },

  save() {
    if (!this.ready || this.restoring || this.saving) return

    this.saving = true
    this.syncSaveState()
    this.setStatus("Saving map...")
    const document = this.serializeDocument()
    const savedVersion = this.changeVersion

    this.pushEvent("save_map", {document, width: this.width, height: this.height}, (reply) => {
      this.saving = false

      if (reply.ok) {
        this.dirty = this.changeVersion !== savedVersion
        this.setStatus(this.dirty ? "Map saved. Newer changes remain unsaved." : "Map saved")
      } else {
        this.setStatus(reply.error || "The map could not be saved")
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

  exportPng() {
    const background = this.canvas.backgroundColor
    this.canvas.backgroundColor = this.mapBackground
    this.canvas.requestRenderAll()

    const link = document.createElement("a")
    link.download = "world-map.png"
    link.href = this.canvas.toDataURL({format: "png", multiplier: 1})
    link.click()

    this.canvas.backgroundColor = background
    this.canvas.requestRenderAll()
    this.setStatus("PNG exported")
  },

  setStatus(message) {
    const status = this.el.querySelector("#ink-map-status")
    if (status) status.textContent = message
  },
}

export default InkMap
