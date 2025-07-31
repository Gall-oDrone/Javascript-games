/**
 * Enemy base class - Handles enemy behavior and collision detection
 */
export class Enemy {
    constructor(game, positionX, positionY) {
        this.game = game;
        this.width = this.game.enemySize;
        this.height = this.game.enemySize;
        this.x = 0;
        this.y = 0;
        this.positionX = positionX;
        this.positionY = positionY;
        this.markedForDeletion = false;
    }

    draw(context) {
        context.drawImage(this.image, this.frameX * this.width, this.frameY * 
            this.height, this.width, this.height, this.x, this.y, this.width, this.height);
    }

    update(x, y) {
        this.x = x + this.positionX;
        this.y = y + this.positionY;
        
        // check collision enemies - projectiles
        this.game.projectilesPool.forEach(projectile => {
            if (!projectile.free && 
                this.game.checkCollision(this, projectile) &&
                this.lives > 0) {
                this.hit(1);
                projectile.reset();
            }
        });
        
        if (this.lives < 1) {
            if (this.game.spriteUpdate) this.frameX++;
            if (this.frameX > this.maxFrame) {
                this.markedForDeletion = true;
                if (!this.game.gameOver) this.game.score += this.maxLives;
            }
        }
        
        // check collision enemies - player
        if (this.game.checkCollision(this, this.game.player) && this.lives > 0) {
            this.lives = 0;
            this.game.player.lives--;
        }
        
        // lose condition
        if (this.y + this.height > this.game.height || this.game.player.lives < 1) {
            this.game.gameOver = true;
        }
    }

    hit(damage) {
        this.lives -= damage;
    }
}

/**
 * Beetlemorph enemy - Fast, low health enemy
 */
export class Beetlemorph extends Enemy {
    constructor(game, positionX, positionY) {
        super(game, positionX, positionY);
        this.image = document.getElementById('beetlemorph');
        this.frameX = 0
        this.maxFrame = 2;
        this.frameY = Math.floor(Math.random() * 4);
        this.lives = 1;
        this.maxLives = this.lives;
    }
}

/**
 * Rhinomorph enemy - Slow, high health enemy
 */
export class Rhinomorph extends Enemy {
    constructor(game, positionX, positionY) {
        super(game, positionX, positionY);
        this.image = document.getElementById('rhinomorph');
        this.frameX = 0
        this.maxFrame = 5;
        this.frameY = Math.floor(Math.random() * 4);
        this.lives = 4;
        this.maxLives = this.lives;
    }

    hit(damage) {
        this.lives -= damage;
        this.frameX = this.maxLives - Math.floor(this.lives);
    }
} 