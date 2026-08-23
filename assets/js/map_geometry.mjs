export function appendDistinctPoint(points, point, minimumDistance = 2) {
  const previous = points.at(-1)

  if (previous && Math.hypot(point.x - previous.x, point.y - previous.y) < minimumDistance) {
    return points
  }

  return [...points, {x: point.x, y: point.y}]
}

export function roughenCoastline(points, roughness, random = Math.random) {
  if (roughness === 0) return points

  return points.flatMap((point, index) => {
    const next = points[(index + 1) % points.length]
    const dx = next.x - point.x
    const dy = next.y - point.y
    const distance = Math.hypot(dx, dy)

    if (distance === 0) return [point]

    const offset = (random() - 0.5) * distance * roughness * 0.025
    const midpoint = {
      x: (point.x + next.x) / 2 - dy / distance * offset,
      y: (point.y + next.y) / 2 + dx / distance * offset,
    }

    return [point, midpoint]
  })
}

export function zoomFromPinch(startZoom, startDistance, currentDistance) {
  if (startDistance <= 0) return startZoom

  return Math.min(4, Math.max(0.05, startZoom * (currentDistance / startDistance)))
}

export function contrastingInk(background) {
  const match = /^#([0-9a-f]{6})$/i.exec(background)
  if (!match) return "#342f28"

  const color = Number.parseInt(match[1], 16)
  const red = (color >> 16) & 255
  const green = (color >> 8) & 255
  const blue = color & 255
  const luminance = (red * 0.2126 + green * 0.7152 + blue * 0.0722) / 255

  return luminance < 0.45 ? "#e6e2da" : "#342f28"
}

export function insertMidpoint(points, edgeIndex) {
  const point = points[edgeIndex]
  const next = points[(edgeIndex + 1) % points.length]
  const midpoint = {x: (point.x + next.x) / 2, y: (point.y + next.y) / 2}

  return [...points.slice(0, edgeIndex + 1), midpoint, ...points.slice(edgeIndex + 1)]
}

export function removeVertex(points, vertexIndex) {
  if (points.length <= 3) return points

  return points.filter((_point, index) => index !== vertexIndex)
}

export function erasableInkTarget(target) {
  return target?.mapKind === "ink" ? target : null
}
