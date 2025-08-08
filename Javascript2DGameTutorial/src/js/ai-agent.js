/**
 * AI Agent for JavaScript 2D Game
 * Provides intelligent gameplay automation
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
    }

    // State observation methods
    getGameState() {
        return {
            player: {
                x: this.game.player.x,
                y: this.game.player.y,
                lives: this.game.player.lives,
                energy: this.game.player.energy,
                cooldown: this.game.player.cooldown
            },
            enemies: this.getAllEnemies(),
            projectiles: this.getActiveProjectiles(),
            bosses: this.game.bossArray.map(boss => ({
                x: boss.x,
                y: boss.y,
                lives: boss.lives,
                width: boss.width,
                height: boss.height
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
                    type: enemy.constructor.name
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
                height: projectile.height
            }));
    }

    getNearestEnemy() {
        const enemies = this.getAllEnemies();
        if (enemies.length === 0) return null;

        let nearest = enemies[0];
        let minDistance = this.calculateDistance(
            this.game.player.x + this.game.player.width * 0.5,
            this.game.player.y,
            nearest.x + nearest.width * 0.5,
            nearest.y
        );

        enemies.forEach(enemy => {
            const distance = this.calculateDistance(
                this.game.player.x + this.game.player.width * 0.5,
                this.game.player.y,
                enemy.x + enemy.width * 0.5,
                enemy.y
            );
            if (distance < minDistance) {
                minDistance = distance;
                nearest = enemy;
            }
        });

        return { enemy: nearest, distance: minDistance };
    }

    getNearestBoss() {
        if (this.game.bossArray.length === 0) return null;

        let nearest = this.game.bossArray[0];
        let minDistance = this.calculateDistance(
            this.game.player.x + this.game.player.width * 0.5,
            this.game.player.y,
            nearest.x + nearest.width * 0.5,
            nearest.y
        );

        this.game.bossArray.forEach(boss => {
            const distance = this.calculateDistance(
                this.game.player.x + this.game.player.width * 0.5,
                this.game.player.y,
                boss.x + boss.width * 0.5,
                boss.y
            );
            if (distance < minDistance) {
                minDistance = distance;
                nearest = boss;
            }
        });

        return { boss: nearest, distance: minDistance };
    }

    calculateDistance(x1, y1, x2, y2) {
        return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    }

    assessThreatLevel() {
        const enemies = this.getAllEnemies();
        const bosses = this.game.bossArray;
        const playerY = this.game.player.y;

        let threatLevel = 0;

        // Check for enemies close to player
        enemies.forEach(enemy => {
            if (enemy.y + enemy.height > playerY - 100) {
                threatLevel += 2;
            }
            if (enemy.y + enemy.height > playerY - 50) {
                threatLevel += 5;
            }
        });

        // Check for bosses
        bosses.forEach(boss => {
            if (boss.y >= 0) {
                threatLevel += 10;
            }
        });

        return threatLevel;
    }

    // Action methods
    moveLeft() {
        if (this.game.keys.indexOf('ArrowLeft') === -1) {
            this.game.keys.push('ArrowLeft');
        }
        // Remove right key if it exists
        const rightIndex = this.game.keys.indexOf('ArrowRight');
        if (rightIndex > -1) {
            this.game.keys.splice(rightIndex, 1);
        }
    }

    moveRight() {
        if (this.game.keys.indexOf('ArrowRight') === -1) {
            this.game.keys.push('ArrowRight');
        }
        // Remove left key if it exists
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
        if (this.game.keys.indexOf('1') === -1) {
            this.game.keys.push('1');
        }
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

    // Decision making methods
    shouldShoot() {
        const nearestEnemy = this.getNearestEnemy();
        if (!nearestEnemy) return false;

        const playerCenterX = this.game.player.x + this.game.player.width * 0.5;
        const enemyCenterX = nearestEnemy.enemy.x + nearestEnemy.enemy.width * 0.5;

        // Check if enemy is roughly aligned with player
        const alignment = Math.abs(playerCenterX - enemyCenterX);
        const tolerance = this.game.player.width * 0.3;

        return alignment < tolerance && nearestEnemy.enemy.y < this.game.height - 100;
    }

    shouldUseLaser() {
        const threatLevel = this.assessThreatLevel();
        const energy = this.game.player.energy;

        if (this.game.player.cooldown) return false;

        // Use laser if high threat and enough energy
        if (threatLevel > 8 && energy > 20) {
            return true;
        }

        // Use laser for bosses
        const nearestBoss = this.getNearestBoss();
        if (nearestBoss && nearestBoss.boss.y >= 0 && energy > 15) {
            return true;
        }

        return false;
    }

    getOptimalPosition() {
        const enemies = this.getAllEnemies();
        if (enemies.length === 0) return this.game.width * 0.5;

        // Calculate center of mass of enemies
        let totalX = 0;
        let count = 0;

        enemies.forEach(enemy => {
            if (enemy.y < this.game.height - 150) { // Only consider enemies in play area
                totalX += enemy.x + enemy.width * 0.5;
                count++;
            }
        });

        if (count === 0) return this.game.width * 0.5;

        const centerOfMass = totalX / count;
        return centerOfMass;
    }

    shouldMove() {
        const optimalPosition = this.getOptimalPosition();
        const playerCenterX = this.game.player.x + this.game.player.width * 0.5;
        const tolerance = 20;

        // Check if we need to dodge enemies
        const dodgeDirection = this.shouldDodge();
        if (dodgeDirection !== 0) {
            return dodgeDirection;
        }

        if (Math.abs(playerCenterX - optimalPosition) > tolerance) {
            return playerCenterX < optimalPosition ? 1 : -1; // 1 for right, -1 for left
        }

        return 0; // No movement needed
    }

    shouldDodge() {
        const enemies = this.getAllEnemies();
        const playerX = this.game.player.x;
        const playerY = this.game.player.y;
        const playerWidth = this.game.player.width;

        // Check for enemies that might collide with player
        for (let enemy of enemies) {
            if (enemy.y + enemy.height > playerY - 50 && enemy.y < playerY + playerWidth) {
                // Enemy is close to player's Y position
                if (enemy.x < playerX + playerWidth && enemy.x + enemy.width > playerX) {
                    // Potential collision - dodge left or right
                    const leftSpace = playerX;
                    const rightSpace = this.game.width - (playerX + playerWidth);

                    if (leftSpace > rightSpace) {
                        return -1; // Dodge left
                    } else {
                        return 1; // Dodge right
                    }
                }
            }
        }

        return 0; // No dodge needed
    }

    // Main decision making method
    makeDecision(deltaTime) {
        if (!this.isActive || this.game.gameOver) return;

        this.lastDecision += deltaTime;
        if (this.lastDecision < this.decisionInterval) return;

        this.lastDecision = 0;

        // Clear previous actions
        this.stopMoving();
        this.shouldShootThisFrame = false;
        this.shouldUseLaserThisFrame = false;

        // Movement decision
        const movementDirection = this.shouldMove();
        if (movementDirection === 1) {
            this.moveRight();
        } else if (movementDirection === -1) {
            this.moveLeft();
        }

        // Shooting decision
        if (this.shouldShoot()) {
            this.shoot();
        }

        // Laser decision
        if (this.shouldUseLaser()) {
            if (this.game.player.energy > 30) {
                this.useBigLaser();
            } else {
                this.useSmallLaser();
            }
        }
    }

    // Control methods
    activate() {
        this.isActive = true;
        console.log('AI Agent activated');
    }

    deactivate() {
        this.isActive = false;
        this.stopMoving();
        console.log('AI Agent deactivated');
    }

    setDifficulty(level) {
        this.difficulty = level;
        switch (level) {
            case 'easy':
                this.decisionInterval = 100;
                break;
            case 'medium':
                this.decisionInterval = 50;
                break;
            case 'hard':
                this.decisionInterval = 25;
                break;
        }
    }

    getPerformanceMetrics() {
        const gameState = this.getGameState();
        return {
            enemiesRemaining: gameState.enemies.length,
            bossesRemaining: gameState.bosses.length,
            threatLevel: this.assessThreatLevel(),
            playerHealth: gameState.player.lives,
            playerEnergy: gameState.player.energy,
            score: gameState.score,
            waveCount: gameState.waveCount
        };
    }

    // Advanced AI functions for future ML integration
    getStateVector() {
        // Convert game state to a numerical vector for ML models
        const gameState = this.getGameState();
        const player = gameState.player;
        const enemies = gameState.enemies;
        const bosses = gameState.bosses;

        // Normalize values to 0-1 range
        const stateVector = [
            player.x / this.game.width, // Normalized player X position
            player.y / this.game.height, // Normalized player Y position
            player.lives / player.maxLives, // Normalized lives
            player.energy / player.maxEnergy, // Normalized energy
            enemies.length / 20, // Normalized enemy count (max 20)
            bosses.length / 3, // Normalized boss count (max 3)
            this.assessThreatLevel() / 50, // Normalized threat level
            gameState.score / 1000, // Normalized score
            gameState.waveCount / 10 // Normalized wave count
        ];

        return stateVector;
    }
} 