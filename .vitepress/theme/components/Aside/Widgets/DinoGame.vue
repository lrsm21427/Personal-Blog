<template>
  <div class="dino-game s-card">
    <!-- 游戏区域 -->
    <div class="game-area" @click="handleClick" @keydown.space.prevent="handleClick" tabindex="0">
      <!-- 分数显示在左上角 -->
      <div class="score-display">
        {{ score }}
      </div>

      <div class="game-ground">
        <!-- 恐龙 -->
        <div
          class="dino"
          :class="{ jumping: isJumping, dead: gameState === 'over' }"
          :style="{ bottom: 16 + dinoY + 'px' }"
        >
          {{ gameState === "over" ? "💀" : "🦕" }}
        </div>

        <!-- 障碍物 -->
        <div
          v-for="obstacle in obstacles"
          :key="obstacle.id"
          class="obstacle"
          :style="{ left: obstacle.x + 'px' }"
        >
          🌵
        </div>
      </div>

      <!-- 游戏提示 -->
      <div v-if="gameState !== 'playing'" class="game-tip">
        {{ gameState === "ready" ? "点击开始" : "游戏结束" }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "DinoGame",
  data() {
    return {
      gameState: "ready", // ready, playing, over
      score: 0,
      dinoY: 0,
      isJumping: false,
      obstacles: [],
      gameSpeed: 3,
      gameLoop: null,
      obstacleTimer: 0,
      // 碰撞检测参数
      dinoWidth: 30,
      dinoHeight: 30,
      obstacleWidth: 20,
      obstacleHeight: 30,
    };
  },
  computed: {
    statusText() {
      const statusMap = {
        ready: "准备就绪",
        playing: "游戏中",
        over: "游戏结束",
      };
      return statusMap[this.gameState] || "";
    },
  },
  methods: {
    // 开始游戏
    startGame() {
      this.gameState = "playing";
      this.score = 0;
      this.dinoY = 0;
      this.isJumping = false;
      this.obstacles = [];
      this.gameSpeed = 3;
      this.obstacleTimer = 0;

      this.gameLoop = setInterval(this.updateGame, 16); // 60fps
    },

    // 恐龙跳跃
    jump() {
      if (this.gameState === "playing" && !this.isJumping) {
        this.isJumping = true;

        // 使用更平滑的跳跃动画
        const jumpHeight = 100;
        const jumpDuration = 500;
        const startTime = Date.now();

        const jumpAnimation = () => {
          const elapsed = Date.now() - startTime;
          const progress = elapsed / jumpDuration;

          if (progress < 1) {
            // 使用抛物线函数计算跳跃高度
            this.dinoY = jumpHeight * Math.sin(progress * Math.PI);
            requestAnimationFrame(jumpAnimation);
          } else {
            this.dinoY = 0;
            this.isJumping = false;
          }
        };

        jumpAnimation();
      }
    },

    // 更新游戏
    updateGame() {
      // 更新分数和速度
      this.score++;
      if (this.score % 200 === 0) {
        this.gameSpeed = Math.min(this.gameSpeed + 0.5, 8);
      }

      // 移动障碍物
      this.obstacles = this.obstacles
        .map((obs) => ({ ...obs, x: obs.x - this.gameSpeed }))
        .filter((obs) => obs.x > -this.obstacleWidth);

      // 生成新障碍物
      this.obstacleTimer++;
      if (this.obstacleTimer > 80 + Math.random() * 60) {
        this.obstacles.push({
          id: Date.now(),
          x: 350, // 从更远的地方开始
        });
        this.obstacleTimer = 0;
      }

      // 碰撞检测
      if (this.checkCollision()) {
        this.gameOver();
      }
    },

    // 改进的碰撞检测
    checkCollision() {
      const dinoLeft = 20;
      const dinoRight = dinoLeft + this.dinoWidth;
      const dinoBottom = 16 + this.dinoY; // 恐龙底部位置
      const dinoTop = dinoBottom + this.dinoHeight; // 恐龙顶部位置

      return this.obstacles.some((obs) => {
        const obsLeft = obs.x;
        const obsRight = obs.x + this.obstacleWidth;
        const obsBottom = 16; // 障碍物底部位置
        const obsTop = obsBottom + this.obstacleHeight; // 障碍物顶部位置

        // 检查水平重叠
        const horizontalOverlap = dinoRight > obsLeft && dinoLeft < obsRight;

        // 检查垂直重叠 - 只有当恐龙底部低于障碍物顶部时才算碰撞
        const verticalOverlap = dinoBottom < obsTop;

        return horizontalOverlap && verticalOverlap;
      });
    },

    // 游戏结束
    gameOver() {
      this.gameState = "over";
      clearInterval(this.gameLoop);
    },

    // 处理点击
    handleClick() {
      if (this.gameState === "ready" || this.gameState === "over") {
        this.startGame();
      } else if (this.gameState === "playing") {
        this.jump();
      }
    },
  },

  beforeDestroy() {
    if (this.gameLoop) {
      clearInterval(this.gameLoop);
    }
  },
};
</script>

<style lang="scss" scoped>
.dino-game {
  width: 100%;
  max-width: 600px;
  height: 200px;
  margin: 0 auto;
  border-radius: 16px;
  overflow: hidden;

  .game-area {
    width: 100%;
    height: 100%;
    position: relative; 
    background: linear-gradient(to bottom, #87ceeb 0%, #98fb98 80%, #8b4513 70%);
    cursor: pointer;
    outline: none;
    overflow: hidden;

    // 游戏分数显示
    .score-display {
      position: absolute;
      top: 5px;
      right: 5px;  
      font-size: 15px;
      font-weight: bold;
      color: #333;
      //background: rgba(255, 255, 255, 0.9);
      padding: 8px 12px;
      border-radius: 8px;
      backdrop-filter: blur(10px);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      z-index: 10;
    }

    .game-ground {
      position: relative;
      width: 100%;
      height: 100%;
    }
 
    .dino {
      position: absolute;
      left: 20px;
      font-size: 28px;
      z-index: 2;
      transition: none;

      &.jumping {
        animation: bounce 0.1s infinite alternate;
      }

      &.dead {
        animation: shake 0.5s;
      }
    }

    .obstacle {
      position: absolute;
      bottom: 16px;
      font-size: 24px;
      z-index: 1;
    }

    .game-tip {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-size: 14px;
      animation: pulse 1.5s infinite;
      z-index: 20;
    }
  }
}

@keyframes bounce {
  from {
    transform: scaleY(1);
  }
  to {
    transform: scaleY(0.8);
  }
}

@keyframes shake {
  0%,
  100% {
    transform: rotate(0deg);
  }
  25% {
    transform: rotate(2deg);
  }
  75% {
    transform: rotate(-2deg);
  }
}

@keyframes pulse {
  0%,
  100% {
    opacity: 0.8;
  }
  50% {
    opacity: 0.5;
  }
}
</style>