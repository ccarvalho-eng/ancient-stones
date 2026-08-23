import assert from "node:assert/strict"
import test from "node:test"

import {
  appendDistinctPoint,
  contrastingInk,
  erasableInkTarget,
  insertMidpoint,
  removeVertex,
  roughenCoastline,
  zoomFromPinch,
} from "./map_geometry.mjs"

test("appendDistinctPoint ignores consecutive points that are too close", () => {
  const points = [{x: 10, y: 10}]

  assert.equal(appendDistinctPoint(points, {x: 11, y: 10}), points)
  assert.deepEqual(appendDistinctPoint(points, {x: 13, y: 10}), [
    {x: 10, y: 10},
    {x: 13, y: 10},
  ])
})

test("roughenCoastline keeps duplicate points finite", () => {
  const result = roughenCoastline(
    [{x: 10, y: 10}, {x: 10, y: 10}, {x: 20, y: 20}],
    50,
    () => 0.75,
  )

  assert.ok(result.every(({x, y}) => Number.isFinite(x) && Number.isFinite(y)))
})

test("zoomFromPinch scales and clamps the canvas zoom", () => {
  assert.equal(zoomFromPinch(1, 100, 150), 1.5)
  assert.equal(zoomFromPinch(1.5, 100, 300), 4)
  assert.equal(zoomFromPinch(0.5, 100, 10), 0.05)
  assert.equal(zoomFromPinch(1, 0, 200), 1)
})

test("contrastingInk keeps tools visible on light and dark canvases", () => {
  assert.equal(contrastingInk("#21252b"), "#e6e2da")
  assert.equal(contrastingInk("#e7ddc4"), "#342f28")
})

test("insertMidpoint adds a vertex between coastline points", () => {
  const points = [{x: 0, y: 0}, {x: 10, y: 0}, {x: 10, y: 10}]

  assert.deepEqual(insertMidpoint(points, 0), [
    {x: 0, y: 0},
    {x: 5, y: 0},
    {x: 10, y: 0},
    {x: 10, y: 10},
  ])
})

test("removeVertex preserves the polygon minimum", () => {
  const triangle = [{x: 0, y: 0}, {x: 10, y: 0}, {x: 10, y: 10}]
  const polygon = [...triangle, {x: 0, y: 10}]

  assert.equal(removeVertex(triangle, 0), triangle)
  assert.deepEqual(removeVertex(polygon, 1), [triangle[0], triangle[2], polygon[3]])
})

test("erasableInkTarget only accepts pencil strokes", () => {
  const ink = {mapKind: "ink"}

  assert.equal(erasableInkTarget(ink), ink)
  assert.equal(erasableInkTarget({mapKind: "landmass"}), null)
  assert.equal(erasableInkTarget({mapKind: "label"}), null)
  assert.equal(erasableInkTarget(null), null)
})
