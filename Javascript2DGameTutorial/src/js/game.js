/**
 * Main Game class - Orchestrates all game components and logic
 */
import { Player } from './classes/Player.js';
import { Projectile } from './classes/Projectile.js';
import { Wave } from './classes/Wave.js';
import { Boss } from './classes/Boss.js';
import { AIAgent } from './ai-agent.js';

export class Game {
    constructor(canvas) {
        this.canvas = canvas;
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.keys = [];
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
        
        // AI Agent
        this.aiAgent = new AIAgent(this);
        this.aiMode = false;
        
        this.restart();
        this.setupEventListeners();
    }

    setupEventListeners() {
        window.addEventListener('keydown', e => {
            if (e.key === '1' && !this.fired) this.player.shoot();
            this.fired = true;
            if (this.keys.indexOf(e.key) === -1) this.keys.push(e.key);
            if (e.key === 'r' && this.gameOver) this.restart();
            
            // AI Agent controls
            if (e.key === 'a' || e.key === 'A') {
                this.toggleAIMode();
            }
            if (e.key === 'd' || e.key === 'D') {
                this.cycleAIDifficulty();
            }
        });

        window.addEventListener('keyup', e => {
            this.fired = false;
            const index = this.keys.indexOf(e.key);
            if (index > -1) this.keys.splice(index, 1);
        });
    }

    render(context, deltaTime) {
        // sprite timing
        if (this.spriteTimer > this.spriteInterval) {
            this.spriteUpdate = true;
            this.spriteTimer = 0;
        } else {
            this.spriteUpdate = false;
            this.spriteTimer += deltaTime;
        }
        
        // AI Agent decision making
        if (this.aiMode) {
            this.aiAgent.makeDecision(deltaTime);
        }
        
        this.drawStatusText(context);
        this.projectilesPool.forEach(projectile => {
            projectile.update();
            projectile.draw(context);
        })
        this.player.draw(context);
        this.player.update();
        this.bossArray.forEach(boss => {
            boss.draw(context);
            boss.update();
        })
        this.bossArray = this.bossArray.filter(object => !object.markedForDeletion);
        
        this.waves.forEach(wave => {
            wave.render(context);
            if (wave.enemies.length < 1 && !wave.nextWaveTrigger && !this.gameOver) {
                this.newWave();
                wave.nextWaveTrigger = true;
            }
        })
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
        for (let i = 0; i < this.player.maxLives; i++) {
            context.strokeRect(20 + 10 * i, 100, 10, 15);
        }
        for (let i = 0; i < this.player.lives; i++) {
            context.fillRect(20 + 20 * i, 100, 10, 15);
        }
        // energy
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
            context.fillText('Press A to toggle AI, D to change difficulty', 20, 180);
        } else {
            context.fillStyle = 'white';
            context.fillText('AI: OFF - Press A to activate', 20, 160);
        }
        
        if (this.gameOver) {
            context.textAlign = 'center';
            context.font = '100px Impact';
            context.fillText('GAME OVER!', this.width * 0.5, this.height * 0.5);
            context.font = '20px Impact';
            context.fillText('Press R to restart!', this.width * 0.5, this.height * 0.5 + 30);
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