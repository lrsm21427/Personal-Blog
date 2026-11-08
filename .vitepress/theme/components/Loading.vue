<template>
  <Teleport to="body">
    <Transition name="fade" mode="out-in">
      <div v-if="loadingStatus" class="loading" @click="loadingStatus = false">
        <img ref="flowerRef" class="flower" :src="frameUrls[0]" alt="页面加载中" />
        <span :class="['tip', { show: showTip }]">一直显示？点击任意区域即可关闭</span>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { animate } from "animejs";
import { storeToRefs } from "pinia";
import { mainStore } from "@/store";

const store = mainStore();
const { loadingStatus } = storeToRefs(store);
const flowerRef = ref(null);
const frameUrls = Array.from(
  { length: 8 },
  (_, index) => `/loading-flower-bloom-frames/frame-${String(index + 1).padStart(2, "0")}.png`,
);

const showTip = ref(false);
const showTimeOut = ref(null);
let flowerAnimation = null;

const stopFlowerAnimation = () => {
  flowerAnimation?.cancel();
  flowerAnimation = null;
};

const startFlowerAnimation = async () => {
  if (typeof window === "undefined") return;
  await nextTick();
  const flower = flowerRef.value;
  if (!flower) return;

  stopFlowerAnimation();
  flower.src = frameUrls[0];

  frameUrls.forEach((url) => {
    const image = new Image();
    image.src = url;
  });

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    flower.src = frameUrls[frameUrls.length - 1];
    return;
  }

  const frameState = { value: 0 };
  let lastFrame = -1;

  flowerAnimation = animate(frameState, {
    value: frameUrls.length - 0.001,
    duration: 560,
    ease: `steps(${frameUrls.length})`,
    loop: true,
    loopDelay: 220,
    onUpdate: () => {
      const frame = Math.min(frameUrls.length - 1, Math.floor(frameState.value));
      if (frame !== lastFrame) {
        flower.src = frameUrls[frame];
        lastFrame = frame;
      }
    },
  });
};

watch(
  () => loadingStatus.value,
  (val) => {
    clearTimeout(showTimeOut.value);
    if (val) {
      startFlowerAnimation();
      showTimeOut.value = setTimeout(() => {
        showTip.value = true;
      }, 3000);
    } else {
      showTip.value = false;
      stopFlowerAnimation();
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  clearTimeout(showTimeOut.value);
  stopFlowerAnimation();
});
</script>

<style lang="scss" scoped>
.loading {
  position: fixed;
  top: 0;
  left: 0;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100vw;
  height: 100vh;
  background-color: var(--main-card-background);

  .flower {
    display: block;
    width: 92px;
    height: 92px;
    object-fit: contain;
  }

  .tip {
    position: absolute;
    bottom: 2rem;
    font-size: 14px;
    opacity: 0;
    transition: opacity 0.3s;

    &.show {
      opacity: 0.6;
    }
  }
}

@media (prefers-reduced-motion: reduce) {
  .loading .flower {
    transform: none !important;
  }
}
</style>
