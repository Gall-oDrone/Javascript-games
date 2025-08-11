/**
 * Enhanced AI Agent for JavaScript 2D Game
 * Provides intelligent and aggressive gameplay automation
 */
export class AIAgent {
    constructor(game) {
        this.game = game;
        this.decisionInterval = 50; // ms between decisions
        this.lastDecision = 0;
        this.isActive = false;
        this.difficulty = 'medium'; // easy, medium, hard
        this.targetEnemy = null;
        this.movementDirection = 0; // -1: left, 0: none, 1: right
        this.shouldShootThisFrame = false;
        this.shouldUseLaserThisFrame = false;
        this.laserType = 'small'; // 'small' or 'big'

        // Enhanced AI parameters
        this.aggressiveness = 0.7; // 0-1, higher = more aggressive
        this.predictionFrames = 10; // Frames to predict ahead
        this.lastTargetX = null; // Track target movement
        this.stuckCounter = 0; // Detect when stuck
        this.lastPlayerX = null;
        this.dodgeCooldown = 0;
        this.shootInterval = 0; // For continuous shooting
        this.maxShootInterval = 200; // ms between shots
    }

    // State observation methods
    getGameState() {
        return {
            player: {
                x: this.game.player.x,
                y: this.game.player.y,
                lives: this.game.player.lives,
                energy: this.game.player.energy,
                cooldown: this.game.player.cooldown,
                width: this.game.player.width,
                height: this.game.player.height
            },
            enemies: this.getAllEnemies(),
            projectiles: this.getActiveProjectiles(),
            bosses: this.game.bossArray.map(boss => ({
                x: boss.x,
                y: boss.y,
                lives: boss.lives,
                width: boss.width,
                height: boss.height,
                velocityX: boss.velocityX || 0,
                velocityY: boss.velocityY || 0
            })),
            score: this.game.score,
            waveCount: this.game.waveCount,
            gameOver: this.game.gameOver
        };
    }

    getAllEnemies() {
        const enemies = [];
        this.game.waves.forEach(wave => {
            wave.enemies.forEach(enemy => {
                enemies.push({
                    x: enemy.x,
                    y: enemy.y,
                    lives: enemy.lives,
                    width: enemy.width,
                    height: enemy.height,
                    type: enemy.constructor.name,
                    velocityX: enemy.velocityX || 0,
                    velocityY: enemy.velocityY || 0
                });
            });
        });
        return enemies;
    }

    getActiveProjectiles() {
        return this.game.projectilesPool
            .filter(projectile => !projectile.free)
            .map(projectile => ({
                x: projectile.x,
                y: projectile.y,
                width: projectile.width,
                height: projectile.height,
                velocityY: projectile.velocityY || -10
            }));
    }

    // Enhanced targeting with priority system
    getPriorityTarget() {
        const enemies = this.getAllEnemies();
        const bosses = this.game.bossArray;
        const playerX = this.game.player.x + this.game.player.width * 0.5;
        const playerY = this.game.player.y;

        let targets = [];

        // Add enemies with priority scores
        enemies.forEach(enemy => {
            const distance = this.calculateDistance(
                playerX, playerY,
                enemy.x + enemy.width * 0.5, enemy.y + enemy.height * 0.5
            );

            // Priority factors
            let priority = 1000 - distance; // Closer = higher priority

            // Enemies lower on screen get higher priority (more dangerous)
            priority += (enemy.y / this.game.height) * 500;

            // Enemies aligned with player get bonus priority
            const alignment = Math.abs(playerX - (enemy.x + enemy.width * 0.5));
            if (alignment < this.game.player.width) {
                priority += 200;
            }

            targets.push({
                entity: enemy,
                priority: priority,
                type: 'enemy'
            });
        });

        // Add bosses with high priority
        bosses.forEach(boss => {
            const distance = this.calculateDistance(
                playerX, playerY,
                boss.x + boss.width * 0.5, boss.y + boss.height * 0.5
            );

            targets.push({
                entity: boss,
                priority: 2000 - distance, // Bosses get base priority boost
                type: 'boss'
            });
        });

        // Sort by priority and return highest
        targets.sort((a, b) => b.priority - a.priority);
        return targets.length > 0 ? targets[0] : null;
    }

    // Predict future position of target
    predictTargetPosition(target, frames) {
        if (!target || !target.entity) return null;

        const entity = target.entity;
        const velocityX = entity.velocityX || 0;
        const velocityY = entity.velocityY || 0;

        return {
            x: entity.x + (velocityX * frames),
            y: entity.y + (velocityY * frames),
            width: entity.width,
            height: entity.height
        };
    }

    calculateDistance(x1, y1, x2, y2) {
        return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    }

    // Enhanced threat assessment
    assessThreatLevel() {
        const enemies = this.getAllEnemies();
        const bosses = this.game.bossArray;
        const playerY = this.game.player.y;
        const playerX = this.game.player.x;
        const playerWidth = this.game.player.width;

        let threatLevel = 0;
        let immediateDanger = false;

        // Check for enemies with proximity-based threat
        enemies.forEach(enemy => {
            const yDistance = playerY - (enemy.y + enemy.height);
            const xDistance = Math.abs((playerX + playerWidth / 2) - (enemy.x + enemy.width / 2));

            if (yDistance < 100) {
                threatLevel += 10 * (100 - yDistance) / 100; // Scale by proximity

                if (yDistance < 50 && xDistance < playerWidth * 2) {
                    immediateDanger = true;
                    threatLevel += 20;
                }
            }
        });

        // Check for bosses
        bosses.forEach(boss => {
            if (boss.y >= 0) {
                threatLevel += 15;

                // Boss directly above player is high threat
                const xDistance = Math.abs((playerX + playerWidth / 2) - (boss.x + boss.width / 2));
                if (xDistance < boss.width) {
                    threatLevel += 10;
                }
            }
        });

        // Check incoming projectiles (if enemy projectiles exist)
        const projectiles = this.getActiveProjectiles();
        projectiles.forEach(proj => {
            if (proj.velocityY > 0) { // Enemy projectile moving down
                const willHit = this.willProjectileHitPlayer(proj);
                if (willHit) {
                    immediateDanger = true;
                    threatLevel += 15;
                }
            }
        });

        return { level: threatLevel, immediateDanger };
    }

    // Check if projectile will hit player
    willProjectileHitPlayer(projectile) {
        const player = this.game.player;
        const futureY = projectile.y + (projectile.velocityY * 10);

        if (futureY > player.y && futureY < player.y + player.height) {
            if (projectile.x > player.x - 10 && projectile.x < player.x + player.width + 10) {
                return true;
            }
        }
        return false;
    }

    // Action methods
    moveLeft() {
        if (this.game.keys.indexOf('ArrowLeft') === -1) {
            this.game.keys.push('ArrowLeft');
        }
        const rightIndex = this.game.keys.indexOf('ArrowRight');
        if (rightIndex > -1) {
            this.game.keys.splice(rightIndex, 1);
        }
    }

    moveRight() {
        if (this.game.keys.indexOf('ArrowRight') === -1) {
            this.game.keys.push('ArrowRight');
        }
        const leftIndex = this.game.keys.indexOf('ArrowLeft');
        if (leftIndex > -1) {
            this.game.keys.splice(leftIndex, 1);
        }
    }

    stopMoving() {
        const leftIndex = this.game.keys.indexOf('ArrowLeft');
        const rightIndex = this.game.keys.indexOf('ArrowRight');
        if (leftIndex > -1) this.game.keys.splice(leftIndex, 1);
        if (rightIndex > -1) this.game.keys.splice(rightIndex, 1);
    }

    shoot() {
        // Keep the '1' key pressed for continuous shooting
        if (this.game.keys.indexOf('1') === -1) {
            this.game.keys.push('1');
        }
        // Trigger the actual shot
        if (!this.game.fired) {
            this.game.player.shoot();
            this.game.fired = true;
        }
    }

    stopShooting() {
        const index = this.game.keys.indexOf('1');
        if (index > -1) {
            this.game.keys.splice(index, 1);
        }
        // Reset fired state when stopping
        this.game.fired = false;
    }

    useSmallLaser() {
        if (this.game.keys.indexOf('2') === -1) {
            this.game.keys.push('2');
        }
    }

    useBigLaser() {
        if (this.game.keys.indexOf('3') === -1) {
            this.game.keys.push('3');
        }
    }

    // Enhanced shooting decision
    shouldShoot() {
        const target = this.getPriorityTarget();
        if (!target) return false;

        const playerCenterX = this.game.player.x + this.game.player.width * 0.5;

        // Predict where target will be
        const predictedPos = this.predictTargetPosition(target, this.predictionFrames);
        if (!predictedPos) {
            // If can't predict, use current position
            const targetCenterX = target.entity.x + target.entity.width * 0.5;
            const alignment = Math.abs(playerCenterX - targetCenterX);
            const tolerance = this.game.player.width;
            return alignment < tolerance;
        }

        const targetCenterX = predictedPos.x + predictedPos.width * 0.5;

        // Dynamic tolerance based on difficulty and distance
        const distance = Math.abs(target.entity.y - this.game.player.y);
        let tolerance = this.game.player.width * 0.5;

        if (this.difficulty === 'hard') {
            tolerance = this.game.player.width * 0.4;
        } else if (this.difficulty === 'easy') {
            tolerance = this.game.player.width * 0.8;
        }

        // Increase tolerance for distant targets
        tolerance += distance * 0.05;

        const alignment = Math.abs(playerCenterX - targetCenterX);

        // Always shoot if target is very close
        if (distance < 150) {
            return alignment < tolerance * 2;
        }

        return alignment < tolerance;
    }

    // Enhanced laser usage decision
    shouldUseLaser() {
        const threat = this.assessThreatLevel();
        const energy = this.game.player.energy;

        if (this.game.player.cooldown) return false;

        // Immediate danger - use laser if possible
        if (threat.immediateDanger && energy > 10) {
            return true;
        }

        // High threat level
        if (threat.level > 15 && energy > 20) {
            return true;
        }

        // Boss targeting
        const target = this.getPriorityTarget();
        if (target && target.type === 'boss' && energy > 15) {
            const boss = target.entity;
            const playerCenterX = this.game.player.x + this.game.player.width * 0.5;
            const bossCenterX = boss.x + boss.width * 0.5;
            const alignment = Math.abs(playerCenterX - bossCenterX);

            if (alignment < boss.width * 0.7) {
                return true;
            }
        }

        // Multiple enemies aligned
        const enemies = this.getAllEnemies();
        let alignedCount = 0;
        const playerCenterX = this.game.player.x + this.game.player.width * 0.5;

        enemies.forEach(enemy => {
            const enemyCenterX = enemy.x + enemy.width * 0.5;
            if (Math.abs(playerCenterX - enemyCenterX) < this.game.player.width) {
                alignedCount++;
            }
        });

        if (alignedCount >= 3 && energy > 25) {
            return true;
        }

        return false;
    }

    // Enhanced movement decision with active hunting
    getOptimalPosition() {
        const target = this.getPriorityTarget();

        if (target) {
            // Predict where target will be
            const predictedPos = this.predictTargetPosition(target, this.predictionFrames * 0.5);
            if (predictedPos) {
                // Move to intercept predicted position
                return predictedPos.x + predictedPos.width * 0.5;
            }

            // Fallback to current target position
            return target.entity.x + target.entity.width * 0.5;
        }

        // No target - move to center
        return this.game.width * 0.5;
    }

    // Enhanced movement with active dodging
    shouldMove() {
        const threat = this.assessThreatLevel();

        // Priority 1: Dodge immediate threats
        if (threat.immediateDanger || this.dodgeCooldown > 0) {
            const dodgeDirection = this.calculateDodgeDirection();
            if (dodgeDirection !== 0) {
                this.dodgeCooldown = 10; // Prevent dodge spam
                return dodgeDirection;
            }
        }

        // Priority 2: Track target
        const optimalPosition = this.getOptimalPosition();
        const playerCenterX = this.game.player.x + this.game.player.width * 0.5;

        // Check if stuck (not moving when should be)
        if (this.lastPlayerX !== null && Math.abs(this.lastPlayerX - playerCenterX) < 1) {
            this.stuckCounter++;
            if (this.stuckCounter > 20) {
                // Force movement if stuck
                this.stuckCounter = 0;
                return Math.random() > 0.5 ? 1 : -1;
            }
        } else {
            this.stuckCounter = 0;
        }
        this.lastPlayerX = playerCenterX;

        // Aggressive movement toward target
        const movementThreshold = this.difficulty === 'hard' ? 10 :
            this.difficulty === 'easy' ? 30 : 20;

        if (Math.abs(playerCenterX - optimalPosition) > movementThreshold) {
            return playerCenterX < optimalPosition ? 1 : -1;
        }

        return 0;
    }

    // Enhanced dodge calculation
    calculateDodgeDirection() {
        const enemies = this.getAllEnemies();
        const playerX = this.game.player.x;
        const playerY = this.game.player.y;
        const playerWidth = this.game.player.width;
        const playerCenterX = playerX + playerWidth * 0.5;

        let leftThreat = 0;
        let rightThreat = 0;

        // Calculate threat zones
        enemies.forEach(enemy => {
            const distance = this.calculateDistance(
                playerCenterX, playerY,
                enemy.x + enemy.width * 0.5, enemy.y + enemy.height * 0.5
            );

            if (distance < 200) { // Consider nearby enemies
                const threatValue = (200 - distance) / 200;

                if (enemy.x + enemy.width * 0.5 < playerCenterX) {
                    leftThreat += threatValue;
                } else {
                    rightThreat += threatValue;
                }
            }
        });

        // Check boundaries
        const leftSpace = playerX;
        const rightSpace = this.game.width - (playerX + playerWidth);

        // Don't dodge into walls
        if (leftSpace < 50) leftThreat += 10;
        if (rightSpace < 50) rightThreat += 10;

        // Make dodge decision
        if (leftThreat > 0.5 || rightThreat > 0.5) {
            if (leftThreat > rightThreat && rightSpace > 30) {
                return 1; // Dodge right
            } else if (rightThreat > leftThreat && leftSpace > 30) {
                return -1; // Dodge left
            }
        }

        return 0;
    }

    // Main decision making method - Enhanced
    makeDecision(deltaTime) {
        if (!this.isActive || this.game.gameOver) return;

        this.lastDecision += deltaTime;

        // Update cooldowns
        if (this.dodgeCooldown > 0) this.dodgeCooldown--;

        // Make decisions at regular intervals
        if (this.lastDecision < this.decisionInterval) {
            // Still handle shooting between decision intervals for continuous fire
            if (this.shouldShoot()) {
                this.shoot();
            }
            return;
        }
        this.lastDecision = 0;

        // Movement decision - always active
        const movementDirection = this.shouldMove();
        if (movementDirection === 1) {
            this.moveRight();
        } else if (movementDirection === -1) {
            this.moveLeft();
        } else {
            this.stopMoving();
        }

        // Combat decisions - check if should keep shooting
        if (this.shouldShoot()) {
            this.shoot();
        } else {
            this.stopShooting();
        }

        // Special ability decisions
        if (this.shouldUseLaser()) {
            const energy = this.game.player.energy;
            const threat = this.assessThreatLevel();

            // Use big laser for bosses or extreme threats
            if ((threat.level > 25 || this.getPriorityTarget()?.type === 'boss') && energy > 30) {
                this.useBigLaser();
            } else {
                this.useSmallLaser();
            }
        }

        // Reset the fired flag periodically to allow continuous shooting
        if (this.game.fired && this.game.keys.indexOf('1') > -1) {
            setTimeout(() => {
                this.game.fired = false;
            }, 100); // Reset after 100ms to allow next shot
        }
    }

    // Control methods
    activate() {
        this.isActive = true;
        this.stuckCounter = 0;
        this.lastPlayerX = null;
        this.dodgeCooldown = 0;
        this.shootInterval = 0;
        console.log('AI Agent activated');
    }

    deactivate() {
        this.isActive = false;
        this.stopMoving();
        this.stopShooting();
        console.log('AI Agent deactivated');
    }

    setDifficulty(level) {
        this.difficulty = level;
        switch (level) {
            case 'easy':
                this.decisionInterval = 100;
                this.aggressiveness = 0.5;
                this.predictionFrames = 5;
                break;
            case 'medium':
                this.decisionInterval = 50;
                this.aggressiveness = 0.7;
                this.predictionFrames = 10;
                break;
            case 'hard':
                this.decisionInterval = 25;
                this.aggressiveness = 0.9;
                this.predictionFrames = 15;
                break;
        }
        console.log(`AI Difficulty set to ${level}`);
    }

    getPerformanceMetrics() {
        const gameState = this.getGameState();
        const threat = this.assessThreatLevel();
        return {
            enemiesRemaining: gameState.enemies.length,
            bossesRemaining: gameState.bosses.length,
            threatLevel: threat.level,
            immediateDanger: threat.immediateDanger,
            playerHealth: gameState.player.lives,
            playerEnergy: gameState.player.energy,
            score: gameState.score,
            waveCount: gameState.waveCount,
            currentTarget: this.getPriorityTarget()?.type || 'none'
        };
    }

    // Advanced AI functions for future ML integration
    getStateVector() {
        const gameState = this.getGameState();
        const player = gameState.player;
        const enemies = gameState.enemies;
        const bosses = gameState.bosses;
        const threat = this.assessThreatLevel();
        const target = this.getPriorityTarget();

        // Enhanced state vector with more features
        const stateVector = [
            player.x / this.game.width,
            player.y / this.game.height,
            player.lives / (player.maxLives || 5),
            player.energy / (player.maxEnergy || 100),
            enemies.length / 20,
            bosses.length / 3,
            threat.level / 50,
            threat.immediateDanger ? 1 : 0,
            gameState.score / 10000,
            gameState.waveCount / 10,
            target ? target.entity.x / this.game.width : 0.5,
            target ? target.entity.y / this.game.height : 0,
            this.dodgeCooldown / 10,
            player.cooldown ? 1 : 0
        ];

        return stateVector;
    }
}