import { TILE_SIZE } from "../main.js";
import { GameObject } from "./gameObject.js";
import { UP, DOWN, LEFT, RIGHT } from "./input.js";

export class Hero extends GameObject {
    constructor({game,sprite,position,scale}){
        super({game,sprite,position,scale});
        this.speed = 2;
    }
    update(){
        let nextX = this.destinationPosition.x;
        let nextY = this.destinationPosition.y;

        const distance = this.moveTowards(this.destinationPosition, this.speed);
        const arrived = distance <= this.speed;

        if (arrived){
            if (this.game.input.lastKey === UP){
                nextY -= TILE_SIZE;
            } else if (this.game.input.lastKey === DOWN){
                nextY += TILE_SIZE;
            } else if (this.game.input.lastKey === LEFT){
                nextX -= TILE_SIZE;
            } else if (this.game.input.lastKey === RIGHT){
                nextX += TILE_SIZE;
            }
            this.destinationPosition.x = nextX;
            this.destinationPosition.y = nextY;
        }
    }
}