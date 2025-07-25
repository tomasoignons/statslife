<script setup>
import ExplorationMap from './components/ExplorationMap.vue'
</script>

<template>
  <div class="h-screen w-screen overflow-hidden">
    <ExplorationMap />
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  overflow: hidden;
}

#app {
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
}
</style>
