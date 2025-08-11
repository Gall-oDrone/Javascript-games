/**
 * Updated Main Game class - Orchestrates all game components including menu, loading, and leaderboard
 */
import { Player } from './classes/Player.js';
import { Projectile } from './classes/Projectile.js';
import { Wave } from './classes/Wave.js';
import { Boss } from './classes/Boss.js';
import { AIAgent } from './ai-agent.js';
import { Leaderboard, AliasInput } from './leaderboard.js';
import { MainMenu, LoadingScreen } from './main-menu.js';

export class Game {
    constructor(canvas) {
        this.canvas = canvas;
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.keys = [];

        // Game states
        this.gameState = 'loading'; // 'loading', 'menu', 'playing', 'paused', 'gameover', 'highscore'
        this.previousState = null;

        // Core game objects
        this.player = new Player(this);
        this.projectilesPool = [];
        this.numberOfProjectiles = 15;
        this.createProjectiles();
        this.fired = false;

        this.columns = 2;
        this.rows = 2;
        this.enemySize = 80;

        this.waves = [];
        this.waveCount = 1;

        this.spriteUpdate = false;
        this.spriteTimer = 0;
        this.spriteInterval = 120;

        this.score = 0;
        this.gameOver = false;

        this.bossArray = [];
        this.bossLives = 10;

        // New systems
        this.leaderboard = new Leaderboard();
        this.aliasInput = new AliasInput(this);
        this.mainMenu = new MainMenu(this);
        this.loadingScreen = new LoadingScreen(this);

        // AI Agent
        this.aiAgent = new AIAgent(this);
        this.aiMode = false;

        // Initialize loading
        this.initializeLoading();
        this.setupEventListeners();
    }

    initializeLoading() {
        // Add all game assets to loading screen
        this.loadingScreen.addAsset('background', 'https://dg-game-assets.s3.amazonaws.com/javascript/tutorial-javascript-2d-game/background.png');
        this.loadingScreen.addAsset('beetlemorph', 'https://dg-game-assets.s3.amazonaws.com/javascript/tutorial-javascript-2d-game/beetlemorph.png');
        this.loadingScreen.addAsset('rhinomorph', 'https://dg-game-assets.s3.amazonaws.com/javascript/tutorial-javascript-2d-game/rhinomorph.png');
        this.loadingScreen.addAsset('player', 'https://dg-game-assets.s3.amazonaws.com/javascript/tutorial-javascript-2d-game/player.png');
        this.loadingScreen.addAsset('player_jets', 'https://dg-game-assets.s3.amazonaws.com/javascript/tutorial-javascript-2d-game/player_jets.png');
        this.loadingScreen.addAsset('boss', 'https://dg-game-assets.s3.amazonaws.com/javascript/tutorial-javascript-2d-game/boss.png');

        // Start loading assets
        this.loadingScreen.loadAssets(() => {
            this.gameState = 'menu';
            this.mainMenu.activate();
        });
    }

    setupEventListeners() {
        window.addEventListener('keydown', e => {
            // Global keys that work in any state
            if (e.key === 'Escape') {
                this.handleEscape();
                return;
            }

            // State-specific key handling
            if (this.gameState === 'playing') {
                if (e.key === '1' && !this.fired) this.player.shoot();
                this.fired = true;
                if (this.keys.indexOf(e.key) === -1) this.keys.push(e.key);

                // AI Agent controls
                if (e.key === 'a' || e.key === 'A') {
                    this.toggleAIMode();
                }
                if (e.key === 'd' || e.key === 'D') {
                    this.cycleAIDifficulty();
                }
            } else if (this.gameState === 'gameover') {
                if (e.key === 'r' || e.key === 'R') {
                    this.checkHighScore();
                }
            }
        });

        window.addEventListener('keyup', e => {
            if (this.gameState === 'playing') {
                this.fired = false;
                const index = this.keys.indexOf(e.key);
                if (index > -1) this.keys.splice(index, 1);
            }
        });
    }

    handleEscape() {
        if (this.gameState === 'playing') {
            this.pauseGame();
        } else if (this.gameState === 'paused') {
            this.resumeGame();
        } else if (this.gameState === 'gameover' || this.gameState === 'highscore') {
            this.returnToMenu();
        }
    }

    startGame() {
        this.gameState = 'playing';
        this.restart();
        if (this.aiMode) {
            this.aiAgent.activate();
        }
    }

    pauseGame() {
        if (this.gameState === 'playing') {
            this.previousState = this.gameState;
            this.gameState = 'paused';
            if (this.aiMode) {
                this.aiAgent.deactivate();
            }
        }
    }

    resumeGame() {
        if (this.gameState === 'paused') {
            this.gameState = this.previousState || 'playing';
            if (this.aiMode) {
                this.aiAgent.activate();
            }
        }
    }

    returnToMenu() {
        this.gameState = 'menu';
        this.mainMenu.activate();
        this.gameOver = false;
        if (this.aiMode) {
            this.aiAgent.deactivate();
        }
    }

    checkHighScore() {
        if (this.leaderboard.isHighScore(this.score)) {
            this.gameState = 'highscore';
            this.aliasInput.activate(this.score, this.waveCount, (alias) => {
                if (alias) {
                    this.leaderboard.addScore(alias, this.score, this.waveCount);
                }
                this.returnToMenu();
            });
        } else {
            this.returnToMenu();
        }
    }

    render(context, deltaTime) {
        // Handle different game states
        switch (this.gameState) {
            case 'loading':
                this.loadingScreen.update(deltaTime);
                this.loadingScreen.draw(context);
                break;

            case 'menu':
                this.mainMenu.update(deltaTime);
                this.mainMenu.draw(context);
                break;

            case 'playing':
                this.renderGame(context, deltaTime);
                break;

            case 'paused':
                this.renderGame(context, 0); // Render but don't update
                this.drawPauseOverlay(context);
                break;

            case 'gameover':
                this.renderGame(context, 0);
                this.drawGameOverOverlay(context);
                break;

            case 'highscore':
                this.renderGame(context, 0);
                this.aliasInput.update(deltaTime);
                this.aliasInput.draw(context);
                break;
        }
    }

    renderGame(context, deltaTime) {
        // sprite timing
        if (this.spriteTimer > this.spriteInterval) {
            this.spriteUpdate = true;
            this.spriteTimer = 0;
        } else {
            this.spriteUpdate = false;
            this.spriteTimer += deltaTime;
        }

        // AI Agent decision making
        if (this.gameState === 'playing' && this.aiMode) {
            this.aiAgent.makeDecision(deltaTime);
        }

        this.drawStatusText(context);

        if (deltaTime > 0) { // Only update if not paused
            this.projectilesPool.forEach(projectile => {
                projectile.update();
                projectile.draw(context);
            });

            this.player.update();

            this.bossArray.forEach(boss => {
                boss.update();
                boss.draw(context);
            });

            this.waves.forEach(wave => {
                wave.render(context);
                if (wave.enemies.length < 1 && !wave.nextWaveTrigger && !this.gameOver) {
                    this.newWave();
                    wave.nextWaveTrigger = true;
                }
            });

            // Check game over
            if (this.gameOver && this.gameState === 'playing') {
                this.gameState = 'gameover';
            }
        } else {
            // Just draw without updating
            this.projectilesPool.forEach(projectile => {
                projectile.draw(context);
            });

            this.bossArray.forEach(boss => {
                boss.draw(context);
            });

            this.waves.forEach(wave => {
                wave.enemies.forEach(enemy => {
                    enemy.draw(context);
                });
            });
        }

        this.player.draw(context);
        this.bossArray = this.bossArray.filter(object => !object.markedForDeletion);
    }

    drawPauseOverlay(context) {
        // Semi-transparent overlay
        context.save();
        context.fillStyle = 'rgba(0, 0, 0, 0.7)';
        context.fillRect(0, 0, this.width, this.height);

        // Pause text
        context.fillStyle = '#ffffff';
        context.font = 'bold 48px Impact';
        context.textAlign = 'center';
        context.fillText('PAUSED', this.width / 2, this.height / 2);

        context.font = '20px Arial';
        context.fillText('Press ESC to resume', this.width / 2, this.height / 2 + 40);

        context.restore();
    }

    drawGameOverOverlay(context) {
        context.save();
        context.textAlign = 'center';
        context.font = '100px Impact';
        context.fillStyle = '#ff0000';
        context.fillText('GAME OVER!', this.width * 0.5, this.height * 0.5);

        context.font = '30px Impact';
        context.fillStyle = '#ffffff';
        context.fillText(`Final Score: ${this.score}`, this.width * 0.5, this.height * 0.5 + 50);
        context.fillText(`Waves Survived: ${this.waveCount}`, this.width * 0.5, this.height * 0.5 + 90);

        if (this.leaderboard.isHighScore(this.score)) {
            context.fillStyle = '#00ff00';
            context.font = 'bold 24px Impact';
            context.fillText('NEW HIGH SCORE!', this.width * 0.5, this.height * 0.5 + 130);
        }

        context.font = '20px Impact';
        context.fillStyle = '#ffff00';
        context.fillText('Press R to continue', this.width * 0.5, this.height * 0.5 + 170);
        context.restore();
    }

    // create projectiles object pool
    createProjectiles() {
        for (let i = 0; i < this.numberOfProjectiles; i++) {
            this.projectilesPool.push(new Projectile());
        }
    }

    // get free projectile object from the pool
    getProjectile() {
        for (let i = 0; i < this.projectilesPool.length; i++) {
            if (this.projectilesPool[i].free) return this.projectilesPool[i];
        }
    }

    // collision detection between 2 rectangles
    checkCollision(a, b) {
        return (
            a.x < b.x + b.width &&
            a.x + a.width > b.x &&
            a.y < b.y + b.height &&
            a.y + a.height > b.y
        )
    }

    drawStatusText(context) {
        context.save();
        context.shadowOffsetX = 2;
        context.shadowOffsetY = 2;
        context.shadowColor = 'black'
        context.fillText('Score: ' + this.score, 20, 40);
        context.fillText('Wave: ' + this.waveCount, 20, 80);

        // Lives
        for (let i = 0; i < this.player.maxLives; i++) {
            context.strokeRect(20 + 10 * i, 100, 10, 15);
        }
        for (let i = 0; i < this.player.lives; i++) {
            context.fillRect(20 + 20 * i, 100, 10, 15);
        }

        // Energy
        context.save();
        this.player.cooldown ? context.fillStyle = 'red' : context.fillStyle = 'gold';
        for (let i = 0; i < this.player.energy; i++) {
            context.fillRect(20 + 2 * i, 130, 2, 15);
        }
        context.restore();

        // AI Agent status
        if (this.aiMode) {
            context.fillStyle = 'lime';
            context.fillText('AI: ON (' + this.aiAgent.difficulty + ')', 20, 160);
        }

        // High score display
        if (this.leaderboard.scores.length > 0) {
            context.fillStyle = '#ffff00';
            context.font = '16px Impact';
            context.textAlign = 'right';
            context.fillText('HIGH: ' + this.leaderboard.scores[0].score, this.width - 20, 40);
            context.textAlign = 'left';
        }

        context.restore();
    }

    newWave() {
        this.waveCount++;
        if (this.player.lives < this.player.maxLives) this.player.lives++;
        if (this.waveCount % 2 === 0) {
            this.bossArray.push(new Boss(this, this.bossLives))
        } else {
            if (Math.random() < 0.5 && (this.columns * this.enemySize) < this.width * 0.8) {
                this.columns++;
            } else if (this.rows * this.enemySize < this.height * 0.6) {
                this.rows++;
            }
            this.waves.push(new Wave(this));
        }
        this.waves = this.waves.filter(object => !object.markedForDeletion);
    }

    restart() {
        this.player.restart();
        this.columns = 2;
        this.rows = 2;
        this.waves = [];
        this.bossArray = [];
        this.bossLives = 10;
        this.bossArray.push(new Boss(this, this.bossLives));
        this.waveCount = 1;
        this.score = 0;
        this.gameOver = false;
    }

    // AI Agent control methods
    toggleAIMode() {
        this.aiMode = !this.aiMode;
        if (this.aiMode) {
            this.aiAgent.activate();
        } else {
            this.aiAgent.deactivate();
        }
    }

    cycleAIDifficulty() {
        const difficulties = ['easy', 'medium', 'hard'];
        const currentIndex = difficulties.indexOf(this.aiAgent.difficulty);
        const nextIndex = (currentIndex + 1) % difficulties.length;
        this.aiAgent.setDifficulty(difficulties[nextIndex]);
    }
}