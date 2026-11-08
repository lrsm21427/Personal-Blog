<template>
  <Teleport to="body">
    <Transition name="fade" mode="out-in">
      <div v-if="loadingStatus" class="loading" @click="dismissLoading">
        <svg class="flower-color-defs" aria-hidden="true" width="0" height="0">
          <defs>
            <filter id="loading-petal-pink" color-interpolation-filters="sRGB">
              <!-- 仅选中蓝色分量高于绿色的粉色区域，排除白底、枝条和绿叶。 -->
              <feColorMatrix
                in="SourceGraphic"
                type="matrix"
                values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 -12 12 0 0"
                result="pinkMask"
              />
              <feColorMatrix
                in="SourceGraphic"
                type="matrix"
                values="1 0 0 0 0.14  0 1.3 0 0 -0.031  0 0 1.55 0 -0.204  0 0 0 1 0"
                result="lightPink"
              />
              <feComposite in="lightPink" in2="pinkMask" operator="in" result="petals" />
              <feComposite in="SourceGraphic" in2="pinkMask" operator="out" result="rest" />
              <feComposite in="petals" in2="rest" operator="arithmetic" k2="1" k3="1" />
            </filter>
          </defs>
        </svg>
        <div ref="flowerRef" class="flower" role="img" aria-label="页面加载中">
          <img
            v-for="(url, index) in frameUrls"
            :key="url"
            :src="url"
            :style="{
              visibility: index === 0 ? 'visible' : 'hidden',
              transform: frameTransforms[index],
            }"
            alt=""
            aria-hidden="true"
          />
        </div>
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
  { length: 30 },
  (_, index) => `/flower-branch-leaves-30/frame-${String(index + 1).padStart(2, "0")}.png`,
);

// 原始帧图为 192px。以不参与开花运动的右上枝端对齐，
// 避免按花瓣外接框居中而把花瓣展开误判为整体位移。
const branchTips = [
  [176, 49],
  [175, 49],
  [174, 49],
  [172, 49],
  [171, 49],
  [170, 49],
  [176, 44],
  [175, 43],
  [174, 43],
  [173, 43],
  [172, 43],
  [170, 43],
  [176, 40],
  [175, 39],
  [174, 39],
  [173, 39],
  [171, 40],
  [170, 39],
  [177, 35],
  [175, 35],
  [174, 35],
  [173, 35],
  [172, 35],
  [170, 36],
  [177, 32],
  [175, 32],
  [174, 32],
  [173, 32],
  [172, 32],
  [170, 32],
];
const frameTransforms = branchTips.map(
  ([x, y]) => `translate(${((171 - x) / 192) * 100}%, ${((32 - y) / 192) * 100}%)`,
);

const showTip = ref(false);
const showTimeOut = ref(null);
let flowerAnimation = null;
let animationVersion = 0;
let framesReady;
let initialLoadingTimer = null;

const dismissLoading = () => {
  if (!store.initialLoading) loadingStatus.value = false;
};

const stopFlowerAnimation = () => {
  animationVersion++;
  flowerAnimation?.cancel();
  flowerAnimation = null;
};

const startFlowerAnimation = async () => {
  if (typeof window === "undefined") return;
  await nextTick();
  const flower = flowerRef.value;
  if (!flower) return;

  stopFlowerAnimation();
  const version = animationVersion;
  const layers = Array.from(flower.querySelectorAll("img"));
  let lastFrame = -1;
  const renderFrame = (value) => {
    const current = Math.max(0, Math.min(frameUrls.length - 1, Math.floor(value)));
    if (current === lastFrame) return;
    layers.forEach((layer, index) => {
      layer.style.visibility = index === current ? "visible" : "hidden";
    });
    lastFrame = current;
  };
  renderFrame(0);

  framesReady ??= Promise.all(
    frameUrls.map(
      (url) =>
        new Promise((resolve) => {
          const image = new Image();
          image.onload = () =>
            image
              .decode()
              .catch(() => {})
              .then(resolve);
          image.onerror = resolve;
          image.src = url;
        }),
    ),
  );
  await framesReady;
  if (version !== animationVersion || !loadingStatus.value || flower !== flowerRef.value) return;
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const frameState = { value: 0 };
  flowerAnimation = animate(frameState, {
    value: frameUrls.length - 0.001,
    duration: reducedMotion ? 2000 : 1000,
    ease: "linear",
    loop: true,
    alternate: true,
    loopDelay: reducedMotion ? 440 : 220,
    onUpdate: () => {
      renderFrame(frameState.value);
    },
  });

  // 从帧图解码完成、动画开始播放时计时，避免图片下载耗掉展示时间。
  if (store.initialLoading && initialLoadingTimer === null) {
    initialLoadingTimer = setTimeout(() => {
      initialLoadingTimer = null;
      store.initialLoading = false;
      loadingStatus.value = store.routeLoading;
    }, 1000);
  }
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
  { flush: "post" },
);

onMounted(() => {
  if (loadingStatus.value) {
    startFlowerAnimation();
    showTimeOut.value = setTimeout(() => {
      showTip.value = true;
    }, 3000);
  }
});

onBeforeUnmount(() => {
  clearTimeout(initialLoadingTimer);
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
    position: relative;
    mix-blend-mode: multiply;
    display: block;
    width: 92px;
    height: 92px;
    filter: url(#loading-petal-pink);
    img {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
  }

  .flower-color-defs {
    position: absolute;
    pointer-events: none;
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
