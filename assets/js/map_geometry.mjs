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
