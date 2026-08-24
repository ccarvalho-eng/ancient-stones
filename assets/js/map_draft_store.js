const databaseName = "ancient-stones-map-drafts"
const databaseVersion = 1
const storeName = "drafts"

let databasePromise

function openDatabase() {
  if (!window.indexedDB) return Promise.reject(new Error("IndexedDB is unavailable"))

  if (!databasePromise) {
    databasePromise = new Promise((resolve, reject) => {
      const request = window.indexedDB.open(databaseName, databaseVersion)

      request.onupgradeneeded = () => {
        if (!request.result.objectStoreNames.contains(storeName)) {
          request.result.createObjectStore(storeName, {keyPath: "mapId"})
        }
      }

      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error || new Error("Could not open the map draft database"))
      request.onblocked = () => reject(new Error("The map draft database is blocked"))
    }).catch((error) => {
      databasePromise = null
      throw error
    })
  }

  return databasePromise
}

async function transact(mode, operation) {
  const database = await openDatabase()

  return new Promise((resolve, reject) => {
    const transaction = database.transaction(storeName, mode)
    const request = operation(transaction.objectStore(storeName))
    let result

    request.onsuccess = () => {
      result = request.result
    }
    transaction.oncomplete = () => resolve(result)
    transaction.onerror = () => reject(transaction.error || request.error)
    transaction.onabort = () => reject(transaction.error || new Error("Map draft transaction aborted"))
  })
}

export function getMapDraft(mapId) {
  return transact("readonly", (store) => store.get(mapId))
}

export function putMapDraft(draft) {
  return transact("readwrite", (store) => store.put(draft))
}

export function deleteMapDraft(mapId) {
  return transact("readwrite", (store) => store.delete(mapId))
}
