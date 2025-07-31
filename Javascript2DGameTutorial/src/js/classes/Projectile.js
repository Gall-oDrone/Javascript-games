/**
 * Projectile class - Handles player bullet behavior
 */
export class Projectile {
    constructor() {
        this.width = 3;
        this.height = 20;
        this.x = 0;
        this.y = 0;
        this.speed = 20;
        this.free = true;
    }

    draw(context) {
        if (!this.free) {
            context.save();
            context.fillStyle = 'gold'
            context.fillRect(this.x, this.y, this.width, this.height);
            context.restore();
        }
    }

    update() {
        if (!this.free) {
            this.y -= this.speed;
            if (this.y < -this.height) this.reset();
        }
    }

    start(x, y) {
        this.x = x - this.width * 0.5;
        this.y = y;
        this.free = false;
    }

    reset() {
        this.free = true;
    }
} 