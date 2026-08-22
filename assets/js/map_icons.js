import ancientRuinsSvg from "../vendor/map-icons/ancient-ruins.svg"
import barnSvg from "../vendor/map-icons/barn.svg"
import blacksmithSvg from "../vendor/map-icons/blacksmith.svg"
import campfireSvg from "../vendor/map-icons/campfire.svg"
import castleSvg from "../vendor/map-icons/castle.svg"
import castleRuinsSvg from "../vendor/map-icons/castle-ruins.svg"
import caveEntranceSvg from "../vendor/map-icons/cave-entrance.svg"
import churchSvg from "../vendor/map-icons/church.svg"
import compassSvg from "../vendor/map-icons/compass.svg"
import cryptEntranceSvg from "../vendor/map-icons/crypt-entrance.svg"
import dolmenSvg from "../vendor/map-icons/dolmen.svg"
import drakkarSvg from "../vendor/map-icons/drakkar.svg"
import drakkarDragonSvg from "../vendor/map-icons/drakkar-dragon.svg"
import forestSvg from "../vendor/map-icons/forest.svg"
import graveyardSvg from "../vendor/map-icons/graveyard.svg"
import greekTempleSvg from "../vendor/map-icons/greek-temple.svg"
import harborDockSvg from "../vendor/map-icons/harbor-dock.svg"
import hillsSvg from "../vendor/map-icons/hills.svg"
import hillFortSvg from "../vendor/map-icons/hill-fort.svg"
import islandSvg from "../vendor/map-icons/island.svg"
import krakenTentacleSvg from "../vendor/map-icons/kraken-tentacle.svg"
import lighthouseSvg from "../vendor/map-icons/lighthouse.svg"
import medievalGateSvg from "../vendor/map-icons/medieval-gate.svg"
import medievalVillageSvg from "../vendor/map-icons/medieval-village-01.svg"
import menhirSvg from "../vendor/map-icons/menhir.svg"
import militaryFortSvg from "../vendor/map-icons/military-fort.svg"
import mineWagonSvg from "../vendor/map-icons/mine-wagon.svg"
import mountainCaveSvg from "../vendor/map-icons/mountain-cave.svg"
import obeliskSvg from "../vendor/map-icons/obelisk.svg"
import pagodaSvg from "../vendor/map-icons/pagoda.svg"
import palisadeSvg from "../vendor/map-icons/palisade.svg"
import peaksSvg from "../vendor/map-icons/peaks.svg"
import pineTreeSvg from "../vendor/map-icons/pine-tree.svg"
import ravenSvg from "../vendor/map-icons/raven.svg"
import riverSvg from "../vendor/map-icons/river.svg"
import roadSvg from "../vendor/map-icons/road.svg"
import runeStoneSvg from "../vendor/map-icons/rune-stone.svg"
import shipWheelSvg from "../vendor/map-icons/ship-wheel.svg"
import smokingVolcanoSvg from "../vendor/map-icons/smoking-volcano.svg"
import spikedDragonHeadSvg from "../vendor/map-icons/spiked-dragon-head.svg"
import stoneBridgeSvg from "../vendor/map-icons/stone-bridge.svg"
import stableSvg from "../vendor/map-icons/stable.svg"
import tavernSignSvg from "../vendor/map-icons/tavern-sign.svg"
import trailSvg from "../vendor/map-icons/trail.svg"
import valleySvg from "../vendor/map-icons/valley.svg"
import vikingChurchSvg from "../vendor/map-icons/viking-church.svg"
import vikingLonghouseSvg from "../vendor/map-icons/viking-longhouse.svg"
import vikingShieldSvg from "../vendor/map-icons/viking-shield.svg"
import villageSvg from "../vendor/map-icons/village.svg"
import volcanoSvg from "../vendor/map-icons/volcano.svg"
import waterfallSvg from "../vendor/map-icons/waterfall.svg"
import waterMillSvg from "../vendor/map-icons/water-mill.svg"
import watchtowerSvg from "../vendor/map-icons/watchtower.svg"
import wellSvg from "../vendor/map-icons/well.svg"
import windmillSvg from "../vendor/map-icons/windmill.svg"
import wolfHowlSvg from "../vendor/map-icons/wolf-howl.svg"
import woodenSignSvg from "../vendor/map-icons/wooden-sign.svg"

export const mapIcons = [
  icon("mountain", "Peaks", "terrain", "Lorc", peaksSvg, "mountain summit snow ridge"),
  icon("hills", "Hills", "terrain", "Delapouite", hillsSvg, "rolling hills dunes meadow"),
  icon("valley", "Valley", "terrain", "Lorc", valleySvg, "valley canyon ravine lowland"),
  icon("volcano", "Volcano", "terrain", "Lorc", volcanoSvg, "volcano lava eruption mountain"),
  icon("smoking-volcano", "Smoking volcano", "terrain", "Delapouite", smokingVolcanoSvg, "volcano smoke caldera"),
  icon("mountain-cave", "Mountain cave", "terrain", "Delapouite", mountainCaveSvg, "cave mine mountain entrance"),
  icon("cave-entrance", "Cave entrance", "terrain", "Delapouite", caveEntranceSvg, "cave mine tunnel"),
  icon("island", "Island", "terrain", "Delapouite", islandSvg, "island coast sea ocean"),
  icon("waterfall", "Waterfall", "terrain", "Delapouite", waterfallSvg, "water waterfall cliff river"),
  icon("river", "River", "terrain", "Delapouite", riverSvg, "river stream water"),
  icon("forest", "Forest", "nature", "Delapouite", forestSvg, "forest woods trees"),
  icon("settlement", "Settlement", "settlements", "Delapouite", villageSvg, "village town houses"),
  icon("castle", "Castle", "settlements", "Delapouite", castleSvg, "castle keep fortress"),
  icon("shrine", "Shrine", "settlements", "Delapouite", greekTempleSvg, "shrine temple ruins"),
  icon("church", "Church", "settlements", "Delapouite", churchSvg, "church chapel religion"),
  icon("compass-rose", "Compass rose", "routes", "Lorc", compassSvg, "compass wind rose north navigation map"),
  icon("pagoda", "Pagoda", "settlements", "Delapouite", pagodaSvg, "pagoda temple tower"),
  icon("windmill", "Windmill", "settlements", "Delapouite", windmillSvg, "windmill farm mill"),
  icon("watchtower", "Watchtower", "settlements", "Delapouite", watchtowerSvg, "watchtower tower guard"),
  icon("lighthouse", "Lighthouse", "settlements", "Delapouite", lighthouseSvg, "lighthouse beacon coast"),
  icon("harbor", "Harbor", "settlements", "Delapouite", harborDockSvg, "harbor dock port pier"),
  icon("road", "Road", "routes", "Delapouite", roadSvg, "road route path"),
  icon("trail", "Trail", "routes", "Delapouite", trailSvg, "trail path route"),
  icon("bridge", "Stone bridge", "routes", "Delapouite", stoneBridgeSvg, "bridge crossing river stone"),
  icon("mine", "Mine wagon", "routes", "Delapouite", mineWagonSvg, "mine wagon ore quarry"),
  icon("ship", "Drakkar", "routes", "Delapouite", drakkarSvg, "ship boat viking sea"),
  icon("ship-wheel", "Ship wheel", "routes", "Delapouite", shipWheelSvg, "ship wheel harbor sea"),
  icon("signpost", "Signpost", "routes", "Lorc", woodenSignSvg, "signpost direction road"),
  icon("camp", "Campfire", "landmarks", "Lorc", campfireSvg, "campfire camp rest"),
  icon("obelisk", "Obelisk", "landmarks", "Delapouite", obeliskSvg, "obelisk monument landmark"),
  icon("ruins", "Ancient ruins", "landmarks", "Delapouite", ancientRuinsSvg, "ancient ruins stones landmark"),
  icon("viking-longhouse", "Viking longhouse", "nordic", "Delapouite", vikingLonghouseSvg, "norse hall settlement home"),
  icon("viking-church", "Viking church", "nordic", "Delapouite", vikingChurchSvg, "norse stave church temple"),
  icon("rune-stone", "Rune stone", "nordic", "Lorc", runeStoneSvg, "norse runestone monument magic"),
  icon("menhir", "Menhir", "nordic", "Delapouite", menhirSvg, "standing stone monument"),
  icon("dolmen", "Dolmen", "nordic", "Delapouite", dolmenSvg, "stone tomb monument"),
  icon("dragon-longship", "Dragon longship", "nordic", "Delapouite", drakkarDragonSvg, "viking drakkar ship boat"),
  icon("viking-shield", "Viking shield", "nordic", "Delapouite", vikingShieldSvg, "round shield clan stronghold"),
  icon("raven", "Raven", "nordic", "Lorc", ravenSvg, "bird odin omen"),
  icon("wolf-howl", "Howling wolf", "nordic", "Lorc", wolfHowlSvg, "wolf beast wilderness"),
  icon("pine-tree", "Pine tree", "nordic", "Lorc", pineTreeSvg, "pine evergreen taiga forest"),
  icon("medieval-village", "Medieval village", "medieval", "Caro Asercion", medievalVillageSvg, "village town settlement houses"),
  icon("hill-fort", "Hill fort", "medieval", "Delapouite", hillFortSvg, "fort stronghold hill settlement"),
  icon("military-fort", "Military fort", "medieval", "Delapouite", militaryFortSvg, "fortress garrison stronghold"),
  icon("castle-ruins", "Castle ruins", "medieval", "Delapouite", castleRuinsSvg, "ruined castle keep landmark"),
  icon("medieval-gate", "Medieval gate", "medieval", "Delapouite", medievalGateSvg, "city gate walls entrance"),
  icon("palisade", "Palisade", "medieval", "Delapouite", palisadeSvg, "wooden wall fortification"),
  icon("blacksmith", "Blacksmith", "medieval", "Delapouite", blacksmithSvg, "forge smith workshop anvil"),
  icon("tavern", "Tavern", "medieval", "Delapouite", tavernSignSvg, "inn ale lodging sign"),
  icon("stable", "Stable", "medieval", "Delapouite", stableSvg, "horses settlement building"),
  icon("barn", "Barn", "medieval", "Delapouite", barnSvg, "farm agriculture building"),
  icon("water-mill", "Water mill", "medieval", "Caro Asercion", waterMillSvg, "mill river settlement"),
  icon("well", "Well", "medieval", "Delapouite", wellSvg, "water village landmark"),
  icon("graveyard", "Graveyard", "medieval", "Delapouite", graveyardSvg, "cemetery graves death"),
  icon("crypt", "Crypt entrance", "medieval", "Delapouite", cryptEntranceSvg, "crypt tomb dungeon entrance"),
  icon("sea-monster", "Sea monster", "creatures", "Delapouite", krakenTentacleSvg, "kraken sea monster tentacle"),
  icon("dragon", "Dragon", "creatures", "Delapouite", spikedDragonHeadSvg, "dragon beast monster"),
]

export const mapIconPaths = Object.fromEntries(mapIcons.map(({kind, path}) => [kind, path]))

function icon(kind, name, category, author, source, tags) {
  const paths = [...source.matchAll(/<path[^>]*d="([^"]+)"/g)]

  return {
    kind,
    name,
    category,
    author,
    source,
    tags: `${name} ${category} ${tags}`.toLowerCase(),
    path: paths.at(-1)?.[1] || "",
  }
}
