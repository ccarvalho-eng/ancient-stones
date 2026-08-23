import assert from "node:assert/strict"
import test from "node:test"

import {
  filterMapIcons,
  normalizeGameIcon,
} from "./game_icon_library.mjs"

test("normalizeGameIcon creates a searchable, namespaced map symbol", () => {
  const icon = normalizeGameIcon({
    id: "delapouite/castle",
    name: "Castle",
    author: "delapouite",
    categories: ["building", "medieval-fantasy"],
    path_key: "castle",
    path_url: "/paths/delapouite.json",
    url: "/castle.svg",
  })

  assert.equal(icon.kind, "game-icons:delapouite/castle")
  assert.equal(icon.pathKey, "castle")
  assert.equal(icon.pathUrl, "/paths/delapouite.json")
  assert.match(icon.tags, /castle/)
  assert.match(icon.tags, /building/)
})

test("filterMapIcons filters catalog categories and limits rendered results", () => {
  const icons = [
    normalizeGameIcon({id: "lorc/dragon", name: "Dragon", author: "lorc", categories: ["creature"]}),
    normalizeGameIcon({id: "lorc/castle", name: "Castle", author: "lorc", categories: ["building"]}),
    normalizeGameIcon({id: "lorc/tower", name: "Tower", author: "lorc", categories: ["building"]}),
  ]

  assert.deepEqual(filterMapIcons(icons, "castle", "all").icons.map(({name}) => name), ["Castle"])
  assert.deepEqual(filterMapIcons(icons, "castle", "game-icons:creature").icons, [])
  assert.equal(filterMapIcons(icons, "", "game-icons:building", 1).total, 2)
  assert.equal(filterMapIcons(icons, "", "game-icons:building", 1).icons.length, 1)
})
