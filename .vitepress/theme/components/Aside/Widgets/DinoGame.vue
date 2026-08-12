<template>
  <section class="dino-game s-card" aria-label="恐龙跳跃小游戏">
    <div
      ref="gameAreaRef"
      class="game-area"
      :class="{ playing: gameState === 'playing', paused: gameState === 'paused' }"
      role="button"
      tabindex="0"
      :aria-label="actionLabel"
      @click="handleAction"
      @keydown.space.prevent="handleAction"
      @keydown.enter.prevent="handleAction"
      @keydown.up.prevent="handleAction"
    >
      <div class="game-header" aria-live="polite">
        <span>得分 {{ displayScore }}</span>
        <span>最高 {{ bestScore }}</span>
      </div>

      <button
        v-if="gameState === 'playing' || gameState === 'paused'"
        class="pause-button"
        type="button"
        :aria-label="gameState === 'paused' ? '继续游戏' : '暂停游戏'"
        @click.stop="togglePause"
      >
        {{ gameState === "paused" ? "▶" : "Ⅱ" }}
      </button>

      <div class="cloud cloud-one" aria-hidden="true">☁</div>
      <div class="cloud cloud-two" aria-hidden="true">☁</div>

      <div class="game-ground">
        <div
          class="dino"
          :style="{ transform: `translate3d(0, ${-dinoY}px, 0)` }"
          aria-hidden="true"
        >
          {{ gameState === "over" ? "💫" : "🦖" }}
        </div>

        <div
          v-for="obstacle in obstacles"
          :key="obstacle.id"
          class="obstacle"
          :style="{ transform: `translate3d(${obstacle.x}px, 0, 0)` }"
          aria-hidden="true"
        >
          🌵
        </div>
      </div>

      <div v-if="gameState !== 'playing'" class="game-tip">
        <strong>{{ tipTitle }}</strong>
        <span v-if="tipText">{{ tipText }}</span>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from "vue";

const GROUND_Y = 16;
const DINO_X = 20;
const DINO_WIDTH = 30;
const OBSTACLE_WIDTH = 22;
const OBSTACLE_HEIGHT = 30;
const GRAVITY = 1900;
const JUMP_VELOCITY = 650;
const BEST_SCORE_KEY = "dino-game-best-score";

const gameAreaRef = ref(null);
const gameState = ref("ready");
const score = ref(0);
const bestScore = ref(0);
const dinoY = ref(0);
const velocityY = ref(0);
const obstacles = ref([]);

let animationFrame = 0;
let lastFrameTime = 0;
let nextObstacleIn = 1.15;
let obstacleId = 0;
let resizeObserver;
let gameWidth = 300;

const displayScore = computed(() => Math.floor(score.value));
const actionLabel = computed(() => {
  if (gameState.value === "playing") return "跳跃";
  if (gameState.value === "paused") return "继续游戏";
  return gameState.value === "over" ? "重新开始游戏" : "开始游戏";
});
const tipTitle = computed(() => {
  if (gameState.value === "paused") return "游戏暂停";
  if (gameState.value === "over") return `本局得分 ${displayScore.value}`;
  return "点击开始";
});
const tipText = computed(() => {
  if (gameState.value === "paused") return "点击或按空格继续";
  if (gameState.value === "over") return "点击或按空格再来一局";
  return "";
});

const updateGameWidth = () => {
  gameWidth = gameAreaRef.value?.clientWidth || 300;
};

const randomObstacleDelay = () => 0.9 + Math.random() * 0.75;

const spawnObstacle = () => {
  obstacles.value.push({ id: ++obstacleId, x: gameWidth + 24 });
};

const checkCollision = () =>
  obstacles.value.some((obstacle) => {
    const horizontalOverlap =
      DINO_X + DINO_WIDTH - 5 > obstacle.x && DINO_X + 5 < obstacle.x + OBSTACLE_WIDTH;
    const verticalOverlap = GROUND_Y + dinoY.value + 4 < GROUND_Y + OBSTACLE_HEIGHT;
    return horizontalOverlap && verticalOverlap;
  });

const stopLoop = () => {
  cancelAnimationFrame(animationFrame);
  animationFrame = 0;
  lastFrameTime = 0;
};

const finishGame = () => {
  gameState.value = "over";
  stopLoop();
  const finalScore = displayScore.value;
  if (finalScore > bestScore.value) {
    bestScore.value = finalScore;
    localStorage.setItem(BEST_SCORE_KEY, String(finalScore));
  }
};

const updateGame = (time) => {
  if (gameState.value !== "playing") return;
  if (!lastFrameTime) lastFrameTime = time;
  const delta = Math.min((time - lastFrameTime) / 1000, 0.034);
  lastFrameTime = time;

  score.value += delta * 10;
  const speed = Math.min(150 + score.value * 0.7, 310);

  if (dinoY.value > 0 || velocityY.value > 0) {
    velocityY.value -= GRAVITY * delta;
    dinoY.value = Math.max(0, dinoY.value + velocityY.value * delta);
    if (dinoY.value === 0) velocityY.value = 0;
  }

  obstacles.value = obstacles.value
    .map((obstacle) => ({ ...obstacle, x: obstacle.x - speed * delta }))
    .filter((obstacle) => obstacle.x > -OBSTACLE_WIDTH);

  nextObstacleIn -= delta;
  if (nextObstacleIn <= 0) {
    spawnObstacle();
    nextObstacleIn = randomObstacleDelay();
  }

  if (checkCollision()) {
    finishGame();
    return;
  }
  animationFrame = requestAnimationFrame(updateGame);
};

const startGame = async () => {
  stopLoop();
  gameState.value = "playing";
  score.value = 0;
  dinoY.value = 0;
  velocityY.value = 0;
  obstacles.value = [];
  nextObstacleIn = 1.1;
  await nextTick();
  updateGameWidth();
  animationFrame = requestAnimationFrame(updateGame);
};

const jump = () => {
  if (gameState.value === "playing" && dinoY.value === 0) velocityY.value = JUMP_VELOCITY;
};

const togglePause = () => {
  if (gameState.value === "playing") {
    gameState.value = "paused";
    stopLoop();
  } else if (gameState.value === "paused") {
    gameState.value = "playing";
    animationFrame = requestAnimationFrame(updateGame);
  }
};

const handleAction = () => {
  if (gameState.value === "ready" || gameState.value === "over") startGame();
  else if (gameState.value === "paused") togglePause();
  else jump();
};

const handleVisibilityChange = () => {
  if (document.hidden && gameState.value === "playing") togglePause();
};

onMounted(() => {
  const storedScore = Number(localStorage.getItem(BEST_SCORE_KEY));
  bestScore.value = Number.isFinite(storedScore) ? storedScore : 0;
  updateGameWidth();
  resizeObserver = new ResizeObserver(updateGameWidth);
  resizeObserver.observe(gameAreaRef.value);
  document.addEventListener("visibilitychange", handleVisibilityChange);
});

onBeforeUnmount(() => {
  stopLoop();
  resizeObserver?.disconnect();
  document.removeEventListener("visibilitychange", handleVisibilityChange);
});
</script>

<style lang="scss" scoped>
.dino-game {
  width: 100%;
  height: 200px;
  padding: 0;
  overflow: hidden;
  user-select: none;

  .game-area {
    position: relative;
    width: 100%;
    height: 100%;
    overflow: hidden;
    cursor: pointer;
    touch-action: manipulation;
    background: linear-gradient(180deg, #8ed3ff 0%, #dff6ff 69%, #b8df82 70%, #87b957 100%);

    &:focus-visible {
      box-shadow: inset 0 0 0 3px var(--main-color);
    }

    &::after {
      content: "";
      position: absolute;
      right: 0;
      bottom: 15px;
      left: 0;
      height: 2px;
      background: repeating-linear-gradient(90deg, #5d823d 0 14px, transparent 14px 24px);
      opacity: 0.65;
    }

    &.playing::after {
      animation: ground-move 0.45s linear infinite;
    }
  }

  .game-header {
    position: absolute;
    top: 10px;
    left: 12px;
    z-index: 10;
    display: flex;
    gap: 10px;
    color: #284331;
    font-size: 12px;
    font-weight: 700;
    font-variant-numeric: tabular-nums;
  }

  .pause-button {
    position: absolute;
    top: 7px;
    right: 8px;
    z-index: 30;
    width: 30px;
    height: 30px;
    padding: 0;
    border: 0;
    border-radius: 50%;
    color: #284331;
    background: rgb(255 255 255 / 55%);
    cursor: pointer;
    backdrop-filter: blur(6px);

    &:hover {
      background: rgb(255 255 255 / 85%);
    }
  }

  .cloud {
    position: absolute;
    color: rgb(255 255 255 / 75%);
    pointer-events: none;
  }

  .cloud-one {
    top: 45px;
    left: 18%;
    font-size: 28px;
  }

  .cloud-two {
    top: 72px;
    left: 70%;
    font-size: 20px;
  }

  .playing .cloud {
    animation: cloud-move 10s linear infinite;
  }

  .game-ground {
    position: relative;
    width: 100%;
    height: 100%;
  }

  .dino,
  .obstacle {
    position: absolute;
    bottom: 16px;
    z-index: 2;
    will-change: transform;
  }

  .dino {
    left: 20px;
    width: 30px;
    height: 32px;
    font-size: 28px;
    line-height: 32px;
    scale: -1 1;
  }

  .obstacle {
    left: 0;
    width: 22px;
    height: 30px;
    font-size: 24px;
    line-height: 30px;
  }

  .game-tip {
    position: absolute;
    top: 50%;
    left: 50%;
    z-index: 20;
    display: flex;
    width: calc(100% - 40px);
    max-width: 260px;
    padding: 12px 16px;
    border: 1px solid rgb(255 255 255 / 35%);
    border-radius: 12px;
    color: #fff;
    background: rgb(25 48 36 / 78%);
    box-shadow: 0 8px 24px rgb(0 0 0 / 16%);
    transform: translate(-50%, -50%);
    flex-direction: column;
    align-items: center;
    backdrop-filter: blur(8px);

    strong {
      margin-bottom: 4px;
      font-size: 15px;
    }

    span {
      font-size: 11px;
      text-align: center;
      opacity: 0.85;
    }
  }
}

@keyframes ground-move {
  to { background-position-x: -24px; }
}

@keyframes cloud-move {
  to { translate: -340px 0; }
}

@media (prefers-reduced-motion: reduce) {
  .dino-game * {
    animation-duration: 0.001ms !important;
  }
}
</style>
