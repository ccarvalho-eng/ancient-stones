export const gameIconCatalogUrl = "/images/game-icons/manifest.json"
export const gameIconResultLimit = 72

export function normalizeGameIcon(icon) {
  const categories = Array.isArray(icon.categories) ? icon.categories : []

  return {
    ...icon,
    pathKey: icon.path_key || icon.pathKey,
    pathUrl: icon.path_url || icon.pathUrl,
    kind: `game-icons:${icon.id}`,
    categories,
    tags: [icon.name, icon.author, icon.id, ...categories].join(" ").toLowerCase(),
  }
}

export function filterMapIcons(icons, search, category, limit = gameIconResultLimit) {
  const query = search.trim().toLowerCase()
  const matches = icons.filter((icon) => categoryMatches(icon, category) && (!query || icon.tags.includes(query)))

  return {icons: matches.slice(0, limit), total: matches.length}
}

function categoryMatches(icon, category) {
  if (category === "all") return true
  if (category.startsWith("game-icons:")) return icon.categories?.includes(category.slice(11))
  return icon.category === category
}
