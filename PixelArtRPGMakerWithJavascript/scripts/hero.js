import { TILE_SIZE } from "../main.js";
import { GameObject } from "./gameObject.js";
import { UP, DOWN, LEFT, RIGHT } from "./input.js";

export class Hero extends GameObject {
    constructor({game,sprite,position,scale}){
        super({game,sprite,position,scale});
        this.speed = 100;
        this.maxFrame = 8;
        this.moving = false;
    }
    update(deltaTime){
        let nextX = this.destinationPosition.x;
        let nextY = this.destinationPosition.y;

        const scaledSpeed = this.speed * (deltaTime / 1000);

        const distance = this.moveTowards(this.destinationPosition, scaledSpeed);
        const arrived = distance <= scaledSpeed;

        if (arrived){
            if (this.game.input.lastKey === UP){
                nextY -= TILE_SIZE;
                this.sprite.y = 8;
            } else if (this.game.input.lastKey === DOWN){
                nextY += TILE_SIZE;
                this.sprite.y = 10;
            } else if (this.game.input.lastKey === LEFT){
                nextX -= TILE_SIZE;
                this.sprite.y = 9;
            } else if (this.game.input.lastKey === RIGHT){
                nextX += TILE_SIZE;
                this.sprite.y = 11;
            }
            this.destinationPosition.x = nextX;
            this.destinationPosition.y = nextY;
        }

        if (this.game.input.keys.length > 0 || !arrived) {
            this.moving = true;
        } else {
            this.moving = false;
        }
        if (this.game.eventUpdate && this.moving){
            this.sprite.x < this.maxFrame ? this.sprite.x++ : this.sprite.x = 0;
        } else if (!this.moving) {
            this.sprite.x = 0;
        }
    }
}