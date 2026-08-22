import assert from "node:assert/strict"
import test from "node:test"

import {appendDistinctPoint, roughenCoastline, zoomFromPinch} from "./map_geometry.mjs"

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
