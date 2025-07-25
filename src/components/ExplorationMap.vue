<!-- ExplorationMap.vue -->
<template>
  <div class="relative h-full">
    <div id="map" ref="mapRef" class="h-full w-full"></div>
    <div class="absolute top-4 right-4 flex flex-col gap-4 z-500">
      <!-- Network Controls Card -->
      <div class="network-card bg-base-100 shadow-xl rounded-lg w-[300px]">
        <div class="network-content">
          <h2 class="text-base font-bold mb-4 pb-2 border-b border-base-300">Network Layers</h2>
          
          <!-- Network List -->
          <div class="flex flex-col gap-3">
            <div 
              v-for="color in availableColors" 
              :key="color.value"
              class="network-item flex items-center gap-3 rounded-lg transition-all hover:bg-base-200"
              :class="[
                isColorVisible[color.value] ? 'bg-base-100' : 'bg-base-200/50'
              ]"
            >
              <!-- Color Indicator and Name -->
              <div class="flex items-center gap-3 flex-1">
                <button 
                  class="w-6 h-6 rounded-md transition-transform hover:scale-110 focus:outline-none ring-offset-2 ring-primary"
                  :class="{ 'ring-2': color.value === selectedColor }"
                  :style="{ 
                    backgroundColor: color.value,
                  }"
                  @click="handleColorClick(color)"
                  :title="isAddingTile ? 'Select network' : 'Toggle visibility'"
                ></button>

                <span class="flex-1 text-sm font-medium">{{ color.name }}</span>
              </div>

              <!-- Visibility Toggle -->
              <div class="form-control">
                <input 
                  type="checkbox" 
                  class="toggle toggle-primary toggle-sm"
                  :checked="isColorVisible[color.value]"
                  @change="toggleColorVisibility(color.value)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Edit Mode Button -->
      <button 
        @click="showPasswordModal"
        class="btn btn-primary shadow-lg w-[300px]"
        :class="{ 'btn-secondary': isAddingTile }"
      >
        <span class="flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" :class="{ 'rotate-45': isAddingTile }" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          {{ isAddingTile ? 'Done' : 'Edit Tiles' }}
        </span>
      </button>

      <!-- Stats Card -->
      <div class="network-card bg-base-100 shadow-xl rounded-lg w-[300px]">
        <div class="network-content">
          <div class="stats stats-vertical shadow bg-base-200/50 w-full">
            <div class="stat">
              <div class="stat-title">Total Tiles</div>
              <div class="stat-value text-primary">{{ totalTilesCount }}</div>
              <div class="stat-desc">Across all networks</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading Indicator -->
    <div v-if="isLoading" class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 z-1000">
      <div class="network-card bg-white rounded-lg shadow-lg">
        <p class="text-lg font-bold mb-4">Loading Tiles...</p>
        <div class="w-full bg-gray-200 rounded-full h-2.5">
          <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: `${loadingProgress}%` }"></div>
        </div>
        <p class="text-sm text-gray-700 mt-2">{{ loadingProgress }}%</p>
      </div>
    </div>

    <!-- Password Modal -->
    <dialog id="password_modal" class="modal modal-bottom sm:modal-middle">
      <div class="modal-box network-card">
        <h3 class="font-bold text-lg mb-4">Enter Password</h3>
        <div class="form-control">
          <input 
            type="password" 
            v-model="passwordInput"
            placeholder="Enter password to edit tiles"
            class="input input-bordered w-full"
            @keyup.enter="checkPassword"
          />
          <label class="label" v-if="passwordError">
            <span class="label-text-alt text-error">{{ passwordError }}</span>
          </label>
        </div>
        <div class="modal-action">
          <button class="btn btn-ghost" @click="closePasswordModal">Cancel</button>
          <button class="btn btn-primary" @click="checkPassword">Confirm</button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, reactive } from 'vue'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import * as turf from '@turf/turf'
import { supabase } from '../lib/supabaseClient'

// Fix Leaflet icon issue
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png'
})

// State
const mapRef = ref(null)
const map = ref(null)
const isAddingTile = ref(false)
const markedTilesLayer = ref(null)
const gridLayer = ref(null)
const markedTiles = ref({}) // Changed to object to store multiple colors
const selectedColor = ref('#2196f3') // Default blue color
const isColorVisible = reactive({}) // Track visibility of each color layer

// Password protection
const passwordInput = ref('')
const passwordError = ref('')
const CORRECT_PASSWORD = import.meta.env.VITE_PASSWORD

function showPasswordModal() {
  if (isAddingTile.value) {
    // If already in edit mode, just exit
    isAddingTile.value = false
    map.value.getContainer().style.cursor = ''
    return
  }

  // Reset password state
  passwordInput.value = ''
  passwordError.value = ''
  
  // Show modal
  const modal = document.getElementById('password_modal')
  modal.showModal()
}

function closePasswordModal() {
  const modal = document.getElementById('password_modal')
  modal.close()
  passwordInput.value = ''
  passwordError.value = ''
}

function checkPassword() {
  if (passwordInput.value === CORRECT_PASSWORD) {
    closePasswordModal()
    isAddingTile.value = true
    map.value.getContainer().style.cursor = 'pointer'
  } else {
    passwordError.value = 'Incorrect password'
    passwordInput.value = ''
  }
}

// Available colors for tiles with priority (higher number = shows on top)
const availableColors = [
  { name: 'Trains', value: '#2196f3', priority: 4 },
  { name: 'Bus', value: '#4caf50', priority: 5 },
  { name: 'Voiture', value: '#ff9800', priority: 6 },
  { name: 'Vélo', value: '#f44336', priority: 3 },
  { name: 'Marche', value: '#795548', priority: 2 },
  { name: 'Villes visitées', value: '#9c27b0', priority: 1 },
  { name: 'Aéreports visités', value: '#009688', priority: 7 },
  { name: 'Bonus 3', value: '#e91e63', priority: 8 },
]

// Initialize color visibility
onMounted(() => {
  // Initialize visibility in onMounted to ensure reactivity
  availableColors.forEach(color => {
    isColorVisible[color.value] = true
  })
})

// Computed total tiles count
const totalTilesCount = computed(() => {
  return Object.values(markedTiles.value)
    .reduce((total, colorSet) => total + colorSet.size, 0)
})

// Constants
const TILE_SIZE = 2000 // 2km in meters (changed from 5000)
const EARTH_RADIUS = 6378137 // Earth's radius in meters
const GRID_SIZE = TILE_SIZE // Grid size in meters
const MIN_GRID_ZOOM = 11 // Increased minimum zoom level since tiles are smaller

// Helper function to convert meters to degrees at a given latitude
function metersToDegreesAtLatitude(meters, latitude) {
  const latRad = latitude * Math.PI / 180
  return meters / (EARTH_RADIUS * Math.cos(latRad) * Math.PI / 180)
}

// Helper function to convert meters to degrees of latitude
function metersToLatitudeDegrees(meters) {
  return (meters / EARTH_RADIUS) * (180 / Math.PI)
}

// Create a grid cell polygon
function createGridCell(lat, lng) {
  const latDelta = metersToLatitudeDegrees(GRID_SIZE)
  const lngDelta = metersToDegreesAtLatitude(GRID_SIZE, lat)
  
  return {
    type: 'Feature',
    geometry: {
      type: 'Polygon',
      coordinates: [[
        [lng, lat],
        [lng + lngDelta, lat],
        [lng + lngDelta, lat + latDelta],
        [lng, lat + latDelta],
        [lng, lat]
      ]]
    },
    properties: {
      gridId: `${lat.toFixed(6)}_${lng.toFixed(6)}`
    }
  }
}

// Initialize map
onMounted(async () => {
  // Create map
  map.value = L.map(mapRef.value, {
    center: [48.8566, 2.3522], // Paris
    zoom: 13
  })
  
  // Add OpenStreetMap tiles
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19
  }).addTo(map.value)

  // Initialize layers
  gridLayer.value = L.featureGroup().addTo(map.value)
  markedTilesLayer.value = L.featureGroup().addTo(map.value)

  // Load existing data
  await loadData()

  // Add move end handler to update grid
  map.value.on('moveend', updateVisibleGrid)
  map.value.on('zoomend', () => {
    const zoom = map.value.getZoom()
    if (zoom < MIN_GRID_ZOOM) {
      gridLayer.value.clearLayers()
    } else {
      updateVisibleGrid()
    }
  })

  // Initial grid update
  updateVisibleGrid()
})

onUnmounted(() => {
  if (map.value) {
    map.value.remove()
  }
})

// Clear all layers
function clearLayers() {
  if (markedTilesLayer.value) markedTilesLayer.value.clearLayers()
  if (gridLayer.value) gridLayer.value.clearLayers()
}

// Update the visible grid based on map bounds
function updateVisibleGrid() {
  if (!map.value || !gridLayer.value) return

  const zoom = map.value.getZoom()
  if (zoom < MIN_GRID_ZOOM) return

  gridLayer.value.clearLayers()

  const bounds = map.value.getBounds()
  const sw = bounds.getSouthWest()
  const ne = bounds.getNorthEast()

  // Calculate grid steps
  const latStep = metersToLatitudeDegrees(GRID_SIZE)
  const startLat = Math.floor(sw.lat / latStep) * latStep
  const endLat = Math.ceil(ne.lat / latStep) * latStep

  for (let lat = startLat; lat < endLat; lat += latStep) {
    const lngStep = metersToDegreesAtLatitude(GRID_SIZE, lat)
    const startLng = Math.floor(sw.lng / lngStep) * lngStep
    const endLng = Math.ceil(ne.lng / lngStep) * lngStep

    for (let lng = startLng; lng < endLng; lng += lngStep) {
      const cell = createGridCell(lat, lng)
      const gridId = cell.properties.gridId
      const isMarked = markedTiles.value[selectedColor.value]?.has(gridId)

      // Only show grid for unmarked cells (marked cells are shown in markedTilesLayer)
      if (!isMarked) {
        const gridCell = L.geoJSON(cell, {
          style: {
            color: '#999',
            weight: 1,
            opacity: 0.7,
            fillOpacity: 0.1,
            fillColor: '#999'
          }
        })

        if (isAddingTile.value) {
          gridCell.on('click', () => handleGridClick(cell))
        }

        gridCell.addTo(gridLayer.value)
      }
    }
  }
}

// Handle color button click
function handleColorClick(color) {
  if (isAddingTile.value) {
    // In edit mode, select the color
    selectedColor.value = color.value
  }
}

// Toggle color visibility
function toggleColorVisibility(colorValue) {
  console.log('Toggling visibility for', colorValue, 'from', isColorVisible[colorValue], 'to', !isColorVisible[colorValue])
  isColorVisible[colorValue] = !isColorVisible[colorValue]
  updateMarkedTiles()
}

// Handle grid cell click
async function handleGridClick(cell) {
  const gridId = cell.properties.gridId
  const colorSet = markedTiles.value[selectedColor.value] || new Set()
  const isMarked = colorSet.has(gridId)

  try {
    if (isMarked) {
      // Remove tile for this color
      const { error } = await supabase
        .from('tiles')
        .delete()
        .eq('schema', 'statslife')
        .eq('grid_id', gridId)
        .eq('color', selectedColor.value)

      if (error) throw error

      colorSet.delete(gridId)
      if (colorSet.size === 0) {
        delete markedTiles.value[selectedColor.value]
      } else {
        markedTiles.value[selectedColor.value] = colorSet
      }
    } else {
      // Add tile for this color
      const colorInfo = availableColors.find(c => c.value === selectedColor.value)
      const { error } = await supabase
        .from('tiles')
        .insert([{
          schema: 'statslife',
          grid_id: gridId,
          color: selectedColor.value,
          priority: colorInfo.priority,
          geom: cell.geometry,
          center_point: turf.centroid(cell).geometry,
          visited_at: new Date().toISOString()
        }])

      if (error) throw error

      if (!markedTiles.value[selectedColor.value]) {
        markedTiles.value[selectedColor.value] = new Set()
      }
      markedTiles.value[selectedColor.value].add(gridId)
    }

    // Update layers
    updateMarkedTiles()
    updateVisibleGrid()
  } catch (error) {
    console.error('Error toggling tile:', error)
  }
}

// Update marked tiles layer
function updateMarkedTiles() {
  if (!markedTilesLayer.value) return

  markedTilesLayer.value.clearLayers()

  // Get visible colors sorted by priority
  const visibleColors = availableColors
    .filter(color => isColorVisible[color.value])
    .sort((a, b) => a.priority - b.priority)

  // Create a Set to track which tiles have been rendered
  const renderedTiles = new Set()

  // Render tiles in priority order
  visibleColors.forEach(colorInfo => {
    const colorTiles = markedTiles.value[colorInfo.value] || new Set()
    
    colorTiles.forEach(gridId => {
      if (!renderedTiles.has(gridId)) {
        const [lat, lng] = gridId.split('_').map(Number)
        const cell = createGridCell(lat, lng)
        
        L.geoJSON(cell, {
          style: {
            color: colorInfo.value,
            weight: 1,
            opacity: 0.7,
            fillOpacity: 0.3,
            fillColor: colorInfo.value
          }
        })
        .on('click', () => {
          if (isAddingTile.value) {
            handleGridClick(cell)
          }
        })
        .addTo(markedTilesLayer.value)

        renderedTiles.add(gridId)
      }
    })
  })
}

// Add loading state
const isLoading = ref(false)
const loadingProgress = ref(0)

// Load data from Supabase with pagination
async function loadData() {
  try {
    clearLayers()
    markedTiles.value = {}
    isLoading.value = true
    loadingProgress.value = 0

    let hasMore = true
    let page = 0
    const pageSize = 1000 // Adjust this based on performance

    while (hasMore) {
      const { data: tiles, error: tilesError, count } = await supabase
        .from('tiles')
        .select('grid_id, color', { count: 'exact' })
        .eq('schema', 'statslife')
        .range(page * pageSize, (page + 1) * pageSize - 1)

      if (tilesError) throw tilesError

      if (tiles) {
        tiles.forEach(tile => {
          try {
            const color = tile.color
            if (!markedTiles.value[color]) {
              markedTiles.value[color] = new Set()
            }
            markedTiles.value[color].add(tile.grid_id)
          } catch (e) {
            console.error('Error processing tile:', e)
          }
        })

        // Update progress
        const total = count || tiles.length
        loadingProgress.value = Math.min(((page + 1) * pageSize / total) * 100, 100)

        // Check if we need to load more
        hasMore = tiles.length === pageSize
        page++

        // Update display periodically to show progress
        if (page % 2 === 0) {
          await updateMarkedTiles()
        }
      } else {
        hasMore = false
      }
    }

    // Final update of the display
    await updateMarkedTiles()
    isLoading.value = false
  } catch (error) {
    console.error('Error loading data:', error)
    isLoading.value = false
  }
}

// Toggle tile creation mode
function toggleTileMode() {
  isAddingTile.value = !isAddingTile.value
  if (isAddingTile.value) {
    map.value.getContainer().style.cursor = 'pointer'
  } else {
    map.value.getContainer().style.cursor = ''
  }
  updateVisibleGrid()
  updateMarkedTiles()
}
</script>

<style>
/* Only keep styles that are necessary for Leaflet */
.map-container {
  height: 100%;
  width: 100%;
}

#map {
  height: 100%;
  width: 100%;
}

/* Custom styles for better toggle appearance */
.toggle-sm {
  --toggle-width: 2.5rem;
  --toggle-height: 1.25rem;
}
</style> 